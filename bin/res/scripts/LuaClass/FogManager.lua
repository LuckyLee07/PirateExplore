require "LuaClass/Header"

--[[
	迷雾刷新逻辑，每边的迷雾有个刷新方向，然后根据对应迷雾属性(也就是说把迷雾图块分成2*2的格子,有黑的地方计算)，
    根据刷新方向后和所需的值改变成什么样子
]]

--迷雾图块id
FogGids = {}

--右下白
FogGids["7"] = 1
--正底部白
FogGids["3"] = 2
--左下部白
FogGids["11"] = 3
--左上大白
FogGids["8"] = 4
--正上白
FogGids["12"] = 5
--右上大白
FogGids["4"] = 6
--正右白
FogGids["5"] = 7
--全白
-- FogGids.clearFog = 8
FogGids["0"] = 8
--正左白
FogGids["10"] = 9
--对角黑
FogGids["9"] = 10
--全黑
FogGids["15"] = 11
--对角黑
FogGids["6"] = 12
--右上白
FogGids["13"] = 13
-- --正上白
-- FogGids["12"] = 14
--左上白
FogGids["14"] = 15
--左下大白
FogGids["2"] = 16
--右下大白
FogGids["1"] = 18





--点的状态，起始点，过度点，结束点
PointStatue = {Start = 1,Mid = 2, End = 3}

--迷雾刷新方向
FogDirction = {}
FogDirction.leftVertical = 2
FogDirction.rightVertical = -2
FogDirction.topHorizontal = 1
FogDirction.bottomHorizontal = -1


--迷雾状态
FogStatue = class("FogStatue",function ()
	 return {}
end)

FogStatue.__index = FogStatue
FogStatue.leftTop = 0
FogStatue.rightTop = 0
FogStatue.leftBottom = 0
FogStatue.rightBottom = 0
FogStatue.allNum = 0
FogStatue.position = cc.p(0,0)

function FogStatue:create( Id,position )
		fogStatue = FogStatue.new()
	
		if fogStatue and fogStatue:init(Id,position) then
			return fogStatue
		end

	return fogStatue;
end

--根据一个数，抽离出各个定点的数
function FogStatue:init( Id,position )
	self.position = position
	if Id ~= nil then
		self:setFogId(Id)
	end
	return true
end

local function clearAll( target )
	target.leftTop = 0 
	target.leftBottom = 0
	target.rightTop = 0 
	target.rightBottom = 0

	target.allNum = 0
end

--0为透明，1为黑
local function setFogId( target,Id )

	Id = tonumber(Id)

	if Id == 0 then
		clearAll(target)
		return
	elseif Id == 15 then
		target.leftTop = 1 
		target.leftBottom = 1
		target.rightTop = 1 
		target.rightBottom = 1

		target.allNum = 15
		return
	end

	--获得左上顶点的值
	local tempNum1 = shift(Id,-1) 
	target.leftTop = Id - tempNum1 * 2
	-- print("self.leftTop",self.leftTop,tempNum1)
	--获得右上顶点的值
	local tempNum2 = shift(Id,- 2) 
	target.rightTop = tempNum1 - tempNum2 * 2
	-- print("self.rightTop",self.rightTop,tempNum2)
	--获得左下顶点的值
	local tempNum3 = shift(Id,- 3) 
	target.leftBottom = tempNum2 - tempNum3 * 2
	-- print("self.leftBottom",self.leftBottom,tempNum3)
	--获得右下顶点的值
	local tempNum4 = shift(Id,- 4) 
	target.rightBottom = tempNum3 - tempNum4 * 2
	-- print("self.rightBottom",self.rightBottom,tempNum4)
	target.allNum = target.leftTop * 1 + target.rightTop * 2 + target.leftBottom * 4 + target.rightBottom * 8
	-- print("FogStatue",self.allNum,Id)

	
end

