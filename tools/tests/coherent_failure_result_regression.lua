-- Real encrypted settlement fixture and the exact production Explore failure
-- callback. Presenter is spied; native lifecycle/zero-write checks are separate.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/adventure_return_ui_transaction_audit.lua')
local stop=assert(source:find("for _,mode in ipairs({'free','scroll','diamond'})do",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {env=env,A=A,dm=dm,owner=owner}','@coherent-failure-fixture'))()
local F=require 'LuaClass/WarmFailureResult'
local M=require 'LuaClass/WarmMemories'
local dm,A,env=H.dm,H.A,H.env
local production=read('bin/res/scripts/LuaClass/Explore.lua')
local deathFunction=assert(production:match('(function Explore:addDeadData%(%s*%)%s*.-)\nfunction Explore:getbackObjectStr'))
assert(loadstring("local AdventureProgress=require 'LuaClass/AdventureProgress'\n"..deathFunction))()
dataController={getSoilderInfoById=function()return {name='fixture',hp=10,attack=2,star=1,speed=1,skill='1',icon='fixture',rebornConsume={{'1001','2'}}}end,
 getSkillValueByIdAndKey=function()return 'fixture skill'end,getResourceValueByIdAndKey=function()return 'coin'end}
local shown,transitions={},0
local originalShow=F.show
F.show=function(_,result,home)
 assert(transitions>0 and home==zqDispatch.rightNode,'failure appears only after new Home transition')
 assert(dm:getRoleData(roleStatue)==0 and not A.getState(dm).activeVoyage,'failure follows confirmed saved terminal state')
 assert(next(dm:getRoleData(roleBattlePack))==nil and next(dm:getRoleData(roleBattleQueue))==nil)
 assert((dm:getRoleData(roleDeathInformation)or{})[1].num==3,'real death record is committed before presentation')
 shown[#shown+1]=result
end
gotoMainUI=function()transitions=transitions+1;zqDispatch={rightNode={warmHomePresentation=true}}end
local function canonical(v)
 if type(v)~='table'then return type(v)..':'..tostring(v)end
 local keys,out={},{};for k in pairs(v)do keys[#keys+1]=k end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 for _,k in ipairs(keys)do out[#out+1]=canonical(k)..'='..canonical(v[k])end
 return '{'..table.concat(out,';')..'}'
end
for _,reason in ipairs({'Killed','NoBread'})do
 WARM_PIRATE_V1=true;shown={};transitions=0
 env.fixture({[roleDeathInformation]={{id='100',num=2}},[roleMapCoin]=11})
 assert(A.depart(dm,{['1005']=10,['10100']=1}))
 dm:setRoleData(roleBattlePack,{['1005']={id='1005',num=7},['1008']={id='1008',num=2},['1999']={id='1999',num=3}})
 dm:setRoleData(roleMapCoin,11)
 H.owner.playerfighters={{id='100',num=1}}
 H.owner.bagController.battlePackData=dm:getRoleData(roleBattlePack);H.owner.bagController.mapCoin=11
 local before=env.disk();env.setFail(true);H.owner:returnToBase(reason)
 assert(#shown==0 and transitions==0 and env.disk()==before,'failed loss commit produces no result or transition')
 env.reload();env.setFail(false);H.owner:returnToBase(reason)
 assert(#shown==1 and transitions==1)
 local result=shown[1]
 assert(result.committed and result.reason==reason and result.voyage==1 and result.historyRecorded)
 assert(result.lostCrew==1 and result.lostCargo['1005']==7 and result.lostCargo['1008']==2)
 assert(result.missionCargo['1999']==3 and result.lostCargo['1999']==nil and result.mapCoinsLost==11)
 assert(dm:getRoleData(rolePack)['1999']==3 and dm:getRoleData(rolePack)['1005']==90,'original mission exception and ordinary loss retained')
 assert(M.get(dm).lastResult.outcome=='failed'and #M.get(dm).lastResult.memoryIds==0)
 before=canonical(json.decode(env.disk()));H.owner:returnToBase(reason)
 assert(#shown==1 and canonical(json.decode(env.disk()))==before,'repeated failure callback cannot show or settle twice')
 print('PASS production '..reason..': save failure stays at sea; real atomic loss and mission exceptions precede single outcome on new Home')
end
-- The snapshot and completion APIs are read-only and reject incomplete state.
env.fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}))
local before=env.disk();local token=assert(F.before(dm,A.getState(dm),'Killed'))
assert(env.disk()==before and F.complete(dm,token,false)==nil and F.complete(dm,token,true)==nil)
assert(A.failVoyage(dm,{{id='100',num=1}}));before=env.disk()
local result=assert(F.complete(dm,token,true));assert(F.complete(dm,token,true)==nil and env.disk()==before)
result.lostCargo['1005']=999;assert(env.disk()==before,'result cannot alias saved cargo')
assert(F.before(dm,A.getState(dm),'Killed')==nil)
assert(F.before(dm,{enabled=false,version=1,activeVoyage=1},'Killed')==nil)
assert(F.before(dm,{enabled=true,version=1,activeVoyage=1},'normal')==nil)
WARM_PIRATE_V1=false
assert(F.before(dm,{enabled=true,version=1,activeVoyage=1},'Killed')==nil)
F.show=originalShow
print('PASS failure result capture/completion are zero-write, single-use, legacy/disabled/normal-return-safe')
