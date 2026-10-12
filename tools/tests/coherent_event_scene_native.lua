-- Actual Cocos rendering with real decoded records; no GUI or persistent state.
local f=assert(io.open('tools/tests/coherent_event_pages_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('local families={}',1,true))
local T=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,sites=sites,controller=controller,inspect=inspect,bag=bag,W=W,
 roleFixture=function()roles={};roles[roleMapInfo]={mapIndex=2,curIndex=1};roles[roleArenaRecords]={}end,
 records=function(value)roles[roleArenaRecords]=value end}
]],'@event-scene-fixture'))()
local H,W=T.H,T.W;local S=require 'LuaClass/EventSceneIdentity'
local out=os.getenv('COHERENT_EVENT_SCENE_CAPTURE_DIR')or'/workspace/shared/pirate-audit/event-scene-identity'
local checks=0
local function check(ok,why)checks=checks+1;assert(ok,why)end
local function capture(view,w,h,name)
 T.inspect(view,w,h)
 local file=out..'/'..name..'-'..w..'x'..h
 check(coherentCapture(view,w,h,file..'.png'),'native capture')
 -- Force native non-stable re-sorts after arrival order was reset by visit.
 local nodes={}
 for _,root in ipairs({view,view.eventScene,view.buttonController,view.buttons[1],view.buttons[2]})do
  for i=1,28 do local n=cc.Node:create();root:addChild(n);nodes[#nodes+1]=n end
 end
 check(coherentCapture(view,w,h,file..'-dynamic-add.png'),'capture after dynamic children')
 for _,n in ipairs(nodes)do n:removeFromParent(true)end
 check(coherentCapture(view,w,h,file..'-dynamic-remove.png'),'capture after child removal')
end
check(S.resolve(T.sites['3108'],false).enemy=='10001','3108 exact original skeleton identity')
check(S.resolve(T.sites['3108'],true).enemy==nil,'occupied3108 never shows an enemy or supply')
check(S.resolve(T.sites['3053'],false).kind=='supply','same GID48 retains actual supply identity')
check(S.resolve({ID='3108',eventFucString='changeToSupplyPoint'},false)==nil,'mismatched ID/family cannot select art')
check(S.resolve(T.sites['3101'],true)==nil,'occupied unknown battle cannot become supply')
for _,size in ipairs({{360,640},{480,800},{640,960},{720,1280}})do
 local w,h=unpack(size);H.fixture();T.roleFixture();screenSize=cc.size(w,h);local scene=H.prepare(w,h)
 local view=assert(EventLayer:create());scene:addChild(view);view:setController(T.controller())
 for _,case in ipairs({{'3108','battle-entry'},{'3004','tavern-entry'},{'3053','supply-entry'},{'3067','resource-entry'},{'3002','worldchart-entry'},{'3003','resurrection-entry'},{'3020','blackmarket-entry'},{'3036','arena-entry'},{'3052','nextsea-entry'},{'3074','eternalarena-entry'}})do
  view:refreshLayerByInfo(T.sites[case[1]],false);view:show();capture(view,w,h,case[2])
  check(view.eventScene:isVisible(),'semantic scene visible')
  for _,button in ipairs(view.buttons)do if button:isVisible()then
   local z=button:getContentSize();local a=button:convertToWorldSpace(cc.p(0,0));local b=button:convertToWorldSpace(cc.p(z.width,z.height))
   check(a.x>=0 and a.y>=0 and b.x<=w and b.y<=h,'fixed core CTA remains completely in viewport')
  end end
  if case[1]=='3004'then check(view.eventSummary:getString()=='探险者 · 金币 300','actual recruitment identity and price')end
  if case[1]=='3053'then check(view.eventSummary:getString()==dataController.getResourceValueByIdAndKey('1005','name')..' × 7','actual current supply amount')end
 end
 view:refreshLayerByInfo(T.sites['3108'],false);view:getsAndSetsEnemyLayerInfoByEnemy({'10001'});capture(view,w,h,'battle-prepared')
 check(view.eventSceneModel.enemy=='10001','prepared exact enemy drives scene')
 view:showTipOccupiedLayer(T.sites['3108']);capture(view,w,h,'battle-occupied')
 check(view.eventSceneModel.occupied and not view.eventSceneModel.enemy,'occupied battle scene is clear')
 view:refreshLayerByInfo(T.sites['3053'],false)
 view.description:setString(string.rep('一个补给点。可以补充少量面包。',35));view:layoutCoherentEncounter()
 check(view.eventBody:getContentSize().height>=0,'native scroll exists')
 check(view.eventBody:getContainer():getContentSize().height>view.eventBody:getViewSize().height,'long prose scrolls')
 capture(view,w,h,'supply-long')
 local before=view.eventBody:getContentOffset().y
 coherentDescriptionDrag(view.eventBody,0)
 check(view.eventBody:getContentOffset().y~=before,'real scroll drag changes offset')
 capture(view,w,h,'supply-long-dragged')
 T.records({{costs={id='1005',num=2},level=10},{costs={id='1005',num=4},level=20},{costs={id='1005',num=6},level=30},{costs={id='1005',num=8},level=40}})
 view:refreshLayerByInfo(T.sites['3074'],false);view:show();capture(view,w,h,'eternal-checkpoints')
 check(view.eventScene:isVisible(),'checkpoint selection retains exact arena scene')
 check(view.scrollview:getViewSize().height>70,'native checkpoints retain usable height')
 view.selectArenaRecord(2)
 check(view.buttonTips[1]:getString()=='挑战第20关','original chosen level remains in fixed CTA')
 check(view.eventCost:getString()=='(需要4个'..dataController.getResourceValueByIdAndKey('1005','name')..')','selected checkpoint displays its exact original cost before prose')
 capture(view,w,h,'eternal-selected20')
 T.records({})
 view:refreshLayerByInfo(T.sites['3106'],false);capture(view,w,h,'other-family-fallback')
 check(not view.eventScene:isVisible(),'unreviewed identity keeps its existing page')
 check(view.eventBody:getViewSize().height==h-372,'reused scene restores full legacy body height')
 view:refreshLayerByInfo(T.sites['3108'],false);view:show();coherentEventEnter(scene,w,h)
 local b=view.buttons[1];local p=b:convertToWorldSpace(cc.p(b:getContentSize().width/2,30))
 local function gesture(phase,x)coherentEventGesture(phase,p.x+(x or 0),p.y)end
 local function tap()gesture(0);gesture(2)end
 local before=view.controller.triggered or 0
 gesture(0);gesture(3)
 check(not b.isTouch and b.normalSpr:isVisible() and not b.selectSpr:isVisible(),'native cancellation releases button visuals')
 check((view.controller.triggered or 0)==before,'native cancellation never activates')
 gesture(0);gesture(1,20);gesture(2,20)
 check((view.controller.triggered or 0)==before,'native drag cannot activate')
 tap();check(view.controller.triggered==before+1,'native primary dispatch retains original callback')
 tap();check(view.controller.triggered==before+1,'rapid native second tap is blocked')
 view.eventActionBusy=false;view:hide();tap();check(view.controller.triggered==before+1,'hidden event blocks retained native button')
 view:show();gesture(0);view:hide();gesture(2);check(view.controller.triggered==before+1,'hide during gesture cannot activate')
 view:show();gesture(0);view:refreshLayerByInfo(T.sites['3004'],false);gesture(3)
 check(view.eventDetails==nil,'cancel after event reuse does not open new service')
 H.finish();print('PASS native scene identity and layout '..w..'x'..h)
end
print('PASS '..checks..' scene identity/render/input assertions')
