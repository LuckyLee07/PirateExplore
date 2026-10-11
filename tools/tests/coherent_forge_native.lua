-- Real focused BuildLayer/BaseView, shipped data/art/font, and native callbacks.
-- In-memory economy and unlock-boundary spies only; no app, profile or save.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,fixture=fixture,event=event,serialize=serialize,
 getData=function()return data end,visit=visit,realGet=realGet,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,
 countEvents=countEvents,failures=failures}
]],'@focused-forge-native-fixture'))()
local dm=H.dm
UITopHeight=100;UIBottomHeight=136
WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
for _,recipe in pairs(H.tables[csvOfBuild])do
 local rows={}
 for part in tostring(recipe.resume or ''):gmatch('[^;]+')do
  local id,num=part:match('^([^_]+)_([^_]+)$');if id and num then rows[#rows+1]={id,num}end
 end
 recipe.resume=rows
end
local guide=GuideController:getInstance()
guide.addRedPoint=function()end;guide.removeRedPoint=function()end
local guideGet=guide.getIsHaveStep;local buildUnlocked=true
guide.getIsHaveStep=function(self,step,...)if step==1 then return buildUnlocked end;return guideGet(self,step,...)end
dm.isShowDiamondStoreRedPointer=function()return false end
dm.checkDiamondStoreNewGoods=function()return false end
dm.getSound_off=function()return 1 end
dm.cleanNewUnlock=function(_,kind)assert(kind==kUnlockBuild)end
dm.getPackNumWithId=function(_,id)
 local data=H.getData();return id=='1001' and data[roleMoney]or(data[rolePack][id]or 0)
end
local deductions,unlocks,toasts,shortages,backs=0,0,0,0,0
local mutationOrder={}
dm.addPackItemWithId=function(_,id,delta)
 assert(delta<0,'focused Build cannot grant items')
 deductions=deductions+1;mutationOrder[#mutationOrder+1]='deduct:'..id
 local data=H.getData()
 if id=='1001' then data[roleMoney]=data[roleMoney]+delta;H.event(roleMoney)
 else data[rolePack][id]=(data[rolePack][id]or 0)+delta;H.event(rolePack)end
end
dm.createSuccessCheck=function(_,kind,id)
 assert(kind==kUnlockBuild and id=='57','original unlock owner receives original forge ID')
 unlocks=unlocks+1;mutationOrder[#mutationOrder+1]='unlock:'..id
 local data=H.getData();for _,entry in ipairs(data[roleBuilding])do if entry[dataKeyID]==id then entry[dataKeyNum]=1 end end
 H.event(roleBuilding)
end
ToastUtil.downString=function(_,text)assert(text=='建造成功');toasts=toasts+1 end
require 'LuaClass/BuildMode'
local W=require 'LuaClass/WarmTheme'
local forgeIcon=H.tables[csvOfBuild]['57'].iconName
assert(type(forgeIcon)=='string' and forgeIcon~='' and cc.FileUtils:getInstance():isFileExist('Images/Icon/'..forgeIcon),'focused forge uses the original existing shipped iconName')
local actualLackCreate=Lackmaterial.create
local missing,missingCallback
Lackmaterial.create=function(_,items,callback)
 shortages=shortages+1;missing=items;missingCallback=callback
 return {show=function()end}
end
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function walk(page,w,h)
 local texts,primary={},0
 H.visit(page,function(n,visible)
  if visible and n.getString then
   local text=n:getString();texts[text]=true
   local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,'native focused label bounds: '..text)
   if n.getFontName then equal(n:getFontName(),W.font,'focused font')end
  end
 end)
 for key,n in pairs(page.focusedButtons)do
  if key=='build' then primary=primary+1 end
  local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
  assert(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,'focused button bounds: '..key)
 end
 assert(primary<=1,'only one primary construction action')
 for _,text in ipairs({'钻石商城','天赋','情报','炼金','首返补助'})do
  for value in pairs(texts)do assert(not value:find(text,1,true),'unrelated chrome must be absent: '..value)end
 end
 assert(page.tableview==nil and not page.isHaveInfo,'focused entry has no scrolling dashboard or system feed')
 assert(page.approvedPage and page.keepNavigation==false,'existing MainMenu hook hides currency and redundant Back')
 equal(page.roleBuildingData,H.getData()[roleBuilding],'live building list identity is untouched')
 return texts
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2];H.fixture();local scene=H.prepare(w,h);local data=H.getData()
 buildUnlocked=true
 data[roleBuilding]={{[dataKeyID]='58',[dataKeyNum]=0},{[dataKeyID]='57',[dataKeyNum]=0},{[dataKeyID]='6',[dataKeyNum]=1}}
 data[roleMoney]=25;data[rolePack]={['1006']=15,['1008']=2}
 local before=H.serialize(data);local beforeD,beforeU=deductions,unlocks
 local view=assert(BuildLayer:create('57'));view:retain();scene:addChild(view)
 local active=view
 zqDispatch={rightNode=view,mainMenu={openRoute=function(_,route)
  equal(route,0,'Back follows original Home route');backs=backs+1
  active:viewWillDestory();active:destory();active:removeFromParent(true)
 end}}
 local texts=walk(view,w,h)
 assert(texts[H.tables[csvOfBuild]['57'].name],'original forge name retained')
 equal(#view.focusedCostRows,3,'all actual forge recipe costs displayed')
 equal(H.countEvents(),4,'focused entry subscribes only to its four relevant state keys')
 equal(H.serialize(data),before,'opening focused forge never mutates state')
 equal(deductions,beforeD,'opening never spends');equal(unlocks,beforeU,'opening never unlocks')
 local stale=view.focusedButtons.build.item;stale:retain()
 local needById={};for _,row in ipairs(view.focusedCostRows)do needById[row.id]=row.need end
 equal(needById['1001'],25,'shipped coin cost');equal(needById['1006'],15,'shipped stone cost');equal(needById['1008'],2,'shipped iron cost')
 data[roleMoney]=24;H.event(roleMoney);stale:activate()
 equal(deductions,beforeD,'stale pre-refresh build cannot spend')
 stale:release();walk(view,w,h)
 local beforeS=shortages;view.focusedButtons.build.item:activate()
 equal(shortages,beforeS+1,'current shortages use existing material-acquisition callback')
 equal(#missing,1,'only actual missing resource passed');equal(missing[1].mtId,'1001','missing coins');equal(missing[1].mtnum,'1','exact shortfall')
 equal(deductions,beforeD,'opening material-acquisition never spends')
 data[roleMoney]=25;missingCallback();walk(view,w,h)
 stale=view.focusedButtons.build.item;stale:retain();mutationOrder={};stale:activate();stale:activate();stale:release()
 equal(deductions,beforeD+3,'one deduction per original recipe row')
 equal(unlocks,beforeU+1,'rapid/stale double-click unlocks only once')
 equal(mutationOrder[#mutationOrder],'unlock:57','original unlock runs after all original resource deductions')
 equal(data[roleMoney],0,'exact coins spent');equal(data[rolePack]['1006'],0,'exact stone spent');equal(data[rolePack]['1008'],0,'exact iron spent')
 equal(#data[roleBuilding],3,'focused build never loses other unlocked/current buildings')
 equal(data[roleBuilding][1][dataKeyID],'58','focused lookup does not reorder list')
 equal(data[roleBuilding][3][dataKeyNum],1,'previously built entry survives')
 texts=walk(view,w,h);assert(texts['已建设'] and not view.focusedButtons.build,'built detail cannot repeat construction')
 local back=view.focusedButtons.back.item;back:retain();local beforeBack=backs;back:activate();back:activate();back:release()
 equal(backs,beforeBack+1,'Back acts exactly once')
 equal(H.countEvents(),0,'Back removes all focused listeners')
 assert(view.focusedBuildDisposed,'Back disposes focused callbacks');view:release()
 -- Missing targets and a late guide change cannot invent a build action.
 view=assert(BuildLayer:create('999999'));view:retain();scene:addChild(view);active=view
 walk(view,w,h);assert(not view.focusedButtons.build,'unknown target is honestly unavailable')
 view:destory();view:removeFromParent(true);view:release()
 data[roleBuilding][2][dataKeyNum]=0
 view=assert(BuildLayer:create('57'));view:retain();scene:addChild(view);active=view
 beforeD=deductions;local latest=view.focusedButtons.build.item;latest:retain()
 buildUnlocked=false;latest:activate();latest:release()
 equal(deductions,beforeD,'late guide lock blocks original transaction')
 assert(not view.focusedButtons.build,'late locked page removes action')
 view:destory();view:removeFromParent(true);view:release()
 equal(H.countEvents(),0,'all focused lifecycle subscriptions cleared')
 H.finish();print('PASS coherent native focused forge '..w..'x'..h..': original costs, quiet bounds, read-only open, exact transaction, stale guards, Back and cleanup')
end
Lackmaterial.create=actualLackCreate;cc.Director.getInstance=H.realGet
assert(toasts==unlocks,'one original success toast per original successful build')
assert(#H.failures==0,table.concat(H.failures,'\n'))
