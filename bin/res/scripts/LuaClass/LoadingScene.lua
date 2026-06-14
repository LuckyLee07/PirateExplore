require "LuaClass/Header"
require "LuaClass/WoWUtils.lua"
--存放的index
local curTips = nil
local allTips = nil


LoadingScene = class("LoadingScene",function ()
	 return cc.Scene:create()
end)

LoadingScene.__index = LoadingScene
LoadingScene.progressBar = nil
LoadingScene.curProgress = 0
LoadingScene.addProgress = 0
LoadingScene.targetProgress = 0

local maxScale = 0
local actionInterval = 0.05
-- EventManger.curEventId

local curLoading = nil
function getCurLoadingScene(  )
	return curLoading
end

function LoadingScene:create(  )

	local loadingScene = LoadingScene.new()

	if loadingScene and loadingScene:init() then
		curLoading = loadingScene
		return loadingScene
	end

	return nil
end

local curSpeed = 1
function LoadingScene:init()
	local visibleSize = cc.Director:getInstance():getVisibleSize()

	cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB888)
	local bg = cc.Sprite:create("Images/UI/fm_01.png")
	bg:setPosition(cc.p(visibleSize.width / 2, visibleSize.height / 2))
	self:addChild(bg)

	cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB5A1)
	local title = cc.Sprite:create("Images/UI/logo_01.png")
	title:setPosition(cc.p(bg:getPositionX(),visibleSize.height * 0.9 - title:getContentSize().height * title:getScaleY() / 2))
	self:addChild(title)

	local waves = cc.Sprite:create("Images/UI/fmloding_02.png")
	-- waves:setAnchorPoint(cc.p(0,0.5))
	maxScale = 1
	-- waves:setScaleX(maxScale)
	waves:setPosition(cc.p(visibleSize.width * 0.5,visibleSize.height * 0.15))
	self:addChild(waves)

	local tipString = self:screeningTips()

	local tips = cc.LabelTTF:create(tipString, BoldFont, 25)
	tips:setPosition(cc.p(bg:getPositionX(),waves:getPositionY() - waves:getContentSize().height / 2 - tips:getContentSize().height))
	self:addChild(tips)

	self.progressBar = cc.Sprite:create("Images/UI/fmloding_03.png")
	self.progressBar:setAnchorPoint(cc.p(0,0.5))
	self.progressBar:setPosition(cc.p(waves:getPositionX() - waves:getContentSize().width * waves:getScaleX() / 2,waves:getPositionY()))
	self:addChild(self.progressBar)
	self.maxSize = waves:getContentSize()
	self.progressBar:setTextureRect(cc.rect(0,0,0,self.progressBar:getContentSize().height))
	-- self.progressBar:setScaleX(0)

	self.ship = cc.Sprite:create("Images/UI/fmloding_01.png")
	self.ship:setAnchorPoint(0.74,0)
	self.ship:setPosition(cc.p(self.progressBar:getPositionX() + self.ship:getContentSize().width * 0.8,self.progressBar:getPositionY()))
	self:addChild(self.ship)
	self.ship:runAction(cc.Sequence:create(cc.FadeOut:create(0.0),cc.EaseExponentialOut:create(cc.FadeIn:create(1.0))))
	self.targetProgress = 0
	curSpeed = 1

	cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
	return true
end

