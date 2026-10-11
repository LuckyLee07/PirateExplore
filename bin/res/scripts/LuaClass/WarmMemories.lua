-- Permanent, non-tradeable voyage mementos. Preparation is read-only: callers
-- add the returned snapshot to the SAME original return/death transaction.
-- No inventory, currency, unlock, map, objective or reward mutation lives here.
local M = {KEY='warmVoyageMemoriesV1',VERSION=1,ITEM_ID='wreck_chart_fragment',MAX_LOG=20}
M.ID=M.ITEM_ID
local ADVENTURE_KEY='adventureProgressV1'
local MARKER='warmMemoriesVoyageV1'
local definition={id=M.ITEM_ID,name='沉船航图残页',
    description='记录一次沉船抉择与平安返港的纪念残页，可摆在船上。',
    source='wreck_event',tradeable=false,functional=false}
local function copy(value,seen)
    if type(value)~='table' then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local out={};seen[value]=out
    for key,item in pairs(value) do out[key]=copy(item,seen) end
    return out
end
local function whole(value,min)
    return type(value)=='number' and value==value and value<9007199254740991 and value%1==0 and value>=(min or 0)
end
local function voyageId(voyage) return 'adventure:'..string.format('%.0f',voyage) end
local function enabled() return rawget(_G,'WARM_PIRATE_V1')~=false end
local function chapter(map)
    if type(map)~='table' then return nil end
    local value=tonumber(map.curIndex or map.mapIndex)
    return whole(value,1) and value or nil
end
local function validEvent(event,voyage)
    if type(event)~='table' or event.voyage~=voyage then return false end
    local choices={first={rescue='rescue',sailor='rescue',supply='supply',knife='supply'},
        crew={rescue='chart',sailor='chart',supply='supplies',knife='supplies'}}
    local options=choices[event.episode]
    return options and options[event.action]~=nil and options[event.action]==event.choice
end
local function validRecord(id,item)
    return id==M.ITEM_ID and type(item)=='table' and item.id==id
        and whole(item.firstVoyage,1) and item.voyage==item.firstVoyage
        and item.voyageId==voyageId(item.firstVoyage)
        and validEvent({voyage=item.voyage,episode=item.episode,action=item.action,choice=item.choice},item.voyage)
        and item.source=='wreck_event' and (item.chapter==nil or whole(item.chapter,1))
        and item.mapIndex==item.chapter and item.tradeable==false and item.functional==false
end
local function finite(value) return type(value)=='number' and value==value and value>-math.huge and value<math.huge end
local function validCargo(cargo)
    if type(cargo)~='table' then return false end
    for id,item in pairs(cargo) do
        if type(id)~='string' or type(item)~='table' or item.id~=id or not finite(item.num) or item.num<=0 then return false end
    end
    return true
end
local function validSettlement(settlement)
    if type(settlement)~='table' or type(settlement.stockDelta)~='table' or type(settlement.firstReturnAwarded)~='boolean' then return false end
    for _,key in ipairs({'moneyBefore','moneyAfter','diamondBefore','diamondAfter','moneyDelta','diamondDelta','mapCoinsReturned'}) do
        if not finite(settlement[key]) then return false end
    end
    for id,value in pairs(settlement.stockDelta) do if type(id)~='string' or not finite(value) then return false end end
    return settlement.moneyDelta==settlement.moneyAfter-settlement.moneyBefore
        and settlement.diamondDelta==settlement.diamondAfter-settlement.diamondBefore
