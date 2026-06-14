require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/ToastUtil"
require "LuaClass/DataManager"
require "LuaClass/AlertView"
require "LuaClass/DialogueView"

TrainLayer = class("TrainLayer", function ()
    return BaseView:create()
end)

TrainLayer.__index = TrainLayer
TrainLayer.data = nil
TrainLayer.csvData = nil
TrainLayer.dataIndex = nil
TrainLayer.instance = nil

function TrainLayer:create()
    local view = TrainLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function TrainLayer:destory()
    cclog("TrainLayer：我自由了")
    DataManager:getInstance():unregisterEvent(roleGuideStep, "train")
    DataManager:getInstance():unregisterEvent(roleMapInfo, "TrainLayer")
    -- 调用父类的析构
    self:superDestory()
end

function TrainLayer:init()
    DataManager:getInstance():registerEvent(roleMapInfo, "TrainLayer", function()
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

    TrainLayer.instance = self

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    --DataManager:getInstance():addCoin(10000)
    -- 设置title文字
    self.titleLabel:setString("招 募")


    --招募
    local soilderID  = "100" -- 默认招募船员
    self.data = DataManager:getInstance():getRoleData(roleSoildierQueue)
    if self.data == nil then
        self.data = {}
    end
    local SkillData = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
    self.csvData = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    self.bufData =  DataManager:getInstance():getCSVByID(csvOfBuff)
    if self.csvData  == nil or SkillData == nil then
        return false
    end
    --
    self:setDataKey()

    --sure 招募
    local function Recruit()
        --success 
        local _money = self.csvData[soilderID]["produceResume"][1][3]
        local _result = 0
        local _defGoil = 0
        local _result,_defGoil = DataManager:getInstance():addCoin(-1 * tonumber(_money))
        if _result == 0 then
            --ToastUtil:toastString("缺少金币".."X".._defGoil)
        local _alert = AlertView:create(2,0, "购买失败",test,nil)
        local showLabel1 = cc.LabelTTF:create("金币不足!", BoldFont, 36.0)
        showLabel1:setColor(cc.c3b(255, 255, 255))
        -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
        _alert:addChild(showLabel1)

        local showLabel2 = cc.LabelTTF:create("您可以通过充值获得钻石购买金币", BoldFont, 36.0)
        showLabel2:setColor(cc.c3b(255, 255, 255))
        -- showLabel2:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        showLabel2:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - showLabel1:getContentSize().height * 0.2))
        _alert:addChild(showLabel2)
        else
            ToastUtil:toastString("招募成功！")

            --第一次招募 统计
            if not GuideController:getInstance():getIsHaveStep(11) then
                GuideController:getInstance():addStep(11)
            end

            if self.data[soilderID] == nil then
                --self.data[soilderID] = clone(self.csvData[soilderID])
                self.data[soilderID] = {}
                self.data[soilderID][dataKeyID] = soilderID
            end
            if self.data[soilderID][dataKeyNum] == nil then
                self.data[soilderID][dataKeyNum] = 0
            end
            self.data[soilderID][dataKeyNum] = self.data[soilderID][dataKeyNum] + 1
            self:setDataKey()
            self.tableview:reloadData()
            DataManager:getInstance():setRoleData(roleSoildierQueue,self.data,nil)

            DataManager:getInstance():setAchievementInfo(achievement_Training, tostring(soilderID))
        end
        --print("====size===",self.data[soilderID][dataKeyNum])
    end
    -- 设置下方信息界面

    self:addInfoNode(nil, nil, nil, nil, "Images/MainMenu/an_zhaom_a.png", "Images/MainMenu/an_zhaom_b.png", function()
        --cclog("点击了招募按钮")
        
        local _layer = AlertView:create(2,0, "招募",Recruit,nil)
        local _soilder = self.csvData[soilderID]

        local _backGround = cc.Sprite:create("Images/UI/dibantiao_03.png")
        _backGround:setPosition(_layer.s_position)
        _layer:addChild(_backGround)


        local _fontSize = 26
         --local _HeadSprite= cc.Sprite:create("Images/UI/tankuang_04.png")
         local _HeadSprite= cc.Sprite:create("Images/Icon/".._soilder["icon"])
         if _HeadSprite == nil then _HeadSprite= cc.Sprite:create("Images/UI/tankuang_04.png")  end
        _HeadSprite:setPosition(cc.p(_backGround:getPositionX()-_backGround:getContentSize().width/2+_HeadSprite:getContentSize().width-5,
            _backGround:getPositionY()))
        _layer:addChild(_HeadSprite)
        --name
        local _xLeft = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width/2 + 10
        local _centerY = _HeadSprite:getPositionY() -5
        local _name = cc.LabelTTF:create(_soilder["name"],BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY+_fontSize+7))
        _name:setColor(BaseColor)
        -- _name:enableStroke(cc.c4b(215, 199, 165, 255), 1)
        _name:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_name)
        --skill
        local _skillName = cc.LabelTTF:create("技能："..SkillData[tostring(_soilder["skill"])]["name"],BoldFont,_fontSize);
        _skillName:setPosition(cc.p(_xLeft,_centerY+2))
        -- _skillName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _skillName:setColor(WriteColor)
        _skillName:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_skillName)
         --attack
        local _attackName = cc.LabelTTF:create("威力：".._soilder["attack"],BoldFont,_fontSize);
        _attackName:setPosition(cc.p(_xLeft,_centerY-_fontSize))
        -- _attackName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _attackName:setColor(WriteColor)
        _attackName:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_attackName)
        --star 
        local _rightX = _backGround:getPositionX() + 20
        local _righCenterY = _backGround:getPositionY() -5
        for i=0,_soilder["star"]-1 do
            local _starSprite = cc.Sprite:create("Images/UI/xingxing01.png")
            _starSprite:setPosition(cc.p(_rightX+i*_starSprite:getContentSize().width,_name:getPositionY()))
            _starSprite:setAnchorPoint(cc.p(0,0.5))
            _layer:addChild(_starSprite)
        end
        --hp
        local _hpName = cc.LabelTTF:create("生命：".._soilder["hp"],BoldFont,_fontSize);
        _hpName:setPosition(cc.p(_rightX,_skillName:getPositionY()))
        -- _hpName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _hpName:setColor(WriteColor)
        _hpName:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_hpName)
        --speed
        local _speedName = cc.LabelTTF:create("速度：".._soilder["speed"],BoldFont,_fontSize);
        _speedName:setPosition(cc.p(_rightX,_attackName:getPositionY()))
        -- _speedName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _speedName:setColor(WriteColor)
        _speedName:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_speedName)
        --title
        local _titleY = _backGround:getPositionY() + _backGround:getContentSize().height/2 + 55
        local _hf = cc.LabelTTF:create("花费", BoldFont, 30.0)
        _hf:setPosition(cc.p(_HeadSprite:getPositionX()+10,_titleY))
        -- _hf:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _hf:setColor(WriteColor)
        _hf:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_hf)
        --goal
        local _goalSprite = cc.Sprite:create("Images/UI/CoinBg.png")
        _goalSprite:setPosition(cc.p(_HeadSprite:getPositionX()+_hf:getContentSize().width,_titleY))
        _goalSprite:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_goalSprite)
        --
        local _disFont = cc.LabelTTF:create("X".._soilder["produceResume"][1][3].."招募一个".._soilder["name"].."？", BoldFont, 30.0)
        _disFont:setPosition(cc.p(_goalSprite:getPositionX()+_goalSprite:getContentSize().width,_titleY))
        -- _disFont:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _disFont:setColor(WriteColor)
        _disFont:setAnchorPoint(cc.p(0,0.5))
        _layer:addChild(_disFont)

    end, "Images/MainMenu/w_zhaom.png")

    self.setBtnLight:setVisible(true)

    --招募
    local light = cc.Sprite:create("Images/UI/pointer.png")
    light:setScale(1.8)
    light:setPosition(cc.p(self.setBtn:getPositionX(),self.setBtn:getPositionY()))
    self.infoNode:addChild(light,-1)
    light:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.0),cc.ScaleTo:create(0, 1.5), cc.Spawn:create(cc.EaseExponentialIn:create(cc.FadeTo:create(0.8, 128.0)), cc.ScaleTo:create(0.8, 2.3)))))

    local cellSize = cc.size(530,112)
    -- 添加scrollView
    self.tableview = cc.TableView:create(cc.size(self.areaWidth, self.areaHeight))
    self.tableview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview:setPosition(cc.p(self.originPos))
    self.tableview:setDelegate()
    self.tableview:registerScriptHandler(function( view, idx)
        idx = idx + 1
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()

        local _backGround = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png")
        _backGround:setPreferredSize(cc.size(589,101))
        _backGround:setPosition(cc.p(self.areaWidth/2,cellSize.height/2))
        cell:addChild(_backGround)

        --start
        local _fontSize = 26
        local _soilderTable = self.data[self:getDataKeyByIndex(idx)]
        local _soilder =  self.csvData[_soilderTable[dataKeyID]]
        --local _HeadSprite = cc.Sprite:create("Images/UI/tankuang_04.png")
        local _HeadSprite = cc.Sprite:create("Images/Icon/".._soilder["icon"])
         if _HeadSprite == nil then _HeadSprite = cc.Sprite:create("Images/UI/tankuang_04.png") end
        _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width+5,cellSize.height/2))
        cell:addChild(_HeadSprite)
        --num
        if _soilderTable[dataKeyNum] ~= nil and _soilderTable[dataKeyNum] > 1 then
        local _numS = cc.Sprite:create("Images/UI/num_circlebg.png")
        _numS:setScale(1.5)
        _numS:setPosition(cc.p(_HeadSprite:getPositionX()+_HeadSprite:getContentSize().width/2-12,
            _HeadSprite:getPositionY()+_HeadSprite:getContentSize().height/2))
        cell:addChild(_numS)
        local  _numFont = cc.LabelTTF:create(_soilderTable[dataKeyNum],BoldFont,_fontSize);
        _numFont:setColor(BaseColor)
        _numFont:setPosition(_numS:getPosition())
        -- _numFont:enableStroke(cc.c4b(215, 199, 165, 255), 1)
        cell:addChild(_numFont)
        end
        --name
        local _xLeft = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width/2 + 16
        local _centerY = _HeadSprite:getPositionY() -5
        local _name = cc.LabelTTF:create(_soilder["name"],BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY+_fontSize+7))
        _name:setColor(BaseColor)
        -- _name:enableStroke(cc.c4b(215, 199, 165, 255), 1)
        _name:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_name)
        --skill
        local _skillName = cc.LabelTTF:create("技能："..SkillData[tostring(_soilder["skill"])]["name"],BoldFont,_fontSize);
        _skillName:setPosition(cc.p(_xLeft,_centerY+2))
        -- _skillName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _skillName:setColor(WriteColor)
        _skillName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_skillName)
         --attack
        local _attackName = cc.LabelTTF:create("威力：".._soilder["attack"],BoldFont,_fontSize);
        _attackName:setPosition(cc.p(_xLeft,_centerY-_fontSize))
        -- _attackName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _attackName:setColor(WriteColor)
        _attackName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_attackName)
        --star 
        local _rightX = _backGround:getPositionX() + 4
        local _righCenterY = _backGround:getPositionY() -5
        for i=0,_soilder["star"]-1 do
            local _starSprite = cc.Sprite:create("Images/UI/xingxing01.png")
            _starSprite:setPosition(cc.p(_rightX+i*_starSprite:getContentSize().width,_name:getPositionY()))
            _starSprite:setAnchorPoint(cc.p(0,0.5))
            cell:addChild(_starSprite)
        end
        --hp
        local _hpName = cc.LabelTTF:create("生命：".._soilder["hp"],BoldFont,_fontSize);
        _hpName:setPosition(cc.p(_rightX,_skillName:getPositionY()))
        -- _hpName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _hpName:setColor(WriteColor)
        _hpName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_hpName)
        --speed
        local _speedName = cc.LabelTTF:create("速度：".._soilder["speed"],BoldFont,_fontSize);
        _speedName:setPosition(cc.p(_rightX,_attackName:getPositionY()))
        -- _speedName:enableStroke(cc.c4b(153, 156, 156, 255), 1)
        _speedName:setColor(WriteColor)
        _speedName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_speedName)

        --end
        local _menuButton = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        _menuButton:registerScriptTapHandler(function()
            if tonumber(_soilder["star"]) >= 6 then
                ToastUtil:toastString("转职失败，该船员已为最高")
            else 
               local _viewLayer = ChangeJobView:create(_soilder,idx)
               _viewLayer:show()
               --_viewLayer.soilder = _soilder
            end
            
        end)
        _menuButton:setPosition(cc.p(cellSize.width-30,cellSize.height/2))
        local menu = cc.Menu:create(_menuButton)
        menu:setPosition(0.0, 0.0)
        cell:addChild(menu)

        local _zz = cc.LabelTTF:create("转 职", BoldFont, 30.0)
        _zz:setPosition(_menuButton:getPosition())
        -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        cell:addChild(_zz)

        -- 如果满足该英雄进阶地图数，那么显示红点
        local mapData = DataManager:getInstance():getRoleData(roleMapInfo)
        local mapIndex = 1
        if mapData ~= nil then
            mapIndex = DataManager:getInstance():getRoleData(roleMapInfo).mapIndex
        end
        
        local mark = tonumber(_soilder["mark"])
        if mapIndex ~= nil and mark <= mapIndex then
            local btnLight = cc.Sprite:create("Images/btn/BtnLight.png")
            btnLight:setPosition(_menuButton:getPosition())
            btnLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(0.6), cc.EaseExponentialIn:create(cc.FadeIn:create(1.0)))))
            cell:addChild(btnLight)
            -- GuideController:getInstance():addRedPoint(_menuButton)
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

    self.tableview:registerScriptHandler(function(view, cell)

    local idx = cell:getTag()
    local _soilderTable = self.data[self:getDataKeyByIndex(idx)]
    local _soilder =  self.csvData[_soilderTable[dataKeyID]]
    local _skillBuffID = SkillData[tostring(_soilder["skill"])]["buffID"]
    local _skillNameStr = "技能："..SkillData[tostring(_soilder["skill"])]["name"].."\n"
    local _skillBuf = nil
    if _skillBuffID ~= nil and tonumber(_skillBuffID) > 0 then
        --self:showInfoBox("附加效果："..self.bufData[tostring(_skillBuffID)]["description"])
        _skillBuf = "技能效果："..self.bufData[tostring(_skillBuffID)]["description"].."\n"
    else
        --self:showInfoBox("附加效果：无")
        _skillBuf = "技能效果：无".."\n"
    end
    local _soilderSX = "生命：".._soilder["hp"].." ".."威力：".._soilder["attack"].." ".."速度：".._soilder["speed"]
    self:showInfoBox(_skillNameStr.._skillBuf.._soilderSX)
    end, cc.TABLECELL_TOUCHED)
    self:addChild(self.tableview)
    self.tableview:reloadData()

    --self:initBagDataWithType(0)
    function updateCenterButton()
        cclog("招募界面新手引导步骤变化")
        if GuideController:getInstance():getIsHaveStep(11) then
            -- 点了以后去掉红点
            GuideController:getInstance():removeRedPoint(self.setBtn)
        else
            GuideController:getInstance():addRedPoint(self.setBtn)
        end
    end

    updateCenterButton()

    -- 更新新手引导界面显示
    DataManager:getInstance():registerEvent(roleGuideStep, "train", updateCenterButton)

    return true
