require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/ToastUtil"
require "LuaClass/ChargeMode"
require "LuaClass/GuideController"
require "LuaClass/DiamondStore"
require "LuaClass/UIKit"
require "LuaClass/BTheme"
require "LuaClass/MasterTheme"


-- Main-menu chrome is deliberately separate from the legacy page theme.
-- The old route buttons remain hidden guide targets; only four groups render.
local MENU_COLORS = {
    ink = cc.c3b(5, 47, 61), paper = cc.c3b(247, 238, 213),
    pale = cc.c3b(224, 226, 205), coral = cc.c3b(239, 102, 72),
    sea = cc.c3b(31, 111, 126), line = cc.c3b(91, 137, 145)
}
local function menuRGBA(color, alpha)
    return cc.c4f(color.r / 255, color.g / 255, color.b / 255, alpha or 1)
end
local function menuLabel(text, size, color, x, y, bold, anchor)
    local label = cc.LabelTTF:create(tostring(text or ""), bold and BoldFont or "Arial", size)
    label:setColor(color); label:setAnchorPoint(cc.p(anchor or 0, 0.5))
    label:setPosition(cc.p(x, y)); return label
end
local function headingFont()
    return MasterTheme.headingFont and MasterTheme.headingFont() or BoldFont
end
local function masterGraphic(name, width, height)
    return MasterTheme.material(name, width, height)
end
local function transparentMenuItem(text, width, height, callback, size, color)
    local clear = {r = 0, g = 0, b = 0, a = 0}
    local normal = BTheme.panel(width, height, clear)
    local pressed = BTheme.panel(width, height, {r = 255, g = 246, b = 214, a = 28})
    local item = cc.MenuItemSprite:create(normal, pressed)
    item:setCascadeOpacityEnabled(true)
    item.bLabel = menuLabel(text, size or 24, color or MENU_COLORS.paper, width / 2, height / 2, false, 0.5)
    item:addChild(item.bLabel, 2)
    item:registerScriptTapHandler(callback)
    return item
end
-- Legacy pages share compact paper currency controls. Their original 59-point
-- targets and purchase callbacks remain independent of the approved Home UI.
local function legacyCurrencyButton(callback)
    local add=transparentMenuItem('+',59,59,callback,28,MENU_COLORS.ink)
    add.bLabel:setFontName(MasterTheme.headingFont(false))
    local chip=MasterTheme.material('currency-paper.png',48,48,cc.c3b(226,222,203))
    chip:setPosition(cc.p(5.5,5.5));add:addChild(chip,1)
    local n=cc.Node:create();n:setContentSize(cc.size(59,59));n:setAnchorPoint(cc.p(.5,.5))
    n:setCascadeOpacityEnabled(true)
    add:setPosition(cc.p(29.5,29.5))
    local menu=cc.Menu:create(add);menu:setPosition(cc.p(0,0));n:addChild(menu)
    n.item=add;n.label=add.bLabel;n.menu=menu
    return n
end
local function legacyCurrencyPaper(node)
    local paper=MasterTheme.material('currency-paper.png',254,42)
    paper:setPosition(cc.p(0,-21));node:addChild(paper,-1)
end
-- Only these approved static ornaments use detail sprites. Dynamic amounts,
-- purchase targets, navigation hitboxes and callbacks remain native components.
local DETAIL_PATH = "Images/UI/Adventure/Master/Details/"
local function detailSprite(name, width, height)
    local path = DETAIL_PATH .. name
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil end
    local sprite = cc.Sprite:create(path)
    if not sprite then return nil end
    -- These small ornaments use bilinear filtering; source crops are already
    -- Lanczos-prefiltered to production resolution (no NPOT mipmap dependency).
    if sprite.getTexture then sprite:getTexture():setAntiAliasTexParameters() end
    local size = sprite:getContentSize()
    sprite:setScale(math.min(width / size.width, height / size.height))
    sprite:setAnchorPoint(cc.p(0.5, 0.5))
    return sprite
end
local function selectedBrush(width, height)
    local sprite = detailSprite("nav-selected-stroke.png", width, height)
    if not sprite then return masterGraphic("coral-brush.png", width, height) end
    local node = cc.Node:create(); node:setContentSize(cc.size(width, height))
    sprite:setPosition(cc.p(width / 2, height / 2)); node:addChild(sprite)
    return node
