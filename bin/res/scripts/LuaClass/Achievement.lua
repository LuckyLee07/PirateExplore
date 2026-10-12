require "LuaClass/Header"
require "LuaClass/DialogTheme"
require "LuaClass/BaseView"
require "LuaClass/UIKit"
require "LuaClass/Utils"
require "LuaClass/SDButton"

AchievementLayer = class("AchievementLayer", function ()
    return BaseView:create()
end)

AchievementLayer.__index = AchievementLayer
AchievementLayer.scrollView = nil
AchievementLayer.scrollViewContainer = nil
AchievementLayer.scrollViewHeight = 0

function AchievementLayer:create()
    local view = AchievementLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function AchievementLayer:destory()
    if self.achievementDisposed then return end
    self.achievementDisposed=true
    require('LuaClass/ProgressSupportPresentation').dispose(self)
    GuideController:getInstance():addStep(402, true)
    self:superDestory()
end

function AchievementLayer:init()
    self.achievementDisposed=false
    if require("LuaClass/WarmTheme").enabled() then return self:initCoherentAchievement() end
	local visibleSize = cc.Director:getInstance():getVisibleSize()
    local origin = cc.Director:getInstance():getVisibleOrigin()

    -- 设置title文字
    self.titleLabel:setString("成 就")

    -- 隐藏上边左侧的按钮
    self.topLeftBtn:setVisible(false)

    -- 修改右侧按钮为返回
    self:resetTopRightButtonToBack()

    -- 设置下方信息界面
    self:addInfoNode(nil, nil, nil, function()
        zqDispatch:moveToExpedition()
    end, "Images/MainMenu/an_lianj_a.png", "Images/MainMenu/an_lianj_b.png", function()
        -- cclog("点击了炼金按钮")
        DataManager:getInstance():AlchemyButtonDidClick()
    end, nil, true, zqAlchemyTime, false)

    
    -- -- 设置天赋界面中间部分大小、位置
    -- local scrollViewSize = cc.size(self.areaWidth, self.areaHeight)
    -- self.scrollViewContainer = cc.Layer:create()
    -- self.scrollView = cc.ScrollView:create(scrollViewSize)
    -- self.scrollView:setPosition(self.originPos)
    -- self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    -- self.scrollViewContainer:setPosition(cc.p(0.0, 5.0))
    -- self.scrollView:setClippingToBounds(true) -- 設置剪切
    -- self.scrollView:setBounceable(true)  -- 設置彈性效果
    -- self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    -- self.scrollView:setDelegate()
    -- self.scrollView:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- self:addChild(self.scrollView)

    DialogTheme.applyBase(self)

    self:loadAchievementData()

    require('LuaClass/ProgressSupportPresentation').listen(self,{roleAchievement,roleTalent},function()
        self:loadAchievementData()
    end)

    return true
end

