require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/ManagementTheme"
require "LuaClass/HarborGoals"
require "LuaClass/AlertView"
require "LuaClass/DataManager"
require "LuaClass/Lackmaterial"
require "AudioEngine"

BuildLayer = class("BuildLayer", function ()
    return BaseView:create()
end)

BuildLayer.__index = BuildLayer
BuildLayer.csvData = nil
BuildLayer.ResoucecsvData = nil
BuildLayer.dataIndex = nil

local focusedSerial = 0
local focusedEvents = {rolePack, roleMoney, roleBuilding, roleGuideStep}


function BuildLayer:create(focusBuildId)
    local view = BuildLayer.new()
    view.focusTargetId = focusBuildId
    if view and view:init() then
        return view
    end
    return nil
end

function BuildLayer:destory()
    self:disposeFocusedBuild()
    -- 去掉注册的通知
    DataManager:getInstance():unregisterEvent(roleMapInfo, "BuildLayer")
    -- 调用父类的析构
    self:superDestory()
end

function BuildLayer:viewWillDestory()
    -- 清理红点
    DataManager:getInstance():cleanNewUnlock(kUnlockBuild)
end

function BuildLayer:init()
    self:applyManagementTheme()
    -- Goal/recovery links are a single construction decision. Ordinary harbor
    -- construction keeps its complete original list and all utility controls.
    if self.focusTargetId and type(WarmTheme) == "table" and WarmTheme.enabled() then
        return self:initFocusedBuild()
    end
    DataManager:getInstance():registerEvent(roleMapInfo, "BuildLayer", function()
        -- body
        local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
        if (flag) then
            GuideController:getInstance():addRedPoint(self.topRightBtn)
        else
            GuideController:getInstance():removeRedPoint(self.topRightBtn)
        end
    end)

	local flag = DataManager:getInstance():checkDiamondStoreNewGoods()
	if (flag) then
		GuideController:getInstance():addRedPoint(self.topRightBtn)
	else
		GuideController:getInstance():removeRedPoint(self.topRightBtn)
	end

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- local a, b = DataManager:getInstance():unlockUnitWithType(kUnlockBuild, "2")
    -- 设置title文字
    self.titleLabel:setString("建 设")

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, nil, nil, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
        -- 每点击一次延迟三秒刷新tableView，如果再来，那么去掉之前的刷新
        self.titleLabel:stopAllActions()
        self.titleLabel:runAction(cc.Sequence:create(cc.DelayTime:create(1.6), cc.CallFunc:create(function()
            if self.tableview ~= nil then
                local oldlinenum = self:getDataNum()
                local oldp = self.tableview:getContentOffset()
                self.tableview:reloadData()
                local linenum = self:getDataNum()
                if linenum > self.showline then
                    self.tableview:setContentOffset(cc.p(oldp.x, oldp.y - (linenum - oldlinenum) * self.cellhight), false)
                end
            end
        end)))
    end, nil, true, zqAlchemyTime, false)

    self:initdata()
    -- self.roleBuildingData = DataManager:getInstance():getRoleData(roleBuilding)

    -- for k,v in pairs(self.roleBuildingData) do
    --     for kx,vx in pairs(v) do
    --         print(kx,vx)
    --     end
    -- end

    self.csvData = DataManager:getInstance():getCSVByID(csvOfBuild)
    if self.csvData  == nil then
        return false
    end

    self.ResoucecsvData = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    if self.ResoucecsvData  == nil then
        return false
    end

    self:setBackgroundIcon("Images/Background/shic.png")

    -- 如果是商城，隐藏自己的去商城按钮
    -- self.storeMenu:setVisible(false)


    self.cellhight = 112
    self.showline = self.areaHeight/112
    local cellSize = cc.size(visibleSize.width,self.cellhight)
    -- 添加scrollView
    self.tableview = cc.TableView:create(cc.size(visibleSize.width, self.areaHeight))
    cclog("cc.TableView:create(cc.size(visibleSize.width, self.areaHeight))"..visibleSize.width.."  "..self.areaHeight)
    self.tableview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview:setPosition(cc.p(0,self.originPos.y))
    self.tableview.bIsScrollView = true
    self.tableview:setDelegate()

    self.tableview:registerScriptHandler(function(view, cell)
        cclog("scrollView cell "..tostring(cell:getTag()).." touched")




    end, cc.TABLECELL_TOUCHED)

    self.tableview:registerScriptHandler(function( view, idx)
        idx = idx + 1
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()

        local _backGround = ManagementTheme.panel(visibleSize.width-24,100,'paper')

        _backGround:setPosition(cc.p(cellSize.width/2,cellSize.height/2))
        cell:addChild(_backGround)

        --start
        local _fontSize = 26

        local DataTable =  self.roleBuildingData[idx]
        -- print("DataTable:", tableToJson(DataTable))
        local _csvID = DataTable[dataKeyID]
        local _resIcon_str = self.csvData[tostring(_csvID)]["iconName"]


        cclog("_resIcon_str",_resIcon_str)



        -- local _HeadSprite = nil
        -- if _resIcon_str ~= "" and _resIcon_str ~= nil then
        --     _HeadSprite = cc.MenuItemImage:create("Images/Icon/".._resIcon_str, "Images/Icon/".._resIcon_str)
        -- else
        --     _HeadSprite = cc.MenuItemImage:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png")
        -- end
        -- _HeadSprite:registerScriptTapHandler(function()
        --     self:showInfoBox("物品名字："..self.csvData[tostring(_csvID)]["name"].."\n描述："..self.csvData[tostring(_csvID)]["info"].."\n需要材料："..self.csvData[tostring(_csvID)]["comment"])
        -- end)

        -- _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+15,cellSize.height/2))
        -- local _HeadSpriteButton = cc.Menu:create(_HeadSprite)
        -- _HeadSpriteButton:setPosition(0.0, 0.0)
        -- cell:addChild(_HeadSpriteButton)

        
        function showinfo()
            self:showInfoBox("物品名字："..self.csvData[tostring(_csvID)]["name"].."\n描述："..self.csvData[tostring(_csvID)]["info"].."\n需要材料："..self.csvData[tostring(_csvID)]["comment"])
        end
        local _HeadSprite = nil
        if _resIcon_str ~= "" and _resIcon_str ~= nil then
            _HeadSprite = SDButton:create("Images/Icon/".._resIcon_str, "Images/Icon/".._resIcon_str,showinfo)
        else
            _HeadSprite = SDButton:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png",showinfo)
        end
        _HeadSprite:addClickArea(cc.rect(-20, -10, 380, 20))
        _HeadSprite:setSwallowTouches(fasle)
        _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+15,cellSize.height/2))
        cell:addChild(_HeadSprite)




        -- local _HeadSprite = nil
        -- if _resIcon_str ~= "" and _resIcon_str ~= nil then
        --     _HeadSprite = cc.Sprite:create("Images/Icon/".._resIcon_str)
        -- else
        --     _HeadSprite = cc.Sprite:create("Images/Icon/d_1.png")
        -- end
        -- _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+15,cellSize.height/2))
        -- cell:addChild(_HeadSprite)

        --name
        local _xLeft = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width/2 + 20
        local _centerY = _HeadSprite:getPositionY() + _HeadSprite:getContentSize().height/2

        local _name_str = self.csvData[tostring(_csvID)]["name"]
        local _name = cc.LabelTTF:create(_name_str,ManagementTheme.bodyFont(),_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY + 5))
        _name:setFontSize(28)
        ManagementTheme.styleLabel(_name,'body',300)
        -- _name:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _name:setAnchorPoint(cc.p(0,1))
        cell:addChild(_name)

         

        -- 建筑数量
        local buildnum = DataTable[dataKeyNum]
        if tonumber(buildnum) == 0 then

        local resok = nil
            --price
        local s_ishave,s_templacktable = self:getResouceshowtable(_csvID)
        local neednum = #s_templacktable
        local s_p = _xLeft
        local basenode = cc.Node:create()
        basenode:setPosition(cc.p(0,0))
        cell:addChild(basenode)
        for i = 1,neednum do
            local _price = cc.LabelTTF:create(s_templacktable[i]["mtname"],ManagementTheme.bodyFont(),_fontSize - 2);
            _price:setPosition(cc.p(s_p,_centerY - _HeadSprite:getContentSize().height - 5))
            -- _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _price:setColor(s_templacktable[i]["mtcolor"])
            _price:setAnchorPoint(cc.p(0,0))
            basenode:addChild(_price)
            s_p = s_p + _price:getContentSize().width
        end
        
            local _menuButton = ManagementTheme.menuItem(128,59,'coral')

            _menuButton:registerScriptTapHandler(function()
                if DataManager:getInstance():getSound_off() == 0 then
                    AudioEngine.playEffect(EFFECT_Button, false)
                end
                local ishave,templacktable = self:cheackResoucesOK(_csvID)
                if  ishave == 1  then
                    self:useResouces(_csvID)
                    -- 解锁东西
                    local oldlinenum = self:getDataNum()
                    DataManager:getInstance():createSuccessCheck(kUnlockBuild, _csvID)

                    ToastUtil:downString("建造成功")
                    self:initdata()
                    local oldp = self.tableview:getContentOffset()
                
                    self.tableview:reloadData()
                    local linenum = self:getDataNum()
                    if linenum > self.showline then
                        self.tableview:setContentOffset(cc.p(oldp.x,oldp.y - (linenum - oldlinenum) * self.cellhight),false);
                    end
                else
                    -- 材料id 
                    -- 材料名字
                    -- 材料价格
                    -- 缺少数量
                    -- local lacktable = {{mtID = "1007",mtname = "b",mtprice = "100",mtnum = "20"}, {mtID = "1007",mtname = "b",mtprice = "100",mtnum = "20"}, {mtID = "1007",mtname = "b",mtprice = "100",mtnum = "20"}}

                    Lackmaterial:create(templacktable,function ()
                        -- if basenode~=nil then
                        --     basenode:removeFromParent()
                        -- end
                    --     local t_ishave,s_templacktable = self:getResouceshowtable(_csvID)
                    --     local neednum = #s_templacktable
                    --     local s_p = _xLeft
                    --     basenode = cc.Node:create()
                    --     basenode:setPosition(cc.p(0,0))
                    --     cell:addChild(basenode)
                    --     for i = 1,neednum do
                    --         local _price = cc.LabelTTF:create(s_templacktable[i]["mtname"],BoldFont,_fontSize - 2);
                    --         _price:setPosition(cc.p(s_p,_centerY - _HeadSprite:getContentSize().height - 5))
                    --         _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
                    --         _price:setColor(s_templacktable[i]["mtcolor"])
                    --         _price:setAnchorPoint(cc.p(0,0))
                    --         basenode:addChild(_price)
                    --         s_p = s_p + _price:getContentSize().width
                    --     end
                    --     if t_ishave == 1 then
                    --         resok:setVisible(true)
                    --     end
                    -- end
                        local oldp = self.tableview:getContentOffset()
                    
                        self.tableview:reloadData()
                        self.tableview:setContentOffset(cc.p(oldp.x,oldp.y),false)
                    end
                    ):show()

                    -- local _alert = AlertView:create(2,0, "建造失败",test,nil)

                    -- local showLabel1 = cc.LabelTTF:create("材料不足!", BoldFont, 36.0)
                    -- showLabel1:setColor(cc.c3b(255, 255, 255))
                    -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
                    -- showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
                    -- _alert:addChild(showLabel1)
                end
                


            end)
            _menuButton:setPosition(cc.p(cellSize.width-_menuButton:getContentSize().width * 0.5 - 30,cellSize.height/2))
            -- 没点过的都加上红点 by 杨杰到此一游
            if DataTable["S"] ~= nil then
                local btnLight = cc.Sprite:create("Images/btn/BtnLight.png")
                btnLight:setPosition(_menuButton:getPosition())
                btnLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(0.6), cc.EaseExponentialIn:create(cc.FadeIn:create(1.0)))))
                cell:addChild(btnLight)
                -- GuideController:getInstance():addRedPoint(_menuButton)
            end

            local menu = cc.Menu:create(_menuButton)
            menu:setPosition(0.0, 0.0)
            cell:addChild(menu)

            resok = cc.Sprite:create("Images/UI/resok.png")
            resok:setPosition(cc.p(cellSize.width-_menuButton:getContentSize().width - 60,cellSize.height/2))
            cell:addChild(resok)
            if s_ishave ~= 1 then
                resok:setVisible(false)
            end

            local _zz = cc.LabelTTF:create("建 设", ManagementTheme.bodyFont(), 26.0)
            ManagementTheme.styleLabel(_zz,'action')
            _zz:setPosition(_menuButton:getPosition())
            -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            cell:addChild(_zz)
        else
            local _zz = cc.LabelTTF:create("已建设", ManagementTheme.bodyFont(), 26.0)
            ManagementTheme.styleLabel(_zz,'muted')
            -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            _zz:setPosition(cc.p(cellSize.width-_zz:getContentSize().width * 0.5 - 30,cellSize.height/2))
            cell:addChild(_zz)

        end
        return cell

    end, cc.TABLECELL_SIZE_AT_INDEX)

    self.tableview:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        return cellSize.height,cellSize.width -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)

    self.tableview:registerScriptHandler(function(view)
        return self:getDataNum()
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)

    self:addChild(self.tableview)
    self.tableview:reloadData()
    self:focusEntry(self.focusTargetId)

    return true