end
-- Missing assets keep the already-tested native-symbol compatibility fallback.
local function nativeIcon(kind)
    local painted = detailSprite(kind == "coin" and "coin-detail.png" or "gem-detail.png", 34, 34)
    if painted then return painted end
    local node = cc.DrawNode:create()
    if kind == "coin" then
        local gold = menuRGBA(cc.c3b(221,164,47)); local light = menuRGBA(cc.c3b(255,222,125))
        node:drawDot(cc.p(0,0),16,gold); node:drawDot(cc.p(0,0),14,light)
        node:drawDot(cc.p(0,0),12,gold)
        node:drawDot(cc.p(0,3),7,light)
        node:drawDot(cc.p(-3,4),1.7,gold); node:drawDot(cc.p(3,4),1.7,gold)
        node:drawSegment(cc.p(-4,-5),cc.p(4,-5),2.2,light)
    elseif kind == "diamond" then
        local blue = menuRGBA(cc.c3b(23,165,221)); local light = menuRGBA(cc.c3b(123,233,255))
        local p={cc.p(-16,7),cc.p(-9,16),cc.p(10,16),cc.p(17,7),cc.p(0,-17)}
        node:drawPolygon(p,#p,blue,0,blue)
        node:drawSegment(cc.p(-16,7),cc.p(17,7),0.8,light)
        node:drawSegment(cc.p(-6,16),cc.p(0,-17),0.8,light)
        node:drawSegment(cc.p(7,16),cc.p(0,-17),0.8,light)
    end
    return node
end


MainMenuLayer = class("MainMenuLayer", function ()
    return cc.Layer:create()
end)

MainMenuLayer.__index = MainMenuLayer
MainMenuLayer.MainMenuButtonGroup = nil
MainMenuLayer.bIsShowBigInfoBox = false
MainMenuLayer.scrollView = nil
MainMenuLayer.scrollViewContainer = nil

MainMenuLayer.repositoryBtn = nil
MainMenuLayer.resourceBtn = nil
MainMenuLayer.expeditionBtn = nil
MainMenuLayer.buildBtn = nil
MainMenuLayer.makeBtn = nil
MainMenuLayer.trainBtn = nil
MainMenuLayer.storeBtn = nil

MainMenuLayer.btnHLBg = nil

MainMenuLayer.selectedIndex = 0

MainMenuLayer.pointNode = nil

MainMenuLayer.coinNode = nil
MainMenuLayer.diamondNode = nil

MainMenuLayer.bIsStartStory = false
MainMenuLayer.storyQueue = {}

MainMenuLayer.boatSpr = nil

function MainMenuLayer:create()
    local view = MainMenuLayer.new()
    if view and view:init() then
        zqDispatch = view
        return view
    end
    return nil
end

-- 清理函数
function MainMenuLayer:destory()
    if self ~= nil and self:getParent() ~= nil then
        self:closeNavigationGroup()
        DataManager:getInstance():unregisterEvent(roleMoney, "mainmenu")
        DataManager:getInstance():unregisterEvent(roleDiamond, "mainmenu")
        DataManager:getInstance():unregisterEvent("kSystemInfoNeedReload", "mainMenu")
        DataManager:getInstance():unregisterEvent(roleGuideStep, "mainMenu")
        self:removeFromParent()
    end
end

function MainMenuLayer:init()

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    local colors = BTheme.colors
    self.selectedIndex = -1
    self.storyQueue = {}
    self.bIsStartStory = false

    -- Legacy page safe areas are unchanged. The illustrated footer paints only
    -- its own 118-point strip; Home positions its full-scene content separately.
    UITopHeight = 100
    UIBottomHeight = 136
    self.navigationHeight = 118
    local TopBg = BTheme.panel(visibleSize.width, UITopHeight, colors.ink,
        origin.x, origin.y + visibleSize.height - UITopHeight)
    self:addChild(TopBg)
    self.legacyTopBg = TopBg
    local headerWash = MasterTheme.material("ink-brush.png", visibleSize.width, UITopHeight)
    TopBg:addChild(headerWash)
    local headerTitle = MasterTheme.label("港口事务", 28, MENU_COLORS.paper, 24, 71, true)
    TopBg:addChild(headerTitle)
    TopBg:addChild(BTheme.panel(visibleSize.width - 48, 1, colors.sea, 24, 48))

    local function moneyString(value)
        value = tonumber(value) or 0
        return value > 1000000 and math.floor(value / 10000) .. "万" or tostring(value)
    end
    self.coinNode = cc.Node:create()
    self.coinNode:setCascadeOpacityEnabled(true)
    self.coinNode:setPosition(cc.p(origin.x + 24, origin.y + visibleSize.height - 77))
    self:addChild(self.coinNode)
    legacyCurrencyPaper(self.coinNode)
    local coinIcon = nativeIcon("coin");coinIcon:setPosition(cc.p(20,0));self.coinNode:addChild(coinIcon)
    local coinLabel = BTheme.label(moneyString(DataManager:getInstance():getRoleData(roleMoney)), 24, MENU_COLORS.ink, 56, 0)
    coinLabel:setFontName(MasterTheme.headingFont(false))
    self.coinNode:addChild(coinLabel)
    self.coinValueLabel = coinLabel
    DataManager:getInstance():registerEvent(roleMoney, "mainmenu", function()
        coinLabel:setString(moneyString(DataManager:getInstance():getRoleData(roleMoney)))
        BTheme.fitLabel(coinLabel, 142)
        if self.homeCoinLabel then self.homeCoinLabel:setString(moneyString(DataManager:getInstance():getRoleData(roleMoney))); BTheme.fitLabel(self.homeCoinLabel,72) end
    end)
    BTheme.fitLabel(coinLabel, 142)
    local addCoinBtn = legacyCurrencyButton(function()
        DataManager:getInstance():showBuyGoldBox()
    end)
    addCoinBtn:setPosition(cc.p(224, 0))
    self.coinNode:addChild(addCoinBtn)

    self.diamondNode = cc.Node:create()
    self.diamondNode:setCascadeOpacityEnabled(true)
    self.diamondNode:setPosition(cc.p(origin.x + visibleSize.width * 0.53, self.coinNode:getPositionY()))
    self:addChild(self.diamondNode)
    legacyCurrencyPaper(self.diamondNode)
    local diamondIcon = nativeIcon("diamond");diamondIcon:setPosition(cc.p(20,0));self.diamondNode:addChild(diamondIcon)
    local diamondLabel = BTheme.label(moneyString(DataManager:getInstance():getRoleData(roleDiamond)), 24, MENU_COLORS.ink, 56, 0)
    diamondLabel:setFontName(MasterTheme.headingFont(false))
    self.diamondNode:addChild(diamondLabel)
    self.diamondValueLabel = diamondLabel
    DataManager:getInstance():registerEvent(roleDiamond, "mainmenu", function()
        diamondLabel:setString(moneyString(DataManager:getInstance():getRoleData(roleDiamond)))
        BTheme.fitLabel(diamondLabel, 142)
        if self.homeDiamondLabel then self.homeDiamondLabel:setString(moneyString(DataManager:getInstance():getRoleData(roleDiamond))); BTheme.fitLabel(self.homeDiamondLabel,65) end
    end)
    BTheme.fitLabel(diamondLabel, 142)
    local addDiamondBtn = legacyCurrencyButton(function() ChargeLayer:create() end)
    addDiamondBtn:setPosition(cc.p(224, 0))
    self.diamondNode:addChild(addDiamondBtn)

    local BottomBg = BTheme.panel(visibleSize.width, self.navigationHeight, MENU_COLORS.ink, origin.x, origin.y)
    self:addChild(BottomBg)
    self.navigationBg = BottomBg
    local ink = masterGraphic("ink-brush.png", visibleSize.width, self.navigationHeight + 6)
    if ink then ink:setPosition(cc.p(0, 0)); BottomBg:addChild(ink) end
    self.navigationCaption = menuLabel("港口设施", 15, colors.pale, 24, 118)
    self.navigationCaption:setVisible(false); BottomBg:addChild(self.navigationCaption)
    self.pointNode = cc.Node:create(); BottomBg:addChild(self.pointNode)

    -- Preserve every legacy field and guide target, but never render the old
    -- eight-tab bar. Guide fades must not hide the four permanent groups.
    self.MainMenuButtonGroup = cc.Node:create()
    self.MainMenuButtonGroup:setCascadeOpacityEnabled(true)
    self.MainMenuButtonGroup:setVisible(false)
    BottomBg:addChild(self.MainMenuButtonGroup)
    local legacyNames = {"整备", "招募", "建设", "仓库", "制造", "采集", "市场"}
    local fields = {"expeditionBtn", "trainBtn", "buildBtn", "repositoryBtn", "makeBtn", "resourceBtn", "storeBtn"}
    local legacyButtons = {}
    for index = 0, 7 do
        local route = index
        local button = BTheme.menuItem(index == 0 and "基地" or legacyNames[index], 72, 86,
            function() self:openRoute(route) end, {fontSize = 23})
        button:setPosition(cc.p(visibleSize.width / 8 * (index + 0.5), 56))
        if index == 0 then self.homeBtn = button else self[fields[index]] = button end
        legacyButtons[#legacyButtons + 1] = button
    end
    local legacyMenu = cc.Menu:create(unpack(legacyButtons))
    legacyMenu:setPosition(cc.p(0, 0)); self.MainMenuButtonGroup:addChild(legacyMenu)
    self.btnHLBg = BTheme.panel(52, 4, colors.coral)
    self.MainMenuButtonGroup:addChild(self.btnHLBg)

    self.groupNavigation = cc.Node:create(); BottomBg:addChild(self.groupNavigation, 2)
    self.navigationButtons = {}; self.navigationBrushes = {}
    local groupNames = {"基地", "航行", "船员", "港务"}
    local groupIcons = {"anchor", "sail", "crew", "port"}
    local groupCallbacks = {
        function() self:openRoute(0) end, function() self:openRoute(1) end,
        function() self:openNavigationGroup("crew") end,
        function() self:openNavigationGroup("port") end
    }
    local spacing = visibleSize.width / 4
    for index = 1, 4 do
        local item = transparentMenuItem(groupNames[index], spacing, self.navigationHeight,
            groupCallbacks[index], 23, MENU_COLORS.paper)
        item:setPosition(cc.p(spacing * (index - 0.5), self.navigationHeight / 2))
        item.bLabel:setPosition(cc.p(spacing / 2, 38))
        local icon = MasterTheme.icon(groupIcons[index], 48, MENU_COLORS.paper)
        icon:setPosition(cc.p(spacing / 2 - 24, 62)); item:addChild(icon)
        local brush = selectedBrush(50, 7)
        brush:setPosition(cc.p(spacing / 2 - 25, 54)); item:addChild(brush)
        self.navigationButtons[index] = item; self.navigationBrushes[index] = brush
        if index < 4 then
            local rule = cc.DrawNode:create()
            rule:drawSegment(cc.p(spacing * index,30),cc.p(spacing * index,96),0.4,menuRGBA(MENU_COLORS.line,0.65))
            self.groupNavigation:addChild(rule)
        end
    end
    local groupMenu = cc.Menu:create(unpack(self.navigationButtons))
    groupMenu:setPosition(cc.p(0, 0)); self.groupNavigation:addChild(groupMenu)
    self:activeButtonWithIndex(0)

    -- 单独添加一个建造按钮的气泡提示
    -- local buildBtnAlertSpr = cc.Sprite:create("Images/UI/BuildAlert.png")
    -- buildBtnAlertSpr:setScale(0.66)
    -- buildBtnAlertSpr:setPosition(cc.p(self.buildBtn:getPositionX() + buildBtnAlertSpr:getContentSize().width * buildBtnAlertSpr:getScale() * 0.26, self.buildBtn:getPositionY() + buildBtnAlertSpr:getContentSize().height * 0.8))
    -- self.MainMenuButtonGroup:addChild(buildBtnAlertSpr, 10)
    -- buildBtnAlertSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(1.6, cc.p(0, -10)), cc.MoveBy:create(1.6, cc.p(0, 10)))))
    -- buildBtnAlertSpr:setVisible(false)

    -- Keep UIBottomHeight at the legacy 136-point safe area for old pages.

    -- 添加信息框文字的显示节点
    -- local InfoNode = cc.Node:create()
    -- InfoNode:setPosition(cc.p(InfoBg:getContentSize().width * 0.5, InfoBg:getContentSize().height * 0.5))
    -- InfoBg:addChild(InfoNode)

    DataManager:getInstance():registerEvent("kSystemInfoNeedReload", "mainMenu", function()
        cclog("刷新系统信息显示")
        if nil ~= pNeedUpdateLayer then
            pNeedUpdateLayer:updateInfoLabel(DataManager:getInstance():getSystemInfoString())
        end
    end)

    local finger = nil
    local function MainMenuDidGuideChange()
        cclog("mainMenu新手引导步骤变化")
        -- 制造了仓库之后的操作
        if GuideController:getInstance():getIsHaveStep(2) then
            self.repositoryBtn:setVisible(true)
            self.repositoryBtn:setOpacity(255.0)
            self.btnHLBg:setVisible(true)
            -- 建设完仓库之后其实资源就也解锁了，so
            self.resourceBtn:setVisible(true)
            self.resourceBtn:setOpacity(255.0)
            -- 判断是不是没点击过资源按钮的状态，如果是没点过，那么显示红点
            if GuideController:getInstance():getIsHaveStep(5, true) then
                -- 干掉按钮的红点
                GuideController:getInstance():removeRedPoint(self.resourceBtn)
            else
                -- 添加按钮的红点
                GuideController:getInstance():addRedPoint(self.resourceBtn)
            end
        else
            self.repositoryBtn:setVisible(true)
            self.repositoryBtn:setOpacity(51.0)
            self.btnHLBg:setVisible(false)

            self.resourceBtn:setVisible(true)
            self.resourceBtn:setOpacity(51.0)
        end

        -- 建设完船坞之后的操作
        if GuideController:getInstance():getIsHaveStep(8) then
            self.expeditionBtn:setVisible(true)
            self.expeditionBtn:setOpacity(255.0)
            -- 判断是不是没点击过制造按钮的状态，如果是没点过，那么显示红点
            if GuideController:getInstance():getIsHaveStep(6, true) then
                -- 干掉按钮的红点
                GuideController:getInstance():removeRedPoint(self.expeditionBtn)
                -- 干掉小手
                if finger ~= nil then
                    finger:removeFromParent()
                    finger = nil
                end
            else
                -- 添加按钮的红点
                GuideController:getInstance():addRedPoint(self.expeditionBtn)
                -- 如果没有走过，那么显示小手指引
                if not GuideController:getInstance():getIsHaveStep(105, true) then
                    -- 添加引导的小手动画, 进入出征界面之后消失~
                    if finger ~= nil then finger:removeFromParent(); finger = nil end
                    finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
                    finger:setAnchorPoint(0, 1)
                    finger:setScale(0.8)
                    local sailButton = self.navigationButtons[2]
                    finger:setPosition(cc.p(sailButton:getPositionX(), self.navigationHeight - 2))
                    self.groupNavigation:addChild(finger, 9999)

                    local spriteFrame = cc.SpriteFrameCache:getInstance()
                    for i = 1, 2 do
                        local sprName = string.format("Images/Map/Guide/finger_%d.png", i)
                        local tempSprite = cc.Sprite:create(sprName)
                        if tempSprite ~= nil then
                            spriteFrame:addSpriteFrame(tempSprite:getSpriteFrame(), sprName)
                        end
                    end
                    local touchAni = EffectUtil:getAnimate("Images/Map/Guide/finger_%d.png", 1, 2, 0.3)
                    finger:runAction(cc.RepeatForever:create(touchAni))
                end
            end
        else
            self.expeditionBtn:setVisible(true)
            self.expeditionBtn:setOpacity(51.0)
        end
        -- 当制造有解锁之后的操作
        if GuideController:getInstance():getIsHaveStep(10) then
            self.makeBtn:setVisible(true)
            self.makeBtn:setOpacity(255.0)
            -- 判断是不是没点击过制造按钮的状态，如果是没点过，那么显示红点
            if GuideController:getInstance():getIsHaveStep(2, true) then
                -- 干掉按钮的红点
                GuideController:getInstance():removeRedPoint(self.makeBtn)
            else
                -- 添加按钮的红点
                GuideController:getInstance():addRedPoint(self.makeBtn)
            end
        else
            self.makeBtn:setVisible(true)
            self.makeBtn:setOpacity(51.0)
        end
        -- 建设完训练营之后的操作
        if GuideController:getInstance():getIsHaveStep(9) then
            self.trainBtn:setVisible(true)
            self.trainBtn:setOpacity(255.0)
            -- 判断是不是没点击过练兵按钮的状态，如果是没点过，那么显示红点
            if GuideController:getInstance():getIsHaveStep(3, true) then
                -- 干掉按钮的红点
                GuideController:getInstance():removeRedPoint(self.trainBtn)
            else
                -- 添加按钮的红点
                GuideController:getInstance():addRedPoint(self.trainBtn)
            end
        else
            self.trainBtn:setVisible(true)
            self.trainBtn:setOpacity(51.0)
        end
        -- 建设完商城之后的操作
        if GuideController:getInstance():getIsHaveStep(5) then
            self.storeBtn:setVisible(true)
            self.storeBtn:setOpacity(255.0)
            -- 判断是不是没点击过商城按钮的状态，如果是没点过，那么显示红点
            if GuideController:getInstance():getIsHaveStep(4, true) then
                -- 干掉按钮的红点
                GuideController:getInstance():removeRedPoint(self.storeBtn)
            else
                -- 添加按钮的红点
                GuideController:getInstance():addRedPoint(self.storeBtn)
            end
        else
            self.storeBtn:setVisible(true)
            self.storeBtn:setOpacity(51.0)
        end
        -- 点击了炼金按钮之后的操作
        if GuideController:getInstance():getIsHaveStep(1) then
            -- 显示4个按钮
            self.buildBtn:setVisible(true)
            
            if not GuideController:getInstance():getIsHaveStep(101, true) then
                -- 设置7个按钮的visible为true
                self.buildBtn:setVisible(true)
                self.makeBtn:setVisible(true)
                self.trainBtn:setVisible(true)
                self.storeBtn:setVisible(true)
                self.expeditionBtn:setVisible(true)
                self.repositoryBtn:setVisible(true)
                self.resourceBtn:setVisible(true)
                -- 播放建设解锁动画
                self.buildBtn:setOpacity(51.0)
                
                -- buildBtnAlertSpr:setVisible(true)
                -- buildBtnAlertSpr:setOpacity(0.0)
                -- buildBtnAlertSpr:runAction(cc.Sequence:create(cc.FadeOut:create(0.0), cc.DelayTime:create(1.4), cc.FadeIn:create(0.6)))
                self.buildBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0), cc.DelayTime:create(0.3), cc.FadeTo:create(0.6, 255.0)))
                self.makeBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                self.trainBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                self.storeBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                self.expeditionBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                self.repositoryBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                self.resourceBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
                -- 播放建设解锁剧情
                local storyStr = {"建设已解锁！", "点击底部“港务”，再选择“建设”。"}
                self:playStory(storyStr)
                GuideController:getInstance():addStep(101, true)
            else
                -- 判断是不是没点击过建设按钮的状态，如果是没点过，那么显示红点
                if GuideController:getInstance():getIsHaveStep(1, true) then
                    -- 干掉按钮的红点和气泡
                    GuideController:getInstance():removeRedPoint(self.buildBtn)
                    -- buildBtnAlertSpr:setVisible(false)
                    -- print("MainMenu移除了红点。。。。")
                else
                    -- 添加按钮的红点
                    -- if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil then
                        GuideController:getInstance():addRedPoint(self.buildBtn)
                    -- else
                    --     buildBtnAlertSpr:setVisible(true)
                    -- end
                    -- print("MainMenu增加了红点。。。。")
                end
            end
        else
            -- 设置7个按钮的visible为false
            self.buildBtn:setVisible(false)
            self.makeBtn:setVisible(false)
            self.trainBtn:setVisible(false)
            self.storeBtn:setVisible(false)
            self.expeditionBtn:setVisible(false)
            self.repositoryBtn:setVisible(false)
            self.resourceBtn:setVisible(false)

            -- 并且显示刚一进来的剧情对话
            -- local storyStr = {"你睁开双眼，发现身处荒岛", "唯有一艘残破的海盗船", "船上仅有一个神秘的炼金法阵..."}
            -- self:playStory(storyStr)
            TopBg:setOpacity(0.0)
            self.coinNode:setOpacity(0.0)
            self.diamondNode:setOpacity(0.0)
            self.MainMenuButtonGroup:setOpacity(0.0)

            self.coinNode:runAction(cc.FadeOut:create(0.0))
            self.diamondNode:runAction(cc.FadeOut:create(0.0))

            function playStep4()
                -- 显示第二句话
                DataManager:getInstance():sendSystemInfo("现在多使用几次，制造10枚金币吧！")
            end

            function playStep3()
                -- 显示第一句话，然后延迟显示后两句话
                DataManager:getInstance():sendSystemInfo("当你缺少金币的时候，可以点击法阵无限获取！")
                self.MainMenuButtonGroup:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.CallFunc:create(playStep4)))
            end

            function playStep2()
                -- 最后一步，显示文字，然后显示出下方炼金按钮、海盗船以及下方的炼金法阵
                DataManager:getInstance():sendSystemInfo("以及一个神秘的炼金法阵")
                self.MainMenuButtonGroup:runAction(cc.Sequence:create(cc.DelayTime:create(1.6), cc.FadeIn:create(0.6), cc.CallFunc:create(playStep3)))
            end

            function playStep1()
                -- 第一步，显示文字，然后显示出海盗船图
                DataManager:getInstance():sendSystemInfo("唯有一艘残破的海盗船")
                self.coinNode:runAction(cc.Sequence:create(cc.DelayTime:create(3.6), cc.CallFunc:create(playStep2)))

                -- 第二步，显示出金币组和钻石组来
                self.coinNode:runAction(cc.Sequence:create(cc.DelayTime:create(2.6), cc.FadeIn:create(0.6)))
                self.coinNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.DelayTime:create(2.6), cc.EaseExponentialIn:create(cc.ScaleTo:create(0.6, 1.0))))

                self.diamondNode:runAction(cc.Sequence:create(cc.DelayTime:create(2.6), cc.FadeIn:create(0.6)))
                self.diamondNode:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.DelayTime:create(2.6), cc.EaseExponentialIn:create(cc.ScaleTo:create(0.6, 1.0))))
            end

            function playStep()
                -- 首先，显示文字，然后显示顶部背景条
                DataManager:getInstance():sendSystemInfo("你睁开双眼，发现身处荒岛")
                -- 显示顶部菜单背景
                TopBg:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.FadeIn:create(1.6), cc.CallFunc:create(playStep1)))
            end
            -- 一步一步的播放剧情
            cclog("开始播放新手引导内容")
            playStep()
        end

        -- -- 判断是不是没点击过返回按钮的状态，如果是没点过，那么显示红点
        -- if GuideController:getInstance():getIsHaveStep(7, true) then
        --     -- 干掉按钮的红点
        --     GuideController:getInstance():removeRedPoint(backBtn)
        -- else
        --     -- 添加按钮的红点
        --     GuideController:getInstance():addRedPoint(backBtn)
        -- end
        -- 这玩意现在不走了，所以必须在这里调用一下
        self:playUnlockAni()
        self:updateGroupedGuideState()
    end
    DataManager:getInstance():registerEvent(roleGuideStep, "mainMenu", MainMenuDidGuideChange)

    -- 这里要判断新手引导走过之后调用才合理，不调用还不行，要不从战斗出来就不显示下边按钮了
    -- if GuideController:getInstance():getIsHaveStep(1) then
        MainMenuDidGuideChange()
    -- end

    -- Decorative only: a moving paid button can cover Home's primary actions.
    -- Paid offers remain opt-in through the fixed, labelled Port entry.
    local boatArt = cc.Sprite:create("Images/DiamondStore/GoldenBoat.png")
    self.boatSpr = cc.Node:create()
    self.boatSpr:setPosition(cc.p(visibleSize.width + boatArt:getContentSize().width * 0.5, UIBottomHeight + boatArt:getContentSize().height * 0.5))
    self:addChild(self.boatSpr, 9999)

    boatArt:setPosition(cc.p(0, 0))
    self.boatSpr:addChild(boatArt)

    local function playBoatRun()
        -- body
        self.boatSpr:setPosition(cc.p(visibleSize.width + boatArt:getContentSize().width * 0.5, UIBottomHeight + boatArt:getContentSize().height * 0.5))
        self.boatSpr:runAction(cc.MoveTo:create(10.0, cc.p(-boatArt:getContentSize().width * 0.5, self.boatSpr:getPositionY())))
    end

    -- Returning home never interrupts play with a paid offer. The same gift
    -- remains available deliberately through the fixed Port entry.
    -- 出征之后才会显示金船走过 by 杨杰 厉晔的需求
    if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil then
        self:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(60.0), cc.CallFunc:create(playBoatRun))))
    end

    -- 刷新跟新手引导解锁有关的内容
    self:playUnlockAni()

    -- local RichText = SNSColorfulLabel:create()
    -- RichText:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height * 0.5))
    -- self:addChild(RichText)
    
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    return true
end