function AchievementLayer:loadAchievementData()
    if self.achievementDisposed then return end
    if self.supportWarm then return self:loadCoherentAchievementData() end
    -- body
    local achievementData = DataManager:getInstance():getRoleData(roleAchievement)

    local achievementPointLabel = self:getChildByTag(2)
    if (achievementPointLabel ~= nil) then
        achievementPointLabel:removeFromParent()
    end
    achievementPointLabel = cc.LabelTTF:create("成就点数：" .. DataManager:getInstance():getRoleData(roleAchievementPoint), MasterTheme.headingFont(false), 32.0)
    achievementPointLabel:setAnchorPoint(cc.p(0.0, 0.5))
    achievementPointLabel:setColor(MasterTheme.colors.white)
    DialogTheme.fit(achievementPointLabel, self.areaWidth - 50)
    achievementPointLabel:setPosition(cc.p(0.0, self.originPos.y + self.areaHeight - achievementPointLabel:getContentSize().height * 0.5))
    achievementPointLabel:setTag(2)
    self:addChild(achievementPointLabel)

    self.scrollViewHeight = self.areaHeight - achievementPointLabel:getContentSize().height

    -- 自动学习天赋
    local tallentCsvData = DataManager:getInstance():getCSVByID(csvOfTalent)
    local unlocked = getRowDataFromMatrixBySpecifiedKeyAndValue(DataManager:getInstance():getLockedTallent(), dataKeyAutoType, {[1]="1"})

    local unlockedAchievement = sortTableOrderByASC(unlocked, dataKeyAchievement)
    local trigerLabel = nil
    if (unlockedAchievement ~= nil) then
        if (unlockedAchievement[1] ~= nil) then
            trigerLabel = self:getChildByTag(3)
            if (trigerLabel ~= nil) then
                trigerLabel:removeFromParent()
            end
            trigerLabel = cc.LabelTTF:create("点数达到" .. unlockedAchievement[1][dataKeyAchievement] .. "会获得神秘天赋奖励", MasterTheme.headingFont(false), 27.0)
            trigerLabel:setAnchorPoint(cc.p(0.0, 0.5))
            trigerLabel:setColor(MasterTheme.colors.paper)
            DialogTheme.fit(trigerLabel, self.areaWidth - 50)
            trigerLabel:setPosition(cc.p(0.0, achievementPointLabel:getPositionY() - achievementPointLabel:getContentSize().height * 0.5 - trigerLabel:getContentSize().height * 0.5))
            self:addChild(trigerLabel)
            trigerLabel:setTag(3)
            self.scrollViewHeight = self.scrollViewHeight - trigerLabel:getContentSize().height

        end
    end

    -- 天赋界面中间滚动信息
    local function scrollViewDidScroll()
        -- cclog("scrollView滑动ing")
        -- print("--------- scrollView滑动ing")
    end

    local scrollViewSize = cc.size(self.areaWidth, self.scrollViewHeight)
    self.scrollViewContainer = cc.Layer:create()
    self.scrollView  = self:getChildByTag(1)
    if (self.scrollView ~= nil) then
        self.scrollView:removeFromParent()
    end

    self.scrollView = cc.ScrollView:create(scrollViewSize)
    self.scrollView:setPosition(self.originPos)
    self.scrollView:setContainer(self.scrollViewContainer) -- 設置容器
    self.scrollViewContainer:setPosition(cc.p(0.0, 5.0))
    self.scrollView:setClippingToBounds(true) -- 設置剪切
    self.scrollView.bIsScrollView = true
    self.scrollView:setBounceable(true)  -- 設置彈性效果
    self.scrollView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) -- 設置滾動方向
    -- self.scrollView:setDelegate()
    -- self.scrollView:registerScriptHandler(function()

    -- end, cc.SCROLLVIEW_SCRIPT_SCROLL)
    -- self.scrollView:registerScriptHandler(function()

    -- end,cc.SCROLLVIEW_SCRIPT_ZOOM)
    self.scrollView:setTag(1)
    self:addChild(self.scrollView)

    -- 设置天赋界面中间部分条目
    local getShowInfoBoxData=function(itemData)return self:getAchievementInformation(itemData)end

    local createItem = function (tableData, index, flag)
        -- body
        local container = cc.Node:create()

        -- local button = ccui.Button:create()
        -- container:addChild(button)
        -- button:loadTextures("Images/btn/ann03_a.png","Images/btn/ann03_b.png","")
        -- button:setPosition(cc.p(button:getContentSize().width * 0.5, 0.0))
        -- button:setTag(index)
        -- -- button:setTouchEnabled(true)
        -- button:addTouchEventListener(function (sender, eventType)
        --     -- body
        --     local tag = sender:getTag()

        --     -- local achievementData = DataManager:getInstance():getRoleData(roleAchievement)
        --     local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
        --     local itemData = csvData[tostring(tag)]
        --     local showData = getShowInfoBoxData(itemData)

        --     -- -- --  测试代码    By Jasper.Hsu
        --     -- local point = DataManager:getInstance():getRoleData(roleAchievementPoint)
        --     -- DataManager:getInstance():setRoleData(roleAchievementPoint, (point + 10), nil)
        --     -- showData = showData .. "\n成就点：" .. DataManager:getInstance():getRoleData(roleAchievementPoint) .. ""

        --     --     local _result =  DataManager:getInstance():addCoin(100)

        --     -- -- --  测试代码

        --     self:showInfoBox(showData)


        -- end)

        local button = DialogTheme.sdButton("Images/btn/ann03_a.png","Images/btn/ann03_b.png",function ()
            -- local tag = sender:getTag()
            local tag = index

            -- local achievementData = DataManager:getInstance():getRoleData(roleAchievement)
            local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
            local itemData = csvData[tostring(tag)]
            local showData = getShowInfoBoxData(itemData)

            -- -- --  测试代码    By Jasper.Hsu
            -- local point = DataManager:getInstance():getRoleData(roleAchievementPoint)
            -- DataManager:getInstance():setRoleData(roleAchievementPoint, (point + 10), nil)
            -- showData = showData .. "\n成就点：" .. DataManager:getInstance():getRoleData(roleAchievementPoint) .. ""

            --     local _result =  DataManager:getInstance():addCoin(100)

            -- -- --  测试代码

            self:showInfoBox(showData)
        end, "secondary")
        button:setSwallowTouches(false)
        button:setPosition(cc.p(button:getContentSize().width * 0.5, 0.0))
        button:setTag(index)
        container:addChild(button)

        local buttonLabel = cc.LabelTTF:create(tableData[dataKeyName], MasterTheme.headingFont(false), 32.0)

        buttonLabel:setColor(MasterTheme.colors.white)
        DialogTheme.fit(buttonLabel, button:getContentSize().width - 24)
        buttonLabel:setPosition(cc.p(button:getContentSize().width * 0.5, button:getContentSize().height * 0.5))
        button:addChild(buttonLabel)

        -- local flag = tableData[dataKeyFlag]

        -- 开启
        if (flag > 0) then
            local openFlagSprite = cc.Sprite:create("Images/UI/cjdh.png")
            -- openFlagSprite:setPosition(cc.p(button:getContentSize().width, 0))
            openFlagSprite:setPosition(cc.p(button:getContentSize().width - 15, button:getContentSize().height - 12))
            button:addChild(openFlagSprite)

        end

        container:setContentSize(button:getContentSize())
        return container
    end

    local num = getTableRowNum(achievementData)
    local col = 3

    local tempSprite = cc.Sprite:create("Images/btn/ann03_a.png")

    local gap_h = 25
    local gapH = (self.areaWidth - gap_h * 2 - tempSprite:getContentSize().width * col) / (col - 1)
    local gapHTemp = gapH
    gapH = gapH + tempSprite:getContentSize().width
    local gapV = 72
    
    local tempRow = math.floor(num / col)
    local row = math.ceil(num / col)

    local tempTotalHeight = row * gapV
    if (tempTotalHeight < self.scrollViewHeight) then
        tempTotalHeight = self.scrollViewHeight
    end

    local csvData = DataManager:getInstance():getCSVByID(csvOfAchievement)
    for i=1,row do
        for j=1,col do
            local index = (i - 1) * col + j
            if (index <= num) then
                local item = self.scrollViewContainer:getChildByTag(index)

                if (item ~= nil) then
                    item:removeFromParent()
                end

                item = createItem(csvData[tostring(index)], index, achievementData[tostring(index)])
                item:setPosition(cc.p(gap_h + (j - 1) * gapH, tempTotalHeight - (gapV * i) + item:getContentSize().height * 0.5))
                item:setTag(index)
                self.scrollViewContainer:addChild(item)
                -- end
            end
        end
    end

    self.scrollView:setContentSize(cc.size(self.areaWidth, tempTotalHeight))
    self.scrollView:setContentOffset(cc.p(0, -(tempTotalHeight - self.scrollView:getViewSize().height)))

    achievementPointLabel:setPosition(cc.p(self.originPos.x + gap_h, achievementPointLabel:getPositionY()))
    if (trigerLabel ~= nil) then
        trigerLabel:setPosition(cc.p(achievementPointLabel:getPositionX(), trigerLabel:getPositionY()))
    end

