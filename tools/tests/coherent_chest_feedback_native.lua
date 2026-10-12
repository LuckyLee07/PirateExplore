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
-- Unlike the broad loot fixture, exercise both actual shared currency methods.
local function loadMethod(path,first,last)
 local source=read(path);local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+#first,true))
 assert(loadstring(source:sub(a,b-1),'@'..path))()
end
ExploreBagController={}
loadMethod('bin/res/scripts/LuaClass/ExploreBagController.lua','function ExploreBagController:addCoin(','function ExploreBagController:safeTransformCoinToPack(')
loadMethod('bin/res/scripts/LuaClass/DataManager.lua','function DataManager:addDiamond(','function DataManager:unlockTallentByKey(')
dm.addDiamond=DataManager.addDiamond;dm.getSound_off=function()return 1 end
WriteColor=cc.c3b(255,255,255)
local bag,events,toasts,alerts,completed,firstWrites,firstChest
local realUserDefault=cc.UserDefault.getInstance
cc.UserDefault.getInstance=function()return{
 getBoolForKey=function(_,key,default)eq(key,'isFirtFightBox','original first-chest key');return firstChest end,
 setBoolForKey=function(_,key,value)eq(key,'isFirtFightBox','original first-chest key');firstWrites=firstWrites+1;firstChest=value end}end
