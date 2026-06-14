require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/AlertView"
require "LuaClass/SDButton"


StoreLayer = class("StoreLayer", function ()
    return BaseView:create()
end)

StoreLayer.__index = StoreLayer
StoreLayer.data = nil
StoreLayer.csvData = nil
StoreLayer.ResoucecsvData = nil
StoreLayer.dataIndex = nil

function StoreLayer:create(bIsMoveToBottom)
    local view = StoreLayer.new()
    if view and view:init(bIsMoveToBottom) then
        return view
    end
    return nil
end

function StoreLayer:destory()
    -- 关闭的时候清理红点
    DataManager:getInstance():cleanNewUnlock(kUnlockStore)
    -- 调用父类的析构
    self:superDestory()
end

function StoreLayer:init(bIsMoveToBottom)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- local a, b = DataManager:getInstance():unlockUnitWithType(kUnlockStore, "14")
    self.roleStoreData = DataManager:getInstance():getRoleData(roleStore)

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, nil, nil, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
    end, nil, true, zqAlchemyTime, false)

    self.csvData = DataManager:getInstance():getCSVByID(csvOfStore)
    if self.csvData  == nil then
        return false
    end

    self.ResoucecsvData = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    if self.ResoucecsvData  == nil then
        return false
    end

    self:setBackgroundIcon("Images/Background/shic.png")

    -- 设置title文字
    self.titleLabel:setString("市 场")


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
        -- cclog("scrollView cell "..tostring(cell:getTag()).." touched")
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
        
        local DataTable =  self.roleStoreData[idx]
        local _csvID = DataTable[dataKeyID]
        local _sortID = DataTable["sortId"]

        -- local _resID_str = self.csvData[tostring(idx)]["resourceInfoID"]

        local _resIcon_str = self.ResoucecsvData[tostring(_csvID)]["iconName"]

        -- print("_resIcon_str",_resIcon_str)


