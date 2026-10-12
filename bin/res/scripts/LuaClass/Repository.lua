require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/ManagementTheme"
require "LuaClass/SDButton"
require "LuaClass/ItemIcon"


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

RepositoryLayer = class("RepositoryLayer", function ()
	return BaseView:create()
end)

RepositoryLayer.__index = RepositoryLayer
RepositoryLayer.scrollView = nil
RepositoryLayer.scrollViewContainer = nil
RepositoryLayer.produceCsv = nil
RepositoryLayer.lastSortType = "0"
RepositoryLayer.lastUpdateMd5 = nil

function RepositoryLayer:create()
	local view = RepositoryLayer.new()
	if view and view:init() then
		return view
	end
	return nil
end

function RepositoryLayer:destory()
	DataManager:getInstance():unregisterEvent(rolePack, "repository")
	DataManager:getInstance():unregisterEvent(roleGuideStep, "repository")
	DataManager:getInstance():unregisterEvent(roleMapInfo, "RepositoryLayer")

	-- 调用父类的析构
	self:superDestory()
end

function RepositoryLayer:init()
    local ok=self:initLegacy()
    if ok and rawget(_G,'WARM_PIRATE_V1')~=false then self:installCoherentSupplyPage() end
    return ok
end

function RepositoryLayer:showInfoBox(text)
    if self.coherentShell then return supplyInformation(self,'物品说明',text) end
    return BaseView.showInfoBox(self,text)
end

