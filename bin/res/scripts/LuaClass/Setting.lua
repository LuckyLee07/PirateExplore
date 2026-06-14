require "LuaClass/Header"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/DataManager"
require "LuaClass/ToastUtil"
require "LuaClass/AlertView"
require "LuaClass/CDKView"


SettingLayer = class("SettingLayer", function ()
    return BaseView:create()
end)

SettingLayer.__index = SettingLayer
-- SettingLayer.sound_off = 0
-- SettingLayer.music_off = 0
-- SettingLayer.effect_off = 0

function SettingLayer:create()
    local view = SettingLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function SettingLayer:init()
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 设置title文字
    self.titleLabel:setString("设 置")

    -- 隐藏上边左侧的按钮
    self.topLeftBtn:setVisible(false)

    -- 修改右侧按钮为返回
    self:resetTopRightButtonToBack()

    -- print(debug.traceback())

------------------------------------------- 兑换码 和语言----------------------------------------
    -- -- 添加兑换码按钮
    -- local supernum_btn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
    -- local function test()
    -- end
    -- supernum_btn:registerScriptTapHandler(function()
    --     -- self:close()
    --     AlertView:create(2,0, "兑换码测试",test,nil)
    --     -- ToastUtil:toastString("功能暂未开启，敬请期待！")
    -- end)
    -- supernum_btn:setPosition(0.5*visibleSize.width, self.centerPos.y + self.areaHeight * 0.25 + supernum_btn:getContentSize().height * 0.8)
    -- local supernum_menu = cc.Menu:create(supernum_btn)
    -- supernum_menu:setPosition(cc.p(0, 0))
    -- self:addChild(supernum_menu)

    -- -- 放置兑换码文字
    -- local supernumLabel = cc.LabelTTF:create("兑换码", BoldFont, 36.0)
    -- supernumLabel:setColor(cc.c3b(255, 255, 255))
    -- -- supernumLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    -- supernumLabel:setPosition(cc.p(supernum_btn:getContentSize().width * 0.5, supernum_btn:getContentSize().height * 0.5))
    -- supernum_btn:addChild(supernumLabel)

    local gapV = 20

    -- 更多游戏按钮
    local moregame_btn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
    moregame_btn:registerScriptTapHandler(function()
        showMoreGameCallback()
        -- openUrlFunc("http://game.10086.cn/a/")
        end)
    moregame_btn:setPosition(0.5*visibleSize.width, self.centerPos.y + self.areaHeight * 0.25 + moregame_btn:getContentSize().height * 2.0)
    local supernum_menu = cc.Menu:create(moregame_btn)
    supernum_menu:setPosition(cc.p(0, 0))
    self:addChild(supernum_menu)

    -- 放置更多游戏文字
    local moreLabel = cc.LabelTTF:create("更多游戏", BoldFont, 36.0)
    moreLabel:setColor(cc.c3b(255, 255, 255))
    -- moreLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    moreLabel:setPosition(cc.p(moregame_btn:getContentSize().width * 0.5, moregame_btn:getContentSize().height * 0.5))
    moregame_btn:addChild(moreLabel)

    -- 添加兑换码按钮
    local enableStr = getEnableInterface()
    local supernum_btn = moregame_btn
    if enableStr ~= nil then
        local enableTable = json.decode(enableStr)
        if enableTable ~= nil and enableTable["UserCenter"] == "Enabled" then
            supernum_btn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")

            supernum_btn:registerScriptTapHandler(function()
                -- self:close()
                -- AlertView:create(2,0, "兑换码测试",test,nil)

                local cdkView = CDKView:create()
                cdkView:show()
            -- ToastUtil:toastString("功能暂未开启，敬请期待！")
            end)
            supernum_btn:setPosition(0.5*visibleSize.width, self.centerPos.y + self.areaHeight * 0.25 + supernum_btn:getContentSize().height * 2.0 - supernum_btn:getContentSize().height * 0.5 - supernum_btn:getContentSize().height * 0.5 - gapV)
            local supernum_menu = cc.Menu:create(supernum_btn)
            supernum_menu:setPosition(cc.p(0, 0))
            self:addChild(supernum_menu)

            -- 放置兑换码文字
            local supernumLabel = cc.LabelTTF:create("兑换码", BoldFont, 36.0)
            supernumLabel:setColor(cc.c3b(255, 255, 255))
            -- supernumLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
            supernumLabel:setPosition(cc.p(supernum_btn:getContentSize().width * 0.5, supernum_btn:getContentSize().height * 0.5))
            supernum_btn:addChild(supernumLabel)
        end
    end

    -- 添加帮助按钮
    local helpBtn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
    helpBtn:registerScriptTapHandler(function()
        -- self:close()
        local helpbg = AlertView:create(0, 3, "帮 助", nil, nil)
        local helpinfolabel = cc.LabelTTF:create("1.  点击炼金可以立即获得金币。\n\n2.  通过左右滑动可快捷切换界面。\n\n3.  长按“＋”或“—”可以快速\n添加或减少对应数量。\n\n4.  长按仓库中的某些物品可以进行出售。\n\n5.  船队出征是获得新材料的唯一途径。\n\n6.  制造更好的航船可以提升船\n战时的生命值。\n\n7.  你可以从已占据的据点中领取补给。\n\n8.  建设更多的建筑可以使你\n的游民做更多的事。\n\n", BoldFont, 28.0)
        helpinfolabel:setColor(cc.c3b(255, 255, 255))
        helpinfolabel:setPosition(cc.p(helpbg.s_position.x, helpbg.s_position.y - 20))
        helpinfolabel:setDimensions(cc.size(0, 800))
        helpinfolabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        helpbg:addChild(helpinfolabel)
        -- ToastUtil:toastString("功能暂未开启，敬请期待！")
    end)
    helpBtn:setPosition(0.5*visibleSize.width, supernum_btn:getPositionY() - supernum_btn:getContentSize().height * 0.5 - helpBtn:getContentSize().height * 0.5 - gapV)
    local Language_menu = cc.Menu:create(helpBtn)
    Language_menu:setPosition(cc.p(0, 0))
    self:addChild(Language_menu)

    -- 放置帮助文字
    local LanguageLabel = cc.LabelTTF:create("帮 助", BoldFont, 36.0)
    LanguageLabel:setColor(cc.c3b(255, 255, 255))
    -- LanguageLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    LanguageLabel:setPosition(cc.p(helpBtn:getContentSize().width * 0.5, helpBtn:getContentSize().height * 0.5))
    helpBtn:addChild(LanguageLabel)

    -- 添加关于按钮
    local aboutBtn = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
    aboutBtn:registerScriptTapHandler(function()
        -- self:close()
        local helpbg = AlertView:create(0, 3, "关 于", test, nil)
        local helpinfolabel = cc.LabelTTF:create("探险科技有限公司为《海上探险家》\n\n游戏的软件著作权人。探险科技\n\n有限公司在中国大陆从事本游戏的\n\n商业运营。探险科技有限公司同时\n\n负责处理本游戏运营的相关客户服\n\n务及技术支持。\n\n\n客服QQ群：106134362\n\n客服信箱：1976428305@qq.com\n\n", BoldFont, 28.0)
        helpinfolabel:setColor(WriteColor)
        helpinfolabel:setPosition(cc.p(helpbg.s_position.x, helpbg.s_position.y + 5))
        helpinfolabel:setDimensions(cc.size(0, 800))
        helpinfolabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        helpbg:addChild(helpinfolabel)
        -- ToastUtil:toastString("功能暂未开启，敬请期待！")
    end)
    aboutBtn:setPosition(0.5*visibleSize.width, helpBtn:getPositionY() - helpBtn:getContentSize().height * 0.5 - aboutBtn:getContentSize().height * 0.5 - gapV)
    local about_menu = cc.Menu:create(aboutBtn)
    about_menu:setPosition(cc.p(0, 0))
    self:addChild(about_menu)

    -- 放置语言文字
    local aboutLabel = cc.LabelTTF:create("关 于", BoldFont, 36.0)
    aboutLabel:setColor(cc.c3b(255, 255, 255))
    -- LanguageLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    aboutLabel:setPosition(cc.p(aboutBtn:getContentSize().width * 0.5, aboutBtn:getContentSize().height * 0.5))
    aboutBtn:addChild(aboutLabel)


