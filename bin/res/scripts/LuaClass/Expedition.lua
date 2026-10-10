require "LuaClass/Header"
local CrewSkillDetails = require "LuaClass/CrewSkillDetails"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
local BTheme = require "LuaClass/BTheme"
local MasterTheme = require "LuaClass/MasterTheme"
local DepartureTheme = require "LuaClass/DepartureTheme"


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
    self.foodStockUpdater = nil
    if self.adventureRoot then
        self.adventureRoot:stopAllActions()
    end
    DataManager:getInstance():unregisterEvent("breadBirth", "expedition")
    DataManager:getInstance():unregisterEvent(roleMoney, "approvedDeparture")
    DataManager:getInstance():unregisterEvent(roleDiamond, "approvedDeparture")
    DataManager:getInstance():unregisterEvent(roleGuideStep, "expedition")
    -- 调用父类的析构
    self:superDestory()
end

function ExpeditionLayer:init()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    self.departureInProgress = false
    self.isApprovedDeparture = true
    self.approvedPage = true
    self.keepNavigation = true
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
        self:refreshProducedFood()
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

-- Project the approved sheet into screen coordinates. The root stays unscaled
-- so SDButton and ScrollView keep their original screen-space hit testing.
function ExpeditionLayer:createAdventureUI()
    local size=cc.Director:getInstance():getVisibleSize()
    local origin=cc.Director:getInstance():getVisibleOrigin()
    local M,D=MasterTheme,DepartureTheme
    local C=M.colors
    local navigationHeight=(zqDispatch.mainMenu and zqDispatch.mainMenu.navigationHeight) or 118
    local ux=size.width/941
    local uy=math.min(size.height/1672,(size.height-navigationHeight)/1518)
    self.adventureScaleX=ux;self.adventureScaleY=uy
    self.adventureWidth=833*ux;self.adventureRowHeight=126*uy
    local function x(v)return origin.x+v*ux end
    local function y(v)return origin.y+size.height-v*uy end
    self.mainBg:setVisible(false);self.titleBg:setVisible(false);self.storeMenu:setVisible(false)
    for _,child in ipairs(self.infoNode:getChildren()) do
        if child~=self.bottomInfoBox then child:setVisible(false);child:stopAllActions() end
    end
    self.setBtn:stopAllActions();self.setBtnLight:stopAllActions()
    self.infoNode:setPosition(cc.p(0,0));self.infoNode:setLocalZOrder(30)
    self.bottomInfoBox:setPosition(cc.p(x(470.5),y(1160)))
    -- BaseView retains its dark MaskBg_1 tooltip; use light text on that surface.
    self.infoBoxLabel:setColor(C.white)
    local root=cc.Node:create();self.adventureRoot=root;self:addChild(root,2)
    local bg=M.cover(D.path..'backdrop.png',size.width,size.height)
        or M.cover(M.path..'harbor-full.png',size.width,size.height)
    if bg then bg:setPosition(origin);root:addChild(bg)
    else root:addChild(BTheme.panel(size.width,size.height,cc.c3b(83,163,185),origin.x,origin.y)) end
    local function material(name,left,top,w,h)
        local n=D.material(name,w*ux,h*uy);n:setPosition(cc.p(x(left),y(top+h)));root:addChild(n);return n
    end
    local function label(text,font,color,left,top,anchor)
        local n=D.label(text,font*ux,color,x(left),y(top),anchor);root:addChild(n);return n
    end
    local function icon(kind,left,top,w)
        local n=M.icon(kind,w*ux,C.paper);n:setPosition(cc.p(x(left),y(top)-w*ux));root:addChild(n);return n
    end
    local function button(text,left,top,w,h,callback,opts)
        opts=opts or {};opts.fontSize=(opts.fontSize or 32)*ux;opts.bold=true
        local n=M.button(text,w*ux,h*uy,callback,opts)
        n:setPosition(cc.p(x(left+w/2),y(top+h/2)));root:addChild(n);return n
    end
    local back=D.menuItem('‹',65*ux,88*uy,function() zqDispatch:moveToHome() end,
        {clear=true,fontSize=98*ux,textColor=C.ink})
    back:setPosition(cc.p(x(75),y(73)))
    local backMenu=cc.Menu:create(back);backMenu:setPosition(cc.p(0,0));root:addChild(backMenu)
    self.departureBackButton=back
    local heading=label('出航整备',65,C.ink,126,72)
    M.fit(heading,253*ux)
    local compass=D.compass(76*ux);compass:setPosition(cc.p(x(419),y(76)));root:addChild(compass)
    local function currency(kind,key,left,width)
        material('currency-paper.png',left,128,width,62)
        local art=D.currencyIcon(kind,49*ux);art:setPosition(cc.p(x(left+13),y(158)-24.5*ux));root:addChild(art)
        local value=label('',35,C.ink,left+80,159)
        local add=D.menuItem('+',58*ux,62*uy,function()
            if kind=='coin' then DataManager:getInstance():showBuyGoldBox() else ChargeLayer:create() end
        end,{clear=true,fontSize=48*ux,textColor=C.ink})
        add:setPosition(cc.p(x(left+width-32),y(159)))
        local chip=M.material('currency-paper.png',42*ux,46*uy,cc.c3b(219,222,201))
        chip:setPosition(cc.p(8*ux,8*uy));add:addChild(chip,1)
        local menu=cc.Menu:create(add);menu:setPosition(cc.p(0,0));root:addChild(menu)
        local function refresh()
            local amount=tonumber(DataManager:getInstance():getRoleData(key)) or 0
            value:setString(amount>1000000 and math.floor(amount/10000)..'万' or tostring(amount))
            M.fit(value,(width-134)*ux)
        end
        refresh();DataManager:getInstance():registerEvent(key,'approvedDeparture',refresh)
        return value,add
    end
    self.departureCoinLabel,self.departureCoinAdd=currency('coin',roleMoney,47,246)
    self.departureDiamondLabel,self.departureDiamondAdd=currency('diamond',roleDiamond,309,225)
    material('ink-brush.png',42,368,312,86)
    icon('sail',69,380,58)
    self.shipNameLabel=label('',41,C.paper,141,411)
    material('ink-brush.png',30,454,882,150)
    icon('crew',81,479,72);icon('food',504,488,58)
    self.crewLabel=label('',35,C.paper,174,505)
    self.cargoLabel=label('',35,C.paper,579,505)
    local divider=cc.DrawNode:create();divider:drawSegment(cc.p(x(472),y(490)),cc.p(x(472),y(557)),.7,HomeTheme.rgba(C.paper,.6));root:addChild(divider)
    local function capacity(left,width)
        local w,h=width*ux,20*uy
        local frame=HomeTheme.rounded(w,h,C.sea,10*uy);frame:setPosition(cc.p(x(left),y(551)));root:addChild(frame)
        local track=HomeTheme.rounded(w-2,h-2,C.ink,9*uy);track:setPosition(cc.p(x(left)+1,y(551)+1));root:addChild(track)
        local bar=HomeTheme.rounded(w-2,h-2,cc.c3b(66,220,228),9*uy);bar:setPosition(cc.p(x(left)+1,y(551)+1));root:addChild(bar)
        return bar
    end
    self.crewCapacityBar=capacity(76,360);self.cargoCapacityBar=capacity(578,287)
    icon('food',690,562,30)
    self.foodLabel=label('',26,C.paper,735,578)
    material('manifest-paper.png',18,594,904,676)
    label('装载清单',47,C.ink,65,648)
    label('点击名称查看详情',24,C.muted,884,657,1)
    local rule=cc.DrawNode:create();rule:drawSegment(cc.p(x(65),y(678)),cc.p(x(355),y(678)),1.2,HomeTheme.rgba(C.ink));root:addChild(rule)
    label('长按 + / − 连续调整',24,C.muted,470.5,1200,.5)
    material('currency-paper.png',184,1242,574,94)
    self.readinessIcon=D.readinessIcon(46*ux);self.readinessIcon:setPosition(cc.p(x(216),y(1293)));root:addChild(self.readinessIcon)
    self.readyLabel=label('',32,C.ink,280,1274)
    self.readinessRequirement=label('出航需至少 1 名船员与食物',25,C.muted,473,1309,.5)
    self.departureButton=button('出  航  ›',164,1334,613,108,self.departureAction,
        {material='coral-brush.png',fontSize=58})
    self.departureButton.label:setPositionX(374*ux)
    local sail=M.icon('sail',78*ux,C.paper);sail:setPosition(cc.p(164*ux,15*uy));self.departureButton.item:addChild(sail,4)
    self.talentShortcut=button('查看天赋  ›',177,1450,288,63,function() zqDispatch:moveToTalent() end,{fontSize=32})
    self.warehouseShortcut=button('整理仓库  ›',482,1450,285,63,function() zqDispatch:moveToRepository() end,{fontSize=32})
    self.topMaskLabel=D.label('',20,C.ink,0,0);self.topMaskLabel:setVisible(false);root:addChild(self.topMaskLabel)
    local viewSize=cc.size(self.adventureWidth,506*uy)
    self.scrollViewContainer=cc.Layer:create();self.scrollViewContainer:setContentSize(viewSize)
    self.scrollView=cc.ScrollView:create(viewSize)
    self.scrollView:setPosition(cc.p(x(55),y(1192)))
    self.scrollView:setContainer(self.scrollViewContainer);self.scrollView:setViewSize(viewSize)
    self.scrollView.bIsScrollView=true;self.scrollView:setClippingToBounds(true)
    self.scrollView:setBounceable(true);self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self:addChild(self.scrollView,3)