function RepositoryLayer:initLegacy()
    self:applyManagementTheme()
    DataManager:getInstance():registerEvent(roleMapInfo, "RepositoryLayer", function()
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

	self.produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

	local visibleSize = cc.Director:getInstance():getVisibleSize()
	local origin = cc.Director:getInstance():getVisibleOrigin()

	-- 设置title文字
	self:setTitleString("仓 库")

	-- 修改顶部左侧按钮显示
    self.topLeftBtn:setVisible(true)

    -- 修改顶部左侧侧按钮为快速出征
    self:resetTopLeftButtonToExpedition()

	-- 设置下方信息界面
	self:addInfoNode("船 坞", function()
		zqDispatch:moveToExpedition()
	end, "资 源", function()
		zqDispatch:moveToResource()
	end, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
		-- cclog("点击了炼金按钮")
		DataManager:getInstance():AlchemyButtonDidClick()
	end, nil, true, zqAlchemyTime, false)

	-- 添加顶部筛选按钮组的背景
	local topButtonGroup = ManagementTheme.surfaceLike("Images/UI/TopButtonGroupBg.png",'section')
	topButtonGroup:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height - UITopHeight - self.titleHeight - topButtonGroup:getContentSize().height * 0.5))
	self:addChild(topButtonGroup)

	-- 添加全部筛选按钮
	local allBtnNormal = ManagementTheme.tab("全部",false,104,45)
	local allBtnSelected = ManagementTheme.tab("全部",true,104,45)
	local allBtn = cc.MenuItemToggle:create(allBtnNormal, allBtnSelected)
	allBtn:setPosition(cc.p(self.titleLabel:getPositionX() - 220, topButtonGroup:getPositionY()))

	allBtn:setSelectedIndex(1)

	-- 添加装备按钮
	local equipBtnNormal = ManagementTheme.tab("装备",false,104,45)
	local equipBtnSelected = ManagementTheme.tab("装备",true,104,45)
	local equipBtn = cc.MenuItemToggle:create(equipBtnNormal, equipBtnSelected)
	equipBtn:setPosition(cc.p(self.titleLabel:getPositionX() - 108, allBtn:getPositionY()))

	-- 添加资源按钮
	local resourceBtnNormal = ManagementTheme.tab("资源",false,104,45)
	local resourceBtnSelected = ManagementTheme.tab("资源",true,104,45)
	local resourceBtn = cc.MenuItemToggle:create(resourceBtnNormal, resourceBtnSelected)
	resourceBtn:setPosition(cc.p(self.titleLabel:getPositionX(), allBtn:getPositionY()))

	-- 添加碎片按钮
	local pieceBtnNormal = ManagementTheme.tab("碎片",false,104,45)
	local pieceBtnSelected = ManagementTheme.tab("碎片",true,104,45)
	local pieceBtn = cc.MenuItemToggle:create(pieceBtnNormal, pieceBtnSelected)
	pieceBtn:setPosition(cc.p(self.titleLabel:getPositionX() + 108, allBtn:getPositionY()))

	-- 添加其他按钮
	local otherBtnNormal = ManagementTheme.tab("其他",false,104,45)
	local otherBtnSelected = ManagementTheme.tab("其他",true,104,45)
	local otherBtn = cc.MenuItemToggle:create(otherBtnNormal, otherBtnSelected)
	otherBtn:setPosition(cc.p(self.titleLabel:getPositionX() + 220, allBtn:getPositionY()))

	local function buttonClickToggle(tag)
		-- body
		allBtn:setSelectedIndex(0)
		equipBtn:setSelectedIndex(0)
		resourceBtn:setSelectedIndex(0)
		pieceBtn:setSelectedIndex(0)
		otherBtn:setSelectedIndex(0)
		-- 刷新数据
		self:initBagDataWithType(tag.."")
	end
	allBtn:registerScriptTapHandler(function()
		buttonClickToggle(0)
		allBtn:setSelectedIndex(1)
	end)
	equipBtn:registerScriptTapHandler(function()
		buttonClickToggle(1)
		equipBtn:setSelectedIndex(1)
	end)
	resourceBtn:registerScriptTapHandler(function()
		buttonClickToggle(2)
		resourceBtn:setSelectedIndex(1)
	end)
	pieceBtn:registerScriptTapHandler(function()
		buttonClickToggle(3)
		pieceBtn:setSelectedIndex(1)
	end)
	otherBtn:registerScriptTapHandler(function()
		buttonClickToggle(4)
		otherBtn:setSelectedIndex(1)
	end)

	local btnTable = {allBtn, equipBtn, resourceBtn, pieceBtn, otherBtn}
	local menu = cc.Menu:create(unpack(btnTable))
	menu:setPosition(cc.p(0, 0))
	self:addChild(menu)

	-- 添加没有任何道具的时候的提示label
	-- local MaskAlertLabel = cc.LabelTTF:create("请点击下方【炼金】按钮", BoldFont, 32.0)
 --    MaskAlertLabel:setPosition(self.centerPos)
 --    MaskAlertLabel:setColor(WriteColor)
 --    -- MaskAlertLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
 --    self:addChild(MaskAlertLabel)

	-- 添加scrollView
	self.scrollViewContainer = cc.Layer:create()
    local scrollViewSize = cc.size(self.areaWidth, self.areaHeight - self.titleHeight)
    self.scrollViewContainer:setContentSize(scrollViewSize)
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(cc.p(self.centerPos.x - self.areaWidth * 0.5, self.centerPos.y - self.areaHeight * 0.5))
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollView:setViewSize(scrollViewSize)
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView.bIsScrollView = true
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    self.scrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)

    self:initBagDataWithType()

    -- 更新新手引导界面显示
    local guideNode = nil
    local finger = nil
    local function resetGuideStatus()
        if self.coherentShell then self:refreshCoherentRepositoryGuide() end
        -- cclog("repository新手引导步骤变化")
        -- 没走第一步之前的操作
        if GuideController:getInstance():getIsHaveStep(1) then
        	self.setBtn:setEnabled(true)
        	if finger ~= nil then
                finger:removeFromParent()
                finger = nil
            end
            
            if GuideController:getInstance():getIsHaveStep(101, true) then
                -- 干掉炼金按钮的红点
                GuideController:getInstance():removeRedPoint(self.setBtn)
            end
        else
        	-- 默认禁用炼金按钮的点击
            self.setBtn:setEnabled(false)
            self.setBtnText:runAction(cc.FadeOut:create(0.0))
            -- 什么都没做过的话在炼金上显示红点
            GuideController:getInstance():addRedPoint(self.setBtn)
            self.setBtn:runAction(cc.FadeOut:create(0.0))
            self.setBtn:runAction(cc.Sequence:create(cc.DelayTime:create(6.2), cc.FadeIn:create(0.0), cc.ScaleTo:create(0.0, 2.0), cc.EaseExponentialIn:create(cc.ScaleTo:create(0.6, 1.0)), cc.DelayTime:create(2.6), cc.CallFunc:create(function()
            	-- body
            	self.setBtn:setEnabled(true)
            	self.setBtnText:runAction(cc.FadeIn:create(0.6))
            	-- 添加引导的小手动画, 点击10次之后消失~
                finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
                finger:setAnchorPoint(0,1)
                finger:setScale(0.8)
                finger:setPosition(cc.p(self.setBtn:getPositionX(), self.setBtn:getPositionY() + self.setBtn:getContentSize().height * 1.2))
                local fingerParent=self.coherentShell and self.coherentShell.canvas or self
                fingerParent:addChild(finger, 9999)

                local spriteFrame = cc.SpriteFrameCache:getInstance()   
                for i = 1, 2 do
                    local sprName = string.format("Images/Map/Guide/finger_%d.png", i)
                    local tempSprite = cc.Sprite:create(sprName)
                    if tempSprite ~= nil then
                        spriteFrame:addSpriteFrame(tempSprite:getSpriteFrame(), sprName)
                    end
                end
                local touchAni = EffectUtil:getAnimate("Images/Map/Guide/finger_%d.png", 1, 2, 0.3)
                finger:runAction(cc.RepeatForever:create(touchAni))
            end)))
        end
        -- 建设完仓库之后的操作
        if GuideController:getInstance():getIsHaveStep(2) then
            self:setTitleString("仓 库")
            self.storeMenu:setVisible(true)
            menu:setVisible(true)
            topButtonGroup:setVisible(true)
            self.scrollView:setVisible(true)
            -- MaskAlertLabel:setVisible(false)
        else
        	-- 先设置好各种控件的状态
        	self:setTitleString("荒 岛")
        	self.storeMenu:setVisible(false)
        	menu:setVisible(false)
        	topButtonGroup:setVisible(false)
        	self.scrollView:setVisible(false)
        	-- MaskAlertLabel:setVisible(not GuideController:getInstance():getIsHaveStep(1))
            if not GuideController:getInstance():getIsHaveStep(1) then
	            -- 隐藏父节点的一些内容
	            self.titleBg:setOpacity(0.0)
	            self.bgIcon:setOpacity(0.0)
	            -- MaskAlertLabel:setOpacity(0.0)
	            self.mainBg:setOpacity(0.0)
	            -- 第一次走引导的时候按顺序播放动画，先显示荒岛和背景图
	            self.titleBg:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.FadeIn:create(1.6)))
	            self.mainBg:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.FadeIn:create(1.6)))
	            -- 显示海盗船
	            self.bgIcon:runAction(cc.Sequence:create(cc.DelayTime:create(3.6), cc.FadeIn:create(1.6)))
	            -- MaskAlertLabel:runAction(cc.Sequence:create(cc.FadeOut:create(0.0), cc.DelayTime:create(10.8), cc.FadeIn:create(1.6)))
	        end
        end
        -- 如果解锁了船坞，那么现实左侧快速出征按钮
        -- self.topLeftBtn:setVisible(GuideController:getInstance():getIsHaveStep(8))
        -- 如果走了这步，那么就不显示钻石商城的红点鸟~
        if GuideController:getInstance():getIsHaveStep(61) then
			GuideController:getInstance():removeRedPoint(self.topRightBtn)
		end
    end
    DataManager:getInstance():registerEvent(roleGuideStep, "repository", resetGuideStatus)

    -- 初始化的时候默认调用一次
    resetGuideStatus()

