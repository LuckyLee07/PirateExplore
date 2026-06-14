require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/DataManager"


RateView = class("RateView", function ()
    return DialogueView:create()
end)
RateView.__index = RateView
function RateView:create()
    local view = RateView.new()
    if view and view:init() then
        return view
    end
    return nil
end

function RateView:init()
    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)

    --title
    local title  = cc.LabelTTF:create("好评有奖",BoldFont,37)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-35))
    title:setColor(WriteColor)
    title:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self:addChild(title)

    local _tip1 = cc.LabelTTF:create("来个五星好评吧亲!\n参与好评立送100钻石!!!",BoldFont,36)
    _tip1:setPosition(cc.p(bg:getPositionX(),title:getPositionY()-150))
    self:addChild(_tip1)

    -- btn
    local btn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
    btn:registerScriptTapHandler(function()
        self:close()
    end)
    btn:setPosition(cc.p(bg:getPositionX()+bg:getContentSize().width/2-40,title:getPositionY()))
    local menu = cc.Menu:create(btn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    --end
    local _cannelButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
    _cannelButton:setPosition(cc.p(bg:getPositionX()-130,bg:getPositionY()-bg:getContentSize().height/2+75))
    _cannelButton:registerScriptTapHandler(function()
        self:close()
    end)

    local _sureButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
    _sureButton:setPosition(cc.p(bg:getPositionX()+130,_cannelButton:getPositionY()))
    _sureButton:registerScriptTapHandler(function()
        rateIniTunes()
    end)

    local menuIcon = cc.Menu:create(_cannelButton,_sureButton)
    menuIcon:setPosition(0.0, 0.0)
    self:addChild(menuIcon)

    local okButtonLabel = cc.LabelTTF:create("评 分", BoldFont, 32.0)
    --okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    okButtonLabel:setColor(cc.c3b(255,255,255))
    okButtonLabel:setPosition(_sureButton:getPosition())
    self:addChild(okButtonLabel)

    local cancelButtonLabel = cc.LabelTTF:create("拒 绝", BoldFont, 32.0)
    -- cancelButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    cancelButtonLabel:setColor(cc.c3b(255,255,255))
    cancelButtonLabel:setPosition(_cannelButton:getPosition())
    self:addChild(cancelButtonLabel)

    return true
end

function showRateScene()
    print("TT---------showRateScene");
    local rateView = RateView:create()
    rateView:show()
end