------------------------------------------- 6个按钮----------------------------------------
    -- 添加音乐按钮
    local MusicNormal = cc.MenuItemImage:create("Images/UI/yinyue_a.png", "Images/UI/yinyue_a.png")
    local MusicSelected = cc.MenuItemImage:create("Images/UI/yinyue_b.png", "Images/UI/yinyue_b.png")
    local Music_btn = cc.MenuItemToggle:create(MusicNormal, MusicSelected)
    -- local Music_btn = cc.MenuItemImage:create("Images/UI/yinyue_a.png", "Images/UI/yinyue_b.png")
    Music_btn:registerScriptTapHandler(function()
        -- self:close()
        if DataManager:getInstance():getMusic_off() == 0 then
            AudioEngine.pauseMusic()
            DataManager:getInstance():setMusic_off(1)
        else
            if HAS_MUSIC_FILE == 1 then
                AudioEngine.resumeMusic()
            else
                AudioEngine.playMusic(MUSIC_Main, true)
            end
            
            DataManager:getInstance():setMusic_off(0)
        end
        cclog("点击了音乐按钮")
    end)
    Music_btn:setPosition(0.5*visibleSize.width, self.centerPos.y - Music_btn:getContentSize().height *0.5)
    if DataManager:getInstance():getMusic_off() == 1 then
        Music_btn:setSelectedIndex(1)
    end
    
    local Music_menu = cc.Menu:create(Music_btn)
    Music_menu:setPosition(cc.p(0, 0))
    self:addChild(Music_menu)

    -- 放置音乐文字
    local MusicLabel = cc.LabelTTF:create("音乐", BoldFont, 36.0)
    MusicLabel:setColor(cc.c3b(255, 255, 255))
    -- MusicLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    MusicLabel:setPosition(cc.p(Music_btn:getContentSize().width * 0.5, -MusicLabel:getContentSize().height * 0.45))
    Music_btn:addChild(MusicLabel)



    -- 添加音效按钮
    local SoundNormal = cc.MenuItemImage:create("Images/UI/shengyin_a.png", "Images/UI/shengyin_a.png")
    local SoundSelected = cc.MenuItemImage:create("Images/UI/shengyin_b.png", "Images/UI/shengyin_b.png")
    local Sound_btn = cc.MenuItemToggle:create(SoundNormal, SoundSelected)
    -- local Sound_btn = cc.MenuItemImage:create("Images/UI/shengyin_a.png", "Images/UI/shengyin_b.png")
    Sound_btn:registerScriptTapHandler(function()
        -- self:close()
        if DataManager:getInstance():getSound_off() == 0 then
            DataManager:getInstance():setSound_off(1)
        else
            DataManager:getInstance():setSound_off(0)
        end
        cclog("点击了音效按钮")
    end)
    Sound_btn:setPosition(0.25*visibleSize.width, self.centerPos.y - Sound_btn:getContentSize().height *0.5)
    if DataManager:getInstance():getSound_off() == 1 then
        Sound_btn:setSelectedIndex(1)
    end
    local Sound_menu = cc.Menu:create(Sound_btn)
    Sound_menu:setPosition(cc.p(0, 0))
    self:addChild(Sound_menu)

    -- 放置音效文字
    local SoundLabel = cc.LabelTTF:create("音效", BoldFont, 36.0)
    SoundLabel:setColor(cc.c3b(255, 255, 255))
    -- SoundLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    SoundLabel:setPosition(cc.p(Music_btn:getContentSize().width * 0.5, -SoundLabel:getContentSize().height * 0.45))
    Sound_btn:addChild(SoundLabel)





    -- 添加特效按钮
    local EffectNormal = cc.MenuItemImage:create("Images/UI/texiao_a.png", "Images/UI/texiao_a.png")
    local EffectSelected = cc.MenuItemImage:create("Images/UI/texiao_b.png", "Images/UI/texiao_b.png")
    local Effect_btn = cc.MenuItemToggle:create(EffectNormal, EffectSelected)
    -- local Effect_btn = cc.MenuItemImage:create("Images/UI/texiao_a.png", "Images/UI/texiao_b.png")
    Effect_btn:registerScriptTapHandler(function()
        -- self:close()
        if DataManager:getInstance():getEffect_off() == 0 then
            DataManager:getInstance():setEffect_off(1)
        else
            DataManager:getInstance():setEffect_off(0)
        end
        cclog("点击了特效按钮")
    end)
    Effect_btn:setPosition(0.75*visibleSize.width, self.centerPos.y  - Effect_btn:getContentSize().height *0.5)
    if DataManager:getInstance():getEffect_off() == 1 then
        Effect_btn:setSelectedIndex(1)
    end
    local Effect_menu = cc.Menu:create(Effect_btn)
    Effect_menu:setPosition(cc.p(0, 0))
    self:addChild(Effect_menu)

    -- 放置特效文字
    local EffectLabel = cc.LabelTTF:create("特效", BoldFont, 36.0)
    EffectLabel:setColor(cc.c3b(255, 255, 255))
    -- EffectLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    EffectLabel:setPosition(cc.p(Effect_btn:getContentSize().width * 0.5, -EffectLabel:getContentSize().height * 0.45))
    Effect_btn:addChild(EffectLabel)


    -- 增加版本号文本
    local versionLabel = cc.LabelTTF:create("游戏版本号：1.0", BoldFont, 30.0)
    versionLabel:setColor(BaseColor)
    versionLabel:setPosition(cc.p(visibleSize.width * 0.5, Effect_btn:getPositionY() - Effect_btn:getContentSize().height * 1.3))
    self:addChild(versionLabel)


