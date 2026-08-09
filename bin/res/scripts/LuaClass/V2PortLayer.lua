require "LuaClass/Header"
require "LuaClass/ToastUtil"
require "LuaClass/V2ChapterController"

local V2Config = require "LuaClass/V2Config"
local V2PortModel = require "LuaClass/V2PortModel"
local V2UITheme = require "LuaClass/V2UITheme"

V2PortLayer = class("V2PortLayer", function()
    return cc.Layer:create()
end)

V2PortLayer.__index = V2PortLayer

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
    sea = color3("sea"),
    danger = color3("danger"),
    success = color3("success"),
    purple = color3("purple"),
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

local function addBorder(parent, width, height, accentName, alpha, thickness)
    local line = thickness or 1
    local top = cc.LayerColor:create(color4(accentName, alpha or 72), width, line)
    top:setPosition(cc.p(0, height - line))
    parent:addChild(top, 2)
    local bottom = cc.LayerColor:create(color4(accentName, alpha or 72), width, line)
    bottom:setPosition(cc.p(0, 0))
    parent:addChild(bottom, 2)
    local left = cc.LayerColor:create(color4(accentName, alpha or 72), line, height)
    left:setPosition(cc.p(0, 0))
    parent:addChild(left, 2)
    local right = cc.LayerColor:create(color4(accentName, alpha or 72), line, height)
    right:setPosition(cc.p(width - line, 0))
    parent:addChild(right, 2)
end

local function addSurface(parent, x, y, width, height, options)
    local config = options or {}
    local surface = cc.LayerColor:create(color4(config.fill or "surface", config.alpha or 238), width, height)
    surface:setPosition(cc.p(x, y))
    parent:addChild(surface, config.z or 1)
    if config.border then
        addBorder(surface, width, height, config.border, config.border_alpha or 70, config.border_width)
    end
    if config.accent then
        local accent = cc.LayerColor:create(color4(config.accent, 246), config.accent_width or 4, height)
        accent:setPosition(cc.p(0, 0))
        surface:addChild(accent, 3)
    end
    return surface
end

local function fitSprite(sprite, targetWidth, targetHeight)
    local size = sprite:getContentSize()
    if size.width <= 0 or size.height <= 0 then return end
    sprite:setScale(math.max(targetWidth / size.width, targetHeight / size.height))
end

local function addTintedIcon(parent, path, x, y, size, accentName, opacity)
    local icon = cc.Sprite:create(path)
    if icon == nil then return nil end
    local content = icon:getContentSize()
    local maximum = math.max(content.width, content.height)
    if maximum > 0 then icon:setScale(size / maximum) end
    icon:setColor(color3(accentName))
    icon:setOpacity(opacity or 226)
    icon:setPosition(cc.p(x, y))
    parent:addChild(icon, 5)
    return icon
end

local function buttonFace(width, height, role, pressed, accentName)
    local fill = "surface_soft"
    local alpha = pressed and 246 or 232
    local textColor = "ink"
    if role == "primary" then
        fill = accentName or "sea"
        alpha = pressed and 206 or 242
        textColor = "shell"
    elseif role == "selected" then
        fill = "shell_raised"
        alpha = pressed and 252 or 242
    elseif role == "danger" then
        fill = "surface"
        alpha = pressed and 252 or 235
        textColor = "danger"
    end
    local node = cc.Node:create()
    node:setContentSize(cc.size(width, height))
    local surface = addSurface(node, 0, 0, width, height, {
        fill = fill,
        alpha = alpha,
        border = role == "danger" and "danger" or nil,
        border_alpha = 150,
    })
    if role == "selected" then
        local marker = cc.LayerColor:create(color4(accentName or "sea", 255), 4, height)
        marker:setPosition(cc.p(0, 0))
        surface:addChild(marker, 4)
    end
    if pressed then
        local press = cc.LayerColor:create(color4("ink", 18), width - 4, height - 4)
        press:setPosition(cc.p(2, 2))
        surface:addChild(press, 5)
    end
    return node, textColor
end

local function portLayout(width, height)
    local compact = height < 1050
    local topBar = compact and 96 or 132
    local resourceTop = height - topBar - (compact and 58 or 72)
    local statusHeight = compact and 126 or 162
    local statusY = resourceTop - statusHeight - (compact and 18 or 26)
    local navY = compact and 72 or 92
    local navHeight = compact and 76 or 94
    local sheetY = navY + navHeight + (compact and 16 or 24)
    local sheetHeight = statusY - sheetY - (compact and 12 or 18)
    return {
        compact = compact,
        top_bar_height = topBar,
        resource_y = resourceTop,
        resource_height = compact and 42 or 50,
        status_y = statusY,
        status_height = statusHeight,
        sheet_y = sheetY,
        sheet_height = sheetHeight,
        nav_y = navY,
        nav_height = navHeight,
        footer_y = compact and 8 or 12,
        title_size = compact and 28 or 32,
        body_size = compact and 13 or 15,
    }
