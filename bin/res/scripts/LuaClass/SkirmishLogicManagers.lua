require "LuaClass/Header"
require "LuaClass/WoWUtils"

--遭遇战遇怪的逻辑
--[[
1.所需道具遇怪(在玩家背包数据初始化或者战斗背包掉落数据整合的时候，对特殊道具进行标记，然后利用标记的特殊功能，进行几率筛选)
2.杀怪遇怪逻辑，在每次初始化怪物的时候进行判断，若该怪物为标记的怪，在战斗成功时，加入任务怪队列，然后在野外遇怪的时候，对数量和区域进行筛选,若满足，再做随机比率筛选
3.据点遇怪逻辑，在每次据点占领时候判断其是否和遇怪逻辑相关联，若关联，则添加到队列中，然后在野外遇怪的时候，对数量和区域进行筛选,若满足，再做随机比率筛选
4.以上三种任意一种排列组合(所以，借口与借口)
5.未知
6.未知
]]

local skirmishLogicManagers = nil

SkirmishLogicManagers = class("SkirmishLogicManagers",function ()
     return {}
end)

--encounters 当前地图可触发的遭遇
--validEncounters 当前位置可触发的遭遇
--curEncounter通过随机概率后获得的遭遇
SkirmishLogicManagers.__index = SkirmishLogicManagers
SkirmishLogicManagers.data = nil
SkirmishLogicManagers.encounters = {}
SkirmishLogicManagers.validEncounters = nil
SkirmishLogicManagers.curEncounter = nil
SkirmishLogicManagers.posRangs = nil
SkirmishLogicManagers.costs = nil
local function createManger()
    -- print("EventManger:create()!");

    local manger = SkirmishLogicManagers.new()
    
    if manger and manger:init() then
        return manger
    end

    return nil
end

function SkirmishLogicManagers:getInstance(  )
    
    if skirmishLogicManagers == nil then
        skirmishLogicManagers = createManger()
    end

    return skirmishLogicManagers
end

function SkirmishLogicManagers:init(  )
    self.posRangs = {}
    return true
end



