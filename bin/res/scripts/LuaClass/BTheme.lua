-- B: light illustrated adventure. Presentation helpers only; no game state writes.
require "LuaClass/Header"

BTheme = BTheme or {}
BTheme.colors = {
    ink = cc.c3b(22, 53, 62), sea = cc.c3b(36, 130, 149),
    sand = cc.c3b(244, 234, 211), coral = cc.c3b(226, 112, 77),
    white = cc.c3b(255, 250, 237), muted = cc.c3b(111, 127, 124),
    line = cc.c3b(217, 204, 179), pale = cc.c3b(225, 235, 227),
    gold = cc.c3b(231, 187, 95)
}

-- Position is the left edge / vertical center unless anchors are provided.
function BTheme.label(text, size, color, x, y, anchorX, anchorY)
    local label = cc.LabelTTF:create(tostring(text or ""), BoldFont, size or 24)
    label:setColor(color or BTheme.colors.ink)
    label:setAnchorPoint(cc.p(anchorX or 0, anchorY or 0.5))
    label:setPosition(cc.p(x or 0, y or 0))
    return label
end

-- Panels are native solid-color nodes, positioned by their lower-left corner.
function BTheme.panel(width, height, color, x, y)
    color = color or BTheme.colors.sand
    local panel = cc.LayerColor:create(cc.c4b(color.r, color.g, color.b, color.a or 255), width, height)
    panel:setAnchorPoint(cc.p(0, 0))
    panel:ignoreAnchorPointForPosition(false)
    panel:setPosition(cc.p(x or 0, y or 0))
    panel:setCascadeOpacityEnabled(true)
    return panel
end

-- A real MenuItemSprite with a real LabelTTF, for existing cc.Menu containers.
function BTheme.menuItem(text, width, height, callback, opts)
    opts = opts or {}
    local normalColor = opts.color or BTheme.colors.ink
    local selectedColor = opts.selectedColor or BTheme.colors.sea
    local normal = BTheme.panel(width, height, normalColor)
    local selected = BTheme.panel(width, height, selectedColor)
    local item = cc.MenuItemSprite:create(normal, selected)
    item:setCascadeOpacityEnabled(true)
    item.bNormal = normal
    item.bNormalColor = normalColor
    item.bSelectedColor = selectedColor
    item.bLabel = BTheme.label(text, opts.fontSize or 26, opts.textColor or BTheme.colors.white,
        width * 0.5, height * 0.5, 0.5, 0.5)
    item:addChild(item.bLabel, 2)
    if callback then item:registerScriptTapHandler(callback) end
    return item
end

-- Standalone button; add to any node and setPosition at its center.
-- Exposes .item, .label and .menu for existing game callbacks and state updates.
function BTheme.button(text, width, height, callback, opts)
    local node = cc.Node:create()
    node:setContentSize(cc.size(width, height))
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node:setCascadeOpacityEnabled(true)
    node.item = BTheme.menuItem(text, width, height, callback, opts)
    node.label = node.item.bLabel
    node.item:setPosition(cc.p(width * 0.5, height * 0.5))
    node.menu = cc.Menu:create(node.item)
    node.menu:setPosition(cc.p(0, 0))
    node:addChild(node.menu)
    return node
end

function BTheme.setActive(item, active)
    if item and item.bNormal then
        item.bNormal:setColor(active and item.bSelectedColor or item.bNormalColor)
    end
end

function BTheme.fitLabel(label, width)
    local actual = label:getContentSize().width
    label:setScale(actual > width and width / actual or 1)
    return label
end

return BTheme
