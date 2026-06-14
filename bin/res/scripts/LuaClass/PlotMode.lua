--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/2/10
-- Time: 下午4:21
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
require "LuaClass/DataManager"


PlotScene = class("PlotScene", function ()
    return cc.Scene:create()
end)
PlotScene.__index = PlotScene

-- 剧情数组
PlotScene.plots = nil
PlotScene.plotArray = nil
PlotScene.callback = nil
PlotScene.isJumping = false

-- create
-- plotId      number or number[]
-- callback    callback function
function PlotScene:create(plotId, callback)
    local scene = PlotScene.new()
    if scene and scene:init(plotId, callback) then
        return scene
    end
    return nil
end

-- init
function PlotScene:init(plotId, callback)
    self.plotArray = {}
    if type(plotId) == "number" then
        table.insert(self.plotArray, #self.plotArray+1, plotId)
    elseif type(plotId) == "table" then
        for i=1,#plotId do
           local tmp = plotId[i]
           if type(tmp) == "number" then
               table.insert(self.plotArray, #self.plotArray+1, tmp)
           else
               assert(false, "plotId must be number or number[]")
           end
        end
    else
        assert(false, "plotId must be number or number[]")
    end
    if type(callback) ~= "function" then
        assert(false, "callback must be a function")
    end
    self.callback = callback
    self.isJumping = false

    self.plots = {}
    local plotCsv = DataManager:getInstance():getCSVByID(csvOfPlot)
--    for i=1,#self.plotArray do    为了支持中间点击跳到下一届，把一下所有剧情片段全加载改为一幕一幕的加载
    for i=1,1 do
        local plot = plotCsv[tostring(self.plotArray[i])]
        assert(plot, "plot can not found")
        table.insert(self.plots, #self.plots+1, plot)
    end

    local winSize = cc.Director:getInstance():getVisibleSize()

    local baseNode = cc.Node:create()
    self:addChild(baseNode)
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    self:addChild(colorLayer)

--    local listener = cc.EventListenerTouchOneByOne:create()
--    listener:setSwallowTouches(true)
--    listener:registerScriptHandler(function (touch, event)
--        self:next()
--        return true
--    end, cc.Handler.EVENT_TOUCH_BEGAN)
--    listener:registerScriptHandler(function (touch, event)
--    end, cc.Handler.EVENT_TOUCH_MOVED)
--    listener:registerScriptHandler(function (touch, event)
--    end, cc.Handler.EVENT_TOUCH_ENDED)
--    local eventDispatcher = self:getEventDispatcher()
--    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)


    if self.plotArray[1] >= 1 and self.plotArray[1] <= 7 then
        -- jumpBtn
        local jumpBtn = cc.MenuItemImage:create("Images/UI/tiaoguo.png", "Images/UI/tiaoguo.png")
        jumpBtn:setPosition(winSize.width-100.0, 100.0)
        jumpBtn:registerScriptTapHandler(function()
            self:next()
        end)

        local menu = cc.Menu:create(jumpBtn)
        menu:setPosition(0.0, 0.0)
        self:addChild(menu, 1000)
    end

    -- 黑色封面渐显效果
    local blackCoverFadeIn = function()
        local fadein = cc.FadeIn:create(0.5)
        colorLayer:runAction(fadein)
    end

    -- 黑色封面渐隐效果
    local blackCoverFadenOut= function()
        local fadeout = cc.FadeOut:create(0.5)
        colorLayer:runAction(fadeout)
    end

    local actionArray = {}
    for i=1,#self.plots do
        local plot = self.plots[i]
        local iconId = plot.iconID
        local stayTime = tonumber(plot.stayTime)
        local story = plot.story
        local judian = plot.juDianID

        local time = stayTime/#story

        -- 剧情图
        local imageFunc = function()
            baseNode:removeAllChildren()
            -- “瓶中船”剧情特殊处理
            if 7 == tonumber(plot.ID) then
                local bottleNode = cc.Node:create()
                bottleNode:setPosition(0.5*winSize.width, 0.5*winSize.height+200.0)
                baseNode:addChild(bottleNode)

                local bottle = cc.Sprite:create("Images/Plot/juqing_7.png")
                bottle:setPosition(0.0, -100.0)
                bottleNode:addChild(bottle)

                local boat = cc.Sprite:create("Images/Plot/juqing_9.png")
                boat:setPosition(bottle:getPositionX()+50.0, bottle:getPositionY())
                boat:setRotation(-5.0)
                bottleNode:addChild(boat)

                local angle = 5.0
                local rote1 = cc.RotateBy:create(0.5, -angle)
                local rote2 = cc.RotateBy:create(0.5, angle)
                local rote3 = cc.RotateBy:create(0.5, angle)
                local rote4 = cc.RotateBy:create(0.5, -angle)
                local seq = cc.Sequence:create(rote1, rote2, rote3, rote4)
                local action = cc.RepeatForever:create(seq)
                boat:runAction(action)

                local water = cc.Sprite:create("Images/Plot/juqing_8.png")
                water:setPosition(bottle:getPositionX()+67.0, bottle:getPositionY()-55.0)
                bottleNode:addChild(water)

                local t = 1.0
                local delay = cc.DelayTime:create(stayTime+1.0)
                local rotate = cc.RotateBy:create(t, 1000.0)
                local rotateEase = cc.EaseOut:create(rotate, 0.5)
                local scale = cc.ScaleTo:create(t, 0.0)
                local call = cc.CallFunc:create(function()
                    local fade = cc.FadeOut:create(0.9*t)
                    bottle:runAction(fade)
                    fade = cc.FadeOut:create(0.9*t)
                    boat:runAction(fade)
                    fade = cc.FadeOut:create(0.9*t)
                    water:runAction(fade)
                end)
--                local spawn = cc.Spawn:create(rotateEase, call, scale)
                local spawn = cc.Spawn:create(call)
                local action1 = cc.Sequence:create(delay, spawn)
                bottleNode:runAction(action1)

            else
                if iconId and string.len(iconId) > 2 then
                    local nodeGrid = cc.NodeGrid:create()
                    nodeGrid:setPosition(0.5*winSize.width, 0.5*winSize.height+100.0)
                    baseNode:addChild(nodeGrid)

                    local plotImg = cc.Sprite:create("Images/Plot/"..iconId..".png")
                    plotImg:setPosition(0.0, 0.0)
                    nodeGrid:addChild(plotImg)

--                    local twirl = cc.Twirl:create(3.0, cc.size(100.0, 100.0), cc.p(0.5*plotImg:getContentSize().width, 0.5*plotImg:getContentSize().height),
--                        10.0, 1.0)
--                    nodeGrid:runAction(twirl)
                end
            end
        end
        table.insert(actionArray, #actionArray+1, cc.CallFunc:create(imageFunc))

        -- 黑色封面渐隐
        local delayOut = cc.DelayTime:create(0.5)
        local callOut = cc.CallFunc:create(blackCoverFadenOut)
        local spawnOut = cc.Spawn:create(delayOut, callOut)
        table.insert(actionArray, #actionArray+1, spawnOut)

        for i=1,#story do
            -- 弹文字
            local wordFunc = function()
                local label = cc.LabelTTF:create(story[i][1], BoldFont, 30.0)
                label:setPosition(0.5*winSize.width, 0.5*winSize.height+100.0-170.0-20.0-40*i-100.0)
                baseNode:addChild(label)

                local move = cc.MoveBy:create(time, cc.p(0.0, 100.0))
--                local fade1 = cc.FadeIn:create(0.5*time)
--                local delay = cc.DelayTime:create(time)
--                local fade2 = cc.FadeOut:create(0.0)
--                local seq = cc.Sequence:create(delay, fade2)
--                local action = cc.Spawn:create(move, seq)
                label:runAction(move)
            end
            table.insert(actionArray, #actionArray+1, cc.CallFunc:create(wordFunc))
            table.insert(actionArray, #actionArray+1, cc.DelayTime:create(time))
        end

        -- 所有文字播完再停留一下
        if 7 == tonumber(plot.ID) then
            table.insert(actionArray, #actionArray+1, cc.DelayTime:create(2.0))
        else
            table.insert(actionArray, #actionArray+1, cc.DelayTime:create(1.5))
        end

        -- 黑色封面渐显
        local delayIn = cc.DelayTime:create(0.5)
        local callIn = cc.CallFunc:create(blackCoverFadeIn)
        local spawnIn = cc.Spawn:create(delayIn, callIn)
        table.insert(actionArray, #actionArray+1, spawnIn)
    end

    local nextStep = cc.CallFunc:create(self.next)
    table.insert(actionArray, #actionArray+1, nextStep)

    local action = cc.Sequence:create(unpack(actionArray))
    self:runAction(action)

    return true
end

function PlotScene:next()
    if not self.isJumping then
        self.isJumping = true
        if #self.plotArray <= 1 then
            local delayIn = cc.DelayTime:create(0.1)
            local call = cc.CallFunc:create(function()
                self.callback()
            end)
            local seq = cc.Sequence:create(delayIn, call)
            self:runAction(seq)
        else
            table.remove(self.plotArray, 1)
            local scene = PlotScene:create(self.plotArray, self.callback)
            cc.Director:getInstance():replaceScene(scene)
        end
    end
end

