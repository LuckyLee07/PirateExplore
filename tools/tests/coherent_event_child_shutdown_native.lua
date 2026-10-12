-- Real Director lifecycle and original EventLayer -> EventDetailsLayer route.
-- In-memory economy only; never opens a window/profile/network/payment route.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
local dialogOverride=os.getenv('COHERENT_EVENT_DIALOG_SOURCE')
if dialogOverride then package.preload['LuaClass/WarmDialog']=function()return assert(loadfile(dialogOverride))()end end
local baseOverride=os.getenv('COHERENT_EVENT_BASE_SOURCE')
if baseOverride then package.preload['LuaClass/EventBaseView']=function()return assert(loadfile(baseOverride))()end end
local override=os.getenv('COHERENT_EVENT_OWNER_SOURCE')
if override then
 package.preload['LuaClass/EventLayer']=function()return assert(loadfile(override))()end
end
local source=read('tools/tests/coherent_event_pages_native.lua')
local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,sites=sites,resources=resources,bag=bag,roles=function()return roles end,
 seed=function(rows)roles={};black=rows end,
 state=function()return H.serialize({roles=roles,coin=coin,diamond=diamond,grants=grants,bagGrants=bagGrants,black=black})end,
 coin=function()return coin end,grants=function()return #bagGrants end,grant=function()return bagGrants[#bagGrants]end}
]],'@event-child-shutdown-fixture'))()
local H=F.H
cc.Director.getInstance=function()return setmetatable({
 getVisibleSize=function()return cc.size(480,800)end,getVisibleOrigin=function()return cc.p(0,0)end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local errors={};COHERENT_EVENT_CHILD_ERRORS=errors;__G__TRACKBACK__=function(e)errors[#errors+1]=tostring(_G.ACTIVE_CASE)..': '..e;print(debug.traceback(e));return e end
local assertions=0
local function check(ok,why)assertions=assertions+1;assert(ok,why)end
local function frames()for _=1,5 do local deadline=os.clock()+.002;while os.clock()<deadline do end;director:mainLoop()end end
local serial=0
local function fresh(empty,childFirst)
 H.fixture();local resource=F.resources['1005']
 local rows=empty and {}or{{id='1005',name=resource.name,icon=resource.iconName,num=5,costType='1',costs=12}}
 F.seed(rows);screenSize=cc.size(480,800);local scene=H.prepare(480,800)
 if director:getRunningScene()then director:replaceScene(scene)else director:runWithScene(scene)end
 frames()
 local owner=cc.Node:create();scene:addChild(owner)
 local manager=EventManger.new();owner:addChild(manager);manager.owner=owner;manager.costTool=nil
 owner.mapIndex=1;owner.bagController=F.bag
 local view=assert(EventLayer:create());manager:addChild(view);view:setController(manager);view:retain()
 view:refreshLayerByInfo(F.sites['3020'],false);view:show();view.buttons[1]:onSingleCLick()
 local child=assert(view.eventDetails);check(child.ownerEvent==view and child:getParent()==scene,'original entry owns native child')
 local seen={exits=0,cleanups=0,siblingExits=0};local witness=cc.Node:create();child:addChild(witness)
 witness:registerScriptHandler(function(e)if e=='exit'then seen.exits=seen.exits+1 elseif e=='cleanup'then seen.cleanups=seen.cleanups+1 end end)
 if childFirst then child:setLocalZOrder(-1);scene:sortAllChildren()end
 local sibling=cc.Node:create();scene:addChild(sibling)
 sibling:registerScriptHandler(function(e)if e=='exit'then seen.siblingExits=seen.siblingExits+1 end end)
 local controls={child.eventClose.item};if child.eventPrimary then controls[#controls+1]=child.eventPrimary.item end
 for _,control in ipairs(controls)do control:retain()end
 local leave=0;manager.anEventHasTriggered=function()leave=leave+1 end
 serial=serial+1;frames()
 check(view:isRunning() and child:isRunning(),'owner and child genuinely running')
 return {scene=scene,owner=owner,view=view,child=child,controls=controls,sibling=sibling,seen=seen,leave=function()return leave end,rows=rows}
end
local function finish(c)
 for _,item in ipairs(c.controls)do item:release()end
 c.view:release();director:replaceScene(cc.Scene:create());frames();H.finish();frames()
end
local c
if not os.getenv('COHERENT_EVENT_CHILD_ONLY_END')then
-- Explicit close still invokes the original leave exactly once.
c=fresh(false,false);local before=F.state();c.child:retain();c.child:close();c.child:close()
check(c.leave()==1,'normal close invokes original leave once');check(F.state()==before,'normal close preserves currency/stock')
c.child:release();finish(c)
-- Positive transaction boundary is unchanged: exact original price/quantity.
c=fresh(false,false);local coin,grants=F.coin(),F.grants();c.controls[2]:activate()
check(F.coin()==coin-12 and F.grants()==grants+1 and F.grant()[1]=='1005' and F.grant()[2]==5,'one original 12-coin market debit and five-item grant')
finish(c)
for _,empty in ipairs({false,true})do for _,childFirst in ipairs({false,true})do
 for _,path in ipairs({'owner_remove','owner_detach','child_remove','child_detach','replace','push_pop','cleanup'})do
  _G.ACTIVE_CASE=path..' '..tostring(empty)..' '..tostring(childFirst);c=fresh(empty,childFirst);local child=c.child
  local dialog
  if not empty then
   dialog=child:confirmCoherentEventAction(c.rows[1],1,'购买','生命周期检查',function()error('stale dialog committed')end)
   local item=dialog.warmOptions[1].item;item:retain();c.controls[#c.controls+1]=item
  end
  local unrelated=require('LuaClass/WarmDialog').show('其他窗口','不能清除无关窗口',{{label='取消'}},c.sibling)
  local before=F.state()
  if path=='owner_remove'then c.owner:removeFromParent(true)
  elseif path=='owner_detach'then c.owner:retain();c.owner:removeFromParent(false)
  elseif path=='child_remove'then child:removeFromParent(true)
  elseif path=='child_detach'then child:retain();child:removeFromParent(false)
  elseif path=='replace'then director:replaceScene(cc.Scene:create());frames()
  elseif path=='push_pop'then director:pushScene(cc.Scene:create());frames()
  else c.scene:cleanup()end
  check(c.view.eventDetails==nil,'owner child pointer clears immediately: '..path)
  for _,item in ipairs(c.controls)do item:activate()end
  check(F.state()==before and c.leave()==0,'stale close/buy never spends, grants or settles: '..path)
  if path=='push_pop'then director:popScene();frames();for _=1,2 do director:pushScene(cc.Scene:create());frames();director:popScene();frames()end
  elseif path=='owner_detach'then c.scene:addChild(c.owner);c.owner:release();frames()
  elseif path=='child_detach'then c.scene:addChild(child);child:release();frames()
  else frames()end
  check(F.state()==before and c.leave()==0,'queued work/reattach keeps exact economy and callbacks: '..path)
  if path~='replace' then check(c.sibling:getParent()==c.scene,'unrelated sibling preserved: '..path)end
  if path~='replace' and path~='push_pop' and path~='cleanup'then check(c.sibling.adventureDialog==unrelated and unrelated:isVisible(),'unrelated dialog remains owned and visible: '..path)end
  if path~='cleanup'then check(c.seen.exits>=1,'child descendants receive exit: '..path)end
  if path~='replace' and path~='push_pop' and path~='cleanup'then check(c.seen.siblingExits==0,'unrelated sibling never exits: '..path)end
  finish(c)
  print('PASS native event child '..path..' empty='..tostring(empty)..' childFirst='..tostring(childFirst))
 end
end end
end
check(#errors==0,table.concat(errors,'\n'))
if COHERENT_EVENT_CHILD_ENGINE_END then
 c=fresh(true,false);COHERENT_EVENT_CHILD_EXITED=0;COHERENT_EVENT_CHILD_CLEANED=0
 local function witness(parent)local n=cc.Node:create();parent:addChild(n);n:registerScriptHandler(function(e)if e=='exit'then COHERENT_EVENT_CHILD_EXITED=COHERENT_EVENT_CHILD_EXITED+1 elseif e=='cleanup'then COHERENT_EVENT_CHILD_CLEANED=COHERENT_EVENT_CHILD_CLEANED+1 end end)end
 witness(c.child);witness(c.sibling);local other=cc.Node:create();c.scene:addChild(other);witness(other)
 for _,item in ipairs(c.controls)do item:release()end;c.view:release();c.scene:release()
 -- No artificial retain of child or owner hides native vector invalidation.
end
print('PASS event child shutdown lifecycle assertions: '..assertions)
