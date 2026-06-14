require "AudioEngine"
require "LuaClass/Header"

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

	print(" EventBaseView:init")

	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 添加总背景
    local mainBg = cc.Sprite:create("Images/Background/MainBackGround.png")
    mainBg:setAnchorPoint(cc.p(0, 0))
    mainBg:setPosition(cc.p(0, 0))
    self:addChild(mainBg)

    -- 在总背景上添加图
    local bgIcon = cc.Sprite:create("Images/Background/cangk.png")
    bgIcon:setPosition(cc.p(mainBg:getContentSize().width * 0.5, mainBg:getContentSize().height * 0.5))
    mainBg:addChild(bgIcon)
    
    ------------------------- 顶部试图 -------------------------
    -- 添加上边标题栏的背景
    local pTopBg = cc.Sprite:create("Images/UI/TitleBg.png")
    self.topHeight = pTopBg:getContentSize().height
    pTopBg:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height - self.topHeight*0.5))
    self:addChild(pTopBg)

    local TopPosY = pTopBg:getPositionY()
    -- 先分别添加左右背景
    local LeftBg = cc.Sprite:create("Images/UI/TopDecor.png")
    self:addChild(LeftBg)
    local RightBg = cc.Sprite:create("Images/UI/TopDecor.png")
    RightBg:setFlippedX(true)
    self:addChild(RightBg)
    
    -- 设置左右背景的位置
    LeftBg:setPosition(LeftBg:getContentSize().width * 0.75, TopPosY)
    RightBg:setPosition(visibleSize.width - RightBg:getContentSize().width * 0.75, TopPosY)
    
    -- 放置顶部文字
    self.titleLabel = cc.LabelTTF:create("未 知", BoldFont, 46.0)
    self.titleLabel:setColor(cc.c3b(255, 255, 255))
    -- self.titleLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.titleLabel:setPosition(cc.p(visibleSize.width * 0.5, TopPosY))
    self:addChild(self.titleLabel)
    ------------------------- 顶部试图 -------------------------
    
    ------------------------- 底部视图 -------------------------
    -- 添加底部背景图
    local pBottomBg = cc.Sprite:create("Images/UI/BottomBg.png")
    self.buttomHeight = pBottomBg:getContentSize().height
    pBottomBg:setPosition(pTopBg:getPositionX(), self.buttomHeight*0.5)
    self:addChild(pBottomBg)
    
    -- 添加左右分框
    local pSplitLeft = cc.Sprite:create("Images/UI/ButtonSplit.png")
    pSplitLeft:setPosition(cc.p(visibleSize.width*0.25, self.buttomHeight*0.5))
    pBottomBg:addChild(pSplitLeft)
    local pSplitRight = cc.Sprite:create("Images/UI/ButtonSplit.png")
    pSplitRight:setPosition(cc.p(visibleSize.width*0.75, self.buttomHeight*0.5))
    pBottomBg:addChild(pSplitRight)
    
    -- 添加离开按钮
    local centerBtn = cc.MenuItemImage:create("Images/UI/BottomTip_likai.png", "Images/UI/BottomTip_likai.png")
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
    self.infoLabel = cc.LabelTTF:create(" ", BoldFont, 24.0)
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
    local tempSpr = cc.Sprite:create("Images/UI/MaskBg_1.png")
    self.bottomInfoBox = cc.Scale9Sprite:create("Images/UI/MaskBg_1.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    self.bottomInfoBox:setContentSize(infoBoxSize)
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