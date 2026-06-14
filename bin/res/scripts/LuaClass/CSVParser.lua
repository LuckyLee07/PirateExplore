require "LuaClass/Header"
require "LuaClass/Utils"

CSVParserSingleton = nil

CSVParser = class("CSVParser", function ()
	return cc.Node:create()
end)

CSVParser.__index = CSVParser

function CSVParser:getInstance()
	if CSVParserSingleton == nil then
		CSVParserSingleton = CSVParser.new()
		CSVParserSingleton:retain()
	end
	return CSVParserSingleton
end

function CSVParser:loadFileByName(fileName)
	local fileUtils = cc.FileUtils:getInstance()
	-- 从文件里直接读取数据
	-- local fileData = fileUtils:getStringFromFile(fileName)
	-- 从加密文件中读取数据
	local fileData = Record:GetInstance():loadDataFromPackage(fileName)
	-- print("表：", fileName, fileData)
	local dataTable = split(fileData, "\n")

	return self:customizationTable(dataTable)
end

function CSVParser:loadCSVFileByString(fileData)
    local dataTable = split(fileData, "\n")
    return self:customizationTable(dataTable)
end

function CSVParser:test()
	--print("======== test")
end

-- table 定制处理
function CSVParser:customizationTable(tabelData)
	local length = #tabelData
	if (length > 0) then
		local alls = {}

		local keyArr = split(tabelData[2], ",")
		local col = #keyArr
		for i = 3, length - 1, 1 do
			local row = split(tabelData[i], ",")
			local data = {}
			for j = 2, col, 1 do
				data[keyArr[j] .. ""] = row[j]
			end

			alls[row[2] .. ""] = data

		end
		return alls
	end
	return nil
end
