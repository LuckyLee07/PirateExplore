require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/ChargeMode"
require "LuaClass/CCall"
require "LuaClass/DialogueView"


DiamondStore = class("DiamondStore", function ()
    return BaseView:create()
end)
DiamondStore.__index = DiamondStore

DiamondStore.LimitRecommendedKey = "1"
DiamondStore.GoodsInfoKey = "2"
DiamondStore.countdownKey = "countdown"
-- DiamondStore.IDKey = "ID"
DiamondStore.diamondKey = "diamond"
DiamondStore.moneyKey = "money"
DiamondStore.extraDiamondKey = "extraDiamond"
DiamondStore.goodsName = "goodsName"
DiamondStore.pageIndex = 1
DiamondStore.pointArr = nil
DiamondStore.schduler = nil
DiamondStore.s_position = nil
DiamondStore.s_size = nil
DiamondStore.s_size = nil
DiamondStore.recommendedData = nil
DiamondStore.goodsData = nil
DiamondStore.goodsShowData = nil

function DiamondStore:create()
    local view = DiamondStore.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- 清理函数
function DiamondStore:destory()
    if (self.schduler ~= nil) then
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
    	self.schduler = nil
    end

    DataManager:getInstance():unregisterEvent("DiamondStoreUIReload", "DiamondStore")
end

function DiamondStore:init()
    -- DataManager:getInstance():diamondStoreBuySomethingSuccess(5)

	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    
    if DataManager:getInstance():isShowDiamondStoreRedPointer() then
        DataManager:getInstance():setShowDiamondStoreRedPointer(false)
        DataManager:getInstance():resetShowDiamondStoreRedPointer()
        local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
        if (tempData == nil) then
            tempData = {}
            tempData.mapIndex = 1
        end
        DataManager:getInstance():setRoleData(roleMapInfo, tempData)
    end

    -- 设置title文字
    self:setTitleString("钻石商城")

    -- 隐藏上边左侧的按钮
    self.topLeftBtn:setVisible(false)

    -- 修改右侧按钮为返回
    self:resetTopRightButtonToBack()

    if (DataManager:getInstance():getRoleData(roleDiamondStoreData) ~= nil) then
        local diamondStoreData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
        self.recommendedData = diamondStoreData["1"]
        self.goodsData = diamondStoreData["2"]
    else
        self.recommendedData = {}
        local recommendedDataTemp = DataManager:getInstance():getCSVByID(csvOfShopGift)
        local recommendedDataTempNum = getTableRowNum(recommendedDataTemp)
        
        local time = os.time()
        for i=1,recommendedDataTempNum do
            local key = tostring(i)
            local tempValue = recommendedDataTemp[key]
            if (tonumber(tempValue[dataKeyDisplay]) == 1) then
                local giftTemp = {}
                giftTemp[1] = tempValue[dataKeyID]

                if (tonumber(tempValue[dataKeyTime]) > 0) then
                    giftTemp[2] = time + tonumber(tempValue[dataKeyTime]) * 3600
                else
                    giftTemp[2] = tonumber(tempValue[dataKeyTime])
                end
                giftTemp[3] = 0

                self.recommendedData[#self.recommendedData + 1] = giftTemp
            end
        end
        
        local mapLevel = 0
        local mapInfo = DataManager:getInstance():getRoleData(roleMapInfo)
    
        if (mapInfo == nil) then
            mapLevel = 1
        else
            if (mapInfo.mapIndex == nil) then
                mapLevel = 1
            else
                mapLevel = mapInfo.mapIndex
            end
        end

        self.goodsData = {}
        local goodsDataTemp = DataManager:getInstance():getCSVByID(csvOfShopItem)
        local goodsDataTempNum = getTableRowNum(goodsDataTemp)
        for i=1,goodsDataTempNum do
            local key = tostring(i)
            local tempValue = goodsDataTemp[key]
            if (tonumber(tempValue[dataKeyDisplay]) == 1) then
                local temp = {}
                temp[1] = tempValue[dataKeyID]

                if (tonumber(mapLevel) >= tonumber(tempValue[dataKeyUnlock])) then
                    temp[2] = 0
                else
                    temp[2] = 2
                end

                self.goodsData[#self.goodsData + 1] = temp
            end
        end
    end



    for i=1,#self.goodsData do
        if (self.goodsData[i][2] == 4) then
            self.goodsData[i][2] = 0
        end
        
    end

    local pngname = "Images/UI/tankuang_01.png"
    local background = cc.Sprite:create(pngname)
    self.s_size = background:getContentSize()

    self.s_position = cc.p(visibleSize.width * 0.5, visibleSize.height * 0.55)

    self.pageIndex = 1
    self.pointArr = {}

    local tableData = {}
    tableData["1"] = self.recommendedData
    tableData["2"] = self.goodsData

    self:loadData(tableData)

    DataManager:getInstance():registerEvent("DiamondStoreUIReload", "DiamondStore", function (event)
        -- body
        self:buyGigtUIRefresh(event)
        -- self:checkAndstepNextGift(event)
    end)

	return true
end

function DiamondStore:buyGigtUIRefresh(event)
    -- body
    local function refreshUI()
        -- body
        self:loadData(nil)
    end
    self:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(refreshUI)))
    
end

