require "LuaClass/Header"
require "LuaClass/DialogTheme"
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
-- No service is configured in this recovered build. Do not send to a guessed host.
RankingLayer.serviceURL = ""
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
    if self._disposed then return end
    self._disposed = true
    if self.nicknameView and not self.nicknameView._closed then self.nicknameView:close() end
    self._requestSerial = (self._requestSerial or 0) + 1
    if RankingLayer.instance == self then RankingLayer.instance = nil end
    self:superDestory()
end

function RankingLayer:changeRankType()
    if self._disposed or self._requestPending then return end
    self.ranktype = self.ranktype == 1 and 2 or 1
    self.rankData = {}
    self:reload()
    self.ranktypeLabel:setString(self.ranktype == 1 and "永恒竞技场" or "探索榜")
    if self.serviceWarm then self:refreshCoherentRankType() end
    self:httpConnection(self.ranktype, self:getValue(self.ranktype), nil)
end

function RankingLayer:init()
    if rawget(_G,'WARM_PIRATE_V1')~=false then return self:initCoherentRanking() end
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    -- 设置title文字
    self.titleLabel:setString("排行榜")

    -- 隐藏上边的按钮
    self.storeMenu:setVisible(false)

    self.rankData = nil
    self.rankData = {}
    self.ranktype = 1
    self._disposed = false
    self._requestPending = false
    
    -- 添加rankType按钮
    local rankTypeNormal = DialogTheme.menuItem("Images/btn/ann06_a.png", "Images/btn/ann06_b.png", "secondary")
    local rankTypeSelected = DialogTheme.menuItem("Images/btn/ann07_a.png", "Images/btn/ann07_b.png", "secondary")
    for _, pair in ipairs({{rankTypeNormal, "竞技榜"}, {rankTypeSelected, "探索榜"}}) do
        local label = DialogTheme.label(pair[2], 28)
        label:setPosition(cc.p(pair[1]:getContentSize().width*.5, pair[1]:getContentSize().height*.5))
        pair[1]:addChild(label)
    end
    local rankType_btn = cc.MenuItemToggle:create(rankTypeSelected,rankTypeNormal)
    rankType_btn:registerScriptTapHandler(function()
        -- self:close()
        self:changeRankType()
    end)
    rankType_btn:setPosition(0.5*visibleSize.width, self.originPos.y + rankType_btn:getContentSize().height * 0.5 + 10)
    self.button = cc.Menu:create(rankType_btn)
    self.button:setPosition(cc.p(0, 0))
    self:addChild(self.button)

    -- 放置名次文字
    local ranknumLabel = cc.LabelTTF:create("名次", MasterTheme.headingFont(false), 36.0)
    ranknumLabel:setColor(cc.c3b(219, 200, 158))
    -- ranknumLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    ranknumLabel:setPosition(cc.p(0.15*visibleSize.width, self.originPos.y + self.areaHeight - ranknumLabel:getContentSize().height * 0.5 - 10 ))
    self:addChild(ranknumLabel)

    -- 放置昵称文字
    local nameLabel = cc.LabelTTF:create("昵称", MasterTheme.headingFont(false), 36.0)
    nameLabel:setColor(cc.c3b(219, 200, 158))
    -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    nameLabel:setPosition(cc.p(0.4*visibleSize.width, ranknumLabel:getPositionY()))
    self:addChild(nameLabel)


    -- 放置排名类型文字
    self.ranktypeLabel = cc.LabelTTF:create("永恒竞技场", MasterTheme.headingFont(false), 36.0)
    self.ranktypeLabel:setColor(cc.c3b(219, 200, 158))
    -- RankingLayer.ranktypeLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.ranktypeLabel:setPosition(cc.p(0.8*visibleSize.width, ranknumLabel:getPositionY()))
    DialogTheme.fit(self.ranktypeLabel, visibleSize.width*.34)
    self:addChild(self.ranktypeLabel)

    DialogTheme.applyBase(self)

    self.statusLabel = DialogTheme.label("", 27)
    self.statusLabel:setPosition(cc.p(visibleSize.width * .5, self.centerPos.y))
    self:addChild(self.statusLabel, 2)

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
        local row = DialogTheme.card(self.areaWidth, cellSize.height-2, idx%2 == 0 and "ink" or "card")
        row:setPosition(cc.p(self.areaWidth*.5, cellSize.height*.5));cell:addChild(row)
        local fontColor = MasterTheme.colors.white
        if _isMySelf then fontColor = MasterTheme.colors.sea end

        local ranknumLabel = cc.LabelTTF:create(_rang, MasterTheme.headingFont(false), _labelh)
        ranknumLabel:setPosition(cc.p(self.areaWidth/2-222,cellSize.height/2))
        ranknumLabel:setColor(fontColor)
        cell:addChild(ranknumLabel)

        local nameLabel = cc.LabelTTF:create(_name, MasterTheme.headingFont(false), _labelh)
        nameLabel:setPosition(cc.p(self.areaWidth/2-65,ranknumLabel:getPositionY()))
        nameLabel:setColor(fontColor)
        DialogTheme.fit(nameLabel, 185)
        cell:addChild(nameLabel)

        local _ranktypeLabel = cc.LabelTTF:create(tostring(_value), MasterTheme.headingFont(false), _labelh)
        _ranktypeLabel:setPosition(cc.p(self.areaWidth/2+195,ranknumLabel:getPositionY()))
        _ranktypeLabel:setColor(fontColor)
        DialogTheme.fit(_ranktypeLabel, 155)
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
    if self.serviceWarm then return self:reloadCoherentRanking() end
    if self ~= nil and self.tableviewT ~= nil then
        self.tableviewT:reloadData()
    end
