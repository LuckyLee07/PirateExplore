require "AudioEngine"
local CrewSkillDetails = require "LuaClass/CrewSkillDetails"
require "LuaClass/Header"
require "LuaClass/DialogTheme"
require "LuaClass/ItemIcon"
require "LuaClass/EventBaseView"


local visibleSize = cc.Director:getInstance():getVisibleSize()
local origin = cc.Director:getInstance():getVisibleOrigin()

local function showPopTips( tips )
    ToastUtil:toastString(tips)
end

-- 获取星星等级
local function getStarNode(count)
    local node = cc.Node:create()
    for ii = 1, count do
        local star = cc.Sprite:create("Images/UI/xingxing01.png")
        local starWdith = star:getContentSize().width
        star:setPosition(cc.p(starWdith*(ii-1), 0))
        star:setAnchorPoint(cc.p(0, 0.5))
        node:addChild(star)
    end
    return node
end

-- AlertView里的士兵CellItem
local function getStandardCellItem(data)
    printn("getCCC=====", data)
    local cell = cc.Node:create()
    
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_03.png")
    local bgSize = temp:getContentSize()
    local ccSize = temp:getContentSize()
    local pBacksp = DialogTheme.cardFromLegacy("Images/UI/dibantiao_03.png")
    --pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = -ccSize.width*0.5 + 25
    -- 添加CellIcon按钮
    local pIcon = ItemIcon.menuItem(data.icon)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5, 0))
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = pPosX1 + 185
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, MasterTheme.headingFont(false), fontSize+3);
    pName:setPosition(cc.p(pPosX1, pName:getContentSize().height*0.5 + 15))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, MasterTheme.headingFont(false), fontSize);
    pSkill:setPosition(cc.p(pPosX1, -5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.power or data.attack or "无")
    local pPower = cc.LabelTTF:create(power, MasterTheme.headingFont(false), fontSize);
    pPower:setPosition(cc.p(pPosX1, -pPower:getContentSize().height*0.5 - 20))
    pPower:setColor(WriteColor)
    -- pPower:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pPower:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pPower)
    
    -- 星级
    local pStars = getStarNode(data.star or 5)
    pStars:setPosition(cc.p(pPosX2, pName:getPositionY()))
    cell:addChild(pStars)
    
    -- 生命
    local life = "生命：" .. (data.hp or 0)
    local plife = cc.LabelTTF:create(life, MasterTheme.headingFont(false), fontSize);
    plife:setPosition(cc.p(pPosX2, -5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 速度
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, MasterTheme.headingFont(false), fontSize);
    pSpeed:setPosition(cc.p(pPosX2, -pSpeed:getContentSize().height*0.5 - 20))
    pSpeed:setColor(WriteColor)
    -- pSpeed:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSpeed:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSpeed)
    
    return cell
end

-------------------------------EventDetailsLayer-----------------------------------
EventDetailsLayer = class("EventDetailsLayer",function ()
	 return EventBaseView:create()
end)

EventDetailsLayer.__index = EventBaseView
EventDetailsLayer.data = {}
EventDetailsLayer.type = nil
EventDetailsLayer.leaveCalBack = nil

function EventDetailsLayer:create()
	local layer = EventDetailsLayer.new()
    if layer and layer:init() then
        return layer
    end
    
    return nil
end

function EventDetailsLayer:init()
    if self.coherentEventPage then self.type=EventDetailsLayer.type;self.data=EventDetailsLayer.data or {} end
    self:resetTitle()
    self:resetTableView()
    self:reloadDetails()
    return true;
end

function EventDetailsLayer:resetTitle()
    if self.coherentEventPage then return self:coherentDetailTitle() end

    self.buttonClicked = false

    -- Keep the native category title visible instead of baked-in lettering.
    self.titleLabel:setVisible(true)
    if self.type == 1 then
        self.titleLabel:setString("墓 地")
    elseif self.type == 2 then
        self.titleLabel:setString("酒 馆")
    elseif self.type == 3 then
        self.titleLabel:setString("黑 市")
        --检查数据
        self:checkDatas()

        local timeInterval = ExploreDataManager:getInstance():getBlackMarketRefreshTimeInterval()
        local curTime = NotificationNode:getInstance():GetGameTime()
        local disTime = ExploreDataManager:getInstance():getLastBlackMarketRefreshTime() + timeInterval - curTime

        if disTime < 1 then
            ExploreDataManager:getInstance():checkBlackMarketDatas()
            EventDetailsLayer.data = ExploreDataManager:getInstance():getBlackMarketDatas()

            curTime = NotificationNode:getInstance():GetGameTime()
            disTime = ExploreDataManager:getInstance():getLastBlackMarketRefreshTime() + timeInterval - curTime
        end 
       
        local hours = math.floor(disTime / 3600)
        disTime = disTime - hours * 3600
        local minutes = math.floor(disTime / 60)
        local seconds = disTime - minutes * 60
        local timeTip = string.format("距离下次刷新还有%02d : %02d : %02d",hours,minutes,seconds)

        self.timeTip = cc.LabelTTF:create(timeTip, MasterTheme.headingFont(false), 30)
        self.timeTip:setPosition(cc.p(screenSize.width / 2, 160))
        self:addChild(self.timeTip)

    elseif self.type == 4 then
        self.titleLabel:setString("货 舱")
        local sheet=DialogTheme.paperSheet(visibleSize.width-20,self.areaHeight+8)
        sheet:setPosition(self.centerPos);self:addChild(sheet,-1)
        self.tableview:setViewSize(cc.size(visibleSize.width,self.areaHeight-34))
    end
end

