require "AudioEngine"
require "LuaClass/Header"


--根据地图索引获取资料片信息
function getMapShopInfoByMapIndex( index )
    
    local csvData = DataManager:getInstance():getCSVByID(csvOfShopItem)
    -- printn("getMapShopInfoByMapIndex",csvData)
    local i = 1
    local cur_info = csvData["1"]

    while cur_info ~= nil do
        -- print("getMapShopInfoByMapIndex",tonumber(cur_info["unlock"]))
        if tonumber(cur_info["unlock"]) == index then
            print("getMapShopInfoByMapIndex",i)
            break
        end
        i = i + 1
        cur_info = csvData[tostring(i)]
    end

    return cur_info 
end


WorldMapLayer = class("WorldMapLayer",function ()
	 return cc.Layer:create()
end)

WorldMapLayer.__index = EventLayer
WorldMapLayer.owner = nil
WorldMapLayer.name = nil
WorldMapLayer.title = nil
WorldMapLayer.description = nil
WorldMapLayer.buttons = {}
WorldMapLayer.buttonTips = {}
WorldMapLayer.buttonSprs = {}
WorldMapLayer.buttonController = nil
WorldMapLayer.fogs = {}
WorldMapLayer.mapMaxIndex = 0
WorldMapLayer.curMapIndex = 0
WorldMapLayer.tipMapIndex = 0
WorldMapLayer.ships = {}
WorldMapLayer.statue = "ready"

function WorldMapLayer:create()
	print("WorldMapLayer:create()!");

	local worldMapLayer = WorldMapLayer.new()
	
	if worldMapLayer and worldMapLayer:init() then
		return worldMapLayer
	end

	return nil;
end

