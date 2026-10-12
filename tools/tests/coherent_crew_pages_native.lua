-- Actual native crew/shortage pages with shipped CSVs and isolated state spies.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,event=event,serialize=serialize,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,countEvents=countEvents}
]],'@coherent-crew-pages-fixture'))()
local dm=H.dm;local W=require 'LuaClass/WarmTheme'
local assertSubscriptionClean=dofile('tools/tests/coherent_subscription_probe.lua')(H.dm)
UITopHeight=100;UIBottomHeight=136;WriteColor=cc.c3b(255,255,255);BaseColor=W.colors.ink
H.tables[csvOfSkillAttribute]=H.csv('skillAttribute');H.tables[csvOfBuff]=H.csv('buff');H.tables[csvOfWorker]=H.csv('worker')
local function rows(value)
 if type(value)=='table' then return value end
 local out={};for part in tostring(value or ''):gmatch('[^;]+') do local r={};for field in part:gmatch('[^_]+')do r[#r+1]=field end;out[#out+1]=r end;return out
end
for _,soldier in pairs(H.tables[csvOfSoilderAttribute])do soldier.produceResume=rows(soldier.produceResume);soldier.changeJob=rows(soldier.changeJob)end
for _,resource in pairs(H.tables[csvOfResourceInfo])do resource.resume=rows(resource.resume)end
local prices={['1006']=2,['1007']=3,['1008']=4}
local mutations,achievements,recruitedStep=0,0,false
local guide=GuideController:getInstance();guide.addRedPoint=function()end;guide.removeRedPoint=function()end
local actualGuide=guide.getIsHaveStep
guide.getIsHaveStep=function(self,step,...)if step==11 then return recruitedStep end;return actualGuide(self,step,...)end
guide.addStep=function(_,step)assert(step==11);recruitedStep=true end
dm.isShowDiamondStoreRedPointer=function()return false end;dm.checkDiamondStoreNewGoods=function()return false end
dm.getSound_off=function()return 1 end;dm.getStoreUnlockTable=function()return prices end
dm.addCoin=function(_,delta)local data=H.getData();if data[roleMoney]+delta<0 then return 0,-delta-data[roleMoney] end;mutations=mutations+1;data[roleMoney]=data[roleMoney]+delta;H.event(roleMoney);return 1,0 end
dm.addPackItemWithId=function(_,id,delta)local data=H.getData();mutations=mutations+1;if id=='1001' then data[roleMoney]=data[roleMoney]+delta;H.event(roleMoney)else data[rolePack][id]=(data[rolePack][id]or 0)+delta;H.event(rolePack)end end
dm.setRoleData=function(_,key,value)mutations=mutations+1;H.getData()[key]=value;H.event(key)end
dm.setAchievementInfo=function()achievements=achievements+1 end
ToastUtil.toastString=function(_,text)_G.lastToast=text end
require 'LuaClass/TrainMode';require 'LuaClass/Lackmaterial'
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function settle(view) view:stopAllActions();view:setScale(1) end
local function walk(view,w,h)
 local text={}
 H.visit(view,function(node,visible)
  if visible and node.getString and node:getString()~='' then
   text[node:getString()]=true
   local z=node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=w+1,'text x bounds '..node:getString()..' '..a.x..' '..b.x)
   -- Native tables may retain one clipped overscan row; all fixed content is bounded.
   local ancestor=node:getParent();local inTable=false
   while ancestor and ancestor~=view do if ancestor.getViewSize then inTable=true;break end;ancestor=ancestor:getParent()end
   if not inTable then assert(a.y>=-1 and b.y<=h+1,'text y bounds '..node:getString()) end
   if node.getFontName then eq(node:getFontName(),W.font,'shared font') end
  end
 end)
 return text