function DiamondStore:loadData(storeData)
    -- body
    self.pageIndex = 1
    if (storeData ~= nil) then
        DataManager:getInstance():setRoleData(roleDiamondStoreData, storeData, nil)
    end

    if (self.schduler ~= nil) then
        -- self:destory()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
        self.schduler = nil
    end

    local mapLevel = 0
    local mapInfo = DataManager:getInstance():getRoleData(roleMapInfo)
    
    if (mapInfo == nil) then
        mapLevel = 1
    else
        if (mapInfo.mapIndex == nil) then
            mapLevel = 1
        else
            mapLevel = mapInfo.mapIndex
        end
    end

    -- mapLevel = 2

    local recommendedDataTemp = DataManager:getInstance():getCSVByID(csvOfShopGift)
    local goodsDataTemp = DataManager:getInstance():getCSVByID(csvOfShopItem)

    -- 钻石商店数据
    local storeTableData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
    -- 钻石商店上方推荐物品信息
    local limitRecommended = storeTableData[self.LimitRecommendedKey]
    self.recommendedData = limitRecommended
    -- 钻石商店下方物品信息
    -- local goodsInfo = storeTableData[self.GoodsInfoKey]
    local goodsInfo = {}
    local tmp = storeTableData[self.GoodsInfoKey]

    -- printn("storeTableData[self.GoodsInfoKey]", tmp)

    local tmpNum = getTableRowNum(tmp)
    local resaveFlag = false

    self.goodsShowData = nil
    self.goodsShowData = {}

    local buyedGoodItem = DataManager:getInstance():getRoleData(roleMapBuyItems)

    for i=1,tmpNum do
        local flag = tmp[i][2]
        local goodItemID = tmp[i][1]
        -- print("flag and goodItemID:", flag, goodItemID)

        if (flag == 2) then
            local tempValue = goodsDataTemp[goodItemID]

            if (tonumber(tempValue[dataKeyDisplay]) == 1) then

                if (tonumber(mapLevel) >= tonumber(tempValue[dataKeyUnlock])) then
                    goodsInfo[#goodsInfo + 1] = tmp[i]
                    self.goodsShowData[#goodsInfo] = i

                    tmp[i][2] = 4  -- 新添加物品
                    if (buyedGoodItem ~= nil) then
                        for j=1,#buyedGoodItem do
                            local buyedGOodItemId = buyedGoodItem[j]
                            if (buyedGOodItemId == goodItemID) then
                                tmp[i][2] = 1
                                break
                            end
                        end
                    end
                    
                    if (not resaveFlag) then
                        resaveFlag = true
                    end
                end
            end
        else
            if (buyedGoodItem ~= nil) then
                for j=1,#buyedGoodItem do
                    local buyedGOodItemId = buyedGoodItem[j]
                    if (buyedGOodItemId == goodItemID) then
                        tmp[i][2] = 1
                        if (not resaveFlag) then
                            resaveFlag = true
                        end
                        break
                    end
                end
            end

            goodsInfo[#goodsInfo + 1] = tmp[i]
            self.goodsShowData[#goodsInfo] = i
        end
    end
    
    if (resaveFlag) then
        self.goodsData = tmp
        storeTableData[self.GoodsInfoKey] = tmp
        printn(storeTableData)
        DataManager:getInstance():setRoleData(roleDiamondStoreData, storeTableData, nil)
    end

    DataManager:getInstance():setRoleData(roleMapBuyItems, nil, nil) 

    local num = getTableRowNum(limitRecommended)

    local scrollViewDidScroll = function ()
        -- cclog("scrollView滑动ing")
    end

    local gapBottom = 60

    -- 滚动图片
    local banner = cc.Sprite:create("Images/DiamondStore/banner_02.png")

    local temp = cc.Sprite:create("Images/DiamondStore/banner_04.png")

    local pageSize = cc.size(banner:getContentSize().width, banner:getContentSize().height + temp:getContentSize().height * 0.5)

    -- local scrollViewSize = cc.size(self.areaWidth, self.areaHeight)
    -- self.scrollViewContainer = cc.Layer:create()
    -- self.scrollView = cc.ScrollView:create(scrollViewSize)

    local pageView = self:getChildByTag(1)
    if (pageView ~= nil) then
        pageView:removeFromParent()
    end

    pageView = ccui.PageView:create()
    pageView:setTouchEnabled(false)

    pageView:setTag(1)
    pageView:setSize(pageSize)
    
    pageView:setPosition(cc.p(self.originPos.x + self.areaWidth * 0.5 - pageSize.width * 0.5, self.originPos.y + self.areaHeight - pageSize.height * 0.5 - 150))
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
        -- end
    end)

    local nowSecond = os.time()

    -- 上方推荐物品信息
    for i=1,num do
        -- 推荐物品信息
        local tempTableData = recommendedDataTemp[limitRecommended[i][1]]
        if tempTableData ~= nil then
            
            local layout = ccui.Layout:create()
            layout:setTag(i)
            layout:setSize(pageSize)

            local normalSprite = cc.Sprite:create("Images/DiamondStore/banner_02.png")
            local selectedSprite = cc.Sprite:create("Images/DiamondStore/banner_02.png")
            local menuItem = cc.MenuItemSprite:create(normalSprite, selectedSprite)
            menuItem:setTag(i)

            menuItem:registerScriptTapHandler(function (tag, menuItem)
                -- 然后弹窗提示玩家获得的东西
                local goodsDataFromCSV = DataManager:getInstance():getCSVByID(csvOfShopItem)
                local giftId = self.recommendedData[tag][1]
                local pushGiftCsv = DataManager:getInstance():getCSVByID(csvOfPushGift)
                local pushData = pushGiftCsv[giftId]
                local alertContent = ""
                if pushData ~= nil then
                    alertContent = alertContent .. "购买 “"..pushData["name"].."“ 您将获得：\n\n"
                    if pushData["desc"] ~= nil then
                        for i = 1, #pushData["desc"] do
                            alertContent = alertContent .. pushData["desc"][i][1] .. "\n"
                        end
                    end
                end
                local _alert = AlertView:create(2, 0, "礼 包 详 情", function()
                    -- body
                    local giftCSV = DataManager:getInstance():getCSVByID(csvOfShopGift)
                    local giftData = giftCSV[giftId]
                    -- DataManager:getInstance():diamondStoreBuySomethingSuccess(giftData[dataKeyPayType])

                    purchase(giftData[dataKeyPayType])
                    print("购买礼包---------",giftId)
                end, nil, "取 消", "购 买")
                -- print("_alert inited")
                local showLabel1 = cc.LabelTTF:create(alertContent, BoldFont, 30)
                showLabel1:setColor(cc.c3b(255, 255, 255))
                showLabel1:setDimensions(cc.size(0, 800))
                showLabel1:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
                showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y))
                _alert:addChild(showLabel1)
            end)

            local menu = cc.Menu:create(menuItem)
            menu:setPosition(cc.p(layout:getContentSize().width * 0.5, banner:getContentSize().height * 0.5))
            layout:addChild(menu, 1)
            menu:setTag(1)

            pageView:addPage(layout)

            local recommended = cc.Sprite:create("Images/DiamondStore/banner_04.png")
            recommended:setPosition(cc.p(recommended:getContentSize().width * 0.5 - 10, menuItem:getContentSize().height - recommended:getContentSize().height * 0.5 + 28))
            menuItem:addChild(recommended)

            local titleBar = cc.LabelTTF:create(tempTableData[dataKeyName], BoldFont, 38.0)
            titleBar:setColor(WriteColor)
            titleBar:setPosition(cc.p(pageSize.width * 0.5, menuItem:getContentSize().height - titleBar:getContentSize().height * 0.5 - 2))
            menuItem:addChild(titleBar)

            local titleLable = cc.LabelTTF:create("礼包内包含：", BoldFont, 24.0)
            titleLable:setAnchorPoint(cc.p(0.0, 0.5))
            titleLable:setColor(WriteColor)
            titleLable:setPosition(cc.p(recommended:getContentSize().width * 0.5 + 20, recommended:getPositionY() - recommended:getContentSize().height * 0.5 + 3))
            menuItem:addChild(titleLable)

            local itemData = tempTableData[dataKeyItem]
            local num = #itemData
            local baseX = titleLable:getPositionX()
            local baseY = titleLable:getPositionY() - 30
            for i=1,num do
                local goodInfoID = itemData[i][1]
                local goodInfoNum = itemData[i][2]
                local goodInfoData = goodsDataTemp[goodInfoID]
                local goodInfo= cc.LabelTTF:create(goodInfoData[dataKeyName] .. "：" .. tempTableData[dataKeyDesc][i], BoldFont, 20)
                goodInfo:setAnchorPoint(cc.p(0.0, 0.5))
                goodInfo:setPosition(cc.p(baseX, baseY - (i - 1) * (goodInfo:getContentSize().height)))
                menuItem:addChild(goodInfo)
            end

            local sellPre = cc.LabelTTF:create("仅售", BoldFont, 30.0)
            sellPre:setAnchorPoint(cc.p(0.0, 0.0))
            sellPre:setColor(WriteColor)
            sellPre:setPosition(cc.p(layout:getContentSize().width - 140, titleBar:getPositionY() - titleBar:getContentSize().height + 10))
            menuItem:addChild(sellPre)

            local sellNum = cc.LabelTTF:create(tempTableData[dataKeyPrice], BoldFont, 43)
            sellNum:setAnchorPoint(cc.p(0.0, 0.0))
            sellNum:setColor(YellowColor)
            sellNum:setPosition(cc.p(sellPre:getPositionX() + sellPre:getContentSize().width, sellPre:getPositionY()))
            menuItem:addChild(sellNum)

            local sellUnit = cc.LabelTTF:create("元", BoldFont, 30.0)
            sellUnit:setAnchorPoint(cc.p(0.0, 0.0))
            sellUnit:setColor(YellowColor)
            sellUnit:setPosition(cc.p(sellNum:getPositionX() + sellNum:getContentSize().width, sellPre:getPositionY()))
            menuItem:addChild(sellUnit)

            if limitRecommended[i][2] > 0 then
                -- 倒计时
                local countdownTitle = cc.LabelTTF:create("倒计时:", BoldFont, 25.0)
                countdownTitle:setColor(WriteColor)
                countdownTitle:setAnchorPoint(cc.p(0.0, 0.5))
                countdownTitle:setPosition(cc.p(layout:getContentSize().width - 130, countdownTitle:getContentSize().height * 0.5 + 45))
                menuItem:addChild(countdownTitle)

                local countdownTemp = self:getSurplusSecond(nowSecond, limitRecommended[i][2])
                local surplus = cc.LabelTTF:create(getTimeStr(countdownTemp), BoldFont, 27.0)
                surplus:setTag(100)
                surplus:setAnchorPoint(cc.p(0.0, 0.5))
                surplus:setColor(YellowColor)
                surplus:setPosition(cc.p(countdownTitle:getPositionX(), countdownTitle:getPositionY() - 35))
                menuItem:addChild(surplus)
            end
            --[[
             if (limitRecommended[i][2] < 0) then
             surplus:setString("")
             end
             ]]--
            local buyFlag = cc.Sprite:create("Images/DiamondStore/banner_06.png")
            buyFlag:setPosition(cc.p(layout:getContentSize().width - 130 - buyFlag:getContentSize().width * 0.5, buyFlag:getContentSize().height * 0.5 + 2))
            menuItem:addChild(buyFlag)
            if (limitRecommended[i][3] == 1) then
                buyFlag:setVisible(true)
            else
                buyFlag:setVisible(false)
            end
        else
            local layout = ccui.Layout:create()
            layout:setTag(i)
            layout:setSize(pageSize)
            layout:setPosition(cc.p(layout:getContentSize().width * 0.5, banner:getContentSize().height * 0.5))
            pageView:addPage(layout)
            
            local preSprite = cc.Sprite:create("Images/DiamondStore/banner_02.png")
            preSprite:setPosition(cc.p(0, banner:getContentSize().height * 0.5))
            preSprite:setAnchorPoint(cc.p(0, 0.5))
            layout:addChild(preSprite, 1)
            
            local preLabel = cc.LabelTTF:create("礼包筹备中。。。", BoldFont, 38.0)
            preLabel:setPosition(cc.p(layout:getContentSize().width * 0.5, banner:getContentSize().height * 0.5))
            preLabel:setAnchorPoint(cc.p(0.5, 0.5))
            preLabel:setColor(WriteColor)
            layout:addChild(preLabel, 1)
        end
    end

    -- 箭头
    local leftNormalBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    local leftSelectedBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    leftNormalBtn:setFlippedX(true)
    leftSelectedBtn:setFlippedX(true)
    local arrowL = cc.MenuItemSprite:create(leftNormalBtn, leftSelectedBtn)
    arrowL:registerScriptTapHandler(function ()
        -- body
        print("======= 向左滑动")
        self:clearPoint(self.pageIndex)
        if (self.pageIndex > 1) then
            local tempPageView = self:getChildByTag(1)
            self.pageIndex = self.pageIndex - 1
            tempPageView:scrollToPage(self.pageIndex)
        end
        self:moveToPoint(self.pageIndex)
    end)
    arrowL:setPosition(cc.p(-pageSize.width * 0.5 - 15, 0))

    local rightNormalBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    local rightSelectedBtn = cc.Sprite:create("Images/charging/jiantou_04.png")
    local arrowR = cc.MenuItemSprite:create(rightNormalBtn, rightSelectedBtn)
    arrowR:registerScriptTapHandler(function ()
        -- body
        print("======= 向右滑动")
        self:clearPoint(self.pageIndex)
        local limitRecommendedTemp = storeTableData[self.LimitRecommendedKey]

        if (limitRecommendedTemp ~= nil) then
            local tmepNum = getTableRowNum(limitRecommendedTemp)
            if (self.pageIndex < tmepNum) then
                local tempPageView = self:getChildByTag(1)
                self.pageIndex = self.pageIndex + 1
                tempPageView:scrollToPage(self.pageIndex)
            end
        end
        self:moveToPoint(self.pageIndex)
    end)
    arrowR:setPosition(cc.p(pageSize.width * 0.5 + 15, 0))

    local arrows = self:getChildByTag(2)
    if (arrows ~= nil) then
        arrows:removeFromParent()
    end
    arrows = cc.Menu:create(arrowL, arrowR)
    arrows:setTag(2)
    arrows:setPosition(cc.p(self.originPos.x + self.areaWidth * 0.5, self.originPos.y + self.areaHeight - 170 - temp:getContentSize().height * 0.3))
	
    if (num > 1) then
        self:addChild(arrows, 100)
    end

    -- pageview上方充值按钮
    local normalSprite = cc.Sprite:create("Images/btn/ann03_a.png")
    local selectedSprite = cc.Sprite:create("Images/btn/ann03_b.png")
    local menuItem = cc.MenuItemSprite:create(normalSprite, selectedSprite)

    menuItem:registerScriptTapHandler(function (tag, menuItem)
        -- body
        print("========= 点击充值按钮")
        local time = os.time()
        local recommended = {}
        for i=1,5 do
            local temp = {}
            temp["ID"] = tostring(1000 + i)
            temp["diamond"] = 20 * i
            temp["money"] = 10 * i
            -- temp["extraDiamod"] = i * 5

            if (i > 1) then
                temp["countdown"] = time + 1000 * (i - 1) + 5
            else
                temp["countdown"] = time + 20 * i
            end
            
            recommended[tostring(i)] = temp
        end

        local goodsInfo = {}
        for i=1,10 do
             local temp = {}
             temp["ID"] = tostring(2001 + i)
             temp["diamond"] = 30 * i
             temp["money"] = 40 * i
             temp["extraDiamond"] = 50 * i
             goodsInfo[tostring(i)] = temp
        end

        local tableData = {}
        tableData["1"] = recommended
        tableData["2"] = goodsInfo
        -- ChargingView:create(tableData)
        ChargeLayer:create()
    end)

    local chargingStr = cc.LabelTTF:create("充 值", BoldFont, 38)
    chargingStr:setColor(WriteColor)
    chargingStr:setPosition(cc.p(menuItem:getContentSize().width * 0.5, menuItem:getContentSize().height * 0.5))
    menuItem:addChild(chargingStr)

    local menu = self:getChildByTag(4)
    if (menu ~= nil) then
        menu:removeFromParent()
    end
    menu = cc.Menu:create(menuItem)
    menu:setTag(4)
    menu:setPosition(cc.p(arrows:getPositionX() + banner:getContentSize().width * 0.5 - normalSprite:getContentSize().width * 0.5 + 15, pageView:getPositionY() + pageView:getContentSize().height + 5))
    self:addChild(menu, 100)

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

    -- 纵向scrollview

    -- 钻石商店物品
    local scrollViewSize = cc.size(pageSize.width, self.areaHeight - pageSize.height * 0.5 - 150 - 12 - 30)
    local scrollViewContainer = cc.Layer:create()

    local scrollView = self:getChildByTag(3)

    if (scrollView ~= nil) then
        scrollView:removeFromParent()
    end

    scrollView = cc.ScrollView:create(scrollViewSize)

    scrollView:setPosition(cc.p(self.originPos.x + self.areaWidth * 0.5 - pageSize.width * 0.5, self.originPos.y + 10))
    scrollView:setContainer(scrollViewContainer) -- 設置容器
    scrollViewContainer:setPosition(cc.p(0.0, 0.0))
    scrollView:setClippingToBounds(true) -- 設置剪切
    scrollView:setBounceable(true)  -- 設置彈性效果
    scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    scrollView:setDelegate()
    scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(scrollView)
    scrollView:setTag(3)

    -- 下方物品信息
    -- 行数
    local goodsNum = getTableRowNum(goodsInfo)
    local col = 2
    local row = math.ceil(goodsNum / col)
    local tempGoods = cc.Sprite:create("Images/DiamondStore/ann07_a.png")
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
                local tempTableData = goodsDataTemp[goodsInfo[index][1]]

                -- printn(tempTableData)

                local normalSprite = cc.Sprite:create("Images/DiamondStore/ann07_a.png")
                local selectedSprite = cc.Sprite:create("Images/DiamondStore/ann07_b.png")
                local item = cc.MenuItemSprite:create(normalSprite, selectedSprite)
                item:setTag(index)
                item:registerScriptTapHandler(function (tag, menuItem)
                    -- body
                    -- local goodsInfoTemp = storeTableData[self.GoodsInfoKey]
                    -- local goodsTemp = goodsInfoTemp[tostring(tag)]
                    -- -- 添加钻石
                    -- local diamondNum = goodsTemp[self.diamondKey] + goodsTemp[self.extraDiamondKey]
                    -- DataManager:getInstance():addDiamond(tonumber(diamondNum))
                    print("======== 点击购买物品")
                    local srcTag = tag
                    tag = self.goodsShowData[tag]
                    -- local goodTemp = goodsDataFromCSV[tostring(tag)]
                    local buyState = self.goodsData[tag][2]
                    if (buyState == 1) then
                        return 0
                    end

                    local _alert = AlertView:create(0, 0, "购买物品", "", nil)

                    local goodId = self.goodsData[tag][1]
                    local goodsDataFromCSV = DataManager:getInstance():getCSVByID(csvOfShopItem)
                    local goodDataTemp = goodsDataFromCSV[goodId]

                    local iconName = "Images/Icon/" .. goodDataTemp[dataKeyICON] .. ".png"
                    local icon = cc.Sprite:create(iconName)
                    icon:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + _alert.s_size.height * 0.5 - icon:getContentSize().height * 0.5 - 95))
                    _alert:addChild(icon)

                    local goodNameLabel = cc.LabelTTF:create(goodDataTemp[dataKeyName], BoldFont, 26.0)
                    goodNameLabel:setPosition(cc.p(icon:getPositionX() + icon:getContentSize().width * 0.5 + 2, icon:getPositionY() - icon:getContentSize().height * 0.5))
                    goodNameLabel:setAnchorPoint(cc.p(0.0, 0.0))
                    goodNameLabel:setColor(WriteColor)
                    _alert:addChild(goodNameLabel)

                    local goodDesc = cc.LabelTTF:create(goodDataTemp[dataKeyDesc], BoldFont, 24.0)
                    goodDesc:setPosition(cc.p(_alert.s_position.x - _alert.s_size.width * 0.5 + 20, goodNameLabel:getPositionY() - 25))
                    goodDesc:setDimensions(cc.size(_alert.s_size.width - (20 * 2), goodDesc:getContentSize().height * 3))
                    goodDesc:setColor(WriteColor)
                    goodDesc:setAnchorPoint(cc.p(0.0, 1.0))
                    goodDesc:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
                    goodDesc:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
                    _alert:addChild(goodDesc)

                    local needLabel = cc.LabelTTF:create("需消耗：" .. goodDataTemp[dataKeyPrice] .. "钻石", BoldFont, 26.0)
                    needLabel:setPosition(cc.p(goodDesc:getPositionX(), goodDesc:getPositionY() - goodDesc:getDimensions().height - needLabel:getContentSize().height * 0.5))
                    needLabel:setAnchorPoint(cc.p(0.0, 0.5))
                    needLabel:setColor(BaseColor)
                    _alert:addChild(needLabel)

                    local curLabel = cc.LabelTTF:create("当前拥有：" .. DataManager:getInstance():getRoleData(roleDiamond) .. "钻石", BoldFont, 26.0)
                    curLabel:setPosition(cc.p(needLabel:getPositionX(), needLabel:getPositionY() - needLabel:getContentSize().height - 5))
                    curLabel:setAnchorPoint(cc.p(0.0, 0.5))
                    curLabel:setColor(BaseColor)
                    _alert:addChild(curLabel)

                    local normalSpriteL = cc.Sprite:create("Images/btn/ann01_a.png")
                    local selectedSpriteL = cc.Sprite:create("Images/btn/ann01_b.png")
                    local menuItemL = cc.MenuItemSprite:create(normalSpriteL, selectedSpriteL)
                    menuItemL:setPosition(cc.p(-normalSpriteL:getContentSize().width * 0.5 - 35, 0))
                    menuItemL:registerScriptTapHandler(function (tag, menuItem)
                        -- body
                        _alert:removeFromParent()
                    end)

                    local labelL = cc.LabelTTF:create("取 消", BoldFont, 26.0)
                    labelL:setPosition(cc.p(menuItemL:getContentSize().width * 0.5, menuItemL:getContentSize().height * 0.5))
                    labelL:setColor(WriteColor)
                    menuItemL:addChild(labelL)

                    local normalSpriteR = cc.Sprite:create("Images/btn/ann01_a.png")
                    local selectedSpriteR = cc.Sprite:create("Images/btn/ann01_b.png")
                    local menuItemR = cc.MenuItemSprite:create(normalSpriteR, selectedSpriteR)
                    menuItemR:setPosition(cc.p(normalSpriteL:getContentSize().width * 0.5 + 35, 0))
                    menuItemR:registerScriptTapHandler(function (tag, menuItem)
                        -- body
                        print("======== 确认物品", tag)
                        tag = self.goodsShowData[tag]
                        local goodsDataFromCSV = DataManager:getInstance():getCSVByID(csvOfShopItem)
                        -- local goodTemp = goodsDataFromCSV[tostring(tag)]
                        local buyState = self.goodsData[tag][2]
                        if (buyState == 1) then
                            return 0
                        end

                        local goodTemp = goodsDataFromCSV[self.goodsData[tag][1]]
                        local needDiamondNum = tonumber(goodTemp[dataKeyPrice])

                        local goodItemId = self.goodsData[tag][1]
                        -- local goodsDataFromCSV = DataManager:getInstance():getCSVByID(csvOfShopItem)
                        local goodItemDataTemp = goodsDataFromCSV[goodId]
                        local goodItemResume = goodItemDataTemp[dataKeyResume]

                        local goodItemResumeType = goodItemResume[1]
                        local goodItemResumeValue = goodItemResume[2]
                        local goodItemAchievement = goodItemDataTemp[dataKeyAchievement]


                        local curDiamondNum = tonumber(DataManager:getInstance():getRoleData(roleDiamond))
                        if DataManager:getInstance():addDiamond(-needDiamondNum) == 1 then -- (needDiamondNum > curDiamondNum)
                            

                            if (not DataManager:getInstance():buyGoodsInDiamondStore(goodItemResumeType, goodItemResumeValue, goodItemAchievement)) then
                                return 0
                            end

                            ToastUtil:toastString("成功购买物品：" .. goodTemp[dataKeyName])

                            local name = goodTemp[dataKeyName] 
                            if goodTemp["TD_Name"] ~= nil then
                                name = goodTemp["TD_Name"]
                            end
                            printn("goodTemp",goodTemp,name)

                            -- if (goodItemResumeType == "8") then
                            --     --  钻石
                            --     DataManager:getInstance():addDiamond(tonumber(goodItemResumeValue))
                            -- elseif (goodItemResumeType == "3") then
                            --     --  解锁天赋
                            --     DataManager:getInstance():unlockTallentByKey(goodItemResumeValue)
                            -- end

                            local goodItemNextID = goodItemDataTemp[dataKeyNextId]
                            if ((goodItemNextID ~= nil) and (goodItemNextID ~= "")) then
                                self.goodsData[tag][1] = goodItemNextID
                                self.goodsData[tag][2] = 0
                            else
                                local goodItemRepeat = goodItemDataTemp[dataKeyRepeat]
                                if (goodItemRepeat == "0") then
                                    -- 不可重复购买
                                    self.goodsData[tag][2] = 1
                                else
                                    -- 可重复购买

                                end
                            end
                            
                            --  检查购买道具后的礼包刷新问题
                            DataManager:getInstance():checkAndstepNextGift()
                            local newStoreTableData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
                            self.recommendedData = newStoreTableData["1"]
                            
                            local tableData = {}
                            tableData["1"] = self.recommendedData
                            tableData["2"] = self.goodsData
                                                       
                            self:loadData(tableData)
                            
                        end

                        _alert:removeFromParent()
                    end)

                    local labelR = cc.LabelTTF:create("购 买", BoldFont, 26.0)
                    labelR:setPosition(cc.p(menuItemR:getContentSize().width * 0.5, menuItemR:getContentSize().height * 0.5))
                    labelR:setColor(WriteColor)
                    menuItemR:addChild(labelR)
                    -- menuItemR:setTag(tonumber(goodId))
                    menuItemR:setTag(srcTag)


                    local menu = cc.Menu:create(menuItemL, menuItemR)

                    menu:setPosition(cc.p(_alert.s_position.x, curLabel:getPositionY() - curLabel:getContentSize().height * 0.5 - normalSpriteL:getContentSize().height * 0.5 - 10))
                    _alert:addChild(menu, 100)
                    
                end)

                local menu = cc.Menu:create(item)

                if (j == 1) then
                    menu:setPosition(cc.p(baseXL, baseY - (i - 1) * baseItemHeight))
                else
                    menu:setPosition(cc.p(baseXR, baseY - (i - 1) * baseItemHeight))
                end
                menu:setTag(1)

                local iconName = "Images/Icon/" .. tempTableData[dataKeyICON] .. ".png"
                local icon = cc.Sprite:create(iconName)
                icon:setPosition(cc.p(icon:getContentSize().width * 0.5 + 10, icon:getContentSize().height * 0.5 + (normalSprite:getContentSize().height - icon:getContentSize().height) * 0.5))
                item:addChild(icon)

                local goodName = cc.LabelTTF:create(tempTableData[dataKeyName], BoldFont, 26.0)
                goodName:setAnchorPoint(cc.p(0.0, 1.0))
                goodName:setColor(BaseColor)
                goodName:setPosition(cc.p(icon:getPositionX() + icon:getContentSize().width * 0.5 + 10, icon:getPositionY() + icon:getContentSize().height * 0.5))
                item:addChild(goodName)

                local needDiamond = cc.LabelTTF:create("钻石x" .. tempTableData[dataKeyPrice], BoldFont, 26.0)
                needDiamond:setAnchorPoint(cc.p(0.0, 0.0))
                needDiamond:setColor(WriteColor)
                needDiamond:setPosition(cc.p(goodName:getPositionX(), icon:getPositionY() - icon:getContentSize().height * 0.5))
                item:addChild(needDiamond)

                -- 右上角购买标记
                local flag = goodsInfo[index][2]
                if (flag == 1) then
                    local buySprite = cc.Sprite:create("Images/DiamondStore/banner_05.png")
                    buySprite:setPosition(cc.p(normalSprite:getContentSize().width - buySprite:getContentSize().width * 0.5, normalSprite:getContentSize().height - buySprite:getContentSize().height * 0.5))
                    item:addChild(buySprite)

                    item:unregisterScriptTapHandler()
                elseif (flag == 4) then
                    local newFlag = cc.LabelTTF:create("new", BoldFont, 25.0)
                    newFlag:setColor(GreenColor)
                    newFlag:setPosition(cc.p(newFlag:getContentSize().width * 0.5 + 2, item:getContentSize().height - newFlag:getContentSize().height * 0.5 + 8))
                    item:addChild(newFlag)
                end

                scrollViewContainer:addChild(menu)
            else
                break
            end
        end
    end
        
    scrollView:setContentSize(cc.size(scrollViewSize.width, tempTotalHeight))
    scrollView:setContentOffset(cc.p(0, -(tempTotalHeight - scrollView:getViewSize().height)))

    self:moveToPoint(self.pageIndex)