-- showInfoBox

        


        -- local _HeadSprite = nil
        -- if _resIcon_str ~= "" and _resIcon_str ~= nil then
        --     _HeadSprite = cc.MenuItemImage:create("Images/Icon/".._resIcon_str, "Images/Icon/".._resIcon_str)
        -- else
        --     _HeadSprite = cc.MenuItemImage:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png")
        -- end
        -- _HeadSprite:registerScriptTapHandler(function()
        --     self:showInfoBox("物品名字："..self.ResoucecsvData[tostring(_csvID)]["name"].."\n价格为："..self.ResoucecsvData[tostring(_csvID)]["comment"])
        -- end)

        -- _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+15,cellSize.height/2))
        -- local _HeadSpriteButton = cc.Menu:create(_HeadSprite)
        -- _HeadSpriteButton:setPosition(0.0, 0.0)
        -- cell:addChild(_HeadSpriteButton)

        function showinfo()
            self:showInfoBox("名称："..self.ResoucecsvData[tostring(_csvID)]["name"].."\n描述："..self.ResoucecsvData[tostring(_csvID)]["desc"].."\n价格："..self.ResoucecsvData[tostring(_csvID)]["comment"])
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
        local _price = cc.LabelTTF:create(self.ResoucecsvData[tostring(_csvID)]["comment"],BoldFont,_fontSize - 2);
        _price:setPosition(cc.p(_xLeft,_centerY - _HeadSprite:getContentSize().height - 5))
        -- _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _price:setColor(WriteColor)
        _price:setAnchorPoint(cc.p(0,0))
        cell:addChild(_price)



        local _resStarNum_str = self.ResoucecsvData[tostring(_csvID)]["starNum"]
        local _rightX = _backGround:getPositionX() - 40
        for i=1,tostring(_resStarNum_str) do
            local _starSprite = cc.Sprite:create("Images/UI/xingxing01.png")
            _starSprite:setPosition(cc.p(_rightX+i*_starSprite:getContentSize().width,_centerY))
            _starSprite:setAnchorPoint(cc.p(0,1))
            cell:addChild(_starSprite)
        end



        

        function showmorebuy()
            -- body
            cclog("长按购买")
            local _alert = AlertView:create(0,0, "批量购买",nil)

            

            local _menuButton1 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
            _menuButton1:registerScriptTapHandler(function ()
                -- body
                print("self:buy(_csvID,_sortID,10,_alert)",_csvID)
                self:buy(_csvID,_sortID,10,_alert)
            end)

            local _menuButton2 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
            _menuButton2:registerScriptTapHandler(function ()
                -- body
                self:buy(_csvID,_sortID,100,_alert)
            end)

            local _menuButton3 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
            _menuButton3:registerScriptTapHandler(function ()
                -- body
                self:buy(_csvID,_sortID,1000,_alert)
            end)

            local _menuButton1Lable = cc.LabelTTF:create("买10个", BoldFont, 30.0)
            _menuButton1Lable:setPosition(cc.p(_menuButton1:getContentSize().width * 0.5,_menuButton1:getContentSize().height * 0.5))
            -- _menuButton1Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            _menuButton1:addChild(_menuButton1Lable,1)

            local _menuButton2Lable = cc.LabelTTF:create("买100个", BoldFont, 30.0)
            _menuButton2Lable:setPosition(cc.p(_menuButton2:getContentSize().width * 0.5,_menuButton2:getContentSize().height * 0.5))
            -- _menuButton2Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            _menuButton2:addChild(_menuButton2Lable,1)

            local _menuButton3Lable = cc.LabelTTF:create("买1000个", BoldFont, 30.0)
            _menuButton3Lable:setPosition(cc.p(_menuButton3:getContentSize().width * 0.5,_menuButton3:getContentSize().height * 0.5))
            -- _menuButton3Lable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
            _menuButton3:addChild(_menuButton3Lable,1)


            _menuButton1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + _menuButton1:getContentSize().height * 2 - 20))
            _menuButton2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - 20))
            _menuButton3:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - _menuButton1:getContentSize().height * 2 - 20))
            local menu = cc.Menu:create(_menuButton1,_menuButton2,_menuButton3)
            menu:setPosition(0.0, 0.0)
            _alert:addChild(menu)


        end

        

        local _menuButton = SDButton:create("Images/btn/ann01_a.png","Images/btn/ann01_a.png",function ()
                -- body
                -- print("SDButton:create",tostring(_csvID))
                self:buy(_csvID,_sortID,1,nil)
            end)
        if tonumber(self.ResoucecsvData[tostring(_csvID)]["limits"]) ~= 1 then
            _menuButton:registerLongPressedActiveOnce(showmorebuy)
        end
        _menuButton:setPosition(cc.p(cellSize.width-_menuButton:getContentSize().width * 0.5 - 30,cellSize.height/2))
        cell:addChild(_menuButton,1)

        -- 根据数据显示按钮上的红点
        if DataTable["S"] ~= nil then
            GuideController:getInstance():addRedPoint(_menuButton)
        end

        -- --end
        -- local function test()
        -- end
        -- local _menuButton = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        -- _menuButton:registerScriptTapHandler(function()


        --     -- local _priceTable = self.csvData[tostring(idx)]["price"]

        --     -- local _result = DataManager:getInstance():addCoin(-1 * tonumber(_priceTable[1][2]))

        --     if  self:cheackResoucesOK(_csvID) == 1  then
        --         self:useResouces(_csvID)
        --         -- 解锁东西

        --         DataManager:getInstance():createSuccessCheck(kUnlockStore, _csvID)

        --         ToastUtil:downString("购买成功")
        --         self.tableview:reloadData()
        --     else
        --         local _alert = AlertView:create(2,0, "购买失败",test)

        --         local showLabel1 = cc.LabelTTF:create("金币不足!", BoldFont, 36.0)
        --         showLabel1:setColor(cc.c3b(255, 255, 255))
        --         showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        --         showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
        --         _alert:addChild(showLabel1)

        --         local showLabel2 = cc.LabelTTF:create("你可以通过充值获得更多钻石。", BoldFont, 36.0)
        --         showLabel2:setColor(cc.c3b(255, 255, 255))
        --         showLabel2:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        --         showLabel2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - showLabel1:getContentSize().height * 0.2))
        --         _alert:addChild(showLabel2)
        --     end
            
        -- end)
        -- _menuButton:setPosition(cc.p(cellSize.width-_menuButton:getContentSize().width * 0.5 - 30,cellSize.height/2))
        -- local menu = cc.Menu:create(_menuButton)
        -- menu:setPosition(0.0, 0.0)
        -- cell:addChild(menu)

        local _zz = cc.LabelTTF:create("购 买", BoldFont, 30.0)
        _zz:setPosition(_menuButton:getPosition())
        -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        cell:addChild(_zz,1)
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

    -- 添加顶部菜单背景
    -- local TopBg = cc.Sprite:create("Images/UI/SettingBtn1.png")
    -- TopBg:setPosition(self.centerPos)
    -- self:addChild(TopBg)

    if bIsMoveToBottom then
        cclog("通过训练进入了市场")
        self.tableview:setContentOffset(cc.p(0, 0), false);
    end

    return true