-- 根据传进来的对话内容，播放剧情
function MainMenuLayer:playStory(storyArr)
    -- body
    for i = 1, #storyArr do
        table.insert(self.storyQueue, storyArr[i])
    end
    local index = 1
    local function runStorys()
        self.bIsStartStory = true
        -- cclog("开始走剧情啦~"..index)
        if index > #self.storyQueue then
            self.bIsStartStory = false
            self.storyQueue = {}
            return
        end
        DataManager:getInstance():sendSystemInfo(self.storyQueue[index])
        index = index + 1
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.CallFunc:create(runStorys)))
    end
    if not self.bIsStartStory then
        runStorys()
    end
end

-- 播放解锁按钮动画
function MainMenuLayer:playUnlockAni()
    if GuideController:getInstance():getIsHaveStep(10) and not GuideController:getInstance():getIsHaveStep(2, true) then
        if not GuideController:getInstance():getIsHaveStep(102, true) then
            -- self.makeBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
            GuideController:getInstance():addStep(102, true)
        end
    end
    if GuideController:getInstance():getIsHaveStep(9) and not GuideController:getInstance():getIsHaveStep(3, true) then
        if not GuideController:getInstance():getIsHaveStep(103, true) then
            -- self.trainBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
            GuideController:getInstance():addStep(103, true)
        end
    end
    if GuideController:getInstance():getIsHaveStep(5) and not GuideController:getInstance():getIsHaveStep(4, true) then
        if not GuideController:getInstance():getIsHaveStep(104, true) then
            -- self.storeBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 2.0), cc.ScaleTo:create(0.8, 1.0)))
            GuideController:getInstance():addStep(104, true)
        end
    end
