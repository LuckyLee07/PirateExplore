-- Real Cocos/EGL failure sheet on Home. No player save, battle or purchase.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {check=check,equal=equal,serialize=serialize,dm=dm,fixture=fixture,getData=function()return data end,
 setViewport=function(w,h)viewport=cc.size(w,h)end,fresh=fresh,finish=finish,
 visit=visit,labelsWithin=labelsWithin,failures=failures,realGet=realGet,
 setRecovery=function(v)recoveryUnlocked=v end,getRoutes=function()return routes end}
]],'@native-failure-result-fixture'))()
local F=require 'LuaClass/WarmFailureResult'
local function result(reason,history,long)
 local r={committed=true,voyage=2,reason=reason,lostCrew=1,lostCargo={['1005']=7,['1008']=2},
  missionCargo={['1999']=3},mapCoinsLost=11,historyRecorded=history}
 if long then for id=1100,1160 do r.lostCargo[tostring(id)]=id-1000 end end
 return r
end
local function contains(root,text)
 local found=false;H.visit(root,function(n)if n.getString and n:getString():find(text,1,true)then found=true end end);return found
end
for _,size in ipairs({{480,800},{640,960},{640,1136}})do
 H.setViewport(size[1],size[2])
 for _,reason in ipairs({'Killed','NoBread'})do
  H.fixture();local home=H.fresh();local before=H.serialize(H.getData())
  local r=result(reason,true,true);local layer=assert(F.show(H.dm,r,home));layer:retain()
  assert(F.show(H.dm,r,home)==layer and home:blocked(),'single outcome blocks background Home actions')
  home:openActivity('crew');assert(home.warmActivity==nil,'queued background action cannot click through result')
  assert(contains(layer,'本次结算失去伙伴 1 人'));assert(contains(layer,'伙伴已计入复活记录，可在复活据点查看。'))
  assert(contains(layer,reason=='NoBread'and '补给耗尽，航程结束'or '本次航程失利'))
  assert(contains(layer,'任务物品例外按原规则处理。'))
  H.labelsWithin(layer,'Failure '..reason..' '..size[1]..'x'..size[2])
  local oldNext=assert(layer.buttons.next);oldNext:retain();oldNext.item:activate();assert(layer.page==2)
  oldNext.item:activate();assert(layer.page==2,'stale page action is inert');oldNext:release()
  local calls=0;home.openPrimary=function(self)assert(self.warmReturnResult==nil);calls=calls+1 end
  local prepare=layer.buttons.prepare;prepare:retain();prepare.item:activate();prepare.item:activate()
  assert(calls==1 and layer.closed and home.warmReturnResult==nil,'onward route closes first and only runs once')
  assert(F.show(H.dm,r,home)==nil,'closed outcome cannot replay')
  assert(H.serialize(H.getData())==before,'show/page/prepare never changes saved fields')
  prepare:release();layer:release();H.finish(home)
 end
 -- Genuine log route and Home teardown are separate from preparation.
 H.fixture();local home=H.fresh();local before=H.serialize(H.getData());local logs=0
 home.openActivity=function(self,kind)assert(self.warmReturnResult==nil and kind=='log');logs=logs+1 end
 local layer=assert(F.show(H.dm,result('Killed',true,false),home));layer:retain()
 local log=layer.buttons.log;log:retain();log.item:activate();log.item:activate();assert(logs==1)
 log:release();layer:release();H.finish(home)
 H.fixture();home=H.fresh();before=H.serialize(H.getData())
 layer=assert(F.show(H.dm,result('NoBread',false,false),home));layer:retain()
 assert(layer.buttons.log==nil and contains(layer,'不补写旧航程'),'missing history does not fabricate a log route')
 H.finish(home);assert(layer.closed and home.warmReturnResult==nil,'owner cleanup disposes failure layer')
 layer:close();assert(H.serialize(H.getData())==before,'owner cleanup never writes');layer:release()
 print('PASS native failure '..size[1]..'x'..size[2]..': actual Home blocking, typography, both reasons, pagination, preparation/log/exit guards and zero writes')
end
-- Use the real Home primary handler as well: empty crews go to recovery,
-- while a supplied harbor goes to preparation. Neither branch starts sailing.
H.setViewport(480,800);H.fixture();H.setRecovery(true)
local data=H.getData();data[roleSoildierQueue]={};data[roleSelectUnit]={}
local home=H.fresh();local before=H.serialize(data)
local layer=assert(F.show(H.dm,result('Killed',false,false),home));layer:retain()
layer.buttons.prepare.item:activate()
assert(home.warmActivity and home.warmActivity.kind=='crew','actual Home handler routes empty fleet into recovery')
assert(H.serialize(data)==before,'recovery handoff performs no save or recruitment')
layer:release();H.finish(home)
H.fixture();home=H.fresh();before=H.serialize(H.getData())
layer=assert(F.show(H.dm,result('NoBread',false,false),home));layer:retain()
local routes=H.getRoutes();local count=#routes
layer.buttons.prepare.item:activate()
assert(#routes==count+1 and routes[#routes]==1,'actual supplied Home handler routes to preparation, not automatic departure')
assert(H.serialize(H.getData())==before)
layer:release();H.finish(home)
print('PASS actual state-responsive Home continuation: empty fleet recovery and supplied fleet preparation, zero writes')
cc.Director.getInstance=H.realGet
assert(#H.failures==0,table.concat(H.failures,'\n'))
print('PASS coherent failed-voyage continuity; no losses or reward transaction in presentation')
