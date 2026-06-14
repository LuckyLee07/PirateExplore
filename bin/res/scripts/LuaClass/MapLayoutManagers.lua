require "LuaClass/Header"
require "LuaClass/WoWUtils"


-- transform = nil

-- transform = function safeConvertedIntoData( data )
	
-- 	for k,v in pairs(data) do
-- 		if type(v) == "table" then
-- 			transform(v)
		
-- 		elseif type(v) == "string" then
-- 		end

-- 	end

-- end
--根据地图的key的格式获取位置
function getPositionFromPositionDes( posDes )
	if type(posDes) ~= "string" then
		-- print("getPositionFromPositionDes",type(posDes))
		return
	end

	-- print("getPositionFromPositionDes",posDes)

	local x = nil
	local y = nil

	local posX = string.find(posDes,"_")
	local posY = string.find(posDes,"_",posX + 1)
	x = string.sub(posDes,posX + 1,posY - 1)
	y = string.sub(posDes,posY + 1)

	local position = cc.p(tonumber(x),tonumber(y))

	-- print("getPositionFromPositionDes",x,y)

	return position
end

function getTableFromStringByDistributionFormat( string )
	
	-- print("type(string)",type(string))

	if type(string) ~= "string" then
		return string
	end

	local result = {}

	result = split(string,";")
	-- print("getTableFromStringByDistributionFormat1")
	for i=1,#result do
		local temp = split(result[i],"_")
		result[i] = nil
		result[i] = {}
		result[i].id = temp[1]
		result[i].num= temp[2]
	end

	return result
end

MapLayoutManagers = class("MapLayoutManagers",function ()
	 return cc.Layer:create()
end)

MapLayoutManagers.__index = MapLayoutManagers
MapLayoutManagers.owner = nil
MapLayoutManagers.data = nil
--索引数据，供用据点id可以快速获得对应的据点属性数据
MapLayoutManagers.searchDatas = nil
MapLayoutManagers.objectsData = nil
--中间关键节点索引
MapLayoutManagers.judge = 0
--末尾的关键点索引
MapLayoutManagers.endJudge = 0
MapLayoutManagers.targets = {}
MapLayoutManagers.peripheralPositions = {}
MapLayoutManagers.InteriorPositions = {}
--附近的点，type = "3" ，插入据点的key为centralityInfo
MapLayoutManagers.nearbyPositions = {}
MapLayoutManagers.strongholdInfo = {}
MapLayoutManagers.enemyInfo = nil
MapLayoutManagers.guard = nil
MapLayoutManagers.returnBaseTool = nil
MapLayoutManagers.returnBaseNum = nil
MapLayoutManagers.curMapStrongholdNum = 0
MapLayoutManagers.mapEnterTools = nil
function MapLayoutManagers:create( )
	-- print("Jointed:create()!");

	local mapLayoutManager = MapLayoutManagers.new()
	
	if mapLayoutManager and mapLayoutManager:init() then
		return mapLayoutManager
	end

	return nil;
end

