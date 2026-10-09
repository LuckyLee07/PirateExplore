require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
local BTheme = require "LuaClass/BTheme"

-- Keep SDButton's native long-press behavior and hit area with the new flat skin.
local function styleQuantityButton(button, text)
    button.normalSpr:setOpacity(0)
    button.selectSpr:setOpacity(0)
    local size = button:getContentSize()
    button:addChild(BTheme.panel(size.width, size.height, BTheme.colors.sea))
    button:addChild(BTheme.label(text, 31, BTheme.colors.white,
        size.width * 0.5, size.height * 0.5, 0.5, 0.5))
end


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
    self.departureInProgress = true
    self.departureAction = nil
    if self.adventureRoot then
        self.adventureRoot:stopAllActions()
    end
    DataManager:getInstance():unregisterEvent("breadBirth", "expedition")
    DataManager:getInstance():unregisterEvent(roleGuideStep, "expedition")
    -- 调用父类的析构
    self:superDestory()
end

function ExpeditionLayer:init()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    self.departureInProgress = false
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

    -- Keep the original departure checks and inventory transaction together.
    self.departureAction = function()
        if self.departureInProgress then
            return
        end
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
        -- Lock only after both checks pass; repeated taps must not debit twice.
        self.departureInProgress = true
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
    end
    -- BaseView still owns the existing details popup and its lifecycle.
    self:addInfoNode("天 赋", function()
        zqDispatch:gotoTalent()
    end, "仓 库", function()
        zqDispatch:moveToRepository()
    end, "Images/MainMenu/an_yuanz_a.png", "Images/MainMenu/an_yuanz_b.png",
        self.departureAction, "Images/MainMenu/w_qih.png")

    self:createAdventureUI()

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

