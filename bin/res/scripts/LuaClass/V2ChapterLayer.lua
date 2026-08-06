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
    addBorder(
        surface,
        width,
        height,
        config.border or "sea",
        config.border_alpha or 95,
        config.border_width or 1
    )
    if config.accent ~= nil then
        local accent = cc.LayerColor:create(color4(config.accent, 255), config.accent_width or 5, height)
        accent:setPosition(cc.p(0, 0))
        surface:addChild(accent, 2)
    end
    return surface
end

local function addPill(parent, text, x, y, width, height, accent, fontSize, align)
    local pill = addSurface(parent, x, y, width, height, {
        fill = "shell_raised",
        alpha = 226,
        border = accent or "sea",
        border_alpha = 92,
    })
    local label = createLabel(text, fontSize or 14, color3(accent or "ink"), width - 12, align or cc.TEXT_ALIGNMENT_CENTER)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p(width * 0.5, height * 0.5 + 1))
    pill:addChild(label, 3)
    return pill
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

local function heroGroupLabel(group)
    local labels = {
        harbor = "皇家港 / 船员整备",
        map = "羊皮海图 / 迷雾航行",
        combat = "敌船 / 舰炮与接舷",
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
            border = "gold",
            border_alpha = 155,
            accent = "gold",
            accent_width = 6,
        }
    )

    local heading = createLabel("隐私与支持", 25, COLORS.gold)
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
    local buttonHeight = 42
    for index, descriptor in ipairs(buttons) do
        local role = descriptor.isWeb and "primary" or (descriptor.label == "关闭" and "danger" or "utility")
        local normalFace, textColor = createButtonFace(buttonWidth, buttonHeight, role, false)
        local pressedFace = createButtonFace(buttonWidth, buttonHeight, role, true)
        local item = cc.MenuItemSprite:create(normalFace, pressedFace)
        local label = createLabel(descriptor.label, 13, color3(textColor), buttonWidth - 12, cc.TEXT_ALIGNMENT_CENTER)
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

