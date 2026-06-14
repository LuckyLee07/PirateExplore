require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DataManager"
require "LuaClass/WoWUtils"

ChargingView = class("ChargingView", function ()
    return AlertView:create(0, 3, "充 值", function()
    end, nil)
end)

ChargingView.__index = ChargingView

ChargingView.LimitRecommendedKey = "1"
ChargingView.GoodsInfoKey = "2"
ChargingView.countdownKey = "countdown"
-- ChargingView.IDKey = "ID"
ChargingView.diamondKey = "diamond"
ChargingView.moneyKey = "money"
ChargingView.extraDiamondKey = "extraDiamond"
ChargingView.pageIndex = 1
ChargingView.pointArr = nil
ChargingView.schduler = nil


function ChargingView:create(chargingData)
    local view = ChargingView.new()
    if view and view:init(chargingData) then
        return view
    end
    return nil
end

-- 清理函数
function ChargingView:destory()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
    self.schduler = nil
end

function ChargingView:init(chargingData)
	self.pageIndex = 1
	self.pointArr = {}
    self:loadData(chargingData)
    self:setCancelCallback(function()
        -- body
        self:destory()
    end)
    return true
end

function ChargingView:loadData(chargingData)
    -- body
    self.pageIndex = 1
    if (chargingData ~= nil) then
        DataManager:getInstance():setRoleData(roleChargingData, chargingData, nil)
    end

    if (self.schduler ~= nil) then
        self:destory()
    end

    local chargingTableData = DataManager:getInstance():getRoleData(roleChargingData)
    local recommended = chargingTableData[self.LimitRecommendedKey]
    local goodsInfo = chargingTableData[self.GoodsInfoKey]
    local countdownRowNum = getTableRowNum(recommended)
    -- if (DataManager:getInstance():getRoleData(roleChargingData) == nil) then
    --     local countdownTableData = {}

    --     for i=1,countdownRowNum do
    --         local temp = recommended[tostring(i)]
    --         countdownTableData[temp[self.IDKey]] = temp[self.countdownKey]
    --     end
    --     DataManager:getInstance():setRoleData(roleChargingData, countdownTableData, nil)
    -- else
    --     local countdownTableData = DataManager:getInstance():getRoleData(roleChargingData)

    --     for i=1,countdownRowNum do
    --         local temp = recommended[tostring(i)]
    --         local countdownID = temp[self.IDKey]
    --         if (countdownTableData[countdownID] == nil) then
    --             countdownTableData[countdownID] = temp[self.countdownKey]
    --         else
    --             local time = countdownTableData[countdownID]
    --             if (tonumber(time) <= 0.0) then
    --                 countdownTableData[countdownID] = temp[self.countdownKey]
    --             end
    --         end
    --     end

    --      -- 删除本次计费不需要的推荐项
    --     for k,v in pairs(countdownTableData) do
    --         local flag = false
    --         for i=1,countdownRowNum do
    --             local temp = recommended[tostring(i)]
    --             if (temp[self.IDKey] == k) then
    --                 flag = true
    --             end
    --         end
    --         if (not flag) then
    --             removeObjectFromTableByKey(countdownTableData, k)
    --         end
    --     end
    --     DataManager:getInstance():setRoleData(roleChargingData, countdownTableData, nil)
    -- end

    
    local scrollViewDidScroll = function ()
        -- cclog("scrollView滑动ing")
    end

    local gapBottom = 60

    -- 滚动图片
    local banner = cc.Sprite:create("Images/charging/banner_01.png")

    local num = countdownRowNum

    local temp = cc.Sprite:create("Images/charging/banner_01.png")

    local pageView = self:getChildByTag(1)
    if (pageView ~= nil) then
        pageView:removeFromParent()
    end

    pageView = ccui.PageView:create()

    pageView:setTag(1)
    pageView:setSize(temp:getContentSize())
    pageView:setPosition(cc.p(self.s_position.x - temp:getContentSize().width * 0.5, self.s_position.y + self.s_size.height * 0.5 - temp:getContentSize().height - 120))
    self:addChild(pageView)

    pageView:addEventListenerPageView(function (sender, eventType)
    	-- body
    	-- if eventType == ccui.PageViewEventType.turning then
        local pageViewTemp = sender
        local pageIndexTemp = pageViewTemp:getCurPageIndex() + 1
        self:clearPoint(self.pageIndex)
        self.pageIndex = tonumber(pageIndexTemp)
        -- print("======= pageIndex", self.pageIndex)
        self:moveToPoint(self.pageIndex)

        local chargingTableData = DataManager:getInstance():getRoleData(roleChargingData)
        local limitRecommendedTemp = chargingTableData[self.LimitRecommendedKey]
        if (limitRecommendedTemp ~= nil) then
            local tmepNum = getTableRowNum(limitRecommendedTemp)

            local arrowLTemp = self:getChildByTag(101)
            if (self.pageIndex > 1) then
                if (not arrowLTemp:isVisible()) then
                    arrowLTemp:setVisible(true)
                end
            else
                if (arrowLTemp:isVisible()) then
                    arrowLTemp:setVisible(false)
                end
            end


            local arrowRTemp = self:getChildByTag(102)
            if (self.pageIndex < tmepNum) then
                if (not arrowRTemp:isVisible()) then
                    arrowRTemp:setVisible(true)
                end
            else
                if (arrowRTemp:isVisible()) then
                    arrowRTemp:setVisible(false)
                end
            end
        end
        -- end
    end)

    local nowSecond = os.time()

    -- local countdownData = DataManager:getInstance():getRoleData(roleChargingData)
    for i=1,num do
        local tempTableData = recommended[tostring(i)]
        local layout = ccui.Layout:create()
        layout:setTag(i)
        layout:setSize(temp:getContentSize())

        local normalSprite = cc.Sprite:create("Images/charging/banner_01.png")
        local selectedSprite = cc.Sprite:create("Images/charging/banner_01.png")
        local menuItem = cc.MenuItemSprite:create(normalSprite, selectedSprite)
        menuItem:setTag(i)

        menuItem:registerScriptTapHandler(function (tag, menuItem)
            -- body
            local limitRecommendedTemp = chargingTableData[self.LimitRecommendedKey]
            
            local recommendedTemp = limitRecommendedTemp[tostring(tag)]
            -- 添加钻石
            local diamondNum = recommendedTemp[self.diamondKey]
            DataManager:getInstance():addDiamond(tonumber(diamondNum))

        -- print("======= 向右滑动")
        -- self:clearPoint(self.pageIndex)
        -- local limitRecommendedTemp = chargingTableData[self.LimitRecommendedKey]

        -- if (limitRecommendedTemp ~= nil) then
        -- 	local tmepNum = getTableRowNum(limitRecommendedTemp)
        -- 	if (self.pageIndex < tmepNum) then
        -- 		local tempPageView = self:getChildByTag(1)
        -- 		self.pageIndex = self.pageIndex + 1
        -- 		tempPageView:scrollToPage(self.pageIndex)
        -- 	end
        -- end
        -- self:moveToPoint(self.pageIndex)

        end)

        local menu = cc.Menu:create(menuItem)
        menu:setPosition(cc.p(layout:getSize().width * 0.5, layout:getSize().height * 0.5))
        layout:addChild(menu, 1)
        menu:setTag(1)

        pageView:addPage(layout)

        local doubleSpr = cc.Sprite:create("Images/charging/banner_02.png")
        doubleSpr:setPosition(cc.p(doubleSpr:getContentSize().width * 0.5, menuItem:getContentSize().height - doubleSpr:getContentSize().height * 0.5))
        menuItem:addChild(doubleSpr)

        local limitRecommended = cc.LabelTTF:create("限时推荐", BoldFont, 33.0)
        limitRecommended:setAnchorPoint(cc.p(0.0, 0.5))
        limitRecommended:setColor(YellowColor)
        limitRecommended:setPosition(cc.p(menuItem:getContentSize().width * 0.5, menuItem:getContentSize().height - 33))
        menuItem:addChild(limitRecommended)

        
        local countdownTemp = self:getSurplusSecond(nowSecond, tempTableData[self.countdownKey])
        local surplus = cc.LabelTTF:create("剩余：" .. getTimeStr(countdownTemp), BoldFont, 25.0)
        surplus:setTag(100)
        surplus:setAnchorPoint(cc.p(0.0, 0.5))
        surplus:setColor(WriteColor)
        surplus:setPosition(cc.p(limitRecommended:getPositionX(), limitRecommended:getPositionY() - 35))
        menuItem:addChild(surplus)

        if (tempTableData[self.countdownKey] < 0) then
            surplus:setString("")
        end

        local diamondSpr = cc.Sprite:create("Images/UI/DiamondBg.png")
        diamondSpr:setPosition(cc.p(surplus:getPositionX() + 40, surplus:getPositionY() - 50))
        menuItem:addChild(diamondSpr)

        local numSpr = cc.LabelTTF:create(tostring(tempTableData[self.diamondKey]), BoldFont, 33.0)
        numSpr:setAnchorPoint(cc.p(0.0, 0.5))
        numSpr:setColor(WriteColor)
        numSpr:setPosition(cc.p(diamondSpr:getPositionX() + diamondSpr:getContentSize().width * 0.5 + 2, diamondSpr:getPositionY()))
        menuItem:addChild(numSpr)

        local onlySell = cc.LabelTTF:create("仅售", BoldFont, 25.0)
        onlySell:setAnchorPoint(cc.p(0.0, 0.5))
        onlySell:setColor(WriteColor)
        onlySell:setPosition(cc.p(diamondSpr:getPositionX() + 50, 25))
        menuItem:addChild(onlySell)

        local surplusNum = cc.LabelTTF:create(tostring(tempTableData[self.moneyKey]), BoldFont, 50.0)
        surplusNum:setAnchorPoint(cc.p(0.0, 0.5))
        surplusNum:setColor(Khaki)
        surplusNum:setPosition(cc.p(onlySell:getPositionX() + onlySell:getContentSize().width, onlySell:getPositionY() + (surplusNum:getContentSize().height - onlySell:getContentSize().height) * 0.5))
        menuItem:addChild(surplusNum)
    end

    -- 箭头
