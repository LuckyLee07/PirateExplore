require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"


ExpeditionLayer = class("ExpeditionLayer", function ()
    return BaseView:create()
end)

ExpeditionLayer.__index = ExpeditionLayer
ExpeditionLayer.scrollView = nil
ExpeditionLayer.scrollViewContainer = nil
ExpeditionLayer.topMaskLabel = nil
ExpeditionLayer.bottomMaskLabel = nil
ExpeditionLayer.boatNum = 0
ExpeditionLayer.soldierNum = 0
ExpeditionLayer.useBoatNum = 0
ExpeditionLayer.useSoldierNum = 0
ExpeditionLayer.expeditionData = {}
ExpeditionLayer.selectedData = {}
ExpeditionLayer.produceCsv = nil
ExpeditionLayer.lastUpdateMd5 = nil

function ExpeditionLayer:create()
    local view = ExpeditionLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function ExpeditionLayer:destory()
    -- body
    DataManager:getInstance():unregisterEvent("breadBirth", "expedition")
    DataManager:getInstance():unregisterEvent(roleGuideStep, "expedition")
    -- 调用父类的析构
    self:superDestory()
end

function ExpeditionLayer:init()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    self.boatNum = DataManager:getInstance():getRoleData(rolePackSize)
    self.soldierNum = DataManager:getInstance():getRoleData(roleCabinSize)
    self.produceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

    -- 设置title文字
    self.titleLabel:setString("船 坞")

    -- 设置背景Icon
    self:setBackgroundIcon("Images/Background/yuanz.png")

    -- 修改顶部左侧按钮显示
    self.topLeftBtn:setVisible(true)

    -- 修改顶部右侧按钮为排行榜
    self:resetTopRightButtonToRank()

    -- 设置下方信息界面
    self:addInfoNode("天 赋", function()
        zqDispatch:gotoTalent()
    end, "仓 库", function()
        zqDispatch:moveToRepository()
    end, "Images/MainMenu/an_yuanz_a.png", "Images/MainMenu/an_yuanz_b.png", function()
        cclog("点击了出征按钮")
        -- 先保存临时背包以及战斗单位数据
        local packData = {}
        local battleData = {}
        local teamNum = 0
        local breadNum = 0
        -- 优先判断数量是否充足，不足的话弹窗提示（这里如果不先判断的话会导致数量扣减之后的各种bug）
        for k, v in pairs(self.selectedData) do
            print("出征携带的数据", k, v)
            if tonumber(k) >= 10000 then
                -- 战斗数据
                if v > 0 then
                    -- 记录带的兵的数量
                    teamNum = teamNum + 1
                end
            else
                -- 背包数据
                if v > 0 and k == "1005" then
                    -- 如果是面包，那么记录面包数量
                    breadNum = breadNum + 1
                end
            end
        end
        if breadNum <= 0 then
            ToastUtil:downString("必须携带充足食物才能出航",true)
            return
        end
        if teamNum <= 0 then
            local soildierInfoString = "您需要招募一些士兵才能出征"
            if not GuideController:getInstance():getIsHaveStep(9) then
                -- 木有建造训练营时候的情况
                soildierInfoString = "您需建造训练营来招募士兵"
            else
                -- 建造了训练营之后又有兵的情况
                local soildierData = DataManager:getInstance():getRoleData(roleSoildierQueue)
                for k,v in pairs(soildierData) do
                    if soildierData[k] ~= nil then
                        soildierInfoString = "您需在上方点击‘+’来分配出征士兵"
                        break
                    end
                end
            end
            ToastUtil:downString(soildierInfoString, true)
            return
        end
        -- 都满足才能扣除
        for k, v in pairs(self.selectedData) do
            print("正在处理的数据", k, v)
            if tonumber(k) >= 10000 then
                -- 战斗数据
                print("战斗数据：", k, v)
                if v > 0 then
                    battleData[(tonumber(k) - 10000) .. ""] = v
                    -- 从兵库中减去兵种数量
                    DataManager:getInstance():addSoilderWithId((tonumber(k) - 10000) .. "", -v)
                end
            else
                -- 背包数据
                -- print("背包数据：", k, v)
                if v > 0 then
                    packData[k] = {}
                    packData[k].id = k
                    packData[k].num = v
                    -- 从背包中减去道具数量
                    DataManager:getInstance():addPackItemWithId(k .. "", -v)
                end
            end
        end
        --print("战斗兵将数据：", tableToJson(battleData))
        -- 存档
        DataManager:getInstance():setRoleData(roleBattleQueue, battleData)
        DataManager:getInstance():setRoleData(roleBattlePack, packData)
        -- 清理掉之前选中的数据
        self.selectedData = {}
        DataManager:getInstance():setRoleData(roleSelectUnit, self.selectedData, nil)
        -- 最后切换到地图界面
        zqDispatch:moveToFightLayer()
    end, "Images/MainMenu/w_qih.png")

    self.setBtnLight:setVisible(true)

    -- 添加工匠配置底框
    -- local tempSpr = cc.Sprite:create("Images/UI/MaskBg.png")
    maskSize = cc.size(self.areaWidth, self.areaHeight)
    -- local topMask = cc.Scale9Sprite:create("Images/UI/MaskBg.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    -- topMask:setContentSize(maskSize)
    -- topMask:setPosition(self.centerPos)
    -- self:addChild(topMask)

    -- 添加底部资源框的标题
    local topMaskTitleBg = cc.Sprite:create("Images/UI/biaoti_long.png")
    topMaskTitleBg:setPosition(cc.p(self.centerPos.x, self.originPos.y + maskSize.height - topMaskTitleBg:getContentSize().height * 0.5))
    self:addChild(topMaskTitleBg)

    -- 添加底部资源框的title
    self.topMaskLabel = cc.LabelTTF:create("货舱:(15/45) 成员:(15/45)", BoldFont, 28.0)
    self.topMaskLabel:setPosition(topMaskTitleBg:getPosition())
    self.topMaskLabel:setColor(cc.c3b(255, 255, 255))
    -- self.topMaskLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self:addChild(self.topMaskLabel)

    -- 添加资源获取界面的scrollView
    self.scrollViewContainer = cc.Layer:create()
    scrollViewSize = cc.size(maskSize.width, maskSize.height - topMaskTitleBg:getContentSize().height)
    self.scrollViewContainer:setContentSize(scrollViewSize)
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(self.originPos)
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollView:setViewSize(scrollViewSize)
    self.scrollView.bIsScrollView = true
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.scrollView:setDelegate()
    self.scrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self:addChild(self.scrollView)

    DataManager:getInstance():registerEvent("breadBirth", "expedition", function()
        -- cclog("由于产生了面包，所以刷新出征界面面包数据")
        -- 必须重新刷新数据，要不然不会增加
        self:setResourceUIWithData()
    end)

    DataManager:getInstance():registerEvent(roleGuideStep, "expedition", function()
        -- 控制成就红点
        if GuideController:getInstance():getIsHaveStep(402, true) then
            GuideController:getInstance():removeRedPoint(self.topLeftBtn)
        else
            GuideController:getInstance():addRedPoint(self.topLeftBtn)
        end
    end)

    -- 首次进入出征界面，给玩家增加100个食物和1个初级水手
    if not GuideController:getInstance():getIsHaveStep(30, true) then
        -- 确实建设完船坞之后根据新手引导要求，要给玩家船员*1，食物*100
        DataManager:getInstance():addPackItemWithId("1005", 100)
        DataManager:getInstance():addSoilderWithId("100", 1)
        -- 然后push系统信息到系统提示中去
        DataManager:getInstance():sendSystemInfo("有一名船员携带100份食物慕名而来！\n必须有船员携带食物才能出征！\n您可以在采集界面制造食物！\n您可以建造训练营后，招募船员！")
        -- 然后弹窗提示玩家获得的东西
        local _alert = AlertView:create(1, 0, "提  示", nil, nil, "确 定")
        -- print("_alert inited")
        local showLabel1 = cc.LabelTTF:create("恭喜您建好船坞，现在可以出征了！\n恭喜您获得船员×1，食物×100", BoldFont, 30)
        showLabel1:setColor(cc.c3b(255, 255, 255))
        showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y))
        _alert:addChild(showLabel1)

        -- 最后添加这一步新手引导
        GuideController:getInstance():addStep(30, true)
    end

    -- 进入出征界面之后，清理掉首次解锁出征时候的小手引导
    GuideController:getInstance():addStep(105, true)

    -- 进入的时候刷新船员数据
    -- cclog("由于兵种信息变更，所以刷新出征界面兵种数据")

    -- 然后刷新UI界面
    self:setResourceUIWithData()

    return true