function LoadingScene:screeningTips( )
	local tipString = nil


	if allTips == nil then
		allTips = {}
		for k,v in pairs(DataManager:getInstance():getCSVByID(csvOfLoadingTips)) do
			allTips[tonumber(k)] = v
		end
	end

	if curTips == nil then
		curTips = clone(allTips)
	end

	local range = {}
	range.min = 1
	range.max = #curTips

	index = getRandomNumByRange(range)

	-- printn("screeningTips",index,#curTips)

	local value = curTips[index]
	tipString = value["desc"]

	table.remove(curTips,index)

	-- print("removed",#curTips)

	if #curTips < 1 then
		curTips = nil
	end

	return tipString
end

local addSpeed = 0.08

function LoadingScene:upDateProgressDrawRect(  )
	
	-- print("upDateProgressDrawRect",self.curProgress,self.addProgress)

	if self.curProgress == 1 then
		self.progressBar:stopAllActions()
		if self.loadedFunc then
				self.loadedFunc()
		end
		return
	end

	if self.curProgress == self.targetProgress then

		if self.curLoadFunc then
			self.curLoadFunc()
		end

		self.progressBar:stopAllActions()
		return
	end

	self.curProgress = self.curProgress + self.addProgress

	self.curProgress = math.min(self.curProgress,self.targetProgress)
	-- print("upDateProgressDrawRects",self.progressBar:getContentSize().width)
	local newRect = cc.rect(0,0,self.maxSize.width * self.curProgress,self.progressBar:getContentSize().height)

	if self.progressBar:getPositionX() + newRect.width > self.ship:getPositionX() then
		self.ship:setPositionX(self.progressBar:getPositionX() + newRect.width)
	else
		curSpeed = curSpeed + addSpeed
		self.ship:setPositionX(self.ship:getPositionX() + curSpeed )
	end

	self.progressBar:setTextureRect(newRect)
end

function LoadingScene:runLoadingAction( totalTime,targetnum )

	if targetnum ~= nil then
		self.targetProgress = targetnum
	end

	local func = cc.CallFunc:create(function ( )
		self:upDateProgressDrawRect()
	end)

	local calTimes = totalTime / actionInterval

	self.addProgress = (self.targetProgress - self.curProgress) /  calTimes

	local seq = cc.Sequence:create(func,cc.DelayTime:create(actionInterval))
	local action = cc.RepeatForever:create(seq)
	-- local action = cc.Sequence:create(cc.DelayTime:create(0.0),move,cc.DelayTime:create(0.0),func)
	self.progressBar:runAction(action)
end

function LoadingScene:begainMoveAction( targetnum,endFunc )

	if targetnum == nil or type(targetnum) ~= "number" then
		return
	end
	
	self.curLoadFunc = endFunc

	local move = cc.ScaleTo:create(0.5, self.targetProgress, 1.0)
	
	self:runLoadingAction(1.0,targetnum)
end

function LoadingScene:setLoadedFunc( endFunc )
	self.loadedFunc = endFunc
end

function LoadingScene:upDataProgress( addNum ,endFunc)

	if addNum == nil then
		addNum = self.addNum
	end

	addNum = tonumber(addNum)

	if addNum > 1 then
		addNum = addNum / 100
	end
	
	self.curLoadFunc = endFunc

	self.targetProgress = math.min(self.targetProgress + addNum ,1)

	self:runLoadingAction(1.0)

	-- local action = cc.Sequence:create(cc.DelayTime:create(0.0),move,cc.DelayTime:create(0.0),func)
	-- self.progressBar:runAction(action)
	print("upDataProgress",self.targetProgress)

	-- self.progressBar:setScaleX(maxScale * self.targetProgress)
end


--该方法只供map加载使用。。。。
function LoadingScene:update(  )

	print("type",type(self.co))

	print("LoadingScene:update",coroutine.status(self.co))

	if self.co ~= nil and not coroutine.resume(self.co) then
		print("LoadingScene:update1",coroutine.status(self.co))
		self.co = nil
		-- cc.Director:getInstance():replaceScene(nextScenece)
	end

	local func = cc.CallFunc:create(function ( )
		self:upDataProgress(nil,function (  )
			self:update()
		end)
	end)

	local action = cc.Sequence:create(cc.DelayTime:create(0.0),func)
	self:runAction(action)
end

function LoadingScene:checkProgress(  )
	if self.targetProgress == 1.0 then
		if self.endFunc then
			self.endFunc()
		end
	end
end


