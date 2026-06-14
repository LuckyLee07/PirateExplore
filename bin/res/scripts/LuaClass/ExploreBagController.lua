require "LuaClass/Header"
-- require "LuaClass/ExploreBagLayer"


local bagController = nil

ExploreBagController = class("ExploreBagController",function ()
	 return {}
end)
--背包逻辑
--[[
	1.普通战斗掉落，金钱之外的道具放入战斗背包，金钱则直接放入到背包中
	2.竞技场掉落,所有掉落都放入一个临时背包，一旦失败，临时背包的数据全部清空，否则，和背包数据合并，合并逻辑和普通战斗掉落逻辑一样
	3.背包界面中的数据需要实时刷新，so，一开始初始化已经没有必要，当在花费和添加需要关联的数据时，自动刷新背包数据所以，有些数据(type == 2)需要直接和背包关联。。。
	4.特例，福音是战斗背包单独显示，当进入背包再去拼接成总的，当花费的时候，先花费背包的，金币是直接合并的，不如金币就直接和背包关联，福音关联，但是得单独取出来
	5.解决方法，存3个背包数据,先从表中取出所有为2类型的数据，然后根据对应的key引用背包数据，背包数据1即可获得，背包数据2就是战斗背包,当需要消耗东西的时候先从战斗背包中消耗，战斗背包中没有
	再从背包数据1中消耗，背包数据3是竞技场的临时背包，合并的时候，钱和背包数据1合并，其他的和背包2合并，当点击背包界面的时候，先拼接数据，再初始化界面
]]

ExploreBagController.__index = ExploreBagController
ExploreBagController.owner = nil
ExploreBagController.limited = 100
ExploreBagController.costSpace = 0
ExploreBagController.contacts = {}
--地图背包默认携带的数据
ExploreBagController.data = nil
--参战人员
ExploreBagController.battleMemberData = nil
--战斗背包
ExploreBagController.battlePackData = nil
--上一轮永恒竞技场的战斗背包数据
ExploreBagController.lastBattlePackData = nil
ExploreBagController.lastAddMapCoin = -1
--临时背包数据(用于判断玩家进入永恒竞技场总共从其中得到了多少数据，在玩家失败的时候将战斗背包中的对应数据进行减法操作)
ExploreBagController.eternalArenaTempData = nil
ExploreBagController.layer = nil
ExploreBagController.breads = nil
ExploreBagController.mapCoin = 0
-- EventManger.curEventId

function ExploreBagController:destoryController(  )
	bagController = nil
end

function ExploreBagController:getBagController(owner)
	-- print("getBagController!");

	if bagController == nil then
		bagController = ExploreBagController.new()
	
		if bagController and bagController:init(owner) then
			return bagController
		end
	end

	return bagController;
end

function ExploreBagController:init(owner)

	self.owner = owner
    -- print("ExploreBagController:init!");
    self:initDatas()
    return true;
end

