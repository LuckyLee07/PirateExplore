-- Native component test. Actual battle constructors and zero-HP transition;
-- isolated in-memory fixtures, no player profile, GUI or platform purchase.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_battle_stage_native.lua')
local stop=assert(source:find('for _,size in ipairs({{480,800}',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {fresh=fresh,walk=walk,step=step,H=H,dm=dm,fdm=fdm,eq=eq,errors=callbackErrors}
]],'@recovery-production-battle-fixture'))()
local fixture=H.H;local dm=H.dm;local R=require 'LuaClass/WarmBattleRecovery'
local realDirector=fixture.realGet(cc.Director)
local calls,charges,attempts,gifts,balance=0,0,0,0,0
local shortage,routePresent=false,true
local originalDiamond=dm.addDiamond
local originalRoleRead=dm.getRoleData
dm.getRoleData=function(self,key)if key==roleDiamond then return balance end;return originalRoleRead(self,key)end
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
ToastUtil.toastString=function(_,s)_G.recoveryToast=s end
getExplor=function()if routePresent then return {eventManger={layer={safeBackToLayer=function()calls=calls+1 end}}}end end
PushGiftView={create=function()
 gifts=gifts+1;local gift=cc.Layer:create()
 function gift:show()cc.Director:getInstance():getRunningScene():addChild(self,801)end
 function gift:close()self:removeFromParent(true)end
 return gift
end}
dm.addDiamond=function(_,delta,force)
 eq(delta,-50,'unchanged revival price');eq(force,true,'unchanged shortage presentation flag');attempts=attempts+1
 if balance<50 then
  shortage=cc.Layer:create();shortage.isAdventureModal=true
  cc.Director:getInstance():getRunningScene():addChild(shortage,3000);return 0
 end
 balance=balance-50;charges=charges+1;return 1
end
local function capture(root,size,name)
 if coherentCapture and os.getenv('COHERENT_BATTLE_CAPTURE_DIR')then
  assert(coherentCapture(root,size[1],size[2],os.getenv('COHERENT_BATTLE_CAPTURE_DIR')..'/'..name..'-'..size[1]..'x'..size[2]..'.png'))
 end
end
local function tap(b)if coherentMenuTap then coherentMenuTap(b.item)else b.item:activate()end end
local function fail(size,boarding,eternal)
 local v=H.fresh(size,boarding,1,1)
 v.fightFailType=eternal and FightScene.FightFailType.eternal or FightScene.FightFailType.normal
 v.fightOverCallback=function(result)eq(result,false,'original false defeat callback');calls=calls+1 end
 v.beginUpdateTime=100;v.aboardProsb={0};v.buffers={}
 for _,f in ipairs(v.playerTeam.fighters)do f.hp=0 end;v:calculateTeamHpAndRunAction();H.step(v,0);H.step(v,.11)
 v:update(0);assert(v.isPause and v.warmRecoveryState,'real zero HP update opens warm recovery')
 local layer=assert(v.warmRecoveryState.ui);eq(R.choice(v),layer,'duplicate prompt is inert')
 return v,layer
end
local function geometry(layer,size)
 local visible=0
 fixture.visit(layer,function(n,show)
  if show and n.getString and n:getString()~=''then
   visible=visible+1;local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=size[1]+1,'text horizontal: '..n:getString());assert(a.y>=-1 and b.y<=size[2]+1,'text vertical: '..n:getString())
   if n.getFontName then eq(n:getFontName(),require('LuaClass/WarmTheme').font,'clean shared font')end
  end
 end);assert(visible>4,'actual labels rendered')