function EventDetailsLayer:resetTableView()
    if self.coherentEventPage then return self:initCoherentDetailTable() end
    local cellSize = cc.size(0, 0)
    if self.type == 1 then
        cellSize = cc.size(visibleSize.width, 150)
    else
        cellSize = cc.size(visibleSize.width, 92)
    end
    
    local fontSize = 22
    
    -- tableViewSelectItem --
    self.tableview:registerScriptHandler(function(view, cell)
        cclog("scrollView cell "..tostring(cell:getTag()).." touched")
    end, cc.TABLECELL_TOUCHED)
    
    -- tableViewItemForCell --
    self.tableview:registerScriptHandler(function( view, idx)
        idx = idx + 1
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()
        print("TTT=====", idx, "===", self.data)
        local data = self.data[idx]
        
        if self.type == 1 then
            self:initCemeteryCell(cell, cellSize, data, idx)
        elseif self.type == 2 then
            self:initPubBarCell(cell, cellSize, data, idx)
        elseif self.type == 3 then
            self:initBMarketCell(cell, cellSize, data, idx)
        elseif self.type == 4 then
            self:initPackageCell(cell, cellSize, data, idx)
        end
        
        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)

    -- tableViewHeightForRow --
    self.tableview:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        return cellSize.height, cellSize.width --这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)

    -- tableViewAllItemsNumber --
    self.tableview:registerScriptHandler(function(view)
        return self:getDataSize()
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)

    --显示对应的cell信息
    self.tableview:registerScriptHandler(function ( view,cell )
        local idx = cell:getTag()
        self:showCellInfo(idx)
    end,cc.TABLECELL_TOUCHED)

    if self.type == 3 then
        local checkDatas = function (  )
            local timeInterval = ExploreDataManager:getInstance():getBlackMarketRefreshTimeInterval()
            local curTime = NotificationNode:getInstance():GetGameTime()
            local disTime = ExploreDataManager:getInstance():getLastBlackMarketRefreshTime() + timeInterval - curTime

            if disTime < 1 then
                ExploreDataManager:getInstance():checkBlackMarketDatas()
                EventDetailsLayer.data = ExploreDataManager:getInstance():getBlackMarketDatas()
                self:reloadDetails()
                curTime = NotificationNode:getInstance():GetGameTime()
                disTime = ExploreDataManager:getInstance():getLastBlackMarketRefreshTime() + timeInterval - curTime
            end 

             local hours = math.floor(disTime / 3600)
            disTime = disTime - hours * 3600
            local minutes = math.floor(disTime / 60)
            local seconds = disTime - minutes * 60
            local timeTip = string.format("距离下次刷新还有%02d : %02d : %02d",hours,minutes,seconds)
            self.timeTip:setString(timeTip)
        end

        schedule(self,checkDatas, 1.0)
    end

end

function EventDetailsLayer:reloadData()
    
end

function EventDetailsLayer:getDataSize()
    local size = 0
    if self.data then size = #self.data end
    return size
end

