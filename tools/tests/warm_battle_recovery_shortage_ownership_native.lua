-- Actual addDiamond, WarmDialog and PushGiftView together. The native render
-- harness also runs these cases in genuine running scenes. In-memory role
-- data and a purchase spy only: no profile, GUI, network or real payment.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_service_support_native.lua')
local stop=assert(source:find('local now=86400*20000',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,dm=dm,step=function(root,dt)
 H.visit(root,function(n)director:getActionManager():resumeTarget(n)end);director:getActionManager():update(dt)
end}
]],'@real-shortage-ownership-fixture'))()
local H,dm=F.H,F.dm
local R=require 'LuaClass/WarmBattleRecovery'
local D=require 'LuaClass/WarmDialog'
local manager=read('bin/res/scripts/LuaClass/DataManager.lua')
local a=assert(manager:find('function DataManager:addDiamond(',1,true))
local b=assert(manager:find('function DataManager:unlockTallentByKey(',a,true))
assert(loadstring(manager:sub(a,b-1),'@actual-owned-addDiamond'))();dm.addDiamond=DataManager.addDiamond
FightScene={FightFailType={normal=1,eternal=2}}
local director=H.realGet(cc.Director)
local errors={};local traceback=__G__TRACKBACK__
__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local assertions=0
local function eq(a,b,s)assertions=assertions+1;assert(a==b,s..': '..tostring(a)..' ~= '..tostring(b))end
local function ok(value,s)assertions=assertions+1;assert(value,s)end
local application=cc.Application.getInstance;local platform=cc.PLATFORM_OS_IPHONE
cc.Application.getInstance=function()return{getTargetPlatform=function()return platform end}end
local requests,writes,revives,returns,created=0,0,0,0,0
local products={};local onWrite
local function spy(id)requests=requests+1;products[#products+1]=id end
purchase=spy
local createGift=PushGiftView.create
PushGiftView.create=function(self)created=created+1;return createGift(self)end
local toasts={};ToastUtil.downString=function(_,s)toasts[#toasts+1]=s end;ToastUtil.toastString=ToastUtil.downString
getExplor=function()return{eventManger={layer={safeBackToLayer=function()revives=revives+1 end}}}end
dm.setRoleData=function(_,key,value)writes=writes+1;H.getData()[key]=value;if onWrite then onWrite()end end
local function tap(button)if coherentMenuTap then coherentMenuTap(button.item)else button.item:activate()end end
local function fresh(size,mode)
 H.fixture();local scene=H.prepare(size[1],size[2]);local owner=cc.Layer:create();scene:addChild(owner)
 owner.fightFailType=mode or 1;owner.fightResult=false;owner.showFailInfoAndReturn=R.result
 owner.fightOverCallback=function(result)eq(result,false,'original loss result');returns=returns+1 end
 H.getData()[roleDiamond]=49;isEnterMap=true;platform=cc.PLATFORM_OS_IPHONE;purchase=spy
 local choice=R.choice(owner)
 if coherentCapture then
  local out=os.getenv('COHERENT_BATTLE_CAPTURE_DIR')or'/tmp'
  ok(coherentCapture(scene,size[1],size[2],out..'/shortage-ownership-ready.png'),'offscreen GL setup')
 end
 return scene,owner,choice
end
local function shortage(owner,choice)
 local before=writes;tap(choice.buttons.revive)
 local prompt=assert(owner.adventureDialog)
 eq(writes,before,'49 never writes diamonds');eq(#prompt.warmOptions,2,'supported view/cancel options')
 eq(prompt.warmOptions[1].label:getString(),'查看充值选项','truthful non-purchase CTA')
 eq(owner.warmRecoveryState.shortagePresentation.owner,owner,'explicit per-call owner')
 eq(R.choice(owner),choice,'same choice generation')
 return prompt
end
local function openGift(owner,prompt)
 local before=created;prompt.warmOptions[1].item:activate()
 local gift=assert(owner.warmRecoveryState.gift)
 eq(created,before+1,'one actual gift created');eq(owner.adventureDialog,nil,'gift closes owned shortage prompt')
 eq(gift._dialogueEntry.zOrder,999,'original map depth 999')
 return gift
end
local function expire(scene,owner,how)
 if how=='push'then
  director:pushScene(cc.Scene:create());for _=1,4 do director:drawScene()end
 elseif how=='replace'then
  director:replaceScene(cc.Scene:create());for _=1,4 do director:drawScene()end
 elseif how=='detach'then owner:removeFromParent(false)
 elseif how=='cleanup'then owner:cleanup()
 else owner:removeFromParent(true)end
 ok(owner.warmRecoveryState.disposed,how..' invalidates recovery')
end
local methods={'destroy','cleanup'}
-- A never-entered node has no native exit event when detached without cleanup.
if coherentCapture then methods[#methods+1]='detach';methods[#methods+1]='replace';methods[#methods+1]='push'end
for _,size in ipairs({{360,640},{480,800}})do
 for _,order in ipairs({'owner-first','presentation-first'})do
 for _,how in ipairs(methods)do
  for _,phase in ipairs({'prompt','gift'})do
   local scene,owner,choice=fresh(size);owner:retain();choice:retain()
   local prompt=shortage(owner,choice);prompt:retain()
   local option=prompt.warmOptions[1].item;option:retain()
   local revive=choice.buttons.revive.item;revive:retain()
   local decline=choice.buttons['return'].item;decline:retain()
   local gift=phase=='gift'and openGift(owner,prompt)or nil
   if gift then gift:retain()end
   local surface=gift or prompt
   if order=='presentation-first'then surface:setLocalZOrder(-1)end
   local sentinel=cc.Node:create();sentinel:retain();scene:addChild(sentinel,5000)
   scene:sortAllChildren()
   if coherentCapture then ok(scene:isRunning(),'genuine native running scene before '..how)end
   local req,save,nav,loss,gifts=requests,writes,revives,returns,created
   expire(scene,owner,how)
   eq(owner.adventureDialog,nil,'owned prompt reference cleared')
   eq(owner.warmRecoveryState.gift,nil,'owned gift reference cleared')
   if gift then eq(gift._dialogueEntry,nil,'retired gift leaves native modal stack')end
   if how~='replace'and how~='push'then
    eq(sentinel:getParent(),scene,'following scene sibling retains parent')
    local hasSentinel,hasOwner=false,false
    for _,child in ipairs(scene:getChildren())do if child==sentinel then hasSentinel=true elseif child==owner then hasOwner=true end end
    eq(hasSentinel,true,'following scene sibling stays in actual child vector')
    if how~='cleanup'then eq(hasOwner,false,'detached owner leaves actual child vector')end
    F.step(scene,0);F.step(scene,.01)
    eq(prompt:getParent(),nil,'retired prompt removed on safe tick')
   end
   eq(prompt:isVisible(),false,'retired prompt stays hidden in retained scene')
   option:activate();revive:activate();decline:activate()
   if gift then
    ok(gift.serviceClosed,'already-open gift retired')
    eq(gift:isVisible(),false,'orphan gift hidden')
    eq(gift.giftBuyButton:getNumberOfRunningActions(),0,'delayed Buy action stopped')
    if scene:isRunning()then eq(gift:getParent(),nil,'running owner removes exact gift sibling')end
    -- Even explicitly resuming a retained detached presentation cannot buy.
    F.step(gift,0);F.step(gift,gift.timeLine+1);gift.giftBuyButton.item:activate()
   else F.step(scene,0);F.step(scene,4)end
   eq(created,gifts,'stale shortage cannot create a gift')
   eq(requests,req,'stale Buy cannot reach supported purchase spy')
   eq(writes,save,'expired recovery cannot debit')
   eq(revives,nav,'expired recovery cannot revive');eq(returns,loss,'expired recovery cannot settle loss')
   if how=='detach'then scene:addChild(owner);eq(R.choice(owner),nil,'reattached expired owner stays inert');option:activate()end
   if how=='push'then
    director:popScene();for _=1,4 do director:drawScene()end
    eq(prompt:isVisible(),false,'popped scene cannot redisplay expired prompt')
    if gift then eq(gift:isVisible(),false,'popped scene cannot redisplay expired gift');eq(gift.giftBuyButton:getNumberOfRunningActions(),0,'popped scene cannot resume Buy delay')end
   end
   H.finish();option:release();revive:release();decline:release();prompt:release();choice:release();owner:release();sentinel:release();if gift then gift:release()end
   print('PASS real shortage '..phase..' owner '..how..' '..order..' '..size[1]..'x'..size[2]..': stale controls, delayed Buy, no debit or navigation')
  end
 end
end
end
-- Recovery ownership never sweeps unrelated scene-owned dialogs, even while
-- retiring a real gift that has its own scene modal-stack registration.
for _,phase in ipairs({'prompt','gift'})do
 local scene,owner,choice=fresh({480,800});local prompt=shortage(owner,choice)
 if phase=='gift'then openGift(owner,prompt)end
 local other=D.show('Other caller','Unrelated presentation',{{label='Close'}});other:retain()
 owner:removeFromParent(true)
 eq(scene.adventureDialog,other,'unrelated default dialog retains ownership');eq(other:getParent(),scene,'unrelated sibling remains')
 other.warmOptions[1].item:activate();eq(scene.adventureDialog,nil,'unrelated dialog remains actionable');H.finish();other:release()
end
-- Real cancel/retry, real close/reopen, current platform gates and exact product.
for _,mode in ipairs({1,2})do
 local scene,owner,choice=fresh({480,800},mode);local req,save,nav=requests,writes,revives
 local prompt=shortage(owner,choice);prompt:retain();local canceled=prompt.warmOptions[1].item;canceled:retain()
 prompt.warmOptions[2].item:activate();eq(owner.adventureDialog,nil,'cancel removes prompt')
 local before=created;canceled:activate();eq(created,before,'canceled action cannot open gift')
 prompt:release();canceled:release();prompt=shortage(owner,choice);local gift=openGift(owner,prompt);gift:retain()
 choice.buttons.revive.item:activate();choice.buttons['return'].item:activate()
 eq(owner.warmRecoveryState.ui,choice,'real gift blocks underlying recovery');eq(writes,save,'blocked controls do not debit')
 gift.giftBuyButton.item:activate();eq(requests,req,'original gift delay rejects early Buy')
 F.step(scene,0);F.step(scene,gift.timeLine+.1);ok(gift.serviceGiftReady,'real delayed Buy becomes ready')
 platform=cc.PLATFORM_OS_LINUX;gift.giftBuyButton.item:activate();eq(requests,req,'unavailable platform cannot purchase')
 eq(toasts[#toasts],'当前平台暂不支持充值购买','truthful unavailable Buy feedback')
 platform=cc.PLATFORM_OS_IPHONE;gift.giftBuyButton.item:activate();eq(requests,req+1,'explicit live Buy reaches supported spy')
 eq(products[#products],H.tables[csvOfPushGift]['2'].payType,'exact original gift product')
 gift.serviceClose.item:activate();gift.giftBuyButton.item:activate();eq(requests,req+1,'closing gift rejects Buy')
 F.step(scene,0);F.step(scene,.3);eq(owner.warmRecoveryState.gift,nil,'closed real gift clears ownership');gift:release()
 prompt=shortage(owner,choice);prompt.warmOptions[2].item:activate()
 H.getData()[roleDiamond]=50;choice:refreshAffordance();ok(choice.reviveAffordable,'live 50 is affordable')
 H.getData()[roleDiamond]=49;choice.buttons.revive.item:activate();ok(not choice.reviveAffordable,'stale affordable caption refreshed at tap')
 eq(writes,save,'live 49 still cannot debit');owner.adventureDialog.warmOptions[2].item:activate()
 H.getData()[roleDiamond]=50;choice:refreshAffordance();choice:retain();local paid=choice.buttons.revive.item;paid:retain()
 onWrite=function()paid:activate()end;paid:activate();onWrite=nil;paid:activate()
 eq(H.getData()[roleDiamond],0,'exact original 50-diamond debit');eq(writes,save+1,'reentrant debit occurs exactly once');eq(revives,nav+1,'original safe return once')
 H.finish();paid:activate();eq(writes,save+1,'retained paid control remains inert');paid:release();choice:release()
end
-- Default callers still own prompts on their scene. Optional ownership does
-- not affect missing/unsupported bridge copy or the WARM=false legacy branch.
for _,case in ipairs({{cc.PLATFORM_OS_LINUX,true},{cc.PLATFORM_OS_ANDROID,false}})do
 local scene,owner,choice=fresh({480,800});platform=case[1];purchase=case[2]and spy or nil
 tap(choice.buttons.revive);local prompt=assert(owner.adventureDialog)
 eq(#prompt.warmOptions,1,'unavailable owned prompt is dismiss-only');eq(prompt.warmOptions[1].label:getString(),'知道了','honest unavailable dismissal')
 local before=created;prompt.warmOptions[1].item:activate();eq(created,before,'unavailable cannot open gift')
 dm:addDiamond(-50,true);ok(scene.adventureDialog,'default caller remains scene-owned');eq(owner.adventureDialog,nil,'default caller does not inherit recovery owner')
 scene.adventureDialog.warmOptions[1].item:activate();H.finish()
end
for _,z in ipairs({-1,3000})do
 local scene,owner,choice=fresh({480,800});shortage(owner,choice).warmOptions[2].item:activate();dm:addDiamond(-50,true)
 local prompt=assert(scene.adventureDialog);prompt:retain();prompt:setLocalZOrder(z)
 local sentinel=cc.Node:create();sentinel:retain();scene:addChild(sentinel,5000);scene:sortAllChildren()
 prompt:removeFromParent(true)
 local found=false;for _,child in ipairs(scene:getChildren())do if child==sentinel then found=true end end
 eq(found,true,'default dialog direct removal preserves following native sibling')
 eq(scene.adventureDialog,nil,'default dialog external removal clears scene ownership')
 F.step(scene,0);F.step(scene,.01);H.finish();prompt:release();sentinel:release()
end
local scene,owner,choice=fresh({480,800});local legacy,depth=0,nil
local alert=AlertView;AlertView={create=function(_,kind,box,title,action)legacy=legacy+1;eq(title,'购买失败','original legacy alert');local n=cc.Node:create();n.s_position=cc.p(240,400);return n end}
WARM_PIRATE_V1=false;dm:addDiamond(-50,true,nil,{isActive=function()error('legacy must ignore context')end})
eq(legacy,1,'WARM=false keeps legacy shortage');eq(scene.adventureDialog,nil,'legacy creates no warm prompt');eq(owner.adventureDialog,nil,'legacy creates no owner prompt')
WARM_PIRATE_V1=true;AlertView=alert;H.finish()
PushGiftView.create=createGift;cc.Application.getInstance=application;cc.Director.getInstance=H.realGet;__G__TRACKBACK__=traceback
assert(#errors==0,table.concat(errors,'\n'))
print('PASS actual shortage + actual gift ownership: '..assertions..' assertions; native running/full-scene cases '..(coherentCapture and 'included' or 'run separately by render harness'))
