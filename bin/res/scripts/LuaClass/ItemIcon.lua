-- Presentation-only resource/crew icons. CSV names and IDs remain authoritative.
-- Missing artwork gets a neutral, bounded paper slot; callers keep the real name
-- and description beside it. Never substitute a different item's illustration.
require "LuaClass/MasterTheme"
ItemIcon = {}
local I = ItemIcon

function I.path(iconName)
    if type(iconName) ~= "string" or iconName == "" then return nil end
    local path = "Images/Icon/" .. iconName
    if cc.FileUtils:getInstance():isFileExist(path) then return path end
    return nil
end

function I.placeholder(size)
    size = size or cc.size(64, 64)
    local face = cc.Node:create()
    face:setContentSize(size)
    face:setAnchorPoint(cc.p(0.5, 0.5))
    face:addChild(MasterTheme.material("crew-paper.png", size.width, size.height))
    -- Unlettered ledger strokes are deliberately neutral. The adjacent native
    -- label remains the item's actual name, including when no icon is supplied.
    for line = 1, 3 do
        HomeTheme.rule(face, size.width * 0.25, size.height * (0.25 + line * 0.125),
            size.width * (line == 3 and 0.32 or 0.5), MasterTheme.colors.muted)
    end
    return face
end

function I.sprite(iconName)
    local path = I.path(iconName)
    local sprite = path and cc.Sprite:create(path) or nil
    return sprite or I.placeholder()
end

function I.menuItem(iconName)
    return cc.MenuItemSprite:create(I.sprite(iconName), I.sprite(iconName))
end

function I.sdButton(iconName, callback)
    local path = I.path(iconName) or ""
    local button = SDButton:create(path, path, callback)
    for _, state in ipairs({{"normalSpr", "_normalImageMissing"}, {"selectSpr", "_selectedImageMissing"}}) do
        if button[state[2]] then
            local sprite = button[state[1]]
            local face = I.placeholder(sprite:getContentSize())
            face:setAnchorPoint(cc.p(0, 0))
            sprite:addChild(face)
        end
    end
    return button
end
return I
