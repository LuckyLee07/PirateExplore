require "LuaClass/Header"
require "LuaClass/V2Config"


SaveDataManagerSingleton = nil

SaveDataManager = class("SaveDataManager", function ()
    return cc.Node:create()
end)
SaveDataManager.__index = SaveDataManager

function SaveDataManager:getInstance( )
	if SaveDataManagerSingleton == nil then
		SaveDataManagerSingleton = SaveDataManager.new()
		SaveDataManagerSingleton:retain()
	end
return SaveDataManagerSingleton
end

function SaveDataManager:resolveFileName(fileName)
	local resolvedName = V2Config:scopedSaveName(fileName)
	if zqUserId ~= nil then
		resolvedName = resolvedName .. "_" .. zqUserId
	end
	return resolvedName
end

function SaveDataManager:SaveData(Date,FileName)
	-- cclog("SaveDataManager:SaveData=======",Date)
	FileName = self:resolveFileName(FileName)
	Record:GetInstance():saveData(Date,FileName)
end

function SaveDataManager:loadData(FileName)
	-- cclog("SaveDataManager:loadData======")
	FileName = self:resolveFileName(FileName)
	local content = Record:GetInstance():loadData(FileName)
	return content
end

--[[
因为暂时没用到下边这两个函数，所以就不处理多用户存档问题了，需要的时候请加上 by 杨杰
]]
function SaveDataManager:deleteFile( FileName )
	FileName = self:resolveFileName(FileName)
	local _type = Record:GetInstance():deletBuf(FileName)
	return _type
end

function SaveDataManager:WriteData(path,fileName,buf )
	local _type = Record:GetInstance():writeData(path,fileName,buf)
	return _type
end

function SaveDataManager:loadRecourcesCSV(FileName)
	Record:GetInstance():loadRecourcesCSV(FileName)
end
