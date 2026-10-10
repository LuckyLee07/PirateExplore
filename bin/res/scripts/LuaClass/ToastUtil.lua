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
ToastUtil.infoKinds = {}


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
-- Routine production is still calculated, saved, and logged by NotificationNode.
-- Only its floating presentation is quiet while the harbor or a static management page is active.
-- Errors, unlocks and rewards retain the existing toast path.
function ToastUtil:isProductionQuiet()
    if pNeedUpdateLayer and (pNeedUpdateLayer.isAdventureHome or pNeedUpdateLayer.managementTheme or pNeedUpdateLayer.dialogTheme) then return true end
    local director=cc.Director:getInstance()
    local scene=director.getRunningScene and director:getRunningScene()
    if scene then
        for _,child in ipairs(scene:getChildren()) do
            if child.isAdventureModal and child:isVisible() then return true end
        end
    end
    return false
end
function ToastUtil:productionString(str)
    if self:isProductionQuiet() then return end
    self:downString(str, false, 'production')
end

-- Remove only already-visible routine production when entering Home.
function ToastUtil:quietHomeProductionToasts()
    local notification=cc.Director:getInstance():getNotificationNode()
    if not notification then return end
    for _,node in ipairs(notification:getChildren()) do
        if node.isRoutineProductionToast then node:removeFromParent()
        elseif node.clearRoutineProductionToasts then node:clearRoutineProductionToasts() end
    end
end

-- Only manual alchemy shares this feedback. Keep important rewards/errors in
-- the ordinary queue, and keep this small receipt beside its owning control.
function ToastUtil:alchemyCoins(amount)
    local director = cc.Director:getInstance()
    local page = pNeedUpdateLayer
    local host = page and page.infoNode or director:getRunningScene()
    if not host then return end
    local size = director:getVisibleSize()
    local root
    -- Inspect native-owned children instead of retaining a global Lua wrapper
    -- that could outlive a replaced page or notification node.
    for _, child in ipairs(host:getChildren()) do
        if child.isAlchemyToast then root = child; break end
    end
    if not root then
        root = cc.Node:create()
        root.isAlchemyToast = true
        root.alchemyAmount = 0
        root.alchemyTitle = cc.LabelTTF:create('', BoldFont, 28.0)
        root.alchemyTitle:setColor(cc.c3b(255, 250, 237))
        root.alchemyBackdrop = cc.LayerColor:create(cc.c4b(22, 53, 62, 240))
        root.alchemyBackdrop:setAnchorPoint(cc.p(0.5, 0.5))
        root.alchemyBackdrop:ignoreAnchorPointForPosition(false)
        root:addChild(root.alchemyBackdrop)
        root:addChild(root.alchemyTitle)
        root:registerScriptHandler(function(event)
            if event == 'exit' or event == 'cleanup' then
                root:stopAllActions()
                root.alchemyTitle:stopAllActions()
                root.alchemyBackdrop:stopAllActions()
                root.alchemyAmount = 0
                root:setVisible(false)
            end
        end)
        host:addChild(root, 99)
    end
    root:stopAllActions()
    root.alchemyTitle:stopAllActions()
    root.alchemyBackdrop:stopAllActions()
    root.alchemyAmount = root.alchemyAmount + amount
    -- This is a receipt, not a second balance display: spending can happen
    -- while it is visible. The existing currency header owns the live total.
    root.alchemyTitle:setString('金币+'..root.alchemyAmount)
    root.alchemyTitle:setScale(1)
    local textSize = root.alchemyTitle:getContentSize()
    local width = math.min(textSize.width, math.max(100, size.width - 96))
    root.alchemyTitle:setScale(math.min(1, width / math.max(1, textSize.width)))
    root.alchemyBackdrop:setContentSize(cc.size(width + 32, textSize.height + 18))
    local x, y = size.width * 0.5, size.height * 0.5 + 120
    if page and host == page.infoNode and page.setBtn then
        x, y = page.setBtn:getPositionX(), page.setBtn:getPositionY() + 70
    end
    x = math.max(width * 0.5 + 24, math.min(size.width - width * 0.5 - 24, x))
    root:setPosition(x, y)
    root:setVisible(true)
    root.alchemyTitle:setOpacity(255)
    root.alchemyBackdrop:setOpacity(240)
    for _, child in ipairs({root.alchemyTitle, root.alchemyBackdrop}) do
        child:runAction(cc.Sequence:create(cc.DelayTime:create(1.2), cc.FadeOut:create(0.4)))
    end
    root:runAction(cc.Sequence:create(cc.DelayTime:create(1.6), cc.CallFunc:create(function()
        root.alchemyAmount = 0
        root:setVisible(false)
    end)))
    return root
end

