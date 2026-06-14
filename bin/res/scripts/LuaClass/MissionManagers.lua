require "LuaClass/Header"
require "LuaClass/WoWUtils"


Mission = class("Mission",function ()
     return {}
end)

--任务超时就删除

--strongholdNum
--clearStrongHoldNum
--Associated关联的信息，只提供查找
Mission.__index = Mission
Mission.id = nil
Mission.infos = nil
Mission.statue = nil
Mission.complete = nil   --有可能有多个任务目标 table
Mission.total = nil      --有可能有多个任务目标 table
Mission.startTime = nil
Mission.time = nil
Mission.icon = nil
Mission.rewards = nil
Mission.price = nil
Mission.costGodds = nil
function Mission:createMissionByMissionID( ID )
    mission = Mission.new()

    if mission and mission:init(ID) then
        return mission
    end

    return nil
end

function Mission:init( ID )
    self.id = ID
    self.statue = "wait"

    local csvdata = DataManager:getInstance():getCSVByID(csvOftask)
    if self.id then
        print("self.id",ID)
        self.infos = csvdata[self.id]
        self.total = {}
        local goodId = nil

        for i=1,#self.infos["complete"] do
            goodId = self.infos["complete"][i][1]
            self.total[goodId] = tonumber(self.infos["complete"][i][2])
        end

        self.time = tonumber(self.infos["time"])

        -- printn("infos",self.infos)

        self.rewards = self.infos["reward"]

        if self.rewards[1][1] == "0" then
            self.rewards = {}
        end

        self.limits = tonumber(self.infos["frequency"])
        self.price = tonumber(self.infos["cost"])
        self.mapIndex = tonumber(self.infos["trigger"])
        self.costGodds = self.infos["killItems"]

        if self.costGodds[1][1] == "0" then
            self.costGodds = {}
        end

    end

    return true
end

function Mission:begain(  )
    self.startTime = NotificationNode:getInstance():GetGameTime()
end


function Mission:completed(  )
    -- self.complete = self.total
    self.statue = "complete"
end

function Mission:checkTime(  )
    if self.statue ~= "wait" or self.time < 0 then
        return true
    end

    local curTime = NotificationNode:getInstance():GetGameTime()
    local disTime = self.startTime + self.time - curTime
    if disTime < 0 then
        return false
    end 

    return true
end


--任务完成了某一步
function Mission:completeOneStep( stepId,num )


    print("completeOneStep",stepId,num)

    if not stepId then
        return
    end

    if not num then
        num = 1
    end

    local stepId = tostring(stepId)

    if not self.complete then
        self.complete = {}
    end

    if not self.complete[stepId] then
        self.complete[stepId] = {}
        self.complete[stepId].num = 0
    end

    self.complete[stepId].num = self.complete[stepId].num + num

    local statue = self.complete[stepId].statue 

    --若是没完成的任务且当前任务某一步还没有完成，则判断当前这一步和当前任务是否都完成
    if self.statue ~= "complete" and not statue then
        local totalNum = self.total[stepId]
        
        print("totalNum",totalNum,self.complete[stepId].num)
        if totalNum == self.complete[stepId].num then
            self.complete[stepId].statue = "complete"

            statue = "complete"

            --一旦有一步没有完成，就认为任务没有完成
            for k,v in pairs(self.total) do
                --获取对应的完成数据
                v = self.complete[k]
                --若数据没有或者数据的状态没有，则没有完成
                if not v or not v.statue then
                    print("NotificationNode",k)
                    statue = nil
                    break
                end
            end

            --一旦都有状态记录，就算完成了
            if statue then
                self:completed()
            end
        end
    end

end



--供数据存储用
function Mission:getSaveData(  )
    local data = {}
    data.id = self.id

    local statue = nil
    print("getSaveData",self.statue)
    if self.statue == "wait" then
        statue = 1
    elseif self.statue == "complete" then
        statue = 2
    end

    data.statue = statue

    data.complete = self.complete

    data.time = self.startTime
    printn("getSaveData",data)
    return data
end


