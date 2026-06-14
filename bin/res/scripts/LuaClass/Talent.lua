require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DataManager"


TalentLayer = class("TalentLayer", function ()
    return BaseView:create()
end)

TalentLayer.__index = TalentLayer
TalentLayer.scrollView = nil
TalentLayer.scrollViewContainer = nil
TalentLayer.alertLabel = nil

function TalentLayer:create()
    local view = TalentLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function TalentLayer:destory()
    -- body
    DataManager:getInstance():unregisterEvent(roleTalent, "talent")
end

function TalentLayer:init()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 设置title文字
    self.titleLabel:setString("天 赋")

    -- 隐藏上边左侧的按钮
    self.topLeftBtn:setVisible(false)

    -- 修改右侧按钮为返回
    self:resetTopRightButtonToBack()

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, "出 征", function()
        zqDispatch:moveToExpedition()
    end, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
    end, nil, true, zqAlchemyTime, false)

    -- 天赋界面隐藏天赋按钮
    self.leftBtn:setVisible(false)
    self.leftBtnText:setVisible(false)

    -- 天赋界面中间滚动信息
    local function scrollViewDidScroll()
        -- cclog("scrollView滑动ing")
        -- print("--------- scrollView滑动ing")
    end

    
    -- 设置天赋界面中间部分大小、位置
    local scrollViewSize = cc.size(self.areaWidth, self.areaHeight)
    self.scrollViewContainer = cc.Layer:create()
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(self.originPos)
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollViewContainer:setPosition(cc.p(0.0, 5.0))
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    self.scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)

    -- 添加没有数据的时候的提示
    self.alertLabel = cc.LabelTTF:create("尚未开启任何天赋", BoldFont, 40.0)
    self.alertLabel:setColor(BaseColor)
    self.alertLabel:setPosition(self.centerPos)
    self.alertLabel:setVisible(false)
    self:addChild(self.alertLabel)

    -- 加载天赋数据
    self:loadTalentData()

    DataManager:getInstance():registerEvent(roleTalent, "talent", function()
        -- body
        self:loadTalentData()
    end)

	return true
end

function TalentLayer:loadTalentData()
    -- body
    local talentData = DataManager:getInstance():getRoleData(roleTalent)

    -- 设置天赋界面中间部分条目
    local createItem = function (titleStr, contentStr)
        -- body
        local container = cc.Node:create()
        local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
        local bg = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, temp:getContentSize().width, temp:getContentSize().height), cc.rect(17, 17, 30, 30));
        bg:setPreferredSize(cc.size(self.areaWidth, 80))
        bg:setPosition(cc.p(self.areaWidth * 0.5, 0.0))
        container:addChild(bg)

        local gapH = 3

        local content = cc.LabelTTF:create(contentStr, BoldFont, 22.0)
        content:setColor(WriteColor)
        content:setAnchorPoint(cc.p(0.0, 0.5))
        content:setPosition(cc.p(10.0, content:getContentSize().height * 0.5 + gapH + 4))
        bg:addChild(content)

        local title = cc.LabelTTF:create(titleStr, BoldFont, 28.0)
        title:setColor(BaseColor)
        title:setAnchorPoint(cc.p(0.0, 0.5))
        title:setPosition(cc.p(content:getPositionX(), content:getPositionY() + content:getContentSize().height * 0.5 + gapH + title:getContentSize().height * 0.5))
        bg:addChild(title)

        container:setContentSize(cc.size(self.areaWidth, 80))
        return container
    end

    local tempHeight = 90
    local num = getTableRowNum(talentData)
    local tempTotalHeight = num * tempHeight

    if (tempTotalHeight < self.areaHeight) then
        tempTotalHeight = self.areaHeight
    end

    local csvData = DataManager:getInstance():getCSVByID(csvOfTalent)

    -- 根据天赋数据判断是否显示提示
    self.alertLabel:setVisible(num == 0)

    for i=num,1,-1 do
        local talentId = talentData[tostring(i)]
        local talentItem = csvData[tostring(talentId)]

        local item = self.scrollViewContainer:getChildByTag(i)
        if (item ~= nil) then
            item:removeFromParent()
        end
        item = createItem(talentItem[dataKeyName], talentItem[dataKeyComment])
        item:setPosition(cc.p(0.0, tempTotalHeight - (tempHeight * (num - i + 1)) + tempHeight * 0.5))
        item:setTag(i)
        self.scrollViewContainer:addChild(item)
    end
    self.scrollView:setContentSize(cc.size(self.areaWidth, tempTotalHeight))
    self.scrollView:setContentOffset(cc.p(0, -(tempTotalHeight - self.scrollView:getViewSize().height)))
end