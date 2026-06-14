--
-- Created by IntelliJ IDEA.
-- User: sunxy
-- Date: 15/1/9
-- Time: 下午2:50
-- To change this template use File | Settings | File Templates.
--

require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/UIKit"
require "LuaClass/DialogueView"
require "LuaClass/ToastUtil"
require "LuaClass/Utils"
require "LuaClass/FightDataManager"
require "LuaClass/DataManager"
require "LuaClass/EffectUtil"
require "LuaClass/DiamondStore"


-- FightDataManager
local fdm = FightDataManager:getInstance()

-- changeListItemNum
local changeListItemNum = function (tb, id, num)
    local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    local data = resourceCsv[tostring(id)]
    local item,idx
    for i=1, #tb do
        local tmp = tb[i]
        if tmp.id == id then
            item = tmp
            idx = i
            break
        end
    end
    if item then
        item.num = item.num+num
        if item.num <= 0 then
            table.remove(tb, idx)
        end
    else
        if num > 0 then
            local item = {}
            local idx = 1
            item.id = id
            item.num = num

            for i=1, #tb do
                local tmp = resourceCsv[tostring(tb[i].id)]
                if tonumber(data.cubage) == tonumber(tmp.cubage) then
                    idx = i
                    break
                elseif tonumber(data.cubage) > tonumber(tmp.cubage) then
                    idx = i+1
                end
            end
            table.insert(tb, idx, item)
        end
    end
end

-- changeListItemNum1
local changeListItemNum1 = function (tb, id, num)
    local item = tb[id]
    if item then
        item.num = item.num+num
        if item.num <= 0 then
            tb[id] = nil
        end
    else
        if num > 0 then
            item = {}
            item.id = id
            item.num = num
            tb[id] = item
        end
    end
end

-- Fighter
Fighter = class("Fighter", function ()
    return {}
end)
Fighter.__index = Fighter

-- 初始hp
Fighter.m_hp = 0
-- 当前hp
Fighter.hp = 0
-- 初始攻击间隔
Fighter.m_interval = 0
-- 当前攻击间隔
Fighter.interval = 0
-- 上次攻击时间
Fighter.lastAtkTime = 0
-- 初始攻击力
Fighter.m_atk = 0
-- 当前攻击力
Fighter.atk = 0
-- 初始闪避值
Fighter.m_miss = 0
-- 当前闪避值
Fighter.m_miss = 0
-- 技能id
Fighter.soilderId = 0
-- 初始技能系数
Fighter.m_skillRatio = 0
-- 当前技能系数
Fighter.skillRatio = 0
-- 伤害减少数值
Fighter.damageReduction = 0
-- bufferId
Fighter.bufferId = 1
-- 名字
Fighter.name = ""
-- 描述
Fighter.description = ""
-- 星级
Fighter.star = 0
-- 是否活着
Fighter.alive = true
-- 所属队伍标示
Fighter.teamType = 0
-- 在队伍中的id
Fighter.teamIndex = 0
-- 是否眩晕中
Fighter.isHalo = false

-- constant
Fighter.TeamType = {playerTeam = 1, enemyTeam = 2 }
Fighter.monsterNames = {"海魂诅咒者", "魑魅魍魉", "牛鬼蛇神", "加勒比海盗", "百慕大水怪"}
Fighter.fighterNames = {"水手甲", "水手已", "水手丙", "水手丁", "水手戊", "水手己", "水手更", "水手辛", "水手壬", "水手癸" }

