require "LuaClass/Header"
require "LuaClass/ToastUtil"
require "LuaClass/V2ChapterController"

V2ChapterLayer = class("V2ChapterLayer", function()
    return cc.Layer:create()
end)

V2ChapterLayer.__index = V2ChapterLayer

local COLORS = {
    ink = cc.c3b(235, 226, 199),
    muted = cc.c3b(170, 170, 160),
    gold = cc.c3b(222, 174, 76),
    danger = cc.c3b(219, 91, 74),
    sea = cc.c3b(92, 157, 166),
}

local function createLabel(text, size, color, width, alignment)
    local label = cc.LabelTTF:create(text or "", BoldFont, size)
    label:setColor(color or COLORS.ink)
    if width then
        label:setDimensions(cc.size(width, 0))
        label:setHorizontalAlignment(alignment or cc.TEXT_ALIGNMENT_LEFT)
        label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
    end
    return label
end

local function resourceLine(resources)
    return string.format(
        "金币 %d   木材 %d   铁料 %d   补给 %d   符文尘 %d",
        resources.gold,
        resources.timber,
        resources.iron,
        resources.provisions,
        resources.rune_dust
    )
end

local function battleLine(state)
    if state.stage == "naval" then
        return string.format(
            "我方船体 %d/%d    敌舰 %d/%d\n甲板 %d/%d%s    敌炮 %d/%d%s",
            state.battle.player_hull,
            state.battle.player_hull_max,
            state.battle.enemy_ship_hp,
            state.battle.enemy_ship_hp_max,
            state.battle.deck_damage,
            state.battle.deck_threshold,
            state.battle.deck_broken and "（已击毁）" or "",
            state.battle.gun_damage,
            state.battle.gun_threshold,
            state.battle.guns_suppressed and "（已压制）" or ""
        )
    elseif state.stage == "boarding" then
        return string.format(
            "接舷队 %d/%d    敌方甲板部队 %d/%d",
            state.battle.crew_hp,
            state.battle.crew_hp_max,
            state.battle.enemy_boarding_hp,
            state.battle.enemy_boarding_hp_max
        )
    end
    return nil
end

local function fitSprite(sprite, targetWidth, targetHeight)
    local size = sprite:getContentSize()
    if size.width <= 0 or size.height <= 0 then
        return
    end
    local scale = math.max(targetWidth / size.width, targetHeight / size.height)
    sprite:setScale(scale)
end

local function heroGroupLabel(group)
    local labels = {
        harbor = "皇家港 / 船员整备",
        map = "羊皮海图 / 迷雾航行",
        combat = "敌船 / 双阶段战斗",
        rune = "诅咒 / 符文线索",
    }
    return labels[group] or "瓶中海域"
end

function V2ChapterLayer:create()
    local view = V2ChapterLayer.new()
    if view and view:init() then
        return view
    end
    return nil
end

function V2ChapterLayer:init()
    self.controller = V2ChapterController:getInstance()
    self.controller:load()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()

    local background = cc.Sprite:create("Images/Background/MainBackGround.png")
    background:setAnchorPoint(cc.p(0, 0))
    background:setPosition(self.origin)
    self:addChild(background)

    local wash = cc.LayerColor:create(cc.c4b(8, 19, 27, 205), self.visibleSize.width, self.visibleSize.height)
    wash:setPosition(self.origin)
    self:addChild(wash)

    self.dynamicNode = cc.Node:create()
    self:addChild(self.dynamicNode)
    self:refresh()
    if os ~= nil and os.getenv ~= nil then
        local qaCue = os.getenv("NEWPIRATE_V2_AUDIO_CUE")
        if qaCue ~= nil and qaCue ~= "" then
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.8),
                cc.CallFunc:create(function() self:playCue(qaCue) end)
            ))
        end
    end
    return true
end

function V2ChapterLayer:playCue(cueId)
    if not V2Config:shouldPlayAudioCues() then
        return
    end
    local cue = self.controller:getChapterData().by_id.audio_cue[cueId]
    if cue ~= nil and cue.file ~= nil then
        if type(playV2Sound) ~= "function" then
            cclog("V2 native audio bridge is unavailable")
            return
        end
        local ok, played = pcall(playV2Sound, cue.file, cue.volume, cue.loop or 0)
        if not ok or not played then
            cclog("V2 audio cue failed: %s", tostring(cueId))
        end
    end
end