function updateCountdown(delta)
    

    local nowSecond = os.time()

    local pageViewTemp = self:getChildByTag(1)
    if (pageViewTemp ~= nil) then
        local giftCSV = DataManager:getInstance():getCSVByID(csvOfShopGift)
        local storeTableDataTemp = DataManager:getInstance():getRoleData(roleDiamondStoreData)

        local recommended = storeTableDataTemp[self.LimitRecommendedKey]

        local num = getTableRowNum(recommended)

        local deltaTime = delta * 1000

        local removeIndexArr = {}
        local refreshFlag = false
        local time = os.time()
        for i=num,1,-1 do

            local countdown = recommended[i][2]
            if (countdown > 0) then
                if ((countdown - nowSecond) > 0) then
                    local layoutTemp = pageViewTemp:getChildByTag(i)
                    local menu = layoutTemp:getChildByTag(1)

                    local menuItem = menu:getChildByTag(i)

                    local surplus = menuItem:getChildByTag(100)
                    surplus:setString(getTimeStr(self:getSurplusSecond(nowSecond, countdown)))
                else
                    local giftData = giftCSV[recommended[i][1]]
                    local giftItemNextID = giftData[dataKeyNextId]
                    recommended[i][1] = giftItemNextID
                    recommended[i][3] = 0
                    if ((giftItemNextID ~= nil) and (giftItemNextID ~= "") and giftCSV[giftItemNextID] ~= nil) then
                        if (tonumber(giftCSV[giftItemNextID][dataKeyTime]) > 0) then
                            recommended[i][2] = time + tonumber(giftCSV[giftItemNextID][dataKeyTime]) * 3600
                        else
                            recommended[i][2] = tonumber(giftCSV[giftItemNextID][dataKeyTime])
                        end
                    else
                        recommended[i][2] = 0
                    end

                    -- removeObjectFromTableI(recommended, i)
                    if (not refreshFlag) then
                        refreshFlag = true
                    end
                end
            end
        end

        if (refreshFlag) then
            local tableData = {}
            tableData["1"] = recommended
            tableData["2"] = self.goodsData

            self:loadData(tableData)
        end
        

        -- if (refreshFlag) then
        --  local recommended = {}
  --        for i=1,7 do
  --            local temp = {}
  --            temp["ID"] = tostring(1000 + i)
  --            temp["diamond"] = 20 * i
  --            temp["money"] = 10 * i
  --            -- temp["extraDiamod"] = i * 5
  --            temp["countdown"] = 4000 * i
  --            recommended[tostring(i)] = temp
  --        end

  --        local goodsInfo = {}
  --        for i=1,10 do
  --                local temp = {}
  --                temp["ID"] = tostring(2001 + i)
  --                temp["diamond"] = 30 * i
  --                temp["money"] = 40 * i
  --                temp["extraDiamond"] = 50 * i
  --            goodsInfo[tostring(i)] = temp
  --        end

  --        local tableData = {}
  --        tableData["1"] = recommended
  --        tableData["2"] = goodsInfo

        --  self:loadData(tableData)
        -- end

    end
