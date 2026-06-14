require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/DataManager"
require "LuaClass/NotificationNode"
require "LuaClass/ToastUtil"


ResourceLayer = class("ResourceLayer", function ()
    return BaseView:create()
end)

ResourceLayer.__index = ResourceLayer
ResourceLayer.scrollView = nil
ResourceLayer.scrollViewContainer = nil
ResourceLayer.resourceScrollView = nil
ResourceLayer.resourceScrollViewContainer = nil
ResourceLayer.topMaskLabel = nil
ResourceLayer.bottomMaskLabel = nil
ResourceLayer.workerData = nil
ResourceLayer.workerCsv = nil
ResourceLayer.produceCsv = nil
ResourceLayer.workerNum = 0
ResourceLayer.workerUseNum = 0
ResourceLayer.produceTable = {}
ResourceLayer.bIsNeedRedraw = true

function ResourceLayer:create()
    local view = ResourceLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function ResourceLayer:destory()
    cclog("ResourceLayer：我自由了")
    DataManager:getInstance():unregisterEvent(roleProducerQueue, "resource")
    DataManager:getInstance():unregisterEvent(roleLivingUnitNum, "resource")
    DataManager:getInstance():unregisterEvent(roleGuideStep, "resource")
    DataManager:getInstance():unregisterEvent(roleMapInfo, "ResourceLayer")
    DataManager:getInstance():unregisterEvent("kSystemBackToForward", "resource")
    -- 调用父类的析构
    self:superDestory()
end