--[[
    -- 添加微信按钮
    local Weixin_btn = cc.MenuItemImage:create("Images/UI/weixin.png", "Images/UI/weixin.png")
    Weixin_btn:registerScriptTapHandler(function()
        -- self:close()
        ToastUtil:toastString("功能暂未开启，敬请期待！")
    end)
    Weixin_btn:setPosition(0.5*visibleSize.width, self.centerPos.y - Weixin_btn:getContentSize().height *1.5)
    local Weixin_menu = cc.Menu:create(Weixin_btn)
    Weixin_menu:setPosition(cc.p(0, 0))
    self:addChild(Weixin_menu)

    -- 放置微信文字
    local WeixinLabel = cc.LabelTTF:create("微信", BoldFont, 36.0)
    WeixinLabel:setColor(cc.c3b(255, 255, 255))
    -- WeixinLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    WeixinLabel:setPosition(cc.p(Weixin_btn:getContentSize().width * 0.5, -WeixinLabel:getContentSize().height * 0.45))
    Weixin_btn:addChild(WeixinLabel)




    -- 添加好评按钮
    local Saygood_btn = cc.MenuItemImage:create("Images/UI/haoping.png", "Images/UI/haoping.png")
    Saygood_btn:registerScriptTapHandler(function()
        -- self:close()
        openUrlFunc()
        -- ToastUtil:toastString("功能暂未开启，敬请期待！")
    end)
    Saygood_btn:setPosition(0.25*visibleSize.width, self.centerPos.y - Saygood_btn:getContentSize().height *1.5)
    local Saygood_menu = cc.Menu:create(Saygood_btn)
    Saygood_menu:setPosition(cc.p(0, 0))
    self:addChild(Saygood_menu)

    -- 放置好评文字
    local SaygoodLabel = cc.LabelTTF:create("好评", BoldFont, 36.0)
    SaygoodLabel:setColor(cc.c3b(255, 255, 255))
    -- SaygoodLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    SaygoodLabel:setPosition(cc.p(Saygood_btn:getContentSize().width * 0.5, -SaygoodLabel:getContentSize().height * 0.45))
    Saygood_btn:addChild(SaygoodLabel)




    -- 添加微博按钮
    local weibo_btn = cc.MenuItemImage:create("Images/UI/weibo.png", "Images/UI/weibo.png")
    weibo_btn:registerScriptTapHandler(function()
        -- self:close()
        ToastUtil:toastString("功能暂未开启，敬请期待！")
    end)
    weibo_btn:setPosition(0.75*visibleSize.width, self.centerPos.y - weibo_btn:getContentSize().height *1.5)
    local Weibo_menu = cc.Menu:create(weibo_btn)
    Weibo_menu:setPosition(cc.p(0, 0))
    self:addChild(Weibo_menu)

    -- 放置微博文字
    local weiboLabel = cc.LabelTTF:create("微博", BoldFont, 36.0)
    weiboLabel:setColor(cc.c3b(255, 255, 255))
    -- weiboLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    weiboLabel:setPosition(cc.p(weibo_btn:getContentSize().width * 0.5, -weiboLabel:getContentSize().height * 0.45))
    weibo_btn:addChild(weiboLabel)
--]]