end

function V2PortLayer:create()
    local view = V2PortLayer.new()
    if view and view:init() then return view end
    return nil
end

function V2PortLayer:init()
    self.controller = V2ChapterController:getInstance()
    local state = self.controller:load()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.activeSection = "chart"
    if V2Config:isQAProfile(state.profile) and os ~= nil and os.getenv ~= nil then
        local requested = os.getenv("NEWPIRATE_V2_PORT_SECTION")
        if requested ~= nil and V2PortModel.section(requested).id == requested then
            self.activeSection = requested
        end
    end
    self.dynamicNode = cc.Node:create()
    self:addChild(self.dynamicNode)
    self:refresh()
    if V2Config:isQAProfile(state.profile) and os ~= nil and os.getenv ~= nil then
        local qaAction = os.getenv("NEWPIRATE_V2_QA_ACTION")
        if qaAction ~= nil and qaAction ~= "" then
            self:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.8),
                cc.CallFunc:create(function() self:performAction(qaAction) end)
            ))
        end
    end
    return true
end

function V2PortLayer:viewWillDestory()
end

function V2PortLayer:destory()
    self:removeAllChildren()
end

function V2PortLayer:updateInfoLabel()
end

function V2PortLayer:returnToVoyage()
    if zqDispatch ~= nil and zqDispatch.moveToV2Chapter ~= nil then
        zqDispatch:moveToV2Chapter()
    end
end

function V2PortLayer:performAction(actionId)
    local ok, message = self.controller:dispatch(actionId)
    if not ok then
        ToastUtil:downString(message)
        return
    end
    if V2PortModel.returnsToVoyage(actionId) then
        self:returnToVoyage()
        return
    end
    ToastUtil:downString(V2UITheme.actionFeedbackTitle(actionId, self.controller:load().stage))
    self:refresh()
end

function V2PortLayer:addTopBar(parent, state, status, layout)
    local width = self.visibleSize.width
    local height = self.visibleSize.height
    local bar = cc.LayerColor:create(color4("shell", 252), width, layout.top_bar_height)
    bar:setPosition(cc.p(0, height - layout.top_bar_height))
    parent:addChild(bar, 20)

    local plateWidth = 44
    local plateHeight = layout.compact and 54 or 58
    local plate = cc.LayerColor:create(color4("sea", 240), plateWidth, plateHeight)
    plate:setPosition(cc.p(26, 16))
    bar:addChild(plate, 2)
    local mark = createLabel("港", layout.compact and 16 or 18, color3("shell"), nil, nil, BoldFont)
    mark:setAnchorPoint(cc.p(0.5, 0.5))
    mark:setPosition(cc.p(plateWidth * 0.5, plateHeight * 0.62))
    plate:addChild(mark, 3)
    local unit = createLabel("整备", 8, color3("shell"))
    unit:setAnchorPoint(cc.p(0.5, 0.5))
    unit:setPosition(cc.p(plateWidth * 0.5, plateHeight * 0.22))
    plate:addChild(unit, 3)

    local kicker = createLabel("皇家港  /  FLEET QUARTERS", layout.compact and 9 or 10, COLORS.muted)
    kicker:setAnchorPoint(cc.p(0, 0.5))
    kicker:setPosition(cc.p(82, layout.compact and 70 or 98))
    bar:addChild(kicker, 3)
    local title = createLabel("远航整备中心", layout.title_size, COLORS.ink, width - 286, nil, BoldFont)
    title:setAnchorPoint(cc.p(0, 0.5))
    title:setPosition(cc.p(82, 30))
    bar:addChild(title, 3)

    local statusLabel = createLabel(status.label, 10, color3(status.accent), 92, cc.TEXT_ALIGNMENT_RIGHT, BoldFont)
    statusLabel:setAnchorPoint(cc.p(1, 0.5))
    statusLabel:setPosition(cc.p(width - 130, layout.compact and 70 or 98))
    bar:addChild(statusLabel, 3)

    local backWidth = layout.compact and 82 or 96
    local backHeight = layout.compact and 40 or 46
    local normal, textColor = buttonFace(backWidth, backHeight, "selected", false, "sea")
    local pressed = buttonFace(backWidth, backHeight, "selected", true, "sea")
    local item = cc.MenuItemSprite:create(normal, pressed)
    item:setPosition(cc.p(width - 24 - backWidth * 0.5, 36))
    item:registerScriptTapHandler(function() self:returnToVoyage() end)
    local label = createLabel("返回航程", layout.compact and 10 or 11, color3(textColor), backWidth - 14, cc.TEXT_ALIGNMENT_CENTER, BoldFont)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    label:setPosition(cc.p(backWidth * 0.5, backHeight * 0.5 + 1))
    item:addChild(label, 4)
    local menu = cc.Menu:create(item)
    menu:setPosition(cc.p(0, 0))
    bar:addChild(menu, 5)
