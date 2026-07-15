-- UI相关(注意这两个参数只有在controller初始化方法执行之后才会有值)
UITopHeight = 0.0
UIBottomHeight = 0.0

-- ttf相关字体
BoldFont = "Arial-BoldMT"

-- ttf相关颜色
BaseColor = cc.c3b(215, 199, 165)
WriteColor = cc.c3b(229, 229, 229)
GreenColor = cc.c3b(95, 255, 51)
YellowColor = cc.c3b(255, 255, 0)
Khaki = cc.c3b(215, 199, 165)
RedColor = cc.c3b(255, 0, 0)

-- 系统信息数据（仅缓存）
SystemInfoData = {}

require "LuaClass/Header"
require "LuaClass/CSVParser"
require "LuaClass/StaticData"
require "LuaClass/UserData"
require "LuaClass/SaveDataManager"
require "LuaClass/DynamicData"
require "LuaClass/AlertView"
require "json"

DataManagerSingleton = nil

DataManager = class("DataManager", function ()
	return cc.Node:create()
end)

-- DataManager.__mapData = nil

DataManager.__index = DataManager
DataManager.__banner = nil
DataManager.__eventListener = nil
DataManager.__eventDispatcher = nil
DataManager.__roleData = nil
DataManager.__staticData = nil
DataManager.__produceCD = 0
DataManager.__curTime = 0
DataManager.__produceIndex = 0
DataManager.__dynamicData = nil
DataManager.__schduler = nil
DataManager.__timer = 0
DataManager.__counter = 0
function DataManager:getInstance()
	if DataManagerSingleton == nil then
		DataManagerSingleton = DataManager.new()
		DataManagerSingleton:initWithData()
		DataManagerSingleton:retain()
	end
	return DataManagerSingleton
end

function DataManager:initWithData()
	local parser = CSVParser:getInstance()
	-- self.__banner = parser:loadFileByName("data/produce.csv")
	-- local data = self:getData(self.__banner, "8", "name")
	-- local rowData = self:getRowData(self.__banner, "6")

	self.__eventListener = {}

	self.__eventDispatcher = cc.Director:getInstance():getNotificationNode():getEventDispatcher()

	-- self:registerEvent(modelDataName, "test1", test1)
	-- self:registerEvent(modelDataName, "test2", test2)
	
	self.__staticData = StaticData:create()
	self.__staticData:retain()

	self.__roleData = UserData:create()
	self.__roleData:retain()

	-- -- test
	-- local testStr = "123456肯定撒凡客网"
	-- local test = split(testStr, ";")
	-- print("------- 1111", test)
	-- print("---------", tableToJson(test))

	-- local testStr1 = "123456肯定撒凡客网;"
	-- local test1 = split(testStr1, ";")
	-- print("------- 2222", test1)
	-- print("---------", tableToJson(test1))

	-- 加载本地存储数据
	if (not self.__roleData:loadData()) then
		-- 第一次进入游戏设置默认数据
		self.__roleData:loadProducerQueueData(nil)
		self.__roleData:loadTalent(nil)
		self.__roleData:loadMoney(nil)
		self.__roleData:loadPackage(nil)
		self.__roleData:loadExpedition(nil)
		-- self.__roleData:loadMapData(nil)
		self.__roleData:loadSoildier(nil)
		self.__roleData:loadBuild(self:getCSVByID(csvOfBuild))
		self.__roleData:loadMake(self:getCSVByID(csvOfProduce),self:getCSVByID(csvOfResourceInfo))
		self.__roleData:loadStore(self:getCSVByID(csvOfStore),self:getCSVByID(csvOfResourceInfo))
		self.__roleData:loadStorageInfo(nil)
		self.__roleData:loadBonusAttribute(nil)
		self.__roleData:loadLastTime(nil)
		self.__roleData:loadGuideStep(nil)
		self.__roleData:setMusic(0)
		self.__roleData:setSound(0)
		self.__roleData:setEffect(0)
		self.__roleData:loadDiamondStore(self:getCSVByID(csvOfShopGift), self:getCSVByID(csvOfShopItem))
		-- 成就初始化
		local tempAchievementData = CSVParser:getInstance():loadFileByName("data/achievement.csv")
		-- changeTableForKeyFromStringToNumber(tempAchievementData)
		local tempAchievement = {}
		for k,v in pairs(tempAchievementData) do

			tempAchievement[k] = 0
		end

		-- addColumnToMatrix(tempAchievementData, dataKeyFlag, 0)
		self.__roleData:loadAchievement(tempAchievement)
		self.__roleData:loadAchievementPoint(0)

		-- 天赋初始化
		self.__roleData:loadTalent({})


	end

	self.__dynamicData = DynamicData:create()
	self.__dynamicData:retain()
	local talentTemp = CSVParser:getInstance():loadFileByName("data/talent.csv")
	self:splitValueToArray(talentTemp, "preID")
	self:splitValueToArray(talentTemp, "increaseAttrs")
	self:splitValueToArray(talentTemp, "increaseTypes")
	self:splitValueToArray(talentTemp, "increaseNums")
	self.__dynamicData:loadLockedTallent(talentTemp)
	self.__dynamicData:resetUserData(self.__roleData:getRole())

	self.__produceCD = 20.0
	self.__curTime = 0
	self.__produceIndex = 1

	DataManager.__schduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(frameUpdate, 1.0, false)
	self:resetShowDiamondStoreRedPointer()

	-- self:registerEvent("diamondStoreBuySomethingSuccess", "", function (eventData)
	-- 	-- body
	-- 	self:diamondStoreBuySomethingSuccess(eventData)
	-- end)

	return true
end

