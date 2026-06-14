require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/HttpSingleton"
require "LuaClass/DataManager"


RankingLayer = class("RankingLayer", function ()
    return BaseView:create()
end)

RankingLayer.__index = RankingLayer
RankingLayer.ranktype = 1
RankingLayer.ranktypeLabel = nil
RankingLayer.rankData = nil
RankingLayer.instance = nil
RankingLayer.tableviewT = nil
RankingLayer.button = nil
RankingLayer.findStr = {"%s","+","/","?","#","&","="}
RankingLayer.replaceStr = {"%20","%2B","%2F","%3F","%23","%26","%3D"}
function RankingLayer:create()
    local view = RankingLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function RankingLayer:destory()
    -- 调用父类的析构
    self:superDestory()
end

function RankingLayer:changeRankType()
    if RankingLayer.instance.ranktype == 1 then
        RankingLayer.instance.ranktype = 2
        RankingLayer.instance.rankData = nil
        RankingLayer.instance.rankData = {}
        RankingLayer.instance:reload()
        RankingLayer.instance.ranktypeLabel:setString("探索榜")
        local _value = RankingLayer.instance:getValue(2)
        --if _value > 0 then
        RankingLayer.instance.button:setEnabled(false)
        RankingLayer.instance:httpConnection(RankingLayer.instance.ranktype,_value,nil)
        --else
        --   ToastUtil:toastString("没有探索数值")
        --end
    else
        RankingLayer.instance.ranktype = 1
        RankingLayer.instance.rankData = nil
        RankingLayer.instance.rankData = {}
        RankingLayer.instance:reload()
        RankingLayer.instance.ranktypeLabel:setString("永恒竞技场")
        local _value = RankingLayer.instance:getValue(1)
        --if _value > 0 then
        RankingLayer.instance.button:setEnabled(false)
        RankingLayer.instance:httpConnection(RankingLayer.instance.ranktype,_value,nil)
        -- else
        --     ToastUtil:toastString("没有竞技场数值")
        -- end
    end
end