local function refreshFogId( target )
	target.allNum = target.leftTop * 1 + target.rightTop * 2 + target.leftBottom * 4 + target.rightBottom * 8
	-- print("refreshFogId",target.allNum , target.leftTop  , target.rightTop, target.leftBottom  ,target.rightBottom )
end

local function getFogId( target )
	
	return target.allNum

end

local function checkEmptyByDirction( target,dirction )
	local result = false
		if dirction == "top" then
			result = target.leftTop + target.rightTop == 0
		elseif dirction == "bottom" then 
			result = target.leftBottom + target.rightBottom == 0
		elseif dirction == "left" then
			result = target.leftTop + target.leftBottom == 0
		elseif dirction == "right" then
			result = target.rightTop + target.rightBottom == 0
		end

	return result
end




--刷新规律
--[[
	纵向:先左边由下到上纵向刷新，在由右边由下到上纵向刷新
	
	横向:先由底部由左到右横向移动，在由顶部左到右横向移动

]]

local function tryChangeStatueByDirction( target,allStatues,dirction,vertices )
	clearAll(target)
	local cur_target = nil

	if vertices == nil then
		vertices = PointStatue.Mid
	end

	-- print("tryChangeStatueByDirction",dirction,vertices)

	--左边纵向刷新
	if dirction == FogDirction.leftVertical then
		-- --由于是下到上刷新且是在左边，则左边下面必须有黑色
		-- self.leftBottom = 1

		

		--一开始就需要判断是否可以衔接，若不能，改变对应的状态，起始点，或者结束点
		-- if vertices == PointStatue.Mid then

			local up = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]

			local down = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]

			if (up == nil) or (up ~= nil and checkEmptyByDirction(up,bottom)) then
				vertices = PointStatue.End
			elseif (down == nil) or (down ~= nil and checkEmptyByDirction(down,top)) then
				vertices = PointStatue.Start
			end

		-- end

		--开始根据节点状态进行判断
		--起始点(3个点可填值)
		if vertices == PointStatue.Start then
			-- print("enter Start")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]
			-- print("enter Start",getFogId(cur_target))
			if cur_target.leftBottom ~= 0 then 
				target.leftTop = 1
				-- print("self.leftTop = 1")
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]
			-- print("enter Start",getFogId(cur_target))
			if cur_target ~= nil then
				if cur_target.rightBottom ~= 0 then
					target.leftBottom = 1
					-- print("self.leftBottom = 1")
				end
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]
			-- print("enter Start",getFogId(cur_target))
			if cur_target ~= nil  then 
				if cur_target.leftBottom ~= 0 then
					target.rightBottom = 1
					-- print("self.rightBottom = 1")
				end
			end


		--过度点(2个点可填值)
		elseif vertices == PointStatue.Mid then
			-- print("enter Mid")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]
			-- print("enter Mid",cur_target.leftTop)
			if cur_target.leftTop ~= 0 then
				target.leftBottom = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]			
			-- print("enter Mid",cur_target.leftBottom)
			if cur_target.leftBottom ~= 0 then 
				target.leftTop = 1
			end

		--结束点(3个点可填值)
		elseif vertices == PointStatue.End then
			-- print("enter End")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]
			-- print("enter End",getFogId(cur_target),cur_target.leftBottom)
			if cur_target ~= nil and cur_target.leftBottom ~= 0 then
				cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]
				if cur_target ~= nil and cur_target.rightTop ~= 0 then
					target.leftTop = 1
				end
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]
			-- print("enter End",getFogId(cur_target),cur_target.leftTop)
			if cur_target.leftTop ~= 0 then
				target.leftBottom = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]
			-- print("enter End",getFogId(cur_target),cur_target.rightTop)
			if cur_target ~= nil and cur_target.leftTop ~= 0 then
				target.rightTop = 1
			end

		end

	--右边纵向刷新
	elseif dirction == FogDirction.rightVertical then


			local up = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]

			local down = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]

			if (up == nil) or (up ~= nil and checkEmptyByDirction(up,bottom)) then
				vertices = PointStatue.End
			elseif (down == nil) or (down ~= nil and checkEmptyByDirction(down,top)) then
				vertices = PointStatue.Start
			end

		-- end

		--开始根据节点状态进行判断
		--起始点(3个点可填值)
		if vertices == PointStatue.Start then
			-- print("FogDirction.rightVerticalStart")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]

			if cur_target.rightBottom ~= 0 then 
				target.rightTop = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]

			if cur_target ~= nil then
				if cur_target.leftBottom ~= 0 then
					target.rightBottom = 1
				end
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]

			if cur_target ~= nil  then 
				if cur_target.rightBottom ~= 0 then
					target.leftBottom = 1
				end
			end


		--过度点(2个点可填值)
		elseif vertices == PointStatue.Mid then
			-- print("FogDirction.rightVerticalMid")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]
				
			if cur_target.rightTop ~= 0 then
				target.rightBottom = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]			

			if cur_target.rightBottom ~= 0 then 
				target.rightTop = 1
			end

		--结束点(3个点可填值)
		elseif vertices == PointStatue.End then
			-- print("FogDirction.rightVerticalEnd")
			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y - 1)]

			if cur_target ~= nil and cur_target.rightBottom ~= 0 then
				cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]
				if cur_target ~= nil and cur_target.leftTop ~= 0 then
					target.rightTop = 1
				end
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x,target.position.y + 1)]

			if cur_target.rightTop ~= 0 then
				target.rightBottom = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]
			
			if cur_target ~= nil and cur_target.rightTop ~= 0 then
				target.leftTop = 1
			end

		end

	--顶部横向刷新
	elseif dirction == FogDirction.topHorizontal then
		
		local left = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]

		local right = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]


		if (left == nil) or (left ~= nil and checkEmptyByDirction(left,right)) then
			vertices = PointStatue.Start
		elseif (right == nil) or (right ~= nil and checkEmptyByDirction(right,left)) then
			vertices = PointStatue.End
		end


		if vertices == PointStatue.Start then
			-- print("FogDirction.topHorizontalStart",target,allStatues,FogDirction.leftVertical,PointStatue.End)
			--顶部的左边的起始点等于左边的终止点
			tryChangeStatueByDirction(target,allStatues,leftVertical,PointStatue.End)

		elseif vertices == PointStatue.Mid then

			cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]
			-- print("PointStatue.Mid",cur_target.rightTop)
			if cur_target ~= nil and cur_target.rightTop ~= 0 then
				target.leftTop = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]
			-- print("PointStatue.Mid",cur_target.leftTop)
			if cur_target ~= nil and cur_target.leftTop ~= 0 then
				target.rightTop = 1
			end

		elseif vertices == PointStatue.End then
			-- print("FogDirction.topHorizontalEnd")
			--顶部的右边的截至等于右边的终止点
			tryChangeStatueByDirction(target,allStatues,rightVertical,PointStatue.End)
		end


	--底部横向刷新	
	elseif dirction == FogDirction.bottomHorizontal then

		local left = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]

		local right = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]


		if (left == nil) or (left ~= nil and checkEmptyByDirction(left,right)) then
			vertices = PointStatue.Start
		elseif (right == nil) or (right ~= nil and checkEmptyByDirction(right,left)) then
			vertices = PointStatue.End
		end


		if vertices == PointStatue.Start then
			--底部的左边的起始点等于左边的起始点
			tryChangeStatueByDirction(target,allStatues,leftVertical,PointStatue.Start)

		elseif vertices == PointStatue.Mid then

			cur_target = allStatues[string.format("_%d_%d",target.position.x - 1,target.position.y)]

			if cur_target ~= nil and cur_target.rightBottom ~= 0 then
				target.leftBottom = 1
			end

			cur_target = allStatues[string.format("_%d_%d",target.position.x + 1,target.position.y)]

			if cur_target ~= nil and cur_target.leftBottom ~= 0 then
				target.rightBottom = 1
			end

		elseif vertices == PointStatue.End then
			--底部的右边的截至等于右边的起始点
			tryChangeStatueByDirction(target,allStatues,rightVertical,PointStatue.Start)
		end
	end

	refreshFogId(target)

	-- return vertices