end

--[[
处理按钮点击效果的函数
]]
function MainMenuLayer:activeButtonWithIndex(index)
    local changed = index ~= self.selectedIndex
    local buttons = {self.expeditionBtn, self.trainBtn, self.buildBtn, self.repositoryBtn,
        self.makeBtn, self.resourceBtn, self.storeBtn}
    for _, button in ipairs(buttons) do BTheme.setActive(button, false) end
    BTheme.setActive(self.homeBtn, false)
    local button = index == 0 and self.homeBtn or buttons[index]
    if button then
        BTheme.setActive(button, true)
        self.selectedIndex = index
        self.utilityRoute = nil
        self.navigationGroupOverride = nil
        self.btnHLBg:stopAllActions()
        self.btnHLBg:setPosition(cc.p(button:getPositionX() - self.btnHLBg:getContentSize().width * 0.5, 13))
    end
    self:applyHomeNavigationAppearance()
    return changed
end

-- Shared navigation keeps the same unlock gates and guide side effects for
-- both the footer and the new read-only harbor dashboard.
function MainMenuLayer:openRoute(index)
    self:closeNavigationGroup()
    local guide = GuideController:getInstance()
    local required = {[1] = {8, false, "船坞"}, [2] = {103, true, "训练营"},
        [3] = {1, false, "炼金"}, [4] = {2, false, "仓库"},
        [5] = {102, true, "铁匠铺或船工厂"}, [6] = {2, false, "仓库"}, [7] = {104, true, "市场"}}
    local rule = required[index]
    if rule and not guide:getIsHaveStep(rule[1], rule[2]) then
        ToastUtil:downString(index == 3 and "先使用炼金法阵制造10枚金币" or "您需要建造" .. rule[3] .. "，可激活该功能")
        return
    end
    if index == self.selectedIndex and index ~= 0 and not self.utilityRoute then return end
    if index == 0 and zqDispatch.rightNode and zqDispatch.rightNode.isAdventureHome then return end
    if DataManager:getInstance():getSound_off() == 0 then AudioEngine.playEffect(EFFECT_Button, false) end
    if index == 0 then zqDispatch:moveToHome()
    elseif index == 1 then zqDispatch:moveToExpedition()
    elseif index == 2 then zqDispatch:gotoTrain(); guide:addStep(3, true)
    elseif index == 3 then zqDispatch:gotoBuild()
    elseif index == 4 then zqDispatch:moveToRepository()
    elseif index == 5 then zqDispatch:gotoMake(); guide:addStep(2, true)
    elseif index == 6 then zqDispatch:moveToResource()
    elseif index == 7 then zqDispatch:gotoStore(); guide:addStep(4, true)
    end
    self:activeButtonWithIndex(index)
