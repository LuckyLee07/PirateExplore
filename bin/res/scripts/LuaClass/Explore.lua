require "LuaClass/Header"
require "LuaClass/ExploreDataManager"
require "LuaClass/Jointed"
require "LuaClass/EventManger"
require "LuaClass/FogManager"
require "LuaClass/MapLayoutManagers"
require "LuaClass/DataController"
require "LuaClass/FightDataManager"
require "LuaClass/ExploreBagController"
require "LuaClass/TransformLayer"
require "LuaClass/SDButton"
require "LuaClass/GuideController"
require "LuaClass/ExploreGuideComponent"
require "LuaClass/RandomEventMode"
require "LuaClass/SkirmishLogicManagers"


playerOrderLevel = 5
eventOrderLevel = 10
topButtonOrderLevel = 12

mapMoveType = {}
mapMoveType.all = 1
mapMoveType.playerMove = 2
mapMoveType.moveAction = 3

local curMapDatas = nil

local curExplor = nil

local moveTime = 3
local locationTime = 0.3

function getExplor(  )
	return curExplor
end


function getChineseCharactersByNum( num )
	
	local chineseCharacters = nil

	if num == 1 then
		chineseCharacters = "一"
	elseif num == 2 then
		chineseCharacters = "二"
	elseif num == 3 then 
		chineseCharacters = "三"
	elseif num == 4 then
		chineseCharacters = "四"
	elseif num == 5 then
		chineseCharacters = "五"
	elseif num == 6 then 
		chineseCharacters = "六"
	elseif num == 7 then 
		chineseCharacters = "七"
	elseif num == 8 then
		chineseCharacters = "八"
	elseif num == 9 then
		chineseCharacters = "九"
	elseif num == 10 then
		chineseCharacters = "十"
	elseif num == 11 then
		chineseCharacters = "十一"
	elseif num == 12 then
		chineseCharacters = "十二"
	elseif num == 13 then
		chineseCharacters = "十三"
	elseif num == 14 then 
		chineseCharacters = "十四"
	elseif num == 15 then
		chineseCharacters = "十五"
	elseif num == 16 then
		chineseCharacters = "十六"
	end

	return chineseCharacters
end

function getCurMapDatas( )
	return curMapDatas
end

function getDistance( point1,point2 )
	local distance = math.sqrt(math.pow(point1.x - point2.x, 2) + math.pow(point1.y - point2.y, 2))
	return distance
end

function getMidPoint( point1,point2 )
	local midPoint = cc.p((point1.x + point2.x) / 2,(point1.y + point2.y) / 2)

	return midPoint
end

function judgeAValueIsInTable( table,value )
	
	local index = -1

	for k,v in pairs(table) do
		
		if v == value then
			index = k
			break
		end
	end

	return index
end

function ccpSub( point1 , point2 )
	local result = cc.p(0,0)
	result.x = point1.x - point2.x
	result.y = point1.y - point2.y

	return result
end

local addVision = 0
local breadCoefficient = 0

