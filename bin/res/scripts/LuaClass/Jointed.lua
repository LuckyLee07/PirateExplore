require "LuaClass/Header"
require "LuaClass/WoWUtils.lua"
--竖直上:0为不偏移,1为上,2为下,水平上:0为不偏移,1为左，2为右

UpDiriction = 10
LeftUpDirction = 11
RightUpDirction = 12
LeftDirction = 01
RightDircion = 02
LeftBottomDirction = 21
RightBottomDirction = 22
BottomDirction = 20

touchIsBreak = false

JointedTipSpr = class("JointedTipSpr",function ()
    return cc.Sprite:create("Images/Map/tip_center.png")
end)

JointedTipSpr.__index = JointedTipSpr
JointedTipSpr.upSpr = nil
JointedTipSpr.downSpr = nil
JointedTipSpr.leftSpr = nil
JointedTipSpr.rightSpr = nil



function JointedTipSpr:create()
    -- print("JointedTipSpr:create()!");

    local jointedTipSpr = JointedTipSpr.new()
    
    if jointedTipSpr and jointedTipSpr:init() then
        -- print("inited")
        return jointedTipSpr
    end

    return nil;
end

function JointedTipSpr:init()
    -- print("JointedTipSpr:init")

    local interval = 0.2
    --上
    self.upSpr = cc.Sprite:create("Images/Map/tip_direction.png")
    self.upSpr:setPosition(cc.p(self:getContentSize().width / 2,self:getContentSize().height * (1.0 + interval) + self.upSpr:getContentSize().height / 2))
    self:addChild(self.upSpr)
    --下
    self.downSpr = cc.Sprite:create("Images/Map/tip_direction.png")
    self.downSpr:setPosition(cc.p(self:getContentSize().width / 2,-self:getContentSize().height * (1.0 - interval) + self.downSpr:getContentSize().height / 2))
    self.downSpr:setFlippedY(true)
    self:addChild(self.downSpr)
    --左
    self.leftSpr = cc.Sprite:create("Images/Map/tip_direction.png")
    self.leftSpr:setPosition(cc.p(-self:getContentSize().width * (1.0 + interval) + self.leftSpr:getContentSize().width / 2,self:getContentSize().height / 2))
    self.leftSpr:setRotation(-90)
    self:addChild(self.leftSpr)
    --右
    self.rightSpr = cc.Sprite:create("Images/Map/tip_direction.png")
    self.rightSpr:setPosition(cc.p(self:getContentSize().width * (1.0 + interval) + self.rightSpr:getContentSize().width / 2,self:getContentSize().height / 2))
    self.rightSpr:setRotation(90)
    self:addChild(self.rightSpr)

    self:setVisible(false)

    self:setScale(1.5)

    return true
end

function JointedTipSpr:showTipByDirection( direction )
    
    if direction == nil then
        self:tipOver()
    elseif direction == UpDiriction or dirction == LeftUpDirction or dirction == RightUpDirction then
        self:tipUp()
    elseif direction == BottomDirction or dirction == LeftBottomDirction or dirction == RightBottomDirction  then
        self:tipDown()
    elseif direction == LeftDirction then
        self:tipLeft()
    elseif direction == RightDircion then
        self:tipRight()
    end

end

function JointedTipSpr:tipUp(  )

    self.downSpr:setVisible(false)
    self.leftSpr:setVisible(false)
    self.rightSpr:setVisible(false)

    self.upSpr:setVisible(true)
    self:setVisible(true)
end

function JointedTipSpr:tipDown(  )
    self.upSpr:setVisible(false)
    self.leftSpr:setVisible(false)
    self.rightSpr:setVisible(false)

    self.downSpr:setVisible(true)
    self:setVisible(true)
end

function JointedTipSpr:tipLeft(  )
    self.downSpr:setVisible(false)
    self.upSpr:setVisible(false)
    self.rightSpr:setVisible(false)

    self.leftSpr:setVisible(true)
    self:setVisible(true)
end

function JointedTipSpr:tipRight(  )
    self.downSpr:setVisible(false)
    self.leftSpr:setVisible(false)
    self.upSpr:setVisible(false)

    self.rightSpr:setVisible(true)
    self:setVisible(true)
end

function JointedTipSpr:tipOver(  )
    self:setVisible(false)
end

local function onTouchesBegan(target , touch, event) 

        -- if target.owner
        -- eonTouchesBegan(target.controller,touch,event)
     	print("Jointed onTouchesBegan",target.enable,target.limiter:isVisible())
     	touchIsBreak = (target.enable == false or target.limiter:isVisible() == true) 
     	return false
end

local function onTouchesMoved(target ,touch, event)
    -- eonTouchesMoved(target.controller,touch,event)
	-- if target.enable == false then
	-- 	touchIsBreak = true
	-- end
end

