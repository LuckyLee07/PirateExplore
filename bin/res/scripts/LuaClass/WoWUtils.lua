--[[
系统常用变量定义开始
add by yangjie
]]
---[[ 常用颜色
opColorBlue1 = cc.c3b(80, 200, 254)				-- 蓝色(选服蓝色)
opColorRed = cc.c3b(255, 0, 0)				-- 红色
opColorGreen = cc.c3b(6, 251, 3)					-- 绿色
opColorPrimroseYellow = cc.c3b(234, 229, 199)		-- 淡黄色
opColorSaffronYellow = cc.c3b(248, 159, 79)			-- 橘黄色
opColorBlue2 = cc.c3b(138, 218, 219)				-- 蓝色（总实力蓝色）
opColorCoffee = cc.c3b(29, 0, 0)					-- 咖啡色
opNotOpenColor = cc.c3b(193, 189, 182)				-- 置灰 无法使用、开启等颜色
--]]
---[[ 常用字体
BoldFont = "Arial-BoldMT"
--]]
---[[ 常用zOrder宏
ZQ_MAX = 2147483647 - 5
--]]

--屏幕的大小
screenSize = cc.Director:getInstance():getVisibleSize()

-- cjson = require "cjson"
-- zqDataManage = ZQDataManage:SharedZQDataManage()

--获得当前屏幕中心点相对于某个节点的位置
function getRelativePositionOfViewCenterByNode( target )


    --获得世界坐标
    local viewCenterPosition = cc.p(screenSize.width / 2,screenSize.height / 2)

    --获取相对坐标
    viewCenterPosition = target:convertToNodeSpace(viewCenterPosition)

    return viewCenterPosition
end

function getRandomNumByRange( rang )
    local max = rang.max
    local min = rang.min
    local dis = max - min

    math.randomseed(tostring(os.time()):reverse():sub(1, 6))

    local randomNum = math.random() * 100000

    randomNum = randomNum % (dis + 1)

    randomNum = min + randomNum

    print("getRandomNumByRange",max,min,randomNum)

    randomNum = math.floor(randomNum)

    return randomNum
end

function shift( num,digits )
    
    local result = num

    result = result * 2^digits


    if digits < 0 then
        result = math.floor(result)
    end
    -- print("result",result)
    if result - 0.5 > math.floor(result) then
        result = math.ceil(result)
    else
        result = math.floor(result)
    end

    -- print("shift",result,2^digits,digits)

    return result
end

--只读table
function read_only( read_only_table )
    if read_only_table == nil or type(read_only_table) ~= "table" then
        return
    end

    -- if read_only_table == dataController then
    --     return
    -- end

    -- local s ={}

    -- for k,v in pairs(read_only_table) do
    --  s[k] = v
    -- end

    local proxy = {}
    local mt = {
    __index = read_only_table,
    __newindex = function ( t,k,v )
        print("ERROR: you try update of element",tostring(k).."to"..tostring(v)..",but it is a read-only table")
    end
    }

    setmetatable(proxy,mt)
    
    return proxy
end