end
    self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(updateCountdown, 1, false)
end

function DiamondStore:clearPoint(index)
    -- body
    local pointSpr = self:getChildByTag(index + 10)
    if (pointSpr ~= nil) then
        local tempSpr = cc.Sprite:create("Images/UI/dian_a.png")
        pointSpr:setSpriteFrame(tempSpr:getSpriteFrame())
    end
end

function DiamondStore:moveToPoint(index)
    -- body
    local pointSpr = self:getChildByTag(index + 10)
    if (pointSpr ~= nil) then
        local tempSpr = cc.Sprite:create("Images/UI/dian_b.png")
        pointSpr:setSpriteFrame(tempSpr:getSpriteFrame())
    end
end

function DiamondStore:getSurplusSecond(nowSecond, expiredSecond)
    -- body
    if (expiredSecond > nowSecond) then
        return (expiredSecond - nowSecond)
    end
    return 0
end

-- function DiamondStore:checkAndstepNextGift(event)
--     local storeTableData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
--     local recommendedData = storeTableData["1"]
--     local giftCSV = DataManager:getInstance():getCSVByID(csvOfShopGift)
    
--     local function check()
--         local keyIds = {"19", "5", "4"}
--         for kk, vv in pairs(self.goodsData) do
--             if vv[1] == keyIds[1] or vv[1] == keyIds[2] or vv[1] == keyIds[3] then
--                 if vv[2] == 1 then
--                     local giftId = vv[1] == keyIds[1] and "1" or "3"
--                     local giftData = giftCSV[giftId]
                
