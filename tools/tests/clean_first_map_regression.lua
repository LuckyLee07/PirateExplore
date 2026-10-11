-- Real opt-in, encrypted save transaction, random event placement, navigation
-- and tutorial selection. Cocos object/layer reads and disk I/O are fixtures.
package.path='bin/res/scripts/?.lua;'..package.path
local F=assert(loadfile(assert(arg[1], 'decoded TMX fixture required')))()
local M=require 'LuaClass/CleanFirstMap'
local N=require 'LuaClass/AdventureNavigation'
local K=require 'LuaClass/KnownRoute'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function copy(t)if type(t)~='table' then return t end;local out={};for k,v in pairs(t)do out[k]=copy(v)end;return out end
local function equal(a,b,label)assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end

-- Reuse only the established CSV/Record/UserData harness, before it runs tests.
local source=read('tools/tests/adventure_progression_regression.lua')
local prefix=assert(source:match('^(.-)\nassert%(not dm%.__roleData:loadData%(%)%)'))
local E=assert(loadstring(prefix..[[
return {dm=dm,A=A,csv=csv,csvRead=csvRead,setFail=function(v)fail=v end,
    disk=function()return disk end,writes=function()return writes end}
]]))()
local dm,A=E.dm,E.A
assert(not dm.__roleData:loadData())
for _,name in ipairs({'loadProducerQueueData','loadMoney','loadPackage','loadExpedition','loadSoildier','loadGuideStep'})do dm.__roleData[name](dm.__roleData,nil)end
dm.__roleData:loadBuild(E.csv[csvOfBuild])
dm.__roleData:loadMake(E.csv[csvOfProduce],E.csv[csvOfResourceInfo])
dm.__roleData:loadStore(E.csv[csvOfStore],E.csv[csvOfResourceInfo])
equal(M.isEnabled(dm,1),false,'empty unsaved role is not opted in')
E.setFail(true);local before=E.disk()
assert(not A.initializeNewRole(dm.__roleData,dm))
equal(E.disk(),before,'failed new-role transaction changed disk')
equal(dm:getRoleData(M.KEY),nil,'failed transaction published marker')
equal(A.getState(dm).enabled,false,'failed transaction published ledger')
E.setFail(false);assert(A.initializeNewRole(dm.__roleData,dm))
equal(dm:getRoleData(M.KEY),M.VERSION,'new role marker')
assert(M.isEnabled(dm,1) and M.isEnabled(dm,'1'))
equal(M.mapPath(dm,1),'Images/Map/map_1_clean_v1.tmx')
for index=2,16 do
    assert(not M.isEnabled(dm,index));equal(M.mapPath(dm,index),'Images/Map/map_'..index..'.tmx')
end
local encrypted=assert(E.disk());equal(json.decode(encrypted)[M.KEY],-1,'marker uses real numeric role encryption')
dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
assert(M.isEnabled(dm,1));equal(E.disk(),encrypted,'cold restore mutated role')
assert(A.setObjective(dm,'supply'))
dm.__roleData=UserData.new();assert(dm.__roleData:loadData());assert(M.isEnabled(dm,1),'unrelated atomic role commit lost marker')
local writes=E.writes()
for i=1,3 do M.mapPath(dm,1);M.isEnabled(dm,1);M.port();M.harborLandTiles() end
equal(E.writes(),writes,'read-only layout access wrote a save')
for _,marker in ipairs({0,'1',2,true,{version=1}})do
    dm.__roleData:setRoleData(M.KEY,marker);assert(not M.isEnabled(dm,1),'unknown marker enabled layout')
end
dm.__roleData:setRoleData(M.KEY,nil)
dm.__roleData:setRoleData(roleMapInfo,{curIndex=1,playerTitlePosition={x=10,y=10}})
dm.__roleData:saveData();local old=E.disk()
dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
assert(A.getState(dm).enabled,'fixture represents an existing Stage1 adventure save')
equal(M.mapPath(dm,1),'Images/Map/map_1.tmx','unversioned adventure save migrated')
equal(dm:getRoleData(roleMapInfo).playerTitlePosition.x,10,'legacy cold position changed')
equal(E.disk(),old,'legacy layout read mutated role')
dm.__roleData:setRoleData(A.KEY,nil);assert(not M.isEnabled(dm,1))
equal(M.mapPath(dm,1),'Images/Map/map_1.tmx','pre-adventure save migrated')
print('PASS atomic new-role-only opt-in, failure rollback, encrypted cold restore, unrelated commits, strict versions and unmigrated legacy/Stage1 saves')

