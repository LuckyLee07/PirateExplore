local X=dofile('tools/tests/fixtures/intelligence_return_fixture.lua');local H,T,F,dm=X.H,X.T,X.F,X.dm
local errors={};__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local O=require 'LuaClass/WarmShortageOwnership'
for _,kind in ipairs({'return','talent','mission'})do
for _,order in ipairs({'owner-first','presentation-first'})do
for _,how in ipairs({'remove','close','rebind','generation','scene','push'})do
for _,phase in ipairs({'prompt','gift'})do
 if (how~='scene'and how~='push')or coherentEventEnter then
  local v=X.new(kind,0);local writes=T.writes;v.trigger();local prompt,context=T.prompt(v.owner)
  local gift=phase=='gift'and T.gift(prompt,context)or nil
  T.eq(T.writes,writes,'failed '..kind..' never debits');T.eq(v.data[roleDiamond],0,'zero balance conserved')
  if kind=='mission'then T.eq(v.target:getMissionStatue(),'wait','failed quick-complete stays waiting')end
  if kind=='talent'then T.eq(next(v.data[roleTalent]),nil,'failed talent stays locked')end
  local unrelated=DialogueView:create();unrelated:retain();unrelated:show(1600)
  local surface=gift or prompt;if order=='presentation-first'then surface:setLocalZOrder(-1)end
  v.scene:sortAllChildren();local ownerIndex,surfaceIndex
  for i,c in ipairs(v.scene:getChildren())do if c==v.owner then ownerIndex=i elseif c==surface then surfaceIndex=i end end
  T.eq(ownerIndex<surfaceIndex,order=='owner-first','actual native sibling order')
  T.expired(v.scene,v.owner,prompt,context,gift,function()
   if how=='remove'then v.owner:removeFromParent(true)
   elseif how=='close'then
    if kind=='return'then v.owner:removeFromParent(true)else v.owner:close()end
   elseif how=='rebind'then
    if kind=='return'then
     -- Execute the real map-rebind retirement boundary before world rebuilding.
     local source=X.read('bin/res/scripts/LuaClass/Explore.lua')
     local prefix=assert(source:match('(function Explore:initMapByMapIndex%(%s*mapIndex,isclear%s*%).-)    CleanVoyageView.unmount'))
     assert(loadstring(prefix..'end'))();Explore.initMapByMapIndex(v.owner,2,false)
    else v.owner:init()end
   elseif how=='generation'then
    if kind=='return'then v.owner.mapIndex=3 else v.owner.warmIntelligenceGeneration=v.owner.warmIntelligenceGeneration+1 end
    T.eq(context.isActive(),false,'generation invalid immediately')
    if gift then T.step(gift,0);T.step(gift,gift.timeLine+1);gift.giftBuyButton.item:activate()else context.retire()end
   elseif how=='push'then F.director:pushScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end
   else F.director:replaceScene(cc.Scene:create());for _=1,4 do F.director:drawScene()end end
  end)
  if how=='remove'then
   T.eq(v.owner:getParent(),nil,'removed owner parent cleared')
   local ownerFound,unrelatedFound=false,false
   for _,child in ipairs(v.scene:getChildren())do if child==v.owner then ownerFound=true elseif child==unrelated then unrelatedFound=true end end
   T.eq(ownerFound,false,'removed owner is absent from actual native child vector');T.ok(unrelatedFound,'trailing unrelated sibling stays in actual native child vector')
   T.step(v.scene,0);T.step(v.scene,.01)
   T.eq(prompt:getParent(),nil,'deferred prompt removed on safe tick');if gift then T.eq(gift:getParent(),nil,'deferred gift removed on safe tick')end
  end
  if how=='push'then
   F.director:popScene();for _=1,4 do F.director:drawScene()end
   T.eq(prompt:isVisible(),false,'resume never revives retired prompt');if gift then T.eq(gift:isVisible(),false,'resume never revives gift')end
   T.ok(unrelated._dialogueEntry and unrelated:isVisible(),'unrelated modal survives push/pop')
  elseif how~='scene'then T.ok(unrelated._dialogueEntry and unrelated:isVisible(),'unrelated modal remains registered and visible')end
  H.finish();unrelated:release();if gift then gift:release()end;prompt:release();v.owner:release()
  print('PASS actual '..kind..' '..phase..' '..how..' '..order)
 end