--    require "LuaClass/EffectUtil"
--    local ani = EffectUtil:createAnimation("Effect/Animation/baofengyu.plist", 0)
--    ani:setScale(6.0)
--    ani:setPosition(320, 568)
--    self:addChild(ani)
	
	-- 如果是首次出征回来
	if GuideController:getInstance():getIsHaveStep(60) then
		-- 没显示过红点
		if not GuideController:getInstance():getIsHaveStep(61) then
			GuideController:getInstance():addRedPoint(self.topRightBtn)
		else
			GuideController:getInstance():removeRedPoint(self.topRightBtn)
		end
	end
	DataManager:getInstance():registerEvent(rolePack, "repository", function()
    	-- cclog("刷新背包数据")
    	self:reloadData()
    end)
	return true
end

function RepositoryLayer:setIsReload(bIsReload)
	if bIsReload then
		DataManager:getInstance():registerEvent(rolePack, "repository", function()
	    	-- cclog("刷新背包数据")
	    	self:reloadData()
	    end)
	else
		DataManager:getInstance():unregisterEvent(rolePack, "repository")
	end
end

function RepositoryLayer:reloadData()
	-- print("刷新背包数据")
	local jsons = json.encode(DataManager:getInstance():getRoleData(rolePack))
	local jsonMd5 = MD5(jsons, string.len(jsons)):hexdigest()
	-- 如果数据没变还刷新鸡毛啊。。。
	if self.lastUpdateMd5 == nil or self.lastUpdateMd5 ~= jsonMd5 then
		self:initBagDataWithType(self.lastSortType)
		self.lastUpdateMd5 = jsonMd5
	end
