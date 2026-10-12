require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/DialogTheme"

local beganPos = cc.p(0,0)

-------------------------------TouchesMethod-----------------------------------
function onTouchBegan( target,touch, event )
	beganPos = touch:getLocation()
	print("baseView beganPos:",beganPos)
    target.willCloseInfos = true
	return true
end

function onTouchMoved( touch, event )

end

function onTouchEnd( target, touch, event )
    print("target.infoNode:setVisible(false)")
    
    if target.willCloseInfos then
        target.infoNode:setVisible(false)
    end

	local endPos = touch:getLocation()
	local slope = (endPos.y - beganPos.y) / (endPos.x - beganPos.x)
    local distanceX = endPos.x - beganPos.x
        -- cclog("slope:%f", slope)
        -- 首先判断斜率是否符合触发条件
        if slope < 0.5 and slope > -0.5 then
            -- 符合的话再判断移动的距离是否大于指定数值
            if cc.pGetDistance(endPos, beganPos) > 30 then
            	if distanceX > 0 then
            		--触发滑动关闭的接口
            		target:viewWillClose(false)
            	end
            end
        end
	beganPos = nil
end

--touch事件异常结束，要将对应的变量清零
function onTouchCancelled( target, touch, event )
	print("onTouchCancelled")

	if touchcount > 0 then
			target.jointed.enable = bengainStatue
			beganLen = 0
			_dragging = true
			touchTable = nil
			touchTable = {}
	end

	touchcount = 0
	-- zoomCenter = cc.p(0,0)
	--重置判断变量
	beganPos = cc.p(0,0)
	lastPos = cc.p(0,0)
	endPos = cc.p(0,0)
	cur_touchContentOffset = 0
end
-------------------------------TouchesMethod------------------------------------

-------------------------------EventDetailsCell-----------------------------------
EventBaseCell = class("EventBaseCell",function ()
    return cc.Node:create()
end)

EventBaseCell.__index = EventBaseCell
EventBaseCell.size = cc.size(0,0)

function EventBaseCell:create()
    local cell = EventBaseCell.new()
    if cell and cell:init() then
        return cell
    end
    
    return nil
end

function EventBaseCell:init()
    return true;
end
-------------------------------EventDetailsCell-----------------------------------

---------------------------------EventBaseView------------------------------------
EventBaseView = class("EventBaseView",function ()
	 return cc.Layer:create()
end)

EventBaseView.__index = EventBaseView
EventBaseView.titleLabel = nil
EventBaseView.topHeight = 0
EventBaseView.buttomHeight = 0
EventBaseView.tableview = nil
EventBaseView.centerPos = cc.p(0, 0)
EventBaseView.originPos = cc.p(0, 0)
EventBaseView.areaHeight = 0
EventBaseView.areaWidth = 0
EventBaseView.closeCallback = nil
EventBaseView.willCloseInfos = false

function EventBaseView:create()
	local view = EventBaseView.new()

    if view and view:init() then
        return view
    end
    
    return nil
end