end
for _,size in ipairs({{360,640},{480,800}})do
 for _,boarding in ipairs({true,false})do
  calls=0;charges=0;attempts=0;gifts=0;balance=0;routePresent=true
  local v,choice=fail(size,boarding);assert(not choice.reviveAffordable,'shortage is clearly unavailable');eq(choice.buttons.revive.label:getString(),'钻石不足 · 查看说明','shortage cannot look like affordable revival');geometry(choice,size);capture(v,size,boarding and 'revive-boarding' or 'revive-cannon')
  choice:retain();local old=choice.buttons['return'].item;old:retain()
  tap(choice.buttons.revive);eq(attempts,1,'shortage reaches original debit once');eq(charges,0,'no insufficient spend');eq(calls,0,'no insufficient revival')
  choice.buttons.revive.item:activate();choice.buttons['return'].item:activate();eq(attempts,1,'underlying revive blocked by shortage');eq(v.warmRecoveryState.ui,choice,'underlying decline blocked by shortage')
  shortage:removeFromParent(true);shortage=nil
  tap(choice.buttons['return']);local result=assert(v.warmRecoveryState.ui);assert(result~=choice and choice.closed,'decline moves to loss scene')
  eq(calls,0,'decline does not settle early');old:activate();eq(v.warmRecoveryState.ui,result,'stale decline cannot replace result')
  geometry(result,size);capture(v,size,boarding and 'defeat-boarding' or 'defeat-cannon')
  eq(R.result(v),result,'duplicate result inert')
  result:retain();local returnItem=result.buttons['return'].item;returnItem:retain()
  tap(result.buttons.gift);eq(gifts,1,'optional gift opened');result.buttons.gift.item:activate();result.buttons['return'].item:activate();eq(gifts,1,'rapid gift does not stack');eq(calls,0,'return blocked beneath gift')
  v.warmRecoveryState.gift:close();tap(result.buttons.gift);eq(gifts,2,'closed gift can reopen');v.warmRecoveryState.gift:close()
  tap(result.buttons['return']);eq(calls,1,'original loss callback once');returnItem:activate();eq(calls,1,'rapid return is inert')
  fixture.finish();returnItem:activate();old:activate();eq(calls,1,'disposed owner stale callbacks inert');returnItem:release();old:release();choice:release();result:release()
  -- Sufficient diamonds: preserve original safeBackToLayer, do not settle loss.
  calls=0;charges=0;attempts=0
  v,choice=fail(size,boarding);balance=75;routePresent=true;choice:refreshAffordance();assert(choice.reviveAffordable);eq(choice.buttons.revive.label:getString(),'50 钻石复活','affordable exact cost caption')
  choice:retain();local paid=choice.buttons.revive.item;paid:retain()
  tap(choice.buttons.revive);eq(balance,25,'exact 50-diamond debit');eq(charges,1,'one debit');eq(calls,1,'original safe return once');assert(choice.closed and v.warmRecoveryState.done)
  paid:activate();eq(charges,1,'stale paid click inert');eq(calls,1,'no duplicate navigation');eq(R.result(v),nil,'cannot show death after revival')
  fixture.finish();paid:release();choice:release()
  -- Missing original event route must never charge a stale battle.
  v,choice=fail(size,boarding);routePresent=false;balance=50;attempts=0
  tap(choice.buttons.revive);eq(attempts,0,'missing original target is checked before debit');eq(balance,50,'missing route has no spend');assert(recoveryToast)
  fixture.finish();routePresent=true
 end
 print('PASS '..size[1]..'x'..size[2]..' actual ship/boarding zero-HP, shortage modal, gift close/reopen, return, 50-diamond revive and stale targets')
end
-- Both boundaries and a stale displayed balance are validated at the tap.
calls=0;charges=0;attempts=0;balance=49;routePresent=true
local boundary,choice=fail({360,640},true);assert(not choice.reviveAffordable)
eq(choice.buttons.revive.label:getString(),'钻石不足 · 查看说明','49 cannot advertise affordable revive')
tap(choice.buttons.revive);eq(balance,49,'49 never charged');eq(charges,0,'49 has no debit');shortage:removeFromParent(true);shortage=nil
balance=50
if coherentCapture then
 for _=1,4 do local untilTime=os.clock()+.003;while os.clock()<untilTime do end;realDirector:drawScene()end
else choice:refreshAffordance()end
assert(choice.reviveAffordable,'live scheduled balance watcher updates the exact 50 boundary')
balance=49 -- Balance changed after rendering, before the actual tap.
tap(choice.buttons.revive);eq(balance,49,'stale affordable label never overspends');assert(not choice.reviveAffordable,'tap refreshes actual affordability');eq(charges,0,'stale affordable click has no debit')
shortage:removeFromParent(true);shortage=nil
balance=50;choice:refreshAffordance();capture(boundary,{360,640},'revive-exact-50')
choice:retain();local paidBoundary=choice.buttons.revive.item;paidBoundary:retain()
tap(choice.buttons.revive);eq(balance,0,'50 exact boundary debits exactly 50');eq(charges,1,'boundary debits once');eq(calls,1,'boundary revives once');paidBoundary:activate();eq(charges,1,'rapid boundary tap inert')
fixture.finish();paidBoundary:release();choice:release()
print('PASS 49/50 boundary and live balance 49 -> 50 -> 49 -> 50; stale display cannot spend or revive')
-- Eternal challenge preserves its automatic two-second callback, no gift.
calls=0;local v,choice=fail({480,800},true,true);tap(choice.buttons['return'])
local result=v.warmRecoveryState.ui;assert(not result.buttons.gift and not result.buttons['return'])
H.step(v,0);H.step(v,1.99);eq(calls,0,'no early eternal callback');H.step(v,.02);eq(calls,1,'original two-second eternal callback');H.step(v,2);eq(calls,1,'eternal callback once');fixture.finish()
-- Opt-out still executes the unchanged original AlertView constructors.
WARM_PIRATE_V1=false;WriteColor=cc.c3b(255,255,255)
local alerts=0;AlertView={create=function(_,kind,box,title,yes,no,left,right)
 alerts=alerts+1;eq(title,'立即复活','legacy title');eq(left,'确认死亡','legacy decline');eq(right,'复 活','legacy revive')
 local a=cc.Node:create();a.s_position=cc.p(320,480);function a:setOkRemove(v)eq(v,0,'legacy keep-open flag')end;return a
end}
for _,boarding in ipairs({true,false})do
 v=H.fresh({640,960},boarding,1,1);v.beginUpdateTime=100;v.aboardProsb={0};v.buffers={}
 for _,f in ipairs(v.playerTeam.fighters)do f.hp=0 end;v:calculateTeamHp();v:update(0)
 assert(not v.warmRecoveryState,'opt-out never creates helper');fixture.finish()
end
eq(alerts,2,'both legacy revive branches unchanged')
WARM_PIRATE_V1=true;dm.addDiamond=originalDiamond;cc.Director.getInstance=fixture.realGet
assert(#H.errors==0,table.concat(H.errors,'\n'))
print('PASS legacy opt-out, eternal timing and no double economic actions')
