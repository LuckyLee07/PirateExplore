-- Existing real encrypted settlement fixture + actual Explore return callback.
-- The result presenter is spied here; its Cocos lifecycle has a separate test.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/adventure_return_ui_transaction_audit.lua')
local stop=assert(source:find("for _,mode in ipairs({'free','scroll','diamond'})do",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {env=env,A=A,dm=dm,owner=owner,click=function()click()end,confirm=function()return confirm()end}','@return-result-fixture'))()
local R=require 'LuaClass/WarmReturnResult'
local M=require 'LuaClass/WarmMemories'
local dm,A,env=H.dm,H.A,H.env
local shown,transitions={},0
local originalShow=R.show
R.show=function(_,receipt,home)
    assert(home==zqDispatch.rightNode and transitions>0,'result is shown on the new Home after transition')
    shown[#shown+1]=receipt
end
gotoMainUI=function()transitions=transitions+1;zqDispatch={rightNode={warmHomePresentation=true}}end
local function eq(a,b,why)assert(a==b,(why or'')..': '..tostring(a)..' ~= '..tostring(b))end
local function canonical(value)
    if type(value)~='table'then return type(value)..':'..tostring(value)end
    local keys,out={},{};for key in pairs(value)do keys[#keys+1]=key end
    table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
    for _,key in ipairs(keys)do out[#out+1]=canonical(key)..'='..canonical(value[key])end
    return '{'..table.concat(out,';')..'}'
end
for _,mode in ipairs({'free','scroll','diamond'})do
    WARM_PIRATE_V1=true;shown={};transitions=0
    local map={curIndex=2};if mode~='free'then map.fristReturnBaseByTool='1'end
    env.fixture({[roleMapInfo]=map,[roleDiamond]=20})
    assert(A.depart(dm,{['1005']=10,['10100']=1}));assert(A.resolveEvent(dm,'rescue'))
    if mode=='scroll'then local bag=dm:getRoleData(roleBattlePack);bag['1015']={id='1015',num=2};dm:setRoleData(roleBattlePack,bag)end
    H.click();local before=env.disk();env.setFail(true);eq(H.confirm(),false)
    eq(#shown,0);eq(transitions,0);eq(env.disk(),before)
    env.reload();env.setFail(false);H.confirm();eq(#shown,1);eq(transitions,1)
    local result=shown[1];assert(result.committed and result.historyRecorded)
    eq(result.voyage,1);eq(result.memoryIds[1],M.ITEM_ID);eq(result.moneyDelta,25)
    eq(result.diamondDelta,mode=='diamond'and -8 or 0);eq(result.crewReturned,1)
    eq(result.stockDelta['1008'],2);eq(result.stockDelta['1006'],15);eq(result.stockDelta['1015'],nil)
    eq(M.get(dm).log[1].settlement.moneyDelta,result.moneyDelta)
    env.reload();before=canonical(json.decode(env.disk()));H.confirm();eq(#shown,1,'reentrant return cannot show or claim again');eq(canonical(json.decode(env.disk())),before)
end
print('PASS actual Explore free/scroll/diamond return shows only after saved transaction and new Home; failed/reentrant callbacks show nothing')
-- An old active voyage gets only its genuine just-committed net settlement.
WARM_PIRATE_V1=true;env.fixture();shown={}
dm:setRoleData(A.KEY,{version=1,enabled=true,voyage=8,activeVoyage=8,
    pending={voyage=8,episode='first',action='supply',choice='supply'}})
dm:setRoleData(roleBattlePack,{['1008']={id='1008',num=2}});dm:setRoleData(roleBattleQueue,{['100']=1})
H.owner:returnToBase();eq(#shown,1);eq(shown[1].historyRecorded,false);eq(#shown[1].memoryIds,0)
eq(shown[1].stockDelta['1008'],2);eq(dm:getRoleData(M.KEY),nil,'receipt cannot create historical records')
-- Suppression, preview isolation, rejected completion, and single-use token.
env.fixture();WARM_PIRATE_V1=false;shown={};assert(A.depart(dm,{['1005']=10,['10100']=1}))
H.owner:returnToBase();eq(#shown,0);eq(dm:getRoleData(M.KEY),nil)
WARM_PIRATE_V1=true;env.fixture();assert(A.depart(dm,{['1005']=10,['10100']=1}))
local token=R.before(dm,A.getState(dm));local before=env.disk()
eq(R.complete(dm,token,false),nil);eq(R.complete(dm,token,true),nil);eq(env.disk(),before)
assert(A.returnVoyage(dm,nil));local result=assert(R.complete(dm,token,true));eq(R.complete(dm,token,true),nil)
before=env.disk();result.stockDelta['1005']=9999;eq(env.disk(),before)
eq(R.before(dm,{enabled=false}),nil);eq(R.before(dm,A.getState(dm)),nil)
R.show=originalShow
print('PASS old active voyage uses honest transient receipt without backfill; disabled/legacy/rejected/completed tokens cannot invent results')