end

function ExpeditionLayer:updateAdventureReadiness()
    local food=tonumber(self.selectedData['1005']) or 0
    local ship=self.produceCsv[tostring(DataManager:getInstance():getRoleData(roleShipId) or '')] or {}
    self.shipNameLabel:setString(ship.name or '战船');MasterTheme.fit(self.shipNameLabel,205*self.adventureScaleX)
    self.crewLabel:setString('船员  '..self.useSoldierNum..'/'..self.soldierNum)
    self.cargoLabel:setString('货舱  '..self.useBoatNum..'/'..self.boatNum)
    MasterTheme.fit(self.crewLabel,260*self.adventureScaleX);MasterTheme.fit(self.cargoLabel,287*self.adventureScaleX)
    self.foodLabel:setString('已备食物 '..food);MasterTheme.fit(self.foodLabel,139*self.adventureScaleX)
    self.crewCapacityBar:setScaleX(math.min(1,self.useSoldierNum/math.max(1,self.soldierNum)))
    self.cargoCapacityBar:setScaleX(math.min(1,self.useBoatNum/math.max(1,self.boatNum)))
    local ready=food>0 and self.useSoldierNum>0
    self.readinessIcon.update(ready)
    if ready then self.readyLabel:setString('整备就绪 · 船员与补给已登船')
    elseif food<=0 and self.useSoldierNum>0 then self.readyLabel:setString('船员已就位，请装入航行食物')
    elseif food<=0 then self.readyLabel:setString('请装入食物，并分配至少一名船员')
    else self.readyLabel:setString('补给已就位，请分配至少一名船员') end
    MasterTheme.fit(self.readyLabel,458*self.adventureScaleX)
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