ExploreBagController.getBagController=function()return bag end
dm.setRoleData=function(_,key,value,extra)eq(extra,nil,'same setRoleData extra');H.getData()[key]=value;events[#events+1]={key,value}end
ToastUtil.downString=function(_,message)toasts[#toasts+1]=message end
ToastUtil.toastString=ToastUtil.downString
package.loaded['LuaClass/ToastUtil']=true -- Preserve the test sink when availability is loaded.
-- Use native nodes/labels for original shortage text, without invoking shop UI.
AlertView={create=function(_,dtype,boxtype,title)
 eq(title,'购买失败','unchanged shortage alert');alerts=alerts+1
 local node=cc.Node:create();node.s_position=cc.p(240,400);cc.Director:getInstance():getRunningScene():addChild(node)
 return node
end}
local Dialog=require 'LuaClass/WarmDialog';local originalDialogShow=Dialog.show
Dialog.show=function(...)alerts=alerts+1;return originalDialogShow(...)end
FightScene={instance={gotoFightRewardScene=function(_,delay)eq(delay,.5,'same completion delay');completed=completed+1 end}}
local function reset(isFirst)
 local scene=cc.Director:getInstance():getRunningScene();if scene.adventureDialog then scene.adventureDialog.close()end
 H.fixture();local d=H.getData();d[roleBattlePack]={['1005']={id='1005',num=22}};d[rolePackSize]=20;d[roleDiamond]=10;d[roleMapCoin]=0
 bag=setmetatable({mapCoin=0},{__index=ExploreBagController});events={};toasts={};alerts=0;completed=0;firstWrites=0;firstChest=isFirst
end
local function snapshot()return H.serialize({data=H.getData(),bagCoin=bag.mapCoin})end
local function create()
 local chest=assert(FightBoxView:create());chest:retain();chest:show();chest:stopAllActions();chest:setScale(1);return chest
end
local function remove(chest)DialogueViewManager:sharedInstance():removeAllView();chest:release()end
local function label(chest)return chest.showInfoNode:getChildByTag(1):getString()end
local function inspect(chest,id,num,earned)
 local name=H.tables[csvOfResourceInfo][id].name
 eq(label(chest),name..' × '..num..(earned and ' · 已收入' or ' · 未获得'),'one persistent exact receipt')
 assert(chest.showInfoNode:isVisible(),'receipt visible')
 local n=chest.showInfoNode:getChildByTag(1);local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
 local width=cc.Director:getInstance():getVisibleSize().width
 assert(a.x>=0 and b.x<=width,'receipt fits compact viewport')
end
local function capture(chest,w,h,name)
 if coherentCapture and os.getenv('COHERENT_LOOT_CAPTURE_DIR')then
  assert(coherentCapture(chest,w,h,os.getenv('COHERENT_LOOT_CAPTURE_DIR')..'/feedback-'..name..'-'..w..'x'..h..'.png'))
 end
end
local originalBoxData=clone(H.tables[csvOfFightBoxes]['1']);local oldRandom=math.random
-- Native counterparts of the optional-flag matrix: actual methods/native labels.
H.prepare(480,800);WARM_PIRATE_V1=true
local function option(value)if value~='omitted' then return value end end
for _,flag in ipairs({'omitted',true,false})do
 for _,amount in ipairs({5,0,-3})do
  reset(false);bag:addCoin(amount,option(flag))
  eq(bag.mapCoin,amount,'native coin arithmetic');eq(H.getData()[roleMapCoin],amount,'native map coin write');eq(#events,1,'one native coin write')
  eq(#toasts,flag==false and 0 or 2,'native coin feedback flag')
  reset(false);eq(dm:addDiamond(amount,nil,option(flag)),1,'native diamond success')
  eq(H.getData()[roleDiamond],10+amount,'native diamond arithmetic');eq(#events,1,'one native diamond write')
  eq(#toasts,amount>0 and flag~=false and 1 or 0,'native positive-only success flag')
 end
 for _,showAlert in ipairs({'omitted',true,false})do
  reset(false);eq(dm:addDiamond(-11,option(showAlert),option(flag)),0,'native shortage return')
  eq(H.getData()[roleDiamond],10,'native shortage balance');eq(#events,0,'native shortage never writes')
  eq(#toasts,0,'native shortage never reports success');eq(alerts,showAlert==false and 0 or 1,'native original shortage-control flag')
 end
end
H.finish();print('PASS native actual helper flag matrix: omitted/true/false, positive/zero/negative and shortage alert combinations')
for _,size in ipairs({{480,800},{540,900},{640,960},{720,1280}})do
 local w,h=size[1],size[2];H.prepare(w,h);WARM_PIRATE_V1=true;reset(true)
 -- Deterministic rewards through the actual constructor and six-slot callbacks.
 local fixture=clone(originalBoxData);fixture.propB={{'1001','50'}};fixture.propC={{'1008','2'}};fixture.propA={{'1012','3'}}
 H.tables[csvOfFightBoxes]['1']=fixture;math.random=function(min)return min end
 local chest=create();eq(#events,0,'opening is read-only')
 for i,prop in ipairs({{'1001',50},{'1008',2},{'1002',5}})do
  local old=chest.chestButtons[i];old:retain();local before=#events;old:activate();old:activate();old:release()
  eq(chest.openTimeTotal,i,'stale repeated activation cannot open twice');eq(#events,before+1,'one grant/write per successful chest')
  eq(#toasts,0,'coherent reward has no overlapping success toast');eq(alerts,0,'free chests show no shortage')
  inspect(chest,prop[1],prop[2],true)
  local before=snapshot();chest.chestButtons[i]:activate();eq(snapshot(),before,'reward inspection never regrants');eq(#events,i,'inspection never writes');inspect(chest,prop[1],prop[2],true)
  capture(chest,w,h,'earned-'..prop[1])
 end
 eq(bag.mapCoin,50,'gold retained in map bank');eq(H.getData()[roleMoney],30,'gold never moved early into home bank')
 eq(H.getData()[roleDiamond],15,'third first-time chest credits exactly five diamonds immediately')
 eq(H.getData()[roleBattlePack]['1008'].num,2,'material credited exactly once despite full hold')
 eq(H.getData()[roleBattlePack]['1005'].num,22,'inherited overflow unchanged')
 eq(events[1][1],roleMapCoin,'gold write ordering');eq(events[2][1],roleBattlePack,'material write ordering');eq(events[3][1],roleDiamond,'diamond write ordering')
 eq(firstWrites,0,'first-time ownership stays with close');eq(completed,0,'open never completes fight')
 local before=snapshot();local close=chest.coherentClose.item;close:retain();close:activate();close:activate();close:release()
 eq(snapshot(),before,'close never regrants');eq(firstWrites,1,'first-time flag written once on close');eq(completed,1,'completion callback once');remove(chest)
 -- Non-first failure, original shortage, two-diamond retry, fake reveal, drag.
 reset(false);math.random=function(_,max)return max end;chest=create();chest.chestButtons[1]:activate()
 eq(#events,0,'empty chest grants/spends nothing');eq(chest.failTime,1,'original failure count');eq(#toasts,0,'empty state has no generic success toast')
 H.getData()[roleDiamond]=1;chest.chestButtons[2]:activate();eq(alerts,1,'shortage remains visible');eq(#events,0,'shortage never writes');eq(chest.openTimeTotal,1,'shortage never opens')
 local shortage=cc.Director:getInstance():getRunningScene().adventureDialog
 if shortage then shortage.warmOptions[#shortage.warmOptions].item:activate()end
 H.getData()[roleDiamond]=10;math.random=function(min)return min end
 local old=chest.chestButtons[2];old:retain();old:activate();old:activate();old:release()
 eq(H.getData()[roleDiamond],8,'retry costs exactly two');eq(events[1][1],roleDiamond,'spend precedes reward');eq(events[2][1],roleMapCoin,'reward follows spend');eq(#events,2,'exact spend/grant count');eq(bag.mapCoin,50,'retry gold exact');eq(#toasts,0,'retry has one persistent receipt');inspect(chest,'1001',50,true)
 local before=snapshot();chest:giveUpCallback();chest:giveUpCallback();eq(snapshot(),before,'fake reveal never grants')
 local fake
 for i,prop in ipairs(chest.props)do if chest.boxStates[i]~=FightBoxView.BoxState.open then fake=i;break end end
 if not fake then for i=1,6 do if chest.props[i] and chest.boxStates[i]~=FightBoxView.BoxState.open then fake=i;break end end end
 assert(fake,'unearned revealed chest');chest.chestButtons[fake]:activate();local p=chest.props[fake];inspect(chest,tostring(p[1]),p[2],false)
 eq(snapshot(),before,'unearned inspection never grants');capture(chest,w,h,'unearned')
 chest:showInfo(H.tables[csvOfResourceInfo]['1008'].name,string.rep('保留原始物品说明，可滚动阅读。',20),999999,true)
 inspect(chest,'1008',999999,true)
 if coherentDescriptionDrag then local visible,moved=coherentDescriptionDrag(chest.coherentChestDetailScroll);assert(visible and moved,'real receipt description drag remains visible and scrolls')end
 eq(snapshot(),before,'detail drag never changes grant state');eq(#toasts,0,'detail/reveal never emits reward toasts');remove(chest)
 H.finish();print('PASS actual chest feedback '..w..'x'..h..': three free receipts, zero duplicate toasts, exact currency/material writes, overflow, repeat, shortage, paid retry, fake reveal and native drag when available')
end
-- Legacy constructor and original receipt text/toast counts remain unchanged.
H.prepare(640,1136);WARM_PIRATE_V1=false;reset(true);math.random=function(min)return min end
H.tables[csvOfFightBoxes]['1']=clone(originalBoxData);local d=H.tables[csvOfFightBoxes]['1'];d.propB={{'1001','50'}};d.propC={{'1008','2'}};d.propA={{'1012','3'}}
local chest=create();assert(not chest.coherentChest)
for i,prop in ipairs({{'1001',50},{'1008',2},{'1002',5}})do chest.chestButtons[i]:activate();eq(label(chest),H.tables[csvOfResourceInfo][prop[1]].name,'legacy detail unchanged')end
eq(table.concat(toasts,'|'),'金币+50|总共80金币|打开宝箱成功!|钻石+5','legacy success feedback unchanged')
eq(#events,3,'legacy same three grants');eq(H.getData()[roleDiamond],15,'legacy first-time diamond award unchanged');remove(chest)
-- Ordinary manual currency rewards preserve native feedback with omitted flags.
reset(false);bag:addCoin(7);dm:addDiamond(3,false);eq(table.concat(toasts,'|'),'金币+7|总共37金币|钻石+3','manual rewards unchanged')
ToastUtil:downString('普通错误提示');eq(toasts[#toasts],'普通错误提示','ordinary errors unsuppressed')
H.finish();Dialog.show=originalDialogShow;H.tables[csvOfFightBoxes]['1']=originalBoxData;math.random=oldRandom;cc.UserDefault.getInstance=realUserDefault;cc.Director.getInstance=H.realGet
assert(#callbackErrors==0,table.concat(callbackErrors,'\n'));__G__TRACKBACK__=originalTraceback
print('PASS native legacy opt-out, default manual rewards and ordinary errors unchanged; all state was in memory')