function ExploreBagController:setDatas( )

	-- if #self.data > 0 then
		
	-- 	for k,v in pairs(#self.tempData) do
	-- 		if k
	-- 	end

	-- else
	-- 	self.data = self.tempData
	-- end

end

function ExploreBagController:setEternalArenaData( data )
	
	self.eternalArenaTempData = data

end

function ExploreBagController:lostArenaGoods(  )

	-- print("self.eternalArenaTempData",#self.eternalArenaTempData)

	
	local costDatas = {}
	--规范化掉落数据
	for k,v in pairs(self.eternalArenaTempData) do
		costDatas[#costDatas + 1] = v
		-- print(k,v)
	end

	-- print("丢失竞技场")
	self:costGoodsByGoods(costDatas)

	DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)

	--重置金钱
	self.mapCoin = self.lastAddMapCoin

	--重置标识
	self.lastAddMapCoin = -1
	-- print("丢失完毕之后的数据")
	-- for k,v in pairs(self.battlePackData) do
	-- 	-- print(k,v.num)
	-- end

end

function ExploreBagController:setLastBattlePackData( isClone )

	if isClone == nil then
		isClone = false
	end

	if isClone then
		self.lastBattlePackData = clone(DataManager:getInstance():getRoleData(roleBattlePack))
	else
		self.lastBattlePackData = DataManager:getInstance():getRoleData(roleBattlePack)
	end

	if self.lastAddMapCoin < 0 then
		self.lastAddMapCoin = self.mapCoin
	end
end

--每次永恒竞技场战斗完毕之后都要调用下这个接口，然后根据掉落数据，和之前的副本来刷新竞技场的临时数据
function ExploreBagController:refreshTempData(  )
	if self.lastBattlePackData == nil then
		return
	end
	-- print("refreshTempData")
	local item = nil

	for k,v in pairs(self.battlePackData) do
		-- print(k,v)
		item = self.lastBattlePackData[k]
		--若item没有，则说明是新添加的物品，直接将num赋给永恒竞技场临时背包中
		if item == nil then
			self.eternalArenaTempData[k] = {}
			self.eternalArenaTempData[k].id = v.id
			self.eternalArenaTempData[k].num = v.num
		--若item存在，则查看值是添加，还是减少
		else  
			local disNum = v.num - item.num
			--若是添加,则直接对数进行加减
			if disNum > 0 then 

				if self.eternalArenaTempData[k] == nil then
					self.eternalArenaTempData[k] = {}
					self.eternalArenaTempData[k].id = v.id
					self.eternalArenaTempData[k].num = 0
				end

				self.eternalArenaTempData[k].num = self.eternalArenaTempData[k].num + disNum

			--若是减少,首先判断是否是减少到的数据，是否比临时背包存储的数据还低，若是比临时背包还低，则说明动用了原始的数据，则要对少出来部分进行减法操作
			elseif disNum < 0 then
				
				if self.eternalArenaTempData[k] == nil then
					self.eternalArenaTempData[k] = {}
					self.eternalArenaTempData[k].id = v.id
					self.eternalArenaTempData[k].num = 0
				end

				if disNum * - 1 >= self.eternalArenaTempData[k].num then
					--获得少于的部分
					local costNum = -disNum - self.eternalArenaTempData[k].num
					self:costGoodsByGoodsIdAndNum(v.id,costNum,false)
					disNum = - self.eternalArenaTempData[k].num
				end
				--对临时背包数据进行减法操作
				self.eternalArenaTempData[k].num = self.eternalArenaTempData[k].num + disNum
				--若竞技场背包数据的num为0，对其进行删除操作
				if self.eternalArenaTempData[k].num == 0 then
					self.eternalArenaTempData[k] = nil
				end
			end

		end

	end

	-- print("刷新竞技场表")



	-- for k,v in pairs(self.eternalArenaTempData) do
	-- 	-- print(k,v.num)
	-- end

end

--获得所有掉落数据
function ExploreBagController:clearAllEternalArenaData( )
	-- printn("清楚数据")

	self.lastBattlePackData = nil
	self.eternalArenaTempData = nil
	self.eternalArenaTempData = {}
end

function ExploreBagController:getBreads( )
	
	if self:checkItem(1005) then
		return self.battlePackData["1005"].num
	end

	return 0
end

function ExploreBagController:initDatas( )
	
	if self.data == nil then
		self.data = {}
	end
	-- print("inited all Ids")
	self:refreshBagData()

	self:refreshBattlePack(true)
	-- print("battlePack")

	self.tempData = {}
	
	--获得战斗人员，采用引用
	self.battleMemberData = DataManager:getInstance():getRoleData(roleBattleQueue)
	self.eternalArenaTempData = {}
	--清除为0的数据
	-- print("self.data")
	local count = 0
	-- for k,v in pairs(self.data) do
	-- 	-- print(k,v)
	-- 	count = count + 1
	-- end

	--获得背包限制
	self.limited = DataManager:getInstance():getRoleData(rolePackSize)


	--获得背包金币数据
	self.mapCoin = DataManager:getInstance():getRoleData(roleMapCoin)

	if not self.mapCoin then
		self.mapCoin = 0
	end

	-- print("地图背包数据刷新完毕",count,self.limited)
end
--刷新背包信息
function ExploreBagController:refreshBagData(  )
	
	local infos = dataController.resourceInfo.original
	local tempData = nil

	-- print("original")

	--获得背包数据
	local bagData = DataManager:getInstance():getRoleData(rolePack)

	if self.data == nil then
		self.data = {}
	end
    
    -- local lastBagData = clone(self.data)

    local goodsInfo = nil

	local id = nil
	--初始化所有表的默认携带的数据，并且获取对应key的背包中数据引用
	for k,v in pairs(infos) do
		-- print(k,v)
		if v["carryType"] == "2" then
			id = v["ID"]
			--引用
			self.data[id] = bagData[id]
			-- goodsInfo = dataController.getResourceInfoById(id)

			-- --检查任务触发
			-- local taskID = goodsInfo["taskID"] 
			-- local taskOk = goodsInfo["taskOk"] 

			-- --触发任务
			-- if taskID and taskID ~= "0" then
			-- 	local stepInfos = {}
			-- 	stepInfos.id = id
			-- 	stepInfos.num = self.data[id]
			-- 	MissionManagers:getInstance():triggerMissionByIDAndStepInfos(taskID,stepInfos,"taskID")
			-- --更新任务进度
			-- elseif taskOk and taskOk ~= "0" then
			-- 	local stepInfos = {}
			-- 	stepInfos.id = id
			-- 	--获得之前的物品
			-- 	local lastNum = lastBagData[id]

			-- 	if not lastNum then
			-- 		lastNum = 0
			-- 	end

			-- 	stepInfos.num = self.data[id] - lastNum
			-- 	if stepInfos.num > 0 then
			-- 		MissionManagers:getInstance():triggerMissionByIDAndStepInfos(taskOk,stepInfos,"taskOk")
			-- 	end
			-- end

			-- print("carryType == 2",id,bagData[id],self.data[id],v["name"])
		end
	end
	-- print("引用完毕")
	-- for k,v in pairs(self.data) do
	-- 	-- print(k,v)
	-- end

end

--由于战斗那块都是clone的，所以我之前的引用机制无法满足数据刷新，所以每次战斗完毕之后都得刷新一下battlePack中的数据,也采用引用机制
function ExploreBagController:refreshBattlePack( isInit )
	
	-- print("战斗背包数据刷新")
	
	local tempData = DataManager:getInstance():getRoleData(roleBattlePack)
	local tempValue = nil
	local lastBattlePackData = self.battlePackData

	if not lastBattlePackData then
		lastBattlePackData = {}
	end

	--获得战斗背包的数据，采用引用
	self.battlePackData = {}



	-- printn(self.battlePackData)
--由于战斗需要，所以改变结构了，我这再重新变成杨哥的结构，为了方便雨神，所以用双key的结构
	for i=1,#tempData do
		tempValue = tempData[i]
		local value = {}
		value.id = tempValue.id
		value.num = tempValue.num
		self.battlePackData[tostring(value.id)] = value
	end

	--说明是完全一样的结构，则直接引用即可
	if _G.next(self.battlePackData) == nil then
		self.battlePackData = DataManager:getInstance():getRoleData(roleBattlePack)
	end

	--重置结构化的战斗背包数据
	DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)

	if self.owner.bread then
	--刷新面包数据	
	self.owner.bread:setString(string.format("  %d",self:getBreads()))
	end

	self.costSpace = 0

	local goodsInfo = nil

	--刷新空间
	for k,v in pairs(self.battlePackData) do
		self.costSpace = self.costSpace + self:itemIsConsumedSpaceById(v.id) * tonumber(v.num)

		goodsInfo = dataController.getResourceInfoById(v.id)

		--检查任务触发(类型，获得道具)
		local taskID = goodsInfo["taskID"] 
		local taskOk = goodsInfo["taskOk"] 

		local stepInfos = {}
		stepInfos.id = v.id
		
		local lastNum = lastBattlePackData[k]
		--获得上次的数量
		if not lastNum then
			lastNum = 0
		else
			lastNum = lastNum.num
		end

		--求数量差，看是否需要更新任务进度
		stepInfos.num = tonumber(v.num) - tonumber(lastNum)

		--触发任务
		if not isInit and stepInfos.num > 0 then
			MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)
		end

	end

	--更新背包容量显示
	self.owner:updataCapacityTips(self.costSpace,self.limited)
	-- print("battlePack")