end end end end
-- Exact shipped thresholds and the original transaction/learning callbacks.
for _,kind in ipairs({'return','talent','mission'})do
 local seed=X.new(kind,0);local price=kind=='talent'and 3 or seed.target.price;H.finish();seed.owner:release()
 for _,balance in ipairs({price-1,price,price+1})do
  local v=X.new(kind,balance);local writes=T.writes;v.trigger()
  if balance<price then
   T.eq(v.data[roleDiamond],balance,'one below '..kind..' threshold unchanged');T.eq(T.writes,writes,'threshold shortage has no debit')
   local prompt,context=T.prompt(v.owner);prompt.warmOptions[2].item:activate();prompt:release()
  else
   T.eq(v.data[roleDiamond],balance-price,'exact shipped '..kind..' price');T.eq(T.writes,writes+1,'one original '..kind..' debit')
   if kind=='return'then T.eq(v.effects[#v.effects],'home','real old-save return reaches home after cargo cleanup');T.eq(v.data.adventureProgressV1,nil,'old save stays old schema')
   elseif kind=='mission'then T.eq(v.target:getMissionStatue(),'complete','real quick-complete completes');T.eq(v.manager.waitingMissions[v.target.id],nil,'mission leaves waiting');T.eq(v.manager.completedMissions[v.target.id],v.target,'mission added to completed')
   else T.eq(v.data[roleTalent]['1'],'2002','real unlock learns shipped talent');T.eq(#v.random.eventList,0,'success removes exact event')end
  end
  H.finish();v.owner:release()
 end
 print('PASS exact shipped '..kind..' balance threshold '..price)
end
-- Live explicit Buy, source-row rebind, model change, cancellation and retry.
for _,kind in ipairs({'talent','mission'})do
 local v=X.new(kind,0);local old=X.item(v.owner,kind=='talent'and'钻石学习'or'一键完成');old:retain()
 v.trigger();local prompt,context=T.prompt(v.owner);local gift=T.gift(prompt,context)
 T.step(v.scene,0);T.step(v.scene,gift.timeLine+.1);local requests=T.requests;gift.giftBuyButton.item:activate();T.eq(T.requests,requests+1,'live intelligence Buy reaches supported spy')
 T.eq(T.product,H.tables[csvOfPushGift]['2'].payType,'shipped platform product')
 v.owner.tableview1:reloadData();local created=T.created;local writes=T.writes;old:activate();T.eq(T.created,created,'retained rebound source row cannot open gift');T.eq(v.owner.warmShortageContext,context,'retained rebound row cannot replace presentation');T.eq(T.writes,writes,'retained rebound row cannot debit')
 T.ok(context.isActive(),'same-target refresh preserves failed offer')
 if kind=='talent'then v.random.eventList={}else v.manager.waitingMissions[v.target.id]=nil end
 T.eq(context.isActive(),false,'removed model invalid synchronously');gift.giftBuyButton.item:activate();T.ok(context.disposed,'stale gift invalidates exact model context')
 T.eq(T.requests,requests+1,'removed model cannot purchase');H.finish();old:release();gift:release();prompt:release();v.owner:release()
end
-- Cancel/retry uses the same live caller, and expiry invalidates both the
-- original source action and an already-open supported-platform gift.
for _,kind in ipairs({'return','talent','mission'})do
 local v=X.new(kind,0);v.trigger();local prompt,context=T.prompt(v.owner)
 prompt.warmOptions[2].item:activate();T.eq(context.owner.adventureDialog,nil,'cancel closes only shortage');prompt:release()
 local price=({['return']=15,talent=3,mission=50})[kind];v.data[roleDiamond]=price;local writes=T.writes;v.trigger()
 T.eq(v.data[roleDiamond],0,'same-caller retry uses exact shipped price');T.eq(T.writes,writes+1,'same-caller retry debits once')
 H.finish();v.owner:release()
end
do
 local v=X.new('talent',0);local source=X.item(v.owner,'钻石学习');source:retain();v.trigger();local prompt,context=T.prompt(v.owner);local gift=T.gift(prompt,context)
 v.target.startTime=os.time()-v.target.lifeTime-1;v.data[roleDiamond]=3;local requests,writes=T.requests,T.writes
 T.eq(context.isActive(),false,'expired target invalid synchronously');source:activate();T.eq(T.writes,writes,'expired source control never charges')
 T.step(gift,0);T.step(gift,gift.timeLine+.1);gift.giftBuyButton.item:activate();T.eq(T.requests,requests,'expired target gift never purchases');T.ok(context.disposed,'expiry retires context')
 H.finish();source:release();gift:release();prompt:release();v.owner:release()
end
-- No-owner API calls retain the historical scene-owned default presentation.
for _,kind in ipairs({'talent','mission'})do
 local v=X.new(kind,0)
 if kind=='talent'then T.eq(dm:checkTallentPass(H.tables[csvOfTalent]['2002'],2),false,'default talent still fails affordability')
 else T.eq(v.target:completedMissionByCosted(),false,'default mission still fails affordability')end
 T.eq(v.owner.warmShortageContext,nil,'default caller is not opted in');T.ok(v.scene.adventureDialog,'default shortage remains scene-owned')
 H.finish();v.owner:release()
end
-- A separate synthetic type-1 compatibility row covers the optional context
-- on the general-learning branch. Live shipped route coverage above is 2002.
do
 local v=X.new('talent',0);local talent={};for k,value in pairs(H.tables[csvOfTalent]['2002'])do talent[k]=value end
 talent.ID='fixture-type1';talent.resumeType='1';H.tables[csvOfTalent][talent.ID]=talent;v.data[roleMoney]=100000000
 local context=O.forOwner(v.owner,'warmIntelligenceGeneration');local writes=T.writes
 T.eq(dm:checkTallentPass(talent,nil,context),false,'general-learning shortage fails');T.eq(T.writes,writes,'affordability never charges')
 local prompt=T.prompt(v.owner);prompt:release();H.tables[csvOfTalent][talent.ID]=nil;H.finish();v.owner:release()
end
-- WARM=false keeps all three original alerts and transaction amounts.
WARM_PIRATE_V1=false
for _,kind in ipairs({'return','talent','mission'})do
 for _,balance in ipairs({0,({['return']=15,talent=3,mission=50})[kind]})do
  local v=X.new(kind,balance);v.trigger();T.eq(v.owner.warmShortageContext,nil,'legacy caller never opts in');T.eq(v.scene.adventureDialog,nil,'legacy shortage does not become warm')
  local legacy;for _,child in ipairs(v.scene:getChildren())do if child.title=='购买失败'then legacy=child end end
  T.eq(legacy~=nil,balance==0,'original legacy purchase-failed alert only on shortage');T.eq(v.data[roleDiamond],0,'legacy exact original charge or zero shortage');H.finish();v.owner:release()
 end
end
WARM_PIRATE_V1=nil
assert(#errors==0,table.concat(errors,'\n'));T.finish('actual intelligence and old-save return shortage ownership')