end
function RankingLayer:setRequestState(pending, message)
    self._requestPending = pending
    if self.button then self.button:setEnabled(not pending) end
    if self.rankSwitches then for _,b in ipairs(self.rankSwitches)do b.item:setEnabled(not pending)end end
    if self.nicknameButton then self.nicknameButton.item:setEnabled(not pending)end
    if self.statusLabel then
        self.statusLabel:setString(message or "")
        self.statusLabel:setVisible(message ~= nil and message ~= "")
    end
end

function RankingLayer:httpConnection(Type, Amount, UserName, completion)
    if self._disposed or self._requestPending then
        if completion then completion(false) end
        return false
    end
    local url = self.serviceURL
    if type(url) ~= "string" or not url:match("^https?://") then
        self:setRequestState(false, "排行榜服务暂未配置")
        ToastUtil:toastString("排行榜服务暂未配置")
        if completion then completion(false) end
        return false
    end

    self._requestSerial = (self._requestSerial or 0) + 1
    local serial = self._requestSerial
    self:setRequestState(true, "正在加载排行榜…")
    local completed = false
    local function finish(success, message)
        if completed or self._disposed or self._requestSerial ~= serial then return false end
        completed = true
        self:setRequestState(false, message)
        if message and message ~= "" and not success then ToastUtil:toastString(message) end
        if completion then completion(success) end
        return true
    end
    local function callback(xhr)
        if completed or self._disposed or self._requestSerial ~= serial then return end
        local status = xhr and tonumber(xhr.status)
        if not xhr or (status and (status < 200 or status >= 300)) or
            type(xhr.response) ~= "string" or xhr.response:match("^%s*$") then
            finish(false, "排行榜暂不可用，请稍后重试")
            return
        end
        local ok, data, shape = pcall(HttpSingleton.decodeResponse, HttpSingleton, xhr.response)
        if not ok or type(data) ~= "table" or shape.kind ~= "object" then
            finish(false, "排行榜数据异常，请稍后重试")
            return
        end
        -- An explicit server error always wins, even if a list is also present.
        if data.status ~= nil then
            local message = data.status == 1002 and "昵称非法，请重新输入" or
                (data.status == 1001 and "请先登记昵称" or "排行榜暂不可用，请稍后重试")
            if finish(false, message) and not completion and (data.status == 1001 or data.status == 1002) then
                local view = InputNameView:create(self)
                if view then view:show() end
            end
            return
        end
        local function finiteNumber(value)
            if type(value) ~= "number" and type(value) ~= "string" then return nil end
            local number = tonumber(value)
            if number and number == number and number ~= math.huge and number ~= -math.huge then return number end
        end
        local function validNickname(value)
            return type(value) == "string" and value:gsub("%s", ""):gsub("　", "") ~= ""
        end
        if data.mine ~= nil and (type(data.mine) ~= "table" or shape.fields.mine.kind ~= "object" or
            (data.mine.nickname ~= nil and not validNickname(data.mine.nickname))) then
            finish(false, "排行榜数据异常，请稍后重试")
            return
        end
        if type(data.top100) == "table" and shape.fields.top100 and shape.fields.top100.kind == "array" then
            for key in pairs(data.top100) do
                if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or key > #data.top100 then
                    finish(false, "排行榜数据异常，请稍后重试")
                    return
                end
            end
            local rows = {}
            for _, entry in ipairs(data.top100) do
                local rank = type(entry) == "table" and finiteNumber(entry.rank)
                if not rank or rank < 1 or rank % 1 ~= 0 or
                    not validNickname(entry.nickname) or not finiteNumber(entry.amount) then
                    finish(false, "排行榜数据异常，请稍后重试")
                    return
                end
                rows[#rows + 1] = {rank=entry.rank, nickname=entry.nickname, amount=entry.amount}
            end
            self.rankData = rows
            if type(data.mine) == "table" and type(data.mine.nickname) == "string" then
                DataManager:getInstance():setRoleData(roleNickname, data.mine.nickname, nil)
            end
            DataManager:getInstance():setAchievementInfo(achievement_Ranking, 1)
            self:reload()
            finish(true, #rows == 0 and "暂无排名数据" or "")
        else
            finish(false, "暂无排名数据")
        end
    end
    
    local ok = pcall(function()
        local tmp = HttpSingleton:getInstance()
        local nickname = UserName or DataManager:getInstance():getRoleData(roleNickname)
        if type(nickname) ~= "string" then nickname = nil end
        if nickname then
            for i=1,#self.findStr do
                nickname = replaceStr(nickname, self.findStr[i], self.replaceStr[i])
            end
        end
        local header = {cmdid=1001, usrId=getonlyID()}
        local body = {value=Amount, type=Type, name=nickname}
        local request = url.."header="..json.encode(header).."&body="..json.encode(body)
        tmp:send(tmp.POST, request, {type="local"}, callback)
    end)
    if not ok then
        finish(false, "排行榜暂不可用，请稍后重试")
        return false
    end
    return true
end
function RankingLayer:getValue( Type )
    --print("========",Type)
    if Type == 1 then
        local _value = DataManager:getInstance():getRoleData(roleArenaMaxRecord)
        --print("_value",_value)
        if tonumber(_value) and tonumber(_value) > 0 then
            return _value
        end
    elseif Type == 2 then
        local _value = DataManager:getInstance():getRoleData(roleExtents)
        --print("_value",_value)
        if tonumber(_value) and tonumber(_value) > 0 then
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
function InputNameView:create(ranking)
    local view = InputNameView.new()
    view.ranking = ranking or RankingLayer.instance
    if view and view:init() then
        if view.ranking then view.ranking.nicknameView=view end
        return view
    end
    return nil
end
function InputNameView:init()
    if rawget(_G,'WARM_PIRATE_V1')~=false then
        self:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then self._closed=true end end)
        return require('LuaClass/ServiceSupportPresentation').entry(self,{title='登记昵称',subtitle='排行榜 · 船长名册',art='medal',hint='在排行榜上留下您的名字',maxLength=8,placeholder='点击输入昵称（最多八个字）',status=self.ranking and type(self.ranking.serviceURL)=='string'and self.ranking.serviceURL:match('^https?://')and'提交成功后保存昵称'or'排行榜服务暂未配置',callback=function()self:submitName()end})
    end
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
    local title  = cc.LabelTTF:create("昵  称",MasterTheme.headingFont(false),36)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    DialogTheme.fit(title, bg:getContentSize().width - 130)
    self:addChild(title)

    local _tip1 = cc.LabelTTF:create("将您的大名登记在排行榜上！",MasterTheme.headingFont(false),36)
    _tip1:setPosition(cc.p(bg:getPositionX()-bg:getContentSize().width/2+22,title:getPositionY()-78))
    _tip1:setAnchorPoint(cc.p(0,0.5))
    _tip1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip1)

    local _tip2 = cc.LabelTTF:create("最长不超过八个字！",MasterTheme.headingFont(false),28)
    _tip2:setPosition(cc.p(_tip1:getPositionX(),_tip1:getPositionY()-40))
    _tip2:setAnchorPoint(cc.p(0,0.5))
    _tip2:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(_tip2)
    local _kuang = DialogTheme.cardFromLegacy("Images/UI/kuang_10.png", "paper")
    _kuang:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()-25))
    self:addChild(_kuang)

    local textField = ccui.TextField:create()
    textField:setMaxLengthEnabled(true)
    textField:setMaxLength(8)
    textField:setTouchEnabled(true)
    textField:setFontName(MasterTheme.headingFont(false))
    textField:setTouchSize(_kuang:getContentSize());
    textField:setFontSize(30)
    textField:setColor(MasterTheme.colors.ink)
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
        self:submitName()
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
function InputNameView:close()
    if self._closed then return end
    self._closed = true
    if self.ranking and self.ranking.nicknameView==self then self.ranking.nicknameView=nil end
    DialogueView.close(self)