end

-- function TrainLayer:getDataNum()
--        local  _num = 0
--         for k,v in pairs(self.data) do
--            if v~= nil and v["name"] ~= nil and v[dataKeyNum] ~= nil and v[dataKeyNum] > 0 then
--              _num = _num + 1
--             end   
--         end
--     return _num
-- end

-- function TrainLayer:setDataKey()
--     self.dataIndex = nil
--     self.dataIndex = {}
--     local  _num = 0
--     for k,v in pairs(self.data) do
--         if v~= nil and v["name"] ~= nil and v[dataKeyNum] ~= nil and v[dataKeyNum] > 0 then
--             _num = _num + 1
--             self.dataIndex[_num] = k
--         end   
--     end
-- end
function TrainLayer:getDataNum()
       local  _num = 0
        for k,v in pairs(self.data) do
           if v~= nil and v[dataKeyID] ~= nil and v[dataKeyNum] ~= nil and v[dataKeyNum] > 0 then
             _num = _num + 1
            end   
        end
    return _num
end

function TrainLayer:setDataKey()
    self.dataIndex = nil
    self.dataIndex = {}
    local  _num = 0
    for k,v in pairs(self.data) do
        if v~= nil and v[dataKeyID] ~= nil and v[dataKeyNum] ~= nil and v[dataKeyNum] > 0 then
            _num = _num + 1
            local _star = self.csvData[tostring(k)]["star"]
            self.dataIndex[_num] = tostring(_star)..tostring(k)
        end   
    end
    table.sort(self.dataIndex,function(a,b)
        local _numA = string.sub(a,1,1)
        local _numB = string.sub(b,1,1)
        return tonumber(_numA) > tonumber(_numB)
    end)
