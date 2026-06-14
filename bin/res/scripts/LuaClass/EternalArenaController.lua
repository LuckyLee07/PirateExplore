require "LuaClass/Header"


EternalArenaController = class("EternalArenaController",function ()
	 return {}
end)
--永恒竞技场逻辑
--[[
	0,将敌人数赋值改为在EternalArenaController内部，掉落数据也改在EternalArenaController内部
	1,每层都得有个记录roledata，其意义是在战斗大退中，重进可以继续打本层，不用钻石，然后每层打过之后，检查是否是花费记录点，若是，保存在roledata中,然后检查是否是刷新数据点(也就是endLevel)
	2，调用分发层的战斗接口，掉落数据为本层的掉落数据(EventManger:enterEnemyLayer(addDropData))，然后走正常流程
	3,胜利，回到步骤1，反复循环，失败，扣除之前全部的掉落数据，退出事件触发界面
	4,若直接快速战斗，先弹出结算漂浮字，然后直接去对应的关卡+1
]]

local eternalArenaController = nil

EternalArenaController.__index = EternalArenaController
EternalArenaController.curlevel = 0
EternalArenaController.nextRefreshLevel = 0
EternalArenaController.curCoefficient = 0
EternalArenaController.curInfoId = nil
EternalArenaController.owner = nil
EternalArenaController.csvData = nil
EternalArenaController.enemyRange = {}
EternalArenaController.rewards = nil
EternalArenaController.saveDatas = nil
function EternalArenaController:getInstance(owner)
	print("EternalArenaController:getInstance!");

	if eternalArenaController == nil then
		eternalArenaController = EternalArenaController.new()
	
		if eternalArenaController and eternalArenaController:init(owner) then
			return eternalArenaController
		end
	end

	return eternalArenaController
end

function EternalArenaController:init( owner )
	
	self.owner = owner

	self.csvData = DataManager:getInstance():getCSVByID(csvOfEternalArena)

	return self.owner == nil
end

function EternalArenaController:destoryEternalArenaController( )
	
	eternalArenaController = nil

end
--刷新信息
function EternalArenaController:refreshNextInfo(  )
	
	if self.curInfoId == nil then
		self.curInfoId = "1"
	else
		self.curInfoId = tostring(self.nextRefreshLevel)
	end

	print("refreshNextInfo",self.curInfoId)

	local infoDatas = self.csvData[self.curInfoId]

	self.curlevel = tonumber(infoDatas["startLevel"])
	self.nextRefreshLevel = tonumber(infoDatas["endLevel"]) + 1

	self.curCoefficient = tonumber(infoDatas["coefficient"])

	self.enemyRange.min = tonumber(infoDatas["enemyStartIndex"])
	self.enemyRange.max = tonumber(infoDatas["enemyEndIndex"])

	print("EternalArenaController:refreshNextInfo.range",self.enemyRange.min,self.enemyRange.max)

	self.rewards = infoDatas["rewards"]

	self.saveDatas = nil

	if infoDatas["quickChallengesCost"][1][1] ~= "0" then
		self.saveDatas = {}
		self.saveDatas.level = self.curlevel
		self.saveDatas.costs = {}
		local tempData = nil

		tempData = infoDatas["quickChallengesCost"][1]
		self.saveDatas.costs.id = tempData[1]
		self.saveDatas.costs.num = tonumber(tempData[2])

		-- for i=1,#infoDatas["quickChallengesCost"] do
			
		-- end
	end

end

