-- Authored chapter-one layout, opted into only by the new-role transaction.
-- A missing/unknown marker always selects the original TMX. In particular,
-- AdventureProgress v1, empty map data and incomplete guides are not opt-ins.
local M = { KEY = 'cleanFirstMapVersion', VERSION = 1 }

function M.isEnabled(dm, mapIndex)
    if tonumber(mapIndex) ~= 1 or not dm or type(dm.getRoleData) ~= 'function' then return false end
    return dm:getRoleData(M.KEY) == M.VERSION
end

function M.mapPath(dm, mapIndex)
    if M.isEnabled(dm, mapIndex) then return 'Images/Map/map_1_clean_v1.tmx' end
    return string.format('Images/Map/map_%d.tmx', tonumber(mapIndex) or 1)
end

-- TMX tile coordinates, not world/screen positions. Copies prevent a renderer
-- from changing the authored contract. The live TMX remains gameplay truth.
function M.port()
    return {x=7, y=11}
end

function M.harborLandTiles()
    -- Mainland follows the approved harbor's waterline (not roofs/palms),
    -- joins the lower map edge and leaves the pier endpoint (7,11) navigable.
    -- Row spans are the conservative center-grid coast/walkway mask union
    -- with the original 15-cell harbor. TMX and accessor are tested together.
    local rows = {
        {12,5,7}, {13,4,7}, {14,4,7}, {15,4,7}, {16,5,7},
        {17,4,8}, {18,3,9}, {19,2,10}, {20,1,11}
    }
    local tiles = {}
    for _, row in ipairs(rows) do
        for x=row[2],row[3] do
            tiles[#tiles+1] = {x=x, y=row[1]}
        end
    end
    return tiles
end

return M