end

--从背包数据中花费,先使用临时背包，若能完全花费，num返回0
function ExploreBagController:tryCostGoodsFromBag( id,num )

	num = tonumber(num)

	if self.data[id] ~= nil then
		self.tempData.willCostData["b"..id] = tonumber(self.data[id]) - num
		--若资源足够，将num设置为0，
		if self.tempData.willCostData["b"..id] >= 0 then
			num = 0
		else
			--数量不能小于0
			self.tempData.willCostData["b"..id] = 0
			num = num - tonumber(self.data[id]) 
		end
		
	end

	-- print("tryCostGoodsFromBag",num,self.tempData.willCostData["b"..id])

	return num
end

--从战斗背包中花费,,先使用临时背包，若能完全花费，num返回0
function ExploreBagController:tryCostGoodsFromBattlePack( id,num )

	num = tonumber(num)

	if self.battlePackData[id] ~= nil then
		self.tempData.willCostData["f"..id] = tonumber(self.battlePackData[id].num) - num
		--若资源足够，将num设置为0，
		if self.tempData.willCostData["f"..id] >= 0 then
			num = 0
		else
			--数量不能小于0
			self.tempData.willCostData["f"..id] = 0

			num = num - tonumber(self.battlePackData[id].num) 

		end
	end
	-- print("tryCostGoodsFromBattlePack",num,self.tempData.willCostData["f"..id])
	return num