end

function InputNameView:submitName()
    if self._closed or self._submitting then return false end
    local nickname = self.textField:getStringValue()
    if type(nickname) ~= "string" or nickname:gsub("%s", ""):gsub("　", "") == "" then
        ToastUtil:toastString("昵称不能为空")
        return false
    end
    local ranking = self.ranking
    if not ranking or ranking._disposed then
        ToastUtil:toastString("排行榜暂不可用，请重新打开")
        return false
    end
    self._submitting = true
    if self.serviceStatus then self.serviceStatus:setString("正在提交昵称…") end
    self.submitButton:setEnabled(false)
    return ranking:httpConnection(ranking.ranktype, ranking:getValue(ranking.ranktype), nickname, function(success)
        if self._closed then return end
        self._submitting = false
        if self.serviceStatus and not success then self.serviceStatus:setString(ranking.statusLabel and ranking.statusLabel:getString()or"排行榜暂不可用，请稍后重试")end
        self.submitButton:setEnabled(true)
        if success then self:close() end
    end)
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



-- Warm-only composition. Network response validation and persistence above are
-- shared unchanged with the opt-out route.
function RankingLayer:initCoherentRanking()
    local S=require 'LuaClass/ServiceSupportPresentation';local W=require 'LuaClass/WarmTheme'
    self.rankData={};self.ranktype=1;self._disposed=false;self._requestPending=false
    local shell=S.mount(self,'排行榜','与其他船长一同留下航海记录');local root=shell.canvas
    S.art(root,'medal',372,590,125)
    self.ranktypeLabel=S.label(root,'永恒竞技场',28,32,627,250)
    self.rankValueLabel=S.label(root,'',20,32,585,245,W.colors.muted)
    self.rankSwitches={}
    for i,title in ipairs({'竞技榜','探索榜'})do
        local button=W.button(title,120,44,function()if self.ranktype~=i then self:changeRankType()end end,{size=19})
        button:setPosition(cc.p(92+(i-1)*132,518));root:addChild(button);self.rankSwitches[i]=button
    end
    S.label(root,'名次',18,40,464,54,W.colors.muted);S.label(root,'船长昵称',18,116,464,204,W.colors.muted)
    S.label(root,'成绩',18,406,464,78,W.colors.muted,.5)
    local line=cc.Node:create();line:setPosition(cc.p(32,443));root:addChild(line);S.rule(line,0)
    self.rankScroll,self.rankContainer=S.scroll(root,32,116,416,321)
    self.statusLabel=S.label(root,'',20,240,305,392,W.colors.muted,.5)
    self.statusLabel:setDimensions(cc.size(392,86));self.statusLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.nicknameButton=W.button('登记昵称',128,48,function()
        if self._disposed or self._requestPending or self.coherentPageLeaving then return end
        if self.nicknameView and not self.nicknameView._closed then return end
        self.nicknameView=InputNameView:create(self);if self.nicknameView then self.nicknameView:show()end
    end,{size=18});self.nicknameButton:setPosition(cc.p(384,48));root:addChild(self.nicknameButton)
    RankingLayer.instance=self;self:refreshCoherentRankType();self:httpConnection(self.ranktype,self:getValue(self.ranktype),nil)
    return true
