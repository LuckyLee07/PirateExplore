--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/19
-- Time: 下午2:08
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
require "LuaClass/DialogTheme"
require "LuaClass/UIKit"
require "LuaClass/NotificationNode"
--require "LuaClass/Utils"
--require "socket"


--local MAX_Z_ORDER = 2147483647   -- 32(or 64)位机器上int的最大值
local MAX_Z_ORDER = 800

-- DialogueViewManager
DialogueViewManager = class("DialogueViewManager", function ()
    return {}
end)

DialogueViewManager.__index = DialogueViewManager
DialogueViewManager.data = {}

-- views 容器
--DialogueViewManager.views = nil

-- views 数量
DialogueViewManager.viewCount = 0

--instance
local instance

local create = function()
    local manager = DialogueViewManager.new()
    if manager and manager:init() then
        return manager
    end
    return nil
end

function DialogueViewManager:init()
    self.data = {}
    self.viewCount = 0
    return true
end

function DialogueViewManager:sharedInstance()
    if instance == nil then
        instance = create()
    end
    return instance
end

-- A pushed scene keeps its own stack. A replacement scene must never inherit
-- Lua wrappers for a mask that the previous native scene has already destroyed.
function DialogueViewManager:stateForScene(scene, createState)
    if not scene then return nil end
    local state = scene._dialogueViewState
    if not state and createState then
        state = {scene=scene, entries={}}
        scene._dialogueViewState = state
        local owner = cc.Node:create()
        owner:registerScriptHandler(function(event)
            if event == "cleanup" and not state.disposed then
                state.disposed = true
                for _, entry in ipairs(state.entries) do
                    if entry.view._dialogueEntry == entry then
                        entry.view._dialogueEntry = nil
                        entry.view._dialogueClosing = false
                    end
                end
                state.entries = {}
                state.mask = nil
                scene._dialogueViewState = nil
                self:Count()
                -- Do not remove siblings while native Node::cleanup iterates.
            end
        end)
        scene:addChild(owner)
    end
    return state
end

function DialogueViewManager:refreshState(state)
    if not state or state.disposed then return end
    local topOrder
    for i, entry in ipairs(state.entries) do
        local order = math.max(entry.zOrder + i, topOrder and topOrder + 1 or entry.zOrder + i)
        entry.view:setLocalZOrder(order)
        topOrder = order
    end
    if state.mask then
        state.mask:setVisible(topOrder ~= nil)
        if topOrder then state.mask:setLocalZOrder(topOrder - 1) end
    end
end