end

function RepositoryLayer:initBagDataWithType(sortType)
    if self.coherentShell then return self:renderCoherentInventory(sortType) end
	if sortType == nil then
		self.lastSortType = "0"
	else
		self.lastSortType = sortType
	end
	
	-- 先删除上边所有内容
	self.scrollViewContainer:removeAllChildren()

	local produceTable = DataManager:getInstance():getRoleData(rolePack)
	local lineHeight = 76.0
	local dataNum = 0
	-- 要先计算数据
	for k,v in pairs(produceTable) do
		local csvData = self.produceCsv[k]
        if csvData ~= nil then
	        local number = v
	        local display = csvData["display"]
	        local itemType = csvData["type"]
	        if number > 0 and display == "1" and (itemType == self.lastSortType or self.lastSortType == "0") then
				dataNum = dataNum + 1
			end
		end
	end
	-- 循环取得的数据创建label
    local allHeight = math.ceil(dataNum / 2) * lineHeight
    if allHeight < self.scrollView:getViewSize().height then
        allHeight = self.scrollView:getViewSize().height
    end
	local num = 0
	local leftSpr = nil
    -- Paper/materials and runtime TTF labels require their alpha channel.
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    for k,v in pairs(produceTable) do
        -- print(k,v)
        local csvData = self.produceCsv[k]
        if csvData ~= nil then
	        local number = v
	        local name = csvData["name"]
	        local display = csvData["display"]
	        local itemType = csvData["type"]
	        local price = tonumber(csvData["worth"])
	        if number > 0 and display == "1" and (itemType == self.lastSortType or self.lastSortType == "0") then
                leftSpr = ItemIcon.sdButton(csvData["iconName"], function ()
	                -- 点击之后显示详情 
	                if csvData["desc"] ~= nil and csvData["desc"] ~= "" then
	                	self:showInfoBox(csvData["desc"])
	                else
	                	self:showInfoBox("神没有赋予这个物品任何说明")
	                end
	            end)
	            leftSpr:setSwallowTouches(false)
	            leftSpr:addClickArea(cc.rect(0, 10, 200, 20))
        		leftSpr:registerLongPressedActiveOnce(function()
		            -- body
		            cclog("长按出售")
		            if price == nil or price == "" then
		            	ToastUtil:downString("抱歉，商人不收购此物品")
		            	return
		            end
		            local _alert = AlertView:create(0,0, "出售道具",nil)

		            -- 添加顶部的说明文字
		            local infoLabel = cc.LabelTTF:create("出售"..name.." 单价:"..price, ManagementTheme.bodyFont(), 28.0)
                infoLabel:setColor(ManagementTheme.colors.white)
	            	-- infoLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            	infoLabel:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + 114))
	            	_alert:addChild(infoLabel)

		            local _menuButton1 = ManagementTheme.menuItem(190,64,'ink')
		            _menuButton1:registerScriptTapHandler(function ()
		                -- body
		                if DataManager:getInstance():addPackItemWithId(k, -1) then
		                	DataManager:getInstance():addCoin(price)
		                	ToastUtil:downString("成功出售 1个"..name.." 金币+"..price)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton2 = ManagementTheme.menuItem(190,64,'ink')
		            _menuButton2:registerScriptTapHandler(function ()
		                -- body
		                local sellNum = 10
		                if number < 10 then
		                	sellNum = number
		                end
		                if DataManager:getInstance():addPackItemWithId(k, -sellNum) then
		                	DataManager:getInstance():addCoin(price * sellNum)
		                	ToastUtil:downString("成功出售 "..sellNum.."个"..name.." 金币+"..price * sellNum)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton3 = ManagementTheme.menuItem(190,64,'ink')
		            _menuButton3:registerScriptTapHandler(function ()
		                -- body
		                sellNum = number
		                if DataManager:getInstance():addPackItemWithId(k, -sellNum) then
		                	DataManager:getInstance():addCoin(price * sellNum)
		                	ToastUtil:downString("成功出售 "..sellNum.."个"..name.." 金币+"..price * sellNum)
		                end
		                _alert:removeFromParent()
		            end)

		            local _menuButton1Lable = cc.LabelTTF:create("出售1个", ManagementTheme.bodyFont(), 30.0)
		            _menuButton1Lable:setPosition(cc.p(_menuButton1:getContentSize().width * 0.5,_menuButton1:getContentSize().height * 0.5))
		            -- _menuButton1Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton1:addChild(_menuButton1Lable)

		            local _menuButton2Lable = cc.LabelTTF:create("出售10个", ManagementTheme.bodyFont(), 30.0)
		            _menuButton2Lable:setPosition(cc.p(_menuButton2:getContentSize().width * 0.5,_menuButton2:getContentSize().height * 0.5))
		            -- _menuButton2Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton2:addChild(_menuButton2Lable)

		            local _menuButton3Lable = cc.LabelTTF:create("出售所有", ManagementTheme.bodyFont(), 30.0)
		            _menuButton3Lable:setPosition(cc.p(_menuButton3:getContentSize().width * 0.5,_menuButton3:getContentSize().height * 0.5))
		            -- _menuButton3Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
		            _menuButton3:addChild(_menuButton3Lable)


		            _menuButton1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + _menuButton1:getContentSize().height * 2 - 66))
		            _menuButton2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - 46))
		            _menuButton3:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - _menuButton1:getContentSize().height * 2 - 26))
		            local menu = cc.Menu:create(_menuButton1,_menuButton2,_menuButton3)
		            menu:setPosition(0.0, 0.0)
		            _alert:addChild(menu)
        		end)
	        	leftSpr:setPosition(cc.p((num % 2) * (self.scrollViewContainer:getContentSize().width / 2) + 40, allHeight - (math.ceil((num + 1) / 2) - 1) * lineHeight - leftSpr:getContentSize().height * 0.5))
	        	self.scrollViewContainer:addChild(leftSpr)
                local rowWidth=self.scrollViewContainer:getContentSize().width/2
                local row=ManagementTheme.panel(rowWidth-10,lineHeight-6,'paper')
                row:setPosition(cc.p((num%2)*rowWidth+rowWidth/2,allHeight-math.floor(num/2)*lineHeight-lineHeight/2))
                self.scrollViewContainer:addChild(row,-1)

	        	-- 添加名字文本
	            local label = cc.LabelTTF:create(name, ManagementTheme.bodyFont(), 24.0)
	            label:setAnchorPoint(cc.p(0, 1))
	            label:setColor(ManagementTheme.colors.ink)
	            -- label:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            label:setPosition(cc.p(leftSpr:getPositionX() + leftSpr:getContentSize().width * 0.6, leftSpr:getPositionY() + leftSpr:getContentSize().height * 0.5))
	            ManagementTheme.styleLabel(label,'body',self.scrollViewContainer:getContentSize().width/2-96)
	            self.scrollViewContainer:addChild(label)

	            -- 添加数量文本
	            local numLabel = cc.LabelTTF:create(number.."", ManagementTheme.bodyFont(), 28.0)
	            numLabel:setAnchorPoint(cc.p(0, 1))
	            numLabel:setColor(ManagementTheme.colors.muted)
                numLabel:setFontSize(22)
	            -- numLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	            numLabel:setPosition(cc.p(leftSpr:getPositionX() + leftSpr:getContentSize().width * 0.6, label:getPositionY() - 30.0))
	            self.scrollViewContainer:addChild(numLabel)

	            num = num + 1
	        end
	    end
    end
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end