--供数据初始化任务用
function Mission:loadMissionInfoByData( data )

    if not data then
        return
    end

    self.id = data.id
    self.startTime = data.time

    local statue = data.statue

    print("loadMissionInfoByData",statue)

    if statue == 1 then

        self.statue = "wait"

    elseif statue == 2 then

        self.statue = "complete"

    end

    self.complete = clone(data.complete)
    printn("self.complete",self.complete,data)

    local csvdata = DataManager:getInstance():getCSVByID(csvOftask)

    self.infos = csvdata[self.id]
    self.total = {}
    local goodId = nil

    for i=1,#self.infos["complete"] do
        goodId = self.infos["complete"][i][1]
        self.total[goodId] = tonumber(self.infos["complete"][i][2])
    end

    self.time = tonumber(self.infos["time"])
    self.rewards = self.infos["reward"]

    if self.rewards[1][1] == "0" then
        self.rewards = {}
    end

    self.limits = tonumber(self.infos["frequency"])
    self.price = tonumber(self.infos["cost"])
    self.mapIndex = tonumber(self.infos["trigger"])

    self.costGodds = self.infos["killItems"]

    if self.costGodds[1][1] == "0" then
        self.costGodds = {}
    end
end


-- --公共接口
function Mission:getMissionId(  )
    return self.id
end

--获取任务状态接口,wait(等待完成),complete(已经完成)
function Mission:getMissionStatue(  )
    return self.statue
end


function Mission:getLimits(  )
    return self.limits
end

--获取一键完成的花费
function Mission:getCosts( )
    return self.price
end

--图片
function Mission:getIcon(  )
    return self.icon
end

