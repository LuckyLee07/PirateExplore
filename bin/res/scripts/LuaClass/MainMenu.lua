require "AudioEngine"
require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/ToastUtil"
require "LuaClass/ChargeMode"
require "LuaClass/GuideController"
require "LuaClass/DiamondStore"
require "LuaClass/UIKit"


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

    -- 添加顶部菜单背景
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB5A1)
    local TopBg = cc.Sprite:create("Images/UI/TopBg.png")
    TopBg:setPosition(origin.x + visibleSize.width * 0.5, origin.y + visibleSize.height - (TopBg:getContentSize().height * 0.5))
    self:addChild(TopBg)

    -- 记录顶部UI的高度，以备其他类使用
    UITopHeight = TopBg:getContentSize().height

    -- 添加金币节点
    self.coinNode = cc.Node:create()
    self.coinNode:setCascadeOpacityEnabled(true)
    self.coinNode:setPosition(cc.p(visibleSize.width * 0.17, TopBg:getPositionY()))
    self:addChild(self.coinNode)

    -- 添加金币底条
    local coinBg = cc.Sprite:create("Images/UI/ditiao_01.png")
    coinBg:setPosition(cc.p(0, 0))
    self.coinNode:addChild(coinBg)

    -- 添加金币图标
    local coinIcon = cc.Sprite:create("Images/UI/CoinBg.png")
    coinIcon:setPosition(cc.p(coinBg:getContentSize().width * 0.5, 0))
    self.coinNode:addChild(coinIcon)

    -- 添加金币的数字
    local money = DataManager:getInstance():getRoleData(roleMoney)
    if money > 1000000 then
        money = math.floor(money / 10000) .. "万"
    else
        money = money..""
    end
    local coinLabel = cc.LabelTTF:create(money, BoldFont, 30.0)
    coinLabel:setPosition(0.0, 150.0)
    coinLabel:setColor(WriteColor)
    coinLabel:setAnchorPoint(cc.p(1, 0.5))
    -- coinLabel:enableStroke(cc.c4b(8, 8, 8, 255), 1)
    coinLabel:setPosition(cc.p(coinBg:getContentSize().width * 0.5 - 30, 0))
    self.coinNode:addChild(coinLabel)

    DataManager:getInstance():registerEvent(roleMoney, "mainmenu", function()
        cclog("mainMenu:刷新金币数据")
        money = DataManager:getInstance():getRoleData(roleMoney)
        if money > 1000000 then
            coinLabel:setString(math.floor(money / 10000) .. "万")
        else
            coinLabel:setString(money.."")
        end
    end)

    -- 添加金币增加按钮
    local addCoinBtn = SDButton:create("Images/UI/AddMoneyBtn.png", "Images/UI/AddMoneyBtn1.png", function()
        DataManager:getInstance():showBuyGoldBox()
    end)
    addCoinBtn:setPosition(cc.p(-coinBg:getContentSize().width * 0.5, 0))
    addCoinBtn:addClickArea(cc.rect(-20, -20, 220, 40))
    self.coinNode:addChild(addCoinBtn)


    -- 添加钻石节点
    self.diamondNode = cc.Node:create()
    self.diamondNode:setPosition(cc.p(visibleSize.width * 0.83, TopBg:getPositionY()))
    self.diamondNode:setCascadeOpacityEnabled(true)
    self:addChild(self.diamondNode)

    -- 添加钻石底条
    local diamondBg = cc.Sprite:create("Images/UI/ditiao_01.png")
    diamondBg:setPosition(cc.p(0, 0))
    self.diamondNode:addChild(diamondBg)

    -- 添加钻石图标
    local diamondIcon = cc.Sprite:create("Images/UI/DiamondBg.png")
    diamondIcon:setPosition(cc.p(-diamondBg:getContentSize().width * 0.5, 0))
    self.diamondNode:addChild(diamondIcon)

    -- 添加钻石Label
    local diamond = DataManager:getInstance():getRoleData(roleDiamond)
    local diamondLabel = cc.LabelTTF:create(diamond.."", BoldFont, 30.0)
    diamondLabel:setPosition(0.0, 150.0)
    diamondLabel:setColor(WriteColor)
    diamondLabel:setCascadeOpacityEnabled(true)
    diamondLabel:setAnchorPoint(cc.p(0, 0.5))
    -- diamondLabel:enableStroke(cc.c4b(8, 8, 8, 255), 1)
    diamondLabel:setPosition(cc.p(-diamondBg:getContentSize().width * 0.5 + 30, 0))
    self.diamondNode:addChild(diamondLabel)

    DataManager:getInstance():registerEvent(roleDiamond, "mainmenu", function()
        cclog("mainMenu:刷新钻石数据")
        diamond = DataManager:getInstance():getRoleData(roleDiamond)
        diamondLabel:setString(diamond.."")
    end)

    -- 添加钻石按钮
    local addDiamondBtn = SDButton:create("Images/UI/AddMoneyBtn.png", "Images/UI/AddMoneyBtn1.png", function() 
        cclog("点击了增加钻石按钮")
        
        local time = os.time()
        local recommended = {}
        for i=1,5 do
            local temp = {}
            temp["ID"] = tostring(1000 + i)
            temp["diamond"] = 20 * i
            temp["money"] = 10 * i
            -- temp["extraDiamod"] = i * 5

            if (i > 1) then
                temp["countdown"] = time + 1000 * (i - 1) + 5
            else
                temp["countdown"] = time + 20 * i
            end
            
            recommended[tostring(i)] = temp
        end

        local goodsInfo = {}
        for i=1,10 do
             local temp = {}
             temp["ID"] = tostring(2001 + i)
             temp["diamond"] = 30 * i
             temp["money"] = 40 * i
             temp["extraDiamond"] = 50 * i
             goodsInfo[tostring(i)] = temp
        end

        local tableData = {}
        tableData["1"] = recommended
        tableData["2"] = goodsInfo
        -- ChargingView:create(tableData)
        ChargeLayer:create()
    end)
    addDiamondBtn:addClickArea(cc.rect(-220, -20, 240, 40))
    addDiamondBtn:setPosition(cc.p(diamondBg:getContentSize().width * 0.5, 0))
    self.diamondNode:addChild(addDiamondBtn)

    -- 添加底部背景图
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)
    local BottomBg = cc.Sprite:create("Images/UI/BottomBg.png")
    BottomBg:setPosition(TopBg:getPositionX(), origin.y + (BottomBg:getContentSize().height * 0.5))
    self:addChild(BottomBg)

    -- 添加点点承载节点
    self.pointNode = cc.Node:create()
    self.pointNode:setPosition(cc.p(visibleSize.width * 0.5, BottomBg:getContentSize().height * 0.89))
    BottomBg:addChild(self.pointNode)

    -- 添加底部的七个个按钮
    local buttonSplitPosX = 1.08
    local bottomPadding = visibleSize.width / 7
    local bottomBtnPosX = bottomPadding * 0.5

    self.MainMenuButtonGroup = cc.Node:create()
    self.MainMenuButtonGroup:setPosition(0, 0)
    BottomBg:addChild(self.MainMenuButtonGroup)

    -- 创建按钮光效图
    self.btnHLBg = cc.Sprite:create("Images/MainMenu/an_difg.png")
    self.btnHLBg:setPosition(cc.p(visibleSize.width * 0.5, BottomBg:getContentSize().height * 0.5 - 20))
    -- self.btnHLBg:setBlendFunc(GL_DST_COLOR, GL_SRC_ALPHA)
    self.MainMenuButtonGroup:addChild(self.btnHLBg)


    self.expeditionBtn = cc.MenuItemImage:create("Images/MainMenu/chuz_a.png", "Images/MainMenu/chuz_c.png");
    self.expeditionBtn:registerScriptTapHandler(function() 
        cclog("点击了出征按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(8) then
            if self:activeButtonWithIndex(1) then
                zqDispatch:moveToExpedition()
            end
        else
            ToastUtil:downString("您需要建造船坞，可激活该功能")
        end
    end)
    self.expeditionBtn:setPosition(bottomBtnPosX, self.btnHLBg:getPositionY())

    splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.expeditionBtn:getContentSize().width * buttonSplitPosX, self.expeditionBtn:getContentSize().height * 0.5))
    self.expeditionBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.trainBtn = cc.MenuItemImage:create("Images/MainMenu/zhaom_a.png", "Images/MainMenu/zhaom_c.png");
    self.trainBtn:registerScriptTapHandler(function() 
        cclog("点击了招募按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(103, true) then
            if self:activeButtonWithIndex(2) then
                zqDispatch:gotoTrain()
                -- 增加红点隐藏操作
                GuideController:getInstance():addStep(3, true)
            end
        else
            ToastUtil:downString("您需要建造训练营，可激活该功能")
        end
    end)
    self.trainBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())
    self.trainBtn:setVisible(false)

    splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.trainBtn:getContentSize().width * buttonSplitPosX, self.trainBtn:getContentSize().height * 0.5))
    self.trainBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.buildBtn = cc.MenuItemImage:create("Images/MainMenu/jians_a.png", "Images/MainMenu/jians_c.png");
    self.buildBtn:registerScriptTapHandler(function() 
        cclog("点击了建设按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if self:activeButtonWithIndex(3) then
            zqDispatch:gotoBuild()
        end
    end)
    self.buildBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())
    self.buildBtn:setVisible(false)

    splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.buildBtn:getContentSize().width * buttonSplitPosX, self.buildBtn:getContentSize().height * 0.5))
    self.buildBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.repositoryBtn = cc.MenuItemImage:create("Images/MainMenu/cangk_a.png", "Images/MainMenu/cangk_c.png");
    self.repositoryBtn:registerScriptTapHandler(function() 
        cclog("点击了仓库按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(2) then
            if self:activeButtonWithIndex(4) then
                zqDispatch:moveToRepository()
            end
        else
            ToastUtil:downString("您需要建造仓库，可激活该功能")
        end
    end)
    self.repositoryBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())

    local splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.repositoryBtn:getContentSize().width * buttonSplitPosX, self.repositoryBtn:getContentSize().height * 0.5))
    self.repositoryBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.makeBtn = cc.MenuItemImage:create("Images/MainMenu/zhiz_a.png", "Images/MainMenu/zhiz_c.png");
    self.makeBtn:registerScriptTapHandler(function() 
        cclog("点击了制造按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(102, true) then
            if self:activeButtonWithIndex(5) then
                zqDispatch:gotoMake()
                -- 增加红点隐藏操作
                GuideController:getInstance():addStep(2, true)
            end
        else
            ToastUtil:downString("您需要建造铁匠铺或船工厂\n可激活该功能")
        end
    end)
    self.makeBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())
    self.makeBtn:setVisible(false)

    splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.makeBtn:getContentSize().width * buttonSplitPosX, self.makeBtn:getContentSize().height * 0.5))
    self.makeBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.resourceBtn = cc.MenuItemImage:create("Images/MainMenu/caij_a.png", "Images/MainMenu/caij_c.png");
    self.resourceBtn:registerScriptTapHandler(function() 
        cclog("点击了采集按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(2) then
            if self:activeButtonWithIndex(6) then
                zqDispatch:moveToResource()
            end
        else
            ToastUtil:downString("您需要建造仓库，可激活该功能")
        end
    end)
    self.resourceBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())

    splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    splitSpr:setPosition(cc.p(self.resourceBtn:getContentSize().width * buttonSplitPosX, self.resourceBtn:getContentSize().height * 0.5))
    self.resourceBtn:addChild(splitSpr)


    bottomBtnPosX = bottomBtnPosX + bottomPadding
    self.storeBtn = cc.MenuItemImage:create("Images/MainMenu/shic_a.png", "Images/MainMenu/shic_c.png");
    self.storeBtn:registerScriptTapHandler(function() 
        cclog("点击了市场按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        if GuideController:getInstance():getIsHaveStep(104, true) then
            if self:activeButtonWithIndex(7) then
                zqDispatch:gotoStore()
                -- 增加红点隐藏操作
                GuideController:getInstance():addStep(4, true)
            end
        else
            ToastUtil:downString("您需要建造市场，可激活该功能")
        end
    end)
    self.storeBtn:setPosition(bottomBtnPosX, self.expeditionBtn:getPositionY())
    self.storeBtn:setVisible(false)

    -- local backLabel = cc.LabelTTF:create("返     回", BoldFont, 46.0)
    -- backLabel:setColor(BaseColor)
    -- -- backLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)

    -- local backBtn = cc.MenuItemLabel:create(backLabel)
    -- backBtn:registerScriptTapHandler(function() 
    --     cclog("点击了返回按钮")
    --     if DataManager:getInstance():getSound_off() == 0 then
    --         AudioEngine.playEffect(EFFECT_Button, false)
    --     end
    --     zqDispatch:moveToMain()
    --     -- 增加红点隐藏操作
    --     GuideController:getInstance():addStep(7, true)
    -- end)
    -- backBtn:setPosition(visibleSize.width * 1.5, self.buildBtn:getPositionY())

    -- splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    -- splitSpr:setPosition(cc.p(backBtn:getContentSize().width * 1.16, backBtn:getContentSize().height * 0.5))
    -- backBtn:addChild(splitSpr)

    -- splitSpr = cc.Sprite:create("Images/UI/ButtonSplit.png")
    -- splitSpr:setPosition(cc.p(-backBtn:getContentSize().width * 0.16, backBtn:getContentSize().height * 0.5))
    -- backBtn:addChild(splitSpr)

    local buttonArr = {self.repositoryBtn, self.resourceBtn, self.expeditionBtn, self.buildBtn, self.makeBtn, self.trainBtn, self.storeBtn}

    local mainMenuButton = cc.Menu:create(unpack(buttonArr))
    mainMenuButton:setPosition(0, 0)
    self.MainMenuButtonGroup:addChild(mainMenuButton)

    -- 默认选中仓库
    self:activeButtonWithIndex(4)

    -- 单独添加一个建造按钮的气泡提示
    -- local buildBtnAlertSpr = cc.Sprite:create("Images/UI/BuildAlert.png")
    -- buildBtnAlertSpr:setScale(0.66)
    -- buildBtnAlertSpr:setPosition(cc.p(self.buildBtn:getPositionX() + buildBtnAlertSpr:getContentSize().width * buildBtnAlertSpr:getScale() * 0.26, self.buildBtn:getPositionY() + buildBtnAlertSpr:getContentSize().height * 0.8))
    -- self.MainMenuButtonGroup:addChild(buildBtnAlertSpr, 10)
    -- buildBtnAlertSpr:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(1.6, cc.p(0, -10)), cc.MoveBy:create(1.6, cc.p(0, 10)))))
    -- buildBtnAlertSpr:setVisible(false)

    -- 记录底部UI的高度，以备其他类使用
    UIBottomHeight = BottomBg:getContentSize().height

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
                    finger = cc.Sprite:create("Images/Map/Guide/finger_1.png")
                    finger:setAnchorPoint(0, 1)
                    finger:setScale(0.8)
                    finger:setPosition(cc.p(self.expeditionBtn:getPositionX(), self.expeditionBtn:getPositionY() + self.expeditionBtn:getContentSize().height * 0.5))
                    self.MainMenuButtonGroup:addChild(finger, 9999)

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
                local storyStr = {"它回应了你，一个新的功能被解锁！", "看看它能为你做些什么。"}
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
    end
    DataManager:getInstance():registerEvent(roleGuideStep, "mainMenu", MainMenuDidGuideChange)

    -- 这里要判断新手引导走过之后调用才合理，不调用还不行，要不从战斗出来就不显示下边按钮了
    -- if GuideController:getInstance():getIsHaveStep(1) then
        MainMenuDidGuideChange()
    -- end

    -- 播放船走的动画
    local boatBtn = nil
    boatBtn = SDButton:create("Images/DiamondStore/GoldenBoat.png", "Images/DiamondStore/GoldenBoat.png", function()
        PushGiftView:create():show()
        -- 移动小船到准备出发的位置
        self.boatSpr:stopAllActions()
        self.boatSpr:setPosition(cc.p(visibleSize.width + boatBtn:getContentSize().width, UIBottomHeight + boatBtn:getContentSize().height * 0.5))
    end)
    self.boatSpr = cc.Node:create()
    self.boatSpr:setPosition(cc.p(visibleSize.width + boatBtn:getContentSize().width * 0.5, UIBottomHeight + boatBtn:getContentSize().height * 0.5))
    self:addChild(self.boatSpr, 9999)

    boatBtn:setPosition(cc.p(0, 0))
    self.boatSpr:addChild(boatBtn)

    local function playBoatRun()
        -- body
        self.boatSpr:setPosition(cc.p(visibleSize.width + boatBtn:getContentSize().width * 0.5, UIBottomHeight + boatBtn:getContentSize().height * 0.5))
        self.boatSpr:runAction(cc.MoveTo:create(10.0, cc.p(-boatBtn:getContentSize().width * 0.5, self.boatSpr:getPositionY())))
    end

    -- 没解锁船坞并且没进入过地图的情况下不弹礼包推送 by 杨杰，厉晔的需求
    if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil and not isEnterMap then
        local delay = cc.DelayTime:create(0.3)
        local call = cc.CallFunc:create(function()
            PushGiftView:create():show()
        end)
        local seq = cc.Sequence:create(delay, call)
        self:runAction(seq)
    end
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
    if index == self.selectedIndex then
        return false
    end
    -- 处理按钮高亮状态，先把所有按钮的normalImage变为正常
    local buttons = {self.expeditionBtn, self.trainBtn, self.buildBtn, self.repositoryBtn, self.makeBtn, self.resourceBtn, self.storeBtn}
    local normalImages = {"Images/MainMenu/chuz_a.png", "Images/MainMenu/zhaom_a.png", "Images/MainMenu/jians_a.png", "Images/MainMenu/cangk_a.png", "Images/MainMenu/zhiz_a.png", "Images/MainMenu/caij_a.png", "Images/MainMenu/shic_a.png"}
    local selectedImages = {"Images/MainMenu/chuz_c.png", "Images/MainMenu/zhaom_c.png", "Images/MainMenu/jians_c.png", "Images/MainMenu/cangk_c.png", "Images/MainMenu/zhiz_c.png", "Images/MainMenu/caij_c.png", "Images/MainMenu/shic_c.png"}
    for i=1,#buttons do
        if buttons[i] ~= nil then
            buttons[i]:setNormalImage(cc.Sprite:create(normalImages[i]))
        end
    end
    -- 然后把指定的按钮高亮处理
    if buttons[index] ~= nil then
        buttons[index]:setNormalImage(cc.Sprite:create(selectedImages[index]))
        self.selectedIndex = index
        self.btnHLBg:stopAllActions()
        local pos = cc.p(buttons[index]:getPositionX(), buttons[index]:getPositionY())
        self.btnHLBg:runAction(cc.EaseExponentialOut:create(cc.MoveTo:create(0.3, pos)))
    end
    return true
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

