--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/2/4
-- Time: 下午2:21
-- To change this template use File | Settings | File Templates.
--
require "LuaClass/Header"
require "LuaClass/AlertView"
require "LuaClass/DataManager"
require "LuaClass/MissionManagers"


-- 时间格式化函数，把秒数转换为日、时、分、秒的表示
local formatSecondToTimeCn = function(time)
    local day = 0
    local hour = 0
    local minute = 0
    local second = 0

    second = time
    local str = ""
    if second <= 0 then
        str = "1秒"
    elseif second > 0 and second < 60 then
        str = string.format("%d秒", math.floor(second))
    elseif second >= 60 and second < 3600 then
        minute = second / 60
        second = second % 60
        str = string.format("%d分%d秒", math.floor(minute), math.floor(second))
    elseif second >= 3600 and second < 3600*24 then
        hour = second / 3600
        minute = (second % 3600) / 60
        str = string.format("%d时%d分", math.floor(hour), math.floor(minute))
    else
        day = second / (3600*24);
        hour = (second % (3600*24)) / 3600
        str = string.format("%d天%d小时", math.floor(day), math.floor(hour))
    end
    return str
end

-- RandomEventLayer
RandomEventLayer = class("RandomEventLayer", function ()
    return cc.Layer:create()
end)

RandomEventLayer.__index = RandomEventLayer

RandomEventLayer.instance = nil

-- 几率表元素个数
RandomEventLayer.RateCount = 6

-- 几率表周期间隔
RandomEventLayer.Intrval = 6
-- 几率表
RandomEventLayer.Rates = {  [1*RandomEventLayer.Intrval]=100,
                            [2*RandomEventLayer.Intrval]=5,
                            [3*RandomEventLayer.Intrval]=10,
                            [4*RandomEventLayer.Intrval]=15,
                            [5*RandomEventLayer.Intrval]=20,
                            [6*RandomEventLayer.Intrval]=25}

-- 当前检测点
RandomEventLayer.checkIndex = 0
-- 当前是否在循环
RandomEventLayer.isRunningLoop = false
-- 随机到的事件id
RandomEventLayer.eventId = 0
-- 消耗物品列表id
RandomEventLayer.costId = 0
-- 当前随机到的天赋
RandomEventLayer.talent = nil

function RandomEventLayer:create()
    local layer = RandomEventLayer.new()
    if layer and layer:init() then
        return layer
    end
    return nil
end

function RandomEventLayer:init()
    RandomEventLayer.instance = self
    self.isRunningLoop = false
    self.eventId = 0
    self.costId = 0
    self.talent = nil
    self:startEventLoop()
    return true
end

function RandomEventLayer:startEventLoop()
    self.checkIndex = 1
    self.isRunningLoop = true
    local function update()
        -- 随机事件开关
--        if DataManager:getInstance():getRoleData(roleRandomEventSwitch) ~= nil then
            local nowTime = getSystemTimeMilliSecond()
            local deltaTime = nowTime-self.lastUpdateTime
            if (deltaTime > RandomEventLayer.Intrval) then
                self.lastUpdateTime = nowTime
                self:update(deltaTime)
            end
--        end
    end
    self.lastUpdateTime = getSystemTimeMilliSecond()
    self.beginUpdateTime = self.lastUpdateTime
    self:scheduleUpdateWithPriorityLua(update, 0)
end

function RandomEventLayer:terminateEventLoop()
    self.checkIndex = 1
    self.isRunningLoop = false
    self:unscheduleUpdate()
end