--显示界面使用,获取奖励信息
function Mission:getRewards(  )
    
    local goodsInfo = nil
    local goodsId = nil
    local goodsNum = nil
    local goodsType = nil

    local goodCsvData = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    local soldiersCsvData = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)

    local rewards = {}
    for i=1,#self.rewards do
        goodsInfo = self.rewards[i]
        goodsType = goodsInfo[1]
        goodsId = goodsInfo[2]
        goodsNum = goodsInfo[3]
        local reward = {}
        reward.id = goodsId
        reward.num = tonumber(goodsNum)
        --1英雄，2物品
        if goodsType == "1" then
            goodsInfo = soldiersCsvData[goodsId]
            reward.name = goodsInfo["name"]
            reward.star = goodsInfo["star"]
            reward.des = goodsInfo["description"]
            reward.icon = goodsInfo["icon"]
            reward.goodsType = 1
        elseif goodsType == "2" then
            goodsInfo = goodCsvData[goodsId]
            reward.name = goodsInfo["name"]
            reward.star = goodsInfo["starNum"]
            reward.des = goodsInfo["desc"]
            reward.icon = goodsInfo["iconName"]
            reward.goodsType = 2
        end

        rewards[#rewards + 1] = reward
    end

    return rewards
end

--获取开始时间和持续时间
function Mission:getMissionTimes(  )

    -- if self.statue ~= "complete" then
    --     return 0
    -- end

    -- local curTime = NotificationNode:getInstance():GetGameTime()
    -- local disTime = self.startTime + self.time - curTime

    return self.startTime,self.time
end


--描述
function Mission:getDescription(  )
    return self.infos["desc"]
end

--一键完成
function Mission:completedMissionByCosted(  )
    
    if DataManager:getInstance():addDiamond(-self.price) == 0 then
        return false
    end

    if not self.complete then
        self.complete = {}
    end

    for k,v in pairs(self.total) do
        --获取对应的完成数据
        self.complete[k] = {}
        self.complete[k].num = v
        self.complete[k].statue = 1
    end

    self:completed()

    --更改任务的文档数据
    MissionManagers:getInstance().completedMissions[self.id] = self
    MissionManagers:getInstance().waitingMissions[self.id] = nil
    MissionManagers:getInstance().datas[self.id] = self:getSaveData()
    MissionManagers:getInstance():saveMissionDatas()

    return true
end

--领取奖励,调missionmanager和这个都可以，不会发生冲突
function Mission:receive(  )

    if self.statue ~= "complete" then
        return
    end

    self.statue = "receive"
    MissionManagers:getInstance():tryReceiveMissionRewardsByMissionID(self.id)

    --领取
    local goodsInfo = nil
    local goodsId = nil
    local goodsNum = nil
    local goodsType = nil
    local goodsName = nil
    local goodCsvData = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

    --检测是否需要扣除物品
    for i=1,#self.costGodds do
        goodsInfo = self.costGodds[i]
        goodsId = goodsInfo[1]
        goodsNum = goodsInfo[2]
        goodsName = goodCsvData[goodsId]["name"]

        if goodsName == "金币"  then
            DataManager:getInstance():addCoin(-tonumber(goodsNum))
        elseif goodsName == "钻石" then
            DataManager:getInstance():addDiamond(-tonumber(goodsNum))
        else
            DataManager:getInstance():addPackItemWithId(goodsId, -tonumber(goodsNum))
        end
    end

    for i=1,#self.rewards do
        goodsInfo = self.rewards[i]
        goodsType = goodsInfo[1]
        goodsId = goodsInfo[2]
        goodsNum = goodsInfo[3]
        goodsName = goodCsvData[goodsId]["name"]
        --1英雄，2物品
        if goodsType == "1" then

            DataManager:getInstance():addSoilderWithId(goodsId,tonumber(goodsNum))

        elseif goodsType == "2" then
           
            if goodsName == "金币"  then
                DataManager:getInstance():addCoin(tonumber(goodsNum))
            elseif goodsName == "钻石" then
                DataManager:getInstance():addDiamond(tonumber(goodsNum))
            else
                DataManager:getInstance():addPackItemWithId(goodsId, tonumber(goodsNum))
            end

        end
    end

    --领取完毕后可触发下一个任务
    local nextMission = self.infos["next"] 

    DataManager:getInstance():triggerMissionByIDAndStepInfos(nextMission,"1","auto")

end


local missionLimitNum = 5

local missionManagers = nil

MissionManagers = class("MissionManagers",function ()
     return {}
end)

--waitingMissions 等待完成的任务
--validMissions 当前可完成的任务,取决于当前探索地图的环境
--completedMissions 已经完成还未领取的任务
--missions 所有任务
MissionManagers.__index = MissionManagers
MissionManagers.missions = nil
MissionManagers.waitingMissions = nil
MissionManagers.validMissions = nil
MissionManagers.completedMissions = nil
MissionManagers.datas = nil
MissionManagers.UIMissions = nil
local function createManger()
    -- print("EventManger:create()!");

    local manger = MissionManagers.new()
    
    if manger and manger:init() then
        return manger
    end

    return nil
end

function MissionManagers:getInstance(  )
    
    if missionManagers == nil then
        missionManagers = createManger()
    end

    return missionManagers
end

function MissionManagers:init(  )
    --便于索引,string和num通用
    self.missions = getCustomTable()
    self.waitingMissions = getCustomTable()
    self.completedMissions = getCustomTable()
    self.validMissions = getCustomTable()
    self.UIMissions = {}
    self:loadAndAnalysisMissionDatas()
    return true
end


--内部数据获取及筛选
--筛选出validMissions
function MissionManagers:checkMissions(mapIndex, showTip)

    self.validMissions = nil
    self.validMissions = getCustomTable()

    --若没有等待完成的任务，就不用做任何操作
    if not self.waitingMissions then
        return
    end

    

    local mission = nil
    local id = nil
    for i=1,self.waitingMissions.len do
        mission = self.waitingMissions[i]
        id = mission:getMissionId()
        --若和当前地图索引一样，或者根本没有地图限制就添加进去
        if mapIndex == 0 or mission.mapIndex == mapIndex then
            self.validMissions[id] = mission
        end
    end
    if not showTip then -- 不显示提示
        local tipstring = string.format("可完成任务有%d个",self.validMissions.len)
        ToastUtil:toastString(tipstring)
    end
end

--从读取用户数据，并将其转换成Mission对象,便于操作
function MissionManagers:loadAndAnalysisMissionDatas(  )

    local missionDatas = DataManager:getInstance():getRoleData(roleMission)


    if missionDatas == nil then
        missionDatas = {}
    end
    -- printn("loadAndAnalysisMissionDatas",missionDatas)
    self.datas = getCustomTable()

    --根据存储的任务数据，来初始化任务
    local i = 1

    while i < #missionDatas + 1 do

        local data = missionDatas[i]

        local mission = Mission:createMissionByMissionID()
        mission:loadMissionInfoByData(data)

        --若还是有效时间，则加入到任务队列中,否则直接删除数据
        if mission:checkTime() then
            local missionId = mission:getMissionId()
            self.missions[missionId] = mission

            self.datas[missionId] = data

            --加入到等待队列
            if mission:getMissionStatue() == "wait" then
                self.waitingMissions[missionId] = mission

            --加入完成队列
            elseif mission:getMissionStatue() == "complete" then
                self.completedMissions[missionId] = mission
            end
            i = i + 1
        else
            table.remove(missionDatas,i)
        end
    end

    local tipstring = string.format("完成任务有%d个,未完成的有%d个",self.completedMissions.len,self.waitingMissions.len)
    ToastUtil:toastString(tipstring)

    -- for i=1,#missionDatas do
    --     local data = missionDatas[i]

    --     local mission = Mission:createMissionByMissionID()
    --     mission:loadMissionInfoByData(data)

    --     --若还是有效时间，则加入到任务队列中,否则直接删除数据
    --     if mission:checkTime() then
    --         local missionId = mission:getMissionId()
    --         self.missions[missionId] = mission

    --         self.datas[missionId] = data

    --         --加入到等待队列
    --         if mission:getMissionStatue() == "wait" then
    --             self.waitingMissions[missionId] = mission

    --         --加入完成队列
    --         elseif mission:getMissionStatue() == "complete" then
    --             self.completedMissions[missionId] = mission
    --         end

    --     else
    --         table.remove(missionDatas,i)
    --         i = i - 1
    --     end
    -- end
    --将筛选后的任务数据存入文档里
    DataManager:getInstance():setRoleData(roleMission,missionDatas)
end

--存储当前任务信息
function MissionManagers:saveMissionDatas(  )

    printn("saveMissionDatas",self.datas.datas)
    local tipstring = string.format("当前任务有%d个",self.datas.len)
    ToastUtil:toastString(tipstring)
    DataManager:getInstance():setRoleData(roleMission,self.datas.datas)
end


--触发一个任务(也可能是更新任务的进度,内部处理)
function MissionManagers:triggerMissionByIDAndStepInfos( ID,stepInfos,keys )
    
    if not ID or not stepInfos or ID == "0" then
        return
    end

    if keys == nil then
        keys = "none"
    end

    local mission = self.missions[ID]

    --检查当前任务中有该任务不
    if mission then

        printn("will completed",stepInfos,keys)

        --若超时，则进行删除操作
        if not mission:checkTime() then
            self.missions[ID] = nil
            self.waitingMissions[ID] = nil
            self.validMissions[ID] = nil
            return
        end

        if keys ~= "taskOk" then
            return
        end

        printn("will completed",stepInfos)

        local stepid = stepInfos.id
        local stepNum = stepInfos.num

        local statue = mission:getMissionStatue()
        --存在直接进行任务完成
        mission:completeOneStep(stepid,stepNum)
        print("will completed2",statue,mission:getMissionStatue())
        --若之前状态处于未完成状态，则
        if statue ~= "complete" and mission:getMissionStatue() == "complete" then
            --放入到完成队列
            self.completedMissions[ID] = mission
            --从等待队列中删除
            self.waitingMissions[ID] = nil 

            local tipstring = string.format("完成任务有%d个,未完成的有%d个",self.completedMissions.len,self.waitingMissions.len)
            ToastUtil:toastString(tipstring)
        end

        self.datas[ID] = mission:getSaveData()
        printn("self.datas[ID]",self.datas[ID],self.datas.datas)
        --进行数据存储
        self:saveMissionDatas()
    else
        if keys ~= "taskID" and keys ~= "auto" then
            return
        end

        --不存在，检索是否限制次数已经用完
        mission = Mission:createMissionByMissionID(ID)

        local limits = mission:getLimits()

        --若有限制，进行限制权限查看
        if limits > 0 then

            local missionHistory = DataManager:getInstance():getRoleData(roleCompletedMissionHistory)

            if not missionHistory then
                missionHistory = {}
            end

            local remain = missionHistory[ID]

            remain = nil

            if not remain then
                remain = limits
            end

            if remain > 0 then
                self.validMissions[ID] = mission
                self.missions[ID] = mission
                self.waitingMissions[ID] = mission
                remain = remain - 1
                --开始计时
                mission:begain()
                local data = mission:getSaveData()
                -- printn("getSaveData",data)
                self.datas[ID] = data
                self:saveMissionDatas()
            end

            missionHistory[ID] = remain

            DataManager:getInstance():setRoleData(roleCompletedMissionHistory,missionHistory)

        --否则进行入队列操作
        else
            self.validMissions[ID] = mission
            self.missions[ID] = mission
            self.waitingMissions[ID] = mission
            --开始计时
            mission:begain()
            local data = mission:getSaveData()
            self.datas[ID] = data
            self:saveMissionDatas()
        end
    end
end


--外部交互接口
--触发一个任务(也可能是更新任务的进度,外部调用)
function MissionManagers:onTriggerMission( taskID,taskOk,stepInfos )

    if (not taskID and not taskOk) or not stepInfos then
        return
    end

    if taskID and taskID ~= "0" then
        self:triggerMissionByIDAndStepInfos(taskID,stepInfos,"taskID")
    elseif taskOk and taskOk ~= "0" then
        self:triggerMissionByIDAndStepInfos(taskOk,stepInfos,"taskOk")
    end

end

--领取奖励的接口(从任务队列中进行删除操作)
function MissionManagers:tryReceiveMissionRewardsByMissionID( ID )
    if not ID  then
        return
    end   

    local mission = self.completedMissions[ID]

    if mission.statue == "wait" then
        return
    end

    if mission then
        self.missions[ID] = nil
        self.completedMissions[ID] = nil
        self.datas[ID] = nil
        if mission:getMissionStatue() == "complete" then
            mission:receive()
        end
        self:saveMissionDatas()
        self:removeMissionInUI(nil,ID)
    end

end

--删除供外部的界面操作数组对应的任务
function MissionManagers:removeMissionInUI( mission,Id )
    if not mission and not id then
        return
    end

    if mission then
        id = mission:getMissionId()
    end

    local temp = nil
    for i=1,#self.UIMissions do
        mission = self.UIMissions[i]
        temp = mission:getMissionId()
        if temp == id then
            table.remove(self.UIMissions)
            break
        end
    end

end

--获得未完成的任务队列
function MissionManagers:getWaitingMissions( )

    local mission = nil
    local missionID = nil
    local needSaveDatas = false

    for i=1,self.waitingMissions.len do

        mission = self.waitingMissions[i]
        missionID = mission:getMissionId()

        --若不超时，则加入，否则删除
        if not mission:checkTime() then
            self.waitingMissions[i] = nil
            self.missions[missionID] = nil
            self.missionDatas[missionID] = nil
            needSaveDatas = true
        end
    end

    if needSaveDatas then
        self:saveMissionDatas()
    end

    return self.waitingMissions
end

--界面显示有效任务队列
function MissionManagers:getAllMissions(  )
    local missions = {}
    local mission = nil
    local missionID = nil
    local needSaveDatas = false
    print("getAllMissions",self.missions.len)

    --完成的优先
    for i=1,self.completedMissions.len do
        mission = self.completedMissions[i]
        missionID = mission:getMissionId()
        missions[#missions + 1] = mission
    end

    --待完成的
    for i=1,self.waitingMissions.len do
        mission = self.waitingMissions[i]
        missionID = mission:getMissionId()

        --若不超时，则加入，否则删除
        if mission:checkTime() then
            missions[#missions + 1] = mission
        else
            self.waitingMissions[i] = nil
            self.missions[missionID] = nil
            self.missionDatas[missionID] = nil
            needSaveDatas = true
        end
    end

    if needSaveDatas then
        self:saveMissionDatas()
    end

    self.UIMissions = missions

    return self.UIMissions
end

--判断目标任务是否是在有效任务中
function MissionManagers:missionsIsInValidMissions( missionID )

    if (not self.validMissions and not missionID) or not self.validMissions[missionID] then
        return false
    end

    --超时检查
    if not self.validMissions[missionID]:checkTime() then
        self:theMissionIsTimeout(nil,missionID)
        self.validMissions[missionID] = nil
    end

    return self.validMissions[missionID]
end

--供外部任务超时接口
function MissionManagers:theMissionIsTimeout( mission,id )
   
    if not mission and not id then
        return
    end

    if mission then
        id = mission:getMissionId()
    end

    --任务队列删除
    self.missions[id] = nil
    --任务等待队列删除
    self.waitingMissions[id] = nil
    --数据队列删除
    self.datas[id] = nil

    self:saveMissionDatas()
    self:removeMissionInUI(mission,id)
end

--放弃任务
function MissionManagers:giveUpTheMission( mission,id )
    if not mission and not id then
        return
    end

    if mission then
        id = mission:getMissionId()
    end 

     --任务队列删除
    self.missions[id] = nil
    --任务完成队列删除
    self.completedMissions[id] = nil
    --任务等待队列删除
    self.waitingMissions[id] = nil
    --数据队列删除
    self.datas[id] = nil

    self:saveMissionDatas()

    self:removeMissionInUI(mission,id)
end