end

function TrainLayer:getDataKeyByIndex(Index)
    if self.dataIndex ~= nil then
         return  string.sub(self.dataIndex[Index],2,#self.dataIndex[Index])
        --return self.dataIndex[Index]
    end
    return "100"
end

-- function TrainLayer:getDataByID(IgnoreID,DesID)
--     if  IgnoreID == nil or DesID == nil then
--         return nil
--     end
--     for k,v in pairs(self.data) do
--         if v~= nil and v["name"] ~= nil then
--             --print("tonumber(k)=",tonumber(k),"=tonumber(IgnoreID)=",tonumber(IgnoreID))
--             if tonumber(k) ~= tonumber(IgnoreID) then
--                 return self.data[DesID]
--             end
--         end   
--     end
-- return nil
-- end
function TrainLayer:getDataByID(IgnoreID,DesID)
    if  IgnoreID == nil or DesID == nil then
        return nil
    end
    for k,v in pairs(self.data) do
        if v~= nil and v[dataKeyID] ~= nil then
            --print("tonumber(k)=",tonumber(k),"=tonumber(IgnoreID)=",tonumber(IgnoreID))
            if tonumber(k) ~= tonumber(IgnoreID) then
                return self.data[DesID]
            end
        end   
    end
    return nil
end

function TrainLayer:changeJobCallBack(Soilder,Index)
    --print("TrainLayer:changeJobCallBack=",Index)
    ToastUtil:toastString("转职成功！")
    -- 新专职出来的兵种的idq
    local _soilderID = Soilder[dataKeyID]
    if Soilder == nil or _soilderID == nil then
        return
    end
    local _tempSoilder = nil
    --sub
    -- 原来兵种的table
    local _soilder = self.data[self:getDataKeyByIndex(Index)]
    if _soilder ~= nil and _soilder[dataKeyNum] ~= nil then
        _soilder[dataKeyNum]= _soilder[dataKeyNum] - 1
        if _soilder[dataKeyNum] <= 0 then
            -- _soilder[dataKeyNum] = nil
            self.data[self:getDataKeyByIndex(Index)] = nil
            -- _soilder = nil
        end
        if _soilder ~= nil then
            _tempSoilder = self:getDataByID(_soilder[dataKeyID],_soilderID)
        else
            -- 取背包中有无新专职出来的兵种
            _tempSoilder = self.data[_soilderID]
        end
        
        -- printn("selfdate==",self.data)
    end
    --plus
    if  _tempSoilder ~= nil  then
        self.data[_soilderID][dataKeyNum]= self.data[_soilderID][dataKeyNum] + 1
    else
        --self.data[_soilderID] = clone(self.csvData[_soilderID])
        self.data[_soilderID] = {}
        self.data[_soilderID][dataKeyID] = _soilderID
        if self.data[_soilderID][dataKeyNum] == nil then
            self.data[_soilderID][dataKeyNum] = 0
        end
        self.data[_soilderID][dataKeyNum] = self.data[_soilderID][dataKeyNum] + 1
    end 
    self:setDataKey()
    self.tableview:reloadData()
    DataManager:getInstance():setRoleData(roleSoildierQueue,self.data,nil)
    DataManager:getInstance():setAchievementInfo(achievement_Training, tostring(_soilderID))
    -- 发送通知告知出征页面修改数据
    -- DataManager:getInstance():postEvent("changeSoildierJob", nil)
    -- 清理原始存档数据中的战斗单位选择 (出征界面用到的数据) by 杨杰
    local selectedData = DataManager:getInstance():getRoleData(roleSelectUnit)
    for k, v in pairs(selectedData) do
        if tonumber(k) >= 10000 then
            -- 判断战斗数据，如果数量不足，那么修改数据。。。
            local key = (tonumber(k) - 10000) .. ""
            -- print("兵种ID：", key)
            if self.data[key] ~= nil then
                -- 取出战斗队列的数据，更新它
                local num = self.data[key][dataKeyNum]
                if type(num) ~= "number" then
                    num = tonumber(num)
                end
                -- print("清理兵种数量：", self.selectedData[k], num)
                if num > 0 then
                    if selectedData[k] > num then
                        selectedData[k] = num
                    end
                else
                    selectedData[k] = nil
                end
            else
                -- print("这个兵种在兵库里不存在了~")
                selectedData[k] = nil
            end
        end
    end
    -- 重新写入一次数据，要不然会被防内存修改盖掉
    DataManager:getInstance():setRoleData(roleSelectUnit, clone(selectedData))
end
--------------------------------===========================================================----------------
ChangeJobView = class("ChangeJobView", function ()
    return DialogueView:create()
end)
ChangeJobView.__index = ChangeJobView
ChangeJobView.soilder = nil
ChangeJobView.data = nil
ChangeJobView.dataIndex = nil
ChangeJobView.packageData = nil
ChangeJobView.StoreUnlockData = nil
ChangeJobView.conditional = nil
ChangeJobView.instance = nil
ChangeJobView.goodsTag = 10001
ChangeJobView.buttonTag = 20001
ChangeJobView.fontTag = 30001
ChangeJobView.nameTag = 40001
-- create
function ChangeJobView:create(Soilder,Index)
    local view = ChangeJobView.new()
    if view and view:init(Soilder,Index) then
        return view
    end
    return nil
end

-- init
function ChangeJobView:init(Soilder,Index)

    ChangeJobView.instance = self

    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Sprite:create("Images/UI/tankuang_03.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)
    --title
    local title = cc.LabelTTF:create("转 职",BoldFont,36)
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    -- title:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    self:addChild(title)
    --dis
    local dis = cc.LabelTTF:create("请选择要转职的职业",BoldFont,24)
    dis:setPosition(cc.p(title:getPositionX(),title:getPositionY()-58))
    dis:setColor(WriteColor)
    -- dis:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    self:addChild(dis)
    -- btn
    local btn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
    btn:registerScriptTapHandler(function()
        self:close()
    end)
    btn:setPosition(cc.p(bg:getPositionX()+bg:getContentSize().width/2-40,title:getPositionY()))
    local menu = cc.Menu:create(btn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    self.soilder = Soilder

    --csv
    self.csvData = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    self.packageCSV =  DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    local SkillData = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
    --roleData
    self.makeData =  DataManager:getInstance():getRoleData(roleMake)
    self.packageData =  DataManager:getInstance():getRoleData(rolePack)
    self.mySolderData = DataManager:getInstance():getRoleData(roleSoildierQueue)
    --解锁商店
    --for i=1,40 do
    --   DataManager:getInstance():unlockUnitWithType(kUnlockStore, tostring(i))
    --end
    self.StoreUnlockData = DataManager:getInstance():getStoreUnlockTable()

    self.data = self.soilder["changeJob"]
    -- print("self.dataSize=",#self.data)
    -- for k,v in pairs(self.data) do
    --     print(k,v)
    --     for k2,v2 in pairs(v) do
    --         print("=k2=",k2,"=v2=",v2)
    --     end
    -- end
    if self.data == nil or self.csvData == nil or self.soilder== nil or SkillData == nil or self.packageCSV == nil then
        return false
    end
    --
    self.conditional = {} --材料不足的indexTable
    for i=1,#self.data do
        self.conditional[i] = {}
    end

    --tableView
    local cellSize = cc.size(bg:getContentSize().width-40,300)
    -- 添加scrollView
    self.tableview = cc.TableView:create(cc.size(bg:getContentSize().width-40, bg:getContentSize().height-124))
    self.tableview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview:setPosition(cc.p(bg:getPositionX()-bg:getContentSize().width/2+20,bg:getPositionY()-bg:getContentSize().height/2+18))
    self.tableview:setDelegate()
    self.tableview:registerScriptHandler(function(view, idx)
    return cellSize.height+36,cellSize.width -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableview:registerScriptHandler(function(view)
        return #self.data
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableview:registerScriptHandler(function( view, idx)
        idx = idx + 1
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()
        local _backGroundCenterY = (cellSize.height+36)/2+14
        local _backGround = cc.Scale9Sprite:create("Images/UI/tankuang_04.png")
        _backGround:setPosition(cc.p(cellSize.width/2,_backGroundCenterY))
        _backGround:setPreferredSize(cc.size(cellSize.width,cellSize.height))
        cell:addChild(_backGround, -1)

        --start
        local _fontSize = 26
        --print("ChangeJobView:init===idex=",idx)
        local _soilder = self.csvData[self.data[idx][1]]
        --local _HeadSprite = cc.Sprite:create("Images/UI/tankuang_04.png")
        local _HeadSprite = cc.Sprite:create("Images/Icon/".._soilder["icon"])
        if _HeadSprite == nil then
            _HeadSprite = cc.Sprite:create("Images/UI/tankuang_04.png")
        end
        _HeadSprite:setScale(1.3)
        _HeadSprite:setPosition(cc.p(_HeadSprite:getContentSize().width + 6,cellSize.height-30))
        cell:addChild(_HeadSprite)
        --num
        -- local  _numFont = cc.LabelTTF:create(_soilder[dataKeyNum],BoldFont,_fontSize-6);
        -- _numFont:setPosition(cc.p(_HeadSprite:getPositionX()+_HeadSprite:getContentSize().width/2-4,
        --     _HeadSprite:getPositionY()+_HeadSprite:getContentSize().height/2))
        -- cell:addChild(_numFont)
        --name
        local _xLeft = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width * 0.5 + 36
        local _centerY = _HeadSprite:getPositionY() -5
        local _name = cc.LabelTTF:create(_soilder["name"],BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY+_fontSize+7))
        _name:setColor(BaseColor)
        -- _name:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _name:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_name)
        --skill
        local _skillName = cc.LabelTTF:create("技能："..SkillData[tostring(_soilder["skill"])]["name"],BoldFont,_fontSize);
        _skillName:setPosition(cc.p(_xLeft,_centerY+2))
        -- _skillName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _skillName:setColor(WriteColor)
        _skillName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_skillName)
         --attack
        local _attackName = cc.LabelTTF:create("威力：".._soilder["attack"],BoldFont,_fontSize);
        _attackName:setPosition(cc.p(_xLeft,_centerY-_fontSize))
        -- _attackName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _attackName:setColor(WriteColor)
        _attackName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_attackName)
        -- --star 
        local _rightX = _backGround:getPositionX() + 74
        local _righCenterY = _backGround:getPositionY() -5
        for i=0,_soilder["star"]-1 do
            local _starSprite = cc.Sprite:create("Images/UI/xingxing01.png")
            _starSprite:setPosition(cc.p(_rightX+i*_starSprite:getContentSize().width,_name:getPositionY()))
            _starSprite:setAnchorPoint(cc.p(0,0.5))
            cell:addChild(_starSprite)
        end
        --hp
        local _hpName = cc.LabelTTF:create("生命：".._soilder["hp"],BoldFont,_fontSize);
        _hpName:setPosition(cc.p(_rightX,_skillName:getPositionY()))
        -- _hpName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _hpName:setColor(WriteColor)
        _hpName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_hpName)
        --speed
        local _speedName = cc.LabelTTF:create("速度：".._soilder["speed"],BoldFont,_fontSize);
        _speedName:setPosition(cc.p(_rightX,_attackName:getPositionY()))
        -- _speedName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _speedName:setColor(WriteColor)
        _speedName:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_speedName)
        --end

        --转职条件
        local _conditionX = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width/2 + 10
        local _conditionY = _HeadSprite:getPositionY() - 100
        local _conditionDisW = 260
        local _conditionDisH = 75
        local _conditionData = _soilder["produceResume"]
        self.conditional[idx] = {}
        --print("=_conditionDataSize=",#_conditionData)
         if _conditionData ~= nil then
            local _rowIndex = 0
            local _listIndex = 0
             for i=1,#_conditionData do
                --print("====i=======",i)
                --type 训练消耗（消耗类型_消耗ID_消耗数量）;类型1兵种;2物品
                local _conditionType = tonumber(_conditionData[i][1])
                local _conditionID = tonumber(_conditionData[i][2])
                local _conditionNum = tonumber(_conditionData[i][3])
                if _conditionType == nil or _conditionID == nil or _conditionNum == nil then
                    break;
                end
                local _iconSprite = nil--icon
                local _nameSprite = nil--name
                local _numCurr = 0 -- num
                local _numMax = 0 -- num
                --print("_conditionType=",_conditionType,"=_conditionType=",type(_conditionType))
                --print("_conditionID=",_conditionID,"=_conditionIDType=",type(_conditionID))
                --print("_conditionNum",_conditionNum,"=_conditionNumType=",type(_conditionNum))
                if _conditionType == 1 then
                    _iconSprite = self.csvData[tostring(_conditionID)]["icon"]
                    _nameSprite = self.csvData[tostring(_conditionID)]["name"]
                    _numCurr = self.mySolderData[tostring(_conditionID)][dataKeyNum]
                    _numMax = _conditionNum
                elseif _conditionType == 2 then
                    _iconSprite = self.packageCSV[tostring(_conditionID)]["iconName"]
                    _nameSprite = self.packageCSV[tostring(_conditionID)]["name"]
                     _numCurr = self.packageData[tostring(_conditionID)]
                     _numMax = _conditionNum
                end
                if _numCurr == nil then
                    _numCurr = 0
                end
                --print("_iconSprite=",_iconSprite)
                --print("_numCurr=",_numCurr,"_numMax=",_numMax)
                --icon
                local _conDitionIcon = nil
                if(_iconSprite == nil or _iconSprite == "") then
                    _conDitionIcon  = cc.MenuItemImage:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png")
                else
                    _conDitionIcon  = cc.MenuItemImage:create("Images/Icon/".._iconSprite, "Images/Icon/".._iconSprite)
                end
                local _indexX = _conditionDisW*((i+1)%2)
                local _indexY = _conditionDisH*math.floor((i-1)/2)

                -- 开始计算到底显示哪种窗
                -- type , 物品id，当前num，最大num
                local _resumeTable = self.packageCSV[tostring(_conditionID)]["resume"]
                local _have = false
                for k,v in pairs(_resumeTable) do
                    for k2,v2 in pairs(v) do
                        --print(k2,v2,"==22")
                        if v2 ~= nil and v2 ~= "" and tonumber(v2) > 0 then
                            _have = true
                            break
                        end
                    end
                end
                local iscandeal = 0
                print("_have==",_have)
                if _have then
                    iscandeal = 3
                    -- printn("可制造列表",self.makeData)
                    -- printn("物品id",tostring(_conditionID))
                    local _tuzhiID = self.packageCSV[tostring(_conditionID)]["store_connect"]--图纸
                    if _tuzhiID ~= nil and tonumber(_tuzhiID) > 0 and self.StoreUnlockData[tostring(_tuzhiID)] ~= nil then
                        -- 如果需要图纸，且图纸解锁了，提示购买图纸
                        iscandeal = 4
                    else
                        for i = 1, #self.makeData do
                            -- 判断是否已经解锁，解锁过了就不再处理了(这里必须要判断nil，因为有可能会删除一个)
                            if self.makeData[i] ~= nil then
                                if self.makeData[i][dataKeyID] == tostring(_conditionID) then
                                    iscandeal = 1
                                    break
                                end
                            end
                        end
                    end
                end
                _conDitionIcon:setPosition(cc.p(_conditionX+_indexX,_conditionY-_indexY))
                _conDitionIcon:setScale(0.8)
                _conDitionIcon:setTag(9528)
                _conDitionIcon:registerScriptTapHandler(function()
                    for i=1,#self.conditional[idx] do
                        if self.conditional[idx][i] == false then
                            local _showTip = cell:getChildByTag(self.goodsTag+i)
                            if _showTip ~= nil then
                                _showTip:setVisible(false)
                            end
                        end
                    end
                    if iscandeal == 1 then
                        -- 满足条件，弹出合成窗口
                        local _view = MaterialView:create(1,_conditionID,_numCurr,_numMax,self.StoreUnlockData,i,cell,idx)
                        _view:show()
                    elseif iscandeal == 4 then
                        -- 不满足条件
                        local _view = MaterialView:create(4,_nameSprite,0,0,0,0,0,0)
                        _view:show()
                    else
                        -- 不满足条件
                        local _view = MaterialView:create(3,_nameSprite,0,0,0,0,_conditionID,0)
                        _view:show()
                    end
                    if _numCurr == _numMax then
                        _conDitionIcon:removeChildByTag(9527)
                    end
                end)
                local menuIcon = cc.Menu:create(_conDitionIcon)
                menuIcon:setTag(self.buttonTag+i)
                menuIcon:setPosition(0.0, 0.0)
                cell:addChild(menuIcon, 1)

                -- 材料不足的时候，根据状态显示红绿加号
                if _numCurr < _numMax then
                    if iscandeal == 1 then
                        local addBtn = cc.Sprite:create("Images/UI/CanAdd.png")
                        addBtn:setPosition(cc.p(_conDitionIcon:getContentSize().width * 0.8, _conDitionIcon:getContentSize().height * 0.8))
                        _conDitionIcon:addChild(addBtn, 0, 9527)
                    else
                        local addBtn = cc.Sprite:create("Images/UI/CanNotAdd.png")
                        addBtn:setPosition(cc.p(_conDitionIcon:getContentSize().width * 0.8, _conDitionIcon:getContentSize().height * 0.8))
                        _conDitionIcon:addChild(addBtn, 0, 9527)
                    end
                end

                --name
                local _conditionFontSize = 24
                local _conditioncenterY = _conDitionIcon:getPositionY() -5

                local _conditionname = cc.LabelTTF:create(_nameSprite,BoldFont,_conditionFontSize+4);
                _conditionname:setPosition(cc.p(_conditionX+40+_indexX,_conDitionIcon:getPositionY()+(_conditionFontSize+4)/2))
                _conditionname:setColor(BaseColor)
                -- _conditionname:enableStroke(cc.c4b(255, 255, 255, 255), 1)
                _conditionname:setAnchorPoint(cc.p(0,0.5))
                _conditionname:setTag(self.nameTag+i)
                cell:addChild(_conditionname)
                --num
                local _numFont = cc.LabelTTF:create(_numCurr.."/".._numMax,BoldFont,_conditionFontSize);
                _numFont:setPosition(cc.p( _conditionname:getPositionX(), _conditionname:getPositionY()-_conditionname:getContentSize().height/2-10))
                if _numCurr >= _numMax then
                    _numFont:setColor(WriteColor)
                    menuIcon:setEnabled(false)
                else
                    _numFont:setColor(cc.c3b(255,0,0))
                end
                _numFont:setTag(self.fontTag+i)
                _numFont:setAnchorPoint(cc.p(0,0.5))
                cell:addChild(_numFont)
                --tip
                local _tipSprite = cc.Sprite:create("Images/UI/tishi_01.png")
                _tipSprite:setPosition(cc.p(_conDitionIcon:getPositionX(),_conDitionIcon:getPositionY()+40))
                _tipSprite:setVisible(false)
                _tipSprite:setTag(self.goodsTag+i)
                if _numCurr >= _numMax then
                   self.conditional[idx][i] = true
                else
                   self.conditional[idx][i] =false
                end
                cell:addChild(_tipSprite)

             end
         end
        --print("==end==")
        --bottom
        local _success = true
        for i=1,#self.conditional[idx] do
           if self.conditional[idx][i] == false then
                _success = false
                break;
           end 
        end
        local _menuButton = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        _menuButton:registerScriptTapHandler(function()
            -- 点击转职按钮
            _success = true
            for i=1,#self.conditional[idx] do
               if self.conditional[idx][i] == false then
                    _success = false
                    local _showTip = cell:getChildByTag(self.goodsTag+i)
                    if _showTip ~= nil then
                        _showTip:setVisible(true)
                        local _name = cell:getChildByTag(self.nameTag+i)
                        if _name ~= nil then
                            ToastUtil:toastString("需要先制造".._name:getString())
                        end
                    end
                    break;
               end 
            end
            if _success then
                self:close()
                --删除合成数据
                --local _tempPackageData = DataManager:getInstance():getRoleData(rolePack)
                local _tempConditionData = _soilder["produceResume"]
                if _tempConditionData ~= nil then
                    for i=1,#_tempConditionData do
                        local _conditionID = tonumber(_tempConditionData[i][2])
                        local _conditionNum = tonumber(_tempConditionData[i][3])
                        local _name = self.packageCSV[tostring(_conditionID)]["name"]
                        cclog("删除合成物品成功！ID=",_conditionID,"=name=",_name,"=个数=",_conditionNum)
                        DataManager:getInstance():addPackItemWithId(tostring(_conditionID), -1*tonumber(_conditionNum))
                         --if _tempPackageData[_conditionID] == nil then
                         --   _tempPackageData[_conditionID] = 0
                        -- end
                         --_tempPackageData[_conditionID] = _tempPackageData[_conditionID] - tonumber(_conditionNum)
                    end
                end
                --DataManager:getInstance():setRoleData(rolePack,_tempPackageData,nil)
             
                if TrainLayer.instance ~= nil then
                    TrainLayer.instance:changeJobCallBack(_soilder,Index)
                end
                self.packageData = DataManager:getInstance():getRoleData(rolePack)
            end
        end)
        _menuButton:setPosition(cc.p(0, 0))
        local menu = cc.Menu:create(_menuButton)
        menu:setTag(9529)
        menu:setPosition(cc.p(_backGround:getPositionX(),_backGround:getPositionY()-_backGround:getContentSize().height/2))
        cell:addChild(menu, 1)

        -- 如果可以转职，那么转职按钮点亮
        if _success then
            local btnLight = cc.Sprite:create("Images/btn/ChangeJobHL.png")
            btnLight:setPosition(menu:getPosition())
            btnLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(0.6), cc.EaseExponentialIn:create(cc.FadeIn:create(1.0)))))
            cell:addChild(btnLight)
        end

        local titleZZ = cc.LabelTTF:create("转 职",BoldFont,28)
        titleZZ:setPosition(menu:getPosition())
        titleZZ:setColor(WriteColor)
        -- titleZZ:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        cell:addChild(titleZZ, 1)

        --
        local _leftInfoDecor = cc.Sprite:create("Images/UI/InfoDecor.png")
        _leftInfoDecor:setPosition(cc.p(menu:getPositionX()-64,menu:getPositionY()))
        _leftInfoDecor:setAnchorPoint(cc.p(1,0.5))
        cell:addChild(_leftInfoDecor)
        local _rightInfoDecor = cc.Sprite:create("Images/UI/InfoDecor.png")
        _rightInfoDecor:setPosition(cc.p(menu:getPositionX()+64,menu:getPositionY()))
        _rightInfoDecor:setFlippedX(true)
        _rightInfoDecor:setAnchorPoint(cc.p(0,0.5))
        cell:addChild(_rightInfoDecor)

        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)
    self:addChild(self.tableview)
    self.tableview:reloadData()

    return true