end
-- Unsupported or corrupt data is never reset/migrated. Unknown additive fields
-- on a supported schema are kept verbatim by every subsequent transaction.
local function read(dm)
    local raw=dm:getRoleData(M.KEY)
    if raw==nil then return {version=M.VERSION,items={},log={},lastVoyage=0},nil,true end
    if type(raw)~='table' then return nil,'corrupt' end
    if raw.version~=M.VERSION then return nil,'incompatible' end
    if type(raw.items)~='table' or type(raw.log)~='table' or not whole(raw.lastVoyage,0) then return nil,'corrupt' end
    for id,item in pairs(raw.items) do if not validRecord(id,item) or item.firstVoyage>raw.lastVoyage then return nil,'corrupt' end end
    if raw.displayId~=nil and (type(raw.displayId)~='string' or not raw.items[raw.displayId]) then return nil,'corrupt' end
    local count,seen=0,{}
    for key,entry in pairs(raw.log) do
        if not whole(key,1) or key>M.MAX_LOG or type(entry)~='table'
            or not whole(entry.voyage,1) or entry.voyage>raw.lastVoyage
            or entry.voyageId~=voyageId(entry.voyage) or entry.id~=entry.voyageId
            or (entry.outcome~='returned' and entry.outcome~='failed')
            or not validCargo(entry.cargo) or not validCargo(entry.returnedCargo)
            or not validCargo(entry.lostCargo) or type(entry.memoryIds)~='table'
            or not validSettlement(entry.settlement) or seen[entry.voyageId]
            or (entry.chapter~=nil and not whole(entry.chapter,1)) or entry.mapIndex~=entry.chapter then return nil,'corrupt' end
        local memoryCount=0
        for index,id in pairs(entry.memoryIds) do
            if index~=1 or id~=M.ITEM_ID or not raw.items[id] or raw.items[id].voyage~=entry.voyage
                or entry.outcome~='returned' then return nil,'corrupt' end
            memoryCount=memoryCount+1
        end
        if memoryCount~=#entry.memoryIds then return nil,'corrupt' end
        seen[entry.voyageId]=true;count=count+1
    end
    if count~=#raw.log or (raw.lastVoyage>0 and (not raw.log[1] or raw.log[1].voyage~=raw.lastVoyage)) then return nil,'corrupt' end
    local previous=raw.lastVoyage+1
    for _,entry in ipairs(raw.log) do
        if entry.voyage>=previous then return nil,'corrupt' end
        previous=entry.voyage
    end
    return copy(raw)
end
local function available(dm)
    if not enabled() then return false,'disabled' end
    local state=dm:getRoleData(ADVENTURE_KEY)
    if type(state)~='table' or state.version~=1 or state.enabled~=true then return false,'legacy' end
    return true