function RandomEventLayer:handleEvent(event, costType)
    local csv = DataManager:getInstance():getCSVByID(csvOfRandomEvent)
    local data = csv[tostring(event.type)]
    local type = tonumber(data.type)
    local cost = data.cost[event.costId]
    local talent = DataManager:getInstance():getCSVByID(csvOfTalent)[tostring(event.talentId)]
    local amount = tonumber(data.number)

    if type == 1 then
        local propId = cost[1]
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[propId]
        local isSuccessed = math.random(1, 2) == 1
        local itemNum = DataManager:getInstance():getRoleData(roleMoney)
        if 1 == tonumber(data.numType) then
            amount = math.floor(tonumber(data.number)/100.0*itemNum)
            if amount <= 0 then amount = 1 end
        end
        if itemNum >= amount then
            if isSuccessed then
                DataManager:getInstance():addPackItemWithId(propId, amount)
                local str = string.format(data.info[2][1], amount)
                DataManager:getInstance():sendSystemInfo(str)
                ToastUtil:toastString("您的运气真棒，赌赢了！")
                -- 成就触发
                local achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Gamble)
                DataManager:getInstance():setAchievementInfo(achievement_Gamble, (achievementValue + 1))
            else
                DataManager:getInstance():addPackItemWithId(propId, -amount)
                local str = string.format(data.info[1][1], amount)
                DataManager:getInstance():sendSystemInfo(str)
                ToastUtil:toastString("您的运气不佳，赌输了…")
            end
        else
            local info = "您的"..prop.name.."数量不足！"
            DataManager:getInstance():sendSystemInfo(info)
            ToastUtil:toastString(info)
            return true
        end
    elseif type == 2 then
        local propId = cost[1]
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[propId]
        local isSuccessed = math.random(1, 2) == 1
        local itemNum = DataManager:getInstance():getPackNumWithId(tostring(propId))
        if 1 == tonumber(data.numType) then
            amount = math.floor(tonumber(data.number)/100.0*itemNum)
            if amount <= 0 then amount = 1 end
        end
        if itemNum >= amount then
            if isSuccessed then
                DataManager:getInstance():addPackItemWithId(propId, amount)
                local str = string.format(data.info[2][1], prop.name, amount)
                DataManager:getInstance():sendSystemInfo(str)
                ToastUtil:toastString(prop.name.."+"..amount)
            else
                DataManager:getInstance():addPackItemWithId(propId, -amount)
                local str = string.format(data.info[1][1], prop.name, amount)
                DataManager:getInstance():sendSystemInfo(str)
                ToastUtil:toastString(prop.name.."-"..amount)
            end
        else
            local info = "您的"..prop.name.."数量不足！"
            DataManager:getInstance():sendSystemInfo(info)
            ToastUtil:toastString(info)
            return true
        end
    elseif type == 3 then
        if talent then
            local isSuccessed = DataManager:getInstance():checkTallentPass(talent, costType)
            if isSuccessed then
                DataManager:getInstance():unlockTallentByKey(talent.ID, costType)
                local str = string.format(data.info[2][1], talent.name)
                DataManager:getInstance():sendSystemInfo(str)
            else
                local str = string.format(data.info[1][1], "")
                DataManager:getInstance():sendSystemInfo(str)
                return true
            end
        else
            local str = string.format(data.info[1][1], "")
            DataManager:getInstance():sendSystemInfo(str)
        end
    elseif type == 4 then
        local isSuccessed = math.random(1, 2) == 1
        if isSuccessed then
            local str = string.format(data.info[2][1], data.price)
            DataManager:getInstance():sendSystemInfo(str)
        else
            local info = "您的金币数量不足！"
            DataManager:getInstance():sendSystemInfo(info)
            ToastUtil:toastString(info)
            return true
        end
    elseif type == 5 then
        local propId = cost[1]
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[propId]
        local itemNum = DataManager:getInstance():getPackNumWithId(propId)
        if itemNum >= amount then
            DataManager:getInstance():addPackItemWithId(propId, -amount)
            DataManager:getInstance():addCoin(tonumber(data.price), false)
            local str = string.format(data.info[2][1], prop.name, data.price, prop.name)
            DataManager:getInstance():sendSystemInfo(str)
        else
            DataManager:getInstance():sendSystemInfo("您的"..prop.name.."数量不足！"..data.info[1][1])
            ToastUtil:toastString("您的"..prop.name.."数量不足！")
            return true
        end
    end
    return false
end

function RandomEventLayer:update(deltaTime)
    local rand = math.random(1, 100)
    local rate = RandomEventLayer.Rates[self.checkIndex*RandomEventLayer.Intrval]
--    cclog("RandomEventLayer:update "..tostring(self.checkIndex)..", rate = "..tostring(rate).." rand is "..tostring(rand))
    if rate and rate>= rand then
