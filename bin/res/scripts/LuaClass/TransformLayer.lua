require "AudioEngine"
require "LuaClass/Header"

local winSize = cc.Director:getInstance():getVisibleSize()

TransformLayer = class("TransformLayer",function ()
	 return cc.LayerColor:create(cc.c4b(0,0,0,0),winSize.width , winSize.height )
end)

TransformLayer.__index = TransformLayer
TransformLayer.name = nil
TransformLayer.tips = nil
TransformLayer.calback = nil
TransformLayer.statue = nil
function TransformLayer:create(tips)
	print("Jointed:create()!");

	local transformLayer = TransformLayer.new()
	
	if transformLayer and transformLayer:init(tips) then
		return transformLayer
	end

	return nil;
end

function TransformLayer:init(tips)
    print("EventLayer:init!");

    self.name = "transformLayer"
    self.touchCount = 0
    self.statue = "ready"
    local abord = cc.LabelTTF:create(tips, BoldFont, 30.0)
    abord:setPosition(0.5*winSize.width, 0.5*winSize.height-15.0)
    self:addChild(abord)

    self.tips = abord
    -- local labelSize = cc.size(winSize.width,0)
   	-- self.tips:setDimensions(labelSize)
   	self.tips:setVisible(false)
    --添加touch事件,防止触发本层之后的点击事件
   	local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function ( touch,event )

    	print("TransformLayerTouch")

    	return true
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function ( touch,event )
    	
    end,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function ( touch,event )
    	
        if self.statue ~= "transform" then
            self:startClear()
        end

    end,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    eventDispatcher:setPriority(listener,-1000)
    return true;
end

function TransformLayer:setCalback( calback )
	self.calback = calback
end

--开始进行转换动画
function TransformLayer:transform( delayTime,transformType )

    self.statue = "transform"

	local gameScene = cc.Director:getInstance():getRunningScene()
	gameScene:addChild(self,100)

    if transformType == nil then
        transformType = "in"
    end

    if delayTime == nil then
        delayTime = 1.0
    end

    local action = nil

    if transformType == "in" then

        -- self.tips:setAnchorPoint(cc.p(0,1))
        -- self.tips:setPositionX(self.tips:getPositionX() - self.tips:getContentSize().width / 2)
        -- self.tips:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        local fade = cc.FadeIn:create(1.0)

        local delay = cc.DelayTime:create(delayTime)
        
        local call1 = cc.CallFunc:create(function()

            self.tips:setPositionY(self.tips:getPositionY() + self.tips:getContentSize().height * 3)

            local othertips = cc.LabelTTF:create("您可以：\n\t\t1.增加船舱容量，可携带更多食物\n\t\t2.攻打下来的据点，就是你最好的补给站",BoldFont, 30.0)
            othertips:setPosition(cc.p(self.tips:getPositionX() - self.tips:getContentSize().width / 2 + othertips:getContentSize().width / 2,self.tips:getPositionY() - self.tips:getContentSize().height * 1.5 - othertips:getContentSize().height / 2))
            -- othertips:setAnchorPoint(cc.p(0,1))
            othertips:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            -- othertips:setDimensions(cc.size(0,0))
            self:addChild(othertips)

            -- local othertips1 = cc.LabelTTF:create("\n1.增加船舱容量，可携带更多食物\n2.攻打下来的据点，就是你最好的补给站",BoldFont, 30.0)
            -- othertips:setPosition(cc.p(self.tips:getPositionX() - self.tips:getContentSize().width / 2 + othertips:getContentSize().width / 2,self.tips:getPositionY() - self.tips:getContentSize().height / 2 - othertips:getContentSize().height / 2))
            -- -- othertips:setAnchorPoint(cc.p(0,1))
            -- othertips:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            -- -- othertips:setDimensions(cc.size(0,0))
            -- self:addChild(othertips)


            self.tips:setVisible(true)
            self.statue = "ready"
            print("othertips",othertips:getString())
            local touchTips = cc.LabelTTF:create("点击屏幕可继续......", BoldFont, 30.0)
            touchTips:setPosition(cc.p(self.tips:getPositionX(),othertips:getPositionY() - othertips:getContentSize().height - touchTips:getContentSize().height * 6))
            self:addChild(touchTips)
            local seq = cc.Sequence:create(cc.FadeOut:create(0.5),cc.FadeIn:create(0.5))
            local action = cc.RepeatForever:create(seq)
            touchTips:runAction(action)
        end)

        
        -- action = cc.Sequence:create(fade,call1,delay, call2)
        action = cc.Sequence:create(fade,call1)
    else 

        self:setOpacity(255)
        self.tips:setVisible(true)

        local fade = cc.FadeOut:create(1.0)

        local delay = cc.DelayTime:create(delayTime)
        
        local call1 = cc.CallFunc:create(function()
            local fade = cc.FadeOut:create(1.0)
            self.tips:runAction(fade)
        end)

        local call2 = cc.CallFunc:create(function()
            local calback = nil
            if self.calback ~= nil then
                calback = self.calback()
            end

            --移除当前层
            self:removeFromParent()

            if calback then
                calback()
            end

        end)

        action = cc.Sequence:create(delay,call1,fade,call2)
    end


	-- local fade = cc.FadeIn:create(1.0)

	-- local action_1 = cc.Sequence:create(fade)
	-- self.tips:runAction(action_1)

    self:runAction(action)
end

function TransformLayer:startClear(  )
    local call1 = cc.CallFunc:create(function()
            local calback = nil
            if self.calback ~= nil then
                calback = self.calback()
            end

            --移除当前层
            self:removeFromParent()

            if calback then
                calback()
            end

        end)
    local action = cc.Sequence:create(cc.DelayTime:create(0.1), call1) 
    self:runAction(action)
end