end

function V2PortLayer:addResourceDock(parent, state, layout)
    local x = 24
    local width = self.visibleSize.width - 48
    local height = layout.resource_height
    local dock = addSurface(parent, x, layout.resource_y, width, height, {
        fill = "shell_raised",
        alpha = 238,
        border = "separator",
        border_alpha = 54,
        z = 12,
    })
    local items = V2UITheme.resourceItems(state.resources)
    local itemWidth = width / #items
    for index, item in ipairs(items) do
        local itemX = itemWidth * (index - 1)
        if index > 1 then
            local separator = cc.LayerColor:create(color4("separator", 62), 1, height - 14)
            separator:setPosition(cc.p(itemX, 7))
            dock:addChild(separator, 2)
        end
        addTintedIcon(dock, item.icon, itemX + 20, height * 0.5, layout.compact and 16 or 18, item.accent, 220)
        local name = createLabel(item.name, layout.compact and 8 or 9, color3(item.accent))
        name:setAnchorPoint(cc.p(0, 0.5))
        name:setPosition(cc.p(itemX + 34, height * 0.68))
        dock:addChild(name, 4)
        local value = createLabel(tostring(item.value), layout.compact and 13 or 15, COLORS.ink, nil, nil, BoldFont)
        value:setAnchorPoint(cc.p(0, 0.5))
        value:setPosition(cc.p(itemX + 34, height * 0.31))
        dock:addChild(value, 4)
    end
end

function V2PortLayer:addStatusPanel(parent, state, status, layout)
    local width = self.visibleSize.width - 48
    local panel = addSurface(parent, 24, layout.status_y, width, layout.status_height, {
        fill = "shell",
        alpha = 214,
        accent = status.accent,
        accent_width = 5,
        z = 11,
    })
    local title = createLabel("当前整备状态", layout.compact and 9 or 10, color3(status.accent))
    title:setAnchorPoint(cc.p(0, 1))
    title:setPosition(cc.p(22, layout.status_height - 18))
    panel:addChild(title, 3)
    local headline = createLabel(status.label, layout.compact and 22 or 27, COLORS.ink, width - 230, nil, BoldFont)
    headline:setAnchorPoint(cc.p(0, 1))
    headline:setPosition(cc.p(22, layout.status_height - (layout.compact and 38 or 42)))
    panel:addChild(headline, 3)
    local detail = createLabel(status.detail, layout.compact and 12 or 14, COLORS.muted, width - 230)
    detail:setAnchorPoint(cc.p(0, 0))
    detail:setPosition(cc.p(22, layout.compact and 16 or 20))
    panel:addChild(detail, 3)

    local section = V2PortModel.section(self.activeSection)
    local sectionBlock = addSurface(panel, width - 190, 18, 168, layout.status_height - 36, {
        fill = "surface_soft",
        alpha = 126,
    })
    addTintedIcon(sectionBlock, section.icon, 28, (layout.status_height - 36) * 0.5, 28, "sea", 226)
    local sectionIndex = createLabel(section.index, 10, COLORS.muted)
    sectionIndex:setAnchorPoint(cc.p(0, 0.5))
    sectionIndex:setPosition(cc.p(54, (layout.status_height - 36) * 0.69))
    sectionBlock:addChild(sectionIndex, 3)
    local sectionName = createLabel(section.label, layout.compact and 14 or 16, COLORS.ink, 100, nil, BoldFont)
    sectionName:setAnchorPoint(cc.p(0, 0.5))
    sectionName:setPosition(cc.p(54, (layout.status_height - 36) * 0.45))
    sectionBlock:addChild(sectionName, 3)
    local sectionCaption = createLabel(section.caption, layout.compact and 9 or 10, COLORS.muted, 100)
    sectionCaption:setAnchorPoint(cc.p(0, 0.5))
    sectionCaption:setPosition(cc.p(54, (layout.status_height - 36) * 0.21))
    sectionBlock:addChild(sectionCaption, 3)
end

function V2PortLayer:addSheetHeader(sheet, titleText, captionText, layout, sheetWidth, sheetHeight)
    local index = createLabel(V2PortModel.section(self.activeSection).index, 10, color3("sea"), nil, nil, BoldFont)
    index:setAnchorPoint(cc.p(0, 1))
    index:setPosition(cc.p(24, sheetHeight - 20))
    sheet:addChild(index, 4)
    local title = createLabel(titleText, layout.compact and 20 or 23, COLORS.ink, 220, nil, BoldFont)
    title:setAnchorPoint(cc.p(0, 1))
    title:setPosition(cc.p(54, sheetHeight - 18))
    sheet:addChild(title, 4)
    local caption = createLabel(captionText, layout.compact and 10 or 11, COLORS.muted, sheetWidth - 310, cc.TEXT_ALIGNMENT_RIGHT)
    caption:setAnchorPoint(cc.p(1, 1))
    caption:setPosition(cc.p(sheetWidth - 24, sheetHeight - 24))
    sheet:addChild(caption, 4)
    local separator = cc.LayerColor:create(color4("separator", 72), sheetWidth - 48, 1)
    separator:setPosition(cc.p(24, sheetHeight - (layout.compact and 52 or 58)))
    sheet:addChild(separator, 3)