-- 初始化墓地CellItem
function EventDetailsLayer:initCemeteryCell(cell, ccSize, data, index)
    if self.coherentEventPage then return self:coherentRow(cell,ccSize,data,index) end
    if data == nil then return end
    
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = DialogTheme.card(590, ccSize.height-10)
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = ItemIcon.menuItem(data.icon)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5+20, ccSize.height*0.5))
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    if data.num ~= nil and data.num > 1 then
        local pNums = cc.Sprite:create("Images/UI/num_circlebg.png")
        --pNums:setScale(2)
        pNums:setPosition(cc.p(pIcon:getPositionX()+pIcon:getContentSize().width*0.5-2, pIcon:getPositionY()+pIcon:getContentSize().height*0.5-2))
        cell:addChild(pNums)
        local  fNum = cc.LabelTTF:create(data.num, MasterTheme.headingFont(false), fontSize);
        fNum:setColor(BaseColor)
        fNum:setPosition(pNums:getPosition())
        -- fNum:enableStroke(cc.c4b(215, 199, 165, 255), 1)
        cell:addChild(fNum)
    end
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, MasterTheme.headingFont(false), fontSize+3);
    pName:setPosition(cc.p(pPosX1, ccSize.height*0.5 + pName:getContentSize().height*0.5 + 20))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, MasterTheme.headingFont(false), fontSize);
    pSkill:setPosition(cc.p(pPosX1, ccSize.height*0.5 - 5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.attack or 0)
    local pPower = cc.LabelTTF:create(power, MasterTheme.headingFont(false), fontSize);
    pPower:setPosition(cc.p(pPosX1, ccSize.height*0.5 - pPower:getContentSize().height*0.5 - 20))
    pPower:setColor(WriteColor)
    -- pPower:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pPower:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pPower)
    
    local pPosX2 = pPosX1 + 172
    -- 星级
    local pStars = getStarNode(data.star or 5)
    pStars:setPosition(cc.p(pPosX2, pName:getPositionY()))
    cell:addChild(pStars)
    
    -- 技能
    local life = "生命：" .. (data.hp or 0)
    local plife = cc.LabelTTF:create(life, MasterTheme.headingFont(false), fontSize);
    plife:setPosition(cc.p(pPosX2, ccSize.height*0.5 - 5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 威力
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, MasterTheme.headingFont(false), fontSize);
    pSpeed:setPosition(cc.p(pPosX2, ccSize.height*0.5 - pSpeed:getContentSize().height*0.5 - 20))
    pSpeed:setColor(WriteColor)
    -- pSpeed:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSpeed:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSpeed)
    
    -- 复活/埋葬 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnAlive = DialogTheme.menuItem("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnAlive:setPosition(cc.p(rightPosx-btnAlive:getContentSize().width*0.5, ccSize.height*0.7))
    local alive = cc.LabelTTF:create("复 活", MasterTheme.headingFont(false), 28.0)
    alive:setPosition(cc.p(btnAlive:getContentSize().width*0.5, btnAlive:getContentSize().height*0.5))
    -- alive:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    btnAlive:addChild(alive)
    
    local btnBury = DialogTheme.menuItem("Images/btn/ann01_a.png", "Images/btn/ann01_b.png", "secondary")
    btnBury:setPosition(cc.p(rightPosx-btnBury:getContentSize().width*0.5, ccSize.height*0.3))
    local bury = cc.LabelTTF:create("埋 葬", MasterTheme.headingFont(false), 28.0)
    bury:setPosition(cc.p(btnBury:getContentSize().width*0.5, btnBury:getContentSize().height*0.5))
    -- bury:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    btnBury:addChild(bury)
    
    -- 注册按钮点击事件
    btnAlive:registerScriptTapHandler(function() self:reliveCallBack(data, index) end)
    btnBury:registerScriptTapHandler(function() self:buryCallBack(data, index) end)
    
    local menu = cc.Menu:create(btnAlive, btnBury)
    menu:setPosition(0.0, 0.0)
    cell:addChild(menu)
end

-- 初始化酒馆CellItem
function EventDetailsLayer:initPubBarCell(cell, ccSize, data, index)
    if self.coherentEventPage then return self:coherentRow(cell,ccSize,data,index) end
    local fontSize = 25
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = DialogTheme.card(590, ccSize.height-10)
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = ItemIcon.menuItem(data.icon)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5+20, ccSize.height*0.5))
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = pPosX1 + 172 --visibleSize.width*0.5 - 18
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, MasterTheme.headingFont(false), fontSize+3);
    --pName:setPosition(cc.p(pPosX1, ccSize.height*0.5 + pName:getContentSize().height*0.5 + 15))
    pName:setPosition(cc.p(pPosX1, ccSize.height*0.7))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 星级
    local pStars = getStarNode(data.star or 0)
    pStars:setPosition(cc.p(pPosX2, pName:getPositionY()))
    cell:addChild(pStars)
    
    local cost = nil

    if data.costType == "1" then
        cost = "金币x"
    else
        cost = "钻石x"
    end

    -- 钻石
    cost = cost .. (data.costs or 0)
    local pCost = cc.LabelTTF:create(cost, MasterTheme.headingFont(false), fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(WriteColor)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
    
    --[[
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, MasterTheme.headingFont(false), fontSize);
    pSkill:setPosition(cc.p(pPosX1, ccSize.height*0.5 - 5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.power or "无")
    local pPower = cc.LabelTTF:create(power, MasterTheme.headingFont(false), fontSize);
    pPower:setPosition(cc.p(pPosX1, ccSize.height*0.5 - pPower:getContentSize().height*0.5 - 20))
    pPower:setColor(WriteColor)
    -- pPower:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pPower:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pPower)
    
    -- 生命
    local life = "生命：" .. (data.hp or 0)
    local plife = cc.LabelTTF:create(life, MasterTheme.headingFont(false), fontSize);
    plife:setPosition(cc.p(pPosX2, ccSize.height*0.5 - 5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 速度
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, MasterTheme.headingFont(false), fontSize);
    pSpeed:setPosition(cc.p(pPosX2, ccSize.height*0.5 - pSpeed:getContentSize().height*0.5 - 20))
    pSpeed:setColor(WriteColor)
    -- pSpeed:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSpeed:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSpeed)
    ]]--
    
    -- 购买 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnBuy = DialogTheme.menuItem("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnBuy:setPosition(cc.p(rightPosx-btnBuy:getContentSize().width*0.5, ccSize.height*0.5))
    local buy = cc.LabelTTF:create("购 买", MasterTheme.headingFont(false), 28.0)
    buy:setPosition(cc.p(btnBuy:getContentSize().width*0.5, btnBuy:getContentSize().height*0.5))
    -- buy:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    btnBuy:addChild(buy)
    
    local menu = cc.Menu:create(btnBuy)
    menu:setPosition(0.0, 0.0)
    cell:addChild(menu)
    
    -- 注册按钮点击事件
    btnBuy:registerScriptTapHandler(function() self:buyHeroCallBack(data, index) end)
end

-- 初始化黑市CellItem
function EventDetailsLayer:initBMarketCell(cell, ccSize, data, index)
    if self.coherentEventPage then return self:coherentRow(cell,ccSize,data,index) end
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = DialogTheme.card(590, ccSize.height-10)
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = ItemIcon.menuItem(data.icon)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5+20, ccSize.height*0.5))
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    -- Icon点击事件
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = visibleSize.width*0.5 - 20
    local pPosX3 = visibleSize.width*0.5 - 40
    -- 名字
    local name = data.name

    if data.num > 1 then
        name = name.." X "..data.num
    end
    local pName = cc.LabelTTF:create(name, MasterTheme.headingFont(false), fontSize+3);
    pName:setPosition(cc.p(pPosX1, ccSize.height*0.7))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 星级
    local pStars = getStarNode(data.star or 0)
    pStars:setPosition(cc.p(pPosX2, pName:getPositionY()))
    cell:addChild(pStars)
    
    -- 花费道具
    local cost = nil

    if data.costType == "1" then
        cost = "金币x"
    else
        cost = "钻石x"
    end

    -- 钻石
    cost = cost .. (data.costs or 0)
    local pCost = cc.LabelTTF:create(cost, MasterTheme.headingFont(false), fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(WriteColor)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
    
    -- 购买 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnBuy = DialogTheme.menuItem("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnBuy:setPosition(cc.p(rightPosx-btnBuy:getContentSize().width*0.5, ccSize.height*0.5))
    local buy = cc.LabelTTF:create("购 买", MasterTheme.headingFont(false), 28.0)
    buy:setPosition(cc.p(btnBuy:getContentSize().width*0.5, btnBuy:getContentSize().height*0.5))
    -- buy:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    btnBuy:addChild(buy)
    
    local menu = cc.Menu:create(btnBuy)
    menu:setPosition(0.0, 0.0)
    cell:addChild(menu)
    
    -- 注册按钮点击事件
    local itemId = data.id
    local cost = data.costs or 0
    btnBuy:registerScriptTapHandler(function() self:buyItemCallBack(data, index) end)
end

-- 初始化背包CellItem
function EventDetailsLayer:initPackageCell(cell, ccSize, data, index)
    if self.coherentEventPage then return self:coherentRow(cell,ccSize,data,index) end
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = DialogTheme.ledgerRow(590, ccSize.height-10)
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = ItemIcon.menuItem(data.icon)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5+20, ccSize.height*0.5))
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    -- Icon点击事件
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = visibleSize.width*0.5 - 20
    -- 名字
    local name = data.name
    local pName = cc.LabelTTF:create(name, MasterTheme.headingFont(false), fontSize+3);
    pName:setPosition(cc.p(pPosX1, ccSize.height*0.7))
    pName:setColor(MasterTheme.colors.ink)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 星级
    local pStars = getStarNode(data.star or 0)
    pStars:setPosition(cc.p(pPosX2, pName:getPositionY()))
    cell:addChild(pStars)
    
    -- 花费道具
    local cost = "数量：" .. (data.num or 0)
    local pCost = cc.LabelTTF:create(cost, MasterTheme.headingFont(false), fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(MasterTheme.colors.muted)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
end

--- 墓地复活接口 ---
function EventDetailsLayer:reliveCallBack(data, index)
    if self.coherentEventPage and not self:isCurrentEventData(data,index)then return end
    printn(data)
    local commit = function()
                                    printn(data)
        local result =  ExploreBagController:getBagController():costGoodsByGoodsIdAndNum(data.cost.id,data.cost.costNum,false)   --DataManager:getInstance():addCoin(cost)
        if result then
            showPopTips("复活成功，英雄已回到您的城堡中待命")
            DataManager:getInstance():addSoilderWithId(data.id, 1)
            if self.data[index].num == 1 then
                table.remove(self.data, index)
                --self.data[index] = nil //不能直接设置为nil，tableview访问会出问题
            else
                local num = self.data[index].num
                self.data[index].num = num - 1
            end

            DataManager:getInstance():setRoleData(roleDeathInformation, self.data)

            self:reloadDetails()
        else -- 
            showPopTips("缺少材料，复活失败！")
        end
    end
    if self.coherentEventPage then
        return self:confirmCoherentEventAction(data,index,"复活","花费 "..tostring((data.cost or {}).name or "未知材料").." × "..tostring((data.cost or {}).costNum or 0).."，复活一位"..tostring(data.name or "船员").."？",commit)
    end
    local _layer = AlertView:create(2,0, "复 活", commit,nil)
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
    
    
    -- cost describe
    local cost = data.cost
    local desc = "花费" .. (cost.costNum or 0) .. (cost.name or "无") .. "复活一个" .. (data.name or "无") .. "?"
    local descLabel = cc.LabelTTF:create(desc, MasterTheme.headingFont(false), 28.0)
    descLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 105))
    -- descLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    descLabel:setColor(WriteColor)
    _layer:addChild(descLabel)