-- Production changes food stock, not the selected loadout. Preserve existing
-- controls so a production tick cannot destroy an active long-press gesture.
function ExpeditionLayer:refreshProducedFood()
    if self.departureInProgress then return end
    if self.foodStockUpdater then
        local pack=DataManager:getInstance():getRoleData(rolePack) or {}
        self.foodStockUpdater(tonumber(pack['1005']) or 0)
    else
        -- A new food type must become a real row when it first enters stock.
        self:setResourceUIWithData()
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
                table.insert(self.expeditionData, {[dataKeyID] = k, [dataKeyNum] = v, ["name"] = csvData["name"], ["desc"] = csvData["desc"], ["cubage"] = csvData["cubage"], ["star"] = csvData["starNum"], ["icon"] = csvData["icon"]})
                dataNum = dataNum + 1
            end
        end
    end
    for k,v in pairs(soildierData) do
        -- print(k, v)
        local csvData = soildierCsv[tostring(k)]
        if csvData ~= nil and v[dataKeyNum] > 0 then
            table.insert(self.expeditionData, {[dataKeyID] = (tonumber(k) + 10000) .. "", [dataKeyNum] = v[dataKeyNum], ["name"] = csvData["name"], ["skill"] = csvData["skill"], ["hp"] = csvData["hp"], ["attack"] = csvData["attack"], ["speed"] = csvData["speed"], ["star"] = csvData["star"], ["icon"] = csvData["icon"]})
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
    local ux,uy=self.adventureScaleX,self.adventureScaleY
    local D,M=DepartureTheme,MasterTheme
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
    -- Discard the old row closure before replacing its controls.
    self.foodStockUpdater = nil
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
            local skillName, buffDesc = CrewSkillDetails.describe(v["skill"], skillCsv, buffCsv)
            infoString = name.."整装待发\n技能："..skillName.."\n技能效果："..buffDesc.."\n生命："..v["hp"].." 威力："..v["attack"].." 速度："..v["speed"]
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
        local divider=cc.DrawNode:create()
        divider:drawSegment(cc.p(-self.adventureWidth/2,-singleHeight/2),cc.p(self.adventureWidth/2,-singleHeight/2),.65,HomeTheme.rgba(M.colors.muted,.45))
        tempNode:addChild(divider)
        self.scrollViewContainer:addChild(tempNode)
        tempNode.itemId=tostring(k)
        local numberLabel=D.label(itemNum..'',47*ux,M.colors.ink,122.5*ux,0,.5)
        tempNode:addChild(numberLabel);tempNode.quantityLabel=numberLabel

        -- 定义数字按钮上的label
        local numLable = D.label("1",28*ux,M.colors.muted,0,0)

        local function setNumLabel(intNum)
            -- 开始设置数量文本
            if numLable ~= nil and intNum >= 0 then
                numLable:setString("余 " .. intNum)
            end
        end
        -- 优先设置一次数量
        setNumLabel(num)
        if tostring(k) == '1005' then
            self.foodStockUpdater = function(total)
                -- Refresh the same remaining-stock upvalue consumed by + and
                -- fill. Updating only the label would leave their limits stale.
                v[dataKeyNum] = total
                num = math.max(0, total - (tonumber(self.selectedData[k]) or 0))
                setNumLabel(num)
            end
        end

        -- 然后添加左右加减按钮
        local function subButtonDidClick()
            -- cclog("点击减少按钮", i)
            local val = tonumber(numberLabel:getString())
            if val > 0 then
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
        subBtn:setPosition(cc.p(22.5*ux, 0))
        D.quantity(subBtn, "−",78*ux,68*uy,47*ux)
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
        addBtn:setPosition(cc.p(222.5*ux, 0))
        D.quantity(addBtn, "+",78*ux,68*uy,47*ux)
        tempNode:addChild(addBtn)

        -- 添加加号右侧的“装满”按钮
        local addFullBtn = D.menuItem("装满",122*ux,68*uy,nil,{fontSize=35*ux})
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
        addFullBtn:setPosition(cc.p(348.5*ux, 0))

        -- The portrait and name are one real details control. All rows come
        -- from the existing merged inventory, including types outside the mock.
        local nameBtn=D.menuItem('',383*ux,singleHeight,nil,{clear=true})
        nameBtn:registerScriptTapHandler(function() self:showInfoBox(infoString) end)
        nameBtn:setPosition(cc.p(-225*ux,0))
        local portrait=D.portrait(v,145*ux,124*uy)
        portrait:setPosition(cc.p(8*ux,1*uy));nameBtn:addChild(portrait)
        local nameLabel=D.label(name,40*ux,M.colors.ink,184*ux,(bagType==1 and 89 or 80)*uy)
        M.fit(nameLabel,196*ux);nameBtn:addChild(nameLabel)
        if bagType==1 then
            for j=1,tonumber(starNum) or 0 do
                local star=D.label('★',25*ux,cc.c3b(162,115,37),(184+(j-1)*28)*ux,56*uy)
                nameBtn:addChild(star)
            end
        end
        numLable:setPosition(cc.p(184*ux,(bagType==1 and 25 or 38)*uy))
        M.fit(numLable,195*ux);nameBtn:addChild(numLable)
        tempNode.controls={minus=subBtn,plus=addBtn,full=addFullBtn,details=nameBtn}
        tempNode.remainingLabel=numLable

        local buttonArr = {nameBtn, addFullBtn}
        local menu = cc.Menu:create(unpack(buttonArr))
        menu:setPosition(cc.p(0, 0))
        tempNode:addChild(menu)

        -- self.workerUseNum = self.workerUseNum + tonumber(workerTable[dataKeyNum])
    end
    if #self.expeditionData == 0 then
        self.scrollViewContainer:addChild(BTheme.label("暂无可携带物品或船员", 23,
            MasterTheme.colors.muted, self.adventureWidth * 0.5, allHeight * 0.5, 0.5, 0.5))
    end
    -- 设置兵将与背包数量
    resetQueueData(false)
    self.scrollView:setContentSize(cc.size(self.scrollView:getViewSize().width, allHeight))
    self.scrollView:setContentOffset(cc.p(0, -(allHeight - self.scrollView:getViewSize().height)))
end