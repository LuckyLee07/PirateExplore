require "LuaClass/Header"
require "LuaClass/WoWUtils"


local exploreDataManager = nil

ExploreDataManager = class("ExploreDataManager",function ()
     return {}
end)

--strongholdNum
--clearStrongHoldNum
--Associated关联的信息，只提供查找
ExploreDataManager.__index = ExploreDataManager
ExploreDataManager.data = nil
ExploreDataManager.layoutAssociatedData = nil
-- ExploreDataManager.occupationAssociatedInfo = nil
ExploreDataManager.mapFogAssociatedDatas = nil
ExploreDataManager.curIndex = 0
ExploreDataManager.tempOccupationData = nil
local function createManger()
    -- print("EventManger:create()!");

    local manger = ExploreDataManager.new()
    
    if manger and manger:init() then
        return manger
    end

    return nil;
end

function ExploreDataManager:getInstance(  )
    
    if exploreDataManager == nil then
        exploreDataManager = createManger()
    end

    return exploreDataManager

end

function ExploreDataManager:init(  )
	self.data = nil
    self.layoutAssociatedData = nil
    self.mapFogAssociatedDatas = nil
    self.curIndex = 0
    return true
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
function ExploreDataManager:loadAndAnalysisMapDatas(  )

    self.data = nil
    self.layoutAssociatedData = nil
    self.mapFogAssociatedDatas = nil

    if not DataManager:getInstance():loadMapDataByID(self.curIndex) then
        print("enter not load data")
        DataManager:getInstance():setMapData(self.curIndex,mapInfo,{})
        -- --改变地图索引信息
        -- if tempData.mapIndex == nil then
        --     tempData.mapIndex = 1
        --     DataManager:getInstance():setRoleData(roleMapInfo,tempData)
        -- end
    end


    self.data = DataManager:getInstance():getRoleData(mapInfo)
    -- printn("loadAndAnalysisMapDatas",self.data)
    local count = 0
    --获取布局信息和迷雾信息
    if self.data.titlesInfo ~= nil then
        for k,v in pairs(self.data.titlesInfo) do
            --若strongholdInfos不为空，则这个位置有据点,关联起来
            if v.id ~= nil then
                if self.layoutAssociatedData == nil then
                    self.layoutAssociatedData = {}
                end
                self.layoutAssociatedData[k] = v
            end

            --若fogId不为空，则这个位置有迷雾信息,关联起来
            if v.fogId ~= nil then
                if self.mapFogAssociatedDatas == nil then
                    self.mapFogAssociatedDatas = {}
                end
                self.mapFogAssociatedDatas[k] = v.fogId
            end 
            count = count +1
        end
    end
    print("loadAndAnalysisMapDatas",count)

    self.tempOccupationData = DataManager:getInstance():getRoleData(roleTempOccupationData)
    -- printn("loadAndAnalysisMapDatassetOccupationData",self.tempOccupationData)
    -- printn("loadAndAnalysisMapDatas",self.layoutAssociatedData,self.mapFogAssociatedDatas,self.data)

end

function ExploreDataManager:setMapOwner(mapOwner )
    self.mapOwner = mapOwner
end



function ExploreDataManager:exchangeMapDataByIndex( index )
        
    if index == nil then
        index = 1
    end
    self.tempOccupationData = nil 
    --若当前索引等于目标索引，并且之前有布局和迷雾相关的数据，就不重新加载解析
    if self.curIndex == index and self.layoutAssociatedData  and self.mapFogAssociatedDatas  then
        print("LastDatas")
        return
    end

    self.curIndex = index

    self:loadAndAnalysisMapDatas()
end

function ExploreDataManager:saveCurDatas(  )
    DataManager:getInstance():setMapData(self.curIndex,mapInfo,self.data)
    print("ExploreDataManager:saveCurDatas")
end

function ExploreDataManager:getCurMapIndex(  )
    return self.curIndex
end