end

--- 墓地埋葬接口 ---
function EventDetailsLayer:buryCallBack(data, index)
    if self.coherentEventPage and not self:isCurrentEventData(data,index)then return end
    printn(data)
    local commit = function()
        showPopTips("埋葬成功，获得尸尘x1！")

        --添加尸尘
        ExploreBagController:getBagController():addItemToBattlePack("1035",1)

        local dataId = data.id
        if type(data.id) == "number" then dataId = dataId .. "" end
        if self.data[index].num == 1 then
            --self.data[index] = nil
            table.remove(self.data, index)
        else
            local num = self.data[index].num
            self.data[index].num = num - 1
        end

        DataManager:getInstance():setRoleData(roleDeathInformation, self.data)

        printn("1234",data,data.star)
        local star = tonumber(data.star)

        --埋葬成就记录点
        if star == 1 then
            print("走了1星的埋葬")
            achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Star1)
            DataManager:getInstance():setAchievementInfo(achievement_Star1, (achievementValue + 1))
        elseif star == 2 then
            print("走了2星的埋葬")
            achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Star2)
            DataManager:getInstance():setAchievementInfo(achievement_Star2, (achievementValue + 1))
        elseif star == 3 then
            print("走了3星的埋葬")
            achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Star3)
            DataManager:getInstance():setAchievementInfo(achievement_Star3, (achievementValue + 1))
        elseif star == 4 then
            print("走了4星的埋葬")
            achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Star4)
            DataManager:getInstance():setAchievementInfo(achievement_Star4, (achievementValue + 1))
        elseif star == 5 then
            print("走了5星的埋葬")
            achievementValue = DataManager:getInstance():getAchievementInfo(achievement_Star5)
            DataManager:getInstance():setAchievementInfo(achievement_Star5, (achievementValue + 1))
        end

        self:reloadDetails()
    end
    if self.coherentEventPage then
        return self:confirmCoherentEventAction(data,index,"埋葬","埋葬一位"..tostring(data.name or "船员").."，获得尸尘 × 1？",commit)
    end
    local _layer = AlertView:create(2,0, "埋 葬", commit,nil)
    
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
                                    
                                    
    -- get describe
    local desc = "你确定要埋葬" .. (data.name or "无") .. "吗?"
    local descLabel = cc.LabelTTF:create(desc, MasterTheme.headingFont(false), 28)
    descLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 115))
    -- descLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    descLabel:setColor(WriteColor)
    _layer:addChild(descLabel)
    
    local gets = "(可获得尸尘x" .. 1 .. ")"
    local getsLabel = cc.LabelTTF:create(gets, MasterTheme.headingFont(false), 22)
    getsLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 80))
    -- getsLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    getsLabel:setColor(WriteColor)
    _layer:addChild(getsLabel)