--可跟踪数量的table
function getCustomTable(  )
    local customTable = {}
    customTable.datas = {} -- for the 
    local value_table = {}
    value_table.len = 0
    value_table.keys = {}

    local mt = {
        __index = function ( t,k )
            print("customTable search By Key",k)

            if k == "keys" then
                return value_table.keys
            end

            --若整数，默认是索引,返回对应索引的key值
            if type(k) == "number" then
                k = value_table.keys[k]
            end

            return value_table[k]
        end,
        __newindex = function ( t,k,v )

            local index =  nil

            if type(k) == "number" then
                index = k
                k = value_table.keys[k]
            end

            --只支持用字符串key的形式添加元素,只支持删除和修改
            if not k then 
                print("ERROR: you try update a element of Nil key ")
                return 
            end


            if value_table[k] == nil then
                value_table.len = value_table.len + 1
                
                value_table.keys[#value_table.keys + 1] = k

                index = #value_table.keys
            end

            value_table[k] = v

            if not index then
                for i=1,#value_table.keys do
                    if k == value_table.keys[i] then
                        index = i
                    end
                end
            end

            customTable.datas[#value_table.keys] = v

            --nil默认为删除操作
            if not v then
                -- --若不是数字，则需要找到对应key的索引
                -- if type(k) ~= "number" then
                --     for i=1,value_table.len do
                        
                --         if k == value_table.keys[i] then
                --             k = i
                --             break
                --         end
                --     end
                -- end

                --根据索引删除元素
                table.remove(value_table.keys,index)
                table.remove(customTable.datas,index)
                value_table.len = value_table.len - 1
            end

    end,
    __add = function ( table1,table2 )
        
        print("getCustomTableAdd")

    end,
     __mul = function ( table1,table2 )
        print("getCustomTableAdd")
    end
    }
    setmetatable(customTable,mt)

    return customTable
end

function function_name( ... )
    -- body
end

--上面customtable的用咧
--[[
    
    local testT = getCustomTable()
    testT["12123"] = 2
    testT._dsfsg = 3
    testT["fasdfasdf"] =3
    testT[2] = 45
    print(testT["12123"],testT._dsfsg)
    print(testT[1],testT[2])
    (以上两种查询是一样的)
    testT.len(长度)

]]

function safeFree( variable )
    
    if variable == nil then
        return
    end

    variable = nil
end

function check2dxLuaApi( _2dxLuaType )
    
    print("check2dxLuaApi")

    if type(_2dxLuaType) ~= "table" then
        print("ERROR: _2dxLuaType is not table and please checked")
        return
    end

    print("the api is :")

    for k,v in pairs(_2dxLuaType) do
        print(k,v)
    end

end

--凡事用loadingstring的都不行,效率太低！后期优化
function setValueToSetTableByCustomKey( table, key , value )

    local keynum = tonumber(key)

    if keynum ~= nil and tostring(keynum) == key  then
        table[key] = value
        return
    end

    gTable = table
    gValue = value
    local dostring = string.format("gTable.%s = gValue",key)
    --万恶的loadingstring只能引用global变量
    assert(loadstring(dostring))()



    -- print("setValueToSetTableByCustomKey",dostring)

    table = nil 
    table = gTable
    gTable = nil
    gValue = nil



end

function getValueFromSetTableByCustomKey( table,key )

    local keynum = tonumber(key)

    if keynum ~= nil and tostring(keynum) == key  then
        return table[key]
    end

    gTable = table
    gValue = nil
    local dostring = string.format("gValue = gTable.%s",key)
    assert(loadstring(dostring))()
    -- print("dostring",dostring,gValue,gValue)
    gTable = nil

    return gValue
end


function split(fullString, separator)
    local findIndex = 1
    local splitIndex = 1
    local array = {}
    while true do
        if fullString == nil then
            break
        end

        local lastIndex = string.find(fullString, separator, findIndex)
        if not lastIndex then
            array[splitIndex] = string.sub(fullString, findIndex, string.len(fullString))
            break
        end
        array[splitIndex] = string.sub(fullString, findIndex, lastIndex - 1)
        findIndex = lastIndex + string.len(separator)
        splitIndex = splitIndex + 1
    end
    local x = 1
    return array
end

-- function getArrString( fullString )
--     -- body
-- end

-- function split( ... )
    
--     local args = {...}

--     --获得目标字符串
--     local targets = args[1]
    
--     local temp = nil

--     local cur_sep = nil

--     local result = nil

--     for i=2,#args do
--         local cur_sep = args[i]
        
--         if result == nil then
--             result = split(targets,cur_sep)
--         else 

--             for k,v in pairs(result) do
                
--                 while()

--             end

--         end     
--     end

-- end

function timeTransformationFromSeconds( seconds,format )
     if type(format) == "nil" then
        format = "%Y-%m-%d %H:%M:%S"
    end

    local dayStr = os.date(format, seconds)
    return dayStr
end

-- function costConsumablesByTypeStr( typeStr,num )
        
--     if typeStr == "DIAMOND" then 
--         zqDataManage:addDiamond(num * -1)
--     end
-- end

function costOrAddGoodsByConsumables( consumables,add )
    
    print("costGoodsByConsumables")
    checkeTable(consumables,true)
    if consumables == nil or consumables.economy == nil then
        return
    end

    local key_num = -1

    if type(add) ~= "nil" then
        key_num = 1
    end

    local money = consumables.economy.money
    local diamond = consumables.economy.diamond
    local pop = consumables.economy.pop
    local coin = consumables.economy.coin
    local mopTicketCount = 0

    for i,k in pairs(consumables.itemList) do
        local dataid = k.dataid
        local num = k.num
        if dataid == 3018 then
            mopTicketCount = mopTicketCount + num
        end
    end

    print("处理的数据为:",diamond,money,pop,mopTicketCount,key_num)

    -- --删除从掉落数组中获取的消耗物
    -- zqDataManage:addDiamond( key_num * diamond )
    -- zqDataManage:addCoin( key_num * money )
    -- zqDataManage:addReputation( key_num * pop )
    -- zqDataManage:addMopTicketCount( key_num * mopTicketCount )
end

function timeTransformationFromMillisecond( ms ,format)
    local seconds = ms / 1000
    local dayStr = timeTransformationFromSeconds(seconds,format)
    return dayStr
end

function getFillNeatNumberString( number,neatStr,maxFillNum)
        if neatStr == nil then
            neatStr = "0"
        end

        if maxFillNum == nil then 
            maxFillNum = 10
        end

        local fillStr = nil
        if number < maxFillNum and number > 0 then
            fillStr = neatStr..number
        else
            fillStr = string.format("%d",number)
        end
    return fillStr
end

function getDay( seconds )
    local dayStr = timeTransformationFromSeconds(seconds,"%d")
    -- print("天%s",dayStr)
    local day = tonumber(dayStr)
    -- print(day)
    dayStr = getFillNeatNumberString(day).."天"
    return dayStr
end

function getHours( seconds )
    local hoursStr = timeTransformationFromSeconds(seconds,"%H")
        -- print("时%s",hoursStr)
    local hours = tonumber(hoursStr)
    -- print(hours)
    hours = hours % 24
    hoursStr = getFillNeatNumberString(hours).."时"
    return hoursStr
end


function getMinutes( seconds )
    local minutesStr = timeTransformationFromSeconds(seconds,"%M")
        -- print("分%s",minutesStr)
    local minutes = tonumber(minutesStr)
    -- print(minutes)
    minutes = minutes % 24 % 60
    minutesStr = getFillNeatNumberString(minutes).."分"
    return minutesStr
end


--cjson解析结构变成array/dict
function numIsInteger( num )

    if type(num) ~= "number" then
        return
    end

    if num == math.ceil(num) then 
        return true
    end
    return false
end

function checkeTable( table ,checkdata)
    
    if type(table) ~= "table" then
        print("ERROR TYPE :",type(table))
        return false
    end

    if checkdata ~= nil then
        for i,k in pairs(table) do
        print(i,k)
        end
    end
     print("表验证完毕")

    return true
end
--判断是普通表，还是map结构的表
function checkeIsRegularTables( table )
    
    if checkeTable(table) == false then
        return false
    end

    local len = #table
    local count = 0

    for i,k in pairs(table) do
        count = count + 1
    end

    if len == count then
        return true
    end
    return false;
end

--获得两点之间的弧度，point1为圆心,point为圆边上的某一点，算出对应弧度,结果为逆时针走向的角度
function getRadianBetweenTwoPoints( point1,point2)

    --斜边
    local hypotenuse = math.sqrt(math.pow((point1.x - point2.x),2) + math.pow((point1.y - point2.y),2))

    -- print("hypotenuse",hypotenuse)

    local sin_value = (point1.y - point2.y) / hypotenuse

    local cos_value = (point1.x - point2.x) / hypotenuse

    local radian = math.deg(math.asin(sin_value))

    if radian > 0 then
        if cos_value < 0 then 
            radian = 180 - radian
        end
    elseif radian < 0 then
        if cos_value > 0 then
            radian = radian + 360
        elseif cos_value < 0 then
            radian = 180 - radian
        end
    end

    return radian
end

-- function getJsonData(_cmdId)
--     -- 初始卡牌json数据
--     local tablePost ={}
--     tablePost["cmdid"] = _cmdId
--     tablePost["version"] = zqDataManage:getMainVersion()
--     tablePost["ssid"] = zqDataManage:getSession()
--     tablePost["roleid"] = zqDataManage:getplayerID()
--     -- json 编码
--     local jsonData = cjson.encode(tablePost)
--     print(jsonData)
--     -- 拼接为本地协议
--     local jsonDataAll = "header="..jsonData.."&body={}"
--     print(jsonDataAll)

--     return jsonDataAll
-- end

--  --[[ 获取json数据，有body
--     ]]
-- function getJsonData2(_cmdId,_tableBody)
--         -- 初始卡牌json数据
--         local tablePost = {}
--         tablePost["cmdid"] = _cmdId
--         tablePost["version"] = zqDataManage:getMainVersion()
--         tablePost["ssid"] = zqDataManage:getSession()
--         tablePost["roleid"] = zqDataManage:getplayerID()
--         -- json 编码
--         local jsonData = cjson.encode(tablePost)
--         print(jsonData)

--         -- local tableBody = {}
--      --    tableBody["position"] = 1
--         -- json 编码
--         local jsonBody = cjson.encode(_tableBody)
--         print("jsonbody",jsonBody)

--         -- 拼接为本地协议
--         local jsonDataAll = "header="..jsonData.."&body="..jsonBody
--         print("json2",jsonDataAll)

--         return jsonDataAll
--     end

-- function registeredRecursiver( target,func )
    
--     if target == nil or type(func) ~= "function" then
--         return falseend
--     

--     target = func

--     return true

-- end

getArrFromCustomTable = nil
getDicFromCustomTable = nil
getEleFromMapTableByNameAndKey = nil

getEleFromMapTableByNameAndKey = function ( table_name, key,ele_name)
    
    if type(key) == "nil" or type(table_name) ~= "string" or type(ele_name) ~= "string"  then 
        return
    end

    local key_script = nil
    if type(key) == "number" then
        key_script = string.format("%d",key)
    elseif type(type) == "string" then
        key_script = key
    else
        key_script = ""
    end

    local ele_script = string.format("local %s = nil; %s = %s.%s",ele_name,ele_name,table_name,key_script)
    print("ele_script:",ele_script)
    return ele_script
end

--添加监听者方法
function addListener( table )
    
    if not checkeTable(table) then
        return
    end

    print("开始添加监听者")

    --设置原表的私有入口
    local entrance = table

    --将原表对象设置为其代理者，限制其直接访问
    table = {}

    --设置新的查询和更改方法
    local mt = {
        __index = function ( t,k )
            do
            print("试图查找表中的数据为:",tostring(k))
            return entrance[k]
            end
        end,
        __newindex = function ( t,k,v )
            print("试图更改"..tostring(k).."到"..tostring(v))
            entrance[k] = v
        end
    }

    --将新的查询和更改方法插入到table中
    setmetatable(table,mt)

    return table
end

getArrFromCustomTable = function ( table )
    
    if type(table) ~= "table" then
        return nil
    end

    print("开始解析set表数据")

    local tempArr = CCArray:create()
    --tempArr:retain()
    local temEle = nil
    local k = nil

    for i=1,#table do
        
        k = table[i]
        
        if type(k) == "number" then
            if numIsInteger(k) then
             temEle = CCInteger:create(k)
            else
                temEle = CCString:create(string.format("%f",k))
            end
            tempArr:addObject(temEle)
        elseif type(k) == "string" then
            temEle = CCString:create(k)
            tempArr:addObject(temEle)
        elseif type(k) == "boolean" then
            if k then
                temEle = CCInteger:create(1)
            else 
                temEle = CCInteger:create(0)
            end
            tempArr:addObject(temEle)
        elseif type(k) == "table" then
            if checkeIsRegularTables(k) then
                temEle = getArrFromCustomTable(k)
                tempArr:addObject(temEle)
            else
                temEle = getDicFromCustomTable(k)
                tempArr:addObject(temEle)
            end
        end
    end

    return tempArr
end

getDicFromCustomTable = function ( table )
    
    if checkeTable(table) == false then
        return nil
    end

    local tempDic = CCDictionary:create()
    --tempDic:retain()
    local temEle = nil

    print("开始获取map表中的数据!")

    for i,k in pairs(table) do
        --print("key======: ", i, type(k))
        if type(k) == "number"  then
            if numIsInteger(k) then
             temEle = CCInteger:create(k)
            else
                temEle = CCString:create(string.format("%f",k))
            end
            tempDic:setObject(temEle,i)
        elseif type(k) == "string" then
            temEle = CCString:create(k)
            tempDic:setObject(temEle,i)
        elseif type(k) == "boolean" then
            if k then
                temEle = CCInteger:create(1)
            else 
                temEle = CCInteger:create(0)
            end
            tempDic:setObject(temEle,i)
        elseif type(k) == "table" then
            if checkeIsRegularTables(k) then
                temEle = getArrFromCustomTable(k)
                tempDic:setObject(temEle,i)
            else
                temEle = getDicFromCustomTable(k)
                tempDic:setObject(temEle,i)
            end
        end
        -- print(i,type(i))--i 为对应的索引
    end

    return tempDic
end

---------------------box------------------------
local boxOnTouch = function(touchType, x, y)
    if touchType == "began" then
        return true
    end
end

function showBoxWithInfo( tInfo )
    local layer = CCLayer:create()
    layer:registerScriptTouchHandler(boxOnTouch, false, kCCMenuHandlerPriority, true)
    
    local colorLayer = CCLayerColor:create(cc.c4b(0, 0, 0, 128), screenSize.width, screenSize.height)
    colorLayer:setPosition(cc.p(-screenSize.width*0.5, -screenSize.height*0.5))
    layer:addChild(colorLayer)
    
    local boxSize = CCSizeMake(345, 210)
    local fontName = "Arial-BoldMT"
    
    local bgNode = createBgBox(boxSize, true, BgBoxBgTypeBrownImage, false)
    bgNode:setPosition(cc.p(0, 0))
    layer:addChild(bgNode)
    
    local label = CCLabelTTF:create(tInfo.text, fontName, 22, CCSizeMake(boxSize.width*0.8, 0), kCCTextAlignmentCenter)
    label:setColor(opColorPrimroseYellow)
    bgNode:addChild(label)
    label:setPosition(cc.p(0, 35))
    
    local pkPosX = boxSize.width*0.25
    local pkPosY = boxSize.height*0.25
    
    local array = CCArray:create()
    local normalBtn = "hd/PublicImg/button/a_4_button_0.png"
    local highlightBtn = "hd/PublicImg/button/a_4_button_1.png"
    
    -- cancel button
    local cancelBtn = CCMenuItemImage:create(normalBtn, highlightBtn)
    cancelBtn:setPosition(cc.p(-pkPosX, -pkPosY))
    cancelBtn:registerScriptTapHandler(tInfo.callCancel)
    array:addObject(cancelBtn)
    
    local btn1Des = CCLabelBMFont:create("取消", "fnt/login.fnt")
    btn1Des:setScale(0.6)
    --btn1Des:setColor(ccc3(255, 235, 205))
    btn1Des:setPosition(cc.p(cancelBtn:getContentSize().width*0.5, cancelBtn:getContentSize().height*0.5))
    cancelBtn:addChild(btn1Des)
    
    -- sure button
    local sureBtn = CCMenuItemImage:create(normalBtn, highlightBtn)
    sureBtn:setPosition(cc.p(pkPosX, -pkPosY))
    sureBtn:registerScriptTapHandler(tInfo.callSure)
    array:addObject(sureBtn)
    
    local btn2Des = CCLabelBMFont:create("确定", "fnt/login.fnt")
    btn2Des:setScale(0.6)
    btn2Des:setColor(ccc3(255, 235, 205))
    btn2Des:setPosition(cc.p(sureBtn:getContentSize().width*0.5, sureBtn:getContentSize().height*0.5))
    sureBtn:addChild(btn2Des)
    
    local pkMenu = CCMenu:createWithArray(array)
    pkMenu:setPosition(cc.p(0, 0))
    pkMenu:setHandlerPriority(kCCMenuHandlerPriority)
    bgNode:addChild(pkMenu)
    
    layer:setTouchEnabled(true)
    layer:setPosition(cc.p(screenSize.width*0.5, screenSize.height*0.5))
    
    ZQDispatcher:SharedZQDispatcher():addChild(layer, 100, 9999)
end
---------------------box------------------------

---------------------global data------------------------
_global_canPk = nil
_global_showItem = _global_showItem
_global_donePass = _global_donePass
---------------------global data------------------------

---------------------get ccc3 from string like:{#FFFFFF}------------------------
function getColorValue(rgbStr)
    local color = nil
    if type(rgbStr) == "string" and string.len(rgbStr) == 6 then
        local rs = rgbStr:sub(1, 2)
        local gs = rgbStr:sub(3, 4)
        local bs = rgbStr:sub(5, 6)
        local rv = rs and tonumber(rs, 16) or 0
        local gv = gs and tonumber(gs, 16) or 0
        local bv = bs and tonumber(bs, 16) or 0
        color = ccc3(rv, gv, bv)
    end

    if color == nil then 
        color = opColorPrimroseYellow
    end
    
    return color
end

function getTextAndColor(text)
    local nText = nil
    local nColor = nil
    local strC = string.match(text, "{#%w+}")
    if strC then
        nText = string.gsub(text, strC, "")
        nColor = getColorValue(strC:sub(3, -2))
    end
    return nText, nColor
end
---------------------get ccc3 from string like:{#FFFFFF}------------------------