function V2ChapterLayer:playActionFeedback(actionId, previousStage, nextStage)
    if nextStage == "failed" then
        self:playCue("sinking")
    elseif nextStage == "rune_clue" then
        self:playCue("victory")
    elseif actionId == "fire_at_deck" or actionId == "fire_at_guns" then
        self:playCue("cannon")
    elseif actionId == "board_now" then
        self:playCue("boarding")
    elseif actionId == "resist_whisper" or actionId == "listen_whisper"
        or actionId == "follow_cursed_compass" or actionId == "break_cursed_compass"
        or actionId == "take_rune_clue" then
        self:playCue("curse")
    elseif actionId == "start_voyage" or previousStage == "route_choice"
        or previousStage == "black_tide" then
        self:playCue("wave")
    end
end

function V2ChapterLayer:addHeroArt(parent, state)
    local presentation = self.controller:getPresentation()
    local width = self.visibleSize.width
    local artHeight = 540
    local artY = self.visibleSize.height - 840

    local frame = cc.LayerColor:create(cc.c4b(6, 14, 20, 235), width, artHeight)
    frame:setPosition(cc.p(0, artY))
    parent:addChild(frame)

    local background = cc.Sprite:create(presentation.background)
    if background ~= nil then
        background:setPosition(cc.p(width * 0.5, artHeight * 0.5))
        fitSprite(background, width, artHeight)
        background:setOpacity(190)
        frame:addChild(background)
        background:runAction(cc.FadeTo:create(0.45, 225))
    end

    local vignette = cc.LayerColor:create(cc.c4b(3, 11, 16, 92), width, artHeight)
    vignette:setPosition(cc.p(0, 0))
    frame:addChild(vignette, 2)

    if presentation.foreground ~= nil then
        local foreground = cc.Sprite:create(presentation.foreground)
        if foreground ~= nil then
            foreground:setPosition(cc.p(width * 0.73, artHeight * 0.53))
            local size = foreground:getContentSize()
            if size.width > 0 then
                foreground:setScale(math.min(1.0, 250 / size.width))
            end
            foreground:setOpacity(210)
            frame:addChild(foreground, 3)
            foreground:runAction(cc.RepeatForever:create(cc.Sequence:create(
                cc.MoveBy:create(2.4, cc.p(0, 7)),
                cc.MoveBy:create(2.4, cc.p(0, -7))
            )))
        end
    end

    if presentation.portrait ~= nil then
        local portrait = cc.Sprite:create(presentation.portrait)
        if portrait ~= nil then
            portrait:setPosition(cc.p(width - 92, artHeight - 102))
            local size = portrait:getContentSize()
            if size.width > 0 then portrait:setScale(math.min(0.72, 142 / size.width)) end
            portrait:setOpacity(240)
            frame:addChild(portrait, 4)
            portrait:runAction(cc.RepeatForever:create(cc.Sequence:create(
                cc.ScaleBy:create(1.1, 1.035),
                cc.ScaleBy:create(1.1, 1 / 1.035)
            )))
        end
    end

    local artTag = createLabel("正式样片构图  ·  " .. heroGroupLabel(presentation.hero_group), 15, COLORS.gold)
    artTag:setAnchorPoint(cc.p(0, 1))
    artTag:setPosition(cc.p(28, artHeight - 18))
    frame:addChild(artTag, 5)

    if state.stage == "rune_clue" or state.stage == "settlement"
        or state.stage == "upgrade" or state.stage == "complete" then
        local rewardIcon = cc.Sprite:create("Images/UI/CoinBg.png")
        rewardIcon:setPosition(cc.p(48, 55))
        rewardIcon:setScale(0.82)
        frame:addChild(rewardIcon, 5)
        rewardIcon:runAction(cc.RepeatForever:create(cc.RotateBy:create(3.5, 360)))
        local rewardLabel = createLabel("首章奖励已入库", 17, COLORS.gold)
        rewardLabel:setAnchorPoint(cc.p(0, 0.5))
        rewardLabel:setPosition(cc.p(76, 55))
        frame:addChild(rewardLabel, 5)
    end
end

function V2ChapterLayer:viewWillDestory()
end

function V2ChapterLayer:destory()
    pNeedUpdateLayer = nil
end

function V2ChapterLayer:updateInfoLabel()
    -- The V2 graybox owns its status presentation and does not use legacy HUD text.
end

