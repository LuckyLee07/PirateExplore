require "LuaClass/Header"
require "LuaClass/CSVParser"


StaticData = class("StaticData", function ()
	return cc.Node:create()
end)

StaticData._achievement = nil
StaticData._buff = nil
StaticData._build = nil
StaticData._produce = nil
StaticData._resourceInfo = nil
StaticData._skillAttribute = nil
StaticData._soilderAttribute = nil
StaticData._store = nil
StaticData._talent = nil
StaticData._worker = nil
StaticData._strongholdAttribute = nil
StaticData._strongholdDistribution = nil
StaticData._worldMapCoordinates = nil
StaticData._eternalArena = nil
StaticData._fightBoxes = nil
StaticData._randomEvent = nil
StaticData._plot = nil
StaticData._shopGift = nil
StaticData._shopItem = nil
StaticData.loadingTips = nil
StaticData._gift = nil
StaticData._pushGift = nil
StaticData.__blackMarket = nil
StaticData._task = nil
StaticData._encounter = nil 
function StaticData:create()
	-- body
	local instance = StaticData:new()
	instance:initWithData()
	return instance
end

function StaticData:initWithData()
	-- body
	-- 加载数据表格
	local parser = CSVParser:getInstance()
	self._achievement = parser:loadFileByName("data/achievement.csv")
	self._buff = parser:loadFileByName("data/buff.csv")
	self._build = parser:loadFileByName("data/build.csv")
	self:splitValueToMatrix(self._build, "activateID")
	self:splitValueToMatrix(self._build, "activeInfo")

	self._produce = parser:loadFileByName("data/produce.csv")
	self:splitValueToMatrix(self._produce, "activateID")
	--self:splitValueToMatrix(self._produce, "comment")

	--print("**************** 555555", self._produce["33"]["resume"][1][1], self._produce["3"]["resume"][1][2])
	--print("**************** 555555", self._produce["33"]["comment"][1][1], self._produce["3"]["comment"][2][1])
	self._strongholdAttribute = parser:loadFileByName("data/strongholdAttribute.csv")
	self._strongholdDistribution = parser:loadFileByName("data/strongholdDistribution.csv")
	self._worldMapCoordinates = parser:loadFileByName("data/WorldMapCoordinates.csv")

	self:splitValueToMatrix(self._strongholdDistribution,"interiorInfo")
	self:splitValueToMatrix(self._strongholdDistribution,"peripheryInfo")
	self:splitValueToMatrix(self._strongholdDistribution,"enemyInfo")
	self:splitValueToMatrix(self._strongholdDistribution,"bread")
	self:splitValueToMatrix(self._strongholdDistribution,"guard")
	self:splitValueToMatrix(self._strongholdDistribution,"activateID")
	self:splitValueToMatrix(self._strongholdDistribution,"centralityInfo")
	self:splitValueToMatrix(self._strongholdDistribution,"gohome")
	self:splitValueToMatrix(self._strongholdDistribution,"openitems")
	self:splitValueToMatrix(self._strongholdDistribution,"plots")
	self:splitValueToMatrix(self._strongholdDistribution,"dropitems")

	self:splitValueToMatrix(self._strongholdAttribute,"enemys")
	self:splitValueToMatrix(self._strongholdAttribute,"dropitems")
	self:splitValueToMatrix(self._strongholdAttribute,"openbuilding")
	self:splitValueToMatrix(self._strongholdAttribute,"produceID")
	self:splitValueToMatrix(self._strongholdAttribute,"Carryitems")
	self:splitValueToMatrix(self._strongholdAttribute,"requiredtool")

	self._resourceInfo = parser:loadFileByName("data/resourceInfo.csv")
	self:splitValueToMatrix(self._resourceInfo,	"resume")
	self:splitValueToMatrix(self._resourceInfo,	"raiseType")
	-- self:splitValueToMatrix(self._resourceInfo, "price")

	self.loadingTips = parser:loadFileByName("data/loadingTips.csv")

	self._eternalArena = parser:loadFileByName("data/eternalArena.csv")
	self:splitValueToMatrix(self._eternalArena,"quickChallengesCost")
	self:splitValueToMatrix(self._eternalArena,"rewards")

	self._skillAttribute = parser:loadFileByName("data/skillAttribute.csv")

	self._soilderAttribute = parser:loadFileByName("data/soilderAttribute.csv")
	self:splitValueToMatrix(self._soilderAttribute,"produceResume")
	self:splitValueToMatrix(self._soilderAttribute,"rebornConsume")
	self:splitValueToMatrix(self._soilderAttribute,"changeJob")
	self:splitValueToMatrix(self._soilderAttribute,"dropitems")
    self:splitValueToMatrix(self._soilderAttribute,"talk1")
    self:splitValueToMatrix(self._soilderAttribute,"talk2")

	self._store = parser:loadFileByName("data/store.csv")
	self:splitValueToMatrix(self._store, "activateID")

	self._talent = parser:loadFileByName("data/talent.csv")
	self:splitValueToArray(self._talent, "preID")
	self:splitValueToArray(self._talent, "increaseAttrs")
	self:splitValueToArray(self._talent, "increaseTypes")
	self:splitValueToArray(self._talent, "increaseNums")

    self._fightBoxes = parser:loadFileByName("data/fightboxes.csv")
    self:splitValueToMatrix(self._fightBoxes,"propA")
    self:splitValueToMatrix(self._fightBoxes,"propB")
    self:splitValueToMatrix(self._fightBoxes,"propC")
    self:splitValueToMatrix(self._fightBoxes,"propShow")

    self._randomEvent = parser:loadFileByName("data/randomEvent.csv")
    self:splitValueToMatrix(self._randomEvent,"cost")
    self:splitValueToMatrix(self._randomEvent,"info")

    self._plot = parser:loadFileByName("data/plot.csv")
    self:splitValueToMatrix(self._plot, "story")

	self._worker = parser:loadFileByName("data/worker.csv")
	self:splitValueToMatrix(self._worker, "produce")
	-- self:splitValueToMatrix(self._worker, "produceDesc")
	self:splitValueToMatrix(self._worker, "resume")

	self:splitValueToMatrix(self._build,"resume")
	-- self:splitValueToMatrix(self._worker, "resumeDesc")
	-- 注意这个表根据ab类包读取不同的csv了，请注意 by 杨杰
	self._shopGift = parser:loadFileByName("data/shopgift"..zqPackageType..".csv")
	self:splitValueToMatrix(self._shopGift, "item")
	self:splitValueToArray(self._shopGift, "desc")

    self._shopItem = parser:loadFileByName("data/shopitem.csv")
    self:splitValueToArrayBySeparators(self._shopItem, "resume", "_")

    self._gift = parser:loadFileByName("data/gift.csv")
    self:splitValueToMatrix(self._gift, "items")

    self._pushGift = parser:loadFileByName("data/giftPush.csv")
    self:splitValueToMatrix(self._pushGift, "title")
    self:splitValueToMatrix(self._pushGift, "star")
    self:splitValueToMatrix(self._pushGift, "price")
    self:splitValueToMatrix(self._pushGift, "desc")

    self._logingReward = parser:loadFileByName("data/logingReward.csv")
    self:splitValueToMatrix(self._logingReward, "reward")
    self:splitValueToMatrix(self._logingReward, "Tips")
    
    self._mapStrategy = parser:loadFileByName("data/esoterica.csv")
    self:splitValueToMatrix(self._mapStrategy, "Tips")


    self.__blackMarket = parser:loadFileByName("data/blackMarket.csv")
    self:splitValueToMatrix(self.__blackMarket, "fixed")
    self:splitValueToMatrix(self.__blackMarket, "random")


    self._task = parser:loadFileByName("data/task.csv")
    self:splitValueToMatrix(self._task, "complete")
    self:splitValueToMatrix(self._task, "killItems")
    self:splitValueToMatrix(self._task, "reward")

    self._encounter = parser:loadFileByName("data/Encounter.csv")
    self:splitValueToMatrix(self._encounter, "Type")
    self:splitValueToMatrix(self._encounter, "consumption")
    self:splitValueToMatrix(self._encounter, "Enemys")
    self:splitValueToMatrix(self._encounter, "area")