end


function BuildLayer:initdata()
    self.roleBuildingData = DataManager:getInstance():getRoleData(roleBuilding)
end


-- 根据材料是否充足来得到显示table 红色缺乏 白色充足
-- {{mtname = "b",mtcolor = "100"}..}

function BuildLayer:getResouceshowtable(csvID)
    local isok = 1
    local Lacktable = {}
    local needtable = self.csvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        print("keystring",keystring)
        print("keynum",keynum)

        local havenum = DataManager:getInstance():getPackNumWithId(tostring(keystring))
        print("havenum",havenum)
        
            local lacktablecell = {}
            lacktablecell.mtname = self.ResoucecsvData[tostring(keystring)]["name"].."x"..keynum.." "
            if tonumber(havenum) < tonumber(keynum) then
                lacktablecell.mtcolor = ManagementTheme.colors.danger
            else
                lacktablecell.mtcolor = ManagementTheme.colors.ink
            end
            table.insert(Lacktable,1,lacktablecell)
            if tonumber(havenum) < tonumber(keynum) then
                isok = 0
            end
        
    end
    return isok,Lacktable
end


-- 检查资源是否充足
-- {{mtID = "1007",mtname = "b",mtprice = "100",mtnum = "20",mtStar = “2”,mtonlyProduce = "1"}..}
function BuildLayer:cheackResoucesOK(csvID)
    local isok = 1
    local Lacktable = {}
    local needtable = self.csvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        print("keystring",keystring)
        print("keynum",keynum)

        local havenum = DataManager:getInstance():getPackNumWithId(tostring(keystring))
        print("havenum",havenum)
        if tonumber(havenum) < tonumber(keynum) then
            local lacktablecell = {}
            lacktablecell.mtId = tostring(keystring)
            lacktablecell.mtname = self.ResoucecsvData[tostring(keystring)]["name"]
            lacktablecell.mtprice = self.ResoucecsvData[tostring(keystring)]["price"]
            lacktablecell.mtnum = tostring(tonumber(keynum) - tonumber(havenum))

            lacktablecell.mtStar = self.ResoucecsvData[tostring(keystring)]["starNum"]
            lacktablecell.mtonlyProduce = self.ResoucecsvData[tostring(keystring)]["onlyProduce"]

            table.insert(Lacktable,1,lacktablecell)
            isok = 0
        end
    end
    return isok,Lacktable
