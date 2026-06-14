--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/21
-- Time: 下午4:06
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
require "LuaClass/NotificationNode"

local MAX_Z_ORDER = 2147483647   -- 32(or 64)位机器上int的最大值

-- ToastUtil
ToastUtil = class("ToastUtil", function ()
    return {}
end)
ToastUtil.__index = ToastUtil
ToastUtil.infoQueue = {}
ToastUtil.bIsPlaying = false
ToastUtil.schduler = nil


function ToastUtil:toastString(str, node)

--     local visibleSize = cc.Director:getInstance():getVisibleSize()

--     -- root
--     local rootNode = cc.Node:create()
--     rootNode:setPosition(0.5*visibleSize.width, 0.5*visibleSize.height+20.0)
--     if node ~= nil then
--         node:addChild(rootNode, MAX_Z_ORDER)
--     else
--         if cc.Director:getInstance():getNotificationNode() then
--             cc.Director:getInstance():getNotificationNode():addChild(rootNode)
--         end
--     end

--     -- background
-- --    local colorLayer = cc.LayerColor:create(cc.c4f(80, 80, 80, 100))
-- --    colorLayer:setContentSize(cc.size(400.0, 60.0))
-- --    colorLayer:setAnchorPoint(cc.p(0.5, 0.5))
-- --    colorLayer:ignoreAnchorPointForPosition(false)
-- --    colorLayer:setPosition(0.0, 0.0)
-- --    rootNode:addChild(colorLayer)

--     -- title
--     local title = cc.LabelTTF:create(str, BoldFont, 38.0)
--     title:setPosition(0.0, 0.0)
--     rootNode:addChild(title)

--     -- action
--     local move = cc.MoveBy:create(1, cc.p(0.0, -100.0))
--     local remove = cc.RemoveSelf:create()
--     local action = cc.Sequence:create(move, remove)
--     rootNode:runAction(action)

    self:downString(str)
end

--[[
向下飘字的函数
作者：Yang
str：飘字的文本
bIsLimit：限制是否同一时间允许入栈多条数据
]]
function ToastUtil:downString(str, bIsLimit)
    if bIsLimit == nil then
        bIsLimit = false
    end
    if bIsLimit and #self.infoQueue > 0 then
        return
    end
    -- printn("self.infoQueue",self.infoQueue)
    -- printn("str",str)
    table.insert(self.infoQueue, str)
    -- printn("self.infoQueue",self.infoQueue)
    -- body
    local visibleSize = cc.Director:getInstance():getVisibleSize()

    local function playAnimation()
        if self.bIsPlaying then
            return
        end
        self.bIsPlaying = true

        local rootNode = cc.Node:create()
        rootNode:setPosition(0.5*visibleSize.width, 0.5*visibleSize.height + 120.0)
        rootNode:setScale(0.1)
        if cc.Director:getInstance():getNotificationNode() then
            cc.Director:getInstance():getNotificationNode():addChild(rootNode)
        end

        -- title
        local title = cc.LabelTTF:create(self.infoQueue[1], BoldFont, 38.0)
        title:setPosition(0.0, 0.0)
        title:setColor(cc.c3b(229, 229, 229))
        -- title:enableStroke(cc.c4b(8, 8, 8, 255), 1)
        rootNode:addChild(title)

        -- action
        local move = cc.MoveBy:create(5.0, cc.p(0.0, -260.0))
        local remove = cc.RemoveSelf:create()

        -- local cleanUp = cc.CallFunc:create(function()
        --     cc.Director:getInstance():getScheduler():unscheduleScriptFunc(self.schduler)
        --     self.bIsPlaying = false
        --     if #self.infoQueue > 0 then
        --         playAnimation()
        --     end
        -- end)

        function cleanUp()
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
            self.bIsPlaying = false
            if #self.infoQueue > 0 then
                playAnimation()
            end
            -- body
        end
        rootNode:runAction(cc.Sequence:create(move, remove))

        self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(cleanUp, 0.6, false)
        -- rootNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cleanUp))
        rootNode:runAction(cc.Sequence:create(cc.EaseExponentialIn:create(cc.ScaleTo:create(0.2, 1.6)), cc.ScaleTo:create(0.1, 1.0)))
        title:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.EaseExponentialIn:create(cc.FadeOut:create(2.0))))

        table.remove(self.infoQueue, 1)
    end

    cc.Director:getInstance():getNotificationNode():runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(playAnimation)))
end
