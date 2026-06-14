require "LuaClass/Header"

-- 按钮类型
-- 1代表只有确定按钮的对话框
-- 2代表有确定和取消按钮的对话框
local MSG_BOX_OK = 1
local MSG_BOX_OK_CANCEL =2

-- self.s_position  弹出框的坐标（中心点）
-- self.s_size      弹出框的尺寸
-- self.s_bg        弹出框的背景图

AlertView = class("AlertView",function()
    return cc.Layer:create()
end)
AlertView.__index = AlertView
AlertView.title = "提 示"
AlertView.closeBtn = nil
AlertView.isAutoClose = true

function AlertView:create(dtype, boxtype, title, callbackfunc, callbackcancelfunc, leftBtnStr, rightBtnStr)
    if leftBtnStr == nil then
        leftBtnStr = "取 消"
    end
    if rightBtnStr == nil then
        rightBtnStr = "确 定"
    end
    local layer = AlertView.new(dtype, boxtype, title, callbackfunc, callbackcancelfunc, leftBtnStr, rightBtnStr)
    cc.Director:getInstance():getRunningScene():addChild(layer, 1000)
    return layer
end

--初始化
function AlertView:ctor(dtype, boxtype, title, callbackfunc, callbackcancelfunc, leftBtnStr, rightBtnStr)
    -- print("AlertView:dtype=",dtype,"AlertView:title=",title,"AlertView:callback",callbackfunc)
    self.dtype = dtype
    self.title = title
    self.isAutoClose = true
    self.callbackfunc = callbackfunc
    self.callbackcancelfunc = callbackcancelfunc
    self.winSize = cc.Director:getInstance():getWinSize()
    self:setVisible(true)
    self:setLocalZOrder(999)
    self:setContentSize(self.winSize)
    local listener = cc.EventListenerTouchOneByOne:create()
    local function onTouchBegan(touch, event)
        return self:onTouchBegan(touch,event)
    end
    local function onTouchMoved(touch,event)
        self:onTouchMoved(touch,event)
    end
    local function onTouchEnded(touch,event)
        self:onTouchEnded(touch,event)
    end
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    listener:setSwallowTouches(true)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    -- self:createMsgBox()
    self:createBaseBox(boxtype, leftBtnStr, rightBtnStr)

end

function AlertView:setCancelCallback(callbackcancelfunc)

    self.callbackcancelfunc = callbackcancelfunc

end

function AlertView:setOkRemove(isremove)

    self.isAutoClose = isremove

end