-- The notification layer survives ordinary scene changes. Its toast stack owns
-- all native references and timers; the singleton keeps only pending text.
local function ordinaryStack(owner, notification, size)
    for _, child in ipairs(notification:getChildren()) do
        if child.isOrdinaryToastStack then return child end
    end
    local stack = cc.Node:create()
    stack.isOrdinaryToastStack = true
    local active, usedHeight = {}, 0
    local stopped, disposed, generation, entered = false, false, 0, false
    local gap = 12
    local top = size.height * 0.5 + 160
    local availableHeight = top - size.height * 0.35
    local pump
    local function layout()
        usedHeight = 0
        for _, entry in ipairs(active) do
            entry.node:setPosition(size.width * 0.5, top - usedHeight - entry.height * 0.5)
            usedHeight = usedHeight + entry.height + gap
        end
    end
    local function finish(entry, token)
        if stopped or disposed or generation ~= token then return end
        for i, current in ipairs(active) do
            if current == entry then
                table.remove(active, i)
                entry.node:removeFromParent()
                layout()
                pump()
                return
            end
        end
    end
    pump = function()
        if stopped or disposed then return end
        -- Clear only already-retired cards, outside native lifecycle traversal.
        for _, child in ipairs(stack:getChildren()) do
            if child.retiredToast then child:removeFromParent() end
        end
        while #owner.infoQueue > 0 and #active < 3 do
            local text, kind = owner.infoQueue[1], owner.infoKinds[1]
            if kind == 'production' and owner:isProductionQuiet() then
                table.remove(owner.infoQueue, 1); table.remove(owner.infoKinds, 1)
            else
                local title = cc.LabelTTF:create(text, BoldFont, 38.0)
                local maxWidth = math.max(100, size.width - 96)
                if title:getContentSize().width > maxWidth then
                    title:setDimensions(cc.size(maxWidth, 0))
                    title:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
                end
                local textSize = title:getContentSize()
                local scale = math.min(1, (availableHeight - 28) / math.max(1, textSize.height))
                local height = textSize.height * scale + 28
                if #active > 0 and usedHeight + height > availableHeight then break end
                table.remove(owner.infoQueue, 1); table.remove(owner.infoKinds, 1)
                local card = cc.Node:create()
                card.isRoutineProductionToast = kind == 'production'
                card.toastText = text
                title:setColor(cc.c3b(255, 250, 237)); title:setScale(scale)
                local backdrop = cc.LayerColor:create(cc.c4b(22, 53, 62, 240),
                    textSize.width * scale + 48, height)
                backdrop:setAnchorPoint(cc.p(0.5, 0.5)); backdrop:ignoreAnchorPointForPosition(false)
                card:addChild(backdrop); card:addChild(title); stack:addChild(card)
                local entry = {node=card, text=text, kind=kind, height=height}
                active[#active + 1] = entry
                layout()
                local token = generation
                local duration = 1.8 + math.min(1.6, math.max(0, textSize.height / 48 - 1) * 0.5)
                for _, child in ipairs({title, backdrop}) do
                    child:runAction(cc.Sequence:create(cc.DelayTime:create(duration - 0.35), cc.FadeOut:create(0.35)))
                end
                card:runAction(cc.Sequence:create(cc.DelayTime:create(duration), cc.CallFunc:create(function()
                    finish(entry, token)
                end)))
            end
        end
    end
    stack.pumpToasts = pump
    stack.queueToastPump = function()
        if stopped or disposed or stack.pendingToastPump then return end
        stack.pendingToastPump = true
        local token = generation
        stack:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
            if stopped or disposed or generation ~= token then return end
            stack.pendingToastPump = false
            if cc.Director:getInstance():getNotificationNode() == notification then pump() end
        end)))
    end
    stack.clearRoutineProductionToasts = function()
        local current = {}; for _, entry in ipairs(active) do current[#current + 1] = entry end
        for _, entry in ipairs(current) do if entry.kind == 'production' then finish(entry, generation) end end
    end
    stack:registerScriptHandler(function(event)
        if event == 'exit' or event == 'cleanup' then
            if not stopped then
                stopped = true; generation = generation + 1
                -- ActionManager retains its target even while paused. Keep the
                -- delayed driver on this owned node and cancel it on exit.
                stack:stopAllActions(); stack.pendingToastPump = false
                -- Already-visible cards are retired, never replayed in a new
                -- context. Unshown text stays FIFO; remove children in pump.
                for i = #active, 1, -1 do
                    local entry = active[i]
                    entry.node:stopAllActions(); entry.node:setVisible(false)
                    for _, child in ipairs(entry.node:getChildren()) do child:stopAllActions() end
                    entry.node.retiredToast = true
                end
                active = {}; usedHeight = 0
            end
            if event == 'cleanup' then disposed = true end
        elseif event == 'enter' then
            stopped = false; disposed = false
            if entered then pump() end
            entered = true
        end
    end)
    notification:addChild(stack)
    return stack
end

function ToastUtil:downString(str, bIsLimit, kind)
    -- The legacy limit remains a duplicate-spam guard, never a reason to drop
    -- a different achievement, reward or error behind another queued message.
    if bIsLimit then
        for i, pending in ipairs(self.infoQueue) do
            if pending == str and self.infoKinds[i] == (kind or false) then return end
        end
    end
    if #self.infoQueue == 0 then self.infoKinds = {} end
    table.insert(self.infoQueue, str)
    table.insert(self.infoKinds, kind or false)
    local director = cc.Director:getInstance()
    local notification = director:getNotificationNode()
    if not notification then return end
    ordinaryStack(self, notification, director:getVisibleSize()):queueToastPump()
end