--添加天赋信息
function addTalentProperties(  )
	--解开所有天赋
	-- for i=2001,2032 do
		-- print("unlockTallentByKey,key is : ",i)
	-- 	DataManager:getInstance():unlockTallentByKey(tostring(i))
	-- end

	-- print("addTalentProperties")
	--解锁天赋
	-- DataManager:getInstance():unlockTallentByKey("2003")
	-- DataManager:getInstance():unlockTallentByKey("2004")
	local bounds = DataManager:getInstance():getRoleData(roleBonusAttribute)

	if bounds == nil then
		return
	end

	local fightBonusAttribute = FightBonusAttribute.new()

	-- printn(bounds)
	local tempBounds = nil
	local tipstring = nil
	breadCoefficient = 0
	addVision = 0
	-- local powerCoefficient = 0.0
	-- local hpCoefficient = 0.0
	-- local speedCoefficient = 0.0
	-- local attCoefficient = 0.0
	-- local hitsCoefficient = 0.0
	-- local dodgeCoefficient = 0.0
	-- local damageReductionCoefficient = 0.0
	for i=1,#bounds do
		-- print("bounds_",i)
		tempBounds = bounds[i]
		--1威力，2生命，3速度，4伤害，5侦查范围，6给养消耗，7命中，8闪避，9战斗开始时所有角色已经准备就绪，10减少所受伤害
		for k,v in pairs(tempBounds) do
			-- print(k,v,type(k),v["1"],v["2"])
			if k == "1" then
				fightBonusAttribute.power = fightBonusAttribute.power + tonumber(v["1"])
				fightBonusAttribute.powerCoefficient = fightBonusAttribute.powerCoefficient + tonumber(v["2"])
				tipstring = string.format("威力加成%d,%f",fightBonusAttribute.power,fightBonusAttribute.powerCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "2" then
				fightBonusAttribute.hp = fightBonusAttribute.hp + tonumber(v["1"])
				fightBonusAttribute.hpCoefficient = fightBonusAttribute.hpCoefficient + tonumber(v["2"])
				tipstring = string.format("血量加成%d,%f",fightBonusAttribute.hp,fightBonusAttribute.hpCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "3" then
				-- fightBonusAttribute.speed = fightBonusAttribute.speed + tonumber(v["1"])
				-- fightBonusAttribute.speedCoefficient = fightBonusAttribute.speedCoefficient + tonumber(v["2"])
				-- tipstring = string.format("速度加成%d,%f",fightBonusAttribute.speed,fightBonusAttribute.speedCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "4" then
				fightBonusAttribute.att = fightBonusAttribute.att + tonumber(v["1"])
				fightBonusAttribute.attCoefficient = fightBonusAttribute.attCoefficient + tonumber(v["2"])
				tipstring = string.format("攻击加成%d,%f",fightBonusAttribute.att,fightBonusAttribute.attCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "5" then
				addVision = addVision + tonumber(v["1"])
				tipstring = string.format("视野加成%d",addVision)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "6" then
				breadCoefficient = breadCoefficient + tonumber(v["2"]) / 100
				tipstring = string.format("消耗减少%f,",breadCoefficient)
				-- print("1312",breadCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "7" then
				fightBonusAttribute.hits = fightBonusAttribute.hits + tonumber(v["1"])
				fightBonusAttribute.hitsCoefficient = fightBonusAttribute.hitsCoefficient + tonumber(v["2"])
				tipstring = string.format("命中加成%d,%f",fightBonusAttribute.hits,fightBonusAttribute.hitsCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "8" then
				fightBonusAttribute.dodge = fightBonusAttribute.dodge + tonumber(v["1"])
				fightBonusAttribute.dodgeCoefficient = fightBonusAttribute.dodgeCoefficient + tonumber(v["2"])
				tipstring = string.format("闪避加成%d,%f",fightBonusAttribute.dodge,fightBonusAttribute.dodgeCoefficient)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring)
			elseif k == "9" then

				if tonumber(v["1"]) ~= 0 then
					-- print("enter 1")
					fightBonusAttribute.ready = true
				end
				tipstring = string.format("战斗就绪",fightBonusAttribute.ready)
				-- ToastUtil:toastString(tipstring)
				-- print(tipstring,tonumber(v["1"]) ~= 0,tonumber(v["1"]))
			elseif k == "10" then
				fightBonusAttribute.damageReduction = fightBonusAttribute.damageReduction + tonumber(v["1"])
				fightBonusAttribute.damageReductionCoefficient = fightBonusAttribute.damageReductionCoefficient + tonumber(v["2"])
				tipstring = string.format("伤害减免%d,%f",fightBonusAttribute.damageReduction,fightBonusAttribute.damageReductionCoefficient)
				-- ToastUtil:toastString(tipstring)
				
			end

			-- print(tipstring)
		end
	end

	FightDataManager:getInstance().bonusAttribute = fightBonusAttribute
	-- printn("fightBonusAttribute",fightBonusAttribute,fightBonusAttribute.ready)
	-- for i=1,#bounds do
		-- print(i)
	-- end
end


function initPlayerSoilderAndShipInfo( data,ship_id )
	local num = 0
	local id = 0
	local cur_value = nil
	local cur_info = nil
	local skillData = nil


	-- print("initPlayerSoilderAndShipInfo",#data)

	-- for k,v in pairs(data) do
		-- print(k,v)
	-- end

	--船员信息
	for i=1,#data do
		cur_value = data[i]
		
		-- for k,v in pairs(cur_value) do
			-- print(k,v)
		-- end

		-- print("cur_value",cur_value)

		id = cur_value.id
		num = cur_value.num

		cur_info = dataController.getSoilderInfoById(id) 
		skillData = dataController.getSkillInfoById(cur_info["skill"])
		for j=1,num do
			-- print("j",j)
			local fightFighterData = FightFighterData.new()
			-- 威力值
			fightFighterData.power = tonumber(cur_info["attack"])
			-- 血量值
			fightFighterData.hp = tonumber(cur_info["hp"])
			-- 名字
			fightFighterData.name = cur_info["name"]
			-- 速度
			fightFighterData.speed = tonumber(cur_info["attackSpeed"])

			-- if fightFighterData.speed == nil or fightFighterData.speed == 0 then
			-- 	fightFighterData.speed = 1
			-- end

			-- 闪避
			fightFighterData.miss = tonumber(cur_info["dodge"])
			-- 技能 ID
			fightFighterData.soilderId = id
			-- -- 技能系数
			-- fightFighterData.skillRatio = tonumber(skillData["attack"])
			-- print("skillData",skillData["attack"])

			-- fightFighterData.skillRatio = 1
			-- 描述
			fightFighterData.description = cur_info["description"]

			-- print("fightFighterData.description",fightFighterData.description)
			
			if fightFighterData.description == nil or (fightFighterData.description ~= nil and string.len(fightFighterData.description))  then
				-- print("name = description")
				fightFighterData.description = fightFighterData.name
			end

			FightDataManager:getInstance():addPlayerFighterData(fightFighterData)

			-- print("initPlayerSoilderAndShipInfo1",fightFighterData.power,fightFighterData.hp,fightFighterData.name,fightFighterData.speed,fightFighterData.miss,fightFighterData.skillId)
			-- print("initPlayerSoilderAndShipInfo2",fightFighterData.description)
		end
	end	

		-- cur_info = dataController.getResourceInfoById(ship_id)

		-- cur_value = cur_info["raiseValue"]

		-- for k,v in pairs(cur_value[1]) do
			-- print(k,v)
		-- end

		-- print(cur_value[1][1])
		--初始化玩家舰船信息
		fightCannonData = FightCannonData.new()
		ship_id = DataManager:getInstance():getRoleData(roleShipId)
		-- 威力值
		fightCannonData.power = DataManager:getInstance():getRoleData(roleShipGunPower)
		-- 炮数
		fightCannonData.num = DataManager:getInstance():getRoleData(roleWarship)
		-- 血量值
		fightCannonData.hp = DataManager:getInstance():getRoleData(roleShipHp)
		-- 名字
		fightCannonData.name = dataController.getResourceValueByIdAndKey(ship_id,"name")
		-- -- 速度
		-- fightCannonData.speed = 2;
		-- 描述
		fightCannonData.description = dataController.getResourceValueByIdAndKey(ship_id,"desc")
		-- 星级
		fightCannonData.star = dataController.getResourceValueByIdAndKey(ship_id,"starNum")


		FightDataManager:getInstance().playerCanoon = fightCannonData
		-- print("ship_info",fightCannonData.power,fightCannonData.num,fightCannonData.hp,fightCannonData.name,fightCannonData.star)

		--加成属性添加
		addTalentProperties()

end

-- function scrollViewDidScroll(scrollview)
	-- print("self.scrollview:setContentOffset")

-- 	-- for k,v in pairs(scrollview:getContentOffset()) do
	-- 	print(k,v)
-- 	-- end

-- end

-- function scrollViewDidZoom(scrollview)
	
-- end

beganPos = cc.p(0,0)
lastPos = cc.p(0,0)
endPos = cc.p(0,0)
cur_touchContentOffset = 0
touchTable = {}
_dragging = true
isUpdateOffset = false 
beganLen = 0
touchcount = 0
bengainStatue = nil

function checkTouchOffset( target )

	local isOffset = true
	-- print("checkTouchOffset",_dragging,cur_touchContentOffset,target.statue,target.contentOffset.x,target.contentOffset.y)
	if target ~= nil and _dragging == true and cur_touchContentOffset < 30 and (math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) < 15 and target.statue == "ready" and #target.moveWaitingQueue < 1 then
		isOffset = false
	end

	return isOffset
end

-- zoomCenter = cc.p(0,0)
local function onTouchesBegan( target,touch, event )

	-- print("onTouchesBeganExplo",target.statue)

	--在触发事件的时候屏蔽地图touch事件
	if target.statue == "Triggering" then
		return false
	end

	beganPos = touch:getLocation()
	-- print("beganPos init",beganPos.x,beganPos.y,#touchTable)
	lastPos = beganPos

	local cur_index = #touchTable + 1

	-- cur_index = math.max(cur_index,1)

	local isContains = false

	for i=1,#touchTable do
		if touchTable[i] == touch then
			isContains = true
			break;
		end
	end

	touchcount = touchcount + 1


	if isContains ~= true and #touchTable < 3 then
		touchTable[cur_index] = touch
		-- print("touchTable[cur_index]",#touchTable,cur_index)
	end

	if #touchTable == 2 and #touchTable < 3 then 
		_dragging = false
		-- print("len init ",#touchTable)
		local point1 = target.moveLayer:convertTouchToNodeSpace(touchTable[1])
		local point2 = target.moveLayer:convertTouchToNodeSpace(touchTable[2])
		-- zoomCenter = getMidPoint(point1,point2)
		beganLen =  getDistance(point1,point2)
	end

	if bengainStatue == nil then
		bengainStatue = target.jointed.enable
	end

	-- print("TouchBegainAndCount: ",#touchTable , touchcount,_dragging,bengainStatue)

	-- print("onTouchesBegantarget",beganPos, lastPos)
	return true
end

local function onTouchesMoved( target, touch, event )
	
	--若地图在引导当中，不能让其有放大和缩小的操作,只能有船移动的操作
	if target.isNeedGuide then
		return
	end

	--draggin
	if _dragging then
		-- print("draggin move",_dragging)
			--在地图层移动的时候屏蔽摇杆的点击
		target.jointed.enable = false

		-- print("Explore move!",target.jointed.enable)

		endPos = touch:getLocation()

		local horizontalOffset = endPos.x - lastPos.x
		local verticalOffset = endPos.y - lastPos.y

		local ox = target.moveLayer:getPositionX()
		local oy = target.moveLayer:getPositionY()

		local x = ox + horizontalOffset
		local y = oy + verticalOffset


		local winSize = cc.Director:getInstance():getVisibleSize()
		
		-- print("move!",winSize.width / 2,winSize.height / 2,x,y)

		-- print("x,y",x,y)
		-- print("max",math.max(x, winSize.width / 2),math.min(y, winSize.height / 2))

		local scale = target.moveLayer:getScale()

		--做上边界限制
		x = math.min(x, winSize.width / 2 * scale);
		y = math.min(y, winSize.height / 2 * scale);

		-- print("winSize",winSize.width / 2,winSize.height / 2,horizontalOffset,verticalOffset,ox,oy,x,y)
		-- print("x,y",x,y)

		--做下边界限制，屏幕的中心点不能大于地图的宽减去屏幕宽的一半并且地图的高减去屏幕高的一半，否则会看到地图之外
		x = math.max(x,  winSize.width / 2  * scale - target.mapSize.width );
		y = math.max(y, winSize.height / 2 * scale - target.mapSize.height);
		-- print("target.mapSize",target.mapSize.width,target.mapSize.height)
		-- print("winSize / 2 - target.mapSize", winSize.width / 2 - target.mapSize.width,winSize.height / 2 - target.mapSize.height)
		-- print("x,y",x,y)

		--由于边界限制，导致之前的偏移量不准，所以得算出真正的偏移量
		horizontalOffset = x - ox
		verticalOffset = y - oy

		cur_touchContentOffset = cur_touchContentOffset + math.sqrt(math.pow(horizontalOffset,2) + math.pow(verticalOffset,2))
		
		lastPos = endPos

		if target.statue == "lookAt" then
			return
		end

		--若isUpdateOffset == false 且两个偏移量不为0
		if isUpdateOffset == false and (cur_touchContentOffset ~= 0) then
			isUpdateOffset = true
		end

		-- print("onTouchesMovedtarget",lastPos, endPos)
		target.moveLayer:setPosition(x , y )
		-- print("setposition",cur_touchContentOffset)

	--zoom
	else
		target.jointed.enable = false
		-- print("zoom move")
		
		if #touchTable == 2 then 
			-- print("getzoomPoint")
			local point1 = target.moveLayer:convertTouchToNodeSpace(touchTable[1])
			local point2 = target.moveLayer:convertTouchToNodeSpace(touchTable[2])
			local len = getDistance(point1,point2)
			-- print("enter zoom")
			target:setZoomScale(target.moveLayer:getScale() * len / beganLen)
			
		end
		
	end

end

local function onTouchesEnd( target, touch, event )

	local dragging = _dragging

	-- print("onTouchesEnd")
	
	if _dragging then
		
		--获得结束点的位置
		endPos = touch:getLocation()
		-- print("draggin end",endPos.x,endPos.y,beganPos.x,beganPos.y)
		--计算总偏移量
		if target.contentOffset ~= nil and isUpdateOffset then
			-- print("will add",target.contentOffset.x,target.contentOffset.y)
			target.contentOffset.x = target.contentOffset.x + endPos.x - beganPos.x
			target.contentOffset.y = target.contentOffset.y + endPos.y - beganPos.y
			-- print("added",target.contentOffset.x,target.contentOffset.y)
		end

		--若总偏移量为0，摇杆可以使用
		if target.contentOffset.x == 0 and target.contentOffset.y == 0 then
			target.jointed.enable = true
		end
		-- print("1111111123",(math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) >= 15 , target.jointed.enable == false , target.statue == "ready")
		--由于touch的偏移量小于10，且地图的偏移量大于15,当前地图偏移量不为0且地图不在定位的状态中,认为是轻点事件
		if cur_touchContentOffset < 10 and (math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) >= 15 and (target.statue == "ready" or target.statue == "WaitingLocation") then
			-- print("TouchedLocation")
			target.statue = "Location"
			target:slowlyMoveViewpointCenter(cc.p(target.player:getPositionX(),target.player:getPositionY()),locationTime)
		--由于touch的偏移量小于30，且地图的偏移量小于15且地图不在定位的状态中,认为是轻点事件
		elseif cur_touchContentOffset < 30 and (math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) < 15 and target.statue == "ready" then 
			target.jointed.enable = true
			target.statue = "ready"
		elseif (math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) > 20 then
			target.statue = "WaitingLocation"
		elseif target.statue == "WaitingLocation" and cur_touchContentOffset < 10 and (math.sqrt(math.pow(target.contentOffset.x,2) + math.pow(target.contentOffset.y,2))) < 15 then
			target.statue = "ready"
		end
	else 
		if #touchTable == 1 then
			-- print("willFreeJointed",bengainStatue)
			target.jointed.enable = bengainStatue
			beganLen = 0
			_dragging = true
			bengainStatue = nil
		end
	end

	-- print("onTouchesEndtarget",beganPos,lastPos, endPos)

	if #touchTable > 0 then
		table.remove(touchTable,judgeAValueIsInTable(touchTable,touch))
	end


	-- print("touchTable,end",#touchTable)

	touchcount = touchcount - 1
	-- zoomCenter = cc.p(0,0)
	--重置判断变量
	beganPos = cc.p(0,0)
	lastPos = cc.p(0,0)
	endPos = cc.p(0,0)
	cur_touchContentOffset = 0
	isUpdateOffset = false


	-- joind的touch事件
	-- touchIsBreak = checkTouchOffset(target.controller) 

    -- if target.limiter:isVisible() == true then
    --     touchIsBreak = true
    -- end

	print("target.jointed.enable",target.jointed.enable,target.statue)
    
	if target.statue == "WaitingLocation" or target.statue == "Location" or not dragging then
		print("touch ended",target.statue,dragging,cur_touchContentOffset,target.contentOffset.x,target.contentOffset.y)
		return
	end

	local horizontalOffset = 0
	local verticalOffset = 0

	judgePos = touch:getLocation()     
 	-- print("Jointed onTouchesEnd")

 	local ownerWdP = target.jointed.owner:convertToWorldSpaceAR(cc.p(0,0))
 	-- print("Owner onTouchesEnd",target.owner:getPosition())
 	-- print("ownerWdP")
    -- local t1 = os.clock()

 	--计算出来的角度是逆时针为正方向角度
 	local  radian = getRadianBetweenTwoPoints(judgePos,ownerWdP)
 	-- print("radian",radian)

 	if radian < 45 then
 		target.jointed.dirction = RightDircion
 	elseif radian == 45 then
 		target.jointed.dirction = RightUpDirction
 	elseif radian <  90 then
 		target.jointed.dirction = UpDiriction
 	elseif radian  == 90 then
 		target.jointed.dirction = UpDiriction
 	elseif radian <  135 then
 		target.jointed.dirction = UpDiriction
 	elseif radian == 135 then
 		target.jointed.dirction = LeftUpDirction
 	elseif radian <  180 then
 		target.jointed.dirction = LeftDirction
 	elseif radian == 180 then
 		target.jointed.dirction = LeftDirction
 	elseif radian <  225 then
 		target.jointed.dirction = LeftDirction
 	elseif radian == 225 then
 		target.jointed.dirction = LeftBottomDirction
 	elseif radian <  270 then
 		target.jointed.dirction = BottomDirction
 	elseif radian == 270 then
 		target.jointed.dirction = BottomDirction
 	elseif radian <  315 then
 		target.jointed.dirction = BottomDirction
 	elseif radian == 315 then
 		target.jointed.dirction = RightBottomDirction
 	elseif radian <	 360 then
 		target.jointed.dirction = RightDircion
 	elseif radian == 360 then
 		target.jointed.dirction = RightDircion
 	end
    -- target.jointed:tiping(target.jointed.dirction)

    -- print("local t1 = os.clock()",os.clock() - t1)

 	target.jointed.moveActed(target.jointed.dirction)

	-- print("touchTable end over")
end

local function clearAllTouchArgs( target )
	-- print("clearAllTouchArgs")

	if touchcount > 0 then
		target.jointed.enable = bengainStatue
		beganLen = 0
		_dragging = true
		touchTable = nil
		touchTable = {}
		bengainStatue = nil
	end

	touchcount = 0
	-- zoomCenter = cc.p(0,0)
	--重置判断变量
	beganPos = cc.p(0,0)
	lastPos = cc.p(0,0)
	endPos = cc.p(0,0)
	cur_touchContentOffset = 0
	isUpdateOffset = false
end

--touch事件异常结束，要将对应的变量清零
local function onTouchCancelled( target, touch, event )
	-- print("onTouchCancelled")
	clearAllTouchArgs(target)
end

Up = cc.p(0,0)
Down = cc.p(0,0)
Right = cc.p(0,0)
Left = cc.p(0,0)

Explore = class("Explore",function ()
	 return cc.Layer:create()
end)

Explore.__index = Explore
Explore.mapIndex = 0
Explore.map = nil
Explore.mapSize = cc.size(0,0)
Explore.meta = nil
Explore.player = nil
Explore.scrollview = nil
Explore.targetMovePosition = cc.p(0,0)
Explore.jointed = nil
Explore.statue = "ready"
Explore.contentOffset = cc.p(0,0)
Explore.mapName = nil
Explore.bread = nil
Explore.extent = 0
Explore.extentTip = nil
Explore.mapLayoutManagers = nil
Explore.eventManger = nil
Explore.moveLayer = nil
Explore.playerTitlePosition = cc.p(0,0)
Explore.fogManager = nil
Explore.fogLayer = nil
Explore.playerRect = nil
Explore.bothPosition = cc.p(0,0)
Explore.blocks = nil
Explore.bagController = nil
Explore.playerfighters = nil
Explore.breadNum = nil
Explore.breadCostDecimal = 0.0
Explore.visition = 0
Explore.moveWaitingQueue = {}
Explore.moveDirectionQueue = {}
Explore.mapMoveSpeed = 0

function Explore:create(index)
	-- print("Explore:create()!");

	local explore = Explore.new()
	curExplor = explore
	if explore and explore:init(index) then
		return explore
	end

	curExplor = nil

	return nil
end


function Explore:init(index)

	-- local ids = getCustomTable()
	-- ids["1001"] = 2
	-- print("ids[1001]")
	-- for k,v in pairs(ids.data) do
	-- 	print("ids",k,v)
	-- end

	-- local scrollview = cc.ScrollView:create()
	-- scrollview:setPosition(cc.p(0,0))
	-- local scrollview_size = cc.Director:getInstance():getWinSize()
	-- scrollview:setViewSize(cc.size(scrollview_size.width,scrollview_size.height))
	-- scrollview:setScale(1.0)
	-- self:addChild(scrollview);


	--策划需求，一进地图就可以开启随机事件
	if DataManager:getInstance():getRoleData(roleRandomEventSwitch) == nil then 
		DataManager:getInstance():setRoleData(roleRandomEventSwitch,1)
		-- print("开启随机事件开关")
	end
	
	isEnterMap = true
	self.mapGuideComponent = nil
	if index == nil then
		index = 1
		--读取上次地图的索引点...
		if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil then
			index = DataManager:getInstance():getRoleData(roleMapInfo).curIndex
		end
	end

	local winSize = cc.Director:getInstance():getVisibleSize()

	local bgLayer = cc.LayerColor:create(cc.c4b(0,0,0,255),winSize.width , winSize.height )
    bgLayer:setPosition(cc.p(0,0))
    self:addChild(bgLayer)

    initDataController()
    MissionManagers:getInstance():checkMissions(index,true)
   	self.bagController = ExploreBagController:getBagController(self)
   	-- DataManager:getInstance():getRoleData(roleBattlePack)
   	-- self.bagController:addItemToBattlePack(1006,1)

   	self:initTipLayer()

   	self.breadCostDecimal = DataManager:getInstance():getRoleData(roleBreadCostDecimal)

   	if self.breadCostDecimal == nil then
   		self.breadCostDecimal = 0
   	end

   	-- print("DataManager:getInstance():setRoleData(roleBattlePack)",DataManager:getInstance():setRoleData(roleBattlePack))
   	-- for k,v in pairs(DataManager:getInstance():setRoleData(roleBattlePack)) do
   		-- print(k,v)
   	-- end
   	--查看是否有视野信息，若没有初始化视野信息
   	self.visition = DataManager:getInstance():getRoleData(roleScopeOfVision)
   	if self.visition == nil then
   		DataManager:getInstance():setRoleData(roleScopeOfVision,1)
   		self.visition = 1;
   	end

   	local data = {}

   	for k,v in pairs(DataManager:getInstance():getRoleData(roleBattleQueue)) do
		local value = {}
		value.id = k
   		value.num = v
   		data[#data + 1] = value
	end

   	-- for i=1,2 do
   	-- 	local value = {}

   	-- 	if i == 1 then
   	-- 		value.id = 101
   	-- 		value.num = 2
   	-- 	else
   	-- 		value.id = 102
   	-- 		value.num = 1
   	-- 	end
   	-- 	data[i] = value
   	-- end

   	local ship_id = "1158"

   	-- local ship_info = ""

   	-- print("DataManager:getInstance():getRoleData(roleBattlePack)")

   	initPlayerSoilderAndShipInfo(data,ship_id)

   	self.playerfighters = data


   	-- local table = {123,54356,7234,5436,734,6,2,1453,8567,324,567}

   	-- table.sort(table)

   	-- print("arr")
   	-- for i=1,#table do
   		-- print(table[i])
   	-- end

   	-- print("dic")

   	-- print("initTipLayered")
   	--添加touch事件
   	local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function ( touch,event )
    	return onTouchesBegan(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(function ( touch,event )
    	onTouchesMoved(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(function ( touch,event )
    	onTouchesEnd(self,touch,event)
    end,cc.Handler.EVENT_TOUCH_ENDED )
    listener:registerScriptHandler(function ( touch,event )
    	-- print("onTouchCancelledL")
    	onTouchCancelled(self,touchcount,event)
    end,cc.Handler.EVENT_TOUCH_CANCELLED)
    -- listener:setFixedPriority(-127)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    eventDispatcher:setPriority(listener,-130)
	
    --添加迷雾管理者
    self.fogManager = FogManager:create()
    self.fogManager:setOwner(self)
    self:addChild(self.fogManager)

    self.mapLayoutManagers = MapLayoutManagers:create()
    self:addChild(self.mapLayoutManagers)

    -- check2dxLuaApi(cc.Node)

    -- print("设置player点为屏幕起始点")
    -- -- --设置player点为屏幕起始点
    -- self:setViewpointCenter(playerPosition)
    self:initMapByMapIndex(index,false)
    -- self:initMapFogs()
    -- print("Explore:init!");
   	-- local action = cc.ScaleTo:create(1.2, 0.2);
   	-- self.moveLayer:runAction(action)

   

   	

	-- DataManager:getInstance():registerEvent("kBuyBackSuccess", "Explore", function()
        
 --    end)

    

    -- DataManager:getInstance():registerEvent("kBuyBackFailed", "Explore", function()
    -- 	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.3), cc.CallFunc:create(delayPop)))
    -- end)

    return true;
end

function paySuccess()
	local action = cc.Sequence:create(cc.DelayTime:create(0.0),cc.CallFunc:create(function ( ... )
		curExplor:returnToBase()
	end))

	curExplor:runAction(action)
end

local mapGuidePlotDelayTime = 1.7

function Explore:startMapGuide( dirction )
	
	if not self.mapGuideComponent then
		self.mapGuideComponent = ExploreGuideComponent:create(self.map)
		self.mapGuideComponent:hideAllComponents()
	end

	self.isNeedGuide = false
	--地图引导步骤1:显示提示,由于提示有多行，所以需要另外一个步骤来判断是否已经播放提示完毕
	if not GuideController:getInstance():getIsHaveStep(63) then
		---这是判断步骤1中的提示是否播放完毕,没播放就播放动画，否则什么也不做
		if GuideController:getInstance():getIsHaveStep(62) and dirction ~= nil then

		elseif dirction == nil then
			-- self:setZoomScale(0.6)
			local des = {"这是哪,我在瓶子中吗?","这片海域看起来好恐怖..","先驾驶海盗船到旁边看看"}
			local pos = cc.p(self.player:getPosition())
			pos.y = pos.y + Right.x
			local seq = cc.Sequence:create(cc.DelayTime:create(mapGuidePlotDelayTime),cc.CallFunc:create(function ( ... )

				if #des == 0 then
					self:stopAllActions()
					GuideController:getInstance():addStep(63)
					self.mapGuideComponent:hideAllComponents()
					--提示框
					local pos = self:positionForTilePosition(cc.p(12,10))
					self.mapGuideComponent:showTipsByPosition("点击右侧屏幕可向右移动",pos)
					--手
					self.mapGuideComponent:showFingerActionByPosition(pos)
					return
				end

				self.mapGuideComponent:showDes(des[1],pos)
				table.remove(des,1)

			end))

			local action = cc.RepeatForever:create(seq)
			self:runAction(action)
			GuideController:getInstance():addStep(62)
		end
		self.isNeedGuide = true
	elseif not GuideController:getInstance():getIsHaveStep(64) then

		--步骤2--右走第一步
		self.isNeedGuide = true

		if dirction and dirction ~= Right then
			self.moveWaitingQueue = {}
			self.moveDirectionQueue = {}
			return
		--大退之后重新进入上次引导操作
		elseif dirction == nil then
			self:stopAllActions()
			self.mapGuideComponent:hideAllComponents()
			--提示框
			local pos = self:positionForTilePosition(cc.p(12,10))
			self.mapGuideComponent:showTipsByPosition("点击右侧屏幕可向右移动",pos)
			--手
			self.mapGuideComponent:showFingerActionByPosition(pos)
			return
		end

		-- print("enter64",dirction,Right)
		GuideController:getInstance():addStep(64)
		-- self.mapGuideComponent:hideAllComponents()
		-- self.mapGuideComponent:showFingerActionByPosition()
		self.moveDirectionQueue[1] = self.jointed.dirction

		self:tryToMoveForDirction(dirction)
	elseif not GuideController:getInstance():getIsHaveStep(65) then
		--步骤2--右走第二步
		self.isNeedGuide = true

		if dirction and dirction ~= Right then
			self.moveWaitingQueue = {}
			self.moveDirectionQueue = {}
			return
		--大退之后重新进入上次引导操作
		elseif dirction == nil then
			self:stopAllActions()
			self.mapGuideComponent:hideAllComponents()
			--提示框
			local pos = self:positionForTilePosition(cc.p(12,10))
			self.mapGuideComponent:showTipsByPosition("点击右侧屏幕可向右移动",pos)
			--手
			self.mapGuideComponent:showFingerActionByPosition(pos)
			return
		end

		GuideController:getInstance():addStep(65)
		self.moveDirectionQueue[1] = self.jointed.dirction
		self:tryToMoveForDirction(dirction)

	--由于需要等待右走引导需要完毕后才继续，所以，还有一个等待完毕步骤,里面什么也不用执行
	elseif not GuideController:getInstance():getIsHaveStep(66) then
		self.isNeedGuide = true

		if dirction == nil then
			dirction = 1
		end

		-- print("enter66")
	elseif not GuideController:getInstance():getIsHaveStep(68) then
		self.isNeedGuide = true
		self.moveWaitingQueue = {}
		self.moveDirectionQueue = {}
		-- print("enter68")

		if GuideController:getInstance():getIsHaveStep(67) and dirction ~= nil then
			return
		end

		self.mapGuideComponent:hideAllComponents()

		local tips = {"酷!我们已经开始航行了","报告船长远处发现一座小岛","让我们过去一探究竟!"}

		local pos = cc.p(self.player:getPosition())
		pos.y = pos.y + Right.x * 4

		local seq = cc.Sequence:create(cc.DelayTime:create(mapGuidePlotDelayTime),cc.CallFunc:create(function ( )
				self.jointed:tipingByDirection()
				if #tips == 0 then
					self:stopAllActions()
					GuideController:getInstance():addStep(68)
					self.mapGuideComponent:hideAllComponents()
					--提示框
					self.mapGuideComponent:showTipsByPosition("点击上方屏幕向小岛移动",pos)
					--手
					local pos = self:positionForTilePosition(cc.p(12,8))
					self.mapGuideComponent:showFingerActionByPosition(pos)
					return
				end

				self.mapGuideComponent:showTipsByPosition(tips[1],pos)
				table.remove(tips,1)

			end))

		local action = cc.RepeatForever:create(seq)
		self:runAction(action)

		GuideController:getInstance():addStep(67)
		
	elseif not GuideController:getInstance():getIsHaveStep(69) then
		--步骤3--上走第一步
		self.isNeedGuide = true

		if dirction and dirction ~= Up then
			self.moveWaitingQueue = {}
			self.moveDirectionQueue = {}
			return
		--大退之后重新进入上次引导操作
		elseif dirction == nil then
			self.mapGuideComponent:hideAllComponents()
			--提示框
			local pos = self:positionForTilePosition(cc.p(12,8))
			self.mapGuideComponent:showTipsByPosition("点击上方屏幕向小岛移动",pos)
			--手
			self.mapGuideComponent:showFingerActionByPosition(pos)
			return
		end
		self.moveDirectionQueue[1] = self.jointed.dirction
		self:tryToMoveForDirction(dirction)
		GuideController:getInstance():addStep(69)
	elseif not GuideController:getInstance():getIsHaveStep(70) then
		--步骤3--上走第二步
		self.isNeedGuide = true

		if dirction and dirction ~= Up then
			self.moveWaitingQueue = {}
			self.moveDirectionQueue = {}
			return
		--大退之后重新进入上次引导操作
		elseif dirction == nil then
			self.mapGuideComponent:hideAllComponents()
			--提示框
			local pos = self:positionForTilePosition(cc.p(12,8))
			self.mapGuideComponent:showTipsByPosition("点击上方屏幕向小岛移动",pos)
			--手
			self.mapGuideComponent:showFingerActionByPosition(pos)
			return
		end
		self.moveDirectionQueue[1] = self.jointed.dirction
		self:tryToMoveForDirction(dirction)
		GuideController:getInstance():addStep(70)
		self.mapGuideComponent:hideAllComponents()
	end

end

function Explore:initTipLayer(  )

	-- print("initTipLayer")
	
	local winSize = screenSize
	
	local tipLayer = cc.Layer:create()
    tipLayer:setPosition(cc.p(0,0))
    self:addChild(tipLayer,topButtonOrderLevel)

    -- 添加下边的点点承载节点

    -- 添加信息框
    local tempSpr = cc.Sprite:create("Images/Map/mask.png")
    local mapMask = cc.Scale9Sprite:create("Images/Map/mask.png",cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(50, 50, tempSpr:getContentSize().width - 100, tempSpr:getContentSize().height - 100))
    mapMask:setContentSize(winSize)
    mapMask:setPosition(cc.p(winSize.width / 2, winSize.height / 2))
    tipLayer:addChild(mapMask)

    -- local mapMask = cc.Sprite:create("Images/Map/mask.png")
    -- local scaleX = winSize.width / mapMask:getContentSize().width
    -- local scaleY = winSize.height / mapMask:getContentSize().height
    -- mapMask:setScaleX(scaleX)
    -- mapMask:setScaleY(scaleY)
    
    local tempData = DataManager:getInstance():getRoleData(roleMapInfo)

    local backBtn = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        if self.isNeedGuide then
        	return
        end

        local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
        local tipstring = nil
        local comfirmFunc = nil

		if not tempData.fristReturnBaseByTool then

			tipstring = string.format("您确定要返回基地吗？\n(第一次返回免费,不扣除回城卷轴)",self.mapLayoutManagers.returnBaseNum,name)

			comfirmFunc = function ( ... )
        		tempData.fristReturnBaseByTool = "1"
        		DataManager:getInstance():setRoleData(roleMapInfo,tempData)
        		self:returnToBase()
        	end

        elseif self.mapLayoutManagers:checkReturnBase() then
        	local name = dataController.getResourceValueByIdAndKey(self.mapLayoutManagers.returnBaseTool,"name")
        	tipstring = string.format("您确定要返回基地吗？\n(需消耗%d个%s)",self.mapLayoutManagers.returnBaseNum,name)

        	comfirmFunc = function ( ... )
        		self.bagController:costGoodsByGoodsIdAndNum(self.mapLayoutManagers.returnBaseTool,self.mapLayoutManagers.returnBaseNum)

        		self:returnToBase()
        	end
        else

        	local priceId = dataController.getResourceValueByIdAndKey(self.mapLayoutManagers.returnBaseTool,"shop_connect")

        	local shopDatas = DataManager:getInstance():getCSVByID(csvOfShopItem)

        	local price = tonumber(shopDatas[priceId]["price"])

        	tipstring = string.format("回城卷轴不足，您可以花费钻石返回基地。\n(需消耗%d个钻石)",price)

        	comfirmFunc = function ( ... )
        		
        		if DataManager:getInstance():addDiamond(-price) == 1 then
        			self:returnToBase()
        		else
        			--TD记录地图
        		end
        	end
        end
		
		local _alert = AlertView:create(2,0, "返 航", comfirmFunc, function ( ... )
			-- print("离开购买提示界面")
		end)
		-- print("_alert inited")
        local showLabel1 = cc.LabelTTF:create(tipstring, BoldFont, 30)
        showLabel1:setColor(cc.c3b(255, 255, 255))
        -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
        showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y))
        -- print("showLabel1 will add")
        _alert:addChild(showLabel1)
        -- print("showLabel1 inited")
    end)
    backBtn:setScale(0.8)
    backBtn:setPosition(cc.p(winSize.width - backBtn:getContentSize().width / 2 , winSize.height * 0.1 - backBtn:getContentSize().height * backBtn:getScaleY() / 2))
    tipLayer:addChild(backBtn)

    -- local buttons = {}

    -- local button = cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
   	-- --cc.Menu:create(unpack(buttonArr))
   	-- buttons[1] = button
   	-- button:registerScriptTapHandler(function() 
        
    --     if self.mapLayoutManagers:checkReturnBase() then
    --     	self:returnToBase()
    --     end
    -- end)
    -- button:setScale(0.8)
   	-- button:setPosition(cc.p(winSize.width - button:getContentSize().width / 2 , winSize.height * 0.1 - button:getContentSize().height * button:getScaleY() / 2))

   
   	local buttonTips = cc.LabelTTF:create("返 航", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(backBtn:getPositionX() ,backBtn:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	tipLayer:addChild(buttonTips, 1)




   	local BagBtn = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        
        self:goBag()
    end)
    BagBtn:setScale(0.8)
    BagBtn:setPosition(cc.p(backBtn:getPositionX() - winSize.width * 0.1 - BagBtn:getContentSize().width / 2,backBtn:getPositionY()))
    tipLayer:addChild(BagBtn)



    
   	-- button = cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
   	-- --cc.Menu:create(unpack(buttonArr))
   	-- button:setScale(0.8)
   	-- button:setPosition(cc.p(buttons[1]:getPositionX() - winSize.width * 0.1 - button:getContentSize().width / 2,buttons[1]:getPositionY()))
   	-- buttons[2] = button

   	-- button:registerScriptTapHandler(function() 
    --     self:goBag()
    -- end)


   	buttonTips = cc.LabelTTF:create("货 舱", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(BagBtn:getPositionX() ,BagBtn:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	tipLayer:addChild(buttonTips, 1)

--货仓空间提示
	self.capacityTips = cc.LabelTTF:create(string.format("%d/%d",self.bagController.costSpace,self.bagController.limited), BoldFont, winSize.height * 0.025)
   	self.capacityTips:setPosition(cc.p(BagBtn:getPositionX() ,BagBtn:getPositionY() + BagBtn:getContentSize().height * BagBtn:getScaleY() * 0.5 + self.capacityTips:getContentSize().height * self.capacityTips:getScaleY() / 2))
   	self.capacityTips:setColor(opColorPrimroseYellow)
   	tipLayer:addChild(self.capacityTips, 1)


   	--攻略
  	local strategyButton = SDButton:create("Images/Map/strategyBtn.png", "Images/Map/strategyBtn_select.png", function() 
        self:showCurMapStrategy()
    end)
    strategyButton:setScale(0.9)
    strategyButton:setPosition(cc.p(winSize.width * 0.05 + strategyButton:getContentSize().width / 2,backBtn:getPositionY()))
    tipLayer:addChild(strategyButton)


   -- 	local buttonController = cc.Menu:create(unpack(buttons))
  	-- buttonController:setPosition(cc.p(0,0))
  	-- tipLayer:addChild(buttonController)
  	self.chapterTitle = cc.LabelTTF:create("第一章", BoldFont, winSize.height * 0.03)
  	self.chapterTitle:setAnchorPoint(cc.p(1,0.5))
  	self.chapterTitle:setPosition(cc.p(winSize.width  ,winSize.height * 0.99 - self.chapterTitle:getContentSize().height / 2))
  	self.chapterTitle:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
  	self.chapterTitle:setColor(opColorPrimroseYellow)
  	tipLayer:addChild(self.chapterTitle)


  	local title = cc.LabelTTF:create("测试地图", BoldFont, winSize.height * 0.05)
  	title:setAnchorPoint(cc.p(1,0.5))
  	title:setPosition(cc.p(winSize.width  ,winSize.height * 0.95 - title:getContentSize().height / 2))
  	title:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
  	title:setColor(cc.c3b(255, 255, 0))
  	tipLayer:addChild(title)
  	self.nameTitle = title

--本图探索度
  	local extenttitle = cc.LabelTTF:create("本图探索:",BoldFont,winSize.height * 0.03)
  	local extentBg = cc.Sprite:create("Images/Map/shuzk_01.png")
  	local extentBgSize = cc.size(extenttitle:getContentSize().width + winSize.height * 0.15,extenttitle:getContentSize().height * 1.1)

  	extenttitle:setPosition(cc.p(winSize.width * 0.2,winSize.height * 0.995 - extentBgSize.height * 2 - winSize.height * 0.005 * 2 - extenttitle:getContentSize().height / 2))
  	extenttitle:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
  	extenttitle:setColor(opColorPrimroseYellow)
  	extenttitle:setAnchorPoint(cc.p(1,0.5))
  	tipLayer:addChild(extenttitle,1)

  	--适配问题
  	if extenttitle:getContentSize().width > winSize.width * 0.2 then
  		extenttitle:setPositionX(extenttitle:getContentSize().width)
  		-- breadtitile:setPositionX(extenttitle:getPositionX())
  		-- self.bread:setPositionX(extenttitle:getPositionX())
  	end

  	self.extentTip = cc.LabelTTF:create(string.format("  %d",self.extent).."%",BoldFont,winSize.height * 0.03)
  	self.extentTip:setPosition(cc.p(extenttitle:getPositionX(),extenttitle:getPositionY()))
  	self.extentTip:setAnchorPoint(0,0.5)
  	self.extentTip:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
  	self.extentTip:setColor(opColorPrimroseYellow)
  	tipLayer:addChild(self.extentTip,1)

	local scaleX = extentBgSize.width / extentBg:getContentSize().width
  	local scaleY = extentBgSize.height / extentBg:getContentSize().height
  	extentBg:setScaleX(scaleX)
  	extentBg:setPosition(cc.p(extentBgSize.width / 2,self.extentTip:getPositionY()))
  	tipLayer:addChild(extentBg)
--探索度
	local occupation = cc.LabelTTF:create("探索度:",BoldFont,winSize.height * 0.03)
  	occupation:setPosition(cc.p(extenttitle:getPositionX(),extenttitle:getPositionY() + extentBgSize.height / 2 + winSize.height * 0.005 + extentBgSize.height / 2))
  	occupation:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
  	occupation:setColor(opColorPrimroseYellow)
  	occupation:setAnchorPoint(cc.p(1,0.5))
  	tipLayer:addChild(occupation,1)

  	local roleExtentNum = DataManager:getInstance():getRoleData(roleExtents)
	if roleExtentNum == nil then
		roleExtentNum = 0
	end

  	self.occupation = roleExtentNum

  	self.occupationNum = cc.LabelTTF:create(string.format("  %d",self.occupation),BoldFont,winSize.height * 0.03)
  	self.occupationNum:setPosition(cc.p(occupation:getPositionX(),occupation:getPositionY()))
  	self.occupationNum:setAnchorPoint(0,0.5)
  	self.occupationNum:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
  	self.occupationNum:setColor(opColorPrimroseYellow)
  	tipLayer:addChild(self.occupationNum,1)

  	extentBg:setPosition(cc.p(extentBgSize.width / 2,self.occupationNum:getPositionY()))

  	-- local occupationBg = cc.Sprite:create("Images/Map/explore_tip_button_bg.png")
  	-- occupationBg:setScaleX(scaleX)
  	-- occupationBg:setScaleY(scaleY)
  	-- occupationBg:setPosition(cc.p(extentBgSize.width / 2,self.occupationNum:getPositionY()))
  	-- tipLayer:addChild(occupationBg)

--给养
  	local breadtitile = cc.LabelTTF:create("食 物:",BoldFont,winSize.height * 0.03)
  	breadtitile:setPosition(cc.p(extenttitle:getPositionX(),winSize.height * 0.995 - breadtitile:getContentSize().height * breadtitile:getScaleY() * 0.5))
  	breadtitile:setHorizontalAlignment(cc.TEXT_ALIGNMENT_RIGHT)
  	breadtitile:setColor(opColorPrimroseYellow)
  	breadtitile:setAnchorPoint(cc.p(1,0.5))

  	self.breadtitile = breadtitile
  	tipLayer:addChild(breadtitile,1)

  	self.breadNum = self.bagController:getBreads()

  	extentBgSize.height = breadtitile:getPositionY() + breadtitile:getContentSize().height / 2 + 5 - ( extenttitle:getPositionY() - extenttitle:getContentSize().height / 2 - 5)
  	scaleY = extentBgSize.height / extentBg:getContentSize().height
  	extentBg:setScaleY(scaleY)


  	-- self.breadNum = 10000
  	-- print("战斗背包")
  	-- for k,v in pairs(DataManager:getInstance():getRoleData(roleBattlePack)) do
  		-- print(k,v)
  	-- 	for k,j in pairs(v) do
  			-- print(k,j)
  	-- 	end
  	-- end

  	self.bread = cc.LabelTTF:create(string.format("  %d",self.breadNum),BoldFont,winSize.height * 0.03)
  	self.bread:setPosition(cc.p(breadtitile:getPositionX(),breadtitile:getPositionY()))
  	self.bread:setAnchorPoint(0,0.5)
  	breadtitile:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    if self.breadNum < 10 then
        self.bread:setColor(opColorRed)
    else
        self.bread:setColor(opColorPrimroseYellow)
    end

  	tipLayer:addChild(self.bread,1)


  	-- local breadBg = cc.Sprite:create("Images/Map/explore_tip_button_bg.png")
  	-- scaleX = extentBgSize.width / breadBg:getContentSize().width
  	-- scaleY = extentBgSize.height / breadBg:getContentSize().height
  	-- breadBg:setScaleX(scaleX)
  	-- breadBg:setScaleY(scaleY)
  	-- breadBg:setPosition(cc.p(extentBgSize.width / 2,self.bread:getPositionY()))
  	-- tipLayer:addChild(breadBg)

  	
  	--贫血警告字
  	self.warnningTips = cc.LabelTTF:create("食物将耗尽\n速回出发点补充食物",BoldFont,winSize.height * 0.03)
  	self.warnningTips:setPosition(cc.p(winSize.width / 2,winSize.height * 0.6))
  	self.warnningTips:setColor(opColorRed)
  	tipLayer:addChild(self.warnningTips)
  	self.warnningTips:runAction(cc.FadeOut:create(0))

  	--贫血警告框
  	local warnningBox = cc.Sprite:create("Images/Map/anemia_warnning.png")
  	scaleX = winSize.width / warnningBox:getContentSize().width
  	scaleY = winSize.height / warnningBox:getContentSize().height
  	warnningBox:setScaleX(scaleX)
  	warnningBox:setScaleY(scaleY)
  	warnningBox:setPosition(cc.p(winSize.width / 2,winSize.height / 2))
  	tipLayer:addChild(warnningBox,3)
  	self.warnningBox = warnningBox

  	self.warnningBox:setVisible(false)

  	self.tipLayer = tipLayer
end

function Explore:checkBread(  )
	
	local bread = self.bagController:getBreads()

	if bread <= 10 then
		self:warnningAction()
	else
		self:stopWarnningAction()
	end
end

function Explore:warnningAction(  )

	if self.warnningBox:getNumberOfRunningActions() > 0 then
		return
	end

	self.warnningBox:setOpacity(0)
	self.warnningBox:setVisible(true)

	local totaltime = 1.3

	local fadein = cc.FadeIn:create(totaltime / 2)

	local fadeout = cc.FadeOut:create(totaltime / 2)

	local seq = cc.Sequence:create(fadein, fadeout)

	local action = cc.RepeatForever:create(seq)

	self.warnningBox:runAction(action)


	self.breadtitile:setOpacity(0)


	local fadein = cc.FadeIn:create(totaltime / 2)

	local fadeout = cc.FadeOut:create(totaltime / 2)

	local seq = cc.Sequence:create(fadein, fadeout)

	local action = cc.RepeatForever:create(seq)

	self.breadtitile:runAction(action)

	self.bread:setOpacity(0)


	local fadein = cc.FadeIn:create(totaltime / 2)

	local fadeout = cc.FadeOut:create(totaltime / 2)

	local seq = cc.Sequence:create(fadein, fadeout)

	local action = cc.RepeatForever:create(seq)

	self.bread:runAction(action)

	-- self.warnningTips:setVisible(true)
	-- self.warnningTips:setOpacity(255)
	local seq = cc.Sequence:create(cc.FadeOut:create(0),cc.FadeIn:create(totaltime / 2),cc.FadeOut:create(totaltime / 2))
	local action = cc.RepeatForever:create(seq)
	self.warnningTips:runAction(action)

end

function Explore:stopWarnningAction(  )
	self.warnningBox:stopAllActions()
	self.warnningBox:setVisible(false)
	self.breadtitile:setOpacity(255)
	self.breadtitile:stopAllActions()
	self.bread:setOpacity(255)
	self.breadtitile:stopAllActions()
end

function Explore:checkMapScale( scale )
	if scale == nil then
		scale = self.moveLayer:getScale()
	end

	scale = math.min(scale,1.0)
	scale = math.max(scale,0.3)

	print("checkMapScale",scale)

	return scale
end

function Explore:setMapScale( scale )

	scale = self:checkMapScale(scale)

	self.moveLayer:setScale(scale)
end

function Explore:initEventManger( )
	
	if self.eventManger == nil then
		self.eventManger = EventManger:create(self)
	    self.eventManger:setPosition(cc.p(0,0))
	    self:addChild(self.eventManger,eventOrderLevel)
	end
	
	self.jointed:setLimiter(self.eventManger.layer)
	self.eventManger:getMapDataAndRefreshMapByMapIndex(self.mapIndex)

end

function Explore:initMapByMapIndex( mapIndex,isclear )
	--在加载的时候，不允许任何操作
	self.statue = "loading"

	self.isInitFogs = false

	self.isHungry = false

	--若后面一个参数为空，则默认需要清除之前地图关连的数据
	if isclear == nil then
		self:clearMapInfoData(true)
		--清空地图上一次地图据点动画
		self.moveLayer:removeAllChildren()
		self.map = nil 
		self.player = nil
	end

	self.halos = {}
	self.effectsCenters = {}
	self.particles = {}

	self:checkBread()
	print("initMapByMapIndex",mapIndex)

	if mapIndex == nil then
		mapIndex = self.mapIndex + 1
	end

	curMapDatas = nil

	self.mapIndex = mapIndex

	local chapterString = nil

	chapterString = string.format("第%s章",getChineseCharactersByNum(self.mapIndex)) 

	-- if self.mapIndex == 1 then
	-- 	chapterString = "第一章"
	-- elseif self.mapIndex == 2 then
	-- 	chapterString = "第二章"
	-- elseif self.mapIndex == 3 then
	-- 	chapterString = "第三章"
	-- elseif self.mapIndex == 4 then
	-- 	chapterString = "第四章"
	-- elseif self.mapIndex == 5 then
	-- 	chapterString = "第五章"
	-- elseif self.mapIndex == 6 then
	-- 	chapterString = "第六章"
	-- elseif self.mapIndex == 7 then
	-- 	chapterString = "第七章"
	-- elseif self.mapIndex == 8 then
	-- 	chapterString = "第八章"
	-- elseif self.mapIndex == 9 then
	-- 	chapterString = "第九章"
	-- elseif self.mapIndex == 10 then
	-- 	chapterString = "第十章"
	-- elseif self.mapIndex == 11 then
	-- 	chapterString = "第十一章"
	-- elseif self.mapIndex == 12 then
	-- 	chapterString = "第十二章"
	-- elseif self.mapIndex == 13 then
	-- 	chapterString = "第十三章"
	-- elseif self.mapIndex == 14 then
	-- 	chapterString = "第十四章"
	-- elseif self.mapIndex == 15 then
	-- 	chapterString = "第十五章"
	-- elseif self.mapIndex == 16 then
	-- 	chapterString = "第十六章"
	-- end

	self.chapterTitle:setString(chapterString)

	-- print("initMapByMapIndex2",self.mapIndex)
	--取出所有地图信息
	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	-- print("DataManager:getInstance():getRoleData(roleMapInfo)",DataManager:getInstance():getRoleData(roleMapInfo))
	--若所有地图信息为空，则说明从没进入过地图，创建所有地图信息
	if tempData == nil then
		tempData = {}
		DataManager:getInstance():setRoleData(roleMapInfo,tempData)
	end
	--存入当前地图的index
	tempData.curIndex = self.mapIndex

	if tempData.mapIndex == nil then
		tempData.mapIndex = 1
	end

	DataManager:getInstance():setRoleData(roleMapInfo,tempData)
		
	-- print("roleRandomEventSwitch",DataManager:getInstance():getRoleData(roleRandomEventSwitch))

	-- curMapDatas = DataManager:getInstance():getRoleData(mapInfo)

	-- print("curMapDatas",curMapDatas)
	-- print(",curMapDatas.mapLayoutData",curMapDatas.mapLayoutData)
	if self.map ~= nil then
		self.map:removeFromParent(true)
		self.player = nil
	end

	--初始化地图承载层
	if self.moveLayer == nil then
		self.moveLayer = cc.Layer:create()
		self:addChild(self.moveLayer)
	end   
	-- curMapDatas = {}
	local mapString = string.format("Images/Map/map_%d.tmx",self.mapIndex)
	-- print("map",mapString)
	--初始化地图
	self.map = cc.TMXTiledMap:create(mapString);
	-- self.map:setScale(0.8) --不能直接对mapsetscale,因为我是对movelayer进行偏移的!!!
    -- scrollview:setContainer(self.map)
    -- scrollview:updateInset()
    self.map:setPosition(cc.p(0,0))
   	self.moveLayer:addChild(self.map);

   	-- --取出对应地图的信息
	ExploreDataManager:getInstance():exchangeMapDataByIndex(self.mapIndex)
	ExploreDataManager:getInstance():setMapOwner(self)

   	--获取据点层
	local meta = self.map:getLayer("Meta");

    if meta then
    	meta:setVisible(true);
    	self.meta = meta;
    end

     

	-- self.pointsLayer = self.map:getLayer("Points")

   	--开始对地图进行布局
   	self.mapLayoutManagers:setOwner(self)
   	self.mapLayoutManagers:tryToLayoutMapByMapIndex()

   

    -- scrollview:ignoreAnchorPointForPosition(true)
    -- scrollview:setDirection(cc.SCROLLVIEW_DIRECTION_BOTH )
    -- scrollview:setClippingToBounds(true)
    -- scrollview:setBounceable(false)
    -- scrollview:setDelegate()
    -- scrollview:registerScriptHandler(function ()
    -- 	scrollViewDidScroll(self.scrollview)
    -- end,cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- scrollview:registerScriptHandler(function ()
    -- 	scrollViewDidZoom(self.scrollview)
    -- end,cc.SCROLLVIEW_SCRIPT_ZOOM)
    -- self:addChild(self.map);

    -- self.scrollview = scrollview

    --获取地图瓦片大小，并初始化各个方向变量
    local tile_size = self.map:getTileSize().width

    Up.y = tile_size
    Down.y = -tile_size
    Left.x = - tile_size
    Right.x = tile_size;

    --获取当前地图移动速度
    self.mapMoveSpeed = tile_size / moveTime

    --初始化地图的大小
    local mapWidth = self.map:getMapSize().width * self.map:getTileSize().width;
	
	local mapHeight = self.map:getMapSize().height * self.map:getTileSize().height;

	self.mapSize.width = mapWidth
	self.mapSize.height = mapHeight

	self:setMapScale(0.8)
	self:initPlayer()
	self:initMapFogs()
	self:initEventManger(mapIndex)

	if  mapPermissions.fog then
		self:changFogStatue()
	end
		--铁矿检查
   	if self.mapIndex == 1 then
   		local pos = cc.p(12,8)
   		local metaTileId = self.meta:getTileGIDAt(pos)
   		local metaProperties = self.map:getPropertiesForGID(metaTileId)
   		if metaProperties and metaProperties ~= 0 then
   			local id = metaProperties["eventid"]
   			self.mapLayoutManagers:safeCheckDataByPositionAndId(pos,id)
   		end
   	end

	--处理上次的临时占领数据
	tempOccupationData = ExploreDataManager:getInstance():getOccupationTempData()

	if tempOccupationData ~= nil then
		for k,v in pairs(tempOccupationData) do
			-- print(k,v)
			local position = v.position 
			local keyString = ExploreDataManager:getInstance():getPosKeyByPosition(position)

			--把当前数据写入进去
			ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",keyString,"statues","11")
			-- printn("tempData",position,keyString)
			self.eventManger.curEventId = v.id

			-- printn("allinfo",dataController.getStrongholdAttributeInfoById(v.id))

			--添加据点道具掉落
			local addDropInfo = dataController.getStrongholdAttributeValueByIdAndKey(v.id,"dropitems")
			-- printn("addDropInfo",addDropInfo)
			if addDropInfo ~= nil and addDropInfo[1][1] ~= "0" then
				print("addDropInfo")
				for i=1,#addDropInfo do
					
					local cur_data = addDropInfo[i]
					local id = cur_data[1]
					local num = tonumber(cur_data[2])
					-- local name = dataController.getResourceValueByIdAndKey(id,"name")

					ExploreDataManager:getBagController():addItemToBattlePack(id,num)

					-- print("curDropData[i]",i,id,num,name)
				end
			end

			
			--通知ui层开始刷新占领后的据点ui
			self:tileHasBeenOccupiedByTitlePosition(position)
			--通知解锁
			self.eventManger.openbuildIds = v.openbuildIds
			self.eventManger.produceIDs = v.produceIDs

			self.eventManger:postUnlockMessage()
		end

		ExploreDataManager:getInstance():saveCurDatas()
		ExploreDataManager:getInstance():clearTempOccupationData()
	end


	-- self.mapGuideComponent = ExploreGuideComponent:create(self.map)
	-- self.mapGuideComponent:hideAllComponents()

	-- local targetp = self:positionForTilePosition(cc.p(13,9))

	-- self.mapGuideComponent:showFingerActionByPosition(targetp)

	-- self.mapGuideComponent:showDes("提示大家发生过哈撒",cc.p(self.player:getPosition()))

	-- self.fogLayer:setVisible(false)
	-- self:justShowBlock()


	--其他处理

	--怪物检测
	MissionManagers:getInstance():checkMissions(self.mapIndex)
	--检查可遇到特殊怪物
	SkirmishLogicManagers:getInstance():screeningEncounters()

	self:startMapGuide()

	self.statue = "ready"
end

function Explore:initPlayer( )

	--获取上次大退之前的玩家探索信息
	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	local position = tempData.playerTitlePosition
	

	if self.player == nil then

		local shipStar = dataController.getResourceValueByIdAndKey(DataManager:getInstance():getRoleData(roleShipId),"starNum")
		
		
		-- print("initplayer",type(shipStar),shipStar)
		local shipStr = string.format("Images/Map/ship_%d.png",shipStar)



		local player = cc.Sprite:create(shipStr)
		self.map:addChild(player,playerOrderLevel)
		self.player = player;

		--添加虚拟摇杆
	    local jointed = Jointed:create(self.player,function ( dirction )
	    	self:jointedCalBack(dirction)
	    end)

	    -- jointed:setTipTime(moveTime)

	    self.jointed = jointed
	    self.jointed.controller = self
	   	
	    -- print("jointed inited",self.jointed)

	end
	
	local playerPosition = cc.p(0,0)

	if position == nil then
		local startInfoLayer = self.map:getObjectGroup("Objects");
	    local startInfo = nil;
	    -- print("startInfoLayer", startInfoLayer)

	    

	    if startInfoLayer then
	    	startInfo = startInfoLayer:getObject("Start");
	    	--valueMap 改变成table了!!
	    	if startInfo then
	    		-- print("startInfo",startInfo)

	    		-- for k,v in pairs(startInfo) do
	    			-- print(k,v)
	    		-- end

	    		local x = startInfo["x"]
	    		local y = startInfo["y"]

	    		--由于策划画点不能画准，所以要规范一下

	    		-- print("X:",x,"Y:",y);

	    		playerPosition.x = x
	    		playerPosition.y = y

	    		playerPosition = self:coordinateStandardizationByPosition(playerPosition)

	    		-- print("playerPositionX:",playerPosition.x,"playerPositionY:",playerPosition.y);

		    	self.player:setPosition(playerPosition)
	    		
	    		-- print("self.player",self.player);

	    	end	
	    end
    	  --记录出生点
    	  self.bothPosition = self:tileCoordForPosition(playerPosition)
	else
		-- print("读入玩家地图坐标",position.x,position.y)
		print("getPosition",position.x,position.y)
		local playerposition = position
		--若有战斗状态，则需要进行自动偏移
		if tempData.willFight ~= nil then
			print("willFight")
			playerposition.x = playerposition.x - 1
		end
		
		-- print("换算地图坐标为",playerposition.x,playerposition.y)
		local realPos = self:positionForTilePosition(playerposition)
		print("realPos",realPos.x,realPos.y)
		self.player:setPosition(realPos)
		playerPosition.x = realPos.x
		playerPosition.y = realPos.y
	end

	--设置player点为屏幕起始点
    self:setViewpointCenter(playerPosition)
    self.moveWaitingQueue = {}
    self.moveDirectionQueue = {}
end

-- function Explore:initStrongHold( )
	
-- end

function Explore:startJumpAction(  )
	print("startJumpAction")
	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
	if tempData.willFight == nil then
		print("NONONON")
		return
	end
	-- tempData.willFight = nil
	-- DataManager:getInstance():setRoleData(roleMapInfo,tempData)
	-- print("jump!")
	self:tryToMoveForDirction(Right)
end

function Explore:changFogStatue( )

	local visible = not self.fogLayer:isVisible()

	self.fogLayer:setVisible(visible)
	-- self.map:getLayer("Meta"):setVisible(false)
	-- self.map:getLayer("Sea"):setVisible(false)
end

function Explore:initMapFogs(  )
	
	self.fogLayer = nil;

	--获得迷雾层
    local fogs = self.map:getLayer("Fogs")
    self.fogLayer = fogs
    self.fogLayer:setCascadeOpacityEnabled(true)
    self.fogLayer:setVisible(true)
    --让迷雾管理者获得数据，然后根据数据刷新地图迷雾
    self.fogManager:getFogDatasAndClearFogsByMapIndex(self.mapIndex)
end

function Explore:initMapFogsOfStart( )
	-- print(self.fogManager)
	local playerPosition = cc.p(self.player:getPositionX(),self.player:getPositionY())
	-- print(self.player:getPositionX(),self.player:getPositionY(),playerPosition)
	-- print("initMapFogs")
	local tilePosition = self:tileCoordForPosition(playerPosition)
	local rect = cc.rect(tilePosition.x,tilePosition.y,8,8)
	-- print("origin")
	self.fogManager:tryToClearFogByRect(rect)
	self.isInitFogs = true
	self:clearFogs()
end


function Explore:checkMoveWaitingQueue( moveType )
	
	if GuideController:getInstance():getIsHaveStep(65) and not GuideController:getInstance():getIsHaveStep(66) then
		GuideController:getInstance():addStep(66)
		self:startMapGuide()
	end

	if #self.moveWaitingQueue == 0 then
		return
	end

	print("checkMoveWaitingQueue",#self.moveWaitingQueue,moveType)
	local targetDirction = self.moveWaitingQueue[1]
	self:tryToMoveForDirction(targetDirction,moveType)
end

function Explore:jointedCalBack( dirction )
	
	if not GuideController:getInstance():getIsHaveStep(63) then
		return
	end 

	local targetDirction = nil
	if dirction == UpDiriction or dirction == LeftUpDirction or dirction == RightUpDirction then
		targetDirction = Up
	elseif dirction == BottomDirction or dirction == LeftBottomDirction or dirction == RightBottomDirction then
		targetDirction = Down
	elseif dirction == LeftDirction then
		targetDirction = Left
	else 
		targetDirction = Right
	end

	if not self.isHungry and #self.moveWaitingQueue < 1 then
		self.moveWaitingQueue[#self.moveWaitingQueue + 1] = targetDirction
		-- self.moveWaitingQueue[#self.moveWaitingQueue + 1] = targetDirction
		self.moveDirectionQueue[#self.moveDirectionQueue + 1] = dirction
		print("addMove",#self.moveWaitingQueue)
	elseif self.isHungry then
		print("addMoveERROR")
		return
	end

	self:startMapGuide(targetDirction)

	if self.isNeedGuide then
		return
	end

	--在移动和定位当中不执行任何jointed的移动
	if self.statue ~= "ready" then
		return
	end
	-- ToastUtil:toastString("点击移动")
	print("readys",#self.moveWaitingQueue,self.statue)
	self:tryToMoveForDirction(targetDirction)
end

function Explore:getCenterViewPositionByActualPosition( actualPosition )


	--获取当前屏幕中心的位置相对于movelayer上的哪个位置
	local viewCenter = getRelativePositionOfViewCenterByNode(self.moveLayer)
	-- print("viewCenter",viewCenter.x,viewCenter.y)
	--计算偏移量，用当前点减去目标点
	local contentOffset = cc.p(viewCenter.x - actualPosition.x,viewCenter.y - actualPosition.y)
	contentOffset.x = contentOffset.x * self.moveLayer:getScale()
	contentOffset.y = contentOffset.y * self.moveLayer:getScale()
	-- print("contentOffset",contentOffset.x,contentOffset.y)

	--用当前坐标加上偏移量即可得movelayer的位置
	viewCenter.x = self.moveLayer:getPositionX() + contentOffset.x
	viewCenter.y = self.moveLayer:getPositionY() + contentOffset.y

	--对最终目标点做限制
	--上边界检查，x和y任何一个不能大于可视区域的一半,否则看到的边界将会太大
	viewCenter.x = math.min(screenSize.width / 2,viewCenter.x)
	viewCenter.y = math.min(screenSize.height / 2,viewCenter.y)

	--下边界检查,x和y任何一个都不能小于可视区域的一半减去当前地图的大小，否则则会看到的边界超过屏幕大小的一半
	viewCenter.x = math.max(screenSize.width / 2 * self.moveLayer:getScale() - self.mapSize.width, viewCenter.x)
	viewCenter.y = math.max(screenSize.height / 2  * self.moveLayer:getScale() - self.mapSize.height, viewCenter.y)

	return viewCenter;
end

--直接跳置目标点，使其成为中心
function Explore:setViewpointCenter( position )
	
	local centerPositionPercent = cc.p(0,0)

	local centerPosition,centerPositionPercent = self:getCenterViewPositionByActualPosition(position)

	-- print("setViewpointCenter")

	-- for k,v in pairs(cc.ScrollView) do
		-- print(k,v)
	-- end

	-- self.scrollview:setContentOffset(centerPosition)
	self.contentOffset.x = 0
	self.contentOffset.y = 0

	self.jointed.enable = true

	self.moveLayer:setPosition(centerPosition);
end

function Explore:obtainTheOriginalMapSize(  )
	--重新初始化地图大小
	local tile_size = self.map:getTileSize().width

    --初始化地图的大小
    local mapWidth = self.map:getMapSize().width * self.map:getTileSize().width;
	
	local mapHeight = self.map:getMapSize().height * self.map:getTileSize().height;

	self.mapSize.width = mapWidth
	self.mapSize.height = mapHeight
end

function Explore:setZoomScale( scale )
	scale = self:checkMapScale(scale)

	--获得原始地图大小
	self:obtainTheOriginalMapSize()

	local viewCenter = getRelativePositionOfViewCenterByNode(self.moveLayer)
	-- print("setZoomScale:viewCenter",viewCenter.x,viewCenter.y)

	-- --改变地图大小
	self.mapSize.width = self.mapSize.width * scale
	self.mapSize.height = self.mapSize.height * scale
	-- local center = cc.p(self.mapSize.width / 2,self.mapSize.height / 2)
	-- center = self:convertToWorldSpace(center);
	-- print("zoomCenter",center.x,center.y)
	-- local oldCenter = self.moveLayer:convertToNodeSpace(center)
	-- print("oldCenter",oldCenter.x,oldCenter.y)
	self.moveLayer:setScale(scale)		

	local newCenter = getRelativePositionOfViewCenterByNode(self.moveLayer)
	-- print("setZoomScale:newCenter",newCenter.x,newCenter.y)
	local offset = cc.p(newCenter.x - viewCenter.x ,newCenter.y - viewCenter.y )

	offset.x = offset.x * scale
	offset.y = offset.y * scale
	-- local newCenter = self.moveLayer:convertToWorldSpace(oldCenter)
	-- print("newCenter",newCenter.x,newCenter.y)
	-- local offset = ccpSub(center,newCenter)
	-- print("offset",offset.x,offset.y)

	-- if offset.x == 0 and offset.y == 0 then
		-- print("ERROR offset")
	-- end
	
	self.moveLayer:setPosition(cc.p(self.moveLayer:getPositionX() + offset.x,self.moveLayer:getPositionY() + offset.y))

end

--缓慢移动到目标点，使其成为中心
function Explore:slowlyMoveViewpointCenter( position ,duration )
	
	-- print("slowlyMoveViewpointCenter",position.x,position.y)

	if position.x == 0 and position.y == 0 then
		--重置状态
		self.statue = "ready"
		return
	end

	local centerPositionPercent = cc.p(0,0)
	local centerPosition,centerPositionPercent = self:getCenterViewPositionByActualPosition(position)
	self.targetMovePosition = centerPosition;

	if duration == nil then

		-- local actionNum = self.moveLayer:getNumberOfRunningActions()

		-- if actionNum > 0 then
		-- 	local distance = getDistance(self.targetMovePosition,cc.p(self.moveLayer:getPosition()))

		-- 	duration = distance / self.mapMoveSpeed
		-- 	self.actionTime = duration
		-- else

		-- 	duration = moveTime * 2 - 0.5
		-- 	self.actionTime = duration
		-- end

		duration = moveTime
		-- local s = math.sqrt(math.pow(self.contentOffset.x,2) + math.pow(self.contentOffset.y,2))

		-- local speed = s * 0.6

		-- print("speed",speed)

		--限制速度不能小于60
		-- speed = math.max(speed,60)

		print("EaseExponentialOut")
		seq = cc.Sequence:create(cc.EaseExponentialOut:create(cc.MoveTo:create(duration, self.targetMovePosition)))
	else
		print("move")
		--计算时间
		duration = 0.3
		seq = cc.Sequence:create(cc.MoveTo:create(duration, self.targetMovePosition))

	end

	

	-- if self.targetMovePosition ~= cur_position then
	-- 	return
	-- end

	

	--时间限制
	-- duration = math.max(duration,0.1);

	-- print("self.scrollview:setContentOffsetInDuration",duration);

	-- self.scrollview:setContentOffsetInDuration(centerPosition,duration)

	-- self.scrollview:scrollToPercentBothDirection(centerPositionPercent,duration,true)

	-- --需要延迟一下，要不然玩家看不出来是先原点移动，才是屏幕移动
	-- local seq = cc.Sequence:create(cc.MoveTo:create(duration, self.targetMovePosition),cc.CallFunc:create(function ()
	-- 	self:moveEnd()
	-- end))

	-- check2dxLuaApi(cc.CallFunc)
	--执行动画
	self.moveLayer:runAction(seq) 
	local calSeq = cc.Sequence:create(cc.DelayTime:create(duration * 0.9),cc.CallFunc:create(function ()
			self:moveEnd()
		end))
	self:runAction(calSeq)
end

function Explore:moveEnd()

	if self == nil then
		return
	end

	-- print("moveEnd",self.statue)

	--若啥事件都不触发，就饿死回城
	if self:getNumberOfRunningActions() == 1 and self.isHungry == true and self.eventManger.eventWaitingQueue[1] == 0 then
		print("self.isHungry == true")		

		-- if DataManager:getInstance():getRoleData(roleMapInfo).mapIndex >= 2 then
			local _alert = AlertView:create(2, 2, "", function()
				-- 触发充值功能，充值成功之后请调用returnToBase
				purchase("4")

			end, function()

				--饿死的数据处理
				--安全删除默认的自带数据
				self.bagController:safeClearMissionData()
				--设置玩家状态为1(探索状态)
			    DataManager:getInstance():setRoleData(roleStatue,0)
			    DataManager:getInstance():setRoleData(roleBreadCostDecimal,0)
			     --清除地图关联信息
   				self:clearMapInfoData()

   				--添加死亡信息
   				self:addDeadData()

   				--背包数据清除金币
   				self.bagController:safeTransformCoinToPack(true)

				-- 点击不充值之后的结果
				local transformLayer = TransformLayer:create("由于缺少食物，您的舰队已消失在海上…...")
				transformLayer:setCalback(function()
					self:returnToBase("NoBread")
				end)

				--执行中转动画
				transformLayer:transform()
				-- self:returnToBase("NoBread")
			end, "确认死亡", "安全回城")
			_alert:setOkRemove(0)
			-- 添加提示框的叹号图
			local alertIcon = cc.Sprite:create("Images/charging/fuhuo_02.png")
			alertIcon:setPosition(cc.p(_alert.s_position.x - 180.0, _alert.s_position.y + 30.0))
			_alert:addChild(alertIcon, 1)

	        local showLabel1 = cc.LabelTTF:create("您的食物耗尽即将死亡，使\n使用1元直接回城，否则将\n会失去当前英雄及战利品", BoldFont, 30)
	        showLabel1:setColor(WriteColor)
	        showLabel1:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	        -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
	        showLabel1:setPosition(cc.p(_alert.s_position.x + showLabel1:getContentSize().width * 0.15, alertIcon:getPositionY()))
	        _alert:addChild(showLabel1, 1)
		-- else
			-- print("离开购买提示界面")
		-- 	-- 点击不充值之后的结果
		-- 	local transformLayer = TransformLayer:create("食物不足，战队英雄全部死亡…")
		-- 	transformLayer:setCalback(function (  )
		-- 		self:returnToBase("NoBread")
		-- 	end)

		-- 	--执行中转动画
		-- 	transformLayer:transform()
		-- 	-- self:returnToBase("NoBread")
		-- end
		return
	end
	print("curstatue",self.statue)
	if self.statue == "Location" then
		self.statue = "ready"
	end


	if self:getNumberOfRunningActions() == 1 then
		self.jointed:tipingByDirection()
	end

	if self.contentOffset == nil then
		return
	end
	self.contentOffset.x = 0
	self.contentOffset.y = 0

	self.jointed.enable = true

	local centerPosition = cc.p(self.player:getPositionX(),self.player:getPositionY())

	-- --为了防止玩家滑动，再重新set一下
	-- self:setViewpointCenter(centerPosition)
end

function Explore:tileCoordForTilePosition( position )
	-- print("orgposition",position.x,position.y)
	--将人物的目的的坐标的x轴坐标转换成瓦片地图中的x轴的坐标
	local  x = math.floor(position.x / self.map:getTileSize().width);
	--将人物的目的的坐标的y轴坐标转换成瓦片地图中的y轴的坐标
	local y = math.floor(position.y / self.map:getTileSize().height);
	-- print("tileCoordForTilePosition: ",x,y,self.map:getTileSize().width,self.map:getTileSize().height)
	return cc.p(x,y);
end

--获得地图坐标
function Explore:tileCoordForPosition( position ,isLimited)

	if isLimited == nil then
		isLimited = true
	end

	-- print("orgposition",position.x,position.y)
	--将人物的目的的坐标的x轴坐标转换成瓦片地图中的x轴的坐标
	local  x = math.floor(position.x / self.map:getTileSize().width);
	--将人物的目的的坐标的y轴坐标转换成瓦片地图中的y轴的坐标
	local y = math.floor(((self.map:getMapSize().height * self.map:getTileSize().height) - position.y) / self.map:getTileSize().height);
	
	-- if isLimited then
	-- 	x = math.max(0,x)
	-- 	x = math.min(x,self.map:getMapSize().width - 1)

	-- 	y = math.max(0,y)
	-- 	y = math.min(y,self.map:getMapSize().height - 1)
	-- end

	

	-- print("tileCoordForPosition: ",x,y)

	return cc.p(x,y);
end

--根据地图坐标获得真实坐标(中心坐标)
function Explore:positionForTilePosition( tilePosition)
	
	-- print("tilePosition: ",tilePosition.x,tilePosition.y)
	-- print("self.map:getTileSize()",self.map:getTileSize().width,self.map:getTileSize().height)
	local x = (tilePosition.x + 0.5) * self.map:getTileSize().width
	local y = self.map:getMapSize().height * self.map:getTileSize().height - (tilePosition.y + 0.5) * self.map:getTileSize().height

	-- print("positionForTilePosition: ",x,y)

	return cc.p(x,y)
end

--根据一个位置获得一个其所在准确位置
function Explore:coordinateStandardizationByPosition( position )
	
	local titlePosition = self:tileCoordForPosition(position)
	local coordinateStandardization = self:positionForTilePosition(titlePosition)

	return coordinateStandardization
end

function Explore:isBlock( position )
	-- body
end

function Explore:moveAudioEffect(  )
	
	if DataManager:getInstance():getSound_off() == 0 then
        AudioEngine.playEffect(EFFECT_walk, false)
    end

end


--移动统一接口
function Explore:tryToMoveForDirction( dirction,moveType )
	table.remove(self.moveWaitingQueue,1)
	self.jointed:tipingByDirection(self.moveDirectionQueue[1])
	table.remove(self.moveDirectionQueue,1)

	local x = 0
	local y = 0
	x,y = self.player:getPosition();
	local playerposition = cc.p(x,y);

	if moveType == nil then
		moveType = mapMoveType.all
	end

	if moveType ~= mapMoveType.moveAction then
		playerposition.x = playerposition.x + dirction.x;
		playerposition.y = playerposition.y + dirction.y;
	end

	-- print("playerposition",playerposition,x,y)

	local tilePosition = self:tileCoordForPosition(playerposition,false)

	-- print("mapsize",self.map:getMapSize().width,self.map:getMapSize().height,tilePosition.x,tilePosition.y)

	if (tilePosition.x > self.map:getMapSize().width - 1 or tilePosition.x < 0) or (tilePosition.y > self.map:getMapSize().height - 1 or tilePosition.y < 0) then
		return
	end

	 --获得阻碍层
    local blocks_1 = self.map:getLayer("Blocks_1")
    local blocks_2 = self.map:getLayer("Blocks_2")

	local blocksTitled_1 = blocks_1:getTileGIDAt(tilePosition)
	local blocksTitled_2 = nil

	if blocks_2 ~= nil then
		blocksTitled_2 = blocks_2:getTileGIDAt(tilePosition)
	end 

	local metaTileId = self.meta:getTileGIDAt(tilePosition)


	-- print("tileId!",blocksTitled_1,blocksTitled_2,metaTileId)
	local call = cc.CallFunc:create(function ( ... )
					self.eventManger:triggeringEventOfWating()
					-- print("addmove1111",#self.moveWaitingQueue)
					-- print("triggeringEventOfWating",self.statue)
					end)

	local delayTime = 0.4

	--获得对应坐标的tile属性
	if metaTileId and (blocksTitled_1 or blocksTitled_2) then
		-- print("getPropertiesForGIDP")

		local metaProperties = self.map:getPropertiesForGID(metaTileId);

		local blocksTitledProperties_1 = nil 
		local blocksTitledProperties_2 = nil

		if blocksTitled_1 then
			blocksTitledProperties_1 = self.map:getPropertiesForGID(blocksTitled_1)
		end
		
		if blocksTitled_2 then
			blocksTitledProperties_2 = self.map:getPropertiesForGID(blocksTitled_2)
		end

		-- print("properties!",metaProperties,blocksTitledProperties_1,blocksTitledProperties_2)

		if (blocksTitledProperties_1 ~= nil and blocksTitledProperties_1 ~= 0 and type(blocksTitledProperties_1) == "table") or (blocksTitledProperties_2 ~= nil and blocksTitledProperties_2 ~= 0 and type(blocksTitledProperties_2) == "table") then
			-- print("由于非法移动行动取消!")
			playerposition.x = x
			playerposition.y = y
			tilePosition = nil
			ToastUtil:toastString("前方有障碍，无法通过!")
		elseif metaProperties ~= nil and metaProperties ~= 0  then
			if type(metaProperties) == "table" then

				local eventId = metaProperties["eventid"]
				-- print("eventId ", eventId)
				if eventId ~= nil then
					self:moveAudioEffect()
					if moveType ~= mapMoveType.playerMove then
						self.eventManger:willTriggerEventById(eventId)
					end
					-- print("此次行动有效!")
					local seq = cc.Sequence:create(cc.CallFunc:create(function ( ... )
						self.player:setPosition(playerposition)
						-- self.moveWaitingQueue = {}
					end),cc.DelayTime:create(delayTime),call)
					self.player:runAction(seq)
					-- self.player:setPosition(playerposition)
					-- self:costbread()
				end

			elseif type(metaProperties) == "number" then
				-- print("此点是已经领取过的补给点，不用触发事件，直接略过!")
				self:moveAudioEffect()
				
				 

				if moveType ~= mapMoveType.playerMove then
					self.eventManger:willTriggerEventById(0)
					call = cc.CallFunc:create(function ( ... )
						self.statue = "ready"
						self.eventManger:triggeringEventOfWating()
						print("addmove1111",#self.moveWaitingQueue)
						self:checkMoveWaitingQueue(mapMoveType.all)
						print("triggeringEventOfWating",self.statue)
					end)
				end

  				self:costbread()

  				local seq = cc.Sequence:create(cc.CallFunc:create(function ( ... )
						self.player:setPosition(playerposition)
					end),cc.DelayTime:create(delayTime),call)
				self.player:runAction(seq)
  				-- self.player:setPosition(playerposition)
			end
  			
		else 
			 -- print("由于没有属性值，默认有效!")
  			--没有让其执行踩地雷事件
  			self:moveAudioEffect()
  			self.eventManger:willTriggerEventById(0)
  			self:costbread()
  			self.player:setPosition(playerposition)
  			local isMinesweeper = self.eventManger:minesweeper()
  			local seq = nil 

  			if isMinesweeper then
  				print("isMinesweeper",isMinesweeper)
  				seq = cc.Sequence:create(cc.CallFunc:create(function ( ... )
						self.player:setPosition(playerposition)
					end),cc.DelayTime:create(delayTime),call)
  			else

  				if moveType ~= mapMoveType.playerMove then
  					call = cc.CallFunc:create(function ( ... )
  						self.statue = "ready"
  						self.eventManger:triggeringEventOfWating()
  						print("addmove1111",#self.moveWaitingQueue)
						self:checkMoveWaitingQueue(mapMoveType.all)
						print("triggeringEventOfWating",self.statue)
					end)
  				end
  				
  				seq = cc.Sequence:create(cc.CallFunc:create(function ( ... )
						self.player:setPosition(playerposition)
					end),cc.DelayTime:create(delayTime),call)
  			end

			self.player:runAction(seq)
			-- self.player:setPosition(playerposition)
		end

		-- --Value也是个table
		-- if properties ~= nil and properties ~= 0 then
		-- 	local eventId = properties["eventid"]
			-- print("eventId ", eventId)
		-- 	--取消这次移动
		-- 	if eventId ~= nil and eventId == "1" then
				-- print("由于非法移动行动取消!")
		-- 		playerposition.x = x
		-- 		playerposition.y = y
		-- 		tilePosition = nil
		-- 	--否则执行这次行动
		-- 	else
		-- 		self.eventManger:willTriggerEventById(eventId)
				-- print("此次行动有效!")
		-- 		self.player:setPosition(playerposition)
		-- 		self:costbread()
		-- 	end
		-- 	-- for k,v in pairs(properties) do
   --  			print(k,v)
  --  --  		end
  -- 		else
  			-- print("由于没有属性值，默认有效!")
  -- 			--没有让其执行踩地雷事件
  -- 			self.eventManger:willTriggerEventById(0)
  -- 			self.eventManger:minesweeper()
		-- 	self.player:setPosition(playerposition)
		-- 	self:costbread()
		-- end
			
	end

	if moveType ~= mapMoveType.moveAction and tilePosition ~= nil then
		self.playerTitlePosition = tilePosition
		-- print("titlePosition ~= nil",tilePosition.x,tilePosition.y)
		local realVision = (self.visition + addVision) * 2
		self.playerRect = cc.rect(tilePosition.x,tilePosition.y,realVision,realVision)
		self:checkClearFogs()
		self:clearFogs()

		--若状态不为饥饿状态刷新玩家位置
		if not self.isHungry then
			self.mapLayoutManagers:stopAllActions()
			if not self.isNeedGuide then
				local seq = cc.Sequence:create(cc.DelayTime:create(moveTime),cc.CallFunc:create(function ( ... )
				-- print("savePos",self.playerTitlePosition.x,self.playerTitlePosition.y)
					local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
					tempData.playerTitlePosition = self.playerTitlePosition
					DataManager:getInstance():setRoleData(roleMapInfo,tempData)
				end))
				self.mapLayoutManagers:runAction(seq)
			else
				local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
				tempData.playerTitlePosition = self.playerTitlePosition
				DataManager:getInstance():setRoleData(roleMapInfo,tempData)
			end
		end

		-- print("写入玩家地图坐标",tempData.playerTitlePosition.x,tempData.playerTitlePosition.y,playerposition.x,playerposition.y)
	elseif moveType == mapMoveType.moveAction then
		
	end

	

	if moveType ~= mapMoveType.moveAction and playerposition.x == x and playerposition.y == y then
		print("ERROR return",moveType)
		return
	end

	-- print("will lookAt")

	if moveType ~= mapMoveType.playerMove then
		self.actionTime = 0

		--执行移动
		self:lookAtViewPointCenter(playerposition)
	end

end

function Explore:lookAtViewPointCenter( position )
	self.statue = "lookAt"
	-- print("start lookAt")

	local curPos = self.moveLayer:getPosition()

	self.moveLayer:stopAllActions()
	self:slowlyMoveViewpointCenter(position)
end

function Explore:costbread( )
	-- print("breadCoefficient",breadCoefficient)
	--消耗面包,后面0以后用耐饿天赋代替
	local costDecimal = 1 - breadCoefficient;
	-- costDecimal = 0;
	self.breadCostDecimal = self.breadCostDecimal + costDecimal
	-- print("costbread",self.breadCostDecimal,costDecimal)

	local temp = self.bagController:getBreads()

	--若玩家已经拾取更多的面包了，则即可清空之前的breadCostDecimal,让其面包等于0了，可以继续走3步
	if self.breadNum == 0 and self.breadNum < temp then
		self.breadCostDecimal = 0
	end

	self.breadNum = temp
	-- print("Explore:costbread",self.breadNum)
	if self.breadCostDecimal >= 1 then
		self.bagController:costGoodsByGoodsIdAndNum(1005,1,false)
		self.breadNum = self.breadNum - 1

		if self.breadNum < 0 then
			self.breadNum = 0
		else
			self.breadCostDecimal = self.breadCostDecimal - 1
		end

		self:checkBread()
	end
	-- print("costbreadover",self.breadCostDecimal)
	self.bread:setString(string.format("  %d",self.breadNum))

    if self.breadNum < 10 then
        self.bread:setColor(opColorRed)
    else
        self.bread:setColor(opColorPrimroseYellow)
    end

	if self.breadNum == 0 and self.breadCostDecimal ~= 0 then
		self.breadCostDecimal = self.breadCostDecimal + 0.5
	end

	
	if self.breadCostDecimal > 3 then
		self.isHungry = true
	else
		DataManager:getInstance():setRoleData(roleBreadCostDecimal,self.breadCostDecimal)
	end
end

function Explore:updataCapacityTips( costSpace,capacity )
	
	if self.capacityTips then
		self.capacityTips:setString(string.format("%d/%d",costSpace,capacity))
	end

end

function Explore:updataOccupation(  )
	local roleExtentNum = DataManager:getInstance():getRoleData(roleExtents)

  	self.occupation = roleExtentNum

  	self.occupationNum:setString(" "..tostring(self.occupation))

  	--探索成就进度触发且添加探索度
	achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Exploration)
	DataManager:getInstance():setAchievementInfo(achievement_Exploration, (achievementValue + 1))

	-- --获取探索度
	-- local roleExtentNum = DataManager:getInstance():getRoleData(roleExtents)
	-- if roleExtentNum == nil then
	-- 	roleExtentNum = 0
	-- end

	-- if isUpdateTotalExtent then
	-- 	roleExtentNum = roleExtentNum + dis
	
	-- 	--跟新新探索度
	-- 	DataManager:getInstance():setRoleData(roleExtents,roleExtentNum)
		-- print("新总探索度",roleExtentNum)
	-- end
end

function Explore:updataExtent( isUpdateTotalExtent )

	if isUpdateTotalExtent == nil then
		isUpdateTotalExtent = true
	end

	local fogs = ExploreDataManager:getInstance():getFogs()
	local totalNum = self.map:getMapSize().width * self.map:getMapSize().height

	-- print("updataExtent",fogs,totalNum,isUpdateTotalExtent)

	--若是初始化迷雾，则全部添加，否则直接变成当前self.extent
	if self.isInitFogs then
		lastExtent = 0
	else 
		lastExtent = self.extent
	end

	
	self.extent = math.floor(fogs / totalNum * 100) 

	local dis = self.extent - lastExtent

	-- print(self.extent)
	self.extentTip:setString(string.format("  %d",self.extent).."%")
end

function Explore:minesweeperTip( )
	
	if self.isHungry == true then
		return
	end

	-- print("Explore:minesweeperTip")



	local tips = cc.LabelTTF:create("WOW！", BoldFont, screenSize.height * 0.04)
	tips:setPosition(cc.p(self.player:getContentSize().width + tips:getContentSize().width / 2,self.player:getContentSize().height + tips:getContentSize().height / 2))
	self.player:addChild(tips)

	local seq = cc.Sequence:create(cc.ScaleTo:create(0.02,2.0),cc.ScaleTo:create(0.02,1.2),cc.DelayTime:create(0.0),cc.CallFunc:create(function (tips)
		self:minesweeperTipOver(tips)
	end))

	-- local seq = cc.Spawn:create(move, fade)

	-- print("seq");
	tips:runAction(seq)
end

function Explore:minesweeperTipOver( tips )
	tips:removeFromParent()
	self.eventManger:minesweeperFight()
end

--检查是否开启战争迷雾(通知迷雾管理器进行检查)
function Explore:checkClearFogs( )
	-- print("checkClearFogs")
	self.fogManager:tryToClearFogByRect(self.playerRect)
end

--移动之后通知地图管理器对之前的分析的迷雾数据进行清楚
function Explore:clearFogs( isUpdateTotalExtent )

	local clearFogs = self.fogManager:getClearFogs()
	local roundFogs =  self.fogManager:getRoundFogs()
	-- print("clearFogsLen",#clearFogs,clearFogs[1],isUpdateTotalExtent,roundFogs)
	local position = nil
	for i=1,#clearFogs do
		position = clearFogs[i]
		-- print("will search clearFogs[i]")

		-- print("int ",position,clearFogs[i],i)
		self:changeFogByPosition(position)
	end

	local gidKey = nil
	-- print("对周边迷雾布局",#roundFogs)
	for i=1,#roundFogs do
		position = roundFogs[i].position
		gidKey = roundFogs[i].gidKey
		-- print("迷雾位置和id",position.x,position.y,gidKey)
		self:changeFogByPosition(position,gidKey)
	end

	self.fogManager:clearClearFogs()
	self:updataExtent(isUpdateTotalExtent)
end

--改变坐标的迷雾
function Explore:changeFogByPosition( position,fogGidKey )
	
	if fogGidKey == nil then
		fogGidKey = "0"
	end

	-- print("changeFogByPosition",position.x,position.y,FogGids[tostring(fogGidKey)])
	self.fogLayer:setTileGID(FogGids[tostring(fogGidKey)],position)
end

--淡出对应坐标的迷雾
function Explore:fadeFogByPosition( position )
	
	if position == nil then
		return
	end

	local fog = self.fogLayer:getTileAt(position)

	if fog then
		fog:runAction(cc.FadeOut:create(0.5))
	end
end

--占据某个据点
function Explore:tileHasBeenOccupiedByTitlePosition( titlePosition)
	
	if titlePosition == nil then
		titlePosition = self.playerTitlePosition
	end
	--通知地图布局者跟新数据，并且获得对应的图片id
	local gid = self.mapLayoutManagers:setTheOccupationAndModifyTheDataByIdAndPosition(self.eventManger.curEventId,titlePosition)

	--刷新地图id
	self:changeTitleByTitlePosition(titlePosition,gid)

end

--改变某个位置的图块信息
function Explore:changeTitleByTitlePosition( titlePosition ,gid)
	
	if titlePosition == 0 or self.map == nil then
		return
	end

	print("changeTitleByTitlePosition",gid,titlePosition.x,titlePosition.y)



	-- local titleinfo = self.meta:getTileSet()
	-- print("titleinfo",titleinfo)
	-- for k,v in pairs(cc.TMXTilesetInfo) do
		-- print(k,v)
	-- end

	-- check2dxLuaApi(cc.Node)
	if gid == nil then
		gid = 42
	end
	self.meta:setTileGID(gid,titlePosition)

end

--[[
1···白色
2···绿色
3···蓝色
4···紫色
5···橙色
6···红色
]]

function Explore:showStrongholdTipAction( pos,tid )
	if tonumber(tid) > -1 or not pos then
		self:hideStrongholdTipAction(pos)
		return
	end

	local color = nil

	local posKey = string.format("_%d_%d",pos.x,pos.y)

	if tid == "-1" then
		color = cc.c3b(255,255,255)
	elseif tid == "-2" then
		color = cc.c3b(43,229,0)
	elseif tid == "-3" then
		color = cc.c3b(37,88,255)
	elseif tid == "-4" then
		color = cc.c3b(229,0,221)
	elseif tid == "-5" then
		color = cc.c3b(255,157,42)
	elseif tid == "-6" then
		color = cc.c3b(255,37,37)
	end

	local target = self.meta:getTileAt(pos)
	local x = target:getPositionX() + target:getContentSize().width / 2
	local y = target:getPositionY() + target:getContentSize().height / 2
	-- target:setColor(color)

	local call1 = cc.CallFunc:create(function (  )
            -- target:setOpacity(255)
            target:setScale(0.4)
        end)

	local haloTime = 2
	local delayTime = 0.5

    --白光的效果扩大加谈出
    local scale = cc.ScaleTo:create(haloTime,2.4)
    local fadeIn = cc.FadeIn:create(haloTime / 2)
    local fadeOut = cc.FadeOut:create(haloTime / 2)
    local fadeAction = cc.Sequence:create(fadeIn, fadeOut)
    local spawn = cc.Spawn:create(scale, fadeAction)
    local seq = cc.Sequence:create(call1, spawn,cc.DelayTime:create(delayTime))
    local action = cc.RepeatForever:create(seq)

    local halo = cc.Sprite:create("Images/Map/huanguang_015.png")
    halo:setPosition(cc.p(x,y))
    halo:setScale(0.6)
    halo:setColor(color)
    halo:setOpacity(0)
    self.halos[posKey] = halo
    self.moveLayer:addChild(halo)

    halo:runAction(action)
    target = halo

    local center = cc.Sprite:create("Images/Map/shanguang_014.png")
    center:setPosition(cc.p(x,y))
    center:setOpacity(40)
    center:setScale(0.6)
    center:setColor(color)
    self.effectsCenters[posKey] = center
    self.moveLayer:addChild(center)

    local call1 = cc.CallFunc:create(function (  )
            center:setOpacity(40)
            center:setScale(0.6)
        end)

    --白光的效果扩大加谈出
    local scale = cc.ScaleTo:create(haloTime + delayTime,2.4)
    local fadeOut = cc.FadeTo:create(haloTime + delayTime,180)
    local rotate = cc.RotateBy:create(haloTime + delayTime,360)
    local spawn = cc.Spawn:create(scale, fadeOut,rotate)
    local seq = cc.Sequence:create(call1, spawn)
    local action = cc.RepeatForever:create(seq)
    center:runAction(action)

    local particleColor = cc.c4f(color.r/255, color.g/255, color.b/255, 1)
    local particle = cc.ParticleSystemQuad:create("Images/Map/Particles/baise.plist")
    particle:setPosition(cc.p(x,y))
    particle:setStartColor(particleColor)
    particle:setEndColor(particleColor)
    particle:setPositionType(1)
    self.particles[posKey] = particle
    self.moveLayer:addChild(particle)
end

function Explore:hideStrongholdTipAction( pos )

	if not pos then
		return
	end

	local posKey = string.format("_%d_%d",pos.x,pos.y)

	local target = self.halos[posKey]

	if not target then
		return
	end

	target:removeFromParent()
	self.halos[posKey] = nil

	target = self.effectsCenters[posKey]
	target:removeFromParent()
	self.effectsCenters[posKey] = nil

	target = self.particles[posKey]
	target:removeFromParent()
	self.particles[posKey] = nil
end

function Explore:destory( )
	if self ~= nil then
        if self:getParent() ~= nil then
            cclog("MAP:我自由了！")
            self:removeFromParent()
        end
        -- DataManager:getInstance():unregisterEvent("kBuyBackSuccess", "Explore")
        -- DataManager:getInstance():unregisterEvent("kBuyBackFailed", "Explore")
    end
end

--背包界面接口
function Explore:goBag( )
	-- self.fogLayer:setVisible(not self.fogLayer:isVisible())
    
    
    -- local pkgData = {}
	-- local data = clone(DataManager:getInstance():getRoleData(roleBattlePack))
	-- for key, value in pairs(data) do
 --        local pData = {}
	-- 	pData.name = dataController.getResourceValueByIdAndKey(value.id, "name")
 --        pData.icon = dataController.getResourceValueByIdAndKey(value.id, "iconName")
 --        pData.star = tonumber(dataController.getResourceValueByIdAndKey(value.id, "starNum"))
	-- 	pData.num = value.num
 --        pData.id = value.id
 --        pkgData[#pkgData+1] = pData
	-- end
	--获取战斗背包信息
	pkgData = self.bagController:getAllDataInfo()

    -- printn(pkgData)
    
    EventDetailsLayer.type = 4
    EventDetailsLayer.data = {}
    for k, v in pairs(pkgData) do
        if v ~= nil and v.num > 0 then
            EventDetailsLayer.data[#EventDetailsLayer.data+1] = v
        end
    end
    
    local pubLayer = EventDetailsLayer:create()
    pubLayer:setPosition(cc.p(0, 0))
    local gameScene = cc.Director:getInstance():getRunningScene()
    if gameScene ~= nil then
        gameScene:addChild(pubLayer)
    else
        gameScene = cc.Scene:create()
        gameScene:addChild(pubLayer)
        cc.Director:getInstance():runWithScene(gameScene)
    end
end

function Explore:showCurMapStrategy(  )
	local allTips = DataManager:getInstance():getCSVByID(csvOfMapStrategy)

	local tips = allTips[tostring(self.mapIndex)]["Tips"]

	local tipView = AlertView:create(3,1,"本图攻略",function (  )
	end)

	local mapTip = ""
	local tip = nil

	for i=1,#tips do
		if i ~= 1 then
			mapTip = string.format("%s\n\n",mapTip)
		end

		tip = tips[i][1]

		mapTip = string.format("%s%s",mapTip,tip)

	end

	local tipLabel = cc.LabelTTF:create(mapTip, BoldFont, 30)
	tipLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	tipLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	tipLabel:setColor(cc.c3b(196, 213, 215))
	tipLabel:setDimensions(cc.size(tipView.s_size.width * 0.94,cc.Director:getInstance():getVisibleSize().height))
        -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    tipLabel:setPosition(cc.p(tipView.s_position.x, tipView.s_position.y))
        -- print("showLabel1 will add")
    tipView:addChild(tipLabel)

end

--添加死亡数据
function Explore:addDeadData(  )
	local DeathInformation = DataManager:getInstance():getRoleData(roleDeathInformation)
	-- print("addDeadData",roleDeathInformation)
	
	if DeathInformation == nil then
		DeathInformation = {}
	end

	local tempData = nil
	local infoData = nil
	for i=1,#self.playerfighters do
		tempData = self.playerfighters[i]
        infoData = dataController.getSoilderInfoById(tempData.id)
        local isExist = false
        for key, value in pairs(DeathInformation) do
            if value ~= nil and value.id == tempData.id then
                value.num = value.num + tempData.num
                isExist = true --非兵种
                break
            end
        end
        if not isExist then -- 添加新兵种
            local name = infoData["name"]
            local hp = infoData["hp"]
            local atk = infoData["attack"]
            local star = infoData["star"]
            local speed = infoData["speed"]
            local skill = infoData["skill"]
            local icon = infoData["icon"]
            local skillName = dataController.getSkillValueByIdAndKey(skill, "name")
            local rebornData = infoData["rebornConsume"]
            local costData = rebornData[1]
            local costId = costData[1]
            local costName = dataController.getResourceValueByIdAndKey(costId,"name")
            local costNum = costData[2]
            
            local value = {}
            --基础数据
            value.id = tempData.id
            value.name = name
            value.num = tempData.num
            value.hp = hp
            value.icon = icon
            value.star = star
            value.attack = atk
            value.speed = speed
            value.skill = skill
            value.skillName = skillName
            
            --复活需要的数据
            value.cost = {}
            value.cost.id = costId
            value.cost.name = costName
            value.cost.costNum = costNum
            
            DeathInformation[#DeathInformation + 1] = value
        end
        
		--从战斗数据中删除对应的兵
		-- DataManager:getInstance():addSoilderWithId(tempData.id, -tempData.num)
	end
	DataManager:getInstance():setRoleData(roleDeathInformation, DeathInformation)
	DataManager:getInstance():setRoleData(roleBattlePack,{})
	--清除战斗人员数据
	DataManager:getInstance():setRoleData(roleBattleQueue,{})

	self.playerfighters = {}
end

function Explore:getbackObjectStr()
	-- body
	local showstr = ""
	--战斗背包
	battlePackData = DataManager:getInstance():getRoleData(roleBattlePack)

	for k,v in pairs(battlePackData) do
		-- print(k,v)
		local pData = {}
		pData.name = dataController.getResourceValueByIdAndKey(k, "name")
		pData.num = v.num
		showstr = showstr.." "..pData.name.."*"..pData.num
	end
	return showstr
end
--清除地图关联信息
function Explore:clearMapInfoData( isChangeMapIndex )

	tempData = DataManager:getInstance():getRoleData(roleMapInfo)
    tempData.playerTitlePosition = nil
    DataManager:getInstance():setRoleData(roleMapInfo,tempData)

    local restrictions = DataManager:getInstance():getRoleData(roleBlackMarketRestrictions)


    --清空临时黑市限制数据
    if not isChangeMapIndex and restrictions and restrictions.tempRestrictions then
    	restrictions.tempRestrictions = nil
    	DataManager:getInstance():setRoleData(roleBlackMarketRestrictions,restrictions)
    end
end

--根据状态返回主城
function Explore:returnToBase( statue )
	--安全删除默认的自带数据
	self.bagController:safeClearMissionData()
	-- 设置是否进入过地图了（首次出征返回）
	GuideController:getInstance():addStep(60)
	--设置玩家状态为1(探索状态)
    DataManager:getInstance():setRoleData(roleStatue,0)
    DataManager:getInstance():setRoleData(roleBreadCostDecimal,0)
    --清除地图关联信息
   self:clearMapInfoData()

	--正常返回
	if statue == nil then
		local showstr = "您的舰队本次出征,带回了"
		showstr = showstr..self:getbackObjectStr()
		DataManager:getInstance():sendSystemInfo(showstr)
	--全员阵亡
	elseif statue == "Killed" then
		-- print("战死")
		--添加死亡数据
		self:addDeadData()
		DataManager:getInstance():sendSystemInfo("您的勇士已全部战死，同时失去了所有的战利品！您可以提升战船、转职英雄或来提升战斗力！")
		--粮食用尽
	elseif statue == "NoBread" then 

		-- print("饿死")
		-- if 1 then
		-- 	return
		-- end
		--添加死亡数据
		self:addDeadData()
		DataManager:getInstance():sendSystemInfo("您的舰队食物不足，消失在茫茫海上，所有勇士及战利品全部丢失！您可以升级货仓提升食物携带数量，也可以进入已被您占领的据点获得食物补给")
		--使用回城卷轴
	else 

	end

	self.bagController:safeTransformCoinToPack(statue)
	self.moveLayer:stopAllActions()

	--清除临时领取数据
	DataManager:getInstance():setRoleData(roleTempReceivedDatas,nil)
	DataManager:getInstance():mixPackAndSoildier()

	--清楚之前战斗的数据
	FightDataManager:getInstance():clearAllData()
	EternalArenaController:getInstance():destoryEternalArenaController()
	self.bagController:destoryController()
	-- print("存当")
	-- self.eventManger:saveEventData()
	-- self.fogManager:saveFogDatas()
	-- self.mapLayoutManagers:saveData()
	-- print("存当完毕")
	--以防异常关闭，导致touch的全局变量还在
	clearAllTouchArgs(self)
	isEnterMap = false
	gotoMainUI(true)
end


