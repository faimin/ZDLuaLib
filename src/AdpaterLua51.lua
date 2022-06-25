
--- hook setmetatable
--- https://stackoverflow.com/questions/27426704/lua-5-1-workaround-for-gc-metamethod-for-tables
--- https://blog.csdn.net/cbbbc/article/details/50959539
if _VERSION == "Lua 5.1" then
    local originSetmetatableFunc = setmetatable
    setmetatable = function(t, mt)
        if not t.gcProxy then
            local proxy = newproxy(true)
            getmetatable(proxy).__gc = function(a)
                mt.__gc(t)
            end
            t[proxy] = true
            t.gcProxy = proxy
        end
    end
    return originSetmetatableFunc(t, mt)
end