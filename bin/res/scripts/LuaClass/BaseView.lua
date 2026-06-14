require "LuaClass/Header"
require "LuaClass/DataManager"
require "LuaClass/EffectUtil"
require "AudioEngine"
require "LuaClass/RandomEventMode"

BaseViewLastClickCDTime = 0

BaseView = class("BaseView", function ()
    return cc.Layer:create()
end)

BaseView.__index = BaseView
BaseView.centerPos = cc.p(0, 0)
BaseView.originPos = cc.p(0, 0)
BaseView.infoScrollView = nil
BaseView.infoScrollViewContainer = nil
BaseView.infoLabel = nil
BaseView.titleLabel = nil
BaseView.topLeftBtn = nil
BaseView.topLeftBtnLabel = nil
BaseView.topRightBtn = nil
BaseView.topRightBtnLabel = nil
BaseView.areaHeight = 0
BaseView.areaWidth = 0
BaseView.storeMenu = nil
BaseView.titleHeight = 0
BaseView.infoNode = nil
BaseView.titleBg = nil
BaseView.isHaveInfo = false
BaseView.mainBg = nil
BaseView.bgIcon = nil
BaseView.bottomInfoBox = nil
BaseView.infoBoxLabel = nil
BaseView.scrollIndex = -1
BaseView.bIsFirstClick = false

BaseView.LeftBg = nil
BaseView.RightBg = nil

BaseView.leftBtn = nil
BaseView.leftBtnText = nil
BaseView.rightBtn = nil
BaseView.rightBtnText = nil
BaseView.setBtn = nil
BaseView.setBtnText = nil

BaseView.setButtonProgrees = nil
BaseView.bIsCenterBtnCanClick = true
BaseView.setBtnLight = nil

BaseView.pointNode = nil

function BaseView:create()
    local view = BaseView.new()
    if view and view:init() then
        return view
    end
    return nil
end

-- view将要销毁之前执行的方法
function BaseView:viewWillDestory()

end

-- view销毁执行的方法
function BaseView:destory()
    self:superDestory()
end

-- 父类销毁执行的方法
function BaseView:superDestory()
    cclog("BaseView:我自由了")
    pNeedUpdateLayer = nil
end