function EventBaseView:init()
    if EventPageUI and EventPageUI.theme() then return self:initCoherentEventBase() end

	print(" EventBaseView:init")

	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- The same harbor paint sits quietly behind the event roster.
    DialogTheme.screen(self, visibleSize)

    ------------------------- 顶部试图 -------------------------
    -- 添加上边标题栏的背景
    local pTopBg = DialogTheme.cardFromLegacy("Images/UI/TitleBg.png", "ink")
    self.topHeight = pTopBg:getContentSize().height
    pTopBg:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height - self.topHeight*0.5))
    self:addChild(pTopBg)

    local TopPosY = pTopBg:getPositionY()
    DialogTheme.rule(self, 26, TopPosY, 100)
    DialogTheme.rule(self, visibleSize.width-126, TopPosY, 100)

    -- 放置顶部文字
    self.titleLabel = cc.LabelTTF:create("未 知", MasterTheme.headingFont(false), 46.0)
    self.titleLabel:setColor(cc.c3b(255, 255, 255))
    -- self.titleLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.titleLabel:setPosition(cc.p(visibleSize.width * 0.5, TopPosY))
    self:addChild(self.titleLabel)
    ------------------------- 顶部试图 -------------------------
    
    ------------------------- 底部视图 -------------------------
    -- 添加底部背景图
    local pBottomBg = DialogTheme.cardFromLegacy("Images/UI/BottomBg.png", "ink")
    self.buttomHeight = pBottomBg:getContentSize().height
    pBottomBg:setPosition(pTopBg:getPositionX(), self.buttomHeight*0.5)
    self:addChild(pBottomBg)
    
    DialogTheme.rule(pBottomBg, 24, self.buttomHeight-4, visibleSize.width-48)

    -- 添加离开按钮
    local centerBtn = DialogTheme.menuItem("Images/UI/BottomTip_likai.png", "Images/UI/BottomTip_likai.png", "secondary")
    local closeLabel = DialogTheme.label("离 开", 28)
    closeLabel:setPosition(cc.p(centerBtn:getContentSize().width*.5, centerBtn:getContentSize().height*.5))
    centerBtn:addChild(closeLabel)
    centerBtn:setPosition(pBottomBg:getPosition())
    centerBtn:registerScriptTapHandler(function() self:close() end)
    
    local centerMenu = cc.Menu:create(centerBtn)
    centerMenu:setPosition(cc.p(0, 0))
    self:addChild(centerMenu)
    ------------------------- 底部视图 -------------------------
    
    -- 一些关于tableview的数值计算
    self.areaHeight = visibleSize.height - self.topHeight - self.buttomHeight
    self.areaWidth = visibleSize.width - 30.0
    
    local pTableY = origin.y + self.buttomHeight + self.areaHeight*0.5
    self.centerPos = cc.p(origin.x + visibleSize.width*0.5, pTableY)
    self.originPos = cc.p(self.centerPos.x - self.areaWidth*0.5, self.centerPos.y - self.areaHeight*0.5)
    
    -- 添加scrollView
    local cellSize = cc.size(visibleSize.width, 118)
    self.tableview = cc.TableView:create(cc.size(visibleSize.width, self.areaHeight))
    self.tableview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview:setPosition(cc.p(0, self.originPos.y))
    self.tableview:setDelegate()
    self:addChild(self.tableview)
    
    --注册touch事件
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function ( touch,event )
        return onTouchBegan(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function ( touch,event )
    	onTouchEnd(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_ENDED )
    listener:setSwallowTouches(true)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    eventDispatcher:setPriority(listener, -128-5)
    
    --提示框的infonode
    self.infoNode = cc.Layer:create()
    self.infoNode:setPosition(cc.p(screenSize.width * 0.1, self.buttomHeight))
    self:addChild(self.infoNode,12)

    local infoBoxSize = cc.size(screenSize.width * 0.8, 24 * 5)

     -- 添加scrollView上的label
    self.infoLabel = cc.LabelTTF:create(" ", MasterTheme.headingFont(false), 24.0)
    -- self.infoLabel:setAnchorPoint(cc.p(0.0, 0.0))
    self.infoLabel:setColor(WriteColor)
    -- self.infoLabel:setHorizontalAlignment(0)
    -- self.infoLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
    -- self.infoLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.infoLabel:setPosition(cc.p(infoBoxSize.width / 2, infoBoxSize.height / 2))
    self.infoLabel:setDimensions(cc.size(infoBoxSize.width * 0.9, 0))
    self.infoNode:addChild(self.infoLabel,1)

    -- 添加下边的点点承载节点
    
    -- self.pointNode = cc.Node:create()
    -- self.pointNode:setPosition(cc.p(self.centerPos.x, self.setBtn:getPositionY() - infoBoxSize.height * 0.95))
    -- self.infoNode:addChild(self.pointNode)

    -- 添加信息框
    self.bottomInfoBox = DialogTheme.card(infoBoxSize.width, infoBoxSize.height)
    self.bottomInfoBox:setPosition(self.infoLabel:getPosition())
    -- self.bottomInfoBox:setVisible(false)
    self.infoNode:addChild(self.bottomInfoBox)

    self.infoNode:setVisible(false)

    return true;
end

function EventBaseView:close()
    -- self:removeFromParent(true)
end

function EventBaseView:viewWillClose( isNormal )
	print("EventBaseView:viewWillClose")
end
---------------------------------EventBaseView------------------------------------
-- Local to the event hosts: opt-in clean geometry does not recolor unknown
-- legacy dialogs. All economy, map freeze and queue ownership stays upstream.
EventPageUI = {}
local E = EventPageUI
function E.theme()
    if rawget(_G,'WARM_PIRATE_V1') == false then return nil end
    local ok, W = pcall(require, 'LuaClass/WarmTheme')
    if ok and type(W)=='table' and W.enabled and W.enabled() then return W end
end
function E.text(parent, text, size, color, x, y, width)
    local W=E.theme();local n=W.label(text,size,color,x,y,false,0)
    if width then n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT) end
    parent:addChild(n);return n
