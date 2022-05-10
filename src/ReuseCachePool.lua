--- Project: ZeroCode
--- Created by Zero.D.Saber.
--- DateTime: 2022/5/10 14:14
---
--- Class Introduce: ReuseCachePool
---
---

local MT = {
    -- self is ReuseCachePool
    __call = function(self, ...)
        local params = { ... }
        return self:new(params[1])
    end
}
local ReuseCachePool = setmetatable({}, MT)

---@param createObjCallback fun(reuseId:string):any
function ReuseCachePool:new(createObjCallback)
    local instance = setmetatable({}, self)
    self.__index = self

    instance:init(createObjCallback)

    return instance
end

---@param createObjCallback fun(reuseId:string):any
function ReuseCachePool:init(createObjCallback)

    self:setCreateObjCallback(createObjCallback)

    ---@type table<string, any[]>
    self.reusePool = {}

    return self
end

---@param createObjCallback fun(reuseId:string):any
function ReuseCachePool:setCreateObjCallback(createObjCallback)
    ---@type fun(reuseId:string):any
    self.createObjCallback = createObjCallback
    return self
end

---入队
---@param reuseId string
---@param obj any
function ReuseCachePool:enqueue(reuseId, obj)
    if not reuseId then
        assert(false, "reuseId is a required params")
        return
    end

    local t = self.reusePool[reuseId]
    if not t then
        t = {}
        self.reusePool[reuseId] = t
    end
    table.insert(t, obj)
end

---出队
---@param reuseId string
---@return any
function ReuseCachePool:dequeue(reuseId)
    if not reuseId then
        assert(false, "reuseId is a required params...")
        return
    end

    local t = self.reusePool[reuseId]
    if not t then
        t = {}
        self.reusePool[reuseId] = t
    end
    local o = table.remove(t)
    if (not o) and self.createObjCallback then
        o = self.createObjCallback(reuseId)
    else
        assert(self.createObjCallback, "callBack is required...")
    end
    return o
end

return ReuseCachePool
