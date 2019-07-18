
--- Created by Zero.D.Saber.
--- DateTime: 2019-04-11 12:23
---
--- Class Introduce: Promise

local Promise = {}
local met = {}
function met:__call( ... )
    return Promise:new( ... )
end
setmetatable(Promise, met)

PromiseState = {
    pending = 0,
    fulfilled = 1,
    rejected = 2,
}

function Promise:new()
    o = {}
    o = setmetatable(o, self)
    self.__index = self
    o.observers = {
        resultObservers = {},
        errorObservers = {}
    }
    o.value = nil
    o.error = nil
    o.state = PromiseState.pending
    o.isPromise = true
    return o
end

--- 核心方法
local function observer(self, resolveFunc, rejectFunc)
    local newPromise = Promise:new()

    --promise已经fulfilled时直接回
    if resolveFunc then
        if self.state == PromiseState.fulfilled then
            --如果返回的还是promise
            if type(self.value) == "table" and self.value.isPromise == true then
                observer(self.value, function(v)
                    newPromise:fulfill(resolveFunc(v))
                end, function(e)
                    newPromise:reject(e)
                end)
            else
                newPromise:fulfill(resolveFunc(self.value))
            end
        elseif self.state == PromiseState.rejected then
            --thenNext时也要把错误值往下传递,因为后面也许会有catch操作,不传递的话数据链就断了
            newPromise:reject(self.error)
        else
            table.insert(self.observers.resultObservers, function(value)
                newPromise:fulfill(resolveFunc(value)) --值进行map操作,然后往下传递
            end)
            table.insert(self.observers.errorObservers, function(error)
                newPromise:reject(error) --值不进行map操作,直接往下传递
            end)
        end
    end

    if rejectFunc then
        if self.state == PromiseState.rejected then
            newPromise:reject(rejectFunc(self.error))
        elseif self.state == PromiseState.fulfilled then
            --如果返回的是promise
            if type(self.value) == "table" and self.value.isPromise == true then
                observer(self.value, function(v)
                    newPromise:fulfill(v)	--往下传递
                end, function(e)
                    newPromise:reject(rejectFunc(e))
                end)
            else
                newPromise:fulfill(self.value)
            end
        else
            table.insert(self.observers.resultObservers, function(value)
                newPromise:fulfill(value)
            end)
            table.insert(self.observers.errorObservers, function(error)
                newPromise:reject(rejectFunc(error))
            end)
        end
    end

    return newPromise
end

--使用说明:
--[[
    Promise:new():async(function(fulfill, reject)
        http:requset(url, parameters, function(response, error)
            if reponse ~= nil then
                fulfill(response) -- 假如response = 100
            else
                reject(error) -- errorxxxx
            end
        end)
    end):thenNext(function(value)
        return value * 2  -- value = 100
    end):thenNext(function(value)
        print(value)  -- 200
        return nil
    end):catch(function(error)
        print(error) -- errorxxxx
    end)
--]]
function Promise:async(promiseFunc)
    if type(promiseFunc) ~= "function" then
        assert(false, "parameter should be a function type")
    end

    --没有调用new的时候
    if self == Promise then
        self = self:new()
    end

    promiseFunc(function (result)
        self:fulfill(result)
    end, function(error)
        self:reject(error)
    end)

    return self
end

function Promise:thenNext(resultFunc)
    return observer(self, resultFunc, nil)
end

function Promise:catch(errorFunc)
    return observer(self, nil, errorFunc)
end

function Promise:fulfill(value)
    if self.state == PromiseState.pending then
        self.state = PromiseState.fulfilled
        self.value = value
        for _, v in ipairs(self.observers.resultObservers) do
            if type(v) == "function" then
                v(value)
            end
        end
    end
end

function Promise:reject(error)
    if self.state == PromiseState.pending then
        self.state = PromiseState.rejected
        self.error = error
        for _, v in ipairs(self.observers.errorObservers) do
            if type(v) == "function" then
                v(error)
            end
        end
    end
end

function Promise:all(promises)
    if (not promises or #promises == 0) then return nil end

    local newPromise = self:async(function (resolve, reject)
        local resultArray = {}
        for i, v in ipairs(promises) do
            observer(v,function (value)
                table.insert(resultArray, value)

                for _, vv in ipairs(promises) do
                    if vv.state ~= PromiseState.fulfilled then
                        return
                    end
                end

                --没有错误的时候才会回调
                resolve(resultArray)
            end, function (error)
                --如果出现错误立即reject
                reject(error)
            end)
        end
    end)

    return newPromise
end

function Promise:finish(promises)
    if (not promises or #promises == 0) then return nil end

    local newPromise = self:async(function (resolve, reject)
        local resultArray = {}
        local errorArray = {}
        for i, v in ipairs(promises) do
            observer(v,function (value)
                table.insert(resultArray, value)

                for _, vv in ipairs(promises) do
                    if vv.state == PromiseState.pending then
                        return
                    end
                end

                resolve(resultArray)
            end, function (error)
                table.insert(resultArray, error)

                --所有的promise都失败时才会回调
                for _, vv in ipairs(promises) do
                    if vv.state ~= PromiseState.rejected then
                        return
                    end
                end

                table.insert(errorArray, error)

                reject(errorArray)
            end)
        end
    end)

    return newPromise
end

return Promise



--[[
-- 测试代码
local _class = {}

function _class:new()
	local class = {}
	class["key"] = "value"
	setmetatable(class, self)
	return self
end

local promise1 = Promise:new():async(function(fulfill, reject)
	fulfill(100)
--	reject("❌")
end):thenNext(function(value)
	return value * 2  	-- value = 100
end):catch(function(error)
	print(error) 		-- errorxxxx
end):thenNext(function(value)
	print(value)  		-- 200
	return value / 100 	-- 2
end)

local promise2 = Promise:new():async(function(fulfill, reject)
	fulfill(2300)
end)

local promise3 = Promise:new():async(function(fulfill, reject)
--	fulfill("你好")
	reject("❌")
end)

Promise:new():all({ promise1, promise2, promise3 }):thenNext(function(value)
    return value
end):catch(function(error)
    print(error)
end):thenNext(function(value)
    for i, v in ipairs(value) do
        print(i, v)
        --print result is:
        --1	2
        --2	2300
        --3	你好
    end
end)

Promise():finish({ promise1, promise2, promise3 }):thenNext(function(value)
    print("第一个next")
    return value
end):catch(function(error)
    print("都错了", error)
end):thenNext(function(value)
    print("来结果了。。。")
    for i, v in ipairs(value) do
        print(i, v)
    end
end)

--支持内部返回promise的处理
Promise():async(function(fulfill, reject)
    local p = Promise():async(function(_fulfill, _reject)
        _fulfill("1")
        --_reject("-1")
    end)
    fulfill(p)
end):thenNext(function(v)
    local p = Promise():async(function(_fulfill, _reject)
        _fulfill(v .. " 10000000")
        --_reject("内部错误")
    end)
    return p
end):catch(function(e)
    local errortext = "catch结果 = " .. e
    return errortext
end):thenNext(function(v)
    print("thenNext结果 = ", v)
end):catch(function(e)
    print("最后的error", e)
end)


return _class

--]]