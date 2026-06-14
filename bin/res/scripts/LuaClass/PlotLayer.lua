require "AudioEngine"
require "LuaClass/Header"


local winSize = cc.Director:getInstance():getVisibleSize()

PlotLayer = class("PlotLayer",function ()
	 return cc.LayerColor:create(cc.c4b(0,0,0,0),winSize.width , winSize.height )
end)

PlotLayer.__index = PlotLayer
PlotLayer.name = nil
PlotLayer.plots = nil
PlotLayer.calback = nil
PlotLayer.curTTf = nil
PlotLayer.ttfs = nil
PlotLayer.curTargetY = 0
PlotLayer.startY = 0
PlotLayer.delayTime = 2
function PlotLayer:create(plotId,otherPlots)
	print("PlotLayer:create()!");

	local plotLayer = PlotLayer.new()
	
	if plotLayer and plotLayer:init(plotId,otherPlots) then
		return plotLayer
	end

	return nil;
end

function PlotLayer:init(plotId,otherPlots)
    print("PlotLayer:init!",plotId);

    self.name = "PlotLayer"
    --获得剧情文字
    plotDatas =  DataManager:getInstance():getCSVByID(csvOfPlot)

    self.ttfs = {}

    for k,v in pairs(plotDatas) do
        print(k,v)
    end

    if plotId ~= nil then
        self.plots = clone(plotDatas[tostring(plotId)]["story"])
    else
        self.plots = otherPlots
    end

    self.stayFunc = nil
    self.delayTime = 2
    --设置目标Y
    self.curTargetY = winSize.height * 0.55
    --设置起始Y
    self.startY = winSize.height * 0.4

    --判断是否能在0.4的位置开始
    if self.curTargetY - (#self.plots - 0.5) * (winSize.height * 0.03) < self.startY then
        self.startY = self.curTargetY - (#self.plots - 0.5) * (winSize.height * 0.03)
    end 

    --添加touch事件,防止触发本层之后的点击事件
   	local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function ( touch,event )

    print("PlotLayer")

    end,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function ( touch,event )
    	
    end,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function ( touch,event )
    	
    end,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    eventDispatcher:setPriority(listener,-1000)
    return true;
end

function PlotLayer:setCalback( calback )
	self.calback = calback
end

-- function PlotLayer:setPlots( plots )
--     self.plots = plots
-- end

function PlotLayer:setStayCallback( stayFunc )
    self.stayFunc = stayFunc
end

--开始播放动画(剧情动画和当前层动画分开，这个接口只播放层动画)
function PlotLayer:play(  )
    print("PlotLayer:play")
	local gameScene = cc.Director:getInstance():getRunningScene()
	gameScene:addChild(self,10000)
	local fade = cc.FadeIn:create(1.0)
    
    local call1 = cc.CallFunc:create(function()
    	self:plotsPlay()
    end)

    local action = cc.Sequence:create(fade,call1)

	-- local fade = cc.FadeIn:create(1.0)

	-- local action_1 = cc.Sequence:create(fade)
	-- self.tips:runAction(action_1)

    self:runAction(action)
end

function PlotLayer:plotsPlay(  )
    print("plotsPlay",self.plots)
    printn(self.plots)
    --若待播放的剧情没有了，开始调回掉函数
    if #self.plots == 0 then

        local delay = cc.DelayTime:create(self.delayTime)

        local stayFunc = cc.CallFunc:create(function ( ... )
            
            if self.stayFunc ~= nil then
                self.stayFunc()
            end

        end)


        local call1 = cc.CallFunc:create(function()
            --所有ttfs淡出
            for i=1,#self.ttfs do
                local fade = cc.FadeOut:create(1.0)
                self.ttfs[i]:runAction(fade)
            end
            --淡出后的回掉
            local call1 = cc.CallFunc:create(function()
                local calback = nil
                if self.calback ~= nil then
                    self.calback()
                end

                --移除当前层
                self:removeFromParent()

                -- if calback then
                --     calback()
                -- end
            end) 

            --plotslayer淡出
            local fade = cc.FadeOut:create(1.0)
            local action = cc.Sequence:create(fade,call1)
            self:runAction(action)
        end)
        
        local action = cc.Sequence:create(stayFunc,delay,call1)
        self:runAction(action)
        return
    end

    --添加新的文字
    self.curTTf = cc.LabelTTF:create(self.plots[1][1],BoldFont,winSize.height * 0.03)
    self.curTTf:setPosition(cc.p(winSize.width / 2,self.startY))
    self:addChild(self.curTTf)
    
    self.ttfs[#self.ttfs + 1] = self.curTTf

    table.remove(self.plots,1)

    --给文字添加动画
    local fade = cc.FadeIn:create(0.5)

    local move = cc.MoveTo:create(1.0, cc.p(winSize.width / 2,self.curTargetY))

    -- local spawn = cc.Spawn:create( move)

    
    local call1 = cc.CallFunc:create(function()
        self.curTargetY = self.curTargetY - self.curTTf:getContentSize().height
        self:plotsPlay()
    end)

    local action = cc.Sequence:create(move,call1)


    self.curTTf:runAction(action)

end