function BaseView:init()
    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 添加总背景
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB888)
    self.mainBg = cc.Sprite:create("Images/Background/MainBackGround.png")
    self.mainBg:setAnchorPoint(cc.p(0, 0))
    self.mainBg:setPosition(cc.p(0, 0))
    self:addChild(self.mainBg)
    cc.Texture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA8888)

    -- 在总背景上添加图
    self.bgIcon = cc.Sprite:create("Images/Background/cangk.png")
    self.bgIcon:setPosition(cc.p(self.mainBg:getContentSize().width * 0.5, self.mainBg:getContentSize().height * 0.5))
    self.mainBg:addChild(self.bgIcon)

    -- 添加上边标题栏的背景
    self.titleBg = cc.Sprite:create("Images/UI/TitleBg.png")
    self.titleBg:setCascadeOpacityEnabled(true)
    self.titleBg:setPosition(cc.p(visibleSize.width * 0.5, visibleSize.height - UITopHeight - self.titleBg:getContentSize().height * 0.5))
    self:addChild(self.titleBg)

    self.titleHeight = self.titleBg:getContentSize().height

    -- 先分别添加左右背景
    self.LeftBg = cc.Sprite:create("Images/UI/TopDecor.png")
    self.titleBg:addChild(self.LeftBg)

    self.RightBg = cc.Sprite:create("Images/UI/TopDecor.png")
    self.RightBg:setFlippedX(true)
    self.titleBg:addChild(self.RightBg)
 
    -- 计算出当前UI应该有的高度
    self.areaHeight = visibleSize.height - UIBottomHeight - UITopHeight - self.titleBg:getContentSize().height
    self.areaWidth = visibleSize.width - 30.0
    local posY = origin.y + visibleSize.height - UITopHeight - self.titleBg:getContentSize().height - self.areaHeight * 0.5

    self.centerPos = cc.p(origin.x + visibleSize.width * 0.5, posY)
    self.originPos = cc.p(self.centerPos.x - self.areaWidth * 0.5, self.centerPos.y - self.areaHeight * 0.5)

    -- 设置左右背景的位置
    self.LeftBg:setPosition(self.LeftBg:getContentSize().width * 0.75, self.titleBg:getContentSize().height * 0.5)
    self.RightBg:setPosition(visibleSize.width - self.RightBg:getContentSize().width * 0.75, self.LeftBg:getPositionY())

    -- 放置顶部文字
    self.titleLabel = cc.LabelTTF:create("未 知", BoldFont, 46.0)
    self.titleLabel:setColor(WriteColor)
    -- self.titleLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.titleLabel:setPosition(cc.p(visibleSize.width * 0.5, self.LeftBg:getPositionY()))
    self.titleBg:addChild(self.titleLabel)

    -- 添加title左侧的成就按钮
    self.topLeftBtn = cc.MenuItemImage:create("Images/btn/ann02_a.png", "Images/btn/ann02_b.png")
    self.topLeftBtn:registerScriptTapHandler(function() 
        cclog("点击了成就按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        zqDispatch:gotoAchievement()
    end)
    self.topLeftBtn:setPosition(cc.p(self.topLeftBtn:getContentSize().width * 0.6, self.titleBg:getPositionY()))
    self.topLeftBtn:setVisible(false)

    self.topLeftBtnLabel = cc.LabelTTF:create("成 就", BoldFont, 24.0)
    self.topLeftBtnLabel:setColor(WriteColor)
    -- achievementLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.topLeftBtnLabel:setPosition(cc.p(self.topLeftBtn:getContentSize().width * 0.5, self.topLeftBtn:getContentSize().height * 0.5))
    self.topLeftBtn:addChild(self.topLeftBtnLabel, 1)

    -- 添加title右侧的商城按钮
    self.topRightBtn = cc.MenuItemImage:create("Images/DiamondStore/ann05_a.png", "Images/DiamondStore/ann05_b.png")
    self.topRightBtn:registerScriptTapHandler(function() 
        cclog("点击了钻石商城按钮")

        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        GuideController:getInstance():addStep(61)
        zqDispatch:gotoDiamondStore()
    end)
    self.topRightBtn:setPosition(cc.p(visibleSize.width - self.topRightBtn:getContentSize().width * 0.6, self.titleBg:getPositionY()))

    self.topRightBtnLabel = cc.LabelTTF:create("钻石商城", BoldFont, 24.0)
    self.topRightBtnLabel:setColor(WriteColor)
    -- self.topRightBtnLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.topRightBtnLabel:setPosition(cc.p(self.topRightBtn:getContentSize().width * 0.5, self.topRightBtn:getContentSize().height * 0.5))
    self.topRightBtn:addChild(self.topRightBtnLabel, 1)

    local baseViewButtonGroup = {self.topRightBtn, self.topLeftBtn}

    self.storeMenu = cc.Menu:create(unpack(baseViewButtonGroup))
    self.storeMenu:setPosition(0, 0)
    self:addChild(self.storeMenu, 1)

    -- 控制钻石商店红点
    if DataManager:getInstance():isShowDiamondStoreRedPointer() then
        GuideController:getInstance():addRedPoint(self.topRightBtn)
    else
        GuideController:getInstance():removeRedPoint(self.topRightBtn)
    end

    return true;
end

-- 在仓库和资源生产界面修改左侧侧按钮的函数
function BaseView:resetTopLeftButtonToExpedition()
    self.topLeftBtnLabel:setString("设  置")
    self.topLeftBtn:unregisterScriptTapHandler()
    self.topLeftBtn:setNormalImage(cc.Sprite:create("Images/btn/ann02_a.png"))
    self.topLeftBtn:setSelectedImage(cc.Sprite:create("Images/btn/ann02_b.png"))
    self.topLeftBtn:registerScriptTapHandler(function() 
        cclog("点击了设置按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        zqDispatch:gotoSetting()
    end)
    self.topLeftBtn:setVisible(GuideController:getInstance():getIsHaveStep(2))
end

-- 在出征界面修改右侧按钮的函数
function BaseView:resetTopRightButtonToRank()
    self.topRightBtnLabel:setString("排行榜")
    self.topRightBtn:unregisterScriptTapHandler()
    self.topRightBtn:setNormalImage(cc.Sprite:create("Images/btn/ann02_a.png"))
    self.topRightBtn:setSelectedImage(cc.Sprite:create("Images/btn/ann02_b.png"))
    self.topRightBtn:registerScriptTapHandler(function() 
        cclog("点击了排行榜按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        zqDispatch:gotoRanking()
    end)
end

-- 在设置、成就、天赋、钻石商城等界面将右上角按钮改为返回按钮
function BaseView:resetTopRightButtonToBack()
    self.topRightBtnLabel:setString("返  回")
    self.topRightBtn:unregisterScriptTapHandler()
    self.topRightBtn:setNormalImage(cc.Sprite:create("Images/btn/ann02_a.png"))
    self.topRightBtn:setSelectedImage(cc.Sprite:create("Images/btn/ann02_b.png"))
    self.topRightBtn:registerScriptTapHandler(function() 
        cclog("点击了返回按钮")
        if DataManager:getInstance():getSound_off() == 0 then
            AudioEngine.playEffect(EFFECT_Button, false)
        end
        zqDispatch:backToLastView()
    end)
end

--[[
不同的界面处理显示不同的背景
]]
function BaseView:setBackgroundIcon(iconPath)
    -- body
    local tempSpr = cc.Sprite:create(iconPath)
    if nil ~= tempSpr then
        self.bgIcon:setSpriteFrame(tempSpr:getSpriteFrame())
    else
        cclog("shit, 背景资源没有找到。。。路径："..iconPath)
    end
end

--[[
更新下方scrollView的函数，需要的时候将header里的句柄指向这个（要求是每个界面必须有这个函数）
]]
function BaseView:updateInfoLabel(infoString)
    if not self.isHaveInfo then
        return
    end

    local oldcontentHeight = self.infoLabel:getContentSize().height
    local oldInfoString = self.infoLabel:getString()
    -- 开始设置信息
    self.infoLabel:setString(infoString)
    local contentHeight = self.infoLabel:getContentSize().height
    -- printn("文字高度",contentHeight)
    -- printn("infoScrollView高度",self.infoScrollView:getViewSize().height)
    if contentHeight < self.infoScrollView:getViewSize().height then
        contentHeight = self.infoScrollView:getViewSize().height
    end
    if oldcontentHeight < self.infoScrollView:getViewSize().height then
        oldcontentHeight = self.infoScrollView:getViewSize().height
    end

    local oldoffset = self.infoScrollView:getContentOffset()
    -- printn("聊天窗口老的offset",oldoffset)

    -- printn("oldPositionY",self.infoScrollViewContainer:getPositionY())
    -- 重新设置scrollView的高度
    self.infoScrollView:setContentSize(cc.size(self.infoScrollViewContainer:getContentSize().width, contentHeight))
    -- 如果移动到可以自己往上推的区间，那么保证scrollView的位置永远是在顶部
    -- print("固定值：", (-(contentHeight - self.infoScrollView:getViewSize().height - 24.0) + 20.0), contentHeight)
    -- print("oldcontentHeight:::::::", oldcontentHeight, oldoffset.y)
    local duration = 0.3
    if contentHeight - oldcontentHeight > 30.0 then
        duration = 0.0
    end
    if contentHeight > self.infoScrollView:getViewSize().height then
        if oldoffset.y < (-(contentHeight - self.infoScrollView:getViewSize().height) + 27.0) then
            -- print("走了这里了哦~~~~~~~~~")
            self.infoScrollView:setContentOffsetInDuration(cc.p(0, -(contentHeight - self.infoScrollView:getViewSize().height)), duration)
        else
            if contentHeight > oldcontentHeight then
                -- print("走了这里，所以出错了~！~~~~~")
                self.infoScrollView:setContentOffsetInDuration(cc.p(0, oldoffset.y - (contentHeight - oldcontentHeight)), duration)
            end
        end
    end
    -- 为了表现效果一致，当高度固定的时候，再次做一次label的虚拟移动
    if self.infoScrollView:getViewSize().height == contentHeight and oldInfoString ~= infoString and oldInfoString ~= " " then
        self.infoLabel:setPositionY(contentHeight + 26.0)
        self.infoLabel:runAction(cc.MoveTo:create(duration, cc.p(0, contentHeight)))
    else
        self.infoLabel:setPosition(cc.p(0, contentHeight))
    end
    -- local newoffset = self.infoScrollView:getContentOffset()
    -- printn("聊天窗口xin的offset",newoffset)
    
    self.infoScrollView:setTouchEnabled(self.infoLabel:getContentSize().height > self.infoScrollView:getViewSize().height)
end

--[[
显示下方的信息框，必须要有下方的info区域才会显示
]]
function BaseView:showInfoBox(infoString)
    if (not self.isHaveInfo) or infoString == nil or infoString == "" then
        return
    end
    self.bIsFirstClick = true
    self.infoBoxLabel:setString(infoString)
    self.bottomInfoBox:setVisible(true)
end

--[[
修改title的操作
]]
function BaseView:setTitleString(str)
    if self.titleLabel ~= nil then
        self.titleLabel:setString(str)
        -- 重新设置左右装饰的位置
        self.LeftBg:setPosition(self.centerPos.x - self.titleLabel:getContentSize().width * 0.5 - self.LeftBg:getContentSize().width * 0.52, self.LeftBg:getPositionY())
        self.RightBg:setPosition(self.centerPos.x + self.titleLabel:getContentSize().width * 0.5 + self.RightBg:getContentSize().width * 0.52, self.RightBg:getPositionY())
    end
end

--[[
设置title条隐藏或者显示的函数
]]
function BaseView:setTitleVisible(bIsVisible)
    self.titleBg:setVisible(bIsVisible)
    self.LeftBg:setVisible(bIsVisible)
    self.RightBg:setVisible(bIsVisible)
    self.titleLabel:setVisible(bIsVisible)
    self.storeMenu:setVisible(bIsVisible)
end

--[[
添加信息界面的函数（注意一定要在子类的init方法开头调用，否则获得的区域不正确）
leftTitle           : 向左按钮的文字，如果存在传string，不存在传nil
leftFunc            : 向左按钮的回调函数，不存在传nil
rightTitle          : 同leftTitle
rightFunc           : 同leftFunc
middleNormalImage   : 中间那个按钮的未选中图
middleSelectedImage : 中间那个按钮的选中后的图
middleFunc          : 中间那个按钮的回调
middleCaptionImage  : 中间那个按钮的caption图
bIsNeedProgress     : 中间那个按钮是否是progress
progressTime        : 中间progress按钮的倒计时间
bIsNeedBtnLight     : 是否显示按钮光效
]]
function BaseView:addInfoNode(leftTitle, leftFunc, rightTitle, rightFunc, middleNormalImage, middleSelectedImage, middleFunc, middleCaptionImage, bIsNeedProgress, progressTime, bIsNeedBtnLight)
    -- 赋初始值
    if middleCaptionImage == nil then
        middleCaptionImage = "Images/MainMenu/w_lianj.png"
    end
    if bIsNeedProgress == nil then
        bIsNeedProgress = false
    end
    if progressTime == nil then
        progressTime = 0.0
    end
    if bIsNeedBtnLight == nil then
        bIsNeedBtnLight = true
    end

    local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    self.isHaveInfo = true

    -- 添加各个界面下边的数据层
    self.infoNode = cc.Layer:create()
    self.infoNode:setPosition(cc.p(0, UIBottomHeight))
    self.infoNode:setContentSize(cc.size(self.areaWidth, 230 * visibleSize.height / 1136))
    self:addChild(self.infoNode)

    -- 添加顶部的分割线
    local topSplit = cc.Sprite:create("Images/UI/InfoSplit.png")
    topSplit:setPosition(cc.p(visibleSize.width * 0.5, self.infoNode:getContentSize().height))
    self.infoNode:addChild(topSplit)

    -- 根据传进来的数据判断添加左右按钮
    local btnArr = {}
    -- local spriteFrame = cc.SpriteFrameCache:getInstance()
    -- for i = 1, 4 do
    --     local sprName = string.format("Images/UI/jiant_%02d.png", i)
    --     local tempSprite = cc.Sprite:create(sprName)
    --     if tempSprite ~= nil then
    --         spriteFrame:addSpriteFrame(tempSprite:getSpriteFrame(), sprName)
    --     end
    -- end

    -- if leftTitle ~= nil then
    --     local leftNormalBtn = cc.Sprite:createWithSpriteFrameName("Images/UI/jiant_01.png")
    --     local leftAni = EffectUtil:getAnimate("Images/UI/jiant_%02d.png", 1, 4, 0.2)
    --     leftNormalBtn:runAction(cc.RepeatForever:create(leftAni))
    --     leftNormalBtn:setFlippedX(true)

    --     local lSpr = cc.Sprite:create("Images/UI/middleBtn.png")
    --     local rSpr = cc.Sprite:create("Images/UI/middleBtn.png")
    --     lSpr:setFlippedX(true)
    --     rSpr:setFlippedX(true)
    --     self.leftBtn = cc.MenuItemSprite:create(lSpr, rSpr)
    --     self.leftBtn:registerScriptTapHandler(leftFunc)
    --     self.leftBtn:setPosition(cc.p(self.leftBtn:getContentSize().width * 0.5, self.infoNode:getContentSize().height - self.leftBtn:getContentSize().height * 0.5))
    --     leftNormalBtn:setPosition(cc.p(leftNormalBtn:getContentSize().width * 0.55, self.leftBtn:getContentSize().height * 0.5))
    --     self.leftBtn:addChild(leftNormalBtn)

    --     self.leftLabelBtn = cc.LabelTTF:create(leftTitle, BoldFont, 28.0)
    --     self.leftLabelBtn:setColor(BaseColor)
    --     self.leftLabelBtn:setPosition(cc.p(leftNormalBtn:getPositionX() + leftNormalBtn:getContentSize().width * 0.5 + self.leftLabelBtn:getContentSize().width * 0.55, leftNormalBtn:getPositionY()))
    --     self.leftBtn:addChild(self.leftLabelBtn)

    --     table.insert(btnArr, self.leftBtn)
    -- end

    -- if rightTitle ~= nil then
    --     local rightNormalBtn = cc.Sprite:createWithSpriteFrameName("Images/UI/jiant_01.png")
    --     local rightAni = EffectUtil:getAnimate("Images/UI/jiant_%02d.png", 1, 4, 0.2)
    --     rightNormalBtn:runAction(cc.RepeatForever:create(rightAni))
    --     self.rightBtn = cc.MenuItemImage:create("Images/UI/middleBtn.png", "Images/UI/middleBtn.png")
    --     self.rightBtn:registerScriptTapHandler(rightFunc)
    --     self.rightBtn:setPosition(cc.p(visibleSize.width - self.rightBtn:getContentSize().width * 0.5, self.infoNode:getContentSize().height - self.rightBtn:getContentSize().height * 0.5))
    --     rightNormalBtn:setPosition(cc.p(self.rightBtn:getContentSize().width - rightNormalBtn:getContentSize().width * 0.55, self.rightBtn:getContentSize().height * 0.5))
    --     self.rightBtn:addChild(rightNormalBtn)

    --     self.rightLabelBtn = cc.LabelTTF:create(rightTitle, BoldFont, 28.0)
    --     self.rightLabelBtn:setColor(BaseColor)
    --     -- rightLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    --     self.rightLabelBtn:setPosition(cc.p(rightNormalBtn:getPositionX() - rightNormalBtn:getContentSize().width * 0.5 - self.rightLabelBtn:getContentSize().width * 0.55, rightNormalBtn:getPositionY()))
    --     self.rightBtn:addChild(self.rightLabelBtn)

    --     table.insert(btnArr, self.rightBtn)
    -- end

    -- 添加顶部的炼金按钮及其装饰
    local btnDecor = cc.Sprite:create("Images/MainMenu/di_a.png")
    btnDecor:setPosition(cc.p(visibleSize.width * 0.5, self.infoNode:getContentSize().height - btnDecor:getContentSize().height * 0.55))
    self.infoNode:addChild(btnDecor, 1)

    self.setBtn = SDButton:create(middleNormalImage, middleSelectedImage)
    if bIsNeedProgress then
        self.setBtn = SDButton:create(middleNormalImage, middleNormalImage)
    end
    self.setBtn:setPosition(btnDecor:getPosition())
    -- table.insert(btnArr, self.setBtn)
    self.infoNode:addChild(self.setBtn, 1)

    self.setButtonProgrees = cc.ProgressTimer:create(cc.Sprite:create(middleSelectedImage))
    self.setButtonProgrees:setPercentage(0)
    self.setButtonProgrees:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.setButtonProgrees:setPosition(cc.p(self.setBtn:getContentSize().width * 0.5, self.setBtn:getContentSize().height * 0.5))
    self.setButtonProgrees:setVisible(bIsNeedProgress)
    self.setBtn:addChild(self.setButtonProgrees)

    -- 添加中间按钮的文字
    self.setBtnText = cc.Sprite:create(middleCaptionImage)
    self.setBtnText:setPosition(cc.p(self.setBtn:getPositionX(), self.setBtn:getPositionY() - self.setBtn:getContentSize().height * 0.4))
    self.infoNode:addChild(self.setBtnText, 1)

    require "LuaClass/NotificationNode"
    -- print("上一次的时间：", BaseViewLastClickCDTime)
    local iscanclick = true
    local function openclick()
        -- cclog("open了")
        self.bIsCenterBtnCanClick = true
        self.setButtonProgrees:setPercentage(0)
        if bIsNeedProgress and self.setBtnLight ~= nil then
            self.setBtnLight:setVisible(true)
        end
        self.setBtn:runAction(cc.ScaleTo:create(0.0, 1.0))
    end
    local function dealclick()
        -- cclog("执行了")
        if bIsNeedProgress and bIsNeedBtnLight then
             BaseViewLastClickCDTime = os.time()
        end
        middleFunc()
        if bIsNeedProgress and self.setBtnLight ~= nil then
            self.setBtnLight:setVisible(false)
        end
    end 
    
    local function progressSetBtn()
        -- cclog("点击了中间的按钮,没走过新手引导第一步的时候不允许点击") and GuideController:getInstance():getIsHaveStep(1)
        if self.bIsCenterBtnCanClick then
            self.bIsCenterBtnCanClick = false
            
            -- cclog("触发了点击")
            local act2 = cc.CallFunc:create(dealclick)
            local act3 = cc.ProgressTo:create(progressTime, 100)
            local act4 = cc.CallFunc:create(openclick)
            self.setButtonProgrees:stopAllActions()
            self.setButtonProgrees:runAction(cc.Sequence:create(act2,act3,act4))
            -- 播放按钮点击动画
            self.setBtn:stopAllActions()
            self.setBtn:runAction(cc.Sequence:create(cc.ScaleTo:create(0.0, 0.1), cc.EaseElasticOut:create(cc.ScaleTo:create(0.6, 1.0))))
        end
    end
    self.setBtn:registerSingleCLick(progressSetBtn)

    -- 因为是新加上的存档内容，所以要做容错
    local canLongPress = DataManager:getInstance():getRoleData(roleAlchemyCanLongPress)
    if canLongPress == nil then
        canLongPress = 0
        DataManager:getInstance():setRoleData(roleAlchemyCanLongPress, canLongPress)
    end
    if canLongPress == 1 then
        self.setBtn:registerLongPressed(progressSetBtn)
    end

    if bIsNeedBtnLight and self.setBtnLight == nil then
        self.setBtnLight = cc.Sprite:create("Images/UI/pointer.png")
        self.setBtnLight:setPosition(self.setBtn:getPosition())
        self.infoNode:addChild(self.setBtnLight, -1)
        self.setBtnLight:setVisible(false)
        self.setBtnLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.0),cc.ScaleTo:create(0, 1.5), cc.Spawn:create(cc.EaseExponentialIn:create(cc.FadeTo:create(0.8, 128.0)), cc.ScaleTo:create(0.8, 3.3)))))
    end

    -- 都初始化完了设置显示或者隐藏状态
    if bIsNeedProgress then
        local nowTime = os.time()
        if nowTime - BaseViewLastClickCDTime < progressTime then
            if bIsNeedBtnLight then
                self.setBtnLight:setVisible(false)
            end
            self.bIsCenterBtnCanClick = false
            self.setButtonProgrees:stopAllActions()
            local persent = nowTime - BaseViewLastClickCDTime
            if persent > progressTime then
                persent = 0
            end
            local act3 = cc.ProgressTo:create(progressTime, 100)
            local act4 = cc.CallFunc:create(openclick)
            local newPersent = math.floor((persent / progressTime) * 100)
            -- print("新的百分比：", newPersent, persent, progressTime)
            self.setButtonProgrees:setPercentage(newPersent)
            self.setButtonProgrees:runAction(cc.Sequence:create(act3, act4))
        else
            if bIsNeedBtnLight then
                self.setBtnLight:setVisible(true)
            end
        end
    end

    -- 添加左侧天赋按钮
    self.leftBtn = cc.MenuItemImage:create("Images/MainMenu/tianf_a.png", "Images/MainMenu/tianf_b.png")
    self.leftBtn:setPosition(cc.p(self.setBtn:getPositionX() - 253, self.setBtn:getPositionY() + 12))
    self.leftBtn:registerScriptTapHandler(function()
        -- body
        if GuideController:getInstance():getIsHaveStep(8) then
            zqDispatch:moveToTalent()
        else
            ToastUtil:downString("您需要建造船坞，可激活该功能")
        end
    end)
    table.insert(btnArr, self.leftBtn)

    -- 控制天赋红点
    if GuideController:getInstance():getIsHaveStep(401, true) then
        GuideController:getInstance():removeRedPoint(self.leftBtn)
    else
        GuideController:getInstance():addRedPoint(self.leftBtn)
    end

    -- 添加天赋按钮的文字
    self.leftBtnText = cc.Sprite:create("Images/MainMenu/w_tianf.png")
    self.leftBtnText:setPosition(cc.p(self.leftBtn:getPositionX(), self.leftBtn:getPositionY() - self.leftBtn:getContentSize().height * 0.6))
    self.infoNode:addChild(self.leftBtnText, 1)

    if GuideController:getInstance():getIsHaveStep(8) then
        self.leftBtnText:setOpacity(255.0)
        self.leftBtn:setOpacity(255.0)
    else
        self.leftBtnText:setOpacity(51.0)
        self.leftBtn:setOpacity(51.0)
    end

    -- 添加右侧情报按钮,情报按钮建造了船坞之后才显示
    self.rightBtn = cc.MenuItemImage:create("Images/MainMenu/qingb_a.png", "Images/MainMenu/qingb_b.png")
    self.rightBtn:setPosition(cc.p(self.setBtn:getPositionX() + 253, self.leftBtn:getPositionY()))
    self.rightBtn:registerScriptTapHandler(function()
        -- body
        if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil and not isEnterMap then
            cclog("点击了情报按钮")
            local view = RandomEventView:create()
            view:show()
        else
            ToastUtil:downString("您需要建造船坞并出征\n之后方可激活该功能")
        end
    end)
    table.insert(btnArr, self.rightBtn)

    -- 添加右侧情报按钮高亮
    require "LuaClass/MissionManagers"
    local waitingMissions = MissionManagers:getInstance():getWaitingMissions()
    if waitingMissions.len > 0 or #RandomEventManager:getInstance().eventList > 0 then
        -- local rightLight = cc.Sprite:create("Images/UI/pointer.png")
        -- rightLight:setPosition(self.rightBtn:getPosition())
        -- self.infoNode:addChild(rightLight, -1)
        -- rightLight:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.FadeIn:create(0.0),cc.ScaleTo:create(0, 0.6), cc.Spawn:create(cc.EaseExponentialIn:create(cc.FadeTo:create(0.8, 128.0)), cc.ScaleTo:create(0.8, 1.9)))))
        GuideController:getInstance():addRedPoint(self.rightBtn)
    end

    -- 添加天赋按钮的文字
    self.rightBtnText = cc.Sprite:create("Images/MainMenu/w_qingb.png")
    self.rightBtnText:setPosition(cc.p(self.rightBtn:getPositionX(), self.rightBtn:getPositionY() - self.rightBtn:getContentSize().height * 0.6))
    self.infoNode:addChild(self.rightBtnText, 1)

    if DataManager:getInstance():getRoleData(roleMapInfo) ~= nil and not isEnterMap then
        self.rightBtnText:setOpacity(255.0)
        self.rightBtn:setOpacity(255.0)
    else
        self.rightBtnText:setOpacity(51.0)
        self.rightBtn:setOpacity(51.0)
    end

    local infoMenu = cc.Menu:create(unpack(btnArr))
    infoMenu:setPosition(cc.p(0, 0))
    self.infoNode:addChild(infoMenu, 1)

    -- 添加显示信息的scrollView
    self.infoScrollViewContainer = cc.Layer:create()
    -- self.scrollViewContainer:setContentSize(bigInfoSize)
    local scrollViewSize = cc.size(self.areaWidth, self.setBtn:getPositionY() - self.setBtn:getContentSize().height * 0.6)
    self.infoScrollView = cc.ScrollView:create(scrollViewSize)
    self.infoScrollView:setPosition(cc.p(self.originPos.x, 10.0))
    self.infoScrollView:setContainer(self.infoScrollViewContainer) -- 設置容器
    self.infoScrollView:setViewSize(scrollViewSize) 
    self.infoScrollView:setClippingToBounds(true) -- 設置剪切
    self.infoScrollView:setBounceable(true)  -- 設置彈性效果
    self.infoScrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    self.infoScrollView:setDelegate()
    self.infoScrollView:registerScriptHandler(function()

    end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.infoScrollView:registerScriptHandler(function()

    end,cc.SCROLLVIEW_SCRIPT_ZOOM)
    self.infoNode:addChild(self.infoScrollView)

    -- 添加scrollView上的label
    self.infoLabel = cc.LabelTTF:create(" ", BoldFont, 24.0)
    self.infoLabel:setAnchorPoint(cc.p(0.0, 1.0))
    self.infoLabel:setColor(WriteColor)
    self.infoLabel:setHorizontalAlignment(0)
    self.infoLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
    -- self.infoLabel:enableStroke(cc.c4b(16, 16, 16, 255), 2)
    self.infoLabel:setPosition(cc.p(0, 0))
    self.infoLabel:setDimensions(cc.size(self.infoScrollView:getViewSize().width, 0))
    self.infoScrollViewContainer:addChild(self.infoLabel)

    -- 添加下边的点点承载节点
    local infoBoxSize = cc.size(self.areaWidth * 0.8, 180)

    -- 添加信息框
    local tempSpr = cc.Sprite:create("Images/UI/MaskBg_1.png")
    self.bottomInfoBox = cc.Scale9Sprite:create("Images/UI/MaskBg_1.png", cc.rect(0, 0, tempSpr:getContentSize().width, tempSpr:getContentSize().height), cc.rect(12, 12, tempSpr:getContentSize().width - 24, tempSpr:getContentSize().height - 24))
    self.bottomInfoBox:setContentSize(infoBoxSize)
    self.bottomInfoBox:setPosition(cc.p(self.centerPos.x, self.infoNode:getContentSize().height - infoBoxSize.height * 0.5))
    self.bottomInfoBox:setVisible(false)
    self.infoNode:addChild(self.bottomInfoBox, 99999)

    -- 添加信息框上的文本
    self.infoBoxLabel = cc.LabelTTF:create("unknown", BoldFont, 26.0)
    self.infoBoxLabel:setColor(BaseColor)
    -- self.infoBoxLabel:enableStroke(cc.c4b(16, 16, 16, 255), 1)
    self.infoBoxLabel:setPosition(cc.p(self.bottomInfoBox:getContentSize().width * 0.5, self.bottomInfoBox:getContentSize().height * 0.5))
    self.bottomInfoBox:addChild(self.infoBoxLabel)

    local function onTouchBegan(touch, event)
        local location = touch:getLocation()
        -- cclog("Dispatch touchBeginPoint")
        -- 如果在下方点击区域内，那么吸收点击事件
        return true
    end

    local function onTouchMoved(touch, event)

    end

    local function onTouchEnded(touch, event)
        local location = touch:getLocation()
        if not self.bIsFirstClick then
            -- print("baseView响应点击事件")
            self.bottomInfoBox:setVisible(false)
        else
            -- print("baseView不响应点击事件")
            self.bIsFirstClick = false
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self.infoNode:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.infoNode)

    -- 重新设置自己的可用区域
    self.areaHeight = visibleSize.height - UIBottomHeight - UITopHeight - self.titleBg:getContentSize().height - self.infoNode:getContentSize().height
    local posY = origin.y + visibleSize.height - UITopHeight - self.titleBg:getContentSize().height - self.areaHeight * 0.5

    self.centerPos = cc.p(origin.x + visibleSize.width * 0.5, posY)
    self.originPos = cc.p(self.centerPos.x - self.areaWidth * 0.5, self.centerPos.y - self.areaHeight * 0.5)

end