function RepositoryLayer:installCoherentSupplyPage()
    local W=require 'LuaClass/WarmTheme'
    local shell=supplyMount(self,'仓库','点按物品查看说明，长按选择出售数量。','炼金',354,160)
    local canvas=shell.canvas
    self.supplyTabs={};self.supplyTabsNode=cc.Node:create();canvas:addChild(self.supplyTabsNode)
    for index,title in ipairs({'全部','装备','资源','碎片','其他'})do
        local button=W.button(title,78,44,function()
            if supplyOpen(self)then self:initBagDataWithType(tostring(index-1))end
        end,{size=19})
        button:setPosition(cc.p(71+(index-1)*84.5,628));self.supplyTabsNode:addChild(button)
        self.supplyTabs[index]=button
    end
    self.supplyStockLabel=supplyLabel(canvas,'',18,W.colors.muted,32,586,416)
    supplyResizeScroll(self.scrollView,self.scrollViewContainer,canvas,32,248,416,316)
    local card=W.panel(416,128,W.colors.white,8);card:setPosition(cc.p(32,104));canvas:addChild(card,-1)
    supplyLabel(canvas,'炼金',22,W.colors.ink,48,207,198)
    self.alchemyYieldLabel=supplyLabel(canvas,'',18,W.colors.muted,48,174,206)
    self.alchemyStatus=supplyLabel(canvas,'',17,W.colors.muted,48,140,216)
    self.supplyLocked=supplyLabel(canvas,'仓库尚未建成\n继续炼金，准备建设所需的金币。',21,W.colors.ink,48,420,384)
    self.supplyLocked:setDimensions(cc.size(384,100))
    local resource=W.button('分配工人',128,48,function()
        if supplyOpen(self)then zqDispatch:moveToResource()end
    end,{size=18});resource:setPosition(cc.p(384,48));canvas:addChild(resource);self.supplyResource=resource
    local function status()
        self.alchemyYieldLabel:setString('每次获得 '..tostring(DataManager:getInstance():getRoleData(roleAlchemyUnit))..' 金币')
        W.fit(self.alchemyYieldLabel,206)
        if not self.setBtn.bIsEnable then self.alchemyStatus:setString('正在准备炼金…')
        elseif not self.bIsCenterBtnCanClick then self.alchemyStatus:setString('炼金中…')
        elseif self.setBtn.onLongPressed then self.alchemyStatus:setString('可点按，也可长按连续炼金')
        else self.alchemyStatus:setString('点按炼金')end
        W.fit(self.alchemyStatus,216)
    end
    status();schedule(self.alchemyStatus,status,.1)
    self:initBagDataWithType(self.lastSortType);self:refreshCoherentRepositoryGuide()
    GuideController:getInstance():removeRedPoint(self.setBtn)
    if not GuideController:getInstance():getIsHaveStep(101,true)then GuideController:getInstance():addRedPoint(self.setBtn)end
    local cleanup=cc.Node:create();canvas:addChild(cleanup)
    cleanup:registerScriptHandler(function(event)
        if event=='exit' or event=='cleanup'then
            self.coherentPageDisposed=true
            self.setButtonProgrees:stopAllActions();self.setBtn:stopAllActions();self.setBtn.normalSpr:stopAllActions()
            self:destory()
        end
    end)
