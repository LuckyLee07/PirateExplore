-- Opening-story presentation only. PlotMode still owns every action/callback.
-- Original artwork remains the explicit Warm opt-out and missing-file fallback.
local Warm = require 'LuaClass/WarmTheme'
local Art = {}
local prefix = 'Images/Plot/CleanOpening/'
local parts = {
    -- Source rectangles trim transparent generator padding at runtime; the
    -- logical sizes preserve the existing bottle/ship/water anchors and motion.
    juqing_7 = {48, 74, 1903, 642, 539, 216},
    juqing_8 = {41, 319, 2092, 228, 316, 45},
    juqing_9 = {48, 32, 1534, 898, 243, 143},
}

function Art.path(iconId)
    local original = 'Images/Plot/' .. iconId .. '.png'
    if not Warm.enabled() or not iconId:match('^juqing_[1-9]$') then
        return original
    end
    local clean = prefix .. iconId .. '.png'
    return cc.FileUtils:getInstance():isFileExist(clean) and clean or original
end

function Art.sprite(iconId)
    local path = Art.path(iconId)
    local part = parts[iconId]
    if not part or path:sub(1, #prefix) ~= prefix then
        return cc.Sprite:create(path)
    end
    local sprite = cc.Sprite:create(path, cc.rect(part[1], part[2], part[3], part[4]))
    local node = cc.Node:create()
    node:setContentSize(cc.size(part[5], part[6]))
    node:setAnchorPoint(cc.p(.5, .5))
    node:setCascadeOpacityEnabled(true)
    sprite:setScaleX(part[5] / part[3])
    sprite:setScaleY(part[6] / part[4])
    sprite:setPosition(cc.p(part[5] / 2, part[6] / 2))
    node:addChild(sprite)
    return node
end

return Art
