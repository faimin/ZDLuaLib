--- Project: ZDLuaLib
--- Created by Zero.D.Saber.
--- DateTime: 2022/4/22 18:00
---
--- Class Introduce: Import
---
---

---以`delimiter`来分割`text`字符串
---@param text string
---@param delimiter string
---@return string[]
local function split(text, delimiter)
    assert(type(text) == "string")
    local separateStr = string.format("[^%s]+", delimiter)
    local words = {}
    for s in string.gmatch(text, separateStr) do
        table.insert(words, s)
    end
    return words
end

---以相对路径的方式引用模块
---@author Zero.D.Saber
---@param relatedFilePath string
---@return any
function import(relatedFilePath)
    if not relatedFilePath or type(relatedFilePath) ~= "string" then
        assert(false)
    end

    -- 去掉lua后缀
    local suffix = ".lua"
    local found = string.sub(relatedFilePath, -(#suffix)) == suffix
    if found then
        relatedFilePath, _ = string.gsub(relatedFilePath, suffix, "")
    end

    if string.sub(relatedFilePath, 1, #(".")) ~= "." then
        local trimPath = string.gsub(relatedFilePath, "/", ".")
        return require(trimPath)
    end

    -- 找到当前文件的路径
    local info = debug.getinfo(2)
    local currentFilePath = info.source --info.short_src
    local currentFilePathArr = split(currentFilePath, "/")
    -- 把当前文件名从数组中剔除
    local _ = table.remove(currentFilePathArr)

    -- 相对路径被'/'分隔成路径数组
    local relatedArr = split(relatedFilePath, "/")
    -- 取出绝对路径的部分
    local reverseFilePaths = {}
    for i = #relatedArr, 1, -1 do
        local str = relatedArr[i]
        if string.sub(str, 1, #(".")) ~= "." then
            table.insert(reverseFilePaths, str)
        else
            break
        end
    end
    local relatedFilePaths = {}
    for i = #reverseFilePaths, 1, -1 do
        table.insert(relatedFilePaths, reverseFilePaths[i])
    end

    assert((#currentFilePathArr) >= (#relatedArr - #relatedFilePath), "相对路径错误")

    -- 发现'..'则把当前文件中的路径删除，最后再把相路径中的部分拼接起来
    for i = 1, #relatedArr do
        -- 只处理以相对路径开头的路径
        local tempStr = relatedArr[i]
        if string.sub(tempStr, 1, #(".")) == "." then
            local dotCount = #(tempStr)
            for _ = 2, dotCount do
                table.remove(currentFilePathArr)
            end
        end
    end

    local realPath = table.concat(currentFilePathArr, ".") .. "." .. table.concat(relatedFilePaths, ".")
    --print("realPath = ", realPath)

    return require(realPath)
end

---以相对路径的方式引用模块
---@author Zero.D.Saber
---@param relatedFilePath string
---@return any
function require_relative(relatedFilePath)
    return import(relatedFilePath)
end
