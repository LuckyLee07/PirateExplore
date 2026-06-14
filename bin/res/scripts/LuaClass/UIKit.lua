require "LuaClass/Header"

local kTagTypeNone = 0
local kTagTypeText = 1
local kTagTypeImage = 2
local kTagTypeCustom = 3

SNSColorfulLabel = class("SNSColorfulLabel", function (args)
    return ccui.RichText:create()
end)

SNSColorfulLabel.__index = SNSColorfulLabel

function SNSColorfulLabel:create(content, size)
    local view = SNSColorfulLabel.new(args)
    if view and view:init(content, size) then
        return view
    end
    return nil
end

function SNSColorfulLabel:init(content, size)
    if size ~= nil then
        self:ignoreContentAdaptWithSize(false)
        self:setSize(cc.size(500, 300))
    end

    -- 开始解析数据，返回table
    local re1 = ccui.RichElementText:create(1, WriteColor, 255, "这是白色的文字。 ", BoldFont, 24)
    local re2 = ccui.RichElementText:create(2, YellowColor, 255, "这个就是黄色的文字了。 ", BoldFont, 24)
    local reimg = ccui.RichElementImage:create(3, WriteColor, 255, "Images/UI/cjdh.png");
    local re3 = ccui.RichElementText:create(4, GreenColor, 255, "绿的在这里。 ", BoldFont, 24)
    local spr = cc.Sprite:create("Images/UI/DiamondBg.png")
    spr:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.1, 30)))
    local re4 = ccui.RichElementCustomNode:create(5, WriteColor, 255, spr)
    local re5 = ccui.RichElementText:create(6, RedColor, 255, "最后才轮到红色 ", BoldFont, 24)

    self:pushBackElement(re1)
    self:insertElement(re2, 1)
    self:pushBackElement(re3)
    self:insertElement(reimg, 2)
    self:pushBackElement(re4)
    self:insertElement(re5, 3)

    local dataTable = self:parse("[s:color=FFFFFF size=24]切分[s]字符串开始，[t:color=FF00FF size=24]测试紫红色文本[t] [i:scale=1.0]Images/UI/test.png[i]测试图片之后[c:color=red size=20]结束[c]...还不能结束，再来个[t:color=blue size=24]小字符串[t]")

    return true
end

--[[
解析html为文本数据的函数,不能支持嵌套
]]
function SNSColorfulLabel:parse(str)
    -- 定义查找标签的代码
    local tagPattern = "%[[citCIT][%w:=%.%s]+%][^%]]*%b[]"
    -- 取出标签的个数
    local _, tagNum = string.gsub(str, tagPattern, "")
    local dataTable = {}
    -- 记录上一次最后搜索的位置
    local lastEof = 0
    for i = 1, tagNum do
        local s, e = string.find(str, tagPattern, lastEof + 1)
        -- 如果当前搜索到的起始位置大于上一次的结束位置+1，那么证明之间的这个字符串是没有标签环绕的
        if s > lastEof + 1 then
            local normalTable = {}
            normalTable.type = kTagTypeNone
            normalTable.content = string.find(str, lastEof + 1, s)
            table.insert(dataTable, normalTable)
        end
        -- 开始解析标签内容
        local tagStr = string.sub(str, s, e)
        print("查找字符串结果:", i, s, e, tagStr)
        if tagStr ~= nil then
            local parsedTable = self:parseTag(tagStr)
            if parsedTable ~= nil then
                table.insert(dataTable, parsedTable)
            end
        end
        lastEof = e
    end
    return dataTable
end

function SNSColorfulLabel:parseTag(tagStr)
    -- body
    local returnVal = {}
    local tagStart = string.sub(tagStr, string.find(tagStr, "%b[]", 1))
    local typeStr = string.sub(tagStr, 2, 2)
    if typeStr == "t" then
        -- 字符串
        returnVal.type = kTagTypeText
    elseif typeStr == "i" then
        -- 图片
        returnVal.type = kTagTypeImage
    elseif typeStr == "c" then
        -- 自定义节点
        returnVal.type = kTagTypeCustom
    end
    local contentStr = string.gsub(tagStr, "%b[]", "")
    print("处理中的字符串:", tagStart, typeStr, contentStr)

    -- 开始解析各种设置。。。
    local configTable = {}
    -- 首先把里边的设置变成a=1这种结构，放个table里
    string.gsub(tagStart, "[^%s:=]+=[^%s%]]+", function(c) configTable[#configTable + 1] = c end)
    for k,v in pairs(configTable) do
        local fields = {}
        -- 然后再分解a和1出来
        string.gsub(v, "([^=]+)", function(c) fields[#fields + 1] = c end)
        if fields[1] ~= nil then

        end
    end

    
    return {}
end