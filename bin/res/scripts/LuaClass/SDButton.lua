require "LuaClass/Header"
require "AudioEngine"
require "LuaClass/DataManager"


SDButton = class("SDButton", function ()
    return cc.Layer:create()
end)

SDButton.__index = SDButton
SDButton.bIsEnable = true
SDButton.listener = nil
SDButton.clickArea = nil
SDButton.touchEffectiveArea = nil

function SDButton:create(normalpng,selectpng,callbackfunc)
    local view = SDButton.new(normalpng,selectpng,callbackfunc)
    if view then
        return view
    end
    return nil
end

function SDButton:registerSingleCLick(callbackfunc)
    if callbackfunc ~= nil then
        self.onSingleCLick = callbackfunc
    end
end

function SDButton:registerDoubleClick(callbackfunc)
    if callbackfunc ~= nil then
        self.onDoubleClick = callbackfunc
    end
end

function SDButton:registerThreeClick(callbackfunc)
    if callbackfunc ~= nil then
        self.onThreeClick = callbackfunc
    end
end

function SDButton:registerLongPressedActiveOnce(callbackfunc)
    if callbackfunc ~= nil then
        self.onLongPressedActiveOnce = callbackfunc
    end
end

function SDButton:registerLongPressed(callbackfunc)
    if callbackfunc ~= nil then
        self.onLongPressed = callbackfunc
    end
end

function SDButton:registerMove(callbackfunc)
    if callbackfunc ~= nil then
        self.onMove = callbackfunc
    end
end

function SDButton:registerSwip(callbackfunc)
    if callbackfunc ~= nil then
        self.onSwip = callbackfunc
    end
end

--初始化
function SDButton:ctor(normalpng,selectpng,callbackfunc)

    -- print("SDButton:normalpng=",normalpng,"SDButton:selectpng=",selectpng,"SDButton:callback",callbackfunc)

    self.onSingleCLick = callbackfunc                    --单击  
    self.onDoubleClick = nil                    --双击  
    self.onThreeClick = nil                     --3连击  
    self.onLongPressedActiveOnce = nil          --长按 只触发一次
    self.onLongPressed = nil                    --长按  
    self.onMove = nil                           --移动  
    self.onSwip = nil                           --滑动
    self.singleCLickEnable = true               --防止玩家多次点击按钮影响逻辑
    self.clickArea = cc.rect(0, 0, 0, 0)

    self.minSwipdistance = 100 
    self.minSwiptime     = 1000    --毫秒  
    self.maxClickedDis   = 20  

    self.isTouch         = false
  
    self.isMoved         = false  
  
    self.pressTimes      = 0  
  
    self.touchCounts     = 0 

    self.m_longProgress       = false 

    self.normalSpr = cc.Sprite:create(normalpng)
    self.normalSpr:setAnchorPoint(cc.p(0, 0))
    self.selectSpr = cc.Sprite:create(selectpng)
    self.selectSpr:setAnchorPoint(cc.p(0, 0))
    self.callbackfunc = callbackfunc
    self.winSize = cc.Director:getInstance():getWinSize()
    self:setVisible(true)
    self:setLocalZOrder(999)
    self:setContentSize(self.normalSpr:getContentSize())
    self:setAnchorPoint(cc.p(0.5, 0.5))
    self:ignoreAnchorPointForPosition(false)
    -- 要让自己向下传递alpha矩阵才可以
    self:setCascadeOpacityEnabled(true)
    
    self.listener = cc.EventListenerTouchOneByOne:create()
    local function onTouchBegan(touch, event)
      return self:onTouchBegan(touch,event)
    end
    local function onTouchMoved(touch,event)
      self:onTouchMoved(touch,event)
    end
    local function onTouchEnded(touch,event)
      self:onTouchEnded(touch,event)
    end
    self.listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    self.listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    self.listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    self.listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self.listener, self)
    -- self:createMsgBox()
    -- self:createBaseBox()
    self:addChild(self.normalSpr)
    self:addChild(self.selectSpr)
    -- 默认设置状态为未解锁
    self:setActive(false)
end


function SDButton:setFlippedX(mFlippedX)
    if mFlippedX then
        self.normalSpr:setFlippedX(true)
    end
end

function SDButton:setEnabled(isEnable)
    -- body
    self.bIsEnable = isEnable
end

function SDButton:setSwallowTouches(bIsSwallowTouches)
    -- body
    self.listener:setSwallowTouches(bIsSwallowTouches)
end

-- 设置点击有效增加的区域，比如之前是0，0，4，4，那么传进来的这个rect会加在之前这个上
function SDButton:addClickArea(addRects)
    self.clickArea = addRects
end