end

-- 检查资源是否充足
function StoreLayer:cheackResoucesOK(csvID,num)
    local isok = 1
    -- print("csvID",tostring(csvID))
    local neednum = self.ResoucecsvData[tostring(csvID)]["price"]
    local havenum = DataManager:getInstance():getPackNumWithId("1001")
    -- print("havenum",havenum)
    -- print("neednum",neednum)
    if tonumber(havenum) < tonumber(neednum) * num then
        islack = 0
        return 0
    end
    return 1
end

function StoreLayer:initdata()

    self.roleStoreData = DataManager:getInstance():getRoleData(roleStore)
end 

function StoreLayer:buy(_csvID,_sortID,num,_oldalert)
    -- print("StoreLayer:buy(_csvID,num,_oldalert)",tostring(_csvID))
    if  self:cheackResoucesOK(_csvID,num) == 1  then
        if _oldalert ~= nil then
            _oldalert:removeFromParent()
        end
        self:useResouces(_csvID,num)

         -- 解锁东西
        local oldlinenum = self:getDataNum()
        DataManager:getInstance():createSuccessCheck(kUnlockStore, _sortID)

        ToastUtil:downString("购买成功", true)
        self:initdata()
        local oldp = self.tableview:getContentOffset()
        self.tableview:reloadData()
        local linenum = self:getDataNum()
        if linenum > self.showline then
            self.tableview:setContentOffset(cc.p(oldp.x,oldp.y - (linenum - oldlinenum) * self.cellhight),false);
        end

    else
        if _oldalert ~= nil then
            _oldalert:removeFromParent()
        end
        local _alert = AlertView:create(2,0, "购买失败", function()
            DataManager:getInstance():showBuyGoldBox()
        end, nil)

        local showLabel1 = cc.LabelTTF:create("金币不足!", BoldFont, 36.0)
        showLabel1:setColor(cc.c3b(255, 255, 255))
        -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
        _alert:addChild(showLabel1)

        local showLabel2 = cc.LabelTTF:create("你可以通过充值获得钻石购买金币", BoldFont, 36.0)
        showLabel2:setColor(cc.c3b(255, 255, 255))
        -- showLabel2:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        showLabel2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - showLabel1:getContentSize().height * 0.2))
        _alert:addChild(showLabel2)
    end
end

-- 消耗资源
function StoreLayer:useResouces(csvID,num)
    local neednum = self.ResoucecsvData[tostring(csvID)]["price"]
    -- print("csvID num",tostring(csvID))
    -- print("num",neednum)
    DataManager:getInstance():addPackItemWithId("1001", -1 * tonumber(neednum) * num)

    DataManager:getInstance():addPackItemWithId(tostring(csvID), 1 * num)

    local showstr = "您购买了"..self.ResoucecsvData[tostring(csvID)]["name"].."+"..num
    DataManager:getInstance():sendSystemInfo(showstr)
    -- local needtable = self.ResoucecsvData[tostring(csvID)]["resume"]
    -- local neednum = #needtable
    -- for i = 1,neednum do
    --     local ketable = needtable[i]
    --     local keystring = ketable[1]
    --     local keynum = ketable[2]
    --     print("keystring",keystring)
    --     print("keynum",keynum)

    --     DataManager:getInstance():addPackItemWithId(tostring(keystring), -1 * tonumber(keynum))
    -- end
end

function StoreLayer:setDataKey()
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

function StoreLayer:getDataNum()
    local  _num = 0
    for k,v in pairs(self.csvData) do
        if v~= nil and v["name"] ~= nil then
         _num = _num + 1
        end   
    end
    -- cclog("_num = ".._num)
    _num = #self.roleStoreData
    return _num
end