end

function ExploreBagController:costGoodsByGoods( goods )
	
	if goods == nil then
		return true
	end

	-- print("costGoodsByGoods",#goods)

	local canCost = true
	local num = 0
	self.tempData.willCostData = {}
	local nums = {}
	for i=1,#goods do
		-- print("goods id ",goods[i].id,goods[i].num)
		nums[goods[i].id] = goods[i].num
		--先从战斗背包中扣除
		num = self:tryCostGoodsFromBattlePack(goods[i].id,goods[i].num)	
		--若剩下的数量大于0，则剩下的从地图背包中继续扣除
		if num > 0 then
			num = self:tryCostGoodsFromBag(goods[i].id,num)
			print("costGoodsByGoods:tryCostGoodsFromBag",num)
			--若还有剩余，说明无法扣除对应的物品，跳出循环
			if num > 0 then
				canCost = false
				break
			end
		end

	end

	--若可以完全扣除，则去除之前的数据
	if canCost then
		local fristKey = nil
		local id = nil
		for k,v in pairs(self.tempData.willCostData) do
			fristKey = string.sub(k,1,1)
			id = string.sub(k,2)
			--战斗背包中扣除
			if fristKey == "f" then

				local costSpace = self:itemIsConsumedSpaceById(id)
				self.costSpace = self.costSpace - costSpace * nums[id]

				self.battlePackData[id].num = self.tempData.willCostData["f"..id]
				DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)
				--若数量等于0了，则不需要这个数据了
				if self.battlePackData[id].num == 0 then
					self.battlePackData[id] = nil
				end
			--地图背包中扣除
			elseif fristKey == "b" then
				self.data[id] = self.tempData.willCostData["b"..id]
				DataManager:getInstance():addPackItemWithId(tostring(id), -1*tonumber(nums[id]))
				--若扣完之后数据为空，则将对应的数据清楚
				if self.data[id] == 0 then
					self.data[id] = nil
				end
			end
		end
	--更新背包容量显示
	self.owner:updataCapacityTips(self.costSpace,self.limited)
	end

	--清楚临时数据
	self.tempData.willCostData = nil

	return canCost
