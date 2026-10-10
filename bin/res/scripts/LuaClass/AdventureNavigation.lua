-- Adapter: reads the live layout/fog and the same TMX properties as Explore.
-- Never generates a map, clears fog, triggers an event or mutates role data.
local K=require 'LuaClass/KnownRoute'
local N={boundaryMessage='已到海图边界，请换个方向。'}
local function props(map,layer,p)
    if not layer then return nil end
    local gid=layer:getTileGIDAt(p)
    return gid and map:getPropertiesForGID(gid) or nil
end
function N.port(owner)
    local objects=owner.map and owner.map:getObjectGroup('Objects')
    local start=objects and objects:getObject('Start')
    if start then return owner:tileCoordForPosition({x=tonumber(start.x),y=tonumber(start.y)}) end
    return nil -- Do not trust bothPosition: legacy reload leaves it at (0,0).
end
function N.snapshot(owner)
    if not owner or not owner.map then return nil end
    local map=owner.map;local size=map:getMapSize()
    local graph={width=size.width,height=size.height,cells={}}
    local a,b=map:getLayer('Blocks_1'),map:getLayer('Blocks_2')
    local meta=owner.meta or map:getLayer('Meta')
    if not meta or not a then return nil end
    local fog=owner.fogManager and owner.fogManager.data
    if not fog and ExploreDataManager then fog=ExploreDataManager:getInstance():getCurMapFogData() end
    fog=fog or {}
    for y=0,size.height-1 do for x=0,size.width-1 do
        local p={x=x,y=y};local key=K.key(p,size.width)
        local pa,pb,pm=props(map,a,p),props(map,b,p),props(map,meta,p)
        local event=type(pm)=='table' and pm.eventid~=nil
        graph.cells[key]={known=tonumber(fog[key])==0,
            blocked=type(pa)=='table' or type(pb)=='table' or (type(pm)=='table' and not event),
            event=event,costed=not event}
    end end
    return graph
end
local function position(owner)
    if owner.playerTitlePosition then return owner.playerTitlePosition end
    if not owner.player then return nil end
    local x,y=owner.player:getPosition()
    return owner:tileCoordForPosition({x=x,y=y})
end
function N.query(owner,options)
    local graph=N.snapshot(owner);local port=graph and N.port(owner)
    if not graph or not port then return {status='unavailable'} end
    options=options or {}
    local bagFood=owner.bagController and owner.bagController:getBreads() or 0
    local decimal=owner.breadCostDecimal or 0
    -- costbread clears accumulated starvation debt on replenishing an empty bag.
    if owner.breadNum==0 and bagFood>0 then decimal=0 end
    local result=K.find(graph,position(owner),port,{breadCoefficient=options.breadCoefficient,
        breadCostDecimal=decimal,food=bagFood})
    result.port=port
    return result