end
local function dismissAll()DialogueViewManager:sharedInstance():removeAllView()end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2];H.fixture();local scene=H.prepare(w,h);local data=H.getData();recruitedStep=false
 data[roleSoildierQueue]={};data[roleSelectUnit]={};data[rolePack]={};data[roleMoney]=3;data[roleMake]={};data[roleProducerQueue]={}
 local before=H.serialize(data);local startMutations=mutations
 local train=assert(TrainLayer:create());train:retain();scene:addChild(train)
 local texts=walk(train,w,h);assert(texts['还没有船员']);eq(H.serialize(data),before,'empty opening read-only')
 assert(train.approvedPage and not train.keepNavigation and not train.isHaveInfo,'no dense legacy footer/feed')
 eq(train.coherentRosterSummary.owned,0,'empty ownership is honest')
 local stale=train.coherentRecruitButton.item;stale:retain()
 train.coherentRecruitButton.item:activate();local recruit=train.coherentRecruitDialog;assert(recruit);settle(recruit);walk(recruit,w,h)
 eq(mutations,startMutations,'recruit preview never spends')
 local confirm=recruit.coherentConfirm.item;confirm:retain();confirm:activate();confirm:activate();confirm:release()
 eq(data[roleMoney],0,'exact original 3 gold recruit');eq(data[roleSoildierQueue]['100'][dataKeyNum],1,'recruit creates one original sailor')
 eq(train.tableview:getContentOffset().y,204,'one sailor aligns to top of 300px roster')
 assert(recruitedStep,'recruit preserves guide11');eq(achievements,(_G.lastCrewAchievement or 0)+1,'one recruit achievement');_G.lastCrewAchievement=achievements
 dismissAll();stale:activate();stale:release();eq(data[roleSoildierQueue]['100'][dataKeyNum],1,'stale recruit cannot repeat')
 train.coherentRecruitButton.item:activate();recruit=train.coherentRecruitDialog;settle(recruit);recruit.coherentConfirm.item:activate()
 assert(recruit.coherentAlchemy,'zero gold keeps clear recovery route');eq(data[roleMoney],0,'insufficient gold never spends');walk(recruit,w,h);dismissAll()
 local sailor=H.tables[csvOfSoilderAttribute]['100'];local job=assert(ChangeJobView:create(sailor,1));job:show();settle(job);walk(job,w,h)
 local choiceBefore=H.serialize(data)
 for i=#sailor.changeJob,1,-1 do job.coherentChoices[i].item:activate();eq(job.coherentTarget[dataKeyID],sailor.changeJob[i][1],'real profession option');walk(job,w,h)end
 eq(H.serialize(data),choiceBefore,'profession selection read-only')
 local promoted=job.coherentTarget;assert(promoted and promoted.name and #promoted.produceResume>0)
 local old=job.coherentPromote.item;old:retain();local beforePromote=mutations;old:activate();eq(mutations,beforePromote,'missing promotion materials cannot spend')
 for _,req in ipairs(promoted.produceResume)do data[rolePack][tostring(req[2])]=tonumber(req[3])end
 H.event(rolePack);old:activate();eq(mutations,beforePromote,'stale promotion button invalidated');old:release()
 data[roleSelectUnit]={['10100']=1};local selectedBefore=H.serialize(data[roleSelectUnit]);walk(job,w,h)
 local promote=job.coherentPromote.item;promote:retain();promote:activate();promote:activate();promote:release()
 eq(data[roleSoildierQueue]['100'],nil,'promotion consumes one source sailor')
 eq(data[roleSoildierQueue][tostring(promoted[dataKeyID])][dataKeyNum],1,'promotion grants original chosen profession')
 eq(data[roleSelectUnit]['10100'],nil,'original selected unit clamp retained')
 for _,req in ipairs(promoted.produceResume)do eq(data[rolePack][tostring(req[2])],0,'exact original promotion consumption')end
 _G.lastCrewAchievement=achievements;dismissAll()
 -- A real manufactured recipe is selected from the shipped promotion requirements.
 local materialId=tostring(promoted.produceResume[1][2]);local recipe=H.tables[csvOfResourceInfo][materialId]
 assert(recipe and #recipe.resume>0 and tonumber(recipe.resume[1][1]),'shipped training material has a recipe')
 data[roleMake]={{[dataKeyID]=materialId}};data[roleMoney]=100000
 for _,req in ipairs(recipe.resume)do data[rolePack][tostring(req[1])]=tonumber(req[2])end
 local material=assert(MaterialView:create(1,materialId,0,1,prices,0,materialId,1));material:show();settle(material);walk(material,w,h)
 local synth=material.coherentCommit.item;synth:retain();synth:activate();synth:activate();synth:release()
 eq(data[rolePack][materialId],1,'synthesis grants once')
 for _,req in ipairs(recipe.resume)do local id=tostring(req[1]);eq(id=='1001' and data[roleMoney] or data[rolePack][id],id=='1001' and 100000-tonumber(req[2]) or 0,'exact synthesis input')end
 dismissAll()
 -- Shortages use live counts and one bounded scrolling list, including late stock changes.
 data[rolePack]['1006']=0;local callbacks=0;local list={{mtId='1006',mtname='石头',mtprice='2',mtnum='3',mtStar='1',mtonlyProduce='0'}}
 local lack=Lackmaterial:create(list,function()callbacks=callbacks+1 end);lack:show();settle(lack);walk(lack,w,h)
 eq(lack.coherentRows[1].missing,3,'exact initial shortage')
 old=lack.coherentRows[1].button.item;old:retain();data[rolePack]['1006']=1;H.event(rolePack);old:activate();old:release();eq(callbacks,0,'late stock invalidates old purchase')
 eq(lack.coherentRows[1].missing,2,'exact live shortage');local gold=data[roleMoney]
 local buy=lack.coherentRows[1].button.item;buy:retain();buy:activate();buy:activate();buy:release()
 eq(data[roleMoney],gold-4,'purchase spends current deficit only');eq(data[rolePack]['1006'],3,'purchase fills deficit exactly');eq(callbacks,1,'caller refresh once')
 dismissAll()
 local route;zqDispatch={moveToResource=function()route='production'end,moveToRepository=function()route='alchemy'end,moveToExpedition=function()route='explore'end,gotoStore=function()route='store'end}
 lack=Lackmaterial:create({{mtId='1001',mtname='金币',mtprice='1',mtnum='3',mtStar='1',mtonlyProduce='0'}},function()end);lack:show();settle(lack);lack.coherentRows[1].button.item:activate()
 eq(route,'alchemy','gold shortage opens original warehouse/alchemy route');eq(DialogueViewManager:sharedInstance():Count(),0,'source route removes full obsolete stack')
 -- Every acquisition family remains a real, safe destination.
 data[rolePack]['1006']=0;data[roleMoney]=100
 local acquisition=MaterialView:create(2,'石头',3,6,3,1,'1006',0);acquisition:show();settle(acquisition);walk(acquisition,w,h)
 local item=acquisition.coherentCommit.item;item:retain();item:activate();item:activate();item:release()
 eq(data[roleMoney],94,'nested acquisition exact price');eq(data[rolePack]['1006'],3,'nested acquisition exact quantity');dismissAll()
 for _,mode in ipairs({3,4})do
  acquisition=MaterialView:create(mode,'石头',0,3,{},0,'1006',0);acquisition:show();settle(acquisition);walk(acquisition,w,h)
  acquisition.coherentSource.item:activate();eq(route,mode==3 and 'explore' or 'store','material source route');eq(DialogueViewManager:sharedInstance():Count(),0,'source clears sheets')
 end
 local workerId
 for id,row in pairs(H.tables[csvOfWorker])do
  for _,out in ipairs(rows(row.produce))do if tostring(out[1])=='1006' and (tonumber(out[2])or 0)>0 and row.resume then workerId=id;break end end
  if workerId then break end
 end
 assert(workerId,'shipped stone producer')
 data[roleProducerQueue]={};data[rolePack]['1006']=0
 lack=Lackmaterial:create({{mtId='1006',mtname='石头',mtprice='2',mtnum='3',mtStar='1',mtonlyProduce='1'}},function()end);lack:show();settle(lack)
 assert(not lack.coherentRows[1].button,'locked production route is absent')
 data[roleProducerQueue]={{[dataKeyID]=workerId,[dataKeyNum]=0}};H.event(roleProducerQueue)
 assert(lack.coherentRows[1].button,'zero-worker unlocked production stays reachable');walk(lack,w,h)
 acquisition=MaterialView:create(2,'石头',3,6,3,1,'1006',0);acquisition:show();settle(acquisition)
 eq(DialogueViewManager:sharedInstance():Count(),2,'nested source stack')
 acquisition.coherentProduction.item:activate();eq(route,'production','production uses original route');eq(DialogueViewManager:sharedInstance():Count(),0,'production removes full nested stack')
 -- Full shipped roster, long numeric counts and live refresh retain scroll position.
 data[roleSoildierQueue]={};data[roleSelectUnit]={};local roster=0
 for id,soldier in pairs(H.tables[csvOfSoilderAttribute])do
  if soldier.icon and soldier.icon:find('j_',1,true) and tonumber(id)>=100 then
   data[roleSoildierQueue][id]={[dataKeyID]=id,[dataKeyNum]=1234567};roster=roster+1
  end
 end
 H.event(roleSoildierQueue);assert(roster>30);walk(train,w,h)
 train.tableview:setContentOffset(cc.p(0,-100));H.event(roleMoney);eq(train.tableview:getContentOffset().y,-100,'live refresh keeps roster scroll');walk(train,w,h)
 local many={};for i=1,8 do many[i]={mtId=tostring(1005+i),mtname='材料'..i,mtprice='2',mtnum='1234567',mtStar='1',mtonlyProduce='0'}end
 lack=Lackmaterial:create(many,function()end);lack:show();settle(lack);assert(lack.coherentSheetBounds.height<=584,'long deficit list bounded');walk(lack,w,h);dismissAll()
 train:destory();train:removeFromParent(true);train:release();eq(H.countEvents(),0,'all page and nested listeners removed')
 H.finish();assertSubscriptionClean();print('PASS coherent crew pages native '..w..'x'..h..': empty recovery, confirmed recruitment, live promotion, synthesis, shortage, exact deltas, stale guards and cleanup')
end
print('coherent crew pages native: PASS')