end
function M.definitions() return {copy(definition)} end
function M.get(dm)
    local raw,reason,missing=read(dm)
    local ok,modeReason=available(dm)
    local out={version=M.VERSION,items={},entries={},log={},logs={},readOnly=reason~=nil or not ok,
        reason=reason or modeReason,missing=missing==true,enabled=ok and reason==nil}
    if not raw then return out end
    out.items=copy(raw.items);out.displayId=raw.displayId;out.log=copy(raw.log);out.logs=copy(raw.log)
    out.lastResult=copy(raw.log[1]);out.lastVoyage=raw.lastVoyage
    for _,d in ipairs(M.definitions()) do
        if raw.items[d.id] then
            local item=copy(raw.items[d.id])
            for key,value in pairs(d) do item[key]=value end
            out.items[d.id]=copy(item);out.entries[#out.entries+1]=item
        end
    end
    return out
end
-- The departure marker distinguishes a new real voyage from an already-active
-- pre-feature save. Merely enabling the theme/reading old progress cannot grant.
function M.prepareDeparture(dm,state)
    if not available(dm) or type(state)~='table' or not whole(state.activeVoyage,1) then return nil end
    local previous=state[MARKER]
    if previous~=nil and (type(previous)~='table' or previous.version~=M.VERSION) then return nil end
    local raw=read(dm);if not raw or state.activeVoyage<=raw.lastVoyage then return nil end
    return {version=M.VERSION,voyage=state.activeVoyage,voyageId=voyageId(state.activeVoyage)}
end
local function eligible(dm,state)
    if not available(dm) or type(state)~='table' or not whole(state.activeVoyage,1) then return false end
    local marker=state[MARKER]
    return type(marker)=='table' and marker.version==M.VERSION and marker.voyage==state.activeVoyage
        and marker.voyageId==voyageId(state.activeVoyage)
end
-- Called only by the existing successful wreck resolveEvent commit. The event
-- chapter is captured there, not guessed later from the return destination.
function M.prepareEvent(dm,state)
    if not eligible(dm,state) or not validEvent(state.pending,state.activeVoyage) then return nil end
    local event=copy(state.pending);event.warmMemorySource='wreck_event'
    event.warmMemoryChapter=chapter(dm:getRoleData(roleMapInfo))
    return event
end
local function numeric(value) return tonumber(value) or 0 end
local function quantities(cargo)
    local out={}
    for id,item in pairs(cargo or {}) do
        if type(item)=='table' and numeric(item.num)>0 then out[tostring(id)]={id=tostring(id),num=numeric(item.num)} end
    end
    return out
end
local function delta(before,after)
    local keys,out={},{}
    for id in pairs(before or {}) do keys[id]=true end
    for id in pairs(after or {}) do keys[id]=true end
    for id in pairs(keys) do local difference=numeric((after or {})[id])-numeric((before or {})[id]);if difference~=0 then out[id]=difference end end
    return out
end
local function prepare(dm,state,cargo,map,fields,outcome,context)
    if not eligible(dm,state) then return nil,'ineligible' end
    local raw,reason=read(dm);if not raw then return nil,reason end
    if state.activeVoyage<=raw.lastVoyage then return nil,'recorded' end
    -- Final settlement fields are mandatory; a preview cannot invent a result.
    if type(fields)~='table' or type(fields[rolePack])~='table'
        or not finite(fields[roleMoney]) or not finite(fields[roleDiamond])
        or type(fields[ADVENTURE_KEY])~='table' or fields[ADVENTURE_KEY].activeVoyage then return nil,'incomplete_settlement' end
    local id=voyageId(state.activeVoyage)
    local event=validEvent(state.pending,state.activeVoyage) and state.pending or nil
    local record={id=id,voyageId=id,voyage=state.activeVoyage,outcome=outcome,
        chapter=chapter(map),mapIndex=chapter(map),cargo=quantities(cargo),returnedCargo={},lostCargo={},memoryIds={},
        settlement={moneyBefore=numeric(dm:getRoleData(roleMoney)),moneyAfter=fields[roleMoney],
            diamondBefore=numeric(dm:getRoleData(roleDiamond)),diamondAfter=fields[roleDiamond],
            stockDelta=delta(dm:getRoleData(rolePack),fields[rolePack]),
            firstReturnAwarded=fields[ADVENTURE_KEY].firstReturnClaimed==true and state.firstReturnClaimed~=true}}
    record.settlement.moneyDelta=record.settlement.moneyAfter-record.settlement.moneyBefore
    record.settlement.diamondDelta=record.settlement.diamondAfter-record.settlement.diamondBefore
    if event then record.event={episode=event.episode,action=event.action,choice=event.choice,
        source=event.warmMemorySource,chapter=event.warmMemoryChapter} end
    if outcome=='returned' then
        record.returnedCargo=copy(record.cargo)
        record.returnKind=context and context.returnRequest and context.returnRequest.kind or (context and context.statue and 'tool' or 'normal')
        record.settlement.mapCoinsReturned=not (context and context.statue) and numeric(dm:getRoleData(roleMapCoin)) or 0
        if event and event.warmMemorySource=='wreck_event' and not raw.items[M.ITEM_ID] then
            local item=copy(definition)
            item.firstVoyage=state.activeVoyage;item.voyage=state.activeVoyage;item.voyageId=id
            item.action=event.action;item.choice=event.choice;item.episode=event.episode
            item.chapter=event.warmMemoryChapter;item.mapIndex=item.chapter
            raw.items[M.ITEM_ID]=item;record.memoryIds={M.ITEM_ID}
        end
    else
        local resources=dm:getCSVByID(csvOfResourceInfo) or {}
        for itemId,item in pairs(record.cargo) do
            if tostring((resources[itemId] or {}).carryType)=='2' then record.returnedCargo[itemId]=copy(item)
            else record.lostCargo[itemId]=copy(item) end
        end
        record.settlement.mapCoinsReturned=0
    end
    table.insert(raw.log,1,record)
    while #raw.log>M.MAX_LOG do table.remove(raw.log) end
    raw.lastVoyage=state.activeVoyage
    return raw
end
function M.prepareReturn(dm,state,cargo,map,fields,context)
    return prepare(dm,state,cargo,map,fields,'returned',context)
end
function M.prepareFailure(dm,state,cargo,map,fields)
    return prepare(dm,state,cargo,map,fields,'failed')
end
-- Explicit display confirmation calls this. Opening, preview, Back and Cancel
-- use get() only. No automatic selection is made when a memory is collected.
function M.setDisplay(dm,id)
    local ok,reason=available(dm);if not ok then return false,reason end
    local raw,err,missing=read(dm);if not raw then return false,err end
    if id~=nil and (type(id)~='string' or not raw.items[id]) then return false,'not_owned' end
    if missing or raw.displayId==id then return true,'unchanged' end
    raw.displayId=id
    if not dm.__roleData or type(dm.__roleData.commitAdventure)~='function'
        or not dm.__roleData:commitAdventure({[M.KEY]=raw}) then return false,'save_failed' end
    if type(dm.postEvent)=='function' then dm:postEvent(M.KEY,nil) end
    return true
end
return M
