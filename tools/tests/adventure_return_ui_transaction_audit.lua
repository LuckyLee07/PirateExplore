local f=assert(io.open('tools/tests/adventure_state_audit.lua'));local harness=f:read('*a');f:close()
harness=assert(harness:match('^(.-)\nfixture%(%{%[roleGuideStep%]'))
local env=assert(loadstring(harness..'\nreturn {A=A,dm=dm,fixture=fixture,reload=reload,setFail=function(v)fail=v end,disk=function()return disk end}'))()
local A,dm=env.A,env.dm
csvOfStrongholdDistribution='areas';csvOfShopItem='shops'
local originalCSV=dm.getCSVByID
function dm:getCSVByID(k)
 if k=='areas' then return {['2']={gohome='1015_2'}} end
 if k=='shops' then return {['7']={price='8'}} end
 local r=originalCSV(self,k);r['1015']={carryType='2',cubage=0,shop_connect='7',name='scroll'};return r
end
function dm:setRoleData(k,v) self.__roleData:setRoleData(k,v);self.__roleData:saveData()end
function dm:sendSystemInfo()end
DataManager={getInstance=function()return dm end}
ToastUtil={toastString=function()end};FightDataManager={getInstance=function()return {clearAllData=function()end}end};EternalArenaController={getInstance=function()return {destoryEternalArenaController=function()end}end};clearAllTouchArgs=function()end;gotoMainUI=function()end
local file=assert(io.open('bin/res/scripts/LuaClass/Explore.lua'));local source=file:read('*a');file:close()
Explore={}
local returnFn=assert(source:match('(function Explore:returnToBase%(%s*statue.-)\nend'))..'\nend'
assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\n"..returnFn))()
local snippet=assert(source:match('(local backBtn = button%("返航".-)\n    self.adventureReturnButton'))
local bind=assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\nreturn function(self,button) "..snippet..' end'))()
local confirm,click
package.loaded['LuaClass/AdventureDialog']={show=function(_,_,options)confirm=options[1].action end}
local owner=setmetatable({mapIndex=2,moveLayer={stopAllActions=function()end},getbackObjectStr=function()return 'cargo'end,bagController={destoryController=function()end}}, {__index=Explore})
bind(owner,function(_,a,b,c,d,cb)click=cb;return {}end)
for _,mode in ipairs({'free','scroll','diamond'})do
 local map={curIndex=2};if mode~='free' then map.fristReturnBaseByTool='1'end
 env.fixture({[roleMapInfo]=map,[roleDiamond]=20})
 assert(A.depart(dm,{['1005']=10,['10100']=1}))
 if mode=='scroll' then local p=dm:getRoleData(roleBattlePack);p['1015']={id='1015',num=1};dm:setRoleData(roleBattlePack,p);local stock=dm:getRoleData(rolePack);stock['1015']=2;dm:setRoleData(rolePack,stock)end
 click();local before=env.disk();env.setFail(true);assert(confirm()==false,'failed transaction must keep dialog open');assert(env.disk()==before);env.reload()
 assert(dm:getRoleData(roleDiamond)==20 and A.getState(dm).activeVoyage)
 assert((dm:getRoleData(roleMapInfo).fristReturnBaseByTool~=nil)==(mode~='free'))
 env.setFail(false);confirm();env.reload();assert(not A.getState(dm).activeVoyage)
 assert(dm:getRoleData(roleDiamond)==(mode=='diamond' and 12 or 20))
 if mode=='scroll' then assert(dm:getRoleData(rolePack)['1015']==1)end
 local before=env.disk();confirm();env.reload();assert(dm:getRoleData(roleDiamond)==(mode=='diamond' and 12 or 20));if mode=='scroll' then assert(dm:getRoleData(rolePack)['1015']==1)end
 print('PASS actual UI callback -> actual Explore return -> real transaction: '..mode..' save failure, cold reload retry, duplicate callback')
end
local f=assert(io.open('bin/res/scripts/LuaClass/EventManger.lua'));local source=f:read('*a');f:close()
EventManger={};local fn=assert(source:match('(function EventManger:allMembersKilled%(%s*%).-)\nend'))..'\nend';assert(loadstring(fn))()
env.fixture({[roleMapInfo]={curIndex=2,willFight=1,playerTitlePosition={x=3,y=4}}});assert(A.depart(dm,{['1005']=10,['10100']=1}))
owner.addDeadData=function()return A.failVoyage(dm,{{id='100',num=1}})end
local event={owner=owner};local before=env.disk();env.setFail(true);EventManger.allMembersKilled(event);assert(env.disk()==before);env.reload();assert(dm:getRoleData(roleMapInfo).willFight==1 and dm:getRoleData(roleBattleQueue)['100']==1)
env.setFail(false);EventManger.allMembersKilled(event);env.reload();assert(dm:getRoleData(roleMapInfo).willFight==nil and next(dm:getRoleData(roleBattleQueue))==nil)
print('PASS actual battle-death upstream callback cannot pre-clear cold-start battle retry state before failed death transaction')
