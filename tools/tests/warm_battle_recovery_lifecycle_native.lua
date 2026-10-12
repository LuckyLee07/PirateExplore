-- Real gift, platform gate, native scene/owner exits and stale input. No GUI,
-- profiles, network or actual platform purchase; supported requests are spies.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/coherent_service_support_native.lua')
local stop=assert(source:find('local now=86400*20000',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,dm=dm,step=function(root,dt)
 H.visit(root,function(n)director:getActionManager():resumeTarget(n)end);director:getActionManager():update(dt)
end}
]],'@recovery-real-gift-fixture'))()
local fixture=H.H;local dm=H.dm;local R=require 'LuaClass/WarmBattleRecovery'
FightScene={FightFailType={normal=1,eternal=2}}
local director=fixture.realGet(cc.Director)
local errors={};local prior=__G__TRACKBACK__;__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local function eq(a,b,s)assert(a==b,s..': '..tostring(a)..' ~= '..tostring(b))end
local calls,requests,toasts=0,{},{}
local originalApplication=cc.Application.getInstance;local platform=cc.PLATFORM_OS_LINUX
cc.Application.getInstance=function()return{getTargetPlatform=function()return platform end}end
purchase=function(id)requests[#requests+1]=id end
ToastUtil.downString=function(_,s)toasts[#toasts+1]=s end;ToastUtil.toastString=ToastUtil.downString
local function fresh()
 fixture.fixture();local scene=fixture.prepare(480,800);local owner=cc.Layer:create();scene:addChild(owner)
 owner.fightFailType=1;owner.fightResult=false;owner.fightOverCallback=function(result)eq(result,false,'exact result');calls=calls+1 end
 owner.showFailInfoAndReturn=R.result
 local sheet=R.result(owner)
 if coherentCapture then assert(coherentCapture(scene,480,800,os.getenv('COHERENT_BATTLE_CAPTURE_DIR')..'/lifecycle-ready.png'))end
 return scene,owner,sheet
end
local function tap(button)if coherentMenuTap then coherentMenuTap(button.item)else button.item:activate()end end
local function clear()fixture.finish()end
-- Actual PushGiftView is optional, has the original delay and exact payType.
local scene,owner,sheet=fresh();local before=fixture.serialize(fixture.getData())
tap(sheet.buttons.gift);local gift=assert(owner.warmRecoveryState.gift);gift:retain()
eq(#requests,0,'opening gift does not purchase');gift.giftBuyButton.item:activate();eq(#requests,0,'actual delayed purchase guard')
H.step(scene,0);H.step(scene,gift.timeLine+.1);assert(gift.serviceGiftReady,'actual purchase delay elapsed')
gift.giftBuyButton.item:activate();eq(#requests,0,'Linux no billing');eq(toasts[#toasts],'当前平台暂不支持充值购买','Linux honest response')
platform=cc.PLATFORM_OS_ANDROID;gift.giftBuyButton.item:activate();eq(#requests,1,'supported platform delegates only after explicit tap')
eq(requests[1],fixture.tables[csvOfPushGift]['2'].payType,'unchanged product ID')
local req=#requests;gift.serviceClose.item:activate();gift.giftBuyButton.item:activate();eq(#requests,req,'closing gift cannot buy')
H.step(scene,0);H.step(scene,.3);eq(owner.warmRecoveryState.gift,nil,'closed gift drops native pointer')
eq(fixture.serialize(fixture.getData()),before,'no opening/closing/platform-spy economy writes');gift:release()
tap(sheet.buttons.gift);gift=assert(owner.warmRecoveryState.gift);gift:retain();eq(#requests,req,'reopen does not buy')
-- An owner removed individually must retire its own sibling gift. The render
-- harness also has a genuine running scene and autorelease frame traversal.
owner:retain();sheet:retain();local stale=sheet.buttons['return'].item;stale:retain()
owner:removeFromParent(true);assert(owner.warmRecoveryState.disposed,'owner cleanup invalidates every action');assert(gift.serviceClosed,'orphan gift cannot purchase')
H.step(scene,0);H.step(scene,.01)
if scene:isRunning()then eq(gift:getParent(),nil,'running owner exit removes sibling gift on safe tick')end
stale:activate();gift.giftBuyButton.item:activate();eq(calls,0,'stale return cannot settle');eq(#requests,req,'stale gift cannot buy')
clear();stale:release();sheet:release();owner:release();gift:release()
-- Full scene replacement is a different native traversal order.
if coherentCapture then
 scene,owner,sheet=fresh();tap(sheet.buttons.gift);gift=assert(owner.warmRecoveryState.gift);gift:retain();owner:retain()
 local button=sheet.buttons['return'].item;button:retain()
 director:replaceScene(cc.Scene:create());for _=1,4 do director:drawScene()end
 assert(owner.warmRecoveryState.disposed and gift.serviceClosed,'full scene exit invalidates gift/recovery')
 button:activate();gift.giftBuyButton.item:activate();eq(calls,0,'scene replacement rejects stale return');eq(#requests,req,'scene replacement rejects stale billing')
 clear();button:release();owner:release();gift:release()
end
-- Explicit presentation close is inert; reopening creates a fresh guarded UI.
scene,owner,sheet=fresh();sheet:retain();local old=sheet.buttons['return'].item;old:retain();sheet:close();sheet:close()
local next=R.result(owner);assert(next and next~=sheet);old:activate();eq(calls,0,'closed generation is inert')
tap(next.buttons['return']);eq(calls,1,'fresh return callback once');old:activate();eq(calls,1,'old does not repeat');clear();old:release();sheet:release()
cc.Application.getInstance=originalApplication;cc.Director.getInstance=fixture.realGet;__G__TRACKBACK__=prior
assert(#errors==0,table.concat(errors,'\n'))
print('PASS real gift delay/price route, unsupported/supported bridge spies, close/reopen, owner cleanup, stale return/purchase and no economic writes'..(coherentCapture and '; running owner/full scene exit passed' or '; running-scene exits are checked by the render harness'))
