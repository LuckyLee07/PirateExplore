-- Presentation-only names. The packaged CSV remains authoritative for every
-- resource value, transaction and semantic identity. Missing art uses its name.
ResourceTheme = {}
local R = ResourceTheme
R.icons = {
    ['1001']='r_9.png', -- coins
    ['1004']='r_1.png', -- wheat
    ['1005']='r_2.png', -- food
    ['1006']='r_3.png', -- stone
    ['1007']='r_4.png', -- wood
    ['1008']='r_5.png', -- iron
    ['1009']='r_6.png', -- gold ore, not currency
    ['1011']='r_8.png', -- steel
    ['1017']='r_19.png', -- leather
    ['1018']='r_20.png', -- cloth
    ['1019']='r_21.png', -- silk
    ['1037']='r_16.png', -- simple key
    ['1120']='r_16.png' -- library key shares the original key artwork
}
R.crewIcons = {
    ['100']={'j_1.png', 'crew-100.png'}, -- low-rank crew, original tricorn silhouette
    ['101']={'j_2.png', 'crew-101.png'}, -- sailor, original bare-shouldered silhouette
    ['102']={'j_3.png', 'crew-102.png'}, -- exact already-approved assault sailor
    ['107']={'j_4.png', 'crew-107.png'}, -- exact already-approved wood-shield helmsman
    ['124']={'j_7.png', 'crew-124.png'} -- exact already-approved ship doctor
}

function R.applyIcons(records)
    if type(records) ~= 'table' or not cc or not cc.FileUtils then return 0 end
    local files = cc.FileUtils:getInstance()
    if not files or not files.isFileExist then return 0 end
    local count = 0
    for id, original in pairs(R.icons) do
        local row = records[id]
        local replacement = 'B/' .. original
        if type(row) == 'table' and tostring(row.ID) == id and row.iconName == original
            and files:isFileExist('Images/Icon/' .. replacement) then
            row.iconName = replacement
            count = count + 1
        end
    end
    return count
end

function R.applyCrewIcons(records)
    if type(records) ~= 'table' or not cc or not cc.FileUtils then return 0 end
    local files = cc.FileUtils:getInstance()
    if not files or not files.isFileExist then return 0 end
    local count = 0
    for id, names in pairs(R.crewIcons) do
        local row = records[id]
        local replacement = 'B/' .. names[2]
        if type(row) == 'table' and tostring(row.ID) == id and row.icon == names[1]
            and files:isFileExist('Images/Icon/' .. replacement) then
            row.icon = replacement
            count = count + 1
        end
    end
    return count
end
return R
