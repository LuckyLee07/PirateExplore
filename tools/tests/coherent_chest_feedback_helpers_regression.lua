-- Execute actual currency methods with only in-memory storage and alert/toast sinks.
local function method(path,first,last)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close()
 local a=assert(s:find(first,1,true));local b=assert(s:find(last,a+#first,true))
 assert(loadstring(s:sub(a,b-1),'@'..path))()
end
WARM_PIRATE_V1=false -- This matrix pins the unchanged legacy alert path.
roleMapCoin='mapCoin';roleMoney='money';roleDiamond='diamond';BoldFont='fixture';WriteColor={}
local state,events,toasts,alerts={},{},{},0
local dm={};DataManager=dm;function dm:getInstance()return self end
function dm:getRoleData(key)return state[key]end
function dm:setRoleData(key,value,flag)state[key]=value;events[#events+1]=key..':'..value;assert(flag==nil)end
ExploreBagController={}
method('bin/res/scripts/LuaClass/ExploreBagController.lua','function ExploreBagController:addCoin(','function ExploreBagController:safeTransformCoinToPack(')
method('bin/res/scripts/LuaClass/DataManager.lua','function DataManager:addDiamond(','function DataManager:unlockTallentByKey(')
ToastUtil={downString=function(_,s)toasts[#toasts+1]=s;events[#events+1]='toast:'..s end}
AlertView={create=function()alerts=alerts+1;events[#events+1]='shortage';return{s_position={x=0,y=0},addChild=function()end}end}
cc={p=function()end,LabelTTF={create=function(_,s)return{setColor=function()end,setPosition=function()end,getContentSize=function()return{height=10}end}end}}
local function reset()state={money=30,mapCoin=0,diamond=10};events={};toasts={};alerts=0;return setmetatable({mapCoin=0},{__index=ExploreBagController})end
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function option(value)if value~='omitted' then return value end end
for _,flag in ipairs({'omitted',true,false})do
 for _,amount in ipairs({5,0,-3})do
  local bag=reset();bag:addCoin(amount,option(flag))
  eq(state.mapCoin,amount,'same map coin grant');eq(bag.mapCoin,amount,'same bag coin grant');eq(state.money,30,'no permanent coin credit')
  eq(events[1],'mapCoin:'..amount,'write precedes feedback');eq(#toasts,flag==false and 0 or 2,'coin success flag')
  if flag~=false then eq(toasts[1],'金币+'..amount,'original gain text');eq(toasts[2],'总共'..(30+amount)..'金币','original total text')end
  reset();eq(dm:addDiamond(amount,nil,option(flag)),1,'diamond success return')
  eq(state.diamond,10+amount,'same diamond arithmetic');eq(events[1],'diamond:'..(10+amount),'diamond writes before feedback')
  eq(#toasts,amount>0 and flag~=false and 1 or 0,'positive diamond feedback only');eq(alerts,0,'success has no shortage')
 end
 -- The new success flag never changes the original shortage-control argument.
 for _,showAlert in ipairs({'omitted',true,false})do
  reset();eq(dm:addDiamond(-11,option(showAlert),option(flag)),0,'shortage fails')
  eq(state.diamond,10,'shortage leaves balance');eq(#toasts,0,'shortage has no success toast');eq(alerts,showAlert==false and 0 or 1,'original shortage visibility')
  eq(#events,alerts,'shortage never writes')
 end
end
-- Existing two-argument use keeps its unconditional positive success feedback.
reset();dm:addDiamond(5,false);eq(toasts[1],'钻石+5','legacy false suppresses shortage only')
print('PASS actual currency helper matrix: omitted/true/false, positive/zero/negative, original shortage-control combinations, exact write-before-feedback and no permanent coin mutation')