end
function E.rule(parent,x,y,width)
    local W=E.theme();local n=W.panel(width,1,W.colors.line,0);n:setPosition(cc.p(x,y));parent:addChild(n);return n
end
function E.scroll(parent,x,y,width,height)
    local s=cc.ScrollView:create();s:setViewSize(cc.size(width,height));s:setPosition(cc.p(x,y))
    s:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);s:setClippingToBounds(true);s:setBounceable(false)
    parent:addChild(s);return s
end
function E.flow(scroll,nodes,gap)
    local view=scroll:getViewSize();local height=16
    for _,n in ipairs(nodes)do height=height+n:getContentSize().height*(n:getScaleY() or 1)+(gap or 14) end
    height=math.max(view.height,height);local y=height-8
    for _,n in ipairs(nodes)do local h=n:getContentSize().height*(n:getScaleY() or 1);n:setAnchorPoint(cc.p(0,1));n:setPositionY(y);y=y-h-(gap or 14) end
    scroll:getContainer():setContentSize(cc.size(view.width,height));scroll:updateInset();scroll:setContentOffset(cc.p(0,view.height-height))
end
function E.alive(view)
    if view.eventDisposed or view.eventClosed or not view:isVisible() then return false end
    local p=view:getParent();if not p then return false end
    while p do if not p:isVisible()then return false end;p=p:getParent() end
    return true
end
function E.blocked(view)
    if view.adventureDialog or view.eventDetails or view.worldMapLayer then return true end
    local scene=cc.Director:getInstance():getRunningScene()
    if scene then for _,child in ipairs(scene:getChildren())do
        if child~=view and child.isAdventureModal and child:isVisible()then return true end
    end end
    return false
