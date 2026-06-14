require "AudioEngine"
require "LuaClass/Header"
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
    local pBacksp = cc.Scale9Sprite:create("Images/UI/dibantiao_03.png", cc.rect(0, 0, bgSize.width, bgSize.height), cc.rect(17, 17, 30, 30))
    --pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = -ccSize.width*0.5 + 25
    -- 添加CellIcon按钮
    local pIcon = nil
    local pPath = data.icon or "j_5.png"
    pIcon = cc.MenuItemImage:create("Images/Icon/"..pPath, "Images/Icon/"..pPath)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5, 0))
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = pPosX1 + 185
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, BoldFont, fontSize+3);
    pName:setPosition(cc.p(pPosX1, pName:getContentSize().height*0.5 + 15))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, BoldFont, fontSize);
    pSkill:setPosition(cc.p(pPosX1, -5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.power or data.attack or "无")
    local pPower = cc.LabelTTF:create(power, BoldFont, fontSize);
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
    local plife = cc.LabelTTF:create(life, BoldFont, fontSize);
    plife:setPosition(cc.p(pPosX2, -5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 速度
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, BoldFont, fontSize);
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
    self:resetTitle()
    self:resetTableView()
    self.tableview:reloadData()
    return true;
end

function EventDetailsLayer:resetTitle()

    self.buttonClicked = false

    -- 默认是显示黑市
    local spPath = nil
    if self.type == 1 then
        self.titleLabel:setString("墓 地")
        spPath = "Images/UI/topTitle_mudi.png"
    elseif self.type == 2 then
        self.titleLabel:setString("酒 馆")
        spPath = "Images/UI/topTitle_jiuguan.png"
    elseif self.type == 3 then
        self.titleLabel:setString("黑 市")
        spPath = "Images/UI/topTitle_heishi.png"
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

        self.timeTip = cc.LabelTTF:create(timeTip, BoldFont, 30)
        self.timeTip:setPosition(cc.p(screenSize.width / 2, 160))
        self:addChild(self.timeTip)

    elseif self.type == 4 then
        self.titleLabel:setString("货 舱")
    end
    if spPath ~= nil then
        self.titleLabel:setVisible(false)
        local pTitle = cc.Sprite:create(spPath)
        pTitle:setPosition(self.titleLabel:getPosition())
        self:addChild(pTitle)
    end
end

function EventDetailsLayer:resetTableView()
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
                self.tableview:reloadData()
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
    if data == nil then return end
    
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, bgSize.width, bgSize.height), cc.rect(17, 17, 30, 30))
    pBacksp:setPreferredSize(cc.size(590, ccSize.height-10))
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = nil
    local pPath = data.icon or "j_5.png"
    pIcon = cc.MenuItemImage:create("Images/Icon/"..pPath, "Images/Icon/"..pPath)
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
        local  fNum = cc.LabelTTF:create(data.num, BoldFont, fontSize);
        fNum:setColor(BaseColor)
        fNum:setPosition(pNums:getPosition())
        -- fNum:enableStroke(cc.c4b(215, 199, 165, 255), 1)
        cell:addChild(fNum)
    end
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, BoldFont, fontSize+3);
    pName:setPosition(cc.p(pPosX1, ccSize.height*0.5 + pName:getContentSize().height*0.5 + 20))
    pName:setColor(BaseColor)
    -- pName:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pName:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pName)
    
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, BoldFont, fontSize);
    pSkill:setPosition(cc.p(pPosX1, ccSize.height*0.5 - 5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.attack or 0)
    local pPower = cc.LabelTTF:create(power, BoldFont, fontSize);
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
    local plife = cc.LabelTTF:create(life, BoldFont, fontSize);
    plife:setPosition(cc.p(pPosX2, ccSize.height*0.5 - 5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 威力
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, BoldFont, fontSize);
    pSpeed:setPosition(cc.p(pPosX2, ccSize.height*0.5 - pSpeed:getContentSize().height*0.5 - 20))
    pSpeed:setColor(WriteColor)
    -- pSpeed:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSpeed:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSpeed)
    
    -- 复活/埋葬 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnAlive = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnAlive:setPosition(cc.p(rightPosx-btnAlive:getContentSize().width*0.5, ccSize.height*0.7))
    local alive = cc.LabelTTF:create("复 活", BoldFont, 28.0)
    alive:setPosition(cc.p(btnAlive:getContentSize().width*0.5, btnAlive:getContentSize().height*0.5))
    -- alive:enableStroke(cc.c4b(255, 255, 255, 255), 2)
    btnAlive:addChild(alive)
    
    local btnBury = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnBury:setPosition(cc.p(rightPosx-btnBury:getContentSize().width*0.5, ccSize.height*0.3))
    local bury = cc.LabelTTF:create("埋 葬", BoldFont, 28.0)
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
    local fontSize = 25
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, bgSize.width, bgSize.height), cc.rect(17, 17, 30, 30))
    pBacksp:setPreferredSize(cc.size(590, ccSize.height-10))
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = nil
    local pPath = data.icon or "d_1.png"
    pIcon = cc.MenuItemImage:create("Images/Icon/"..pPath, "Images/Icon/"..pPath)
    pIcon:setPosition(cc.p(emptyDis+pIcon:getContentSize().width*0.5+20, ccSize.height*0.5))
    pIcon:registerScriptTapHandler(function() cclog("click on cell Icon") end)
    
    local pIconButton = cc.Menu:create(pIcon)
    pIconButton:setPosition(0, 0)
    cell:addChild(pIconButton)
    
    local pPosX1 = pIcon:getPositionX() + pIcon:getContentSize().width*0.5 + 20
    local pPosX2 = pPosX1 + 172 --visibleSize.width*0.5 - 18
    -- 名字
    local name = data.name or "无"
    local pName = cc.LabelTTF:create(name, BoldFont, fontSize+3);
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
    local pCost = cc.LabelTTF:create(cost, BoldFont, fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(WriteColor)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
    
    --[[
    -- 技能
    local skill = "技能：" .. (data.skillName or "无")
    local pSkill = cc.LabelTTF:create(skill, BoldFont, fontSize);
    pSkill:setPosition(cc.p(pPosX1, ccSize.height*0.5 - 5))
    pSkill:setColor(WriteColor)
    -- pSkill:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSkill:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSkill)
    
    -- 威力
    local power = "威力：" .. (data.power or "无")
    local pPower = cc.LabelTTF:create(power, BoldFont, fontSize);
    pPower:setPosition(cc.p(pPosX1, ccSize.height*0.5 - pPower:getContentSize().height*0.5 - 20))
    pPower:setColor(WriteColor)
    -- pPower:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pPower:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pPower)
    
    -- 生命
    local life = "生命：" .. (data.hp or 0)
    local plife = cc.LabelTTF:create(life, BoldFont, fontSize);
    plife:setPosition(cc.p(pPosX2, ccSize.height*0.5 - 5))
    plife:setColor(WriteColor)
    -- plife:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    plife:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(plife)
    
    -- 速度
    local speed = "速度：" .. (data.speed or 0)
    local pSpeed = cc.LabelTTF:create(speed, BoldFont, fontSize);
    pSpeed:setPosition(cc.p(pPosX2, ccSize.height*0.5 - pSpeed:getContentSize().height*0.5 - 20))
    pSpeed:setColor(WriteColor)
    -- pSpeed:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pSpeed:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pSpeed)
    ]]--
    
    -- 购买 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnBuy = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnBuy:setPosition(cc.p(rightPosx-btnBuy:getContentSize().width*0.5, ccSize.height*0.5))
    local buy = cc.LabelTTF:create("购 买", BoldFont, 28.0)
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
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, bgSize.width, bgSize.height), cc.rect(17, 17, 30, 30))
    pBacksp:setPreferredSize(cc.size(590, ccSize.height-10))
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = nil
    local pPath = data.icon or "d_1.png"
    pIcon = cc.MenuItemImage:create("Images/Icon/"..pPath, "Images/Icon/"..pPath)
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
    local pName = cc.LabelTTF:create(name, BoldFont, fontSize+3);
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
    local pCost = cc.LabelTTF:create(cost, BoldFont, fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(WriteColor)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
    
    -- 购买 按钮
    local rightPosx = ccSize.width - emptyDis - 15
    local btnBuy = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    btnBuy:setPosition(cc.p(rightPosx-btnBuy:getContentSize().width*0.5, ccSize.height*0.5))
    local buy = cc.LabelTTF:create("购 买", BoldFont, 28.0)
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
    local fontSize = 22
    -- 添加Cell背景图片
    local temp = cc.Sprite:create("Images/UI/dibantiao_02.png")
    local bgSize = temp:getContentSize()
    local pBacksp = cc.Scale9Sprite:create("Images/UI/dibantiao_02.png", cc.rect(0, 0, bgSize.width, bgSize.height), cc.rect(17, 17, 30, 30))
    pBacksp:setPreferredSize(cc.size(590, ccSize.height-10))
    pBacksp:setPosition(cc.p(ccSize.width*0.5, ccSize.height*0.5))
    cell:addChild(pBacksp)
    
    local emptyDis = (ccSize.width-590) * 0.5
    -- 添加CellIcon按钮
    local pIcon = nil
    if data.icon ~= nil and string.find(data.icon, "png") ~= nil then
        pIcon = cc.MenuItemImage:create("Images/Icon/".. data.icon, "Images/Icon/".. data.icon)
    else
        pIcon = cc.MenuItemImage:create("Images/Icon/d_1.png", "Images/Icon/d_1.png")
        --pIcon:setVisible(false)
    end
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
    local pName = cc.LabelTTF:create(name, BoldFont, fontSize+3);
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
    local cost = "数量：" .. (data.num or 0)
    local pCost = cc.LabelTTF:create(cost, BoldFont, fontSize);
    pCost:setPosition(cc.p(pPosX1, ccSize.height*0.27))
    pCost:setColor(WriteColor)
    -- pCost:enableStroke(cc.c4b(255, 255, 255, 255), 1)
    pCost:setAnchorPoint(cc.p(0, 0.5))
    cell:addChild(pCost)
end

--- 墓地复活接口 ---
function EventDetailsLayer:reliveCallBack(data, index)
    printn(data)
    local _layer = AlertView:create(2,0, "复 活", function()
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

            self.tableview:reloadData()
        else -- 
            showPopTips("缺少材料，复活失败！")
        end
    end,nil)
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
    
    
    -- cost describe
    local cost = data.cost
    local desc = "花费" .. (cost.costNum or 0) .. (cost.name or "无") .. "复活一个" .. (data.name or "无") .. "?"
    local descLabel = cc.LabelTTF:create(desc, BoldFont, 28.0)
    descLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 105))
    -- descLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    descLabel:setColor(WriteColor)
    _layer:addChild(descLabel)