function ResourceLayer:init()
    -- local a, b = DataManager:getInstance():unlockUnitWithType(kUnlockResource, "2")
    DataManager:getInstance():registerEvent(roleMapInfo, "ResourceLayer", function()
        -- body
        local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
        if (flag) then
            GuideController:getInstance():addRedPoint(self.topRightBtn)
        else
            GuideController:getInstance():removeRedPoint(self.topRightBtn)
        end
    end)

	local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
	if (flag) then
		GuideController:getInstance():addRedPoint(self.topRightBtn)
	else
		GuideController:getInstance():removeRedPoint(self.topRightBtn)
	end

    self.workerCsv = DataManager:getInstance():getCSVByID(csvOfWorker)
    self.workerNum = DataManager:getInstance():getRoleData(roleLivingUnitNum)
    self.produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 设置title文字
    self.titleLabel:setString("资 源")

    -- 修改顶部左侧按钮显示
    self.topLeftBtn:setVisible(true)

    -- 修改顶部左侧侧按钮为快速出征
    self:resetTopLeftButtonToExpedition()

    -- 设置背景Icon
    self:setBackgroundIcon("Images/Background/caij.png")

    -- 设置下方信息界面
    local progressTime = 30.0
    self:addInfoNode("仓 库", function()
        zqDispatch:moveToRepository()
    end, nil, nil, "Images/MainMenu/an_caiji_a.png", "Images/MainMenu/an_caiji_b.png", function()
        cclog("点击了采集按钮")

        -- local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
        -- if (tempData == nil) then
        --     tempData = {}
        --     tempData.mapIndex = 1
        -- end
        -- tempData.mapIndex = tempData.mapIndex + 1
        -- DataManager:getInstance():setRoleData(roleMapInfo, tempData)


        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Caiji, false)
        end
        local baseValue = DataManager:getInstance():getRoleData(roleGatherUnit)
        local addStoneValue = math.floor(baseValue * (1 + (1 - math.random(100) % 3) * math.random(20) / 100))
        local addWoodValue = math.floor(baseValue * (1 + (1 - math.random(100) % 3) * math.random(20) / 100))
        
        DataManager:getInstance():addPackItemWithId("1006", addStoneValue)
        DataManager:getInstance():addPackItemWithId("1007", addWoodValue)

        local achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Collect)
        DataManager:getInstance():setAchievementInfo(achievement_Collect, (achievementValue + 1))

        -- 点击采集按钮之后+一步
        GuideController:getInstance():addStep(3)
        -- 加了步骤之后再解锁一次仓库的建造检查
        
        if not GuideController:getInstance():getIsHaveStep(300) then
            DataManager:getInstance():createSuccessCheck(kUnlockBuild, "1")
            DataManager:getInstance():sendSystemInfo("有了石头和木头，您可以建造这些建筑了。")
            GuideController:getInstance():addStep(300)
        end
    end, "Images/MainMenu/w_caij.png", true, progressTime)

    -- -- 添加底部的回城按钮
    -- local backBtn = cc.MenuItemImage:create("Images/UI/BigBtn.png", "Images/UI/BigBtn1.png")
    -- backBtn:registerScriptTapHandler(function()
    --     zqDispatch:moveToRepository()
    -- end)
    -- backBtn:setPosition(cc.p(backBtn:getContentSize().width * 0.64, UIBottomHeight + backBtn:getContentSize().height * 0.7))

    -- local backLabel = cc.LabelTTF:create("返回仓库", BoldFont, 28.0)
    -- backLabel:setColor(cc.c3b(255, 255, 255))
    -- backLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    -- backLabel:setPosition(cc.p(backBtn:getContentSize().width * 0.4, backBtn:getContentSize().height * 0.55))
    -- backBtn:addChild(backLabel)

    -- -- 添加采集按钮
    -- local GatherBtn = cc.MenuItemImage:create("Images/UI/GatherBtn.png", "Images/UI/GatherBtn.png")
    -- GatherBtn:registerScriptTapHandler(function()
    --     cclog("点击采集按钮")
    -- end)
    -- GatherBtn:setPosition(cc.p(visibleSize.width - GatherBtn:getContentSize().width * 0.8, backBtn:getPositionY()))

    -- local GatherLabel = cc.LabelTTF:create("采 集", BoldFont, 28.0)
    -- GatherLabel:setColor(cc.c3b(255, 255, 255))
    -- GatherLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    -- GatherLabel:setPosition(cc.p(GatherBtn:getContentSize().width * 0.5, GatherBtn:getContentSize().height * 0.5))
    -- GatherBtn:addChild(GatherLabel)

    -- local buttons = {backBtn, GatherBtn}
    -- local bottomMenu = cc.Menu:create(unpack(buttons))
    -- bottomMenu:setPosition(cc.p(0, 0))
    -- self:addChild(bottomMenu)

    -- 添加资源更新底框
    local maskBgGap = 8.0
    -- local tempSpr = cc.Sprite:create("Images/UI/MaskBg.png")
    local bottomMaskHeight = 180 * visibleSize.height / 1136
    local maskSize = cc.size(self.areaWidth, bottomMaskHeight)
    -- local bottomMask = cc.Scale9Sprite:create("Images/UI/MaskBg.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    -- bottomMask:setContentSize(maskSize)
    -- bottomMask:setPosition(cc.p(self.centerPos.x, self.originPos.y + maskSize.height * 0.5 + 6.0))
    -- self:addChild(bottomMask)

    -- 添加底部资源框的标题
    local bottomMaskTitleBg = cc.Sprite:create("Images/UI/biaoti.png")
    bottomMaskTitleBg:setPosition(self.originPos.x + maskSize.width * 0.5, self.originPos.y + maskSize.height - bottomMaskTitleBg:getContentSize().height * 0.5)
    self:addChild(bottomMaskTitleBg)

    local bottomMaskTitleBgTopLine = cc.Sprite:create("Images/UI/anbeijintiao.png")
    bottomMaskTitleBgTopLine:setPosition(cc.p(bottomMaskTitleBg:getPositionX(), bottomMaskTitleBg:getPositionY() + bottomMaskTitleBg:getContentSize().height * 0.5))
    self:addChild(bottomMaskTitleBgTopLine)

    -- 添加底部资源框的title
    self.bottomMaskLabel = cc.LabelTTF:create(" ", BoldFont, 28.0)
    self.bottomMaskLabel:setPosition(bottomMaskTitleBg:getPosition())
    self.bottomMaskLabel:setColor(cc.c3b(255, 255, 255))
    -- self.bottomMaskLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self:addChild(self.bottomMaskLabel)

    -- 添加资源获取界面的scrollView
    self.resourceScrollViewContainer = cc.Layer:create()
    local scrollViewSize = cc.size(maskSize.width, maskSize.height - bottomMaskTitleBg:getContentSize().height)
    self.resourceScrollViewContainer:setContentSize(scrollViewSize)
    self.resourceScrollView = cc.ScrollView:create(scrollViewSize)
    self.resourceScrollView:setPosition(self.originPos)
    self.resourceScrollView:setContainer(self.resourceScrollViewContainer) -- 設置容器
    self.resourceScrollView:setViewSize(scrollViewSize)
    self.resourceScrollView.bIsScrollView = true
    self.resourceScrollView:setClippingToBounds(true) -- 設置剪切
    self.resourceScrollView:setBounceable(true)  -- 設置彈性效果
    self.resourceScrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.resourceScrollView:setDelegate()
    self.resourceScrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.resourceScrollView)

    -- self:setResourceUIWithData()

    -- 添加工匠配置底框
    maskSize = cc.size(self.areaWidth, self.areaHeight - bottomMaskHeight - maskBgGap)
    -- local topMask = cc.Scale9Sprite:create("Images/UI/MaskBg.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    -- topMask:setContentSize(maskSize)
    -- topMask:setPosition(cc.p(self.centerPos.x, bottomMask:getPositionY() + (bottomMask:getContentSize().height + maskSize.height) * 0.5 + maskBgGap))
    -- self:addChild(topMask)

    -- 添加底部资源框的标题
    local topMaskTitleBg = cc.Sprite:create("Images/UI/biaoti.png")
    topMaskTitleBg:setPosition(cc.p(self.originPos.x + maskSize.width * 0.5, self.originPos.y + bottomMaskHeight + maskBgGap + maskSize.height - topMaskTitleBg:getContentSize().height * 0.5))
    self:addChild(topMaskTitleBg)

    -- 添加底部资源框的title
    self.topMaskLabel = cc.LabelTTF:create("游民:(15/45)", BoldFont, 28.0)
    self.topMaskLabel:setPosition(topMaskTitleBg:getPosition())
    self.topMaskLabel:setColor(cc.c3b(255, 255, 255))
    -- self.topMaskLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self:addChild(self.topMaskLabel)

    -- 添加资源获取界面的scrollView
    self.scrollViewContainer = cc.Layer:create()
    scrollViewSize = cc.size(maskSize.width, maskSize.height - topMaskTitleBg:getContentSize().height)
    self.scrollViewContainer:setContentSize(scrollViewSize)
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(cc.p(self.originPos.x, self.originPos.y + bottomMaskHeight + maskBgGap))
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollView:setViewSize(scrollViewSize)
    self.scrollView.bIsScrollView = true
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    self.scrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)

    self:setWorkerUIWithData()
    self:resetWorkData(false)

    local TopMaskTitleBgBottomLine = cc.Sprite:create("Images/UI/anbeijin.png")
    TopMaskTitleBgBottomLine:setPosition(cc.p(topMaskTitleBg:getPositionX(), self.originPos.y + bottomMaskHeight + maskBgGap))
    self:addChild(TopMaskTitleBgBottomLine)


    local nowTime = NotificationNode:getInstance():GetGameTime()
    local function update(delta)
        local nextProduceTime = DataManager:getInstance():getRoleData(roleProduceTime)
        local CDTime = DataManager:getInstance():getRoleData(roleResourceCD)
        -- 更新显示倒计时
        local showTime = math.abs(nextProduceTime - nowTime)
        if showTime > CDTime then
            showTime = CDTime
        end
        if nextProduceTime - nowTime < 10 then
            self.bottomMaskLabel:setString("下次收获：00:0" .. showTime)
        else
            self.bottomMaskLabel:setString("下次收获：00:" .. showTime)
        end

        nowTime = NotificationNode:getInstance():GetGameTime()

        -- 只有选择了工人之后才显示倒计时
        if self.workerUseNum <= 0 then
            self.bottomMaskLabel:setString("收获奖励")
            nextProduceTime = nowTime
        end
    end

    -- 添加倒计时，计算时间剩余秒数
    -- self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 1.0, false)
    schedule(self, update, 1.0)

    DataManager:getInstance():registerEvent(roleProducerQueue, "resource", function()
        cclog("刷新资源队列数据")
        if self.bIsNeedRedraw then
            self:setWorkerUIWithData()
        end
        self:resetWorkData(false)
    end)
    DataManager:getInstance():registerEvent(roleLivingUnitNum, "resource", function()
        cclog("刷新水手数量数据")
        self:resetWorkData(false)
    end)

    -- 刷新完上边的数据，刷新下下边的数据
    self:setResourceUIWithData()

    -- 更新新手引导界面显示
    -- local guideNode = nil
    DataManager:getInstance():registerEvent(roleGuideStep, "resource", function()
        cclog("resource新手引导步骤变化")
        -- 显示采集按钮的红点
        if GuideController:getInstance():getIsHaveStep(3) then
            -- 点了以后去掉红点
            GuideController:getInstance():removeRedPoint(self.setBtn)
        end
        -- 建造完船坞之后的操作
        -- if GuideController:getInstance():getIsHaveStep(8) then
        --     -- 判断是不是没点击过船坞按钮的状态，如果是没点过，那么播放引导动画
        --     if GuideController:getInstance():getIsHaveStep(6, true) then
        --         if guideNode ~= nil then
        --             guideNode:removeFromParent()
        --             guideNode = nil
        --         end
        --     else
        --         -- 添加新手引导动画
        --         if guideNode == nil then
        --             guideNode = cc.Node:create()
        --             guideNode:setPosition(cc.p(0, 0))
        --             self:addChild(guideNode)

        --             local arrowSpr = cc.Sprite:create("Images/UI/s_02.png")
        --             arrowSpr:setPosition(self.centerPos)
        --             arrowSpr:setAnchorPoint(cc.p(1, 0.5))
        --             guideNode:addChild(arrowSpr)

        --             local handSpr = cc.Sprite:create("Images/UI/s_01.png")
        --             handSpr:setPosition(self.centerPos)
        --             handSpr:setAnchorPoint(cc.p(0, 1))
        --             guideNode:addChild(handSpr)

        --             local moveAction = {cc.MoveTo:create(0.6, cc.p(self.centerPos.x + 200, self.centerPos.y)), cc.DelayTime:create(0.6), cc.MoveTo:create(0.0, cc.p(self.centerPos.x - 50, self.centerPos.y))}
        --             arrowSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(unpack(moveAction))))
        --             arrowSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.2), cc.EaseExponentialIn:create(cc.FadeOut:create(0.4)), cc.DelayTime:create(0.6), cc.FadeIn:create(0.0))))

        --             moveAction = {cc.MoveTo:create(0.6, cc.p(self.centerPos.x + 200, self.centerPos.y)), cc.DelayTime:create(0.6), cc.MoveTo:create(0.0, cc.p(self.centerPos.x - 200, self.centerPos.y))}
        --             handSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(unpack(moveAction))))
        --             handSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(0.4), cc.EaseExponentialIn:create(cc.FadeOut:create(0.2)), cc.DelayTime:create(0.6), cc.FadeIn:create(0.0))))
        --         end
        --     end
        -- end
        -- 如果解锁了船坞，那么现实左侧快速出征按钮
        -- self.topLeftBtn:setVisible(GuideController:getInstance():getIsHaveStep(8))
        -- 如果点击过钻石商城了，那么就不显示钻石商城的红点鸟~
        if GuideController:getInstance():getIsHaveStep(61) then
            GuideController:getInstance():removeRedPoint(self.topRightBtn)
        end
    end)

    -- 显示采集按钮的红点
    if GuideController:getInstance():getIsHaveStep(3) then
        -- 点了以后去掉红点
        GuideController:getInstance():removeRedPoint(self.setBtn)
    else
        GuideController:getInstance():addRedPoint(self.setBtn)
    end

    -- 如果是首次出征回来，判断是否显示钻石商城的红点
    if GuideController:getInstance():getIsHaveStep(60) then
        -- 没显示过红点
        if not GuideController:getInstance():getIsHaveStep(61) then
            GuideController:getInstance():addRedPoint(self.topRightBtn)
        else
            GuideController:getInstance():removeRedPoint(self.topRightBtn)
        end
    end

    -- 注册从后台返回的回调
    DataManager:getInstance():registerEvent("kSystemBackToForward", "resource", function()
        cclog("纠正采集cd时间开始")
        local function openclick()
            self.bIsCenterBtnCanClick = true
            self.setButtonProgrees:setPercentage(0)
            self.setBtnLight:setVisible(true)
        end
        local nowTime = os.time()--NotificationNode:getInstance():GetGameTime()
        if nowTime - BaseViewLastClickCDTime < progressTime then
            self.bIsCenterBtnCanClick = false
            self.setBtnLight:setVisible(false)
            self.setButtonProgrees:stopAllActions()
            local persent = nowTime - BaseViewLastClickCDTime
            if persent > progressTime then
                persent = 0
            end
            local act3 = cc.ProgressTo:create(progressTime, 100)
            local act4 = cc.CallFunc:create(openclick)
            local newPersent = math.floor((persent / progressTime) * 100)
            -- print("新的百分比：", newPersent, persent, progressTime)
            self.setButtonProgrees:setPercentage(newPersent)
            self.setButtonProgrees:runAction(cc.Sequence:create(act3, act4))
        else
            openclick()
            self.setButtonProgrees:stopAllActions()
            self.setBtnLight:setVisible(true)
        end
    end)

    return true