-- This screen owns its presentation nodes; BaseView and save data remain unchanged.
function ExpeditionLayer:createAdventureUI()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    local C = BTheme.colors
    local left = origin.x + 16
    local width = visibleSize.width - 32
    local bottom = origin.y + UIBottomHeight
    local top = origin.y + visibleSize.height - UITopHeight
    local unit = math.min(1, (top - bottom) / 900)
    self.adventureUnit = unit
    self.adventureWidth = width - 32
    self.adventureRowHeight = math.max(72, 86 * unit)

    self.mainBg:setVisible(false)
    self.titleBg:setVisible(false)
    self.storeMenu:setVisible(false)
    -- Hide the original circular action strip, but retain its working details box.
    for _, child in ipairs(self.infoNode:getChildren()) do
        if child ~= self.bottomInfoBox then
            child:setVisible(false)
            child:stopAllActions()
        end
    end
    self.setBtn:stopAllActions()
    self.setBtnLight:stopAllActions()
    self.infoNode:setPosition(cc.p(0, 0))
    self.infoNode:setLocalZOrder(30)
    self.bottomInfoBox:setPosition(cc.p(origin.x + visibleSize.width * 0.5, bottom + 230 * unit))
    self.infoBoxLabel:setColor(C.ink)

    self.adventureRoot = cc.Node:create()
    self:addChild(self.adventureRoot, 2)
    local root = self.adventureRoot
    root:addChild(BTheme.panel(visibleSize.width, top - bottom, C.sand, origin.x, bottom))
    root:addChild(BTheme.panel(width, 64 * unit, C.ink, left, top - 64 * unit))
    root:addChild(BTheme.label("出航整备", 30, C.white, left + 22, top - 32 * unit, 0, 0.5))

    local achievements = BTheme.button("成就", 72, 38 * unit, function()
        zqDispatch:gotoAchievement()
    end, {color = C.sea, fontSize = 20})
    achievements:setPosition(cc.p(left + width - 136, top - 32 * unit))
    root:addChild(achievements)
    self.topLeftBtn = achievements.item
    local rankings = BTheme.button("榜单", 72, 38 * unit, function()
        zqDispatch:gotoRanking()
    end, {color = C.sea, fontSize = 20})
    rankings:setPosition(cc.p(left + width - 50, top - 32 * unit))
    root:addChild(rankings)
    self.topRightBtn = rankings.item

    local heroHeight = 228 * unit
    local heroBottom = top - 64 * unit - heroHeight
    root:addChild(BTheme.panel(width, heroHeight, C.sea, left, heroBottom))
    local harborPath = "Images/UI/Adventure/harbor.png"
    if cc.FileUtils:getInstance():isFileExist(harborPath) then
        local harbor = cc.Sprite:create(harborPath)
        local size = harbor:getContentSize()
        local scale = math.max(width / size.width, heroHeight / size.height)
        local cropWidth = width / scale
        local cropHeight = heroHeight / scale
        harbor:setTextureRect(cc.rect((size.width - cropWidth) * 0.5,
            (size.height - cropHeight) * 0.5, cropWidth, cropHeight))
        harbor:setScale(scale)
        harbor:setPosition(cc.p(left + width * 0.5, heroBottom + heroHeight * 0.5))
        root:addChild(harbor)
    end
    local caption = cc.LayerColor:create(cc.c4b(18, 48, 57, 210), width, 62 * unit)
    caption:setPosition(cc.p(left, heroBottom))
    root:addChild(caption)
    root:addChild(BTheme.label("海盗港湾", 27, C.white, left + 20, heroBottom + 42 * unit, 0, 0.5))
    root:addChild(BTheme.label("带上船员与补给，驶向未知海域", 18, C.white,
        left + 20, heroBottom + 17 * unit, 0, 0.5))

    local contentLeft = left + 16
    local contentWidth = width - 32
    root:addChild(BTheme.label("出航准备", 29, C.ink, contentLeft, heroBottom - 28 * unit, 0, 0.5))
    self.foodLabel = BTheme.label("已备食物 0", 21, C.muted,
        left + width - 16, heroBottom - 28 * unit, 1, 0.5)
    root:addChild(self.foodLabel)
    local cardWidth = (contentWidth - 16) * 0.5
    local cardY = heroBottom - 98 * unit
    local cardColor = cc.c3b(255, 250, 238)
    for index = 0, 1 do
        root:addChild(BTheme.panel(cardWidth, 54 * unit, cardColor,
            contentLeft + index * (cardWidth + 16), cardY))
    end
    self.crewLabel = BTheme.label("船员  0 / 0", 22, C.ink, contentLeft + 12,
        cardY + 35 * unit, 0, 0.5)
    self.cargoLabel = BTheme.label("货舱  0 / 0", 22, C.ink,
        contentLeft + cardWidth + 28, cardY + 35 * unit, 0, 0.5)
    root:addChild(self.crewLabel)
    root:addChild(self.cargoLabel)
    self.capacityBarWidth = cardWidth - 24
    for index = 0, 1 do
        root:addChild(BTheme.panel(self.capacityBarWidth, 7 * unit, cc.c3b(216, 211, 191),
            contentLeft + index * (cardWidth + 16) + 12, cardY + 10 * unit))
    end
    self.crewCapacityBar = BTheme.panel(self.capacityBarWidth, 7 * unit, C.sea,
        contentLeft + 12, cardY + 10 * unit)
    self.cargoCapacityBar = BTheme.panel(self.capacityBarWidth, 7 * unit, C.coral,
        contentLeft + cardWidth + 28, cardY + 10 * unit)
    root:addChild(self.crewCapacityBar)
    root:addChild(self.cargoCapacityBar)

    local navY = bottom + 36 * unit
    local linkWidth = (contentWidth - 16) * 0.5
    local talent = BTheme.button("船员成长  >", linkWidth, 46 * unit, function()
        zqDispatch:moveToTalent()
    end, {color = C.ink, fontSize = 22})
    talent:setPosition(cc.p(contentLeft + linkWidth * 0.5, navY))
    root:addChild(talent)
    local warehouse = BTheme.button("整理仓库  >", linkWidth, 46 * unit, function()
        zqDispatch:moveToRepository()
    end, {color = C.ink, fontSize = 22})
    warehouse:setPosition(cc.p(contentLeft + linkWidth * 1.5 + 16, navY))
    root:addChild(warehouse)
    self.departureButton = BTheme.button("出  航    >", contentWidth, 62 * unit,
        self.departureAction, {color = C.coral, fontSize = 31})
    self.departureButton:setPosition(cc.p(left + width * 0.5, bottom + 103 * unit))
    root:addChild(self.departureButton)
    self.readyLabel = BTheme.label("选择食物和船员后即可出航", 18, C.muted,
        left + width * 0.5, bottom + 149 * unit, 0.5, 0.5)
    root:addChild(self.readyLabel)

    -- The native scroll view continues to own all item/crew controls.
    local scrollBottom = bottom + 168 * unit
    local scrollTop = cardY - 14 * unit
    local scrollViewSize = cc.size(contentWidth, math.max(100, scrollTop - scrollBottom))
    self.topMaskLabel = cc.LabelTTF:create("", BoldFont, 20)
    self.topMaskLabel:setVisible(false)
    root:addChild(self.topMaskLabel)
    self.scrollViewContainer = cc.Layer:create()
    self.scrollViewContainer:setContentSize(scrollViewSize)
    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(cc.p(contentLeft, scrollBottom))
    self.scrollView:setContainer(self.scrollViewContainer)
    self.scrollView:setViewSize(scrollViewSize)
    self.scrollView.bIsScrollView = true
    self.scrollView:setClippingToBounds(true)
    self.scrollView:setBounceable(true)
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self:addChild(self.scrollView, 3)
end

