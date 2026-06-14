require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/AlertView"
require "LuaClass/Lackmaterial"


MakeLayer = class("MakeLayer", function ()
    return BaseView:create()
end)

MakeLayer.__index = MakeLayer
MakeLayer.csvData = nil
MakeLayer.ResoucecsvData = nil
MakeLayer.dataIndex = nil


function MakeLayer:create()
    local view = MakeLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function MakeLayer:destory()
    -- 干掉注册的信息
    DataManager:getInstance():unregisterEvent(roleMapInfo, "MakeLayer")
    -- 调用父类的析构
    self:superDestory()
end

function MakeLayer:viewWillDestory()
    -- 关闭的时候清理红点
    DataManager:getInstance():cleanNewUnlock(kUnlockMake)
    -- 出制造界面清理制造红点
    GuideController:getInstance():addStep(2, true)
end

function MakeLayer:init()
    DataManager:getInstance():registerEvent(roleMapInfo, "MakeLayer", function()
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

    -- 测试激活数据
    -- local a, b = DataManager:getInstance():unlockUnitWithType(kUnlockMake, "2")
    -- cclog(b)
    
    -- for k,v in pairs(self.workerData) do
    --     for kx,vx in pairs(v) do
    --         print(kx,vx)
    --     end
    -- end

    -- 设置title文字
    self.titleLabel:setString("制 造")

    self:initdata()

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, nil, nil, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
    end, nil, true, zqAlchemyTime, false)

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


        
        local DataTable =  self.workerData[idx]
        local _csvID = DataTable[dataKeyID]
        local _sortID = DataTable["sortId"]
        -- local _ObjectNumber = DataTable[dataKeyNum]

        local _resID_str = self.ResoucecsvData[tostring(_csvID)]["ID"]
        -- print("roleMakeid = ",roleMakeid)
        -- print("_resID_str",_resID_str)
        local _resIcon_str = self.ResoucecsvData[tostring(_csvID)]["iconName"]

        -- print("_resIcon_str",_resIcon_str)




        -- local _HeadSprite = nil
        -- if _resIcon_str ~= "" and _resIcon_str ~= nil then
        --     _HeadSprite = cc.MenuItemImage:create("Images/Icon/".._resIcon_str, "Images/Icon/".._resIcon_str)
        -- else
        --     _HeadSprite = cc.MenuItemImage:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png")
        -- end
        -- _HeadSprite:registerScriptTapHandler(function()
        --     self:showInfoBox("物品名字："..self.ResoucecsvData[tostring(_csvID)]["name"].."\n描述："..self.ResoucecsvData[tostring(_csvID)]["desc"].."\n需要材料："..self.ResoucecsvData[tostring(_csvID)]["comment"])
        -- end)

        -- _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+15,cellSize.height/2))
        -- local _HeadSpriteButton = cc.Menu:create(_HeadSprite)
        -- _HeadSpriteButton:setPosition(0.0, 0.0)
        -- cell:addChild(_HeadSpriteButton)



        function showinfo()
            self:showInfoBox("物品名字："..self.ResoucecsvData[tostring(_csvID)]["name"].."\n描述："..self.ResoucecsvData[tostring(_csvID)]["desc"].."\n需要材料："..self.ResoucecsvData[tostring(_csvID)]["comment"])
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

        local _name_str = self.ResoucecsvData[tostring(_csvID)]["name"]
        local _name = cc.LabelTTF:create(_name_str,BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY + 5))
        _name:setColor(BaseColor)
        -- _name:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _name:setAnchorPoint(cc.p(0,1))
        cell:addChild(_name)

        --price
        -- local s_ishave,s_templacktable = self:cheackResoucesOK(_csvID)
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

        -- local _price = cc.LabelTTF:create(self.ResoucecsvData[tostring(_csvID)]["comment"],BoldFont,_fontSize - 2);
        -- _price:setPosition(cc.p(_xLeft,_centerY - _HeadSprite:getContentSize().height - 5))
        -- _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        -- if  s_ishave == 1  then
        --     _price:setColor(WriteColor)
        -- else
        --     _price:setColor(RedColor)
        -- end
        -- _price:setAnchorPoint(cc.p(0,0))
        -- cell:addChild(_price)



        local _resStarNum_str = self.ResoucecsvData[tostring(_csvID)]["starNum"]
        local _rightX = _backGround:getPositionX() - 40
        if _resStarNum_str ~= "" and _resStarNum_str ~= nil then
            for i=1,tostring(_resStarNum_str) do
                local _starSprite = cc.Sprite:create("Images/UI/xingxing01.png")
                _starSprite:setPosition(cc.p(_rightX+i*_starSprite:getContentSize().width,_centerY))
                _starSprite:setAnchorPoint(cc.p(0,1))
                cell:addChild(_starSprite)
            end
        end


        --end
        local function test()
        end
        local _menuButton = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        _menuButton:registerScriptTapHandler(function()

            local ishave,templacktable = self:cheackResoucesOK(_csvID)
            if  ishave == 1  then
                self:useResouces(_csvID)
                -- 解锁东西
                local oldlinenum = self:getDataNum()
                DataManager:getInstance():createSuccessCheck(kUnlockMake, _sortID)

                ToastUtil:downString("制造成功")
                self:initdata()
                local oldp = self.tableview:getContentOffset()
                self.tableview:reloadData()
                local linenum = self:getDataNum()
                if linenum > self.showline then
                    self.tableview:setContentOffset(cc.p(oldp.x,oldp.y - (linenum - oldlinenum) * self.cellhight),false);
                end
            else
                Lackmaterial:create(templacktable,function ()
                    -- if basenode~=nil then
                    --     basenode:removeFromParent()
                    -- end

                    -- body
                    -- local s_ishave,s_templacktable = self:getResouceshowtable(_csvID)
                    -- local neednum = #s_templacktable
                    -- local s_p = _xLeft
                    -- basenode = cc.Node:create()
                    -- basenode:setPosition(cc.p(0,0))
                    -- cell:addChild(basenode)
                    -- for i = 1,neednum do
                    --     local _price = cc.LabelTTF:create(s_templacktable[i]["mtname"],BoldFont,_fontSize - 2);
                    --     _price:setPosition(cc.p(s_p,_centerY - _HeadSprite:getContentSize().height - 5))
                    --     _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
                    --     _price:setColor(s_templacktable[i]["mtcolor"])
                    --     _price:setAnchorPoint(cc.p(0,0))
                    --     basenode:addChild(_price)
                    --     s_p = s_p + _price:getContentSize().width
                    -- end
                    local oldp = self.tableview:getContentOffset()
                    
                    self.tableview:reloadData()
                    self.tableview:setContentOffset(cc.p(oldp.x,oldp.y),false)
                end):show()
            end



            
        end)
        _menuButton:setPosition(cc.p(cellSize.width-_menuButton:getContentSize().width * 0.5 - 30,cellSize.height/2))
        local menu = cc.Menu:create(_menuButton)
        menu:setPosition(0.0, 0.0)
        cell:addChild(menu)

        -- 根据数据显示按钮上的红点
        if DataTable["S"] ~= nil then
            GuideController:getInstance():addRedPoint(_menuButton)
        end

        local _zz = cc.LabelTTF:create("制 造", BoldFont, 30.0)
        _zz:setPosition(_menuButton:getPosition())
        -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        cell:addChild(_zz)
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




