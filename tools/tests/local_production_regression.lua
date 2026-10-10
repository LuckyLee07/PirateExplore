-- Synthetic time/seed fixtures only. Never reads or writes a player profile.
package.path = 'bin/res/scripts/?.lua;' .. package.path
local P = require 'LuaClass/LocalProduction'
local function equal(a,b,why) assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local recipes = {
 ['1']={resume={{'0'}},produce={{'1004','1'}}},
 ['2']={resume={{'1004','2'}},produce={{'1005','1'}}},
 ['3']={resume={{'1005','1'}},produce={{'1007','3'}}},
 ['8']={resume={{'1009','1'}},produce={{'1001','11'}}},
 ['9']={resume={{'1001','4'}},produce={{'1016','1'}}},
 ['10']={resume={{'1016','3'},{'1006','1'}},produce={{'1013','1'}}},
}
local function input()
 return {now=1000,gameTime=1000,cd=20,cap=3600,pack={},money=0,recipes=recipes,
 workers={{id='1',num=2},{id='2',num=1}},idKey='id',numKey='num',nextTime=0}
end
local x=input();local first=P.calculate(x)
equal(first.cycles,0,'migration grants nothing');equal(first.ledger.wall,1000);equal(first.ledger.remaining,20)
x.ledger=first.ledger;x.now=1060;x.gameTime=1001
local a=P.calculate(x);equal(a.cycles,3);equal(a.pack['1005'],3);equal(a.pack['1004'],0)
equal(a.nextTime,1021,'voyage clock remains independent');equal(x.pack['1005'],nil,'no input mutation')
x.pack=a.pack;x.money=a.money;x.ledger=a.ledger
local b=P.calculate(x);equal(b.cycles,0,'same-time cold restart');equal(b.pack['1005'],3)
print('PASS local migration, real 2-farmer/1-cook cycle chain, 60-second fixture, cold-restart idempotence, independent voyage time')
x=input();x.ledger={wall=1000,remaining=7};x.now=1010
local phase=P.calculate(x);equal(phase.cycles,1);equal(phase.ledger.remaining,17)
x.pack=phase.pack;x.ledger=phase.ledger;x.now=1026;equal(P.calculate(x).cycles,0)
x.now=1027;equal(P.calculate(x).cycles,1)
x=input();x.ledger={wall=1000,remaining=20};x.now=1000+99999999
for _,cap in ipairs({3600,7200,14400,21600,28800,36000,43200}) do
 x.cap=cap;local r=P.calculate(x);equal(r.cycles,cap/20,'purchased offline cap');equal(r.pack['1005'],cap/20)
end
x.cap=1e12;equal(P.calculate(x).cycles,43200/20,'corrupt duration bounded by highest shipped entitlement')
print('PASS fractional cycle carries once; huge forward jump obeys every 1/2/4/6/8/10/12-hour entitlement')
x=input();x.ledger={wall=2000,remaining=20};equal(P.calculate(x).cycles,0,'rollback');
x.ledger={wall=0/0,remaining=20};equal(P.calculate(x).cycles,0,'invalid timestamp')
x.ledger={wall=1000,remaining=math.huge};equal(P.calculate(x).cycles,0,'invalid phase')
x=input();x.ledger={wall=1000,remaining=20};x.now=1060;x.workers={{id='3',num=5}};x.pack={['1005']=2}
local r=P.calculate(x);equal(r.pack['1005'],0);equal(r.pack['1007'],6)
x.workers={{id='10',num=2}};x.pack={['1016']=9,['1006']=1};r=P.calculate(x)
equal(r.pack['1016'],6);equal(r.pack['1006'],0);equal(r.pack['1013'],1)
x.workers={{id='8',num=1},{id='9',num=2}};x.pack={['1009']=1};r=P.calculate(x)
equal(r.money,3);equal(r.pack['1016'],2)
print('PASS rollback/future/corrupt timestamps migrate safely, scarce multi-input recipes stay nonnegative, coin dependency chain')
-- Load the real transaction implementation with a mocked disk, not a real save.
for _,name in ipairs({'LuaClass/Header','LuaClass/Utils','LuaClass/SaveDataManager','json','LuaClass/simplejson.lua'}) do package.loaded[name]={} end
class=function() return {} end
local disk, writes, fail = nil,0,false
json={encode=function(t) return t end}
SaveDataManager={getInstance=function(self) return self end,
 saveDataAtomic=function(self,t) writes=writes+1;if fail then return false end;disk=t;return true end,
 SaveData=function(self,t) disk=t end}
dofile('bin/res/scripts/LuaClass/UserData.lua')
local fields={pack={['1005']=3},money=7,[P.KEY]={wall=1060,remaining=20}}
assert(UserData:commitLocalProduction(fields));equal(disk.pack['1005'],-3);equal(disk.money,-7)
fail=true;assert(not UserData:commitLocalProduction({pack={['1005']=99},money=99}));UserData:saveData()
equal(disk.pack['1005'],-3,'failed save cannot publish candidate');equal(disk[P.KEY].wall,-1060)
fail=false;assert(UserData:commitLocalProduction({money=8}));equal(disk.pack['1005'],-3);equal(disk.money,-8)
print('PASS actual UserData transaction keeps existing encoding, writes one complete snapshot, rejects failed candidate without moving ledger')