end

function AchievementLayer:getAchievementInformation(itemData)
        -- body
        local desc = itemData[dataKeyDesc]
        local rewardPoint = itemData[dataKeyPoint]
        local showData = desc .. "\n" .. "奖励成就点x" .. rewardPoint
        local diamond = tonumber(itemData[dataKeyDiamond])
        if (diamond > 0) then
            showData = showData .. "\n" .. "奖励钻石x" .. diamond
        end

        local achievementType = getNumber(itemData[dataKeyType])
        local totalValue = itemData[dataKeyTotalValue]

        local progress = nil
        local store = DataManager:getInstance():getRoleData(roleStorageInfo)

        if (achievementType == achievement_Alchemy) then
            progress = store[achievement_Alchemy]
        elseif (achievementType == achievement_Exploration) then
            progress = store[achievement_Exploration]
        elseif (achievementType == achievement_Gamble) then
            progress = store[achievement_Gamble]
        elseif (achievementType == achievement_Arena) then
            progress = store[achievement_Arena]
        elseif (achievementType == achievement_ConsumeBread) then
            progress = store[achievement_ConsumeBread]
        elseif (achievementType == achievement_Collect) then
            progress = store[achievement_Collect]
        -- elseif (achievementType == achievement_ShareToFriends) then
        --     progress = store[achievement_ShareToFriends]
        -- elseif (achievementType == achievement_ShareToWeibo) then
        --     progress = store[achievement_ShareToWeibo]
        elseif (achievementType == achievement_KillMonster) then
            progress = store[achievement_KillMonster]
        end
        -- progress = "5"
        if ((progress ~= nil) and (totalValue ~= nil)) then
            if (totalValue ~= "-1") then
                showData = showData .. "\n" .. "当前进度" .. progress .. "/" .. totalValue
            end
        end
        return showData
