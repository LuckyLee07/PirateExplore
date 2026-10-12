-- Actual FightMode reward/chest constructors, native nodes and original callbacks.
-- All state lives in memory. No game profile, GUI, combat simulation or purchase.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,serialize=serialize,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,realGet=realGet}
]],'@coherent-loot-native-fixture'))()
local callbackErrors={};local originalTraceback=__G__TRACKBACK__
__G__TRACKBACK__=function(message)callbackErrors[#callbackErrors+1]=tostring(message);return tostring(message)end
local dm=H.dm;local W=require 'LuaClass/WarmTheme'
require 'LuaClass/CombatTheme';require 'LuaClass/ItemIcon';require 'LuaClass/DialogueView'
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function parse(value)local rows={};for part in value:gmatch('[^;]+')do local row={};for field in part:gmatch('[^_]+')do row[#row+1]=field end;rows[#rows+1]=row end;return rows end
H.tables[csvOfFightBoxes]=H.csv('fightboxes')
for _,row in pairs(H.tables[csvOfFightBoxes])do for _,field in ipairs({'propA','propB','propC','propShow'})do row[field]=parse(row[field])end end
local fdm={mapID=1,dropData={}}
local source=read('bin/res/scripts/LuaClass/FightMode.lua')
local first=assert(source:find('local changeListItemNum = function',1,true));local last=assert(source:find('-- Fighter',first,true))
local chest=assert(source:find('FightBoxViewAlert = class(',1,true));local chestEnd=assert(source:find('-- 战斗过渡场景',chest,true))
local cargo=assert(source:find('FightRewardScene = class(',1,true))
assert(loadstring('local fdm=...\n'..source:sub(first,last-1)..source:sub(chest,chestEnd-1)..source:sub(cargo),'@real-fight-reward-chest'))(fdm)
local writes,coins,diamondWrites,completed,toast,order=0,0,0,0,nil,{}
local onWrite
local realUserDefault=cc.UserDefault.getInstance
local firstChest=false;local firstWrites=0
cc.UserDefault.getInstance=function()return{getBoolForKey=function()return firstChest end,setBoolForKey=function(_,key,v)eq(key,'isFirtFightBox','original first chest key');firstWrites=firstWrites+1;firstChest=v end}end
dm.getSound_off=function()return 1 end
dm.setRoleData=function(_,key,value)writes=writes+1;order[#order+1]='write:'..key;H.getData()[key]=value;if onWrite then onWrite()end end
dm.addDiamond=function(_,delta)local data=H.getData();if data[roleDiamond]+delta<0 then return 0 end;diamondWrites=diamondWrites+1;data[roleDiamond]=data[roleDiamond]+delta;order[#order+1]='diamond:'..delta;return 1 end
ExploreBagController={getBagController=function()return{addCoin=function(_,n)coins=coins+n;order[#order+1]='coin:'..n end}end}
ToastUtil.downString=function(_,s)toast=s end
FightScene={instance={gotoFightRewardScene=function(_,delay)eq(delay,.5,'original reward transition delay');completed=completed+1;order[#order+1]='rewardScene'end}}
local function amount(list,id)for _,v in pairs(list)do if tostring(v.id)==id then return tonumber(v.num)end end;return 0 end
local function capture(view,w,h,name)
 if coherentCapture and os.getenv('COHERENT_LOOT_CAPTURE_DIR') then
  assert(coherentCapture(view,w,h,os.getenv('COHERENT_LOOT_CAPTURE_DIR')..'/'..name..'-'..w..'x'..h..'.png'))
 end
end
local function reset(cap,food,drop,reserved)
 H.fixture();local data=H.getData();data[rolePackSize]=cap;data[roleBattlePack]={};data[roleDiamond]=10
 if food>0 then data[roleBattlePack]['1005']={id='1005',num=food}end
 if reserved then data[roleBattlePack][reserved.id]=clone(reserved)end
 fdm.dropData=clone(drop or {});writes=0;coins=0;diamondWrites=0;completed=0;toast=nil;order={};onWrite=nil
end
local function newCargo(scene,cap,food,drop,reserved)
 reset(cap,food,drop,reserved);local view=assert(FightRewardScene:create());view:retain();scene:addChild(view)
 view:setFightOverCallback(function(result)eq(result,true,'original fight result');completed=completed+1;order[#order+1]='callback'end);view:setFightResult(true)
 return view
end
local function remove(view)view:removeFromParent(true);view:release()end
local function tap(view,side,id)
 local list=side==1 and view.package or view.rewardItems;local index
 for i,item in ipairs(list)do if tostring(item.id)==id then index=i;break end end
 assert(index,'row '..id);local tableview=side==1 and view.tableview1 or view.tableview2
 local cell=tableview:cellAtIndex(index-1)
 if not cell then cell=cc.TableViewCell:create();cell:setTag(index);cell.coherentItemId=id end
 view.coherentCargoTouch[side](tableview,cell)
end
local function walk(view,w,h)
 local text={}
 H.visit(view,function(n,visible)
  if visible and n.getString and n:getString()~='' then
   local s=n:getString();text[s]=true;local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=w+1,'label horizontal '..s..' '..a.x..' '..b.x)
   local inTable=false;local parent=n:getParent()
   while parent and parent~=view do if parent.getViewSize then inTable=true end;parent=parent:getParent()end
   if not inTable then assert(a.y>=-1 and b.y<=h+1,'label vertical '..s..' '..a.y..' '..b.y)end
   if n.getFontName then eq(n:getFontName(),W.font,'all clean text uses shared font')end
  end
 end)
 return text
end
local taskId
for id,row in pairs(H.tables[csvOfResourceInfo])do if row.carryType=='2' and tonumber(row.cubage)==0 then taskId=id;break end end
assert(taskId,'actual zero-volume quest item')
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2];local scene=H.prepare(w,h)
 local view=newCargo(scene,20,20,{{id='1001',num=7},{id='1012',num=2},{id=taskId,num=1}}, {id='1002',num=3})
 local before=H.serialize(H.getData());walk(view,w,h);capture(view,w,h,'cargo')
 eq(writes,0,'opening never persists');eq(coins,0,'opening never grants');eq(H.serialize(H.getData()),before,'read-only allocation construction')
 if coherentTableTap then
  view:setScale(.8);view:setPosition(cc.p(40,50))
  local cell=view.tableview1:cellAtIndex(0);assert(cell)
  local point=cell:convertToWorldSpace(cc.p(100,54))
  assert(coherentTableTap(view.tableview1,point.x,point.y),'native scaled table accepts its visible row')
  eq(amount(view.package,'1005'),19,'native scaled coordinate selects the right food row')
  local clip=view.tableview1:getViewSize();point=view.tableview1:convertToWorldSpace(cc.p(clip.width+8,clip.height/2))
  assert(not coherentTableTap(view.tableview1,point.x,point.y),'native table rejects clipped outside touch')
  eq(amount(view.package,'1005'),19,'outside table coordinate cannot transfer')
  tap(view,2,'1005');view:setScale(1);view:setPosition(cc.p(0,0))
 end
 local a,b=view.tableview1:getViewSize(),view.tableview2:getViewSize()
 eq(a.width,b.width,'responsive columns are equal');assert(a.width*2+20<=w-56,'compact columns cannot overlap')
 view.coherentCargoButtons.settle.item:activate();eq(completed,0,'important reward blocks settle');assert(toast:find('重要道具',1,true))
 view.coherentCargoButtons.pick.item:activate();eq(coins,7,'gold fits a full hold');eq(amount(view.package,taskId),1,'zero-volume quest item fits');eq(amount(view.rewardItems,'1012'),2,'full hold leaves volume-two reward')
 view.coherentCargoButtons.pick.item:activate();eq(coins,7,'repeated pickup never grants twice')
 tap(view,1,'1005');tap(view,2,'1012');eq(view.packageSize,19,'partial volume does not round up')
 tap(view,1,'1005');tap(view,2,'1012');eq(view.packageSize,20,'two-space reward fits after exact room')
 tap(view,1,'1012');tap(view,2,'1005');eq(view.packageSize,19,'manual transfer is reversible')
 eq(amount(view.package,'1005')+amount(view.rewardItems,'1005'),20,'food conserved')
 eq(amount(view.package,'1012')+amount(view.rewardItems,'1012'),2,'reward conserved')
 -- State listeners and the original completion can synchronously re-enter.
 onWrite=function()view:settleCargo();view:pickUpAllRewards()end
 view:setFightOverCallback(function(result)
  eq(result,true,'natural callback sees unchanged result');eq(writes,1,'pack committed before callback');eq(view.isClosed,false,'original callback-before-closed order')
  completed=completed+1;order[#order+1]='callback';view:settleCargo();view:pickUpAllRewards()
 end)
 local settle=view.coherentCargoButtons.settle.item;settle:retain();settle:activate();settle:activate();settle:release()
 eq(writes,1,'listener and rapid settle commit once');eq(completed,1,'reentrant completion fires once');eq(order[#order],'callback','write precedes callback')
 eq(H.getData()[roleBattlePack]['1002'].num,3,'reserved inventory restored unchanged')
 eq(H.getData()[roleBattlePack][taskId].num,1,'important reward kept')
 eq(H.getData()[roleBattlePack]['1005'].num,19,'manual final cargo committed exactly');assert(view.isClosed)
 remove(view)
 -- Closing a scene externally is not settlement; stale controls cannot commit.
 view=newCargo(scene,20,1,{{id='1008',num=3}});local stale=view.coherentCargoButtons.settle.item;stale:retain()
 tap(view,1,'1005');local _,_,noFood=view:getCargoHint();assert(noFood,'last-food move warns');walk(view,w,h)
 remove(view);stale:activate();stale:release();eq(writes,0,'external cleanup cancels staged pack writes')
 view=newCargo(scene,20,0,{});walk(view,w,h);assert(not view.coherentCargoButtons.pick.item:isEnabled(),'empty reward disables bulk only');view.coherentCargoButtons.settle.item:activate();eq(completed,1,'empty allocation completes once');remove(view)
 -- Overflow lists exercise native clipping containers and quantities at compact widths.
 local drops={};for _,id in ipairs({'1006','1007','1008','1009','1010','1012','1022','1039','1076'})do drops[#drops+1]={id=id,num=999999}end
 view=newCargo(scene,20,20,drops);walk(view,w,h);view:pickUpAllRewards();eq(view.packageSize,20,'overflow never changes a full hold');remove(view)
 -- Inherited chest grants can exceed capacity before allocation starts.
 -- Hints describe the remaining item volumes, never impose a new cargo rule.
 view=newCargo(scene,20,22,{{id='1001',num=7}})
 local hint,detail=view:getCargoHint();assert(hint:find('超出 2 格',1,true) and hint:find('不占空间',1,true),'overfull currency hint still invites pickup')
 assert(not hint:find('腾',1,true),'currency-only pickup never asks to make room')
 local overfullBefore=H.serialize(H.getData());walk(view,w,h);capture(view,w,h,'cargo-overfull-currency')
 eq(H.serialize(H.getData()),overfullBefore,'overflow copy is read-only')
 view.coherentCargoButtons.pick.item:activate();view.coherentCargoButtons.pick.item:activate()
 eq(coins,7,'overfull currency credits once');eq(view.packageSize,22,'currency pickup preserves inherited overflow');eq(#view.rewardItems,0,'currency-only drop collected')
 hint,detail=view:getCargoHint();assert(hint:find('已全部装船',1,true) and hint:find('超出 2 格',1,true),'all-collected hint preserves overflow truth');assert(detail:find('可完成装载',1,true),'all-collected overflow can still settle')
 view.coherentCargoButtons.settle.item:activate();eq(writes,1,'overfull cargo still commits normally');eq(H.getData()[roleBattlePack]['1005'].num,22,'no implicit overflow discard');remove(view)
 view=newCargo(scene,20,22,{{id='1001',num=7},{id='1012',num=1}})
 hint,detail=view:getCargoHint();assert(hint:find('零占用物品仍可装船',1,true) and detail:find('其他物品需先腾位',1,true),'mixed rewards distinguish free pickup from volume blocked')
 view:pickUpAllRewards();view:pickUpAllRewards();eq(coins,7,'mixed overflow keeps original gold grant');eq(amount(view.rewardItems,'1012'),1,'volume reward remains blocked');eq(view.packageSize,22,'no change to overfull allowance')
 hint=view:getCargoHint();assert(hint:find('超出 2 格',1,true) and hint:find('腾出空间',1,true),'remaining volume-only loot asks for space');walk(view,w,h);remove(view)
 view=newCargo(scene,20,22,{{id=taskId,num=1}})
 hint=view:getCargoHint();assert(hint:find('不占空间',1,true),'essential zero-volume item remains collectible while overfull')
 view:settleCargo();eq(writes,0,'uncollected essential reward still blocks settlement')
 tap(view,2,taskId);eq(view.packageSize,22,'essential pickup does not consume capacity');view:settleCargo()
 eq(H.getData()[roleBattlePack][taskId].num,1,'essential reward committed exactly');eq(H.getData()[roleBattlePack]['1005'].num,22,'essential pickup never trims inherited cargo');remove(view)
 view=newCargo(scene,20,22,{})
 hint=view:getCargoHint();assert(hint:find('已全部装船',1,true) and hint:find('超出 2 格',1,true),'empty overfull reward is explicit');view:settleCargo();eq(completed,1,'empty overfull reward can complete');remove(view)
 view=newCargo(scene,20,20,{{id='1001',num=7}})
 hint=view:getCargoHint();assert(hint:find('货舱已满',1,true) and hint:find('不占空间',1,true),'exact-full currency hint also remains actionable');remove(view)
 print('PASS coherent loot native '..w..'x'..h..': full/empty/overflow, exact transfers, important/reserved items, reentry and lifecycle')
 -- Actual six-chest flow, deterministic random boundary and original paid retry.
 reset(20,0,{});firstChest=false
 local chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1);walk(chest,w,h);capture(chest,w,h,'chest-closed')
 eq(writes,0,'opening chest is read-only');eq(diamondWrites,0,'opening chest is free');assert(chest.freeInfoNode:isVisible() and not chest.costInfoNode:isVisible())
 chest:showInfo('完整物品说明',string.rep('保留原始物品说明，可滚动阅读。',20));assert(chest.coherentChestDescription:getContentSize().height>42,'long original descriptions remain scrollable');assert(chest.coherentChestDetailScroll:getContentOffset().y<0,'long description starts at its top');walk(chest,w,h)
 assert(chest.tapEventListener==nil,'Warm description is not dismissed on touch-began')
 if coherentDescriptionDrag then
  local visible,moved=coherentDescriptionDrag(chest.coherentChestDetailScroll)
  assert(visible and moved,'real dispatched description drag remains visible and scrolls')
 end
 chest:hideInfo()
 local oldRandom=math.random;math.random=function(_,max)return max end
 local first=chest.chestButtons[1];first:retain();first:activate();first:activate();first:release()
 eq(chest.openTimeTotal,1,'stale chest click cannot open twice');eq(chest.failTime,1,'original failed attempt');eq(diamondWrites,0,'failure never charges automatically');assert(chest.costInfoNode:isVisible());assert(chest.infoCost:getString():find('2 钻石',1,true));walk(chest,w,h)
 H.getData()[roleDiamond]=1;chest.chestButtons[2]:activate();eq(chest.openTimeTotal,1,'insufficient diamonds never opens');eq(diamondWrites,0,'insufficient diamonds never spends')
 H.getData()[roleDiamond]=10;math.random=function(min)return min end
 local retry=chest.chestButtons[2];retry:retain();retry:activate();retry:activate();retry:release()
 eq(H.getData()[roleDiamond],8,'paid retry spends original 2 diamonds exactly once');eq(chest.openTimeTotal,2,'paid retry opens one slot');eq(chest.rewardTime,1,'original successful reward');eq(chest.rewardRate[1],100,'original retry probability adjustment');assert(not chest.chestActivationInProgress,'native reward callback completed without swallowed errors')
 local stateBefore=H.serialize({pack=H.getData()[roleBattlePack],coins=coins,diamonds=H.getData()[roleDiamond]})
 chest:giveUpCallback();chest:giveUpCallback();walk(chest,w,h);capture(chest,w,h,'chest-revealed')
 eq(H.serialize({pack=H.getData()[roleBattlePack],coins=coins,diamonds=H.getData()[roleDiamond]}),stateBefore,'give-up fake reveal never grants')
 assert(not chest.freeInfoNode:isVisible() and not chest.costInfoNode:isVisible() and chest.closeBtn:isVisible(),'give-up exposes only completion')
 local finish=chest.coherentClose.item;finish:retain();finish:activate();finish:activate();finish:release();eq(completed,1,'rapid chest close transitions once')
 DialogueViewManager:sharedInstance():removeAllView();chest:release();math.random=oldRandom
 -- Reentry resets the chest offers; external cancel makes saved controls inert.
 chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1)
 assert(chest.freeInfoNode:isVisible() and not chest.costInfoNode:isVisible() and not chest.isUserGiveUp,'new chest starts clean')
 first=chest.chestButtons[1];first:retain();local opening=chest.openTimeTotal;DialogueViewManager:sharedInstance():removeAllView();first:activate();first:release();eq(chest.openTimeTotal,opening,'cleaned-up chest cannot grant');chest:release()
 -- All three successful original rewards are already committed before close.
 reset(20,0,{});firstChest=true;math.random=function(min)return min end
 local originalChestData=H.tables[csvOfFightBoxes]['1'];H.tables[csvOfFightBoxes]['1']=clone(originalChestData)
 chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1)
 local expected={}
 for _,prop in ipairs({chest.data.propB[1],chest.data.propC[1],{'1002',5}})do expected[tostring(prop[1])]=(expected[tostring(prop[1])] or 0)+tonumber(prop[2])end
 for i=1,3 do chest.chestButtons[i]:activate()end
 eq(chest.rewardTime,3,'original first chest has three rewards');eq(chest.openTimeTotal,3,'original first chest has three opens')
 eq(coins,expected['1001'] or 0,'original coin reward exact');eq(H.getData()[roleDiamond],10+(expected['1002'] or 0),'original third reward diamonds exact')
 for id,number in pairs(expected)do if id~='1001' and id~='1002' then eq(amount(H.getData()[roleBattlePack],id),number,'original resource reward exact')end end
 assert(chest.closeBtn:isVisible() and not chest.freeInfoNode:isVisible() and not chest.costInfoNode:isVisible(),'complete reward state exposes completion')
 local finalRewards=H.serialize({pack=H.getData()[roleBattlePack],coins=coins,diamond=H.getData()[roleDiamond]})
 chest.coherentClose.item:activate();eq(completed,1,'successful chest continues once')
 eq(H.serialize({pack=H.getData()[roleBattlePack],coins=coins,diamond=H.getData()[roleDiamond]}),finalRewards,'close does not re-grant committed rewards')
 DialogueViewManager:sharedInstance():removeAllView();chest:release();H.tables[csvOfFightBoxes]['1']=originalChestData;math.random=oldRandom
 -- Original optional seven-diamond continuation preserves cancel/shortage guards.
 reset(20,0,{});firstChest=false;chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1)
 local alert=assert(FightBoxViewAlert:create());alert:retain();alert:show();alert:stopAllActions();alert:setScale(1);walk(alert,w,h)
 H.getData()[roleDiamond]=6;alert.coherentAlertPaid.item:activate();eq(diamondWrites,0,'seven-diamond shortage never spends');assert(not alert.coherentAlertDone)
 H.getData()[roleDiamond]=10;local paid=alert.coherentAlertPaid.item;paid:retain();paid:activate();paid:activate();paid:release()
 eq(H.getData()[roleDiamond],3,'optional continuation spends exactly seven once');eq(chest.rewardRate[1],100,'optional continuation preserves original adjustment')
 DialogueViewManager:sharedInstance():removeAllView();alert:release();chest:release()
 reset(20,0,{});chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1)
 alert=assert(FightBoxViewAlert:create());alert:retain();alert:show();alert:stopAllActions();alert:setScale(1)
 alert.coherentAlertCancel.item:activate();alert.coherentAlertCancel.item:activate();eq(diamondWrites,0,'cancel continuation never spends');assert(chest.isUserGiveUp)
 DialogueViewManager:sharedInstance():removeAllView();alert:release();chest:release()
 H.finish();print('PASS coherent chest native '..w..'x'..h..': closed/open, failure, paid retry, fake reveal, exact-once grants/return and reentry')
end
-- Natural ordinary-event handoff uses the actual EventLayer entry method.
local scene=H.prepare(480,800);reset(20,12,{});local directorFactory=cc.Director.getInstance
local pushed;local handoff={};local navigation=directorFactory()
cc.Director.getInstance=function()return setmetatable({
 pushScene=function(_,value)pushed=value;value:retain();handoff[#handoff+1]='push'end,
 popScene=function()handoff[#handoff+1]='pop'end
},{__index=navigation})end
local oldBag=ExploreBagController
ExploreBagController={getBagController=function()return{addCoin=function(_,n)coins=coins+n end,
 refreshBattlePack=function()handoff[#handoff+1]='refresh'end}end}
local oldController=dataController
dataController={getResourceValueByIdAndKey=function(id,key)return H.tables[csvOfResourceInfo][tostring(id)][key]end}
local eventSource=read('bin/res/scripts/LuaClass/EventLayer.lua')
local eventStart=assert(eventSource:find('function EventLayer:enterRewardLayer(',1,true))
local eventEnd=assert(eventSource:find('function EventLayer:checkPop(',eventStart,true))
local previousEvent=EventLayer;EventLayer={}
assert(loadstring(eventSource:sub(eventStart,eventEnd-1),'@actual-event-reward-entry'))()
local event=setmetatable({enterNextLayer=function(_,a,b)eq(a,false,'same next-layer argument');eq(b,true,'same reward argument');handoff[#handoff+1]='next'end},{__index=EventLayer})
event:enterRewardLayer({{id='1008',num=1}})
assert(pushed);local cargo=pushed:getChildren()[1];eq(cargo.fightResult,false,'ordinary event is not battle victory')
cargo.coherentCargoButtons.pick.item:activate();cargo.coherentCargoButtons.settle.item:activate();cargo.coherentCargoButtons.settle.item:activate()
eq(table.concat(handoff,','),'push,pop,refresh,next','actual event resumes original scene, refreshes committed pack, then advances once')
eq(writes,1,'ordinary event commits once');eq(H.getData()[roleBattlePack]['1008'].num,1,'event reward appears in original bag')
pushed:cleanup();pushed:release();cc.Director.getInstance=directorFactory;ExploreBagController=oldBag;dataController=oldController;EventLayer=previousEvent;H.finish()
print('PASS actual EventLayer -> FightRewardScene -> pack commit -> pop -> refresh -> next callback order')
assert(#callbackErrors==0,table.concat(callbackErrors,'\n'));__G__TRACKBACK__=originalTraceback
cc.UserDefault.getInstance=realUserDefault;cc.Director.getInstance=H.realGet
print('coherent loot/chest pages native: PASS')
