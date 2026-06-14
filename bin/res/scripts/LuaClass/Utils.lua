-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function split(str, separator)
	local sub_str_tab = {};
	while (true) do
		local pos = string.find(str, separator)
		if (not pos) then
			sub_str_tab[#sub_str_tab + 1] = str
			break;
		end
		local sub_str = string.sub(str, 1, pos - 1)
		sub_str_tab[#sub_str_tab + 1] = sub_str
		str = string.sub(str, pos + 1, #str)
	end

	return sub_str_tab
end

function splitToMatrix(str, separator1, separator2)
	-- body
	-- print("splitToMatrix:", str, separator1, separator2)
	local matrix = {}
	while (true) do
		local pos = string.find(str, separator1)
		if (not pos) then
			matrix[#matrix + 1] = split(str, separator2)
			break;
		end
		local sub_str = string.sub(str, 1, pos - 1)
		matrix[#matrix + 1] = split(sub_str, separator2)
		str = string.sub(str, pos + 1, #str)
	end

	return matrix;
end


-- 增
function addTableData(tableData, key, value)
	-- body
	if (tableData ~= nil) then
		if (tableData[key] ~= nil) then
			tableData[key] = nil
		end
		tableData[key] = value
	end
end

-- 删
function remove(var)
	-- body
	if "table" == type(var) then
		for k,v in pairs(var) do
  			if "table" == type(v) then
  				remove(v)
  			end
  			var[k] = nil
		end
	else
		var = nil
	end
end

-- 改
function modify(src, dest)
	-- body
	remove(src)
	src = dest
end

-- 查
function find(tableData, key)
	-- body
	if (tableData ~= nil) then
		local vtype = type(key)  
  		if vtype == "string" then    
    		return tableData[key .. ""]
  		elseif vtype == "number" then
    		return tableData[key]	
  		end
	end
	return nil
end

function customTableToIKey(tableData)
	-- body
	local tabelVar = {}
	for k,v in pairs(tableData) do
  		tabelVar[#tabelVar + 1] = v
	end
	--table.sort(tabelVar)
	return tabelVar
end

function pairsByKeys(t)  
	local a = {}  
    for n in pairs(t) do  
        a[#a+1] = n  
	end  
	table.sort(a)  
	local i = 0  
	return function()  
		i = i + 1  
		return a[i], t[a[i]]  
	end  
end

function sortTableOrderByASC(tableData, key)
	-- body
	local ascTable = {}
	for k,v in pairs(tableData) do
		ascTable[#ascTable + 1] = v
	end

	local num = #ascTable

    local i = num
    local j = 1
    while i > 0 do  
        j = 1  
        while j < num do
        	local preData = tonumber(ascTable[j][key])
        	local nextData = tonumber(ascTable[j+1][key])
            if (preData > nextData) then  
                ascTable[j], ascTable[j+1] = ascTable[j+1], ascTable[j]  
            end  
            j = j + 1  
        end  
        i = i - 1  
    end
    
    return ascTable 
end

function changeTableDataByKey(tableData, key, value)
	-- body
	local data = tableData[key]
	if (data == nil) then
		remove(data)
	end
	tableData[key] = value
end

function appendObjectToTableI(tableData, obj)
	-- body
	tableData[#tableData + 1] = obj
end

function addObjetToTableAtIndexI(tableData, obj, index)
	-- body
	if (index > #tableData) then
		addObjectToTableI(tableData, index)
	else
		for i=#tableData,index,-1 do
			tableData[i + 1] = tableData[i]
		end
		tableData[index] = obj
	end
end

function removeObjectFromTableI(tableData, index)
	-- body
	if (index < #tableData) then
		local length = #tableData
		local data = tableData[index]
		for i=index,length-1,1 do
			tableData[i] = tableData[i + 1]
		end
		remove(data)
		local lastData = tableData[length]
		tableData[length] = nil
		remove(lastData)
	else
		local data = tableData[index]
		tableData[index] = nil
		remove(data)
	end
end

function removeObjectFromTableByIKeyStr(tableData, index)
	-- body
	local num = getTableRowNum(tableData)
	if (index < num) then
		local data = tableData[tostring(index)]
		for i=index,num-1,1 do
			tableData[tostring(i)] = tableData[tostring(i + 1)]
		end

		tableData[tostring(num)] = nil
	else
		tableData[tostring(index)] = nil
	end
	-- tableData[{}] = nil
end

function findObjectFromTableByIndexI(tableData, index)
	-- body
	return tableData[index]
end

function changeObjectFromTableByIndexI(tableData, index, obj)
	-- body
	local data = tableData[index]
	if (nil ~= data) then
		tableData[index] = obj
	else
		addObjectToTableI(tableData, obj)
	end
end

function removeObjectFromTableByKey(tableData, key)
	-- body
	if (tableData[key] ~= nil) then
		local data = tableData[key]
		tableData[key] = nil
		data = nil
		-- tableData[{}] = nil
	end
end

-- table减法
function tableSubtraction(minuendTable, subtrahendTable)
	-- body
	for k, v in pairs(subtrahendTable) do
		removeObjectFromTableByKey(key)
	end
end

-- table加法
function tableAddition(augendTable, addendTable)
	-- body
	for k, v in pairs(addendTable) do
		augendTable[k] = v
	end
end

function checkTableNumByKeyAndValue(tableData, key, value)
	-- body
	if (tableData[key] ~= nil) then
		local data = tableData[key]
		local numValue = 0
		if (type(data) == "string") then
			numValue = tonumber(data)
		elseif (type(data) == "number") then
			numValue = data
		end
		return (value >= numValue)
	end
	return false
end

function getPassedRowDataFromMatrixByKeyAndValue(tableData, key, value)
	-- body
	local arrData = {}
	for k,v in pairs(tableData) do
		if (nil ~= v) then
			if (checkTableNumByKeyAndValue(v, key, value)) then
				arrData[k] = v
			end
		end
	end
	return arrData
end

function checkTableNumByKeyAndValueTMore(tableData, key, value)
	-- body
	if (tableData[key] ~= nil) then
		local data = tableData[key]
		local numValue = 0
		if (type(data) == "string") then
			numValue = tonumber(data)
		elseif (type(data) == "number") then
			numValue = data
		end
		return (value <= numValue)
	end
	return false
end

function getPassedRowDataFromMatrixByKeyAndValueTMore(tableData, key, value)
	-- body
	local arrData = {}
	for k,v in pairs(tableData) do
		if (nil ~= v) then
			if (checkTableNumByKeyAndValueTMore(v, key, value)) then
				arrData[k] = v
			end
		end
	end
	return arrData
end

function getRowDataFromMatrixBySpecifiedKeyAndValue(tableData, key, arrValue)
	-- body
	if ((tableData == nil) or (key == nil) or (arrValue == nil)) then
		return {}
	end
	local arrData = {}
	local flag = false
	for k,v in pairs(tableData) do
		if (nil ~= v) then
			local data = v[key]
			if (data ~= nil) then
				if (checkValueInArr(data, arrValue)) then
					arrData[k] = v
					if (not flag) then
						flag = true
					end
				end
			end
		end
	end
	
	if (flag) then
		arrData[{}] = nil
		return arrData
	else
		return {}
	end
end

function checkValueInArr(value, arr)
	-- body
	for k,v in pairs(arr) do
		if (value == v) then
			return true
		end
	end
	return false
end

function isTableHaveKey(tableData, key)
	-- body
	if (tableData[key] == nil) then
		return false
	else
		return true
	end
end

function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end  -- if
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end  -- for
        return setmetatable(new_table, getmetatable(object))
    end  -- function _copy
    return _copy(object)
end  -- function deepcopy

function addColumnToMatrix(tableData, key, value)
	-- body
	for k,v in pairs(tableData) do
		v[key] = value
	end
end

function getTableRowNum(tableData)
	-- body
	local index = 0
	for k,v in pairs(tableData) do
		index = index + 1
	end
	return index
end

function tableToJson(t)
	local function serialize(tbl)
		local tmp = {}
		for k, v in pairs(tbl) do
			local k_type = type(k)
			local v_type = type(v)
			local key = (k_type == "string" and "\"" .. k .. "\":") or (k_type == "number" and k .. ":")
			local value = (v_type == "table" and serialize(v)) or (v_type == "boolean" and tostring(v)) or (v_type == "string" and "\"" .. v .. "\"") or (v_type == "number" and v)
                        tmp[#tmp + 1] = key and value and tostring(key) .. tostring(value) or nil
		end
		if table.maxn(tbl) == 0 then
			return "{" .. table.concat(tmp, ",") .. "}"
		else
			return "[" .. table.concat(tmp, ",") .. "]"
		end
	end
	assert(type(t) == "table")
	return serialize(t)
end

-- 判断一个table是否为空表{}
function is_table_empty(t)
    assert(type(t) == "table")
    return _G.next(t) == nil
end

-- 获取系统毫秒时间
function getSystemTimeMilliSecond()
    require "socket"
    return socket.gettime()
end

function getNumber(var)
	-- body
	local varType = type(var)
	if (varType == "string") then
		return tonumber(var)
	elseif (varType == "number") then
		return var
	end
end

function toLua(v, ea, wrapStringKey, handleArrayIndex)
  if(wrapStringKey == nil) then
    wrapStringKey = true;
  end
  if(ea == nil)then
    ea = "=";
  end
  local t = type(v)
  if(t=="number") then
    return string.format (math.ceil(v)==v and "%d" or "%.16f", v)
  elseif(t=="boolean") then
    return tostring(v)
  elseif(t=="string") then
    return string.format("%q",v)
  elseif(t=="table") then
    if type(t.tostring) == "function" then
      return t:tostring()
    elseif handleArrayIndex and lengthCkeck(v) then
      return dumpArray(v,ea,wrapStringKey, handleArrayIndex)
    else
      return dumpData(v,ea,wrapStringKey, handleArrayIndex)
    end
  elseif(t=="nil") then
    return "nil"
  else
    error("can not serialize a " .. t .. " type.")
  end
end

function _loadstring(...)
  return loadstring(...);
end

function loadTableData(s)
  if s == "nil" or s == "" then
    return nil
  else
    local newgt = {loadstring = loadstring};
    setfenv(_loadstring, newgt) -- 防止函数调用和数据获取
    return _loadstring("local tmp = " .. s .. "; return tmp")()
  end
end

function lengthCkeck(t)
  local total = 0
  for i,v in pairs(t) do
    if i == total + 1 then
      total = i
    else
       return false
    end
  end
  if total == 0 then return false; end
  return total == #t
end

function dumpArray(v,ea,wrapStringKey, handleArrayIndex)
  local ret = "[";
  local length = #v;
  for i,value in ipairs(v) do
    ret = ret .. toLua(value,ea,wrapStringKey, handleArrayIndex)
    if i~=length then ret = ret .. "," end
  end
  ret = ret .. "]"
  return ret;
end

function dumpData(ori_tab,ea,wrapStringKey, handleArrayIndex)
  if(ea == nil)then
    ea = "=";
  end
  local retStr = "{";
  for i,v in pairs(ori_tab) do
    local vtype = type(v);
    local itype = type(i);
    if(checkValueDataType(vtype) and checkIndexDataType(itype)) then
      if( wrapStringKey == true ) then
        retStr = retStr .. "[" .. toLua(i,ea,wrapStringKey) .. "]" .. ea .. toLua(v,ea,wrapStringKey) .. ","
      else
        local key = toLua(i,ea,wrapStringKey)
        if type(key) == "number" then key = "\""..key.."\"" end
        retStr = retStr .. key .. ea .. toLua(v,ea,wrapStringKey, handleArrayIndex) .. ","
      end
    end
  end
  if(#retStr > 1)then
    return retStr:sub(1,-2) .. "}";
  else
    return retStr .. "}";
  end
end

function checkValueDataType(t)
  if(t=="thread" or t=="userdata" or t=="function") then
    return false
  else
    return true
  end
end

function checkIndexDataType(t)
  if(t=="thread" or t=="userdata" or t=="function" or t == "table") then
    return false
  else
    return true
  end
end

function changeTableForKeyFromStringToNumber(tableData)
	-- body
	for k,v in pairs(tableData) do
		tableData[tonumber(k)] = v
		-- tableData[k] = nil
	end
end

function getTimeStr(time)
	-- body
	local str = ""
	local day = math.floor(time / 86400)
	local temp = 0
	if (day >= 1) then
		temp = time - day * 86400

		local hour = math.ceil(temp / 3600)
		return day .. "天" .. hour .. "小时"
	else
		local hour = math.floor(time / 3600)
		if (hour < 10) then
			str = str .. "0" .. hour
		else
			str = str .. hour
		end

		str = str .. ":"

		temp = time - hour * 3600

		local minute = math.floor(temp / 60)
		if (minute < 10) then
			str = str .. "0" .. minute
		else
			str = str .. minute
		end

		str = str .. ":"

		temp = temp - minute * 60

		-- local second = temp
		local second = math.ceil(temp)
		if (second < 10) then
			str = str .. "0" .. second
		else
			str = str .. second
		end

		return str
	end
end

------------------------封装PopTip方法---------------------------
function showPopTips(tips)
    local vsSize = cc.Director:getInstance():getVisibleSize()
    local node = cc.Node:create()
    node:setPosition(cc.p(vsSize.width*0.5, vsSize.height*0.5))
    local gameScene = cc.Director:getInstance():getRunningScene()
    if gameScene ~= nil then
        gameScene:addChild(node, 100001)
    end
    
    -- 添加提示文本
    local label = cc.LabelTTF:create(tips, BoldFont, 22);
    label:setOpacity(200)
    label:setPosition(ccp(0, 0))
    label:setColor(WriteColor)
    -- label:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    node:addChild(label)
    
    -- 播放移动动画
    local move = cc.MoveBy:create(1.2, cc.p(0, 96))
    local labelFadeIn = cc.FadeIn:create(0.1)
    local labelFadeOut = cc.FadeOut:create(1.1)
    local callfuncN = cc.CallFunc:create(function()
        node:removeFromParent(true)
    end)
    
    node:runAction(cc.Sequence:create(move, cc.DelayTime:create(0.35)))
    label:runAction(cc.Sequence:create(labelFadeIn, labelFadeOut, cc.DelayTime:create(0.35), callfuncN))
end

------------------------封装print方法---------------------------
function table.size(tab)
	local size = 0
	for k in pairs(tab) do
		size = size + 1
	end
	return size
end

local _print = print
function printn(...)

	local function getKey(key, level)
		if type(key) == "number" then
			key = ('  '):rep(level).. ("[%d]"):format(key)
        elseif type(key) == "string" then
			key = ('  '):rep(level).. ("[%q]"):format(key)
        else
			key = ('  '):rep(level).. ("[%s]"):format(tostring(key))
		end
		return key
	end

	local function getValue(value)
		if type(value) == "number" then
			value = ("%d"):format(value)
        elseif type(value) == "string" then
            value = ("%q"):format(value)
        else
			value = ("%s"):format(tostring(value))
		end
		return value
	end

	local print_t = {} -- 记录打印过的table
    local function getTable(tab, level)
        local tabstr = ("{ --%s\n"):format(tostring(tab))
		local index = 0
		local size = table.size(tab)
		print_t[tab] = true
        for key, value in pairs(tab) do
			index = index + 1
			key = getKey(key, level)
            if type(value) == "table" then
				if print_t[value] then
					tabstr = tabstr .. key .. (" : ref%q"):format(tostring(value))
				else
					tabstr = tabstr .. key .. " : " .. getTable(value, level+1)
				end
            else
				tabstr = tabstr .. key .. " : " .. getValue(value)
            end
            tabstr = tabstr .. (index==size and "\n" or ",\n")
        end
        tabstr = tabstr .. ('  '):rep(level-1) .. "}"
        return tabstr
    end

    local function dumpArgs(...)
		local buffer = ""
		local size = select('#', ...)
        for ii=1, select('#', ...) do
			local args = select(ii, ...)
			local ends = ii==size and "" or ",\n"
            if type(args) == "table" then
				local temp = ("[%s] = "):format(tostring(args))
                buffer = buffer .. temp .. getTable(args, 1) .. ends
            elseif type(args) == "userdata" then
				local temp = ("[%s] = "):format(tostring(args))
				buffer = buffer .. getValue(args) .. ends
            else
				buffer = buffer .. getValue(args) .. ends
            end
        end
		_print(buffer)
        
		----------------释放print_t-------------------
		print_t = nil
        buffer = nil
    end

    dumpArgs(...)
end

--print = printn