end


allFogStatues = {}


FogManager = class("FogManager",function ()
	 return cc.Layer:create()
end)

FogManager.__index = FogManager
FogManager.owner = nil
FogManager.data = nil
FogManager.clearFogs = {}
--迷雾层空白迷雾周围的迷雾信息
FogManager.roundFogs = {}


-- EventManger.curEventId

function FogManager:create()
	-- print("FogManager:create()!");

	local fogManager = FogManager.new()
	
	if fogManager and fogManager:init() then
		return fogManager
	end

	return nil;
end

function FogManager:init()
    -- print("FogManager:init!");
    -- self:getFogDatasByMapIndex(0)
    return true;
end

--根据地图索引获得迷雾数据并刷新地图迷雾
function FogManager:getFogDatasAndClearFogsByMapIndex( mapIndex )
	-- print("getFogDatasAndClearFogsByMapIndex")
	self.data = ExploreDataManager:getInstance():getCurMapFogData() 

	-- self.data = getCurMapDatas().mapFogDatas
	-- printn(getCurMapDatas())
	--清空之前的迷雾状态
	allFogStatues = nil 
	allFogStatues = {}
	-- self.data = nil 

	-- if self.data ~= nil then
	-- 	-- print("self.data.clearStrongHoldNum",self.data.clearStrongHoldNum)
	-- end

	-- for i=0,15 do
	-- 	local statue = FogStatue:create( i,cc.p(0,0) )
	-- end

	local count = 0

	-- if self.data ~= nil then
	-- 	for k,v in pairs(self.data) do
			-- print(k,v)
	-- 		count = count + 1
	-- 	end
	-- end
	self:clearClearFogs()
	-- local t1 = os.clock()
	--初始化所有迷雾原始数据
	for i= -1,self.owner.map:getMapSize().width  do
		for j= -1,self.owner.map:getMapSize().height  do
			--15为全黑
			local statue = {}
			statue.position = {x = i,y = j}
			setFogId(statue,15)
			local posDes = string.format("_%d_%d",i,j)
			allFogStatues[posDes] = statue
		end
	end
	-- local t2 = os.clock()
	-- print("initfogsStatue",t2 - t1)
	-- print("end",#self.clearFogs)
	--若没有数据，则认为是刚开始，初始化刚开始的地图区域
	if self.data == nil then
		-- self.data = {}
		self.owner:initMapFogsOfStart()
	--若有数据，则根据数据去刷新
	else

		local position = nil
		local posDes = nil
		for k,v in pairs(self.data) do

			position = ExploreDataManager:getInstance():getTitlePositionByPosKey(k)
			posDes = string.format("_%d_%d",position.x,position.y)
			--若v == 0 为空白区域
			if v == "0" then
				setFogId(allFogStatues[posDes],0)
				self:clearFogByPosition(position)
			--剩下的为周边区域
			else
				self:changeRoundFogs(position,v)
				setFogId(allFogStatues[posDes],tonumber(v))
			end
		end
		self.owner:clearFogs(false)
	end
end

function FogManager:saveFogDatas( )

end

--设置Owner
function FogManager:setOwner( owner )
	self.owner = owner
end

--刷新数据
function FogManager:refreshData( data,index )
	
end

--把对应位置的清除迷雾数据放入清楚数组和数据中
function FogManager:clearFogByPosition( position )
	self.clearFogs[#self.clearFogs + 1] = position
end

--存入周边的迷雾数据
function FogManager:changeRoundFogs( position,gidkey )
	-- print("changeRoundFogs",position,gidkey)

	local positiondescription = ExploreDataManager:getInstance():getPosKeyByPosition(position)

	if self.owner.mapLayoutManagers.data[positiondescription] ~= nil and self.owner.mapLayoutManagers.data[positiondescription].tips ~= nil then
		local tips = tonumber(self.owner.mapLayoutManagers.data[positiondescription].tips) 
		-- printn("changeRoundFogs",self.owner.mapLayoutManagers.data[positiondescription])
		--判断数据是否要修改
		if tips > 0 then
			self.owner.mapLayoutManagers.data[positiondescription].tips = tostring(-tips)
			--若是有图形界面就刷界面，没有只是数据改变(为以后迷雾随机开启做准备)
			if self.owner.map then
				self.owner:showStrongholdTipAction(position,tostring(-tips))
			end
		end
	end

	

	local index = #self.roundFogs + 1
	self.roundFogs[index] = {}
	self.roundFogs[index].position = position
	self.roundFogs[index].gidKey = tostring(gidkey)
end


function FogManager:tryToChangeRoundByRect( rect )
	--计算出x,y的范围
		local minx = rect.x - rect.width / 2
		local miny = rect.y - rect.height / 2
		local maxx = rect.x + rect.width / 2
		local maxy = rect.y + rect.height / 2

		local mapsize = self.owner.map:getMapSize()

		miny = math.max(miny,0)
		minx = math.max(minx,0)
		maxx = math.min(maxx,mapsize.width - 1)
		maxy = math.min(maxy,mapsize.height - 1)

		-- print("org",rect.x,rect.y)
		-- print("max",maxx,maxy)
		-- print("min",minx,miny)

		-- print("tryToChangeRoundByRect")

		local dirction = FogDirction.rightVertical

		local posDes = nil
		--锁定x,让其等于min 和 max ,对y进行变化(下到上刷新)
		for i = minx,maxx,maxx - minx do

			dirction = -dirction 

			for j = miny,maxy do
				local position = cc.p(i,j)
				-- print(position,i,j)
				posDes = string.format("_%d_%d",position.x,position.y)

				local cur_statue = allFogStatues[posDes]
				-- print("1_1",i,j,getFogId(cur_statue),cur_statue.position.x,cur_statue.position.y)
				--若已经被探索过的图块就不能继续给它加迷雾数据,已经探索过的图块数据为空
				if getFogId(cur_statue) ~= 0  then
					local vertices = PointStatue.Mid

					if j == miny then
						vertices = PointStatue.End
					elseif j == maxy then
						vertices = PointStatue.Start
					end
					tryChangeStatueByDirction(cur_statue,allFogStatues,dirction,vertices)
					posDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
					if not ExploreDataManager:getInstance():getValueByKeys("titlesInfo",posDes) then
						ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",posDes,{})
					end

					--存入数据中,若为0则为全开，要走迷雾清除存放逻辑，否则探索度或者探索出来的据点会出错
					if getFogId(cur_statue) == 0 then
						-- print("changroundfogs")
						self:inputFogsToDataByPosition(position)
					else
						-- print("roundFogsX",posDes,tostring(getFogId(cur_statue)))
						self.data[posDes] = tostring(getFogId(cur_statue))
						ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",posDes,"fogId",self.data[posDes])
					end

					self:changeRoundFogs(position,getFogId(cur_statue))
				end

			end

			if i == maxx then
				break
			end

		end
		-- if 1 then 
		-- 	return
		-- end

		dirction = FogDirction.bottomHorizontal
		--锁定y,让其等于min 和 max ,对x进行变化(左右)
		for i= miny,maxy,maxy - miny do
			dirction = -dirction
			for j= minx + 1 ,maxx -1  do
				local position = cc.p(j,i)
				
				posDes = string.format("_%d_%d",position.x,position.y)
				local cur_statue = allFogStatues[posDes]
				-- print("2_2",i,j,getFogId(cur_statue),cur_statue.position.x,cur_statue.position.y)
				--若已经被探索过的图块就不能继续给它加迷雾数据
				if getFogId(cur_statue) ~= 0  then
					local vertices = PointStatue.Mid
					tryChangeStatueByDirction(cur_statue,allFogStatues,dirction,vertices)
					posDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)
					if not ExploreDataManager:getInstance():getValueByKeys("titlesInfo",posDes) then
						ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",posDes,{})
					end

					--存入数据中,若为0则为全开，要走迷雾清除存放逻辑，否则探索度或者探索出来的据点会出错
					if getFogId(cur_statue) == 0 then
						-- print("changroundfogs")
						self:inputFogsToDataByPosition(position)
					else
						-- print("roundFogsY",posDes,tostring(getFogId(cur_statue)))
						self.data[posDes] = tostring(getFogId(cur_statue))
						ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",posDes,"fogId",self.data[posDes])
					end
					self:changeRoundFogs(position,getFogId(cur_statue))
				end
			end

			if i == maxy then
				break
			end
		end

		if self.isNeedCheckAll then
			ToastUtil:toastString("您已找到所有据点,本图迷雾全部开启")
			self:checkAllStrongholdIsCleared()
		end
		-- print("tryToChangeRoundByRected")
end

--根据玩家的位置信息,玩家的矩形探索范围和玩家的移动方向获得移动后可以开启的区域,这还可以继续封装!
function FogManager:tryToClearFogByRect( rect )

	-- printn("tryToClearFogByRect",rect)
	self.isNeedCheckAll = false
	--若初始数据为空表示第一次进地图，所以直接现实所有rect,否则这对一个点一个点进行排查
	if self.data == nil then 


		-- getCurMapDatas().mapFogDatas = {}

		self.data = {}

		-- self.data.clearStrongHoldNum = 0

		self:inputFogsToDataByRect(rect)
	else
		--计算出x,y的范围
		local minx = rect.x - rect.width / 2
		local miny = rect.y - rect.height / 2
		local maxx = rect.x + rect.width / 2
		local maxy = rect.y + rect.height / 2

		local mapsize = self.owner.map:getMapSize()

		miny = math.max(miny,0)
		minx = math.max(minx,0)
		maxx = math.min(maxx,mapsize.width - 1)
		maxy = math.min(maxy,mapsize.height - 1)
		
		-- print("org",rect.x,rect.y)
		-- print("max",maxx,maxy)
		-- print("min",minx,miny)

		-- --锁定x,让其等于min 和 max ,对y进行变化
		for i = minx,maxx,maxx - minx do
			local value = nil
			for j= miny,maxy do
				local position = cc.p(i,j)
				-- print(position,i,j)
				if self:fogDataIsExisted(position) == nil  then
					self:inputFogsToDataByPosition(position)
					self.clearFogs[#self.clearFogs + 1] = position
				end
			end
			-- print("tryToClearFogByRectx")
			i = maxx
		end



		--锁定y,让其等于min 和 max ,对x进行变化
		for i= miny,maxy,maxy - miny do
			for j= minx + 1 ,maxx -1  do
				local position = cc.p(j,i)
				-- print("2",position,j,i)
				if self:fogDataIsExisted(position) == nil then
					self:inputFogsToDataByPosition(position)
					self.clearFogs[#self.clearFogs + 1] = position
				end
			end
			-- print("tryToClearFogByRecty")
		end
	end

	--比当前矩形区域两边各大一格,重置rect

	rect.width = rect.width + 2
	rect.height = rect.height + 2
	--清理完毕的时候，查看是否有数据变化
	if #self.clearFogs > 0 then
		

		--若不需要清空所有迷雾，则开始对虚化迷雾进行绘制，否则直接清空迷雾，不用再虚化迷雾
		if self.isNeedCheckAll then
			ToastUtil:toastString("您已找到所有据点,本图迷雾全部开启")
			self:checkAllStrongholdIsCleared()
		else
			self:tryToChangeRoundByRect(rect)			
		end

		ExploreDataManager:getInstance():saveCurDatas()
		-- DataManager:getInstance():setMapData(self.owner.mapIndex,mapInfo,getCurMapDatas())
	end

	-- self:inputFogsToDataByRect(rect)
end

function FogManager:inputFogsToDataByPosition( position ,gidKey )
	-- print("inputFogsToDataByPosition",position)
	local positiondescription = ExploreDataManager:getInstance():getPosKeyByPosition(position)
	if self:fogDataIsExisted(position) == nil then
		-- if self.data["fogs"] == nil then
		-- 	self.data["fogs"] = 0
		-- end
		-- print("inputFogsToDataByPosition333",gidKey,positiondescription)
		local clearStrongHoldNum = ExploreDataManager:getInstance():getClearStrongHoldNum()
		local curMapStrongholdNum = ExploreDataManager:getInstance():getCurMapStrongholdNum()
		if not clearStrongHoldNum then
			clearStrongHoldNum = 0
			ExploreDataManager:getInstance():setClearStrongHoldNum(clearStrongHoldNum)
		end

		--检查这点是否是据点,若是，把探索出来的据点数+1
		if clearStrongHoldNum < curMapStrongholdNum and self.owner.mapLayoutManagers.data[positiondescription] ~= nil and self.owner.mapLayoutManagers.data[positiondescription].gid then
			
			clearStrongHoldNum = clearStrongHoldNum + 1

			--新老数据容错使用
			if self.owner.mapLayoutManagers.data[positiondescription].tips then
				local tips = tonumber(self.owner.mapLayoutManagers.data[positiondescription].tips) 

				--判断数据是否要修改
				if tips > 0 then
					self.owner.mapLayoutManagers.data[positiondescription].tips = tostring(-tips)
					--若是有图形界面就刷界面，没有只是数据改变(为以后迷雾随机开启做准备)
					if self.owner.map then
						self.owner:showStrongholdTipAction(position,tostring(-tips))
					end
				end
			end

			

			

			-- printn("inputFogsToDataByPositionUpdataHoldNum",position.x,position.y,self.owner.mapLayoutManagers.data[positiondescription],clearStrongHoldNum,curMapStrongholdNum)
			ExploreDataManager:getInstance():setClearStrongHoldNum(clearStrongHoldNum)
			--若数量相等，说明可以全开
			if clearStrongHoldNum == curMapStrongholdNum then
				self.isNeedCheckAll = true
			end
		end

		local curFogs = ExploreDataManager:getInstance():getFogs()

		if not curFogs then
			curFogs = 0
		end

		curFogs = curFogs + 1

		ExploreDataManager:getInstance():setFogs(curFogs)
	end	

	if gidKey == nil then
		local posDes = string.format("_%d_%d",position.x,position.y)
		gidKey = "0"
		--将对应清除迷雾allFogStatues的数据设置为0
		setFogId(allFogStatues[posDes],0)
	end

	if not ExploreDataManager:getInstance():getValueByKeys("titlesInfo",positiondescription) then
		-- print("create new world!")
		ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positiondescription,{})
	end

	ExploreDataManager:getInstance():updateValueByKeysAndValue("titlesInfo",positiondescription,"fogId",gidKey)

	-- print("inputFogsToDataByPosition",self.data["fogs"])
	self.data[positiondescription] = gidKey
end

-- function FogManager:inputFogsToDataByFullRect( rect )
	
-- 	local minx = rect.x - rect.width / 2
-- 	local miny = rect.y - rect.height / 2
-- 	local maxx = rect.x + rect.width / 2
-- 	local maxy = rect.y + rect.height / 2

-- 	local mapsize = self.owner.map:getMapSize()

-- 	miny = math.min(miny,1)
-- 	minx = math.min(minx,1)
-- 	maxx = math.max(maxx,mapsize.width)
-- 	maxy = math.max(maxy,mapsize.height)

	-- print("org",rect.x,rect.y)
	-- print("max",maxx,maxy)
	-- print("min",minx,miny)

-- 	for i = minx,maxx do
-- 			local value = nil
-- 			for j= miny,maxy do
				-- print(i,j)
-- 				local position = cc.p(i,j)
				-- print(position)
-- 				self:inputFogsToDataByPosition(position)
-- 				self:clearFogByPosition(position)
-- 			end
-- 	end
	
	-- print("inputFogsToDataByFullRect",self.data["fogs"])

-- end

function FogManager:inputFogsToDataByRect( rect )
			--计算出x,y的范围
		local minx = rect.x - rect.width / 2
		local miny = rect.y - rect.height / 2
		local maxx = rect.x + rect.width / 2
		local maxy = rect.y + rect.height / 2

		local mapsize = self.owner.map:getMapSize()

		miny = math.max(miny,0)
		minx = math.max(minx,0)
		maxx = math.min(maxx,mapsize.width - 1)
		maxy = math.min(maxy,mapsize.height - 1)

		-- print("mapsize",mapsize.width,mapsize.height)
		-- print("org",rect.x,rect.y)
		-- print("max",maxx,maxy)
		-- print("min",minx,miny)

		--锁定x,让其等于min 和 max ,对y进行变化
		for i = minx,maxx do
			local value = nil
			for j= miny,maxy do
				-- print(i,j)
				local position = cc.p(i,j)
				-- print(position)
				self:inputFogsToDataByPosition(position)
				self:clearFogByPosition(position)
			end

			i = maxx
		end

		--锁定y,让其等于min 和 max ,对x进行变化
		for i= miny,maxy do
			for j = minx + 1,maxx - 1 do
				-- print(i,j)
				-- print(position)
				local position = cc.p(j,i)
				self:inputFogsToDataByPosition(position)
				self:clearFogByPosition(position)
			end
			i = maxx - 1
		end

end

function FogManager:checkAllStrongholdIsCleared(  )
	
	local allStrongholdInfos = self.owner.mapLayoutManagers.data

	local fadeFogs = {}

	for i=0,self.owner.map:getMapSize().width - 1 do
		for j=0,self.owner.map:getMapSize().height - 1 do
			local position = cc.p(i,j)
			local posDes = ExploreDataManager:getInstance():getPosKeyByPosition(position)

			--若不是之前开过的迷雾，就进行淡出，并把其放入data中
			if self.data[posDes] == nil or (self.data[posDes] ~= nil and self.data[posDes] ~= "0") then
				self:inputFogsToDataByPosition(position)
				fadeFogs[#fadeFogs + 1] = position
			end
			-- self:clearFogByPosition(position)
		end
	end

	totalNum = self.owner.map:getMapSize().width * self.owner.map:getMapSize().height

	-- self.data["fogs"] = totalNum

	ExploreDataManager:getInstance():setFogs(totalNum)

	--迷雾淡出
	for i=1,#fadeFogs do
		self.owner:fadeFogByPosition(fadeFogs[i])
	end

	--由于和迷雾清除是放在一起的，则不需要写入数据和执行迷雾清除
	-- DataManager:getInstance():setRoleData(roleMapInfo,getCurMapDatas())

	-- self.owner:clearFogs()
end

function FogManager:fogDataIsExisted( position )

	local positiondescription = ExploreDataManager:getInstance():getPosKeyByPosition(position)

	-- print("fogDataIsExisted",self.data[positiondescription])

	--有数据，但不是清除迷雾的数据，就返回不存在
	if self.data[positiondescription] ~= nil and self.data[positiondescription] ~= "0" then
		return nil
	end

	return self.data[positiondescription]
end

--获得移动前匹配好的消除迷雾的数组信息
function FogManager:getClearFogs( )
	return self.clearFogs
end

function FogManager:getRoundFogs(  )
	return self.roundFogs;
end

function FogManager:clearClearFogs( )
	self.clearFogs = {}
	self.roundFogs = {}
end

function FogManager:getClearedFogs( )
	-- return self.data["fogs"]
end