function V2ChapterLayer:addHeroArt(parent, state, isQA, layout)
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

    local atmosphere = cc.LayerColor:create(color4(accentName, 26), width, artHeight)
    atmosphere:setPosition(cc.p(0, 0))
    frame:addChild(atmosphere, 2)

    local lowerScrim = cc.LayerColor:create(color4("shell", 124), width, layout.compact and 82 or 118)
    lowerScrim:setPosition(cc.p(0, 0))
    frame:addChild(lowerScrim, 3)

    local accentLine = cc.LayerColor:create(color4(accentName, 220), width, 3)
    accentLine:setPosition(cc.p(0, artHeight - 3))
    frame:addChild(accentLine, 5)

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

    local artTagText = heroGroupLabel(presentation.hero_group)
    if isQA then
        artTagText = "QA 构图  ·  " .. artTagText
    end
    local artTagHeight = layout.compact and 28 or 34
    local artTagY = layout.card_y + layout.card_height - artY
    addPill(
        frame,
        artTagText,
        24,
        artTagY,
        layout.compact and 196 or 224,
        artTagHeight,
        accentName,
        layout.compact and 12 or 14,
        cc.TEXT_ALIGNMENT_LEFT
    )

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
    local width = self.visibleSize.width
    local stripWidth = width - 52
    local stripHeight = 58
    local strip = addSurface(parent, 26, y - 10, stripWidth, stripHeight, {
        fill = "shell",
        alpha = 222,
        border = "sea",
        border_alpha = 66,
    })
    local current = V2UITheme.progressIndex(state.stage)
    local accentName = V2UITheme.accentName(state.stage)
    local startX = 50
    local endX = stripWidth - 50
    local segment = (endX - startX) / (#V2UITheme.progress_labels - 1)

    local routeLine = cc.LayerColor:create(color4("track", 255), endX - startX, 4)
    routeLine:setPosition(cc.p(startX, 32))
    strip:addChild(routeLine, 2)
    if current > 1 then
        local completeWidth = segment * (current - 1)
        local completeLine = cc.LayerColor:create(color4("success", 218), completeWidth, 4)
        completeLine:setPosition(cc.p(startX, 32))
        strip:addChild(completeLine, 3)
    end

    for index, labelText in ipairs(V2UITheme.progress_labels) do
        local x = startX + segment * (index - 1)
        local markerColor = "track"
        if index < current then markerColor = "success" end
        if index == current then markerColor = accentName end
        local markerSize = index == current and 16 or 12
        local marker = cc.LayerColor:create(color4(markerColor, 255), markerSize, markerSize)
        marker:setPosition(cc.p(x - markerSize * 0.5, 26 + (16 - markerSize) * 0.5))
        strip:addChild(marker, 4)

        local label = createLabel(
            labelText,
            13,
            index == current and color3(accentName) or (index < current and COLORS.ink or COLORS.muted),
            84,
            cc.TEXT_ALIGNMENT_CENTER
        )
        label:setAnchorPoint(cc.p(0.5, 0))
        label:setPosition(cc.p(x, 5))
        strip:addChild(label, 4)
    end
end

createButtonFace = function(width, height, role, pressed)
    local face = cc.Node:create()
    face:setContentSize(cc.size(width, height))
    local style = {
        primary = { fill = "gold", border = "gold", text = "shell", alpha = pressed and 188 or 238 },
        selected = { fill = "surface_soft", border = "gold", text = "gold", alpha = pressed and 220 or 248 },
        utility = { fill = "shell_raised", border = "sea", text = "sea", alpha = pressed and 210 or 246 },
        danger = { fill = "surface", border = "danger", text = "danger", alpha = pressed and 210 or 246 },
        choice = { fill = "surface_soft", border = "sea", text = "ink", alpha = pressed and 210 or 246 },
    }
    local token = style[role] or style.choice
    local yOffset = pressed and -2 or 0
    local shadow = cc.LayerColor:create(color4("shell", 170), width, height)
    shadow:setPosition(cc.p(0, -3))
    face:addChild(shadow, 0)
    local fill = cc.LayerColor:create(color4(token.fill, token.alpha), width, height)
    fill:setPosition(cc.p(0, yOffset))
    face:addChild(fill, 1)
    addBorder(fill, width, height, token.border, pressed and 145 or 230, 2)
    local accent = cc.LayerColor:create(color4(token.border, 255), 5, height)
    accent:setPosition(cc.p(0, 0))
    fill:addChild(accent, 2)
    return face, token.text
end

function V2ChapterLayer:addActionButton(parent, state, action, actionIndex, actionCount, x, y, layout)
    local role = V2UITheme.actionRole(
        state.stage,
        action.id,
        actionIndex,
        actionCount,
        state.selected_module
    )
    local normalFace, textColor = createButtonFace(
        layout.action_button_width,
        layout.action_button_height,
        role,
        false
    )
    local pressedFace = createButtonFace(
        layout.action_button_width,
        layout.action_button_height,
        role,
        true
    )
    local button = cc.MenuItemSprite:create(normalFace, pressedFace)
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

    local maximumLineLength = 0
    for line in string.gmatch(action.label, "[^\n]+") do
        maximumLineLength = math.max(maximumLineLength, string.len(line))
    end
    local fontSize = maximumLineLength > 36 and (layout.action_font_size - 2) or layout.action_font_size
    local labelWidth = math.max(layout.action_label_width, layout.action_button_width - 26)
    local label = createLabel(action.label, fontSize, color3(textColor), labelWidth, cc.TEXT_ALIGNMENT_CENTER)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    label:setPosition(cc.p(layout.action_button_width * 0.5, layout.action_button_height * 0.5 + 1))
    button:addChild(label, 2)
    parent:addChild(button)
end

function V2ChapterLayer:addObjectiveBanner(parent, state, layout)
    local width = self.visibleSize.width
    local accentName = V2UITheme.accentName(state.stage)
    local bannerHeight = layout.compact and 34 or 38
    local banner = addSurface(parent, 26, layout.objective_y - bannerHeight, width - 52, bannerHeight, {
        fill = "shell_raised",
        alpha = 235,
        border = accentName,
        border_alpha = 96,
        accent = accentName,
        accent_width = 5,
    })
    local badge = createLabel("目标", layout.compact and 12 or 13, color3(accentName))
    badge:setAnchorPoint(cc.p(0, 0.5))
    badge:setPosition(cc.p(16, bannerHeight * 0.5 + 1))
    banner:addChild(badge, 3)
    local objective = createLabel(
        state.objective,
        layout.objective_size - 2,
        COLORS.ink,
        width - 120,
        cc.TEXT_ALIGNMENT_LEFT
    )
    objective:setAnchorPoint(cc.p(0, 0.5))
    objective:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    objective:setPosition(cc.p(62, bannerHeight * 0.5 + 1))
    banner:addChild(objective, 3)
end

function V2ChapterLayer:addResourceRow(parent, resources, layout)
    local width = self.visibleSize.width
    local items = V2UITheme.resourceItems(resources)
    local contentWidth = width - 52
    local gap = layout.resource_chip_gap
    local chipWidth = (contentWidth - gap * (#items - 1)) / #items
    local chipHeight = layout.resource_chip_height
    local baseY = layout.resource_y - chipHeight
    for index, item in ipairs(items) do
        local x = 26 + (index - 1) * (chipWidth + gap)
        local chip = addSurface(parent, x, baseY, chipWidth, chipHeight, {
            fill = "shell",
            alpha = 218,
            border = item.accent,
            border_alpha = 82,
        })
        local accent = cc.LayerColor:create(color4(item.accent, 255), 4, chipHeight)
        accent:setPosition(cc.p(0, 0))
        chip:addChild(accent, 2)
        local label = createLabel(
            string.format("%s  %d", item.name, item.value),
            layout.resource_size - 2,
            COLORS.ink,
            chipWidth - 12,
            cc.TEXT_ALIGNMENT_CENTER
        )
        label:setAnchorPoint(cc.p(0.5, 0.5))
        label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        label:setPosition(cc.p(chipWidth * 0.5 + 2, chipHeight * 0.5 + 1))
        chip:addChild(label, 3)
    end
end

local function routeLabel(state)
    if state.route == "safe_route" then return "安全外海" end
    if state.route == "risky_shortcut" then return "暗礁近路" end
    return "航线待定"
end

function V2ChapterLayer:addMetaRow(parent, state, moduleData, layout, cardWidth)
    local data = self.controller:getChapterData()
    local node = data.by_id.map_node[state.current_node]
    local fontSize = layout.compact and 12 or 14
    local gap = 8
    local pillWidth = (cardWidth - 48 - gap * 2) / 3
    local y = layout.card_meta_y - (layout.compact and 26 or 31)
    local height = layout.compact and 28 or 34
    local values = {
        { "位置 · " .. node.name, "sea" },
        { "航线 · " .. routeLabel(state), state.route == "risky_shortcut" and "danger" or "sea" },
        { "船装 · " .. moduleData.name, "gold" },
    }
    for index, value in ipairs(values) do
        addPill(
            parent,
            value[1],
            16 + (index - 1) * (pillWidth + gap),
            y,
            pillWidth,
            height,
            value[2],
            fontSize,
            cc.TEXT_ALIGNMENT_CENTER
        )
    end
end

local function addMeter(parent, labelText, value, maximum, x, y, width, accentName, compact)
    local label = createLabel(labelText, compact and 12 or 14, COLORS.muted)
    label:setAnchorPoint(cc.p(0, 0))
    label:setPosition(cc.p(x, y + 11))
    parent:addChild(label, 4)
    local valueLabel = createLabel(string.format("%d / %d", value, maximum), compact and 12 or 14, color3(accentName))
    valueLabel:setAnchorPoint(cc.p(1, 0))
    valueLabel:setPosition(cc.p(x + width, y + 11))
    parent:addChild(valueLabel, 4)
    local track = cc.LayerColor:create(color4("track", 255), width, 8)
    track:setPosition(cc.p(x, y))
    parent:addChild(track, 3)
    local ratio = maximum > 0 and math.max(0, math.min(1, value / maximum)) or 0
    if ratio > 0 then
        local fill = cc.LayerColor:create(color4(accentName, 255), math.max(2, width * ratio), 8)
        fill:setPosition(cc.p(x, y))
        parent:addChild(fill, 4)
    end
end

function V2ChapterLayer:addBattleStatus(parent, state, impact, layout, cardWidth)
    local compact = layout.compact
    local meterWidth = (cardWidth - 72) * 0.5
    local rightX = 40 + meterWidth
    local mainY = compact and 132 or 176
    local secondaryY = compact and 96 or 132
    if state.stage == "naval" then
        addMeter(parent, "我方船体", state.battle.player_hull, state.battle.player_hull_max, 24, mainY, meterWidth, "success", compact)
        addMeter(parent, "敌方船体", state.battle.enemy_ship_hp, state.battle.enemy_ship_hp_max, rightX, mainY, meterWidth, "danger", compact)
        addMeter(parent, state.battle.deck_broken and "敌方甲板 · 已击毁" or "敌方甲板", state.battle.deck_damage, state.battle.deck_threshold, 24, secondaryY, meterWidth, "gold", compact)
        addMeter(parent, state.battle.guns_suppressed and "敌方火炮 · 已压制" or "敌方火炮", state.battle.gun_damage, state.battle.gun_threshold, rightX, secondaryY, meterWidth, "sea", compact)
    elseif state.stage == "boarding" then
        addMeter(parent, "我方接舷队", state.battle.crew_hp, state.battle.crew_hp_max, 24, mainY, meterWidth, "success", compact)
        addMeter(parent, "敌方甲板部队", state.battle.enemy_boarding_hp, state.battle.enemy_boarding_hp_max, rightX, mainY, meterWidth, "danger", compact)
    else
        return
    end

    if impact ~= nil and impact.text ~= nil then
        local impactLabel = createLabel(
            impact.text,
            compact and 12 or 14,
            color3(V2UITheme.accentName(state.stage)),
            cardWidth - 48,
            cc.TEXT_ALIGNMENT_LEFT
        )
        impactLabel:setAnchorPoint(cc.p(0, 1))
        impactLabel:setPosition(cc.p(24, compact and 78 or 104))
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

    self:addHeroArt(root, state, isQA, layout)

    local topBar = cc.LayerColor:create(color4("shell", 246), width, layout.top_bar_height)
    topBar:setPosition(cc.p(0, height - layout.top_bar_height))
    root:addChild(topBar)
    local topAccent = cc.LayerColor:create(color4(accentName, 215), width, 3)
    topAccent:setPosition(cc.p(0, 0))
    topBar:addChild(topAccent, 3)

    local kickerText = "海上探险家  ·  第一章"
    if isQA then
        kickerText = "NEW PIRATE V2  ·  CHAPTER 01  ·  QA"
    end
    local kicker = createLabel(kickerText, 14, color3(accentName))
    kicker:setAnchorPoint(cc.p(0, 0.5))
    kicker:setPosition(cc.p(30, layout.kicker_y))
    topBar:addChild(kicker)

    local title = createLabel(self.controller:getStageTitle(), layout.title_size, COLORS.ink, width - 170)
    title:setAnchorPoint(cc.p(0, 0.5))
    title:setPosition(cc.p(30, layout.title_y))
    topBar:addChild(title)

    if isQA then
        local profile = createLabel("存档 " .. state.profile, 14, COLORS.muted)
        profile:setAnchorPoint(cc.p(1, 0.5))
        profile:setPosition(cc.p(width - 28, layout.profile_y))
        topBar:addChild(profile)
    end

    local releaseInfoLabel = createLabel("隐私 · 支持", 13, COLORS.gold)
    local releaseInfoItem = cc.MenuItemLabel:create(releaseInfoLabel)
    releaseInfoItem:setPosition(cc.p(width - 62, layout.title_y))
    releaseInfoItem:registerScriptTapHandler(function() self:showReleaseInfo() end)
    local releaseInfoMenu = cc.Menu:create(releaseInfoItem)
    releaseInfoMenu:setPosition(cc.p(0, 0))
    topBar:addChild(releaseInfoMenu)

    self:addObjectiveBanner(root, state, layout)
    self:addResourceRow(root, state.resources, layout)

    self:addMapStrip(root, state, layout.map_y)

    local cardHeight = layout.card_height
    local cardWidth = width - 52
    local card = addSurface(root, 26, layout.card_y, cardWidth, cardHeight, {
        fill = "surface",
        alpha = 216,
        border = accentName,
        border_alpha = 118,
        accent = accentName,
        accent_width = 6,
    })

    local stageLabel = createLabel(self.controller:getStageTitle(), layout.card_title_size, color3(accentName))
    stageLabel:setAnchorPoint(cc.p(0, 1))
    stageLabel:setPosition(cc.p(24, layout.card_title_y))
    card:addChild(stageLabel)

    local stageKind = createLabel(V2UITheme.stageKind(state.stage), layout.compact and 12 or 14, COLORS.muted)
    stageKind:setAnchorPoint(cc.p(1, 1))
    stageKind:setPosition(cc.p(cardWidth - 20, layout.card_title_y - 4))
    card:addChild(stageKind, 3)

    local moduleData = self.controller:getChapterData().by_id.ship_module[state.selected_module]
    self:addMetaRow(card, state, moduleData, layout, cardWidth)

    local narrative = createLabel(self.controller:getNarrative(), layout.card_narrative_size, COLORS.ink, cardWidth - 48)
    narrative:setAnchorPoint(cc.p(0, 1))
    narrative:setPosition(cc.p(24, layout.card_narrative_y))
    card:addChild(narrative)

    local impact = self.controller:getCombatImpact()
    local battle = battleLine(state, impact)
    if battle then
        self:addBattleStatus(card, state, impact, layout, cardWidth)
    end

    local logHeight = layout.compact and 42 or 48
    local logY = math.max(8, layout.card_result_y - 5)
    local resultPanel = addSurface(card, 16, logY, cardWidth - 32, logHeight, {
        fill = "shell",
        alpha = 226,
        border = "muted",
        border_alpha = 48,
    })
    local logBadge = createLabel("航海日志", layout.compact and 11 or 12, color3(accentName))
    logBadge:setAnchorPoint(cc.p(0, 0.5))
    logBadge:setPosition(cc.p(12, logHeight * 0.5 + 1))
    resultPanel:addChild(logBadge, 3)
    local resultLabel = createLabel(state.last_result, layout.card_result_size - 1, COLORS.muted, cardWidth - 132)
    resultLabel:setAnchorPoint(cc.p(0, 0.5))
    resultLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    resultLabel:setPosition(cc.p(86, logHeight * 0.5 + 1))
    resultPanel:addChild(resultLabel, 3)

    local actions = self.controller:getActions()
    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    root:addChild(menu)
    local columns = { width * 0.27, width * 0.73 }
    for index, action in ipairs(actions) do
        local x = width * 0.5
        local y = layout.action_base_y
        if #actions == 2 then
            x = columns[index]
        elseif #actions == 3 and state.stage == "route_choice" then
            if index > 1 then
                x = columns[index - 1]
                y = layout.action_base_y - layout.action_row_gap
            end
        elseif #actions == 3 then
            if index < 3 then
                x = columns[index]
            else
                y = layout.action_base_y - layout.action_row_gap
            end
        elseif #actions > 3 then
            local column = ((index - 1) % 2) + 1
            local row = math.floor((index - 1) / 2)
            x = columns[column]
            y = layout.action_base_y - row * layout.action_row_gap
            if index == #actions and (#actions % 2) == 1 then
                x = width * 0.5
            end
        end
        self:addActionButton(menu, state, action, index, #actions, x, y, layout)
    end

    local footerText = "迷雾会记住你的每一次选择。"
    if isQA then
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
    local footerShade = cc.LayerColor:create(color4("shell", 232), width, layout.compact and 24 or 34)
    footerShade:setPosition(cc.p(0, 0))
    root:addChild(footerShade, 1)
    local footer = createLabel(footerText, layout.footer_size, COLORS.muted, width - 40, cc.TEXT_ALIGNMENT_CENTER)
    footer:setAnchorPoint(cc.p(0, 0))
    footer:setPosition(cc.p(20, layout.footer_y))
    root:addChild(footer, 2)
end

return V2ChapterLayer
