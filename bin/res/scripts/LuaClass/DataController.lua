require "LuaClass/Header"

--只读table
function read_only( read_only_table )
	if read_only_table == nil or type(read_only_table) ~= "table" then
		return
	end

	if read_only_table == dataController then
		return
	end

	-- local s ={}

	-- for k,v in pairs(read_only_table) do
	-- 	s[k] = v
	-- end

	local proxy = {}
	local mt = {
	__index = read_only_table,
	__newindex = function ( t,k,v )
		-- print("ERROR: you try update of element",tostring(k).."to"..tostring(v)..",but it is a read-only table")
	end
	}

	setmetatable(proxy,mt)


	return proxy
end

-- --可跟踪数量的table
-- function getCustomTable(  )
-- 	local customTable = {}
-- 	local value_table = {}
-- 	value_table.len = 0
-- 	value_table.keys = {}

-- 	local mt = {
-- 		__index = function ( t,k )
			-- print("customTable search By Key",k)
-- 			--若整数，默认是索引,返回对应索引的key值
-- 			if type(k) == "number" then
-- 				k = value.keys[k]
-- 			end

-- 			return value_table[k]
-- 		end,
-- 		__newindex = function ( t,k,v )

-- 			if value_table[k] == nil then
-- 				value_table.len = value_table.len + 1
-- 				value_table.keys[#value_table.keys + 1] = k
-- 			end

-- 			value_table[k] = v
-- 	end
-- 	}

-- 	setmetatable(customTable,mt)

-- 	return customTable
-- end

--添加逻辑，并且封装成只读表
local function initDataByKey( keyString )
	
	-- print("initDataByKey",keyString,type(keyString))

	if keyString == nil or type(keyString) ~= "string" then
		return nil
	end

	local value = nil

	if keyString == "buff" then
		value = DataManager:getInstance():getCSVByID(csvOfBuff)
	elseif keyString == "skillAttribute" then	
		value = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
	elseif keyString == "soilderAttribute" then
		value = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
	elseif keyString == "talent" then
		value = DataManager:getInstance():getCSVByID(csvOfTalent)
	elseif keyString == "strongholdAttribute" then
		value = DataManager:getInstance():getCSVByID(csvOfStrongholdAttribute)
	elseif keyString == "strongholdDistribution" then
		value = DataManager:getInstance():getCSVByID(csvOfStrongholdDistribution)
	elseif keyString == "produce" then
		value = DataManager:getInstance():getCSVByID(csvOfProduce)
	elseif keyString == "resourceInfo" then
		value = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
	end

	value["des"] = keyString
	value["original"] = value
	value = read_only(value)

	return value

end

local datas = {}

local function getValuesById( table,id )

	-- print("getValuesById",table.des,id)


	if id == nil then
		return
	end
	-- print("is not nil",id)
	if type(id) ~= "string" then
		id = tostring(id)
	end

	-- print("tosring",id)

	-- print("getValuesByIdOver")
	return table[id]
end

local function getValueByIdAndKey( table,id ,key )
	-- print("getValueByIdAndKey",table.des,id,key)

	local temp = getValuesById(table,id)
	local result = nil

	if temp ~= nil and key ~= nil then
		if type(key) ~= "string" then
			key = tostring(key)
		end
		result = temp[key]
	end

	return result
end

dataController = nil 



local singletonManager = {}

local singletons = {}

function initDataController(  )
	
	if dataController == nil then
		dataController = {}
		-- datas = {}

		local mt = {
			__index = function ( t,k )
				--若没有该数据，就执行对应的初始化方法
				if datas[k] == nil then
					-- print("__index",k)
					datas[k] = initDataByKey(k)
				end	
				return datas[k]
			end,
			__newindex = function ( t,k,v )
				-- print("ERROR: you try update of element",tostring(k).."to"..tostring(v)..",You're trying to change a read-only data tables, this is a single case, can not be changed!")
			end
		}
		setmetatable(dataController,mt)
	end

	singletonManager[1] = dataController
	singletonManager = read_only(singletonManager)

end


--buf
datas["getBufInfoById"] = function ( id )

	return getValuesById(dataController.buff,id)
end

datas["getBufValueByIdAndKey"] = function ( id,key )

	return getValueByIdAndKey(dataController.buff,id,key)
end

--skill
datas["getSkillInfoById"] = function ( id )
	
	return getValuesById(dataController.skillAttribute,id)
end

datas["getSkillValueByIdAndKey"] = function ( id,key )
	
	return getValueByIdAndKey(dataController.skillAttribute,id,key)
end

--soilder
datas["getSoilderInfoById"] = function ( id )
	-- print("getSoilderInfoById")
	return getValuesById(dataController.soilderAttribute,id)
end

datas["getSoilderValueByIdAndKey"] = function ( id,key )

	return getValueByIdAndKey(dataController.soilderAttribute,id,key)
end

--talent
datas["getTalentInfoById"] = function ( id )

	return getValuesById(dataController.talent,id)
end

datas["getTalentValueByIdAndKey"] = function ( id,key )
	
	return getValueByIdAndKey(dataController.talent,id,key)
end

--strongholdAttribute
datas["getStrongholdAttributeInfoById"] = function ( id )

	return getValuesById(dataController.strongholdAttribute,id)
end

datas["getStrongholdAttributeValueByIdAndKey"] = function ( id,key )
	
	return getValueByIdAndKey(dataController.strongholdAttribute,id,key)
end

--strongholdDistribution
datas["getStrongholdDistributionInfoById"] = function ( id )
	
	return getValuesById(dataController.strongholdDistribution,id)
end

datas["getStrongholdDistributionValueByIdAndKey"] = function ( id,key )

	return getValueByIdAndKey(dataController.strongholdDistribution,id,key)
end

--produce
datas["getProduceInfoById"] = function ( id )
	
	return getValuesById(dataController.produce,id)
end

datas["getProduceValueByIdAndKey"] = function ( id,key )
	
	return getValueByIdAndKey(dataController.produce,id,key)
end

--resourceInfo
datas["getResourceInfoById"] = function ( id )
	
	return getValuesById(dataController.resourceInfo,id)
end

datas["getResourceValueByIdAndKey"] = function ( id,key )
	
	return getValueByIdAndKey(dataController.resourceInfo,id,key)
end