--设置敌人id
function EternalArenaController:setEnemyId(  )

	local enemy = {}
	--设置怪物属性加层系数
	enemy.coefficient = self.curCoefficient
	--屏蔽怪物的自己带的掉落数据
	enemy.isOwnDrop = false
	--设置怪物id
	enemy[1] = tostring(getRandomNumByRange(self.enemyRange))
	print("EternalArenaController:setEnemyId",enemy[1])
	print("setEnemyId",self.owner.enemys,#self.owner.enemys)
	self.owner.enemys[#self.owner.enemys + 1] = enemy
end
--获得通关level的所有掉落数据
function EternalArenaController:getAllRewardsByLevel( level )

	local info = nil
	local start = 0
	local ended = 0
	local num = 0
	local rewards = {}
	local tempRewards = nil
	local tempData = nil
	local i = 1
	while i < level  do

		print("getAllRewardsByLevel:",tostring(i))
		info =  self.csvData[tostring(i)]
		start = tonumber(info["startLevel"])
		ended = tonumber(info["endLevel"])

		if level > ended then
			num = ended - start
			i = ended + 1
		else
			num = level - start
			i = level
		end
		
		tempRewards = info["rewards"]

		for i=1,#tempRewards do
			tempData = tempRewards[i]
			local data = {}
			data.id = tempData[1]
			data.num = tonumber(tempData[2]) * num
			rewards[#rewards + 1] = data
		end

		print("ended",i)

	end

	-- for i=1,level do
	-- 	print("getAllRewardsByLevel:",tostring(i))
	-- 	info =  self.csvData[tostring(i)]
	-- 	start = tonumber(info["enemyStartIndex"])
	-- 	ended = tonumber(info["enemyEndIndex"])

	-- 	if level > ended then
	-- 		num = ended - start
	-- 		i = ended
	-- 	else
	-- 		num = level - start
	-- 		i = level
	-- 	end
		
	-- 	tempRewards = info["rewards"]

	-- 	for i=1,#tempRewards do
	-- 		tempData = tempRewards[i]
	-- 		local data = {}
	-- 		data.id = tempData[1]
	-- 		data.num = tonumber(tempData[2]) * num
	-- 		tempRewards[#tempRewards + 1] = data
	-- 	end
	-- 	print("ended",i)
	-- end

	return rewards
end
--直接跳到对应的层数
function EternalArenaController:jumpToFightByLevel( level )
	
	level = tonumber(level)
	
	--设置上一次战斗背包数据
	ExploreBagController:getBagController():setLastBattlePackData(true)

	--获得所有掉落信息
	local rewards = self:getAllRewardsByLevel(level)
	--将奖励数据添加到背包中
	ExploreBagController:getBagController():addItems(rewards)
	--刷新竞技场的获得的物品数据
	ExploreBagController:getBagController():refreshTempData()

	--设置刷新id
	self.curInfoId = "1" --1只是让它不进入重新赋值
	self.nextRefreshLevel = level
	print("level",level)
	--刷新数据，所有初始化流程完毕，开始进入控制流程
	self:refreshNextInfo()
end
--开始控制
function EternalArenaController:bagainControleEternalArenaByLevel( level )
	
	print("EternalArenaController:bagainControleEternalArenaByLevel")

	if level ~= nil then

		self:jumpToFightByLevel(level)

	else
		self.curInfoId = nil
		self:refreshNextInfo()
	end

	self:aNewRoundStart()
end
--准备新的一轮,(检查刷新和存入记录点都在这里)
function EternalArenaController:prepareToNewRound()
	ExploreBagController:getBagController():refreshBattlePack()
	--刷新竞技场的获得的物品数据,获得数据差值
	ExploreBagController:getBagController():refreshTempData()

	--层数加1
	self.curlevel = self.curlevel + 1

	--重新刷新战斗掉落数据
	if self.curlevel == self.nextRefreshLevel then
		self:refreshNextInfo()
	end



	--若通关开始的第一层，有记录点数据则存入记录点数据
	if self.curlevel == tonumber(self.csvData[self.curInfoId]["startLevel"]) + 1 and self.saveDatas ~= nil then
		local records = DataManager:getInstance():getRoleData(roleArenaRecords)

		--第一次写入信息创建新表
		if records == nil then
			records = {}
		end

		--判断之前是否记录过，没记录就记录一下
		if #records == 0 or ( records[#records].level < self.saveDatas.level ) then
			records[#records + 1] = self.saveDatas

			DataManager:getInstance():setRoleData(roleArenaRecords,records)
			print("存入永恒竞技场记录点",self.curlevel,self.saveDatas.level)
		end
	end

end

--一轮开始
function EternalArenaController:aNewRoundStart(  )
	--重新刷新上一次战斗背包数据
	ExploreBagController:getBagController():setLastBattlePackData()

	--添加战斗id
	self:setEnemyId()
	--刷新分发界面,由按钮回调，进行战斗
	self.owner:enterEnemyLayer(self.rewards,function ( fightResult )
		 self:aRoundEnd( fightResult )
	end)

	--改变对应的button回掉状态
	self.owner.layer.buttons[2]:registerSingleCLick(function (  )
		self:safeLeaveArena()
	end)


end

--一轮结束
function EternalArenaController:aRoundEnd( fightResult )
	
	-- local orgEnemys = self.owner.enemys
	-- local orgOwner = self.owner
	
	--若不需要pop，则返回
	if not self.owner.layer:checkPop() then
		return
	end

	print("EternalArenaController:aRoundEnd",fightResult,self.owner,self.owner.enemys)

	self.owner.enemys[1] = nil

	self.owner.layer.buttons[1]:setSingleCLickEnable(true)

	if fightResult == true then
		--杀怪成就记录点
		achievementValue = DataManager:getInstance():getAchievementInfo(achievement_KillMonster)
		DataManager:getInstance():setAchievementInfo(achievement_KillMonster, (achievementValue + 1))

		--获得最大值，判断并触发成就
		local maxRecords = DataManager:getInstance():getRoleData(roleArenaMaxRecord)
		
		if maxRecords == nil then
			maxRecords = 0
		end

		if maxRecords < self.curlevel then
			achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Arena)
   			DataManager:getInstance():setAchievementInfo(achievement_Arena, (achievementValue + 1),maxRecords)
		end

		--竞技场成就
		self:prepareToNewRound()
		self:aNewRoundStart()
		print("will pop")
		cc.Director:getInstance():popScene()
		print("pop over")
	else
		print("will pop")
		cc.Director:getInstance():popScene()
		print("pop over")
		self:curRoundIsDefeat()
	end


end

--在当前一轮中被击败
function EternalArenaController:curRoundIsDefeat( )
	local maxRecords = DataManager:getInstance():getRoleData(roleArenaMaxRecord)
	--若最大记录是空，说明没有打过，直接覆盖
	if maxRecords == nil or (maxRecords ~= nil and tonumber(maxRecords) < self.curlevel - 1) then
		DataManager:getInstance():setRoleData(roleArenaMaxRecord,self.curlevel - 1)
		maxRecords = self.curlevel - 1

		-- --竞技场成就记录点
		-- achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Arena)
		-- DataManager:getInstance():setAchievementInfo(achievement_Arena, (achievementValue + 1),maxRecords)
	end

	--被击败，丢失之前所有的竞技场物品数据
	ExploreBagController:getBagController():lostArenaGoods()
	--清除数据
	ExploreBagController:getBagController():clearAllEternalArenaData()
	--当放弃事件使用
	self.owner:anEventHasToGiveUp()
end

--正常离开，进行数据合并
function EternalArenaController:safeLeaveArena(  )
	local maxRecords = DataManager:getInstance():getRoleData(roleArenaMaxRecord)
	--若最大记录是空，说明没有打过，直接覆盖
	if maxRecords == nil or (maxRecords ~= nil and tonumber(maxRecords) < self.curlevel ) then
		DataManager:getInstance():setRoleData(roleArenaMaxRecord,self.curlevel - 1)
		maxRecords = self.curlevel 
		
		-- --竞技场成就记录点
		-- achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Arena)
		-- DataManager:getInstance():setAchievementInfo(achievement_Arena, (achievementValue + 1),maxRecords)
	end

	--获得所有之前的掉落数据
	ExploreBagController:getBagController():clearAllEternalArenaData()

	--将按钮2改回原来的回调事件
	self.owner.layer.buttons[2]:registerSingleCLick(function() 
        self.owner.layer:leaveToExploreMap(true)
    end)

	self.owner:anEventHasToGiveUp()
end