function DialogueViewManager:addView(view, state, zOrder)
    if view._dialogueEntry then return view._dialogueEntry end
    if not state.mask then
        state.mask = cc.LayerColor:create(cc.c4b(3, 20, 29, 166))
        state.scene:addChild(state.mask, zOrder - 1)
    end
    local entry = {view=view, state=state, zOrder=zOrder}
    state.entries[#state.entries+1] = entry
    view._dialogueEntry = entry
    view._dialogueClosing = false
    self:refreshState(state)
    self:Count()
    return entry
end

function DialogueViewManager:removeView(view)
    local entry = view._dialogueEntry
    if not entry then return end
    view._dialogueEntry = nil
    view._dialogueClosing = false
    local state = entry.state
    for i, current in ipairs(state.entries) do
        if current == entry then
            table.remove(state.entries, i)
            break
        end
    end
    self:refreshState(state)
    self:Count()
end

-- Explicit closes call this only after removing the view. Lifecycle callbacks
-- merely hide an empty mask, avoiding mutation of native sibling iteration.
function DialogueViewManager:releaseEmptyMask(state)
    if state and not state.disposed and #state.entries == 0 and state.mask then
        local mask = state.mask
        state.mask = nil
        mask:removeFromParent()
    end
end

-- 是否无view正在显示
function DialogueViewManager:empty()
    return self:Count() == 0
end

function DialogueViewManager:Count()
    local state = self:stateForScene(cc.Director:getInstance():getRunningScene())
    self.data = {}
    if state then for _, entry in ipairs(state.entries) do self.data[#self.data+1] = entry.view end end
    self.viewCount = #self.data
    return self.viewCount
end

function DialogueViewManager:removeAllView()
    local state = self:stateForScene(cc.Director:getInstance():getRunningScene())
    if not state then return end
    local views = {}
    for _, entry in ipairs(state.entries) do views[#views+1] = entry.view end
    for _, view in ipairs(views) do
        self:removeView(view)
        view:stopAllActions()
        view:removeFromParent()
    end
    self:releaseEmptyMask(state)
    self:Count()
end


-- DialogueView
DialogueView = class("DialogueView", function ()
    return cc.Layer:create()
end)
DialogueView.__index = DialogueView

DialogueView.tapEventListener = nil

function DialogueView:create()
    local v = DialogueView:new()
    if v and v:init() then
        return v
    end
    return nil
end

function DialogueView:init()
    self.tapEventListener = nil
    return true
end

-- Subclasses rebuild their content in place (Lackmaterial:reflush). The
-- lifecycle observer is infrastructure, not content: clearing it would look
-- like removal of the still-attached dialog and strand its close callback.
function DialogueView:removeAllChildren(cleanup)
    for _, child in ipairs(self:getChildren()) do
        if child ~= self._dialogueLifecycle then
            child:removeFromParent(cleanup ~= false)
        end
    end
end

function DialogueView:setTapEventListener(listener)
    assert(type(listener) == "function")
    self.tapEventListener = listener
    return true
end

function DialogueView:rigisterEventListener()
    if self._dialogueTouchRegistered then return end
    self._dialogueTouchRegistered = true
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function (touch, event)
        if self.tapEventListener and not self._dialogueClosing then
            self.tapEventListener()
        end
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(function (touch, event)
    end, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(function (touch, event)
    end, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function DialogueView:show(zOrder)
    return self:showEffect(zOrder)
end

function DialogueView:hide()
    self:close()
end

function DialogueView:close()
    self:closeEffect()
end

function DialogueView:showEffect(zOrder)
    if self:getParent() then return false end
    local manager = DialogueViewManager:sharedInstance()
    local scene = cc.Director:getInstance():getRunningScene()
    if not scene then return false end
    local state = manager:stateForScene(scene, true)
    zOrder = zOrder or MAX_Z_ORDER
    if not self._dialogueLifecycle then
        local owner = cc.Node:create()
        self._dialogueLifecycle = owner
        owner:registerScriptHandler(function(event)
            local entry = self._dialogueEntry
            if not entry then return end
            -- Node::onExit marks the scene non-running before visiting its
            -- children. Keep a pushed scene's views; detach an individually
            -- removed view while its owning scene is still running.
            if event == "cleanup" or (event == "exit" and entry.state.scene:isRunning()) then
                manager:removeView(self)
            end
        end)
        self:addChild(owner)
    end
    self:rigisterEventListener()
    manager:addView(self, state, zOrder)
    scene:addChild(self, self:getLocalZOrder())
    local scale1 = cc.ScaleTo:create(0.0, 0.1)
    local scale2 = cc.ScaleTo:create(0.1, 1.2)
    local scale3 = cc.ScaleTo:create(0.1, 1.0)
    local action = cc.Sequence:create(scale1, scale2, scale3);
    self:runAction(action)
    return true
end

function DialogueView:closeEffect()
    local entry = self._dialogueEntry
    if not entry or self._dialogueClosing then return end
    self._dialogueClosing = true
    local manager = DialogueViewManager:sharedInstance()
    local scale1 = cc.ScaleTo:create(0.1, 1.2)
    local scale2 = cc.ScaleTo:create(0.1, 0.1)
    local callback = cc.CallFunc:create(function()
        -- A removed/reopened view or a disposed scene invalidates this
        -- exact registration, even if an old callback is already queued.
        if self._dialogueEntry ~= entry or entry.state.disposed then return end
        manager:removeView(self)
        self:removeFromParent()
        manager:releaseEmptyMask(entry.state)
    end)
    local action = cc.Sequence:create(scale1, scale2, callback);
    self:runAction(action)
end