--                     for k, v in pairs(recommendedData) do
--                         if (v[1] == giftId) then
--                             local showType = tonumber(giftData[dataKeyShowType])
                        
--                             if (showType == 1) then
--                                 local time = os.time()
                            
--                                 local giftItemNextID = giftData[dataKeyNextId]
--                                 v[1] = giftItemNextID
--                                 if giftCSV[giftItemNextID] ~= nil then
--                                     if (tonumber(giftCSV[giftItemNextID][dataKeyTime]) > 0) then
--                                         v[2] = time + tonumber(giftCSV[giftItemNextID][dataKeyTime]) * 3600
--                                     else
--                                         v[2] = tonumber(giftCSV[giftItemNextID][dataKeyTime])
--                                     end
--                                 else
--                                     v[2] = 0
--                                 end
--                                 v[3] = 0
--                                 if giftItemNextID == "1" or giftItemNextID == "3" then
--                                     check()
--                                 end
--                             elseif (showType == 2) then
--                                 v[3] = 0
--                             end
--                         end
--                     end
--                 end
--             end
--         end
--     end
    
--     check()
    
--     storeTableData["1"] = recommendedData
--     self.recommendedData = storeTableData["1"]
--     DataManager:getInstance():setRoleData(roleDiamondStoreData, storeTableData, nil)
-- end


