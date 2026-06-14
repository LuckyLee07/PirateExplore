require "LuaClass/Header"
require "LuaClass/Utils"
require "LuaClass/SaveDataManager"
require "json"


MapData = class("MapData", function ()
	return cc.Node:create()
end)
MapData._mapData = nil

function MapData:create()
	-- body
	local instance = MapData:new()
	instance:initWithData()
	return instance
end

function MapData:initWithData()
	-- 首次初始化数据已经移动到DataManager里的init方法里，请去那里加 by 杨杰
	
end


function MapData:getMap()
	-- body
	return self._mapData
end

function MapData:setMap(mapInfo)
	-- body
	-- remove(self._roleDada)
	self._mapData = mapInfo
end

function MapData:getMapData(mapDataID)
	-- body
	return self._mapData[mapDataID]
end

function MapData:setMapData(mapDataID, mapData)
	-- body
	self._mapData[mapDataID] = mapData
end






-- -- 初始化地图相关数据
-- function MapData:loadMapData(tableData)
-- 	-- body
-- 	self._mapData[roleMapFog] = {}
-- end


function MapData:loadData(mapindex)
	-- body
	local mapData = SaveDataManager:getInstance():loadData("gameMap"..mapindex)

	if (mapData ~= nil) then
		self._mapData = loadTableData(mapData)
		return true
	else
		self._mapData = {}
		return false
	end
end

function MapData:saveData(mapindex)
	-- body
	SaveDataManager:getInstance():SaveData(toLua(self._mapData), "gameMap"..mapindex)
end