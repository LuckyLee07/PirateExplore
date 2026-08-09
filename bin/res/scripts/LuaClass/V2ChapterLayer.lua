require "LuaClass/Header"
require "LuaClass/ToastUtil"
require "LuaClass/V2ChapterController"

local V2ChapterLayout = require "LuaClass/V2ChapterLayout"
local V2ReleaseInfo = require "LuaClass/V2ReleaseInfo"
local V2UITheme = require "LuaClass/V2UITheme"

V2ChapterLayer = class("V2ChapterLayer", function()
    return cc.Layer:create()
end)

V2ChapterLayer.__index = V2ChapterLayer

local function color3(name)
    local value = V2UITheme.colors[name] or V2UITheme.colors.ink
    return cc.c3b(value[1], value[2], value[3])
end

local function color4(name, alpha)
    local value = V2UITheme.colors[name] or V2UITheme.colors.ink
    return cc.c4b(value[1], value[2], value[3], alpha or 255)
end

local COLORS = {
    ink = color3("ink"),
    muted = color3("muted"),
    gold = color3("gold"),
    danger = color3("danger"),
    sea = color3("sea"),
    purple = color3("purple"),
    success = color3("success"),
    separator = color3("separator"),
}

local function createLabel(text, size, color, width, alignment, fontName)
    local label = cc.LabelTTF:create(text or "", fontName or "Arial", size)
    label:setColor(color or COLORS.ink)
    if width then
        label:setDimensions(cc.size(width, 0))
        label:setHorizontalAlignment(alignment or cc.TEXT_ALIGNMENT_LEFT)
        label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
    end
    return label
end

local function addBorder(parent, width, height, color, alpha, thickness)
    local line = thickness or 2
    local top = cc.LayerColor:create(color4(color, alpha), width, line)
    top:setPosition(cc.p(0, height - line))
    parent:addChild(top)
    local bottom = cc.LayerColor:create(color4(color, alpha), width, line)
    bottom:setPosition(cc.p(0, 0))
    parent:addChild(bottom)
    local left = cc.LayerColor:create(color4(color, alpha), line, height)
    left:setPosition(cc.p(0, 0))
    parent:addChild(left)
    local right = cc.LayerColor:create(color4(color, alpha), line, height)
    right:setPosition(cc.p(width - line, 0))
    parent:addChild(right)
end

local function addSurface(parent, x, y, width, height, options)
    local config = options or {}
    local surface = cc.LayerColor:create(
        color4(config.fill or "surface", config.alpha or 232),
        width,
        height
    )
    surface:setPosition(cc.p(x, y))
    parent:addChild(surface, config.z or 1)
    if config.border ~= nil then
        addBorder(
            surface,
            width,
            height,
            config.border,
            config.border_alpha or 95,
            config.border_width or 1
        )
    end
    if config.accent ~= nil then
        local accent = cc.LayerColor:create(color4(config.accent, 255), config.accent_width or 5, height)
        accent:setPosition(cc.p(0, 0))
        surface:addChild(accent, 2)
    end
    return surface
end

local createButtonFace

local function battleLine(state, impact)
    if state.stage == "naval" then
        local metrics = string.format(
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
        return impact and (metrics .. "\n" .. impact.text) or metrics
    elseif state.stage == "boarding" then
        local metrics = string.format(
            "接舷队 %d/%d    敌方甲板部队 %d/%d",
            state.battle.crew_hp,
            state.battle.crew_hp_max,
            state.battle.enemy_boarding_hp,
            state.battle.enemy_boarding_hp_max
        )
        return impact and (metrics .. "\n" .. impact.text) or metrics
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

local function addTintedIcon(parent, path, x, y, size, accentName, opacity)
    local icon = cc.Sprite:create(path)
    if icon == nil then
        return nil
    end
    local contentSize = icon:getContentSize()
    local maximum = math.max(contentSize.width, contentSize.height)
    if maximum > 0 then
        icon:setScale(size / maximum)
    end
    icon:setColor(color3(accentName))
    icon:setOpacity(opacity or 232)
    icon:setPosition(cc.p(x, y))
    parent:addChild(icon, 4)
    return icon
end

local function captureActionSnapshot(state)
    local resources = state.resources or {}
    local battle = state.battle or {}
    local ship = state.ship or {}
    return {
        stage = state.stage,
        gold = resources.gold or 0,
        timber = resources.timber or 0,
        iron = resources.iron or 0,
        provisions = resources.provisions or 0,
        rune_dust = resources.rune_dust or 0,
        player_hull = battle.player_hull or 0,
        enemy_ship_hp = battle.enemy_ship_hp or 0,
        deck_damage = battle.deck_damage or 0,
        gun_damage = battle.gun_damage or 0,
        crew_hp = battle.crew_hp or 0,
        crew_hp_max = battle.crew_hp_max or 0,
        enemy_boarding_hp = battle.enemy_boarding_hp or 0,
        voyage_hull_damage = state.voyage_hull_damage or 0,
        ship_hull_max = ship.hull_max or 0,
        ship_gun_level = ship.gun_level or 0,
    }
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

    local wash = cc.LayerColor:create(color4("shell", 118), self.visibleSize.width, self.visibleSize.height)
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
        local releaseInfoSection = os.getenv("NEWPIRATE_V2_RELEASE_INFO")
        if releaseInfoSection == "1" or releaseInfoSection == "privacy" or releaseInfoSection == "support" then
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.8),
                cc.CallFunc:create(function() self:showReleaseInfo(releaseInfoSection) end)
            ))
        end
        local qaAction = os.getenv("NEWPIRATE_V2_QA_ACTION")
        if qaAction ~= nil and qaAction ~= "" and V2Config:isQAProfile(self.controller:load().profile) then
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.8),
                cc.CallFunc:create(function() self:performAction(qaAction) end)
            ))
        end
    end
    return true