function MapLayoutManagers:init()
    -- print("MapLayoutManagers:init!",#self.targets);
    self.targets = nil
    self.targets = {}
    -- self.strongholdInfo = DataManager:getInstance():getCSVByID(csvOfStrongholdAttribute)
    return true;
end

function MapLayoutManagers:setOwner( owner )
	self.owner = owner
end

function MapLayoutManagers:tryToLayoutMapByMapIndex( )
	--从地图信息中获取布局信息
	self.data = ExploreDataManager:getInstance():getCurLayoutData()

	if self.data ~= nil then
		self.curMapStrongholdNum = ExploreDataManager:getInstance():getCurMapStrongholdNum()
		-- print("tryToLayoutMapByMapIndex0",self.data.strongholdNum)
	end


	-- local count = 0

	-- if self.data ~= nil then
	-- 	for k,v in pairs(self.data) do
			-- print(k,v)
	-- 		count = count + 1
	-- 	end
	-- 	if count < 1 then
	-- 		self.data = nil
	-- 	end
	-- end
	-- print("tryToLayoutMapByMapIndex1",#self.targets,getCurMapDatas().mapLayoutData)

	-- print("tryToLayoutMapByMapIndex2",#self.targets,getCurMapDatas().mapLayoutData,count)


	-- self.data = nil
	--若布局信息为空，说明第一次进入此界面，所以需要随机布局
	if self.data == nil then

		--若没有图块信息，创建图块信息
		if not ExploreDataManager:getInstance():getValueByKeys("titlesInfo") then
			self.data = {}
			ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",self.data)
		end
		
		-- print("sadfasf",ExploreDataManager:getInstance():getValueByKeys("titlesInfo"))
		-- getCurMapDatas().mapLayoutData = {}
		-- self.data = getCurMapDatas().mapLayoutData
		-- print("tryToLayoutMapByMapIndex2",self.data,getCurMapDatas().mapLayoutData)
		self:initLayoutDataByObjectsData()
		--初始化所有信息的时候需要更新数据
		ExploreDataManager:getInstance():saveCurDatas()
		-- DataManager:getInstance():setMapData(self.owner.mapIndex,mapInfo,getCurMapDatas())
	end


	--获得当前地图可随机到的怪物
	self:initEnemyInfo()
	self:layoutMap()
end

--根据一堆id获得对应的内部据点信息和外部据点信息
function MapLayoutManagers:analyticalAndGetStrongholdTilesByAllId( ids )
	
	-- print("analyticalAndGetStrongholdTilesByAllId",#self.targets)

	-- print("over!",peripheryInfo)
	-- ids["peripheralInfo"] = peripheryInfo
	-- print("idsperipheryInfo",ids["peripheryInfo"])
	-- ids["peripheralInfo"] = getTableFromStringByDistributionFormat(ids["peripheralInfo"])

	-- ids["interiorInfo"] = getTableFromStringByDistributionFormat(ids["interiorInfo"])
	-- print(type(ids["peripheralInfo"]),type(ids["interiorInfo"]))

	local id = 0
	local gid = 0
	local num = 0
	local temp = nil
	

	-- print("peripheryInfo len",#ids["peripheryInfo"])
	for i=1,#ids["peripheryInfo"] do
		temp = ids["peripheryInfo"][i]

		-- for k,v in pairs(temp) do
			-- print(k,v)
		-- end

		id = temp[1]
		
		num = tonumber(temp[2])

		-- print("peripheryInfonum",num,id)
		-- print("DataManager:getInstance():getCSVByID(csvOfStrongholdAttribute", self.strongholdInfo)
			-- for k,v in pairs(self.strongholdInfo) do
				-- print(k,v)
			-- end
		-- local curStrongholdInfo = self.strongholdInfo[id]

		local curStrongholdInfo = dataController.getStrongholdAttributeInfoById(id)

		gid = curStrongholdInfo["gid"]		-- gid = math.random() % 49

		-- if gid < 25 then
		-- 	gid = math.ceil(25 + gid)
		-- end
		local cur_index = #self.targets + 1

		self.targets[cur_index] = {}
		self.targets[cur_index].id = id
		self.targets[cur_index].num = num
		self.targets[cur_index].gid = gid
		self.targets[cur_index].info = curStrongholdInfo
	end

	-- print("self.targets",#self.targets)

	self.judge = #self.targets

	-- print("interiorInfo len",#ids["interiorInfo"])

	for i=1,#ids["interiorInfo"] do

		temp = ids["interiorInfo"][i]

		id = temp[1]
		num = tonumber(temp[2])

		-- print("interiorInfonum",num,id)

		-- gid = math.random() % 49

		-- if gid < 25 then
		-- 	gid = math.ceil(25 + gid)
		-- end

		local curStrongholdInfo = dataController.getStrongholdAttributeInfoById(id)

		gid = curStrongholdInfo["gid"]

		local cur_index = #self.targets + 1

		self.targets[cur_index] = {}
		self.targets[cur_index].id = id
		self.targets[cur_index].num = num
		-- print("interiorInfoNum",self.targets[cur_index].num)
		self.targets[cur_index].gid = gid
		self.targets[cur_index].info = curStrongholdInfo
	end
	self.endJudge = #self.targets

	-- print("1111",ids["centralityInfo"][1][1])

	if ids["centralityInfo"][1][1] ~= "0" then
		for i=1,#ids["centralityInfo"] do

			temp = ids["centralityInfo"][i]

			id = temp[1]
			num = tonumber(temp[2])

			-- print("centralityInfo",num,id)

			local curStrongholdInfo = dataController.getStrongholdAttributeInfoById(id)

			gid = curStrongholdInfo["gid"]

			local cur_index = #self.targets + 1

			self.targets[cur_index] = {}
			self.targets[cur_index].id = id
			self.targets[cur_index].num = num
			-- print("interiorInfoNum",self.targets[cur_index].num)
			self.targets[cur_index].gid = gid
			self.targets[cur_index].info = curStrongholdInfo
		end
	end

	

	-- print("self.targets",#self.targets,self.endJudge)


end

--获得所有布局据点的id和数量
function MapLayoutManagers:getAllTargetStrongholdInfo(  )
	-- local distributionData = DataManager:getInstance():getCSVByID(csvOfStrongholdDistribution)
	-- self.targets =  distributionData[self.owner.mapIndex]
	local mapIndex = self.owner.mapIndex

	self:analyticalAndGetStrongholdTilesByAllId(dataController.getStrongholdDistributionInfoById(tostring(mapIndex)))

	-- print("getAllTargetStrongholdInfo")

	-- self.targets = distributionData[1]
end

--查看某一点放置某个据点id是否可行
function MapLayoutManagers:checkPositionByRandomRule( id )
	
end

--获得对应id据点的限制条件
function MapLayoutManagers:getLimitedRuleByStrongholdId( id )
		
end


--开始随机布置外围据点的位置
function MapLayoutManagers:startToRandomLayoutPeripheralPositions(  )

		-- print("self.judge",self.judge)
		for i=1,self.judge do
			local curStronghold = self.targets[i]
			local num = curStronghold.num
			for i=1,num do
				local rang = {}
				rang.min = 1
				rang.max = #self.peripheralPositions
				local index = self:getRandomIndexByRange(rang)
				-- print("index",index,#self.InteriorPositions,self.peripheralPositions[index])
				local position = cc.p(self.peripheralPositions[index]["x"],self.peripheralPositions[index]["y"])
				local op = position
				position = self.owner:tileCoordForPosition(position)
				local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)

				-- local dataindex = #self.data + 1
				self.data[positionDes] = {}
				ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positionDes,self.data[positionDes])
				self.data[positionDes].id = curStronghold.id
				self.data[positionDes].gid = curStronghold.gid
				self.data[positionDes].statues = "00"
				self.data[positionDes].tips = curStronghold.info["especial"]
				self.curMapStrongholdNum = self.curMapStrongholdNum + 1
				-- print("startToRandomLayoutPeripheralPositions",positionDes,i,self.data[positionDes].id)
				table.remove(self.peripheralPositions,index)
			end

		end

		--把剩下的外部点加入到内部点中
		for i=1,#self.peripheralPositions do
			self.InteriorPositions[#self.InteriorPositions + 1] = self.peripheralPositions[i]
		end

end

--开始获得非外围据点位置
function MapLayoutManagers:startToRandomLayoutInteriorPositions(  )
		
		-- printn("12360",#self.targets,#self.targets,self.judge,self.endJudge)

		for i=self.judge + 1,self.endJudge do

			local curStronghold = self.targets[i]
			local num = curStronghold.num

			for j=1,num do
				local rang = {}
				rang.min = 1
				rang.max = #self.InteriorPositions
				local index = self:getRandomIndexByRange(rang)
				-- print("index",index,#self.InteriorPositions,self.peripheralPositions[index])
				local position = cc.p(self.InteriorPositions[index]["x"],self.InteriorPositions[index]["y"])
				local op = position
				position = self.owner:tileCoordForPosition(position)
				-- local dataindex = #self.data + 1
				local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
				self.data[positionDes] = {}
				ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positionDes,self.data[positionDes])
				self.data[positionDes].id = curStronghold.id
				self.data[positionDes].gid = curStronghold.gid
				self.data[positionDes].statues = "00"
				self.data[positionDes].tips = curStronghold.info["especial"]
				-- print("startToRandomLayoutInteriorPositions",positionDes,self.data[positionDes].id)
				self.curMapStrongholdNum = self.curMapStrongholdNum + 1
				table.remove(self.InteriorPositions,index)
			end
		end
end

--开始布局附近的点
function MapLayoutManagers:startToRandomLayoutNearbyPositions( ... )
	
	for i= self.endJudge + 1,#self.targets do

			local curStronghold = self.targets[i]
			local num = curStronghold.num

			for j=1,num do
				local rang = {}
				rang.min = 1
				rang.max = #self.nearbyPositions
				local index = self:getRandomIndexByRange(rang)
				-- print("index",index,#self.InteriorPositions,self.peripheralPositions[index])
				local position = cc.p(self.nearbyPositions[index]["x"],self.nearbyPositions[index]["y"])
				local op = position
				position = self.owner:tileCoordForPosition(position)
				-- local dataindex = #self.data + 1
				local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
				self.data[positionDes] = {}
				ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positionDes,self.data[positionDes])
				self.data[positionDes].id = curStronghold.id
				self.data[positionDes].gid = curStronghold.gid
				self.data[positionDes].statues = "00"
				self.data[positionDes].tips = curStronghold.info["especial"]
				-- print("startToRandomLayoutNearbyPositions",positionDes,self.data[positionDes].id)
				self.curMapStrongholdNum = self.curMapStrongholdNum + 1
				table.remove(self.nearbyPositions,index)
			end
		end

end

function MapLayoutManagers:DebugSetFullPoint(  )

	local count = 0

	for i=1,#self.InteriorPositions do
		index = i
		local position = cc.p(self.InteriorPositions[index]["x"],self.InteriorPositions[index]["y"])
		position = self.owner:tileCoordForPosition(position)
		-- local dataindex = #self.data + 1
		local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
		self.data[positionDes] = {}
		self.data[positionDes].id = "3001"
		self.data[positionDes].gid = "46"
		-- print("DebugSetFullPointInteriorPositions",positionDes,self.data[positionDes].id)
		count = count + 1
		-- table.remove(self.InteriorPositions,index)
	end

	for i=1,#self.nearbyPositions do
		index = i
		local position = cc.p(self.nearbyPositions[index]["x"],self.nearbyPositions[index]["y"])
		position = self.owner:tileCoordForPosition(position)
		-- local dataindex = #self.data + 1
		local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
		self.data[positionDes] = {}
		self.data[positionDes].id = "3001"
		self.data[positionDes].gid = "46"
		-- print("DebugSetFullPointNearbyPositions",positionDes,self.data[positionDes].id)
		count = count + 1
		-- table.remove(self.nearbyPositions,index)
	end
	-- print("DebugSetFullPoint",count)
end

--随机获得范围内的某一个数
function MapLayoutManagers:getRandomIndexByRange( rang )
	local max = rang.max
	local min = rang.min

	math.randomseed(tostring(os.time()):reverse():sub(1, 6))

	local randomNum = math.random() * 100000

	local randomIndex = randomNum % (max + 1)
	
	if randomIndex < min then 
		randomIndex = min + randomIndex
	end

	randomIndex = math.floor(randomIndex)

	return randomIndex
end

function MapLayoutManagers:initLayoutDataByObjectsData( )
	local objects = self.owner.map:getObjectGroup("Objects");
	self.objectsData = objects:getObjects()

	self.InteriorPositions = {}
	self.peripheralPositions = {}
	self.nearbyPositions = {}

	self.curMapStrongholdNum = 0

	--去除start出身点的属性
	table.remove(self.objectsData,1)

	--将对应的点按类型分配到表中
	for k,v in pairs(self.objectsData) do
		--1为内部,2为外部
		if v["type"] == "1" then
			self.InteriorPositions[#self.InteriorPositions + 1] = v
		elseif v["type"] == "2" then
			self.peripheralPositions[#self.peripheralPositions + 1] = v
		elseif v["type"] == "3" then
			self.nearbyPositions[#self.nearbyPositions + 1] = v
			-- print("3Points",v.x,v.y)
		end

	end

	-- print("initLayoutDataByObjectsData",#self.InteriorPositions,#self.peripheralPositions,#self.nearbyPositions)

	--获得布局的据点信息
	self:getAllTargetStrongholdInfo()
	--先布置外围的
	self:startToRandomLayoutPeripheralPositions()
	--布置内部的
	self:startToRandomLayoutInteriorPositions()
	--布置在初始点之内的东西
	self:startToRandomLayoutNearbyPositions()

	ExploreDataManager:getInstance():setCurMapStrongholdNum(self.curMapStrongholdNum)

	-- self.data.strongholdNum = self.curMapStrongholdNum

	-- self:DebugSetFullPoint()

	--布局数据完毕，发送解锁信息
	self:postCurMapUnlockMessage()

	self.targets = nil
	self.targets = {}
	self.peripheralPositions = nil
	self.peripheralPositions = {}
	self.InteriorPositions = nil
	self.InteriorPositions = {}
	-- print("destroy temp")


	-- for k,v in pairs(self.objectsData ) do
		-- print(k,v)
	-- 	for k,v in pairs(v) do
		-- print(k,v)
	-- 	end
	-- end
	
	-- print("self.objectsData[1]")
	
end

--发送进入当前地图的解锁信息
function MapLayoutManagers:postCurMapUnlockMessage(  )

	-- print("MapLayoutManagers:postCurMapUnlockMessage")

	local postdata = dataController.getStrongholdDistributionInfoById(tostring(self.owner.mapIndex))
	DataManager:getInstance():unlockUnitWithCsvData(postdata)
end

--[[关于所有据点全部探索出来方法，可以这样写,首先，把用clone布局完后的表，传递给fogmanager，然后fogmananger判断其中那些已经现实，之后每探索出一块区域以后，判断该区域是否在
这其中，有就消除掉，在完全清除迷雾的一块信息之后，得看看是否表中的数据长度是否为0,若为0，则所有据点全部探索完毕,over!
]]

function MapLayoutManagers:initEnemyInfo(  )

	-- local distributionData = DataManager:getInstance():getCSVByID(csvOfStrongholdDistribution)
	--设置地图名字
	local mapName = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"name")
	-- print("mapName",mapName)
	self.owner.nameTitle:setString(mapName)

	-- print("self.owner.mapIndex",self.owner.mapIndex)

	self.enemyInfo = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"enemyInfo")
	-- print("initEnemyInfo",#self.enemyInfo)
	-- for k,v in pairs(self.enemyInfo) do
		-- print(k,v)
	-- end

	-- print("initEnemyInfoOver")

	--获取传送点开启道具信息openitems
	self.mapEnterTools = nil
	local tools = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"openitems")

	if tools[1][1] ~= "0" then
		local tempData = nil
		self.mapEnterTools = {}
		for i=1,#tools do
			
			tempData = tools[i]
			local costId = tempData[1]
			local costNum = tempData[2]
			-- print("cost",costId,costNum)
			-- print("enter cost",costId,costNum)
			self.mapEnterTools[i] = {}
			self.mapEnterTools[i].id = costId
			self.mapEnterTools[i].num = costNum
		end
	end
	print("self.mapEnterTools",self.mapEnterTools)

	--获得传送点掉落数据
	self.mapEnterDropItems = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"dropitems")

	--设置传送点守卫的信息
	self.guard = nil
	local guardDatas = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"guard")

	local tempDatas = nil

	-- print("guardDatas",guardDatas[1][1])
	self.guard = {}
	for i=1,#guardDatas do
		tempDatas = guardDatas[i]
		self.guard[i] = {}
		self.guard[i][1] = tempDatas[1]
	end


	--获得面包补给点信息
	tempDatas = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"bread")
	-- print("breads",tempDatas[1][1],tempDatas[1][2])

	ExploreBagController:getBagController().breads = nil
	ExploreBagController:getBagController().breads = {}
	ExploreBagController:getBagController().breads[1] = {}
	ExploreBagController:getBagController().breads[1].id = tempDatas[1][1]

	ExploreBagController:getBagController().breads[1].num = tonumber(tempDatas[1][2])

	self.returnBaseTool = dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"gohome")[1][1]
	self.returnBaseNum = tonumber(dataController.getStrongholdDistributionValueByIdAndKey(tostring(self.owner.mapIndex),"gohome")[1][2])
	-- print("returnBaseTools",self.returnBaseTool,self.returnBaseNum)
end

--传送点掉落数据
function MapLayoutManagers:getMapEnterDropItems(  )
	
	return self.mapEnterDropItems
end

function MapLayoutManagers:getRandomEnemy( )
	
	local range = {}
	
	range.min = 1
	
	range.max = #self.enemyInfo

	local index = self:getRandomIndexByRange(range)

	local enemy = self.enemyInfo[index]
	-- print("getRandomEnemy",index,#self.enemyInfo)

	-- for k,v in pairs(self.enemyInfo) do
		-- print(k,v)
	-- end

	return enemy
end

function MapLayoutManagers:layoutMap(  )
	
	self.searchDatas = {}

	for k,v in pairs(self.data) do
		if k ~= "strongholdNum" then
			local position = ExploreDataManager:getInstance():getTitlePositionByPosKey(k)
			-- print("maplayout",position,v.gid)
			self.owner:changeTitleByTitlePosition(position,v.gid)
			--若是老数据，则不开启这个特效效果，否则开启
			if v.tips then
				self.owner:showStrongholdTipAction(position,v.tips)
			end

			--加入到索引数组中
			self.searchDatas[v.id] = {}
			self.searchDatas[v.id].infos = v
			self.searchDatas[v.id].pos = position

		end
	end

end

function MapLayoutManagers:getStongholdIdByPosition( position )
	local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)

	return self.data[positionDes].id
end

function MapLayoutManagers:saveData(  )
	-- DataManager:getInstance():setRoleData(roleMapLayout,self.data)
end

--刷新地图图块数据，并且返回新的id
function MapLayoutManagers:setTheOccupationAndModifyTheDataByIdAndPosition( id,position )
	--获取探索度
	local roleExtentNum = DataManager:getInstance():getRoleData(roleExtents)
	if roleExtentNum == nil then
		roleExtentNum = 0
	end

	roleExtentNum = roleExtentNum + 1

	--更新新探索度
	DataManager:getInstance():setRoleData(roleExtents,roleExtentNum)

	if roleExtentNum == 10 then

		local stepInfos = {}

		stepInfos.id = "1"
		stepInfos.num = 1
		--触发任务1
		MissionManagers:getInstance():onTriggerMission("1",nil,stepInfos)
	end

	-- print("新总探索度",roleExtentNum)
	--显示更新
	self.owner:updataOccupation()

	local occupationgid = dataController.getStrongholdAttributeValueByIdAndKey(tostring(id),"occupationgid")
	local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
	-- print("setTheOccupationAndModifyTheDataByIdAndPosition",positionDes,self.data[positionDes],id,occupationgid)
	--更改图块的数据

	self.data[positionDes].id = id 
	self.data[positionDes].gid = occupationgid
	--数据改变需要重新写入数据
	-- DataManager:getInstance():setMapData(self.owner.mapIndex,mapInfo,getCurMapDatas())

	ExploreDataManager:getInstance():saveCurDatas()

	return occupationgid
end

function MapLayoutManagers:clearStrongholdTipData( pos )
	if not pos then 
		return
	end

	local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(pos)

	--若没有数据,则是地图自带的据点，如传送阵或者复活据点，所以不用清除,或者已经清除过，则不必在更改存储数据
	if not self.data[positionDes] or self.data[positionDes].tips == "0" then
		return
	end

	self.data[positionDes].tips = "0"
	ExploreDataManager:getInstance():saveCurDatas()

	self.owner:hideStrongholdTipAction(pos)
end

--购买回城道具
function MapLayoutManagers:buyBackGoods(diamonds)  
	-- print("购买通信")
	
	-- DataManager:getInstance:addDiamond(diamonds)
	self.owner:returnToBase()	
end

--离开
function MapLayoutManagers:leaveAlertView( )
	-- print("离开购买提示界面")
end

--检查是否含有这个数据，没有则添加进去
function MapLayoutManagers:safeCheckDataByPositionAndId( pos,id )
	
	local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(pos)
	-- printn("safeCheckDataByPositionAndId",self.data[positionDes],self.data[positionDes])
	if tonumber(id) == 3068 then
		local info = dataController.getStrongholdAttributeInfoById(id)
		if self.data[positionDes] and not self.data[positionDes].id then
			print("addMapData",id)
			ExploreDataManager:getInstance():setCurMapStrongholdNum(self.curMapStrongholdNum + 1)
			self.data[positionDes].id = id
			self.data[positionDes].gid = info["gid"]
			self.data[positionDes].statues = "00"
			self.data[positionDes].tips = tostring(-tonumber(info["especial"]))
			ExploreDataManager:getInstance():saveCurDatas()
			self.owner:showStrongholdTipAction(pos,self.data[positionDes].tips)
		elseif not self.data[positionDes] then
			print("addMapData",id)
			-- self.data[positionDes] = {}
			local data = ExploreDataManager:getInstance():getValueByKeys("titlesInfo",positionDes)
			
			if data then
				ExploreDataManager:getInstance():setCurMapStrongholdNum(self.curMapStrongholdNum + 1)
				data.id = id
				data.gid = info["gid"]
				data.statues = "00"
				data.tips = tostring(-tonumber(info["especial"]))
				self.data[positionDes] = data
				ExploreDataManager:getInstance():saveCurDatas()
				self.owner:showStrongholdTipAction(pos,data.tips)
			end

		end

	end
	
end

function MapLayoutManagers:getCurMapEnterCostTools(  )
	return self.mapEnterTools
end

function MapLayoutManagers:checkReturnBase( )

	-- if 1 then
	-- 	return true
	-- end

	local returnBaseTools = {}
	returnBaseTools[1] = {}
	returnBaseTools[1].id = self.returnBaseTool
	returnBaseTools[1].num = self.returnBaseNum

	local canBack = ExploreBagController:getBagController():checkItemsIsHave(returnBaseTools)

	-- if not canBack then

	-- 	local tipstring = nil
	-- 	local name = dataController.getResourceValueByIdAndKey(self.returnBaseTool,"name")
	-- 	tipstring = string.format("是否购买%d个%s",self.returnBaseNum,name)
	-- 	local _alert = AlertView:create(2,0, "返航失败",function ( ... )
	-- 		self:buyBackGoods()
	-- 	end,function ( ... )
	-- 		self:leaveAlertView()
	-- 	end)
		-- print("_alert inited")
 --        local showLabel1 = cc.LabelTTF:create(tipstring, BoldFont, 36.0)
 --        showLabel1:setColor(cc.c3b(255, 255, 255))
 --        showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
 --        showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
        -- print("showLabel1 will add")
 --        _alert:addChild(showLabel1)
        -- print("showLabel1 inited")
	-- end

	return canBack
end

function MapLayoutManagers:getStongholdInfosById( id )
	
	return self.searchDatas[id]

end