end
function N.gateClue(owner,options)
    options=options or {}
    local graph=N.snapshot(owner);local origin=options.origin=='port' and N.port(owner) or position(owner)
    local layout=owner.mapLayoutManagers and owner.mapLayoutManagers.data
    local csv=owner.eventManger and owner.eventManger.csvData
    if not graph or not origin or not layout or not csv then return {status='unavailable'} end
    local gates={}
    for key,value in pairs(layout) do
        local info=type(value)=='table' and csv[tostring(value.id)]
        if info and info.name=='传送点' and tonumber(key) then
            local n=tonumber(key);local p={x=n%graph.width,y=math.floor(n/graph.width)}
            if K.inBounds(p,graph.width,graph.height) and not graph.cells[K.key(p,graph.width)].blocked then gates[#gates+1]=p end
        end
    end
    table.sort(gates,function(a,b)return a.y==b.y and a.x<b.x or a.y<b.y end)
    if #gates~=1 then return {status=#gates==0 and 'no_gate' or 'ambiguous_gate'} end
    return {status='ok',direction=K.direction(origin,gates[1]),target=gates[1],
        text='章门线索：'..K.direction(origin,gates[1])..'方海域（以'..(options.origin=='port' and '港口' or '当前位置')..'为准）'}
end
-- Actual material-event records, joined by this save's layout IDs. No unknown
-- positions are returned. A clue is a visit objective, not a grant or guarantee.
function N.supplyClue(owner)
    local graph=N.snapshot(owner);local origin=position(owner)
    local layout=owner.mapLayoutManagers and owner.mapLayoutManagers.data
    local csv=owner.eventManger and owner.eventManger.csvData
    local missing={status='not_found',text='尚未发现可前往的材料点，请继续揭开附近迷雾。'}
    if not graph or not origin or not layout or not csv then return missing end
    local candidates={}
    for key,value in pairs(layout) do
        local info=type(value)=='table' and csv[tostring(value.id)]
        local numeric=tonumber(key)
        if numeric and info and info.eventFucString=='changeToMaterialsLayer' then
            local target={x=numeric%graph.width,y=math.floor(numeric/graph.width)}
            local cell=graph.cells[key]
            local priority,material=2,nil
            if type(info.dropitems)=='table' then
                for _,drop in ipairs(info.dropitems) do
                    if type(drop)=='table' and tonumber(drop[1]) and tonumber(drop[1])>0
                        and tonumber(drop[2]) and tonumber(drop[2])>0 then
                        material=material or tostring(drop[1])
                        -- Packaged resourceInfo: 1007 wood, 1008 iron. IDs are
                        -- obtained from this target's dropitems, never invented.
                        if tostring(drop[1])=='1007' or tostring(drop[1])=='1008' then
                            priority=1;material=tostring(drop[1])
                        end
                    end
                end
            end
            if material and cell and cell.known and not cell.blocked and cell.event then
                local route=K.find(graph,origin,target,{})
                if route.status=='ok' or route.status=='at_port' then
                    candidates[#candidates+1]={target=target,name=info.name or '材料点',
                        materialId=material,priority=priority,steps=route.steps,id=tostring(value.id)}
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.priority~=b.priority then return a.priority<b.priority end
        if a.steps~=b.steps then return a.steps<b.steps end
        return a.target.y==b.target.y and a.target.x<b.target.x or a.target.y<b.target.y
    end)
    local target=candidates[1]
    if not target then return missing end
    target.status='ok';target.direction=K.direction(origin,target.target)
    target.text='补给线索：'..target.direction..'方'..target.name..'（已探；占领/采集另需成本）'
    if target.steps==0 then target.text='已到'..target.name..'，请点击据点查看占领/采集成本。' end
    return target
end
function N.tutorialPoint(owner)
    local graph=N.snapshot(owner);local port=graph and N.port(owner)
    if not graph or not port then return nil,'地图尚未就绪' end
    -- Generation validation only, NOT the player-facing known-route query.
    -- Read real terrain behind fog to place a reachable first-voyage objective.
    -- Caller restricts to new saves; this never reveals fog or paints a tile.
    for _,cell in pairs(graph.cells) do cell.known=true end
    local candidates={}
    for y=0,graph.height-1 do for x=0,graph.width-1 do
        local p={x=x,y=y};local cell=graph.cells[K.key(p,graph.width)]
        if math.abs(x-port.x)+math.abs(y-port.y)<=4 and cell.known and not cell.blocked and not cell.event then
            local out=K.find(graph,port,p,{})
            local back=K.find(graph,p,port,{})
            if out.status=='ok' and back.status=='ok' and out.steps>=2 and out.steps+back.steps<=8 then
                candidates[#candidates+1]={x=x,y=y,path=out.path,steps=out.steps,
                    minFood=out.minimumFood+back.minimumFood,direction=K.direction(port,p)}
            end
        end
    end end
    table.sort(candidates,function(a,b)
        if a.steps~=b.steps then return a.steps>b.steps end
        return a.y==b.y and a.x<b.x or a.y<b.y
    end)
    return candidates[1],#candidates==0 and '港口附近没有2至4步内可往返的空海格' or nil
end
return N