end

--[[
获得当前选中界面的索引
]]
function MainMenuLayer:getSelectedIndex()
    return self.selectedIndex
end

--[[
设置下方的点点
]]
-- function MainMenuLayer:setPointWithIndex(index, allNum)
--     self.pointNode:removeAllChildren()
--     -- 根据新手引导状态修改当前数值
--     if not GuideController:getInstance():getIsHaveStep(2) then
--         -- 没建设仓库之前
--         index = 1
--         allNum = 1
--     elseif not GuideController:getInstance():getIsHaveStep(8) then
--         -- 没建造船坞之前
--         index = index - 2
--         allNum = 2
--     end
--     for i = 1, allNum do
--         local spr = nil
--         if i == index then
--             spr = cc.Sprite:create("Images/UI/dian_b.png")
--         else
--             spr = cc.Sprite:create("Images/UI/dian_a.png")
--         end
--         -- print("宽度：", allNum % 2)
--         spr:setPosition(cc.p((i - allNum / 2.0 - 0.5) * (spr:getContentSize().width + 10), 0))
--         self.pointNode:addChild(spr)
--     end
-- end



-- Four persistent groups share legacy routes; the current route index remains
-- compatible with Dispatch and all guide data. Utility pages use a separate key.
function MainMenuLayer:applyHomeNavigationAppearance()
    if not self.navigationButtons then return end
    local group = self.navigationGroupOverride
    if not group then
        group = self.selectedIndex == 0 and 1 or (self.selectedIndex == 1 and 2 or (self.selectedIndex == 2 and 3 or 4))
    end
    for index, button in ipairs(self.navigationButtons) do
        self.navigationBrushes[index]:setVisible(index == group)
        button.bLabel:setFontName(MasterTheme.headingFont(true))
        button.bLabel:setColor(MENU_COLORS.paper)
    end
    -- The guide may fade or hide legacy targets; it never controls these nodes.
    self.groupNavigation:setVisible(true)
    self.navigationBg:setColor(MENU_COLORS.ink)
    self.navigationCaption:setVisible(false)