end

function V2PortLayer:addActions(parent, state, actions, y, layout, width)
    if #actions == 0 then return end
    local gap = 14
    local buttonWidth = #actions == 1 and math.min(420, width - 64)
        or math.min(270, (width - 64 - gap) * 0.5)
    local buttonHeight = layout.compact and 48 or 56
    local startX = width * 0.5 - ((#actions - 1) * (buttonWidth + gap)) * 0.5
    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    parent:addChild(menu, 8)
    for index, action in ipairs(actions) do
        local role = V2UITheme.actionRole(state.stage, action.id, index, #actions, state.selected_module)
        local face, textColor = buttonFace(buttonWidth, buttonHeight, role, false, "sea")
        local pressed = buttonFace(buttonWidth, buttonHeight, role, true, "sea")
        local item = cc.MenuItemSprite:create(face, pressed)
        item:setPosition(cc.p(startX + (index - 1) * (buttonWidth + gap), y))
        item:registerScriptTapHandler(function() self:performAction(action.id) end)
        local label = createLabel(action.label, layout.compact and 12 or 13, color3(textColor), buttonWidth - 24, cc.TEXT_ALIGNMENT_CENTER, BoldFont)
        label:setAnchorPoint(cc.p(0.5, 0.5))
        label:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
        label:setPosition(cc.p(buttonWidth * 0.5, buttonHeight * 0.5 + 1))
        item:addChild(label, 4)
        menu:addChild(item)
    end
end

function V2PortLayer:addChartSection(sheet, state, data, actions, layout, width, height)
    self:addSheetHeader(sheet, "下一次远航", "默认配置可直接行动，复杂选项按需展开", layout, width, height)
    local status = V2PortModel.status(state)
    local objective = addSurface(sheet, 24, height - 172, width - 48, 96, {
        fill = "surface_soft",
        alpha = 124,
        accent = status.accent,
        accent_width = 4,
    })
    local objectiveLabel = createLabel("当前航令", 9, color3(status.accent))
    objectiveLabel:setAnchorPoint(cc.p(0, 1))
    objectiveLabel:setPosition(cc.p(18, 78))
    objective:addChild(objectiveLabel, 3)
    local objectiveText = createLabel(state.objective, layout.compact and 14 or 16, COLORS.ink, width - 86, nil, BoldFont)
    objectiveText:setAnchorPoint(cc.p(0, 1))
    objectiveText:setPosition(cc.p(18, 55))
    objective:addChild(objectiveText, 3)

    local readiness = V2PortModel.readiness(state, data)
    local gap = 10
    local cardWidth = (width - 48 - gap * 2) / 3
    local readinessY = height - 292
    for index, item in ipairs(readiness) do
        local x = 24 + (index - 1) * (cardWidth + gap)
        local card = addSurface(sheet, x, readinessY, cardWidth, 96, {
            fill = "surface_soft",
            alpha = 98,
        })
        local marker = cc.LayerColor:create(color4(item.ready and "success" or "danger", 238), 7, 7)
        marker:setPosition(cc.p(14, 70))
        marker:setRotation(45)
        card:addChild(marker, 3)
        local label = createLabel(item.label, 9, COLORS.muted)
        label:setAnchorPoint(cc.p(0, 0.5))
        label:setPosition(cc.p(30, 74))
        card:addChild(label, 3)
        local value = createLabel(item.value, layout.compact and 12 or 14, COLORS.ink, cardWidth - 28, nil, BoldFont)
        value:setAnchorPoint(cc.p(0, 1))
        value:setPosition(cc.p(14, 52))
        card:addChild(value, 3)
        local ready = createLabel(item.ready and "已就绪" or "待处理", 9, color3(item.ready and "success" or "danger"))
        ready:setAnchorPoint(cc.p(0, 0.5))
        ready:setPosition(cc.p(14, 16))
        card:addChild(ready, 3)
    end

    local ship = V2PortModel.ship(state, data)
    local lowerHeight = layout.compact and 180 or 240
    local lowerY = layout.compact and 142 or 178
    local summaryWidth = (width - 58) * 0.5
    local shipCard = addSurface(sheet, 24, lowerY, summaryWidth, lowerHeight, {
        fill = "surface_soft", alpha = 88,
    })
    local shipTitle = createLabel("船只 · " .. ship.name, 10, color3("sea"))
    shipTitle:setAnchorPoint(cc.p(0, 1))
    shipTitle:setPosition(cc.p(16, lowerHeight - 18))
    shipCard:addChild(shipTitle, 3)
    local shipModule = createLabel(ship.selected_module, 17, COLORS.ink, summaryWidth - 32, nil, BoldFont)
    shipModule:setAnchorPoint(cc.p(0, 1))
    shipModule:setPosition(cc.p(16, lowerHeight - 42))
    shipCard:addChild(shipModule, 3)
    local shipDetail = createLabel(string.format("耐久 %d  ·  船体等级 %d  ·  火炮等级 %d", ship.hull_max, ship.hull_level, ship.gun_level), 11, COLORS.muted, summaryWidth - 32)
    shipDetail:setAnchorPoint(cc.p(0, 1))
    shipDetail:setPosition(cc.p(16, lowerHeight - 70))
    shipCard:addChild(shipDetail, 3)
    local voyage = createLabel(string.format("已完成远航 %d 次", ship.voyages), 10, color3("gold"))
    voyage:setAnchorPoint(cc.p(0, 0.5))
    voyage:setPosition(cc.p(16, 14))
    shipCard:addChild(voyage, 3)

    local goalCard = addSurface(sheet, 34 + summaryWidth, lowerY, summaryWidth, lowerHeight, {
        fill = "surface_soft", alpha = 88,
    })
    local goalTitle = createLabel("已知下一目标", 10, color3("purple"))
    goalTitle:setAnchorPoint(cc.p(0, 1))
    goalTitle:setPosition(cc.p(16, lowerHeight - 18))
    goalCard:addChild(goalTitle, 3)
    local goal = state.next_voyage_objective or "取得第一枚符文线索"
    local goalLabel = createLabel(goal, 16, COLORS.ink, summaryWidth - 32, nil, BoldFont)
    goalLabel:setAnchorPoint(cc.p(0, 1))
    goalLabel:setPosition(cc.p(16, lowerHeight - 46))
    goalCard:addChild(goalLabel, 3)
    local clue = createLabel(string.format("符文尘 %d  ·  首章线索 %s", (state.resources or {}).rune_dust or 0, state.chapter_complete and "已确认" or "未确认"), 10, COLORS.muted, summaryWidth - 32)
    clue:setAnchorPoint(cc.p(0, 0.5))
    clue:setPosition(cc.p(16, 16))
    goalCard:addChild(clue, 3)

    self:addActions(sheet, state, actions, layout.compact and 48 or 96, layout, width)
end

function V2PortLayer:addShipSection(sheet, state, data, actions, layout, width, height)
    self:addSheetHeader(sheet, "旗舰与模块", "模块定义远航风格，强化只在真实可用阶段开放", layout, width, height)
    local ship = V2PortModel.ship(state, data)
    local summary = addSurface(sheet, 24, height - 174, width - 48, 98, {
        fill = "surface_soft", alpha = 116, accent = "sea", accent_width = 4,
    })
    local name = createLabel(ship.name, 20, COLORS.ink, 180, nil, BoldFont)
    name:setAnchorPoint(cc.p(0, 0.5))
    name:setPosition(cc.p(18, 61))
    summary:addChild(name, 3)
    local module = createLabel("当前装配  ·  " .. ship.selected_module, 11, color3("sea"))
    module:setAnchorPoint(cc.p(0, 0.5))
    module:setPosition(cc.p(18, 27))
    summary:addChild(module, 3)
    local metrics = {
        { label = "最大耐久", value = ship.hull_max },
        { label = "船体等级", value = ship.hull_level },
        { label = "火炮等级", value = ship.gun_level },
        { label = "航行损伤", value = ship.voyage_damage },
    }
    local metricWidth = 82
    for index, metric in ipairs(metrics) do
        local x = width - 48 - metricWidth * (5 - index)
        local label = createLabel(metric.label, 8, COLORS.muted, metricWidth, cc.TEXT_ALIGNMENT_CENTER)
        label:setAnchorPoint(cc.p(0.5, 0.5))
        label:setPosition(cc.p(x, 65))
        summary:addChild(label, 3)
        local value = createLabel(tostring(metric.value), 17, COLORS.ink, nil, nil, BoldFont)
        value:setAnchorPoint(cc.p(0.5, 0.5))
        value:setPosition(cc.p(x, 34))
        summary:addChild(value, 3)
    end

    local gap = 12
    local moduleWidth = (width - 48 - gap) * 0.5
    local moduleHeight = layout.compact and 190 or 238
    local moduleY = layout.compact and (height - 402) or (height - 436)
    for index, item in ipairs(ship.modules) do
        local x = 24 + (index - 1) * (moduleWidth + gap)
        local card = addSurface(sheet, x, moduleY, moduleWidth, moduleHeight, {
            fill = item.selected and "shell_raised" or "surface_soft",
            alpha = item.selected and 224 or 102,
            accent = item.selected and item.accent or nil,
            accent_width = 4,
            border = item.selected and item.accent or nil,
            border_alpha = 88,
        })
        local stateLabel = createLabel(item.selected and "当前装配" or "可选模块", 9, color3(item.accent))
        stateLabel:setAnchorPoint(cc.p(0, 1))
        stateLabel:setPosition(cc.p(16, moduleHeight - 19))
        card:addChild(stateLabel, 3)
        local title = createLabel(item.name, 18, COLORS.ink, moduleWidth - 32, nil, BoldFont)
        title:setAnchorPoint(cc.p(0, 1))
        title:setPosition(cc.p(16, moduleHeight - 43))
        card:addChild(title, 3)
        local effect = createLabel(item.effect, 11, COLORS.ink, moduleWidth - 32)
        effect:setAnchorPoint(cc.p(0, 1))
        effect:setPosition(cc.p(16, moduleHeight - 80))
        card:addChild(effect, 3)
        local bonus = item.hull_bonus > 0 and string.format("耐久 +%d", item.hull_bonus)
            or string.format("齐射 +%d", item.cannon_bonus)
        if item.supply_modifier ~= 0 then bonus = bonus .. string.format("  ·  补给上限 %d", item.supply_modifier) end
        local bonusLabel = createLabel(bonus, 11, color3(item.accent), moduleWidth - 32, nil, BoldFont)
        bonusLabel:setAnchorPoint(cc.p(0, 0.5))
        bonusLabel:setPosition(cc.p(16, layout.compact and 38 or 54))
        card:addChild(bonusLabel, 3)
        local tradeoff = createLabel(item.tradeoff, 9, COLORS.muted, moduleWidth - 32)
        tradeoff:setAnchorPoint(cc.p(0, 0.5))
        tradeoff:setPosition(cc.p(16, layout.compact and 15 or 22))
        card:addChild(tradeoff, 3)
    end

    local upgradeY = layout.compact and 112 or 184
    local upgradeHeight = layout.compact and 72 or 92
    local upgrade = addSurface(sheet, 24, upgradeY, width - 48, upgradeHeight, {
        fill = "surface_soft", alpha = 88,
    })
    local upgradeTitle = createLabel("首次强化预览", 9, color3("gold"))
    upgradeTitle:setAnchorPoint(cc.p(0, 0.5))
    upgradeTitle:setPosition(cc.p(16, upgradeHeight - 21))
    upgrade:addChild(upgradeTitle, 3)
    local hull = createLabel(string.format("船体：木材 -%d  →  最大耐久 +%d", ship.hull_upgrade.cost, ship.hull_upgrade.gain), 11, COLORS.ink)
    hull:setAnchorPoint(cc.p(0, 0.5))
    hull:setPosition(cc.p(16, 19))
    upgrade:addChild(hull, 3)
    local guns = createLabel(string.format("火炮：铁料 -%d  →  单次齐射 +%d", ship.gun_upgrade.cost, ship.gun_upgrade.gain), 11, COLORS.ink)
    guns:setAnchorPoint(cc.p(0, 0.5))
    guns:setPosition(cc.p(width * 0.52, 19))
    upgrade:addChild(guns, 3)

    self:addActions(sheet, state, actions, layout.compact and 44 or 66, layout, width)
end

function V2PortLayer:addCrewSection(sheet, state, data, layout, width, height)
    self:addSheetHeader(sheet, "核心船员", "身份、主动技能和远航特性保持一眼可读", layout, width, height)
    local crew = V2PortModel.crew(state, data)
    local gap = 12
    local cardWidth = (width - 48 - gap) * 0.5
    local cardHeight = (height - 100 - gap) * 0.5
    for index, item in ipairs(crew) do
        local column = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        local x = 24 + column * (cardWidth + gap)
        local y = height - 78 - cardHeight - row * (cardHeight + gap)
        local card = addSurface(sheet, x, y, cardWidth, cardHeight, {
            fill = "surface_soft", alpha = 108, accent = item.accent, accent_width = 4,
        })
        local badge = addSurface(card, 16, cardHeight - 58, 42, 42, {
            fill = item.accent, alpha = 220,
        })
        local initial = createLabel(string.sub(item.name, 1, 3), 15, color3("shell"), nil, nil, BoldFont)
        initial:setAnchorPoint(cc.p(0.5, 0.5))
        initial:setPosition(cc.p(21, 21))
        badge:addChild(initial, 3)
        local indexLabel = createLabel(item.index .. "  ·  " .. item.role, 9, color3(item.accent))
        indexLabel:setAnchorPoint(cc.p(0, 0.5))
        indexLabel:setPosition(cc.p(70, cardHeight - 27))
        card:addChild(indexLabel, 3)
        local name = createLabel(item.name, 18, COLORS.ink, cardWidth - 88, nil, BoldFont)
        name:setAnchorPoint(cc.p(0, 0.5))
        name:setPosition(cc.p(70, cardHeight - 49))
        card:addChild(name, 3)
        local separator = cc.LayerColor:create(color4("separator", 66), cardWidth - 32, 1)
        separator:setPosition(cc.p(16, cardHeight - 76))
        card:addChild(separator, 3)
        local skillCaption = createLabel("主动技能", 8, COLORS.muted)
        skillCaption:setAnchorPoint(cc.p(0, 1))
        skillCaption:setPosition(cc.p(16, cardHeight - 94))
        card:addChild(skillCaption, 3)
        local skill = createLabel(item.active_skill, 14, color3(item.accent), cardWidth - 32, nil, BoldFont)
        skill:setAnchorPoint(cc.p(0, 1))
        skill:setPosition(cc.p(16, cardHeight - 114))
        card:addChild(skill, 3)

        local actionCaption = createLabel("战斗效果", 8, COLORS.muted)
        actionCaption:setAnchorPoint(cc.p(0, 1))
        actionCaption:setPosition(cc.p(16, cardHeight - 151))
        card:addChild(actionCaption, 3)
        local action = createLabel(item.active_detail, layout.compact and 9 or 10, COLORS.ink, cardWidth - 32)
        action:setAnchorPoint(cc.p(0, 1))
        action:setPosition(cc.p(16, cardHeight - 171))
        card:addChild(action, 3)

        local passiveCaption = createLabel("远航特性", 8, COLORS.muted)
        passiveCaption:setAnchorPoint(cc.p(0, 1))
        passiveCaption:setPosition(cc.p(16, cardHeight - 210))
        card:addChild(passiveCaption, 3)
        local passive = createLabel(item.passive_trait, layout.compact and 9 or 10, COLORS.ink, cardWidth - 32)
        passive:setAnchorPoint(cc.p(0, 1))
        passive:setPosition(cc.p(16, cardHeight - 230))
        card:addChild(passive, 3)
    end
end

function V2PortLayer:addCargoSection(sheet, state, data, actions, layout, width, height)
    self:addSheetHeader(sheet, "货舱与用途", "五种资源只服务远航、恢复和关键成长", layout, width, height)
    local cargo = V2PortModel.cargo(state, data)
    local themed = {}
    for _, item in ipairs(V2UITheme.resourceItems(state.resources)) do themed[item.id] = item end
    local bottomReserve = #actions > 0 and (layout.compact and 78 or 94) or 18
    local rowHeight = (height - 80 - bottomReserve) / #cargo
    for index, item in ipairs(cargo) do
        local theme = themed[item.id]
        local y = height - 72 - index * rowHeight
        local row = addSurface(sheet, 24, y, width - 48, rowHeight - 7, {
            fill = "surface_soft", alpha = index % 2 == 0 and 82 or 106,
        })
        addTintedIcon(row, theme.icon, 26, (rowHeight - 7) * 0.5, layout.compact and 20 or 22, theme.accent, 228)
        local name = createLabel(item.name, 14, COLORS.ink, 72, nil, BoldFont)
        name:setAnchorPoint(cc.p(0, 0.5))
        name:setPosition(cc.p(48, (rowHeight - 7) * 0.62))
        row:addChild(name, 3)
        local value = createLabel(tostring(item.value), 18, color3(theme.accent), nil, nil, BoldFont)
        value:setAnchorPoint(cc.p(0, 0.5))
        value:setPosition(cc.p(48, (rowHeight - 7) * 0.27))
        row:addChild(value, 3)
        local primaryCaption = createLabel("主要用途", 8, COLORS.muted)
        primaryCaption:setAnchorPoint(cc.p(0, 0.5))
        primaryCaption:setPosition(cc.p(150, (rowHeight - 7) * 0.68))
        row:addChild(primaryCaption, 3)
        local primary = createLabel(item.primary_use, 11, COLORS.ink, 170, nil, BoldFont)
        primary:setAnchorPoint(cc.p(0, 0.5))
        primary:setPosition(cc.p(150, (rowHeight - 7) * 0.31))
        row:addChild(primary, 3)
        local secondaryCaption = createLabel("次要用途", 8, COLORS.muted)
        secondaryCaption:setAnchorPoint(cc.p(0, 0.5))
        secondaryCaption:setPosition(cc.p(370, (rowHeight - 7) * 0.68))
        row:addChild(secondaryCaption, 3)
        local secondary = createLabel(item.secondary_use, 11, COLORS.ink, width - 426)
        secondary:setAnchorPoint(cc.p(0, 0.5))
        secondary:setPosition(cc.p(370, (rowHeight - 7) * 0.31))
        row:addChild(secondary, 3)
    end
    self:addActions(sheet, state, actions, 38, layout, width)
end

function V2PortLayer:addSectionNavigation(parent, layout)
    local x = 24
    local width = self.visibleSize.width - 48
    local nav = addSurface(parent, x, layout.nav_y, width, layout.nav_height, {
        fill = "shell_raised", alpha = 246, border = "separator", border_alpha = 52, z = 14,
    })
    local itemWidth = width / #V2PortModel.sections
    local menu = cc.Menu:create()
    menu:setPosition(cc.p(0, 0))
    nav:addChild(menu, 5)
    for index, section in ipairs(V2PortModel.sections) do
        local selected = section.id == self.activeSection
        local function createNavigationFace(pressed)
            local face = cc.Node:create()
            face:setContentSize(cc.size(itemWidth, layout.nav_height))
            local fill = cc.LayerColor:create(
                color4(selected and "surface_soft" or "shell_raised", pressed and 238 or (selected and 214 or 124)),
                itemWidth,
                layout.nav_height
            )
            face:addChild(fill)
            if selected then
                local marker = cc.LayerColor:create(color4("sea", 255), itemWidth, 3)
                marker:setPosition(cc.p(0, layout.nav_height - 3))
                fill:addChild(marker, 3)
            end
            if index > 1 then
                local separator = cc.LayerColor:create(color4("separator", 54), 1, layout.nav_height - 22)
                separator:setPosition(cc.p(0, 11))
                fill:addChild(separator, 2)
            end
            addTintedIcon(fill, section.icon, 24, layout.nav_height * 0.52, layout.compact and 18 or 20, selected and "sea" or "muted", selected and 245 or 180)
            local indexLabel = createLabel(section.index, 8, selected and color3("sea") or COLORS.muted)
            indexLabel:setAnchorPoint(cc.p(0, 0.5))
            indexLabel:setPosition(cc.p(44, layout.nav_height * 0.68))
            fill:addChild(indexLabel, 3)
            local label = createLabel(section.label, layout.compact and 11 or 12, selected and COLORS.ink or COLORS.muted, itemWidth - 52, nil, BoldFont)
            label:setAnchorPoint(cc.p(0, 0.5))
            label:setPosition(cc.p(44, layout.nav_height * 0.40))
            fill:addChild(label, 3)
            return face
        end
        local item = cc.MenuItemSprite:create(createNavigationFace(false), createNavigationFace(true))
        item:setPosition(cc.p(itemWidth * (index - 0.5), layout.nav_height * 0.5))
        item:registerScriptTapHandler(function()
            self.activeSection = section.id
            self:refresh()
        end)
        menu:addChild(item)
    end
end

function V2PortLayer:refresh()
    self.dynamicNode:removeAllChildren()
    local root = self.dynamicNode
    local state = self.controller:load()
    local data = self.controller:getChapterData()
    local layout = portLayout(self.visibleSize.width, self.visibleSize.height)
    local status = V2PortModel.status(state)

    local background = cc.Sprite:create("Images/V2/ui2_harbor.png")
    background:setPosition(cc.p(self.visibleSize.width * 0.5, self.visibleSize.height * 0.5))
    fitSprite(background, self.visibleSize.width, self.visibleSize.height)
    root:addChild(background, 0)
    local wash = cc.LayerColor:create(color4("shell", 142), self.visibleSize.width, self.visibleSize.height)
    root:addChild(wash, 1)

    self:addTopBar(root, state, status, layout)
    self:addResourceDock(root, state, layout)
    self:addStatusPanel(root, state, status, layout)

    local sheetWidth = self.visibleSize.width - 48
    local sheet = addSurface(root, 24, layout.sheet_y, sheetWidth, layout.sheet_height, {
        fill = "surface", alpha = 248, accent = "sea", accent_width = 4, z = 10,
    })
    local actions = V2PortModel.actions(self.activeSection, self.controller:getActions())
    if self.activeSection == "ship" then
        self:addShipSection(sheet, state, data, actions, layout, sheetWidth, layout.sheet_height)
    elseif self.activeSection == "crew" then
        self:addCrewSection(sheet, state, data, layout, sheetWidth, layout.sheet_height)
    elseif self.activeSection == "cargo" then
        self:addCargoSection(sheet, state, data, actions, layout, sheetWidth, layout.sheet_height)
    else
        self:addChartSection(sheet, state, data, actions, layout, sheetWidth, layout.sheet_height)
    end
    self:addSectionNavigation(root, layout)

    if V2Config:isQAProfile(state.profile) then
        local footer = createLabel("QA  ·  port/" .. self.activeSection, 10, COLORS.muted, self.visibleSize.width - 40, cc.TEXT_ALIGNMENT_CENTER)
        footer:setAnchorPoint(cc.p(0, 0))
        footer:setPosition(cc.p(20, layout.footer_y))
        root:addChild(footer, 4)
    end
end

return V2PortLayer