end

function ChangeJobView:makeCallback(GoodsID,ShowNum,MaxNum,Index,Cell,CellIndex)
    local _success = false
    if ShowNum >= MaxNum then
        _success = true
    end
    if self.conditional[CellIndex] ~= nil and self.conditional[CellIndex][Index] ~= nil and _success then
        self.conditional[CellIndex][Index] = true
        print("===change true ====",Index)
    end
    local _numFont = Cell:getChildByTag(tonumber(self.fontTag+Index))
    if _numFont ~= nil then 
        if _success then _numFont:setColor(WriteColor) end
        
        _numFont:setString(ShowNum.."/"..ShowNum)
    end
    local _button = Cell:getChildByTag(tonumber(self.buttonTag+Index))
    if _button ~= nil and _success then
        _button:setEnabled(false)
        local item = _button:getChildByTag(9528)
        if item ~= nil then
            item:removeChildByTag(9527)
        end
    end
    -- 如果都搞定了，那么刷新下边转职按钮的高光
    local changeBtn = Cell:getChildByTag(9529)
    if changeBtn ~= nil then
        local allSuccess = true
        for i = 1, #self.conditional[CellIndex] do
           if self.conditional[CellIndex][i] == false then
                allSuccess = false
                break
           end
        end
        if allSuccess then
            local btnLight = cc.Sprite:create("Images/btn/ChangeJobHL.png")
            btnLight:setPosition(changeBtn:getPosition())
            btnLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(0.6), cc.EaseExponentialIn:create(cc.FadeIn:create(1.0)))))
            Cell:addChild(btnLight)
        end
    end