end

function MainMenuLayer:updateGroupedGuideState()
    if not self.navigationButtons then return end
    local guide = GuideController:getInstance()
    local groups = {
        {}, {self.expeditionBtn}, {self.trainBtn},
        {self.buildBtn, self.repositoryBtn, self.makeBtn, self.resourceBtn, self.storeBtn}
    }
    for index, fields in ipairs(groups) do
        local red = false
        for _, button in ipairs(fields) do
            if button:isVisible() and button:getChildByTag(9527) then red = true; break end
        end
        if index == 4 and not guide:getIsHaveStep(1) then red = true end
        if red then guide:addRedPoint(self.navigationButtons[index])
        else guide:removeRedPoint(self.navigationButtons[index]) end
    end
    self:applyHomeNavigationAppearance()
end

function MainMenuLayer:closeNavigationGroup()
    local overlay = self.navigationOverlay
    if not overlay then return end
    self.navigationOverlay = nil
    self.groupRouteButtons = nil
    self.navigationCloseButton = nil
    if self.navigationOverlayListener then
        self:getEventDispatcher():removeEventListener(self.navigationOverlayListener)
        self.navigationOverlayListener = nil
    end
    overlay:stopAllActions()
    overlay:removeFromParent()
end

-- Keep ownership on the menu, with a native cleanup observer so a dismissed
-- or scene-replaced dialog never leaves a stale Cocos wrapper to query.
function MainMenuLayer:openGiftOffer()
    if DataManager:getInstance():getRoleData(roleMapInfo) == nil or isEnterMap then
        ToastUtil:downString("出征返港后可查看付费礼包")
        return
    end
    if self.giftDialog then return end
    local view = PushGiftView:create()
    if not view then return end
    self.giftDialog = view
    local owner = cc.Node:create()
    owner:registerScriptHandler(function(event)
        if event == "cleanup" and self.giftDialog == view then self.giftDialog = nil end
    end)
    view:addChild(owner)
    view:show()