function DataManager:diamondStoreBuySomethingSuccess(eventData)
	-- body
	local userData = eventData
	if (userData ~= nil) then
		local buyType = tonumber(userData)
		if ((buyType >= 5) and (buyType <= 10) or (buyType == 12)) then

			local giftCSV = DataManager:getInstance():getCSVByID(csvOfShopGift)
            local goodsDataFromCSV = DataManager:getInstance():getCSVByID(csvOfShopItem)

            local giftId = nil

            for k,v in pairs(giftCSV) do
            	if (tonumber(v[dataKeyPayType]) == buyType) then
            		giftId = k
            		break
            	end
            end
            
            local giftData = giftCSV[giftId]
            local giftItem = giftData[dataKeyItem]
            local buyedGoodItemTemp = DataManager:getInstance():getRoleData(roleMapBuyItems)
            if (buyedGoodItemTemp == nil) then
                buyedGoodItemTemp = {}
            end

            for i=1,#giftItem do
                local temp = giftItem[i]
                local goodItemId = temp[1]
                local goodItemNum = temp[2]

                local goodTemp = goodsDataFromCSV[goodItemId]

                if (goodTemp[dataKeyRepeat] == "0" and (goodTemp[dataKeyNextId] == nil or goodTemp[dataKeyNextId] == "")) then
                    buyedGoodItemTemp[#buyedGoodItemTemp + 1] = goodItemId
                end

                -- local needDiamondNum = tonumber(goodTemp[dataKeyPrice]) * goodItemNum
                -- local curDiamondNum = tonumber(DataManager:getInstance():getRoleData(roleDiamond))
                -- if (needDiamondNum > curDiamondNum) then
                --     ToastUtil:toastString("钻石不足")
                --     return 0
                -- else
                --     local goodItemResume = goodTemp[dataKeyResume]
                --     local goodItemResumeType = goodItemResume[1]
                --     local goodItemResumeValue = goodItemResume[2] * goodItemNum
                --     local goodItemAchievement = goodTemp[dataKeyAchievement]
                
                --     if (not DataManager:getInstance():buyGoodsInDiamondStore(goodItemResumeType, goodItemResumeValue, goodItemAchievement)) then
                --         return 0
                --     end
                --     -- ToastUtil:toastString("成功购买物品：" .. goodTemp[dataKeyName])
                --     DataManager:getInstance():addDiamond(-needDiamondNum)

                -- end

                local goodItemResume = goodTemp[dataKeyResume]
                local goodItemResumeType = goodItemResume[1]
                local goodItemResumeValue = goodItemResume[2] * goodItemNum
                local goodItemAchievement = goodTemp[dataKeyAchievement]

                if (not DataManager:getInstance():buyGoodsInDiamondStore(goodItemResumeType, goodItemResumeValue, goodItemAchievement)) then
                    return 0
                end

            end

            DataManager:getInstance():setRoleData(roleMapBuyItems, buyedGoodItemTemp, nil) 

            ToastUtil:toastString("购买成功")

        	print("diamondStoreBuySomethingSuccess6")
            local storeTableData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
            local recommendedData = storeTableData["1"]

            for k,v in pairs(recommendedData) do
            	if (v[1] == giftId) then
            		local showType = tonumber(giftData[dataKeyShowType])

            		if (showType == 1) then
            			local time = os.time()

            			local giftItemNextID = giftData[dataKeyNextId]
                        v[1] = giftItemNextID
                        if giftCSV[giftItemNextID] ~= nil then
                            if (tonumber(giftCSV[giftItemNextID][dataKeyTime]) > 0) then
                                v[2] = time + tonumber(giftCSV[giftItemNextID][dataKeyTime]) * 3600
                                else
                                v[2] = tonumber(giftCSV[giftItemNextID][dataKeyTime])
                            end
                        else
                            v[2] = 0
                        end
                        v[3] = 0
            		elseif (showType == 2) then
            			v[3] = 0
            		end
            		
            		break
            	end
            end

            storeTableData["1"] = recommendedData

            self:setRoleData(roleDiamondStoreData, storeTableData)
            self:checkAndstepNextGift()

            self:postEvent("DiamondStoreUIReload", eventData)
        else
        	if (buyType == 1) then
		        ToastUtil:downString("支付成功")
		        DataManager:getInstance():addDiamond(120)
    		end
		    if (buyType == 2) then
		        ToastUtil:downString("支付成功")
		        DataManager:getInstance():addDiamond(398)
		    end
		    if (buyType == 3) then
		        ToastUtil:downString("支付成功")
		        DataManager:getInstance():addDiamond(888)
		    end
		    if (buyType == 11) then
		        ToastUtil:downString("支付成功，金币+100")
		        DataManager:getInstance():addCoin(100)

		        GuideController:getInstance():addStep(811)
		    end
		end
	end
end

function DataManager:checkAndstepNextGift()
	print("刷新礼包数据")
    local storeTableData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
    local recommendedData = storeTableData["1"]
    local goodsData = storeTableData["2"]
    local giftCSV = DataManager:getInstance():getCSVByID(csvOfShopGift)
    
    local function check()
        local keyIds = {"19", "5", "4"}
        for kk, vv in pairs(goodsData) do
            if vv[1] == keyIds[1] or vv[1] == keyIds[2] or vv[1] == keyIds[3] then
                if vv[2] == 1 then
                    local giftId = vv[1] == keyIds[1] and "1" or "3"
                    local giftData = giftCSV[giftId]
                
                    for k, v in pairs(recommendedData) do
                        if (v[1] == giftId) then
                            local showType = tonumber(giftData[dataKeyShowType])
                        
                            if (showType == 1) then
                                local time = os.time()
                            
                                local giftItemNextID = giftData[dataKeyNextId]
                                v[1] = giftItemNextID
                                if giftCSV[giftItemNextID] ~= nil then
                                    if (tonumber(giftCSV[giftItemNextID][dataKeyTime]) > 0) then
                                        v[2] = time + tonumber(giftCSV[giftItemNextID][dataKeyTime]) * 3600
                                    else
                                        v[2] = tonumber(giftCSV[giftItemNextID][dataKeyTime])
                                    end
                                else
                                    v[2] = 0
                                end
                                v[3] = 0
                                if giftItemNextID == "1" or giftItemNextID == "3" then
                                    check()
                                end
                            elseif (showType == 2) then
                                v[3] = 0
                            end
                        end
                    end
                end
            end
        end
    end
    
    check()
    
    storeTableData["1"] = recommendedData
    -- self.recommendedData = storeTableData["1"]
    DataManager:getInstance():setRoleData(roleDiamondStoreData, storeTableData, nil)
end

-- 清理函数
function DataManager:destory()
    cc.Director:getInstance():getScheduler():unscheduleScriptEntry(DataManager.__schduler)
end

function DataManager:isShowDiamondStoreRedPointer()
	-- body
	local mapLevel = 0
    local mapInfo = self:getRoleData(roleMapInfo)

	if (mapInfo == nil) then
        mapLevel = 1
    else
        if (mapInfo.mapIndex == nil) then
            mapLevel = 1
        else
            mapLevel = mapInfo.mapIndex
        end
    end

    local diamondStoreRedPointerData = self:getRoleData(roleDiamondStroeRedPointer)
	return (diamondStoreRedPointerData[1] and (mapLevel > diamondStoreRedPointerData[2]))
end

function DataManager:setShowDiamondStoreRedPointer(var)
	-- body
	local diamondStoreRedPointerData = self:getRoleData(roleDiamondStroeRedPointer)
	diamondStoreRedPointerData[1] = var
	self:setRoleData(roleDiamondStroeRedPointer, diamondStoreRedPointerData)
end

function DataManager:resetShowDiamondStoreRedPointer()
	-- body
	local mapLevel = 0
    local mapInfo = self:getRoleData(roleMapInfo)

	if (mapInfo == nil) then
        mapLevel = 1
    else
        if (mapInfo.mapIndex == nil) then
            mapLevel = 1
        else
            mapLevel = mapInfo.mapIndex
        end
    end

	local diamondStoreRedPointerData = self:getRoleData(roleDiamondStroeRedPointer)
	if (diamondStoreRedPointerData == nil) then
		diamondStoreRedPointerData = {}
		diamondStoreRedPointerData[1] = false
		diamondStoreRedPointerData[2] = mapLevel
	end

	diamondStoreRedPointerData[2] = mapLevel

	self:setRoleData(roleDiamondStroeRedPointer, diamondStoreRedPointerData, nil)
end

-- 钻石商店
function DataManager:checkDiamondStoreNewGoods()
	-- body
	local mapLevel = 0
    local mapInfo = self:getRoleData(roleMapInfo)
    
    if (mapInfo == nil) then
        mapLevel = 1
    else
        if (mapInfo.mapIndex == nil) then
            mapLevel = 1
        else
            mapLevel = mapInfo.mapIndex
        end
    end

    local goodsDataTemp = self:getCSVByID(csvOfShopItem)

    -- 钻石商店数据
    local storeTableData = self:getRoleData(roleDiamondStoreData)
    -- 钻石商店上方推荐物品信息
    -- local limitRecommended = storeTableData[self.LimitRecommendedKey]
    -- 钻石商店下方物品信息
    -- local goodsInfo = storeTableData[self.GoodsInfoKey]
    local goodsInfo = {}
    local tmp = storeTableData["2"]
    local tmpNum = getTableRowNum(tmp)

    local state = false
    for i=1,tmpNum do
        local flag = tmp[i][2]
        local goodItemID = tmp[i][1]
        if (flag == 2) then
            local tempValue = goodsDataTemp[goodItemID]

            if (tonumber(tempValue[dataKeyDisplay]) == 1) then

                if (tonumber(mapLevel) >= tonumber(tempValue[dataKeyUnlock])) then
                    if (not state) then
                    	state = true
                    	break
                    end
                end
            end
        end
    end

    if (state) then
    	if (not self:isShowDiamondStoreRedPointer()) then
        	self:setShowDiamondStoreRedPointer(true)
    	end
    end
    return (state and self:isShowDiamondStoreRedPointer())
end

function frameUpdate(delta)
	-- body
	-- -- print("============= frameUpdate", delta, DataManager.__timer, DataManager.__counter)
	-- DataManager.__timer = DataManager.__timer + delta
	-- --DataManager:getInstance():checkAutoLearnedTallent()

	-- if (DataManager.__counter > 10) then
	-- 	DataManager:getInstance().__roleData:saveData()
	-- 	DataManager.__counter = 0
	-- end
	-- DataManager.__counter = DataManager.__counter + 1
end

function DataManager:getData(tableData, key1, key2)
	local temp = tableData[key1]
	if temp then
		return temp[key2]
	else
	 	return nil
	end
end

function DataManager:getRowData(tableData, key)
	if tableData then
		return tableData[key]
	end
	return nil
end


function DataManager:registerEvent(dataID, str, listener)
	-- body
	if (self.__eventListener[dataID] == nil) then
		self.__eventListener[dataID] = {}
	end
	if (self.__eventListener[dataID][str] == nil) then
		self.__eventListener[dataID][str] = listener
	end
	local handler = cc.EventListenerCustom:create(dataID .. str .. "", listener)

	-- self.__eventListener[dataID][str..1] = handler

	self.__eventListener[dataID][dataID .. str .. ""] = handler

	self.__eventDispatcher:addEventListenerWithFixedPriority(handler, 1)
end

function DataManager:unregisterEvent(dataID, str)
	-- body
	-- print("unregisterEvent")
	if (self.__eventListener[dataID] == nil) then
		self.__eventListener[dataID] = {}
		return
	else
		local listener = self.__eventListener[dataID][dataID .. str .. ""]

		self.__eventListener[dataID][dataID .. str .. ""] = nil
		
		if listener ~= nil then
			self.__eventDispatcher:removeEventListener(listener)
		end
	end
end

function DataManager:postEvent(dataID, eventData)
	-- body
	if (self.__eventListener[dataID] == nil) then
		return
	else
		local listeners = self.__eventListener[dataID]
		for k,v in pairs(listeners) do
  			local event = cc.EventCustom:new(k)
  			event._usedata = eventData
        	self.__eventDispatcher:dispatchEvent(event)
		end
	end
end

function DataManager:getCSVByID(csvID)
	-- body
	return self.__staticData:getCSVByID(csvID)
end

--音乐
function DataManager:getMusic_off()
	-- body
	return self.__roleData:getMusic()
end

function DataManager:setMusic_off(Music_off)
	-- body
	self.__roleData:setMusic(Music_off)
	self.__roleData:saveData()
end

--音效
function DataManager:getSound_off()
	-- body
	return self.__roleData:getSound()
end

function DataManager:setSound_off(Sound_off)
	-- body
	self.__roleData:setSound(Sound_off)
	self.__roleData:saveData()
end

--特效
function DataManager:getEffect_off()
	-- body
	return self.__roleData:getEffect()
end

function DataManager:setEffect_off(Effect_off)
	-- body
	self.__roleData:setEffect(Effect_off)
	self.__roleData:saveData()
end




function DataManager:loadMapDataByID(mapIndex)--sd
	-- body
	return self.__roleData:loadMap(mapIndex)
end


-- function DataManager:getMap()
-- 	-- body
-- 	return self.__mapData:getMap()
-- end

-- function DataManager:setMap(mapInfo)
-- 	-- body
-- 	self.__mapData:setMap(mapInfo)
-- end

-- function DataManager:getMapData(mapDataID)
-- 	-- body
-- 	return self.__mapData:getMapData(mapDataID)
-- end

-- function DataManager:setMapData(mapDataID, mapData, eventData)
-- 	-- body
-- 	self.__mapData:setMapData(mapDataID, mapData)

-- 	self:postEvent(mapDataID, eventData)


-- 	local autoLearnedTallent = self:checkAutoLearnedTallent()
-- 	if ((autoLearnedTallent ~= nil) and (getTableRowNum(autoLearnedTallent) > 0)) then
-- 		for k,v in pairs(autoLearnedTallent) do
-- 			if (v ~= nil) then
-- 				self:unlockTallentByKey(k)
-- 				local str = "已解锁：" .. v[dataKeyName]
-- 				ToastUtil:toastString(str)
-- 			end
-- 		end
-- 	end

-- 	self.__mapData:saveData()
-- end



function DataManager:buyGoodsInDiamondStore(goodType, goodValue, appendData)
	-- body
	if (goodType == "1") then
    	--  解锁传送门
    	self:setRoleData(roleTranslateDoor, tonumber(goodValue))
    	if ((appendData ~= nil) and (appendData ~= "0")) then
    		self:unlockAchievementByID(appendData)
    	end
    elseif (goodType == "2") then
    	--  材料收获CD
    	self:setRoleData(roleResourceCD, tonumber(goodValue))
    elseif (goodType == "3") then
    	--  解锁天赋
    	self:unlockTallentByKey(goodValue)
    elseif (goodType == "4") then
    	--  离线奖励时间 
    	self:setRoleData(roleOfflineBonusTime, tonumber(goodValue))
    elseif (goodType == "5") then
    	--  获得物品
    	self:addPackItemWithId(goodValue, 1)
    elseif (goodType == "6") then
    	--  获得水手
    	self:addSoilderWithId(goodValue, 1)
    elseif (goodType == "7") then
    	--  金币
    	self:addCoin(tonumber(goodValue), false, true)
    elseif (goodType == "8") then
    	--  钻石
    	self:addDiamond(tonumber(goodValue))
	end
	return true
end

function DataManager:cdkExchangeGoods(goodType, goodId, goodValue)
	-- body
	goodType = tostring(goodType)
	goodId = tostring(goodId)
	goodValue = tonumber(goodValue)

	if (goodType == "1") then
		--  金币
    	self:addCoin(tonumber(goodValue), false, true)
    elseif (goodType == "2") then
    	--  钻石
    	self:addDiamond(tonumber(goodValue))
    elseif (goodType == "3") then
    	--  获得物品
    	self:addPackItemWithId(goodId, goodValue)
    elseif (goodType == "4") then
    	--  解锁天赋
    	self:unlockTallentByKey(goodId)
    elseif (goodType == "5") then
    	--  获得水手
    	self:addSoilderWithId(goodId, goodValue)
    	local soilderCSV = self:getCSVByID(csvOfSoilderAttribute)
    	local soilderData = soilderCSV[goodId]
    	if (soilderData ~= nil) then
    		local soilderName = soilderData[dataKeyName]
    		ToastUtil:downString("招募" .. soilderName .. "+" .. goodValue)
    	end
    elseif (goodType == "6") then
    	--  材料收获CD
    	self:setRoleData(roleResourceCD, tonumber(goodValue))
	end
	return true
end

function DataManager:getRole()
	-- body
	return self.__roleData:getRole()
end

function DataManager:setRole(roleInfo)
	-- body
	self.__roleData:setRole(roleInfo)
end

function DataManager:getRoleData(roleDataID)
	-- body
	return self.__roleData:getRoleData(roleDataID)
end

function DataManager:setRoleData(roleDataID, roleData, eventData)
	-- body
	-- print("setRoleData",roleDataID,roleData)

	-- if type(roleData) == "table" then
	-- 	for k,v in pairs(roleData) do
	-- 		print(k,v)
	-- 	endE
	-- end
	-- 
	-- self:checkSaveDataDuplicate()
	self.__roleData:setRoleData(roleDataID, roleData)
	-- if (roleDataID == modelDataName) then
	-- 	self:postEvent(modelDataName, eventData)
	-- else
		self:postEvent(roleDataID, eventData)
	-- end
	local autoLearnedTallent = self:checkAutoLearnedTallent()
	if ((autoLearnedTallent ~= nil) and (getTableRowNum(autoLearnedTallent) > 0)) then
		for k,v in pairs(autoLearnedTallent) do
			if (v ~= nil) then
				self:unlockTallentByKey(k)
				-- local str = "已解锁：" .. v[dataKeyName]
				-- ToastUtil:toastString(str)
			end
		end
	end
	-- self:setSaveDataDuplicate()
    -- local roleIDNum = tonumber(roleDataID)
    -- if roleIDNum > 63 and roleIDNum < 67 then
    --     -- 任务的存档单独拎出来
    --     self.__roleData:saveMission()
    -- else
        -- 其他的存档单独拎出来
        self.__roleData:saveData()
    -- end
end

function DataManager:checkSaveDataDuplicate()
	-- body
	if saveDataDuplicate ~= nil and saveDataDuplicate ~= {} then
		self.__roleData:setRoleData(roleDataID, saveDataDuplicate)
	end
end

function DataManager:setSaveDataDuplicate()
	-- body
	saveDataDuplicate = clone(self.__roleData:getRoleData(roleDataID))
end

function DataManager:setMapData(mapIndex,roleDataID, roleData, eventData)--sd
	-- body
	print("setMapData1"..os.clock()) 
	self.__roleData:setRoleData(roleDataID, roleData)
	print("setMapData2"..os.clock()) 
	-- if (roleDataID == modelDataName) then
	-- 	self:postEvent(modelDataName, eventData)
	-- else
		self:postEvent(roleDataID, eventData)
		print("setMapData3"..os.clock()) 
	-- end

	-- local autoLearnedTallent = self:checkAutoLearnedTallent()
	-- if ((autoLearnedTallent ~= nil) and (getTableRowNum(autoLearnedTallent) > 0)) then
	-- 	for k,v in pairs(autoLearnedTallent) do
	-- 		if (v ~= nil) then
	-- 			self:unlockTallentByKey(k)
	-- 			local str = "已解锁：" .. v[dataKeyName]
	-- 			ToastUtil:toastString(str)
	-- 		end
	-- 	end
	-- end

	self.__roleData:saveMap(mapIndex)
	print("setMapData4"..os.clock()) 
end


function DataManager:getAchievementInfo(achievementType)
	-- body
	local roledata = self:getRoleData(roleStorageInfo)
	if roledata ~= nil and roledata[achievementType] ~= nil then
		return roledata[achievementType]
	end
	return roledata[achievementType]
end

function DataManager:setAchievementInfo(achievementType, achievementValue)
	-- body
	local roledata = self:getRoleData(roleStorageInfo)
	roledata[achievementType] = achievementValue
	-- print("setAchievementInfo0",achievementValue)
	self:setRoleData(roleStorageInfo, roledata, nil)
	-- printn("setAchievementInfo",roledata)
	self:unlockAchievement(achievementType, achievementValue)
end

function DataManager:unlockAchievementByID(achievementID)
	-- body
	local achievementCSV = self:getCSVByID(csvOfAchievement)
	local achievementData = achievementCSV[achievementID]
	local achievementType = tonumber(achievementData[dataKeyType])

	local achievementValue = 1

	local roledata = self:getRoleData(roleStorageInfo)
	roledata[achievementType] = achievementValue
	self:setRoleData(roleStorageInfo, roledata, nil)
	self:unlockAchievement(achievementType, achievementValue)

end

function DataManager:addAchievementPoint(achievementPoint)
	-- body
	local roledata = self:getRoleData(roleAchievementPoint)
	self:setRoleData(roleAchievementPoint, (roledata + achievementPoint), nil)
end

function DataManager:produceUpdate(delta)
	-- body

end

function DataManager:getCurDiamondStoreGoods()
	-- body
	local diamondStoreData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
	local recommendedData = diamondStoreData["1"]
	if (#recommendedData > 0) then
		return recommendedData[1][1], recommendedData[1][3]
	else
		return nil, nil
	end
end

function DataManager:setCurDiamondStoreGoods(goodsId)
	-- body
	local diamondStoreData = DataManager:getInstance():getRoleData(roleDiamondStoreData)
	local recommendedData = diamondStoreData["1"]
	
	if (recommendedData ~= nil) then
		for i=1,#recommendedData do
			if (recommendedData[i][1] == goodsId) then
				recommendedData[i][3] = 1
			end
		end
		DataManager:getInstance():setRoleData(roleDiamondStoreData, diamondStoreData)
	end
end

function DataManager:addProducer(producer)
	-- body
	addObjectToTableI(self:getRoleData(roleProductionQueue), producer)
end

function DataManager:addProducerAtIndex(producer, index)
	-- body
	addObjetToTableAtIndexI(self:getRoleData(roleProductionQueue), producer, index)
end

function DataManager:removeProducerAtIndex(index)
	-- body
	removeObjectFromTableI(self:getRoleData(roleProductionQueue), index)
end

function DataManager:findProducerAtIndex(index)
	-- body
	findObjectFromTableByIndexI(self:getRoleData(roleProductionQueue), index)
end

function DataManager:changeProducerAtIndex(obj, index)
	-- body
	changeObjectFromTableByIndexI(self:getRoleData(roleProductionQueue), obj, index)
end

function DataManager:checkAutoLearnedTallent()
	-- body
	-- 非自动学习天赋
	local passed = getRowDataFromMatrixBySpecifiedKeyAndValue(self.__dynamicData:getLockedTallent(), dataKeyAutoType, {[1]="1"})

	-- 成就点判断
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyAchievement, self:getRoleData(roleAchievementPoint))
	else
		return nil
	end

	-- 判断金币信息
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyResumeCoin, self:getRoleData(roleMoney))
	else
		return nil
	end

	-- 地图层数
	local mapLevel = 0
 	local mapInfo = self:getRoleData(roleMapInfo)
 	
 	if (mapInfo == nil) then
 		mapLevel = 1
 	else
 		if (mapInfo.mapIndex == nil) then
 			mapLevel = 1
 		else
 			mapLevel = mapInfo.mapIndex
 		end
 	end

 	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyTrigger, mapLevel)
	else
		return nil
	end

	-- 判断钻石信息
	local diamondPassed = getRowDataFromMatrixBySpecifiedKeyAndValue(passed, dataKeyResumeType, {[1]="1"})
	if ((diamondPassed ~= nil) and (getTableRowNum(diamondPassed) > 0)) then
		local diamond = self:getRoleData(roleDiamond)
		-- local tempPassed = {}
		for k,v in pairs(diamondPassed) do
			local temp = v[dataKeyResumeNum]
			if (nil ~= temp) then
				if (diamond < getNumber(temp)) then
					removeObjectFromTableByKey(passed, k)
				end
			end
		end

		-- if (getTableRowNum(tempPassed) > 0) then
		-- 	passed = tempPassed
		-- else
		-- 	return nil
		-- end
	end

	-- 判断上一个天赋
    if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
        local fatherTalent = getPassedRowDataFromMatrixByKeyAndValueTMore(passed, dataKeyFatherID, 1)

        if ((fatherTalent ~= nil) and (getTableRowNum(fatherTalent) > 0)) then
            local learnedTalent = self:getRoleData(roleTalent)
            for k,v in pairs(fatherTalent) do
                local canPassFatherTalent = false
                local needFatherId = v[dataKeyFatherID]

                for k1,v1 in pairs(learnedTalent) do
                    if (v1 == needFatherId) then
                        canPassFatherTalent = true
                    end
                end

                if (not canPassFatherTalent) then
                    removeObjectFromTableByKey(passed, k)
                end
            end
        end

    else
        return nil
    end

	-- 判断所需物品信息
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		local needGoods = getRowDataFromMatrixBySpecifiedKeyAndValue(passed, dataKeyPreFlag, {[1]="1"})

		if ((needGoods ~= nil) and (getTableRowNum(needGoods) > 0)) then
			for k,v in pairs(needGoods) do
				local goods = v[dataKeyPreID]
				for i=1,#goods do
					local isHaveGood = true
					-- 物品id
					local itemNum = self:getPackNumWithId(goods[i])
					if (itemNum <= 0) then
						isHaveGood = false
					end
				end
				if (not isHaveGood) then
					removeObjectFromTableByKey(passed, k)
				end
			end
		end
	else
		return nil
	end

	-- 计算几率(触发天赋学习的几率)
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		for k,v in pairs(passed) do
			 local needProbability = getNumber(v[dataKeyProbability])
			 local probability = math.random(0, 100)
			 if (probability > needProbability) then
			 	removeObjectFromTableByKey(passed, k)
			 end
		end
		passed[{}] = nil

	else
		return nil
	end
	
	return passed
