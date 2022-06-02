-----
----- Created by Zero.D.Saber.
----- DateTime: 2019-07-01 11:23
-----
----- Class Introduce: 面向对象(继承)

local JSON = require("JSON")

local MT = {
    __tostring = function(t)
        if JSON then
            return JSON.encode(t)
        else
            return tostring(v)
        end
    end
}
MT.__index = MT
MT.__call = function(self, ...)
    return self:new(...)
end
setmetatable(MT, MT)

function MT:new(...)
    local instance = setmetatable({}, self)
    return instance
end

return MT