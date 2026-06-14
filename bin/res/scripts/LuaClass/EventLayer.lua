require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/FightMode"
require "LuaClass/EventDetailsLayer"
require "LuaClass/EventRewardLayer"
require "LuaClass/WorldMapLayer"


EventLayer = class("EventLayer",function ()
	 return cc.Layer:create()
end)

EventLayer.__index = EventLayer
EventLayer.controller = nil
EventLayer.name = nil
EventLayer.title = nil
EventLayer.description = nil
EventLayer.midTip = nil
EventLayer.buttonTips = {}
EventLayer.buttons = {}
EventLayer.buttonController = nil
EventLayer.enemysIndex = 0
EventLayer.curDropData = nil
EventLayer.scrollview = nil
EventLayer.controller = nil
EventLayer.needsPop = 0
-- EventManger.curEventId

local buttoninterval = 0
local descriptioninterval = 0

function EventLayer:create()
	-- print("Jointed:create()!");

	local eventLayer = EventLayer.new()
	
	if eventLayer and eventLayer:init() then
		return eventLayer
	end

	return nil;
end

function EventLayer:init()
    -- print("EventLayer:init!");

    self.worldMapLayer = nil

    local winSize = cc.Director:getInstance():getVisibleSize()

    buttoninterval = winSize.height * 0.1
    descriptioninterval = winSize.height * 0.3

    local bgLayer = cc.LayerColor:create(cc.c4b(0,0,0,255),winSize.width , winSize.height )
    bgLayer:setPosition(cc.p(0,0))
    self:addChild(bgLayer)

   	self.title = cc.LabelTTF:create("事件标题文本", BoldFont, winSize.height * 0.04)
   	self.title:setPosition(cc.p(winSize.width / 2,winSize.height - self.title:getContentSize().height / 2))
   	self:addChild(self.title)

   	self.midTip = cc.LabelTTF:create("中间提示文本", BoldFont, winSize.height * 0.03)
   	self.midTip:setPosition(cc.p(winSize.width / 2,self.title:getPositionY() - descriptioninterval / 2))
   	self:addChild(self.midTip)

   	self.midTip:setVisible(false)

   	self.description = cc.LabelTTF:create("事件描述文本", BoldFont, winSize.height * 0.03)
	self.description:setPosition(cc.p(winSize.width / 2,self.title:getPositionY() - descriptioninterval))
   	self:addChild(self.description)
   	local labelSize = cc.size(winSize.width,0)
   	self.description:setDimensions(labelSize)
   	self.midTip:setDimensions(labelSize)
  	
   	local button = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        self:enterFightLayer()
    end)
   	-- cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
   	-- --cc.Menu:create(unpack(buttonArr))
   	-- button:registerSingleCLick(function() 
    --     self:enterFightLayer()
    -- end)
   	button:setPosition(cc.p(winSize.width / 2 ,self.description:getPositionY() - buttoninterval - button:getContentSize().height / 2))
   	self.buttons[1] = button

   	local buttonTips = cc.LabelTTF:create("按钮1", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	self:addChild(buttonTips,3)

   	self.buttonTips[1] = buttonTips
   	
   	button = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        self:leaveToExploreMap(true)
    end)

   	-- cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
   	-- --cc.Menu:create(unpack(buttonArr))
   	button:setPosition(cc.p(winSize.width / 2 ,self.buttonTips[1]:getPositionY() - buttoninterval  - button:getContentSize().height / 2))
   	self.buttons[2] = button

   	-- button:registerSingleCLick(function() 
    --     self:leaveToExploreMap(true)
    -- end)

   	buttonTips = cc.LabelTTF:create("按钮2", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	self:addChild(buttonTips,3)
   	self.buttonTips[2] = buttonTips

  	self.buttonController = cc.Layer:create()
  	self.buttonController:setPosition(cc.p(0,0))
  	self:addChild(self.buttonController)

  	for i=1,#self.buttons do
  		-- print("init buttons",i)
  		self.buttonController:addChild(self.buttons[i])
  	end

  	
  	-- local e = EventCostLayer:create()
  	-- e:setPosition(cc.p(0,0))
  	-- self:addChild(e,30)
  	-- e:changeType(1)
    return true;
end

function EventLayer:setController( controller )
	self.controller = controller
end


--显示滚动按钮
function EventLayer:showMultipleButtons(  )
	
	print("showMultipleButtons")

	local arenaRecords = DataManager:getInstance():getRoleData(roleArenaRecords)
	local winSize = cc.Director:getInstance():getWinSize()

	local transform = buttoninterval * 0.4

	local buttoninterval = transform

	--若没有记录点，则按照之前的布局
	if arenaRecords == nil or #arenaRecords == nil then
		return
	end

	local scrollview_size_height = cc.Director:getInstance():getWinSize().height * 0.4

	if self.scrollview == nil then
			local scrollview = cc.ScrollView:create()
			local scrollview_size = cc.size(cc.Director:getInstance():getWinSize().width,scrollview_size_height)
			scrollview:setViewSize(scrollview_size)
			scrollview:setScale(1.0)
			self:addChild(scrollview);
		  	scrollview:ignoreAnchorPointForPosition(true)
		    scrollview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
		    scrollview:setClippingToBounds(true)
		    scrollview:setBounceable(false)
		    scrollview:setDelegate()
		    scrollview:registerScriptHandler(function ()
    	
    		end,cc.SCROLLVIEW_SCRIPT_SCROLL)
		    -- scrollview:setAnchorPoint(cc.p(0,1))

		    self.scrollview = scrollview
	end

	local scrollview_size = self.scrollview:getViewSize()
	
	local containerSize = cc.size(0,0)

	--按钮界面容器
	local containerLayer = cc.Layer:create()
	containerLayer:setPosition(cc.p(0,0))

	local record = nil
	local tipString = nil
	local startY = 0
	local buttons = {}
	local costId = 0
	local iconName = nil

	printn("arenaRecords:",arenaRecords)

	startY = startY + buttoninterval 

	--先添加离开滑动按钮
	local button = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        	self:stopAllActions()
	    	local seq = cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function ()
				self:leaveToExploreMap(true)
			end))
			self:runAction(seq)
    end)

	-- cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
	-- 	button:registerSingleCLick(function() 
	-- 		self:stopAllActions()
	--     	local seq = cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function ()
	-- 			self:leaveToExploreMap(true)
	-- 		end))
	-- 		self:runAction(seq)
 --    	end)



	startY = startY + button:getContentSize().height / 2
   	button:setPosition(cc.p(button:getContentSize().width / 2 ,startY))

   	buttons[1] = button

   	local buttonTips = cc.LabelTTF:create("离 开", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	containerLayer:addChild(buttonTips)

   	startY = startY + button:getContentSize().height / 2

	local i = #arenaRecords

	while( i >= 1) do

		local record = arenaRecords[i]

		startY = startY + buttoninterval 

		print("showMultipleButtons",record.costs,record.level)

		-- local label = cc.LabelTTF:create(tipString, BoldFont, winSize.height * 0.03)

		-- startY = startY - buttoninterval - label:getContentSize().height / 2

		-- label:setPosition(cc.p(label:getContentSize().width / 2,startY))
		-- containerLayer:addChild(label)

		-- startY = startY - label:getContentSize().height / 2

		local button = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        	self:checkJumpToEternalArena(record.costs,record.level)
    	end)

		-- cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
		-- button:registerSingleCLick(function() 
  --       	self:checkJumpToEternalArena(record.costs,record.level)
  --   	end)
    	startY = startY + button:getContentSize().height / 2
   		button:setPosition(cc.p(button:getContentSize().width / 2 ,startY))

   		buttons[i + 1] = button

   		--获取花费信息
		costId = record.costs.id
		iconName = dataController.getResourceValueByIdAndKey(costId,"iconName")

   		local tipSpr = cc.Sprite:create(string.format("Images/Icon/%s",iconName))
   		tipSpr:setPosition(cc.p(button:getContentSize().width * 0.4,button:getContentSize().height * 0.5))
   		local scale = button:getContentSize().height / tipSpr:getContentSize().height
   		tipSpr:setScale(scale)
   		button:addChild(tipSpr)
   		print("%s",string.format("Images/Icon/%s",iconName),scale,button:getContentSize().height,tipSpr:getContentSize().height)
   		local costNumLabel = cc.LabelTTF:create(string.format("X%d",tonumber(record.costs.num)), BoldFont, winSize.height * 0.04)
   		costNumLabel:setPosition(cc.p(tipSpr:getPositionX() + tipSpr:getContentSize().width * scale / 2 + costNumLabel:getContentSize().width / 2,tipSpr:getPositionY()))
   		button:addChild(costNumLabel)

   		--将startY设置为按钮的顶部
   		startY = startY + button:getContentSize().height / 2

   		tipString = string.format("快送挑战到%d关",tonumber(record.level))

		local label = cc.LabelTTF:create(tipString, BoldFont, winSize.height * 0.03)

		startY = startY + label:getContentSize().height / 2

		label:setPosition(cc.p(label:getContentSize().width / 2,startY))
		containerLayer:addChild(label)
		print("a loop startY",startY)

		startY = startY + label:getContentSize().height / 2

		i = i - 1
	end

	startY = startY + buttoninterval 

	--先添加离开滑动按钮
	local button = SDButton:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png", function() 
        	self:stopAllActions()
	    	local seq = cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function ()
				self:enterToEternalArenaByLevel()
			end))
			self:runAction(seq)
    	end)

	-- cc.MenuItemImage:create("Images/btn/ann05_b.png", "Images/btn/ann05_b.png");
	-- 	button:registerSingleCLick(function() 
	-- 		self:stopAllActions()
	--     	local seq = cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function ()
	-- 			self:enterToEternalArenaByLevel()
	-- 		end))
	-- 		self:runAction(seq)
 --    	end)

	startY = startY + button:getContentSize().height / 2
   	button:setPosition(cc.p(button:getContentSize().width / 2 ,startY))

   	buttons[#buttons + 1] = button

   	local buttonTips = cc.LabelTTF:create("挑 战", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(opColorPrimroseYellow)
   	containerLayer:addChild(buttonTips)

   	startY = startY + button:getContentSize().height / 2

	-- --只能倒序
	-- for i= #arenaRecords,1 do
		
 --   		-- --筛选出宽度,查出一个bug，要想纵向移动container的宽必须和viewsize的宽一样，所以蛋疼的scview!横纵向管毛用。。。
 --   		-- local maxWidth = math.max(button:getContentSize().width,label:getContentSize().width)
 --   		-- containerSize.width = math.max(containerSize.width,maxWidth)
	-- end



	local buttonController = cc.Layer:create()
  	buttonController:setPosition(cc.p(0,0))
  	containerLayer:addChild(buttonController)

  	for i=1,#buttons do
  		buttonController:addChild(buttons[i])
  	end

	containerSize.height = math.max(startY,scrollview_size.height)
	containerSize.width = winSize.width
	-- local tiplayer = cc.LayerColor:create(cc.c4b(255,0,0,255),containerSize.width , containerSize.height )
	-- tiplayer:setPosition(cc.p(0,0))
	-- containerLayer:addChild(tiplayer,-1)
	

	containerLayer:setContentSize(containerSize)
	print("containerLayersize",containerSize.width,scrollview_size.height)
	self.scrollview:setPosition(cc.p(self.buttons[1]:getPositionX() - self.buttons[1]:getContentSize().width * self.buttons[1]:getScaleX() / 2,self.buttons[1]:getPositionY() - self.buttons[1]:getContentSize().height * self.buttons[1]:getScaleY() / 2 - scrollview_size_height))

	self.scrollview:setContainer(containerLayer)
	self.scrollview:updateInset()
	self.scrollview:setVisible(true)

	--设置偏移
	print("setContentOffset",scrollview_size.height - containerSize.height )
	self.scrollview:setContentOffset(cc.p(0,scrollview_size.height - containerSize.height ))

	--对第二个按钮和label的位置进行赋值
	self.buttonController:setVisible(false)
	self.buttonTips[1]:setVisible(false)
	self.buttonTips[2]:setVisible(false)
	-- self.buttons[2]:setPositionY(self.scrollview:getPositionY() - self.buttons[2]:getContentSize().height / 2)
	-- self.buttonTips[2]:setPosition(self.buttons[2]:getPosition())
	-- print("showMultipleButtonsOver",self.buttons[2]:getPositionY())
end

--隐藏滚动按钮
function EventLayer:hideMultipleButtons(  )
	if self.scrollview ~= nil then
		self.scrollview:setVisible(false)
	end
	self.buttonController:setVisible(true)
	self.buttonTips[1]:setVisible(true)
	self.buttonTips[2]:setVisible(true)

	print("hideMultipleButtons")

	-- self.buttons[2]:setPositionY(self.buttonTips[1]:getPositionY() - buttoninterval  - self.buttons[2]:getContentSize().height / 2)
	-- self.buttonTips[2]:setPosition(self.buttons[2]:getPosition())

end

--检查是否能直接跳入到对应的层
function EventLayer:checkJumpToEternalArena( costDatas,level )
	if not ExploreBagController:getBagController():costGoodsByGoodsIdAndNum(costDatas.id,costDatas.num,true,"对应物品不足，无法直接跳入对应的层数") then
		return
	end

	self:enterToEternalArenaByLevel(level)
end

--全局中介函数
transformFunc = nil

function EventLayer:refreshLayerByInfo( info , isOccupied)
	
	print("getsAndSetsLayerInfoById",info)
	-- local id = tonumber(s_id)

	--删除之前的tips

	if self.otherTips then
		self.otherTips:removeFromParent(true)
		self.otherTips = nil
	end



	local title = info["name"]
	
	local des = nil

	local addStr = " "

	if not isOccupied then
	
		des = info["description"]

		local costDatas = info["requiredtool"]

		if title == "传送点" then

			-- printn("传送点花费道具",costDatas)

			if self.controller.costTool == nil then
				costDatas = {}
				costDatas[1] = {}
				costDatas[1][1] = "0"
			else
				costDatas = {}
				for i=1,#self.controller.costTool do
					local costdata = {}
					costdata[1] = self.controller.costTool[i].id
					costdata[2] = self.controller.costTool[i].num
					costDatas[i] = costdata
				end

			end
		end

		--拼接所需物品字符串
		if costDatas[1][1] ~= "0" then
			
			local tempData = nil
			
			self.costTool = nil
			
			addStr = "(需要"
			
			for i=1,#costDatas do

				if i > 1 and i < #costDatas then
					addStr = string.format("%s,",addStr)
				elseif i == #costDatas then
					if #costDatas > 1 then
						addStr = string.format("%s和",addStr)
					end
				end

				tempData = costDatas[i]
				local costId = tempData[1]
				local costNum = tempData[2]
				print("tip cost",costId,costNum)
				local toolname = dataController.getResourceValueByIdAndKey(costId,"name")
				addStr = string.format("%s%s个%s",addStr,costNum,toolname)
			end

		addStr = string.format("%s)",addStr)
		end
	else
		des = info["occupationdescription"]
	end
	self.buttons[1]:setVisible(true)
	self.buttonTips[1]:setVisible(true)
	self.buttons[2]:setVisible(true)
	self.buttonTips[2]:setVisible(true)

	local description = string.format("%s%s",des,addStr)

	self.title:setString(title)
	self.description:setString(description)
	self.midTip:setString(des)
	



	print("description",description,des,addStr)

	self.buttonTips[1]:setString("传送")


	self.buttonTips[2]:setString("离开")

	self.enemysIndex = 1
	

	self.name = self.title:getString()

	eventFucString = info["eventFucString"]

	local funCString = string.format("transformFunc = function ( target ,info ,isOccupied ) target:%s( info,isOccupied ) end",eventFucString)

	assert(loadstring(funCString))()

	--执行
	transformFunc(self,info,isOccupied)

	--释放
	transformFunc = nil

	print("refreshLayerByInfoOver",eventFucString)

	

	-- --从csv表中取出的func名字字符串
	-- local eventString = ""

	-- --从控制中心获得用户的数据
	-- local userData = ""

	-- --拼接最终的func调用字符串
	-- eventString = string.format("self.%s(userData)",eventString)

	-- --事件调度者触发事件
	-- assert(loadstring(eventString))
end

function EventLayer:show()
	print("EventLayer:show")
	self:setVisible(true)
	self.description:setVisible(true)
end

function EventLayer:hide()
	print("EventLayer:hide")
	self:setVisible(false)
	self:hideMultipleButtons()
	self.midTip:setVisible(false)
	self.description:setFontSize(cc.Director:getInstance():getVisibleSize().height * 0.03)
	self.worldMapLayer = nil
end

--怪物的记录
local curEnemyInfo = nil

--enemy最好是个通过表的解析过的数据，不要id号
function EventLayer:getsAndSetsEnemyLayerInfoByEnemy( enemy,addDropInfo,calBack )

	-- enemyFighters,enemyCanoon

	-- for k,v in pairs(enemy) do
	-- 	print(k,v)
	-- end
	
	curEnemyInfo = {}

	local enemyInfo = {}

	-- print("getsAndSetsEnemyLayerInfoByEnemy",enemy)
	
	local index = 1
	--清除之前的敌人信息
	FightDataManager:getInstance():clearEnemyData()
	local mapID = DataManager:getInstance():getRoleData(roleMapInfo).curIndex

	if mapID == nil then
		mapID = 1
	end

	FightDataManager:getInstance().mapID = mapID
	--初始化船站信息
	if #enemy > 1 then
		print("shipInfo init")
		--船站不需要mapid
		FightDataManager:getInstance().mapID = nil

		local id = enemy[index]
		
        -- 地图4故意卡付费的船战改动
        if tonumber(id) == 21008 then
            id = 11005
        end
		
		--怪物记录
		curEnemyInfo.ship = id

		cur_info = dataController.getSoilderInfoById(id)

		fightCannonData = FightCannonData.new()

		-- 威力值
		fightCannonData.power = tonumber(cur_info["attack"])
		-- 炮数
		fightCannonData.num = tonumber(cur_info["artilleryqty"])
		-- 血量值
		fightCannonData.hp = tonumber(cur_info["hp"])
		-- 名字
		fightCannonData.name = cur_info["name"]
		-- -- 速度
		-- fightCannonData.speed = 2;
		-- 描述
		fightCannonData.description = cur_info["description"]
		-- 星级
		fightCannonData.star = tonumber(cur_info["star"])

		FightDataManager:getInstance().enemyCanoon = fightCannonData

        -- print("fightCannonData",fightCannonData.power,fightCannonData.num,fightCannonData.hp,fightCannonData.name,fightCannonData.description,fightCannonData.star,id)

		index = index + 1
	end

		print("onshipBattle init")

		local coefficient = 1

		--若敌人数据中有增强系数，则将其赋入到敌人数据内部中(只有血和攻击需要)
		if enemy.coefficient ~= nil then
			coefficient = enemy.coefficient
		end

		coefficient = tonumber(coefficient)

		print("enemyCoefficient:",coefficient)

		--初始化登船战斗的信息
		local id = enemy[index]

		--怪物记录
		curEnemyInfo.enemy = id

		local cur_info = dataController.getSoilderInfoById(id) 

		if cur_info == nil then
			print(string.format("怪物id为%s数据找不到，请查表!",tostring(id)))
			ToastUtil:toastString("怪物信息无法找到，请联系客服!")
		end

		-- local skillData = dataController.getSkillInfoById(cur_info["skill"])
		local fightFighterData = FightFighterData.new()
		-- 威力值
		fightFighterData.power = math.ceil(tonumber(cur_info["attack"]) * coefficient)
		-- 血量值
		fightFighterData.hp = math.ceil(tonumber(cur_info["hp"]) * coefficient)
		-- 名字
		fightFighterData.name = cur_info["name"]
		-- 速度
		fightFighterData.speed = tonumber(cur_info["attackSpeed"])

		if fightFighterData.speed == nil or fightFighterData.speed == 0 then
			fightFighterData.speed = 2
		end

        fightFighterData.soilderId = id
		-- print("attackSpeed",cur_info["attackSpeed"])
		-- 闪避
		fightFighterData.miss = tonumber(cur_info["dodge"])
		-- print("dodge",fightFighterData.miss,cur_info["dodge"])
		-- 技能buffer ID
		-- fightFighterData.soilderId = "1"
		-- -- 技能系数
		-- fightFighterData.skillRatio = 1
		-- 描述
		fightFighterData.description = cur_info["description"]

		--添加敌人登船站信息
		FightDataManager:getInstance():addEnemyFighterData(fightFighterData)

		-- for k,v in pairs(fightFighterData) do
		-- 	print(k,v)
		-- end

		print("getsAndSetsEnemyLayerInfoByEnemyOver",fightFighterData.power,fightFighterData.hp,fightFighterData.name,fightFighterData.speed,fightFighterData.miss,fightFighterData.bufferId,fightFighterData.description)
		print(fightFighterData.skillRatio,fightFighterData.description)
		--获得掉落数据
		local dropData = cur_info["dropitems"]
		-- print(dropData,dropData[1])

		print("dropData_:",dropData,dropData[1],dropData[1][1],enemy.isOwnDrop)
		local curDropData = {}

		--若表中没有数据或者有其他掉落(永恒竞技场)，就不掉落怪物自带的掉落数据
		if dropData[1][1] ~= "0" and enemy.isOwnDrop == nil then
			local range = {}
		--拷贝对应的值
			for i=1,#dropData do
				local cur_data = dropData[i]
				local id = cur_data[1]
				range.min = tonumber(cur_data[2])
				range.max = tonumber(cur_data[3])
				local num = getRandomNumByRange(range)
				local name = dataController.getResourceValueByIdAndKey(id,"name")

				curDropData[i] = {}
				curDropData[i].id = id
				curDropData[i].num = num

				print("curDropData[i]",i,curDropData[i].id,curDropData[i].num,curDropData[i].name)
			end
		end

		--添加特殊掉落
		if addDropInfo ~= nil and addDropInfo[1][1] ~= "0" then
			print("addDropInfo")
			for i=1,#addDropInfo do
				
				local cur_data = addDropInfo[i]
				local id = cur_data[1]
				local num = tonumber(cur_data[2])
				local name = dataController.getResourceValueByIdAndKey(id,"name")

				curDropData[i] = {}
				curDropData[i].id = id
				curDropData[i].num = num
				print("curDropData[i]",i,curDropData[i].id,curDropData[i].num,curDropData[i].name)
			end
		end

		print("curDropData",#curDropData)

		--传递给战斗数据
		FightDataManager:getInstance().dropData = curDropData
		
		if index == 1 then 
			--设置title
			self.title:setString(string.format("%s(第%d层)",self.name,self.enemysIndex))
			self.description:setString(fightFighterData.description)
			self.buttons[1]:registerSingleCLick(function() 
        		self:enterFightLayer(false,calBack)
    		end)
			self.description:setFontSize(cc.Director:getInstance():getVisibleSize().height * 0.025)
			self.midTip:setVisible(true)
			-- self.buttons[1]:registerSingleCLick(function() 
			-- 	self.enemysIndex = self.enemysIndex + 1
   --      		self:fightIsOver(true)
   --  		end)
			print("getsAndSetsEnemyLayerInfoByEnemy")
			self.buttonTips[1]:setString("战 斗")
		end

		


		-- self.buttons[2]:registerSingleCLick(function() 
  --       	self:enterNextLayer()
  --   	end)

		-- for k,v in pairs(fightFighterData) do
		-- 	print(k,v)
		-- end

	--设置描述



	--更改按钮回调事件



end

-- function EventLayer( ... )
-- 	-- body
-- end

--复活界面
function EventLayer:changeToResurrectionLayer( data,isOccupied )
	if not self.controller:checkEnterNext() then
		return
	end
	print("changeToResurrectionLayer")
	self.buttons[1]:registerSingleCLick(function() 
        	self:enterResurrectionLayer()
    	end)
	self.buttonTips[1]:setString("进入")
end

function EventLayer:enterResurrectionLayer( ... )
	if not self.controller:checkEnterNext() then
		return
	end
    
    local datas = DataManager:getInstance():getRoleData(roleDeathInformation)
    printn("TTT=====", datas)
    --//[[
    EventDetailsLayer.type = 1
    EventDetailsLayer.data = datas
    local pubLayer = EventDetailsLayer:create()
    pubLayer.leaveCalBack = function (  )
        self:enterNextLayer(false)
    end

    pubLayer:setPosition(cc.p(0, 0))
    local gameScene = cc.Director:getInstance():getRunningScene()
    if gameScene ~= nil then
        gameScene:addChild(pubLayer)
    else
        gameScene = cc.Scene:create()
        gameScene:addChild(pubLayer)
        cc.Director:getInstance():runWithScene(gameScene)
    end
     --]]--
end

--传送点
function EventLayer:changeToNextMapEnter( data,isOccupied )
	print("changeToNextMapEnter")
	
	if not isOccupied then
		self.buttons[1]:registerSingleCLick(function() 
        	self:enterNextLayer()
    	end)
		self.buttonTips[1]:setString("进入")
	else
		self.buttons[1]:registerSingleCLick(function() 
        	-- self:enterNextMapEnter(true) --由于需要所以现在这个接口不能直接跳转，要通过世界地图跳转
        	self:enterTeleport()
    	end)
		self.buttonTips[1]:setString("进入")
	end

end

function EventLayer:enterNextMapEnter( needEnterNext,index,isCheck )
	if not self.controller:checkEnterNext() then
		return false
	end

	local limitedIndex = DataManager:getInstance():getRoleData(roleTranslateDoor)

	print("enterNextMapEnter",index,self.controller.owner.mapIndex,limitedIndex)

	--进入地图的限制
	if (index == nil and self.controller.owner.mapIndex + 1 > limitedIndex) or ( index ~= nil and index > limitedIndex) then
		-- ToastUtil:toastString("您需要购买资料片才能进入该地图。\n（资料片可以在钻石商城中购买）")

		-- ToastUtil:toastString(string.format("请购买资料片，进入%s",dataController.getStrongholdDistributionValueByIdAndKey(tostring(limitedIndex),"name")))
		return false
	end

	if isCheck ~= nil and isCheck == true then
		return true
	end

	--清除临时领取数据
	DataManager:getInstance():setRoleData(roleTempReceivedDatas,nil)

	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)

	local tipIndex = tempData.tipMapIndex
	--若有提示地图，且当前进入的地图等于提示地图，则把提示地图取消
	if tipIndex and ((index == nil and self.controller.owner.mapIndex + 1 == tipIndex) or index == tipIndex) then
		tempData.tipMapIndex = nil 
		DataManager:getInstance():setRoleData(roleMapInfo,tempData)

		local maskLayer = cc.LayerColor:create(cc.c4b(0,0,0,0),screenSize.width , screenSize.height )
		local gameScene = cc.Director:getInstance():getRunningScene()
    	gameScene:addChild(maskLayer)

    	local fade = cc.FadeIn:create(1.0)

		self.controller.owner:setVisible(false)

		local delay = cc.DelayTime:create(0.00)
		call1 = cc.CallFunc:create(function ( ... )
			self.worldMapLayer:removeFromParent(true)
			print("call1",self.worldMapLayer)
			maskLayer:setVisible(false)
		end)
        local call2 = cc.CallFunc:create(function ( ... )
        	local plots = clone(dataController.getStrongholdDistributionValueByIdAndKey(tostring(index),"plots"))
			-- printn("self.owner.mapIndex",self.owner.mapIndex + 1,self.plots)
			if plots[1][1] == "0" then
				return
			end

        	local plot = PlotLayer:create(nil,plots)

        	plot.delayTime = 0
			plot:setStayCallback(function (  )
				maskLayer:removeFromParent(true)
				self:enterNextLayer(false)
				self.controller.owner.statue = "Triggering"
				self.controller.owner:initMapByMapIndex(index)
				self.controller.owner.statue = "Triggering"
				self.controller.owner:setVisible(true)
				local action = cc.Sequence:create(cc.DelayTime:create(1.0),cc.CallFunc:create(function ( ... )
					self.controller.owner.statue = "ready"
				end))

				self.controller:runAction(action)

			end)
			-- self:addChild(plot,30000)

			plot:play()
			-- self.owner:setVisible(true)
        end)

        
		local action = cc.Sequence:create(fade,call1,call2)
		maskLayer:runAction(action)
		
		return false
	end

	-- if 1 then



	-- 	return false
	-- end

	--先事件处理毕，然后在更换地图
	if needEnterNext ~= nil and needEnterNext == true then
		self:enterNextLayer(false)
	end

	self.controller.owner:initMapByMapIndex(index)
	return true