end

function MainMenuLayer:openUtilityRoute(key)
    self:closeNavigationGroup()
    if key == "gift" then self:openGiftOffer(); return end
    local dispatch = zqDispatch
    if not dispatch then return end
    local routes = {
        growth = "gotoTalent", achievement = "gotoAchievement", alchemy = "moveToRepository",
        ranking = "gotoRanking", settings = "gotoSetting", diamondStore = "gotoDiamondStore"
    }
    local route = routes[key]
    if not route then return end
    -- These utilities were reached through the unlocked expedition page.
    -- Grouping must not expose them before the original shipyard prerequisite.
    if (key == "achievement" or key == "ranking") and not GuideController:getInstance():getIsHaveStep(8) then
        ToastUtil:downString("您需要建造船坞，可激活该功能")
        return
    end
    if key == "settings" and not GuideController:getInstance():getIsHaveStep(2) then
        ToastUtil:downString("您需要建造仓库，可激活该功能")
        return
    end
    if DataManager:getInstance():getSound_off() == 0 then AudioEngine.playEffect(EFFECT_Button, false) end
    -- This is the same shop guide side effect as the original BaseView button.
    if key == "diamondStore" then GuideController:getInstance():addStep(61) end
    dispatch[route](dispatch)
    self.utilityRoute = key
    self.navigationGroupOverride = (key == "growth" or key == "achievement") and 3 or 4
    self:applyHomeNavigationAppearance()
end