end

--- 墓地埋葬接口 ---
function EventDetailsLayer:buryCallBack(data, index)
    printn(data)
    local _layer = AlertView:create(2,0, "埋 葬", function()
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

        self.tableview:reloadData()
    end,nil)
    
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
                                    
                                    
    -- get describe
    local desc = "你确定要埋葬" .. (data.name or "无") .. "吗?"
    local descLabel = cc.LabelTTF:create(desc, BoldFont, 28)
    descLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 115))
    -- descLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    descLabel:setColor(WriteColor)
    _layer:addChild(descLabel)
    
    local gets = "(可获得尸尘x" .. 1 .. ")"
    local getsLabel = cc.LabelTTF:create(gets, BoldFont, 22)
    getsLabel:setPosition(cc.p(cellItem:getPositionX(), cellItem:getPositionY() + 80))
    -- getsLabel:enableStroke(cc.c4b(153, 156, 156, 255), 1)
    getsLabel:setColor(WriteColor)
    _layer:addChild(getsLabel)
end

--- 酒馆购买接口 ---
function EventDetailsLayer:buyHeroCallBack(data, index)
    printn(data)
    self.buttonClicked = true
    local _layer = AlertView:create(2, 0, "购 买", function()
        local cost = data.costs or 0
        local result = nil
        if data.costType == "1" then
            result = DataManager:getInstance():addCoin(-cost,true)
        else
            result = DataManager:getInstance():addDiamond(-cost,true)
        end
    
        if result == 1 then  -- 购买成功
            showPopTips("购买成功！")
            DataManager:getInstance():addSoilderWithId(data.id, 1)
            -- self.data[index] = nil --暂时屏蔽所有酒馆购买消失的事件
            self.tableview:reloadData()
        else -- 购买失败
            showPopTips("金币不足！")
        end
    end,nil)
    
    local cellItem = getStandardCellItem(data)
    local itemSize = cellItem:getContentSize()
    cellItem:setPosition(_layer.s_position)
    _layer:addChild(cellItem)
    
    -- desc1
    local posY = cellItem:getPositionY() + 105
    local posX = _layer.s_position.x - 125
    local costTip1 = cc.LabelTTF:create("花费", BoldFont, 28.0)
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
    local costTip3 = cc.LabelTTF:create(desc, BoldFont, 28.0)
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
        result = DataManager:getInstance():addDiamond(-cost,true)
    end

    if result == 1 then  -- 购买成功
        showPopTips("购买成功！")
        ExploreBagController:getBagController():addItemToBattlePack(data.id, data.num,true)
        --self.data[index] = nil
        self:trySaveLimitedData(data.id,index)
        self.tableview:reloadData()
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
            local skillName = dataController.getSkillValueByIdAndKey(soilderInfos["skill"], "name")
            local buffCsv = DataManager:getInstance():getCSVByID(csvOfBuff)
            local skillInfo = "无"
            if soilderInfos["skill"] ~= nil and soilderInfos["skill"] ~= "0" then
                skillInfo = buffCsv[soilderInfos["skill"]]["description"]
            end
            infos = string.format("%s\n技能: %s\n技能效果:%s\n 生命: %d 威力: %d 速度: %0.1f",infos,skillName,skillInfo,soilderInfos["hp"],soilderInfos["attack"],soilderInfos["speed"])
        end
        
    --酒馆
    elseif self.type == 2 then
        local soilderInfos = dataController.getSoilderInfoById(data.id)
        local buffCsv = DataManager:getInstance():getCSVByID(csvOfBuff)
        local skillInfo = "无"
        if soilderInfos["skill"] ~= nil and soilderInfos["skill"] ~= "0" then
            skillInfo = buffCsv[soilderInfos["skill"]]["description"]
        end
        infos = string.format("%s\n技能: %s\n技能效果:%s\n 生命: %d 威力: %d 速度: %0.1f",infos,data.skillName,skillInfo,soilderInfos["hp"],soilderInfos["attack"],soilderInfos["speed"])
    end
    print("infos",infos)
    self.willCloseInfos = false
    self.infoNode:setVisible(true)
    self.infoLabel:setString(infos)
    print("infos",self.infoLabel:getString())
end

function EventDetailsLayer:close(  )
    
    print("EventDetailsLayer:close")

    if self.leaveCalBack ~= nil then
        self.leaveCalBack()
    end

    self:removeFromParent(true)
end

-------------------------------EventDetailsLayer-----------------------------------