end

--- 酒馆购买接口 ---
function EventDetailsLayer:buyHeroCallBack(data, index)
    if self.coherentEventPage and not self:isCurrentEventData(data,index)then return end
    printn(data)
    self.buttonClicked = true
    local commit = function()
        local cost = data.costs or 0
        local result = nil
        if data.costType == "1" then
            result = DataManager:getInstance():addCoin(-cost,true)
        else
            result = DataManager:getInstance():addDiamond(-cost,true,nil,self.coherentEventPage and require('LuaClass/WarmShortageOwnership').forOwner(self,'eventGeneration',function()return self:isCurrentEventData(data,index)end)or nil)
        end
    
        if result == 1 then  -- 购买成功
            -- The original crew grant already reports the exact new quantity.
            -- Keep that receipt instead of stacking a second generic success.
            if not self.coherentEventPage then showPopTips("购买成功！")end
            DataManager:getInstance():addSoilderWithId(data.id, 1)
            -- self.data[index] = nil --暂时屏蔽所有酒馆购买消失的事件
            self:reloadDetails()
        else -- 购买失败
            showPopTips("金币不足！")
        end
    end
    if self.coherentEventPage then
        return self:confirmCoherentEventAction(data,index,"招募","花费 "..(data.costType=="1" and "金币 "or"钻石 ")..tostring(data.costs or 0).."，招募一位"..tostring(data.name or "船员").."？",commit)
    end
    local _layer = AlertView:create(2, 0, "购 买", commit,nil)
    
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
    
    -- desc1
    local posY = cellItem:getPositionY() + 105
    local posX = _layer.s_position.x - 125
    local costTip1 = cc.LabelTTF:create("花费", MasterTheme.headingFont(false), 28.0)
    costTip1:setPosition(cc.p(posX, posY))
    -- costTip1:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    costTip1:setColor(WriteColor)
    costTip1:setAnchorPoint(cc.p(1.0, 0.5))
    _layer:addChild(costTip1)
    
    -- goal icon
    local costTip2 = nil  
    if data.costType == "1" then
        costTip2 = cc.Sprite:create("Images/UI/CoinBg.png")
    elseif data.costType == "2" then
        costTip2 = cc.Sprite:create("Images/UI/DiamondBg.png")
    end

    costTip2:setPosition(costTip1:getPosition())
    costTip2:setAnchorPoint(cc.p(0.0, 0.5))
    _layer:addChild(costTip2)
    
    -- desc2
    local desc = "x" .. (data.costs or 0) .. "购买一个" .. (data.name or "无") .. "?"
    local costTip3 = cc.LabelTTF:create(desc, MasterTheme.headingFont(false), 28.0)
    costTip3:setPosition(cc.p(costTip2:getPositionX()+costTip2:getContentSize().width, posY))
    -- costTip3:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    costTip3:setColor(WriteColor)
    costTip3:setAnchorPoint(cc.p(0.0, 0.5))
    _layer:addChild(costTip3)
end

--检查是否要去除掉一些数据
function EventDetailsLayer:checkDatas(  )
    
    local restrictions = DataManager:getInstance():getRoleData(roleBlackMarketRestrictions)
    printn("checkDatas",restrictions)
    --若限制数据为空
    if restrictions == nil then
        return
    end


    for i=#self.data,1,-1 do

        local tempRestrictions = restrictions.tempRestrictions

        --若是之前限制物品，判断其剩下次数是否为0，为0就删除
        if restrictions[self.data[i].id] ~= nil and restrictions[self.data[i].id] == 0 then
            table.remove(self.data, i)
        elseif tempRestrictions ~= nil and tempRestrictions[self.data[i].id] ~= nil and tempRestrictions[self.data[i].id] == 0 then
            table.remove(self.data, i)
        end
    end

end

function EventDetailsLayer:trySaveLimitedData( id,index )
    
    id = tostring(id)

    --判断是否需要改变某些数值，如富强粉之类的物品
    DataManager:getInstance():upgradeResourceUnitWithId(id)

    local limit = tonumber(dataController.getResourceValueByIdAndKey(id,"limits"))

    print("trySaveLimitedData",limit)
    if limit > 0 then

        local data = DataManager:getInstance():getRoleData(roleBlackMarketRestrictions)

        if data == nil then
            data = {}
        end

        local remaining = data[id]
        
        if remaining == nil then
            remaining = limit
            data[id] = remaining
        end

        remaining = remaining - 1

        if remaining <= 0 then
            --从data中移除掉
            table.remove(self.data, index)
            remaining = 0
        end

        data[id] = remaining
        DataManager:getInstance():setRoleData(roleBlackMarketRestrictions,data)

    elseif limit < -1 then

        if limit == -2 then
            limit = -1
        end

        local restrictions = DataManager:getInstance():getRoleData(roleBlackMarketRestrictions)

        if restrictions == nil then
            restrictions = {}
        end

        if not restrictions.tempRestrictions then
            restrictions.tempRestrictions = {}
        end

        local data = restrictions.tempRestrictions

        local remaining = data[id]

        if not remaining then

            remaining = -limit
            data[id] = remaining

        end

        remaining = remaining - 1

        if remaining <= 0 then
            --从data中移除掉
            table.remove(self.data, index)
            remaining = 0
        end

        data[id] = remaining

        DataManager:getInstance():setRoleData(roleBlackMarketRestrictions,restrictions)
    end

end

