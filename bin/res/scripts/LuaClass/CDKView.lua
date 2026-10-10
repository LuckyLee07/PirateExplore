require "LuaClass/Header"
require "LuaClass/DialogTheme"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/HttpSingleton"
require "LuaClass/DataManager"

CDKView = class("CDKView", function ()
    return DialogueView:create()
end)
CDKView.__index = CDKView
CDKView.serviceURL = ""
function CDKView:create()
    local view = CDKView.new()
    if view and view:init() then
        return view
    end
    return nil
end
function CDKView:init()
    self:registerScriptHandler(function(event)
        if event == "exit" then self._closed = true end
    end)
    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = DialogTheme.panelFromLegacy("Images/UI/tankuang_01.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)
    --title
    local title  = cc.LabelTTF:create("兑换码",MasterTheme.headingFont(false),36)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    DialogTheme.fit(title, bg:getContentSize().width - 130)
    self:addChild(title)

    local _tip1 = cc.LabelTTF:create("输入兑换码领取奖励!\n(每个兑换码仅限使用1次)",MasterTheme.headingFont(false),36)
    _tip1:setPosition(cc.p(bg:getPositionX(),title:getPositionY()-110))
    -- _tip1:setAnchorPoint(cc.p(0,0.5))
    -- _tip1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip1)
    
    local _kuang = DialogTheme.cardFromLegacy("Images/UI/kuang_10.png", "paper")
    _kuang:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()-25))
    self:addChild(_kuang)

    local textField = ccui.TextField:create()
    textField:setMaxLengthEnabled(true)
    textField:setMaxLength(15)
    textField:setTouchEnabled(true)
    textField:setFontName(MasterTheme.headingFont(false))
    textField:setTouchSize(_kuang:getContentSize());
    textField:setFontSize(30)
    textField:setColor(MasterTheme.colors.ink)
    textField:setPlaceHolder("点击此处输入兑换码")
    textField:setPosition(cc.p(_kuang:getPositionX(), _kuang:getPositionY()))
    textField:addEventListenerTextField(function (sender, eventType)
        -- if eventType == ccui.TextFiledEventType.attach_with_ime then
        --     print("attach with IME",textField:getStringValue())
        -- elseif eventType == ccui.TextFiledEventType.detach_with_ime then
        --     print("detach with IME",textField:getStringValue())
        -- elseif eventType == ccui.TextFiledEventType.insert_text then
        --     print("insert words",textField:getStringValue())
        -- elseif eventType == ccui.TextFiledEventType.delete_backward then
        --     print("delete word",textField:getStringValue())
        -- end
    end) 
    self:addChild(textField)
    self.textField = textField
    -- btn
    local btn = DialogTheme.closeItem()
    btn:registerScriptTapHandler(function()
        self:close()
    end)
    btn:setPosition(cc.p(bg:getPositionX()+bg:getContentSize().width/2-40,title:getPositionY()))
    local menu = cc.Menu:create(btn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    --end
    local _cannelButton = DialogTheme.menuItem("Images/btn/ann03_a.png", "Images/btn/ann03_b.png", "secondary")
    _cannelButton:setPosition(cc.p(bg:getPositionX()-130,bg:getPositionY()-bg:getContentSize().height/2+50))
    _cannelButton:registerScriptTapHandler(function()
        self:close()
    end)

    local _sureButton = DialogTheme.menuItem("Images/btn/ann03_a.png", "Images/btn/ann03_b.png")
    _sureButton:setPosition(cc.p(bg:getPositionX()+130,_cannelButton:getPositionY()))
    self.submitButton = _sureButton
    _sureButton:registerScriptTapHandler(function()
        self:requestNetwork(textField:getStringValue())
    end)

    local menuIcon = cc.Menu:create(_cannelButton,_sureButton)
    menuIcon:setPosition(0.0, 0.0)
    self:addChild(menuIcon)

    local okButtonLabel = cc.LabelTTF:create("确 定", MasterTheme.headingFont(false), 32.0)
    --okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    okButtonLabel:setColor(cc.c3b(255,255,255))
    okButtonLabel:setPosition(_sureButton:getPosition())
    self:addChild(okButtonLabel)

    local cancelButtonLabel = cc.LabelTTF:create("取 消", MasterTheme.headingFont(false), 32.0)
    -- cancelButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    cancelButtonLabel:setColor(cc.c3b(255,255,255))
    cancelButtonLabel:setPosition(_cannelButton:getPosition())
    self:addChild(cancelButtonLabel)

    return true
end
function CDKView:close()
    if self._closed then return end
    self._closed = true
    DialogueView.close(self)
end

function CDKView:validateCode(code)
    if type(code) ~= "string" or code:gsub("%s", ""):gsub("　", "") == "" then
        ToastUtil:toastString("兑换码不能为空")
        return false
    end
    return true
end

function CDKView:setRequestPending(pending)
    self._requestPending = pending
    if not self._closed and self.submitButton then self.submitButton:setEnabled(not pending) end
end

-- Legacy HTTP redemption remains opt-in only when a real service is configured.
-- Validate the complete response before applying the unchanged gift definitions.
function CDKView:httpConnection(cdk)
    if self._closed or self._requestPending or not self:validateCode(cdk) then return false end
    local url = self.serviceURL
    if type(url) ~= "string" or not url:match("^https?://") then
        self:setRequestPending(false)
        ToastUtil:toastString("兑换服务暂未配置")
        return false
    end
    self:setRequestPending(true)
    local completed = false
    local function finish(message, success)
        if completed then return end
        completed = true
        self:setRequestPending(false)
        if not self._closed then
            ToastUtil:toastString(message)
            if success then self:close() end
        end
    end
    local function callback(xhr)
        if completed then return end
        local status = xhr and tonumber(xhr.status)
        if not xhr or (status and (status < 200 or status >= 300)) or
            type(xhr.response) ~= "string" or xhr.response:match("^%s*$") then
            finish("兑换服务暂不可用，请稍后重试")
            return
        end
        local ok, data, shape = pcall(HttpSingleton.decodeResponse, HttpSingleton, xhr.response)
        if not ok or type(data) ~= "table" or shape.kind ~= "object" then
            finish("兑换数据异常，请稍后重试")
            return
        end
        if data.status ~= nil then
            finish(type(data.errorMsg) == "string" and data.errorMsg ~= "" and data.errorMsg or "兑换未完成，请稍后重试")
            return
        end
        local giftCSV = DataManager:getInstance():getCSVByID(csvOfGift)
        local goods = type(giftCSV) == "table" and giftCSV[tostring(data.dropId)]
        local items = type(goods) == "table" and goods[dataKeyItems]
        if data.dropId == nil or type(items) ~= "table" or #items == 0 then
            finish("兑换奖励数据异常，请稍后重试")
            return
        end
        for _, item in ipairs(items) do
            if type(item) ~= "table" or item[1] == nil or item[2] == nil or item[3] == nil then
                finish("兑换奖励数据异常，请稍后重试")
                return
            end
        end
        -- A successful submitted redemption must not lose its reward merely
        -- because the dialog was dismissed while the request was in flight.
        completed = true
        for _, item in ipairs(items) do
            DataManager:getInstance():cdkExchangeGoods(item[1], item[2], item[3])
        end
        self:setRequestPending(false)
        if not self._closed then
            ToastUtil:toastString("兑换成功")
            self:close()
        end
    end
    local ok = pcall(function()
        local tmp = HttpSingleton:getInstance()
        local header = {cmdid=1002, usrId=getonlyID()}
        local request = url.."header="..json.encode(header).."&body="..json.encode({cdk=cdk})
        tmp:send(tmp.POST, request, {type="local"}, callback)
    end)
    if not ok then finish("兑换服务暂不可用，请稍后重试"); return false end
    return true
end

function CDKView:requestNetwork(codeKey)
    if self._closed or self._requestPending or not self:validateCode(codeKey) then return false end
    -- The native SDK owns its connectivity. Posting to an unrelated website
    -- neither verifies redemption availability nor proves a code is valid.
    local platform = cc.Application:getInstance():getTargetPlatform()
    local enabled, interfaces = false, nil
    if type(getEnableInterface) == "function" then
        local ok, value = pcall(getEnableInterface)
        if ok and type(value) == "string" then
            ok, interfaces = pcall(json.decode, value)
            enabled = ok and type(interfaces) == "table" and interfaces.UserCenter == "Enabled"
        end
    end
    if not enabled or (platform ~= cc.PLATFORM_OS_IPHONE and platform ~= cc.PLATFORM_OS_IPAD) or
        type(decodeExKey) ~= "function" then
        ToastUtil:toastString("此平台的兑换服务暂不可用")
        return false
    end
    self:setRequestPending(true)
    local ok, success = pcall(decodeExKey, codeKey)
    self:setRequestPending(false)
    if ok and success == true then
        ToastUtil:toastString("兑换成功")
        self:close()
        return true
    end
    -- The recovered iOS bridge is a stub returning false. Do not mislabel a
    -- missing service as an invalid player code, or issue a local reward.
    ToastUtil:toastString("兑换服务暂不可用，请稍后重试")
    return false
end
