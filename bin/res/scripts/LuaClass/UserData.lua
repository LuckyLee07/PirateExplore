require "LuaClass/Header"
require "LuaClass/Utils"
require "LuaClass/SaveDataManager"
require "json"
libJson = require "LuaClass/simplejson.lua"


-- clone数据函数，主要为的是防止数据修改
function simpleclone(object,clonetype,key)

	-- printn("simpleclone",object,clonetype,key)
	
    local lookup_table = {}
    local function _copy(object,isKey)
    	local objtype = type(object)
        if objtype ~= "table" then
        	--加密处理
        	if objtype == "number" and not isKey then
        		if clonetype ~= nil then
        			object = object * clonetype
        			-- object = temp
        		end
        	end
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key,true)] = _copy(value,false)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local realDatas = {}
local delegatesDatas = {}

UserData = class("UserData", function ()
	return cc.Node:create()
end)
UserData._roleDada = nil
UserData._mapDada = nil  --sd

UserData.lastMapID = 0

function UserData:create()
	-- body
	local instance = UserData:new()
	instance:initWithData()
	return instance
end

function UserData:initWithData()
	-- 首次初始化数据已经移动到DataManager里的init方法里，请去那里加 by 杨杰
	
end



function UserData:getRole()
	-- body
	return self._roleDada
end

function UserData:setRole(roleInfo)
	-- body
	-- remove(self._roleDada)
	self._roleDada = roleInfo
end

function UserData:getRoleData(roleDataID)--sd
	-- body

	local roleIDNum = tonumber(roleDataID)

	if roleDataID == mapInfo then
		return self._mapDada
	-- elseif roleIDNum > 63 and roleIDNum < 67 then
	-- 	return self._missionData[roleDataID]
	else
		return self._roleDada[roleDataID]
	end
end

function UserData:setRoleData(roleDataID, roleData)--sd
	-- body
	local roleIDNum = tonumber(roleDataID)

	if roleDataID == mapInfo then
		self._mapDada = roleData
	-- elseif roleIDNum > 63 and roleIDNum < 67 then
	-- 	self._missionData[roleDataID] = roleData
	else
		self._roleDada[roleDataID] = roleData
	end
	
end


function UserData:setMusic(var)
	-- body
	self._roleDada[roleMusic_off] = var
end
function UserData:getMusic()
	-- body
	return self._roleDada[roleMusic_off]
end

function UserData:setSound(var)
	-- body
	self._roleDada[roleSound_off] = var
end
function UserData:getSound()
	-- body
	return self._roleDada[roleSound_off]
end

function UserData:setEffect(var)
	-- body
	self._roleDada[roleEfect_off] = var
end
function UserData:getEffect()
	-- body
	return self._roleDada[roleEfect_off]
end



function UserData:loadLastTime(lasttime)
	-- body
	self._roleDada[roleLastTime] = lasttime
end

function UserData:loadTalent(tableData)
	-- body
	self._roleDada[roleTalent] = tableData
end

function UserData:loadAchievement(tableData)
	-- body
	self._roleDada[roleAchievement] = tableData
end

function UserData:loadAchievementPoint(var)
	-- body
	self._roleDada[roleAchievementPoint] = var
end

-- 初始化新手引导数据
function UserData:loadGuideStep(tableData)
	self._roleDada[roleGuideStep] = ""
end

-- 初始化建造数据的
function UserData:loadProducerQueueData(tableData)
	-- body
	-- if (tableData == nil) then
	-- 	local data = {}
	-- 	for i=1,5 do
	-- 		local workerData = {[dataKeyID]=i .. "", [dataKeyNum]=0 .. ""}
	-- 		data[i] = workerData
	-- 	end
	-- 	self._roleDada[roleProducerQueue] = data
	-- 	self._roleDada[roleLivingUnitNum] = 45 .. ""
	-- 	self._roleDada[roleProduceTime] = 0
 -- 	else
	-- 	self._roleDada[roleProducerQueue] = tableData
	-- end

	-- 初始化建造就是什么都木有
	self._roleDada[roleProducerQueue] = {}
	self._roleDada[roleLivingUnitNum] = 0
	self._roleDada[roleProduceTime] = 0
	self._roleDada[roleSevenDayBonus] = 0	-- 玩家7日登陆奖励记录初始化，暂时存这里
	self._roleDada[roleGatherUnit] = 1
	self._roleDada[roleResourceCD] = 20
	self._roleDada[roleOfflineBonusTime] = 3600
