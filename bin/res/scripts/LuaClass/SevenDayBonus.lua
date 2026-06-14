require "LuaClass/Header"
require "LuaClass/UIKit"
require "LuaClass/DataManager"
require "LuaClass/WoWUtils"
require "LuaClass/GuideController"


local SevenDayBonusLayerInstance = nil

SevenDayBonusLayer = class("SevenDayBonusLayer", function ()
    return AlertView:create(0, 1, "", function()
    end, nil, nil, "领 取")
end)

SevenDayBonusLayer.__index = SevenDayBonusLayer

function SevenDayBonusLayer:create()
    if SevenDayBonusLayerInstance ~= nil then
        return nil
    end
    local view = SevenDayBonusLayer.new()
    if view and view:init() then
        SevenDayBonusLayerInstance = view
        return view
    end
    return nil
end

-- 清理函数
function SevenDayBonusLayer:destory()
    SevenDayBonusLayerInstance = nil
end

function SevenDayBonusLayer:init()
    -- 钻石商店物品
    -- local scrollViewSize = cc.size(self.s_size.width, self.s_size.height - 140)
    -- self.scrollViewContainer = cc.Layer:create()

    -- self.scrollView = cc.ScrollView:create(scrollViewSize)

    -- self.scrollView:setPosition(cc.p(self.s_position.x - self.s_size.width * 0.5, self.s_position.y - self.s_size.height * 0.5 + 40))
    -- self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    -- self.scrollViewContainer:setPosition(cc.p(0.0, 0.0))
    -- self.scrollView:setClippingToBounds(true) -- 設置剪切
    -- self.scrollView:setBounceable(true)  -- 設置彈性效果
    -- self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    -- self.scrollView:setDelegate()
    -- -- self.scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- self:addChild(self.scrollView)

    -- 移除自己的关闭按钮
    self.closeBtn:removeFromParent()

    -- 添加title文字
    local titleSpr = cc.Sprite:create("Images/SevenDayBonus/SevenBonusTitle.png")
    titleSpr:setPosition(cc.p(self.s_position.x, self.s_position.y + self.s_size.height * 0.5 - 36))
    self:addChild(titleSpr)

    -- 添加底部的确定按钮
    local okBtn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
    okBtn:setPosition(cc.p(self.s_position.x, self.s_position.y - self.s_size.height * 0.5 + okBtn:getContentSize().height))
    okBtn:registerScriptTapHandler(function()
        -- cclog("点击信息按钮", i)
        local sevenData = DataManager:getInstance():getRoleData(roleSevenDayBonus)
        -- 处理领取数据
        local csv = DataManager:getInstance():getCSVByID(csvOfLogingReward)
        for k,v in pairs(csv) do
            -- print("id是：", v["ID"], math.floor(sevenData / 1000000))
            if v["ID"] == ((math.floor(sevenData / 1000000) + 1) .. "") then
                -- print("走进来了。。。")
                for ks,vs in pairs(v["reward"]) do
                    local types = vs[1]
                    local id = vs[2]
                    local num = vs[3]
                    -- print("数据在此：", types, id, num)
                    if types == "1" then
                        -- 道具
                        if id ~= nil and num ~= nil then
                            -- print("要加入背包数据了")
                            DataManager:getInstance():addPackItemWithId(id, tonumber(num), true)
                        end
                    elseif types == "2" then
                        -- 英雄
                        if id ~= nil and num ~= nil then
                            DataManager:getInstance():addSoilderWithId(id, tonumber(num), true)
                        end
                    end
                end
                break
            end
        end
        -- 把当前数据日期 + 1
        local allDayNum = math.floor(NotificationNode:getInstance():GetGameTime() / 86400)
        if sevenData == 0 then
            sevenData = allDayNum + 1000000
        else
            -- 1000000等于一天
            sevenData = allDayNum + 1000000 * (math.floor(sevenData / 1000000) + 1)
        end
        cclog("sevenData:%d", sevenData)
        DataManager:getInstance():setRoleData(roleSevenDayBonus, sevenData)
        self:removeFromParent()
    end)

    local okLabel = cc.LabelTTF:create("领  取", BoldFont, 28.0)
    okLabel:setColor(BaseColor)
    okLabel:setPosition(cc.p(okBtn:getContentSize().width * 0.5, okBtn:getContentSize().height * 0.5))
    okBtn:addChild(okLabel)

    local menu = cc.Menu:create(okBtn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    -- 加载数据回调
    self:loadData()

    -- 添加析构回调
    self:setCancelCallback(function()
        -- body
        self:destory()
    end)
    return true
end

function SevenDayBonusLayer:loadData()
    cclog("开始加载7日登陆奖励界面的数据")
    local csv = DataManager:getInstance():getCSVByID(csvOfLogingReward)
    local gap = 20
    local menuItemArr = {}
    local showSize = cc.size(self.s_size.width, self.s_size.height - 60)
    local originPos = cc.p(self.s_position.x - self.s_size.width * 0.5, self.s_position.y - self.s_size.height * 0.5 + 40)
    -- 获得从1970年1月1日至今的日子
    local sevenData = DataManager:getInstance():getRoleData(roleSevenDayBonus)
    local days = math.floor(sevenData / 1000000) + 1
    for i = 1, 7 do
        local data = csv[i..""]
        local bg = cc.Sprite:create("Images/SevenDayBonus/SevenBonusItem.png") 
        if bg ~= nil then
            bg:setPosition(cc.p(originPos.x + (3 - i % 2 * 2) * (bg:getContentSize().width * 0.5) + (2 - i % 2) * gap, 
                originPos.y + showSize.height - math.ceil(i * 0.5) * (bg:getContentSize().height + gap)))
            self:addChild(bg)

            -- 添加礼包图标
            local fileName = nil
            if i == 7 then
                fileName = "Images/SevenDayBonus/SevenBonusBox3.png"
            elseif i == 2 or i == 3 then
                fileName = "Images/SevenDayBonus/SevenBonusBox2.png"
            else
                fileName = "Images/SevenDayBonus/SevenBonusBox1.png"
            end
            local icon = cc.Sprite:create(fileName)
            icon:setPosition(cc.p(icon:getContentSize().width * 0.62, icon:getContentSize().height * 0.82))
            bg:addChild(icon)

            -- 添加礼包天数文字
            local dayLabel = cc.LabelTTF:create(data["day"], BoldFont, 24.0)
            dayLabel:setPosition(cc.p(icon:getPositionX(), dayLabel:getContentSize().height * 0.7))
            bg:addChild(dayLabel)

            -- 如果i小于领过的日期, 那么添加领取过的图标，如果等于，那么添加高粱矿
            if i < days then
                local stateSpr = cc.Sprite:create("Images/UI/cjdh.png")
                stateSpr:setPosition(cc.p(bg:getContentSize().width - stateSpr:getContentSize().width * 0.3, bg:getContentSize().height - stateSpr:getContentSize().height * 0.3))
                bg:addChild(stateSpr, 1)
            elseif i == days then
                local stateSpr = cc.Sprite:create("Images/SevenDayBonus/SevenBonusItemHL.png")
                stateSpr:setPosition(cc.p(bg:getContentSize().width * 0.5, bg:getContentSize().height * 0.5))
                bg:addChild(stateSpr)
            end

            -- 添加礼包内容文字
            local infoString = ""
            for k,v in pairs(data["Tips"]) do
                infoString = infoString .. v[1] .. "\n"
            end
            local infoLabel = cc.LabelTTF:create(infoString, BoldFont, 20.0)
            infoLabel:setColor(WriteColor)
            infoLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            infoLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
            infoLabel:setAnchorPoint(cc.p(0, 0.5))
            infoLabel:setPosition(cc.p(icon:getPositionX() + icon:getContentSize().width * 0.7, bg:getContentSize().height * 0.5))
            bg:addChild(infoLabel)
        end
    end

end