end

-- isShowBox: boolean 金币不足时是否弹出购买金币的弹框
function DataManager:addCoin( _Coinnum, isShowBox, showPopString )
	-- 不加钱执行什么，傻逼吧
	if _Coinnum == 0 then
		return
	end
	-- body
	local    dealsuccess = 0
	local 	 defiCoin = 0		--缺少金币
	local function dealcoinless()
    end
	local money = self:getRoleData(roleMoney)
	if _Coinnum < 0 and money + _Coinnum < 0 then
		dealsuccess = 0
		defiCoin = math.abs(money + _Coinnum)
		-- local _alert = AlertView:create(2,0, "",dealcoinless)
		-- local showLabel1 = cc.LabelTTF:create("金币不足!", BoldFont, 36.0)
  --       showLabel1:setColor(cc.c3b(255, 255, 255))
  --       showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
  --       showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.0))
  --       _alert:addChild(showLabel1)
	else
		money = money + _Coinnum
		self:setRoleData(roleMoney, money, nil)
		dealsuccess = 1
		-- if _Coinnum < 0 then
		-- 	ToastUtil:toastString("金币-".._Coinnum)
		-- else
		-- 	ToastUtil:toastString("金币+".._Coinnum)
		-- end
	end
    
    -- 弹出购买金币的弹框
    if dealsuccess == 0 and isShowBox then

    	-- --某些情况下会找不到方法，所以加个容错处理
    	-- if showBuyGoldBox == nil then
    	-- 	print("Not found showBuyGoldBox!")
    	-- 	require "LuaClass/MainMenu"
    	-- end

        self:showBuyGoldBox()
    end

    if (showPopString ~= nil) then
    	if (showPopString and _Coinnum > 0) then
    		ToastUtil:downString("金币+" .. _Coinnum)
    	end
    end
    
	return dealsuccess , defiCoin
end

