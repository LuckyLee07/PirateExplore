require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/FightMode"


EventLayer = class("EventLayer",function ()
	 return cc.Layer:create()
end)

EventLayer.__index = EventLayer
EventLayer.controller = nil
EventLayer.name = nil
EventLayer.title = nil
EventLayer.description = nil
EventLayer.buttonTips = {}
EventLayer.buttons = {}
EventLayer.buttonController = nil
EventLayer.enemysIndex = 0

-- EventManger.curEventId

local buttoninterval = 0
local descriptioninterval = 0

function EventLayer:create()
	print("Jointed:create()!");

	local eventLayer = EventLayer.new()
	
	if eventLayer and eventLayer:init() then
		return eventLayer
	end

	return nil;
end

function EventLayer:init()
    print("EventLayer:init!");

    local winSize = cc.Director:getInstance():getVisibleSize()

    buttoninterval = winSize.height * 0.1
    descriptioninterval = winSize.height * 0.3

    local bgLayer = cc.LayerColor:create(cc.c4b(0,0,0,255),winSize.width , winSize.height )
    bgLayer:setPosition(cc.p(0,0))
    self:addChild(bgLayer)

   	self.title = cc.LabelTTF:create("事件标题文本", BoldFont, winSize.height * 0.04)
   	self.title:setPosition(cc.p(winSize.width / 2,winSize.height - self.title:getContentSize().height / 2))
   	self:addChild(self.title)

   	self.description = cc.LabelTTF:create("事件描述文本", BoldFont, winSize.height * 0.03)
	self.description:setPosition(cc.p(winSize.width / 2,self.title:getPositionY() - descriptioninterval))
   	self:addChild(self.description)

   	
  	
   	local button = cc.MenuItemImage:create("Images/UI/BottomBtn1.png", "Images/UI/BottomBtn1.png");
   	--cc.Menu:create(unpack(buttonArr))
   	button:registerScriptTapHandler(function() 
        self:enterFightLayer()
    end)
   	button:setPosition(cc.p(winSize.width / 2 ,self.description:getPositionY() - buttoninterval - button:getContentSize().height / 2))
   	self.buttons[1] = button

   	local buttonTips = cc.LabelTTF:create("按钮1", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(cc.c3b(0, 0, 0))
   	self:addChild(buttonTips,3)

   	self.buttonTips[1] = buttonTips
   	
   	button = cc.MenuItemImage:create("Images/UI/BottomBtn1.png", "Images/UI/BottomBtn1.png");
   	--cc.Menu:create(unpack(buttonArr))
   	button:setPosition(cc.p(winSize.width / 2 ,self.buttonTips[1]:getPositionY() - buttoninterval  - button:getContentSize().height / 2))
   	self.buttons[2] = button

   	button:registerScriptTapHandler(function() 
        self:leaveToExploreMap(true)
    end)

   	buttonTips = cc.LabelTTF:create("按钮2", BoldFont, winSize.height * 0.03)
   	buttonTips:setPosition(cc.p(button:getPositionX() ,button:getPositionY()))
   	buttonTips:setColor(cc.c3b(0, 0, 0))
   	self:addChild(buttonTips,3)
   	self.buttonTips[2] = buttonTips

  	self.buttonController = cc.Menu:create(unpack(self.buttons))
  	self.buttonController:setPosition(cc.p(0,0))
  	self:addChild(self.buttonController)

    return true;
end

function EventLayer:setController( controller )
	self.controller = controller
end
--全局中介函数
transformFunc = nil

function EventLayer:refreshLayerByInfo( info , isOccupied)
	
	print("getsAndSetsLayerInfoById",info)
	-- local id = tonumber(s_id)

	local title = info["name"]
	
	local des = nil

	local addStr = " "

	if not isOccupied then
	
		des = info["description"]

		local costId = info["requiredtool"]
		local costNum = info["requirednum"]

		if tonumber(costNum) > 0 then
			local toolname = dataController.getProduceValueByIdAndKey(costId)
			addStr = string.format("(需要%s个%s)",costNum,toolname)
		end
	
	else
		des = info["occupationdescription"]
	end



	local description = string.format("%s%s",des,addStr)

	self.title:setString(title)
	self.description:setString(description)

	self.buttonTips[1]:setString("传送")
	self.buttonTips[2]:setString("离开")

	self.enemysIndex = 1

	-- if id == -1 then
		-- self.title:setString("占领点")
		-- self.description:setString("你已经占领该据点")
	-- 	self.buttonTips[1]:setString("掠夺")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 3 then
	-- 	self.title:setString("传送点")
	-- 	self.description:setString("传送至下一地图")
	-- 	self.buttonTips[1]:setString("传送")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 4 then
	-- 	self.title:setString("复活点")
	-- 	self.description:setString("复活所有已经阵亡的英雄")
	-- 	self.buttonTips[1]:setString("复活")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 5 then
	-- 	self.title:setString("酒馆")
	-- 	self.description:setString("招募特殊英雄")
	-- 	self.buttonTips[1]:setString("招募")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 6 then
	-- 	self.title:setString("黑市")
	-- 	self.description:setString("购买特殊物品")
	-- 	self.buttonTips[1]:setString("购买")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 7 then
	-- 	self.title:setString("竞技场")
	-- 	self.description:setString("击杀特殊怪物得到特殊道具")
	-- 	self.buttonTips[1]:setString("竞技")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 8 then
	-- 	self.title:setString("材料据点")
	-- 	self.description:setString("占领后可激活相应材料生产功能")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 9 then
	-- 	self.title:setString("已经被攻占的据点")
	-- 	self.description:setString("占领后可激活相应材料生产功能")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 10 then
	-- 	self.title:setString("固定据点")
	-- 	self.description:setString("怪物据点，胜利后占领该据点，得到材料或金币等道具")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 11 then
	-- 	self.title:setString("多层固定据点")
	-- 	self.description:setString("多层固定据点")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 12 then
	-- 	self.title:setString("加密固定据点")
	-- 	self.description:setString("需要有某样道具才可进行占领或访问")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 13 then
	-- 	self.title:setString("随机触发战斗")
	-- 	self.description:setString("胜利后可得到材料或金币等道具")
	-- 	self.buttonTips[1]:setString("占领")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 14 then
	-- 	self.title:setString("随机宝箱")
	-- 	self.description:setString("碰到后得到金币")
	-- 	self.buttonTips[1]:setString("获取")
	-- 	self.buttonTips[2]:setString("离开")
	-- elseif id == 15 then
	-- 	self.title:setString("随机天灾")
	-- 	self.description:setString("遇到风暴、海啸等，强制扣除一定数量体力")
	-- 	self.buttonTips[1]:setString("战斗")
	-- 	self.buttonTips[2]:setString("离开")
	-- end

	self.name = self.title:getString()

	eventFucString = "changeToResurrectionLayer"

	local funCString = string.format("transformFunc = function ( target , isOccupied ) target:%s( isOccupied ) end",eventFucString)

	assert(loadstring(funCString))()

	--执行
	transformFunc(self,isOccupied)

	--释放
	transformFunc = nil

	self.buttons[1]:registerScriptTapHandler(function() 
        self:enterNextLayer()
    end)

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
end

function EventLayer:hide()
	print("EventLayer:hide")
	self:setVisible(false)
end

--enemy最好是个通过表的解析过的数据，不要id号
function EventLayer:getsAndSetsEnemyLayerInfoByEnemy( enemy )

	-- enemyFighters,enemyCanoon

	

	local enemyInfos = dataController.getSoilderInfoById(enemy)

	local enemyInfo = {}

	print("getsAndSetsEnemyLayerInfoByEnemy",enemy)
	
	local index = 1

	--初始化船站信息
	if #enemy > 1 then

		--
		local id = enemy[index]
		
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
		fightCannonData.description = "这是一艘船，很有可能幽灵化"
		-- 星级
		fightCannonData.star = tonumber(cur_info["star"])

		FightDataManager:getInstance().enemyCanoon = fightCannonData

		index = index + 1
	end

		--初始化登船战斗的信息
		local id = enemy[index]
		local cur_info = dataController.getSoilderInfoById(id) 
		-- local skillData = dataController.getSkillInfoById(cur_info["skill"])
		local fightFighterData = FightFighterData.new()
		-- 威力值
		fightFighterData.power = tonumber(cur_info["attack"])
		-- 血量值
		fightFighterData.hp = tonumber(cur_info["hp"])
		-- 名字
		fightFighterData.name = cur_info["name"]
		-- 速度
		fightFighterData.speed = tonumber(cur_info["attackSpeed"])
		-- 闪避
		fightFighterData.miss = tonumber(cur_info["dodge"])
		-- 技能buffer ID
		fightFighterData.bufferId = "0"
        -- soilder id
        fightFighterData.soilderId = id
		-- 技能系数
		fightFighterData.skillRatio = 0
		-- 描述
		fightFighterData.description = "一个怪物正在恶狠狠的盯着你"

		--添加敌人登船站信息
		FightDataManager:getInstance():addEnemyFighterData(fightFighterData)
		print("getsAndSetsEnemyLayerInfoByEnemyOver")

		
		
		if index == 1 then 
			--设置title
			self.title:setString(string.format("%s(第%d层)",self.name,self.enemysIndex))
			self.description:setString(fightFighterData.description)
			-- self.buttons[1]:registerScriptTapHandler(function() 
   --      		self:enterFightLayer(false)
   --  		end)

			self.buttons[1]:registerScriptTapHandler(function() 
				self.enemysIndex = self.enemysIndex + 1
        		self:fightIsOver(true)
    		end)

			self.buttonTips[1]:setString("战 斗")
		end

		


		-- self.buttons[2]:registerScriptTapHandler(function() 
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
function EventLayer:changeToResurrectionLayer( ... )
	print("changeToResurrectionLayer")
end

--传送点
function EventLayer:changeToNextMapEnter( ... )
	-- body
end

--酒馆界面
function EventLayer:changeToPubLayer( ... )
	-- body
end

--黑市
function EventLayer:changeToBlackMarket( ... )
	-- body
end

--竞技场
function EventLayer:changeToArena(  )
	-- body
end

--材料据点
function EventLayer:changeToMaterials( ... )
	-- body
end

--怪物据点
function EventLayer:changeToEnemyLayer( ... )
	-- body
end

--需要材料
function EventLayer:changeTo( ... )
	-- body
end

-- --改变成招募界面
-- function EventLayer:changeToRecruitLayer( ... )
-- 	-- body
-- end

-- --改变成传送点
-- function EventLayer:changeToTeleport( ... )
-- 	-- body
-- end




function EventLayer:changet( ... )
	-- body
end




function EventLayer:enterNextLayer( )
	self.controller:anEventHasTriggered()

end

function EventLayer:enterFightLayer( isNeedShipBattle )
    local fightScene = FightScene:create()

    local fightType = enterFightLayer

   	if not isNeedShipBattle then
   		fightType = FightScene.FightType.aboardWar
   		self.enemysIndex =  self.enemysIndex + 1
   	end

    fightScene:setFightOverCallback(function()
        cclog("return from fight")
    end)
    if DataManager:getInstance():getMusic_off() == 0 then
        AudioEngine.playMusic(MUSIC_PK, true)
        HAS_MUSIC_FILE = 1
    else
        -- 不播放
    end
    local scene = cc.Scene:create()
    scene:addChild(fightScene)
    cc.Director:getInstance():pushScene(scene)
    self:leaveToExploreMap( false )
end

function EventLayer:fightIsOver( result )
	
	if result then
		self.controller:anEventHasTriggered()
	else
		self.controller:allMembersKilled()
	end

end

function EventLayer:leaveToExploreMap( arg )
	
	print("arg",arg)
	if not arg then
		self.controller:allEventsHasTriggered(arg)
	else
		self.controller:anEventHasToGiveUp()
	end

end

