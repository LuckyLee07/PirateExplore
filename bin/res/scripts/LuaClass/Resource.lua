require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/ManagementTheme"
require "LuaClass/DataManager"
require "LuaClass/NotificationNode"
require "LuaClass/ToastUtil"


-- Warm-only presentation adapters. The original SDButton, ProgressTimer,
-- scheduled cooldown actions, guide handles and transaction closures stay live.
local function supplyMove(node, parent)
    node:retain();node:removeFromParent(false);parent:addChild(node);node:release()
end
local function supplyLabel(parent,text,size,color,x,y,width,anchor)
    local W=require 'LuaClass/WarmTheme'
    local label=W.label(text,size,color,x,y,false,anchor or 0)
    if width then W.fit(label,width) end
    parent:addChild(label);return label
end
local function supplyOpen(view)
    return not view.coherentPageDisposed and not view.coherentPageLeaving and not view.adventureDialog
end
local function supplyMount(view,title,subtitle,action,x,y)
    local W=require 'LuaClass/WarmTheme'
    local children=view:getChildren()
    local legacy=cc.Node:create();view:addChild(legacy);legacy:setVisible(false)
    for _,child in ipairs(children)do supplyMove(child,legacy) end
    view.supplyLegacy=legacy
    local shell=view:applyCoherentPageShell(title,subtitle)
    view.alchemyReceiptHost=shell.canvas
    local button=view.setBtn
    supplyMove(button,shell.canvas)
    -- Replace only the visual faces before interaction. SDButton still owns
    -- its listener, repeated-press scheduling, real hitbox and click state.
    local selected=button.selectSpr:isVisible()
    button.normalSpr:removeFromParent();button.selectSpr:removeFromParent()
    button.normalSpr=W.panel(156,56,W.colors.sea,8)
    button.selectSpr=W.panel(156,56,W.colors.ink,8)
    button.normalSpr:setVisible(not selected);button.selectSpr:setVisible(selected)
    button:addChild(button.normalSpr);button:addChild(button.selectSpr)
    button:setContentSize(cc.size(156,56));button:addClickArea(cc.rect(0,0,0,0))
    button:setPosition(cc.p(x,y));button:setSwallowTouches(false)
    view.supplyActionLabel=supplyLabel(button,action,24,W.colors.white,78,30,132,.5)
    local timer=view.setButtonProgrees
    timer:setScaleX(132/177);timer:setScaleY(3);timer:setPosition(cc.p(78,7))
    local click,hold=button.onSingleCLick,button.onLongPressed
    button:registerSingleCLick(function()if supplyOpen(view) and button.bIsEnable then click()end end)
    if hold then button:registerLongPressed(function()if supplyOpen(view) and button.bIsEnable then hold()end end)end
    return shell
end
local function supplyResizeScroll(scroll,container,parent,x,y,w,h)
    supplyMove(scroll,parent);scroll:setPosition(cc.p(x,y));scroll:setViewSize(cc.size(w,h))
    container:setContentSize(cc.size(w,h));scroll:setContentSize(cc.size(w,h))
    -- SDButton's legacy clip test uses parent coordinates; this canvas is scaled.
    scroll.bIsScrollView=false