end

function RepositoryLayer:refreshCoherentRepositoryGuide()
    local unlocked=GuideController:getInstance():getIsHaveStep(2)
    self.coherentShell.heading:setString(unlocked and '仓库' or '荒岛')
    self.coherentShell.subtitle:setString(unlocked and '点按物品查看说明，长按选择出售数量。' or '先炼金积累金币，再建造自己的仓库。')
    local ready=GuideController:getInstance():getIsHaveStep(1)
    self.supplyLocked:setString(ready and '建设已解锁\n返回船上，进入港务建造仓库。' or '仓库尚未建成\n继续炼金，准备建设所需的金币。')
    self.supplyTabsNode:setVisible(unlocked);self.scrollView:setVisible(unlocked)
    self.supplyStockLabel:setVisible(unlocked);self.supplyLocked:setVisible(not unlocked)
    self.supplyResource:setVisible(unlocked)
end

function RepositoryLayer:renderCoherentInventory(sortType)
    local W=require 'LuaClass/WarmTheme'
    local oldSort=self.lastSortType
    self.lastSortType=sortType or '0'
    local oldHeight=self.scrollViewContainer:getContentSize().height;local oldOffset=self.scrollView:getContentOffset().y
    self.supplyInventoryGeneration=(self.supplyInventoryGeneration or 0)+1
    local generation=self.supplyInventoryGeneration
    self.scrollViewContainer:removeAllChildren();self.supplyInventoryRows={}
    local rows={}
    for id,number in pairs(DataManager:getInstance():getRoleData(rolePack))do
        local csv=self.produceCsv[id]
        if csv and number>0 and csv.display=='1' and (self.lastSortType=='0' or csv.type==self.lastSortType)then
            rows[#rows+1]={id=id,number=number,csv=csv}
        end
    end
    -- Stable presentation order prevents rows moving under a held finger.
    table.sort(rows,function(a,b)return tonumber(a.id)<tonumber(b.id)end)
    local height=math.max(316,#rows*76)
    for index,data in ipairs(rows)do
        local csv,id,number=data.csv,data.id,data.number
        local y=height-index*76+5
        local row=W.panel(416,70,W.colors.white,8);row:setPosition(cc.p(0,y));self.scrollViewContainer:addChild(row)
        local function active()return supplyOpen(self)and generation==self.supplyInventoryGeneration end
        local icon=ItemIcon.sdButton(csv.iconName,function()
            if active()then supplyInformation(self,csv.name,csv.desc and csv.desc~='' and csv.desc or '神没有赋予这个物品任何说明')end
        end)
        local iconSize=icon:getContentSize();icon:setScale(math.min(48/iconSize.width,48/iconSize.height))
        icon:setPosition(cc.p(36,35));icon:setSwallowTouches(false)
        -- The entire row remains the original icon's single/long-press target.
        -- Convert the desired row dimensions back into the icon's local units.
        local scale=icon:getScaleX()
        icon:addClickArea(cc.rect(iconSize.width/2-32/scale,iconSize.height/2-31/scale,408/scale-iconSize.width,62/scale-iconSize.height))
        icon:registerLongPressedActiveOnce(function()
            if active()then self:openCoherentSale(id,csv.name,tonumber(csv.worth),number)end
        end)
        supplyClip(icon,self.scrollView);row:addChild(icon)
        supplyLabel(row,csv.name,21,W.colors.ink,74,47,252)
        supplyLabel(row,'持有 '..number,18,W.colors.muted,74,21,310)
        supplyLabel(row,'›',25,W.colors.muted,390,35,20,.5)
        self.supplyInventoryRows[index]={id=id,number=number,button=icon,row=row}
    end
    if #rows==0 then
        supplyLabel(self.scrollViewContainer,'这里还没有物品',22,W.colors.ink,16,268,384)
        supplyLabel(self.scrollViewContainer,'采集、生产或航行带回的物品会存入仓库。',18,W.colors.muted,16,229,384)
    end
    self.supplyStockLabel:setString('当前分类 · '..#rows..' 种物品')
    for index,tab in ipairs(self.supplyTabs)do
        local selected=tostring(index-1)==self.lastSortType
        tab.label:setColor(selected and W.colors.white or W.colors.ink)
        tab.item:setNormalImage(W.panel(78,44,selected and W.colors.ink or W.colors.paper,8))
    end
    self.scrollViewContainer:setContentSize(cc.size(416,height));self.scrollView:setContentSize(cc.size(416,height))
    local keep=self.supplyInventoryRendered and oldSort==self.lastSortType
    self.scrollView:setContentOffset(cc.p(0,keep and math.max(316-height,math.min(0,oldOffset+oldHeight-height))or 316-height))
    self.supplyInventoryRendered=true
end

function RepositoryLayer:openCoherentSale(id,name,price,number)
    if not supplyOpen(self)then return end
    if price==nil then ToastUtil:downString('抱歉，商人不收购此物品');return end
    local function sell(quantity)
        if self.coherentPageDisposed or self.coherentPageLeaving then return end
        -- Original sale owner and ordering: deduct first, grant only on success.
        if DataManager:getInstance():addPackItemWithId(id,-quantity)then
            DataManager:getInstance():addCoin(price*quantity)
            ToastUtil:downString('成功出售 '..quantity..'个'..name..' 金币+'..price*quantity)
        end
    end
    local D=require 'LuaClass/WarmDialog'
    return D.show('出售 '..name,'持有 '..number..' 个 · 单价 '..price..' 金币',{
        {label='出售 1 个',detail='获得 '..price..' 金币',action=function()sell(1)end},
        {label='出售 10 个',detail='本次 '..math.min(10,number)..' 个 · 获得 '..price*math.min(10,number)..' 金币',action=function()sell(math.min(10,number))end},
        {label='出售所有',detail='本次 '..number..' 个 · 获得 '..price*number..' 金币',action=function()sell(number)end},
        {label='暂不出售'}},self)
end