end

function ResourceLayer:resetWorkData(bIsSave)
    self.workerNum = DataManager:getInstance():getRoleData(roleLivingUnitNum)
    self.topMaskLabel:setString("游民：" .. (self.workerNum - self.workerUseNum) .. "/" .. self.workerNum)
    -- 调用存档方法
    if bIsSave then
        DataManager:getInstance():setRoleData(roleProducerQueue, self.workerData, nil)
    end
    if not self.bIsNeedRedraw then
        -- 刷新下边的数据
        self:setResourceUIWithData()
    end
end

function ResourceLayer:setWorkerUIWithData()
    cclog("开始加载资源上方UI的数据")
    self.workerData = DataManager:getInstance():getRoleData(roleProducerQueue)
    self.workerUseNum = 0
    self.scrollViewContainer:removeAllChildren()
    -- 临时计算高度用的图
    local tempSpr = cc.Sprite:create("Images/UI/Info.png")
    local singleHeight = tempSpr:getContentSize().height + 14
    local allHeight = singleHeight * #self.workerData
    if allHeight < self.scrollView:getViewSize().height then
        allHeight = self.scrollView:getViewSize().height
    end

    local tempNode = nil
    for i = 0, #self.workerData - 1, 1 do
        local workerTable = self.workerData[i + 1]
        -- for k,v in pairs(self.workerTable) do
        --     print(k,v)
        -- end
        local workerCsvData = self.workerCsv[workerTable[dataKeyID]]
        -- 根据数据结果，开始画界面
        tempNode = cc.Node:create()
        tempNode:setPosition(cc.p(self.scrollView:getContentSize().width * 0.5, allHeight - singleHeight * i - singleHeight * 0.5))
        tempNode:setTag(i + 1)
        self.scrollViewContainer:addChild(tempNode)

        -- 首先添加文字框
        local numberBox = cc.Sprite:create("Images/UI/NumberBox.png")
        tempNode:addChild(numberBox)

        -- 天健文字框中间的数字label
        local numberLabel = cc.LabelTTF:create(workerTable[dataKeyNum], BoldFont, 24.0)
        numberLabel:setColor(WriteColor)
        -- numberLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        tempNode:addChild(numberLabel)

        -- 然后添加左右加减按钮
        local function subButtonDidClick()
            -- cclog("点击减少按钮", i)
            local val = tonumber(numberLabel:getString())
            if val > 0 then
                numberLabel:setString((val - 1) .. "")
                self.workerUseNum = self.workerUseNum - 1
                -- 修改原始数据
                workerTable[dataKeyNum] = val - 1
                -- 刷新显示
                self.bIsNeedRedraw = false
                self:resetWorkData(true)
                self.bIsNeedRedraw = true
            end
        end
        local subBtn = SDButton:create("Images/UI/SubCircleBtn.png", "Images/UI/SubCircleBtn1.png", subButtonDidClick)
        subBtn:registerLongPressed(subButtonDidClick)
        subBtn:setPosition(cc.p(-numberBox:getContentSize().width * 0.6 - subBtn:getContentSize().width * 0.5, 0))
        tempNode:addChild(subBtn)

        local function addButtonDidClick()
            -- cclog("点击增加按钮", i)
            local val = tonumber(numberLabel:getString())
            if (self.workerNum - self.workerUseNum) > 0 then
                numberLabel:setString((val + 1) .. "")
                self.workerUseNum = self.workerUseNum + 1
                -- 修改原始数据
                workerTable[dataKeyNum] = val + 1
                -- 刷新显示
                self.bIsNeedRedraw = false
                self:resetWorkData(true)
                self.bIsNeedRedraw = true
            else
                ToastUtil:downString("游民数量不足，请建造民宅", true)
            end
        end
        local addBtn = SDButton:create("Images/UI/AddCircleBtn.png", "Images/UI/AddCircleBtn1.png", addButtonDidClick)
        addBtn:registerLongPressed(addButtonDidClick)
        addBtn:setPosition(cc.p(numberBox:getContentSize().width * 0.6 + addBtn:getContentSize().width * 0.5, 0))
        tempNode:addChild(addBtn, 1)

        local addBtnLight = cc.Sprite:create("Images/UI/huan.png")
        addBtnLight:setPosition(addBtn:getPosition())
        addBtnLight:setTag(9528)
        addBtnLight:setVisible(false)
        tempNode:addChild(addBtnLight)

        addBtnLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.1, 30)))

        -- 添加左侧工匠类型文本
        local nameLabel = cc.LabelTTF:create(workerCsvData["name"], BoldFont, 24.0)
        nameLabel:setColor(BaseColor)
        -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        nameLabel:setPosition(cc.p(subBtn:getPositionX() - subBtn:getContentSize().width - nameLabel:getContentSize().width * 0.5, 0))
        nameLabel:setTag(9527)
        tempNode:addChild(nameLabel)

        local infoBtn = cc.MenuItemImage:create("Images/UI/Info.png", "Images/UI/Info1.png")
        infoBtn:registerScriptTapHandler(function()
            -- cclog("点击信息按钮", i)
            self:showInfoBox(workerCsvData["produceDesc"].." "..workerCsvData["resumeDesc"])
        end)
        infoBtn:setPosition(cc.p(addBtn:getPositionX() + addBtn:getContentSize().width + infoBtn:getContentSize().width * 0.5, 0))

        local buttonArr = {infoBtn}
        local menu = cc.Menu:create(unpack(buttonArr))
        menu:setPosition(cc.p(0, 0))
        tempNode:addChild(menu)

        self.workerUseNum = self.workerUseNum + tonumber(workerTable[dataKeyNum])
    end
    -- 刷新scrollView
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end