end

--传送阵
function EventLayer:changeToTeleportLayer( data )
	-- print("changeToTeleportLayer")
	self.buttons[1]:registerSingleCLick(function() 
        	self:enterTeleport()
    	end)
	self.buttonTips[1]:setString("进入")

	local tempData = DataManager:getInstance():getRoleData(roleMapInfo)

	if tempData.mapIndex ~= nil and tempData.mapIndex < 2 then
		self.buttons[1]:setVisible(false)
		self.buttonTips[1]:setVisible(false)
		local des = "您还无法进入世界海图。试着探索一下黑色的“迷雾”区域，应该能找到通往下一海域的“传送点”，尽量带上更多的“面包”避免在海上陷入困境。"
		self.description:setString("")

		local winSize = cc.Director:getInstance():getVisibleSize()

		local otherTips = cc.LabelTTF:create(des, BoldFont, winSize.height * 0.03)
		otherTips:setPosition(cc.p(self.description:getPosition()))
		otherTips:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		otherTips:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)

		local labelSize = cc.size(winSize.width,0)
   		otherTips:setDimensions(labelSize)
   		self.description:getParent():addChild(otherTips,2,4)
   		self.otherTips = otherTips
		-- self.midTip:setString(des)

		local explor = getExplor()
		if not GuideController:getInstance():getIsHaveStep(71) then
    		explor.mapGuideComponent:hideAllComponents()
    		GuideController:getInstance():addStep(71)
    		explor.isNeedGuide = false
    	end		
	end

