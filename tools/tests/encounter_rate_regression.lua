-- Production encounter pipeline; no player save, native UI or real random seed changes.
local root='bin/res/scripts/LuaClass/'
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local function eq(a,b,label)assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
require=function()return true end
function class(_,factory)local t={};function t.new()return setmetatable(factory(),{__index=t})end;return t end
cc={p=function(x,y)return {x=x,y=y}end};printn=function()end
csvOfEncounter='encounters';roleCompletedMissionHistory='history';roleDefeatedHistory='defeated';roleBattleQueue='crew'
local history,rows,active,costs={},{},{},{}
local dm={getCSVByID=function()return rows end,getRoleData=function(_,key)if key=='history'then return history else return {}end end,setRoleData=function(_,_,v)history=v end}
DataManager={getInstance=function()return dm end}
MissionManagers={getInstance=function()return {missionsIsInValidMissions=function(_,id)return active[id]end}end}
ExploreBagController={getBagController=function()return {costGoodsByGoodsIdAndNum=function(_,id,n)costs[#costs+1]={id,n}end}end}
local x,y=10,20
local explor={mapIndex=1,player={getPositionX=function()return x end,getPositionY=function()return y end},tileCoordForPosition=function(_,p)return p end}
getExplor=function()return explor end
local draw,rolls,selections=0,0,0
math.random=function(...)eq(select('#',...),0,'same no-argument random draw');rolls=rolls+1;return draw end
getRandomNumByRange=function(r)eq(r.min,1);selections=selections+1;return r.max end
dofile(root..'SkirmishLogicManagers.lua')
local manager=SkirmishLogicManagers.new();manager:init()
local function encounter(rate)return {ID='24',rate=tostring(rate),trigger='1',area={{'2','10','2','20','2'}},Type={{'5','24','1'}},Enemys={{'enemy','1'}},consumption={{'0'}},frequency='1'}end
for _,case in ipairs({{0,0,false},{0,.999999,false},{20,0,true},{20,.199999,true},{20,.20,false},{20,.200001,false},{20,.87354,false},{100,0,true},{100,.999999,true},{100,1,true}})do
    manager.validEncounters={encounter(case[1])};draw=case[2];local r,s=rolls,selections
    manager:useTheDice();eq(manager.curEncounter~=nil,case[3],'rate '..case[1]..' roll '..draw);eq(rolls,r+1,'exactly one percentage draw');eq(selections,s+(case[3] and 1 or 0),'candidate selection only on hit')
end
-- Decode the actual shipped CSV with the existing independent fixture decoder.
local fixture=read('tools/tests/home_master_regression.lua');local a=assert(fixture:find('local function readFile(path)',1,true));local b=assert(fixture:find("\nlocal soldiers=packagedCSV('soilderAttribute')",a,true))
local csv=assert(loadstring('local equal=...\n'..fixture:sub(a,b-1)..'\nreturn packagedCSV','@encounter-csv'))(eq)('Encounter')
local actual
for _,row in pairs(csv)do if row.Type:match('^5_24')then actual=row;break end end
assert(actual,'real mission 24 encounter');eq(actual.rate,'20','packaged mission 24 remains twenty percent')
rows={['24']=encounter(100)};active['24']=true;draw=.87354
manager:screeningEncounters();eq(manager:tryMeetSpecialMonster()[1],'enemy')
for _,p in ipairs({{10,20},{12,22}})do x,y=p[1],p[2];assert(manager:tryMeetSpecialMonster(),'inclusive area edges')end
for _,p in ipairs({{9,20},{13,20},{10,19},{10,23}})do x,y=p[1],p[2];eq(manager:tryMeetSpecialMonster(),nil,'outside area')end
x,y=10,20;active['24']=nil;eq(manager:tryMeetSpecialMonster(),nil,'inactive mission');active['24']=true
explor.mapIndex=2;manager:screeningEncounters();eq(manager:tryMeetSpecialMonster(),nil,'wrong map');explor.mapIndex=1
history.E24=0;manager:screeningEncounters();eq(manager:tryMeetSpecialMonster(),nil,'exhausted encounter');history.E24=1;manager:screeningEncounters();assert(manager:tryMeetSpecialMonster());manager:minesweeperFightIsOver();eq(history.E24,0);eq(#manager.encounters,0);eq(manager:tryMeetSpecialMonster(),nil,'exhaustion immediately prunes candidate')
-- Existing candidate choice and costs stay intact.
local one,two=encounter(100),encounter(100);two.ID='25';two.consumption={{'1','food','2'}};manager.validEncounters={one,two};manager:useTheDice();eq(manager.curEncounter,two);eq(costs[#costs][1],'food');eq(costs[#costs][2],2)
print('PASS encounter 0/20/100 thresholds, real CSV, single percentage draw, map/area/mission/frequency gates, selection and prebattle costs')