end
function RankingLayer:refreshCoherentRankType()
    local W=require 'LuaClass/WarmTheme'
    self.rankValueLabel:setString('我的成绩  '..tostring(self:getValue(self.ranktype)));W.fit(self.rankValueLabel,245)
    for i,b in ipairs(self.rankSwitches)do b.label:setColor(i==self.ranktype and W.colors.sea or W.colors.muted)end
end
function RankingLayer:reloadCoherentRanking()
    if self._disposed or not self.rankContainer then return end
    local S=require 'LuaClass/ServiceSupportPresentation';local W=require 'LuaClass/WarmTheme'
    self.rankContainer:removeAllChildren();local heights,names={},{};local height=0
    for i,entry in ipairs(self.rankData)do
        local name=W.label(entry.nickname,20,W.colors.ink,84,0);name:setDimensions(cc.size(230,0));name:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        names[i]=name;heights[i]=math.max(62,name:getContentSize().height+18);height=height+heights[i]
    end
    height=math.max(321,height);local top=height
    for i,entry in ipairs(self.rankData)do
        local rowH=heights[i];top=top-rowH;local row=cc.Node:create();row:setContentSize(cc.size(416,rowH));row:setPosition(cc.p(0,top));self.rankContainer:addChild(row)
        local mine=entry.nickname==DataManager:getInstance():getRoleData(roleNickname)
        local color=mine and W.colors.sea or W.colors.ink
        S.label(row,entry.rank,20,28,rowH/2,56,color,.5)
        local name=names[i];name:setColor(color);name:setPositionY(rowH/2);row:addChild(name)
        S.label(row,entry.amount,20,374,rowH/2,78,color,.5);S.rule(row,1)
    end
    self.rankContainer:setContentSize(cc.size(416,height));self.rankScroll:setContentSize(cc.size(416,height));self.rankScroll:setContentOffset(cc.p(0,321-height))
end