function DataManager:addDiamond(_Diamondnum, bIsShowAlert)
	if bIsShowAlert == nil then
		bIsShowAlert = true
	end
	-- body
	print("增加钻石", _Diamondnum)
	local dealsuccess = 0

	local function dealDiamondless()
		if not bIsShowAlert then
			return
		end
		local _newalert = AlertView:create(2, 0, "购买失败", function()
			-- require "LuaClass/ChargeMode"
			-- local charge = ChargeMiniLayer:create()
			-- charge:setCancelCallback(function()
	  --           charge:destory()
	  --       end)
            if isEnterMap then
			    PushGiftView:create():show(999)
            else
                PushGiftView:create():show()
            end
		end, nil)

	    local showLabel1 = cc.LabelTTF:create("钻石不足!", BoldFont, 36.0)
	    showLabel1:setColor(WriteColor)
	    -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
	    showLabel1:setPosition(cc.p(_newalert.s_position.x, _newalert.s_position.y + showLabel1:getContentSize().height * 1.0))
	    _newalert:addChild(showLabel1)

	    local showLabel2 = cc.LabelTTF:create("你可以通过充值获得更多钻石。", BoldFont, 36.0)
	    showLabel2:setColor(WriteColor)
	    -- showLabel2:enableStroke(cc.c4b(16, 16, 16, 255), 2)
	    showLabel2:setPosition(cc.p(_newalert.s_position.x, _newalert.s_position.y - showLabel1:getContentSize().height * 0.2))
	    _newalert:addChild(showLabel2)
    end

	local money = self:getRoleData(roleDiamond)
	if _Diamondnum < 0 and money + _Diamondnum < 0 then
		dealsuccess = 0
		dealDiamondless()
	else
		money = money + _Diamondnum
		self:setRoleData(roleDiamond, money, nil)
		dealsuccess = 1
    end
    if (_Diamondnum > 0) then
        ToastUtil:downString("钻石+" .. _Diamondnum)
    end
	return dealsuccess
end

-- 天赋解锁
function DataManager:unlockTallentByKey(key, costType)
	-- body
	key = tostring(key)
	local num = getTableRowNum(self:getRoleData(roleTalent))
	local locked = self.__dynamicData:getLockedTallent()
	local value = locked[key]
	local csvData = self:getCSVByID(csvOfTalent)

	if (value ~= nil) then
		local talent = self:getRoleData(roleTalent)
		talent[tostring(num + 1)] = value[dataKeyID]
		-- self:getRoleData(roleTalent)[tostring(num + 1)] = value
		removeObjectFromTableByKey(self.__dynamicData:getLockedTallent(), key)

		if costType == nil then
            -- 消耗物品
            local coin = tonumber(value[dataKeyResumeCoin])
            if (coin > 0) then
                self:addCoin(-coin)
            end

            local resumeType = tonumber(value[dataKeyResumeType])
            if (resumeType == 1) then
                local diamond = tonumber(value[dataKeyResumeNum])
                self:addDiamond(-diamond)
            end
        else
            local resumeType = tonumber(value[dataKeyResumeType])
            if (resumeType == 2) then
                if costType == 1 then
                    local coin = tonumber(value[dataKeyResumeCoin])
                    if (coin > 0) then
                        self:addCoin(-coin)
                    end
                elseif costType == 2 then
                    local diamond = tonumber(value[dataKeyResumeNum])
                    if diamond > 0 then
                        self:addDiamond(-diamond)
                    end
                end
            end
        end

		local preFlag = tonumber(value[dataKeyPreFlag])
		if (preFlag == 1) then
			local goods = value[dataKeyPreID]
			for k,v in pairs(goods) do
				self:addPackItemWithId(goods[i], -1)
			end
		end

		-- 处理属性加成
		self:handleTallentItemAddition(value)
		self:setRoleData(roleTalent, talent, nil)

		local str = "已解锁天赋：" .. value[dataKeyName]
		ToastUtil:downString(str)

		-- 解锁成就
		self:unlockAchievement(achievement_Skill, key)

		-- 增加天赋的红点
		GuideController:getInstance():removeStep(401, true)
	end
end

function DataManager:getLockedTallent()
	return self.__dynamicData:getLockedTallent()
end

function DataManager:checkUnAutoLearnedTallent()
	-- body
	-- 非自动学习天赋
	local passed = getRowDataFromMatrixBySpecifiedKeyAndValue(self.__dynamicData:getLockedTallent(), dataKeyAutoType, {[1]="0"})

	-- 成就点判断
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyAchievement, self:getRoleData(roleAchievementPoint))
	else
		return nil
	end

	-- -- 判断金币信息
	-- if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
	-- 	passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyResumeCoin, self:getRoleData(roleMoney))
	-- else
	-- 	return nil
	-- end

	-- 地图层数
	local mapLevel = 0
 	local mapInfo = self:getRoleData(roleMapInfo)
 	
 	if (mapInfo == nil) then
 		mapLevel = 1
 	else
 		if (mapInfo.mapIndex == nil) then
 			mapLevel = 1
 		else
 			mapLevel = mapInfo.mapIndex
 		end
 	end
 	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		passed = getPassedRowDataFromMatrixByKeyAndValue(passed, dataKeyTrigger, mapLevel)
	else
		return nil
	end

	-- 判断钻石信息
--	local diamondPassed = getRowDataFromMatrixBySpecifiedKeyAndValue(passed, dataKeyResumeType, {[1]="0"})
--	if ((diamondPassed ~= nil) and (getTableRowNum(diamondPassed) > 0)) then
--		local diamond = self:getRoleData(roleDiamond)
--		local tempPassed = {}
--		for k,v in pairs(diamondPassed) do
--			local temp = v[dataKeyResumeNum]
--			if (nil ~= temp) then
--				if (diamond >= getNumber(temp)) then
--					tempPassed[k] = v
--				end
--			end
--		end
--
--		if (getTableRowNum(tempPassed) > 0) then
--			passed = tempPassed
--		else
--			return nil
--		end
--    end
    passed = getRowDataFromMatrixBySpecifiedKeyAndValue(passed, dataKeyResumeType, {[1]="2"})

    --print("passed -- "..json.encode(passed))

	-- 判断上一个天赋
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		local fatherTalent = getPassedRowDataFromMatrixByKeyAndValueTMore(passed, dataKeyFatherID, 1)

		if ((fatherTalent ~= nil) and (getTableRowNum(fatherTalent) > 0)) then
			local learnedTalent = self:getRoleData(roleTalent)
			for k,v in pairs(fatherTalent) do
				local canPassFatherTalent = false
                local needFatherId = v[dataKeyFatherID]

				for k1,v1 in pairs(learnedTalent) do
					if (v1 == needFatherId) then
						canPassFatherTalent = true
					end
				end

				if (not canPassFatherTalent) then
					removeObjectFromTableByKey(passed, k)
				end
			end
		end
		
	else
		return nil
    end

	-- -- 判断所需物品信息
	-- if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
	-- 	local needGoods = getRowDataFromMatrixBySpecifiedKeyAndValue(passed, dataKeyPreFlag, {[1]="1"})

	-- 	if ((needGoods ~= nil) and (getTableRowNum(needGoods) > 0)) then
	-- 		for k,v in pairs(needGoods) do
	-- 			local goods = v[dataKeyPreID]
	-- 			for i=1,#goods do
	-- 				local isHaveGood = true
	-- 				-- 物品id
	-- 				local itemNum = self:getPackNumWithId(goods[i])
	-- 				if (itemNum <= 0) then
	-- 					isHaveGood = false
	-- 				end
	-- 			end
	-- 			if (not isHaveGood) then
	-- 				removeObjectFromTableByKey(passed, k)
	-- 			end
	-- 		end
	-- 	end
	-- else
	-- 	return nil
	-- end

	-- 计算几率(触发天赋学习的几率)
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		for k,v in pairs(passed) do
			 local needProbability = getNumber(v[dataKeyProbability])
			 local probability = math.random(0, 100)
			 if (probability > needProbability) then
			 	removeObjectFromTableByKey(passed, k)
			 end
		end
		passed[{}] = nil

	else
		return nil
	end
	return passed
end

function DataManager:getUnAutoLearnedTallent()
	-- body
	local passed = self:checkUnAutoLearnedTallent()
	if ((passed ~= nil) and (getTableRowNum(passed) > 0)) then
		for k,v in pairs(passed) do
			return v
		end
	end
	return nil
end

function DataManager:checkTallentPass(tallent, costType)
	-- body
	local flag = true
	if (tallent ~= nil) then
		local tallentId = tallent[dataKeyID]
		local tallents = self:getCSVByID(csvOfTalent)
		local tallentFromCSV = tallents[tallentId]

        if costType == nil then --  一般学习，之前金币钻石都需要
            -- 金币判断
            local needCoin = tonumber(tallentFromCSV[dataKeyResumeCoin])
            if (needCoin > tonumber(self:getRoleData(roleMoney))) then
                flag = false
                self:addCoin(-needCoin, true)
                self:sendSystemInfo("金币不足，无法学习")
                ToastUtil:toastString("金币不足，无法学习")
            end

            -- 钻石判断
            local currencyType = tallentFromCSV[dataKeyResumeType]
            if (currencyType == "1" and flag) then
                local needDiamod = tonumber(tallentFromCSV[dataKeyResumeNum])
                if (needDiamod > tonumber(self:getRoleData(roleDiamond))) then
                    flag = false
                    self:addDiamond(-needDiamod)
                    self:sendSystemInfo("钻石不足，无法学习")
                    ToastUtil:toastString("钻石不足，无法学习")
                end
            end
        elseif costType == 1 then --用金币学习
            local currencyType = tallentFromCSV[dataKeyResumeType]
            if (currencyType == "2") then
                -- 金币判断
                local needCoin = tonumber(tallentFromCSV[dataKeyResumeCoin])
                if (needCoin > tonumber(self:getRoleData(roleMoney))) then
                    flag = false
                    self:addCoin(-needCoin, true)
                    self:sendSystemInfo("金币不足，无法学习")
                    ToastUtil:toastString("金币不足，无法学习")
                end
            else
                flag = false
            end
        elseif costType == 2 then --用钻石学习
            local currencyType = tallentFromCSV[dataKeyResumeType]
            if (currencyType == "2") then
                -- 钻石判断
                local needDiamod = tonumber(tallentFromCSV[dataKeyResumeNum])
                if (needDiamod > tonumber(self:getRoleData(roleDiamond))) then
                    flag = false
                    self:addDiamond(-needDiamod)
                    self:sendSystemInfo("钻石不足，无法学习")
                    ToastUtil:toastString("钻石不足，无法学习")
                end
            else
                flag = false
            end
        end
		
		-- 道具判断
		local needGoodsFlag = tallentFromCSV[dataKeyPreFlag]
		if (needGoodsFlag == "1" and flag) then
			local needGoods = tallentFromCSV[dataKeyPreID]
			for i=1,#needGoods do
				-- 物品id
				local itemNum = self:getPackNumWithId(needGoods[i])
				if (itemNum <= 0) then
					flag = false
				end
			end
			if (flag == false) then
				self:sendSystemInfo("缺少道具，无法学习")
                ToastUtil:toastString("缺少道具，无法学习")
			end
		end
	else
		flag = false
	end

	return flag
end

-- 天赋属性加成
function DataManager:handleTallentsAddition(tableData)
	-- body
	if ((tableData ~= nil) and (getTableRowNum(tableData) > 0)) then
		for k,v in pairs(tableData) do
		 	self:handleTallentItemAddition(v)
		end
	end
end

function DataManager:handleTallentItemAddition(tableData)
	-- body
	if ((tableData ~= nil) and (getTableRowNum(tableData) > 0)) then
		
		local increaseAttrs = tableData[dataKeyIncreaseAttrs]
		local increaseTypes = tableData[dataKeyIncreaseTypes]
		local increaseNums = tableData[dataKeyIncreaseNums]
		local skillType = tableData[dataKeyType]
		local bonusAttribute = self:getRoleData(roleBonusAttribute)
		
		for i=1,#increaseAttrs do
			bonusAttribute[tonumber(skillType)][increaseAttrs[i]][increaseTypes[i]] = increaseNums[i]
		end

		self:setRoleData(roleBonusAttribute, bonusAttribute, nil)
	end
end