--在这我只用做地图和次数限制的筛选
function SkirmishLogicManagers:screeningEncounters(  )
    
    local csvData = DataManager:getInstance():getCSVByID(csvOfEncounter)

    self.encounters = {}
    self.posRangs = {}

    local missionHistory = DataManager:getInstance():getRoleData(roleCompletedMissionHistory)
    if not missionHistory then
        missionHistory = {}
    end
    local mapIndex = getExplor().mapIndex

    local encounterLimits = nil
    local encounterMapIndex = nil

    local rangeInfo = nil

    for k,v in pairs(csvData) do
        encounterMapIndex = tonumber(v["trigger"])
        rangeInfo = v["area"][1]

        k = "E"..k
        -- print("encounterMapIndex == mapIndex",encounterMapIndex,mapIndex,missionHistory[k])
        if encounterMapIndex == mapIndex and (not missionHistory[k] or (missionHistory[k] and missionHistory[k] > 0)) then
            self.encounters[#self.encounters + 1] = v
            self:addPosRangeByEncounterInfos(rangeInfo)
        end
    end

    print("screeningEncounters",#self.encounters)
end

function SkirmishLogicManagers:addPosRangeByEncounterInfos( info )

    if not info then
        return
    end

    local posRangType = info[1]
    local range = {}
    local manger = getExplor().mapLayoutManagers
    local pos = nil

    -- printn("addPosRangeByEncounterInfos",posRangType)

    --1是据点,2坐标范围
    if posRangType == "1" then
        local len = tonumber(info[3])
        local id = info[2]
        local strongholdInfos = manger:getStongholdInfosById(id)
        pos = strongholdInfos.pos

        range.minx = pos.x - len
        range.maxx = pos.x + len

        range.miny = pos.y - len
        range.maxy = pos.y + len

    elseif posRangType == "2" or posRangType == "20" then
        pos = {}

        pos.x = tonumber(info[2])
        pos.y = tonumber(info[4])

        local width = tonumber(info[3])
        local height = tonumber(info[5])

        range.minx = pos.x 
        range.maxx = pos.x + width
        range.maxy = pos.y + height
        range.miny = pos.y

    end

    self.posRangs[#self.posRangs + 1] = range
end

--[[
table.curMapStrongholdNum
table.clearStrongHoldNum
table.fogs
table.titlesInfo {}(pos_key)

table.titlesInfo:
table.titlesInfo.strongholdInfos(id,gid,statues 1开启/2占领)
table.titlesInfo.fogId
]]

--当前位置的有效怪物(在此时筛选时候做个标记)
function SkirmishLogicManagers:validEnemyInCurPosition(  )

    local explor = getExplor()

    --获得玩家坐标
    local curPosition = cc.p(explor.player:getPositionX(),explor.player:getPositionY())
    curPosition = explor:tileCoordForPosition(curPosition)

    self.validEncounters = {}
    printn("curPosition",curPosition)
    local encounter = nil
    local range = nil
    for i=1,#self.posRangs do
        range = self.posRangs[i]
        printn("curPosition",range)

        --位置范围判断
        if range.minx - 1 < curPosition.x and range.maxx + 1 > curPosition.x and range.miny - 1 < curPosition.y and range.maxy + 1 > curPosition.y then
            self.validEncounters[#self.validEncounters + 1] = self.encounters[i]
        end
    end

    print("validEnemyInCurPosition",#self.validEncounters)

end

--检测遇怪道具，筛选出满足条件的怪物
function SkirmishLogicManagers:checkProps( )
   


end

--[[
0默认
1携带英雄
2携带物品
3占领据点
4怪物击杀
5任务触发
]]

--根据条件筛选出可能触发的怪物
function SkirmishLogicManagers:checkValidEncountersByConditions( )
    local temp = {}

    local encounter = nil
    local encounterType = nil
    local encounterLimits = nil
    local encounterMapIndex = nil

    --杀怪记录
    local defeatedHistory = DataManager:getInstance():getRoleData(roleDefeatedHistory)

    if not defeatedHistory then
        defeatedHistory = {}
    end

    --参战人员
    local warriors = DataManager:getInstance():getRoleData(roleBattleQueue)


    local id = 0
    local num = 0
    local manger = nil
    local rangeInfo = nil

    for i=1,#self.validEncounters do
        encounter = self.validEncounters[i]
        encounterType = encounter["Type"]

        if encounterType[1][1] == "0" then
            
            temp[#temp + 1] = encounter
        
        elseif encounterType[1][1] == "1" then
            id = encounterType[1][2]
            num = tonumber(encounterType[1][3])
            
            --人物id及其数量检测
            if warriors[id] and warriors[id] > num - 1 then
                temp[#temp + 1] = encounter
            end

        elseif encounterType[1][1] == "3" then
            id = encounterType[1][2]
            num = tonumber(encounterType[1][3])

            --判断是否携带了足够的物品
            if ExploreBagController:getBagController():checkItemsIsHaveByIdAndNum(id,num)  then
                temp[#temp + 1] = encounter
            end

        elseif encounterType[1][1] == "4" then
            id = encounterType[1][2]
            num = tonumber(encounterType[1][3])

            if defeatedHistory[id] and defeatedHistory[id] > num then
                temp[#temp + 1] = encounter
            end

        elseif encounterType[1][1] == "5" then
            id = encounterType[1][2]
            num = tonumber(encounterType[1][3])

            manger = MissionManagers:getInstance()

            --判断是否是有效任务
            if manger:missionsIsInValidMissions(id) then
                temp[#temp + 1] = encounter
            end
        end

    end

    self.validEncounters = temp

end

--检测杀怪记录,继续筛选
function SkirmishLogicManagers:checkMonstersRecord(  )
    

end

--检测据点记录，最后筛选
function SkirmishLogicManagers:checkStrongholdRecord(  )
    -- body
end

function SkirmishLogicManagers:useTheDice(  )
    --清空
    self.curEncounter = nil
    --当前骰子投掷出来的数
    local dicePoint = math.random() * 100000 % 101
    local encounter = nil
    local rate = nil

    local temp = {}
    print("curDiceNum",dicePoint)
    for i=1,#self.validEncounters do
        encounter = self.validEncounters[i]
        rate = tonumber(encounter["rate"])
        rate = 100

        if rate > dicePoint - 1 then
            temp[#temp + 1] = encounter
        end

    end

    if #temp > 0 then
        local rang = {}
        rang.min = 1
        rang.max = #temp
        local index = getRandomNumByRange(rang)
        self.curEncounter = temp[index]

        local costs = self.curEncounter["consumption"]
        -- printn("useTheDice",costs)
        if costs[1][1] == "0" then
            costs = nil
        end

        self.costs = costs

        if self.costs then
            local costtype = self.costs[1][1]
            local id = self.costs[1][2]
            local num = (tonumber(self.costs[1][3]))
            
            --若是战斗前消耗类型,否则保留
            if costtype == "1" then
                ExploreBagController:getBagController():costGoodsByGoodsIdAndNum(id,num)
                self.costs = nil
            else
                self.costs = {}
                self.costs.id = id
                self.costs.num = num
            end
            -- printn("useTheDice",self.costs)
        end

    end

end

--接入函数
function SkirmishLogicManagers:tryMeetSpecialMonster(  )
    self:validEnemyInCurPosition()
    self:checkValidEncountersByConditions()

    self:useTheDice()

    local enemys = nil

    if self.curEncounter then
        local temp = self.curEncounter["Enemys"]
        enemys = {}

        for i=1,#temp do
            enemys[1] = temp[1][1]
            enemys[2] = temp[1][2]
        end
    end


    return enemys
end

--一个遭遇战斗胜利
function SkirmishLogicManagers:minesweeperFightIsOver(  )
    
    --不是特殊战斗，不做操作
    if not self.curEncounter then
        return
    end

    --杀死特殊怪，将改怪物的剩余次数做更变，另外修改怪物数据
    local missionHistory = DataManager:getInstance():getRoleData(roleCompletedMissionHistory)
    if not missionHistory then
        missionHistory = {}
    end

    local id = self.curEncounter["ID"]

    local limits = tonumber(self.curEncounter["frequency"])

    local remain = missionHistory["E"..id]

    if not remain then
        remain = limits
    end

    remain = remain - 1

    missionHistory["E"..id] = remain

    DataManager:getInstance():setRoleData(roleCompletedMissionHistory,missionHistory)

    if remain == 0 then
        local index = nil
        for i=1,#self.encounters do
            
            if self.encounters[i] == self.curEncounter then
                index = i
                break
            end

        end

        table.remove(self.encounters,index)
        table.remove(self.posRangs,index)

    end


    --若还有消耗物，则消耗
    if self.costs then
        printn("minesweeperFightIsOver",self.costs)
        ExploreBagController:getBagController():costGoodsByGoodsIdAndNum(self.costs.id,self.costs.num)
        self.costs = nil
    end

    --清空
    self.curEncounter = nil
end

