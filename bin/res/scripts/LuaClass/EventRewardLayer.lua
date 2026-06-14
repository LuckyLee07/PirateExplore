require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/DataManager"


-- FightRewardScene
EventRewardLayer = class("EventRewardLayer", function ()
    return cc.Scene:create()
end)
EventRewardLayer.__index = EventRewardLayer

-- data
-- 背包内物品
EventRewardLayer.packageItems = {}
-- 奖励物品列表
EventRewardLayer.rewardItems = {}
-- 背包占用量
EventRewardLayer.packageSize = 0
-- 背包容量
EventRewardLayer.packageCapicity = 800
-- 战斗结果
EventRewardLayer.fightResult = false

-- ui
EventRewardLayer.tableview1 = nil
EventRewardLayer.tableview2 = nil

-- pickUpCallback
EventRewardLayer.pickUpCallback = nil

function EventRewardLayer:create( data )
    local view = EventRewardLayer.new()
    if view and view:init(data) then
        return view
    end
    return nil
end

function EventRewardLayer:init( data )
    self:initData(data)

    self.packageCapicity = ExploreBagController:getBagController().limited

    print("self.packageCapicity",self.packageCapicity)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 添加总背景
    local mainBg = cc.Sprite:create("Images/Background/MainBackGround.png")
    mainBg:setAnchorPoint(cc.p(0, 0))
    mainBg:setPosition(cc.p(0, 0))
    self:addChild(mainBg)

    -- 添加底部背景图
    local topBg = cc.Sprite:create("Images/UI/TitleBg.png")
    topBg:setPosition(0.5*visibleSize.width, visibleSize.height)
    topBg:setAnchorPoint(0.5, 1.0)
    self:addChild(topBg)

    -- 上方装饰条
    local leftDector = cc.Sprite:create("Images/UI/TopDecor.png")
    leftDector:setPosition(cc.p(0.5*visibleSize.width-85.0, visibleSize.height-33.0))
    leftDector:setAnchorPoint(1.0, 0.5)
    self:addChild(leftDector)
    local rightDector = cc.Sprite:create("Images/UI/TopDecor.png")
    rightDector:setPosition(cc.p(0.5*visibleSize.width+85.0, visibleSize.height-33.0))
    rightDector:setAnchorPoint(0.0, 0.5)
    rightDector:setFlippedX(true)
    self:addChild(rightDector)

    -- 中间装饰条
    local midDector = cc.Sprite:create("Images/Fight/shutiao03.png")
    midDector:setPosition(cc.p(0.5*visibleSize.width, 0.5*visibleSize.height))
    self:addChild(midDector)

    -- 添加底部背景图
    local bottomBg = cc.Sprite:create("Images/UI/BottomBg.png")
    bottomBg:setPosition(0.5*visibleSize.width, 0.0)
    bottomBg:setAnchorPoint(0.5, 0.0)
    self:addChild(bottomBg)

    -- title
    local title = cc.Sprite:create("Images/Fight/zhanlip.png")
    title:setPosition(cc.p(0.5*visibleSize.width, visibleSize.height-33.0))
    self:addChild(title)

    -- biaoti
