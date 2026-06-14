require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/Utils"
require "LuaClass/SDButton"

AchievementLayer = class("AchievementLayer", function ()
    return BaseView:create()
end)

AchievementLayer.__index = AchievementLayer
AchievementLayer.scrollView = nil
AchievementLayer.scrollViewContainer = nil
AchievementLayer.scrollViewHeight = 0

function AchievementLayer:create()
    local view = AchievementLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function AchievementLayer:destory()
    -- body
    DataManager:getInstance():unregisterEvent(roleAchievement, "achievement")
    DataManager:getInstance():unregisterEvent(roleTalent, "talent")
    -- 出去的时候清理红点
    GuideController:getInstance():addStep(402, true)
    -- 调用父类的析构
    self:superDestory()
end

function AchievementLayer:init()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 设置title文字
    self.titleLabel:setString("成 就")

    -- 隐藏上边左侧的按钮
    self.topLeftBtn:setVisible(false)

    -- 修改右侧按钮为返回
    self:resetTopRightButtonToBack()

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, nil, function()
        zqDispatch:moveToExpedition()
    end, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
    end, nil, true, zqAlchemyTime, false)

    
    -- -- 设置天赋界面中间部分大小、位置
    -- local scrollViewSize = cc.size(self.areaWidth, self.areaHeight)
    -- self.scrollViewContainer = cc.Layer:create()
    -- self.scrollView = cc.ScrollView:create(scrollViewSize)
    -- self.scrollView:setPosition(self.originPos)
    -- self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    -- self.scrollViewContainer:setPosition(cc.p(0.0, 5.0))
    -- self.scrollView:setClippingToBounds(true) -- 設置剪切
    -- self.scrollView:setBounceable(true)  -- 設置彈性效果
    -- self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    -- self.scrollView:setDelegate()
    -- self.scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- self:addChild(self.scrollView)

    self:loadAchievementData()

    DataManager:getInstance():registerEvent(roleAchievement, "achievement", function()
        -- body
        self:loadAchievementData()
    end)

    DataManager:getInstance():registerEvent(roleTalent, "talent", function()
        -- body
        self:loadAchievementData()
    end)

    return true
end