function WorldMapLayer:init()
    print("WorldMapLayer:init!");

    local winSize = cc.Director:getInstance():getVisibleSize()
    self.statue = "ready"
    --地图承载点
    local containerLayer = cc.Layer:create()
    containerLayer:setPosition(cc.p(0,0))
    --地图承载点的大小
    local contentSize = cc.size(0,0)
    --设置返回按钮
    local backBtn = SDButton:create("Images/Map/WorldMap/fanhang_a.png", "Images/Map/WorldMap/fanhang_b.png", function() 
        self:backToCurMap()
    end)
    backBtn:setScale(0.8)
    backBtn:setPosition(cc.p(winSize.width / 2 , backBtn:getContentSize().height * backBtn:getScaleY() ))
    self:addChild(backBtn)

    -- --按钮文字
    -- local buttonTips = cc.LabelTTF:create("返 航", BoldFont, 30)
    -- buttonTips:setPosition(cc.p(backBtn:getPositionX() ,backBtn:getPositionY()))
    -- buttonTips:setColor(opColorPrimroseYellow)
    -- self:addChild(buttonTips, 1000)

    --初始化地图
    local bottomMap = cc.Sprite:create("Images/Map/WorldMap/worldMapBottom.png")
    bottomMap:setPosition(cc.p(bottomMap:getContentSize().width / 2,bottomMap:getContentSize().height / 2))
    containerLayer:addChild(bottomMap)

    contentSize.width = bottomMap:getContentSize().width
    contentSize.height = bottomMap:getContentSize().height	

    local midMap = cc.Sprite:create("Images/Map/WorldMap/worldMapMid.png")
    midMap:setPosition(cc.p(bottomMap:getPositionX(),bottomMap:getPositionY() + bottomMap:getContentSize().height / 2 + midMap:getContentSize().height / 2))
    containerLayer:addChild(midMap)

    contentSize.height = contentSize.height + midMap:getContentSize().height

    local topMap = cc.Sprite:create("Images/Map/WorldMap/worldMapTop.png")
    topMap:setPosition(cc.p(midMap:getPositionX(),midMap:getPositionY() + midMap:getContentSize().height / 2 + topMap:getContentSize().height / 2))
    containerLayer:addChild(topMap)

    contentSize.height = contentSize.height + topMap:getContentSize().height

    containerLayer:setContentSize(contentSize)

    --获取坐标数据
    local csvData = DataManager:getInstance():getCSVByID(csvOfWorldMapCoordinates)

    --添加迷雾蒙层
    local fog = nil
    local mapButton = nil
    local mapName = nil
    local fogString = nil
    local buttonString = nil
    local mapButtons ={}
    local x = 0
    local y = 0
    --写死，读表效率低
    local names = {"瓶中船","皇家港","加勒比海","白帽港","深邃幽蓝","极地港","霜冻海湾","冤嚎之境","乱葬海","无尽之海","海中城堡","幽魂之域","神秘海域","远古封印","死亡之渊","世界尽头"}
    local chapterString = nil
    --开始赋值
    for k,v in pairs(csvData) do
    	--获取索引和图片名称
    	local index = tonumber(v["ID"])

    	buttonString = string.format("Images/Map/WorldMap/%s.png",v["buttonName"])

    	--设置button(透明图)
    	mapButton = cc.MenuItemImage:create("Images/Map/WorldMap/quang_10.png","Images/Map/WorldMap/quang_10.png")
    	x = tonumber(v["buttonX"])
    	y = contentSize.height - tonumber(v["buttonY"])
    	-- mapButton:setAnchorPoint(cc.p(0,1.0))
    	mapButton:setPosition(cc.p(x + mapButton:getContentSize().width * mapButton:getScaleX() / 2,y - mapButton:getContentSize().height * mapButton:getScaleY() / 2))
    	mapButton:registerScriptTapHandler(function (  )
    		print("will enterMapByIndex",index)
    		self:moveToMapByIndex(index)
    	end)

        self.buttons[index] = mapButton

        --原点
        local buttonTip = cc.Sprite:create(buttonString)
        -- buttonTip:setAnchorPoint(cc.p(0,1.0))
        buttonTip:setPosition(mapButton:getPosition())
        containerLayer:addChild(buttonTip, 1)
        self.buttonSprs[index] = buttonTip

        --船
        local ship = cc.Sprite:create("Images/Map/WorldMap/c.png")
        -- ship:setAnchorPoint(cc.p(0,1.0))
        x = tonumber(v["shipX"])
        y = contentSize.height - tonumber(v["shipY"])
        ship:setPosition(cc.p(x + ship:getContentSize().width * ship:getScaleX() / 2,y - ship:getContentSize().height * ship:getScaleY() / 2))
        containerLayer:addChild(ship, 1)

        self.ships[index] = ship

        ship:setVisible(false)

        --地图名字
        mapName = cc.LabelTTF:create(names[index],BoldFont,winSize.height * 0.025)
        mapName:setPosition(cc.p(mapButton:getPositionX() ,mapButton:getPositionY() - mapButton:getContentSize().height * mapButton:getScaleY() * 0.7 - mapName:getContentSize().height * mapName:getScaleY() / 2))
        mapName:setColor(opColorPrimroseYellow)
        containerLayer:addChild(mapName, 1)

        --地图名字背景图
        local chapterBg = cc.Sprite:create("Images/Map/WorldMap/k.png")
        chapterBg:setPosition(mapName:getPosition())
        containerLayer:addChild(chapterBg)

        --章节描述
        chapterString = string.format("第%s章",getChineseCharactersByNum(index)) 
        local chapter = cc.LabelTTF:create(chapterString,BoldFont,winSize.height * 0.02)
        chapter:setPosition(cc.p(mapName:getPositionX(),mapName:getPositionY() - mapName:getContentSize().height * mapName:getScaleY() * 0.7 - chapter:getContentSize().height * chapter:getScaleY() / 2))
        chapter:setColor(opColorPrimroseYellow)
        chapter:enableStroke(cc.c4b(0, 0, 0, 255), 1)
        containerLayer:addChild(chapter, 1)
        
        --迷雾蒙层
    	fogString = string.format("Images/Map/WorldMap/%s.png",v["name"])
    	fog = cc.Sprite:create(fogString)
    	fog:setAnchorPoint(cc.p(0,1.0))
    	x = tonumber(v["fogX"])
    	y = contentSize.height - tonumber(v["fogY"])
    	fog:setPosition(cc.p(x,y))
    	containerLayer:addChild(fog,2)
        fog:setOpacity(215)
    	self.fogs[index] = fog
    end

    --将item添加到menu上
    local buttonController = cc.Menu:create(unpack(self.buttons))
  	buttonController:setPosition(cc.p(0,0))
  	containerLayer:addChild(buttonController)

    print("csvData",#csvData)

    -- fog = cc.Sprite:create()

    --初始化scrollview
	self.scrollview = cc.ScrollView:create()
	self.scrollview:setPosition(cc.p(0,0))
	local scrollview_size = cc.Director:getInstance():getWinSize()
	self.scrollview:setViewSize(winSize)
	self.scrollview:setScale(1.0)
	self:addChild(self.scrollview);
  	self.scrollview:ignoreAnchorPointForPosition(true)
    self.scrollview:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.scrollview:setClippingToBounds(true)
    self.scrollview:setBounceable(false)
    self.scrollview:setDelegate()
    self.scrollview:setContainer(containerLayer)
    self.scrollview:updateInset()
    self.scrollview:registerScriptHandler(function ()

    end,cc.SCROLLVIEW_SCRIPT_SCROLL)
 
    self.mapMaxIndex = DataManager:getInstance():getRoleData(roleMapInfo).mapIndex
    -- self.mapMaxIndex = 16
    print("self.mapMaxIndex",type(self.mapMaxIndex),self.mapMaxIndex,self.scrollview)
    self:clearWorldFogs()
    return true;
end

function WorldMapLayer:tipMap( index )
    -- local tempData = DataManager:getInstance():getRoleData(roleMapInfo)

    -- local tipMapIndex = tempData.tipMapIndex

    -- if tipMapIndex == nil then
    --     return
    -- end
    local tempData = DataManager:getInstance():getRoleData(roleMapInfo)
    local isFadeOutIndex = tempData.fadeMapFogIndex

    if isFadeOutIndex == nil then
        isFadeOutIndex = 1
    end

    --若淡出层比当前层要小，则淡出，否则直接setvisible
    if isFadeOutIndex < index then
        --蒙层淡出效果
        local fadeOut = cc.FadeOut:create(1.2)
        self.fogs[index]:runAction(fadeOut)
        tempData.fadeMapFogIndex = index
        DataManager:getInstance():setRoleData(roleMapInfo,tempData)
    else
        self.fogs[index]:setVisible(false)
    end

    

    --若需要添加解锁动画
    if self.willTipLock then
        self.lock = nil
        local lock = cc.Sprite:create("Images/Map/WorldMap/mapLock.png")
        lock:setPosition(self.buttonSprs[index]:getPosition())
        self.buttonSprs[index]:getParent():addChild(lock,1)
        self.lock = lock
        self.buttonSprs[index]:setOpacity(0)
        --执行锁的动画
        self:lockAction()
    --否则正常执行
    else
        self.tipMapIndex = index
        local call1 = cc.CallFunc:create(function (  )
            self.buttons[index]:setOpacity(255)
            self.buttons[index]:setScale(1.0)
        end)

        --白光的效果扩大加谈出
        local scale = cc.ScaleTo:create(0.9,2.0)
        local fadeOut = cc.FadeOut:create(0.9)
        local spawn = cc.Spawn:create(scale, fadeOut)
        local seq = cc.Sequence:create(call1, spawn)
        local action = cc.RepeatForever:create(seq)

        self.buttons[index]:runAction(action)
    end

    

end

function WorldMapLayer:showChargeView( ... )
    self.statue = "charging"

    local charge = ChargeLayer:create()

    charge:setCancelCallback(function()
        self.statue = "ready"
        charge:destory()
    end)
end

--资料片购买界面
function WorldMapLayer:showBuyView(  )
    self.statue = "Buy"
    local price = tonumber(self.lockMapInfo["price"])


    local _alert = AlertView:create(2,0, "购买扩展包", function ( ... )
        --钻石足够了直接扣，否则弹出充值界面
        if DataManager:getInstance():addDiamond(-price) == 1 then
            self:unlockAction()
        else
            self.statue = "ready"
            
            --[[
            --钻石不足提示框
            local _alert = AlertView:create(2,0,"购买失败",function ( ... )
                self:showChargeView()
            end,function (  )
                self.statue = "ready"
            end)

            local showLabel1 = cc.LabelTTF:create("船长大人,由于钻石不足无法获得\n是否前往充值", BoldFont, 30)
            showLabel1:setColor(cc.c3b(255, 255, 255))
            -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
            showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y))
            -- print("showLabel1 will add")
            _alert:addChild(showLabel1)
            ]]--
        end


   end, function (  )
            
            self.statue = "ready"

        end)


    local showLabel1 = cc.LabelTTF:create(string.format("报告船长\n此处需要消耗钻石x%d购买扩展包\n才能继续进行探索。是否同意购买?",price), BoldFont, 30)
    showLabel1:setColor(cc.c3b(255, 255, 255))
    -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    showLabel1:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y))
    -- print("showLabel1 will add")
    _alert:addChild(showLabel1)

    local tempSpr = cc.Sprite:create("Images/btn/ann03_a.png")

    local priceLabel = cc.LabelTTF:create(string.format("花费钻石x%d",price), BoldFont, 20)
    priceLabel:setColor(cc.c3b(255, 255, 255))
    priceLabel:setPosition(cc.p(_alert.s_position.x + _alert.s_size.width * 0.25, _alert.s_position.y - _alert.s_size.height / 2 + 50 + tempSpr:getContentSize().height * 0.6))
    _alert:addChild(priceLabel)