function SDButton:onTouchBegan(touch, event)
    -- print("SDButton",self:isVisible())
    local isTouchInEffectArea = true
    local c = self:getParent()
    while (c ~= nil) do
        if c.bIsScrollView then
            -- print("找到scrollView")
            if not cc.rectContainsPoint(c:getBoundingBox(), touch:getLocation()) then
                -- print("没在可点击区域内")
                isTouchInEffectArea = false
            end
        end
        if c:isVisible() == false then
            return false
        end
        c = c:getParent()
    end

    if self:isVisible() == false or self.bIsEnable == false then
        return false
    end

    local curLocation = self:convertToNodeSpace(touch:getLocation())
    local rect = self.normalSpr:getBoundingBox()
    rect = cc.rect(rect.x + self.clickArea.x, rect.y + self.clickArea.y, rect.width + self.clickArea.width, rect.height + self.clickArea.height)
    if cc.rectContainsPoint(rect, curLocation) and isTouchInEffectArea then
       -- print("point in rect")
        self.m_startPoint = self:convertToNodeSpace(touch:getLocation())
  
        self.isTouch = true
              
        self.m_startTime = getSystemTimeMilliSecond() 
             
         --处理长按事件
        function myupdate()
             -- body
            self:updatelongprogress()
        end
        -- self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(myupdate, 0.6, false)
        schedule(self.normalSpr, myupdate, 0.6)
        -- print("SDButton:onTouchBegan")
        self:setActive(true)
        return true
    else
        return false
    end
end

function SDButton:setSingleCLickEnable( enable )
    self.singleCLickEnable = enable

end

function SDButton:onTouchEnded(touch, event)

    self.isTouch = false
    self.pressTimes = 0  
    -- if self.schduler ~= nil then
    --     cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
    -- end
    self.normalSpr:stopAllActions()
    --如果刚完成长按事件 则把按下次数清零 长按状态置空 直接返回 不继续执行  
    local curLocation = self:convertToNodeSpace(touch:getLocation())
    local rect = self.normalSpr:getBoundingBox()
    rect = cc.rect(rect.x + self.clickArea.x, rect.y + self.clickArea.y, rect.width + self.clickArea.width, rect.height + self.clickArea.height)
    -- 设置激活状态为空
    self:setActive(false)
    -- 判断是否点击到点击有效区范围内
    if cc.rectContainsPoint(rect, curLocation) then
        if self.m_longProgress  then  
            -- 长按的情况允许他
            self.touchCounts = 0
            self.m_longProgress = false
            return
        else
            if not self.singleCLickEnable then
                return
            end

            self:onSingleCLick()
            if DataManager:getInstance():getSound_off() == 0 then
                AudioEngine.playEffect(EFFECT_Button, false)
            end
            return
        end
    end

    self.m_endPoint = self:convertToNodeSpace(touch:getLocation())
      
    local endTime = getSystemTimeMilliSecond() 
      
    local timeDis = endTime - self.m_startTime 
      
    -- E_SWIP_DIR dir=GetSwipDir(m_startPoint, m_endPoint,timeDis);  
      
    -- if ( dir != E_INVAILD) {  
    --     onSwip(m_startPoint, m_endPoint, dir);  
    --     return;  
    -- }  
      
    --做连击判断  
    if self.isMoved then
        self.isMoved = false;  
        return;  
    end

    if self.touchCounts == 2 then
        if self.onThreeClick then
            self.onThreeClick()
        end
        self.touchCounts = 0
    elseif self.touchCounts == 1 then
        -- cc.Director:getInstance():getScheduler():scheduleScriptFunc(self.updateDoubleDelay, 0.25, true)
        schedule(self.normalSpr, self.updateDoubleDelay, 0.25)
        self.touchCounts = self.touchCounts + 1
    elseif self.touchCounts == 0 then
        -- cc.Director:getInstance():getScheduler():scheduleScriptFunc(self.updateSingleDelay, 0.25, true)
        schedule(self.normalSpr, self.updateSingleDelay, 0.25)
        self.touchCounts = self.touchCounts + 1
    end
end

function SDButton:onTouchMoved(touch, event)
    self.isMoved   = true 
    local curPoint = self:convertToNodeSpace(touch:getLocation()) 
    if self.onMove then
        self.onMove(curPoint)
    end
end

function SDButton:setActive(bIsActive)
    self.normalSpr:setVisible(not bIsActive)
    self.selectSpr:setVisible(bIsActive)
end

function SDButton:updateSingleDelay(ft)  
 
    if self.touchCounts == 1 then 
 
        if self.onSingleCLick then
            self.onSingleCLick()
        end
        self.touchCounts = 0 

    end 
end 
  
function SDButton:updateDoubleDelay(ft)  

    if self.touchCounts == 2 then 

        if self.onDoubleClick then
            self.onDoubleClick()
        end
        self.touchCounts = 0
    end 
end
  
function SDButton:updatelongprogress()
    -- cclog("SDButton:updatelongprogress(ft)")
    -- cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.schduler)
    self:stopAllActions()
    if self.isTouch then 

        self.pressTimes = self.pressTimes + 1
          
        -- if self.pressTimes >= 2 then

            self.m_longProgress = true

            if self.onLongPressed then
                self.onLongPressed()
                --处理长按事件
                function myupdate()
                -- body
                    self:onLongPressed()
                end
                -- self.schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(myupdate, 0.1, false)
                schedule(self.normalSpr, myupdate, 0.1)
            end
            if self.onLongPressedActiveOnce then
                 self.onLongPressedActiveOnce()
            end
              
        -- end
    else
        self.pressTimes = 0
    end
end

return SDButton