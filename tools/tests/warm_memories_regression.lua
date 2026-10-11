-- Real encrypted UserData + production return/death commits. Only Record disk
-- I/O is mocked; no existing player profile is opened or modified.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/adventure_state_audit.lua')
local stop=assert(source:find('\nfixture({[roleGuideStep]',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..'\n'..[[
return {dm=dm,A=A,fixture=fixture,reload=reload,stableFail=stableFail,
    disk=function()return disk end,writes=function()return writes end,
    fail=function(value)fail=value end}
]],'@warm-memories-fixture'))()
local dm,A=F.dm,F.A
local M=require 'LuaClass/WarmMemories'
local function eq(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function serial(v)
    if type(v)~='table' then return type(v)..':'..tostring(v) end
    local keys={};for key in pairs(v)do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    local out={};for _,key in ipairs(keys)do out[#out+1]=serial(key)..'='..serial(v[key])end
    return '{'..table.concat(out,';')..'}'
end
local function set(key,value)dm.__roleData:setRoleData(key,value)end
local function fixture(extra)
    WARM_PIRATE_V1=true;F.fixture(extra);set(roleMapInfo,{curIndex=1});dm.__roleData:saveData()
end
local function depart(action)
    assert(A.depart(dm,{['1005']=10,['10100']=1}))
    if action then assert(A.resolveEvent(dm,action)) end
end
local function onlyWrites(number,fn)
    local before=F.writes();local result={fn()};eq(F.writes()-before,number,'atomic save count');return unpack(result)
end
fixture();local before=F.disk()
eq(#M.get(dm).entries,0);eq(#M.get(dm).log,0);eq(M.get(dm).readOnly,false)
assert(M.setDisplay(dm,nil));assert(not M.setDisplay(dm,M.ITEM_ID))
eq(F.disk(),before,'read/clear empty field cannot initialize');eq(dm:getRoleData(M.KEY),nil)
eq(M.definitions()[1].name,'沉船航图残页')
-- The new eligible marker participates in departure rollback and cold reload.
F.stableFail(function()return A.depart(dm,{['1005']=10,['10100']=1})end)
eq(A.getState(dm).warmMemoriesVoyageV1,nil)
depart('rescue');eq(A.getState(dm).warmMemoriesVoyageV1.voyage,1)
eq(A.getState(dm).pending.warmMemorySource,'wreck_event');eq(A.getState(dm).pending.warmMemoryChapter,1)
eq(dm:getRoleData(M.KEY),nil,'pending sea outcome is not collection ownership')
F.reload();F.stableFail(function()return A.returnVoyage(dm,nil)end)
eq(dm:getRoleData(M.KEY),nil,'failed return save grants nothing');assert(A.getState(dm).pending)
local ok,awarded=onlyWrites(1,function()return A.returnVoyage(dm,nil)end);assert(ok and awarded)
local view=M.get(dm);eq(#view.entries,1);eq(#view.log,1);eq(view.displayId,nil)
local item=view.items[M.ITEM_ID]
eq(item.firstVoyage,1);eq(item.voyageId,'adventure:1');eq(item.action,'rescue');eq(item.choice,'rescue')
eq(item.chapter,1);eq(item.source,'wreck_event');eq(item.tradeable,false);eq(item.functional,false)
eq(view.log[1].memoryIds[1],M.ITEM_ID);eq(view.log[1].outcome,'returned')
eq(view.log[1].returnedCargo['1008'].num,2);eq(view.log[1].settlement.moneyAfter,dm:getRoleData(roleMoney))
eq(view.log[1].settlement.stockDelta['1008'],2);eq(view.log[1].settlement.stockDelta['1006'],15)
assert(view.log[1].settlement.firstReturnAwarded)
eq(A.getState(dm).warmMemoriesVoyageV1,nil,'terminal marker is cleared in same snapshot')
for i=1,3 do F.reload();before=F.disk();assert(A.returnVoyage(dm,nil));eq(F.disk(),before);eq(#M.get(dm).log,1)end
eq(M.get(dm).items[M.ITEM_ID].choice,'rescue','actual encrypted JSON round-trip retains story')
-- Snapshot edits, preview and cancellation never call a setter or touch disk.
before=F.disk();view=M.get(dm);view.items[M.ITEM_ID].choice='fake';view.entries[1].action='fake';view.log[1].outcome='fake';view.displayId=M.ITEM_ID
eq(F.disk(),before);eq(M.get(dm).displayId,nil);eq(M.get(dm).entries[1].action,'rescue')
assert(not M.setDisplay(dm,'invented'));assert(not M.setDisplay(dm,{}));eq(F.disk(),before)
F.stableFail(function()return M.setDisplay(dm,M.ITEM_ID)end);eq(M.get(dm).displayId,nil)
onlyWrites(1,function()assert(M.setDisplay(dm,M.ITEM_ID))end);F.reload();eq(M.get(dm).displayId,M.ITEM_ID)
onlyWrites(0,function()assert(M.setDisplay(dm,M.ITEM_ID))end)
before=F.disk();local preview=nil;eq(preview,nil);eq(F.disk(),before,'cancel clear-display preview remains unchanged')
onlyWrites(1,function()assert(M.setDisplay(dm,nil))end);F.reload();eq(M.get(dm).displayId,nil)
print('PASS first actual return: same atomic grant/log, rollback, cold JSON reload, replay, read-only preview and validated explicit display')

-- Return quotes are consumed by the original path before its log is prepared.
csvOfStrongholdDistribution='csvOfStrongholdDistribution';csvOfShopItem='csvOfShopItem'
local originalCSV=dm.getCSVByID
function dm:getCSVByID(key)
    if key==csvOfStrongholdDistribution then return {['1']={gohome={{'1999','1'}}}} end
    if key==csvOfShopItem then return {['12']={price=15}} end
    local rows=originalCSV(self,key);rows['1999'].shop_connect='12';return rows
end
for _,kind in ipairs({'free','scroll','diamond'}) do
    fixture();depart('rescue')
    if kind~='free' then set(roleMapInfo,{curIndex=1,fristReturnBaseByTool='1'}) end
    if kind=='scroll' then local bag=dm:getRoleData(roleBattlePack);bag['1999']={id='1999',num=1};set(roleBattlePack,bag)end
    set(roleMapCoin,11);dm.__roleData:saveData();local quote=A.quoteReturn(dm,1);eq(quote.kind,kind)
    F.stableFail(function()return A.returnVoyage(dm,true,quote)end)
    assert(A.returnVoyage(dm,true,quote));view=M.get(dm);local result=view.log[1]
    eq(result.returnKind,kind);eq(result.settlement.mapCoinsReturned,0)
    eq(result.settlement.moneyAfter,dm:getRoleData(roleMoney));eq(result.settlement.diamondAfter,dm:getRoleData(roleDiamond))
    eq(result.settlement.diamondDelta,kind=='diamond' and -15 or 0)
    eq(result.returnedCargo['1999'],nil,'spent scroll never appears as returned cargo')
    eq(result.cargo['1999'],nil);eq(#view.entries,1)
end
fixture();depart('rescue');set(roleMapInfo,{curIndex=1,fristReturnBaseByTool='1'})
local quote=A.quoteReturn(dm,1);set(roleDiamond,0);before=F.disk()
assert(not A.returnVoyage(dm,true,quote));eq(F.disk(),before);eq(dm:getRoleData(M.KEY),nil)
set(roleBattleQueue,{});assert(not A.returnVoyage(dm,nil));eq(dm:getRoleData(M.KEY),nil)
dm.getCSVByID=originalCSV
print('PASS free/scroll/diamond final settlements reflect actual paid costs; insufficient funds/no-survivor rejection cannot grant/log')

-- Every original first/crew choice can produce this single memorial, with its
-- actual branch saved. The memorial never claims a rescue/chart branch instead.
for _,episode in ipairs({'first','crew'}) do
    for _,action in ipairs({'rescue','supply','sailor','knife'}) do
        fixture();set(rolePackSize,40)
        if episode=='crew' then set(A.KEY,{version=1,enabled=true,voyage=8,firstEventReturned=true,firstReturnClaimed=true}) end
        local crewId=action=='sailor' and '101' or action=='knife' and '112' or '100'
        set(roleSoildierQueue,{[crewId]={id=crewId,num=1}})
        assert(A.depart(dm,{['1005']=10,[tostring(tonumber(crewId)+10000)]=1}))
        assert(A.resolveEvent(dm,action));local pending=A.getState(dm).pending
        set(roleMapInfo,{curIndex=2}) -- first acquisition chapter was the wreck's chapter one.
        assert(A.returnVoyage(dm,nil));item=M.get(dm).entries[1]
        eq(item.episode,episode);eq(item.action,action);eq(item.choice,pending.choice);eq(item.chapter,1)
        eq(M.get(dm).log[1].chapter,2,'log return chapter and event chapter are distinct')
    end
end
fixture();depart('supply');assert(A.returnVoyage(dm,nil));local first=serial(M.get(dm).entries[1])
set(rolePackSize,30);depart('rescue');assert(A.returnVoyage(dm,nil))
eq(#M.get(dm).entries,1);eq(serial(M.get(dm).entries[1]),first);eq(#M.get(dm).log,2)
eq(#M.get(dm).log[1].memoryIds,0,'second real wreck does not regrant or rewrite first story')
print('PASS all actual first/crew wreck choices preserve provenance; first ownership stays once-only')

-- Enabling the new code on old progress cannot retrospectively grant or log.
fixture();set(A.KEY,{version=1,enabled=true,voyage=8,activeVoyage=8,firstEventReturned=true,
    pending={voyage=8,episode='first',action='rescue',choice='rescue'}})
set(roleBattlePack,{['1008']={id='1008',num=2}});set(roleBattleQueue,{['100']=1})
assert(A.returnVoyage(dm,nil));eq(dm:getRoleData(M.KEY),nil,'pre-feature active voyage has no marker')
fixture();set(A.KEY,{version=1,enabled=true,voyage=8,firstEventReturned=true,firstReturnClaimed=true,followupReturned=true})
depart();assert(A.returnVoyage(dm,nil));eq(#M.get(dm).entries,0);eq(#M.get(dm).log,1)
eq(M.get(dm).log[1].voyage,9,'no fabricated eight historical logs')
fixture();depart('rescue');local state=A.getState(dm);state.pending.voyage=77;set(A.KEY,state)
assert(A.returnVoyage(dm,nil));eq(#M.get(dm).entries,0,'mismatched pending voyage cannot grant')
fixture();depart('rescue');state=A.getState(dm);state.pending.warmMemorySource=nil;set(A.KEY,state)
assert(A.returnVoyage(dm,nil));eq(#M.get(dm).entries,0,'unstamped event is not a new qualifying wreck')
fixture();set(A.KEY,nil);before=F.disk();eq(M.get(dm).readOnly,true)
assert(not A.returnVoyage(dm,nil));assert(not M.setDisplay(dm,nil));eq(F.disk(),before);eq(dm:getRoleData(M.KEY),nil)
print('PASS no old-save backfill, no pre-feature active-voyage grant, no mismatched event grant, absent-ledger no-op')

-- Failure loses the same ordinary cargo and preserves the same mission items.
fixture();depart('rescue');local cargo=dm:getRoleData(roleBattlePack);cargo['1999']={id='1999',num=2};set(roleBattlePack,cargo)
set(roleMapCoin,11);dm.__roleData:saveData();before=F.disk()
assert(not A.returnVoyage(dm,'Killed'));assert(not A.returnVoyage(dm,'NoBread'));eq(F.disk(),before)
F.stableFail(function()return A.failVoyage(dm,{{id='100',num=1}})end);eq(dm:getRoleData(M.KEY),nil)
onlyWrites(1,function()assert(A.failVoyage(dm,{{id='100',num=1}}))end);F.reload()
view=M.get(dm);eq(#view.entries,0);eq(view.log[1].outcome,'failed');eq(#view.log[1].memoryIds,0)
eq(view.log[1].returnedCargo['1999'].num,2);eq(view.log[1].lostCargo['1008'].num,2)
eq(view.log[1].settlement.mapCoinsReturned,0);eq(view.log[1].settlement.stockDelta['1999'],2)
eq(dm:getRoleData(rolePack)['1999'],2);eq(dm:getRoleData(rolePack)['1005'],90)
before=F.disk();assert(A.failVoyage(dm,{}));eq(F.disk(),before);eq(#M.get(dm).log,1)
fixture();depart('supply');assert(A.finishVoyage(dm,false));eq(#M.get(dm).entries,0)
print('PASS failure/abandon grants nothing; actual loss/mission survival log uses original single atomic death commit')

-- More than twenty actual voyages stays bounded; high-water ID prevents replay.
fixture()
for voyage=1,24 do depart();assert(A.returnVoyage(dm,nil))end
view=M.get(dm);eq(#view.log,M.MAX_LOG);eq(view.log[1].voyage,24);eq(view.log[20].voyage,5)
eq(view.lastResult.voyage,24);F.reload();eq(#M.get(dm).log,20)
state=A.getState(dm);state.activeVoyage=2;state.warmMemoriesVoyageV1={version=1,voyage=2,voyageId='adventure:2'};set(A.KEY,state)
set(roleBattleQueue,{['100']=1});before=serial(dm:getRoleData(M.KEY));assert(A.returnVoyage(dm,nil))
eq(serial(dm:getRoleData(M.KEY)),before,'evicted historical voyage cannot duplicate log')
print('PASS stable unique voyage IDs, twenty-record retention and replay high-water mark')

-- Unknown version/corrupt field is never reset; supported unknown fields survive.
for _,raw in ipairs({false,'bad',{version=2,future={sentinel=true}},
    {version=1,items={},log={},lastVoyage='bad'},
    {version=1,items={},log={},lastVoyage=0,displayId=M.ITEM_ID},
    {version=1,items={[M.ITEM_ID]={id=M.ITEM_ID}},log={},lastVoyage=0}}) do
    fixture();set(M.KEY,raw);dm.__roleData:saveData();local original=serial(raw)
    assert(M.get(dm).readOnly);assert(not M.setDisplay(dm,nil));depart('rescue');assert(A.returnVoyage(dm,nil))
    eq(serial(dm:getRoleData(M.KEY)),original,'invalid schema never overwritten');F.reload();eq(serial(dm:getRoleData(M.KEY)),original)
end
fixture();set(M.KEY,{version=1,items={},log={},lastVoyage=0,future={sentinel=true}})
depart('rescue');assert(A.returnVoyage(dm,nil));assert(M.setDisplay(dm,M.ITEM_ID));F.reload()
eq(dm:getRoleData(M.KEY).future.sentinel,true)
fixture();state=A.getState(dm);state.warmMemoriesVoyageV1={version=2,future=true};set(A.KEY,state)
depart('rescue');assert(A.returnVoyage(dm,nil));eq(A.getState(dm).warmMemoriesVoyageV1.version,2)
eq(dm:getRoleData(M.KEY),nil,'unknown departure marker is preserved rather than adopted')
print('PASS unknown version/corrupt schema fail safely; supported additive fields preserved')

-- Toggle parity uses actual original settlement paths, not hand-derived totals.
local tracked={A.KEY,rolePack,roleSoildierQueue,roleMoney,roleDiamond,roleBattlePack,roleBattleQueue,
    roleMapInfo,roleMapCoin,roleStatue,roleGuideStep,roleBreadCostDecimal,roleSelectUnit,rolePackSize,
    roleCabinSize,roleBuilding,roleDeathInformation,roleBlackMarketRestrictions,roleTempReceivedDatas}
local function result(warm,failed,tool)
    fixture();WARM_PIRATE_V1=warm;depart('rescue')
    local bag=dm:getRoleData(roleBattlePack);bag['1001']={id='1001',num=3};bag['1002']={id='1002',num=2};bag['1999']={id='1999',num=2};set(roleBattlePack,bag);set(roleMapCoin,11)
    if failed then assert(A.failVoyage(dm,{{id='100',num=1}})) else assert(A.returnVoyage(dm,tool))end
    local out={};for _,key in ipairs(tracked)do out[key]=dm:getRoleData(key)end
    if not warm then eq(dm:getRoleData(M.KEY),nil) end
    return serial(out)
end
for _,failed in ipairs({false,true})do for _,tool in ipairs({false,true})do eq(result(true,failed,tool),result(false,failed,tool),'all original settlement fields identical')end end
-- Optional module loads safely when lightweight legacy fixtures return true.
local originalRequire=require;require=function(name)if name=='LuaClass/WarmMemories' then return true end;return originalRequire(name)end
local mocked=assert(loadfile('bin/res/scripts/LuaClass/AdventureProgress.lua'))();fixture()
assert(mocked.depart(dm,{['1005']=10,['10100']=1}));assert(mocked.resolveEvent(dm,'rescue'));assert(mocked.returnVoyage(dm,nil))
eq(dm:getRoleData(M.KEY),nil);require=originalRequire
print('PASS WARM_PIRATE_V1=false exact legacy settlement parity and true-sentinel require compatibility')