--    local biaoti1 = cc.Sprite:create("Images/UI/BottomBtn1_a.png")
--    biaoti1:setPosition(1/4*visibleSize.width, visibleSize.height-110.0)
--    self:addChild(biaoti1)
--    local biaoti2 = cc.Sprite:create("Images/UI/BottomBtn2_a.png")
--    biaoti2:setPosition(3/4*visibleSize.width, visibleSize.height-110.0)
--    self:addChild(biaoti2)
    local beibao = cc.LabelTTF:create("货 舱", BoldFont, 35.0)
    beibao:setColor(BaseColor)
    beibao:setPosition(1/4*visibleSize.width, visibleSize.height-110.0)
    self:addChild(beibao)
    local diaoluo = cc.LabelTTF:create("掉 落", BoldFont, 35.0)
    diaoluo:setColor(BaseColor)
    diaoluo:setPosition(3/4*visibleSize.width, visibleSize.height-110.0)
    self:addChild(diaoluo)

    -- capacity
    local capacity = cc.LabelTTF:create("("..tostring(self.packageSize).."/"..tostring(self.packageCapicity)..")", BoldFont, 30.0)
    capacity:setAnchorPoint(cc.p(0.0, 0.5))
    capacity:setPosition(beibao:getPositionX()+0.5*beibao:getContentSize().width+3.0, visibleSize.height-110.0)
    self:addChild(capacity)


    -- tableview1
    self.tableview1 = cc.TableView:create(cc.size(250.0, visibleSize.height-300.0))
    self.tableview1:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview1:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview1:setPosition(50.0, 150.0)
    self.tableview1:setDelegate()
    self:addChild(self.tableview1)
    self.tableview1:registerScriptHandler(function(view, cell)
        local idx = cell:getTag()
        local item = self.packageItems[idx]
        self.packageSize = self.packageSize - item.space
        print("tableview1:registerScriptHandler")
        self:changeRewardItemNum(self.packageItems, item, -1)
        self:changeRewardItemNum(self.rewardItems, item, 1)
        self.tableview1:reloadData()
        self.tableview2:reloadData()
    end, cc.TABLECELL_TOUCHED)
    self.tableview1:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        local item = self.packageItems[idx]
        local cell = view:dequeueCell()
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()
        printn("cell1",item)
        -- background
        local bg = cc.Scale9Sprite:create("Images/UI/MaskBg_1.png")
        bg:setPreferredSize(cc.size(250, 100.0))
        bg:setPosition(125.0, 60.0)
        cell:addChild(bg)

        -- icon
        local icon = cc.Sprite:create("Images/Icon/"..item.icon)
        icon:setPosition(50.0, 60.0)
        cell:addChild(icon)

        -- labe
        local label = cc.LabelTTF:create(item.name, BoldFont, 30.0)
        label:setColor(BaseColor)
        label:setPosition(100.0, 75.0)
        label:setAnchorPoint(cc.p(0.0, 0.5))
        cell:addChild(label)

        -- num
        local num = cc.LabelTTF:create("数量".."  +"..tostring(item.num), BoldFont, 30.0)
        num:setPosition(100.0, 40.0)
        num:setAnchorPoint(cc.p(0.0, 0.5))
        cell:addChild(num)

        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)
    self.tableview1:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        return 120, 250.0 -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableview1:registerScriptHandler(function(view)
        return #self.packageItems
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableview1:reloadData()

    -- tableview2
    self.tableview2 = cc.TableView:create(cc.size(250.0, visibleSize.height-300.0))
    self.tableview2:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview2:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview2:setPosition(visibleSize.width-50.0-250.0, 150.0)
    self.tableview2:setDelegate()
    self:addChild(self.tableview2)
    self.tableview2:registerScriptHandler(function(view, cell)
        local idx = cell:getTag()
        local item = self.rewardItems[idx]

        if self.packageSize + item.space > self.packageCapicity then
            return
        end

        self.packageSize = self.packageSize + item.space
        print("self.tableview2:registerScriptHandler")
        self:changeRewardItemNum(self.packageItems, item, 1)
        self:changeRewardItemNum(self.rewardItems, item, -1)
        self.tableview1:reloadData()
        self.tableview2:reloadData()
    end, cc.TABLECELL_TOUCHED)
    self.tableview2:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        local item = self.rewardItems[idx]
        local cell = view:dequeueCell()
         printn("cell2",item)
        if not cell then
            cell = cc.TableViewCell:create()
        end
        cell:setTag(idx)
        cell:removeAllChildren()

        -- background
        local bg = cc.Scale9Sprite:create("Images/UI/MaskBg_1.png")
        bg:setPreferredSize(cc.size(250, 100.0))
        bg:setPosition(125.0, 60.0)
        cell:addChild(bg)

        -- icon
        local icon = cc.Sprite:create("Images/Icon/"..item.icon)
        icon:setPosition(50.0, 60.0)
        cell:addChild(icon)

        -- labe
        local label = cc.LabelTTF:create(item.name, BoldFont, 30.0)
        label:setColor(BaseColor)
        label:setPosition(100.0, 75.0)
        label:setAnchorPoint(cc.p(0.0, 0.5))
        cell:addChild(label)

        -- num
        local num = cc.LabelTTF:create("数量".."  +"..tostring(item.num), BoldFont, 30.0)
        num:setPosition(100.0, 40.0)
        num:setAnchorPoint(cc.p(0.0, 0.5))
        cell:addChild(num)

        return cell
    end, cc.TABLECELL_SIZE_AT_INDEX)
    self.tableview2:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        return 120, 250.0 -- 这里有个问题，引擎manual tolua之后，现在width和height顺序是反的
    end, cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableview2:registerScriptHandler(function(view)
        return #self.rewardItems
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.tableview2:reloadData()


    -- closeBtn
    local closeBtn = SDButton:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png", function()
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        self:saveBattlePack()
        if self.pickUpCallback then
            self.pickUpCallback()
        end
        self:removeFromParent(true)
    end)
    
    -- closeBtn:registerScriptTapHandler(function()
    --     --存储数据
    --     self:saveBattlePack()
    --     if self.pickUpCallback then
    --         self.pickUpCallback()
    --     end
    --     self:removeFromParent(true)
    -- end)
    closeBtn:setPosition(1/3*visibleSize.width-40.0, 60.0)
    self:addChild(closeBtn)

    -- shiquBtn
    local shiquBtn = SDButton:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png", function()
            if DataManager:getInstance():getSound_off() == 0 then
                AudioEngine.playEffect(EFFECT_Button, false)
            end
            self:pickUpAllRewards()
    end)
    -- shiquBtn:registerScriptTapHandler(function()
    --     self:pickUpAllRewards()
    -- end)
    shiquBtn:setPosition(2/3*visibleSize.width+40.0, 60.0)
    self:addChild(shiquBtn)

    -- local menu1 = SNSButton:create(closeBtn)
    -- menu1:setPosition(cc.p(0, 0))
    -- self:addChild(menu1)
    -- local menu2 = SNSButton:create(shiquBtn)
    -- menu2:setPosition(cc.p(0, 0))
    -- self:addChild(menu2)

    local close = cc.LabelTTF:create("关闭", BoldFont, 30.0)
    close:setPosition(closeBtn:getPosition())
    self:addChild(close,1)
    local shiqu = cc.LabelTTF:create("全部拾取", BoldFont, 30.0)
    shiqu:setPosition(shiquBtn:getPosition())
    self:addChild(shiqu,1)

    local function update()
        capacity:setString("("..tostring(self.packageSize).."/"..tostring(self.packageCapicity)..")")
    end
    self:scheduleUpdateWithPriorityLua(update, 0)

    return true