end

function AchievementLayer:initCoherentAchievement()
    local P=require 'LuaClass/ProgressSupportPresentation';local W=require 'LuaClass/WarmTheme'
    local shell=P.mount(self,'冒险成就','查看目标与奖励，记录每一步成长')
    local canvas=shell.canvas
    self.achievementPointsLabel=P.label(canvas,'',32,32,630,280)
    self.achievementCountLabel=P.label(canvas,'',18,32,588,306,W.colors.muted)
    local medal=P.symbol('medal',98);medal:setPosition(cc.p(350,574));canvas:addChild(medal)
    self.achievementThresholdLabel=P.label(canvas,'',18,32,550,416)
    self.achievementThresholdHint=P.label(canvas,'',16,32,520,416,W.colors.muted)
    self.achievementThresholdBar=cc.DrawNode:create();self.achievementThresholdBar:setPosition(cc.p(32,498));canvas:addChild(self.achievementThresholdBar)
    P.scroll(self,260,218)
    self.achievementEmpty=P.label(canvas,'尚无成就记录\n探索、采集和炼金的成长会记录在这里。',19,240,366,390,W.colors.muted,.5)
    self.achievementEmpty:setDimensions(cc.size(390,76));self.achievementEmpty:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    local talent=W.button('天赋',100,48,function()
        if not P.open(self)then return end
        if GuideController:getInstance():getIsHaveStep(8)then zqDispatch:moveToTalent()
        else ToastUtil:downString('您需要建造船坞，可激活该功能')end
    end,{size=18});talent:setPosition(cc.p(282,48));canvas:addChild(talent);self.achievementTalent=talent
    local intelligence=W.button('情报',100,48,function()
        if not P.open(self)then return end
        if DataManager:getInstance():getRoleData(roleMapInfo)~=nil and not isEnterMap then RandomEventView:create():show()
        else ToastUtil:downString('您需要建造船坞并出征\n之后方可激活该功能')end
    end,{size=18});intelligence:setPosition(cc.p(398,48));canvas:addChild(intelligence);self.achievementIntelligence=intelligence
    self:loadAchievementData()
    P.listen(self,{roleAchievement,roleTalent,roleAchievementPoint,roleStorageInfo,roleMapInfo,roleGuideStep},function()self:loadAchievementData()end)
    return true