end


--上锁动画
function WorldMapLayer:lockAction(  )

    local left1 = cc.RotateTo:create(0.1, -60)
    local right1 = cc.RotateTo:create(0.1,60)
    local left2 = cc.RotateTo:create(0.1, -60)
    local right2 = cc.RotateTo:create(0.1,60)
    local mid = cc.RotateTo:create(0.05,0)
    local seq = cc.Sequence:create(left1, right1,left2,right2,mid,cc.DelayTime:create(0.8)) 
    local action = cc.RepeatForever:create(seq)

    self.lock:runAction(action)
end

--接触数据限制
function WorldMapLayer:unlockMapDatas(  )

    --商城刷新状态
    local tempData = DataManager:getInstance():getRoleData(roleMapBuyItems)

    if tempData == nil then
        tempData = {}
    end

    local id = self.lockMapInfo["ID"]

    if id ~= nil then
        tempData[#tempData + 1] = id
        DataManager:getInstance():setRoleData(roleMapBuyItems,tempData)
    end
    
    --成就触发逻辑
    local itemType = self.lockMapInfo["resume"][1]
    local achive = self.lockMapInfo["achievement"]
    local nextLimited = tonumber(self.lockMapInfo["resume"][2])

    DataManager:getInstance():buyGoodsInDiamondStore(itemType,nextLimited,achive)

    print("下一个限制点为",nextLimited)
    --刷新限制点
    DataManager:getInstance():setRoleData(roleTranslateDoor,nextLimited)

end

--解锁动画
function WorldMapLayer:unlockAction(  )


    self.lock:stopAllActions()
    -- local index = 2
    local index = DataManager:getInstance():getRoleData(roleTranslateDoor) + 1

    self:unlockMapDatas()

    --执行解锁动画(放大和淡出)
    local cur_rotation = self.lock:getRotation()

    local expand = cc.ScaleTo:create(0.5,3.0)
    local fadeTime = 0.5
    local fadeOut = cc.FadeOut:create(fadeTime)
    local spawn = cc.Spawn:create(expand, fadeOut)
    local call1 = cc.CallFunc:create(function ( ... )
        self.lock:removeFromParent(true)
        self.statue = "ready"
        local call1 = cc.CallFunc:create(function ( ... )
            self.buttons[index]:setOpacity(255)
            self.buttons[index]:setScale(1.0)
        end)
           --白光的效果扩大加谈出
        local scale = cc.ScaleTo:create(0.9,2.0)
        local fadeOut = cc.FadeOut:create(0.9)
        local spawn = cc.Spawn:create(scale, fadeOut)
        local seq = cc.Sequence:create(call1, spawn)
        local action = cc.RepeatForever:create(seq)

        self.buttons[index]:runAction(action)
    end)
    local action = nil
    --若当前旋转度不为0，因为要平滑过度
    if cur_rotation ~= 0 then
        local mid = cc.RotateTo:create(0.1,0)
        fadeTime = fadeTime + 0.2
        action = cc.Sequence:create(mid, spawn, call1) 
    else
        action = cc.Sequence:create(spawn, call1) 
    end
    --按钮同时淡进
    self.buttonSprs[index]:runAction(cc.FadeIn:create(fadeTime))
    
    self.lock:runAction(action)

end

function WorldMapLayer:moveToCurMapCenter(  )

    local centerSpr = self.buttons[self.curMapIndex]
    local posY = centerSpr:getPositionY()

    local offset = cc.p(0,0)

    if posY > screenSize.height / 2 then

        offset.y = screenSize.height / 2 - posY

    end
    print("moveToCurMapCenter",self.scrollview)
    self.scrollview:setContentOffset(offset)

end

--移动到某一个地图上，并执行动画
function WorldMapLayer:moveToMapByIndex( index )

    --检查是否是已经开启的地图，不是则返回
    if index > self.mapMaxIndex  or self.statue ~= "ready" then

        return
    end

    --若是限制地图，则弹出购买提示
    if not self.owner:enterNextMapEnter(false,index,true) then
        self:showBuyView()
        return
    end

    self.statue = "moveAction"

--若index为当前记录点不播放任何动画，直接进入地图
    if index == self.curMapIndex then
        self:enterMapByIndex(index)
        return
    end

    --若进入的地图为提示的地图，关闭提示动画
    if self.tipMapIndex == index then
        self.buttons[index]:stopAllActions()
        self.buttons[index]:setOpacity(255)
        self.buttons[index]:setScale(1.0)
    end

--当前地图点
    self.buttons[self.curMapIndex]:setVisible(false)
    local expandTime = 0.05
    local narrowTime = 0.15

    --船放大与缩小
    local expand = cc.ScaleTo:create(expandTime,1.3)
    local narrow = cc.ScaleTo:create(narrowTime,0.2)

    local minScale = 1.0
    local maxScale = 1.5

    self.willEnter = false

    -- local time = 0.2
    --按钮显示和隐藏,船的移动
    local call1 = cc.CallFunc:create(function ( ... )
        print("call1")

        --船和原点图切换的工作
        self.ships[self.curMapIndex]:setVisible(false)
        self.ships[self.curMapIndex]:setScale(1.0)
        self.buttons[self.curMapIndex]:setVisible(true)
        -- self.willEnter = true
        -- local harmonic = nil
        -- harmonic = function ( ... )
        --     local expand = cc.ScaleTo:create(time,maxScale)
        --     local narrow = cc.ScaleTo:create(time,minScale)


        --     local action = cc.Sequence:create(expand, narrow)
        --     self.buttonSprs[self.curMapIndex]:runAction(action)
        -- end

        -- harmonic()
        -- self.buttonSprs[index]:setVisible(true)
    end)

    self.buttonSprs[self.curMapIndex]:setScale(1.0)
    self.buttonSprs[self.curMapIndex]:setVisible(true)

    local action = cc.Sequence:create(expand, narrow,call1)
    self.ships[self.curMapIndex]:runAction(action)

--目标地图点

     --原点放大与缩小
    -- local expand = cc.ScaleTo:create(expandTime,1.3)
    -- local narrow = cc.ScaleTo:create(narrowTime,1.0)

    local minScale = 1.0
    local maxScale = 1.5


    local call1 = cc.CallFunc:create(function ( ... )
        self.buttons[index]:setOpacity(255)
        self.buttons[index]:setScale(1.0)
    end)

    local call2 = cc.CallFunc:create(function ( ... )
        self.ships[index]:setScale(0.2)
        self.ships[index]:setVisible(true)
        local expand = cc.ScaleTo:create(0.0,1.3)
        local narrow = cc.ScaleTo:create(expandTime,1.0)
        local call1 = cc.CallFunc:create(function ( ... )
            self.buttonSprs[index]:setVisible(false)
            self.buttons[index]:setVisible(false)
            local call1 = cc.CallFunc:create(function ( ... )
                self.buttons[index]:setVisible(true)
                --移动进对应的地图
                self:enterMapByIndex(index)
            end)

            local action = cc.Sequence:create(expand,narrow,cc.DelayTime:create(0.1),call1)
            self.ships[index]:runAction(action)
        end)

        local action = cc.Sequence:create(expand, narrow,call1)
        self.ships[self.curMapIndex]:runAction(action)
    end)

    --白光的效果扩大加谈出
    local scale = cc.ScaleTo:create(0.3,2.0)
    local fadeOut = cc.FadeOut:create(0.3)
    local spawn = cc.Spawn:create(scale, fadeOut)
    local action = cc.Sequence:create(call1, spawn,call2)
    -- local action = cc.RepeatForever:create(seq)

    -- -- local time = 0.2
    -- --按钮显示和隐藏
    -- local call1 = cc.CallFunc:create(function ( ... )
    --     --原点和船图切换的工作
    --     self.ships[index]:setScale(1.0)
    --     self.buttonSprs[index]:setVisible(false)
    --     self.buttons[index]:setVisible(false)
    --     self.ships[index]:setVisible(true)
    --     self.buttonSprs[index]:setScale(1.0)

    --     -- local harmonic = nil
    --     -- harmonic = function ( ... )

    --     --     local expand = cc.ScaleTo:create(time,maxScale)
    --     --     local narrow = cc.ScaleTo:create(time,minScale)

    --     local call1 = cc.CallFunc:create(function ( ... )
    --         self.buttons[index]:setVisible(true)
    --         --移动进对应的地图
    --         self:enterMapByIndex(index)
    --     end)

    --     local action = cc.Sequence:create(cc.DelayTime:create(0.1),call1)
    --     self:runAction(action)

    --     --     local action = cc.Sequence:create(expand, narrow,call1)
    --     --     self.ships[index]:runAction(action)
    --     -- end

    --     -- harmonic()
    --     -- self.buttonSprs[index]:setVisible(true)
    -- end)

    -- local action = cc.Sequence:create(expand, narrow,call1)
    self.buttons[index]:runAction(action)

end

function WorldMapLayer:setOwner( owner )
	self.owner = owner
end

--清除占领过地图的世界迷雾和检查是否有需要提示进入的地图，并执行对应的提示动画
function WorldMapLayer:clearWorldFogs( )

    local tempData = DataManager:getInstance():getRoleData(roleMapInfo)

    local tipMapIndex = tempData.tipMapIndex

    print("clearWorldFogs",tipMapIndex)

    self.willTipLock = false

	for i=1,self.mapMaxIndex do
        -- print("i",i)
		if tipMapIndex ~= nil and tipMapIndex == i then
            --若提示地图为解锁地图，则需要执行上锁动画
            if DataManager:getInstance():getRoleData(roleTranslateDoor) + 1 == i then
                self.willTipLock = true
                --获取锁的资料片的商场信息
                self.lockMapInfo = getMapShopInfoByMapIndex(i)
            end
        else
            self.fogs[i]:setVisible(false)
        end	
	end	
    --获得当前地图点
    self.curMapIndex = DataManager:getInstance():getRoleData(roleMapInfo).curIndex

    self.ships[self.curMapIndex]:setVisible(true)
    self.buttonSprs[self.curMapIndex]:setVisible(false)

    -- self:tipMap(2)

    if tipMapIndex ~= nil then
        self:tipMap(tipMapIndex)
    end

    self:moveToCurMapCenter()
end

--返回当前地图
function WorldMapLayer:backToCurMap( )
    if self.statue ~= "ready" then
        return
    end

    self.owner:enterNextLayer(false)
    self:removeFromParent(true)
end

--进入某个地图
function WorldMapLayer:enterMapByIndex( index )
	
	
	print("enterMapByIndex",index)

    --成功进入地图后再删除本层
	if self.owner:enterNextMapEnter(true,index) then
        self:removeFromParent(true)
    end
end

