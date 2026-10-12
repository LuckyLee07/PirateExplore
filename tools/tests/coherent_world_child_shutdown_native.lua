-- Real original world-selector sibling: native purge/removal, no GUI or saves.
local selectorOverride=os.getenv('COHERENT_WORLD_SELECTOR_SOURCE')
if selectorOverride then package.preload['LuaClass/WorldChartSelector']=function()return assert(loadfile(selectorOverride))()end end
local override=os.getenv('COHERENT_EVENT_OWNER_SOURCE')
if override then package.preload['LuaClass/EventLayer']=function()return assert(loadfile(override))()end end
local errors={};COHERENT_EVENT_CHILD_ERRORS=errors
__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local originalGet=cc.Director.getInstance;local director=originalGet(cc.Director)
function coherentEventEnter(scene)
 if director:getRunningScene()then director:replaceScene(scene)else director:runWithScene(scene)end
 for _=1,5 do local t=os.clock()+.002;while os.clock()<t do end;director:mainLoop()end
end
local f=assert(io.open('tools/tests/world_chart_selector_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {fresh=fresh,scene=function()return scene end,event=function()return event end,state=function()return H.serialize(T.roles())..':'..tostring(T.diamonds())..':'..tostring(T.writes())end}
]],'@selector-native-purge'))()
local chart=F.fresh(480,800,2,2,3,7,2);local scene=F.scene();local event=F.event()
assert(chart:isRunning() and event:isRunning(),'actual running original selector route')
if os.getenv('SELECTOR_FIRST')then chart:setLocalZOrder(-1);scene:sortAllChildren()end
COHERENT_EVENT_CHILD_EXITED=0;COHERENT_EVENT_CHILD_CLEANED=0
local function witness(parent)
 local n=cc.Node:create();parent:addChild(n)
 n:registerScriptHandler(function(e)
  if e=='exit'then COHERENT_EVENT_CHILD_EXITED=COHERENT_EVENT_CHILD_EXITED+1
  elseif e=='cleanup'then COHERENT_EVENT_CHILD_CLEANED=COHERENT_EVENT_CHILD_CLEANED+1 end
 end)
end
witness(chart)
for _=1,2 do local sibling=cc.Node:create();scene:addChild(sibling);witness(sibling)end
local mode=os.getenv('SELECTOR_PATH')or'purge';local before=F.state()
if mode=='detach'then
 local S=require('LuaClass/WorldChartSelector');local calls=0
 for _=1,3 do
  local modal=S.modal(chart,'检查','确认不能跨越卸载','确认',function()calls=calls+1 end);local stale=modal.worldAccept
  chart:removeFromParent(false);stale();assert(calls==0 and chart.worldSuspended and event.worldMapLayer==chart,'detached selector invalidates stale confirmation but preserves ownership')
  scene:addChild(chart);for _=1,5 do director:mainLoop()end
  assert(S.ready(chart) and not chart.worldDisposed,'cleanup-free selector reentry remains supported');stale();assert(calls==0,'old confirmation stays invalid after reentry')
 end
 COHERENT_EVENT_CHILD_EXITED=0
elseif mode=='child'then
 chart:removeFromParent(true);chart:release();assert(event.worldMapLayer==nil,'destroyed selector clears exact owner pointer');event:removeFromParent(true)
elseif mode=='owner'then
 event:retain();event:removeFromParent(true)
 assert(event.worldMapLayer==nil and chart.worldDisposed and not chart:isVisible(),'immediate selector retirement')
 for _=1,5 do director:mainLoop()end
 assert(chart:getParent()==nil,'safe deferred selector removal')
 event:release()
elseif mode=='replace'then
 director:replaceScene(cc.Scene:create());for _=1,5 do director:mainLoop()end
 assert(not chart:isRunning() and chart.worldDisposed,'replacement retires selector')
elseif mode=='push_pop'then
 for _=1,3 do director:pushScene(cc.Scene:create());for _=1,5 do director:mainLoop()end;director:popScene();for _=1,5 do director:mainLoop()end end
 assert(chart:isRunning() and not chart.worldDisposed and chart.owner==event,'ordinary selector push/pop stays resumable')
 -- Each preserved node legitimately exited three additional times. The C++
 -- final-purge check counts only the terminal exit, and all cleanup calls.
 COHERENT_EVENT_CHILD_EXITED=0
end
assert(F.state()==before,'selector lifecycle preserves exact role/currency/write state')
assert(#errors==0,table.concat(errors,'\n'))
if mode~='child'then chart:release()end;scene:release()
print('PASS selector owner lifecycle '..mode)
print('READY unretained genuine selector purge; selectorFirst='..tostring(os.getenv('SELECTOR_FIRST')))