function ResourceLayer:setResourceUIWithData()
    cclog("开始加载资源下方UI的数据")
    self.resourceScrollViewContainer:removeAllChildren()
    self.produceTable = {}
    -- 循环工匠数据，计算产出和消耗
    for i = 0, #self.workerData - 1, 1 do
        local workerTable = self.workerData[i + 1]
        local workerCsvData = self.workerCsv[workerTable[dataKeyID]]
        local produceData = workerCsvData["produce"]
        local workerNum = tonumber(workerTable[dataKeyNum])

        -- 取出产出的id，去道具表里找到相应的名字,如果有的话
        for j = 1, #produceData do
            if produceData[j][1] ~= nil and produceData[j][1] ~= "" then
                local produceId = produceData[j][1]
                local produceCsvData = self.produceCsv[produceId]
                local produceNum = produceData[j][2]
                if self.produceTable[produceId] == nil then
                    self.produceTable[produceId] = {}
                end
                self.produceTable[produceId][2] = produceCsvData["name"]
                local newProduceTable = clone(produceCsvData)
                if self.produceTable[produceId][1] ~= nil then
                    self.produceTable[produceId][1] = tonumber(self.produceTable[produceId][1]) + tonumber(produceNum) * workerNum
                else
                    self.produceTable[produceId][1] = tonumber(produceNum) * workerNum
                end
            end
        end

        -- 取出消耗的id，去产出表找到相应的名字（优先计算消耗）
        local resumeData = workerCsvData["resume"]
        -- print("资源生产id", workerTable[dataKeyID], #resumeData)
        for j = 1, #resumeData do
            if resumeData[j][1] ~= nil and resumeData[j][1] ~= "" and resumeData[j][1] ~= "0" then
                -- print("2-1是：", resumeData[j][1])
                local resumeId = resumeData[j][1]
                produceCsvData = self.produceCsv[resumeId]
                local resumeNum = resumeData[j][2]
                if self.produceTable[resumeId] == nil then
                    self.produceTable[resumeId] = {}
                end
                self.produceTable[resumeId][2] = produceCsvData["name"]
                if self.produceTable[resumeId][1] ~= nil then
                    self.produceTable[resumeId][1] = tonumber(self.produceTable[resumeId][1]) - tonumber(resumeNum) * workerNum
                else
                    self.produceTable[resumeId][1] = -tonumber(resumeNum) * workerNum
                end
            end
        end
    end
    -- 循环取得的数据创建label
    local lineNum = 4
    local allHeight = math.floor(#self.produceTable / lineNum) * 30.0
    if allHeight < self.resourceScrollViewContainer:getContentSize().height then
        allHeight = self.resourceScrollViewContainer:getContentSize().height
    end
    self.resourceScrollViewContainer:setContentSize(cc.size(self.resourceScrollViewContainer:getContentSize().width, allHeight))
    local num = 0
    for k,v in pairs(self.produceTable) do
        -- print(k,v)
        local number = v[1]
        local name = v[2]
        if number ~= 0 then
            local addSub = "+"
            if number < 0 then
                addSub = ""
            end
            local label = cc.LabelTTF:create(name..addSub..number, BoldFont, 24.0)
            label:setAnchorPoint(cc.p(0, 1))
            if number < 0 then
                label:setColor(RedColor)
            else
                label:setColor(WriteColor)
            end
            
            -- label:enableStroke(cc.c4b(16, 16, 16, 255), 1)
            label:setPosition(cc.p((num % lineNum) * (self.resourceScrollViewContainer:getContentSize().width / lineNum) + 20, allHeight - (math.ceil((num + 1) / lineNum) - 1) * 30.0))
            self.resourceScrollViewContainer:addChild(label)
            num = num + 1
        end
    end
end

--[[
检查是否有新解锁的，有的话播放动画
]]
function ResourceLayer:checkIsHaveNewUnlock()
    -- cclog("检查是否有新解锁的资源制造单位，有的话播放动画")
    -- 没辙。。。只能遍历的说
    for i = 1, #self.workerData do
        -- 如果没显示过这个东西，那么刷新显示他
        -- print("遍历id：", i)
        local baseNode = self.scrollViewContainer:getChildByTag(i)
        if baseNode ~= nil then
            -- print("节点找到了，id为", i)
            local nameLabel = baseNode:getChildByTag(9527)
            local btnLight = baseNode:getChildByTag(9528)
            if not GuideController:getInstance():getIsHaveStep(900 + i, true) then
                -- print("没走过动画")
                if btnLight ~= nil then
                    btnLight:setVisible(true)
                end
                nameLabel:runAction(cc.Sequence:create(cc.FadeOut:create(0.0), cc.DelayTime:create(0.6), cc.FadeIn:create(0.0), cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))

                GuideController:getInstance():addStep(900 + i, true)
            else
                -- print("走过动画")
                if btnLight ~= nil then
                    btnLight:setVisible(false)
                end
            end
        end
    end
end