-- 招募弹出框
function AlertView:createBaseBox(boxtype, leftBtnStr, rightBtnStr)
    local layerbg = cc.LayerColor:create(cc.c4b(0,0,0,64));
    self:addChild(layerbg)

    local pngname = "Images/UI/tankuang_01.png"
    if boxtype == 0 then
        pngname = "Images/UI/tankuang_01.png"
    elseif boxtype == 1 then
        pngname = "Images/Fight/dikuang_07.png"
    elseif boxtype == 2 then
        -- 复活框，add by yangjie
        pngname = "Images/charging/fuhuo_01.png"
    else
        pngname = "Images/UI/tankuang_03.png"
    end
    local background = cc.Scale9Sprite:create(pngname)
    local labelContentSize = cc.size(350,0)

    self.s_position = cc.p(self.winSize.width * 0.5,self.winSize.height * 0.5)
    background:setPosition(self.s_position)
    self:addChild(background)
    
    local msgBoxWidth = background:getContentSize().width
    local msgBoxHeight = background:getContentSize().height

    local contentSize = background:getContentSize()
    self.s_size = background:getContentSize()
    self.s_bg = background  

    if self.title ~= nil and self.title ~= "" then
        -- local label = ccui.Text:create()
        local label = cc.LabelTTF:create(self.title, BoldFont, 36.0)
        -- label:setDimensions(cc.size(350,0))
        -- label:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        -- label:enableGlow(cc.c4b(255, 255, 255, 255))
        label:setColor(cc.c3b(255,255,255))
        -- label:setHorizontalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        -- label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        -- label:setText(self.title)
        -- label:setFontSize(36)
        -- local labelContentSize = label:getTextAreaSize();
        label:setPosition(cc.p(msgBoxWidth * 0.5,msgBoxHeight-40))
        background:addChild(label,1)
    end
    
    --关闭弹出框
    local function cancelMsgBoxEvent(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if  self.callbackcancelfunc then
                
                self.callbackcancelfunc()
            end

            self:removeFromParent(true)
        end
    end
    --执行回调函数，并关闭弹出框
    local function okMsgBoxEvent(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if self.callbackfunc then
                self.callbackfunc()
            end
            if self.isAutoClose then
                self:removeFromParent(true)
            end
            
        end
    end
    

    self.closeBtn = SDButton:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png", function()
        cclog("点了按钮")
        cancelMsgBoxEvent(nil, ccui.TouchEventType.ended)
    end)
    self.closeBtn:addClickArea(cc.rect(-30, -30, 60, 60))
    self.closeBtn:setPosition(cc.p(msgBoxWidth-self.closeBtn:getContentSize().width*0.5-20,msgBoxHeight-self.closeBtn:getContentSize().height*0.5-10))
    background:addChild(self.closeBtn)

    --创建只有确定按钮的弹出框
    if self.dtype == MSG_BOX_OK then
      
        local okButton = ccui.Button:create()
        background:addChild(okButton)
        okButton:loadTextures("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        okButton:setPosition(cc.p(contentSize.width/2,50))
        okButton:setTouchEnabled(true)
        okButton:addTouchEventListener(cancelMsgBoxEvent)
        local okButtonSize = okButton:getContentSize()
        local okButtonLabel = cc.LabelTTF:create(rightBtnStr, BoldFont, 32.0)
        -- okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        okButtonLabel:setColor(cc.c3b(255,255,255))
        okButtonLabel:setPosition(cc.p(okButtonSize.width/2,okButtonSize.height/2))
        okButton:addChild(okButtonLabel)
        
    --创建具有确定和取消按钮的弹出框 
    elseif self.dtype == MSG_BOX_OK_CANCEL then
        local okButton = ccui.Button:create()
        background:addChild(okButton)
        okButton:loadTextures("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        okButton:setTouchEnabled(true)
        okButton:setPosition(cc.p(contentSize.width * 0.75,50))
        okButton:addTouchEventListener(okMsgBoxEvent)
        local okButtonSize = okButton:getContentSize()
        local okButtonLabel = cc.LabelTTF:create(rightBtnStr, BoldFont, 32.0)
        -- okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        okButtonLabel:setColor(cc.c3b(255,255,255))
        okButtonLabel:setPosition(cc.p(okButtonSize.width/2,okButtonSize.height/2))
        okButton:addChild(okButtonLabel)
        
        local cancelButton = ccui.Button:create()
        background:addChild(cancelButton)
        cancelButton:loadTextures("Images/btn/ann04_a.png","Images/btn/ann04_b.png","")
        cancelButton:setTouchEnabled(true)
        cancelButton:setPosition(cc.p(contentSize.width * 0.25,50))
        cancelButton:addTouchEventListener(cancelMsgBoxEvent)
        local cancelButtonSize = cancelButton:getContentSize()
        local cancelButtonLabel = cc.LabelTTF:create(leftBtnStr, BoldFont, 32.0)
        -- cancelButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        cancelButtonLabel:setColor(cc.c3b(255,255,255))
        cancelButtonLabel:setPosition(cc.p(cancelButtonSize.width/2,cancelButtonSize.height/2))
        cancelButton:addChild(cancelButtonLabel)
    end
end


function AlertView:createMsgBox()
    local layerbg = cc.LayerColor:create(cc.c4b(0,0,0,64));
    self:addChild(layerbg)


    local background = cc.Scale9Sprite:create("Images/UI/tankuang_04.png")
    self.s_bg = background  
    self.s_size = background:getContentSize()
    -- local label = ccui.Text:create()
    local label = cc.LabelTTF:create(self.title, BoldFont, 36.0)
    label:setDimensions(cc.size(350,0))
    -- label:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    label:setColor(cc.c3b(255,255,255))
    label:setHorizontalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    -- label:setText(self.title)
    -- label:setFontSize(36)
    -- local labelContentSize = label:getTextAreaSize();
    local labelContentSize = cc.size(350,0)


    local msgBoxWidth = 450
    local msgBoxHeight = labelContentSize.height + 400
    self.s_position = cc.p(self.winSize.width * 0.5,self.winSize.height * 0.5)
    background:setContentSize(cc.size(msgBoxWidth,msgBoxHeight))
    background:setPosition(self.s_position)
    self:addChild(background)
    
    local contentSize = background:getContentSize()
    label:setPosition(cc.p(msgBoxWidth * 0.5,msgBoxHeight-50))
    background:addChild(label,1)
    
    --关闭弹出框
    local function cancelMsgBoxEvent(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:removeFromParent(true)
        end
    end
    --执行回调函数，并关闭弹出框
    local function okMsgBoxEvent(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if self.callbackfunc then
                self.callbackfunc()
            end
            self:removeFromParent(true)
        end
    end
    
    --创建只有确定按钮的弹出框
    if self.dtype == MSG_BOX_OK then
      
        local okButton = ccui.Button:create()
        background:addChild(okButton)
        okButton:loadTextures("Images/btn/ann02_a.png","Images/btn/ann02_b.png","")
        okButton:setPosition(cc.p(contentSize.width/2,50))
        okButton:setTouchEnabled(true)
        okButton:addTouchEventListener(cancelMsgBoxEvent)
        local okButtonSize = okButton:getContentSize()
        -- local okButtonLabel = cc.Sprite:create()
        -- okButtonLabel:setTexture("confirm.png")
        -- local okButtonLabel = cc.LabelTTF:create("确 定", BoldFont, 32.0)
        -- okButtonLabel:setPosition(cc.p(okButtonSize.width/2,okButtonSize.height/2))
        -- okButton:addChild(okButtonLabel)
        
    --创建具有确定和取消按钮的弹出框 
    elseif self.dtype == MSG_BOX_OK_CANCEL then
        local okButton = ccui.Button:create()
        background:addChild(okButton)
        okButton:loadTextures("Images/btn/ann02_a.png","Images/btn/ann02_b.png","")
        okButton:setTouchEnabled(true)
        okButton:setPosition(cc.p(contentSize.width/2-100,50))
        okButton:addTouchEventListener(okMsgBoxEvent)
        local okButtonSize = okButton:getContentSize()
        -- local okButtonLabel = cc.Sprite:create()
        -- okButtonLabel:setTexture("confirm.png")
        -- okButtonLabel:setPosition(cc.p(okButtonSize.width/2,okButtonSize.height/2))
        -- okButton:addChild(okButtonLabel)
        
        local cancelButton = ccui.Button:create()
        background:addChild(cancelButton)
        cancelButton:loadTextures("Images/btn/ann02_a.png","Images/btn/ann02_b.png","")
        cancelButton:setTouchEnabled(true)
        cancelButton:setPosition(cc.p(contentSize.width/2+100,50))
        cancelButton:addTouchEventListener(cancelMsgBoxEvent)
        local cancelButtonSize = cancelButton:getContentSize()
        -- local cancelButtonLabel = cc.Sprite:create()
        -- cancelButtonLabel:setTexture("cancel.png")
        -- cancelButtonLabel:setPosition(cc.p(cancelButtonSize.width/2,cancelButtonSize.height/2))
        -- cancelButton:addChild(cancelButtonLabel)
    end
end

function AlertView:onTouchBegan(touch, event)
    return true
end

function AlertView:onTouchEnded(touch, event)

    local curLocation = self:convertToNodeSpace(touch:getLocation())
    local rect = self.s_bg:getBoundingBox()
    if cc.rectContainsPoint(rect, curLocation) then
       print("point in rect")
    else
       -- self:removeFromParent(true)
    end
  
end

function AlertView:onTouchMoved(touch, event)
  
end

return AlertView