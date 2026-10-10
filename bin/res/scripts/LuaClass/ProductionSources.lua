-- Read-only production navigation. The saved worker queue is the runtime's
-- unlock authority; buildings and sea-area rewards can both unlock workers.
ProductionSources = {}
local P = ProductionSources

local function rows(value)
    if type(value) == 'table' then return value end
    local result = {}
    for part in tostring(value or ''):gmatch('[^;]+') do
        local id, amount = part:match('^([^_]+)_([^_]+)$')
        if id and amount then result[#result+1] = {id, amount} end
    end
    return result
end

function P.find(dm, guide, resourceId)
    if not guide:getIsHaveStep(2) then return nil end
    local recipes = dm:getCSVByID(csvOfWorker) or {}
    local resources = dm:getCSVByID(csvOfResourceInfo) or {}
    for _, worker in ipairs(dm:getRoleData(roleProducerQueue) or {}) do
        local id = tostring(worker[dataKeyID])
        local recipe = recipes[id]
        -- Zero assigned workers can still be arranged on the resource page.
        -- Like LocalProduction, a valid recipe needs both input and output data.
        if recipe and recipe.resume and recipe.produce then
            for _, output in ipairs(rows(recipe.produce)) do
                if tostring(output[1]) == tostring(resourceId) and (tonumber(output[2]) or 0) > 0 then
                    return {id=id, resourceId=tostring(resourceId),
                        name=(resources[tostring(resourceId)] or {}).name or tostring(resourceId)}
                end
            end
        end
    end
end

function P.first(dm, guide, materials)
    for _, material in ipairs(materials or {}) do
        local source = P.find(dm, guide, material.mtId)
        if source then return source end
    end
end

function P.caption(source)
    return source and (source.name..'可生产\n需安排工人并备齐原料') or '暂无已解锁的生产途径'
end

return P