end

-- 初始化金币和钻石数据
function UserData:loadMoney(tableData)
	-- body
	self._roleDada[roleMoney] = 0
	self._roleDada[roleDiamond] = 0
end

-- 初始化背包数据
function UserData:loadPackage(tableData)
	-- body
	self._roleDada[rolePack] = {}
	-- 测试代码
	-- for i = 1001,1040 do
	-- 	self._roleDada[rolePack][i..""] = 1888
	-- end
end

-- 初始化出征信息
function UserData:loadExpedition(tableData)
	-- body
	self._roleDada[roleCabinSize] = 1			-- 战船大小
	self._roleDada[rolePackSize] = 20			-- 战斗背包大小
	self._roleDada[roleShipHp] = 500			-- 战船血量
	self._roleDada[roleShipGunPower] = 22		-- 战船炮筒攻击力
	self._roleDada[roleWarship] = 2 			-- 战船炮筒数
	self._roleDada[roleGatherUnit] = 10			-- 单位采集收益（数值*(1 + 上下20%)）
	self._roleDada[roleAlchemyUnit] = 1			-- 单位炼金收益
	self._roleDada[roleShipId] = "1299"			-- 战船id，用来取信息用

	self._roleDada[roleBreadHp] = 15 			-- 面包基础回血量
	self._roleDada[roleBreadOwn] = 0			-- 面包基础回血量升级记录(LINUX权限原理)
	self._roleDada[roleTranslateDoor] = 5 		-- 传送门最高打到得层级

	self._roleDada[roleBattleQueue] = {}		-- 出征兵将数据
	self._roleDada[roleBattlePack] = {}			-- 出征背包数据
	self._roleDada[roleSelectUnit] = {}			-- 出征前玩家选择的单位数据
end

-- 初始化建造数据
function UserData:loadBuild(tableData)
	-- 初始化建造数据
	self._roleDada[roleBuilding] = {{[dataKeyID] = "1", [dataKeyNum] = 0, ["S"] = 1}}
	-- self._roleDada[roleBuilding]["1"] = self._roleDada[roleBuilding][1]
end

-- 初始化制造数据
function UserData:loadMake(tableData,ResourceInfo)
	
	-- 初始化制造数据
	self._roleDada[roleMake] = {} --{[dataKeyID]="1158", [dataKeyNum]="0", ["sortId"] = "16"}
	local id = nil
	local i = 1
	for k,v in pairs(tableData) do
		if tonumber(v["unit"]) == 1 then
			local _dataKeyNum = ResourceInfo[v["resourceInfoID"]]["limits"]
			-- print("sdsdsdsdsdsd",_dataKeyNum)
			-- table.insert(self._roleDada[roleMake], {[dataKeyID] = v["resourceInfoID"], [dataKeyNum] = v["limits"], ["sortId"] = v[dataKeyID]})
			table.insert(self._roleDada[roleMake], {[dataKeyID] = v["resourceInfoID"], [dataKeyNum] = _dataKeyNum, ["sortId"] = v[dataKeyID], ["S"] = 1})
			-- self._roleDada[roleMake][v[dataKeyID]] = self._roleDada[roleMake][i]
		end
		i = i + 1
	end
end

-- 初始化商城数据数据
function UserData:loadStore(tableData,ResourceInfo)
	-- body
	self._roleDada[roleStore] = {}
	local id = nil
	local i = 1
	for k,v in pairs(tableData) do
		if tonumber(v["unit"]) == 1 then
			local _dataKeyNum = ResourceInfo[v["resourceInfoID"]]["limits"]
			table.insert(self._roleDada[roleStore], {[dataKeyID] = v["resourceInfoID"], [dataKeyNum] = _dataKeyNum, ["sortId"] = v[dataKeyID], ["S"] = 1})
			-- self._roleDada[roleMake][v[dataKeyID]] = self._roleDada[roleMake][i]
		end
		i = i + 1
	end
end

-- 初始化练兵数据
function UserData:loadSoildier(tableData)
	-- body
	self._roleDada[roleSoildierQueue] = {}
end

-- -- 初始化地图相关数据
-- function UserData:loadMapData(tableData)
-- 	-- body
-- 	self._roleDada[roleMapFog] = {}
-- end