function V2ChapterLayer:addMapStrip(parent, state, y)
    local data = self.controller:getChapterData()
    local visited = {
        node_port = true,
        node_fog_gate = state.stage ~= "opening" and state.stage ~= "harbor",
        node_wreck = state.flags.risky_route == true,
        node_safe_cove = state.flags.safe_route == true,
        node_black_tide = state.flags.route_event_resolved == true,
        node_whisper = state.flags.curse_heard == true or state.stage == "whisper",
        node_cursed_compass = state.flags.curse_heard == true,
        node_raider = state.flags.compass_resolved == true,
        node_rune_clue = state.flags.raider_defeated == true,
    }
    local positions = {
        node_port = 38,
        node_fog_gate = 102,
        node_wreck = 166,
        node_safe_cove = 166,
        node_black_tide = 244,
        node_whisper = 322,
        node_cursed_compass = 400,
        node_raider = 478,
        node_rune_clue = 558,
    }
    local offsets = { node_wreck = 28, node_safe_cove = -28 }

    local routeLine = cc.LayerColor:create(cc.c4b(83, 110, 116, 180), 500, 3)
    routeLine:setPosition(cc.p(65, y + 8))
    parent:addChild(routeLine)

    for _, node in ipairs(data.map_node) do
        local x = positions[node.id]
        local nodeY = y + (offsets[node.id] or 0)
        local color = visited[node.id] and cc.c4b(107, 166, 154, 255) or cc.c4b(61, 72, 76, 255)
        if state.current_node == node.id then
            color = cc.c4b(222, 174, 76, 255)
        end
        local marker = cc.LayerColor:create(color, 18, 18)
        marker:setPosition(cc.p(x - 9, nodeY))
        parent:addChild(marker)

        local shortName = node.name
        if node.id == "node_fog_gate" then shortName = "迷雾" end
        if node.id == "node_safe_cove" then shortName = "海湾" end
        if node.id == "node_black_tide" then shortName = "黑潮" end
        if node.id == "node_cursed_compass" then shortName = "罗盘" end
        if node.id == "node_rune_clue" then shortName = "符文" end
        if node.id == "node_raider" then shortName = "追猎者" end
        if node.id == "node_whisper" then shortName = "低语" end
        if node.id == "node_wreck" then shortName = "沉船" end
        local label = createLabel(shortName, 16, state.current_node == node.id and COLORS.gold or COLORS.muted, 76, cc.TEXT_ALIGNMENT_CENTER)
        label:setAnchorPoint(cc.p(0.5, 1))
        label:setPosition(cc.p(x, nodeY - 5))
        parent:addChild(label)
    end
end

function V2ChapterLayer:addActionButton(parent, action, x, y)
    local button = cc.MenuItemImage:create("Images/btn/ann01_a.png", "Images/btn/ann01_b.png")
    button:setScale(1.55)
    button:setPosition(cc.p(x, y))
    button:registerScriptTapHandler(function()
        local previousStage = self.controller:load().stage
        local ok, message = self.controller:dispatch(action.id)
        if not ok then
            ToastUtil:downString(message)
        else
            self:playActionFeedback(action.id, previousStage, self.controller:load().stage)
        end
        self:refresh()
    end)

    local fontSize = string.len(action.label) > 36 and 12 or 15
    local label = createLabel(action.label, fontSize, COLORS.ink, 116, cc.TEXT_ALIGNMENT_CENTER)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p(button:getContentSize().width * 0.5, button:getContentSize().height * 0.5 + 2))
    label:setScale(1 / 1.55)
    button:addChild(label, 2)
    parent:addChild(button)
end