end

---=============================材料合成和获得=========================---------
MaterialView = class("MaterialView", function ()
    return DialogueView:create()
end)
MaterialView.__index = ChangeJobView
MaterialView.material = nil
MaterialView.type = 0 -- 1 材料合成 2 材料获得
MaterialView.data = nil
MaterialView.instance = nil
MaterialView.conditional = nil
MaterialView.goodsTag = 10001
MaterialView.buttonTag = 20001
MaterialView.fontTag = 30001
MaterialView.nameTag = 40001
-- create
function MaterialView:create(Type,Material,CurrNum,MaxNum,StoreUnlockData,Index,GoodsID,CellIndex)
    local view = MaterialView.new()
    if view and view:init(Type,Material,CurrNum,MaxNum,StoreUnlockData,Index,GoodsID,CellIndex) then
        return view
    end
    return nil
end

function MaterialView:init(Type,Material,CurrNum,MaxNum,StoreUnlockData,Index,GoodsID,CellIndex)
    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Sprite:create("Images/UI/tankuang_01.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)
    --title
    local title = nil
    if Type == 1 then
        title = cc.LabelTTF:create("材料合成",BoldFont,36)
    elseif Type == 2 then
        title = cc.LabelTTF:create("材料获得",BoldFont,36)
    elseif Type == 3 or Type == 4 then
        title = cc.LabelTTF:create("提 示",BoldFont,36)
    end
    title:setPosition(cc.p(bg:getPositionX(),bg:getPositionY()+bg:getContentSize().height/2-34))
    title:setColor(WriteColor)
    -- title:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    self:addChild(title)
    --dis
    -- local dis = cc.LabelTTF:create("请选择要转职的职业",BoldFont,22)
    -- dis:setPosition(cc.p(title:getPositionX(),title:getPositionY()-58))
    -- dis:setColor(WriteColor)
    -- dis:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    -- self:addChild(dis)
    -- btn
    local btn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
    btn:registerScriptTapHandler(function()
        self:close()
    end)
    btn:setPosition(cc.p(bg:getPositionX()+bg:getContentSize().width/2-40,title:getPositionY()))
    local menu = cc.Menu:create(btn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    self.type = Type

    self.packageCSV =  DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    self.packageData =  DataManager:getInstance():getRoleData(rolePack)


    if Type == 1 then
       --self:initMaterial()
       MaterialView.instance = self
       self.material = tostring(Material)
       self.data = self.packageCSV[self.material]
       --print("self.material=",self.material)
       --print("CurrNum=",CurrNum,"=MaxNum=",MaxNum)
       --icon
       local _iconPath = self.data["iconName"]
       local _iconSprite = nil
        if(_iconPath == nil or _iconPath == "") then
            _iconSprite  = cc.Sprite:create("Images/UI/tankuang_04.png")
        else
            _iconSprite  = cc.Sprite:create("Images/Icon/".._iconPath)
        end
        --_iconSprite:setScale(0.8)
        _iconSprite:setPosition(cc.p(title:getPositionX()-4,title:getPositionY()-85))
        _iconSprite:setAnchorPoint(cc.p(1,0.5))
        self:addChild(_iconSprite)
        local _fontSize = 26
        local _nameMaterial = cc.LabelTTF:create(self.data["name"],BoldFont,_fontSize)
        _nameMaterial:setPosition(cc.p(title:getPositionX()+4,_iconSprite:getPositionY()))
        _nameMaterial:setAnchorPoint(cc.p(0,0))
        _nameMaterial:setColor(BaseColor)
        self:addChild(_nameMaterial)
        local _numFont = cc.LabelTTF:create(CurrNum.."/"..MaxNum,BoldFont,_fontSize)
        _numFont:setAnchorPoint(cc.p(0,1))
        _numFont:setPosition(cc.p(_nameMaterial:getPositionX(),_iconSprite:getPositionY()))
        if CurrNum >= MaxNum then
            _numFont:setColor(WriteColor)
        else
            _numFont:setColor(cc.c3b(255,0,0))
        end
        self:addChild(_numFont)

        -- 
        local _hcFont = cc.LabelTTF:create("合成所需材料",BoldFont,_fontSize-4)
        _hcFont:setPosition(cc.p(title:getPositionX(),_iconSprite:getPositionY()-60))
        _hcFont:setColor(WriteColor)
        -- _hcFont:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_hcFont)
        local _hengSprite = cc.Sprite:create("Images/UI/hengt_01.png")
        _hengSprite:setPosition(cc.p(_hcFont:getPositionX()-_hcFont:getContentSize().width/2-30,_hcFont:getPositionY()))
        _hengSprite:setAnchorPoint(cc.p(1,0.5))
        _hengSprite:setFlippedX(true)
        self:addChild(_hengSprite)
        local _hengSpriteRight = cc.Sprite:create("Images/UI/hengt_01.png")
        _hengSpriteRight:setPosition(cc.p(_hcFont:getPositionX()+_hcFont:getContentSize().width/2+30,_hcFont:getPositionY()))
        _hengSpriteRight:setAnchorPoint(cc.p(0,0.5))
        self:addChild(_hengSpriteRight)


        --start  
        local _conditionX = bg:getPositionX() - bg:getContentSize().width/4 - 42
        local _conditionY = _hcFont:getPositionY() - 54
        local _conditionDisW = 264
        local _conditionDisH = 84
        local _conditionData = self.packageCSV[self.material]["resume"]
        self.conditional = {} --材料不足的indexTable
        --print("=_conditionDataSize=",#_conditionData)
         if _conditionData ~= nil then
             for i=1,#_conditionData do
                local _conditionID = tonumber(_conditionData[i][1])
                local _conditionNum = tonumber(_conditionData[i][2])
                if _conditionID == nil or _conditionNum == nil then
                    break;
                end
                local _iconSprite = nil--icon
                local _nameSprite = nil--name
                local _numCurr = 0 -- num
                local _numMax = 0 -- num
                --print("_conditionType=",_conditionType,"=_conditionType=",type(_conditionType))
                --print("_conditionID=",_conditionID,"=_conditionIDType=",type(_conditionID))
                --print("_conditionNum",_conditionNum,"=_conditionNumType=",type(_conditionNum))
                _iconSprite = self.packageCSV[tostring(_conditionID)]["iconName"]
                _nameSprite = self.packageCSV[tostring(_conditionID)]["name"]
                _numCurr = self.packageData[tostring(_conditionID)]
                _numMax = _conditionNum
                if _numCurr == nil then
                    _numCurr = 0
                end
                --print("_iconSprite=",_iconSprite)
                --print("_numCurr=",_numCurr,"_numMax=",_numMax)
                --icon
                local _conDitionIcon = nil
                if(_iconSprite == nil or _iconSprite == "") then
                    _conDitionIcon  = cc.MenuItemImage:create("Images/UI/tankuang_04.png", "Images/UI/tankuang_04.png")
                else
                    _conDitionIcon  = cc.MenuItemImage:create("Images/Icon/".._iconSprite, "Images/Icon/".._iconSprite)
                end

                local _indexX = _conditionDisW*((i+1)%2)
                local _indexY = _conditionDisH*math.floor((i-1)/2)

                local iscandeal = 0
                --ToastUtil:toastString("材料合成")
                cclog("_numMax=",_numMax,"=_numCurr=",_numCurr)
                cclog("StoreUnlockData[tostring(_conditionID)",StoreUnlockData[tostring(_conditionID)])
                local _view = nil
                if StoreUnlockData ~= nil and StoreUnlockData[tostring(_conditionID)] ~= nil then
                    --_type ，name ，缺少个数，花费金币，
                    iscandeal = 1
                else
                    iscandeal = 3
                end

                _conDitionIcon:setPosition(cc.p(_conditionX+_indexX,_conditionY-_indexY))
                _conDitionIcon:setScale(0.8)
                _conDitionIcon:setTag(9528)
                _conDitionIcon:registerScriptTapHandler(function()

                    for i=1,#self.conditional do
                        if self.conditional[i] == false then
                            local _showTip = self:getChildByTag(tonumber(self.goodsTag+i))
                            if _showTip ~= nil then
                                _showTip:setVisible(false)
                            end
                        end
                    end
                    --ToastUtil:toastString("材料合成")
                    cclog("_numMax=",_numMax,"=_numCurr=",_numCurr)
                    cclog("StoreUnlockData[tostring(_conditionID)",StoreUnlockData[tostring(_conditionID)])
                    local _view = nil
                    if StoreUnlockData ~= nil and StoreUnlockData[tostring(_conditionID)] ~= nil then
                        --_type ，name ，缺少个数，花费金币，
                        local _price = (_numMax-_numCurr)*tonumber(StoreUnlockData[tostring(_conditionID)])
                        _view = MaterialView:create(2,_nameSprite,_numMax-_numCurr,_price,_numMax,i,_conditionID,0)--满足条件
                    else
                        _view = MaterialView:create(3,_nameSprite,0,0,0,0,_conditionID,0)--不满足条件
                    end
                   _view:show()

                end)
                local menuIcon = cc.Menu:create(_conDitionIcon)
                menuIcon:setTag(self.buttonTag+i)
                menuIcon:setPosition(0.0, 0.0)
                self:addChild(menuIcon, 1)

                -- 材料不足的时候，根据状态显示红绿加号
                if _numCurr < _numMax then
                    if iscandeal == 1 then
                        local addBtn = cc.Sprite:create("Images/UI/CanAdd.png")
                        addBtn:setPosition(cc.p(_conDitionIcon:getContentSize().width * 0.8, _conDitionIcon:getContentSize().height * 0.8))
                        _conDitionIcon:addChild(addBtn, 0, 9527)
                    else
                        local addBtn = cc.Sprite:create("Images/UI/CanNotAdd.png")
                        addBtn:setPosition(cc.p(_conDitionIcon:getContentSize().width * 0.8, _conDitionIcon:getContentSize().height * 0.8))
                        _conDitionIcon:addChild(addBtn, 0, 9527)
                    end
                end

                --name
                local _conditionFontSize = 24
                local _conditioncenterY = _conDitionIcon:getPositionY() -5

                local _conditionname = cc.LabelTTF:create(_nameSprite,BoldFont,_conditionFontSize+4);
                _conditionname:setPosition(cc.p(bg:getPositionX() - bg:getContentSize().width/4 +_indexX,_conDitionIcon:getPositionY()+(_conditionFontSize+4)/2))
                _conditionname:setColor(BaseColor)
                -- _conditionname:enableStroke(cc.c4b(255, 255, 255, 255), 1)
                _conditionname:setAnchorPoint(cc.p(0,0.5))
                _conditionname:setTag(self.nameTag+i)
                self:addChild(_conditionname)
                --num
                local _numFont = cc.LabelTTF:create(_numCurr.."/".._numMax,BoldFont,_conditionFontSize);
                _numFont:setPosition(cc.p( _conditionname:getPositionX(), _conditionname:getPositionY()-_conditionname:getContentSize().height/2-10))
                if _numCurr >= _numMax then
                    _numFont:setColor(WriteColor)
                    menuIcon:setEnabled(false)
                else
                    _numFont:setColor(cc.c3b(255,0,0))
                end
                _numFont:setTag(self.fontTag+i)
                _numFont:setAnchorPoint(cc.p(0,0.5))
                self:addChild(_numFont)

                --tip
                local _tipSprite = cc.Sprite:create("Images/UI/tishi_01.png")
                _tipSprite:setPosition(cc.p(_conDitionIcon:getPositionX(),_conDitionIcon:getPositionY()+40))
                _tipSprite:setVisible(false)
                _tipSprite:setTag(self.goodsTag+i)
                if _numCurr >= _numMax then
                   self.conditional[i] = true
                else
                   self.conditional[i] =false
                end
                self:addChild(_tipSprite)

             end
         end

        --end
        local _cannelButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
        _cannelButton:setPosition(cc.p(bg:getPositionX()-130,bg:getPositionY()-bg:getContentSize().height/2+50))
        _cannelButton:registerScriptTapHandler(function()
            self:close()

        end)

        local _sureButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
        _sureButton:setPosition(cc.p(bg:getPositionX()+130,_cannelButton:getPositionY()))
        _sureButton:registerScriptTapHandler(function()

            local _success = true
            for i=1,#self.conditional do
               if self.conditional[i] == false then
                    _success = false
                    local _showTip = self:getChildByTag(tonumber(self.goodsTag+i))
                    if _showTip ~= nil then
                        _showTip:setVisible(true)
                        local _name = self:getChildByTag(self.nameTag+i)
                        if _name ~= nil then
                            ToastUtil:toastString("需要先制造".._name:getString())
                        end
                    end
                    break;
               end 
            end
            if _success then--合成功
                self:close()
                local _tempPackageData = DataManager:getInstance():getRoleData(rolePack)
                ToastUtil:toastString("制造成功！"..self.data["name"].."+1")
                --if _tempPackageData[self.material] == nil then
                --    _tempPackageData[self.material] = 0
                --end
                --_tempPackageData[self.material] = _tempPackageData[self.material] + 1
                DataManager:getInstance():addPackItemWithId(self.material, 1)
                --print("制造成功！ name=",self.data["name"],"个数=", 1)
                --删除合成的材料
                local _tempCondition = self.packageCSV[self.material]["resume"]
                if _tempCondition ~= nil then
                    for i=1,#_tempCondition do
                        local _conditionID = tonumber(_tempCondition[i][1])
                        local _conditionNum = tonumber(_tempCondition[i][2])
                        local _nameSprite = self.packageCSV[tostring(_conditionID)]["name"]
                         print("删除合成材料成功！ID=",_conditionID,"=name=",_nameSprite,"个数=",_conditionNum)
                         --if _tempPackageData[_conditionID] == nil then
                          --  _tempPackageData[_conditionID] = 0
                         --end
                         --_tempPackageData[_conditionID] = _tempPackageData[_conditionID] - tonumber(_conditionNum)
                         DataManager:getInstance():addPackItemWithId(tostring(_conditionID), -1*tonumber(_conditionNum))
                    end
                end
                --DataManager:getInstance():setRoleData(rolePack,_tempPackageData,nil)
                if ChangeJobView.instance ~= nil then
                    ChangeJobView.instance:makeCallback(self.material,CurrNum+1,MaxNum,Index,GoodsID,CellIndex)
                end
                self.packageData =  DataManager:getInstance():getRoleData(rolePack)
            end

        end)

        local menuIcon = cc.Menu:create(_cannelButton,_sureButton)
        menuIcon:setPosition(0.0, 0.0)
        self:addChild(menuIcon, 1)

        local okButtonLabel = cc.LabelTTF:create("合 成", BoldFont, 32.0)
        -- okButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        okButtonLabel:setColor(cc.c3b(255,255,255))
        okButtonLabel:setPosition(_sureButton:getPosition())
        self:addChild(okButtonLabel, 1)

        local cancelButtonLabel = cc.LabelTTF:create("取 消", BoldFont, 32.0)
        -- cancelButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        cancelButtonLabel:setColor(cc.c3b(255,255,255))
        cancelButtonLabel:setPosition(_cannelButton:getPosition())
        self:addChild(cancelButtonLabel)

    elseif Type == 2 then
        --self:initMaterialGet()
        local _fontSize = 26
        local _title1 = cc.LabelTTF:create("当前缺少"..CurrNum.."个"..Material,BoldFont,_fontSize)
        _title1:setPosition(cc.p(title:getPositionX(),title:getPositionY()-62))
        _title1:setColor(WriteColor)
        -- _title1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title1)
        local _title2 = cc.LabelTTF:create("您可以通过以下方式获得",BoldFont,_fontSize+2)
        _title2:setPosition(cc.p(title:getPositionX(),_title1:getPositionY()-40))
        _title2:setColor(WriteColor)
        -- _title2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title2)

        local _back1 = cc.Sprite:create("Images/UI/dibantiao_03.png")
        _back1:setPosition(cc.p(_title2:getPositionX(),_title2:getPositionY()-99))
        self:addChild(_back1)
        --
        local _back1Font1 = cc.LabelTTF:create("购买"..CurrNum.."个"..Material,BoldFont,_fontSize)
        _back1Font1:setAnchorPoint(cc.p(0,0))
        _back1Font1:setColor(WriteColor)
        -- _back1Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _back1Font1:setPosition(cc.p(_back1:getPositionX()-_back1:getContentSize().width/2+22,_back1:getPositionY()+6))
        self:addChild(_back1Font1)
        local _back1Font2 = cc.LabelTTF:create("花费"..MaxNum.."金币",BoldFont,_fontSize)
        _back1Font2:setAnchorPoint(cc.p(0,1))
        _back1Font2:setColor(WriteColor)
        -- _back1Font2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _back1Font2:setPosition(cc.p(_back1Font1:getPositionX(),_back1:getPositionY()-6))
        self:addChild(_back1Font2)
        local _back2 = cc.Sprite:create("Images/UI/dibantiao_03.png")
        _back2:setPosition(cc.p(_title2:getPositionX(),_back1:getPositionY()-120))
        self:addChild(_back2)
        local _back2Font1 = cc.LabelTTF:create("生产：需花费一些时间",BoldFont,_fontSize)
        _back2Font1:setAnchorPoint(cc.p(0,0.5))
        _back2Font1:setColor(WriteColor)
        -- _back2Font1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _back2Font1:setPosition(cc.p(_back1Font1:getPositionX(),_back2:getPositionY()))
        self:addChild(_back2Font1)

        --button
        local _buyButton = cc.MenuItemImage:create("Images/btn/ann01_a.png","Images/btn/ann01_b.png")
        _buyButton:setPosition(cc.p(_back1:getPositionX()+_back1:getContentSize().width/2-90,_back1:getPositionY()))
        _buyButton:registerScriptTapHandler(function()
            --购买
            self:close()
            local _result = 0
            local _defGoil = 0
             _result ,_defGoil= DataManager:getInstance():addCoin(-1 * tonumber(MaxNum))
            if _result == 0 then
                 ToastUtil:toastString("缺少金币".."X".._defGoil)
             else
                ToastUtil:toastString("购买成功！"..Material.."+"..tonumber(MaxNum))
                --存购买的物品
                --if self.packageData[tostring(GoodsID)] == nil then
                --    self.packageData[tostring(GoodsID)] = 0
                --end
                --self.packageData[tostring(GoodsID)] = self.packageData[tostring(GoodsID)] + tonumber(MaxNum)
                --DataManager:getInstance():setRoleData(rolePack,self.packageData,nil)
                DataManager:getInstance():addPackItemWithId(tostring(GoodsID), tonumber(CurrNum))
                print("存购买的物品 name=",Material,"个数=", tonumber(CurrNum))
                if MaterialView.instance ~= nil then
                    MaterialView.instance:buyCallback(GoodsID,StoreUnlockData,Index)
                end
            end

        end)

        local _produceButton = cc.MenuItemImage:create("Images/btn/ann01_a.png","Images/btn/ann01_b.png")
        _produceButton:setPosition(cc.p(_buyButton:getPositionX(),_back2:getPositionY()))
        _produceButton:registerScriptTapHandler(function()
            --生产
            --关闭所有窗口
            --self:close()
            DialogueViewManager:sharedInstance():removeAllView()
            zqDispatch:moveToResource()
        end)

        local menuIcon = cc.Menu:create(_buyButton,_produceButton)
        menuIcon:setPosition(0.0, 0.0)
        self:addChild(menuIcon)

        local _buyLabel = cc.LabelTTF:create("购 买", BoldFont, 32.0)
        -- _buyLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        _buyLabel:setColor(cc.c3b(255,255,255))
        _buyLabel:setPosition(_buyButton:getPosition())
        self:addChild(_buyLabel)

        local _produceButtonLabel = cc.LabelTTF:create("生 产", BoldFont, 32.0)
        -- _produceButtonLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        _produceButtonLabel:setColor(cc.c3b(255,255,255))
        _produceButtonLabel:setPosition(_produceButton:getPosition())
        self:addChild(_produceButtonLabel)
    elseif Type == 3 then
        local _fontSize = 30
        local _title1 = cc.LabelTTF:create("您当前还无法获得"..Material,BoldFont,_fontSize)
        _title1:setPosition(cc.p(title:getPositionX(),bg:getPositionY()+40))
        _title1:setColor(WriteColor)
        -- _title1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title1)
        print("GoodsID:", GoodsID)
        local _title2 = cc.LabelTTF:create(self.packageCSV[tostring(GoodsID)]["obtain"],BoldFont,_fontSize)
        _title2:setPosition(cc.p(_title1:getPositionX(),bg:getPositionY()-17))
        _title2:setColor(WriteColor)
        -- _title2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title2)
        local _goButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
        _goButton:setPosition(cc.p(title:getPositionX(),bg:getPositionY()-bg:getContentSize().height/2+74))
        _goButton:registerScriptTapHandler(function()
            --前往探索
            --self:close()
            DialogueViewManager:sharedInstance():removeAllView()
            zqDispatch:moveToExpedition()
        end)
        local menuIcon = cc.Menu:create(_goButton)
        menuIcon:setPosition(0.0, 0.0)
        self:addChild(menuIcon)
        local goLabel = cc.LabelTTF:create("出征探索", BoldFont, 32.0)
        -- goLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        goLabel:setColor(cc.c3b(255,255,255))
        goLabel:setPosition(_goButton:getPosition())
        self:addChild(goLabel)
    elseif Type == 4 then
        local _fontSize = 30
        local _title1 = cc.LabelTTF:create("您当前还无法制造"..Material,BoldFont,_fontSize)
        _title1:setPosition(cc.p(title:getPositionX(),bg:getPositionY()+40))
        _title1:setColor(WriteColor)
        -- _title1:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title1)
        local _title2 = cc.LabelTTF:create("可以在市场中购买图纸解锁",BoldFont,_fontSize)
        _title2:setPosition(cc.p(_title1:getPositionX(),bg:getPositionY()-17))
        _title2:setColor(WriteColor)
        -- _title2:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        self:addChild(_title2)
        local _goButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png")
        _goButton:setPosition(cc.p(title:getPositionX(),bg:getPositionY()-bg:getContentSize().height/2+74))
        _goButton:registerScriptTapHandler(function()
            --前往探索
            --self:close()
            DialogueViewManager:sharedInstance():removeAllView()
            zqDispatch:gotoStore(true)
        end)
        local menuIcon = cc.Menu:create(_goButton)
        menuIcon:setPosition(0.0, 0.0)
        self:addChild(menuIcon)
        local goLabel = cc.LabelTTF:create("前往市场", BoldFont, 32.0)
        -- goLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        goLabel:setColor(cc.c3b(255,255,255))
        goLabel:setPosition(_goButton:getPosition())
        self:addChild(goLabel)

    end

    return true
end

function MaterialView:buyCallback(GoodsID,ShowNum,Index)
    if self.conditional ~= nil and self.conditional[Index] ~= nil then
        self.conditional[Index] = true
    end
    local _numFont = self:getChildByTag(tonumber(self.fontTag+Index))
    if _numFont ~= nil then 
        _numFont:setColor(WriteColor)
        _numFont:setString(ShowNum.."/"..ShowNum)
    end
    local _button = self:getChildByTag(tonumber(self.buttonTag+Index))
    if _button ~= nil then
        _button:setEnabled(false)
        local item = _button:getChildByTag(9528)
        if item ~= nil then
            item:removeChildByTag(9527)
        end
    end
end