--- 黑市购买接口 ---
function EventDetailsLayer:buyItemCallBack(data, index)
    if self.coherentEventPage and not self:isCurrentEventData(data,index)then return end

    
    -- if ExploreBagController:getBagController().costSpace == ExploreBagController:getBagController().limited then
    --     showPopTips("购买失败！背包已经满")
    --     return
    -- end

    self.buttonClicked = true

    local cost = data.costs or 0
    local result = nil
    if data.costType == "1" then
        result = DataManager:getInstance():addCoin(-cost,true)
    else
        result = DataManager:getInstance():addDiamond(-cost,true,nil,self.coherentEventPage and require('LuaClass/WarmShortageOwnership').forOwner(self,'eventGeneration',function()return self:isCurrentEventData(data,index)end)or nil)
    end

    if result == 1 then  -- 购买成功
        ExploreBagController:getBagController():addItemToBattlePack(data.id, data.num,true)
        --self.data[index] = nil
        self:trySaveLimitedData(data.id,index)
        if self.coherentEventPage then
            showPopTips(tostring(data.name or '物品')..' × '..tostring(data.num or 1)..' · '..(data.costType=='1' and '金币 −'or'钻石 −')..tostring(cost))
        else showPopTips("购买成功！")end
        self:reloadDetails()
    else -- 购买失败
        showPopTips("金币不足！")
    end
end

function EventDetailsLayer:viewWillClose( isNormal )
    print("EventDetailsLayer:viewWillClose")
    -- self:close()
end

function EventDetailsLayer:clickIcon( data )
    -- body
end


function EventDetailsLayer:showCellInfo( idx )
    if self.coherentEventPage then
        if not self.data[idx] then return end
        require('LuaClass/WarmShortageOwnership').retire(self)
        self.eventSelectedIndex=idx;self.eventSelectedData=self.data[idx];self.eventGeneration=self.eventGeneration+1
        local offset=self.tableview:getContentOffset();self.tableview:reloadData();self.tableview:setContentOffset(offset);self:refreshCoherentSelection();return
    end
    print("点击到index为",idx)

    --若点击过按钮，则直接返回，把按钮点击状态置为没有点击
    if self.buttonClicked == true then
        self.buttonClicked = false
        return
    end

    if self.data == nil then
        return
    end

    print("target.infoNode:setVisible(true)",self.type,self.data[idx],self.type)

    local data = self.data[idx]

    if data == nil then
        return
    end

    local infos = data.name
    --墓地
    if self.type == 1 then
        return
    --黑市或货仓
    elseif self.type == 3 or self.type == 4 then

        local info = dataController.getResourceInfoById(data.id)

        if info ~= nil then
            infos = string.format("%s\n%s",infos,dataController.getResourceValueByIdAndKey(data.id,"desc"))
        else
            local soilderInfos = dataController.getSoilderInfoById(data.id)
            local skillName, skillInfo = CrewSkillDetails.describe(soilderInfos and soilderInfos.skill,
                DataManager:getInstance():getCSVByID(csvOfSkillAttribute),
                DataManager:getInstance():getCSVByID(csvOfBuff))
            if not soilderInfos then
                infos = infos.."\n船员详情暂不可用"
            else
                infos = string.format("%s\n技能: %s\n技能效果:%s\n 生命: %d 威力: %d 速度: %0.1f",infos,skillName,skillInfo,soilderInfos["hp"],soilderInfos["attack"],soilderInfos["speed"])
            end
        end
        
    --酒馆
    elseif self.type == 2 then
        local soilderInfos = dataController.getSoilderInfoById(data.id)
        local skillName, skillInfo = CrewSkillDetails.describe(soilderInfos and soilderInfos.skill,
            DataManager:getInstance():getCSVByID(csvOfSkillAttribute),
            DataManager:getInstance():getCSVByID(csvOfBuff))
        if not soilderInfos then
            infos = infos.."\n船员详情暂不可用"
        else
            infos = string.format("%s\n技能: %s\n技能效果:%s\n 生命: %d 威力: %d 速度: %0.1f",infos,skillName,skillInfo,soilderInfos["hp"],soilderInfos["attack"],soilderInfos["speed"])
        end
    end
    print("infos",infos)
    self.willCloseInfos = false
    self.infoNode:setVisible(true)
    self.infoLabel:setString(infos)
    -- Grow upward from the existing footer boundary; native CJK line height
    -- can exceed the legacy fixed 120px card even with only four lines.
    if self.bottomInfoBox then
        local old = self.bottomInfoBox
        local size = old:getContentSize()
        local height = math.max(120, self.infoLabel:getContentSize().height + 32)
        local x = old:getPositionX()
        local y = old:getPositionY() - size.height / 2 + height / 2
        if size.height ~= height then
            self.bottomInfoBox = DialogTheme.card(size.width, height)
            self.infoNode:addChild(self.bottomInfoBox)
            old:removeFromParent(true)
        end
        self.bottomInfoBox:setPosition(cc.p(x, y))
        self.infoLabel:setPosition(cc.p(x, y))
    end
    print("infos",self.infoLabel:getString())
end

function EventDetailsLayer:close(  )
    if self.coherentEventPage then
        if self.eventClosed then return end
        require('LuaClass/WarmShortageOwnership').retire(self)
        self.eventClosed=true;self.eventGeneration=self.eventGeneration+1
        if self.ownerEvent and self.ownerEvent.eventDetails==self then self.ownerEvent.eventDetails=nil end
        self.ownerEvent=nil
        if self.adventureDialog and self.adventureDialog.close then self.adventureDialog.close()end
    end
    
    print("EventDetailsLayer:close")

    if self.leaveCalBack ~= nil then
        self.leaveCalBack()
    end

    self:removeFromParent(true)
end

-------------------------------EventDetailsLayer-----------------------------------