function RankingLayer:init()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    -- 设置title文字
    self.titleLabel:setString("排行榜")

    -- 隐藏上边的按钮
    self.storeMenu:setVisible(false)

    self.rankData = nil
    self.rankData = {}
    self.ranktype = 1
    
    -- 添加rankType按钮
    local rankTypeNormal = cc.MenuItemImage:create("Images/btn/ann06_a.png", "Images/btn/ann06_b.png")
    local rankTypeSelected = cc.MenuItemImage:create("Images/btn/ann07_a.png", "Images/btn/ann07_b.png")
    local rankType_btn = cc.MenuItemToggle:create(rankTypeSelected,rankTypeNormal)
    rankType_btn:registerScriptTapHandler(function()
        -- self:close()
        RankingLayer:changeRankType()
    end)
    rankType_btn:setPosition(0.5*visibleSize.width, self.originPos.y + rankType_btn:getContentSize().height * 0.5 + 10)
    self.button = cc.Menu:create(rankType_btn)
    self.button:setPosition(cc.p(0, 0))
    self:addChild(self.button)

    -- 放置名次文字
    local ranknumLabel = cc.LabelTTF:create("名次", BoldFont, 36.0)
    ranknumLabel:setColor(cc.c3b(219, 200, 158))
    -- ranknumLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    ranknumLabel:setPosition(cc.p(0.15*visibleSize.width, self.originPos.y + self.areaHeight - ranknumLabel:getContentSize().height * 0.5 - 10 ))
    self:addChild(ranknumLabel)

    -- 放置昵称文字
    local nameLabel = cc.LabelTTF:create("昵称", BoldFont, 36.0)
    nameLabel:setColor(cc.c3b(219, 200, 158))
    -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    nameLabel:setPosition(cc.p(0.4*visibleSize.width, ranknumLabel:getPositionY()))
    self:addChild(nameLabel)


    -- 放置排名类型文字
    self.ranktypeLabel = cc.LabelTTF:create("永恒竞技场", BoldFont, 36.0)
    self.ranktypeLabel:setColor(cc.c3b(219, 200, 158))
    -- RankingLayer.ranktypeLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.ranktypeLabel:setPosition(cc.p(0.8*visibleSize.width, ranknumLabel:getPositionY()))
    self:addChild(self.ranktypeLabel)

    RankingLayer.instance = self
    local _labelh = 32
    local cellSize = cc.size(visibleSize.width,45)
    local scrollViewSize = cc.size(visibleSize.width, self.areaHeight - ranknumLabel:getContentSize().height - rankType_btn:getContentSize().height - 60)
    self.tableviewT = cc.TableView:create(scrollViewSize)
    self.tableviewT:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableviewT:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableviewT:setPosition(cc.p(self.originPos.x, self.originPos.y + rankType_btn:getContentSize().height + 40))
    self.tableviewT:setDelegate()
    self.tableviewT:registerScriptHandler(function( view, idx)
        idx = idx + 1
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()
        local _rang = self.rankData[idx]["rank"]
        local _name = self.rankData[idx]["nickname"]
        local _value = self.rankData[idx]["amount"]
        local _isMySelf = false
        local _nickName = DataManager:getInstance():getRoleData(roleNickname)
        if _nickName ~= nil and _name == _nickName then
            _isMySelf = true
        end
        local fontColor = WriteColor
        if _isMySelf then fontColor = GreenColor end

        local ranknumLabel = cc.LabelTTF:create(_rang, BoldFont, _labelh)
        ranknumLabel:setPosition(cc.p(self.areaWidth/2-222,cellSize.height/2))
        ranknumLabel:setColor(fontColor)
        cell:addChild(ranknumLabel)

        local nameLabel = cc.LabelTTF:create(_name, BoldFont, _labelh)
        nameLabel:setPosition(cc.p(self.areaWidth/2-65,ranknumLabel:getPositionY()))
        nameLabel:setColor(fontColor)
        cell:addChild(nameLabel)

        local _ranktypeLabel = cc.LabelTTF:create(tostring(_value), BoldFont, _labelh)
        _ranktypeLabel:setPosition(cc.p(self.areaWidth/2+195,ranknumLabel:getPositionY()))
        _ranktypeLabel:setColor(fontColor)
        cell:addChild(_ranktypeLabel)

        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)
    self.tableviewT:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
    return cellSize.height,cellSize.width -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableviewT:registerScriptHandler(function(view)
        return #self.rankData
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self:addChild(self.tableviewT)
    self.tableviewT:reloadData()

    local _value = self:getValue(self.ranktype)
    --if _value ~= nil and tonumber(_value) > 0 then
    self:httpConnection(self.ranktype,_value,nil)
    --else
    --    ToastUtil:toastString("没有竞技场数值")
    --end
	return true
end
function RankingLayer:reload()
    if self ~= nil and self.tableviewT ~= nil then
        self.tableviewT:reloadData()
    end
end
function RankingLayer:httpConnection(Type,Amount,UserName)
    local tmp = HttpSingleton:getInstance()

    local function callback(xhr)
        if xhr.response == "" then
        else
            local event = cc.EventCustom:new("requestresources")
            event._usedata = xhr.response
            local _data = event._usedata
            local data =  json.decode(_data)

            if data == nil then
            ToastUtil:toastString("暂无数据")
            end

            if self.rankData == nil then self.rankData = {} end
            if data["mine"] ~= nil and data["mine"]["nickname"] ~= nil then
                DataManager:getInstance():setRoleData(roleNickname,data["mine"]["nickname"],nil)
            end
            if data["top100"] ~= nil then
                DataManager:getInstance():setAchievementInfo(achievement_Ranking, 1)
                for i=1,#data["top100"] do
                    local _size = #self.rankData + 1
                    if self.rankData[_size] == nil then
                    self.rankData[_size] = {}
                    end
                    self.rankData[_size]["rank"] =  data["top100"][i]["rank"]
                    self.rankData[_size]["nickname"] = data["top100"][i]["nickname"]
                    self.rankData[_size]["amount"] = data["top100"][i]["amount"]
                 end
                self:reload()
            elseif data["status"] ~= nil and data["status"] == 1001 then
                local _view = InputNameView:create()
                _view:show()
            elseif data["status"] ~= nil and data["status"] == 1002 then
                ToastUtil:toastString("昵称非法，请重新输入")
                local _view = InputNameView:create()
                _view:show()

            else
                ToastUtil:toastString("暂无数据")
            end

            self.button:setEnabled(true)
        end


    end

    local type = tmp.POST
    local url = ""--""113.31.128.35:11200/pirate/g/a?"
    local dataPost = {}
    local _nickName = nil
    if UserName ~= nil then
        _nickName = UserName
    else
       _nickName =  DataManager:getInstance():getRoleData(roleNickname)
    end
    
    if _nickName == nil then
        _nickName = "null"
    else
        for i=1,#self.findStr do
            _nickName = replaceStr(_nickName,tostring(self.findStr[i]),tostring(self.replaceStr[i]))
        end
    end
    print("_nickName===",_nickName)
    dataPost.type = "local"
    local _table1 = {}
    _table1["cmdid"] = 1001
    _table1["usrId"] = getonlyID()
    local _str1 = "header="..json.encode(_table1).."&"

    local _table2 = {}
    _table2["value"] = Amount
    _table2["type"] = Type
    if _nickName ~= "null" then
        _table2["name"] = tostring(_nickName)
    end
    local _str2 = "body="..json.encode(_table2)

    local _sendMessage = url.._str1.._str2

    print("_sendMessage",_sendMessage)
    tmp:send(type, _sendMessage, dataPost, callback)
end
function RankingLayer:getValue( Type )
    --print("========",Type)
    if Type == 1 then
        local _value = DataManager:getInstance():getRoleData(roleArenaMaxRecord)
        --print("_value",_value)
        if _value ~= nil and tonumber(_value) > 0 then
            return _value
        end
    elseif Type == 2 then
        local _value = DataManager:getInstance():getRoleData(roleExtents)
        --print("_value",_value)
        if _value ~= nil and tonumber(_value) > 0 then
            return _value
        end
    end
    return 0
end
--============================================================--------------------------------------
InputNameView = class("InputNameView", function ()
    return DialogueView:create()
end)
InputNameView.__index = InputNameView
function InputNameView:create()
    local view = InputNameView.new()
    if view and view:init() then
        return view
    end
    return nil
end
function InputNameView:init()
        local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)
    --title
    local title  = cc.LabelTTF:create("昵  称",BoldFont,36)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    title:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self:addChild(title)

    local _tip1 = cc.LabelTTF:create("将您的大名登记在排行榜上！",BoldFont,36)
    _tip1:setPosition(cc.p(bg:getPositionX()-bg:getContentSize().width/2+22,title:getPositionY()-78))
    _tip1:setAnchorPoint(cc.p(0,0.5))
    _tip1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip1)

    local _tip2 = cc.LabelTTF:create("最长不超过八个字！",BoldFont,28)
    _tip2:setPosition(cc.p(_tip1:getPositionX(),_tip1:getPositionY()-40))
    _tip2:setAnchorPoint(cc.p(0,0.5))
    _tip2:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip2)
    local _kuang = cc.Sprite:create("Images/UI/kuang_10.png")
    _kuang:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()-25))
    self:addChild(_kuang)

    local textField = ccui.TextField:create()
    textField:setMaxLengthEnabled(true)
    textField:setMaxLength(8)
    textField:setTouchEnabled(true)
    --textField:setFontName(font_TextName)
    textField:setTouchSize(_kuang:getContentSize());
    textField:setFontSize(34)
    textField:setPlaceHolder("点击此处输入您的昵称")
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
        self:close()
        print("input =========",textField:getStringValue())
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
             ToastUtil:toastString("昵称不能为空")
            return
        end
        --local str = textField:getStringValue()
        -- if string.find(str,"%s") ~= nil or  string.find(str,"+") ~= nil  or string.find(str,"/") ~= nil  or
        --       string.find(str,"?") ~= nil  or string.find(str,"%") ~= nil or  string.find(str,"#")~= nil  or 
        --       string.find(str,"&") ~= nil or string.find(str,"=") ~= nil  then
        --        ToastUtil:toastString("含有非法字符")
        --     return
        -- end
        --DataManager:getInstance():setRoleData(roleNickname,textField:getStringValue(),nil)

        local _value =  RankingLayer.instance:getValue(RankingLayer.instance.ranktype)
        -- if _value > 0 then
        RankingLayer.instance:httpConnection(RankingLayer.instance.ranktype,_value,textField:getStringValue())
        --end

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