function MainMenuLayer:openNavigationGroup(group)
    self:closeNavigationGroup()
    if group ~= "crew" and group ~= "port" then return end
    local size = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()
    local entries
    if group == "crew" then
        entries = {
            {"recruit", "招募船员", 2}, {"growth", "成长 / 天赋"},
            {"achievement", "成就"}
        }
    else
        entries = {
            {"build", "建设", 3}, {"repository", "仓库", 4},
            {"make", "制造", 5}, {"resource", "采集", 6},
            {"store", "市场", 7}, {"alchemy", "炼金"},
            {"ranking", "榜单"}, {"settings", "设置"},
            {"diamondStore", "钻石商城"}, {"gift", "礼包（付费）"}
        }
    end
    local overlay = cc.Layer:create()
    overlay:setContentSize(size)
    overlay:setPosition(origin)
    self.navigationOverlay = overlay
    self.groupRouteButtons = {}
    self:addChild(overlay, 20000)
    local shade = cc.LayerColor:create(cc.c4b(1, 25, 35, 158), size.width, size.height)
    overlay:addChild(shade)
    local panelWidth = math.min(568, size.width - 32)
    local rows = math.ceil(#entries / 2)
    local panelHeight = 104 + rows * 82
    local left = (size.width - panelWidth) / 2
    local bottom = math.max(UIBottomHeight + 14, (size.height - panelHeight) / 2)
    local paper = masterGraphic("crew-paper.png", panelWidth, panelHeight)
    paper:setPosition(cc.p(left, bottom)); overlay:addChild(paper, 1)
    paper:addChild(menuLabel(group == "crew" and "船员" or "港务", 32, MENU_COLORS.ink, 28, panelHeight - 42, true))
    local close = transparentMenuItem("×", 64, 64, function() self:closeNavigationGroup() end, 36, MENU_COLORS.ink)
    close:setPosition(cc.p(left + panelWidth - 42, bottom + panelHeight - 40))
    local items = {close}
    self.navigationCloseButton = close
    local gap = 14; local itemWidth = (panelWidth - 56 - gap) / 2
    for index, entry in ipairs(entries) do
        local key, title, route = entry[1], entry[2], entry[3]
        local row = math.floor((index - 1) / 2); local column = (index - 1) % 2
        local item = transparentMenuItem(title, itemWidth, 70, function()
            if route then self:openRoute(route) else self:openUtilityRoute(key) end
        end, 25, MENU_COLORS.ink)
        local backing = masterGraphic("currency-paper.png", itemWidth, 70)
        item:addChild(backing, -1)
        item:setPosition(cc.p(left + 28 + itemWidth / 2 + column * (itemWidth + gap),
            bottom + panelHeight - 115 - row * 82))
        self.groupRouteButtons[key] = item
        items[#items + 1] = item
        local legacy = route and ({[2]=self.trainBtn,[3]=self.buildBtn,[4]=self.repositoryBtn,
            [5]=self.makeBtn,[6]=self.resourceBtn,[7]=self.storeBtn})[route]
        if (key == "achievement" or key == "ranking") and not GuideController:getInstance():getIsHaveStep(8) then
            item.bLabel:setColor(cc.c3b(112,129,122))
        end
        if key == "gift" and (DataManager:getInstance():getRoleData(roleMapInfo) == nil or isEnterMap) then
            item.bLabel:setColor(cc.c3b(112,129,122))
        end
        if legacy then
            if not legacy:isVisible() or legacy:getOpacity() < 200 then
                item.bLabel:setColor(cc.c3b(112, 129, 122))
            end
            if legacy:getChildByTag(9527) then GuideController:getInstance():addRedPoint(item) end
        end
    end
    local menu = cc.Menu:create(unpack(items)); menu:setPosition(cc.p(0,0)); overlay:addChild(menu, 3)
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    local beganOutside = false
    local function outside(touch)
        local point = overlay:convertToNodeSpace(touch:getLocation())
        return point.x < left or point.x > left + panelWidth or point.y < bottom or point.y > bottom + panelHeight
    end
    listener:registerScriptHandler(function(touch)
        beganOutside = outside(touch)
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(function(touch)
        if beganOutside and outside(touch) then self:closeNavigationGroup() end
        beganOutside = false
    end, cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(function() beganOutside = false end, cc.Handler.EVENT_TOUCH_CANCELLED)
    self.navigationOverlayListener = listener
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, overlay)
end

-- The home header is transparent over the full harbor. Other pages retain
-- their original header, currency fields, and purchase actions.
function MainMenuLayer:setHomePresentation(active)
    self:closeNavigationGroup()
    self.homePresentation = active
    if active then ToastUtil:quietHomeProductionToasts() end
    self.legacyTopBg:setVisible(not active)
    self.coinNode:setVisible(not active); self.diamondNode:setVisible(not active)
    if not self.homeHeader then
        local size = cc.Director:getInstance():getVisibleSize()
        local origin = cc.Director:getInstance():getVisibleOrigin()
        local header = cc.Node:create(); header:setPosition(origin)
        self:addChild(header); self.homeHeader = header
        local title = menuLabel("海盗基地", 46, MENU_COLORS.ink, 42, size.height - 55, false)
        title:setFontName(MasterTheme.headingFont(true)); header:addChild(title)
        local titleArt = detailSprite("home-title-art.png", 240, 58)
        if titleArt then
            title:setVisible(false) -- Retain semantic/native text fallback without a duplicate visible title.
            titleArt:setPosition(cc.p(42 + 120, size.height - 55)); header:addChild(titleArt)
        end
        local compass = cc.DrawNode:create(); local ink = menuRGBA(MENU_COLORS.ink, 0.85)
        for segment = 0, 23 do
            local first, last = segment * math.pi / 12, (segment + 1) * math.pi / 12
            compass:drawSegment(cc.p(math.cos(first) * 10, math.sin(first) * 10),
                cc.p(math.cos(last) * 10, math.sin(last) * 10), 0.45, ink)
        end
        compass:drawSegment(cc.p(-22,0),cc.p(22,0),0.55,ink)
        compass:drawSegment(cc.p(0,-19),cc.p(0,19),0.55,ink)
        compass:drawSegment(cc.p(-7,-7),cc.p(7,7),0.4,ink)
        compass:drawSegment(cc.p(-7,7),cc.p(7,-7),0.4,ink)
        compass:drawPolygon({cc.p(0,15),cc.p(-3,0),cc.p(0,-15),cc.p(3,0)},4,
            cc.c4f(0,0,0,0),0.5,ink)
        compass:setPosition(cc.p(262, size.height - 57)); compass:setVisible(titleArt == nil); header:addChild(compass)
        local function currency(kind, value, x, width, plusX, callback)
            local centerY = size.height - 121
            local paper = masterGraphic("currency-paper.png", width, 52)
            paper:setPosition(cc.p(x, centerY - 26)); header:addChild(paper)
            local icon = nativeIcon(kind); icon:setPosition(cc.p(x + 28, centerY)); header:addChild(icon)
            local number = menuLabel(value, 27, MENU_COLORS.ink, x + 56, centerY, false)
            number:setFontName(MasterTheme.headingFont(true)); header:addChild(number)
            local add = transparentMenuItem("+", 59, 59, callback, 36, MENU_COLORS.sea)
            add:setPosition(cc.p(plusX, centerY))
            local chip = MasterTheme.material("currency-paper.png", 34, 34, cc.c3b(224, 225, 202))
            chip:setPosition(cc.p(12.5, 12.5)); add:addChild(chip, 1)
            local menu = cc.Menu:create(add); menu:setPosition(cc.p(0,0)); header:addChild(menu)
            return number, add
        end
        self.homeCoinLabel, self.homeCoinAddButton = currency("coin", self.coinValueLabel:getString(), 35, 182, 193,
            function() DataManager:getInstance():showBuyGoldBox() end)
        self.homeDiamondLabel, self.homeDiamondAddButton = currency("diamond", self.diamondValueLabel:getString(), 230, 170, 376,
            function() ChargeLayer:create() end)
    end
    self.homeHeader:setVisible(active)
    if active then
        self.homeCoinLabel:setString(self.coinValueLabel:getString())
        self.homeDiamondLabel:setString(self.diamondValueLabel:getString())
        BTheme.fitLabel(self.homeCoinLabel, 72); BTheme.fitLabel(self.homeDiamondLabel, 65)
    end
    self:applyHomeNavigationAppearance()
end

-- Approved secondary pages render their own live header. Hide only shared
-- chrome; always restore navigation/header when returning to legacy or Home.
function MainMenuLayer:setApprovedPagePresentation(active, keepNavigation)
    self.approvedPagePresentation=active
    if active then
        self.legacyTopBg:setVisible(false)
        self.coinNode:setVisible(false);self.diamondNode:setVisible(false)
        if self.homeHeader then self.homeHeader:setVisible(false) end
    end
    self.navigationBg:setVisible(not active or keepNavigation)
end
