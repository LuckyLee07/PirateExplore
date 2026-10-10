-- Read-only recovery advice. Original construction/recruitment owns all spending.
CrewRecovery = {}
local R=CrewRecovery
local function goldCost(value,production)
    local rows=value
    if type(rows)~='table' then
        rows={}
        for part in tostring(value or ''):gmatch('[^;]+') do
            local row={};for field in part:gmatch('[^_]+') do row[#row+1]=field end
            rows[#rows+1]=row
        end
    end
    if #rows~=1 then return nil end
    local row=rows[1];local index=production and 2 or 1
    if production and tostring(row[1])~='2' then return nil end
    if tostring(row[index])~='1001' then return nil end
    local cost=tonumber(row[index+1]);if cost and cost>0 then return cost end
end
function R.next(dm,guide)
    if not guide:getIsHaveStep(8) or not guide:getIsHaveStep(30,true) then return nil end
    for id,num in pairs(dm:getRoleData(roleSelectUnit) or {}) do
        if (tonumber(id) or 0)>=10000 and (tonumber(num) or 0)>0 then return nil end
    end
    for _,unit in pairs(dm:getRoleData(roleSoildierQueue) or {}) do
        if type(unit)=='table' and (tonumber(unit[dataKeyNum]) or 0)>0 then return nil end
    end
    local camp
    for _,row in ipairs(dm:getRoleData(roleBuilding) or {}) do
        if tostring(row[dataKeyID])=='58' then camp=tonumber(row[dataKeyNum]) end
    end
    local build=(dm:getCSVByID(csvOfBuild) or {})['58']
    local crew=(dm:getCSVByID(csvOfSoilderAttribute) or {})['100']
    local buildCost=goldCost(build and build.resume)
    local recruitCost=goldCost(crew and crew.produceResume,true)
    local result={action='暂不可用',detail='训练营或招募尚未开放，请查看港务建设。'}
    if not buildCost or not recruitCost then return result end
    local gate=guide:getIsHaveStep(103,true)
    local cost
    if camp==0 and not gate and guide:getIsHaveStep(1) then
        cost=buildCost;result.route='build';result.action='查看训练营'
        result.detail='先建训练营：'..buildCost..'金币\n再招募'..(crew.name or '船员')..'：'..recruitCost..'金币'
    elseif camp and camp>0 and gate then
        cost=recruitCost;result.route='recruit';result.action='前往招募'
        result.detail='训练营已建成\n招募'..(crew.name or '船员')..'：'..recruitCost..'金币'
    else return result end
    local missing=math.max(0,cost-(tonumber(dm:getRoleData(roleMoney)) or 0))
    result.detail=result.detail..'\n'..(missing>0 and ('当前步骤还缺 '..missing..'金币') or '当前步骤金币已备齐')..'\n招募后，在整备中编入船员与食物。'
    if missing>0 then result.route='alchemy';result.action='前往炼金' end
    return result
end
return R