-- 初始化成就数据
function UserData:loadStorageInfo(tableData)
	-- body
	print("loadStorageInfo",tableData)
	if (tableData == nil) then
		local roleStorageInfoTable = {}
		roleStorageInfoTable = {}
		for i=1,20 do
			print("loadStorageInfo",i)
			roleStorageInfoTable[i] = 0
			-- print("loadStorageInfo",self._roleDada[roleStorageInfo][i])
		end
		self._roleDada[roleStorageInfo] = roleStorageInfoTable
		-- self._roleDada[roleStorageInfo][achievement_Alchemy] = 498
	else
		print("loadStorageInfo2",tableData)
		self._roleDada[roleStorageInfo] = tableData
	end



	-- local newdat = self:getRoleData(roleStorageInfo)
	-- printn("newdat",newdat)
	-- for k,v in pairs(newdat) do
	-- 	print(k,v)
	-- end

end

function UserData:loadBonusAttribute(tableData)
	-- body
	if (tableData == nil) then
		local roleBonusAttributeTable = {}
		for i=1,17 do
			roleBonusAttributeTable[i] = {}

			for j=1,10 do
				print("j=1,10",i,j)
				roleBonusAttributeTable[i][tostring(j)] = {}
				roleBonusAttributeTable[i][tostring(j)][tostring(1)] = 0
				roleBonusAttributeTable[i][tostring(j)][tostring(2)] = 0
			end


			self._roleDada[roleBonusAttribute] = roleBonusAttributeTable
		end
	else
		self._roleDada[roleBonusAttribute] = tableData
	end
end

function UserData:loadData()
	-- body
	-- local missionData = SaveDataManager:getInstance():loadData("mission")
	-- if not missionData then
	-- 	self._missionData = {}
	-- else
	-- 	self._missionData = json.decode(missionData)
	-- end


	local roleData = SaveDataManager:getInstance():loadData("gameRole")
	self._mapDada = {}
	if (roleData ~= nil and roleData ~= "{}") then
		-- self._roleDada = loadTableData(roleData)
		realDatas = json.decode(roleData)
		
		--判断是否是未加密的老挡，若是，对其进行更新成新数据
		if not realDatas[roleEncrypted] then

			realDatas = simpleclone(realDatas,-1)

			realDatas[roleEncrypted] = "1"

			self:saveData()
		end

		-- delegatesDatas = clone(realDatas)
		self._roleDada = {}
		local mt = {
    		__index = function ( t,k )
    			-- --会有抓包的风险
    			-- if type(delegatesDatas[k]) == "table" and _G.next(delegatesDatas[k]) == nil then
    			-- 	cclog("index return real")
    			-- 	return realDatas[k]
    			-- end
    			-- if k == "8" then
    			-- 	printn("__index",k,realDatas[k])
    			-- end
    			-- printn("__index",k,realDatas[k])
    			return simpleclone(realDatas[k],-1,k)
    		end,
    		__newindex = function ( t,k,v )

    			

    			realDatas[k] = simpleclone(v,-1,k)

    			-- if k == "8" then
    			-- 	printn("__newindex",k,realDatas[k])
    			-- end

  				-- if tonumber(k) == 24 then
  				-- 	print("ERROR: 24 is Locked",delegatesDatas[k])
  				-- 	print("ERROR:",realDatas[k])
  				-- end

        		--cclog("Warning: you try update of element "..tostring(k).." to "..tostring(v))
    		end
    	}

    	setmetatable(self._roleDada,mt)
    	cclog("initedrealdata")
		return true
	else
		realDatas = {}
		realDatas[roleEncrypted] = "1"
		delegatesDatas = {}
		local mt = {
    		__index = function ( t,k )
    			--会有抓包的风险
    			-- if type(delegatesDatas[k]) == "table" and _G.next(delegatesDatas[k]) == nil then
    			-- 	cclog("index return real")
    			-- 	return realDatas[k]
    			-- end
    			-- if k == "8" then
    			-- 	printn("__index",k,realDatas[k])
    			-- end

    			return simpleclone(realDatas[k],-1,k)
    		end,
    		__newindex = function ( t,k,v )
    			-- local delegatesDatas = nil 

    			-- delegatesDatas = simpleclone(realDatas,-1)

    			-- delegatesDatas[k] = v

    			

    			realDatas[k] = simpleclone(v,-1,k)

    			-- if k == "8" then
    			-- 	printn("__newindex",k,v)
    			-- end


    		-- 	if tonumber(k) == 24 then
  				-- 	print("ERROR: 24 is Locked",delegatesDatas[k])
  				-- 	print("ERROR:",realDatas[k])
  				-- end
        		--cclog("Warning: you try update of element "..tostring(k).." to "..tostring(v))
    		end
    	}
    	cclog("initedrealdata")
		self._roleDada = {}
		setmetatable(self._roleDada,mt)
		return false
	end