function ExploreDataManager:updateValueByKeysAndValue( ... )
    
    local args = {...}

    local lastTarget = self.data
    local target = getValueFromSetTableByCustomKey(lastTarget,args[1])
    
    for i=2,#args - 1 do
        if target == nil then
            print("err:return nil")
            return false
        end
        lastTarget = target
        target = getValueFromSetTableByCustomKey(target,args[i])
        -- print("updateValueByKeysAndValue",target,#args,args[i],lastTarget)
    end

    target = setValueToSetTableByCustomKey(lastTarget,args[#args - 1],args[#args])

    -- if target == nil then
        
    -- else    
    --     print("updateValueByKeysAndValue3",args[#args])
    --     target = args[#args]
    -- end

    


    return true 
end

function ExploreDataManager:getOccupationTempData(  )
    return self.tempOccupationData
end

function ExploreDataManager:setOccupationData( data )
   -- printn("setOccupationData",self.tempOccupationData)
   DataManager:getInstance():setRoleData(roleTempOccupationData,self.tempOccupationData)

end

function ExploreDataManager:clearTempOccupationData(  )
    self.tempOccupationData = nil
    self:setOccupationData()
end

--获得上次黑市刷新的时间
function ExploreDataManager:getLastBlackMarketRefreshTime(  )
   return self.data.lastBlackMarketRefreshTime
end
--获得上次黑市道具数据
function ExploreDataManager:getBlackMarketDatas(  )
   return clone(self.data.blackMarketDatas)
end

local refreshTimeInterval = 3600 -- zqDebug and 60 or 

function ExploreDataManager:getBlackMarketRefreshTimeInterval(  )
    return refreshTimeInterval
end

--检查是否要切换黑市道具数据
function ExploreDataManager:checkBlackMarketDatas( )
    local curTime = NotificationNode:getInstance():GetGameTime()

    local isNeedRefreshData = false

    if not self.data.lastBlackMarketRefreshTime then
        print("not self.data.lastBlackMarketRefreshTime")
        isNeedRefreshData = true
    elseif (curTime - self.data.lastBlackMarketRefreshTime) / refreshTimeInterval > 1 then
        print("(curTime - self.data.lastBlackMarketRefreshTime) / refreshTimeInterval > 1")
        isNeedRefreshData = true
    end

    if isNeedRefreshData then
        --重新筛选数据
        self:refreshBlackMarketDatas()
        --重新记录刷新时间
        self.data.lastBlackMarketRefreshTime = curTime
        --存储数据
        self:saveCurDatas()
    end

end

function ExploreDataManager:refreshBlackMarketDatas(  )
    print("ExploreDataManager:refreshBlackMarketDatas")
    local csv = DataManager:getInstance():getCSVByID(csvOfBlackMarket)
    local curDatas = csv[tostring(self.curIndex)]

    local itemInfos = {}
    local temp_data = nil

    local fixeds = curDatas["fixed"]


    if fixeds[1][1] ~= "0" then
         for i=1,#fixeds do
            temp_data = fixeds[i]

            local itemInfo = {}
            itemInfo.id = temp_data[2]
            itemInfo.name = dataController.getResourceValueByIdAndKey(itemInfo.id,"name")
            itemInfo.icon = dataController.getResourceValueByIdAndKey(itemInfo.id,"iconName")
            itemInfo.star = tonumber(dataController.getResourceValueByIdAndKey(itemInfo.id,"starNum"))
            if itemInfo.star == nil then itemInfo.star = 5 end
            itemInfo.description = dataController.getResourceValueByIdAndKey(itemInfo.id,"desc")
            itemInfo.costType = temp_data[1]
            itemInfo.costs = tonumber(temp_data[3])

            if not temp_data[4] then
                temp_data[4] = 1
            end
            
            itemInfo.num = tonumber(temp_data[4])
            itemInfos[i] = itemInfo
        end

    end

    local randomNum = curDatas["class"]

    local randomDatas = clone(curDatas["random"])
    local range = {}
    range.min = 1
    range.max = #randomDatas
    local index = 0
    
    for i=1,randomNum do
        local index = getRandomNumByRange(range)
        temp_data = randomDatas[index]

        local itemInfo = {}
        itemInfo.id = temp_data[2]
        itemInfo.name = dataController.getResourceValueByIdAndKey(itemInfo.id,"name")
        itemInfo.icon = dataController.getResourceValueByIdAndKey(itemInfo.id,"iconName")
        itemInfo.star = tonumber(dataController.getResourceValueByIdAndKey(itemInfo.id,"starNum"))
        if itemInfo.star == nil then itemInfo.star = 5 end
        itemInfo.description = dataController.getResourceValueByIdAndKey(itemInfo.id,"desc")
        itemInfo.costType = temp_data[1]
        itemInfo.costs = tonumber(temp_data[3])

        if not temp_data[4] then
            temp_data[4] = 1
        end
        
        itemInfo.num = tonumber(temp_data[4])
        itemInfos[#itemInfos + 1] = itemInfo

        table.remove(randomDatas,index)
        range.max = #randomDatas
    end

    self.data.blackMarketDatas = itemInfos
end

function ExploreDataManager:getValueByKeys( ... )

    local args = {...}
    local value = getValueFromSetTableByCustomKey(self.data,args[1])
    -- print("getValueByKeys",#args,args[1],value)
    for i=2,#args do
        if value == nil then
            return nil
        end
        -- print("getValueByKeys",value,args[i])
        value = getValueFromSetTableByCustomKey(value,args[i])
    end

    -- print("getValueByKeys",value,args[1])
    return value
end

function ExploreDataManager:setCurMapStrongholdNum( num )
    self.data.curMapStrongholdNum = num
end

function ExploreDataManager:getCurMapStrongholdNum(  )
    return self.data.curMapStrongholdNum
end

function ExploreDataManager:setClearStrongHoldNum( num )
    self.data.clearStrongHoldNum = num
end

function ExploreDataManager:getClearStrongHoldNum( ... )
    return self.data.clearStrongHoldNum
end

function ExploreDataManager:setFogs( fogs )
    self.data.fogs = fogs
end

function ExploreDataManager:getFogs( ... )
    return self.data.fogs
end

function ExploreDataManager:getCurLayoutData(  )
    return self.layoutAssociatedData
end

function ExploreDataManager:getCurMapFogData(  )
    return self.mapFogAssociatedDatas
end

--根据位置获得对应的key
function ExploreDataManager:getPosKeyByPosition( position )
    local key = nil
    local keyNum = 0

    if self.mapOwner ~= nil then
        keyNum = position.x + position.y * self.mapOwner.map:getMapSize().width
        key = tostring(keyNum)
    end


    return key
end

--根据key获得对应的图块位置
function ExploreDataManager:getTitlePositionByPosKey( posKey )
    local pos = {}
    pos.x = 0
    pos.y = 0
    -- print("posKey",posKey,type(posKey))
    if self.mapOwner ~= nil then
        local num = tonumber(posKey)
        pos.y = math.floor(num / self.mapOwner.map:getMapSize().width)
        pos.x = num - pos.y * self.mapOwner.map:getMapSize().width
    end

    return pos
end