end

--查看物品是否拥有对应的物品
function ExploreBagController:checkItemsIsHave( items )
	local have = true
	local num = 0
	self.tempData.willCostData = {}
	for i=1,#items do
		--先从战斗背包中扣除
		num = self:tryCostGoodsFromBattlePack(items[i].id,items[i].num)	

		--若剩下的数量大于0，则剩下的从地图背包中继续扣除
		if num > 0 then
			num = self:tryCostGoodsFromBag(items[i].id,items[i].num)
			--若还有剩余，说明无法扣除对应的物品，跳出循环
			if num > 0 then
				have = false
				break
			end
		end
	end
	-- print("ExploreBagController:checkItemsIsHave",have,num,#items)
	self.tempData.willCostData = nil

	return have
end

function ExploreBagController:checkItemsIsHaveByIdAndNum( id,num  )
	
	local id = tostring(id)

	if num == nil then
		num = 1
	end

	num = tonumber(num)

	local costNum = num

	self.tempData.willCostData = {}

	--先从战斗背包中扣除
	num = self:tryCostGoodsFromBattlePack(id,num)

	--只有战斗背包中去掉的数据才会增加空间
	costNum = costNum - num

	--如果没有扣除完毕，再从背包中扣除
	if num > 0 then
		num = self:tryCostGoodsFromBag(id,num)
	end
	--若num为0则可以全部花费
	local have = num == 0



	return have
end

--花费东西
function ExploreBagController:costGoodsByGoodsIdAndNum( id,num,isTip,tipString )

	if self.data == nil then
		return false
	end

	if isTip == nil then
		isTip = true
	end

	if tipString == nil then
		tipString = "使用失败，没有足够的数量"
	end

	local id = tostring(id)

	if num == nil then
		num = 1
	end

	num = tonumber(num)

	local goodsName = dataController.getResourceValueByIdAndKey(id,"name")

	if goodsName == "金币" then
		local deal = DataManager:getInstance():addCoin(-num,false)
		if deal == 0 and isTip then
			deal = false
			self:tipUserByString(tipString)
		end
		return deal
	elseif goodsName == "钻石" then
		local deal = DataManager:getInstance():addDiamond(-num,false)
		if deal == 0 and isTip then
			deal = false
			self:tipUserByString(tipString)
		end
		return deal
	end

	local costNum = num
    local totalCost = num

	self.tempData.willCostData = {}

	--先从战斗背包中扣除
	num = self:tryCostGoodsFromBattlePack(id,num)

	--只有战斗背包中去掉的数据才会增加空间
	costNum = costNum - num

	--如果没有扣除完毕，再从背包中扣除
	if num > 0 then
		num = self:tryCostGoodsFromBag(id,num)
	end
	--若num为0则可以全部花费
	local canCost = num == 0
	--将临时数据对应的数量写入对应的背包
	if canCost == true then
		--战斗背包数据
		if self.tempData.willCostData["f"..id] ~= nil then
			self.battlePackData[id].num = self.tempData.willCostData["f"..id]
			-- DataManager:getInstance():addPackItemWithId(tostring(id), -1*tonumber(totalCost))
			--若扣完之后数据为空，则将对应的数据清楚
			if self.battlePackData[id].num == 0 then
				self.battlePackData[id] = nil
			end
			DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)
		--清除对应的空间
			local costSpace = self:itemIsConsumedSpaceById(id)
			self.costSpace = self.costSpace - costSpace * costNum
		end

		--背包数据
		if self.tempData.willCostData["b"..id] ~= nil then
			self.data[id] = self.tempData.willCostData["b"..id]
            DataManager:getInstance():addPackItemWithId(tostring(id), -1*tonumber(totalCost))
			--若扣完之后数据为空，则将对应的数据清楚
			if self.data[id] == 0 then
				self.data[id] = nil
			end
		end
		--更新背包容量显示
		self.owner:updataCapacityTips(self.costSpace,self.limited)
	end
	--释放之前使用过的数据
	self.tempData.willCostData = nil
	-- self.tempData.willCostData["f"..id] = nil
	-- self.tempData.willCostData["b"..id] = nil

	--
	-- print("canCost",canCost)
	if isTip and not canCost  then
		self:tipUserByString(tipString)
	end

	return canCost