-- [[
------------------------------------------- DEBUG菜单 ----------------------------------------
    local sharegetLabel = cc.LabelTTF:create("分享奖励10钻石", BoldFont, 36.0)
    sharegetLabel:setColor(WriteColor)
    -- sharegetLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)

    local tapNum = 0
    local bIsCanCallBack = false
    local debugItem = cc.MenuItemLabel:create(sharegetLabel)
    debugItem:setOpacity(0.0)
    debugItem:setPosition(0.5 * visibleSize.width, self.originPos.y)
    debugItem:registerScriptTapHandler(function()
        if zqDebug then
            tapNum = tapNum + 1

            local function cleanTapNum()
                -- body
                tapNum = 0
            end

            local function setCanCallBack()
                -- body
                bIsCanCallBack = true
            end

            if tapNum == 1 then
                bIsCanCallBack = false
                self:stopAllActions()
                self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.CallFunc:create(setCanCallBack)))
                self:runAction(cc.Sequence:create(cc.DelayTime:create(2.0), cc.CallFunc:create(cleanTapNum)))
            end

            if tapNum == 6 then
                if not bIsCanCallBack then
                    cleanTapNum()
                    return
                end
                cclog("点击了DEBUG按钮")
                local _alert = AlertView:create(0,0, "DEBUG菜单",nil)

                -- 添加顶部的说明文字
                -- local infoLabel = cc.LabelTTF:create("DEBUG菜单", BoldFont, 28.0)
                -- infoLabel:setColor(BaseColor)
                -- -- infoLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
                -- infoLabel:setPosition(cc.p(_alert.s_position.x, _alert.s_position.y + 114))
                -- _alert:addChild(infoLabel)

                local _menuButton1 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton1:registerScriptTapHandler(function ()
                    -- body
                    DataManager:getInstance():addCoin(10000)
                    -- _alert:removeFromParent()
                end)

                local _menuButton2 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton2:registerScriptTapHandler(function ()
                    -- body
                    DataManager:getInstance():addDiamond(10000)
                    -- _alert:removeFromParent()
                end)

                local _menuButton3 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton3:registerScriptTapHandler(function ()
                    -- body
                    ToastUtil:downString("地图迷雾全开，去看看吧，欢迎吐槽")
                    mapPermissions.fog = true
                    _alert:removeFromParent()
                end)

                local _menuButton4 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton4:registerScriptTapHandler(function ()
                    -- ToastUtil:downString("功能开发中，敬请期待哦~")
                    SaveDataManager:getInstance():SaveData("{}", "gameRole")
                    for i = 1, 16 do
                        SaveDataManager:getInstance():SaveData("{}", "gameMap"..i)
                    end
                    os.exit(0)
                    _alert:removeFromParent()
                end)

                local _menuButton5 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton5:registerScriptTapHandler(function ()
                    -- body
                    for i = 1006, 1030 do
                        if i ~= 1021 then
                            DataManager:getInstance():addPackItemWithId(i .. "", 10000)
                        end
                    end
                end)

                local _menuButton6 = cc.MenuItemImage:create("Images/btn/ann05_a.png", "Images/btn/ann05_b.png")
                _menuButton6:registerScriptTapHandler(function ()
                    -- body
                    ToastUtil:downString("你说你是不是闲的蛋疼\n没标题的按钮你都点。。。")
                end)

                local _menuButton1Lable = cc.LabelTTF:create("加1w金币", BoldFont, 30.0)
                _menuButton1Lable:setPosition(cc.p(_menuButton1:getContentSize().width * 0.5,_menuButton1:getContentSize().height * 0.5))
                _menuButton1:addChild(_menuButton1Lable)

                local _menuButton2Lable = cc.LabelTTF:create("加1w钻石", BoldFont, 30.0)
                _menuButton2Lable:setPosition(cc.p(_menuButton2:getContentSize().width * 0.5,_menuButton2:getContentSize().height * 0.5))
                _menuButton2:addChild(_menuButton2Lable)

                local _menuButton3Lable = cc.LabelTTF:create("迷雾全开", BoldFont, 30.0)
                _menuButton3Lable:setPosition(cc.p(_menuButton3:getContentSize().width * 0.5,_menuButton3:getContentSize().height * 0.5))
                _menuButton3:addChild(_menuButton3Lable)

                local _menuButton4Lable = cc.LabelTTF:create("清空存档", BoldFont, 30.0)
                _menuButton4Lable:setPosition(cc.p(_menuButton4:getContentSize().width * 0.5, _menuButton4:getContentSize().height * 0.5))
                _menuButton4:addChild(_menuButton4Lable)

                local _menuButton5Lable = cc.LabelTTF:create("常用道具+1w", BoldFont, 30.0)
                _menuButton5Lable:setPosition(cc.p(_menuButton5:getContentSize().width * 0.5, _menuButton5:getContentSize().height * 0.5))
                _menuButton5:addChild(_menuButton5Lable)

                _menuButton1:setPosition(cc.p(_alert.s_position.x - 150, _alert.s_position.y + _menuButton1:getContentSize().height * 2 - 46))
                _menuButton2:setPosition(cc.p(_alert.s_position.x - 150, _alert.s_position.y - 26))
                _menuButton3:setPosition(cc.p(_alert.s_position.x - 150, _alert.s_position.y - _menuButton1:getContentSize().height * 2 - 6))

                _menuButton4:setPosition(cc.p(_alert.s_position.x + 150, _menuButton1:getPositionY()))
                _menuButton5:setPosition(cc.p(_alert.s_position.x + 150, _menuButton2:getPositionY()))
                _menuButton6:setPosition(cc.p(_alert.s_position.x + 150, _menuButton3:getPositionY()))

                local menu = cc.Menu:create(_menuButton1, _menuButton2, _menuButton3, _menuButton4, _menuButton5, _menuButton6)
                menu:setPosition(0.0, 0.0)
                _alert:addChild(menu)

                tapNum = 0
            end
        end
    end)

    local debugMenu = cc.Menu:create(debugItem)
    debugMenu:setPosition(cc.p(0, 0))
    self:addChild(debugMenu)
--]]
	return true
end