local p=M.port();equal(p.x,7);equal(p.y,11);p.x=99;equal(M.port().x,7,'port accessor leaked mutation')
local land=M.harborLandTiles();equal(#land,50)
local expectedHarbor={};for _,tile in ipairs(F.harbor)do expectedHarbor[K.key(tile,21)]=true end
for _,tile in ipairs(land)do
    assert(F.blocks[tile.y*21+tile.x+1]>0,'renderer harbor footprint absent from TMX')
    assert(expectedHarbor[K.key(tile,21)],'renderer footprint differs from approved coast mask')
    expectedHarbor[K.key(tile,21)]=nil
end
equal(next(expectedHarbor),nil,'renderer omitted authored harbor land')
land[1].x=99;assert(M.harborLandTiles()[1].x~=99)
cc.p=function(x,y)return {x=x,y=y}end
local map={meta=copy(F.meta)}
local blocks={getTileGIDAt=function(_,q)return F.blocks[q.x+q.y*21+1]end}
local meta={getTileGIDAt=function(_,q)return map.meta[q.x+q.y*21+1]end}
function map:getLayer(name)if name=='Blocks_1' then return blocks elseif name=='Meta' then return meta end end
function map:getMapSize()return {width=21,height=21}end
function map:getPropertiesForGID(gid)return F.props[tonumber(gid)]end
function map:getObjectGroup(name)
    assert(name=='Objects')
    return {getObjects=function()return copy(F.objects)end,getObject=function(_,name)assert(name=='Start');return copy(F.objects[1])end}
end
local owner={map=map,meta=meta,mapIndex=1,fogManager={data={}},playerTitlePosition=M.port()}
function owner:tileCoordForPosition(q)return {x=math.floor(q.x/64),y=math.floor((1344-q.y)/64)}end
local function tutorial(label)
    local before=copy(owner.fogManager.data)
    local port=N.port(owner);equal(port.x,7);equal(port.y,11)
    local point,reason=N.tutorialPoint(owner);assert(point,label..': '..tostring(reason))
    assert(point.steps>=2 and point.steps<=4 and #point.path==point.steps+1)
    local graph=N.snapshot(owner);for _,cell in pairs(graph.cells)do cell.known=true end
    local out=K.find(graph,port,point,{})
    local back=K.find(graph,point,port,{})
    assert(back.status=='ok' and point.steps+back.steps<=8)
    equal(point.minFood,out.minimumFood+back.minimumFood,'real food route quote')
    equal(out.minimumFood,point.steps,'ordinary outbound water keeps per-step food cost')
    equal(back.minimumFood,back.steps-1,'only the original port event avoids a return step debit')
    for i,q in ipairs(point.path)do
        local cell=graph.cells[K.key(q,21)];assert(not cell.blocked)
        if i>1 then
            local previous=point.path[i-1]
            equal(math.abs(q.x-previous.x)+math.abs(q.y-previous.y),1,'non-cardinal tutorial move')
            assert(not cell.event,'tutorial transits an event')
        end
    end
    equal(next(owner.fogManager.data),next(before),'tutorial leaked hidden fog')
    return point
end
tutorial('authored fixed events')
for _,q in ipairs(F.slots)do map.meta[q.x+q.y*21+1]=19 end
tutorial('every possible random slot occupied')

-- Use the real layout manager with decrypted packaged CSV values. Only its
-- clock source varies to cover different permutations of the unchanged rules.
package.loaded['LuaClass/WoWUtils']={}
require 'LuaClass/MapLayoutManagers'
local distribution=copy(E.csv[csvOfStrongholdDistribution]['1'])
local function rows(value)
    local out={};for row in value:gmatch('[^;]+')do local fields={};for v in row:gmatch('[^_]+')do fields[#fields+1]=v end;out[#out+1]=fields end;return out
end
local expected={}
for _,key in ipairs({'peripheryInfo','interiorInfo','centralityInfo'})do
    distribution[key]=rows(distribution[key])
    for _,row in ipairs(distribution[key])do
        if row[1]~='0' then expected[row[1]]=(expected[row[1]] or 0)+tonumber(row[2])end
    end
end
assert(expected['3067'] and expected['3070'],'real quarry/wood distribution missing')
local attributes=E.csvRead('strongholdAttribute')
dataController={getStrongholdDistributionInfoById=function()return distribution end,
    getStrongholdAttributeInfoById=function(id)return assert(attributes[tostring(id)])end}
function dm:unlockUnitWithCsvData()end
ExploreDataManager={getInstance=function(self)return self end,
    getPosKeyByPosition=function(_,q)return K.key(q,21)end,
    updateValueByKeysAndValue=function()end,setCurMapStrongholdNum=function()end}
local originalTime=os.time
for seed=1,32 do
    os.time=function()return 1700000000+seed*123 end
    local manager=MapLayoutManagers.new();manager.owner=owner;manager.data={};manager.targets={}
    manager:initLayoutDataByObjectsData()
    map.meta=copy(F.meta);local actual={};local count=0
    for key,event in pairs(manager.data)do
        local n=assert(tonumber(key));assert(not F.props[F.blocks[n+1]],'random event on land')
        equal(F.meta[n+1],0,'random event overwrote authored event')
        map.meta[n+1]=tonumber(event.gid)
        actual[event.id]=(actual[event.id] or 0)+1;count=count+1
    end
    equal(count,manager.curMapStrongholdNum,'random event count')
    for id,num in pairs(expected)do equal(actual[id],num,'original event count '..id)end
    for id,num in pairs(actual)do equal(expected[id],num,'invented event '..id)end
    tutorial('real random layout '..seed)
end
os.time=originalTime
print('PASS 50-cell harbor coast contract, production TMX port, real cardinal tutorial/return/food route, all-slots stress and 32 real CSV random layouts with original event counts')