function AchievementLayer:loadAchievementData()
    -- body
    local achievementData = DataManager:getInstance():getRoleData(roleAchievement)

    local achievementPointLabel = self:getChildByTag(2)
    if (achievementPointLabel ~= nil) then
        achievementPointLabel:removeFromParent()
    end
    achievementPointLabel = cc.LabelTTF:create("成就点数：" .. DataManager:getInstance():getRoleData(roleAchievementPoint), BoldFont, 32.0)
    achievementPointLabel:setAnchorPoint(cc.p(0.0, 0.5))
    achievementPointLabel:setColor(WriteColor)
    achievementPointLabel:setPosition(cc.p(0.0, self.originPos.y + self.areaHeight - achievementPointLabel:getContentSize().height * 0.5))
    achievementPointLabel:setTag(2)
    self:addChild(achievementPointLabel)

    self.scrollViewHeight = self.areaHeight - achievementPointLabel:getContentSize().height

    -- 自动学习天赋
    local tallentCsvData = DataManager:getInstance():getCSVByID(csvOfTalent)
    local unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(DataManager:getInstance():getLockedTallent(), dataKeyAutoType, {[1]="1"})

    local unlockedAchievement = sortTableOrderByASC(unlocked, dataKeyAchievement)
    local trigerLabel = nil
    if (unlockedAchievement ~= nil) then
        if (unlockedAchievement[1] ~= nil) then
            trigerLabel = self:getChildByTag(3)
            if (trigerLabel ~= nil) then
                trigerLabel:removeFromParent()
            end
            trigerLabel = cc.LabelTTF:create("点数达到" .. unlockedAchievement[1][dataKeyAchievement] .. "会获得神秘天赋奖励", BoldFont, 27.0)
            trigerLabel:setAnchorPoint(cc.p(0.0, 0.5))
            trigerLabel:setColor(WriteColor)
            trigerLabel:setPosition(cc.p(0.0, achievementPointLabel:getPositionY() - achievementPointLabel:getContentSize().height * 0.5 - trigerLabel:getContentSize().height * 0.5))
            self:addChild(trigerLabel)
            achievementPointLabel:setTag(3)
            self.scrollViewHeight = self.scrollViewHeight - trigerLabel:getContentSize().height

        end
    end

    -- 天赋界面中间滚动信息
    local function scrollViewDidScroll()
        -- cclog("scrollView滑动ing")
        -- print("--------- scrollView滑动ing")
    end

    local scrollViewSize = cc.size(self.areaWidth, self.scrollViewHeight)
    self.scrollViewContainer = cc.Layer:create()
    self.scrollView  = self:getChildByTag(1)
    if (self.scrollView ~= nil) then
        self.scrollView:removeFromParent()
    end

    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(self.originPos)
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollViewContainer:setPosition(cc.p(0.0, 5.0))
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView.bIsScrollView = true
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    -- self.scrollView:setDelegate()
    -- self.scrollView:registerScriptHandler(function()

    -- end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- self.scrollView:registerScriptHandler(function()

    -- end,cc.SCROLLVIEW_SCRIPT_ZOOM)
    self.scrollView:setTag(1)
    self:addChild(self.scrollView)

    -- 设置天赋界面中间部分条目
    local getShowInfoBoxData = function (itemData)
        -- body
        local desc = itemData[dataKeyDesc]
        local rewardPoint = itemData[dataKeyPoint]
        local showData = desc .. "\n" .. "奖励成就点x" .. rewardPoint
        local diamond = tonumber(itemData[dataKeyDiamond])
        if (diamond > 0) then
            showData = showData .. "\n" .. "奖励钻石x" .. diamond
        end

        local achievementType = getNumber(itemData[dataKeyType])
        local totalValue = itemData[dataKeyTotalValue]

        local progress = nil
        local store = DataManager:getInstance():getRoleData(roleStorageInfo)

        if (achievementType == achievement_Alchemy) then
            progress = store[achievement_Alchemy]
        elseif (achievementType == achievement_Exploration) then
            progress = store[achievement_Exploration]
        elseif (achievementType == achievement_Gamble) then
            progress = store[achievement_Gamble]
        elseif (achievementType == achievement_Arena) then
            progress = store[achievement_Arena]
        elseif (achievementType == achievement_ConsumeBread) then
            progress = store[achievement_ConsumeBread]
        elseif (achievementType == achievement_Collect) then
            progress = store[achievement_Collect]
        -- elseif (achievementType == achievement_ShareToFriends) then
        --     progress = store[achievement_ShareToFriends]
        -- elseif (achievementType == achievement_ShareToWeibo) then
        --     progress = store[achievement_ShareToWeibo]
        elseif (achievementType == achievement_KillMonster) then
            progress = store[achievement_KillMonster]
        end
        -- progress = "5"
        if ((progress ~= nil) and (totalValue ~= nil)) then
            if (totalValue ~= "-1") then
                showData = showData .. "\n" .. "当前进度" .. progress .. "/" .. totalValue
            end
        end
        return showData
    end

    local createItem = function (tableData, index, flag)
        -- body
        local container = cc.Node:create()

        -- local button = ccui.Button:create()
        -- container:addChild(button)
        -- button:loadTextures("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        -- button:setPosition(cc.p(button:getContentSize().width * 0.5, 0.0))
        -- button:setTag(index)
        -- -- button:setTouchEnabled(true)
        -- button:addTouchEventListener(function (sender, eventType)
        --     -- body
        --     local tag = sender:getTag()

        --     -- local achievementData = DataManager:getInstance():getRoleData(roleAchievement)
        --     local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
        --     local itemData = csvData[tostring(tag)]
        --     local showData = getShowInfoBoxData(itemData)

        --     -- -- --  测试代码    By Jasper.Hsu
        --     -- local point = DataManager:getInstance():getRoleData(roleAchievementPoint)
        --     -- DataManager:getInstance():setRoleData(roleAchievementPoint, (point + 10), nil)
        --     -- showData = showData .. "\n成就点：" .. DataManager:getInstance():getRoleData(roleAchievementPoint) .. ""

        --     --     local _result =  DataManager:getInstance():addCoin(100)

        --     -- -- --  测试代码

        --     self:showInfoBox(showData)


        -- end)

        local button = SDButton:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png",function ()
            -- local tag = sender:getTag()
            local tag = index

            -- local achievementData = DataManager:getInstance():getRoleData(roleAchievement)
            local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
            local itemData = csvData[tostring(tag)]
            local showData = getShowInfoBoxData(itemData)

            -- -- --  测试代码    By Jasper.Hsu
            -- local point = DataManager:getInstance():getRoleData(roleAchievementPoint)
            -- DataManager:getInstance():setRoleData(roleAchievementPoint, (point + 10), nil)
            -- showData = showData .. "\n成就点：" .. DataManager:getInstance():getRoleData(roleAchievementPoint) .. ""

            --     local _result =  DataManager:getInstance():addCoin(100)

            -- -- --  测试代码

            self:showInfoBox(showData)
        end)
        button:setSwallowTouches(false)
        button:setPosition(cc.p(button:getContentSize().width * 0.5, 0.0))
        button:setTag(index)
        container:addChild(button)

        local buttonLabel = cc.LabelTTF:create(tableData[dataKeyName], BoldFont, 32.0)

        buttonLabel:setColor(BaseColor)
        buttonLabel:setPosition(cc.p(button:getContentSize().width * 0.5, button:getContentSize().height * 0.5))
        button:addChild(buttonLabel)

        -- local flag = tableData[dataKeyFlag]

        -- 开启
        if (flag > 0) then
            local openFlagSprite = cc.Sprite:create("Images/UI/cjdh.png")
            -- openFlagSprite:setPosition(cc.p(button:getContentSize().width, 0))
            openFlagSprite:setPosition(cc.p(button:getContentSize().width - 15, button:getContentSize().height - 12))
            button:addChild(openFlagSprite)

        end

        container:setContentSize(button:getContentSize())
        return container
    end

    local num = getTableRowNum(achievementData)
    local col = 3

    local tempSprite = cc.Sprite:create("Images/btn/ann03_a.png")

    local gap_h = 25
    local gapH = (self.areaWidth - gap_h * 2 - tempSprite:getContentSize().width * col) / (col - 1)
    local gapHTemp = gapH
    gapH = gapH + tempSprite:getContentSize().width
    local gapV = 72
    
    local tempRow = math.floor(num / col)
    local row = math.ceil(num / col)

    local tempTotalHeight = row * gapV
    if (tempTotalHeight < self.scrollViewHeight) then
        tempTotalHeight = self.scrollViewHeight
    end

    local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
    for i=1,row do
        for j=1,col do
            local index = (i - 1) * col + j
            if (index <= num) then
                local item = self.scrollViewContainer:getChildByTag(index)

                if (item ~= nil) then
                    item:removeFromParent()
                end

                item = createItem(csvData[tostring(index)], index, achievementData[tostring(index)])
                item:setPosition(cc.p(gap_h + (j - 1) * gapH, tempTotalHeight - (gapV * i) + item:getContentSize().height * 0.5))
                item:setTag(index)
                self.scrollViewContainer:addChild(item)
                -- end
            end
        end
    end

    self.scrollView:setContentSize(cc.size(self.areaWidth, tempTotalHeight))
    self.scrollView:setContentOffset(cc.p(0, -(tempTotalHeight - self.scrollView:getViewSize().height)))

    achievementPointLabel:setPosition(cc.p(self.originPos.x + gap_h, achievementPointLabel:getPositionY()))
    if (trigerLabel ~= nil) then
        trigerLabel:setPosition(cc.p(achievementPointLabel:getPositionX(), trigerLabel:getPositionY()))
    end

end