end
function AchievementLayer:loadCoherentAchievementData()
    if self.achievementDisposed then return end
    local P=require 'LuaClass/ProgressSupportPresentation';local W=require 'LuaClass/WarmTheme'
    local dm=DataManager:getInstance();local csv=dm:getCSVByID(csvOfAchievement)or{};local data=dm:getRoleData(roleAchievement)or{}
    local points=tonumber(dm:getRoleData(roleAchievementPoint))or 0
    self.achievementPointsLabel:setString('成就点数 '..points);W.fit(self.achievementPointsLabel,308)
    -- Read the same locked auto-talents as the original page. Reaching the
    -- point threshold never grants a talent here; DataManager owns all gates.
    local locked=getRowDataFromMatrixBySpecifiedKeyAndValue(dm:getLockedTallent(),dataKeyAutoType,{[1]='1'})
    local ordered=sortTableOrderByASC(locked,dataKeyAchievement)
    local nextTalent=ordered and ordered[1];local threshold=nextTalent and tonumber(nextTalent[dataKeyAchievement])
    self.achievementNextThreshold=threshold
    self.achievementThresholdLabel:setString(threshold and ('下一项天赋 · 需要 '..threshold..' 成就点')or'已无待解锁的成就点数天赋')
    W.fit(self.achievementThresholdLabel,416)
    self.achievementThresholdHint:setString(threshold and (points>=threshold and '已达到点数条件，天赋按原有条件自动获得' or ('还需 '..(threshold-points)..' 点 · 天赋按原有条件自动获得'))or'继续探索，完成更多冒险目标')
    W.fit(self.achievementThresholdHint,416)
    local bar=self.achievementThresholdBar;bar:clear()
    if threshold then
        bar:drawSegment(cc.p(0,0),cc.p(416,0),2,HomeTheme.rgba(W.colors.line))
        local ratio=threshold>0 and math.max(0,math.min(1,points/threshold))or 1
        bar:drawSegment(cc.p(0,0),cc.p(416*ratio,0),2,HomeTheme.rgba(W.colors.gold))
    end
    local entries={};local attained=0
    for id,flag in pairs(data)do if tonumber(id)then entries[#entries+1]={id=tostring(id),flag=tonumber(flag)or 0};if tonumber(flag)and tonumber(flag)>0 then attained=attained+1 end end end
    table.sort(entries,function(a,b)return tonumber(a.id)<tonumber(b.id)end)
    self.achievementEntries=entries;self.achievementRows={};self.achievementGeneration=(self.achievementGeneration or 0)+1;local generation=self.achievementGeneration
    self.achievementCountLabel:setString('已达成 '..attained..' / '..#entries..' 项 · 点按查看详情')
    self.achievementEmpty:setVisible(#entries==0)
    local store=dm:getRoleData(roleStorageInfo)or{}
    local tracked={[achievement_Alchemy]=true,[achievement_Exploration]=true,[achievement_Gamble]=true,[achievement_Arena]=true,[achievement_ConsumeBread]=true,[achievement_Collect]=true,[achievement_KillMonster]=true}
    local heights={};for i in ipairs(entries)do heights[i]=100 end
    P.rows(self,heights,function(i,h)
        local entry=entries[i];local record=csv[entry.id];local row=cc.Node:create();row:setContentSize(cc.size(416,h))
        local button=SDButton:create('Images/btn/ann03_a.png','Images/btn/ann03_b.png',function()
            if not P.open(self)or generation~=self.achievementGeneration then return end
            local latest=dm:getCSVByID(csvOfAchievement)[entry.id]
            if latest then self:showInfoBox(self:getAchievementInformation(latest))end
        end)
        button.normalSpr:removeFromParent();button.selectSpr:removeFromParent()
        button.normalSpr=cc.Node:create();button.normalSpr:setContentSize(cc.size(416,98))
        button.selectSpr=W.panel(416,98,W.colors.line,0);button.selectSpr:setVisible(false)
        button:addChild(button.normalSpr);button:addChild(button.selectSpr)
        button:setContentSize(cc.size(416,98));button:setPosition(cc.p(208,50));button:setSwallowTouches(false);row:addChild(button);P.clip(button,self.scrollView)
        local kinds={[achievement_Alchemy]='alchemy',[achievement_Exploration]='compass',[achievement_Arena]='target',[achievement_ConsumeBread]='food',[achievement_KillMonster]='lightning'}
        local iconKind=record and kinds[tonumber(record[dataKeyType])] or (entry.flag>0 and 'medal' or 'badge')
        local icon=P.symbol(iconKind,42);icon:setPosition(cc.p(0,38));button:addChild(icon)
        P.label(button,record and record[dataKeyName]or('成就 '..entry.id),21,54,76,252)
        P.label(button,entry.flag>0 and '已达成' or '进行中',17,410,76,86,entry.flag>0 and W.colors.sea or W.colors.muted,1)
        local rewards=record and ('成就点 +'..tostring(record[dataKeyPoint]or 0))or'暂无奖励说明'
        if record and (tonumber(record[dataKeyDiamond])or 0)>0 then rewards=rewards..' · 钻石 +'..record[dataKeyDiamond]end
        P.label(button,rewards,17,54,45,356,W.colors.muted)
        local kind=record and tonumber(record[dataKeyType]);local target=record and tonumber(record[dataKeyTotalValue]);local progress=kind and tracked[kind]and store[kind]
        local text=progress~=nil and target and target>=0 and ('当前进度 '..tostring(progress)..' / '..target)or(entry.flag>0 and '目标已达成 · 查看说明' or '查看目标说明')
        P.label(button,text,17,54,18,356,W.colors.muted);P.rule(row,1)
        self.achievementRows[i]={id=entry.id,node=row,button=button};return row
    end)
    self.achievementTalent:setOpacity(GuideController:getInstance():getIsHaveStep(8)and 255 or 115)
    self.achievementIntelligence:setOpacity(dm:getRoleData(roleMapInfo)~=nil and not isEnterMap and 255 or 115)
end
function AchievementLayer:showInfoBox(infoString)
    if self.supportWarm then return require('LuaClass/ProgressSupportPresentation').information(self,'成就详情',infoString)end
    return BaseView.showInfoBox(self,infoString)
end
