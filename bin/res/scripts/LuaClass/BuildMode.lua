require "LuaClass/Header"
require "LuaClass/BaseView"
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


function BuildLayer:create()
    local view = BuildLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function BuildLayer:destory()
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

        local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
        local _backGround = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, temp:getContentSize().width, temp:getContentSize().height), cc.rect(17, 17, 30, 30));
        _backGround:setPreferredSize(cc.size(visibleSize.width, 100))

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
        local _name = cc.LabelTTF:create(_name_str,BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY + 5))
        _name:setColor(BaseColor)
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
            local _price = cc.LabelTTF:create(s_templacktable[i]["mtname"],BoldFont,_fontSize - 2);
            _price:setPosition(cc.p(s_p,_centerY - _HeadSprite:getContentSize().height - 5))
            -- _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
            _price:setColor(s_templacktable[i]["mtcolor"])
            _price:setAnchorPoint(cc.p(0,0))
            basenode:addChild(_price)
            s_p = s_p + _price:getContentSize().width
        end
        
            local _menuButton = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")

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

            local _zz = cc.LabelTTF:create("建 设", BoldFont, 30.0)
            _zz:setPosition(_menuButton:getPosition())
            -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            cell:addChild(_zz)
        else
            local _zz = cc.LabelTTF:create("已建设", BoldFont, 30.0)
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
                lacktablecell.mtcolor = RedColor
            else
                lacktablecell.mtcolor = WriteColor
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