end

function V2ChapterLayer:openReleaseUrl(kind)
    local url = V2ReleaseInfo:getPublicUrl(kind)
    if url == nil then
        ToastUtil:downString("公开页面尚未配置，请从 App Store 产品页联系支持")
        return
    end
    if type(openUrlFunc) ~= "function" then
        ToastUtil:downString("当前设备无法打开该页面")
        return
    end
    openUrlFunc(url)
end

function V2ChapterLayer:showReleaseInfo(initialKind)
    if self.releaseInfoOverlay ~= nil then
        return
    end

    local width = self.visibleSize.width
    local height = self.visibleSize.height
    local overlay = cc.LayerColor:create(color4("shell", 232), width, height)
    overlay:setPosition(self.origin)
    self:addChild(overlay, 2000)
    self.releaseInfoOverlay = overlay

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, overlay)

    local panelWidth = math.min(width - 36, 604)
    local panelHeight = math.min(height - 48, 900)
    local panel = addSurface(
        overlay,
        (width - panelWidth) * 0.5,
        (height - panelHeight) * 0.5,
        panelWidth,
        panelHeight,
        {
            fill = "surface",
            alpha = 255,
        }
    )

    local panelAccent = cc.LayerColor:create(color4("gold", 255), 56, 3)
    panelAccent:setPosition(cc.p(24, panelHeight - 3))
    panel:addChild(panelAccent, 3)

    local heading = createLabel("隐私与支持", 25, COLORS.ink, nil, nil, BoldFont)
    heading:setAnchorPoint(cc.p(0, 1))
    heading:setPosition(cc.p(24, panelHeight - 22))
    panel:addChild(heading)

    local version = createLabel("版本 2.0.0", 13, COLORS.muted)
    version:setAnchorPoint(cc.p(1, 1))
    version:setPosition(cc.p(panelWidth - 24, panelHeight - 28))
    panel:addChild(version)

    local section = createLabel("隐私说明", 14, COLORS.sea)
    section:setAnchorPoint(cc.p(0, 1))
    section:setPosition(cc.p(24, panelHeight - 62))
    panel:addChild(section)

    local body = createLabel(
        V2ReleaseInfo.PRIVACY_TEXT,
        panelHeight < 780 and 14 or 16,
        COLORS.ink,
        panelWidth - 48,
        cc.TEXT_ALIGNMENT_LEFT
    )
    body:setDimensions(cc.size(panelWidth - 48, panelHeight - 150))
    body:setAnchorPoint(cc.p(0, 1))
    body:setPosition(cc.p(24, panelHeight - 90))
    panel:addChild(body)

    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    panel:addChild(menu)

    local currentKind = "privacy"
    local webLabel = nil
    local function selectSection(kind)
        currentKind = kind
        if kind == "privacy" then
            section:setString("隐私说明")
            body:setString(V2ReleaseInfo.PRIVACY_TEXT)
        else
            section:setString("支持说明")
            body:setString(V2ReleaseInfo.SUPPORT_TEXT)
        end
        if webLabel ~= nil then
            webLabel:setString(kind == "privacy" and "打开隐私网页" or "打开支持网页")
        end
    end
    selectSection(initialKind == "support" and "support" or "privacy")

    local buttons = {
        { label = "隐私说明", action = function() selectSection("privacy") end },
        { label = "支持说明", action = function() selectSection("support") end },
    }
    if V2ReleaseInfo:hasConfiguredPublicLinks() then
        table.insert(buttons, {
            label = "打开隐私网页",
            action = function() self:openReleaseUrl(currentKind) end,
            isWeb = true,
        })
    end
    table.insert(buttons, {
        label = "关闭",
        action = function()
            self.releaseInfoOverlay = nil
            overlay:removeFromParent()
        end,
    })

    local spacing = panelWidth / (#buttons + 1)
    local buttonWidth = math.min(132, (panelWidth - 36) / #buttons - 8)
    local buttonHeight = 44
    for index, descriptor in ipairs(buttons) do
        local role = descriptor.isWeb and "primary" or "utility"
        local normalFace, textColor = createButtonFace(buttonWidth, buttonHeight, role, false, "gold")
        local pressedFace = createButtonFace(buttonWidth, buttonHeight, role, true, "gold")
        local item = cc.MenuItemSprite:create(normalFace, pressedFace)
        local label = createLabel(descriptor.label, 13, color3(textColor), buttonWidth - 12, cc.TEXT_ALIGNMENT_CENTER, BoldFont)
        if descriptor.isWeb then
            webLabel = label
        end
        label:setAnchorPoint(cc.p(0.5, 0.5))
        label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        label:setPosition(cc.p(buttonWidth * 0.5, buttonHeight * 0.5 + 1))
        item:addChild(label, 2)
        item:setPosition(cc.p(spacing * index, 34))
        item:registerScriptTapHandler(descriptor.action)
        menu:addChild(item)
    end
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

function V2ChapterLayer:showActionFeedback(actionId, before, after, layout)
    if self.dynamicNode == nil then
        return
    end
    local accentName = V2UITheme.accentName(after.stage)
    local changes = V2UITheme.feedbackChanges(before, after)
    local detail = nil
    if #changes > 0 then
        local visible = {}
        for index = 1, math.min(3, #changes) do
            table.insert(visible, changes[index])
        end
        detail = table.concat(visible, "  ·  ")
        if #changes > #visible then
            detail = detail .. string.format("  ·  另%d项", #changes - #visible)
        end
    elseif before.stage ~= after.stage then
        detail = "进入  ·  " .. V2UITheme.stageKind(after.stage)
    else
        detail = "指令已执行，航海日志已更新"
    end

    local isBattleStage = after.stage == "naval" or after.stage == "boarding"
    local cardHeight = isBattleStage and layout.card_height or layout.story_card_height
    local cardY = isBattleStage and layout.card_y or (layout.card_y - layout.story_card_offset)
    local width = math.min(self.visibleSize.width - 64, 404)
    local height = layout.compact and 50 or 56
    local x = (self.visibleSize.width - width) * 0.5
    local y = math.min(layout.resource_y - 88, cardY + cardHeight + 18)
    local toast = cc.Node:create()
    toast:setPosition(cc.p(0, -7))
    toast:setOpacity(0)
    toast:setCascadeOpacityEnabled(true)
    self.dynamicNode:addChild(toast, 60)

    local surface = addSurface(toast, x, y, width, height, {
        fill = "shell_raised",
        alpha = 250,
        accent = accentName,
        accent_width = 4,
        border = "separator",
        border_alpha = 74,
    })
    local title = createLabel(
        V2UITheme.actionFeedbackTitle(actionId, after.stage),
        layout.compact and 11 or 12,
        color3(accentName),
        width - 30,
        cc.TEXT_ALIGNMENT_LEFT,
        BoldFont
    )
    title:setAnchorPoint(cc.p(0, 0.5))
    title:setPosition(cc.p(17, height * 0.68))
    surface:addChild(title, 4)
    local deltaLabel = createLabel(
        detail,
        layout.compact and 10 or 11,
        COLORS.ink,
        width - 30,
        cc.TEXT_ALIGNMENT_LEFT
    )
    deltaLabel:setAnchorPoint(cc.p(0, 0.5))
    deltaLabel:setPosition(cc.p(17, height * 0.30))
    surface:addChild(deltaLabel, 4)

    toast:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.FadeTo:create(0.14, 255),
            cc.MoveBy:create(0.14, cc.p(0, 7))
        ),
        cc.DelayTime:create(1.25),
        cc.FadeTo:create(0.20, 0),
        cc.RemoveSelf:create()
    ))
end

function V2ChapterLayer:addHeroArt(parent, state, layout)
    local presentation = self.controller:getPresentation()
    local width = self.visibleSize.width
    local artHeight = layout.art_height
    local artY = layout.art_y
    local accentName = V2UITheme.accentName(state.stage)

    local frame = cc.LayerColor:create(color4("shell", 255), width, artHeight)
    frame:setPosition(cc.p(0, artY))
    parent:addChild(frame)

    local background = cc.Sprite:create(presentation.background)
    if background ~= nil then
        background:setPosition(cc.p(width * 0.5, artHeight * 0.5))
        fitSprite(background, width, artHeight)
        background:setOpacity(226)
        frame:addChild(background)
        background:runAction(cc.FadeTo:create(0.28, 255))
    end

    local atmosphere = cc.LayerColor:create(color4(accentName, 18), width, artHeight)
    atmosphere:setPosition(cc.p(0, 0))
    frame:addChild(atmosphere, 2)

    -- The upper context rail sits directly on the scene. A single scrim gives
    -- the objective, resources and route enough contrast without creating
    -- three more floating cards.
    local contextScrimHeight = layout.compact and 164 or 176
    local contextScrim = cc.LayerColor:create(color4("shell", 164), width, contextScrimHeight)
    contextScrim:setPosition(cc.p(0, artHeight - contextScrimHeight))
    frame:addChild(contextScrim, 3)

    if presentation.foreground ~= nil then
        local foreground = cc.Sprite:create(presentation.foreground)
        if foreground ~= nil then
            foreground:setPosition(cc.p(width * 0.73, artHeight * (layout.compact and 0.46 or 0.53)))
            local size = foreground:getContentSize()
            if size.width > 0 then
                local targetWidth = layout.compact and 180 or 250
                foreground:setScale(math.min(layout.compact and 0.75 or 1.0, targetWidth / size.width))
            end
            foreground:setOpacity(0)
            foreground:setPositionY(foreground:getPositionY() - 7)
            frame:addChild(foreground, 4)
            foreground:runAction(cc.Spawn:create(
                cc.FadeTo:create(0.32, 232),
                cc.MoveBy:create(0.32, cc.p(0, 7))
            ))
        end
    end

    if presentation.portrait ~= nil then
        local portrait = cc.Sprite:create(presentation.portrait)
        if portrait ~= nil then
            portrait:setPosition(cc.p(width - 92, artHeight - (layout.compact and 72 or 102)))
            local size = portrait:getContentSize()
            if size.width > 0 then
                local targetWidth = layout.compact and 108 or 142
                portrait:setScale(math.min(layout.compact and 0.52 or 0.72, targetWidth / size.width))
            end
            portrait:setOpacity(0)
            frame:addChild(portrait, 5)
            portrait:runAction(cc.FadeTo:create(0.28, 244))
        end
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

function V2ChapterLayer:addVoyageRail(parent, state, layout)
    local width = self.visibleSize.width
    local current = V2UITheme.progressIndex(state.stage)
    local accentName = V2UITheme.accentName(state.stage)
    local gap = layout.voyage_rail_gap
    local railWidth = 72
    local railHeight = gap * (#V2UITheme.progress_labels - 1) + 64
    local railX = width - railWidth - 24
    local railY = layout.map_y - railHeight + 30
    local rail = cc.LayerColor:create(color4("shell", 188), railWidth, railHeight)
    rail:setPosition(cc.p(railX, railY))
    parent:addChild(rail, 6)

    local voyageLabel = createLabel("航程", layout.compact and 9 or 10, COLORS.muted)
    voyageLabel:setAnchorPoint(cc.p(0.5, 0.5))
    voyageLabel:setPosition(cc.p(railWidth * 0.5, railHeight - 16))
    rail:addChild(voyageLabel, 4)

    local lineBottom = 20
    local lineTop = railHeight - 36
    local routeLine = cc.LayerColor:create(color4("track", 236), 2, lineTop - lineBottom)
    routeLine:setPosition(cc.p(railWidth * 0.5 - 1, lineBottom))
    rail:addChild(routeLine, 2)
    if current > 1 then
        local completeHeight = gap * (current - 1)
        local completeLine = cc.LayerColor:create(color4(accentName, 196), 2, completeHeight)
        completeLine:setPosition(cc.p(railWidth * 0.5 - 1, lineTop - completeHeight))
        rail:addChild(completeLine, 3)
    end

    for index, _ in ipairs(V2UITheme.progress_labels) do
        local y = lineTop - gap * (index - 1)
        local markerColor = index <= current and accentName or "track"
        local markerSize = index == current and 12 or 7
        local marker = cc.LayerColor:create(color4(markerColor, 255), markerSize, markerSize)
        marker:setPosition(cc.p(railWidth * 0.5 - markerSize * 0.5, y - markerSize * 0.5))
        marker:setRotation(45)
        rail:addChild(marker, 5)

        if index == current then
            local stageTag = cc.LayerColor:create(color4("shell_raised", 242), 92, 25)
            stageTag:setPosition(cc.p(-86, y - 12))
            rail:addChild(stageTag, 3)
            local stageLabel = createLabel(
                string.format("%02d  %s", index, V2UITheme.progress_labels[index]),
                layout.compact and 10 or 11,
                color3(accentName),
                80,
                cc.TEXT_ALIGNMENT_RIGHT,
                BoldFont
            )
            stageLabel:setAnchorPoint(cc.p(0.5, 0.5))
            stageLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
            stageLabel:setPosition(cc.p(44, 13))
            stageTag:addChild(stageLabel, 2)
        end
    end
end

createButtonFace = function(width, height, role, pressed, accentName)
    local face = cc.Node:create()
    face:setContentSize(cc.size(width, height))
    local stageAccent = accentName or "gold"
    local style = {
        primary = { fill = stageAccent, text = "shell", alpha = pressed and 206 or 244 },
        selected = { fill = "surface_soft", text = stageAccent, alpha = pressed and 220 or 248, accent = stageAccent },
        utility = { fill = "shell_raised", text = "muted", alpha = pressed and 214 or 244 },
        danger = { fill = "surface", text = "danger", alpha = pressed and 212 or 242, border = "danger" },
        choice = { fill = "surface_soft", text = "ink", alpha = pressed and 214 or 244 },
    }
    local token = style[role] or style.choice
    local inset = pressed and 2 or 0
    local fill = cc.LayerColor:create(color4(token.fill, token.alpha), width - inset * 2, height - inset)
    fill:setPosition(cc.p(inset, pressed and 0 or 1))
    face:addChild(fill, 1)
    if token.border ~= nil then
        addBorder(fill, width - inset * 2, height - inset, token.border, pressed and 104 or 146, 1)
    end
    if token.accent ~= nil then
        local accent = cc.LayerColor:create(color4(token.accent, 255), 3, height - inset)
        accent:setPosition(cc.p(0, 0))
        fill:addChild(accent, 2)
    end
    return face, token.text
end

local function actionRoleCaption(role)
    local captions = {
        primary = "推进",
        selected = "已选",
        utility = "辅助",
        danger = "风险",
        choice = "选择",
    }
    return captions[role] or "指令"
end

local function createActionFace(width, height, role, pressed, accentName, actionIndex)
    local face, textColor = createButtonFace(width, height, role, pressed, accentName)
    local blockColor = accentName
    local blockAlpha = pressed and 176 or 224
    local numberColor = "shell"
    if role == "primary" then
        blockColor = "shell"
        blockAlpha = pressed and 150 or 190
        numberColor = accentName
    elseif role == "utility" then
        blockColor = "muted"
        blockAlpha = pressed and 100 or 132
    elseif role == "danger" then
        blockColor = "danger"
    end

    local commandWidth = 42
    local commandBlock = cc.LayerColor:create(color4(blockColor, blockAlpha), commandWidth, height - 2)
    commandBlock:setPosition(cc.p(1, 1))
    face:addChild(commandBlock, 3)

    local commandNumber = createLabel(string.format("%02d", actionIndex), 15, color3(numberColor), nil, nil, BoldFont)
    commandNumber:setAnchorPoint(cc.p(0.5, 0.5))
    commandNumber:setPosition(cc.p(commandWidth * 0.5, height * 0.59))
    commandBlock:addChild(commandNumber, 2)

    local commandRole = createLabel(actionRoleCaption(role), 8, color3(numberColor))
    commandRole:setAnchorPoint(cc.p(0.5, 0.5))
    commandRole:setPosition(cc.p(commandWidth * 0.5, height * 0.24))
    commandBlock:addChild(commandRole, 2)
    return face, textColor
end

function V2ChapterLayer:addActionButton(parent, state, action, actionIndex, actionCount, x, y, layout)
    local role = V2UITheme.actionRole(
        state.stage,
        action.id,
        actionIndex,
        actionCount,
        state.selected_module
    )
    local normalFace, textColor = createActionFace(
        layout.action_button_width,
        layout.action_button_height,
        role,
        false,
        V2UITheme.accentName(state.stage),
        actionIndex
    )
    local pressedFace = createActionFace(
        layout.action_button_width,
        layout.action_button_height,
        role,
        true,
        V2UITheme.accentName(state.stage),
        actionIndex
    )
    local button = cc.MenuItemSprite:create(normalFace, pressedFace)
    button:setPosition(cc.p(x, y))
    button:registerScriptTapHandler(function()
        self:performAction(action.id)
    end)

    local maximumLineLength = 0
    for line in string.gmatch(action.label, "[^\n]+") do
        maximumLineLength = math.max(maximumLineLength, string.len(line))
    end
    local fontSize = maximumLineLength > 36 and (layout.action_font_size - 2) or layout.action_font_size
    local labelWidth = layout.action_button_width - 58
    local label = createLabel(action.label, fontSize, color3(textColor), labelWidth, cc.TEXT_ALIGNMENT_LEFT, BoldFont)
    label:setAnchorPoint(cc.p(0, 0.5))
    label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    label:setPosition(cc.p(52, layout.action_button_height * 0.5 + 1))
    button:addChild(label, 2)
    parent:addChild(button)
end

function V2ChapterLayer:performAction(actionId)
    local before = captureActionSnapshot(self.controller:load())
    local ok, message = self.controller:dispatch(actionId)
    local after = captureActionSnapshot(self.controller:load())
    if not ok then
        ToastUtil:downString(message)
    else
        self:playActionFeedback(actionId, before.stage, after.stage)
    end
    self:refresh()
    if ok then
        local layout = V2ChapterLayout.build(self.visibleSize.width, self.visibleSize.height)
        self:showActionFeedback(actionId, before, after, layout)
    end
    return ok, message
end

function V2ChapterLayer:addObjectiveBanner(parent, state, layout)
    local accentName = V2UITheme.accentName(state.stage)
    local panelWidth = self.visibleSize.width - 128
    local panelHeight = layout.objective_panel_height
    local mission = cc.LayerColor:create(color4("shell", 202), panelWidth, panelHeight)
    mission:setPosition(cc.p(26, layout.objective_y - panelHeight * 0.5))
    parent:addChild(mission, 6)

    local orderBlock = cc.LayerColor:create(color4(accentName, 226), 52, panelHeight)
    orderBlock:setPosition(cc.p(0, 0))
    mission:addChild(orderBlock, 2)
    local orderNumber = createLabel("01", layout.compact and 17 or 20, color3("shell"), nil, nil, BoldFont)
    orderNumber:setAnchorPoint(cc.p(0.5, 0.5))
    orderNumber:setPosition(cc.p(26, panelHeight * 0.61))
    orderBlock:addChild(orderNumber, 2)
    local orderLabel = createLabel("航令", layout.compact and 8 or 9, color3("shell"))
    orderLabel:setAnchorPoint(cc.p(0.5, 0.5))
    orderLabel:setPosition(cc.p(26, panelHeight * 0.25))
    orderBlock:addChild(orderLabel, 2)

    local badge = createLabel(V2UITheme.stageKind(state.stage), layout.compact and 9 or 10, color3(accentName))
    badge:setAnchorPoint(cc.p(0, 0.5))
    badge:setPosition(cc.p(66, panelHeight - (layout.compact and 14 or 16)))
    mission:addChild(badge, 3)
    local objective = createLabel(
        state.objective,
        layout.objective_size,
        COLORS.ink,
        panelWidth - 78,
        cc.TEXT_ALIGNMENT_LEFT
    )
    objective:setAnchorPoint(cc.p(0, 0.5))
    objective:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    objective:setPosition(cc.p(66, panelHeight * 0.40))
    mission:addChild(objective, 3)
end

function V2ChapterLayer:addResourceRow(parent, resources, layout)
    local width = self.visibleSize.width
    local items = V2UITheme.resourceItems(resources)
    local dockWidth = width - 128
    local dockHeight = layout.resource_chip_height
    local statusDock = cc.LayerColor:create(color4("shell_raised", 222), dockWidth, dockHeight)
    statusDock:setPosition(cc.p(26, layout.resource_y - dockHeight * 0.5))
    parent:addChild(statusDock, 6)

    local cellWidth = dockWidth / #items
    for index, item in ipairs(items) do
        local cellX = cellWidth * (index - 1)
        if index > 1 then
            local separator = cc.LayerColor:create(color4("separator", 84), 1, dockHeight - 14)
            separator:setPosition(cc.p(cellX, 7))
            statusDock:addChild(separator, 2)
        end
        local iconX = cellX + (layout.compact and 16 or 18)
        addTintedIcon(statusDock, item.icon, iconX, dockHeight * 0.5, layout.compact and 18 or 20, item.accent)
        local textX = cellX + (layout.compact and 30 or 33)
        local resourceName = createLabel(item.name, layout.compact and 8 or 9, color3(item.accent), nil, nil, BoldFont)
        resourceName:setAnchorPoint(cc.p(0, 0.5))
        resourceName:setPosition(cc.p(textX, dockHeight * 0.70))
        statusDock:addChild(resourceName, 3)
        local resourceValue = createLabel(tostring(item.value), layout.resource_size, COLORS.ink, nil, nil, BoldFont)
        resourceValue:setAnchorPoint(cc.p(0, 0.5))
        resourceValue:setPosition(cc.p(textX, dockHeight * 0.30))
        statusDock:addChild(resourceValue, 3)
    end
end

local function routeLabel(state)
    if state.route == "safe_route" then return "安全外海" end
    if state.route == "risky_shortcut" then return "暗礁近路" end
    return "航线待定"
end

function V2ChapterLayer:addContextColumns(parent, state, moduleData, layout, cardWidth, metaY)
    local data = self.controller:getChapterData()
    local node = data.by_id.map_node[state.current_node]
    local columns = {
        { label = "当前位置", value = node.name },
        { label = "航线", value = routeLabel(state) },
        { label = "船装", value = moduleData.name },
    }
    local startX = 24
    local contentWidth = cardWidth - 48
    local columnWidth = contentWidth / #columns
    local topY = metaY or layout.card_meta_y
    for index, column in ipairs(columns) do
        local x = startX + columnWidth * (index - 1)
        if index > 1 then
            local separator = cc.LayerColor:create(color4("separator", 66), 1, 32)
            separator:setPosition(cc.p(x - 10, topY - 31))
            parent:addChild(separator, 3)
        end
        local caption = createLabel(column.label, layout.compact and 8 or 9, COLORS.muted)
        caption:setAnchorPoint(cc.p(0, 1))
        caption:setPosition(cc.p(x, topY))
        parent:addChild(caption, 4)
        local value = createLabel(column.value, layout.card_meta_size, COLORS.ink, columnWidth - 16, cc.TEXT_ALIGNMENT_LEFT, BoldFont)
        value:setAnchorPoint(cc.p(0, 1))
        value:setPosition(cc.p(x, topY - (layout.compact and 12 or 14)))
        parent:addChild(value, 4)
    end
end

local function addMeter(parent, labelText, value, maximum, x, y, width, accentName, compact, iconPath)
    addTintedIcon(parent, iconPath, x + 8, y + (compact and 17 or 19), compact and 16 or 18, accentName, 214)
    local label = createLabel(labelText, compact and 12 or 14, COLORS.muted)
    label:setAnchorPoint(cc.p(0, 0))
    label:setPosition(cc.p(x + (compact and 20 or 22), y + 9))
    parent:addChild(label, 4)
    local valueLabel = createLabel(string.format("%d / %d", value, maximum), compact and 12 or 14, color3(accentName))
    valueLabel:setAnchorPoint(cc.p(1, 0))
    valueLabel:setPosition(cc.p(x + width, y + 9))
    parent:addChild(valueLabel, 4)
    local track = cc.LayerColor:create(color4("track", 255), width, 6)
    track:setPosition(cc.p(x, y))
    parent:addChild(track, 3)
    local ratio = maximum > 0 and math.max(0, math.min(1, value / maximum)) or 0
    if ratio > 0 then
        local fill = cc.LayerColor:create(color4(accentName, 230), math.max(2, width * ratio), 6)
        fill:setPosition(cc.p(x, y))
        parent:addChild(fill, 4)
    end
end

function V2ChapterLayer:addBattleStatus(parent, state, impact, layout, cardWidth)
    local compact = layout.compact
    local meterWidth = (cardWidth - 72) * 0.5
    local rightX = 40 + meterWidth
    local mainY = layout.card_battle_y
    local secondaryY = mainY - (compact and 38 or 44)
    if state.stage == "naval" then
        addMeter(parent, "我方船体", state.battle.player_hull, state.battle.player_hull_max, 24, mainY, meterWidth, "sea", compact, V2UITheme.battleIcon("hull"))
        addMeter(parent, "敌方船体", state.battle.enemy_ship_hp, state.battle.enemy_ship_hp_max, rightX, mainY, meterWidth, "danger", compact, V2UITheme.battleIcon("hull"))
        addMeter(parent, state.battle.deck_broken and "敌方甲板 · 已击毁" or "敌方甲板", state.battle.deck_damage, state.battle.deck_threshold, 24, secondaryY, meterWidth, "muted", compact, V2UITheme.battleIcon("deck"))
        addMeter(parent, state.battle.guns_suppressed and "敌方火炮 · 已压制" or "敌方火炮", state.battle.gun_damage, state.battle.gun_threshold, rightX, secondaryY, meterWidth, "muted", compact, V2UITheme.battleIcon("cannon"))
    elseif state.stage == "boarding" then
        addMeter(parent, "我方接舷队", state.battle.crew_hp, state.battle.crew_hp_max, 24, mainY, meterWidth, "sea", compact, V2UITheme.battleIcon("crew"))
        addMeter(parent, "敌方甲板部队", state.battle.enemy_boarding_hp, state.battle.enemy_boarding_hp_max, rightX, mainY, meterWidth, "danger", compact, V2UITheme.battleIcon("crew"))
    else
        return
    end

    if impact ~= nil and impact.text ~= nil then
        local impactLabel = createLabel(
            impact.text,
            compact and 12 or 14,
            COLORS.muted,
            cardWidth - 48,
            cc.TEXT_ALIGNMENT_LEFT
        )
        impactLabel:setAnchorPoint(cc.p(0, 1))
        impactLabel:setPosition(cc.p(24, compact and 65 or 75))
        parent:addChild(impactLabel, 4)
    end
end

function V2ChapterLayer:refresh()
    self.dynamicNode:removeAllChildren()
    local state = self.controller:load()
    local root = self.dynamicNode
    local width = self.visibleSize.width
    local height = self.visibleSize.height
    local layout = V2ChapterLayout.build(width, height)
    local isQA = V2Config:isQAProfile(state.profile)
    local accentName = V2UITheme.accentName(state.stage)

    self:addHeroArt(root, state, layout)

    local topBar = cc.LayerColor:create(color4("shell", 250), width, layout.top_bar_height)
    topBar:setPosition(cc.p(0, height - layout.top_bar_height))
    root:addChild(topBar, 10)

    local chapterPlate = cc.LayerColor:create(color4(accentName, 236), 44, 56)
    chapterPlate:setPosition(cc.p(26, 16))
    topBar:addChild(chapterPlate, 2)
    local chapterNumber = createLabel("01", layout.compact and 17 or 19, color3("shell"), nil, nil, BoldFont)
    chapterNumber:setAnchorPoint(cc.p(0.5, 0.5))
    chapterNumber:setPosition(cc.p(22, 34))
    chapterPlate:addChild(chapterNumber, 2)
    local chapterUnit = createLabel("章", layout.compact and 8 or 9, color3("shell"))
    chapterUnit:setAnchorPoint(cc.p(0.5, 0.5))
    chapterUnit:setPosition(cc.p(22, 13))
    chapterPlate:addChild(chapterUnit, 2)

    local kicker = createLabel("瓶中海域  /  CAPTAIN'S LOG", layout.compact and 9 or 10, COLORS.muted)
    kicker:setAnchorPoint(cc.p(0, 0.5))
    kicker:setPosition(cc.p(82, layout.kicker_y))
    topBar:addChild(kicker)

    local title = createLabel(self.controller:getStageTitle(), layout.title_size, COLORS.ink, width - 232, nil, BoldFont)
    title:setAnchorPoint(cc.p(0, 0.5))
    title:setPosition(cc.p(82, layout.title_y))
    topBar:addChild(title)

    if isQA then
        local profile = createLabel("QA  ·  " .. state.profile, layout.compact and 10 or 11, COLORS.muted)
        profile:setAnchorPoint(cc.p(1, 0.5))
        profile:setPosition(cc.p(width - 28, layout.profile_y))
        topBar:addChild(profile)
    end

    local infoWidth = 58
    local infoHeight = 44
    local infoNormal, infoTextColor = createButtonFace(infoWidth, infoHeight, "utility", false, accentName)
    local infoPressed = createButtonFace(infoWidth, infoHeight, "utility", true, accentName)
    local releaseInfoItem = cc.MenuItemSprite:create(infoNormal, infoPressed)
    releaseInfoItem:setPosition(cc.p(width - 30 - infoWidth * 0.5, layout.title_y))
    releaseInfoItem:registerScriptTapHandler(function() self:showReleaseInfo() end)
    local releaseInfoLabel = createLabel("支持", 11, color3(infoTextColor), infoWidth - 12, cc.TEXT_ALIGNMENT_CENTER, BoldFont)
    releaseInfoLabel:setAnchorPoint(cc.p(0.5, 0.5))
    releaseInfoLabel:setPosition(cc.p(infoWidth * 0.5, infoHeight * 0.5 + 1))
    releaseInfoItem:addChild(releaseInfoLabel, 3)
    local releaseInfoMenu = cc.Menu:create(releaseInfoItem)
    releaseInfoMenu:setPosition(cc.p(0, 0))
    topBar:addChild(releaseInfoMenu)

    self:addObjectiveBanner(root, state, layout)
    self:addResourceRow(root, state.resources, layout)

    self:addVoyageRail(root, state, layout)

    local isBattleStage = state.stage == "naval" or state.stage == "boarding"
    local cardHeight = isBattleStage and layout.card_height or layout.story_card_height
    local cardY = isBattleStage and layout.card_y or (layout.card_y - layout.story_card_offset)
    local cardMetaY = cardHeight - (layout.compact and 34 or 38)
    local narrativeY = cardHeight - (layout.compact and 84 or 94)
    local cardWidth = width - 44
    local cardShadow = cc.LayerColor:create(color4("shell", 104), cardWidth, cardHeight)
    cardShadow:setPosition(cc.p(29, cardY - 6))
    root:addChild(cardShadow, 6)
    local card = addSurface(root, 22, cardY, cardWidth, cardHeight, {
        fill = "surface",
        alpha = 247,
        z = 7,
    })

    local cardSpine = cc.LayerColor:create(color4(accentName, 255), 4, cardHeight)
    cardSpine:setPosition(cc.p(0, 0))
    card:addChild(cardSpine, 3)

    local logTabWidth = layout.compact and 94 or 108
    local logTab = cc.LayerColor:create(color4(accentName, 246), logTabWidth, 27)
    logTab:setPosition(cc.p(0, cardHeight))
    card:addChild(logTab, 5)
    local logTabLabel = createLabel("船长日志", layout.compact and 10 or 11, color3("shell"), nil, nil, BoldFont)
    logTabLabel:setAnchorPoint(cc.p(0.5, 0.5))
    logTabLabel:setPosition(cc.p(logTabWidth * 0.5, 14))
    logTab:addChild(logTabLabel, 2)

    local stageKindLabel = createLabel(V2UITheme.stageKind(state.stage), layout.compact and 9 or 10, color3(accentName))
    stageKindLabel:setAnchorPoint(cc.p(1, 0.5))
    stageKindLabel:setPosition(cc.p(cardWidth - 22, cardHeight + 13))
    card:addChild(stageKindLabel, 5)

    local moduleData = self.controller:getChapterData().by_id.ship_module[state.selected_module]
    self:addContextColumns(card, state, moduleData, layout, cardWidth, cardMetaY)

    local metaSeparator = cc.LayerColor:create(color4("separator", 72), cardWidth - 48, 1)
    metaSeparator:setPosition(cc.p(24, cardMetaY - (layout.compact and 40 or 44)))
    card:addChild(metaSeparator, 3)

    local narrative = createLabel(self.controller:getNarrative(), layout.card_narrative_size, COLORS.ink, cardWidth - 48)
    narrative:setAnchorPoint(cc.p(0, 1))
    narrative:setPosition(cc.p(24, narrativeY))
    card:addChild(narrative)

    local impact = self.controller:getCombatImpact()
    local battle = battleLine(state, impact)
    if battle then
        self:addBattleStatus(card, state, impact, layout, cardWidth)
    end

    local logSeparatorY = layout.card_result_y + (layout.compact and 22 or 26)
    local logSeparator = cc.LayerColor:create(color4("separator", 78), cardWidth - 48, 1)
    logSeparator:setPosition(cc.p(24, logSeparatorY))
    card:addChild(logSeparator, 3)
    local logMarker = cc.LayerColor:create(color4(accentName, 255), 7, 7)
    logMarker:setPosition(cc.p(24, layout.card_result_y - 3))
    logMarker:setRotation(45)
    card:addChild(logMarker, 3)
    local logBadge = createLabel("最近记录", layout.compact and 10 or 11, color3(accentName))
    logBadge:setAnchorPoint(cc.p(0, 0.5))
    logBadge:setPosition(cc.p(40, layout.card_result_y))
    card:addChild(logBadge, 3)
    local resultLabel = createLabel(state.last_result, layout.card_result_size - 1, COLORS.muted, cardWidth - 148)
    resultLabel:setAnchorPoint(cc.p(0, 0.5))
    resultLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    resultLabel:setPosition(cc.p(112, layout.card_result_y))
    card:addChild(resultLabel, 3)

    local actions = self.controller:getActions()
    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    root:addChild(menu)
    local columns = { width * 0.27, width * 0.73 }
    local actionBaseY = isBattleStage and layout.action_base_y or (layout.action_base_y - layout.story_card_offset)
    for index, action in ipairs(actions) do
        local x = width * 0.5
        local y = actionBaseY
        if #actions == 2 then
            x = columns[index]
        elseif #actions == 3 and state.stage == "route_choice" then
            if index > 1 then
                x = columns[index - 1]
                y = actionBaseY - layout.action_row_gap
            end
        elseif #actions == 3 then
            if index < 3 then
                x = columns[index]
            else
                y = actionBaseY - layout.action_row_gap
            end
        elseif #actions > 3 then
            local column = ((index - 1) % 2) + 1
            local row = math.floor((index - 1) / 2)
            x = columns[column]
            y = actionBaseY - row * layout.action_row_gap
            if index == #actions and (#actions % 2) == 1 then
                x = width * 0.5
            end
        end
        self:addActionButton(menu, state, action, index, #actions, x, y, layout)
    end

    if isQA then
        local report = self.controller:getTelemetrySummary()
        local footerText = string.format(
            "QA 记录 %d 条｜决策 %d｜舰炮 %d｜接舷 %d｜无效 %d",
            report.total_events,
            report.decisions,
            report.naval_actions,
            report.boarding_actions,
            report.invalid_actions
        )
        local footer = createLabel(footerText, layout.footer_size, COLORS.muted, width - 40, cc.TEXT_ALIGNMENT_CENTER)
        footer:setAnchorPoint(cc.p(0, 0))
        footer:setPosition(cc.p(20, layout.footer_y))
        root:addChild(footer, 2)
    end
end

return V2ChapterLayer