function ExpeditionLayer:updateAdventureReadiness()
    local food = tonumber(self.selectedData["1005"]) or 0
    self.crewLabel:setString("船员  " .. self.useSoldierNum .. " / " .. self.soldierNum)
    self.cargoLabel:setString("货舱  " .. self.useBoatNum .. " / " .. self.boatNum)
    self.foodLabel:setString("已备食物 " .. food)
    self.crewCapacityBar:setScaleX(math.min(1, self.useSoldierNum / math.max(1, self.soldierNum)))
    self.cargoCapacityBar:setScaleX(math.min(1, self.useBoatNum / math.max(1, self.boatNum)))
    if food > 0 and self.useSoldierNum > 0 then
        self.readyLabel:setString("整备就绪 · 船员与补给已登船")
        self.readyLabel:setColor(BTheme.colors.sea)
    elseif food <= 0 and self.useSoldierNum > 0 then
        self.readyLabel:setString("船员已就位，请装入航行食物")
        self.readyLabel:setColor(BTheme.colors.muted)
    elseif food <= 0 then
        self.readyLabel:setString("请装入食物，并分配至少一名船员")
        self.readyLabel:setColor(BTheme.colors.muted)
    else
        self.readyLabel:setString("补给已就位，请分配至少一名船员")
        self.readyLabel:setColor(BTheme.colors.muted)
    end
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
    -- Keep required food and crew visible first; sort presentation only.
    table.sort(self.expeditionData, function(a, b)
        local aID, bID = tonumber(a[dataKeyID]), tonumber(b[dataKeyID])
        local aGroup = aID == 1005 and 0 or (aID >= 10000 and 1 or 2)
        local bGroup = bID == 1005 and 0 or (bID >= 10000 and 1 or 2)
        return aGroup == bGroup and aID < bID or aGroup < bGroup
    end)
    local singleHeight = self.adventureRowHeight
    local allHeight = singleHeight * dataNum
    if allHeight < self.scrollView:getViewSize().height then
        allHeight = self.scrollView:getViewSize().height
    end
    -- 重新设置数量的函数
    local function resetQueueData(bIsNeedSave)
        self.topMaskLabel:setString("货舱：(" .. self.useBoatNum .. "/" .. self.boatNum .. ") 成员：(" .. self.useSoldierNum .. "/" .. self.soldierNum .. ")")
        self:updateAdventureReadiness()
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
        tempNode:setPosition(cc.p(self.scrollView:getViewSize().width * 0.5, allHeight - singleHeight * (i - 1) - singleHeight * 0.5))
        tempNode:addChild(BTheme.panel(self.adventureWidth, singleHeight - 8,
            cc.c3b(255, 250, 238), -self.adventureWidth * 0.5, -(singleHeight - 8) * 0.5))
        self.scrollViewContainer:addChild(tempNode)

        -- 首先添加文字框
        local numberBox = cc.Sprite:create("Images/UI/NumberBox.png")
        numberBox:setPosition(cc.p(42, 0))
        numberBox:setOpacity(0)
        tempNode:addChild(numberBox)

        -- 添加健文字框中间的数字label
        local numberLabel = cc.LabelTTF:create(itemNum .. "", BoldFont, 24.0)
        numberLabel:setColor(BTheme.colors.ink)
        -- numberLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        numberLabel:setPosition(numberBox:getPosition())
        tempNode:addChild(numberLabel)

        -- 定义数字按钮上的label
        local numLable = cc.LabelTTF:create("1", BoldFont, 18.0)

        local function setNumLabel(intNum)
            -- 开始设置数量文本
            if numLable ~= nil and intNum >= 0 then
                numLable:setString("余 " .. intNum)
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
        subBtn:setPosition(cc.p(-20, 0))
        styleQuantityButton(subBtn, "−")
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
        addBtn:setPosition(cc.p(104, 0))
        styleQuantityButton(addBtn, "+")
        tempNode:addChild(addBtn)

        -- 添加加号右侧的“装满”按钮
        local addFullBtn = BTheme.menuItem("装满", 98, 48, nil,
            {color = BTheme.colors.sea, selectedColor = BTheme.colors.ink, fontSize = 23})
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
        addFullBtn:setPosition(cc.p(self.adventureWidth * 0.5 - 60, 0))

        -- 添加左侧工匠名称按钮
        local nameBtn = BTheme.menuItem("", 180, 66, nil,
            {color = cc.c3b(255, 250, 238), selectedColor = BTheme.colors.pale})
        nameBtn:registerScriptTapHandler(function()
            cclog("点击名称按钮", i)
            self:showInfoBox(infoString)
        end)
        nameBtn:setPosition(cc.p(-self.adventureWidth * 0.5 + 94, 0))

        -- 添加左侧工匠类型文本
        local nameLabel = cc.LabelTTF:create(name, BoldFont, 23.0)
        nameLabel:setColor(BTheme.colors.ink)
        -- nameLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
        nameLabel:setPosition(cc.p(nameBtn:getContentSize().width * 0.5, nameBtn:getContentSize().height * 0.68))
        BTheme.fitLabel(nameLabel, 174)
        nameBtn:addChild(nameLabel)

        -- 添加左侧工匠类型的星级
        for j = 1, starNum do
            local spr = cc.Sprite:create("Images/UI/xingxing01.png")
            -- print("宽度：", allNum % 2)
            spr:setScale(0.28)
            spr:setPosition(cc.p(128 + (j - starNum / 2.0 - 0.5) *
                (spr:getContentSize().width * spr:getScale() + 1), 18))
            nameBtn:addChild(spr)
        end

        -- 添加出征数据的数量文本
        numLable:setPosition(cc.p(44, 18))
        numLable:setColor(BTheme.colors.muted)
        nameBtn:addChild(numLable)

        -- 添加详情按钮
        -- local infoBtn = cc.MenuItemImage:create("Images/UI/Info.png", "Images/UI/Info1.png")
        -- infoBtn:setPosition(cc.p(addBtn:getPositionX() + addBtn:getContentSize().width + infoBtn:getContentSize().width * 0.8, 0))

        local buttonArr = {nameBtn, addFullBtn}
        local menu = cc.Menu:create(unpack(buttonArr))
        menu:setPosition(cc.p(0, 0))
        tempNode:addChild(menu)

        -- self.workerUseNum = self.workerUseNum + tonumber(workerTable[dataKeyNum])
    end
    if #self.expeditionData == 0 then
        self.scrollViewContainer:addChild(BTheme.label("暂无可携带物品或船员", 23,
            BTheme.colors.muted, self.adventureWidth * 0.5, allHeight * 0.5, 0.5, 0.5))
    end
    -- 设置兵将与背包数量
    resetQueueData(false)
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end