-- <<<<<<< .mine
--     local leftNormalBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
--     local leftSelectedBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
--     leftNormalBtn:setFlippedX(true)
--     leftSelectedBtn:setFlippedX(true)
--     local arrowL = cc.MenuItemSprite:create(leftNormalBtn, leftSelectedBtn)
--     arrowL:setTag(1)
--     arrowL:registerScriptTapHandler(function ()
-- =======
    -- local leftNormalBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    -- local leftSelectedBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    -- leftNormalBtn:setFlippedX(true)
    -- leftSelectedBtn:setFlippedX(true)

    if (self:getChildByTag(101) ~= nil) then
        self:getChildByTag(101):removeFromParent()
    end
    if (self:getChildByTag(102) ~= nil) then
        self:getChildByTag(102):removeFromParent()
    end


    local arrowL = SDButton:create("Images/charging/jiantou_04.png", "Images/charging/jiantou_04.png",function ()
-- >>>>>>> .r1881
        -- body
        print("======= 向左滑动")

        self:clearPoint(self.pageIndex)
        if (self.pageIndex > 1) then
            local tempPageView = self:getChildByTag(1)
            self.pageIndex = self.pageIndex - 1
            tempPageView:scrollToPage(self.pageIndex - 1)
        end
        self:moveToPoint(self.pageIndex)

        local chargingTableData = DataManager:getInstance():getRoleData(roleChargingData)
        local limitRecommendedTemp = chargingTableData[self.LimitRecommendedKey]
        if (limitRecommendedTemp ~= nil) then
            local tmepNum = getTableRowNum(limitRecommendedTemp)

            local arrowLTemp = self:getChildByTag(101)
            if (not arrowLTemp:isVisible()) then
                arrowLTemp:setVisible(true)
            end

            local arrowRTemp = self:getChildByTag(102)
            if (self.pageIndex < tmepNum) then
                if (not arrowRTemp:isVisible()) then
                    arrowRTemp:setVisible(true)
                end
            else
                if (arrowRTemp:isVisible()) then
                    arrowRTemp:setVisible(false)
                end
            end
        end
    end)
    arrowL:addClickArea(cc.rect(-20, 20, 100, 40))
    arrowL:setFlippedX(true)
    arrowL:setPosition(cc.p(self.s_position.x - temp:getContentSize().width * 0.5 - 25, self.s_position.y + self.s_size.height * 0.5 - temp:getContentSize().height * 0.5 - 120))
    
    arrowL:setTag(101)

    local arrowR = SDButton:create("Images/charging/jiantou_04.png", "Images/charging/jiantou_04.png",function ()
        -- body
        print("======= 向右滑动")

        self:clearPoint(self.pageIndex)
        local chargingTableData = DataManager:getInstance():getRoleData(roleChargingData)
        local limitRecommendedTemp = chargingTableData[self.LimitRecommendedKey]

        if (limitRecommendedTemp ~= nil) then
            local tmepNum = getTableRowNum(limitRecommendedTemp)
            if (self.pageIndex < tmepNum) then
                local tempPageView = self:getChildByTag(1)
                self.pageIndex = self.pageIndex + 1
                tempPageView:scrollToPage(self.pageIndex - 1)
            end

            local arrowLTemp = self:getChildByTag(101)
            if (self.pageIndex > 1) then
                if (not arrowLTemp:isVisible()) then
                    arrowLTemp:setVisible(true)
                end
            else
                if (arrowLTemp:isVisible()) then
                    arrowLTemp:setVisible(false)
                end
            end

            local arrowRTemp = self:getChildByTag(102)
            if (not arrowRTemp:isVisible()) then
                arrowRTemp:setVisible(true)
            end

        end
        self:moveToPoint(self.pageIndex)
    end)
    -- arrowL:setFlippedX(true)
    arrowR:addClickArea(cc.rect(-20, 20, 100, 40))
    arrowR:setPosition(cc.p(self.s_position.x + temp:getContentSize().width * 0.5 + 25, self.s_position.y + self.s_size.height * 0.5 - temp:getContentSize().height * 0.5 - 120))
    
    arrowR:setTag(102)

    if (num > 1) then
        self:addChild(arrowL, 100)
        self:addChild(arrowR, 100)
        arrowL:setVisible(false)
    end

    -- 滚动图片下方小点
    for i=1,#self.pointArr do
    	self.pointArr[i]:removeFromParent()
    	self.pointArr[i] = nil
    end
    local gapPointH = 30
    local pointBaseX = self.s_position.x - ((num - 1) * gapPointH) * 0.5
    for i=1,num do
    	local pointerOne = cc.Sprite:create("Images/UI/dian_a.png")
    	pointerOne:setPosition(cc.p(pointBaseX + (i - 1) * gapPointH, pageView:getPositionY() - 12))
    	pointerOne:setTag(10 + i)
    	self:addChild(pointerOne)
    	self.pointArr[i] = pointerOne
    end

    -- local pointerOne = cc.Sprite:create("Images/UI/dian_a.png")
    -- pointerOne:setPosition(cc.p(self.s_position.x - 30, pageView:getPositionY() - 12))
    -- self:addChild(pointerOne)

    -- local pointerTwo= cc.Sprite:create("Images/UI/dian_a.png")
    -- pointerTwo:setPosition(cc.p(pointerOne:getPositionX() + 30, pointerOne:getPositionY()))
    -- self:addChild(pointerTwo)

    -- local pointerThree = cc.Sprite:create("Images/UI/dian_a.png")
    -- pointerThree:setPosition(cc.p(pointerTwo:getPositionX() + 30, pointerOne:getPositionY()))
    -- self:addChild(pointerThree)

    -- 纵向scrollview

    -- 钻石商店物品
    local scrollViewSize = cc.size(self.s_size.width, self.s_size.height - 140 - temp:getContentSize().height - 45)
    local scrollViewContainer = cc.Layer:create()

    local scrollView = self:getChildByTag(3)

    if (scrollView ~= nil) then
    	scrollView:removeFromParent()
    end

    scrollView = cc.ScrollView:create(scrollViewSize)

    scrollView:setPosition(cc.p(self.s_position.x - self.s_size.width * 0.5, self.s_position.y - self.s_size.height * 0.5 + 40))
    scrollView:setContainer(scrollViewContainer) -- 設置容器
    scrollViewContainer:setPosition(cc.p(0.0, 0.0))
    scrollView:setClippingToBounds(true) -- 設置剪切
    scrollView:setBounceable(true)  -- 設置彈性效果
    scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    scrollView:setDelegate()
    scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(scrollView)
    scrollView:setTag(3)
        
    -- local index = 0
    -- 行数
    local goodsNum = getTableRowNum(goodsInfo)
    local col = 2
    local row = math.ceil(goodsNum / col)
    local tempGoods = cc.Sprite:create("Images/charging/kuang_10.png")
    local rowHeight = 1
    local gapV = 5
    local gapH = 10

    local baseXL = scrollViewSize.width * 0.5 - gapH * 0.5 - tempGoods:getContentSize().width * 0.5
    local baseXR = scrollViewSize.width * 0.5 + gapH * 0.5 + tempGoods:getContentSize().width * 0.5

    local tempTotalHeight = (tempGoods:getContentSize().height + gapV) * row - gapV

    if (tempTotalHeight < scrollViewSize.height) then
        tempTotalHeight = scrollViewSize.height
    end

    local baseY = tempTotalHeight - tempGoods:getContentSize().height * 0.5
    local baseItemHeight = tempGoods:getContentSize().height + gapV

    for i=1,row do
        for j=1,col do
            index = (i - 1) * col + j
            if (index <= goodsNum) then
                local tempTableData = goodsInfo[tostring(index)]

                local normalSprite = cc.Sprite:create("Images/charging/kuang_10.png")
                local selectedSprite = cc.Sprite:create("Images/charging/kuang_10.png")
                local item = cc.MenuItemSprite:create(normalSprite, selectedSprite)
                item:setTag(index)
                item:registerScriptTapHandler(function (tag, menuItem)
                    -- body
                    local goodsInfoTemp = chargingTableData[self.GoodsInfoKey]
                    local goodsTemp = goodsInfoTemp[tostring(tag)]
                    -- 添加钻石
                    local diamondNum = goodsTemp[self.diamondKey] + goodsTemp[self.extraDiamondKey]
                    DataManager:getInstance():addDiamond(tonumber(diamondNum))
                end)

                local menu = cc.Menu:create(item)

                if (j == 1) then
                    menu:setPosition(cc.p(baseXL, baseY - (i - 1) * baseItemHeight))
                else
                    menu:setPosition(cc.p(baseXR, baseY - (i - 1) * baseItemHeight))
                end
                menu:setTag(1)

                local littleDiamondName = nil
                local buyDiamodNum = "钻石x" .. tempTableData[self.diamondKey]
                local needMoney = tempTableData[self.moneyKey] .. "元"
                local extraNum = tempTableData[self.extraDiamondKey]
                local diamondNum = tempTableData[self.diamondKey] + tempTableData[self.extraDiamondKey]
                index = index % 4

                if (index == 0) then
                    littleDiamondName = "Images/charging/tubiao_01.png"
                    -- buyDiamodNum = "钻石x80"
                    -- needMoney = "8元"
                    -- extraNum = 8
                    -- diamondNum = 88
                elseif (index == 1) then
                    littleDiamondName = "Images/charging/tubiao_02.png"
                    -- buyDiamodNum = "钻石x160"
                    -- needMoney = "16元"
                    -- extraNum = 16
                    -- diamondNum = 176
                elseif (index == 2) then
                    littleDiamondName = "Images/charging/tubiao_03.png"
                    -- buyDiamodNum = "钻石x200"
                    -- needMoney = "20元"
                    -- extraNum = 20
                    -- diamondNum = 220
                elseif (index == 3) then
                    littleDiamondName = "Images/charging/tubiao_04.png"
                    -- buyDiamodNum = "钻石x300"
                    -- needMoney = "30元"
                    -- extraNum = 30
                    -- diamondNum = 330
                end

                -- item:setTag(diamondNum)

                local littleDiamondSpr = cc.Sprite:create(littleDiamondName)
                littleDiamondSpr:setPosition(cc.p(65.0, 90.0))
                item:addChild(littleDiamondSpr)

                local buyDiamodNumSpr = cc.LabelTTF:create(buyDiamodNum, BoldFont, 30.0)
                buyDiamodNumSpr:setAnchorPoint(cc.p(0.0, 0.5))
                buyDiamodNumSpr:setColor(Khaki)
                buyDiamodNumSpr:setPosition(cc.p(item:getContentSize().width * 0.5 - 20, 110))
                item:addChild(buyDiamodNumSpr)

                local needMoneySpr = cc.LabelTTF:create(needMoney, BoldFont, 26.0)
                needMoneySpr:setAnchorPoint(cc.p(0.0, 0.5))
                needMoneySpr:setColor(WriteColor)
                needMoneySpr:setPosition(cc.p(buyDiamodNumSpr:getPositionX(), buyDiamodNumSpr:getPositionY() - 33))
                item:addChild(needMoneySpr)

                local extraNumSprPre = cc.LabelTTF:create("额外赠送", BoldFont, 26.0)
                extraNumSprPre:setAnchorPoint(cc.p(0.0, 0.5))
                extraNumSprPre:setColor(WriteColor)
                extraNumSprPre:setPosition(cc.p(30.0, 14.0))
                item:addChild(extraNumSprPre)

                local extraNumSpr = cc.LabelTTF:create(extraNum, BoldFont, 26.0)
                extraNumSpr:setColor(Khaki)
                extraNumSpr:setPosition(cc.p(extraNumSprPre:getPositionX() + extraNumSprPre:getContentSize().width + 20, extraNumSprPre:getPositionY()))
                item:addChild(extraNumSpr)

                local extraNumSprNext = cc.LabelTTF:create("钻", BoldFont, 26.0)
                extraNumSprNext:setAnchorPoint(cc.p(0.0, 0.5))
                extraNumSprNext:setColor(WriteColor)
                extraNumSprNext:setPosition(cc.p(extraNumSpr:getPositionX() + 20, extraNumSprPre:getPositionY()))
                item:addChild(extraNumSprNext)

                scrollViewContainer:addChild(menu)
            else
                break
            end
        end
    end
        
    scrollViewContainer:setContentSize(cc.size(scrollViewSize.width, tempTotalHeight))
    scrollView:setContentOffset(cc.p(0, -(tempTotalHeight - scrollView:getViewSize().height)))

    self:moveToPoint(self.pageIndex)

function updateCountdown(delta)
	

	local nowSecond = os.time()

	local pageViewTemp = self:getChildByTag(1)
	if (pageViewTemp ~= nil) then
		local chargingTableDataTemp = DataManager:getInstance():getRoleData(roleChargingData)

    	local recommended = chargingTableDataTemp[self.LimitRecommendedKey]

    	local num = getTableRowNum(recommended)

    	local deltaTime = delta * 1000

        local removeIndexArr = {}
        local refreshFlag = false
		for i=1,num do
			local layoutTemp = pageViewTemp:getChildByTag(i)
			local menu = layoutTemp:getChildByTag(1)

			local menuItem = menu:getChildByTag(i)

			local surplus = menuItem:getChildByTag(100)

			local tempTableData = recommended[tostring(i)]

			local countdownTemp = tempTableData[self.countdownKey]

            if (countdownTemp > 0) then

                tempTableData[self.countdownKey] = countdownTemp

                if ((countdownTemp - nowSecond) > 0) then
                    surplus:setString("剩余：" .. getTimeStr(self:getSurplusSecond(nowSecond, countdownTemp)))
                else
                    if (not refreshFlag) then
                        refreshFlag = true
                    end
                    removeIndexArr[#removeIndexArr + 1] = i
                end
            end
		end

        for i=#removeIndexArr,1,-1 do
            removeObjectFromTableByIKeyStr(recommended, removeIndexArr[i])
        end

		DataManager:getInstance():setRoleData(roleChargingData, chargingTableDataTemp, nil)

		if (refreshFlag) then
			self:loadData(nil)
		end

		-- if (refreshFlag) then
		-- 	local recommended = {}
  --       	for i=1,7 do
  --           	local temp = {}
  --           	temp["ID"] = tostring(1000 + i)
  --           	temp["diamond"] = 20 * i
  --           	temp["money"] = 10 * i
  --           	-- temp["extraDiamod"] = i * 5
  --           	temp["countdown"] = 4000 * i
  --           	recommended[tostring(i)] = temp
  --       	end

  --       	local goodsInfo = {}
  --       	for i=1,10 do
  --            	local temp = {}
  --            	temp["ID"] = tostring(2001 + i)
  --            	temp["diamond"] = 30 * i
  --            	temp["money"] = 40 * i
  --            	temp["extraDiamond"] = 50 * i
  --           	goodsInfo[tostring(i)] = temp
  --       	end

  --       	local tableData = {}
  --       	tableData["1"] = recommended
  --       	tableData["2"] = goodsInfo

		-- 	self:loadData(tableData)
		-- end

	end
end
    self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(updateCountdown, 1, false)

end

function ChargingView:clearPoint(index)
	-- body
    local pointSpr = self:getChildByTag(index + 10)
	if (pointSpr ~= nil) then
		local tempSpr = cc.Sprite:create("Images/UI/dian_a.png")
    	pointSpr:setSpriteFrame(tempSpr:getSpriteFrame())
	end
end

function ChargingView:moveToPoint(index)
	-- body
	local pointSpr = self:getChildByTag(index + 10)
	if (pointSpr ~= nil) then
		local tempSpr = cc.Sprite:create("Images/UI/dian_b.png")
    	pointSpr:setSpriteFrame(tempSpr:getSpriteFrame())
	end
end

-- function ChargingView:countdownUpdate(delta)
-- 	local pageViewTemp = self:getChildByTag(1)
-- 	if (pageViewTemp ~= nil) then
-- 		local countdownData = DataManager:getInstance():getRoleData(roleChargingData)
-- 		local num = getTableRowNum(countdownTemp)

--     	local recommended = chargingTableData[self.LimitRecommendedKey]

--     	local deltaTime = delta * 1000
--     	local refreshFlag = false

-- 		for i=1,num do
-- 			local layout = pageViewTemp:getChildByTag(i)
-- 			local menuItem = layout:getChildByTag(i)
-- 			local surplus = menuItem:getChildByTag(1)

-- 			local tempTableData = recommended[tostring(i)]

-- 			local countdownTemp = countdownData[tempTableData[self.IDKey]]

-- 			countdownTemp = math.ceil(countdownTemp - deltaTime)

-- 			if (countdownTemp > 0) then
-- 				surplus:setString("剩余：" .. countdownTemp)
-- 			else
-- 				if (not refreshFlag) then
-- 					refreshFlag = true
-- 				end
-- 			end
-- 		end

-- 		if (refreshFlag) then
-- 			local recommended = {}
--         	for i=1,7 do
--             	local temp = {}
--             	temp["ID"] = tostring(1000 + i)
--             	temp["diamond"] = 20 * i
--             	temp["money"] = 10 * i
--             	-- temp["extraDiamod"] = i * 5
--             	temp["countdown"] = 4000 * i
--             	recommended[tostring(i)] = temp
--         	end

--         	local goodsInfo = {}
--         	for i=1,10 do
--              	local temp = {}
--              	temp["ID"] = tostring(2001 + i)
--              	temp["diamond"] = 30 * i
--              	temp["money"] = 40 * i
--              	temp["extraDiamond"] = 50 * i
--             	goodsInfo[tostring(i)] = temp
--         	end

--         	local tableData = {}
--         	tableData["1"] = recommended
--         	tableData["2"] = goodsInfo

-- 			self:loadData(tableData)
-- 		end

-- 	end
-- end

function ChargingView:getSurplusSecond(nowSecond, expiredSecond)
	-- body
	return (expiredSecond - nowSecond)
end