-- init
function Fighter:init(teamType)
    self.teamType = teamType
    if self.teamType == Fighter.TeamType.playerTeam then
        self.m_hp = math.random(200, 250)
        self.m_interval = math.random(1000, 2000)/1000
        self.m_atk = math.random(15, 25)
        self.m_miss = math.random(0, 0)
        self.m_skillRatio = 1
        self.damageReduction = 0
        self.bufferId = 1
        self.star = 1
        self.soilderId = 104
        self.name = self.fighterNames[math.random(1, #self.fighterNames)]
    else
        self.m_hp = math.random(800, 1000)
        self.m_interval = math.random(1000, 2000)/1000
        self.m_atk = math.random(20, 30)
        self.m_miss = math.random(0, 0)
        self.m_skillRatio = 1
        self.damageReduction = 0
        self.bufferId = 1
        self.star = 1
        self.soilderId = 10092
        self.name = self.monsterNames[math.random(1, #self.monsterNames)]
    end
    self.description = ""
    self.isHalo = false
    self.lastAtkTime = getSystemTimeMilliSecond()
    self:reset()

end

-- reset
function Fighter:reset()
    self.hp = self.m_hp
    self.interval = self.m_interval
    self.atk = self.m_atk
    self.miss = self.m_miss
    self.skillRatio = self.m_skillRatio
    self.alive = true
end

-- 是否可以攻击
function Fighter:canAttack()
    local nowTime = getSystemTimeMilliSecond()
    if nowTime-self.lastAtkTime >= self.interval and not self.isHalo then return true end
    return false
end

-- Team
Team = class("Team", function ()
    return {}
end)
Team.__index = Team

-- 初始总hp
Team.m_hp = 0
-- 当前总hp
Team.hp = 0
-- 团队平均miss值
Team.miss = 0
-- 队伍星级
Team.star = 0
-- 队伍中成员列表
Team.fighters = nil


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

FightBoxViewAlert = class("FightBoxViewAlert", function ()
    return DialogueView:create()
end)
FightBoxViewAlert.__index = FightBoxViewAlert
FightBoxViewAlert.instance = nil
-- create
function FightBoxViewAlert:create()
    local view = FightBoxViewAlert.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- init
function FightBoxViewAlert:init()
    FightBoxViewAlert.instance = self
    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    local bg = cc.Scale9Sprite:create("Images/Fight/dikuang_07.png")
    local bgSize = cc.size(500.0, 400.0)
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPreferredSize(bgSize)
    bg:setPosition(cc.p(0.5*size.width, 0.5*size.height))
    self:addChild(bg)

    -- title
    local title = cc.LabelTTF:create("寻宝结束", BoldFont, 36.0)
    title:setPosition(0.5*size.width, 0.5*(size.height+bgSize.height)-35.0)
    self:addChild(title)

    -- info
    local info = cc.LabelTTF:create("您尚未发现全部神秘奖励\n \n是否使用7钻石继续寻宝", BoldFont, 30.0)
    info:setPosition(0.5*size.width, 0.5*size.height+30.0)
    self:addChild(info)

    -- giveUpBtn
    local giveUpBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    giveUpBtn:registerScriptTapHandler(function()
        if FightBoxView.instance then FightBoxView.instance:giveUpCallback() end
        self:close()
    end)
    giveUpBtn:setPosition(0.5*(size.width-bgSize.width)+120.0, 0.5*(size.height-bgSize.height)+90.0)

    -- continueBtn
    local continueBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    continueBtn:registerScriptTapHandler(function()
        -- to do use diamond
        if 1 == DataManager:getInstance():addDiamond(-7) then
            if FightBoxView.instance then FightBoxView.instance:useDiamondCallback() end
            self:close()
        else
            ToastUtil:downString("您的钻石不足！", true)
        end
    end)
    continueBtn:setPosition(0.5*(size.width+bgSize.width)-120.0, 0.5*(size.height-bgSize.height)+90.0)

    local menu = cc.Menu:create(continueBtn, giveUpBtn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    -- 放弃
    local giveUp = cc.LabelTTF:create("放 弃", BoldFont, 30.0)
    giveUp:setPosition(giveUpBtn:getPosition())
    self:addChild(giveUp)
    -- 继续
    local continue = cc.LabelTTF:create("继 续", BoldFont, 30.0)
    continue:setPosition(continueBtn:getPosition())
    self:addChild(continue)


    return true
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------



FightBoxView = class("FightBoxView", function ()
    return DialogueView:create()
end)
FightBoxView.__index = FightBoxView

-- constant
FightBoxView.BoxState = {close = 1, open = 2, show = 3}

-- ui
FightBoxView.boxesMenu = nil
FightBoxView.viewBg = nil
FightBoxView.instance = nil

FightBoxView.freeInfoNode = nil
FightBoxView.costInfoNode = nil

FightBoxView.showInfoNode = nil

FightBoxView.closeBtn = nil
FightBoxView.giveupBtn = nil
FightBoxView.closeLabel = nil
FightBoxView.gibeupLabel = nil

FightBoxView.diamondLabel = nil

FightBoxView.infoCost = nil


-- data
-- 开启状态table
FightBoxView.boxStates = nil
-- 获得物品table
FightBoxView.props = nil
-- 假奖品table
FightBoxView.fakeIndexes = nil
-- 当前关卡奖励相关数据table，来自csv表
FightBoxView.data = nil
-- 累计开启次数
FightBoxView.openTimeTotal = 0
-- 当前开启次数
FightBoxView.openTime = 0
-- 当前获得奖励次数
FightBoxView.rewardTime = 0
-- 是否已获得A道具
FightBoxView.isGotA = false
-- 是否已获得B道具
FightBoxView.isGotB = false
-- 是否已获得C道具
FightBoxView.isGotC = false
-- 玩家是否已选择放弃继续开启
FightBoxView.isUserGiveUp = false
-- 玩家是否开到了骷髅
FightBoxView.isFail = false
-- 开到骷髅次数
FightBoxView.failTime = 0
FightBoxView.FailDiamond = {2, 4, 8}
-- 获得奖励机率
FightBoxView.rewardRate = {80.0, 20.0, 5.0}

-- create
function FightBoxView:create()
    local view = FightBoxView.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- init
function FightBoxView:init()
    FightBoxView.instance = self
    self.boxStates = {}
    self.props = {}
    self.fakeIndexes = {}
    for i=1,6 do
        self.boxStates[i] = FightBoxView.BoxState.close
        table.insert(self.fakeIndexes, 1, i)
    end
    local csv = DataManager:getInstance():getCSVByID(csvOfFightBoxes)
    self.data = csv[tostring(fdm.mapID)]
    self.openTimeTotal = 0
    self.openTime = 0
    self.rewardTime = 0
    self.isGotA = false
    self.isGotB = false
    self.isGotC = false
    self.isUserGiveUp = false
    self.isFail = false
    self.failTime = 0
    self.rewardRate = {80.0, 20.0, 5.0}
    self:setTapEventListener(function()
        self:hideInfo()
    end)

    local size = cc.Director:getInstance():getVisibleSize()

    -- background
    self.viewBg = cc.Sprite:create("Images/Fight/dikuang_07.png")
    self.viewBg:setPosition(0.5*size.width, 0.5*size.height)
    self:addChild(self.viewBg)

    -- diamond
    local diamondBg = cc.Sprite:create("Images/Fight/diamondBg.png")
    diamondBg:setAnchorPoint(cc.p(0.0, 0.0))
    diamondBg:setPosition(0.5*(size.width-self.viewBg:getContentSize().width)+4.0, 0.5*(size.height+self.viewBg:getContentSize().height)-3.0)
    self:addChild(diamondBg)
    local diamondSp = cc.Sprite:create("Images/UI/DiamondBg.png")
    diamondSp:setPosition(30.0, 0.5*diamondBg:getContentSize().height)
    diamondSp:setScale(0.8)
    diamondBg:addChild(diamondSp)
    self.diamondLabel = cc.LabelTTF:create(tostring(DataManager:getInstance():getRoleData(roleDiamond)), BoldFont, 28.0)
    self.diamondLabel:setPosition(30.0+0.5*(diamondBg:getContentSize().width-60.0), 0.5*diamondBg:getContentSize().height)
    diamondBg:addChild(self.diamondLabel)

    -- title
    local title = cc.LabelTTF:create("发现神秘宝箱", BoldFont, 36.0)
    title:setPosition(0.5*size.width, 0.5*(size.height+self.viewBg:getContentSize().height)-35.0)
    self:addChild(title)

    -- info
    local info = cc.LabelTTF:create("尝试从六个宝箱中找到三个神秘奖励\n发现骷髅则需花费钻石继续寻找", BoldFont, 25.0)
    info:setPosition(0.5*size.width, 0.5*(size.height+self.viewBg:getContentSize().height)-120.0)
    self:addChild(info)

    self.freeInfoNode = cc.Node:create()
    self:addChild(self.freeInfoNode)

    self.costInfoNode = cc.Node:create()
    self:addChild(self.costInfoNode)

    -- infofree
    local infofree = cc.LabelTTF:create("点击免费开启宝箱", BoldFont, 25.0)
    infofree:setPosition(0.5*size.width, 0.5*(size.height-self.viewBg:getContentSize().height)+70.0)
    self.freeInfoNode:addChild(infofree)

    -- info1
    self.infoCost = cc.LabelTTF:create("花费"..tostring(FightBoxView.FailDiamond[self.failTime]).."    可再次开启宝箱", BoldFont, 25.0)
    self.infoCost:setPosition(0.5*size.width-80.0, 0.5*(size.height-self.viewBg:getContentSize().height)+70.0)
    self.costInfoNode:addChild(self.infoCost)
    local diamondSp = cc.Sprite:create("Images/UI/DiamondBg.png")
    diamondSp:setScale(0.6)
    diamondSp:setPosition(self.infoCost:getPositionX()-0.19*self.infoCost:getContentSize().width, self.infoCost:getPositionY())
    self.costInfoNode:addChild(diamondSp)

    self.showInfoNode = cc.Node:create()
    self:addChild(self.showInfoNode)
    self:hideInfo()

    local bg9Size = cc.size(self.viewBg:getContentSize().width, 80.0)
    local bg9 = cc.Scale9Sprite:create("Images/Fight/dit_03.png")
    bg9:setPreferredSize(bg9Size)
    bg9:setPosition(0.5*size.width, 0.5*(size.height-self.viewBg:getContentSize().height-bg9:getContentSize().height))
    self.showInfoNode:addChild(bg9)

    local propName = cc.LabelTTF:create("物品名称", BoldFont, 25.0)
    propName:setTag(1)
    propName:setAnchorPoint(cc.p(0.0, 0.5))
    propName:setPosition(10.0+bg9:getPositionX()-0.5*bg9Size.width, bg9:getPositionY()+0.25*bg9Size.height)
    self.showInfoNode:addChild(propName)

    local propDesc = cc.LabelTTF:create("物品详情描述", BoldFont, 25.0)
    propDesc:setTag(2)
    propDesc:setAnchorPoint(cc.p(0.0, 0.5))
    propDesc:setPosition(10.0+bg9:getPositionX()-0.5*bg9Size.width, bg9:getPositionY()-0.25*bg9Size.height)
    self.showInfoNode:addChild(propDesc)

    -- boxies
    self:reloadBoxes()

    -- closeBtn
    self.closeBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    self.closeBtn:registerScriptTapHandler(function()
        self:close()
        cc.UserDefault:getInstance():setBoolForKey("isFirtFightBox", false)
        if FightScene.instance then FightScene.instance:gotoFightRewardScene(0.5) end
    end)
    self.closeBtn:setPosition(0.5*(size.width+self.viewBg:getContentSize().width)-120.0, self.infoCost:getPositionY())

    self.giveupBtn = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    self.giveupBtn:registerScriptTapHandler(function()
        self:giveUpCallback()
    end)

    self.giveupBtn:setPosition(self.closeBtn:getPosition())

    local menu = cc.Menu:create(self.closeBtn, self.giveupBtn)
    menu:setPosition(cc.p(0, 0))
    self:addChild(menu)

    self.closeLabel = cc.LabelTTF:create("关 闭", BoldFont, 36.0)
    self.closeLabel:setPosition(self.closeBtn:getPosition())
    self:addChild(self.closeLabel)
    self.giveupLabel = cc.LabelTTF:create("放 弃", BoldFont, 36.0)
    self.giveupLabel:setPosition(self.closeBtn:getPosition())
    self:addChild(self.giveupLabel)

    self.costInfoNode:setVisible(false)
    self.closeBtn:setVisible(false)
    self.closeLabel:setVisible(false)
    self.giveupLabel:setVisible(false)
    self.giveupBtn:setVisible(false)


--    -- closeBtn
--    local closeBtn = cc.MenuItemImage:create("Images/UI/cancel_button.png", "Images/UI/cancel_button.png")
--    closeBtn:registerScriptTapHandler(function()
--        self:close()
--        if FightScene.instance then FightScene.instance:gotoFightRewardScene(0.5) end
--    end)
--
--    closeBtn:setPosition(0.5*(size.width+self.viewBg:getContentSize().width)-40.0, 0.5*(size.height+self.viewBg:getContentSize().height)-35.0)
--    local menu = cc.Menu:create(closeBtn)
--    menu:setPosition(cc.p(0, 0))
--    self:addChild(menu)

    return true
end

function FightBoxView:reloadBoxes()
    local size = cc.Director:getInstance():getVisibleSize()
    if self.boxesMenu then self:removeChild(self.boxesMenu); self.boxesMenu = nil end
    local propShowList = self.data.propShow
    local boxes = {}
    for i=1,6 do
        local state = self.boxStates[i]
        local prop = self.props[i]
        if state ~= FightBoxView.BoxState.close or self.isUserGiveUp then
            boxes[i] = cc.MenuItemImage:create("Images/Fight/baoxiang02.png", "Images/Fight/baoxiang02.png")
            boxes[i]:setEnabled(prop ~= nil)
        else
            boxes[i] = cc.MenuItemImage:create("Images/Fight/baoxiang01.png", "Images/Fight/baoxiang01.png")
        end
        local row = math.floor((6-i)/3)+1  -- 下->上 1.2
        local column = ((i-1)%3)+1   -- 左->右 1.2.3
        local posx
        if column == 1 then posx = 0.5*(size.width-self.viewBg:getContentSize().width)+110.0
        elseif column == 2 then posx = 0.5*(size.width-self.viewBg:getContentSize().width)+0.5*self.viewBg:getContentSize().width
        else posx = 0.5*(size.width-self.viewBg:getContentSize().width)+self.viewBg:getContentSize().width-110.0 end
        local posy
        if row == 1 then posy = 0.5*(size.height-self.viewBg:getContentSize().height)+200.0
        else posy = 0.5*(size.height-self.viewBg:getContentSize().height)+400.0 end
        boxes[i]:setPosition(posx, posy)
        boxes[i]:setTag(i)

        if state ~= FightBoxView.BoxState.close or self.isUserGiveUp then
            local isFake = false
            if prop ~= nil then
                local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
                local data = resource[prop[1]]
                if data.iconName and string.len(data.iconName) > 1 then
                    local bg = cc.Sprite:create("Images/Fight/k_2.png")
                    bg:setPosition(0.5*boxes[i]:getContentSize().width-10.0, 0.5*boxes[i]:getContentSize().height+30.0)
                    boxes[i]:addChild(bg)
                    local sp = cc.Sprite:create("Images/Icon/"..data.iconName)
                    sp:setPosition(0.5*boxes[i]:getContentSize().width-5.0, 0.5*boxes[i]:getContentSize().height+20.0)
                    boxes[i]:addChild(sp)
                    local numLabel = cc.LabelTTF:create(""..tostring(prop[2]), BoldFont, 18.0)
                    numLabel:setAnchorPoint(cc.p(1.0, 0.0))
                    numLabel:setPosition(sp:getPositionX()+0.5*sp:getContentSize().width-5.0, sp:getPositionY()-0.5*sp:getContentSize().height+5.0)
                    boxes[i]:addChild(numLabel)
                end
            else
                local iconGost = "k_1.png"
                if self.isUserGiveUp and state == FightBoxView.BoxState.close then
                    -- 放弃的话，全体未开启都显示为好物品(总奖品数量不超过3)
                    for j=1,#self.fakeIndexes do
                        if i == self.fakeIndexes[j] then
                            isFake = true
                            table.remove(self.fakeIndexes, j)
                            break
                        end
                    end
                    if isFake then
                        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
                        local prop = propShowList[math.random(1, #propShowList)]
                        self.props[i] = prop
                        boxes[i]:setEnabled(prop ~= nil)
                        local data = resource[prop[1]]
                        if data.iconName and string.len(data.iconName) > 1 then
                            local bg = cc.Sprite:create("Images/Fight/k_2.png")
                            bg:setPosition(0.5*boxes[i]:getContentSize().width-10.0, 0.5*boxes[i]:getContentSize().height+30.0)
                            boxes[i]:addChild(bg)
                            local sp = cc.Sprite:create("Images/Icon/"..data.iconName)
                            sp:setPosition(0.5*boxes[i]:getContentSize().width-5.0, 0.5*boxes[i]:getContentSize().height+20.0)
                            boxes[i]:addChild(sp)
                            local numLabel = cc.LabelTTF:create(""..tostring(prop[2]), BoldFont, 18.0)
                            numLabel:setAnchorPoint(cc.p(1.0, 0.0))
                            numLabel:setPosition(sp:getPositionX()+0.5*sp:getContentSize().width-5.0, sp:getPositionY()-0.5*sp:getContentSize().height+5.0)
                            boxes[i]:addChild(numLabel)
                        end
                    else
                        local sp = cc.Sprite:create("Images/Fight/"..iconGost)
                        sp:setPosition(0.5*boxes[i]:getContentSize().width, 0.5*boxes[i]:getContentSize().height)
                        boxes[i]:addChild(sp)
                    end
                else
                    local sp = cc.Sprite:create("Images/Fight/"..iconGost)
                    sp:setPosition(0.5*boxes[i]:getContentSize().width, 0.5*boxes[i]:getContentSize().height)
                    boxes[i]:addChild(sp)
                end
            end
            if not isFake and state == FightBoxView.BoxState.open then
                local spopen = cc.Sprite:create("Images/Fight/ykq_a.png")
                spopen:setPosition(0.5*boxes[i]:getContentSize().width, 0.5*boxes[i]:getContentSize().height-60.0)
                boxes[i]:addChild(spopen)
            end
        end

        boxes[i]:registerScriptTapHandler(function()
            local prop = self.props[i]
        --            if not self.isUserGiveUp then
            if prop == nil then
                if self.isFail then
                    if 1 == DataManager:getInstance():addDiamond(-FightBoxView.FailDiamond[self.failTime]) then
                        if FightBoxView.instance then FightBoxView.instance:useDiamondCallback() end
                        self:openBox(i)
                    end
                else
                    self:openBox(i)
                end
            else
                local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
                local data = resourceCsv[tostring(prop[1])]
                self:showInfo(data.name, data.desc)
            end
        --            end
        end)
    end
    self.boxesMenu = cc.Menu:create(unpack(boxes))
    self.boxesMenu:setPosition(cc.p(0, 0))
    self:addChild(self.boxesMenu)
end

function FightBoxView:showInfo(name, desc)
    if self.showInfoNode then
        self.showInfoNode:setVisible(true)
        local propName = self.showInfoNode:getChildByTag(1)
        local propDesc = self.showInfoNode:getChildByTag(2)
        if propName then
            propName:setString(tostring(name))
        end
        if propDesc then
            propDesc:setString(tostring(desc))
        end
    end
end

function FightBoxView:hideInfo()
    if self.showInfoNode then
        self.showInfoNode:setVisible(false)
    end
end

function FightBoxView:openBox(idx)
    self.openTime = self.openTime+1
    self.openTimeTotal = self.openTimeTotal+1
    self.boxStates[idx] = FightBoxView.BoxState.open
    for i=1,#self.fakeIndexes do
        local data = self.fakeIndexes[i]
        if data == idx then
            table.remove(self.fakeIndexes, i)
            break
        end
    end


    -- 计算机率
    local rand = math.random(1, 100)
    local rate = self.rewardRate[self.rewardTime+1]
    local isReward = false
    -- 玩家首次开宝箱，会连续成功3次，且第三次必开出5个钻石
    local isFirstFightBox = cc.UserDefault:getInstance():getBoolForKey("isFirtFightBox", true)
    if rate ~= nil then isReward = rate>= rand end
    -- 已经获得三个骷髅则强制必然获奖
    local isForceReward = (self.openTime-self.rewardTime) >= 3
--    cclog("isForceReward = "..tostring(isForceReward)..", isReward = "..tostring(isReward)..", rand = "..tostring(rand)..", rate = "..tostring(rate))
    -- 获奖
    if isReward or (isForceReward and self.rewardTime <= 2) or isFirstFightBox then
        self.rewardTime = self.rewardTime+1
        local propId,propNum  -- 获得奖励物品id和数量
        local propList  -- 随机奖励列表
        -- 第一个好物品和第二个好物品为B类或C类物品
        if self.rewardTime ~= 3 then
            local rand = math.random(1, 2)
            local isProbB = rand == 1
            if isProbB and not self.isGotB then
                propList = self.data.propB
                self.isGotB = true
            else
                propList = self.data.propC
                self.isGotC = true
            end
        elseif self.rewardTime == 3 then
            propList = self.data.propA
            self.isGotA = true
        end

        -- 记录获得奖励
        if propList and #propList > 0 then
            local data = propList[math.random(1, #propList)]
            -- 玩家首次开宝箱，会连续成功3次，且第三次必开出5个钻石
            if isFirstFightBox and self.rewardTime == 3 then
                data[1] = "1002"
                data[2] = 5
            end
            self.props[idx] = data
            propId = tostring(data[tonumber(1)])
            propNum = tonumber(data[tonumber(2)])
        end

        self.isFail = false
        self.freeInfoNode:setVisible(true)
        self.costInfoNode:setVisible(false)

        self.closeBtn:setVisible(false)
        self.closeLabel:setVisible(false)
        self.giveupLabel:setVisible(false)
        self.giveupBtn:setVisible(false)

        -- 如果已经获得三次奖励那么打开所有箱子
        if self.rewardTime == 3 then
            for i=1,#self.boxStates do
                if self.boxStates[i] == FightBoxView.BoxState.close then
                    self.boxStates[i] = FightBoxView.BoxState.show
                end
            end
            self.freeInfoNode:setVisible(false)
            self.closeBtn:setVisible(true)
            self.closeLabel:setVisible(true)
        end

        -- 添加奖励
        local isGold = "1001" == tostring(propId)
        local isDiamond = "1002" == tostring(propId)
        if isGold then

            ExploreBagController:getBagController():addCoin(propNum)

            -- DataManager:getInstance():addCoin(propNum, false)
            -- ToastUtil:downString("金币＋"..tostring(propNum))
        elseif isDiamond then
            DataManager:getInstance():addDiamond(propNum, false)
            self.diamondLabel:setString(tostring(DataManager:getInstance():getRoleData(roleDiamond)))
        else
            local package = DataManager:getInstance():getRoleData(roleBattlePack)
            local list = clone(package)
            changeListItemNum1(list, propId, propNum)
            DataManager:getInstance():setRoleData(roleBattlePack, list, nil)
            ToastUtil:downString("打开宝箱成功!")
        end

        local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resourceCsv[tostring(propId)]
        self:showInfo(data.name, data.desc)
    else
--        FightBoxViewAlert:create():show()
        self.isFail = true
        self.failTime = self.failTime+1
        self.infoCost:setString("花费"..tostring(FightBoxView.FailDiamond[self.failTime]).."    可再次开启宝箱")
        self.freeInfoNode:setVisible(false)
        self.costInfoNode:setVisible(true)

        self.closeBtn:setVisible(self.isUserGiveUp)
        self.closeLabel:setVisible(self.isUserGiveUp)
        self.giveupLabel:setVisible(not self.isUserGiveUp)
        self.giveupBtn:setVisible(not self.isUserGiveUp)
    end
    self:reloadBoxes()
end

function FightBoxView:giveUpCallback()
    -- 放弃
    self.isUserGiveUp = true
    local tb = clone(self.fakeIndexes)
    self.fakeIndexes = {}
    local num = 3-self.rewardTime
    for i=1,num do
        local rand = math.random(1, #tb)
        local data = tb[rand]
        table.remove(tb, rand)
        table.insert(self.fakeIndexes, 1, data)
    end
    self:reloadBoxes()

    self.closeBtn:setVisible(self.isUserGiveUp)
    self.closeLabel:setVisible(self.isUserGiveUp)
    self.giveupLabel:setVisible(not self.isUserGiveUp)
    self.giveupBtn:setVisible(not self.isUserGiveUp)
end

function FightBoxView:useDiamondCallback()
    -- 每用一次钻石，获奖概率都提升20点
    for i=1,#self.rewardRate do
        self.rewardRate[i] = self.rewardRate[i] +20
    end
    self.diamondLabel:setString(tostring(DataManager:getInstance():getRoleData(roleDiamond)))
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 战斗过渡场景，现在测试阶段使用这个来做战斗中不同场景切换的过渡
-- FightTransitionScene
FightTransitionScene = class("FightTransitionScene", function ()
    return cc.Scene:create()
end)
FightTransitionScene.__index = FightTransitionScene

-- create
function FightTransitionScene:create(info, delay, callback)
    local scene = FightTransitionScene.new()
    if scene and scene:init(info, delay, callback) then
        return scene
    end
    return nil
end
-- init
function FightTransitionScene:init(info, delay, callback)

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- background
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    self:addChild(colorLayer)

    -- info
    local infoLabel = cc.LabelTTF:create(info, BoldFont, 40.0)
    infoLabel:setPosition(0.5*visibleSize.width, 0.5*visibleSize.height)
    self:addChild(infoLabel)

    -- action
    local fadeOut = cc.FadeOut:create(delay)
    local callFunc = cc.CallFunc:create(callback)
    local action = cc.Sequence:create(fadeOut, callFunc)
    infoLabel:runAction(action)

    return true
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- FightBufferData
FightBufferData = class("FightBufferData", function ()
    return {}
end)
FightBufferData.__index = FightBufferData

-- buffer表定义的类型，每种代表一类buffer  1:灼烧 2:恢复 3:眩晕 4:减攻击力
FightBufferData.BufferType = {type1 = 1, type2 = 2, type3 = 3, type4 = 4 }
-- SettleType  结算方式类型      immediate:即时结算   realtime:实时结算  continued:持续结算
FightBufferData.SettleStype = {immediate = 1, realtime = 2, continued = 3}

--FightBufferData.index = 0
--FightBufferData.name = ""
--FightBufferData.description = ""
FightBufferData.icon = 0
--FightBufferData.star = 0
FightBufferData.type = 0
FightBufferData.settleStype = 0
FightBufferData.duration = 0
FightBufferData.attack = 0
FightBufferData.weak = 0
FightBufferData.icon = ""
-- 结算周期
FightBufferData.settleCyc = 0
-- 运行的周期
FightBufferData.runningCyc = 0
-- startTime
FightBufferData.startTime = 0
-- runningTime
FightBufferData.runningTime = 0

function FightBufferData:init()
    self.icon = 100
    self.type = FightBufferData.BufferType.type1
    self.settleStype = FightBufferData.SettleStype.continued
    self.duration = 15.0
    self.attack = 100
    self.weak = 10
    self.icon = ""
    self.settleCyc = 1.0
    self.runningCyc = 0
    self.startTime = 0
    self.runningTime = 0
end




---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- FightScene
FightScene = class("FightScene", function ()
    return cc.Scene:create()
end)
FightScene.__index = FightScene
FightScene.instance = nil
-- constant
-- 一开始做的功能是第一个figher首先被攻击，当其血量为0时死亡，死亡后不再有动作，后来需要改成只要总血量不为0，所有figher就都能进行攻击，
-- 所以在这里加了个FightMode，以防以后需求变回来，还得重修修改回原来的逻辑(如果后期确实定了就按allInOne模式做，最好删除这部分相关代码，
-- 以免把逻辑弄的过于混乱)
-- FightMode  oneByOne：一个一个死亡，死亡不做动作；allInOne：总血量为0后一同死亡，然后战斗结束
FightScene.FightMode = {oneByOne = 1, allInOne = 2}
-- FightType    shipWar：船战，两队舰船互相炮击；aboardWar：登船战，两队队员互相攻击
FightScene.FightType = {shipWar = 1, aboardWar = 2 }
-- FightFailType    normal：普通 “您的舰队已覆灭”   eternal：永恒竞技场 “挑战失败，\n本次挑战奖励被收回”
FightScene.FightFailType = {normal = 1, eternal = 2 }
-- ShipFightCD
FightScene.ShipFightCD = 2.0
-- ShipFightCD
FightScene.ShipFightRest = 0.7
-- 船战最大回合数
FightScene.ShipWarRoundMax = 6.1

-- 炮筒位置
FightScene.paoScale = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0}
FightScene.paoRotate = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}

-- FightScene.data
FightScene.playerTeam = nil
FightScene.enemyTeam = nil
FightScene.fightMode = 0
FightScene.fightType = 0
FightScene.fightFailType = 0
FightScene.fightResult = false

FightScene.breadData = nil

-- buffer列表
FightScene.buffers = nil
-- 船战每回合的登船几率
FightScene.aboardProsb = {}
-- 是否开启战斗特效
FightScene.isShowEffect = true


-- ui staff
FightScene.hp = nil
FightScene.label_hp = nil
FightScene.playerAtkPgBar = nil
FightScene.playerHpLabels = nil

FightScene.ehp = nil
FightScene.label_ehp = nil

FightScene.playerActors = nil
FightScene.playerHealActors = nil
FightScene.enemyActors = nil
FightScene.enemyEffectActors = nil

FightScene.playerAtkBtns = nil

FightScene.autoEnableBtn = nil
FightScene.autoDisableBtn = nil

FightScene.breadNumLabel = nil

FightScene.shipWarEffectNodeEnemy = nil
FightScene.shipWarEffectNodePlayer = nil

FightScene.shipWarBombNodeEnemy = nil
FightScene.shipWarBombNodePlayer = nil

FightScene.shipNodeEnemy = nil
FightScene.shipNodePlayer = nil

FightScene.bufferNode = nil
FightScene.debufferNode = nil

FightScene.jyProgress = nil

FightScene.dlgNode = nil
FightScene.dlgLabel = nil

-- bufferLabel列表
FightScene.bufferLabels = nil

-- lastUpdateTime
FightScene.lastUpdateTime = 0
-- beginUpdateTime
FightScene.beginUpdateTime = 0
-- 船战回合数
FightScene.shipWarRound = 0

-- callback
FightScene.JiYangCD = 5.0
FightScene.jiyangtime = 0.0

-- isAutoAtk
FightScene.isAutoAtk = true
-- isPause
FightScene.isPause = false
-- isBossInjured
FightScene.isBossInjured = false

-- callback
FightScene.fightOverCallback = nil

-- FightScene.funcitons
function FightScene:create(fightType, failType, isHideCurtain)
    local view = FightScene.new()
    if view and view:init(fightType, failType, isHideCurtain) then
        return view
    end
    return nil
end

-- init
function FightScene:init(fightType, failType, isHideCurtain)
    FightScene.instance = self
    self:initData(fightType)
    self:initUIAndScene()
    self.fightFailType = failType



    local function update()
        local nowTime = getSystemTimeMilliSecond()
        local deltaTime = nowTime-self.lastUpdateTime
        self.lastUpdateTime = nowTime
        self:update(deltaTime)
    end

    local function scheduleMyUpdate()
        for i=1,#self.playerTeam.fighters do
            local fighter = self.playerTeam.fighters[i]
            fighter.lastAtkTime = getSystemTimeMilliSecond()

            -- 先发制人天赋
            if fdm.bonusAttribute.ready then fighter.lastAtkTime = 0 end
        end

        for i=1,#self.enemyTeam.fighters do
            local fighter = self.enemyTeam.fighters[i]
            fighter.lastAtkTime = getSystemTimeMilliSecond()
        end
        self:initShipWarCDData()
        self.lastUpdateTime = getSystemTimeMilliSecond()
        self.beginUpdateTime = self.lastUpdateTime
        self:scheduleUpdateWithPriorityLua(update, 0)
    end

    if isHideCurtain then
        scheduleMyUpdate()
    else
        self:showCurtainEffect(1, function()
            scheduleMyUpdate()
        end)
    end

    return true
end

-- 初始化战斗数据
function FightScene:initData(fightType)
    -- init fightMode and fightType
    if fightType == FightScene.FightType.shipWar or fightType == FightScene.FightType.aboardWar then
        self.fightType = fightType
    else
        self.fightType = FightScene.FightType.shipWar
    end
    self.fightMode = FightScene.FightMode.allInOne
    self.isPause = false
    self.isShowEffect = DataManager:getInstance():getEffect_off() == 0
    self.shipWarRound = 0
    self.fightResult = false
    self.isBossInjured = false
    self.isAutoAtk = true
    self.jiyangtime = FightScene.JiYangCD

    -- init two team here (for test)
    self.playerTeam = Team.new()
    self.enemyTeam = Team.new()

    self.breadData = nil
    local package = DataManager:getInstance():getRoleData(roleBattlePack)
    if package then
        self.breadData = package["1005"]
    end

    local playerFighters = {}
    local enemyFighters = {}
    if self.fightType == FightScene.FightType.shipWar then
        self.playerTeam.star = fdm.playerCanoon.star
        local teamNums = fdm.playerCanoon.num
        for i=1,teamNums do
            if i>10 then break end
            local fighter = Fighter.new()
            fighter:init(Fighter.TeamType.playerTeam)
            fighter.teamIndex = i
            if i == 1 then
                fighter.m_hp = math.floor(fdm.playerCanoon.hp/teamNums+fdm.playerCanoon.hp%teamNums)
            else
                fighter.m_hp = math.floor(fdm.playerCanoon.hp/teamNums)
            end
            fighter.m_atk = fdm.playerCanoon.power
            fighter.m_skillRatio = 1
            fighter.name = fdm.playerCanoon.name
            fighter:reset()
            playerFighters[i] = fighter
        end
        self.enemyTeam.star = fdm.enemyCanoon.star
        local enemyNum = fdm.enemyCanoon.num
        for i=1,enemyNum do
            if i>10 then break end
            local fighter = Fighter.new()
            fighter:init(Fighter.TeamType.enemyTeam)
            fighter.teamIndex = i
            if i == 1 then
                fighter.m_hp = math.floor(fdm.enemyCanoon.hp/enemyNum+fdm.enemyCanoon.hp%enemyNum)
            else
                fighter.m_hp = math.floor(fdm.enemyCanoon.hp/enemyNum)
            end
            fighter.m_atk = fdm.enemyCanoon.power
            fighter.m_skillRatio = 1
            fighter.name = fdm.enemyCanoon.name
            fighter:reset()
            enemyFighters[i] = fighter
        end
    else
        self.playerTeam.star = 1

        -- test
--        fdm.bonusAttribute.hp = 100
--        fdm.bonusAttribute.power = 100
--        fdm.bonusAttribute.att = 0
--        fdm.bonusAttribute.hits = 100000
--        fdm.bonusAttribute.dodge = 100000
--        fdm.bonusAttribute.damageReduction = 100


        local teamNums = #fdm.playerFighters
        for i=1,teamNums do
            if i>6 then break end
            local data = fdm.playerFighters[i]
            local fighter = Fighter.new()
            fighter:init(Fighter.TeamType.playerTeam)
            fighter.teamIndex = i
            if i == 1 then
                fighter.m_hp = data.hp+math.ceil(fdm.bonusAttribute.hp/teamNums+fdm.bonusAttribute.hp%teamNums)

                local addPower = fdm.bonusAttribute.power+fdm.bonusAttribute.att
                fighter.m_atk = data.power+math.ceil(addPower/teamNums+addPower%teamNums)

                fighter.m_miss = data.miss+fdm.bonusAttribute.dodge

                fighter.damageReduction = math.ceil(fdm.bonusAttribute.damageReduction/teamNums+fdm.bonusAttribute.damageReduction%teamNums)
            else
                fighter.m_hp = data.hp+math.ceil(fdm.bonusAttribute.hp/teamNums)

                local addPower = fdm.bonusAttribute.power+fdm.bonusAttribute.att
                fighter.m_atk = data.power+math.ceil(addPower/teamNums)

                fighter.m_miss = data.miss+fdm.bonusAttribute.dodge

                fighter.damageReduction = math.ceil(fdm.bonusAttribute.damageReduction/teamNums)
            end

            fighter.m_interval = data.speed
            fighter.name = data.name
            fighter.soilderId = data.soilderId
            local soilderCsv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
            local skillCsv = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
            local soilderData = soilderCsv[tostring(data.soilderId)]
            local skillData = skillCsv[tostring(soilderData.skill)]
            fighter.m_skillRatio = tonumber(skillData.attack)
            fighter.bufferId = tonumber(skillData.buffID)
            fighter.description = soilderData.description
            fighter:reset()
            playerFighters[i] = fighter
        end
        self.enemyTeam.star = math.random(1,5)
        local enemyNum = #fdm.enemyFighters
        for i=1,1 do  -- 登船战只有一个boss
            if i>6 then break end
            local data = fdm.enemyFighters[i]
            local fighter = Fighter.new()
            fighter:init(Fighter.TeamType.enemyTeam)
            fighter.teamIndex = i
            fighter.m_hp = data.hp
            fighter.m_interval = data.speed
            fighter.m_atk = data.power
            fighter.m_miss = data.miss
            fighter.name = data.name
            fighter.soilderId = data.soilderId
            local soilderCsv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
            local soilderData = soilderCsv[tostring(data.soilderId)]
            self.enemyTeam.star = tonumber(soilderData.star)
            fighter.m_skillRatio = 1
            fighter.bufferId = 1
            fighter.description = soilderData.description
            fighter:reset()
            enemyFighters[i] = fighter
        end
    end

--    local teamNums = math.random(2, 6)
--    if self.fightType == FightScene.FightType.shipWar then
--        teamNums = math.random(4, 4)*2
--    elseif self.fightType == FightScene.FightType.aboardWar then
--        teamNums = math.random(1, 3)*2
--    end
--
--    for i=1,teamNums do
--        local fighter = Fighter.new()
--        fighter:init(Fighter.TeamType.playerTeam)
--        fighter.teamIndex = i
--        playerFighters[i] = fighter
--    end
--
--    local enemyNum = 0
--    if self.fightType == FightScene.FightType.shipWar then
--        enemyNum = math.random(4, 4)*2
--    elseif self.fightType == FightScene.FightType.aboardWar then
--        enemyNum = 1 -- 登船战斗现在默认只有一个怪物
--    end
--    for i=1,enemyNum do
--        local fighter = Fighter.new()
--        fighter:init(Fighter.TeamType.enemyTeam)
--        fighter.teamIndex = i
--        enemyFighters[i] = fighter
--    end

    self.buffers = {}
    self.bufferLabels = {}
    self.aboardProsb = {1, 5, 10, 50, 80 ,100}
    self.playerTeam.fighters = playerFighters
    self.enemyTeam.fighters = enemyFighters
    self:calculateTeamHp()
    self:calculateTeamMiss()
    self:initShipWarCDData()
end

-- initShipWarCDData
function FightScene:initShipWarCDData()
    if self.fightType == FightScene.FightType.shipWar then
        local arrayPlayer = {}
        for i=1,#self.playerTeam.fighters do
            arrayPlayer[i] = i
        end
        for i=1,#self.playerTeam.fighters do
            local rand = math.random(1, #arrayPlayer)
            local idx = arrayPlayer[rand]
            local fighter = self.playerTeam.fighters[idx]
            table.remove(arrayPlayer, rand)

            fighter.m_interval = FightScene.ShipFightCD+FightScene.ShipFightRest
            fighter.lastAtkTime = getSystemTimeMilliSecond()-(i*FightScene.ShipFightCD/(#self.playerTeam.fighters))-FightScene.ShipFightRest
            fighter:reset()

        end

        local arrayEnemy = {}
        for i=1,#self.enemyTeam.fighters do
            arrayEnemy[i] = i
        end
        for i=1,#self.enemyTeam.fighters do
            local rand = math.random(1, #arrayEnemy)
            local idx = arrayEnemy[rand]
            local fighter = self.enemyTeam.fighters[idx]
            table.remove(arrayEnemy, rand)

            fighter.m_interval = FightScene.ShipFightCD+FightScene.ShipFightRest
            fighter.lastAtkTime = getSystemTimeMilliSecond()-(i*FightScene.ShipFightCD/(#self.enemyTeam.fighters))-FightScene.ShipFightRest
            fighter:reset()

        end
    end
end

-- 初始化界面和场景
function FightScene:initUIAndScene()
    if self.fightType == FightScene.FightType.aboardWar then
        self:initAboardWarUIScene()
    elseif self.fightType == FightScene.FightType.shipWar then
        self:initShipWarUIScene()
    end
end

function FightScene:initShipWarUIScene()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    local pao_layer1 = 1
    local boat_layer = 2
    local pao_layer2 = 3
    local top_layer = 3

    -- background
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    self:addChild(colorLayer)

    -- 添加总背景
    local mainBg = cc.Sprite:create("Images/Background/MainBackGround.png")
    mainBg:setAnchorPoint(cc.p(0, 0))
    mainBg:setPosition(cc.p(0, 0))
    self:addChild(mainBg)

    self.shipNodeEnemy = cc.Node:create()
    self.shipNodePlayer = cc.Node:create()
    self:addChild(self.shipNodeEnemy, boat_layer)
    self:addChild(self.shipNodePlayer, boat_layer)

    -- boat
    local boat_down = cc.Sprite:create("Images/Fight/chuan_04.png")
    boat_down:setPosition(0.5*visibleSize.width, 0.0)
    boat_down:setAnchorPoint(cc.p(0.5, 0.0))
    self.shipNodePlayer:addChild(boat_down, boat_layer)
    local boatr_up = cc.Sprite:create("Images/Fight/chuan_04.png")
    boatr_up:setFlippedY(true)
    boatr_up:setAnchorPoint(cc.p(0.5, 1.0))
    boatr_up:setPosition(0.5*visibleSize.width, visibleSize.height)
    self.shipNodeEnemy:addChild(boatr_up, boat_layer)
    -- tip
    local tip = cc.LabelTTF:create("一艘阴森森的海盗船对你发起了炮击", BoldFont, 25.0)
    tip:setPosition(0.5*visibleSize.width, visibleSize.height-30.0)
    self:addChild(tip, top_layer)

    -- stars
    for i=1,self.enemyTeam.star do
        local star = cc.Sprite:create("Images/UI/xingxing01.png")
        local len = self.enemyTeam.star-1
        local posx = (-0.5*len+(i-1))*30.0
        star:setPosition(0.5*visibleSize.width+posx, visibleSize.height-90.0)
        self:addChild(star)
    end


    -- name
    local name = cc.LabelTTF:create("海魂诅咒者", BoldFont, 35.0)
    name:setPosition(0.5*visibleSize.width, visibleSize.height-130.0)
    self:addChild(name, top_layer)
    local mons = self.enemyTeam.fighters[1]
    if mons then name:setString(mons.name) end


    -- enemy hp
    local bg_ehp = cc.Sprite:create("Images/Fight/xuetiao01.png")
    bg_ehp:setPosition(0.5*visibleSize.width-0.5*bg_ehp:getContentSize().width, visibleSize.height-170.0)
    bg_ehp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(bg_ehp, top_layer)
    self.ehp = cc.Sprite:create("Images/Fight/xuetiao02.png")
    self.ehp:setPosition(bg_ehp:getPosition())
    self.ehp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(self.ehp, top_layer)
    self.label_ehp = cc.LabelTTF:create(tostring(self.enemyTeam.hp).."/"..tostring(self.enemyTeam.m_hp), BoldFont, 20.0)
    self.label_ehp:setPosition(0.5*visibleSize.width, bg_ehp:getPositionY())
    self:addChild(self.label_ehp, top_layer)

    local paoPosX = {162.0, 486.0, 258.0, 391.0, 61.0, 588.0, 209.0, 437.0, 108.0, 540}
    local paoPosY = {355.0, 355.0, 355.0, 355.0, 355.0, 355.0, 400.0, 400.0, 400.0, 400.0}

    self.enemyActors = {}
    self.enemyEffectActors = {}
    -- monsters
    for i=1,#self.enemyTeam.fighters do
        local t_layer = pao_layer2
        local monster
        if i > 6 then
            t_layer = pao_layer1
            monster = cc.Sprite:create("Images/Fight/chuan_03.png")
        else
            monster = cc.Sprite:create("Images/Fight/chuan_02.png")
        end

        monster:setPosition(paoPosX[i], visibleSize.height-paoPosY[i]+0.5*self.paoScale[i]*monster:getContentSize().height)
        monster:setAnchorPoint(cc.p(0.5, 1.0))
        monster:setScale(self.paoScale[i])
        monster:setRotation(-self.paoRotate[i])
        monster:setFlippedY(true)
        self.shipNodeEnemy:addChild(monster, t_layer)
        self.enemyActors[i] = monster
        self.enemyEffectActors[i] = monster
    end


    -- wofang
    local wofang = cc.LabelTTF:create("我方", BoldFont, 30.0)
    wofang:setPosition(0.5*visibleSize.width, 230.0)
    self:addChild(wofang, top_layer)

    -- hp
    local bg_hp = cc.Sprite:create("Images/Fight/xuetiao01.png")
    bg_hp:setPosition(0.5*visibleSize.width-0.5*bg_ehp:getContentSize().width, 200.0)
    bg_hp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(bg_hp, top_layer)
    self.hp = cc.Sprite:create("Images/Fight/xuetiao02.png")
    self.hp:setPosition(bg_hp:getPosition())
    self.hp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(self.hp, top_layer)
    self.label_hp = cc.LabelTTF:create(tostring(self.playerTeam.hp).."/"..tostring(self.playerTeam.m_hp), BoldFont, 20.0)
    self.label_hp:setPosition(0.5*visibleSize.width, bg_hp:getPositionY())
    self:addChild(self.label_hp, top_layer)

    self.playerAtkPgBar = {}
    self.playerHpLabels = {}
    self.playerActors = {}
    self.playerAtkBtns = {}
    for i=1,#self.playerTeam.fighters do
        local fighter = self.playerTeam.fighters[i]
        local headPosX
        local headNode = cc.Node:create()
        if i%2 ~= 0 then headPosX=visibleSize.width*0.25 else headPosX=visibleSize.width*0.75 end
        local headPosY = 350.0-math.floor((i-1)/2)*100.0
        headNode:setPosition(headPosX, headPosY)
        self:addChild(headNode, top_layer)

        local namebg = cc.Sprite:create("Images/Fight/bg1.png")
        namebg:setPosition(40.0, 30.0)
        namebg:setVisible(false)
        headNode:addChild(namebg)

        local name = cc.LabelTTF:create(fighter.name, BoldFont, 20.0)
        name:setPosition(namebg:getPosition())
        name:setVisible(false)
        headNode:addChild(name)

        local progbar1 = cc.Sprite:create("Images/Fight/jntiao01.png")
        local progbar2 = cc.Sprite:create("Images/Fight/jntiao02.png")
--        local progbar3 = cc.Sprite:create("Images/Fight/progbar_2_bg.png")
        progbar1:setAnchorPoint(cc.p(0.0, 0.5))
        progbar2:setAnchorPoint(progbar1:getAnchorPoint())
--        progbar3:setAnchorPoint(progbar1:getAnchorPoint())
        progbar1:setPosition(-30.0, -20.0)

        -- atkBtn
        local atkBtn = cc.MenuItemImage:create("Images/Fight/jntiao02.png", "Images/Fight/jntiao02.png")
        atkBtn:setTag(i)
        atkBtn:setPosition(progbar1:getPositionX()+0.5*progbar1:getContentSize().width, progbar1:getPositionY())
        atkBtn:setVisible(false)
        atkBtn:registerScriptTapHandler(function(tag, menuItem)
            -- do nothing
        end)
        local menu = cc.Menu:create(atkBtn)
        menu:setPosition(0.0, 0.0)
        self.playerAtkBtns[i] = atkBtn

        progbar2:setPosition(progbar1:getPosition())
--        progbar3:setPosition(progbar1:getPositionX()-4.0, progbar1:getPositionY())
        progbar2:setScaleX(fighter.hp/fighter.m_hp)
        self.playerAtkPgBar[i] = progbar2
        headNode:addChild(progbar1)
        headNode:addChild(progbar2)
        headNode:addChild(menu)
--        headNode:addChild(progbar3)

        progbar1:setVisible(false)
        progbar2:setVisible(false)
--        progbar3:setVisible(false)


        local t_layer = pao_layer2
        local head
        if i > 6 then
            t_layer = pao_layer1
            head = cc.Sprite:create("Images/Fight/chuan_03.png")
        else
            head = cc.Sprite:create("Images/Fight/chuan_02.png")
        end

        head:setPosition(paoPosX[i], paoPosY[i]-0.5*self.paoScale[i]*head:getContentSize().height)
        head:setAnchorPoint(cc.p(0.5, 0.0))
        head:setScale(self.paoScale[i])
        head:setRotation(self.paoRotate[i])
        self.shipNodePlayer:addChild(head, t_layer)
        self.playerActors[i] = head


        local hp = cc.LabelTTF:create(tostring(fighter.hp).."/"..tostring(fighter.m_hp), BoldFont, 20.0)
        hp:setPosition(progbar1:getPositionX()+0.5*progbar1:getContentSize().width, progbar1:getPositionY())
        hp:setColor(cc.c4b(255, 0, 0, 255))
        hp:setVisible(false)
        headNode:addChild(hp)
        self.playerHpLabels[i] = hp

    end

    -- shipWarEffectNode
    self.shipWarEffectNodeEnemy = cc.Node:create()
    self.shipWarEffectNodeEnemy:setPosition(120.0, visibleSize.height-220.0)
    self:addChild(self.shipWarEffectNodeEnemy, top_layer)
    self.shipWarEffectNodePlayer = cc.Node:create()
    self.shipWarEffectNodePlayer:setPosition(visibleSize.width-120.0, 220.0)
    self:addChild(self.shipWarEffectNodePlayer, top_layer)

    self.shipWarBombNodeEnemy = cc.Node:create()
    self.shipWarBombNodePlayer = cc.Node:create()
    self:addChild(self.shipWarBombNodeEnemy, boat_layer)
    self:addChild(self.shipWarBombNodePlayer, boat_layer)

    -- 桅杆
--    local wengan_down = cc.Sprite:create("Images/Fight/weigan.png")
--    wengan_down:setPosition(0.5*visibleSize.width, 348.0)
--    self.shipNodePlayer:addChild(wengan_down, top_layer)
--    local wengan_up = cc.Sprite:create("Images/Fight/weigan.png")
--    wengan_up:setFlippedY(true)
--    wengan_up:setPosition(0.5*visibleSize.width, visibleSize.height-348.0)
--    self.shipNodeEnemy:addChild(wengan_up, top_layer)

    -- 船舵
    local duo = cc.Sprite:create("Images/Fight/zdzd_01.png")
    duo:setPosition(0.5*visibleSize.width, 0.5*134.0)
    self:addChild(duo, top_layer)

--    -- autoBtn
--    local menuf,autoCallback
--    local resetAutoBtn = function()
--        local autoBtn
--        if self.isAutoAtk then
--            autoBtn = cc.MenuItemImage:create("Images/Fight/zdzd_03.png", "Images/Fight/zdzd_02.png")
--        else
--            autoBtn = cc.MenuItemImage:create("Images/Fight/zdzd_02.png", "Images/Fight/zdzd_03.png")
--        end
--        autoBtn:setPosition(0.5*visibleSize.width, 28.0)
--        autoBtn:registerScriptTapHandler(autoCallback)
--        local menuf = cc.Menu:create(autoBtn)
--        menuf:setPosition(cc.p(0, 0))
--        menuf:setEnabled(false)
--        self:addChild(menuf, top_layer)
--    end
--    autoCallback = function()
----        cclog("点击了自动战斗按钮")
----        self.isAutoAtk = not self.isAutoAtk
----        self:removeChild(menuf)
----        resetAutoBtn()
--    end
--    resetAutoBtn()


end

function FightScene:initAboardWarUIScene()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- background
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 255))
    self:addChild(colorLayer)

    -- 添加总背景
    local mainBg = cc.Sprite:create("Images/Background/MainBackGround.png")
    mainBg:setAnchorPoint(cc.p(0, 0))
    mainBg:setPosition(cc.p(0, 0))
    self:addChild(mainBg)

    -- boat
    self.shipNodePlayer = cc.Node:create()
    self:addChild(self.shipNodePlayer)
    local boat = cc.Sprite:create("Images/Fight/chuan_01.png")
    boat:setPosition(0.5*visibleSize.width, 0.0)
    boat:setAnchorPoint(cc.p(0.5, 0.0))
    self.shipNodePlayer:addChild(boat)

    local monsterNode = cc.Node:create()
    monsterNode:setPosition(0.5*visibleSize.width, 0.5*visibleSize.height+0.5*(460.0-130.0)-50.0)
    self:addChild(monsterNode)

    local mons = self.enemyTeam.fighters[1]
    -- tip
    local tip = cc.LabelTTF:create("", BoldFont, 25.0)
    tip:setPosition(0.5*visibleSize.width, visibleSize.height-30.0)
    self:addChild(tip)
    if mons and mons.description then tip:setString(mons.description) end

    -- stars
    for i=1,self.enemyTeam.star do
        local star = cc.Sprite:create("Images/UI/xingxing01.png")
        local len = self.enemyTeam.star-1
        local posx = (-0.5*len+(i-1))*30.0
        star:setPosition(0.5*visibleSize.width+posx, visibleSize.height-90.0)
        self:addChild(star)
    end

    -- name
    local name = cc.LabelTTF:create("海魂诅咒者", BoldFont, 35.0)
    name:setPosition(0.5*visibleSize.width, visibleSize.height-130.0)
    self:addChild(name)
    if mons and mons.name then name:setString(mons.name) end

    -- enemy hp
    local bg_ehp = cc.Sprite:create("Images/Fight/xuetiao01.png")
    bg_ehp:setPosition(0.5*visibleSize.width-0.5*bg_ehp:getContentSize().width, visibleSize.height-170.0)
    bg_ehp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(bg_ehp)
    self.ehp = cc.Sprite:create("Images/Fight/xuetiao02.png")
    self.ehp:setPosition(bg_ehp:getPosition())
    self.ehp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(self.ehp)
    self.label_ehp = cc.LabelTTF:create(tostring(self.enemyTeam.hp).."/"..tostring(self.enemyTeam.m_hp), BoldFont, 20.0)
    self.label_ehp:setPosition(0.5*visibleSize.width, bg_ehp:getPositionY())
    self:addChild(self.label_ehp)

    -- debufferNode
    self.debufferNode = cc.Node:create()
    self.debufferNode:setPosition(0.5*visibleSize.width, self.label_ehp:getPositionY()-50.0)
    self:addChild(self.debufferNode, 3)

    self.enemyActors = {}
    self.enemyEffectActors = {}


    local soilders = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    -- monsters （现在默认只有一个）
    for i=1,#self.enemyTeam.fighters do
        local fighter = self.enemyTeam.fighters[i]
        local data = soilders[tostring(fighter.soilderId)]
        local str = "Images/Boss/g_300.png"
        if data.icon and string.len(data.icon) > 2 then
            str = "Images/Boss/"..data.icon
        end
        local monster = cc.Sprite:create(str)
        monster:setScale(2.5)
        monsterNode:addChild(monster)
        local node = cc.Node:create()
        monsterNode:addChild(node)
        self.enemyActors[i] = monster
        self.enemyEffectActors[i] = node

        -- 怪物时隐时现效果
        local fadeTo30 = cc.FadeTo:create(1.0, 0.3*255)
        local fadeTo70 = cc.FadeTo:create(1.0, 0.7*255)
        local delay = cc.DelayTime:create(1.0)
        local seq = cc.Sequence:create(fadeTo30, fadeTo70, delay)
        local action = cc.RepeatForever:create(seq)
        monster:runAction(action)
    end

    self.dlgNode = cc.Node:create()
    self.dlgNode:setPosition(monsterNode:getPositionX(), monsterNode:getPositionY()+130.0)
    self:addChild(self.dlgNode)

    local dlg = cc.Sprite:create("Images/Fight/fightDlg.png")
    self.dlgNode:addChild(dlg)

    self.dlgLabel = cc.LabelTTF:create("...", BoldFont, 24.0)
    self.dlgLabel:setPosition(dlg:getPositionX(), dlg:getPositionY()+10.0)
    self.dlgNode:addChild(self.dlgLabel)
    self:hideMonasterDialogue()

    -- wofang
    local wofang = cc.LabelTTF:create("我方", BoldFont, 35.0)
    wofang:setPosition(0.5*visibleSize.width, 530.0)
    self:addChild(wofang)

    -- hp
    local bg_hp = cc.Sprite:create("Images/Fight/xuetiao01.png")
    bg_hp:setPosition(0.5*visibleSize.width-0.5*bg_ehp:getContentSize().width, 490.0)
    bg_hp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(bg_hp)
    self.hp = cc.Sprite:create("Images/Fight/xuetiao02.png")
    self.hp:setPosition(bg_hp:getPosition())
    self.hp:setAnchorPoint(cc.p(0.0, 0.5));
    self:addChild(self.hp)
    self.label_hp = cc.LabelTTF:create(tostring(self.playerTeam.hp).."/"..tostring(self.playerTeam.m_hp), BoldFont, 20.0)
    self.label_hp:setPosition(0.5*visibleSize.width, bg_hp:getPositionY())
    self:addChild(self.label_hp)

    -- bufferNode
    self.bufferNode = cc.Node:create()
    self.bufferNode:setPosition(0.5*visibleSize.width, self.label_hp:getPositionY()-50.0)
    self:addChild(self.bufferNode, 3)

    self.playerAtkPgBar = {}
    self.playerHpLabels = {}
    self.playerActors = {}
    self.playerAtkBtns = {}
    for i=1,#self.playerTeam.fighters do
        local fighter = self.playerTeam.fighters[i]
        local soilderCsv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
        local skillCsv = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
        local soilderData = soilderCsv[tostring(fighter.soilderId)]
        local skillData = skillCsv[tostring(soilderData.skill)]
        local headPosX
        local headNode = cc.Node:create()
        if i%2 ~= 0 then headPosX=visibleSize.width*0.25 else headPosX=visibleSize.width*0.75 end
        local headPosY = 350.0-math.floor((i-1)/2)*100.0
        headNode:setPosition(headPosX, headPosY)
        self:addChild(headNode)

--        local namebg = cc.Sprite:create("Images/Fight/bg1.png")
--        namebg:setPosition(40.0, 30.0)
--        headNode:addChild(namebg)

        local name = cc.LabelTTF:create(fighter.name, BoldFont, 24.0)
        name:setAnchorPoint(cc.p(0.0, 0.5))
        name:setPosition(-30.0, 30.0)
        headNode:addChild(name)

        local progbar1 = cc.Sprite:create("Images/Fight/jntiao01.png")
        local progbar2 = cc.Sprite:create("Images/Fight/jntiao02.png")
--        local progbar3 = cc.Sprite:create("Images/Fight/progbar_2_bg.png")
        progbar1:setAnchorPoint(cc.p(0.0, 0.5))
        progbar2:setAnchorPoint(progbar1:getAnchorPoint())
--        progbar3:setAnchorPoint(progbar1:getAnchorPoint())
        progbar1:setPosition(-30.0, 0.0)

        -- atkBtn
        local atkBtn = cc.MenuItemImage:create("Images/Fight/jntiao01.png", "Images/Fight/jntiao02.png")
        atkBtn:setTag(i)
        atkBtn:setPosition(progbar1:getPositionX()+0.5*progbar1:getContentSize().width, progbar1:getPositionY())
        atkBtn:registerScriptTapHandler(function(tag, menuItem)
        --            cclog("atkBtn tag is "..tostring(tag))
            local attackter = self.playerTeam.fighters[tag]
            local defender = self.enemyTeam.fighters[1]
            if attackter and defender then self:attack(attackter, defender) end
        end)
        local menu = cc.Menu:create(atkBtn)
        menu:setPosition(0.0, 0.0)
        self.playerAtkBtns[i] = atkBtn
        atkBtn:setVisible(false)

        progbar2:setPosition(progbar1:getPosition())
--        progbar3:setPosition(progbar1:getPositionX()-4.0, progbar1:getPositionY())
        progbar2:setScaleX(fighter.hp/fighter.m_hp)
        if fdm.bonusAttribute.ready then progbar2:setScaleX(0) end
        self.playerAtkPgBar[i] = progbar2
        headNode:addChild(progbar1)
        headNode:addChild(progbar2)
        headNode:addChild(menu)
--        headNode:addChild(progbar3)

        -- 技能名字
        local skillName = cc.LabelTTF:create(tostring(skillData.name), BoldFont, 24.0)
        skillName:setPosition(progbar1:getPositionX()+0.5*progbar1:getContentSize().width, progbar1:getPositionY())
        headNode:addChild(skillName)

        -- 船员星级
        local starLevel = tonumber(soilderData.star)
        for i=1,starLevel do
            local star = cc.Sprite:create("Images/UI/xingxing01.png")
            star:setAnchorPoint(cc.p(0.0, 0.5))
            star:setPosition(-30.0+(i-1)*30.0, -25.0)
            headNode:addChild(star)
        end

        -- 头像背景图
        local headBg = cc.Sprite:create("Images/Fight/toux_01.png")
        headBg:setPosition(-68.0, 2.0)
        headNode:addChild(headBg)

        -- 头像
        local str = "Images/Icon/j_2.png"
        if soilderData.icon and string.len(soilderData.icon) > 2 then
            str = "Images/Icon/"..soilderData.icon
        end
        local head = cc.Sprite:create(str)
        head:setPosition(headBg:getPosition())
        headNode:addChild(head)
        self.playerActors[i] = head

        local hp = cc.LabelTTF:create(tostring(fighter.hp).."/"..tostring(fighter.m_hp), BoldFont, 20.0)
        hp:setPosition(progbar1:getPositionX()+0.5*progbar1:getContentSize().width, progbar1:getPositionY())
        hp:setColor(cc.c4b(255, 0, 0, 255))
        hp:setVisible(self.fightMode == FightScene.FightMode.oneByOne)
        headNode:addChild(hp)
        self.playerHpLabels[i] = hp

    end

    self.playerHealActors = cc.Node:create()
    self.playerHealActors:setPosition(visibleSize.width*0.5, 350.0-100.0)
    self:addChild(self.playerHealActors)


    -- 船舵
    local duo = cc.Sprite:create("Images/Fight/zdzd_01.png")
    duo:setPosition(0.5*visibleSize.width, 0.5*134.0)
    self:addChild(duo)

--    -- autoBtn
--    self.autoEnableBtn = cc.MenuItemImage:create("Images/Fight/zdzd_02.png", "Images/Fight/zdzd_03.png")
--    self.autoDisableBtn = cc.MenuItemImage:create("Images/Fight/zdzd_03.png", "Images/Fight/zdzd_02.png")
--    self.autoEnableBtn:setPosition(0.5*visibleSize.width, 28.0)
--    self.autoDisableBtn:setPosition(self.autoEnableBtn:getPosition())
--    self.autoEnableBtn:setVisible(false)
--    self.autoEnableBtn:registerScriptTapHandler(function()
--        if self.isPause then return end
--        self.isAutoAtk = true
--        self.autoEnableBtn:setVisible(false)
--        self.autoDisableBtn:setVisible(true)
--    end)
--    self.autoDisableBtn:registerScriptTapHandler(function()
--        if self.isPause then return end
--        self.isAutoAtk = false
--        self.autoEnableBtn:setVisible(true)
--        self.autoDisableBtn:setVisible(false)
--    end)
--
--    local menuf = cc.Menu:create(self.autoEnableBtn, self.autoDisableBtn)
--    menuf:setPosition(cc.p(0, 0))
--    self:addChild(menuf)

    -- miaoshaBtn
    local miaoshaBtn = cc.MenuItemImage:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png")
    miaoshaBtn:registerScriptTapHandler(function()
        if self.isPause then return end
        if 1 == DataManager:getInstance():addDiamond(-5, false) then
            miaoshaBtn:setEnabled(false)
            self:miaoshaAttack()
        else
            ToastUtil:downString("您的钻石不足！", true)
        end
    end)
    miaoshaBtn:setPosition(105.0, 35.5)

    -- jiyangBtn
    local jiyangBtn = cc.MenuItemImage:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png")
    jiyangBtn:setScaleX(-1.0)
    jiyangBtn:registerScriptTapHandler(function()
        if self.isPause then return end
        if nil == self.breadData or nil == self.breadData.num or self.breadData.num <= 0 then
            ToastUtil:downString("您的食物不足！", true)
        else
            if self.jiyangtime >= FightScene.JiYangCD then
                -- 面包数量减少
                self.breadData.num = self.breadData.num-1

                local package = DataManager:getInstance():getRoleData(roleBattlePack)

                if package then
                    package["1005"] = self.breadData
                end
                
                DataManager:getInstance():setRoleData(roleBattlePack,package,nil)

                -- 加血音效
                if DataManager:getInstance():getSound_off() == 0 then
                    AudioEngine.playEffect(EFFECT_addhp, false)
                end

                -- 成就触发
                local achievementValue = DataManager:getInstance():getAchievementInfo(achievement_ConsumeBread)
                DataManager:getInstance():setAchievementInfo(achievement_ConsumeBread, (achievementValue + 1))

                local breadHp = math.floor(DataManager:getInstance():getRoleData(roleBreadHp))
                local healHp = breadHp
                for i=1,#self.playerTeam.fighters do
                    local fighter = self.playerTeam.fighters[i]
                    local heal = fighter.m_hp-fighter.hp
                    if healHp > heal then
                        fighter.hp = fighter.m_hp
                        healHp = healHp-heal
                    else
                        fighter.hp = fighter.hp+healHp
                        healHp = 0
                    end
                    -- 死亡变红的角色还原
                    local actor = self.playerActors[i]
                    if actor and self.fightMode == FightScene.FightMode.oneByOne then actor:setColor(cc.c3b(255, 255, 255)) end
                end
                local actor = self.shipWarEffectNodePlayer
                self:injuredEffect(actor, "+"..tostring(breadHp), cc.c3b(0, 255, 0))

                -- 设置cd
                self.jiyangtime = 0.0

                -- 更新血条
                self:calculateTeamHpAndRunAction()
            else
                ToastUtil:downString("冷却中！", true)
            end
        end
    end)
    jiyangBtn:setPosition(visibleSize.width-105.0, 35.5)

        -- shipWarEffectNode
    self.shipWarEffectNodeEnemy = cc.Node:create()
    self.shipWarEffectNodeEnemy:setPosition(self.ehp:getPositionX()-60.0, self.ehp:getPositionY())
    self:addChild(self.shipWarEffectNodeEnemy)
    self.shipWarEffectNodePlayer = cc.Node:create()
    self.shipWarEffectNodePlayer:setPosition(self.hp:getPositionX()+self.hp:getContentSize().width+60.0, self.hp:getPositionY())
    self:addChild(self.shipWarEffectNodePlayer)


    local menu2 = cc.Menu:create(miaoshaBtn)
    menu2:setPosition(cc.p(0, 0))
    self:addChild(menu2)
    local menu3 = cc.Menu:create(jiyangBtn)
    menu3:setPosition(cc.p(0, 0))
    self:addChild(menu3)

    local miaosha = cc.LabelTTF:create("秒杀", BoldFont, 40.0)
    miaosha:setPosition(miaoshaBtn:getPositionX()+30.0, miaoshaBtn:getPositionY())
    self:addChild(miaosha)

    local diamomdSp = cc.Sprite:create("Images/UI/DiamondBg.png")
    diamomdSp:setPosition(miaoshaBtn:getPositionX()-50.0, miaoshaBtn:getPositionY())
    self:addChild(diamomdSp)
    local diamomdNum = cc.LabelTTF:create("×5", BoldFont, 20.0)
    diamomdNum:setPosition(miaoshaBtn:getPositionX()-28.0, miaoshaBtn:getPositionY()-10.0)
    self:addChild(diamomdNum)

    self.jyProgress = cc.Sprite:create("Images/btn/ann03_a.png")
    self.jyProgress:setColor(cc.c3b(0, 0, 0))
    self.jyProgress:setAnchorPoint(cc.p(0.0, 0.5))
    self.jyProgress:setOpacity(230)
    self.jyProgress:setScaleX(0.0)
    self.jyProgress:setPosition(jiyangBtn:getPositionX()-0.5*self.jyProgress:getContentSize().width, jiyangBtn:getPositionY())
    self:addChild(self.jyProgress)

    local jiyang = cc.LabelTTF:create("吃食物", BoldFont, 40.0)
    jiyang:setPosition(jiyangBtn:getPositionX(), jiyangBtn:getPositionY())
    self:addChild(jiyang)
    local breadBg = cc.Sprite:create("Images/Fight/shuzidi02.png")
    breadBg:setPosition(jiyang:getPositionX()+80.0, jiyang:getPositionY()+25.0)
--    breadBg:setScale(0.4)
    self:addChild(breadBg)

    local num = 0
    if self.breadData and self.breadData.num then
        num = tostring(self.breadData.num)
    end
    self.breadNumLabel = cc.LabelTTF:create(tostring(num), BoldFont, 17.0)
    self.breadNumLabel:setPosition(breadBg:getPosition())
    self:addChild(self.breadNumLabel)

    -- 开场时boss必说话
    self:showMonasterDialogue(1)
end

-- update
function FightScene:update(deltaTime)
    if self.isPause then return end
    -- 船战回合判定
    if self.fightType == FightScene.FightType.shipWar then
        local nowTime = getSystemTimeMilliSecond()
        local deltaTime = nowTime-self.beginUpdateTime+FightScene.ShipFightRest
        self.shipWarRound = deltaTime/(FightScene.ShipFightCD+FightScene.ShipFightRest)

        local round = math.floor(self.shipWarRound)
        local aboard = false
        if round >= 1 and round < #self.aboardProsb then
            local prob =  self.aboardProsb[round]
            self.aboardProsb[round] = 0
            local rand = math.random(1, 100)
            aboard = prob >= rand
            if prob>0 then
--                cclog("round is "..tostring(round)..", prob is "..tostring(prob)..", rand is "..tostring(rand)..", aboard is "..tostring(aboard))
            end
        end
        -- 超回合或者几率符合开始登船
        if self.shipWarRound >= FightScene.ShipWarRoundMax or aboard then
            self:unscheduleUpdate()
            self:showCurtainEffect(2, function()
                local fightOverCallback = self.fightOverCallback
                local s = FightScene:create(FightScene.FightType.aboardWar, self.fightFailType, true)
                s:setFightOverCallback(fightOverCallback)
                local scene = cc.Scene:create()
                scene:addChild(s)
                cc.Director:getInstance():replaceScene(scene)
            end)
            return
        end
    end

    -- 执行攻击判定
    if self.playerTeam.hp>0 and self.enemyTeam.hp>0 then
        if self.isAutoAtk then
            self:playerAttack()
        end
        self:enemyAttack()
    end

    -- update UI
    for i=1,#self.playerTeam.fighters do
        local fighter = self.playerTeam.fighters[i]
        local atkPgBar = self.playerAtkPgBar[i]
        local hpLabel = self.playerHpLabels[i]
        local nowTime = getSystemTimeMilliSecond()

        -- 攻击CD更新
        local deltaTime = nowTime-fighter.lastAtkTime
        local scaleX = deltaTime/fighter.interval
        if scaleX < 0 then scaleX = 0 end
        if scaleX > 1 then scaleX = 1 end
        scaleX = 1-scaleX;
        atkPgBar:setScaleX(scaleX)

        -- 血量值更新
        hpLabel:setString(tostring(fighter.hp).."/"..tostring(fighter.m_hp))

        -- 死亡表识
        if fighter.hp <= 0 and (self.fightMode == FightScene.FightMode.oneByOne) then
            local actor = self.playerActors[i]
            if actor then actor:setColor(cc.c3b(255, 0, 0)) end
        end

        -- 手动攻击按钮
        local atkBtn = self.playerAtkBtns[i]
        if atkBtn and self.fightType ~= FightScene.FightType.shipWar then
            atkBtn:setVisible(not self.isAutoAtk and fighter.alive and fighter:canAttack())
        end
    end

    local breadNum = 0
    if self.breadData and self.breadData.num then
        breadNum = tostring(self.breadData.num)
        if self.breadNumLabel then
            self.breadNumLabel:setString(tostring(breadNum))
        end
    end

    if self.fightType == FightScene.FightType.aboardWar then
        self:updateBuffers(deltaTime)
    end

    -- 给养按钮CD
    if self.jyProgress then
        self.jiyangtime = self.jiyangtime + deltaTime
        local rate = self.jiyangtime/FightScene.JiYangCD
        if rate > 1 then rate = 1 end
        if rate < 0 then rate = 0 end
        self.jyProgress:setScaleX(1-rate)
    end

    -- 战斗结束
    if self.playerTeam.hp == 0 or self.enemyTeam.hp == 0 then
        self.fightResult = self.playerTeam.hp > 0
        self.isPause = true
        if self.fightType ~= FightScene.FightType.shipWar then
            if not self.fightResult then

                local _alert = AlertView:create(2, 2, "立即复活", function()

                    if DataManager:getInstance():addDiamond(-50,true) == 1 then
                        local explor = getExplor()
                        explor.eventManger.layer:safeBackToLayer()
                        return
                    end

                    end, function()

                    self:showFailInfoAndReturn()

                end, "确认死亡", "复 活")
                _alert:setOkRemove(0)
                -- 添加提示框的叹号图
                local alertIcon = cc.Sprite:create("Images/charging/fuhuo_02.png")
                alertIcon:setPosition(cc.p(_alert.s_position.x - 180.0, _alert.s_position.y + 30.0))
                _alert:addChild(alertIcon, 1)

                local showLabel1 = cc.LabelTTF:create("花费50钻可复活", BoldFont, 30)
                showLabel1:setColor(WriteColor)
                showLabel1:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
                -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
                showLabel1:setPosition(cc.p(_alert.s_position.x + showLabel1:getContentSize().width * 0.15, alertIcon:getPositionY()))
                _alert:addChild(showLabel1, 1)

                -- self:showFailInfoAndReturn()
            else
                -- 死亡音效
                if DataManager:getInstance():getSound_off() == 0 then
                    AudioEngine.playEffect(EFFECT_mdead, false)
                end
                local delay = cc.DelayTime:create(1.0)
                local callf = cc.CallFunc:create(function()
                    if fdm.curLevel and fdm.totalLevel and fdm.curLevel > 0 and fdm.totalLevel > 0 and fdm.curLevel == fdm.totalLevel then
                        FightBoxView:create():show()
                        ExploreDataManager:getInstance():setOccupationData()
                    else
                        self:gotoFightRewardScene(0.0)
                    end
                end)
                local action = cc.Sequence:create(delay, callf)
                self:runAction(action)
            end
        else
            if not self.fightResult then

                 local _alert = AlertView:create(2, 2, "立即复活", function()

                    if DataManager:getInstance():addDiamond(-50,true) == 1 then
                        local explor = getExplor()
                        explor.eventManger.layer:safeBackToLayer()
                        return
                    end

                    end, function()

                    self:showFailInfoAndReturn()

                end, "确认死亡", "复 活")

                 _alert:setOkRemove(0)

                -- 添加提示框的叹号图
                local alertIcon = cc.Sprite:create("Images/charging/fuhuo_02.png")
                alertIcon:setPosition(cc.p(_alert.s_position.x - 180.0, _alert.s_position.y + 30.0))
                _alert:addChild(alertIcon, 1)

                local showLabel1 = cc.LabelTTF:create("花费50钻可复活", BoldFont, 30)
                showLabel1:setColor(WriteColor)
                showLabel1:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
                -- showLabel1:enableStroke(cc.c4b(16, 16, 16, 255), 1)
                showLabel1:setPosition(cc.p(_alert.s_position.x + showLabel1:getContentSize().width * 0.15, alertIcon:getPositionY()))
                _alert:addChild(showLabel1, 1)

                -- self:showFailInfoAndReturn()
            else
                local delay
                if self.isShowEffect then
                    delay = 2.0
                    if self.playerTeam.hp == 0 then
                        self:runShipBombingEffect(Fighter.TeamType.playerTeam, delay)
                    end
                    if self.enemyTeam.hp == 0 then
                        -- 沉船音效
                        if DataManager:getInstance():getSound_off() == 0 then
                            AudioEngine.playEffect(EFFECT_Chenchuan, false)
                        end
                        self:runShipBombingEffect(Fighter.TeamType.enemyTeam, delay)
                    end
                    self:gotoFightRewardScene(delay)
                else
                    delay = 1.0
                    self:gotoFightRewardScene(delay)
                end
            end
        end
    end

end

-- setFightOverCallback curtainId:1－战斗开始 2－登船
function FightScene:showCurtainEffect(curtainId, callback)
    local winSize = cc.Director:getInstance():getVisibleSize()

    local curtain1 = cc.Sprite:create("Images/Fight/bait_01.png")
    curtain1:setPosition(-0.5*curtain1:getContentSize().width, 0.5*winSize.height)
    self:addChild(curtain1, 1000)
    local move1 = cc.MoveBy:create(0.3, cc.p(winSize.width+curtain1:getContentSize().width, 0.0))
    local remove1 = cc.RemoveSelf:create()
    local action1 = cc.Sequence:create(move1, remove1)
    curtain1:runAction(action1)


    local curtain2 = cc.Sprite:create("Images/Fight/bait_01.png")
    curtain2:setPosition(winSize.width+0.5*curtain1:getContentSize().width, 0.5*winSize.height)
    curtain2:setFlippedX(true)
    curtain2:setFlippedY(true)
    self:addChild(curtain2, 1000)
    local move2 = cc.MoveBy:create(0.3, cc.p(-winSize.width-curtain2:getContentSize().width, 0.0))
    local remove2 = cc.RemoveSelf:create()
    local action2 = cc.Sequence:create(move2, remove2)
    curtain2:runAction(action2)

    local sp
    if 1 == curtainId then
        sp = cc.Sprite:create("Images/Fight/bait_02.png")
    elseif 2 == curtainId then
        sp = cc.Sprite:create("Images/Fight/bait_03.png")
    end
    sp:setPosition(0.5*winSize.width, 0.5*winSize.height)
    sp:setVisible(false)
    self:addChild(sp, 1000)

    local delay1 = cc.DelayTime:create(0.5)
    local show = cc.Show:create()
    local delay2 = cc.DelayTime:create(0.7)
    local scale = cc.ScaleBy:create(0.1, 2.5, 1.5)
    local fade = cc.FadeOut:create(0.1)
    local spawn = cc.Spawn:create(scale, fade)
    local delay3 = cc.DelayTime:create(0.3)
    local action = cc.Sequence:create(delay1, show, delay2, spawn, delay3, cc.CallFunc:create(function()
        callback()
    end), cc.RemoveSelf:create())
    sp:runAction(action)


end

-- setFightOverCallback
function FightScene:setFightOverCallback(callback)
    assert(type(callback) == "function")
    self.fightOverCallback = callback
end

-- gotoFightRewardScene
function FightScene:gotoFightRewardScene(delay)
    if delay == nil then delay = 1.0 end
    local fightOverCallback = self.fightOverCallback
    local fightResult = self.fightResult
    local delay = cc.DelayTime:create(delay)
    local callf = cc.CallFunc:create(function()
        local s = FightRewardScene:create()
        s:setFightOverCallback(fightOverCallback)
        s:setFightResult(fightResult)
        local scene = cc.Scene:create()
        scene:addChild(s)
        cc.Director:getInstance():replaceScene(scene)
    end)
    local action = cc.Sequence:create(delay, callf)
    self:runAction(action)
end

-- showFailInfoAndReturn
function FightScene:showFailInfoAndReturn()
    local fightOverCallback = self.fightOverCallback
    local fightResult = self.fightResult
    local colorLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 0))
    self:addChild(colorLayer, 10)

    local visibleSize = cc.Director:getInstance():getVisibleSize()

    --顶上的据点提示
    local tips = {"低级据点","中级据点","高级据点","精英据点","boss据点及特殊据点"}
    local colors = {cc.c3b(255,255,255),cc.c3b(43,229,0),cc.c3b(37,88,255),cc.c3b(229,0,221),cc.c3b(255,157,42)}

    local intervalX = visibleSize.width * 0.4
    local intervalY = visibleSize.height * 0.05

    local x = visibleSize.width * 0.15
    local y = visibleSize.height - intervalY / 3

    local spr = nil
    local tipLabel = nil
    local lastX = 0

    for i=1,5 do
        spr = cc.Sprite:create("Images/Map/huanguang_015.png")

        --奇数
        if i ~= 1 and i / 2 ~= math.floor(i / 2) then
            y = y - intervalY * 1.5
            x = visibleSize.width * 0.15
        --偶数
        elseif i ~= 1 then
            x = x + intervalX 
        else
            lastX = x + spr:getContentSize().width * 0.9 / 2
        end
        spr:setScale(0.9)
        spr:setPosition(cc.p(x + spr:getContentSize().width * spr:getScaleX() / 2, y - spr:getContentSize().height * spr:getScaleY() / 2))
        spr:setColor(colors[i])
        colorLayer:addChild(spr)

        tipLabel = cc.LabelTTF:create(tips[i], BoldFont, 20.0)
        tipLabel:setAnchorPoint(cc.p(0,0.5))
        tipLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        tipLabel:setPosition(cc.p(spr:getPositionX() + spr:getContentSize().width * spr:getScaleX() / 2 + 5,spr:getPositionY()))
        colorLayer:addChild(tipLabel)
    end

    y = y - intervalY * 1.5

    tipLabel = cc.LabelTTF:create("建议从最低级开始攻打!", BoldFont, 20.0)
    tipLabel:setAnchorPoint(cc.p(0,0.5))
    tipLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    tipLabel:setPosition(cc.p(lastX,y - tipLabel:getContentSize().height / 2))
    colorLayer:addChild(tipLabel)

    local fade = cc.FadeIn:create(1.0)
    local touchTips = nil 
    local call1 = cc.CallFunc:create(function()
        
        local abord
        if self.fightFailType == FightScene.FightFailType.eternal then
            abord = cc.LabelTTF:create("挑战失败，本次挑战奖励被收回", BoldFont, 40.0)
            abord:setPosition(0.5*visibleSize.width, 0.5*visibleSize.height-15.0)
        else
            abord = cc.LabelTTF:create("您的舰队已覆灭", BoldFont, 30.0)
            abord:setPosition(0.5*visibleSize.width , 0.5*visibleSize.height + abord:getContentSize().height * 4)

            local othertips = cc.LabelTTF:create("您可以：\n\t\t1.升级战船，增加携带海员数量\n\t\t2.升级战船炮筒威力及数量\n\t\t3.英雄转职，属性更强悍\n\t\t4.海上酒馆隐藏超强英雄",BoldFont, 30.0)
            othertips:setPosition(cc.p(visibleSize.width * 0.1 + othertips:getContentSize().width / 2,abord:getPositionY() - abord:getContentSize().height * 1.5 - othertips:getContentSize().height / 2))
            -- othertips:setAnchorPoint(cc.p(0,1))
            othertips:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
            -- othertips:setDimensions(cc.size(0,0))
            colorLayer:addChild(othertips)

            local trapDes1 = cc.LabelTTF:create("您现在需要更加强悍的伙伴", BoldFont, 35.0)
            trapDes1:setPosition(cc.p(visibleSize.width * 0.1 + 30 * 2  + trapDes1:getContentSize().width / 2,othertips:getPositionY() - othertips:getContentSize().height / 2 - trapDes1:getContentSize().height / 2 - 80))
            trapDes1:setColor(cc.c3b(255,127,39))
            colorLayer:addChild(trapDes1)

            -- local trapDes2 = cc.LabelTTF:create("和天赋", BoldFont, 40.0)
            -- trapDes2:setPosition(cc.p(visibleSize.width * 0.1 + 30 * 2  + trapDes2:getContentSize().width / 2,trapDes1:getPositionY() - trapDes1:getContentSize().height / 2 - trapDes2:getContentSize().height / 2 - 15))
            -- colorLayer:addChild(trapDes2)

            -- --Images/Icon/w_32.png
            -- local buttonIcon = cc.Sprite:create("Images/Icon/w_32.png")
            -- buttonIcon:setPosition(cc.p(visibleSize.width * 0.1 + 30 * 2  + buttonIcon:getContentSize().width / 2,othertips:getPositionY() - othertips:getContentSize().height / 2 - buttonIcon:getContentSize().height / 2 - 30))
            -- colorLayer:addChild(buttonIcon)

            local buttonInterval = 80

            local backBtnLabel = cc.LabelTTF:create("回 城", BoldFont, 35.0)
            backBtnLabel:setPosition(cc.p(abord:getPositionX() - buttonInterval - backBtnLabel:getContentSize().width / 2,trapDes1:getPositionY() - trapDes1:getContentSize().height - backBtnLabel:getContentSize().height))
            backBtnLabel:setColor(cc.c3b(255,255,255))
            local backBtn = SDButton:create("Images/btn/ann04_a.png","Images/btn/ann04_b.png",function (  )
                fightOverCallback(fightResult)
            end)
            local scale = backBtnLabel:getContentSize().width * 1.6 / backBtn:getContentSize().width
            backBtn:addClickArea(cc.rect(0, 0, 40, 40))
            backBtn:setScale(scale)
            backBtn:setPosition(cc.p(backBtnLabel:getPosition()))
            colorLayer:addChild(backBtn)

            colorLayer:addChild(backBtnLabel,100000)

            local strengtheningBtnLabel = cc.LabelTTF:create("变 强", BoldFont, 35.0)
            -- strengtheningBtnLabel:setPosition(cc.p(trapDes2:getPositionX() + trapDes2:getContentSize().width / 2 + 10 + strengtheningBtnLabel:getContentSize().width / 2,trapDes2:getPositionY()))
            strengtheningBtnLabel:setColor(cc.c3b(255,255,255))
            strengtheningBtnLabel:setPosition(cc.p(abord:getPositionX() + buttonInterval + strengtheningBtnLabel:getContentSize().width / 2,trapDes1:getPositionY() - trapDes1:getContentSize().height - strengtheningBtnLabel:getContentSize().height))

            local strengtheningBtn = SDButton:create("Images/btn/ann03_a.png","Images/btn/ann03_b.png",function (  )
                PushGiftView:create():show()
            end)

            local scale = strengtheningBtnLabel:getContentSize().width * 1.6 / strengtheningBtn:getContentSize().width
            strengtheningBtn:addClickArea(cc.rect(0, 0, 40, 40))
            strengtheningBtn:setScale(scale)
            strengtheningBtn:setPosition(cc.p(strengtheningBtnLabel:getPosition()))
            colorLayer:addChild(strengtheningBtn)
            colorLayer:addChild(strengtheningBtnLabel,100000)

            -- touchTips = cc.LabelTTF:create("点击屏幕可继续......", BoldFont, 30.0)
            -- touchTips:setPosition(cc.p(abord:getPositionX(),button:getPositionY() - button:getContentSize().height * scale - touchTips:getContentSize().height * 2))
            -- colorLayer:addChild(touchTips)
            -- touchTips:setVisible(false)

        end
        colorLayer:addChild(abord)
    end)
    local delay = cc.DelayTime:create(1.0)
    local call2 = cc.CallFunc:create(function()
        fightOverCallback(fightResult)
    end)

    local action = nil 
    if self.fightFailType == FightScene.FightFailType.eternal then
        action = cc.Sequence:create(fade, call1, delay, call2)

    else
        self.maskStatue = "actioning"
        -- --添加touch事件,防止触发本层之后的点击事件
        -- local listener = cc.EventListenerTouchOneByOne:create()
        -- listener:registerScriptHandler(function ( touch,event )

        --     print("maskLayerTouch",self.maskStatue)
        --     return true
        -- end,cc.Handler.EVENT_TOUCH_BEGAN)
        -- listener:setSwallowTouches(true)
        -- listener:registerScriptHandler(function ( touch,event )
            
        -- end,cc.Handler.EVENT_TOUCH_MOVED )
        -- listener:registerScriptHandler(function ( touch,event )
        --     if self.maskStatue ~= "actioning" then
        --         local action = cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
        --             print("call2")
        --             fightOverCallback(fightResult)
        --         end))
        --         colorLayer:runAction(action)
        --     end

        -- end,cc.Handler.EVENT_TOUCH_ENDED )

        -- local eventDispatcher = colorLayer:getEventDispatcher()
        -- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, colorLayer)
        -- eventDispatcher:setPriority(listener,-1000)
        action = cc.Sequence:create(fade, call1,cc.CallFunc:create(function ( ... )
            self.maskStatue = "ready"
            -- touchTips:setVisible(true)
            
            -- local seq = cc.Sequence:create(cc.FadeOut:create(0.5),cc.FadeIn:create(0.5))
            -- local action = cc.RepeatForever:create(seq)
            -- touchTips:runAction(action)

        end))
    end

    -- action = cc.Sequence:create(fade, call1, delay, call2)
    colorLayer:runAction(action)
end

-- runShipBombingEffect
function FightScene:runShipBombingEffect(teamType, delay)
    if delay == nil then delay = 3.0 end
    local visibleSize = cc.Director:getInstance():getVisibleSize()

    local actor
    local posx, posy
    local offset = 200.0
    posx= 0.5*visibleSize.width
    if teamType == Fighter.TeamType.enemyTeam then
        posy= visibleSize.height-offset
        actor = self.shipWarBombNodeEnemy
    else
        posy = offset
        actor = self.shipWarBombNodePlayer
    end

    if actor then
        local offsetW = visibleSize.width-100.0
        local offsetH = 400.0
        local callback = function()
            local offsetX = math.random(0, offsetW)-0.5*offsetW
            local offsetY = math.random(0, offsetH)-0.5*offsetH
            local animation = EffectUtil:createAnimation("Effect/Animation/chuanzhanbaozha.plist", math.random(1, 3))
            animation:setScale(3.0)
            animation:setPosition(posx+offsetX, posy+offsetY)
            actor:addChild(animation)
        end

        local del = cc.DelayTime:create(0.2)
        local call = cc.CallFunc:create(callback)
        local seq = cc.Sequence:create(del, call)
        local action = cc.RepeatForever:create(seq)
        self:runAction(action)
    end
end

-- updateBuffers
function FightScene:updateBuffers(deltaTime)
    for i=1,#self.buffers do
        local buffer = self.buffers[i]
        local bufferLabel = self.bufferLabels[i]
        buffer.runningTime = buffer.runningTime+deltaTime
        local str = string.format("%2.1f", buffer.duration-buffer.runningTime)
        bufferLabel:setString(str)

        -- 每秒结算
        if buffer.type == FightBufferData.BufferType.type1 or buffer.type == FightBufferData.BufferType.type2 then
            buffer.runningCyc = buffer.runningCyc+deltaTime
            if buffer.runningCyc >= buffer.settleCyc then
                buffer.runningCyc = 0
                self:bufferSettle(buffer)
            end
        end

        -- buffer 结束
        if buffer.runningTime >= buffer.duration then
            if buffer.type == FightBufferData.BufferType.type1 then
                self:bufferSettle(buffer)
            elseif buffer.type == FightBufferData.BufferType.type2 then
                self:bufferSettle(buffer)
            elseif buffer.type == FightBufferData.BufferType.type3 then
                self:bufferSettle(buffer)
            elseif buffer.type == FightBufferData.BufferType.type4 then

            end
            self:removeBuffer(buffer.index)
        end


    end
end

-- bufferBegin
function FightScene:bufferBegin(buffer)
    buffer.runningTime = 0
    buffer.startTime = getSystemTimeMilliSecond()
    if buffer.type == FightBufferData.BufferType.type1 then

    elseif buffer.type == FightBufferData.BufferType.type2 then

    elseif buffer.type == FightBufferData.BufferType.type3 then
        self:bufferSettle(buffer)
    elseif buffer.type == FightBufferData.BufferType.type4 then
        self:bufferSettle(buffer)
    end
end

-- bufferEnd
function FightScene:bufferEnd(buffer)
    local fighter = self.enemyTeam.fighters[1]
    if fighter then
        if buffer.type == FightBufferData.BufferType.type1 then

        elseif buffer.type == FightBufferData.BufferType.type2 then

        elseif buffer.type == FightBufferData.BufferType.type3 then
            fighter.isHalo = false
        elseif buffer.type == FightBufferData.BufferType.type4 then
            fighter.atk = fighter.m_atk
        end
    end
end

-- bufferSettle  buffer:结算的buffer
function FightScene:bufferSettle(buffer)
    local fighter = self.enemyTeam.fighters[1]
    if fighter then
        if buffer.type == FightBufferData.BufferType.type1 then
            fighter.hp = fighter.hp-buffer.attack
            local actor = self.shipWarEffectNodeEnemy
            self:injuredEffect(actor, "-"..tostring(buffer.attack))
            if fighter.hp <0 then fighter.hp=0 end
        elseif buffer.type == FightBufferData.BufferType.type2 then
            fighter = self.playerTeam.fighters[1]
            fighter.hp = fighter.hp+buffer.attack
            local actor = self.shipWarEffectNodePlayer
            self:injuredEffect(actor, "+"..tostring(buffer.attack), cc.c3b(0, 255, 0))
            if fighter.hp > fighter.m_hp then fighter.hp=fighter.m_hp end
        elseif buffer.type == FightBufferData.BufferType.type3 then
            fighter.isHalo = true
        elseif buffer.type == FightBufferData.BufferType.type4 then
            fighter.atk = fighter.atk-buffer.attack
            if fighter.atk <0 then fighter.atk=1 end
        end
    end
    self:calculateTeamHpAndRunAction()
end

-- addBuffer
function FightScene:addBuffer(buf)
    for i=1,#self.buffers do
        local tmpbuf  = self.buffers[i]
        if buf.type == tmpbuf.type then
            -- buffer的叠加暂时做覆盖处理
            self:removeBuffer(buf.index)
            break
        end
    end
    table.insert(self.buffers, 1, buf)
    self:bufferBegin(buf)
    self:reloadBuffers()
end

-- removeBuffer
function FightScene:removeBuffer(bufindex)
    for i=1,#self.buffers do
        local buf = self.buffers[i]
        if bufindex == buf.index then
            self:bufferEnd(buf)
            table.remove(self.buffers, i)
            self.bufferLabels[i] = nil
            self:reloadBuffers()
            return
        end
    end

end

-- reloadBuffers
function FightScene:reloadBuffers()
    self.debufferNode:removeAllChildren()
    self.bufferNode:removeAllChildren()
    local bufferNum = 0
    local debufferNum = 0
    for i=1,#self.buffers do
        local buffer = self.buffers[i]
        if buffer.type == FightBufferData.BufferType.type2 then
            bufferNum = bufferNum+1
            local icon = cc.Sprite:create("Images/Icon/"..buffer.icon)
            local len = #self.buffers-self:getDebufferNum()-1
            local posx = (-0.5*len+(bufferNum-1))*80.0
            icon:setPosition(posx, 0.0)
            self.bufferNode:addChild(icon)

            local bufferTime = cc.LabelTTF:create("", BoldFont, 20.0)
            bufferTime:setPosition(icon:getPositionX(), icon:getPositionY()-50.0)
            self.bufferNode:addChild(bufferTime)
            self.bufferLabels[i] = bufferTime
        else
            debufferNum = debufferNum+1
            local icon = cc.Sprite:create("Images/Icon/"..buffer.icon)
            local len = self:getDebufferNum()-1
            local posx = (-0.5*len+(debufferNum-1))*80.0
            icon:setPosition(posx, 0.0)
            self.debufferNode:addChild(icon)

            local debufferTime = cc.LabelTTF:create("", BoldFont, 20.0)
            debufferTime:setPosition(icon:getPositionX(), icon:getPositionY()-50.0)
            self.debufferNode:addChild(debufferTime)
            self.bufferLabels[i] = debufferTime
        end
    end
end

-- getDebufferNum
function FightScene:getDebufferNum()
    local num = 0
    for i=1,#self.buffers do
        local buffer = self.buffers[i]
        if buffer.type ~= FightBufferData.BufferType.type2 then
            num = num+1
        end
    end
    return num
end

-- calculateTeamMiss
function FightScene:calculateTeamMiss()
    local playerTeam = self.playerTeam
    local teamMiss = 0
    for i=1,#playerTeam.fighters do
        local fighter = playerTeam.fighters[i]
        teamMiss = teamMiss+fighter.miss
    end
    playerTeam.miss = teamMiss/#playerTeam.fighters

    local enemyTeam = self.enemyTeam
    local enemyMiss = 0
    for i=1,#self.enemyTeam.fighters do
        local fighter = enemyTeam.fighters[i]
        enemyMiss = enemyMiss+fighter.miss
    end
    enemyTeam.miss = enemyMiss/#enemyTeam.fighters
end

-- calculateTeamHp
function FightScene:calculateTeamHp()
    local playerTeam = self.playerTeam
    playerTeam.hp = 0;playerTeam.m_hp = 0
    for i=1,#self.playerTeam.fighters do
        local fighter = self.playerTeam.fighters[i]
        playerTeam.m_hp = playerTeam.m_hp + fighter.m_hp
        playerTeam.hp = playerTeam.hp + fighter.hp
    end

    local enemyTeam = self.enemyTeam
    enemyTeam.hp = 0;enemyTeam.m_hp = 0
    for i=1,#self.enemyTeam.fighters do
        local fighter = self.enemyTeam.fighters[i]
        enemyTeam.m_hp = enemyTeam.m_hp + fighter.m_hp
        enemyTeam.hp = enemyTeam.hp + fighter.hp
    end
end

-- runTeamHpAction
function FightScene:calculateTeamHpAndRunAction()
    local old_hp = self.playerTeam.hp
    local old_ehp = self.enemyTeam.hp

    self:calculateTeamHp()

    if old_hp ~= self.playerTeam.hp then
        local call = cc.CallFunc:create(function()
            self.label_hp:setString(tostring(self.playerTeam.hp).."/"..tostring(self.playerTeam.m_hp))
        end)
        local scale = cc.ScaleTo:create(0.1, self.playerTeam.hp/self.playerTeam.m_hp, 1.0)
        local action = cc.Sequence:create(call, scale)
        self.hp:runAction(action)
    end
    if old_ehp ~= self.enemyTeam.hp then
        local call = cc.CallFunc:create(function()
            self.label_ehp:setString(tostring(self.enemyTeam.hp).."/"..tostring(self.enemyTeam.m_hp))
        end)
        local scale = cc.ScaleTo:create(0.1, self.enemyTeam.hp/self.enemyTeam.m_hp, 1.0)
        local action = cc.Sequence:create(call, scale)
        self.ehp:runAction(action)
    end


end

-- 玩家角色攻击
function FightScene:playerAttack()
    for i=1,#self.playerTeam.fighters do
        local attacker = self.playerTeam.fighters[i]
        for j=1,#self.enemyTeam.fighters do
            local defender = self.enemyTeam.fighters[j]
            local done = self:attack(attacker, defender)
            if done then return end
        end
    end
end

-- 敌人攻击
function FightScene:enemyAttack()
    for i=1,#self.enemyTeam.fighters do
        local attacker = self.enemyTeam.fighters[i]
        for j=1,#self.playerTeam.fighters do
            local defender = self.playerTeam.fighters[j]
            local done = self:attack(attacker, defender)
            if done then return end
        end
    end
end

-- 攻击逻辑
function FightScene:attack(attacker, defender)
    local soilderCsv = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
    local skillCsv = DataManager:getInstance():getCSVByID(csvOfSkillAttribute)
    local soilderData = soilderCsv[tostring(attacker.soilderId)]
    local skillData = skillCsv[tostring(soilderData.skill)]
    if attacker.alive and defender.alive and attacker:canAttack() then
        if (defender.hp <= 0 and (self.fightMode == FightScene.FightMode.allInOne)) then
            return false
        end
        -- 判定是否命中
        local miss,isMiss
        if attacker.teamType == Fighter.TeamType.enemyTeam then
            miss = self.playerTeam.miss
        else
            miss = self.enemyTeam.miss
        end
        local hit = 100
        if attacker.teamType == Fighter.TeamType.playerTeam then
            hit = hit + fdm.bonusAttribute.hits
--            cclog("hit = "..tostring(hit)..", miss = "..tostring(miss))
        end
        local missRate = math.floor(miss/(miss+hit)*100)  -- 闪避率%=被攻击方闪避平均值/（攻击方命中（恒定为100）+ 被攻击方闪避平均值)
        local rand = math.random(1, 100)
        isMiss = missRate >= rand
        -- 回血技能不会miss
        if skillData ~= nil and skillData.type == "2" then
            isMiss = false
        end
        if (not isMiss) or (self.fightType == FightScene.FightType.shipWar) then  -- 命中（船战必然命中）
            local damage = attacker.atk*attacker.skillRatio-defender.damageReduction
            damage = math.floor(damage)
            if damage <= 0 then damage = 1 end -- 减伤可能导致伤害变负数，这里小于等于零都强制为1
            if skillData == nil or skillData.type ~= "2" then
                self:calculateDamage(damage, defender.teamType)
            elseif skillData ~= nil and skillData.type == "2" then
                self:calculateHeal(damage, attacker.teamType)
            end
            -- 添加buffer
            if self.fightType == FightScene.FightType.aboardWar and attacker.teamType == Fighter.TeamType.playerTeam then
                local csvData = DataManager:getInstance():getCSVByID(csvOfBuff)
                local data = csvData[tostring(attacker.bufferId)]
                if data then
                    local buffer = FightBufferData.new()
                    buffer.type = math.floor(tonumber(data.type))
                    buffer.duration = tonumber(data.duration)
                    buffer.attack = tonumber(data.attack)
                    buffer.weak = tonumber(data.weak)
                    buffer.icon = data.icon
                    buffer.settleCyc = 1.02
                    self:addBuffer(buffer)
                end
            end

            -- 音效
            if DataManager:getInstance():getSound_off() == 0 then
                if self.fightType == FightScene.FightType.aboardWar then
                    if attacker.teamType == Fighter.TeamType.playerTeam then
                        if skillData ~= nil and skillData.audioType ~= nil then
                            if skillData.audioType == "1" then
                                AudioEngine.playEffect(EFFECT_attack, false)
                            elseif skillData.audioType == "2" then
                                AudioEngine.playEffect(EFFECT_magic, false)
                            elseif skillData.audioType == "3" then
                                AudioEngine.playEffect(EFFECT_addhp, false)
                            elseif skillData.audioType == "4" then
                                AudioEngine.playEffect(EFFECT_paoji, false)
                            else
                                -- do nothing
                            end
                        end
                    else
                        AudioEngine.playEffect(EFFECT_mattack, false)
                    end
                else
                    AudioEngine.playEffect(EFFECT_paoji, false)
                end
            end

            -- 攻击效果
            self:runAttackEffect(attacker.teamType, attacker.teamIndex)

            -- 受击效果
            if self.fightType == FightScene.FightType.aboardWar then
                if attacker.teamType == Fighter.TeamType.playerTeam then
                    self.isBossInjured = true
                    local rand = math.random(1, 100)
                    if rand <= 20 then -- boss被攻击时时有20%的概率说话
                        self:showMonasterDialogue(2)
                    end
                end
                local color = cc.c3b(255, 0, 0)
                if skillData ~= nil and skillData.type == "2" then
                    self:runInjuredEffect(attacker.teamType, attacker.teamIndex, "+"..tostring(damage), skillData, cc.c3b(0, 255, 0))
                else
                    self:runInjuredEffect(defender.teamType, defender.teamIndex, "-"..tostring(damage), skillData)
                end
                self:shakeEffect(self.shipNodePlayer, defender.teamType)
            elseif self.fightType == FightScene.FightType.shipWar then
                self:runInjuredEffect(defender.teamType, defender.teamIndex, "-"..tostring(damage))
            end
        else
            -- 攻击效果
            self:runAttackEffect(attacker.teamType, attacker.teamIndex)
            -- miss效果
            self:runMissEffect(defender.teamType, defender.teamIndex)
        end
        -- 更新血条
        self:calculateTeamHpAndRunAction()

        -- 重置攻击时间
        attacker.lastAtkTime = getSystemTimeMilliSecond()
        return true
    end
    return false
end

-- 计算伤害 damage:造成伤害值  teamType:被伤害的Team
function FightScene:calculateDamage(damage, teamType)
    local fighters
    if teamType == Fighter.TeamType.enemyTeam then
        fighters = self.enemyTeam.fighters
    else
        fighters = self.playerTeam.fighters
    end
    for i=1,#fighters do
        local fighter = fighters[i]
        if fighter.hp > 0 then
            local hp = fighter.hp
            fighter.hp = hp-damage
            if fighter.hp < 0 then
                fighter.hp = 0
                damage = damage-hp
                if self.fightMode == FightScene.FightMode.oneByOne and teamType == Fighter.TeamType.enemyTeam then
                    fighter.alive = false
                    -- 死亡音效
                    if DataManager:getInstance():getSound_off() == 0 then
                        AudioEngine.playEffect(EFFECT_mdead, false)
                    end
                end
            else
                return
            end
        end
    end
end

-- 计算恢复 heal:恢复  teamType:被恢复的Team
function FightScene:calculateHeal(heal, teamType)
    local fighters
    if teamType == Fighter.TeamType.enemyTeam then
        fighters = self.enemyTeam.fighters
    else
        fighters = self.playerTeam.fighters
    end
    for i=1,#fighters do
        local fighter = fighters[i]
        if fighter.hp < fighter.m_hp then
            local hp = fighter.m_hp-fighter.hp
            fighter.hp = fighter.hp+heal
            if fighter.hp > fighter.m_hp then fighter.hp = fighter.m_hp end
            heal = heal-hp
            if heal <= 0 then
                return
            end
        end
    end
end

-- 秒杀逻辑
function FightScene:miaoshaAttack(attacker, defender)
    for i=1,#self.enemyTeam.fighters do
        local fighter = self.enemyTeam.fighters[i]
        local hp = fighter.hp
        if fighter then fighter.hp = 0;fighter.alive=false end
        local actor = self.shipWarEffectNodeEnemy
        self:injuredEffect(actor, "-"..tostring(hp))
        self:calculateTeamHpAndRunAction()
    end
end

-- 播放攻击特效
function FightScene:runAttackEffect(teamType, teamIndex)
    local actor
    if teamType == Fighter.TeamType.playerTeam then
        actor = self.playerActors[teamIndex]
    else
        actor = self.enemyActors[teamIndex]
    end
    if actor then
        if self.fightType == FightScene.FightType.aboardWar then
            if self.isBossInjured then return end
            local tmp = actor:getScale()
            local scale1 = cc.ScaleTo:create(0.2, 3.0*tmp)
            local fade1 = cc.FadeOut:create(0.2)
            local spawn = cc.Spawn:create(scale1, fade1)
            local scale2 = cc.ScaleTo:create(0.0, 1.0*tmp)
            local fade2 = cc.FadeIn:create(0.0)
            local action = cc.Sequence:create(spawn, scale2, fade2)
            actor:runAction(action)
        elseif self.fightType == FightScene.FightType.shipWar then
            local scale1 = cc.ScaleTo:create(0.1, self.paoScale[teamIndex], 0.8*self.paoScale[teamIndex])
            local delay1 = cc.DelayTime:create(0.0)
            local scale2 = cc.ScaleTo:create(0.0, self.paoScale[teamIndex], 1.2*self.paoScale[teamIndex])
            local delay2 = cc.DelayTime:create(0.1)
            local scale3 = cc.ScaleTo:create(0.0, self.paoScale[teamIndex], self.paoScale[teamIndex])
            local action = cc.Sequence:create(scale1, delay1, scale2, delay2, scale3)
            actor:runAction(action)

            -- 炮火效果
            if self.isShowEffect then
                local delay = cc.DelayTime:create(0.1)
                local call = cc.CallFunc:create(function()
                    local animation = EffectUtil:createAnimation("Effect/Animation/chuanzhankaihuo.plist", 1)
                    if teamType == Fighter.TeamType.playerTeam then
                        animation:setPosition(0.5*actor:getContentSize().width, actor:getContentSize().height-10.0)
                        animation:setAnchorPoint(cc.p(0.5, 0.0))
                    else
                        animation:setPosition(0.5*actor:getContentSize().width, 10.0)
                        animation:setAnchorPoint(cc.p(0.5, 1.0))
                        animation:setFlippedY(true)
                    end
                    animation:setScale(1.5)
                    actor:addChild(animation)
                end)
                local action = cc.Sequence:create(delay, call)
                actor:runAction(action)
            end
        end
    end
end

-- 播放受伤特效
function FightScene:runInjuredEffect(teamType, teamIndex, str, skilldata, color)
    local actor,actor1
    if self.fightType == FightScene.FightType.shipWar then
        if teamType == Fighter.TeamType.playerTeam then
            actor = self.shipNodePlayer
        else
            actor = self.shipNodeEnemy
        end
        if teamType == Fighter.TeamType.playerTeam then
            self:injuredEffect(self.shipWarEffectNodePlayer, str)
        elseif teamType == Fighter.TeamType.enemyTeam then
            self:injuredEffect(self.shipWarEffectNodeEnemy, str)
        end
        self:shakeEffect(actor, teamType)
    elseif self.fightType == FightScene.FightType.aboardWar then
        if teamType == Fighter.TeamType.playerTeam then
            actor = self.shipWarEffectNodePlayer
            -- 被攻击船动人不动
--            actor1 = self.playerActors[teamIndex]
        else
            actor = self.shipWarEffectNodeEnemy
            actor1 = self.enemyActors[teamIndex]
        end
        if skilldata then
            if self.isShowEffect then
                if skilldata.fileName and string.len(skilldata.fileName) > 2 then
                    self:runAnimationEffect(teamType, teamIndex, skilldata)
                end
                if skilldata.particle and string.len(skilldata.particle) > 2 then
                    self:runParticleEffect(teamType, teamIndex, skilldata)
                end
            end
        end
        self:injuredEffect(actor, str, color)
        self:shakeEffect(actor1, teamType)
    end

end

-- 受伤特效
function FightScene:injuredEffect(actor, str, color)
    if color == nil then color = cc.c3b(255, 0, 0) end
    if actor then
        -- 闪红
--        local tint1 = cc.TintTo:create(0.2, 255, 0, 0)
--        local tint2 = cc.TintTo:create(0.0, 255, 255, 255)
--        local actionFlash = cc.Sequence:create(tint1, tint2)
--        actor:runAction(actionFlash)

        local children = actor:getChildren()
        for i=1,#children do
            local node = children[i]
            if node and node:getTag()>1 then
                local tmp = math.ceil((node:getPositionY()-0.5*actor:getContentSize().height)/50.0)
                if tmp < 1 then tmp = 1 end
                node:setPositionY(tmp*50.0)
            end
        end

        -- 飘数字
        local number = cc.LabelTTF:create(str, BoldFont, 50.0)
        number:setTag(2)
        number:setColor(color)
        number:setPosition(0.5*actor:getContentSize().width, 0.5*actor:getContentSize().height)
        actor:addChild(number)

        local move = cc.MoveBy:create(1.0, cc.p(0.0, 120.0))
        local scale = cc.ScaleTo:create(1.0, 1.0)
        local fade = cc.FadeOut:create(1.0)
        local spawn = cc.Spawn:create(move, scale, fade)
        local remove = cc.CallFunc:create(function()
            actor:removeChild(number)
        end)
        local actionLabel = cc.Sequence:create(spawn, remove)
        number:runAction(actionLabel)



    end
end

-- 摇晃特效
function FightScene:shakeEffect(actor, teamType)
    if actor then
        local offset = 20.0
        local positons = {cc.p(0, offset), cc.p(offset, 0), cc.p(0, -offset), cc.p(-offset, 0)}
        local delay = 0.1
        local array = {}
        array[1] = cc.DelayTime:create(delay)
        local i=1
        while #positons ~= 0 do
            i = i+1
            local idx = math.random(1, #positons)
            array[i] = cc.MoveBy:create(0.03, positons[idx])
            table.remove(positons, idx)
        end
        if self.isBossInjured and teamType == Fighter.TeamType.enemyTeam then
            array[#array+1] = cc.CallFunc:create(function()
                self.isBossInjured = false
            end)
        end
        local action = cc.Sequence:create(unpack(array))
        actor:runAction(action)
    end
end

-- 播放miss特效
function FightScene:runMissEffect(teamType, teamIndex)
    local actor
    if self.fightType == FightScene.FightType.shipWar then -- 船战暂无miss
        -- do nothing
    elseif self.fightType == FightScene.FightType.aboardWar then
        if teamType == Fighter.TeamType.playerTeam then
            actor = self.shipWarEffectNodePlayer
        elseif teamType == Fighter.TeamType.enemyTeam then
            actor = self.shipWarEffectNodeEnemy
        end
    end
    self:missEffect(actor)
end

-- miss特效
function FightScene:missEffect(actor)
    if actor then
        -- miss
        local number = cc.LabelTTF:create("miss", BoldFont, 35.0)
        number:setPosition(0.5*actor:getContentSize().width, 0.5*actor:getContentSize().height)
        actor:addChild(number)
        local move = cc.MoveBy:create(1.0, cc.p(0.0, 80.0))
--        local scale = cc.ScaleTo:create(1.0, 0.5)
        local fade = cc.FadeOut:create(1.0)
        local spawn = cc.Spawn:create(move, fade)
        local remove = cc.CallFunc:create(function()
            actor:removeChild(number)
        end)
        local actionLabel = cc.Sequence:create(spawn, remove)
        number:runAction(actionLabel)
    end
end

-- 播放动画特效
function FightScene:runAnimationEffect(teamType, teamIndex, skilldata)
    local actor
    if self.fightType == FightScene.FightType.shipWar then
        -- do nothing
    elseif self.fightType == FightScene.FightType.aboardWar then
        if teamType == Fighter.TeamType.playerTeam then
            if 0 == tonumber(skilldata.effectUnit) then
                actor = self.playerHealActors
            end
        elseif teamType == Fighter.TeamType.enemyTeam then
            if 1 == tonumber(skilldata.effectUnit) then
                actor = self.enemyEffectActors[teamIndex]
            else
                actor = self.playerHealActors
            end
        end
    end
    if self.isShowEffect then self:animationEffect(actor, skilldata) end
end

-- 动画特效
function FightScene:animationEffect(actor, skilldata)
    if actor then
        local fileName
        if skilldata.fileName and string.len(skilldata.fileName) > 2 then
            fileName = "Effect/Animation/"..skilldata.fileName..".plist"
        end
        local effectNum = tonumber(skilldata.effectNum)
        local interval = tonumber(skilldata.frameInveral)
        local scale = tonumber(skilldata.effectScale)

        local array = {}
        for i=1,effectNum do
            local delay = cc.DelayTime:create(interval*0.1*(i-1))
            local callfunc = cc.CallFunc:create(function()
                local offsetX = math.random(0, 200)-100.0
                local offsetY = math.random(0, 200)-100.0
                if 1 == effectNum then offsetX, offsetY = 0, 0 end
                local animation = EffectUtil:createAnimation(fileName, 1)
                animation:setPosition(0.5*actor:getContentSize().width+offsetX, 0.5*actor:getContentSize().height+offsetY)
                animation:setScale(scale)
                actor:addChild(animation)
            end)
            array[i*2-1] = delay
            array[i*2] = callfunc
        end

        local action = cc.Sequence:create(unpack(array))
        actor:runAction(action)

    end
end

-- 播放粒子特效
function FightScene:runParticleEffect(teamType, teamIndex, skilldata)
    local actor
    if self.fightType == FightScene.FightType.shipWar then
        -- do nothing
    elseif self.fightType == FightScene.FightType.aboardWar then
        if teamType == Fighter.TeamType.playerTeam then
            if 0 == tonumber(skilldata.effectUnit) then
                actor = self.playerHealActors
            end
        elseif teamType == Fighter.TeamType.enemyTeam then
            if 1 == tonumber(skilldata.effectUnit) then
                actor = self.enemyEffectActors[teamIndex]
            else
                actor = self.playerHealActors
            end
        end
    end
    if self.isShowEffect then self:particleEffect(actor, skilldata) end
end

-- 粒子特效
function FightScene:particleEffect(actor, skilldata)
    local particleName
    if skilldata.particle and string.len(skilldata.particle) > 2 then
        particleName = "Effect/Particle/"..skilldata.particle..".plist"
    end
    if actor then
        -- particle
        local particle = EffectUtil:createParticle(particleName)
        particle:setPosition(0.5*actor:getContentSize().width, 0.5*actor:getContentSize().height)
        actor:addChild(particle)
    end
end

--　显示怪物对话 -type 1:开局对话 2:被打对话
function FightScene:showMonasterDialogue(type)
    if self.dlgNode and not self.dlgNode:isVisible() and self.dlgLabel then
        local str = ""
        local fighter = self.enemyTeam.fighters[1]
        local soilders = DataManager:getInstance():getCSVByID(csvOfSoilderAttribute)
        local data = soilders[tostring(fighter.soilderId)]
        if type == 1 then
            str = data.talk1[math.random(1, #data.talk1)][1]
        else
            str = data.talk2[math.random(1, #data.talk2)][1]
        end
        if str ~= nil and str ~= "0" then
            self.dlgLabel:setString(str)
            self.dlgNode:setVisible(true)
            local delay = cc.DelayTime:create(1.5)
            local call = cc.CallFunc:create(function() self:hideMonasterDialogue() end)
            self:runAction(cc.Sequence:create(delay, call))
        end
    end
end

--　隐藏怪物对话
function FightScene:hideMonasterDialogue()
    if self.dlgNode and self.dlgLabel then
        self.dlgNode:setVisible(false)
    end
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- FightRewardScene
FightRewardScene = class("FightRewardScene", function ()
    return cc.Scene:create()
end)
FightRewardScene.__index = FightRewardScene

-- data
-- 背包内物品
FightRewardScene.package = {}
-- 奖励物品列表
FightRewardScene.rewardItems = {}
-- 保留物品（不在左边列表显示）
FightRewardScene.reservedItems = {}
-- 背包占用量
FightRewardScene.packageSize = 0
-- 背包容量
FightRewardScene.packageCapicity = 800
-- 战斗结果
FightRewardScene.fightResult = false

-- ui
FightRewardScene.tableview1 = nil
FightRewardScene.tableview2 = nil

-- fightOverCallback
FightRewardScene.fightOverCallback = nil

function FightRewardScene:create(haveDatas, dropDatas)
    local view = FightRewardScene.new()
    if view and view:init(haveDatas, dropDatas) then
        return view
    end
    return nil
end

function FightRewardScene:init(haveDatas, dropDatas)

    self:initData(haveDatas, dropDatas)

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
    self.tableview1:registerScriptHandler(function(view, cell)
        local idx = cell:getTag()
        local item = self.package[idx]
        local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resourceCsv[tostring(item.id)]
        self.packageSize = self.packageSize-tonumber(data.cubage)
        changeListItemNum(self.package, item.id, -1)
        changeListItemNum(self.rewardItems, item.id, 1)
        self.tableview1:reloadData()
        self.tableview2:reloadData()
    end, cc.TABLECELL_TOUCHED)
    self.tableview1:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        local item = self.package[idx]
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resource[tostring(item.id)]
        local cell = view:dequeueCell()
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
        if data and data.iconName and string.len(data.iconName) > 1 then
            local icon = cc.Sprite:create("Images/Icon/"..data.iconName)
            icon:setPosition(50.0, 60.0)
            cell:addChild(icon)
        end

        if data then
            -- labe
            local label = cc.LabelTTF:create(tostring(data.name), BoldFont, 30.0)
            label:setColor(BaseColor)
            label:setPosition(100.0, 75.0)
            label:setAnchorPoint(cc.p(0.0, 0.5))
            cell:addChild(label)
        end

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
        return #self.package
    end, cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self:addChild(self.tableview1)

    -- tableview2
    self.tableview2 = cc.TableView:create(cc.size(250.0, visibleSize.height-300.0))
    self.tableview2:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.tableview2:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.tableview2:setPosition(visibleSize.width-50.0-250.0, 150.0)
    self.tableview2:setDelegate()
    self.tableview2:registerScriptHandler(function(view, cell)
        local idx = cell:getTag()
        local item = self.rewardItems[idx]
        local isGold = "1001" == tostring(item.id)
        local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resourceCsv[tostring(item.id)]
        local isZeroCubage = 0 == tonumber(data.cubage)
        if 0 >= tonumber(data.cubage) or self.packageCapicity >= self.packageSize+tonumber(data.cubage) then
            local num = 1
            if isGold then num = item.num end
            self.packageSize = self.packageSize+num*tonumber(data.cubage)
            if isGold then
                ExploreBagController:getBagController():addCoin(num)
                -- DataManager:getInstance():addCoin(num, false)
                -- ToastUtil:downString("金币＋"..tostring(num))
                changeListItemNum(self.rewardItems, item.id, -num)
            else
                changeListItemNum(self.package, item.id, num)
                changeListItemNum(self.rewardItems, item.id, -num)
            end
            self.tableview1:reloadData()
            self.tableview2:reloadData()
        else
            ToastUtil:downString("您货舱已满，无法拾取更多物品", true)
        end

    end, cc.TABLECELL_TOUCHED)
    self.tableview2:registerScriptHandler(function(view, idx)
        idx = idx+1 -- lua array starts from 1
        local item = self.rewardItems[idx]
        local resource = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resource[tostring(item.id)]
        local cell = view:dequeueCell()
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
        if data and data.iconName and string.len(data.iconName) > 1 then
            local icon = cc.Sprite:create("Images/Icon/"..data.iconName)
            icon:setPosition(50.0, 60.0)
            cell:addChild(icon)
        end

        -- labe
        if data then
            local label = cc.LabelTTF:create(tostring(data.name), BoldFont, 30.0)
            label:setColor(BaseColor)
            label:setPosition(100.0, 75.0)
            label:setAnchorPoint(cc.p(0.0, 0.5))
            cell:addChild(label)
        end

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
    self:addChild(self.tableview2)


    -- closeBtn
    local closeBtn = cc.MenuItemImage:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png")
    closeBtn:registerScriptTapHandler(function()
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        print("结算界面关闭按钮响应",self.isClosed)

        if self.isClosed == true then
            return
        end
        local hasMissionProp = false
        for i=1,#self.rewardItems do
            local item = self.rewardItems[i]
            local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
            local data = resourceCsv[tostring(item.id)]
            if data.carryType == "2" then
                hasMissionProp = true
                break
            end
        end

        if not hasMissionProp then
            -- 放回保留物品
            for i=1,#self.reservedItems do
                local item = self.reservedItems[i]
                changeListItemNum(self.package, item.id, item.num)
            end

            local package = self.package
            self.package = {}
            for i=1,#package do
                local item = package[i]
                self.package[item.id] = item
            end

            DataManager:getInstance():setRoleData(roleBattlePack, self.package, nil)
            if self.fightOverCallback then
                self.fightOverCallback(self.fightResult)
            end
            self.isClosed = true
        else
            ToastUtil:downString("您有重要道具未拾取，无法离开！", true)
        end
    end)
    closeBtn:setPosition(1/3*visibleSize.width-40.0, 60.0)

    -- shiquBtn
    local shiquBtn = cc.MenuItemImage:create("Images/btn/ann03_a.png", "Images/btn/ann03_b.png")
    shiquBtn:registerScriptTapHandler(function()
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        self:pickUpAllRewards()
    end)
    shiquBtn:setPosition(2/3*visibleSize.width+40.0, 60.0)

    local menu1 = cc.Menu:create(closeBtn)
    menu1:setPosition(cc.p(0, 0))
    self:addChild(menu1)
    local menu2 = cc.Menu:create(shiquBtn)
    menu2:setPosition(cc.p(0, 0))
    self:addChild(menu2)

    local close = cc.LabelTTF:create("关闭", BoldFont, 30.0)
    close:setPosition(closeBtn:getPosition())
    self:addChild(close)
    local shiqu = cc.LabelTTF:create("全部拾取", BoldFont, 30.0)
    shiqu:setPosition(shiquBtn:getPosition())
    self:addChild(shiqu)

    local function update()
        capacity:setString("("..tostring(self.packageSize).."/"..tostring(self.packageCapicity)..")")
    end
    self:scheduleUpdateWithPriorityLua(update, 0)

    return true
end

-- initData
function FightRewardScene:initData(haveDatas, dropDatas)

--    cclog("haveDatas = "..json.encode(haveDatas))
--    cclog("dropDatas = "..json.encode(dropDatas))
--
--    for k,v in pairs(haveDatas) do
--        print("type(k) = ", type(k), ", value(k) = ", k, "type(v) = ", type(v), ", value(v) = ", v)
--    end

    self.isClosed = false
    self.package = {}
    self.rewardItems = {}
    self.reservedItems = {}
    self.fightResult = false
    self.packageSize = 0
    self.packageCapicity = DataManager:getInstance():getRoleData(rolePackSize)

    local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)

    local package = DataManager:getInstance():getRoleData(roleBattlePack)

    local idx = 1
    for k,v in pairs(package) do
        local data = resourceCsv[tostring(k)]
        local tmp = clone(v)
        if tmp.num > 0 then
            self.package[idx] = tmp
            self.packageSize = self.packageSize+v.num*tonumber(data.cubage)
            idx = idx+1
        end
    end

    self.rewardItems = clone(fdm.dropData)

    if haveDatas then
        self.package = clone(haveDatas)
    end
    if dropDatas then
        self.rewardItems = clone(dropDatas)
    end

    -- 取出保留物品
    local package1 = self.package
    self.package = {}
    for i=1,#package1 do
        local item = package1[i]
        local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
        local data = resourceCsv[tostring(item.id)]
        local isZeroCubage = 0 == tonumber(data.cubage)
        if isZeroCubage then
            table.insert(self.reservedItems, 1, item)
        else
            table.insert(self.package, 1, item)
        end
    end

    -- test
--    self.rewardItems[#self.rewardItems+1] = {id = 1033, num = 10}

    -- 排序，让占格子最少的在最前面，方便后面的“全部拾取”功能运算
    table.sort(self.rewardItems, function(a, b)
        local dataA = resourceCsv[tostring(a.id)]
        local dataB = resourceCsv[tostring(b.id)]
        return tonumber(dataA.cubage) < tonumber(dataB.cubage)
    end)

    table.sort(self.package, function(a, b)
        local dataA = resourceCsv[tostring(a.id)]
        local dataB = resourceCsv[tostring(b.id)]
        return tonumber(dataA.cubage) < tonumber(dataB.cubage)
    end)


end

-- setFightOverCallback
function FightRewardScene:setFightOverCallback(callback)
    assert(type(callback) == "function")
    self.fightOverCallback = callback
end

function FightRewardScene:setFightResult(result)
    assert(type(result) == "boolean")
    self.fightResult = result

    self.tableview1:reloadData()
    self.tableview2:reloadData()
end

-- pickUpAllRewards
function FightRewardScene:pickUpAllRewards()
    local resourceCsv = DataManager:getInstance():getCSVByID(csvOfResourceInfo)
    local pick = function()
        -- 有可拾取物品
        if 0 >= #self.rewardItems then
            return false
        end
        local data = resourceCsv[tostring(self.rewardItems[1].id)]
        -- 当前类物品数量
        local num = self.rewardItems[1].num
        -- 剩余容量
        local capLeft = self.packageCapicity-self.packageSize
        -- 可全装下
        if num*tonumber(data.cubage) <= capLeft then
            self.packageSize = self.packageSize+num*tonumber(data.cubage)
            local item = self.rewardItems[1]
            local isGold = "1001" == tostring(item.id)
            if isGold then
                ExploreBagController:getBagController():addCoin(num)
                -- DataManager:getInstance():addCoin(num, false)
                -- ToastUtil:downString("金币＋"..tostring(num))
                changeListItemNum(self.rewardItems, item.id, -item.num)
            else
                changeListItemNum(self.package, item.id, item.num)
                changeListItemNum(self.rewardItems, item.id, -item.num)
            end
            self.tableview1:reloadData()
            self.tableview2:reloadData()
            return true
        else -- 只能装一部分
            local getNum
            if 0 >= tonumber(data.cubage) then
                getNum = num
            else
                getNum = math.ceil(capLeft/tonumber(data.cubage))
                if capLeft <= 0 then
                    ToastUtil:downString("您货舱已满，无法拾取更多物品", true)
                    return false
                end
            end
            self.packageSize = self.packageSize+getNum*tonumber(data.cubage)
            local item = self.rewardItems[1]
            local isGold = "1001" == tostring(item.id)
            if isGold then
                ExploreBagController:getBagController():addCoin(getNum)
                -- DataManager:getInstance():addCoin(getNum, false)
                -- ToastUtil:downString("金币＋"..tostring(getNum))
                changeListItemNum(self.rewardItems, item.id, -getNum)
            else
                changeListItemNum(self.package, item.id, getNum)
                changeListItemNum(self.rewardItems, item.id, -getNum)
            end
            self.tableview1:reloadData()
            self.tableview2:reloadData()
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
        ToastUtil:downString("没有可拾取的物品", true)
    end
end