end
local function supplyClip(button,scroll)
    local began,moved,ended=button.onTouchBegan,button.onTouchMoved,button.onTouchEnded
    local longProgress=button.updatelongprogress
    local active,cancelled,startPoint,startOffset,lastPoint=false,false,nil,nil,nil
    local function inside(point)
        local size=scroll:getViewSize()
        return cc.rectContainsPoint(cc.rect(0,0,size.width,size.height),point)
    end
    local function dragged(point)
        if cancelled then return true end
        if not active then return false end
        point=point or lastPoint
        local offset=scroll:getContentOffset()
        local dx,dy=point.x-startPoint.x,point.y-startPoint.y
        -- Measure in the fixed viewport, never in a row that moves with the
        -- finger. Any real scroll displacement cancels the pending button.
        return not inside(point) or dx*dx+dy*dy>64 or
            math.abs(offset.x-startOffset.x)>1 or math.abs(offset.y-startOffset.y)>1
    end
    local function cancel(self)
        active=false;cancelled=true
        self.isTouch=false;self.isMoved=true;self.m_longProgress=false
        self.pressTimes=0;self.touchCounts=0
        self.normalSpr:stopAllActions();self:setActive(false)
    end
    button.onTouchBegan=function(self,touch,event)
        local point=scroll:convertToNodeSpace(touch:getLocation())
        if not inside(point)then return false end
        local accepted=began(self,touch,event)
        if accepted then
            active=true;cancelled=false;startPoint=point;lastPoint=point
            local offset=scroll:getContentOffset();startOffset=cc.p(offset.x,offset.y)
            self.isMoved=false
        end
        return accepted
    end
    button.onTouchMoved=function(self,touch,event)
        if not active then return end
        lastPoint=scroll:convertToNodeSpace(touch:getLocation())
        if dragged(lastPoint)then cancel(self);return end
        return moved(self,touch,event)
    end
    button.onTouchEnded=function(self,touch,event)
        if not active then return end
        local point=scroll:convertToNodeSpace(touch:getLocation())
        if dragged(point)then cancel(self);return end
        active=false
        return ended(self,touch,event)
    end
    button.updatelongprogress=function(self,...)
        if dragged()then cancel(self);return end
        return longProgress(self,...)
    end
    -- SDButton's repeat timer invokes onLongPressed directly after its first
    -- hold tick. Guard both hold routes as well as the initial hold scheduler.
    for _,key in ipairs({'onLongPressed','onLongPressedActiveOnce'})do
        local callback=button[key]
        if callback then button[key]=function(...)
            if dragged()then cancel(button);return end
            return callback(...)
        end end
    end
    button.onTouchCancelled=function(self)cancel(self)end
    button.listener:registerScriptHandler(function()cancel(button)end,cc.Handler.EVENT_TOUCH_CANCELLED)
end
local function supplyInformation(view,title,text)
    if not supplyOpen(view)then return end
    local dialog=require 'LuaClass/WarmDialog'
    local modal=dialog.show(title,text,{{label='知道了'}},view)
    -- Preserve every real description, including long late-game records.
    -- Only the description scrolls; the dismissal stays outside its clip.
    local panel=modal:getChildren()[1]
    if not panel then return modal end
    local body
    for _,child in ipairs(panel:getChildren())do
        if child.getString and child:getString()==text then body=child;break end
    end
    if body then
        local size=cc.Director:getInstance():getVisibleSize();local k=size.width/640
        local width=panel:getContentSize().width-48*k;local height=132*k
        local container=cc.Layer:create();supplyMove(body,container)
        body:setFontSize(22*k);body:setDimensions(cc.size(width,0))
        local full=math.max(height,body:getContentSize().height)
        body:setPosition(cc.p(0,full));container:setContentSize(cc.size(width,full))
        local scroll=cc.ScrollView:create(cc.size(width,height));scroll:setContainer(container)
        scroll:setContentSize(cc.size(width,full));scroll:setViewSize(cc.size(width,height))
        scroll:setPosition(cc.p(24*k,panel:getContentSize().height-217*k))
        scroll:setClippingToBounds(true);scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
        scroll:setContentOffset(cc.p(0,height-full));scroll:setBounceable(false)
        panel:addChild(scroll);modal.supplyDescription=scroll
    end
    return modal
end

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
    local ok=self:initLegacy()
    if ok and rawget(_G,'WARM_PIRATE_V1')~=false then self:installCoherentSupplyPage() end
    return ok
end

function ResourceLayer:showInfoBox(text)
    if self.coherentShell then return supplyInformation(self,'物品说明',text) end
    return BaseView.showInfoBox(self,text)
end