function EventDetailsLayer:coherentDetailTitle()
    local titles={'墓地','酒馆','黑市','货舱'}
    self.titleLabel:setString(titles[self.type]or'海上见闻')
    local subtitles={'选择一位船员，查看复活条件','选择船员，查看能力与招募价格','选择货物，查看价格与购买限制','查看航行中的货物与详情'}
    self.eventSubtitle:setString(subtitles[self.type]or'');EventPageUI.theme().fit(self.eventSubtitle,self.eventSize.width-48)
    self.eventSubtitle:setPositionY(self.eventSize.height-94)
    self.buttonClicked=false
    if self.type==3 then
        self:checkDatas()
        self.timeTip=EventPageUI.text(self,'',19,EventPageUI.theme().colors.muted,24,self.eventSize.height-135,self.eventSize.width-48)
        self:refreshCoherentMarketClock()
        schedule(self,function()if not self.eventDisposed then self:refreshCoherentMarketClock()end end,1)
    end
end
function EventDetailsLayer:refreshCoherentMarketClock()
    local dm=ExploreDataManager:getInstance();local now=NotificationNode:getInstance():GetGameTime()
    local left=dm:getLastBlackMarketRefreshTime()+dm:getBlackMarketRefreshTimeInterval()-now
    if left<1 then
        dm:checkBlackMarketDatas();self.data=dm:getBlackMarketDatas();EventDetailsLayer.data=self.data
        left=dm:getLastBlackMarketRefreshTime()+dm:getBlackMarketRefreshTimeInterval()-NotificationNode:getInstance():GetGameTime()
        if self.eventDetailScroll then self:reloadDetails()end
    end
    left=math.max(0,left);self.timeTip:setString(string.format('刷新倒计时 %02d:%02d:%02d',math.floor(left/3600),math.floor(left/60)%60,left%60))
