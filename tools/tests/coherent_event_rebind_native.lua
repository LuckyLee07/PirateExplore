-- Independent read-only entry gesture tests; controlled fixtures only.
local f=assert(io.open('tools/tests/coherent_event_pages_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('local families={}',1,true))
local T=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,sites=sites,controller=controller,roleFixture=function()roles={};roles[roleMapInfo]={mapIndex=2,curIndex=1};roles[roleArenaRecords]={}end}
]],'@review-entry-gesture-fixture'))()
local H=T.H;local w,h=360,640;H.fixture();T.roleFixture();screenSize=cc.size(w,h);local scene=H.prepare(w,h)
local view=assert(EventLayer:create());scene:addChild(view);view:setController(T.controller());view:refreshLayerByInfo(T.sites['3108'],false);view:show();coherentEventEnter(scene,w,h)
local b=view.buttons[1];local p=b:convertToWorldSpace(cc.p(b:getContentSize().width/2,30))
local function g(phase)coherentEventGesture(phase,p.x,p.y)end
local failures=0
local function check(ok,msg) print((ok and 'PASS ' or 'FAIL ')..msg);if not ok then failures=failures+1 end end
-- The same native touch ID begins on battle, then ends after entry reuse.
g(0);view:refreshLayerByInfo(T.sites['3004'],false);g(2)
check(view.eventDetails==nil,'release after entry reuse must not activate newly rebound tavern callback')
g(0);g(2)
check(view.eventDetails~=nil,'fresh gesture after rejected rebind still opens current tavern')
view:dismissEventDetails();view.eventActionBusy=false
view:refreshLayerByInfo(T.sites['3108'],false);view:show();local before=view.controller.triggered or 0
g(0);view:hide();view:show();g(2)
check((view.controller.triggered or 0)==before,'release after hide/show must not activate retained callback')
H.finish();assert(failures==0,tostring(failures)..' independent gesture checks failed')
