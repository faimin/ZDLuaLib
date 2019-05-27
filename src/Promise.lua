
--- Created by Zero.D.Saber.
--- DateTime: 2019-04-11 12:23
---
--- Class Introduce: Promise

local Promise = {}

PromiseState = {
    pending = 0,
    fulfilled = 1,
    rejected = 2,
}

function Promise:new(o)
    o = o or {}
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

local function observer(self, resolveFunc, rejectFunc)
    local newPromise = Promise:new()

    --promise已经fulfilled时直接回
    if resolveFunc then
        if self.state == PromiseState.fulfilled then
            newPromise:fulfill(resolveFunc(self.value))
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
    elseif rejectFunc then
        if self.state == PromiseState.rejected then
            newPromise:reject(rejectFunc(self.error))
        elseif self.state == PromiseState.fulfilled then
            newPromise:fulfill(self.value)
        else
            table.insert(self.observers.resultObservers, function(value)
                newPromise:fulfill(value)
            end)
            table.insert(self.observers.errorObservers, function(error)
                newPromise:reject(rejectFunc(error))
            end)
        end
    else
        assert("callBack can't be nil")
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

function Promise:next(resultFunc)
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
                for _, vv in ipairs(promises) do
                    if vv.state ~= PromiseState.fulfilled then
                        return
                    end
                end

                table.insert(resultArray, value)
                resolve(resultArray)
            end, nil)

            observer(v, nil, function (error)
                for _, vv in ipairs(promises) do
                    if vv.state ~= PromiseState.rejected then
                        return
                    end
                end

                reject(error)
            end)
        end
    end)

    return newPromise
end

return Promise