end

function StaticData:getCSVByID(csvID)
	-- body
	if (csvID == csvOfAchievement) then
		return self._achievement
	elseif (csvID == csvOfBuff) then
		return self._buff
	elseif (csvID == csvOfBuild) then
		return self._build
	elseif (csvID == csvOfProduce) then
		return self._produce
	elseif (csvID == csvOfResourceInfo) then
		return self._resourceInfo
	elseif (csvID == csvOfSkillAttribute) then
		return self._skillAttribute
	elseif (csvID == csvOfSoilderAttribute) then
		return self._soilderAttribute
	elseif (csvID == csvOfStore) then
		return self._store
	elseif (csvID == csvOfTalent) then
		return self._talent
	elseif (csvID == csvOfWorker) then
		return self._worker
	elseif (csvID == csvOfStrongholdAttribute) then
		return self._strongholdAttribute
	elseif (csvID == csvOfStrongholdDistribution) then
		return self._strongholdDistribution
    elseif (csvID == csvOfFightBoxes) then
        return self._fightBoxes
    elseif (csvID == csvOfWorldMapCoordinates) then
        return self._worldMapCoordinates
    elseif (csvID == csvOfRandomEvent) then
        return self._randomEvent
    elseif (csvID == csvOfPlot) then
        return self._plot
    elseif (csvID == csvOfEternalArena) then
    	return self._eternalArena
    elseif (csvID == csvOfShopGift) then
        return self._shopGift
    elseif (csvID == csvOfShopItem) then
        return self._shopItem
    elseif (csvID == csvOfLoadingTips) then
    	return self.loadingTips
    elseif (csvID == csvOfGift) then
    	return self._gift
    elseif (csvID == csvOfPushGift) then
        return self._pushGift
    elseif (csvID == csvOfLogingReward) then
    	return self._logingReward
    elseif (csvID == csvOfMapStrategy) then
    	return self._mapStrategy
    elseif (csvID == csvOfBlackMarket) then
    	return self.__blackMarket
    elseif (csvID == csvOftask) then
    	return self._task
    elseif (csvID == csvOfEncounter) then
    	return self._encounter
	end
end

function StaticData:splitValueToMatrix(tableData, key)
	-- body
	self:splitValueToMatrixBySeparators(tableData, key, ";", "_")
end

function StaticData:splitValueToMatrixBySeparators(tableData, key, separator1, separator2)
	-- body
	for k,v in pairs(tableData) do
		local data = v[key]
		v[key] = splitToMatrix(v[key], separator1, separator2)
		remove(data)
	end
end

function StaticData:splitValueToArray(tableData, key)
	-- body
	self:splitValueToArrayBySeparators(tableData, key, ";")
end

function StaticData:splitValueToArrayBySeparators(tableData, key, separator)
	-- body
	for k,v in pairs(tableData) do
		local data = v[key]
		v[key] = split(v[key], separator)
		remove(data)
	end
end