end
function EventDetailsLayer:initCoherentDetailTable()
    local E=EventPageUI;local W=E.theme();local w,h=self.eventSize.width,self.eventSize.height
    self.eventListMaxHeight=math.min(240,math.floor((h-130)*.34));self.eventListHeight=self.eventListMaxHeight;self.eventListTop=h-158
    self.tableview:setViewSize(cc.size(w-48,self.eventListHeight));self.tableview:setPosition(cc.p(24,self.eventListTop-self.eventListHeight))
    self.tableview:setBounceable(false)
    if self.type~=3 then self.listCaption=E.text(self,'',19,W.colors.muted,24,h-135,w-48)end
    self.eventListDivider=E.rule(self,24,self.eventListTop-self.eventListHeight-12,w-48)
    local detailTop=self.eventListTop-self.eventListHeight-30
    self.eventDetailScroll=E.scroll(self,24,118,w-48,detailTop-118)
    self.eventActionDock=cc.Node:create();self:addChild(self.eventActionDock,4);E.rule(self,24,103,w-48)
    self.eventSelectedIndex=1
    self.tableview:registerScriptHandler(function()return self:getDataSize()end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableview:registerScriptHandler(function()return 80,w-48 end,cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableview:registerScriptHandler(function(view,index)
        local cell=view:dequeueCell()or cc.TableViewCell:create();cell:removeAllChildren();cell:setTag(index+1)
        local data=self.data[index+1];local size=cc.size(w-48,80)
        if self.type==1 then self:initCemeteryCell(cell,size,data,index+1)
        elseif self.type==2 then self:initPubBarCell(cell,size,data,index+1)
        elseif self.type==3 then self:initBMarketCell(cell,size,data,index+1)
        else self:initPackageCell(cell,size,data,index+1)end
        return cell
    end,cc.TABLECELL_SIZE_AT_INDEX)
    self.tableview:registerScriptHandler(function(_,cell)
        if E.alive(self) and not E.blocked(self)then self:showCellInfo(cell:getTag())end
    end,cc.TABLECELL_TOUCHED)
end
function EventDetailsLayer:coherentRow(cell,size,data,index)
    if not data then return end
    local E=EventPageUI;local W=E.theme();local selected=self.eventSelectedIndex==index
    if selected then cell:addChild(W.panel(size.width,size.height,cc.c3b(232,239,221),0))end
    local icon=ItemIcon.sprite(data.icon);local z=icon:getContentSize();icon:setScale(math.min(52/z.width,58/z.height));icon:setPosition(cc.p(34,40));cell:addChild(icon)
    local name=tostring(data.name or '未知')
    if self.type==1 or self.type==3 or self.type==4 then name=name..' × '..tostring(data.num or 1)end
    local label=E.text(cell,name,24,W.colors.ink,74,53,size.width-86)
    label:setDimensions(cc.size(0,0));W.fit(label,size.width-86)
    local detail
    if self.type==1 then detail='星级 '..tostring(data.star or 0)..' · '..tostring(data.skillName or '无技能')
    elseif self.type==4 then detail='数量 '..tostring(data.num or 0)..' · 点击查看详情'
    else detail=(data.costType=='1' and '金币 'or'钻石 ')..tostring(data.costs or 0)..' · '..(self.type==2 and '招募一位'or'每次购买')end
    local sub=E.text(cell,detail,19,W.colors.muted,74,24);W.fit(sub,size.width-86)
    E.rule(cell,0,1,size.width)
end
function EventDetailsLayer:reloadDetails()
    if not self.coherentEventPage then self.tableview:reloadData();return end
    local selected=self.eventSelectedData;local index=self.eventSelectedIndex or 1
    if selected then for i,data in ipairs(self.data or {})do if data==selected then index=i;break end end end
    self.eventSelectedIndex=math.max(1,math.min(index,#(self.data or {})))
    self.eventSelectedData=self.data and self.data[self.eventSelectedIndex]
    require('LuaClass/WarmShortageOwnership').retire(self)
    self.eventGeneration=self.eventGeneration+1
    -- Native TableView packs a short container from y=0. Its view must shrink
    -- with the rows, otherwise the first row sits below a large blank band.
    -- Keep a long list's distance from its top across stock/record changes.
    local old=self.eventListLoaded and self.tableview:getContentOffset()
    local fromTop=old and math.max(0,old.y-(self.eventListMinimum or 0))or 0
    local count=#(self.data or {});local width=self.eventSize.width-48
    self.eventListHeight=math.min(self.eventListMaxHeight,count*80)
    local bottom=self.eventListTop-self.eventListHeight
    self.tableview:setViewSize(cc.size(width,self.eventListHeight))
    self.tableview:setPosition(cc.p(24,bottom));self.tableview:setVisible(count>0)
    self.eventListDivider:setPositionY(bottom-12)
    self.eventDetailScroll:setViewSize(cc.size(width,bottom-30-118))
    self.tableview:reloadData();self.eventListLoaded=true
    local minimum=math.min(0,self.eventListHeight-count*80)
    self.eventListMinimum=minimum
    self.tableview:setContentOffset(cc.p(0,math.min(0,minimum+fromTop)))
    self:refreshCoherentSelection()
    if self.listCaption then self.listCaption:setString('共 '..tostring(#(self.data or {}))..' 项 · 选择查看')end
end
function EventDetailsLayer:isCurrentEventData(data,index)
    return EventPageUI.alive(self) and self.data and self.data[index]==data
end
function EventDetailsLayer:coherentDetailText(data)
    if self.type==4 or self.type==3 then
        local resource=dataController.getResourceInfoById(data.id)
        if resource then return tostring(dataController.getResourceValueByIdAndKey(data.id,'desc')or'')end
    end
    local soldier=dataController.getSoilderInfoById(data.id)
    if self.type==1 then soldier=soldier or data end
    if not soldier then return '船员详情暂不可用'end
    local skillName,skillInfo=CrewSkillDetails.describe(soldier.skill,DataManager:getInstance():getCSVByID(csvOfSkillAttribute),DataManager:getInstance():getCSVByID(csvOfBuff))
    return string.format('生命 %s · 威力 %s · 速度 %s\n星级 %s\n技能：%s\n技能效果：%s',tostring(data.hp or soldier.hp or 0),tostring(data.power or data.attack or soldier.attack or 0),tostring(data.speed or soldier.speed or 0),tostring(data.star or soldier.star or 0),skillName,skillInfo)
end
function EventDetailsLayer:coherentLimitText(data)
    local limit=tonumber(dataController.getResourceValueByIdAndKey(data.id,'limits'))or 0
    if limit==0 or limit==-1 then return nil end
    local restrictions=DataManager:getInstance():getRoleData(roleBlackMarketRestrictions)or{}
    local id=tostring(data.id);local remaining
    if limit>0 then remaining=restrictions[id]or limit
    else remaining=(restrictions.tempRestrictions or {})[id]or (limit==-2 and 1 or -limit)end
    return '剩余可购 '..tostring(remaining)..' 次'
end
function EventDetailsLayer:refreshCoherentSelection()
    local E=EventPageUI;local W=E.theme();local w=self.eventSize.width;local content=self.eventDetailScroll:getContainer()
    content:removeAllChildren();self.eventActionDock:removeAllChildren();self.eventPrimary=nil;self.eventSecondary=nil
    local data=self.eventSelectedData;local index=self.eventSelectedIndex;local nodes={}
    local function text(value,size,color)
        local n=E.text(content,value,size,color or W.colors.ink,0,0,w-48);nodes[#nodes+1]=n;return n
    end
    if not data then
        local empty={'没有等待复活的船员','这里暂时没有可招募的船员','本轮货物已售完','货舱里还没有货物'}
        text(empty[self.type]or'暂无内容',25);text('可以返回继续探索。',22,W.colors.muted)
        E.flow(self.eventDetailScroll,nodes,18);return
    end
    text(data.name or '未知',29)
    if self.type==1 then
        local cost=data.cost or {};text('复活一位需要 '..tostring(cost.name or '未知材料')..' × '..tostring(cost.costNum or 0),22,W.colors.sea)
        text('记录数量 '..tostring(data.num or 1)..' · 埋葬一位可获得尸尘 × 1',20,W.colors.muted)
    elseif self.type==2 or self.type==3 then
        text((data.costType=='1' and '金币 'or'钻石 ')..tostring(data.costs or 0)..(self.type==3 and (' / '..tostring(data.num or 1)..' 件')or' / 一位船员'),24,W.colors.sea)
        if self.type==3 then local limit=self:coherentLimitText(data);if limit then text(limit,20,W.colors.muted)end end
    else text('数量 '..tostring(data.num or 0),23,W.colors.sea)end
    text(self:coherentDetailText(data),22,W.colors.muted)
    E.flow(self.eventDetailScroll,nodes,16)
    if self.type==4 then return end
    local generation=self.eventGeneration
    local function action(fn)
        return function()
            if generation~=self.eventGeneration or not self:isCurrentEventData(data,index) or E.blocked(self)then return end
            fn(self,data,index)
        end
    end
    local label=self.type==1 and '复活一位'or(self.type==2 and '招募一位'or'购买')
    local callback=self.type==1 and self.reliveCallBack or(self.type==2 and self.buyHeroCallBack or self.buyItemCallBack)
    local width=self.type==1 and w-174 or w-48
    self.eventPrimary=W.button(label,width,60,action(callback),{primary=true,size=24})
    self.eventPrimary:setPosition(cc.p(24+width/2,57));self.eventActionDock:addChild(self.eventPrimary)
    if self.type==1 then
        self.eventSecondary=W.button('埋葬',110,60,action(self.buryCallBack),{size=23})
        self.eventSecondary:setPosition(cc.p(w-79,57));self.eventActionDock:addChild(self.eventSecondary)
    end
end
function EventDetailsLayer:confirmCoherentEventAction(data,index,title,description,commit)
    local generation=self.eventGeneration
    return require('LuaClass/WarmDialog').show(title,description,{
        {label='确定',action=function()
            if generation~=self.eventGeneration or not self:isCurrentEventData(data,index)then return end
            commit()
        end},
        {label='取消'}
    },self)
end