end

function ExpeditionLayer:resetUI()
    cclog("刷新出征界面的UI")
    
    local jsons = json.encode(DataManager:getInstance():getRoleData(rolePack))
    local jsons2 = json.encode(DataManager:getInstance():getRoleData(roleSoildierQueue))
    local jsonMd5 = MD5(jsons, string.len(jsons)):hexdigest() .. MD5(jsons2, string.len(jsons2)):hexdigest()
    -- 如果数据没变还刷新鸡毛啊。。。
    -- print("last:%s, now:%s", self.lastUpdateMd5, jsonMd5)
    if self.lastUpdateMd5 == nil or self.lastUpdateMd5 ~= jsonMd5 then
        self:setResourceUIWithData()
        self.lastUpdateMd5 = jsonMd5
    end
end

function ExpeditionLayer:setResourceUIWithData()
    -- 拼合可用的士兵数据和背包数据
    self.boatNum = DataManager:getInstance():getRoleData(rolePackSize)
    self.soldierNum = DataManager:getInstance():getRoleData(roleCabinSize)
    local packData = DataManager:getInstance():getRoleData(rolePack)
    local soildierData = DataManager:getInstance():getRoleData(roleSoildierQueue)
    local skillCsv = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
    local soildierCsv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    local buffCsv = DataManager:getInstance():getCSVByID(csvOfBuff)
    -- 重新拼合背包数据
    self.selectedData = DataManager:getInstance():getRoleData(roleSelectUnit)
    -- print("selectedData:", tableToJson(self.selectedData))
    self.expeditionData = {}
    local dataNum = 0
    for k,v in pairs(packData) do
        -- print(k, v)
        local csvData = self.produceCsv[tostring(k)]
        if csvData ~= nil then
            -- 如果可以出征携带并且数量大于0，那么加入数据
            if tonumber(csvData["carryType"]) == 1 and v > 0 then
                table.insert(self.expeditionData, {[dataKeyID] = k, [dataKeyNum] = v, ["name"] = csvData["name"], ["desc"] = csvData["desc"], ["cubage"] = csvData["cubage"], ["star"] = csvData["starNum"]})
                dataNum = dataNum + 1
            end
        end
    end
    for k,v in pairs(soildierData) do
        -- print(k, v)
        local csvData = soildierCsv[tostring(k)]
        if csvData ~= nil and v[dataKeyNum] > 0 then
            table.insert(self.expeditionData, {[dataKeyID] = (tonumber(k) + 10000) .. "", [dataKeyNum] = v[dataKeyNum], ["name"] = csvData["name"], ["skill"] = csvData["skill"], ["hp"] = csvData["hp"], ["attack"] = csvData["attack"], ["speed"] = csvData["speed"], ["star"] = csvData["star"]})
            dataNum = dataNum + 1
        end
    end
    -- 重新排序
    -- for k,v in pairs(table_name) do
        
    -- end
    -- 临时计算高度用的图
    local tempSpr = cc.Sprite:create("Images/btn/ann01_a.png")
    local singleHeight = tempSpr:getContentSize().height + 14
    local allHeight = singleHeight * dataNum
    if allHeight < self.scrollView:getViewSize().height then
        allHeight = self.scrollView:getViewSize().height
    end
    -- 重新设置数量的函数
    local function resetQueueData(bIsNeedSave)
        self.topMaskLabel:setString("货舱：(" .. self.useBoatNum .. "/" .. self.boatNum .. ") 成员：(" .. self.useSoldierNum .. "/" .. self.soldierNum .. ")")
        if bIsNeedSave then
            -- 调用存档方法，记录出征选择数据，这里如果点了出征，那么就直接清理为空
            -- print("存档时的selectedData:", tableToJson(self.selectedData))
            DataManager:getInstance():setRoleData(roleSelectUnit, self.selectedData, nil)
        end
    end
    -- 清理掉之前界面上的所有东西
    self.scrollViewContainer:removeAllChildren()
    self.useBoatNum = 0
    self.useSoldierNum = 0
    -- 开始画界面
    local tempNode = nil
    local name = nil
    local desc
    for i = 1, #self.expeditionData do
        local num = 0
        local itemNum = 0
        local needNum = 1
        -- 这些变量表给我挪走，我不傻，写外边会因为是局部全局变量出bug的，不信你试试
        local bagType = 0
        local starNum = 0
        local infoString = nil
        local v = self.expeditionData[i]
        local k = v[dataKeyID]
        -- print("key值：", k)
        if tonumber(k) < 10000 then
            -- 取出占用格子数
            if v["cubage"] ~= nil and v["cubage"] ~= "" then
                needNum = tonumber(v["cubage"])
            end
            -- 写入常用值
            num = v[dataKeyNum]
            name = v["name"]
            desc = v["desc"]
            starNum = v["star"]
            bagType = 0
            infoString = name.."\n"..tostring(desc).."\n占用货舱格数："..needNum
        else
            -- 说明是兵将
            num = v[dataKeyNum]
            name = v["name"]
            starNum = v["star"]
            local skillData = skillCsv[v["skill"]]
            local buff = skillData["buffID"]
            local buffDesc = "无"
            -- print("buff is：", buff)
            if buff ~= "0" then
                buffDesc = buffCsv[buff]["description"]
            end
            infoString = name.."整装待发\n技能："..skillData["name"].."\n技能效果："..buffDesc.."\n生命："..v["hp"].." 威力："..v["attack"].." 速度："..v["speed"]
            bagType = 1
        end
        -- 如果之前的存储里边存在数据，那么更新它
        if self.selectedData[k] ~= nil then
            itemNum = self.selectedData[k]
            -- 如果曾经有数据，那么证明之前选择过，重新设置剩余数量以及使用数量
            local useNum = itemNum * needNum
            num = num - itemNum
            if bagType == 0 then
                self.useBoatNum = self.useBoatNum + useNum
            elseif bagType == 1 then
                self.useSoldierNum = self.useSoldierNum + useNum
            end
        end
        -- 根据数据结果，开始画界面
        tempNode = cc.Node:create()
        tempNode:setPosition(cc.p(self.scrollView:getContentSize().width * 0.5, allHeight - singleHeight * (i - 1) - singleHeight * 0.5))
        self.scrollViewContainer:addChild(tempNode)

        -- 首先添加文字框
        local numberBox = cc.Sprite:create("Images/UI/NumberBox.png")
        numberBox:setPosition(cc.p(0, 0))
        tempNode:addChild(numberBox)

        -- 添加健文字框中间的数字label
        local numberLabel = cc.LabelTTF:create(itemNum .. "", BoldFont, 24.0)
        numberLabel:setColor(WriteColor)
        -- numberLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        numberLabel:setPosition(numberBox:getPosition())
        tempNode:addChild(numberLabel)

        -- 定义数字按钮上的label
        local numLable = cc.LabelTTF:create("1", BoldFont, 24.0)

        local function setNumLabel(intNum)
            -- 开始设置数量文本
            if numLable ~= nil and intNum >= 0 then
                if intNum > 9 then
                    numLable:setString("N")
                else
                    numLable:setString(intNum.."")
                end
            end
        end
        -- 优先设置一次数量
        setNumLabel(num)

        -- 然后添加左右加减按钮
        local function subButtonDidClick()
            -- cclog("点击减少按钮", i)
            local val = tonumber(numberLabel:getString())
            if val >= needNum then
                numberLabel:setString((val - 1) .. "")
                if bagType == 0 then
                    -- 背包数据
                    self.useBoatNum = self.useBoatNum - needNum
                    num = num + 1
                elseif bagType == 1 then
                    -- 兵将数据
                    self.useSoldierNum = self.useSoldierNum - needNum
                    num = num + 1
                end
                -- 修改剩余数量文本
                setNumLabel(num)
                -- 修改原始数据
                self.selectedData[k] = val - 1
                -- 刷新显示
                resetQueueData(true)
            end
        end

        local subBtn = SDButton:create("Images/UI/SubCircleBtn.png", "Images/UI/SubCircleBtn1.png", subButtonDidClick)
        subBtn:registerLongPressed(subButtonDidClick)
        subBtn:setPosition(cc.p(numberBox:getPositionX() - numberBox:getContentSize().width * 0.6 - subBtn:getContentSize().width * 0.5, 0))
        tempNode:addChild(subBtn)

        local function addButtonDidClick()
            -- cclog("点击增加按钮", i)
            local val = tonumber(numberLabel:getString())
            if bagType == 0 then
                -- 背包数据
                if (self.boatNum - self.useBoatNum) >= needNum and num > 0 then
                    numberLabel:setString((val + 1) .. "")
                    self.useBoatNum = self.useBoatNum + needNum
                    num = num - 1
                    -- 修改原始数据
                    self.selectedData[k] = val + 1
                    -- 刷新显示
                    resetQueueData(true)
                    -- 修改剩余数量文本
                    setNumLabel(num)
                else
                    ToastUtil:downString("该物品数量不足或已达上限", true)
                end
            elseif bagType == 1 then
                cclog("需要数量", needNum)
                if (self.soldierNum - self.useSoldierNum) >= needNum and num > 0 then
                    numberLabel:setString((val + 1) .. "")
                    self.useSoldierNum = self.useSoldierNum + needNum
                    num = num - 1
                    -- 修改原始数据
                    self.selectedData[k] = val + 1
                    -- 刷新显示
                    resetQueueData(true)
                    -- 修改剩余数量文本
                    setNumLabel(num)
                else
                    ToastUtil:downString("成员数量不足或可携带成员已满", true)
                end
            end
        end
        local addBtn = SDButton:create("Images/UI/AddCircleBtn.png", "Images/UI/AddCircleBtn1.png", addButtonDidClick)
        addBtn:registerLongPressed(addButtonDidClick)
        addBtn:setPosition(cc.p(numberBox:getPositionX() + numberBox:getContentSize().width * 0.6 + addBtn:getContentSize().width * 0.5, 0))
        tempNode:addChild(addBtn)

        -- 添加加号右侧的“装满”按钮
        local addFullBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        addFullBtn:registerScriptTapHandler(function()
            cclog("点击装满按钮", i)
            local val = tonumber(numberLabel:getString())
            if bagType == 0 then
                -- 背包数据
                local allAddNum = math.floor((self.boatNum - self.useBoatNum) / needNum)
                if allAddNum > 0 and num > 0 then
                    local realNum = math.min(allAddNum, num)
                    -- print("数据：", allAddNum, num, realNum, self.boatNum, self.useBoatNum, val)
                    numberLabel:setString((val + realNum) .. "")
                    self.useBoatNum = self.useBoatNum + needNum * realNum
                    num = num - realNum
                    -- 修改原始数据
                    self.selectedData[k] = val + realNum
                    -- 刷新显示
                    resetQueueData(true)
                    -- 修改剩余数量文本
                    setNumLabel(num)
                else
                    ToastUtil:downString("该物品数量不足或已达上限", true)
                end
            elseif bagType == 1 then
                local allAddNum = math.floor((self.soldierNum - self.useSoldierNum) / needNum)
                if allAddNum > 0 and num > 0 then
                    local realNum = math.min(allAddNum, num)
                    numberLabel:setString((val + realNum) .. "")
                    self.useSoldierNum = self.useSoldierNum + needNum * realNum
                    num = num - realNum
                    -- 修改原始数据
                    self.selectedData[k] = val + realNum
                    -- 刷新显示
                    resetQueueData(true)
                    -- 修改剩余数量文本
                    setNumLabel(num)
                else
                    ToastUtil:downString("成员数量不足或可携带成员已满", true)
                end
            end
        end)
        addFullBtn:setPosition(cc.p(addBtn:getPositionX() + addBtn:getContentSize().width + addFullBtn:getContentSize().width * 0.5, 0))

        local addFullLabel = cc.LabelTTF:create("装  满", BoldFont, 24.0)
        addFullLabel:setPosition(cc.p(addFullBtn:getContentSize().width * 0.5, addFullBtn:getContentSize().height * 0.5))
        addFullBtn:addChild(addFullLabel)

        -- 添加左侧工匠名称按钮
        local nameBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
        nameBtn:registerScriptTapHandler(function()
            cclog("点击名称按钮", i)
            self:showInfoBox(infoString)
        end)
        nameBtn:setPosition(cc.p(subBtn:getPositionX() - subBtn:getContentSize().width - nameBtn:getContentSize().width * 0.5, 0))

        -- 添加左侧工匠类型文本
        local nameLabel = cc.LabelTTF:create(name, BoldFont, 24.0)
        nameLabel:setColor(BaseColor)
        -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        nameLabel:setPosition(cc.p(nameBtn:getContentSize().width * 0.5, nameBtn:getContentSize().height * 0.6))
        nameBtn:addChild(nameLabel)

        -- 添加左侧工匠类型的星级
        for j = 1, starNum do
            local spr = cc.Sprite:create("Images/UI/xingxing01.png")
            -- print("宽度：", allNum % 2)
            spr:setScale(0.5)
            spr:setPosition(cc.p(nameBtn:getContentSize().width * 0.5 + (j - starNum / 2.0 - 0.5) * (spr:getContentSize().width * spr:getScale() + 2), nameBtn:getContentSize().height * 0.25))
            nameBtn:addChild(spr)
        end

        -- 添加出征数据的数量文本
        local numBg = cc.Sprite:create("Images/UI/num_circlebg.png")
        numBg:setPosition(cc.p(nameBtn:getContentSize().width - numBg:getContentSize().width * 0.5, nameBtn:getContentSize().height - numBg:getContentSize().height * 0.5))
        nameBtn:addChild(numBg)

        numLable:setPosition(cc.p(numBg:getContentSize().width * 0.5, numBg:getContentSize().height * 0.5))
        numLable:setColor(WriteColor)
        numBg:addChild(numLable)

        -- 添加详情按钮
        -- local infoBtn = cc.MenuItemImage:create("Images/UI/Info.png", "Images/UI/Info1.png")
        -- infoBtn:setPosition(cc.p(addBtn:getPositionX() + addBtn:getContentSize().width + infoBtn:getContentSize().width * 0.8, 0))

        local buttonArr = {nameBtn, addFullBtn}
        local menu = cc.Menu:create(unpack(buttonArr))
        menu:setPosition(cc.p(0, 0))
        tempNode:addChild(menu)

        -- self.workerUseNum = self.workerUseNum + tonumber(workerTable[dataKeyNum])
    end
    -- 设置兵将与背包数量
    resetQueueData(false)
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end