end
-- Keep the actual SDButton and its native listener. Only its painted faces and
-- dimensions change; no expanded legacy hit area survives the smaller dock.
function E.sdButton(view,width,height,primary,callback)
    local W=E.theme();local b=SDButton:create('Images/btn/ann05_b.png','Images/btn/ann05_b.png',callback)
    b.normalSpr:removeFromParent(true);b.selectSpr:removeFromParent(true)
    b.normalSpr=W.panel(width,height,primary and W.colors.sea or W.colors.paper,8)
    b.selectSpr=W.panel(width,height,primary and cc.c3b(17,104,118) or W.colors.line,8)
    b:addChild(b.normalSpr);b:addChild(b.selectSpr);b:setContentSize(cc.size(width,height));b:setActive(false)
    b:addClickArea(cc.rect(0,0,0,0));b:setLocalZOrder(1)
    local register=b.registerSingleCLick
    function b:registerSingleCLick(fn)
        local generation=view.eventGeneration;self.eventBoundGeneration=generation
        register(self,function()
            if not E.alive(view) or E.blocked(view) or view.eventActionBusy or generation~=view.eventGeneration then return end
            view.eventActionBusy=true
            fn()
            if not view.eventDisposed then
                view:runAction(cc.Sequence:create(cc.DelayTime:create(.18),cc.CallFunc:create(function()view.eventActionBusy=false end)))
            end
        end)
    end
    local began,moved,ended=b.onTouchBegan,b.onTouchMoved,b.onTouchEnded
    function b:onTouchBegan(touch,event)
        if not E.alive(view) or E.blocked(view)then return false end
        self.eventGestureMoved=false;return began(self,touch,event)
    end
    function b:onTouchMoved(touch,event)
        if self.m_startPoint and cc.pGetDistance(self:convertToNodeSpace(touch:getLocation()),self.m_startPoint)>12 then self.eventGestureMoved=true end
        return moved(self,touch,event)
    end
    function b:onTouchEnded(touch,event)
        if self.eventGestureMoved or not self.isTouch or not E.alive(view) or E.blocked(view)then
            self.isTouch=false;self.normalSpr:stopAllActions();self:setActive(false);return
        end
        return ended(self,touch,event)
    end
    b:registerSingleCLick(callback);return b
end
function EventBaseView:initCoherentEventBase()
    local W=E.theme();local size=cc.Director:getInstance():getVisibleSize();local w,h=size.width,size.height
    local disposed=false -- Survives native userdata destruction in a retained Close callback.
    self.coherentEventPage=true;self.eventClosed=false;self.eventDisposed=false;self.eventGeneration=1
    self.eventSize=size;self.topHeight=112;self.buttomHeight=104;self.areaWidth=w-48;self.areaHeight=h-232
    self.centerPos=cc.p(w/2,104+self.areaHeight/2);self.originPos=cc.p(24,104)
    self:addChild(W.panel(w,h,W.colors.paper,0))
    local header=W.panel(w,112,W.colors.ink,0);header:setPosition(cc.p(0,h-112));self:addChild(header)
    self.titleLabel=E.text(self,'',32,W.colors.white,24,h-43)
    self.eventSubtitle=E.text(self,'',19,cc.c3b(210,230,220),24,h-83)
    self.eventClose=W.button('返回',94,46,function()if not disposed and E.alive(self) and not E.blocked(self)then self:close()end end,{size=21})
    self.eventClose:setPosition(cc.p(w-71,h-53));self:addChild(self.eventClose,5)
    self.tableview=cc.TableView:create(cc.size(self.areaWidth,self.areaHeight));self.tableview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN);self.tableview:setPosition(self.originPos);self.tableview:setDelegate();self:addChild(self.tableview)
    self.infoNode=cc.Node:create();self.infoNode:setVisible(false);self:addChild(self.infoNode)
    self.infoLabel=E.text(self.infoNode,'',22,W.colors.ink,0,0,w-80)
    -- Shield the frozen map while leaving native tables/menus above the shield.
    local shield=cc.EventListenerTouchOneByOne:create();shield:setSwallowTouches(true)
    shield:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(shield,self)
    self.eventShield=shield
    self:registerScriptHandler(function(event)
        if event=='cleanup'then
            disposed=true
            self.eventDisposed=true;self.eventGeneration=self.eventGeneration+1
            if self.ownerEvent and self.ownerEvent.eventDetails==self then self.ownerEvent.eventDetails=nil end
            self.ownerEvent=nil
            if self.adventureDialog and self.adventureDialog.close then self.adventureDialog.close()end
            if self.eventShield then self:getEventDispatcher():removeEventListener(self.eventShield);self.eventShield=nil end
        end
    end)
    return true
end
