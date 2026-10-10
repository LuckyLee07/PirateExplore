-- Read-only suggestions derived from the shipped recipes and current inventory.
-- Opening a suggestion never manufactures, buys, unlocks, or changes a save.
HarborGoals = {}
local G = HarborGoals
local function rows(value)
    if type(value)=='table' then return value end
    local result={}
    for part in tostring(value or ''):gmatch('[^;]+') do
        local a,b=part:match('^([^_]+)_([^_]+)$')
        if a and b then result[#result+1]={a,b} end
    end
    return result
end
local function entry(queue,id)
    for _,v in ipairs(queue or {}) do
        if tostring(v[dataKeyID])==tostring(id) then return v end
    end
end
function G.shortfall(recipe,resources,pack,money)
    local missing={}
    for _,need in ipairs(rows(recipe and recipe.resume)) do
        local id=tostring(need[1]);local required=tonumber(need[2]) or 0
        local have=id=='1001' and (tonumber(money) or 0) or (tonumber(pack[id]) or 0)
        local gap=math.max(0,required-have)
        if gap>0 then missing[#missing+1]=((resources[id] or {}).name or id)..' '..gap end
    end
    return #missing==0 and '材料已备齐' or ('还缺 '..table.concat(missing,' · '))
end
function G.list(dm,returned)
    if not returned then return {} end
    local resources=dm:getCSVByID(csvOfResourceInfo) or {}
    local builds=dm:getCSVByID(csvOfBuild) or {}
    local make=dm:getRoleData(roleMake) or {}
    local forge=entry(dm:getRoleData(roleBuilding),'57')
    local pack=dm:getRoleData(rolePack) or {};local money=dm:getRoleData(roleMoney)
    local result={}
    local specs={{id='1148',role=rolePackSize,kind='1',name='货舱',unit=''},
                 {id='1176',role=roleAlchemyUnit,kind='4',name='炼金',unit='金币/次'}}
    for _,spec in ipairs(specs) do
        local recipe=resources[spec.id];local target
        for _,effect in ipairs(rows(recipe and recipe.raiseType)) do
            if tostring(effect[1])==spec.kind then target=tonumber(effect[2]) end
        end
        local current=tonumber(dm:getRoleData(spec.role)) or 0
        if recipe and target and current>0 and current<target then
            local g={id=spec.id,current=current,target=target,
                title=spec.name..' '..current..' → '..target..spec.unit}
            local unlocked=entry(make,spec.id)
            if unlocked and tonumber(unlocked[dataKeyNum])~=0 then
                g.route='make';g.routeId=spec.id;g.action='查看制造'
                g.detail=G.shortfall(recipe,resources,pack,money)
            elseif forge and tonumber(forge[dataKeyNum])==0 and builds['57'] then
                g.route='build';g.routeId='57';g.action='先建铁匠'
                g.detail='需先建铁匠铺\n'..G.shortfall(builds['57'],resources,pack,money)
            else
                g.action='尚未解锁';g.detail='继续探索，解锁铁匠铺与制造配方'
            end
            result[#result+1]=g
        end
    end
    return result
end
-- CCTableView uses a bottom-origin offset even for top-down row filling.
function G.focusOffset(count,index,height,rowHeight)
    local bottom=math.min(0,height-count*rowHeight)
    return math.min(0,math.max(bottom,bottom+(index-1)*rowHeight))
end
return G