local function onTouchesEnd( target,touch, event)
    -- eonTouchesEnd(target.controller,touch,event)
    touchIsBreak = checkTouchOffset(target.controller) 

    -- if target.limiter:isVisible() == true then
    --     touchIsBreak = true
    -- end

	print("RJointedonTouchesEnd",touchIsBreak)
    
	if target.enable then
		return
	end

	local horizontalOffset = 0
	local verticalOffset = 0

	judgePos = touch:getLocation()     
 	-- print("Jointed onTouchesEnd")

 	local ownerWdP = target.owner:convertToWorldSpaceAR(cc.p(0,0))
 	-- print("Owner onTouchesEnd",target.owner:getPosition())
 	-- print("ownerWdP")
    local t1 = os.clock()

 	--计算出来的角度是逆时针为正方向角度
 	local  radian = getRadianBetweenTwoPoints(judgePos,ownerWdP)
 	-- print("radian",radian)

 	if radian < 45 then
 		target.dirction = RightDircion
 	elseif radian == 45 then
 		target.dirction = RightUpDirction
 	elseif radian <  90 then
 		target.dirction = UpDiriction
 	elseif radian  == 90 then
 		target.dirction = UpDiriction
 	elseif radian <  135 then
 		target.dirction = UpDiriction
 	elseif radian == 135 then
 		target.dirction = LeftUpDirction
 	elseif radian <  180 then
 		target.dirction = LeftDirction
 	elseif radian == 180 then
 		target.dirction = LeftDirction
 	elseif radian <  225 then
 		target.dirction = LeftDirction
 	elseif radian == 225 then
 		target.dirction = LeftBottomDirction
 	elseif radian <  270 then
 		target.dirction = BottomDirction
 	elseif radian == 270 then
 		target.dirction = BottomDirction
 	elseif radian <  315 then
 		target.dirction = BottomDirction
 	elseif radian == 315 then
 		target.dirction = RightBottomDirction
 	elseif radian <	 360 then
 		target.dirction = RightDircion
 	elseif radian == 360 then
 		target.dirction = RightDircion
 	end
    target:tiping(target.dirction)

    print("local t1 = os.clock()",os.clock() - t1)

 	target.moveActed(target.dirction)

 	-- --这是顺时针旋转,但是计算出来的角度是逆时针角度
 	-- --因为图片一开始就是90度的，所以要减去
 	-- radian = -radian + 90

 	-- target.tipSpr:setRotation(radian)

 

end

Jointed = class("Jointed",function ()
	 return cc.Node:create()
end)

Jointed.__index = Jointed
Jointed.owner = nil
Jointed.dirction = 0
Jointed.moveActed = nil
Jointed.enable = true
Jointed.tipSpr = nil
Jointed.tipTime = 0.0
Jointed.needCost = 0
Jointed.limiter = nil
Jointed.controller = nil

function Jointed:create(owner,func)
	-- print("Jointed:create()!");

	local jointed = Jointed.new()
	
	if jointed and jointed:init(owner,func) then
		return jointed
	end

	return nil;
end

function Jointed:init(owner,func)

	if owner == nil then
		return false
	end

	-- print("cc.EventListenerTouchOneByOne")

	-- for k,v in pairs(cc.EventListenerTouchOneByOne) do
	-- 	print(k,v)
	-- end

	local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function ( touch,event )
    	return onTouchesBegan(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(function ( touch,event )
    	onTouchesMoved(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function ( touch, event )
    	onTouchesEnd(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_ENDED )
    -- listener:setFixedPriority(-127)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    eventDispatcher:setPriority(listener,127)

    self.tipSpr = JointedTipSpr:create()
    self.tipSpr:setPosition(cc.p(owner:getContentSize().width / 2,owner:getContentSize().height / 2))
    -- self.tipSpr:setAnchorPoint(cc.p(0,0))
    self:addChild(self.tipSpr)
    owner:addChild(self)


    self.owner = owner

    self.moveActed = func

    -- print("Jointed:init!");

    return true;
end


function Jointed:setLimiter( limiter )
    self.limiter = limiter
end

-- function Jointed:setTipTime( time )
--     self.tipTime = time
-- end

-- function Jointed:tiping( direction )
    
--     self:stopAllActions()

--     if type(self.tipTime) ~= "number" then 
--         print("ERROR:please init tipTime by number value!")
--         return
--     end

--     self.tipSpr:showTipByDirection(direction)

--     local calfunc = cc.CallFunc:create(function ()
--         self:tipEnd()
--     end)
    
--     local seq = cc.Sequence:create(cc.DelayTime:create(self.tipTime),calfunc)

--     -- check2dxLuaApi(cc.CallFunc)
--     --执行动画
--     self:runAction(seq) 

-- end

function Jointed:tipingByDirection( direction )
    self.tipSpr:showTipByDirection(direction)
end

function Jointed:tipEnd( )
    self.tipSpr:tipOver()
end