end


function ExploreBagController:addCoin( addCoin )

	--记录数据
	self.mapCoin = self.mapCoin + addCoin
	DataManager:getInstance():setRoleData(roleMapCoin,self.mapCoin)

	--视觉欺骗
	money = DataManager:getInstance():getRoleData(roleMoney)
	money = money + self.mapCoin

	ToastUtil:downString("金币+" .. addCoin)
	ToastUtil:downString("总共" .. money.."金币")

end

function ExploreBagController:safeTransformCoinToPack( isDead )
	
	--不死亡就添加，否则清空
	if not isDead then
		DataManager:getInstance():addCoin(self.mapCoin)
	end
	
	self.mapCoin = 0
	DataManager:getInstance():setRoleData(roleMapCoin,self.mapCoin)
end


--安全清除战斗背包中默认自带的数据，并将其添加到背包数据中
function ExploreBagController:safeClearMissionData( )
	
	if self.battlePackData == nil then
		return
	end

	local dataType = nil

	for k,v in pairs(self.battlePackData) do
		-- print(k,v)
		dataType = dataController.getResourceValueByIdAndKey(k,"carryType")

		--若dataType为2，则为默认自带数据，直接添加到背包数据中,并将其从战斗背包中删除
		if dataType == "2" then
			DataManager:getInstance():addPackItemWithId(k,v.num)
			self.battlePackData[k] = nil
		end
	end

	--安全移除之后，覆盖战斗背包数据
	DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)

	-- print("战斗背包中的任务数据安全删除完毕")

end

function ExploreBagController:addItemToBattlePack( id,num,isBreakLimits )
	if num == nil then
		num = 1
	end


	-- print("self:checkItem(id)",self.battlePackData[tostring(id)])

	if self.battlePackData[tostring(id)] == nil then 
		self.battlePackData[tostring(id)] = {}
		self.battlePackData[tostring(id)].id = tostring(id)
		self.battlePackData[tostring(id)].num = 0
	end

	

	local oneCostSpace = self:itemIsConsumedSpaceById(id)
	-- print("addItemToBattlePack",self.costSpace,oneCostSpace,self.costSpace <= self.limited)

	--若是强制加入，则不用考虑背包容量
	if not isBreakLimits then
		while self.costSpace <= self.limited or oneCostSpace == 0 do

			self.battlePackData[tostring(id)].num = self.battlePackData[tostring(id)].num + 1

			num = num - 1

			if num < 1 then
				break
			end

			self.costSpace = self.costSpace + oneCostSpace
		end

		if num > 0 then
			self:tipUserByString("货舱已满，无法拾取更多的物品")
		end

	else

		self.battlePackData[tostring(id)].num = self.battlePackData[tostring(id)].num + num
		self.costSpace = self.costSpace + oneCostSpace * num
	end

	-- print("添加完毕")

	self.owner:updataCapacityTips(self.costSpace,self.limited)
	DataManager:getInstance():setRoleData(roleBattlePack,self.battlePackData)
	--刷新面包数据	
	self.owner.bread:setString(string.format("  %d",self:getBreads()))
	-- for k,v in pairs(DataManager:getInstance():getRoleData(roleBattlePack)) do
		-- print(k,v)
	-- end

end

--获得很多物品
function ExploreBagController:addItems( items )
	local geted = false 

	for k,v in pairs(items) do
		
		geted = self:addItemToBattlePack(v.id,v.num)
		
		if geted == false then
			return
		end
	end

	return true
end

