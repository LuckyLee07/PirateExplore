require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/HttpSingleton"
require "LuaClass/DataManager"

CDKView = class("CDKView", function ()
    return DialogueView:create()
end)
CDKView.__index = CDKView
function CDKView:create()
    local view = CDKView.new()
    if view and view:init() then
        return view
    end
    return nil
end
function CDKView:init()
    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)
    --title
    local title  = cc.LabelTTF:create("兑换码",BoldFont,36)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    title:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self:addChild(title)

    local _tip1 = cc.LabelTTF:create("输入兑换码领取奖励!\n(每个兑换码仅限使用1次)",BoldFont,36)
    _tip1:setPosition(cc.p(bg:getPositionX(),title:getPositionY()-110))
    -- _tip1:setAnchorPoint(cc.p(0,0.5))
    -- _tip1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip1)
    
    local _kuang = cc.Sprite:create("Images/UI/kuang_10.png")
    _kuang:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()-25))
    self:addChild(_kuang)

    local textField = ccui.TextField:create()
    textField:setMaxLengthEnabled(true)
    textField:setMaxLength(15)
    textField:setTouchEnabled(true)
    --textField:setFontName(font_TextName)
    textField:setTouchSize(_kuang:getContentSize());
    textField:setFontSize(34)
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
    _cannelButton:setPosition(cc.p(bg:getPositionX()-130,bg:getPositionY()-bg:getContentSize().height/2+50))
    _cannelButton:registerScriptTapHandler(function()
        self:close()
    end)

    local _sureButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
    _sureButton:setPosition(cc.p(bg:getPositionX()+130,_cannelButton:getPositionY()))
    _sureButton:registerScriptTapHandler(function()
        -- self:close()
        -- if RankingLayer.instance.rankData == nil then RankingLayer.instance.rankData = {} end
        -- local _size = #RankingLayer.instance.rankData + 1
        -- if RankingLayer.instance.rankData[_size] == nil then
        --     RankingLayer.instance.rankData[_size] = {}
        -- end
        -- RankingLayer.instance.rankData[_size]["rank"] =  _size+1
        -- RankingLayer.instance.rankData[_size]["nickname"] = textField:getStringValue()
        -- RankingLayer.instance.rankData[_size]["amount"] = 1000+ _size+1
        -- RankingLayer.instance:reload()

        if textField:getStringValue() == nil and textField:getStringValue() == "" then
             ToastUtil:toastString("兑换码不能为空")
            return 0
        end
        --local str = textField:getStringValue()
        -- if string.find(str,"%s") ~= nil or  string.find(str,"+") ~= nil  or string.find(str,"/") ~= nil  or
        --       string.find(str,"?") ~= nil  or string.find(str,"%") ~= nil or  string.find(str,"#")~= nil  or 
        --       string.find(str,"&") ~= nil or string.find(str,"=") ~= nil  then
        --        ToastUtil:toastString("含有非法字符")
        --     return
        -- end
        --DataManager:getInstance():setRoleData(roleNickname,textField:getStringValue(),nil)

        -- local _value =  RankingLayer.instance:getValue(RankingLayer.instance.ranktype)
        -- -- if _value > 0 then
        -- RankingLayer.instance:httpConnection(RankingLayer.instance.ranktype,_value,textField:getStringValue())

        --self:httpConnection(textField:getStringValue())
        --end

        local codeKey = textField:getStringValue()
        self:requestNetwork(codeKey)
    end)

    local menuIcon = cc.Menu:create(_cannelButton,_sureButton)
    menuIcon:setPosition(0.0, 0.0)
    self:addChild(menuIcon)

    local okButtonLabel = cc.LabelTTF:create("确 定", BoldFont, 32.0)
    --okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    okButtonLabel:setColor(cc.c3b(255,255,255))
    okButtonLabel:setPosition(_sureButton:getPosition())
    self:addChild(okButtonLabel)

    local cancelButtonLabel = cc.LabelTTF:create("取 消", BoldFont, 32.0)
    -- cancelButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    cancelButtonLabel:setColor(cc.c3b(255,255,255))
    cancelButtonLabel:setPosition(_cannelButton:getPosition())
    self:addChild(cancelButtonLabel)

    return true
end
function replaceStr(str , strFind ,strTarget)
    local sub_str_tab = "";
   -- print("start======")
    while (true) do
        local pos = string.find(str, strFind)
        if (not pos) then
            sub_str_tab = sub_str_tab..str
           -- print("sub_str_tab ==1=",sub_str_tab)
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1)
        sub_str_tab = sub_str_tab..sub_str..strTarget
        str = string.sub(str, pos + 1, #str)
        --print("sub_str_tab ==2=",sub_str_tab)
    end
    return sub_str_tab
end

function CDKView:httpConnection(cdk)
    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        if xhr.response == "" then
        else
            local _data = xhr.response
            local data =  json.decode(_data)

            if (data ~= nil) then
                local dropId = tostring(data["dropId"])
                local status = data["status"]
                local errorMsg = data["errorMsg"]

                if (status ~= nil) then
                    ToastUtil:toastString(errorMsg)
                else
                    -- 处理数据数据
                    -- ToastUtil:toastString("处理数据数据")
                    -- dropId = "1"
                    local giftCSV = DataManager:getInstance():getCSVByID(csvOfGift)
                    local goods = giftCSV[dropId]
                    
                    if (goods ~= nil) then
                        local items = goods[dataKeyItems]
                        for i=1,#items do
                            local item = items[i]
                            DataManager:getInstance():cdkExchangeGoods(item[1], item[2], item[3])
                        end
                    end 
                    self:close()
                end
            end
        end
    end

    local httpType = tmp.POST
    local url = ""--""http://113.31.128.35:11200/pirate/g/a?"
    local dataPost = {}

    dataPost.type = "local"
    local _table1 = {}
    _table1["cmdid"] = 1002
    _table1["usrId"] = getonlyID()
    local _str1 = "header="..json.encode(_table1).."&"

    local _table2 = {}
    _table2["cdk"] = cdk

    local _str2 = "body="..json.encode(_table2)

    local _sendMessage = url.._str1.._str2

    tmp:send(httpType, _sendMessage, dataPost, callback)
end

function CDKView:requestNetwork(codeKey)
    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        if xhr.response == "" then
            ToastUtil:downString("网络连接失败")
        else
            local isSucc = decodeExKey(codeKey)
            if isSucc then
                ToastUtil:toastString("兑换成功")
                self:close()
            else
                ToastUtil:toastString("兑换码错误")
            end
        end
    end

    local type = tmp.POST
    local url = "http://baidu.com";
    local dataPost = {}
    dataPost.type = "local"
    tmp:send(type, url, dataPost, callback)
end