--        self:terminateEventLoop()
        if self:calculateEventIndex() then
            local csv = DataManager:getInstance():getCSVByID(csvOfRandomEvent)
            local data = csv[tostring(self.eventId)]

            local talendId
            if self.talent then
                talendId = self.talent.ID
            end
            local event = RandomEvent:create(self.eventId, self.costId, talendId, os.time(), tonumber(data.time), self:getFormatedDesc())
            RandomEventManager:getInstance():addEvent(event)
            if RandomEventView.instance then
                if RandomEventView.instance.tableview1 then
                    RandomEventView.instance.tableview1:reloadData()
                end
            end
        end
        self.checkIndex = 1
    elseif self.checkIndex < RandomEventLayer.RateCount then
        self.checkIndex = self.checkIndex+1
    end

end

function RandomEventLayer:calculateEventIndex()
    self.talent = DataManager:getInstance():getUnAutoLearnedTallent()
--    local key = _G.next(self.talent)
--    self.talent = self.talent[key]
--    print("~~~~~~~ talent !!!!")
--    printn(self.talent)
    local csv = DataManager:getInstance():getCSVByID(csvOfRandomEvent)
    -- 1，2，5 随机事件可以一直发生
    local events = {1, 2, 5 }
    -- 3，4 随机事件需要判断条件是否发生
    if self.talent then table.insert(events, #events+1, 3) end
    if false then table.insert(events, #events+1, 4) end
    -- 删除不可重复的事件
    local eventList = RandomEventManager:getInstance().eventList
    for i=1,#eventList do
        for j=1,#events do
            if tonumber(events[j]) == tonumber(eventList[i].type) then
                table.remove(events, j)
                break
            end
        end
    end
    if #events <= 0 then return false end
    -- 之前事件id是随机的
    self.eventId = events[math.random(1, #events)]
    -- 现在事件id是根据权重随机的
    local rates = 0
    for i=1,#events do
        rates = rates+tonumber(csv[tostring(events[i])].rate)
    end
    local rand = math.random(1, rates)
--    print("rates = "..tostring(rates)..", rand = "..tostring(rand))
    for i=1,#events do
        rand = rand-tonumber(csv[tostring(events[i])].rate)
--        print("** rand = "..tostring(rand))
        if rand <= 0 then self.eventId = events[i];break end
    end

--    self.eventId = 3

    local data = csv[tostring(self.eventId)]
    local type = tonumber(data.type)

    if type == 1 or type == 2 or type == 5 then
        local weights = {}
        for i=1,#data.cost do
            if i==1 then
                weights[i] = tonumber(data.cost[i][2])
            else
                weights[i] = tonumber(data.cost[i][2])+weights[i-1]
            end
        end

        local rand = math.random(1, weights[#data.cost])
        for i=1,#weights do
            if weights[i] >= rand then
                self.costId = i
--                cclog("random is "..tostring(rand)..", costid is "..tostring(self.costId))
                break
            end
        end
    else
        self.costId = 1
--        cclog("costid is "..tostring(self.costId))
    end
    return true
end

function RandomEventLayer:getFormatedDesc()
    local str = ""
    local csv = DataManager:getInstance():getCSVByID(csvOfRandomEvent)
    local data = csv[tostring(self.eventId)]
    local amount = tonumber(data.number)
--    printn(data)
    local type = tonumber(data.type)
    local cost = data.cost[self.costId]

    if type == 1 then
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[cost[1]]
        local itemNum = DataManager:getInstance():getRoleData(roleMoney)
        if 1 == tonumber(data.numType) then
            amount = math.floor(tonumber(data.number)/100.0*itemNum)
            if amount <= 0 then amount = 1 end
        end
        str = string.format(data.desc, tostring(amount))
    elseif type == 2 then
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[cost[1]]
        local itemNum = DataManager:getInstance():getPackNumWithId(tostring(cost[1]))
        if 1 == tonumber(data.numType) then
            amount = math.floor(tonumber(data.number)/100.0*itemNum)
            if amount <= 0 then amount = 1 end
        end
        str = string.format(data.desc, tostring(amount), prop.name)
    elseif type == 3 then
        if 1 == tonumber(self.talent.resumeType) then
            str = string.format(data.desc, self.talent.name, self.talent.resumeNum, "钻石")
        else
            str = string.format(data.desc, self.talent.name, self.talent.resumeCoin, "金币")
        end
    elseif type == 4 then
        str = string.format(data.desc, data.price)
    elseif type == 5 then
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local prop = resource[cost[1]]
        str = string.format(data.desc, prop.name, data.price)
    end

    return str
end

-- RandomEvent
RandomEvent = class("RandomEvent",function ()
    return {}
end)
RandomEvent.EventType = {RandomEventDuBo = 1, RandomEventBorrow = 2, RandomEventTalent = 3,
                         RandomEventMapSaler = 4, RandomEventKeyBuier = 5, RandomEventMission = 6 }

-- 事件id，也就是类型
RandomEvent.type = RandomEvent.RandomEventDuBo
-- 消耗物品列表id
RandomEvent.costId = 0
-- 当前随机到的天赋Id
RandomEvent.talentId = 0
-- 事件触发时间
RandomEvent.startTime = 0
-- 事件生命周期
RandomEvent.lifeTime = 0
-- 描述
RandomEvent.description = 0

-- create
function RandomEvent:create(type, costId, talentId, startTime, lifeTime, desc)
    local view = RandomEvent.new()
    if view and view:init(type, costId, talentId, startTime, lifeTime, desc) then
        return view
    end
    return nil
end

-- init
function RandomEvent:init(type, costId, talentId, startTime, lifeTime, desc)
    self.type = type
    self.costId = costId
    self.talentId = talentId
    self.startTime = startTime
    self.description = desc
    self.lifeTime = lifeTime

    return true
end





-- RandomEventManager
RandomEventManager = class("RandomEventManager",function ()
    return {}
end)
RandomEventManager.__index = RandomEventManager

RandomEventManager.instance = nil

RandomEventManager.eventList = nil

local randomEventManager
local function createManger()
    local manger = RandomEventManager.new()
    if manger and manger:init() then
        return manger
    end
    return nil
end

function RandomEventManager:getInstance()
    if randomEventManager == nil then
        randomEventManager = createManger()
    end
    return randomEventManager
end

function RandomEventManager:init()
    self.eventList = DataManager:getInstance():getRoleData(roleRandomEvents)
    if nil == self.eventList then
        self.eventList = {}
    end
    return true
end

function RandomEventManager:saveEvents()
    DataManager:getInstance():setRoleData(roleRandomEvents, RandomEventManager:getInstance().eventList, nil)
end

function RandomEventManager:loadEvents()
    RandomEventManager:getInstance().eventList = DataManager:getInstance():getRoleData(roleRandomEvents)
end

function RandomEventManager:addEvent(event)
    table.insert(RandomEventManager:getInstance().eventList, #RandomEventManager:getInstance().eventList+1, event)
    RandomEventManager:getInstance():saveEvents()
end

function RandomEventManager:removeEvent(event)
    for i=1,#RandomEventManager:getInstance().eventList do
        if event == RandomEventManager:getInstance().eventList[i] then
            table.remove(RandomEventManager:getInstance().eventList, i)
        end
    end
    RandomEventManager:getInstance():saveEvents()
end


-- RandomEventView
RandomEventView = class("RandomEventView", function ()
    return DialogueView:create()
end)
RandomEventView.__index = RandomEventView

RandomEventView.instance = nil

-- create
function RandomEventView:create()
    local view = RandomEventView.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- init
function RandomEventView:init()
    RandomEventView.instance = self

--    DataManager:getInstance():addDiamond(100000)

    print("~~~~~~~~~~~~~~~~~~~~~~")
    print("~~~~~~~~~ length = "..#MissionManagers:getInstance():getAllMissions())
    printn(MissionManagers:getInstance():getAllMissions())
    print("~~~~~~~~~~~~~~~~~~~~~~")

    local winSize = cc.Director:getInstance():getVisibleSize()

    local layerbg = cc.LayerColor:create(cc.c4b(0,0,0,64));
    self:addChild(layerbg)

    local pngname = "Images/UI/tankuang_03.png"
    local background = cc.Scale9Sprite:create(pngname)
    local labelContentSize = cc.size(350,0)

    self.s_position = cc.p(winSize.width * 0.5, winSize.height * 0.5)
    background:setPosition(self.s_position)
    self:addChild(background)

    local msgBoxWidth = background:getContentSize().width
    local msgBoxHeight = background:getContentSize().height

    local contentSize = background:getContentSize()
    self.s_size = background:getContentSize()
    self.s_bg = background

    local label = cc.LabelTTF:create("情 报", BoldFont, 36.0)
    label:setColor(cc.c3b(255,255,255))
    label:setPosition(cc.p(msgBoxWidth * 0.5,msgBoxHeight-40))
    background:addChild(label)

    local closeBtn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
    closeBtn:registerScriptTapHandler(function()
        self:close()
    end)
    closeBtn:setPosition(cc.p(0.5*(winSize.width+contentSize.width)-0.5*closeBtn:getContentSize().width-5.0, 0.5*(winSize.height+contentSize.height)-0.5*closeBtn:getContentSize().height-5.0))
    local menu = cc.Menu:create(closeBtn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)


    -- tableview1
    self.tableview1 = cc.TableView:create(cc.size(530.0, 750.0))
    self.tableview1:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview1:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview1:setPosition(24.0, 30.0)
    self.tableview1:setDelegate()
    self.tableview1:registerScriptHandler(function(view, cell)
--        local event = RandomEventManager:getInstance().eventList[cell:getTag()]
--        RandomEventManager:getInstance():removeEvent(event)
--        self.tableview1:reloadData()

    end, cc.TABLECELL_TOUCHED)
    self.tableview1:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        local event
        local mission
        if idx <= #RandomEventManager:getInstance().eventList then
            event = RandomEventManager:getInstance().eventList[idx]
        else
            local tmpidx = idx - #RandomEventManager:getInstance().eventList
            mission = MissionManagers:getInstance():getAllMissions()[tmpidx]
            local startTime, time = mission:getMissionTimes()
            event = RandomEvent:create(RandomEvent.EventType.RandomEventMission, 0, 0, startTime, time, mission:getDescription())

        end

        local csv = DataManager:getInstance():getCSVByID(csvOfRandomEvent)
        local data = csv[tostring(event.type)]

        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()

        -- background
        local bg = cc.Scale9Sprite:create("Images/UI/tankuang_04.png")
        bg:setPreferredSize(cc.size(530, 300.0))
        bg:setPosition(265.0, 150.0)
        cell:addChild(bg)

        -- icon
        local iconBg = cc.Sprite:create("Images/UI/shijd_01.png")
        iconBg:setPosition(cc.p(50.0, 190.0))
        cell:addChild(iconBg)
        local icon = cc.Sprite:create("Images/UI/"..data.icon)
        icon:setPosition(iconBg:getPosition())
        cell:addChild(icon)

        -- labelInfo
        local labelInfo = cc.LabelTTF:create(event.description, BoldFont, 24.0)
        labelInfo:setPosition(110.0, 280.0)
        labelInfo:setAnchorPoint(cc.p(0.0, 1.0))
        labelInfo:setDimensions(cc.size(400,100))
        labelInfo:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        labelInfo:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        cell:addChild(labelInfo)

        -- labelTime
        local labelTime = cc.LabelTTF:create(string.format("剩余时间：\n%s",
            formatSecondToTimeCn(event.lifeTime-(os.time()-event.startTime))), BoldFont, 22.0)
        labelTime:setColor(YellowColor)
        labelTime:setPosition(300.0, 165.0)
        labelTime:setAnchorPoint(cc.p(0.0, 1.0))
--        labelTime:setDimensions(cc.size(400,200))
        labelTime:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        labelTime:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        cell:addChild(labelTime)

        local function update()
            if tonumber(event.type) == RandomEvent.EventType.RandomEventMission and tonumber(event.lifeTime) == -1 then
                labelTime:setVisible(false)
            else
                labelTime:setString(string.format("剩余时间：\n%s",
                    formatSecondToTimeCn(event.lifeTime-(os.time()-event.startTime))))
                if event.lifeTime-(os.time()-event.startTime) <=0 then
                    RandomEventManager:getInstance():removeEvent(event)
                    self.tableview1:reloadData()
                end
            end
        end
        labelTime:scheduleUpdateWithPriorityLua(update, 0)

        if tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
            -- 奖励
            local rewards = mission:getRewards()
            if #rewards > 0 then
                local reward = rewards[1]
                local iconName = ""
                if reward.goodsType == 2 then -- 物品
                    local csv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
                    local prop = csv[tostring(reward.id)]
                    iconName = prop.iconName
                elseif reward.goodsType == 1 then -- 英雄
                    local csv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
                    local hero = csv[tostring(reward.id)]
                    iconName = hero.icon
                end
                local spJL = cc.Sprite:create("Images/UI/jiangl_01.png")
                spJL:setAnchorPoint(cc.p(0.0, 0.5))
                spJL:setPosition(120.0, 150.0)
                cell:addChild(spJL)
                if iconName and string.len(iconName) > 3 then
                    local rewardIcon = cc.Sprite:create(string.format("Images/Icon/%s", iconName))
                    rewardIcon:setPosition(150.0, 100.0)
                    rewardIcon:setScale(0.8)
                    cell:addChild(rewardIcon)
                    local rewardLabel = cc.LabelTTF:create(string.format("×%d", reward.num), BoldFont, 28.0)
                    rewardLabel:setColor(YellowColor)
                    rewardLabel:setPosition(cc.p(180, 90.0))
                    rewardLabel:setAnchorPoint(cc.p(0.0, 0.5))
                    cell:addChild(rewardLabel)
                end
            end
        end

        -- buttons
        local jinbiButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        jinbiButton:setScale(0.8)
        jinbiButton:setPosition(cc.p(150.0, 40.0))
        jinbiButton:registerScriptTapHandler(function()
            if RandomEventLayer.instance then
                if tonumber(event.type) == RandomEvent.EventType.RandomEventTalent then
                    if not RandomEventLayer.instance:handleEvent(event, 1) then
                        RandomEventManager:getInstance():removeEvent(event)
                        self.tableview1:reloadData()
                    end
                elseif tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
                    MissionManagers:getInstance():giveUpTheMission(mission)
                    self.tableview1:reloadData()
                else
                    RandomEventManager:getInstance():removeEvent(event)
                    self.tableview1:reloadData()
                end
            end
        end)
        local jinbiButtonSize = jinbiButton:getContentSize()
        local jinbiButtonLabel = cc.LabelTTF:create("取消", BoldFont, 32.0)
        jinbiButtonLabel:setColor(cc.c3b(255,255,255))
        jinbiButtonLabel:setPosition(cc.p(jinbiButtonSize.width/2, jinbiButtonSize.height/2))
        jinbiButton:addChild(jinbiButtonLabel)

        local diamondButton = cc.MenuItemImage:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        diamondButton:setScale(0.8)
        diamondButton:setPosition(cc.p(530.0-150.0, 40.0))
        diamondButton:registerScriptTapHandler(function()
            if RandomEventLayer.instance then
                if tonumber(event.type) == RandomEvent.EventType.RandomEventTalent then
                    if not RandomEventLayer.instance:handleEvent(event, 2) then
                        RandomEventManager:getInstance():removeEvent(event)
                        self.tableview1:reloadData()
                    end
                elseif tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
                    if mission:getMissionStatue() == "wait" then
                        mission:completedMissionByCosted()
                    elseif mission:getMissionStatue() == "complete" then
                        mission:receive()
                    end
                    self.tableview1:reloadData()
                else
                    if not RandomEventLayer.instance:handleEvent(event) then
                        RandomEventManager:getInstance():removeEvent(event)
                        self.tableview1:reloadData()
                    end
                end
            end
        end)
        local diamondButtonSize = diamondButton:getContentSize()
        local diamondButtonLabel = cc.LabelTTF:create("确定", BoldFont, 32.0)
        diamondButtonLabel:setColor(cc.c3b(255,255,255))
        diamondButtonLabel:setPosition(cc.p(diamondButtonSize.width/2, diamondButtonSize.height/2))
        diamondButton:addChild(diamondButtonLabel)


        if tonumber(event.type) == RandomEvent.EventType.RandomEventTalent then
            local talent = DataManager:getInstance():getCSVByID(csvOfTalent)[tostring(event.talentId)]
            jinbiButtonLabel:setString("金币学习")
            local iconGold = cc.Sprite:create("Images/UI/CoinBg.png")
            iconGold:setPosition(cc.p(jinbiButton:getPositionX()-20.0, jinbiButton:getPositionY()+40.0))
            iconGold:setAnchorPoint(cc.p(1.0, 0.5))
            iconGold:setScale(0.6)
            cell:addChild(iconGold)
            local jinbiCostLabel = cc.LabelTTF:create(string.format("×%s", talent.resumeCoin), BoldFont, 22.0)
            jinbiCostLabel:setColor(YellowColor)
            jinbiCostLabel:setPosition(cc.p(jinbiButton:getPositionX()-20.0, jinbiButton:getPositionY()+40.0))
            jinbiCostLabel:setAnchorPoint(cc.p(0.0, 0.5))
            cell:addChild(jinbiCostLabel)

            diamondButtonLabel:setString("钻石学习")
            local iconDiamond = cc.Sprite:create("Images/UI/DiamondBg.png")
            iconDiamond:setPosition(cc.p(diamondButton:getPositionX()-20.0, diamondButton:getPositionY()+40.0))
            iconDiamond:setAnchorPoint(cc.p(1.0, 0.5))
            iconDiamond:setScale(0.6)
            cell:addChild(iconDiamond)
            local diamondCostLabel = cc.LabelTTF:create(string.format("×%s", talent.resumeNum), BoldFont, 22.0)
            diamondCostLabel:setColor(YellowColor)
            diamondCostLabel:setPosition(cc.p(diamondButton:getPositionX()-20.0, diamondButton:getPositionY()+40.0))
            diamondCostLabel:setAnchorPoint(cc.p(0.0, 0.5))
            cell:addChild(diamondCostLabel)
        elseif tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
            jinbiButtonLabel:setString("放 弃")
            local stateLabel = cc.LabelTTF:create("", BoldFont, 28.0)
            stateLabel:setColor(RedColor)
            stateLabel:setPosition(cc.p(diamondButton:getPositionX(), 90.0))
            cell:addChild(stateLabel)
            if mission:getMissionStatue() == "wait" then
--                stateLabel:setString(string.format("未完成", 0))
                diamondButtonLabel:setString("一键完成")

                local iconDiamond = cc.Sprite:create("Images/UI/DiamondBg.png")
                iconDiamond:setPosition(cc.p(diamondButton:getPositionX()-20.0, diamondButton:getPositionY()+40.0))
                iconDiamond:setAnchorPoint(cc.p(1.0, 0.5))
                iconDiamond:setScale(0.6)
                cell:addChild(iconDiamond)
                local diamondCostLabel = cc.LabelTTF:create(string.format("×%s", mission:getCosts()), BoldFont, 22.0)
                diamondCostLabel:setColor(YellowColor)
                diamondCostLabel:setPosition(cc.p(diamondButton:getPositionX()-20.0, diamondButton:getPositionY()+40.0))
                diamondCostLabel:setAnchorPoint(cc.p(0.0, 0.5))
                cell:addChild(diamondCostLabel)
            elseif mission:getMissionStatue() == "complete" then
                stateLabel:setString(string.format("已完成", 0))
                diamondButtonLabel:setString("领 奖")
            end
        end
        menu = cc.Menu:create(jinbiButton, diamondButton)
        menu:setPosition(cc.p(0, 0))
        cell:addChild(menu)

        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)
    self.tableview1:registerScriptHandler(function(view, idx)

        return 310, 530.0 -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableview1:registerScriptHandler(function(view)
        local num = #(RandomEventManager:getInstance().eventList)+#(MissionManagers:getInstance():getAllMissions())
        return num
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableview1:reloadData()
    background:addChild(self.tableview1)


    local function update()
        self:update()
    end
    self:scheduleUpdateWithPriorityLua(update, 0)

    return true
end

function RandomEventView:update()
    for i=1,#RandomEventManager:getInstance().eventList do
        local event = RandomEventManager:getInstance().eventList[i]
        if os.time() - event.startTime >= event.lifeTime then
            RandomEventManager:getInstance().removeEvent(event)
            self.tableview1.reloadData()
            return
        end
    end
end

