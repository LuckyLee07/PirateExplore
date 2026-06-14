require "LuaClass/Header"
require "LuaClass/CSVParser"

DynamicData = class("DynamicData", function ()
	return cc.Node:create()
end) 

DynamicData._lockedTallent = nil
  
function DynamicData:create()  
    local instance = DynamicData:new()
	instance:initWithData(nil)
	return instance
end

function DynamicData:initWithData()
	-- body
	-- local parser = CSVParser:getInstance()
	-- self._lockedTallent = parser:loadFileByName("data/talent.csv")
end

function DynamicData:resetUserData(userData)
	-- body
	if (userData ~= nil) then
		self:resetTalent(userData[roleTalent])
	end
end

function DynamicData:loadLockedTallent(tableData)
	-- body
	self._lockedTallent = tableData
end

function DynamicData:resetTalent(userTalentTable)
	-- body
	if (nil ~= userTalentTable) then
		local num = getTableRowNum(userTalentTable)
		if (num > 0) then
			for i=1,num do
				local value = userTalentTable[tostring(i)]
				if (nil ~= value) then
					removeObjectFromTableByKey(self._lockedTallent, value)
				end
			end
		end
	end
end

function DynamicData:getLockedTallent()
	-- body
	return self._lockedTallent
end