end

-- 消耗资源
function BuildLayer:useResouces(csvID)
    local needtable = self.csvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        print("keystring",keystring)
        print("keynum",keynum)

        DataManager:getInstance():addPackItemWithId(tostring(keystring), -1 * tonumber(keynum))
    end
end

function BuildLayer:setDataKey()
    self.dataIndex = nil
    self.dataIndex = {}
    local  _num = 0
    for k,v in pairs(self.data) do
        if v~= nil and v["name"] ~= nil then
            _num = _num + 1
            self.dataIndex[_num] = k
        end   
    end
end

function BuildLayer:getDataNum()
    local  _num = 0
    -- for k,v in pairs(self.csvData) do
    --     if v~= nil and v["name"] ~= nil then
    --      _num = _num + 1
    --     end   
    -- end
    -- cclog("_num = ".._num)
    _num = #self.roleBuildingData
    return _num
end



-- Optional read-only navigation target; ordinary entry keeps its old scroll state.
function BuildLayer:focusEntry(id)
    if not id then return false end
    for index,row in ipairs(self.roleBuildingData or {}) do
        if tostring(row[dataKeyID])==tostring(id) then
            local offset=HarborGoals.focusOffset(#self.roleBuildingData,index,self.areaHeight,self.cellhight)
            self.tableview:setContentOffset(cc.p(0,offset),false)
            return true
        end
    end
    return false
end


-- Keep the complete live building list. Focusing is only a presentation lookup;
-- it never sorts, filters, replaces or saves the player's unlocked buildings.
function BuildLayer:focusedEntry()
    for _, entry in ipairs(self.roleBuildingData or {}) do
        if tostring(entry[dataKeyID]) == tostring(self.focusTargetId) then return entry end
    end
end

function BuildLayer:disposeFocusedBuild()
    if not self.focusedBuildPresentation or self.focusedBuildDisposed then return end
    self.focusedBuildDisposed = true
    local dm = DataManager:getInstance()
    for _, key in ipairs(focusedEvents) do
        dm:unregisterEvent(key, self.focusedEventKey)
        -- Legacy unregisterEvent leaves its short-key callback behind.
        local bucket = dm.__eventListener and dm.__eventListener[key]
        if bucket then bucket[self.focusedEventKey] = nil end
    end
end

function BuildLayer:initFocusedBuild()
    local dm = DataManager:getInstance()
    self.csvData = dm:getCSVByID(csvOfBuild)
    self.ResoucecsvData = dm:getCSVByID(csvOfResourceInfo)
    if not self.csvData or not self.ResoucecsvData then return false end
    self.focusedBuildPresentation = true
    self.approvedPage = true
    self.keepNavigation = false
    self.isHaveInfo = false
    self.focusedGeneration = 0
    self.mainBg:setVisible(false)
    self.titleBg:setVisible(false)
    self.storeMenu:setVisible(false)

    local W = WarmTheme
    local size = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    local scale = math.min(size.width / 480, size.height / 800)
    local paper = cc.LayerColor:create(cc.c4b(W.colors.paper.r, W.colors.paper.g, W.colors.paper.b, 255), size.width, size.height)
    paper:setPosition(origin);self:addChild(paper)
    local canvas = cc.Node:create()
    canvas:setContentSize(cc.size(480,800));canvas:setScale(scale)
    canvas:setPosition(cc.p((size.width-480*scale)/2, (size.height-800*scale)/2))
    paper:addChild(canvas);self.focusedCanvas = canvas
    focusedSerial = focusedSerial + 1
    self.focusedEventKey = "focusedBuild" .. focusedSerial
    for _, key in ipairs(focusedEvents) do
        dm:registerEvent(key, self.focusedEventKey, function()
            if not self.focusedBuildDisposed and not self.focusedBuildBusy then self:refreshFocusedBuild() end
        end)
    end
    self:registerScriptHandler(function(event)
        if event == "exit" or event == "cleanup" then self:disposeFocusedBuild() end
    end)
    self:refreshFocusedBuild()
    return true
end

function BuildLayer:leaveFocusedBuild()
    if self.focusedBuildDisposed or self.focusedBuildLeaving then return end
    self.focusedBuildLeaving = true
    local dispatch = zqDispatch
    if dispatch and dispatch.mainMenu and type(dispatch.mainMenu.openRoute) == "function" then
        dispatch.mainMenu:openRoute(0)
    elseif dispatch and type(dispatch.moveToHome) == "function" then
        dispatch:moveToHome()
    else
        self.focusedBuildLeaving = false
    end
end

function BuildLayer:refreshFocusedBuild()
    if self.focusedBuildDisposed or self.focusedBuildBusy then return end
    self:initdata()
    local W, c = WarmTheme, WarmTheme.colors
    local canvas = self.focusedCanvas
    canvas:removeAllChildren(true)
    self.focusedGeneration = self.focusedGeneration + 1
    local generation = self.focusedGeneration
    self.focusedButtons = {}
    local function label(text, size, color, x, y, width, anchor)
        local n = W.label(text,size,color,x,y,false,anchor or 0)
        if width then W.fit(n,width) end
        canvas:addChild(n);return n
    end
    local function button(key,text,y,action,primary)
        local n = W.button(text,388,54,function()
            if not self.focusedBuildDisposed and not self.focusedBuildLeaving and generation == self.focusedGeneration then action() end
        end,{size=23,primary=primary})
        n:setPosition(cc.p(240,y));canvas:addChild(n);self.focusedButtons[key]=n
        return n
    end
    label("港口建设",23,c.muted,40,752,400)
    local entry = self:focusedEntry()
    local recipe = self.csvData[tostring(self.focusTargetId)]
    local built = entry and tonumber(entry[dataKeyNum]) ~= 0
    local unlocked = entry and recipe and GuideController:getInstance():getIsHaveStep(1)
    self.focusedCostRows = {}
    if recipe then
        local art = W.sprite("Images/Icon/" .. (recipe.iconName or ""),94,94)
        if art then art:setPosition(cc.p(240,655));canvas:addChild(art) end
        label(recipe.name or "建设",30,c.ink,240,574,400,.5)
    end
    if not unlocked then
        label("该建筑尚未开放",23,c.muted,240,464,388,.5)
    elseif built then
        label("已建设",26,c.sea,240,455,388,.5)
        label("回到船上，继续准备下一段航程。",21,c.muted,240,405,388,.5)
    else
        label("建造所需",23,c.ink,46,508,200)
        label("现有 / 所需",19,c.muted,434,508,164,1)
        local costs = recipe.resume or {}
        local spacing = math.min(57,240/math.max(1,#costs))
        local enough = true
        for index, cost in ipairs(costs) do
            local id, need = tostring(cost[1]),tonumber(cost[2]) or 0
            local have = tonumber(DataManager:getInstance():getPackNumWithId(id)) or 0
            local resource = self.ResoucecsvData[id] or {}
            local y = 459-(index-1)*spacing
            local line = W.panel(388,1,c.line,0);line:setPosition(cc.p(46,y-25));canvas:addChild(line)
            label(resource.name or id,23,c.ink,46,y,185)
            local value = label(tostring(have).." / "..tostring(need),23,have>=need and c.ink or ManagementTheme.colors.danger,434,y,188,1)
            self.focusedCostRows[#self.focusedCostRows+1] = {id=id,have=have,need=need,label=value}
            if have<need then enough=false end
        end
        label(enough and "材料已备齐" or "材料不足，可查看获取方式",21,enough and c.sea or c.muted,240,244,388,.5)
        button("build","建设",165,function() self:attemptFocusedBuild() end,true)
    end
    button("back","返回船上",74,function() self:leaveFocusedBuild() end,false)
end

function BuildLayer:attemptFocusedBuild()
    if self.focusedBuildDisposed or self.focusedBuildLeaving or self.focusedBuildBusy then return false end
    if DialogueViewManager and not DialogueViewManager:sharedInstance():empty() then return false end
    -- Recheck the original unlocked row, guide and inventory at the click. A
    -- stale native button can never build twice or create an unavailable item.
    self:initdata()
    local entry = self:focusedEntry()
    local id = tostring(self.focusTargetId)
    if not entry or tonumber(entry[dataKeyNum]) ~= 0 or not self.csvData[id]
        or not GuideController:getInstance():getIsHaveStep(1) then
        self:refreshFocusedBuild();return false
    end
    local dm = DataManager:getInstance()
    if dm:getSound_off() == 0 then AudioEngine.playEffect(EFFECT_Button,false) end
    local enough, missing = self:cheackResoucesOK(id)
    if enough ~= 1 then
        Lackmaterial:create(missing,function()
            if not self.focusedBuildDisposed then self:refreshFocusedBuild() end
        end):show()
        return false
    end
    -- Same transaction and guide/unlock owner as the full construction list.
    -- Inventory events during the deductions must not replace the tapped node.
    self.focusedBuildBusy = true
    self:useResouces(id)
    dm:createSuccessCheck(kUnlockBuild,id)
    ToastUtil:downString("建造成功")
    self.focusedBuildBusy = false
    self:refreshFocusedBuild()
    return true
end