end

function EventLayer:enterTeleport( )
	print("enterTeleport",not self.controller:checkEnterNext(),self.worldMapLayer ~= nil)
	if not self.controller:checkEnterNext() or self.worldMapLayer ~= nil then
		return
	end

	local worldMapLayer = WorldMapLayer:create()
	worldMapLayer:setPosition(0,0)
	worldMapLayer:setOwner(self)
	self.worldMapLayer = worldMapLayer
	local gameScene = cc.Director:getInstance():getRunningScene()
    gameScene:addChild(worldMapLayer)
end

--酒馆界面
function EventLayer:changeToPubLayer( data,isOccupied )
	print("changeToPubLayer")
	self.buttons[1]:registerSingleCLick(function() 
		print("enter self.buttons[1] calback")
        	self:enterPubLayer(data)
    	end)
	self.buttonTips[1]:setString("进入酒馆")
end

function EventLayer:enterPubLayer( data )
	
		print("enterPubLayer",data)

	if not self.controller:checkEnterNext() then
		return
	end

	
	-- print(data)

	-- for k,v in pairs(data) do
	-- 	print(k,v)
	-- end

	local memberInfos = {}
	local datas = data["Carryitems"]
	for i=1,#datas do
		local memberInfo = {}
		data = datas[i]
		memberInfo.id = data[2]
		memberInfo.name = dataController.getSoilderValueByIdAndKey(memberInfo.id,"name")
		memberInfo.icon = dataController.getSoilderValueByIdAndKey(memberInfo.id,"icon")
		memberInfo.star = tonumber(dataController.getSoilderValueByIdAndKey(memberInfo.id,"star"))
		memberInfo.power = dataController.getSoilderValueByIdAndKey(memberInfo.id,"attack")
		memberInfo.hp = dataController.getSoilderValueByIdAndKey(memberInfo.id,"hp")
		memberInfo.speed = dataController.getSoilderValueByIdAndKey(memberInfo.id,"speed")
		local skillId = dataController.getSoilderValueByIdAndKey(memberInfo.id,"skill")
		memberInfo.skillName = dataController.getSkillValueByIdAndKey(skillId,"name")
		memberInfo.costType = data[1]
		memberInfo.costs = tonumber(data[3])
    	if memberInfo.id ~= nil then
        	memberInfos[#memberInfos + 1] = memberInfo
    	end
    	printn("TTT======", memberInfos, data[2])
	end


    
    EventDetailsLayer.type = 2
    EventDetailsLayer.data = memberInfos
    local pubLayer = EventDetailsLayer:create()
    pubLayer:setPosition(cc.p(0, 0))
    pubLayer.leaveCalBack = function (  )
    	self:enterNextLayer(false)
    end
    local gameScene = cc.Director:getInstance():getRunningScene()
    if gameScene ~= nil then
        gameScene:addChild(pubLayer)
    else
        gameScene = cc.Scene:create()
        gameScene:addChild(pubLayer)
        cc.Director:getInstance():runWithScene(gameScene)
    end
end

--黑市
function EventLayer:changeToBlackMarket( data,isOccupied )
	print("changeToBlackMarket")
	self.buttons[1]:registerSingleCLick(function() 
        	self:enterBlackMarket(data)
    	end)
	self.buttonTips[1]:setString("进入")
end
--进入黑市
function EventLayer:enterBlackMarket( data)
	print("enterBlackMarket",data)

	if not self.controller:checkEnterNext() then
		return
	end

	-- for k,v in pairs(data) do
	-- 	print(k,v)
	-- end

	-- data = data["Carryitems"]
	-- local itemInfos = {}
	-- for i=1,#data do
	-- 	local temp_data = data[i]
	-- 	local itemInfo = {}
	-- 	itemInfo.id = temp_data[2]
	-- 	itemInfo.name = dataController.getResourceValueByIdAndKey(itemInfo.id,"name")
	-- 	itemInfo.icon = dataController.getResourceValueByIdAndKey(itemInfo.id,"iconName")
	-- 	itemInfo.star = tonumber(dataController.getResourceValueByIdAndKey(itemInfo.id,"starNum"))
 --        if itemInfo.star == nil then itemInfo.star = 5 end
	-- 	itemInfo.description = dataController.getResourceValueByIdAndKey(itemInfo.id,"desc")
	-- 	itemInfo.costType = temp_data[1]
	-- 	itemInfo.costs = tonumber(temp_data[3])

	-- 	if not temp_data[4] then
	-- 		temp_data[4] = 1
	-- 	end
		
	-- 	itemInfo.num = tonumber(temp_data[4])
	-- 	itemInfos[i] = itemInfo

	-- 	-- print("enterBlackMarketData:",itemInfo.id,itemInfo.name,itemInfo.icon,itemInfo.star,itemInfo.description,itemInfo.costCoin)
	-- end
	
	--检查数据是否需要刷新
	ExploreDataManager:getInstance():checkBlackMarketDatas()

	EventDetailsLayer.type = 3
    EventDetailsLayer.data = ExploreDataManager:getInstance():getBlackMarketDatas()
    printn("黑市",EventDetailsLayer.data)
    local pubLayer = EventDetailsLayer:create()

    pubLayer.leaveCalBack = function (  )
    	self:enterNextLayer(false)
    end

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

--普通竞技场
function EventLayer:changeToArenaLayer( data )
	print("changeToArenaLayer")
	self.buttons[1]:registerSingleCLick(function() 
        	self:enterNextLayer()
    end)
    self.buttonTips[1]:setString("进入")
end

--改变成永恒竞技场
function EventLayer:changeToEternalArena( data )
	--若没有开启过，查看是否有对应的道具
	if not self.controller:checkIsOpen() then		
		local have = ExploreBagController:getBagController():checkItemsIsHave(self.controller.costTool)
		print("have",have)
		--若有，则改变对应1的回掉事件，并显示跳层按钮
		if have then
			self.description:setString(self.midTip:getString())
			self.buttons[1]:registerSingleCLick(function() 
        		self:enterToEternalArenaByLevel()
    		end)
    		self.buttonTips[1]:setString("挑 战")
    		self:showMultipleButtons()
    	--若没有,则只显示离开,隐蔽按钮1
		else
			self.buttons[1]:setVisible(false)
			self.buttonTips[1]:setVisible(false)
		end
	end
end

--进入永恒竞技场
function EventLayer:enterToEternalArenaByLevel( level )
	print("enterToEternalArenaByLevel",level)

	if level ~= nil then
		self.enemysIndex = level
	end
	self:hideMultipleButtons()
	EternalArenaController:getInstance():bagainControleEternalArenaByLevel(level)

end

--材料据点
function EventLayer:changeToMaterialsLayer( data,isOccupied )
	print("changeToArenaLayer")
	if not isOccupied then

		local explor = getExplor()

		self.buttons[1]:registerSingleCLick(function() 
			if not GuideController:getInstance():getIsHaveStep(71) then
	    		explor.mapGuideComponent:hideAllComponents()
	    		GuideController:getInstance():addStep(71)
	    		explor.isNeedGuide = false
	    	end
        	self:enterNextLayer()
    	end)
    	self.buttonTips[1]:setString("占领")

    	--新手引导
    	
    	if not GuideController:getInstance():getIsHaveStep(71) then
    		explor.mapGuideComponent:changeFingerParent(self)
    		explor.mapGuideComponent:showFingerActionByPosition(cc.p(self.buttonTips[1]:getPosition()))
    	end

    else
    	self.buttons[1]:registerSingleCLick(function()
    		print("will cal enterMaterials") 
        	self:enterMaterials(data)
    	end)
    	self.buttonTips[1]:setString("进入")
    end

end

function EventLayer:enterMaterials( data )
	if not self.controller:checkEnterNext() then
		return
	end


	print("enterMaterials",data["dropitems"],data["ID"])

	local dropitems = data["dropitems"]

	local dropDatas = {}
	print("dropDatas",dropitems[1],dropitems[1][1],#dropitems)

	if dropitems ~= nil and dropitems[1][1] ~= "0" then
		--获取掉落信息
		for i=1,#dropitems do
			local cur_data = dropitems[i]
			local id = cur_data[1]
			local num = tonumber(cur_data[2])
			local name = dataController.getResourceValueByIdAndKey(id,"name")
			dropDatas[i] = {}
			dropDatas[i].id = id
			dropDatas[i].num = num
			dropDatas[i].name = name
			dropDatas[i].space = tonumber(dataController.getResourceValueByIdAndKey(id,"cubage"))
			dropDatas[i].icon = dataController.getResourceValueByIdAndKey(id,"iconName")
			dropDatas[i].index = i
			print("MaterialsDrop:",dropDatas[i].id,dropDatas[i].num,dropDatas[i].name,dropDatas[i].space)
		end
	else
		ToastUtil:toastString(string.format("策划对应的材料据点(%s)表中没有掉落数据，请检查",data["ID"]))
	end

	self:enterRewardLayer(dropDatas)
end

--怪物据点
function EventLayer:changeToEnemyLayer( data,isOccupied )

	-- if not self.controller:checkEnterNext() then
	-- 	return
	-- end	

	print("changeToEnemyLayer",data)

	if not isOccupied then
		--设置总层数
		FightDataManager:getInstance().totalLevel = tonumber(data["layers"])
		print("layers :",tonumber(data["layers"]))
		self.buttons[1]:registerSingleCLick(function() 
        	self:enterNextLayer()
    	end)
		self.buttonTips[1]:setString("占 领")
	else
		self.buttonTips[1]:setString("进 入")
		self.buttons[1]:registerSingleCLick(function() 
        	self:enterSupplyPoint(data)
    	end)
	end

end
--补给点
function EventLayer:changeToSupplyPoint( data )
	self.buttons[1]:registerSingleCLick(function() 
        self:enterSupplyPoint()
    end)
    self.buttonTips[1]:setString("领取")
	self.buttonTips[2]:setString("离开")
end

function EventLayer:enterSupplyPoint(  )

	if not self.controller:checkEnterNext() then
		return
	end


	local datas = ExploreBagController:getBagController().breads

	local drop_datas = {}

	local temp_data = nil

	local id = 0
	local num = 0
	-- print("datas",datas[1])

	-- for k,v in pairs(datas[1]) do
	-- 	print(k,v)
	-- end

	for i=1,#datas do
		temp_data = datas[i]
		local drop_data = {}
		drop_data.id = temp_data.id
		drop_data.name = dataController.getResourceValueByIdAndKey(drop_data.id,"name")
		drop_data.icon = dataController.getResourceValueByIdAndKey(drop_data.id,"iconName")
		drop_data.num = temp_data.num
		drop_data.space = tonumber(dataController.getResourceValueByIdAndKey(drop_data.id,"cubage"))
		drop_datas[i] = drop_data
		-- print("enterSupplyPoint",drop_data.num,drop_data.name,drop_data.id,drop_data.space)
	end

	self:enterRewardLayer(drop_datas)

end



function EventLayer:enterNextLayer( isNeedCheck,isReceived )

	if isNeedCheck == nil then
		isNeedCheck = true
	end

	if isReceived == nil then
		isReceived = false
	end

	if isReceived then
		self.controller:received()
	end

	if isNeedCheck and not self.controller:checkEnterNext() then
		return
	end
	self.controller:anEventHasTriggered()

end

function EventLayer:enterFightLayer( isNeedShipBattle,calBack )
	--防止多次点击
	self.buttons[1]:setSingleCLickEnable(false)

	local failType = FightScene.FightFailType.normal
	
	if calBack == nil or type(calBack) ~= "function" then
		calBack = function ( result )
       		self:fightIsOver(result)
		end
	else
		failType = FightScene.FightFailType.eternal
    end

    --战斗就不需要检查了。。。
	-- if not self.controller:checkEnterNext() then
	-- 	return
	-- end	
	
    local fightType = FightScene.FightType.shipWar

   	if not isNeedShipBattle then
   		fightType = FightScene.FightType.aboardWar
   	end

   	--设置战斗到第几层了
   	if FightDataManager:getInstance().totalLevel ~= nil and FightDataManager:getInstance().totalLevel > 0 then
   		FightDataManager:getInstance().curLevel = self.enemysIndex
   		print("当前战斗到第几层了",FightDataManager:getInstance().curLevel)
   	end
   	
   	self.enemysIndex =  self.enemysIndex + 1	

   	local fightScene = FightScene:create(fightType,failType)
   	print("isNeedShipBattle",isNeedShipBattle,fightType)
    fightScene:setFightOverCallback(calBack)
    if DataManager:getInstance():getMusic_off() == 0 then
        AudioEngine.playMusic(MUSIC_PK, true)
        HAS_MUSIC_FILE = 1
    else
        -- 不播放
    end
    local scene = cc.Scene:create()
    scene:addChild(fightScene)
    cc.Director:getInstance():pushScene(scene)
    self.needsPop = self.needsPop + 1
    print("needsPop",self.needsPop)
 --    if 1 then
	-- 	self:fightIsOver(false)
	-- 	return
	-- end

    -- self:leaveToExploreMap( false )
end

function EventLayer:showTipOccupiedLayer( layerInfo )

	local tipDes = layerInfo["occupationdescription"]
	self.description:setString(tipDes)

	self.buttonTips[1]:setString("离 开")
	self.buttons[1]:registerSingleCLick(function() 
        self.controller:anEventHasTriggered()
    end)

	self.buttons[2]:setVisible(false)
	self.buttonTips[2]:setVisible(false)


end

function EventLayer:safeBackToLayer(   )
	
	if not self.controller.isMinesweeper then

		cc.Director:getInstance():popScene()
		self.needsPop = 0
		self.buttons[1]:setSingleCLickEnable(true)
		self.enemysIndex =  self.enemysIndex - 1
	else
		cc.Director:getInstance():popScene()
		self.needsPop = 0
		self.buttons[1]:setSingleCLickEnable(true)
		self.enemysIndex =  self.enemysIndex - 1
		self.controller:allEventsHasTriggered(false)
	end

end

function EventLayer:enterRewardLayer( dropDatas )
	
	--获取战斗背包信息
	local data = clone(DataManager:getInstance():getRoleData(roleBattlePack))
	local haveDatas = {}

	for k,v in pairs(data) do
		local index = #haveDatas + 1
		haveDatas[index] = {}
		haveDatas[index].id = v.id
		haveDatas[index].name = dataController.getResourceValueByIdAndKey(v.id,"name")
		haveDatas[index].num = v.num
		haveDatas[index].icon = dataController.getResourceValueByIdAndKey(v.id,"iconName")
		haveDatas[index].space = tonumber(dataController.getResourceValueByIdAndKey(v.id,"cubage"))
	end

	data = {}
	data.drop = dropDatas
	data.have = haveDatas

    local rewardscene = FightRewardScene:create(haveDatas, dropDatas)
    rewardscene:setFightOverCallback(function(useless)
        cc.Director:getInstance():popScene()

        ExploreBagController:getBagController():refreshBattlePack()
        self:enterNextLayer(false,true)
    end)
    rewardscene:setFightResult(false)
    local scene = cc.Scene:create()
    scene:addChild(rewardscene)
    cc.Director:getInstance():pushScene(scene)

--	local rewardLayer = EventRewardLayer:create( data )
--	rewardLayer.packageCapicity = DataManager:getInstance():getRoleData(rolePackSize)
--	rewardLayer:setPosition(0,0)
--	rewardLayer.pickUpCallback = function (  )
--		ExploreBagController:getBagController():refreshBattlePack()
--		self:enterNextLayer(false,true)
--	end
--	print("rewardLayer.pickUpCallback",rewardLayer.pickUpCallback)
--	local gameScene = cc.Director:getInstance():getRunningScene()
--	gameScene:addChild(rewardLayer)

end

function EventLayer:checkPop(  )
	if self.needsPop < 1  then
		return false
	end

	self.needsPop = self.needsPop - 1

	return true
end

function EventLayer:fightIsOver( result )
	--开启点击
	self.buttons[1]:setSingleCLickEnable(true)
	print("fightIsOver",result,self.needsPop)

	if DataManager:getInstance():getMusic_off() == 0 then
       AudioEngine.playMusic(MUSIC_Map, true)
       HAS_MUSIC_FILE = 1
    else
            -- 不播放
    end

	if result == nil then
		result = true
	end

	if not self:checkPop() then
		return
	end

	cc.Director:getInstance():popScene()

	if result then
		--杀怪成就记录点
		achievementValue = DataManager:getInstance():getAchievementInfo(achievement_KillMonster)
		DataManager:getInstance():setAchievementInfo(achievement_KillMonster, (achievementValue + 1))

		 local defeatedHistory = DataManager:getInstance():getRoleData(roleDefeatedHistory)

	    if not defeatedHistory then
	        defeatedHistory = {}
	    end

	    --船
	    local id = curEnemyInfo.ship

		--把杀怪记录存入到档中
		if id then
			if not defeatedHistory[id] then
				defeatedHistory[id] = 0
			end

			defeatedHistory[id] = defeatedHistory[id] + 1
		end

		if id then
			--查看是否会触发任务
			local enemyinfos = dataController.getSoilderInfoById(id)

			--检查任务触发(类型，杀怪)
			local taskID = enemyinfos["taskID"] 
			local taskOk = enemyinfos["taskOk"] 

			local stepInfos = {}
			stepInfos.id = id
			stepInfos.num = 1
			MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)
		end

		--怪物
		id = curEnemyInfo.enemy

		--把杀怪记录存入到档中
		if id then
			if not defeatedHistory[id] then
				defeatedHistory[id] = 0
			end

			defeatedHistory[id] = defeatedHistory[id] + 1
		end

		--存档
		DataManager:getInstance():setRoleData(roleDefeatedHistory,defeatedHistory)

		--查看是否会触发任务
		local enemyinfos = dataController.getSoilderInfoById(id)

		--检查任务触发(类型，杀怪)
		local taskID = enemyinfos["taskID"] 
		local taskOk = enemyinfos["taskOk"] 

		local stepInfos = {}
		stepInfos.id = id
		stepInfos.num = 1
		MissionManagers:getInstance():onTriggerMission(taskID,taskOk,stepInfos)
			
		self.controller:anEventHasTriggered()
		--刷新地图背包信息
		ExploreBagController:getBagController():refreshBattlePack()
	else
		-- local seq = cc.Sequence:create(cc.DelayTime:create(0.1),cc.CallFunc:create(function ()
		-- 	self.controller:allMembersKilled()
		-- end))
		-- self:runAction(seq)
		self.controller:allMembersKilled()
	end

end

function EventLayer:leaveToExploreMap( arg )
	
	local explor = getExplor()

	--新手引导中不允许离开
	if not GuideController:getInstance():getIsHaveStep(71) then
		return 
	end

	print("arg",arg)
	if not arg then
		self.controller:allEventsHasTriggered(arg)
	else
		self.controller:anEventHasToGiveUp()
	end

end

