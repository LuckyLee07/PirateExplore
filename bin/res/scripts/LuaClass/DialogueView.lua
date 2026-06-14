--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/19
-- Time: 下午2:08
-- To change this template use File | Settings | File Templates.
--

require "LuaClass/Header"
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

-- maskLayer
local maskLayer

local create = function()
    local manager = DialogueViewManager.new()
    if manager and manager:init() then
        return manager
    end
    return nil
end

function DialogueViewManager:init()
--    self.views = {}
    self.viewCount = 0
    return true
end

function DialogueViewManager:sharedInstance()
    if instance == nil then
        instance = create()
    end
    return instance
end

-- addView
function DialogueViewManager:addView(view)
--    self.views.view = view
    self.viewCount = self.viewCount+1
    self.data[#self.data+1] = view
    --print("self.data==",#self.data)
end

-- removeView
function DialogueViewManager:removeView(view)
--    self.views.view = nil
    self.viewCount = self.viewCount-1
    if self.viewCount<0 then self.viewCount = 0 end
    for i=1,#self.data do
        if self.data[i] == view then
            table.remove(self.data,i)
            --print("remove==View")
            break
        end
    end
end

-- 是否无view正在显示
function DialogueViewManager:empty()
    return self.viewCount==0 -- and is_table_empty(self.views)
end

function DialogueViewManager:Count()
     return self.viewCount
end

function DialogueViewManager:removeAllView()
    for i=1,#self.data do
        local _view = self.data[i]
        if _view ~= nil then
            _view:removeFromParent()
        end
    end
    self.data = nil
    self.data ={}
    cc.Director:getInstance():getRunningScene():removeChild(maskLayer)
    maskLayer = nil
    self.viewCount = 0
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

function DialogueView:setTapEventListener(listener)
    assert(type(listener) == "function")
    self.tapEventListener = listener
    return true
end

function DialogueView:rigisterEventListener()
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function (touch, event)
        if self.tapEventListener then
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
    self:rigisterEventListener()
    self:showEffect(zOrder)
end

function DialogueView:hide()
    self:close()
end

function DialogueView:close()
    self:closeEffect()
end

function DialogueView:showEffect(zOrder)
    if zOrder == nil then
        zOrder = MAX_Z_ORDER
    end
    if nil == self:getParent() then
        local scale1 = cc.ScaleTo:create(0.0, 0.1)
        local scale2 = cc.ScaleTo:create(0.1, 1.2)
        local scale3 = cc.ScaleTo:create(0.1, 1.0)
        local action = cc.Sequence:create(scale1, scale2, scale3);
        self:runAction(action)
        if DialogueViewManager:sharedInstance():empty() then
            maskLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 100))
            cc.Director:getInstance():getRunningScene():addChild(maskLayer, zOrder-1)
        end
        DialogueViewManager:sharedInstance():addView(self)
         local _count = 0
        if maskLayer ~= nil then
             _count = DialogueViewManager:sharedInstance():Count()
            cc.Director:getInstance():getRunningScene():reorderChild(maskLayer, zOrder+_count-1)
        end
        cc.Director:getInstance():getRunningScene():addChild(self, zOrder+_count)
    end
end

function DialogueView:closeEffect()
    if nil ~= self:getParent() then
        local scale1 = cc.ScaleTo:create(0.1, 1.2)
        local scale2 = cc.ScaleTo:create(0.1, 0.1)
        local callback = cc.CallFunc:create(function()
        DialogueViewManager:sharedInstance():removeView(self)
        if maskLayer ~= nil then
            local _order = maskLayer:getLocalZOrder()
            cc.Director:getInstance():getRunningScene():reorderChild(maskLayer, _order-1)
        end
            if DialogueViewManager:sharedInstance():empty() then
                cc.Director:getInstance():getRunningScene():removeChild(maskLayer)
                maskLayer = nil
            end
            self:removeFromParent()
        end)
        local action = cc.Sequence:create(scale1, scale2, callback);
        self:runAction(action)
    end
end