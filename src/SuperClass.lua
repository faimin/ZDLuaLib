-----
----- Created by Zero.D.Saber.
----- DateTime: 2019-07-01 11:23
-----
----- Class Introduce: 面向对象(继承)

local SuperClass = {}
SuperClass.__index = SuperClass
local mt = {}
function mt:__call(...)
    return SuperClass:new(...)
end
setmetatable(SuperClass, mt)
---下面这种写法有个弊端：第一个参数是table自身,所以改为上面的写法
-- setmetatable(SuperClass, {
--     __call = function(...)
--         for i, v in ipairs({...}) do
--             print("__call参数:", i, v)
--         end
--         return SuperClass:new(...)
--     end
-- })

function SuperClass:__call(...)
    for i, v in ipairs({...}) do
        print("__call参数:", i, v)
    end

    --函数也是属于table的一部分
    return self:initialize(...)
end

function SuperClass:initialize(...)
    local subClass = setmetatable({}, self)
    subClass.__index = subClass
    subClass.super = self
    print("父类 = ", self, "子类 = ", subClass)
    return subClass
end

function SuperClass:new(...)
    return self:initialize(...)
end

--测试代码
--  function SuperClass:setup()
--      print("父类setup方法 = ", self)
--      return self
--  end

--  local Object = SuperClass()
--  print("object = ", Object)
--  function Object:new(...)
--      for i, v in ipairs({...}) do
--          print("子类参数:", i, v)
--      end
--      print("子new方法执行了")
--      return self
--  end

--  local x = Object("1", "2", "3")
--  print("newObj = ", x)
--  print("子类未实现的方法：", x:setup())

--  local xx = setmetatable({}, x)
--  xx.__index = xx
--  print("newnewObj = ", xx)
--  print("孙类未实现的方法：", xx:setup())
--  print("孙类的父类 = ", xx.super)

return SuperClass