end

-- 钻石商店
function UserData:loadDiamondStore(giftData, itemData)
	-- body
	if (giftData ~= nil and itemData ~= nil) then
		local recommendedData = {}
        -- local giftData = DataManager:getInstance():getCSVByID(csvOfShopGift)
        local recommendedDataTempNum = getTableRowNum(giftData)
        local time = os.time()
        for i=1,recommendedDataTempNum do
            local key = tostring(i)
            local tempValue = giftData[key]
            if (tonumber(tempValue[dataKeyDisplay]) == 1) then
                local giftTemp = {}
                giftTemp[1] = tempValue[dataKeyID]

                if (tonumber(tempValue[dataKeyTime]) > 0) then
                    giftTemp[2] = time + tonumber(tempValue[dataKeyTime]) * 3600
                else
                    giftTemp[2] = tonumber(tempValue[dataKeyTime])
                end
                giftTemp[3] = 0

                recommendedData[#recommendedData + 1] = giftTemp
            end
        end

        local mapLevel = 1

        goodsData = {}
        -- local goodsDataTemp = DataManager:getInstance():getCSVByID(csvOfShopItem)
        local goodsDataTempNum = getTableRowNum(itemData)
        for i=1,goodsDataTempNum do
            local key = tostring(i)
            local tempValue = itemData[key]
            if (tonumber(tempValue[dataKeyDisplay]) == 1) then
                local temp = {}
                temp[1] = tempValue[dataKeyID]

                if (tonumber(mapLevel) >= tonumber(tempValue[dataKeyUnlock])) then
                    temp[2] = 0
                else
                    temp[2] = 2
                end

                goodsData[#goodsData + 1] = temp
            end
        end

        local storeData = {}
        storeData["1"] = recommendedData
        storeData["2"] = goodsData
        self._roleDada[roleDiamondStoreData] = storeData
	end
end

function UserData:loadMap(mapDataID)--sd

	print("loadMap",self.lastMapID,mapDataID)

	--若是之前加载过了数据，就不用加载了
	if self.lastMapID == mapDataID and self._mapDada then
		return self._mapDada
	end

	-- body
	local mapData = SaveDataManager:getInstance():loadData("gameMap"..mapDataID)
	local t1 = os.clock()
	if (mapData ~= nil and mapData ~= "{}") then
		print("saveMap1111") 
		self._mapDada = libJson.decode(mapData)
		-- self._mapDada = json.decode(mapData)
		-- self.lastMapID = mapDataID
		print("gettable time",os.clock() - t1)
		-- self._mapDada = loadTableData(mapData)
		return true
	else
		print("saveMap22222") 
		self._mapDada = {}
		return false
	end

end


function UserData:saveData()
	-- body
	-- SaveDataManager:getInstance():SaveData(toLua(self._roleDada), "gameRole")
		SaveDataManager:getInstance():SaveData(json.encode(realDatas), "gameRole")
end

function UserData:saveMap(mapIndex)--sd
	-- body

	-- print("saveMap0"..os.clock()) 
	-- -- local adata = toLua(self._mapDada)
	-- -- print("saveMap1"..os.clock()) 
	-- local bs = json.encode(self._mapDada)
	-- print()
	-- -- local bs = printn("self._mapDada")
	-- print("saveMap2"..os.clock()) 
	SaveDataManager:getInstance():SaveData(json.encode(self._mapDada), "gameMap"..mapIndex)
	-- print("saveMap3"..os.clock()) 
	
	-- SaveDataManager:getInstance():SaveData(toLua(self._mapDada), "gameMap"..mapIndex)
end

function UserData:saveMission()
	SaveDataManager:getInstance():SaveData(json.encode(self._missionData), "mission")
end
