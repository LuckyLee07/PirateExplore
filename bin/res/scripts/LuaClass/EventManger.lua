require "LuaClass/Header"
require "LuaClass/EventLayer"
require "LuaClass/DataManager"
require "LuaClass/EternalArenaController"
require "LuaClass/PlotLayer"

--悔语录:其实事件管理者已经完全复杂话了，其实只用根据表里的数据，然后生成一个数据结构，根据数据结构的属性，去执行方法，诶(一个星期之后)

EventManger = class("EventManger",function ()
	 return cc.Layer:create()
end)

EventManger.__index = EventManger
EventManger.eventWaitingQueue = nil
EventManger.enemys = {}
EventManger.layer = nil
EventManger.owner = nil
EventManger.data = nil
EventManger.receivedData = nil
EventManger.openData = nil
EventManger.isMinesweeper = false
EventManger.curStrongholdData = {}
EventManger.csvData = nil
EventManger.curEventId = 0
EventManger.costTool = nil
EventManger.isNeedOccupied = false
EventManger.willTip = false
EventManger.openbuildIds = nil
EventManger.produceIDs = nil
EventManger.isBoss = false			---是否是Boss据点
EventManger.isMapEnter = false		---是否是下一站地图入口
EventManger.minesweeperNums = 0 	

function EventManger:create(owner)
	-- print("EventManger:create()!");

	local eventManger = EventManger.new()
	
	if eventManger and eventManger:init(owner) then
		return eventManger
	end

	return nil;
end

function EventManger:init(owner)

	self.eventWaitingQueue = {}
	self.events = {}
	self.owner = owner
	self.layer = EventLayer:create()
	self:addChild(self.layer)
	self.layer:setController(self)
	self.layer:setPosition(cc.p(0,0))
	self.layer:hide()
    -- print("EventManger:init!");
    self.csvData = DataManager:getInstance():getCSVByID(csvOfStrongholdAttribute)

    --初始化永恒竞技场管理者
    EternalArenaController:getInstance(self)

    return true;
end

function EventManger:getRealIdBycurId( id )

	local isCurEvent = id == self.curEventId
	--若id小于100则是事件id，需要转换成据点id，而布局类知道据点id,由于还有复用图块id(酒馆,黑市，竞技场)，所以，图块属性压根没啥用了。。。。。
	if tonumber(id) < 100 or tonumber(id) == 3004 or tonumber(id) == 3020 or tonumber(id) == 3036 then
		-- print("self.owner.player:getPosition()",self.owner.playerTitlePosition)
		id = self.owner.mapLayoutManagers:getStongholdIdByPosition(self.owner.playerTitlePosition)
	end	


	if isCurEvent then
		-- print("curEventId is change",self.curEventId,id)
		self.curEventId = id
	end

	return id
end