PushGiftView = class("PushGiftView", function ()
    return DialogueView:create()
end)
PushGiftView.__index = PushGiftView

PushGiftView.timeLine = 0.0

function PushGiftView:create()
    local view = PushGiftView.new()
    if view and view:init() then
        return view
    end
    return nil
end

function PushGiftView:init()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local good = DataManager:getInstance():getCurDiamondStoreGoods()
    local pushCsv = DataManager:getInstance():getCSVByID(csvOfPushGift)
    local shopCsv = DataManager:getInstance():getCSVByID(csvOfShopGift)
    local data = pushCsv[good]
    local shopData = shopCsv[good]
    self.timeLine = 0.0
    print("data = "..json.encode(data))
    print("shopData = "..json.encode(shopData))

    local bg = cc.Sprite:create("Images/DiamondStore/dazhe_04.png")
    bg:setPosition(cc.p(0.5*visibleSize.width, 0.5*visibleSize.height))
    self:addChild(bg)
    -- closeBtn
    local closeBtn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
    closeBtn:registerScriptTapHandler(function()
        self:close()
    end)
    closeBtn:setPosition(0.5*(visibleSize.width+bg:getContentSize().width), 0.5*(visibleSize.height+bg:getContentSize().height)-90.0)

    local menu = cc.Menu:create(closeBtn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    if data and shopData then
        local titleLabel = cc.LabelTTF:create(data.name, BoldFont, 30.0)
        titleLabel:setPosition(0.5*visibleSize.width, 0.5*(visibleSize.height+bg:getContentSize().height)-130.0+20.0)
--        self:addChild(titleLabel)

        self.timeLine = self.timeLine + 0.3

        local isFull = data.bestIcon ~= "0"

        local startY = titleLabel:getPositionY()+15.0
        local num = math.min(#data.price, #data.title)
        for i=1,num do

            local cellNode = cc.Node:create()
            cellNode:setVisible(false)
            cellNode:setPosition(cc.p(0.0, -50.0))
            self:addChild(cellNode)

            self.timeLine = self.timeLine + 0.3
            local delay = cc.DelayTime:create(self.timeLine)
            local show = cc.Show:create()
            local move = cc.MoveTo:create(0.1, cc.p(0.0, 0.0))
            local seq = cc.Sequence:create(delay, show, move)
            cellNode:runAction(seq)

            local h = 60.0
            if isFull and i == 1 then
                h = 100.0
            end

            local background
            if isFull and i > 1 then
                background = cc.Scale9Sprite:create("Images/UI/ditiao_01.png")
                background:setPosition(cc.p(0.5*visibleSize.width, startY-i*70.0-20.0))
            else
                background = cc.Scale9Sprite:create("Images/DiamondStore/ditiaoxg.png")
                background:setPosition(cc.p(0.5*visibleSize.width, startY-i*70.0))
            end
            background:setContentSize(cc.size(bg:getContentSize().width-50.0, h))
            cellNode:addChild(background)

            local titleLabel = cc.LabelTTF:create(data.title[i][1], BoldFont, 30.0)
            titleLabel:setColor(BaseColor)
            titleLabel:setAnchorPoint(cc.p(0.0, 0.5))
            titleLabel:setPosition(cc.p(0.5*(visibleSize.width-bg:getContentSize().width)+50.0, background:getPositionY()))
            cellNode:addChild(titleLabel)

            if isFull and i == 1 then
                titleLabel:setPosition(cc.p(0.5*(visibleSize.width-bg:getContentSize().width)+90.0, background:getPositionY()+20.0))

                local desc = cc.LabelTTF:create(data.bestDesc, BoldFont, 20.0)
                desc:setColor(BaseColor)
                desc:setAnchorPoint(cc.p(0.0, 0.5))
                desc:setPosition(cc.p(0.5*(visibleSize.width-bg:getContentSize().width)+90.0, background:getPositionY()-20.0))
                cellNode:addChild(desc)
            end

            local priceLabel = cc.LabelTTF:create(data.price[i][1], BoldFont, 30.0)
            priceLabel:setAnchorPoint(cc.p(1.0, 0.5))
            priceLabel:setPosition(cc.p(0.5*(visibleSize.width+bg:getContentSize().width)-50.0, background:getPositionY()))
            cellNode:addChild(priceLabel)

        end

        self.timeLine = self.timeLine + 0.1

        local oldPriceLabel = cc.LabelTTF:create(data.allPrice, BoldFont, 28.0)
        oldPriceLabel:setPosition(0.5*(visibleSize.width+bg:getContentSize().width)-150.0, startY-(num+1)*70.0)
        if isFull then
            oldPriceLabel:setPosition(0.5*(visibleSize.width+bg:getContentSize().width)-150.0, startY-(num+1)*70.0-20.0)
        end
        oldPriceLabel:setVisible(false)
        self:addChild(oldPriceLabel)

        self.timeLine = self.timeLine + 0.3
        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local seq = cc.Sequence:create(delay, show)
        oldPriceLabel:runAction(seq)

        local coverSp = cc.Sprite:create("Images/DiamondStore/dazhe_05.png")
        coverSp:setPosition(oldPriceLabel:getPosition())
        coverSp:setVisible(false)
        self:addChild(coverSp)

        self.timeLine = self.timeLine + 0.5
        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local seq = cc.Sequence:create(delay, show)
        coverSp:runAction(seq)

        -- buyBtn
        local buyBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        buyBtn:registerScriptTapHandler(function()
            print("按了购买按钮--------")
            purchase(data.payType)
        end)
        buyBtn:setPosition(0.5*visibleSize.width, 0.5*(visibleSize.height-bg:getContentSize().height)+60.0)
        buyBtn:setVisible(false)

        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local seq = cc.Sequence:create(delay, show)
        buyBtn:runAction(seq)

        local menu = cc.Menu:create(buyBtn)
        menu:setPosition(cc.p(0, 0))
        self:addChild(menu)

        local closeLabel = cc.LabelTTF:create("购 买", BoldFont, 36.0)
        closeLabel:setPosition(buyBtn:getPosition())
        closeLabel:setVisible(false)
        self:addChild(closeLabel)

        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local seq = cc.Sequence:create(delay, show)
        closeLabel:runAction(seq)

        local priceLabel = cc.LabelTTF:create("现价：", BoldFont, 30.0)
        priceLabel:setAnchorPoint(cc.p(1.0, 0.0))
        priceLabel:setPosition(0.5*(visibleSize.width+bg:getContentSize().width)-150.0, 0.5*(visibleSize.height-bg:getContentSize().height)+130.0)
        priceLabel:setVisible(false)
        priceLabel:setPositionY(priceLabel:getPositionY()-50.0)
        self:addChild(priceLabel)

        self.timeLine = self.timeLine + 0.3
        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local move = cc.MoveBy:create(0.3, cc.p(0.0, 50.0))
        local seq = cc.Sequence:create(delay, show, move)
        priceLabel:runAction(seq)

        local priceNumLabel = cc.LabelTTF:create(data.nowPrice, BoldFont, 50.0)
        priceNumLabel:setColor(YellowColor)
        priceNumLabel:setAnchorPoint(cc.p(0.0, 0.0))
        priceNumLabel:setPosition(0.5*(visibleSize.width+bg:getContentSize().width)-150.0, 0.5*(visibleSize.height-bg:getContentSize().height)+130.0)
        priceNumLabel:setPositionY(priceNumLabel:getPositionY()-50.0)
        priceNumLabel:setVisible(false)
        self:addChild(priceNumLabel)

        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local move = cc.MoveBy:create(0.3, cc.p(0.0, 50.0))
        local seq = cc.Sequence:create(delay, show, move)
        priceNumLabel:runAction(seq)

        local zheSp1 = cc.Sprite:create("Images/DiamondStore/"..data.icon)
        zheSp1:setPosition(0.5*(visibleSize.width-bg:getContentSize().width)+100.0, 0.5*(visibleSize.height-bg:getContentSize().height)+150.0)
        zheSp1:setVisible(false)
        self:addChild(zheSp1)

        self.timeLine = self.timeLine + 0.6
        local delay = cc.DelayTime:create(self.timeLine+0.1)
        local show = cc.Show:create()
        local scale = cc.ScaleTo:create(0.1, 1.5)
        local fadeout = cc.FadeOut:create(0.1)
        local seq = cc.Sequence:create(delay, show, scale, fadeout)
        zheSp1:runAction(seq)


        local zheSp2 = cc.Sprite:create("Images/DiamondStore/"..data.icon)
        zheSp2:setPosition(zheSp1:getPosition())
        zheSp2:setVisible(false)
        zheSp2:setScale(1.5)
        self:addChild(zheSp2)


        local delay = cc.DelayTime:create(self.timeLine)
        local show = cc.Show:create()
        local scale = cc.ScaleTo:create(0.1, 1.0)
        local seq = cc.Sequence:create(delay, show, scale)
        zheSp2:runAction(seq)

    end
    return true
end