function V2ChapterLayer:refresh()
    self.dynamicNode:removeAllChildren()
    local state = self.controller:load()
    local root = self.dynamicNode
    local width = self.visibleSize.width
    local height = self.visibleSize.height

    self:addHeroArt(root, state)

    local topBar = cc.LayerColor:create(cc.c4b(13, 29, 37, 238), width, 122)
    topBar:setPosition(cc.p(0, height - 122))
    root:addChild(topBar)

    local kicker = createLabel("NEW PIRATE V2  ·  CHAPTER 01  ·  CONTENT SAMPLE", 15, COLORS.sea)
    kicker:setAnchorPoint(cc.p(0, 0.5))
    kicker:setPosition(cc.p(30, 92))
    topBar:addChild(kicker)

    local title = createLabel(self.controller:getStageTitle(), 34, COLORS.ink)
    title:setAnchorPoint(cc.p(0, 0.5))
    title:setPosition(cc.p(30, 50))
    topBar:addChild(title)

    local profile = createLabel("存档 " .. state.profile, 15, COLORS.muted)
    profile:setAnchorPoint(cc.p(1, 0.5))
    profile:setPosition(cc.p(width - 28, 91))
    topBar:addChild(profile)

    local objectiveLabel = createLabel("当前目标｜" .. state.objective, 21, COLORS.gold, width - 60)
    objectiveLabel:setAnchorPoint(cc.p(0, 1))
    objectiveLabel:setPosition(cc.p(30, height - 145))
    root:addChild(objectiveLabel)

    local resourceLabel = createLabel(resourceLine(state.resources), 18, COLORS.ink, width - 60, cc.TEXT_ALIGNMENT_CENTER)
    resourceLabel:setAnchorPoint(cc.p(0, 1))
    resourceLabel:setPosition(cc.p(30, height - 202))
    root:addChild(resourceLabel)

    self:addMapStrip(root, state, height - 276)

    local cardHeight = 470
    local card = cc.LayerColor:create(cc.c4b(10, 25, 32, 208), width - 52, cardHeight)
    card:setPosition(cc.p(26, height - 815))
    root:addChild(card)

    local stageLabel = createLabel(self.controller:getStageTitle(), 28, COLORS.gold)
    stageLabel:setAnchorPoint(cc.p(0, 1))
    stageLabel:setPosition(cc.p(24, cardHeight - 24))
    card:addChild(stageLabel)

    local moduleData = self.controller:getChapterData().by_id.ship_module[state.selected_module]
    local meta = string.format(
        "节点：%s   航线：%s   模块：%s",
        self.controller:getChapterData().by_id.map_node[state.current_node].name,
        state.route == "safe_route" and "安全外海" or (state.route == "risky_shortcut" and "暗礁近路" or "未选择"),
        moduleData.name
    )
    local metaLabel = createLabel(meta, 17, COLORS.muted, width - 100)
    metaLabel:setAnchorPoint(cc.p(0, 1))
    metaLabel:setPosition(cc.p(24, cardHeight - 68))
    card:addChild(metaLabel)

    local narrative = createLabel(self.controller:getNarrative(), 19, COLORS.ink, width - 100)
    narrative:setAnchorPoint(cc.p(0, 1))
    narrative:setPosition(cc.p(24, cardHeight - 112))
    card:addChild(narrative)

    local battle = battleLine(state)
    if battle then
        local battleLabel = createLabel(battle, 19, state.stage == "naval" and COLORS.sea or COLORS.danger, width - 100)
        battleLabel:setAnchorPoint(cc.p(0, 1))
        battleLabel:setPosition(cc.p(24, 126))
        card:addChild(battleLabel)
    end

    local resultLabel = createLabel("最近结果｜" .. state.last_result, 17, COLORS.muted, width - 100)
    resultLabel:setAnchorPoint(cc.p(0, 0))
    resultLabel:setPosition(cc.p(24, 22))
    card:addChild(resultLabel)

    local actions = self.controller:getActions()
    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    root:addChild(menu)
    local columns = #actions == 1 and { width * 0.5 } or { width * 0.27, width * 0.73 }
    for index, action in ipairs(actions) do
        local column = ((index - 1) % 2) + 1
        local row = math.floor((index - 1) / 2)
        local x = columns[column] or width * 0.5
        local y = 270 - row * 92
        self:addActionButton(menu, action, x, y)
    end

    local footerText = "V2 样片：8 个事件、正式原画构图、双阶段战斗、关键动画与原生声音提示。"
    if string.sub(state.profile or "", 1, 3) == "qa_" then
        local report = self.controller:getTelemetrySummary()
        footerText = string.format(
            "QA 记录 %d 条｜决策 %d｜舰炮 %d｜接舷 %d｜无效 %d",
            report.total_events,
            report.decisions,
            report.naval_actions,
            report.boarding_actions,
            report.invalid_actions
        )
    end
    local footer = createLabel(footerText, 15, COLORS.muted, width - 40, cc.TEXT_ALIGNMENT_CENTER)
    footer:setAnchorPoint(cc.p(0, 0))
    footer:setPosition(cc.p(20, 18))
    root:addChild(footer)
end

return V2ChapterLayer