-- 成就解锁
function DataManager:unlockAchievement(atype, value)
	-- body
	-- print("unlockAchievement",atype, value)
	value = getNumber(value)
	local flag = false
 	-- local unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(self:getRoleData(roleAchievement), dataKeyFlag, {[1]=0})

 	local unlocked = {}
 	local csvData = self:getCSVByID(csvOfAchievement)
 	local achievementData = self:getRoleData(roleAchievement)
 	for k,v in pairs(achievementData) do
 		if (v == 0) then
 			unlocked[k] = csvData[k]
 		end
 	end
 	-- print("unlockedId",#unlocked)
 	local unlockedId = {}
	if (atype == achievement_Alchemy) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Alchemy .. ""})
		-- printn("unlockAchievement1",unlocked)
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue] 
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Exploration) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Exploration .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Gamble) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Gamble .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Training) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Training .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value == getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Arena) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Arena .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Skill) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Skill .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value == getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_ConsumeBread) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_ConsumeBread .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_KillBoss) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=atype .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value == getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Collect) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Collect .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	-- elseif (atype == achievement_ShareToFriends) then
	-- 	unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_ShareToFriends .. ""})
	-- 	for k,v in pairs(unlocked) do
	-- 		 local num = v[dataKeyTotalValue]
	-- 		 unlockedId[#unlockedId + 1] = k
	-- 	end
	-- elseif (atype == achievement_ShareToWeibo) then
	-- 	unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_ShareToWeibo .. ""})
	-- 	for k,v in pairs(unlocked) do
	-- 		 local num = v[dataKeyTotalValue]
	-- 		 unlockedId[#unlockedId + 1] = k
	-- 	end
	elseif (atype == achievement_Ranking) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Ranking .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value > getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Plot) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Plot .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value > getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Progress) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=atype .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value > getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Progress1) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=atype .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value > getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Progress2) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=atype .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value > getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Star1) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Star1 .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Star2) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Star2 .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Star3) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Star3 .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Star4) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Star4 .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_Star5) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_Star5 .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end
	elseif (atype == achievement_KillMonster) then
		unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(unlocked, dataKeyType, {[1]=achievement_KillMonster .. ""})
		for k,v in pairs(unlocked) do
			 local num = v[dataKeyTotalValue]
			 if (value >= getNumber(num)) then
				unlockedId[#unlockedId + 1] = k
			 end
		end

	end

	if (#unlockedId > 0) then
		-- local achievementData = self:getRoleData(roleAchievement)
		for k,v in pairs(unlockedId) do
			achievementData[tostring(v)] = 1

			local str = "已解锁成就：" .. csvData[v][dataKeyName]
			ToastUtil:downString(str)

			-- 添加成就点
			self:addAchievementPoint(tonumber(csvData[v][dataKeyPoint]))
			self:setRoleData(roleAchievement,achievementData)
			-- 添加钻石
			local gainedDiamond = tonumber(csvData[v][dataKeyDiamond])
			if (gainedDiamond > 0) then
				self:addDiamond(gainedDiamond)
			end
		end
		flag = true
	end

	--	通知成就数据变更
	if (flag) then
		self:postEvent(roleAchievement, "achievementChanged")
		-- 增加成就的红点
		GuideController:getInstance():removeStep(402, true)
	end
end

--[[
升级解锁功能相关函数开始
]]
-- 解锁功能触发函数
function DataManager:unlockUnitWithType(unitType, id)
	if type(id) ~= "string" then
		cclog("传入的解锁id必须是string！！！")
		return false
	end
	-- 根据类型，处理相关解锁数据
	if unitType == kUnlockMake then
		-- 解锁制造
		local produceCsv = self:getCSVByID(csvOfProduce)
		local ResourceInfoCsv = self:getCSVByID(csvOfResourceInfo)
		if produceCsv ~= nil then
			local unlockData = produceCsv[id]
			if unlockData ~= nil then
				-- 取得制造的存档数据
				local makeData = self:getRoleData(roleMake)
				-- 如果是互斥的，那么记录清除逻辑
				local lastId = "-1"
				if unlockData["mutex"] == "1" then
					-- 取出它的前一个id
					lastId = unlockData["preID"]
				end
				
				local tempData = {}
				local bigId = 0
				local needDeleteIndex = -1

				for i = 1, #makeData do
					-- 判断是否已经解锁，解锁过了就不再处理了(这里必须要判断nil，因为有可能会删除一个)
					if makeData[i] ~= nil then
						if makeData[i][dataKeyID] == id then
							cclog("已经解锁过这个id了，请勿重复解锁~")
							return false
						end
						-- 如果上一层解锁数据存在，那么就不写入新结构（这里是用sortId存的produce表里的id，存档里的id是resourceInfo）
						if makeData[i]["sortId"] ~= lastId then
							-- 如果不满足解锁关联条件，那么将数据写入临时数组
							tempData[makeData[i]["sortId"]] = makeData[i]
							-- 取出最大的排序id
							if bigId < tonumber(makeData[i]["sortId"]) then
								bigId = tonumber(makeData[i]["sortId"])
							end
						end
					end
				end
				-- 插入数据到当前存档
				local _dataKeyNum = ResourceInfoCsv[unlockData["resourceInfoID"]]["limits"]
				--print("sdsdsdsdsd",_dataKeyNum)
				-- local insertData = {["sortId"] = unlockData[dataKeyID], [dataKeyID] = unlockData["resourceInfoID"], [dataKeyNum] = unlockData["limits"]}
				local insertData = {["sortId"] = unlockData[dataKeyID], [dataKeyID] = unlockData["resourceInfoID"], [dataKeyNum] = _dataKeyNum, ["S"] = 1}
				
				table.insert(makeData, insertData)
				tempData[unlockData[dataKeyID]] = insertData

				-- 一旦解锁新事物，马上让下边的那些个该死的按钮红灯亮起
				GuideController:getInstance():removeStep(2, true)

				if bigId < tonumber(unlockData[dataKeyID]) then
					bigId = tonumber(unlockData[dataKeyID])
				end
				-- 重新排序写入数据
				local finalData = {}
				for i = 1, bigId do
					if tempData[i..""] ~= nil then
						-- 这里插入的时候判断一下，如果是地图的史诗奖励，那么插到队头，否则插到队尾
						if i >= 100 and i <= 115 then
							table.insert(finalData, 1, clone(tempData[i..""]))
						else
							table.insert(finalData, clone(tempData[i..""]))
						end
					end
				end
				-- 存档
				self:setRoleData(roleMake, finalData, nil)
			else
				cclog("传入的解锁id不正确，在csv里没找到！请检查")
				return false
			end
		else
			cclog("制造csv表格读取失败！请检查")
			return false
		end
	elseif unitType == kUnlockBuild then
		-- 解锁建造
		local buildingCsv = self:getCSVByID(csvOfBuild)
		if buildingCsv ~= nil then
			-- 处理解锁逻辑开始
			local unlockData = buildingCsv[id]
			if unlockData ~= nil then
				-- 取得建造的存档数据
				local buildingData = self:getRoleData(roleBuilding)
				-- 如果是互斥的，那么记录清除逻辑
				local lastId = "-1"
				if unlockData["mutex"] == "1" then
					-- 取出它的前一个id
					lastId = unlockData["preID"]
				end
				
				local tempData = {}
				local bigId = 0
				for i = 1, #buildingData do
					-- 判断是否已经解锁，解锁过了就不再处理了
					if buildingData[i][dataKeyID] == id then
						cclog("已经解锁过这个id了，请勿重复解锁~")
						return false
					end
					-- 如果上一层解锁数据存在，那么就不写入新结构
					if buildingData[i][dataKeyID] ~= lastId then
						-- 如果不满足解锁关联条件，那么将数据写入临时数组
						tempData[buildingData[i][dataKeyID]] = buildingData[i]
						-- 取出最大的排序id
						if bigId < tonumber(buildingData[i][dataKeyID]) then
							bigId = tonumber(buildingData[i][dataKeyID])
						end
					end
				end
				-- 插入数据到当前存档
				-- print("unlockData", tableToJson(unlockData))
				local insertData = {[dataKeyID] = unlockData[dataKeyID], [dataKeyNum] = 0, ["S"] = 1}
				table.insert(buildingData, insertData)
				-- print("解锁的道具id", unlockData[dataKeyID])
				tempData[unlockData[dataKeyID]] = insertData

				-- 在信息框里显示新手引导解锁提示
				if unlockData["activeInfo"] ~= nil then
					for i = 1, #unlockData["activeInfo"] do
						self:sendSystemInfo(unlockData["activeInfo"][i][1])
					end
				end

				-- 一旦解锁新事物，马上让下边的那些个该死的按钮红灯亮起
				GuideController:getInstance():removeStep(1, true)

				if bigId < tonumber(unlockData[dataKeyID]) then
					bigId = tonumber(unlockData[dataKeyID])
				end
				-- 重新排序写入数据,要求没制造的生序排列，制造过的降序在下边排列
				local finalData = {}
				local midIndex = 1
				for i = 1, bigId do
					if tempData[i..""] ~= nil then
						-- print("判断到底是什么状态：", tempData[i..""][dataKeyNum])
						if tempData[i..""][dataKeyNum] == 0 then
							table.insert(finalData, midIndex, clone(tempData[i..""]))
							midIndex = midIndex + 1
						else
							table.insert(finalData, midIndex, clone(tempData[i..""]))
						end
						-- print("解锁排序顺序", i, midIndex)
					end
				end
				-- 存档
				self:setRoleData(roleBuilding, finalData, nil)
			else
				cclog("传入的解锁id不正确，在csv里没找到！请检查")
				return false
			end
		else
			cclog("建造csv表格读取失败！请检查")
			return false
		end
	elseif unitType == kUnlockResource then
		-- 解锁资源
		local workerCsv = self:getCSVByID(csvOfWorker)
		if workerCsv ~= nil then
			local unlockData = workerCsv[id]
			if unlockData ~= nil then
				-- 取得工人类型的存档数据
				local workerQueueData = self:getRoleData(roleProducerQueue)
				local tempData = {}
				local bigId = 0
				for i = 1, #workerQueueData do
					-- 判断是否已经解锁，解锁过了就不再处理了
					if workerQueueData[i][dataKeyID] == id then
						cclog("已经解锁过这个id了，请勿重复解锁~")
						return false
					end
					-- 如果不满足解锁关联条件，那么将数据写入临时数组
					tempData[workerQueueData[i][dataKeyID]] = workerQueueData[i]
					-- 取出最大的排序id
					if bigId < tonumber(workerQueueData[i][dataKeyID]) then
						bigId = tonumber(workerQueueData[i][dataKeyID])
					end
				end
				-- 插入数据到当前存档
				local insertData = {[dataKeyID] = unlockData[dataKeyID], [dataKeyNum] = "0"}
				table.insert(workerQueueData, insertData)
				tempData[unlockData[dataKeyID]] = insertData

				-- 一旦解锁新事物，马上让右侧的红灯亮起，显示手指向左滑动的动画
				GuideController:getInstance():removeStep(5, true)

				if bigId < tonumber(unlockData[dataKeyID]) then
					bigId = tonumber(unlockData[dataKeyID])
				end
				-- 重新排序写入数据
				local finalData = {}
				for i = 1, bigId do
					if tempData[i..""] ~= nil then
						-- cclog("写入数据："..i.." ----- "..bigId)
						table.insert(finalData, clone(tempData[i..""]))
					end
				end
				-- 存档
				self:setRoleData(roleProducerQueue, finalData, nil)
			else
				cclog("传入的解锁id不正确，在csv里没找到！请检查")
				return false
			end
		else
			cclog("工人种类csv表格读取失败！请检查")
			return false
		end
	elseif unitType == kUnlockStore then
		-- 解锁商店（没有关联解锁信息，暂无）
		local storeCsv = self:getCSVByID(csvOfStore)
		local ResourceInfoCsv = self:getCSVByID(csvOfResourceInfo)
		if storeCsv ~= nil then
			local unlockData = storeCsv[id]
			if unlockData ~= nil then
				-- 取得商城的存档数据
				local storeData = self:getRoleData(roleStore)

				local tempData = {}
				local bigId = 0
				for i = 1, #storeData do
					-- 判断是否已经解锁，解锁过了就不再处理了
					if storeData[i][dataKeyID] == id then
						cclog("已经解锁过这个id了，请勿重复解锁~")
						return false
					end
					-- 如果不满足解锁条件，那么将数据写入临时数组
					tempData[storeData[i]["sortId"]] = storeData[i]
					-- 取出最大的排序id
					if bigId < tonumber(storeData[i]["sortId"]) then
						bigId = tonumber(storeData[i]["sortId"])
					end
				end
				-- 插入数据到当前存档
				local _dataKeyNum = ResourceInfoCsv[unlockData["resourceInfoID"]]["limits"]
				local insertData = {[dataKeyID] = unlockData["resourceInfoID"], [dataKeyNum] = _dataKeyNum, ["sortId"] = unlockData[dataKeyID], ["S"] = 1}
				table.insert(storeData, insertData)
				tempData[unlockData[dataKeyID]] = insertData

				-- 一旦解锁新事物，马上让下边的那些个该死的按钮红灯亮起
				GuideController:getInstance():removeStep(4, true)

				if bigId < tonumber(unlockData[dataKeyID]) then
					bigId = tonumber(unlockData[dataKeyID])
				end
				-- 重新排序写入数据
				local finalData = {}
				for i = 1, bigId do
					if tempData[i..""] ~= nil then
						table.insert(finalData, clone(tempData[i..""]))
					end
				end
				-- 存档
				self:setRoleData(roleStore, finalData, nil)
			else
				cclog("传入的解锁id不正确，在csv里没找到！请检查")
				return false
			end
		else
			cclog("制造csv表格读取失败！请检查")
			return false
		end
	else
		cclog("*************解锁出错，请检查传入类型！！！*************")
		return false
	end
	cclog("解锁成功！")
	return true
end

-- 根据传入的csv解锁或升级指定模块元素
function DataManager:unlockUnitWithCsvData(data)
	if data ~= nil then
		local activityData = data["activateID"]
		
		if activityData ~= nil then
			local actType = nil
			local actId = nil
			local actNum = nil
			for i = 1, #activityData do
				if activityData[i] ~= nil and activityData[i] ~= "0" then
					actType = activityData[i][1]
					actId = activityData[i][2]
					actNum = activityData[i][3]
					-- print(actType, actId, actNum, activityId)
					if actType == "1" then
						-- 解锁制造
						if actId == "0" then
							-- 如果是建造进来的话，那么走等于0的逻辑，其他的不走
							if data["successDesc"] ~= nil then
								local activityId = data[dataKeyID]
								-- 如果接下去解锁的id为0，那么证明要把当前这条删除
								local makeData = self:getRoleData(roleMake)
								-- print("unlockUnitWithCsvData：准备开始删除指定的数据")
								for i = 1, #makeData do
									if makeData[i] ~= nil then
										-- print("数据里边的id", makeData[i][dataKeyID])
										if makeData[i]["sortId"] == activityId then
											cclog("解锁制造的时候，发现制造级联解锁类型是1，解锁id为0，那么删除当前这条数据，触发的id：", activityId)
											table.remove(makeData, i)
											break
										end
									end
								end
								self:setRoleData(roleMake, makeData)
							end
						else
							self:unlockUnitWithType(kUnlockMake, actId)
						end
						require "LuaClass/GuideController"
						-- 任意制造解锁之后
						GuideController:getInstance():addStep(10)
					elseif actType == "2" then
						-- 解锁建造
						self:unlockUnitWithType(kUnlockBuild, actId)
					elseif actType == "3" then
						-- 解锁商店物品
						self:unlockUnitWithType(kUnlockStore, actId)
					elseif actType == "4" then
						-- 解锁生产单位
						self:unlockUnitWithType(kUnlockResource, actId)
					elseif actType == "5" then
						-- 升级工匠数量,直接赋值，不要做其他操作
						self:setRoleData(roleLivingUnitNum, actId, nil)
					elseif actType == "6" then
						-- 礼包奖励,这个不需要解锁处理，属于直接操作类型
						if actNum ~= nil then
							self:addPackItemWithId(actId, tonumber(actNum))
						end
					else
						cclog("解锁类型找不到！！！无法解锁！")
						return false
					end
				else
					cclog("解锁数据为空或者找不到！！！无法解锁！"..i.." dataCount:"..#activityData)
					return false
				end
			end
		else
			cclog("没有找到可解锁数据但是操作成功了！")
			return true
		end
	else
		cclog("传入的解锁id在csv表里没找到！！！")
		return false
	end
end

-- 清理新解锁的数据
function DataManager:cleanNewUnlock(unitType)
	cclog("********type***********", unitType)
	-- 根据类型，处理相关解锁数据
	if unitType == kUnlockMake then
		-- 解锁制造
		local makeData = self:getRoleData(roleMake)
		for i = 1, #makeData do
			if makeData[i]["S"] ~= nil then
				makeData[i]["S"] = nil
			end
		end
		self:setRoleData(roleMake, makeData, nil)
	elseif unitType == kUnlockBuild then
		-- 解锁建造
		local buildingData = self:getRoleData(roleBuilding)
		local bIsNeedRedPoint = false
		for i = 1, #buildingData do
			if buildingData[i]["S"] ~= nil then
				buildingData[i]["S"] = nil
			end
			-- 如果这个建筑不是房屋且没建造过的话，那么显示红点
			local ids = tonumber(buildingData[i][dataKeyID])
			-- cclog("*@#$*@#*@*#*ID is : ", buildingData[i][dataKeyNum], ids, type(ids))
			if buildingData[i][dataKeyNum] == 0 and (ids < 2 or ids > 51) then
				bIsNeedRedPoint = true
			end
		end
		self:setRoleData(roleBuilding, buildingData, nil)
		-- 判断是否显示下边红点,只要有一个没建造的就显示红点
		if bIsNeedRedPoint then
			-- 增加红点显示操作
			cclog("显示红点")
        	GuideController:getInstance():removeStep(1, true)
		else
			-- 增加红点隐藏操作
			cclog("隐藏红点")
        	GuideController:getInstance():addStep(1, true)
		end
	elseif unitType == kUnlockResource then
		-- 解锁资源
	elseif unitType == kUnlockStore then
		-- 解锁商店
		local storeData = self:getRoleData(roleStore)
		local bIsNeedRedPoint = false
		for i = 1, #storeData do
			if storeData[i]["S"] ~= nil then
				storeData[i]["S"] = nil
			end
		end
		self:setRoleData(roleStore, storeData, nil)
	else
		cclog("*************判断出错，请检查传入类型！！！*************")
		return false
	end
	return true
end

-- 根据传过来的id判断这个元素是否需要解锁或者升级
function DataManager:createSuccessCheck(unitType, id)
	if type(id) ~= "string" then
		cclog("传入的解锁id必须是string！！！")
		return false
	end
	if unitType == kUnlockMake then
		-- 根据传进来的id把原始数据的num+1
		local makeData = self:getRoleData(roleMake)
		local finalData = {}
		for i = 1, #makeData do
			local sortIds = makeData[i]["sortId"]
			if sortIds == id then
				cclog("发现需要修改的id")
				local num = tonumber(makeData[i][dataKeyNum])
				-- print("createSuccessCheck"..num)
				if num > 0 then
					num = num - 1
				end
				makeData[i][dataKeyNum] = num .. ""
				if num ~= 0 then -- num == -1 or num > 0
					-- 排序的时候判断如果是地图史诗奖励，那么插到队首，否则插到队尾
					if tonumber(sortIds) >= 100 and tonumber(sortIds) <= 115 then
						table.insert(finalData, 1, clone(makeData[i]))
					else
						table.insert(finalData, clone(makeData[i]))
					end
				end
			else
				-- 排序的时候判断如果是地图史诗奖励，那么插到队首，否则插到队尾
				if tonumber(sortIds) >= 100 and tonumber(sortIds) <= 115 then
					table.insert(finalData, 1, clone(makeData[i]))
				else
					table.insert(finalData, clone(makeData[i]))
				end
			end
		end
		self:setRoleData(roleMake, finalData, nil)

		if not GuideController:getInstance():getIsHaveStep(950,true) then
			GuideController:getInstance():addStep(950,true)
		end

		-- 制造完成时的检查
		local produceCsv = self:getCSVByID(csvOfProduce)
		if produceCsv ~= nil then
			-- 根据produce表取出真实id，然后去resource表里检查升级
			if produceCsv[id] ~= nil then
				local resourceInfoId = produceCsv[id]["resourceInfoID"]
				-- 判断解锁
				if resourceInfoId ~= nil then
					self:upgradeResourceUnitWithId(resourceInfoId)
				else
					cclog("根据传入的解锁id没有找到resourceInfoID！！！")
					return false
				end
				-- 判断逐级解锁
				local data = produceCsv[id]
				-- 发送成功制造的信息
				self:sendSystemInfo(data["successDesc"])
				-- 检查级联解锁
				self:unlockUnitWithCsvData(data)
                -- 触发任务(类型，制作)
                local taskID = data["taskID"] 
                local taskOk = data["taskOk"]  

                local stepInfos = {}
                stepInfos.id = id
                stepInfos.num = 1
                MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)
                
			else
				cclog("传入的解锁id查表木有找到~~~" .. id)
				return false
			end
		else
			cclog("资源produce的csv木有找到！！！")
			return false
		end
	elseif unitType == kUnlockBuild then
		-- 根据传进来的id把原始数据的num+1
		local bIsNewBuild = false
		local bigId = 1
		local buildingData = self:getRoleData(roleBuilding)
		for i = 1, #buildingData do
			-- print("循环到的id", buildingData[i][dataKeyID])
			if buildingData[i][dataKeyID] == id then
				-- print("发现需要修改的id")
				if buildingData[i][dataKeyNum] == 0 then
					bIsNewBuild = true
				end
				buildingData[i][dataKeyNum] = 1
			end
			if bigId < tonumber(buildingData[i][dataKeyID]) then
				bigId = tonumber(buildingData[i][dataKeyID])
			end
		end
		-- 必须排序一遍，否则当解锁的内容没有建造的时候有可能不正确
		local finalData = {}
		local midIndex = 1
		-- print("开始建造排序操作", bigId)
		for i = 1, bigId do
			if buildingData[i] ~= nil then
				-- print("判断到底是什么状态：", buildingData[i][dataKeyNum])
				if buildingData[i][dataKeyNum] == 0 then
					table.insert(finalData, midIndex, clone(buildingData[i]))
					midIndex = midIndex + 1
				else
					table.insert(finalData, midIndex, clone(buildingData[i]))
				end
				-- print("解锁排序顺序", i, midIndex)
			end
		end
		self:setRoleData(roleBuilding, finalData, nil)
		-- 根据解锁id处理新手引导解锁功能步骤
		require "LuaClass/GuideController"
		if id == "1" then

			if not GuideController:getInstance():getIsHaveStep(2) then
				print("11111")
			end

			-- 建设完仓库之后
			GuideController:getInstance():addStep(2)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "2" then
			-- 建设完民房之后
			GuideController:getInstance():addStep(3)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "52" then
			-- 建设完成农场之后
			GuideController:getInstance():addStep(4)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "53" then
			-- 建设完市场之后
			GuideController:getInstance():addStep(5)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "54" then
			-- 建设完加工坊之后
			GuideController:getInstance():addStep(6)
		elseif id == "55" then
			-- 建设完磨坊之后
			GuideController:getInstance():addStep(7)
			-- 这里要删除一下资源按钮引导数据(这样就会再次显示资源界面引导红点)
			GuideController:getInstance():removeStep(5, true)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "56" then
			-- 建设完船坞之后
			GuideController:getInstance():addStep(8)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		elseif id == "58" then
			-- 建设完训练营之后
			GuideController:getInstance():addStep(9)
			-- 删除返回按钮的记录，让他显示红点
			-- GuideController:getInstance():removeStep(7, true)
		end
		-- 建造完成时的检查
		local csv = self:getCSVByID(csvOfBuild)
		local data = csv[id]
        if data ~= nil then
    		-- 如果是建筑成功的话才发送系统消息
    		if bIsNewBuild then
    			-- 发送成功建造的信息
    			self:sendSystemInfo(data["successDesc"])
    		end
    		-- 如果新手引导没走到第三步，那么直接return
    		if not GuideController:getInstance():getIsHaveStep(3) then
    			return
    		end
    		-- 检查级联解锁
    		self:unlockUnitWithCsvData(data)
            -- 触发任务(类型，建造)
            local taskID = data["taskID"] 
            local taskOk = data["taskOk"]  

            local stepInfos = {}
            stepInfos.id = id
            stepInfos.num = 1
            MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)
        end
	elseif unitType == kUnlockStore then
		-- 商店购买后的检查
		local storeData = self:getRoleData(roleStore)
		local finalData = {}
		for i = 1, #storeData do
			-- print("循环到的id", buildingData[i][dataKeyNum])
			if storeData[i]["sortId"] == id then
				-- print("发现需要修改的id")
				local num = tonumber(storeData[i][dataKeyNum])
				if num > 0 then
					num = num - 1
				end
				storeData[i]["S"] = nil
				storeData[i][dataKeyNum] = num .. ""
				if num == -1 or num > 0 then
					table.insert(finalData, #finalData + 1, clone(storeData[i]))
					-- finalData[i] = clone(storeData[i])
				end
			else
				table.insert(finalData, #finalData + 1, clone(storeData[i]))
				-- finalData[i] = clone(storeData[i])
			end
		end
		self:setRoleData(roleStore, finalData, nil)

		if not GuideController:getInstance():getIsHaveStep(951,true) then
			GuideController:getInstance():addStep(951,true)
		end

		-- 完成时的检查
		local storeCsv = self:getCSVByID(csvOfStore)
		if storeCsv ~= nil then
			-- 根据produce表取出真实id，然后去resource表里检查升级
			if storeCsv[id] ~= nil then
				local resourceInfoId = storeCsv[id]["resourceInfoID"]

				-- 判断逐级解锁
				local data = storeCsv[id]
				-- 发送成功制造的信息
				self:sendSystemInfo(data["successDesc"])
				-- 检查级联解锁
				self:unlockUnitWithCsvData(data)
			else
				cclog("传入的解锁id查表木有找到~~~"..id)
				return false
			end
		else
			cclog("csv木有找到！！！")
			return false
		end
		-- local storeCsv = self:getCSVByID(csvOfStore)
		-- local data = storeCsv[id]
		-- self:unlockUnitWithCsvData(data)
	else
		cclog("*************判断出错，请检查传入类型！！！*************")
		return false
	end
	cclog("DataManager:createSuccessCheck:操作成功！")
	return true
end

-- 根据类型和id判断是否升级
function DataManager:upgradeResourceUnitWithId(id)
	if type(id) ~= "string" then
		return false, "传入的升级id必须是string！！！"
	end
	-- body
	local resourceCsv = self:getCSVByID(csvOfResourceInfo)
	-- 去csv里查找解锁数量
	local csvData = resourceCsv[id]
	if csvData ~= nil then
		local activityData = csvData["raiseType"]
		if activityData ~= nil then
			local actType = nil
			local actNum = nil
			-- 1背包 2战船 3采集 4炼金 5炮筒数量 6炮筒攻击力 7战船血量
			for i = 1, #activityData do
				actType = activityData[i][1]
				actId = tonumber(activityData[i][2])
				if actType == "1" then
					-- 升级战斗背包
					self:setRoleData(rolePackSize, actId, nil)
				elseif actType == "2" then
					-- 升级战船船舱数
					self:setRoleData(roleCabinSize, actId, nil)
				elseif actType == "3" then
					-- 升级采集初始值
					self:setRoleData(roleGatherUnit, actId, nil)
				elseif actType == "4" then
					-- 升级炼金单次数值
					self:setRoleData(roleAlchemyUnit, actId, nil)
				elseif actType == "5" then
					-- 升级战船炮筒数
					self:setRoleData(roleWarship, actId, nil)
				elseif actType == "6" then
					-- 升级炮筒攻击力
					self:setRoleData(roleShipGunPower, actId, nil)
				elseif actType == "7" then
					-- 升级战船血量
					self:setRoleData(roleShipHp, actId, nil)
					-- 记录当前战船id
					self:setRoleData(roleShipId, id, nil)
				elseif actType == "8" then
					local myBreadOwn = self:getRoleData(roleBreadOwn)
					local BreadOwn = activityData[i][2]
					if string.find(myBreadOwn, BreadOwn) == nil then
						myBreadOwn = myBreadOwn.."_"..BreadOwn
						local addhp = tonumber(activityData[i][3])
						-- 增加面包基础回血量
						self:setRoleData(roleBreadHp, addhp, nil)
						self:setRoleData(roleBreadOwn, myBreadOwn, nil)
					end
				else
					return false, "解锁类型找不到！！！无法解锁！(具体请弄死姜雨辰)"
				end
			end
		else
			return false, "解锁数据不正确！！！无法解锁！"
		end
	else
		return false, "csv中没找到相应的数据，请检查id是否正确"
	end
	return true, "升级成功！"
end

-- 获得商店的解锁数据，key value格式
function DataManager:getStoreUnlockTable()
	-- body
	local finalTable = {}
	local storeData = self:getRoleData(roleStore)
	local resourceCsv = self:getCSVByID(csvOfResourceInfo)
	for i = 1, #storeData do
		if resourceCsv[storeData[i][dataKeyID]] ~= nil then
			finalTable[storeData[i][dataKeyID]] = resourceCsv[storeData[i][dataKeyID]]["price"]
		end
	end
	return finalTable
end
--[[
解锁功能相关函数结束
]]

--[[
系统信息功能相关函数开始
]]
-- 增加系统信息文本
function DataManager:sendSystemInfo(infoString)
	-- 传进来的信息字符串不能是nil或者空~
	if infoString == nil or infoString == "" then
		return
	end
    table.insert(SystemInfoData, infoString)
    -- 判断如果长度超出指定长度，那么干掉多余的数据
    while #SystemInfoData > 20 do
        table.remove(SystemInfoData, 1)
    end
    -- 干完之后发送通知
    self:postEvent("kSystemInfoNeedReload", nil)
end

-- 获得系统信息文本
function DataManager:getSystemInfoString()
	local labelStr = ""
    for i = 0, #SystemInfoData, 1 do
        -- 首先取出所有的数据
        if SystemInfoData[#SystemInfoData - i] ~= nil then
            labelStr = labelStr .. SystemInfoData[#SystemInfoData - i] .. "\n"
        end
    end
    -- 添加label到节点上
    -- labelStr = labelStr .. "\n"
    return labelStr
end
--[[
系统信息功能相关函数结束
]]

--[[
背包与战斗背包操作相关函数开始
]]
function DataManager:addPackItemWithId(itemId, num, bIsFloat)
	if bIsFloat == nil then
		bIsFloat = true
	end
	if type(itemId) ~= "string" or type(num) ~= "number" then
		cclog("传入的解锁id必须是string,num必须是number！！！")
		return false
	end
	if itemId == "1001" then
		-- 是金币的情况
		self:addCoin(num)
	elseif itemId == "1002" then
		-- 是钻石的情况
		self:addDiamond(num)
	else
		-- 不是金币的情况
		local packData = self:getRoleData(rolePack)
		if packData[itemId] ~= nil then
			if packData[itemId] + num < 0 then
				cclog("背包道具数量不足，请检查是否可以扣除")
				return false
			end
			packData[itemId] = tonumber(packData[itemId]) + num
		else
			packData[itemId] = tonumber(num)
		end
		-- 如果数字小于等于0，那么将这个数据干掉
		if packData[itemId] <= 0 then
			packData[itemId] = nil
		end
		-- 飘字提示物品增加
		if bIsFloat and num > 0 then
			local resourceCsv = self:getCSVByID(csvOfResourceInfo)[itemId]
			if resourceCsv ~= nil then
				local name = resourceCsv["name"]
				ToastUtil:downString(name .. "+" .. num .. " 总共 "..packData[itemId])
			end
		end
		self:setRoleData(rolePack, packData, nil)
	end
	return true
end

-- 获得背包里指定道具数量
function DataManager:getPackNumWithId(itemId)
	if type(itemId) ~= "string" then
		cclog("传入的解锁id必须是string！！！")
		return -1
	end
	if itemId == "1001" then
		local money = self:getRoleData(roleMoney)
		return tonumber(money)
	else
		local packData = self:getRoleData(rolePack)
		local itemData = packData[itemId]
		if itemData ~= nil then
			return tonumber(itemData)
		end
	end
	return 0
end

-- 合并战斗背包和兵将数据的函数
function DataManager:mixPackAndSoildier()
	local battleData = self:getRoleData(roleBattleQueue)
	local packData = self:getRoleData(roleBattlePack)
	local selectUnit = self:getRoleData(roleSelectUnit)
	local produceCsv = self:getCSVByID(csvOfResourceInfo)
	-- 写入兵将数据
	for k,v in pairs(battleData) do
		print("出征返回来的兵将：", k, v)
		if v > 0 then
			self:addSoilderWithId(k, v)
			-- 写入回兵将数据之后将出征界面记录的临时数据写回去
			selectUnit[tonumber(k) + 10000 .. ""] = v
		end
	end
	-- 写入背包数据
	-- print("***************", tableToJson(packData))
	for k,v in pairs(packData) do
		if packData[k] ~= nil and packData[k].num > 0 then
			self:addPackItemWithId(k, packData[k].num)
			-- 去道具表判断这个物品是否会在出征界面显示，如果有，那么把他写到出征界面临时数据里去
			local data = produceCsv[k]
			if data ~= nil and tonumber(data["carryType"]) == 1 then
				selectUnit[k] = packData[k].num
			end
		end
	end
	-- 再次写入出征界面临时存储数据
	self:setRoleData(roleSelectUnit, selectUnit, nil)
end
--[[
背包操作相关函数结束
]]

--[[
兵种操作开始
]]
function DataManager:addSoilderWithId(itemId, num, bIsFloat)
	if num == 0 then
		-- 无论有没有这条兵种信息，加0操作无意义，故而删除
		return true
	end
	if bIsFloat == nil then
		bIsFloat = false
	end
    if type(itemId) == "number" then itemId = tostring(itemId) end
    
	if type(itemId) ~= "string" or type(num) ~= "number" then
		cclog("传入的解锁id必须是string,num必须是number！！！")
		return false
	end
		local soildierData = self:getRoleData(roleSoildierQueue)
		if soildierData[itemId] ~= nil then
            if soildierData[itemId][dataKeyNum] == nil then
                soildierData[itemId][dataKeyNum] = 0
            end
			if num > 0 then
				cclog("增加兵", itemId, num)
				soildierData[itemId][dataKeyNum] = tonumber(soildierData[itemId][dataKeyNum]) + num
				local csv = self:getCSVByID(csvOfSoilderAttribute)[itemId]

                --任务检查(类型，拥有英雄)
                local taskID = csv["taskID"] 
                local taskOk = csv["taskOk"]  

                local stepInfos = {}
                stepInfos.id = itemId
                stepInfos.num = num

                MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)

				ToastUtil:downString(csv["name"] .. "+" .. num .. " 总共 "..soildierData[itemId][dataKeyNum])
			elseif num < 0 then
				cclog("减少兵", itemId, num)
				soildierData[itemId][dataKeyNum] = tonumber(soildierData[itemId][dataKeyNum]) + num
				if soildierData[itemId][dataKeyNum] <= 0 then
					soildierData[itemId][dataKeyNum] = nil
					soildierData[itemId] = nil
				end

			end
		else
			if num <= 0 then
				-- 如果背包中已经没有这条兵种信息，还要去删除或者加0操作，就没有意义还会导致添加了一条数量为0的兵种信息，船坞界面会出错
				return true
			end
	        local _csvData = self:getCSVByID(csvOfSoilderAttribute)
            --soildierData[itemId] = clone(_csvData[itemId])
            soildierData[itemId] = {}
            soildierData[itemId][dataKeyID] = itemId
            soildierData[itemId][dataKeyNum] = 0
            soildierData[itemId][dataKeyNum] = soildierData[itemId][dataKeyNum] + num
            local csv = self:getCSVByID(csvOfSoilderAttribute)[itemId]
			ToastUtil:downString(csv["name"] .. "+" .. num .. " 总共 "..soildierData[itemId][dataKeyNum])
            cclog("新兵ID=", itemId, num,"=当前num=",soildierData[itemId][dataKeyNum])
		end
		self:setRoleData(roleSoildierQueue, soildierData, nil)

	return true
end
--[[
兵种操作结束
]]

--[[
点击炼金按钮回调函数开始
]]
function DataManager:AlchemyButtonDidClick()
    -- 播放声音
    if DataManager:getInstance():getSound_off() == 0 then
        AudioEngine.playEffect(EFFECT_Gold, false)
    end

    local _addcoin = DataManager:getInstance():getRoleData(roleAlchemyUnit)
    local _result =  DataManager:getInstance():addCoin(_addcoin)
    if _result == 1 then
        ToastUtil:downString("金币+".._addcoin.." 总共:"..DataManager:getInstance():getRoleData(roleMoney), true)
    end

    local achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Alchemy)
    DataManager:getInstance():setAchievementInfo(achievement_Alchemy, (achievementValue + 1))

    -- 取出玩家炼金次数记录
    local AlchemyBtnClickCount = self:getRoleData(roleAlchemyBtnClickCount)
    if AlchemyBtnClickCount == nil then
        AlchemyBtnClickCount = 1
    end
    -- cclog("炼金次数：%d", AlchemyBtnClickCount)

    -- 走新手引导的时候，第一次要求点击10次炼金按钮，才能触发addStep
    if AlchemyBtnClickCount >= 10 then
        local isBuildUnlocked = GuideController:getInstance():getIsHaveStep(1)
        GuideController:getInstance():addStep(1)
        if not isBuildUnlocked then
            self:sendSystemInfo("建设已解锁：点击底部“建设”，优先建造仓库。仓库会解锁采集，是第一次出航的起点。")
        end
        if not GuideController:getInstance():getIsHaveStep(2) then
            -- 第一次点击炼金的时候清理掉成就和声望的红点
            GuideController:getInstance():addStep(401, true)
            GuideController:getInstance():addStep(402, true)
        end
    end
    -- 然后有逻辑是说要点击100次会触发一个弹出购买提示框购买按住连续点击炼金
    local canLongPress = self:getRoleData(roleAlchemyCanLongPress)
    if canLongPress == 0 then
        -- 如果购买了长按炼金，那么就不用走这套逻辑了，抛弃之
        local showCount = self:getRoleData(roleAlchemyShowCount)
        if showCount == nil then
            showCount = 1
        end
        if AlchemyBtnClickCount >= (showCount < 4 and 100 or 300) then
            -- 触发弹出逻辑
            if showCount < 3 then
                -- 弹框提示钻石购买金币
                local _newalert = AlertView:create(2, 0, "购买金币", function()
                    if self:addDiamond(-40) == 1 then
                        self:addCoin(5000, false, true)
                    end
                end, nil)
                _newalert:setOkRemove(false)

                local showLabel1 = cc.LabelTTF:create("您是否花费40钻石\n购买5000金币？", BoldFont, 36.0)
                showLabel1:setColor(WriteColor)
                showLabel1:setPosition(cc.p(_newalert.s_position.x, _newalert.s_position.y))
                _newalert:addChild(showLabel1)
            else
                -- 弹框提示购买长按炼金
                local _newalert = nil
                _newalert = AlertView:create(2, 0, "购买长按炼金", function()
                    if self:addDiamond(-398) == 1 then
                        self:setRoleData(roleAlchemyCanLongPress, 1)
                        -- 这里必须刷新之前的界面，否则多次炼金不生效
                        zqDispatch:backToLastView()
                        _newalert:removeFromParent()
                    end
                end, nil)
                _newalert:setOkRemove(false)

                local showLabel1 = cc.LabelTTF:create("长按炼金按钮，可持续获得金币，\n您是否花费398钻石获得此功能？", BoldFont, 36.0)
                showLabel1:setColor(WriteColor)
                -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
                showLabel1:setPosition(cc.p(_newalert.s_position.x, _newalert.s_position.y))
                _newalert:addChild(showLabel1)
            end
            -- 将次数置为0
            AlchemyBtnClickCount = 0
            -- 写入显示次数
            self:setRoleData(roleAlchemyShowCount, showCount + 1)
        end
        -- 需要的时候（主要是新手引导之后，没买按住一直炼金之前）把点击次数++
        AlchemyBtnClickCount = AlchemyBtnClickCount + 1
        self:setRoleData(roleAlchemyBtnClickCount, AlchemyBtnClickCount)
    end
end

--[[
点击炼金按钮回调函数结束
]]

function DataManager:splitValueToArray(tableData, key)
	-- body
	self:splitValueToArrayBySeparators(tableData, key, ";")
end

function DataManager:splitValueToArrayBySeparators(tableData, key, separator)
	-- body
	for k,v in pairs(tableData) do
		local data = v[key]
		v[key] = split(v[key], separator)
		remove(data)
	end
end

-- 显示购买金币的框
function DataManager:showBuyGoldBox()
    local _alert = AlertView:create(0, 0, "购买金币","",nil)
    
    local showLabel1 = cc.LabelTTF:create("消耗钻石购买获得更多金币", BoldFont, 33.0)
    showLabel1:setColor(cc.c3b(255, 255, 255))
    -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + showLabel1:getContentSize().height * 1.8))
    _alert:addChild(showLabel1)
    
    for i = 1,2 do
        local _backGround = cc.Sprite:create("Images/UI/dibantiao_03.png")
        _backGround:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y - 10 - _backGround:getContentSize().height *1.2 * (i - 1)))
        _alert:addChild(_backGround)
        
        local _fontSize = 26
        local _HeadSprite= nil--cc.Sprite:create("Images/Icon/".._soilder["icon"])
        if _HeadSprite == nil then _HeadSprite= cc.Sprite:create("Images/Icon/r_9.png")  end
        _HeadSprite:setPosition(cc.p(_backGround:getPositionX()-_backGround:getContentSize().width/2+_HeadSprite:getContentSize().width-5,_backGround:getPositionY()))
        _alert:addChild(_HeadSprite)
        --name
        local _xLeft = _HeadSprite:getPositionX() + _HeadSprite:getContentSize().width/2 + 10
        local _centerY = _HeadSprite:getPositionY() -5
        local _name = cc.LabelTTF:create("金 币",BoldFont,_fontSize+4);
        _name:setPosition(cc.p(_xLeft,_centerY+_fontSize+2))
        _name:setColor(BaseColor)
        -- _name:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _name:setAnchorPoint(cc.p(0,0.5))
        _alert:addChild(_name)
        
        
        local coinnum = 5000
        local need_diamond = 30
        if i ==1 then
            coinnum = 5000
            need_diamond = 30
        elseif i ==2 then
            coinnum = 120000
            need_diamond = 500
        end

        local _price = cc.LabelTTF:create("x"..coinnum,BoldFont,_fontSize+4);
        _price:setPosition(cc.p(_xLeft,_centerY-_fontSize+7))
        _price:setColor(WriteColor)
        -- _price:enableStroke(cc.c4b(255, 255, 255, 255), 1)
        _price:setAnchorPoint(cc.p(0,0.5))
        _alert:addChild(_price)
        
        local _menuButton = cc.MenuItemImage:create("Images/btn/ann10_a.png", "Images/btn/ann10_b.png")
        
        _menuButton:registerScriptTapHandler(function()
            print("点击购买")
            if DataManager:getInstance():getSound_off() == 0 then
                AudioEngine.playEffect(EFFECT_Button, false)
            end
            if i then
                -- local Diamondnum = DataManager:getInstance():getRoleData(roleDiamond)
                if DataManager:getInstance():addDiamond(need_diamond * -1) == 1 then    --Diamondnum >= need_diamond
                    local _result =  DataManager:getInstance():addCoin(coinnum)
                    if _result == 1 then
                        ToastUtil:downString("金币+"..coinnum)
                        _alert:removeFromParent()
                    end
                else
                    if _alert ~= nil then
                        _alert:removeFromParent()
                    end
                end
            end
        end)
        
        _menuButton:setPosition(cc.p(_backGround:getContentSize().width  - _menuButton:getContentSize().width * 0.5 - 15,_backGround:getContentSize().height * 0.5))
        local menu = cc.Menu:create(_menuButton)
        menu:setPosition(0.0, 0.0)
        _backGround:addChild(menu)
        
        
        local _diaIcon = cc.Sprite:create("Images/UI/DiamondBg.png")
        _diaIcon:setAnchorPoint(cc.p(1,0))
        _diaIcon:setPosition(cc.p(_menuButton:getContentSize().width * 0.5,_menuButton:getContentSize().height * 0.5 - 10))
        _menuButton:addChild(_diaIcon)
        
        
        local _diaLable = cc.LabelTTF:create("x"..need_diamond, BoldFont, 25.0)
        _diaLable:setAnchorPoint(cc.p(0,0))
        _diaLable:setPosition(cc.p(_menuButton:getContentSize().width * 0.5,_menuButton:getContentSize().height * 0.5))
        -- _diaLable:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        _menuButton:addChild(_diaLable)
        
        
        local _zz = cc.LabelTTF:create("购 买", BoldFont, 25.0)
        _zz:setAnchorPoint(cc.p(0.5,0))
        _zz:setPosition(cc.p(_menuButton:getContentSize().width * 0.5,0))
        -- _zz:enableStroke(cc.c4b(255, 255, 255, 255), 2)
        _menuButton:addChild(_zz)
    end
end

function test1(event)
	-- body
	print("==== DataManager:test1", event._usedata)
end

function test2(event)
	-- body
	print("==== DataManager:test2", event._usedata)
end
