require "LuaClass/Header"
require "LuaClass/EffectUtil"


ExploreGuideComponent = class("ExploreGuideComponent",function ()
	 return {}
end)

ExploreGuideComponent.__index = ExploreGuideComponent
ExploreGuideComponent.finger = nil
ExploreGuideComponent.halo = nil
ExploreGuideComponent.desLaebl = nil
ExploreGuideComponent.desBox = nil
ExploreGuideComponent.tipLable = nil
ExploreGuideComponent.tipBox = nil

function ExploreGuideComponent:create(parent)

	local guidelayer = ExploreGuideComponent.new()
	
	if guidelayer and guidelayer:init(parent) then
		return guidelayer
	end

	return nil
end


function ExploreGuideComponent:init(parent)

	print("ExploreGuideComponent:init",parent)

	if not parent then
		return false
	end

	self.halo = cc.Sprite:create("Images/Map/Guide/halo.png")
	parent:addChild(self.halo,1000)

	--手
	self.finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
	self.finger:setAnchorPoint(0,1)
	parent:addChild(self.finger,1000)

	local spriteFrame = cc.SpriteFrameCache:getInstance()	
	for i = 1, 2 do
        local sprName = string.format("Images/Map/Guide/finger_%d.png", i)
        local tempSprite = cc.Sprite:create(sprName)
        if tempSprite ~= nil then
            spriteFrame:addSpriteFrame(tempSprite:getSpriteFrame(), sprName)
        end
    end

    local winSize = cc.Director:getInstance():getVisibleSize()

	local parent = parent:getParent():getParent()

	local tempSpr =  cc.Sprite:create("Images/Map/Guide/desBox.png")

	--对话
	self.desBox = cc.Scale9Sprite:create("Images/Map/Guide/desBox.png",cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(1, 1, tempSpr:getContentSize().width - 2, tempSpr:getContentSize().height - 2))
	self.desBox:setPosition(cc.p(winSize.width / 2,winSize.height / 2 + 50))
	parent:addChild(self.desBox,1000)

	self.desLaebl = cc.LabelTTF:create("描述话", BoldFont, 20)
	self.desLaebl:setPosition(cc.p(winSize.width / 2,winSize.height / 2 + 55))
	parent:addChild(self.desLaebl,1000)

	--提示
	local tempSpr =  cc.Sprite:create("Images/Map/Guide/tipBox.png")
	self.tipBox = cc.Scale9Sprite:create("Images/Map/Guide/tipBox.png",cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(1, 1, tempSpr:getContentSize().width - 2, tempSpr:getContentSize().height - 2))
	self.tipBox:setPosition(cc.p(winSize.width / 2,winSize.height * 0.75))
	parent:addChild(self.tipBox,1000)

	self.tipLable = cc.LabelTTF:create("提示话", BoldFont, 30)
	self.tipLable:setPosition(cc.p(winSize.width / 2,winSize.height * 0.75))
	parent:addChild(self.tipLable,1000)

    return true
end

function ExploreGuideComponent:hideAllComponents(  )

	self.finger:setVisible(false)
	self.halo:setVisible(false)
	self.desLaebl:setVisible(false)
	self.desBox:setVisible(false)
	self.tipLable:setVisible(false)
	self.tipBox:setVisible(false)
end

function ExploreGuideComponent:changeFingerParent( parent )

	if parent == nil then
		return
	end
	print("changeFingerParent")

	self.halo:removeFromParent(true)
	self.halo = nil
	self.finger:removeFromParent(true)
	self.finger = nil

	self.halo = cc.Sprite:create("Images/Map/Guide/halo.png")
	parent:addChild(self.halo,1000)

	--手
	self.finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
	self.finger:setAnchorPoint(0,1)
	parent:addChild(self.finger,1000)
end

function ExploreGuideComponent:showFingerActionByPosition( position )
	


	if position ~= nil then
		print("showFingerActionByPosition",position.x,position.y)
		self.halo:setPosition(position)
		self.finger:setPosition(cc.p(position.x - self.halo:getContentSize().width * 0.3 ,position.y + self.halo:getContentSize().height * 0.8))
	end

	self.finger:stopAllActions()
	self.halo:stopAllActions()
	-- self.finger:setPosition(cc.p(position.x + self.finger:getContentSize().width * 0.4,position.y - self.finger:getContentSize().height * 0.6))

    -- self.halo:setScale(1.0)
    -- self.halo:setOpacity(255)

	self.finger:setVisible(true)
	self.halo:setVisible(true)

	local touchAni = EffectUtil:getAnimate("Images/Map/Guide/finger_%d.png", 1, 2, 0.3)
	print("showFingerActionByPosition",touchAni)
    self.finger:runAction(cc.RepeatForever:create(touchAni))

	local delay = cc.DelayTime:create(0.3)

   	local expend = cc.ScaleTo:create(0.3,2.0)

   	local fadeOut = cc.FadeOut:create(0.3)

   	local cal = cc.CallFunc:create(function ( ... )
   		self.halo:setScale(1.0)
    	self.halo:setOpacity(255)
   	end)

   	local spawn = cc.Spawn:create(expend,fadeOut)

   	local seq = cc.Sequence:create(delay,cal,spawn)

   	local action = cc.RepeatForever:create(seq)

   	self.halo:runAction(action)
end

function ExploreGuideComponent:showTipsByPosition(tips,position )
	
	-- if position then
	-- 	self.tipBox:setPosition(position)
	-- 	self.tipLable:setPosition(position)
	-- end

	self.tipLable:setString(tips)

	local boxSize = cc.size(self.tipLable:getContentSize().width * 1.1,self.tipLable:getContentSize().height * 1.1)
	self.tipBox:setContentSize(boxSize)
	-- self.tipBox:setScale(boxSize / self.tipBox:getContentSize().width)

	self.tipLable:setVisible(true)
	self.tipBox:setVisible(true)
end

function ExploreGuideComponent:showDes( des,position )
	-- if position then
	-- 	self.desBox:setPosition(position)
	-- 	self.desLaebl:setPosition(cc.p(position.x,position.y + 5))
	-- end

	self.desLaebl:setString(des)

	local boxSize = cc.size(self.desLaebl:getContentSize().width * 1.1,self.desLaebl:getContentSize().height * 1.4)

	self.desBox:setContentSize(boxSize)

	self.desLaebl:setVisible(true)
	self.desBox:setVisible(true)
end