-- 根据材料是否充足来得到显示table 红色缺乏 白色充足
-- {{mtname = "b",mtcolor = "100"}..}

function MakeLayer:getResouceshowtable(csvID)
    local isok = 1
    local Lacktable = {}
    local needtable = self.ResoucecsvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        -- print("keystring",keystring)
        -- print("keynum",keynum)

        local havenum = DataManager:getInstance():getPackNumWithId(tostring(keystring))
        -- print("havenum",havenum)
        
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
-- {{mtId = "1007",mtname = "b",mtprice = "100",mtnum = "20",mtStar = “2”,mtonlyProduce = "1"}..}

function MakeLayer:cheackResoucesOK(csvID)
    local isok = 1
    local Lacktable = {}
    local needtable = self.ResoucecsvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        -- print("keystring",keystring)
        -- print("keynum",keynum)

        local havenum = DataManager:getInstance():getPackNumWithId(tostring(keystring))
        -- print("havenum",havenum)
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
function MakeLayer:useResouces(csvID)
    local needtable = self.ResoucecsvData[tostring(csvID)]["resume"]
    local neednum = #needtable
    for i = 1,neednum do
        local ketable = needtable[i]
        local keystring = ketable[1]
        local keynum = ketable[2]
        -- print("keystring",keystring)
        -- print("keynum",keynum)

        DataManager:getInstance():addPackItemWithId(tostring(keystring), -1 * tonumber(keynum))
    end
    DataManager:getInstance():addPackItemWithId(tostring(csvID), 1)

    -- local showstr = "恭喜您成功制造了"..self.ResoucecsvData[tostring(csvID)]["name"]
    -- DataManager:getInstance():sendSystemInfo(showstr)
end

function MakeLayer:initdata()

    self.workerData = DataManager:getInstance():getRoleData(roleMake)
end 

function MakeLayer:setDataKey()
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

function MakeLayer:getDataNum()
    local  _num = 0
    for k,v in pairs(self.ResoucecsvData) do
        if v~= nil and tonumber(v["name"])  ~= 0 then
         _num = _num + 1
        end   
    end
    -- cclog("_num = ".._num)
    _num = #self.workerData
    return _num
end