--获得一些同样的物品
function ExploreBagController:addItemByidAndNum( id,num )

	if num == nil then
		num = 1
	end

	if not self:checkItem(id) then 
		self.data[tostring(id)] = {}
		self.data[tostring(id)].num = 0
	end

	local oneCostSpace = self:itemIsConsumedSpaceById(id)

	local totalCostSpace = self.costSpace 
	totalCostSpace = totalCostSpace + oneCostSpace
	while totalCostSpace <= self.limited do
		self.data[tostring(id)].num = self.data[tostring(id)].num + 1
		num = num - 1
		if num < 1 then
			break
		end
		totalCostSpace = totalCostSpace + oneCostSpace
	end

	if num > 0 then
		self:tipUserByString("货舱已满，无法拾取更多的物品")
		return false
	end

	return true
end

--检查id对应id的item是否存在
function ExploreBagController:checkItem( id )

	local isExist = self.data[tostring(id)] ~= nil or self.battlePackData[tostring(id)] ~= nil

	-- print("checkItemFunc",self.data[tostring(id)],isExist)

	return isExist
end

function ExploreBagController:tipUserByString( string )
	ToastUtil:toastString(string)
end

--检查物品是否消耗空间，是的话返回对应的消耗空间，否则返回0
function ExploreBagController:itemIsConsumedSpaceById( id )
	local costSpace = 0 
	local itemInfo = dataController.getResourceInfoById(id)

	if itemInfo ~= nil then
		costSpace = tonumber(itemInfo["cubage"])
	end

	return costSpace
end

--获得所有道具详细的数据信息(供背包界面使用)
function ExploreBagController:getAllDataInfo( )
	
	local pkgData = {}
	print("getAllDataInfo1")
	local tempRecord = {}

	--金币，单独处理
	money = DataManager:getInstance():getRoleData(roleMoney)
	money = money + self.mapCoin
	
	local pData = {}
	pData.name = "金币"
    pData.icon = dataController.getResourceValueByIdAndKey("1001", "iconName")
    pData.star = tonumber(dataController.getResourceValueByIdAndKey("1001", "starNum"))
	pData.num = money
    pData.id = "1001"

	pkgData[1] = pData

	--战斗背包
	for k,v in pairs(self.battlePackData) do
		print(k,v)
		local pData = {}
		pData.name = dataController.getResourceValueByIdAndKey(k, "name")
	    pData.icon = dataController.getResourceValueByIdAndKey(k, "iconName")
	    pData.star = tonumber(dataController.getResourceValueByIdAndKey(k, "starNum"))
		pData.num = v.num
	    pData.id = k
	    local index = #pkgData+1
	    tempRecord[tostring(k)] = index
	    pkgData[index] = pData
	end
	-- printn("battlePackData",pkgData)
	--背包数据
	--由于背包有些数据需要事实更新，所以在每次进入背包界面时候，先刷新背包数据
	self:refreshBagData()
	for k,v in pairs(self.data) do

		if tempRecord[tostring(k)] ~= nil then
			local index = tempRecord[tostring(k)]
			local pData = pkgData[index]
			pData.num = pData.num + tonumber(v)
		else
			local pData = {}
			pData.name = dataController.getResourceValueByIdAndKey(k, "name")
		    pData.icon = dataController.getResourceValueByIdAndKey(k, "iconName")
		    pData.star = tonumber(dataController.getResourceValueByIdAndKey(k, "starNum"))
			pData.num = v
		    pData.id = k
		    pkgData[#pkgData+1] = pData
		end
	end
	-- printn("bagData",pkgData)
	

	--战斗人员
	for k,v in pairs(self.battleMemberData) do
		-- print("battleMemberData",k,v)
		local pData = {}
		pData.name = dataController.getSoilderValueByIdAndKey(k, "name")
	    pData.icon = dataController.getSoilderValueByIdAndKey(k, "icon")
	    pData.star = tonumber(dataController.getSoilderValueByIdAndKey(k, "star"))
	    print("fight",pData.star)
		pData.num = v
	    pData.id = k
	    pkgData[#pkgData+1] = pData
	end



	return pkgData
end



