-- One display-only, first-chapter coast. The TMX remains the source of land,
-- movement, events and fog; this module never materializes or changes its tiles.
SeaChartSlice = {}
local S = SeaChartSlice
S.path = "Images/UI/Adventure/SeaChart/Slice/"

local width, height = 320, 384
local originX, originY = 192, 832
local expected = {
    [3] = {[4]=70, [5]=71, [6]=72},
    [4] = {[4]=100, [5]=94, [6]=78},
    [5] = {[4]=95, [5]=76, [6]=78},
    [6] = {[5]=100, [6]=99}
}

-- Validate the empty margin as well as the eleven land cells. A changed map,
-- another chapter, or a different tile scale retains its accepted rendering.
local function inspect(map, mapIndex)
    if mapIndex ~= 1 or not map then return nil, "chapter" end
    local mapSize, tileSize = map:getMapSize(), map:getTileSize()
    if mapSize.width ~= 21 or mapSize.height ~= 21
        or tileSize.width ~= 64 or tileSize.height ~= 64 then
        return nil, "map-size"
    end
    local land = map:getLayer("Blocks_1")
    if not land then return nil, "land-layer" end
    for y=2,7 do
        for x=3,7 do
            local gid = expected[y] and expected[y][x] or 0
            if land:getTileGIDAt(cc.p(x, y)) ~= gid then return nil, "land-cells" end
        end
    end
    local origin = land:getPositionAt(cc.p(3, 7))
    if origin.x + land:getPositionX() ~= originX
        or origin.y + land:getPositionY() ~= originY then
        return nil, "land-position"
    end
    local z = land:getLocalZOrder()
    -- Equal-z children render in insertion order: preserve the original coast
    -- underneath, with all gameplay markers, grid and fog above the new art.
    for _, name in ipairs({"Meta", "GridLayer", "Fogs"}) do
        local layer = map:getLayer(name)
        if not layer or layer:getLocalZOrder() <= z then return nil, "overlay-order" end
    end
    return {z=z}
end

-- This intentionally relies on the existing per-pixel Fogs layer. Requiring
-- every land cell to be clear would remove the entire coast when only one end
-- remains unexplored. A coordinated raster also must not be clipped to a flat
-- shoreline mask, which would cut away the rocks' raised silhouettes.
function S.refresh(map, group)
    if not map or not group or map._seaChartSliceGroup ~= group
        or group:getParent() ~= map then return false end
    local layout = inspect(map, 1)
    group:setVisible(layout ~= nil)
    return layout ~= nil
end

function S.cleanup(map, group)
    if not map or not group or map._seaChartSliceGroup ~= group then return false end
    map._seaChartSliceGroup = nil
    if group:getParent() == map then group:removeFromParent(true) end
    return true
end

-- Returns the owned display group, or nil plus a short fallback reason. All
-- validation completes before adding a node to the live map. Artwork is one
-- transparent 5:6 canvas, scaled uniformly to its audited 320x384 world bounds.
function S.build(map, mapIndex)
    local layout, reason = inspect(map, mapIndex)
    if not layout then return nil, reason end
    local existing = map._seaChartSliceGroup
    if existing and S.refresh(map, existing) then return existing end
    if existing then S.cleanup(map, existing) end

    local path = S.path .. "coast-piece.png"
    if not cc.FileUtils:getInstance():isFileExist(path) then return nil, "missing-art" end
    local sprite = cc.Sprite:create(path)
    if not sprite then return nil, "unreadable-art" end
    local texture = sprite:getTexture()
    -- This independent NPOT image never shares a TMX atlas. Keep its import
    -- contract explicit without touching global texture defaults.
    texture:setTexParameters(9729, 9729, 33071, 33071) -- LINEAR, LINEAR, CLAMP, CLAMP
    local size = sprite:getContentSize()
    if size.width <= 0 or size.height <= 0
        or size.width * height ~= size.height * width then return nil, "art-aspect" end

    local group = cc.Node:create()
    group:setContentSize(cc.size(width, height))
    group:setAnchorPoint(cc.p(0, 0))
    group:setPosition(cc.p(originX, originY))
    sprite:setAnchorPoint(cc.p(0, 0))
    sprite:setPosition(cc.p(0, 0))
    sprite:setScale(width / size.width)
    group:addChild(sprite)
    map:addChild(group, layout.z)
    map._seaChartSliceGroup = group
    S.refresh(map, group)
    return group
end

return S