function ResourceLayer:initLegacy()
    self:applyManagementTheme()
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
    -- The harvest summary has its own compact band. Keeping the footer safe
    -- area unchanged gives the worker list the space formerly left blank here.
    local bottomMaskHeight = 84
    local maskSize = cc.size(self.areaWidth, bottomMaskHeight)
    -- local bottomMask = cc.Scale9Sprite:create("Images/UI/MaskBg.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    -- bottomMask:setContentSize(maskSize)
    -- bottomMask:setPosition(cc.p(self.centerPos.x, self.originPos.y + maskSize.height * 0.5 + 6.0))
    -- self:addChild(bottomMask)

    -- 添加底部资源框的标题
    local bottomMaskTitleBg = ManagementTheme.panel(self.areaWidth,32,'section')
    bottomMaskTitleBg:setPosition(self.originPos.x + maskSize.width * 0.5, self.originPos.y + maskSize.height - bottomMaskTitleBg:getContentSize().height * 0.5)
    self:addChild(bottomMaskTitleBg)

    local bottomMaskTitleBgTopLine = cc.Sprite:create("Images/UI/anbeijintiao.png")
    bottomMaskTitleBgTopLine:setPosition(cc.p(bottomMaskTitleBg:getPositionX(), bottomMaskTitleBg:getPositionY() + bottomMaskTitleBg:getContentSize().height * 0.5))
    bottomMaskTitleBgTopLine:setVisible(false)
    self:addChild(bottomMaskTitleBgTopLine)

    -- 添加底部资源框的title
    self.bottomMaskLabel = cc.LabelTTF:create(" ", ManagementTheme.bodyFont(), 28.0)
    self.bottomMaskLabel:setPosition(bottomMaskTitleBg:getPosition())
    ManagementTheme.styleLabel(self.bottomMaskLabel,'heading')
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
    local topMaskTitleBg = ManagementTheme.surfaceLike("Images/UI/biaoti.png",'section')
    topMaskTitleBg:setPosition(cc.p(self.originPos.x + maskSize.width * 0.5, self.originPos.y + bottomMaskHeight + maskBgGap + maskSize.height - topMaskTitleBg:getContentSize().height * 0.5))
    self:addChild(topMaskTitleBg)

    -- 添加底部资源框的title
    self.topMaskLabel = cc.LabelTTF:create("游民:(15/45)", ManagementTheme.bodyFont(), 28.0)
    self.topMaskLabel:setPosition(topMaskTitleBg:getPosition())
    ManagementTheme.styleLabel(self.topMaskLabel,'heading')
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
    TopMaskTitleBgBottomLine:setVisible(false)
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
        if self.coherentShell then
            local remaining=math.max(0,math.min(CDTime,nextProduceTime-nowTime))
            self.bottomMaskLabel:setString(string.format('下次净收获 · %02d:%02d',math.floor(remaining/60),remaining%60))
        end

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
            -- Resume only the unelapsed cooldown. Reopening this page or
            -- foregrounding the app must not start another full gather wait.
            local persent = math.max(0, nowTime - BaseViewLastClickCDTime)
            local remaining = math.max(0, progressTime - persent)
            local act3 = cc.ProgressTo:create(remaining, 100)
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
    if self.coherentShell then
        self.topMaskLabel:setString("空闲 " .. (self.workerNum-self.workerUseNum) .. " / " .. self.workerNum)
        require("LuaClass/WarmTheme").fit(self.topMaskLabel,230)
    end
    -- 调用存档方法
    if bIsSave then
        DataManager:getInstance():setRoleData(roleProducerQueue, self.workerData, nil)
    end
    if self.coherentShell or not self.bIsNeedRedraw then
        -- 刷新下边的数据
        self:setResourceUIWithData()
    end
end

function ResourceLayer:setWorkerUIWithData()
    if self.coherentShell then return self:renderCoherentWorkers() end
    cclog("开始加载资源上方UI的数据")
    self.workerData = DataManager:getInstance():getRoleData(roleProducerQueue)
    self.workerUseNum = 0
    self.scrollViewContainer:removeAllChildren()
    -- 临时计算高度用的图
    local tempSpr = cc.Sprite:create("Images/UI/Info.png")
    local singleHeight = tempSpr:getContentSize().height + 14
    local edgePadding=8
    local allHeight = singleHeight * #self.workerData + edgePadding*2
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
        tempNode:setPosition(cc.p(self.scrollView:getViewSize().width * 0.5, allHeight - edgePadding - singleHeight * i - singleHeight * 0.5))
        tempNode:setTag(i + 1)
        self.scrollViewContainer:addChild(tempNode)
        local row=ManagementTheme.panel(self.areaWidth-12,singleHeight-5,'paper')
        tempNode:addChild(row,-1)

        -- 首先添加文字框
        local numberBox = ManagementTheme.surfaceLike("Images/UI/NumberBox.png",'section')
        tempNode:addChild(numberBox)

        -- 天健文字框中间的数字label
        local numberLabel = cc.LabelTTF:create(workerTable[dataKeyNum], ManagementTheme.bodyFont(), 24.0)
        numberLabel:setColor(ManagementTheme.colors.ink)
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
        ManagementTheme.skinSDButton(subBtn,'ink')
        subBtn:addChild(ManagementTheme.label('−',32,'action',25,25,.5),2)
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
        ManagementTheme.skinSDButton(addBtn,'coral')
        addBtn:addChild(ManagementTheme.label('+',32,'action',25,25,.5),2)
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
        local nameLabel = cc.LabelTTF:create(workerCsvData["name"], ManagementTheme.bodyFont(), 24.0)
        nameLabel:setColor(ManagementTheme.colors.ink)
        -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        nameLabel:setPosition(cc.p(subBtn:getPositionX() - subBtn:getContentSize().width - nameLabel:getContentSize().width * 0.5, 0))
        nameLabel:setTag(9527)
        tempNode:addChild(nameLabel)

        local infoBtn = ManagementTheme.menuItem(54,54,'ink')
        infoBtn:addChild(ManagementTheme.label('i',27,'action',27,27,.5),2)
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
    self.scrollViewContainer:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
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
    if self.coherentShell then return self:renderCoherentProduction() end
    -- 循环取得的数据创建label
    local lineNum,lineHeight = 4,36
    local visibleCount=0
    for _,v in pairs(self.produceTable) do if v[1]~=0 then visibleCount=visibleCount+1 end end
    local viewSize=self.resourceScrollView:getViewSize()
    local allHeight=math.max(viewSize.height,math.ceil(visibleCount/lineNum)*lineHeight+12)
    self.resourceScrollViewContainer:setContentSize(cc.size(viewSize.width, allHeight))
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
            local label = cc.LabelTTF:create(name..addSub..number, ManagementTheme.bodyFont(), 24.0)
            label:setAnchorPoint(cc.p(0, 1))
            if number < 0 then
                label:setColor(ManagementTheme.colors.danger)
            else
                label:setColor(ManagementTheme.colors.ink)
            end
            
            -- label:enableStroke(cc.c4b(16, 16, 16, 255), 1)
            label:setPosition(cc.p((num % lineNum) * (viewSize.width / lineNum) + 12, allHeight - 6 - (math.ceil((num + 1) / lineNum) - 1) * lineHeight))
            self.resourceScrollViewContainer:addChild(label)
            num = num + 1
        end
    end
    self.resourceScrollView:setContentSize(cc.size(viewSize.width,allHeight))
    self.resourceScrollView:setContentOffset(cc.p(0,viewSize.height-allHeight))
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

-- A collection card, a short worker list and a separate net-production ledger.
-- No rewards or allocation persistence are owned by this presentation layer.
function ResourceLayer:installCoherentSupplyPage()
    local W=require 'LuaClass/WarmTheme'
    local shell=supplyMount(self,'资源采集','分配游民，营地会持续生产补给。','采集',354,590)
    local canvas=shell.canvas
    local card=W.panel(416,128,W.colors.white,8);card:setPosition(cc.p(32,522));canvas:addChild(card,-1)
    supplyLabel(canvas,'手动采集',22,W.colors.ink,48,626,180)
    supplyLabel(canvas,'石头与木头 · 数量浮动',17,W.colors.muted,48,592,214)
    self.gatherYieldLabel=supplyLabel(canvas,'',18,W.colors.muted,48,559,214)
    self.gatherStatus=supplyLabel(canvas,'可以采集',17,W.colors.muted,354,546,156,.5)
    supplyLabel(canvas,'工人分配',22,W.colors.ink,32,491,156)
    supplyMove(self.topMaskLabel,canvas);self.topMaskLabel:setFontSize(19)
    self.topMaskLabel:setAnchorPoint(cc.p(1,.5));self.topMaskLabel:setPosition(cc.p(448,491))
    supplyResizeScroll(self.scrollView,self.scrollViewContainer,canvas,32,276,416,192)
    supplyMove(self.bottomMaskLabel,canvas);self.bottomMaskLabel:setFontSize(20)
    self.bottomMaskLabel:setAnchorPoint(cc.p(0,.5));self.bottomMaskLabel:setPosition(cc.p(32,246))
    supplyResizeScroll(self.resourceScrollView,self.resourceScrollViewContainer,canvas,32,104,416,124)
    self.supplyWorkyard=W.sprite('Images/UI/CleanWorkyard/workyard-v1.png',238,119)
    if self.supplyWorkyard then self.supplyWorkyard:setPosition(cc.p(329,165));canvas:addChild(self.supplyWorkyard,-1) end
    self.supplyScrollHint=supplyLabel(canvas,'',14,W.colors.muted,240,265,416,.5)
    local warehouse=W.button('查看仓库',128,48,function()
        if supplyOpen(self)then zqDispatch:moveToRepository()end
    end,{size=18});warehouse:setPosition(cc.p(384,48));canvas:addChild(warehouse);self.supplyWarehouse=warehouse
    self:setWorkerUIWithData();self:resetWorkData(false);self:setResourceUIWithData()
    local function status()
        local base=DataManager:getInstance():getRoleData(roleGatherUnit)
        self.gatherYieldLabel:setString('采集基数 '..tostring(base));W.fit(self.gatherYieldLabel,214)
        local remain=math.max(0,30-(os.time()-BaseViewLastClickCDTime))
        self.gatherStatus:setString(self.bIsCenterBtnCanClick and '可以采集' or ('休息 '..math.ceil(remain)..' 秒'))
        W.fit(self.gatherStatus,156)
    end
    status();schedule(self.gatherStatus,status,.25)
    GuideController:getInstance():removeRedPoint(self.setBtn)
    if not GuideController:getInstance():getIsHaveStep(3)then GuideController:getInstance():addRedPoint(self.setBtn)end
    local cleanup=cc.Node:create();canvas:addChild(cleanup)
    cleanup:registerScriptHandler(function(event)
        if event=='exit' or event=='cleanup'then
            self.coherentPageDisposed=true
            self.setButtonProgrees:stopAllActions();self.setBtn:stopAllActions();self.setBtn.normalSpr:stopAllActions()
            self:destory()
        end
    end)
end

function ResourceLayer:renderCoherentWorkers()
    local W=require 'LuaClass/WarmTheme'
    self.workerData=DataManager:getInstance():getRoleData(roleProducerQueue)
    self.workerUseNum=0;self.supplyWorkerButtons={}
    local oldHeight=self.scrollViewContainer:getContentSize().height
    local oldOffset=self.scrollView:getContentOffset().y
    self.scrollViewContainer:removeAllChildren()
    local height=math.max(192,#self.workerData*92)
    for index,worker in ipairs(self.workerData)do
        local record=self.workerCsv[worker[dataKeyID]]
        local row=cc.Node:create();row:setContentSize(cc.size(416,86));row:setPosition(cc.p(0,height-index*92+6));row:setTag(index)
        self.scrollViewContainer:addChild(row)
        local paper=W.panel(416,86,W.colors.white,8);row:addChild(paper,-1)
        local art=require('LuaClass/CleanResourceArt').sprite(record.produce[1] and record.produce[1][1],48)
        if art then art:setPosition(cc.p(35,44));row:addChild(art) end
        local name=supplyLabel(row,record.name,21,W.colors.ink,68,60,164);name:setTag(9527)
        local outputs={}
        for _,product in ipairs(record.produce)do
            local csv=self.produceCsv[product[1]]
            if csv then outputs[#outputs+1]=csv.name..' +'..product[2]end
        end
        local note=supplyLabel(row,table.concat(outputs,' · '),17,W.colors.muted,68,28,164)
        local number=supplyLabel(row,worker[dataKeyNum],18,W.colors.ink,324,43,88,.5)
        local function change(delta)
            if not supplyOpen(self) or row:getParent()~=self.scrollViewContainer then return end
            local value=tonumber(number:getString())
            if delta<0 and value<=0 then return end
            if delta>0 and self.workerNum-self.workerUseNum<=0 then
                ToastUtil:downString('游民数量不足，请建造民宅',true);return
            end
            number:setString(tostring(value+delta));W.fit(number,88)
            self.workerUseNum=self.workerUseNum+delta;worker[dataKeyNum]=value+delta
            self.bIsNeedRedraw=false;self:resetWorkData(true);self.bIsNeedRedraw=true
        end
        local function stepButton(text,x,delta)
            local button=SDButton:create('Images/UI/SubCircleBtn.png','Images/UI/SubCircleBtn1.png',function()change(delta)end)
            ManagementTheme.skinSDButton(button,'section')
            local size=button:getContentSize();button:setScale(44/size.width)
            button:setPosition(cc.p(x,43));button:setSwallowTouches(false)
            button:addChild(W.label(text,30,W.colors.ink,size.width/2,size.height/2,false,.5))
            button:registerLongPressed(function()change(delta)end);supplyClip(button,self.scrollView);row:addChild(button)
            return button
        end
        local sub=stepButton('−',258,-1);local add=stepButton('+',390,1)
        local light=cc.Node:create();light:setPosition(add:getPosition());light:setTag(9528);light:setVisible(false);row:addChild(light)
        local mark=W.panel(44,3,W.colors.gold,0);mark:setPosition(cc.p(-22,-25));light:addChild(mark)
        -- The name/production area is a real non-swallowing information target.
        local info=SDButton:create('Images/UI/Info.png','Images/UI/Info.png',function()
            if supplyOpen(self)then supplyInformation(self,record.name,record.produceDesc..' '..record.resumeDesc)end
        end)
        info.normalSpr:setOpacity(0);info.selectSpr:setOpacity(0)
        info.normalSpr:setContentSize(cc.size(228,76));info.selectSpr:setContentSize(cc.size(228,76))
        info:setContentSize(cc.size(228,76));info:setPosition(cc.p(116,43));info:setSwallowTouches(false)
        supplyClip(info,self.scrollView);row:addChild(info);self.supplyWorkerButtons[index]={add=add,sub=sub,info=info,number=number,name=name,note=note,art=art}
        self.workerUseNum=self.workerUseNum+tonumber(worker[dataKeyNum])
    end
    if #self.workerData==0 then
        supplyLabel(self.scrollViewContainer,'还没有可分配的工作',21,W.colors.ink,16,154,384)
        supplyLabel(self.scrollViewContainer,'先采集石头和木头，再建造生产设施。',18,W.colors.muted,16,116,384)
    end
    self.scrollViewContainer:setContentSize(cc.size(416,height));self.scrollView:setContentSize(cc.size(416,height))
    local offset=self.supplyWorkersRendered and math.max(192-height,math.min(0,oldOffset+oldHeight-height))or 192-height
    self.scrollView:setContentOffset(cc.p(0,offset));self.supplyWorkersRendered=true
    if self.supplyScrollHint then self.supplyScrollHint:setString(#self.workerData>2 and ('上下滑动 · '..#self.workerData..' 项工作') or '') end
end

function ResourceLayer:renderCoherentProduction()
    local W=require 'LuaClass/WarmTheme';local rows={}
    for id,item in pairs(self.produceTable)do if item[1]~=0 then rows[#rows+1]={id=id,num=item[1],name=item[2]}end end
    table.sort(rows,function(a,b)return tonumber(a.id)<tonumber(b.id)end)
    local compact=#rows<=2
    if self.supplyWorkyard then self.supplyWorkyard:setVisible(compact) end
    local columns=compact and 1 or 2;local width=compact and 178 or 416
    self.resourceScrollView:setViewSize(cc.size(width,124))
    local height=math.max(124,math.ceil(#rows/columns)*48)
    for index,item in ipairs(rows)do
        local column=(index-1)%columns;local y=height-math.floor((index-1)/columns)*48-24
        local x=column*212
        supplyLabel(self.resourceScrollViewContainer,item.name,18,W.colors.ink,x+10,y,96)
        supplyLabel(self.resourceScrollViewContainer,(item.num>0 and '+'or '')..item.num,19,item.num<0 and ManagementTheme.colors.danger or W.colors.sea,x+(compact and 174 or 200),y,compact and 72 or 92,1)
    end
    if #rows==0 then
        supplyLabel(self.resourceScrollViewContainer,'分配工人后\n查看净收获',18,W.colors.muted,10,height-30,164)
    end
    self.resourceScrollViewContainer:setContentSize(cc.size(width,height));self.resourceScrollView:setContentSize(cc.size(width,height))
    self.resourceScrollView:setContentOffset(cc.p(0,124-height))
end