end

-- initData
function EventRewardLayer:initData( data )
    self.packageItems = data.have
    self.rewardItems = data.drop

    --获取背包大小
    for i=1,#self.packageItems do
        local item = self.packageItems[i]
        self.packageSize = self.packageSize + item.space * item.num
    end

    self.fightResult = false
end

--存储确认后的
function EventRewardLayer:saveBattlePack( )

    printn("EventRewardLayer:saveBattlePack",self.packageItems)

    DataManager:getInstance():setRoleData(roleBattlePack,self.packageItems,nil)

end

-- setpickUpCallback
function EventRewardLayer:setPickUpCallback(callback)
    assert(type(callback) == "function")
    self.pickUpCallback = callback
end

-- pickUpAllRewards
function EventRewardLayer:pickUpAllRewards()
    print("pickUpAllRewards")
    local pick = function()
        -- 有容量并且有可拾取物品
        if self.packageSize < self.packageCapicity then
            if 0 >= #self.rewardItems then
                return false
            end
            -- 当前类物品数量
            local num = self.rewardItems[1].num 
            -- 剩余容量
            local capLeft = self.packageCapicity - self.packageSize
            -- 可全装下
            if num < capLeft then
                local item = self.rewardItems[1]
                self.packageSize = self.packageSize + item.space * item.num
                self:changeRewardItemNum(self.packageItems, item, item.num)
                self:changeRewardItemNum(self.rewardItems, item, -item.num)
                self.tableview1:reloadData()
                self.tableview2:reloadData()
                return true
            else -- 只能装一部分
                local item = self.rewardItems[1]
                --向上取整
                local getNum = math.floor(capLeft / item.space)
                self.packageSize = self.packageSize + item.space * getNum
                self:changeRewardItemNum(self.packageItems, item, getNum)
                self:changeRewardItemNum(self.rewardItems, item, -getNum)
                self.tableview1:reloadData()
                self.tableview2:reloadData()
                ToastUtil:toastString("您货舱已满，无法拾取更多物品")
                return false
            end
        else
            ToastUtil:toastString("您货舱已满，无法拾取更多物品")
            return false
        end
    end

    if 0 < #self.rewardItems then
        while(true)
        do
            if not pick() then
                return
            end
        end
    else
        ToastUtil:toastString("没有可拾取的物品")
    end
end

-- changeRewardItemNum
function EventRewardLayer:changeRewardItemNum(tb, itemInfo, num)
    local id = itemInfo.id
    local name = itemInfo.name
    local space = itemInfo.space 
    local item,idx
    for i=1, #tb do
        local tmp = tb[i]
        if tmp.id == id then
            item = tmp
            idx =i
            break
        end
    end

    print("changeRewardItemNum",id,num,item,idx)

    if item then
        item.num = item.num+num
        if item.num <= 0 then
            table.remove(tb, idx)
        end
    else
        if num > 0 then
            item = {}
            item.id = id
            item.num = num
            item.name = name
            item.space = itemInfo.space
            item.icon = itemInfo.icon
            tb[#tb + 1] = item
        end
    end
end