function EventManger:getMapStrongholdDataById( id )
	local indexString = string.format("%d",id)
	
	-- print("indexString",indexString)

	self.curStrongholdData = dataController.getStrongholdAttributeInfoById(indexString)

	-- print("self.curStrongholdData",self.curStrongholdData,self.curStrongholdData["openbuilding"],self.curStrongholdData["openbuilding"],self.curStrongholdData["openbuilding"])
	local costDatas = self.curStrongholdData["requiredtool"]
	self.costTool = nil
	if costDatas[1][1] ~= "0" then
		local tempData = nil
		self.costTool = {}
		for i=1,#costDatas do
			
			tempData = costDatas[i]
			local costId = tempData[1]
			local costNum = tempData[2]
			-- print("cost",costId,costNum)
			-- print("enter cost",costId,costNum)
			self.costTool[i] = {}
			self.costTool[i].id = costId
			self.costTool[i].num = costNum
		end
	end
	
	self.isMapEnter = self.curStrongholdData["name"] == "传送点"
	--若有剧情id，则为boss据点
	self.plotID = tonumber(self.curStrongholdData["plotID"])
	if self.plotID ~= 0 then
		self.isBoss = true
	end 

	local enemyDatas = self.curStrongholdData["enemys"][1]
	-- print("enemyDatas",enemyDatas[1],self.plotID)


	--是传送点，怪物数据得从地图分布表走
	if self.isMapEnter == true then
		self.enemys = clone(self.owner.mapLayoutManagers.guard)
		self.isNeedOccupied = false
		
		self.costTool = self.owner.mapLayoutManagers:getCurMapEnterCostTools()
		
	--竞技场不能占领
	elseif enemyDatas[1] ~= "0" then
		self.enemys = clone(self.curStrongholdData["enemys"])

		if string.find(self.curStrongholdData["name"],"竞技场") == nil then
			self.isNeedOccupied = true
		end
	else
		self.enemys = nil
		self.enemys = {}
		self.isNeedOccupied = false
	end

	--若有敌人,将rolemapinfo设置为战斗状态
	if not self:checkOccupiedByPosition(self.owner.playerTitlePosition) then 
		local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
		tempData.willFight = 1
		DataManager:getInstance():setRoleData(roleMapInfo,tempData)
	end


	-- print("self.enemys",self.enemys,#self.enemys,self.isNeedOccupied)
	-- print("inpair")
	-- for k,v in pairs(self.enemys) do
		-- print(k,v)
	-- end
	--DataManager:unlockUnitWithType(unitType, id)
	--[[
	kUnlockMake = 1 		-- 解锁制造
	kUnlockBuild = 2 		-- 解锁建造
	kUnlockResource = 3 	-- 解锁资源
	kUnlockStore = 4		-- 解锁商店

	kUnlockWorker = 5		-- 解锁工匠数量
	kUnlockPack = 6			-- 解锁战斗背包格子数
	kUnlockCabin = 7		-- 解锁战船容积和血量
	kUnlockShipGun = 8		-- 解锁战船火力
	kUnlockGather = 9		-- 解锁采集收益
	kUnlockAlchemy = 10		-- 解锁炼金收益
	]]
	self.openbuildIds = self.curStrongholdData["openbuilding"]
	--若为0表示没有可开启点
	if self.openbuildIds[1][1] == "0" then
		self.openbuildIds = nil
	else
		-- print("allOpenFuncIDs",#self.openbuildIds,self.openbuildIds[1][1])
	end
	
	self.produceIDs = self.curStrongholdData["produceID"]

	-- print("self.produceIDs",type(self.produceIDs))

	if self.produceIDs ~= nil and (type(self.produceIDs) ~= "table" or self.produceIDs[1][1] == "0") then
		-- print("self.produceIDs[1][1]",self.produceIDs[1][1])
		self.produceIDs = nil
	else
		-- print("allOpenFuncIDs",#self.produceIDs,self.produceIDs[1][1])
	end

	if self.isNeedOccupied  then
		local tempData = ExploreDataManager:getInstance():getOccupationTempData()

		if not tempData then
			tempData = {}
		end
		local value = {}
		tempData[#tempData + 1] = value
		value.id = self.curEventId
		value.position = self.owner.playerTitlePosition
		value.openbuildIds = clone(self.openbuildIds)
		value.produceIDs = clone(self.produceIDs)
		ExploreDataManager:getInstance().tempOccupationData = tempData
		-- ExploreDataManager:getInstance():setOccupationData()
	end

end
--[[
	tempData.mapIndex = tempData.mapIndex + 1

		--若随机事件开关值为nil且mapindex大于1，则对开关进行赋值，开启开关
		if DataManager:getInstance():getRoleData(roleRandomEventSwitch) == nil and tempData.mapIndex > 1 then 
			DataManager:getInstance():setRoleData(roleRandomEventSwitch,1)
		end
]]
--根据某个位置去检查该位置是否被占领
function EventManger:checkOccupiedByPosition( position )
	local keyString = ExploreDataManager:getInstance():getPosKeyByPosition(position)
	

	local statues = ExploreDataManager:getInstance():getValueByKeys("titlesInfo",keyString,"statues")

	local isOccupied = true

	if statues ~= nil and string.sub(statues,1,1) == "0" then
		isOccupied = false
		print("checkOccupiedByPosition",keyString,string.sub(statues,1,1),isOccupied)
	elseif statues == nil then
		isOccupied = false
	end
	
	return isOccupied
end

function EventManger:checkIsOpen(  )
	local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(self.owner.playerTitlePosition)
	local statues = ExploreDataManager:getInstance():getValueByKeys("titlesInfo",positionDes,"statues")

	local open = true

	if statues ~= nil then
		open = string.sub(statues,2) ~= "0"
	end

	-- print("checkIsOpen",string.sub(statues,2),string.sub(statues,2) ~= "0")
	return open
end

--检查是否满足进入事件详情界面的条件
function EventManger:checkEnterNext(  )

	if self.costTool then
		
		--若找不到数据，则之前没有开启过
		if not self:checkIsOpen() then

		--查看是否有道具可开启		
		local enterNext = self.owner.bagController:costGoodsByGoods(self.costTool)
			if not enterNext then
				ToastUtil:toastString("你没有对应物品，无法进入!\n该物品本地图可掉落(钥匙除外)")
			else
				local positionDes = ExploreDataManager:getInstance():getPosKeyByPosition(self.owner.playerTitlePosition)
				ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positionDes,"statues","01")
				ExploreDataManager:getInstance():saveCurDatas()
				-- self.openData[positionDes] = "1"
				-- DataManager:getInstance():setMapData(self.owner.mapIndex,mapInfo,getCurMapDatas())
			end

			return enterNext
		end
	end

	return true
end


--刷新数据
function EventManger:refreshData( )

	--检查当前据点是否是boss据点
	self:checkBossAchievement()

	-- print("refreshData",self.data)
	--由于写了个地图布局类，所以以后地图布局的相关逻辑全部写在改类中,所以该类数据只是存醋数据，用来感知是否是补集的事件
	local curData = {}
	curData.position = self.owner.playerTitlePosition
	local keyString = ExploreDataManager:getInstance():getPosKeyByPosition(self.owner.playerTitlePosition)

	print("refreshData")

	--把当前数据写入进去
	ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",keyString,"statues","11")

	-- self.data[keyString] = true
	--重新写入整个地图数据
	ExploreDataManager:getInstance():saveCurDatas()
	-- DataManager:getInstance():setMapData(self.owner.mapIndex,mapInfo,getCurMapDatas())
	-- setValueToSetTableByCustomKey(self.data,keyString,curData)
	-- print("InputData",keyString,self.data[keyString])
	--通知ui层开始刷新占领后的据点ui
	self.owner:tileHasBeenOccupiedByTitlePosition()
	--通知解锁
	self:postUnlockMessage()
end

function EventManger:postUnlockMessage(  )

	--DataManager:unlockUnitWithType(unitType, id)
	--[[
	kUnlockMake = 1 		-- 解锁制造
	kUnlockBuild = 2 		-- 解锁建造
	kUnlockResource = 3 	-- 解锁资源
	kUnlockStore = 4		-- 解锁商店

	kUnlockWorker = 5		-- 解锁工匠数量
	kUnlockPack = 6			-- 解锁战斗背包格子数
	kUnlockCabin = 7		-- 解锁战船容积和血量
	kUnlockShipGun = 8		-- 解锁战船火力
	kUnlockGather = 9		-- 解锁采集收益
	kUnlockAlchemy = 10		-- 解锁炼金收益
	]]

	local temp = nil
	local id = nil
	--建造通知
	if self.openbuildIds ~= nil then
		for i=1,#self.openbuildIds do
			temp = self.openbuildIds[i]
			id = temp[1]
			-- print("postUnlockBuildMessage",id)
			DataManager:getInstance():unlockUnitWithType(kUnlockBuild,id)
		end
	end

	--制作通知
	if self.produceIDs ~= nil then
		for i=1,#self.produceIDs do
			temp = self.produceIDs[i]
			id = temp[1]
			-- print("postUnlockMakeMessage",id)
			DataManager:getInstance():unlockUnitWithType(kUnlockMake,id)
		end
	end

end

--获取数据
function EventManger:getMapDataAndRefreshMapByMapIndex( index )
	--从地图信息中获取占领信息
	-- self.data = getCurMapDatas().occupationInfo
	
	self.minesweeperNums = 0

	--获取地图的开启信息
	-- -- self.data = DataManager:getInstance():getRoleData(roleMapInfo)
	-- self.openData = getCurMapDatas().openData
	-- if self.data then
	-- 	-- print("eventMap is inited")
	-- 	for k,v in pairs(self.data) do
	-- 		-- print(k,v)
	-- 	end
	-- end

	-- if  self.data == nil then
	-- 	getCurMapDatas().occupationInfo = {}
	-- 	self.data = getCurMapDatas().occupationInfo
	-- end

	-- if self.openData == nil then
	-- 	getCurMapDatas().openData = {}
	-- 	self.openData = getCurMapDatas().openData
	-- end
	
	--获取临时获取数据
	self.receivedData = DataManager:getInstance():getRoleData(roleTempReceivedDatas)
	--有临时数据，则刷新ui
	if self.receivedData ~= nil then
		for k,v in pairs(self.receivedData) do
			-- print(k,v)
			self:received(k)
		end
	end

	-- print("getMapDataandRefreshMapByMapIndex",self.data)
end

function EventManger:saveEventData( )


end

function EventManger:freezeOwnerOperations( )
	-- print("freezeOwnerOperations")
	self.owner.tipLayer:setVisible(false)
	self.owner.statue = "Triggering"
	self.owner.moveWaitingQueue = {}
	self.owner.moveDirectionQueue = {}
end

function EventManger:unreezeOwnerOperations( )
	-- print("unreezeOwnerOperations")
	self.owner.tipLayer:setVisible(true)
	self.owner.statue = "ready"
	ExploreDataManager:getInstance():clearTempOccupationData()
end

--根据事件id即将触发某个事件
function EventManger:willTriggerEventById( eventId )

	local index = math.max(#self.eventWaitingQueue,1)


	self.eventWaitingQueue[index] = eventId

	-- table.insert(self.eventWaitingQueue,index,eventId);
	-- print("addEventId",self.eventWaitingQueue[index])
	-- setmetatable()
	-- getmetatable()
end

--触发一个等待事件
function EventManger:triggeringEventOfWating( )

	--若是在等待随机遇敌状态，则等待随机战结束后再刷新状态
	if self.isMinesweeper then 
		return
	end

	if #self.eventWaitingQueue == 0 then
		-- print("eventWaitingQueue == 0")
		return
	end

	local curEventId = 0

	if #self.eventWaitingQueue > 0 then
		curEventId = self.eventWaitingQueue[1]
		self.curEventId = curEventId
	elseif #self.enemys > 0 then 
		curEventId = self.enemys[1]
	end

	-- print("triggeringEventOfWatingId",curEventId,self.owner.playerTitlePosition.x,self.owner.playerTitlePosition.y)
	self:onTriggerById(curEventId)

end

--触发对应id的事件
function EventManger:onTriggerById( id )

	-- local posDes = ExploreDataManager:getInstance():getPosKeyByPosition(self.owner.playerTitlePosition)
	local positionDes = string.format("_%d_%d",self.owner.playerTitlePosition.x,self.owner.playerTitlePosition.y)
	if self.receivedData ~= nil and self.receivedData[positionDes] ~= nil then
		table.remove(self.eventWaitingQueue,1)
		self:allEventsHasTriggered()
		return
	end

	--0表示没有任何据点，开始进行踩地雷模块
	if id == 0 then
		self:unreezeOwnerOperations()
		return
	end
	--回城点id
	if id == "3001" then
		self:unreezeOwnerOperations()
		self.owner:returnToBase()
		return
	end

	--存入玩家位置
	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	tempData.playerTitlePosition = self.owner.playerTitlePosition
	DataManager:getInstance():setRoleData(roleMapInfo,tempData)
	print("EVEsavePos",tempData.playerTitlePosition.x,tempData.playerTitlePosition.y)

	id = self:getRealIdBycurId(id)

	-- print("EventManger:onTriggerById",id)
	--冻结map界面的操作
	self:freezeOwnerOperations()
	--开始获得对应的据点信息并赋值给layer更新界面
	self:getMapStrongholdDataById(id)
	-- print("getMapStrongholdDataByIdOver")
	-- for k,v in pairs(self.curStrongholdData) do
		-- print(k,v)
	-- end

	local isOccupied = self:checkOccupiedByPosition(self.owner.playerTitlePosition)

	-- print("checkOccupiedByPositionOver")
	-- for k,v in pairs(self.curStrongholdData) do
		-- print(k,v)
	-- end

	self.layer:refreshLayerByInfo(self.curStrongholdData,isOccupied)

	self.layer:show()
end

--获得策划的坐标，16 * 16
function EventManger:getShitsPlannersCoordForPosition( titlePosition , mapSize)
	--获得比例系数
	local cur_x_coefficient = math.floor(mapSize.width / 16)
	local cur_y_coefficient = math.floor(mapSize.height / 16)

	--计算出对应的格子
	local shitsPlannersPosition = cc.p(0,0)
	shitsPlannersPosition.x = cur_x_coefficient * titlePosition.x
	shitsPlannersPosition.y = cur_y_coefficient * titlePosition.y

	return shitsPlannersPosition
end
--标记已经领取过，再次进入无法领取
function EventManger:received( posDes )

	local position = nil

	--若没有位置key，则为新添加值，否则为根据原始值来刷新ui
	if posDes == nil then

		--若自己的获取数据为空，则需要初始下数据,不用每次都存储，因为一recived之后就会走allEventsHasTriggered,这个方法要将玩家的状态值改变，因而会在那时候存储所有的recive的数据
		if self.receivedData == nil then
			self.receivedData = {}
			DataManager:getInstance():setRoleData(roleTempReceivedDatas,self.receivedData)
		end
		position = self.owner.playerTitlePosition
		posDes = string.format("_%d_%d",self.owner.playerTitlePosition.x,self.owner.playerTitlePosition.y)
		local gid = tonumber(self.curStrongholdData["occupationgid"])
		self.receivedData[posDes] = gid
	else
		position = getPositionFromPositionDes(posDes)
	end
	DataManager:getInstance():setRoleData(roleTempReceivedDatas,self.receivedData)
	print("received gid",self.receivedData[posDes],posDes)
	self.owner:changeTitleByTitlePosition(position,self.receivedData[posDes])

end

--一个事件已经触发完毕
function EventManger:anEventHasTriggered( )
	
	table.remove(self.eventWaitingQueue,1)
	-- print("anEventHasTriggered",#self.eventWaitingQueue,#self.enemys,self.willTip)

	local posDes = string.format("_%d_%d",self.owner.playerTitlePosition.x,self.owner.playerTitlePosition.y)

	if self.receivedData and self.receivedData[posDes] ~= nil then
		table.remove(self.eventWaitingQueue,1)
		self:allEventsHasTriggered()
		self.enemys = nil
		self.enemys = {}
		return
	end


	--若还有等待调用的事件，则继续调用
	if #self.eventWaitingQueue > 0 then 
		self:triggeringEventOfWating()
		return
	end


	if #self.enemys > 0 and not self:checkOccupiedByPosition(self.owner.playerTitlePosition) then 

		

		local addDropData = nil
		-- print("#self.enemys == 1")
		--即将显示占领提示界面		
		if #self.enemys == 1 and not self.isMinesweeper then
			
			if not self.isBoss and not self.isMapEnter then
				self.willTip = true
			end

			addDropData = self.curStrongholdData["dropitems"]

			--若是传送点，则获得对应的特殊掉落数据
			if self.isMapEnter then
				addDropData = self.owner.mapLayoutManagers:getMapEnterDropItems()
			end
		end

		self:enterEnemyLayer(addDropData)
		self.lastEnemysId = self.enemys[1]
		table.remove(self.enemys,1)
		return
	end	
	-- print("willTringleEndAction",self.willTip,self.isBoss,self.isMapEnter,self.isNeedOccupied)
	if self.willTip then 
		self:enterTipOccupiedLayer()
		self.willTip = false
		return
	end

	--是boss且没有被占领的时候，播放剧情
	if self.isBoss and not self:checkOccupiedByPosition(self.owner.playerTitlePosition) then
		self:enterTipOccupiedLayer()

		--若地图的层数小于6则剧情成就点即可加1
		if self.owner.mapIndex < 6 then
			local rolePoltNum = DataManager:getInstance():getRoleData(rolePolts)

			if rolePoltNum == nil then
				rolePoltNum = 0
			end

			rolePoltNum = rolePoltNum + 1

			DataManager:getInstance():setRoleData(rolePolts,rolePoltNum)
			-- print("检查剧情",rolePoltNum)
			--若已经播放了5次前五章地图，则开启成就
			if rolePoltNum == 5 then
				-- print("触发了前五章剧情全部打完成就")
				achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Plot)
				DataManager:getInstance():setAchievementInfo(achievement_Plot, achievementValue + 1)
			end 
		end

		
		-- self:addChild(plot,30000)

		local delay = cc.DelayTime:create(0.00)
        local call1 = cc.CallFunc:create(function ( ... )
        	local plot = PlotLayer:create(self.plotID)
				plot:setCalback(function (  )
			-- self:allEventsHasTriggered(false)
			end)
			plot:play()
			-- self.owner:setVisible(true)
        end)

		local action = cc.Sequence:create(delay,call1)
		self:runAction(action)


		self.isBoss = false
		return
	end

	--是传送点且没有被占领,先刷新数据，[[然后自动进入下一个界面]]此功能现在取消
	if self.isMapEnter and not self:checkOccupiedByPosition(self.owner.playerTitlePosition) then
		print("self:checkOccupiedByPosition(self.owner.playerTitlePosition)")
		self:refreshData()
		--刷新地图层数
		local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
		tempData.mapIndex = tempData.mapIndex + 1
		--记录在世界地图中提示的地图
		tempData.tipMapIndex = tempData.mapIndex

		self.owner:setVisible(false)
		self.layer:refreshLayerByInfo(self.curStrongholdData,true)
		self.layer.description:setVisible(false)
		DataManager:getInstance():setRoleData(roleMapInfo,tempData)
		-- print("刷新地图层数",tempData.mapIndex)
		
		local delay = cc.DelayTime:create(0.00)
        local call1 = cc.CallFunc:create(function ( ... )
        	local transformLayer = TransformLayer:create("报告船长，发现了新的海域!\n我们可以从此处传送至下一海域")
			transformLayer:setCalback(function (  )
			
			end)
			--执行中转动画
			transformLayer:transform(3.0,"out")
			self.owner:setVisible(true)
        end)

		local action = cc.Sequence:create(delay,call1)
		self:runAction(action)
		return
		-- self.layer:enterNextMapEnter()
	end

	self:allEventsHasTriggered(false)
	
end

function EventManger:checkBossAchievement(  )

	achievementValue = DataManager:getInstance():getAchievementInfo(achievement_KillBoss)
	DataManager:getInstance():setAchievementInfo(achievement_KillBoss, self.curStrongholdData["ID"])

end

--放弃事件(直接离开)
function EventManger:anEventHasToGiveUp( )
	--清除等待队列
	self.eventWaitingQueue = nil
	self.eventWaitingQueue = {}

	--直接异常跳转到所有事件已经触发完毕了
	self:allEventsHasTriggered(true)

end


--所有事件都已经触发完毕
function EventManger:allEventsHasTriggered( isBreak )

	--去除战斗状态
	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	tempData.willFight = nil
	DataManager:getInstance():setRoleData(roleMapInfo,tempData)

	-- print("isFightBack",isBreak)

	--消除特效和检查任务
	if self.curStrongholdData and not self.isMinesweeper and isBreak ~= true then
		self.owner.mapLayoutManagers:clearStrongholdTipData( self.owner.playerTitlePosition )

		--检查任务(类型，通关据点)
		local taskID = self.curStrongholdData["taskID"]
		local taskOk = self.curStrongholdData["taskOk"]
		local id = self.curStrongholdData["ID"]

		local stepInfos = {}
		stepInfos.id = id
		stepInfos.num = 1
		MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)

	end

	if self.isMinesweeper == false and isBreak ~= true and self.isNeedOccupied == true then
		print("allEventsHasTriggered",isBreak,self.isNeedOccupied)
		self:refreshData()
	end

	--通知遭遇逻辑中心，一个遭遇战斗胜利结束
	if self.isMinesweeper and not isBreak then
		SkirmishLogicManagers:getInstance():minesweeperFightIsOver()
	end

	self.isMinesweeper = false

	self.isNeedOccupied = false
	self.isBoss = false
	self.willTip = false
	self.isMapEnter = false

	self.curStrongholdData = nil
	
	self:unreezeOwnerOperations()
	self.layer:hide()
	FightDataManager:getInstance().totalLevel = 0
	-- print("remove all touches")
	touchTable = nil
	touchTable = {}
	cur_touchContentOffset = 0
	self.owner:checkBread()
end

function EventManger:enterEnemyLayer(addDropData,calBack)
	self.layer:getsAndSetsEnemyLayerInfoByEnemy(self.enemys[1],addDropData,calBack)
	-- self.layer:enterFightLayer(false)
end

--查看当前遇到的可能性
function EventManger:getMinesweeperProbability( )
	local bagData = ""
	local probability = 0

	self.minesweeperNums = self.minesweeperNums + 1

    -- 遇战船概率 --
	if self.minesweeperNums <= 10 then
		probability = 0.011
    elseif self.minesweeperNums <= 15 then
        probability = 0.052
	elseif self.minesweeperNums <= 20 then
		probability = 0.101
    elseif self.minesweeperNums <= 25 then
        probability = 0.152
    elseif self.minesweeperNums <= 30 then
        probability = 0.172
	elseif self.minesweeperNums <= 35 then
		probability = 0.206
    elseif self.minesweeperNums <= 42 then
        probability = 0.277
    elseif self.minesweeperNums <= 50 then
        probability = 0.359
    elseif self.minesweeperNums >= 50 then
        probability = 0.504
	end

    local mapIndex = self.owner.mapIndex
    if mapIndex <= 0 then mapIndex = 1 end
    probability = (probability/mapIndex)*3.0

	-- local bread = self.owner.breadNum

	-- if bread < 5 then
	-- 	probability = 0.1
	-- else
	-- 	local addNum =  0
	-- 	if math.floor((bread - 5) / 5) > ((bread - 5) / 5) - 0.5 then
	-- 		addNum = math.floor((bread - 5) / 5)
	-- 	else
	-- 		addNum = math.ceil((bread - 5) / 5)
	-- 	end
		-- print("addNum",addNum)
	-- 	probability = 0.1 + addNum * 0.02
	-- end

	-- --限制小于0.5
	probability = math.min(probability,0.5)

	-- probability = 0.05
	-- probability = 0
	return probability
end

function EventManger:tryToMinesweeper()
	local probability = self:getMinesweeperProbability()

	math.randomseed(tostring(os.time()):reverse():sub(1, 6) )

	local totalNum = math.random() * 10000
	local judgeNum = 100 * probability
	-- print("tryToMinesweeper",totalNum,totalNum % 101,judgeNum)

	if totalNum % 101 <= judgeNum then
		return true
	end

	return false
end

--坐标获得敌人信息
--由于加入赏金任务，所以在随机遇敌的时候需要对当前赏金任务进行判断
function EventManger:getMinesweeperEnemys( enemys )

	if not enemys then
		enemys = self.owner.mapLayoutManagers:getRandomEnemy()
	end

	-- print("getMinesweeperEnemys")
	-- for k,v in pairs(enemys) do
		-- print(k,v)
	-- end

	self.enemys = clone(enemys)
	self.layer:getsAndSetsEnemyLayerInfoByEnemy(self.enemys)
	--获得玩家坐标
	local playerPosition = cc.p(self.owner.player:getPositionX(),self.owner.player:getPositionY())
	playerPosition = self.owner:tileCoordForPosition(playerPosition)

	-- --转换成策划坐标
	playerPosition = self:getShitsPlannersCoordForPosition(playerPosition , self.owner.map:getMapSize())

	-- --根据对应的策划坐标获得敌人信息
	-- local enemys = "1"

	return enemys
end


function EventManger:enterTipOccupiedLayer(  )
		self.layer:showTipOccupiedLayer(self.curStrongholdData)
end

function EventManger:minesweeper( )
	
	--新手引导不能遇敌
	if self.owner.isNeedGuide then
		return
	end
	
	self.isMinesweeper = self:tryToMinesweeper()

	-- print("minesweeper",self.isMinesweeper)

	if self.isMinesweeper then
		self.minesweeperNums = 0
		--冻结操作
		self:freezeOwnerOperations()

		--先检测特殊怪物
		local enemys = SkirmishLogicManagers:getInstance():tryMeetSpecialMonster()

		self:getMinesweeperEnemys(enemys)
		self.owner:minesweeperTip()
	else
		self:unreezeOwnerOperations()
	end

	return self.isMinesweeper
end

function EventManger:minesweeperFight(  )
	self.enemys = nil
	self.enemys = {}
	self.layer:enterFightLayer(true)
end

function EventManger:calFight( enemys )
	
	self.layer:enterFightLayer(enemys)

end

--一个战斗结束了
function EventManger:oneFightIsOver( beat )
	--若被击败则返回主城
	if not beat then
		self:allMembersKilled()
	else
		self:anEventHasTriggered()
	end
end

--战斗中全员阵亡
function EventManger:allMembersKilled( )

	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	tempData.willFight = nil
	DataManager:getInstance():setRoleData(roleMapInfo,tempData)

	self.owner:returnToBase( "Killed" )
end


