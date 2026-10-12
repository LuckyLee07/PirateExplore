-- Production recipe pages, native Cocos tables/SDButtons/fonts/callbacks.
-- CSVs are shipped assets; state and transaction boundary are in-memory spies.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,event=event,serialize=serialize,
 getData=function()return data end,visit=visit,realGet=realGet,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end,
 countEvents=countEvents,failures=failures}
]],'@coherent-recipe-native-fixture'))()
UITopHeight=100;UIBottomHeight=136;WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
for _,kind in ipairs({csvOfBuild,csvOfResourceInfo})do
 for _,recipe in pairs(H.tables[kind])do
  local rows={};for part in tostring(recipe.resume or ''):gmatch('[^;]+')do
   local id,num=part:match('^([^_]+)_([^_]+)$');if id and num then rows[#rows+1]={id,num}end
  end;recipe.resume=rows
 end
end
local W=require 'LuaClass/WarmTheme'
require 'LuaClass/BuildMode';require 'LuaClass/MakeMode';require 'LuaClass/SDButton'
local dm,guide=H.dm,GuideController:getInstance()
local locked,modal=false,false
local guideSteps={}
guide.addRedPoint=function()end;guide.removeRedPoint=function()end
guide.getIsHaveStep=function(_,step)return not locked end
guide.addStep=function(_,step,red)guideSteps[#guideSteps+1]={step,red}end
dm.isShowDiamondStoreRedPointer=function()return false end;dm.checkDiamondStoreNewGoods=function()return false end
dm.getSound_off=function()return 1 end
dm.cleanNewUnlock=function(_,kind)assert(kind==kUnlockBuild or kind==kUnlockMake)end
dm.getPackNumWithId=function(_,id)local data=H.getData();return id=='1001' and data[roleMoney]or(data[rolePack][id]or 0)end
local changes,unlocks,toasts={},0,0
local expectedKind,expectedId,removeMade=nil,nil,false
dm.addPackItemWithId=function(_,id,delta)
 changes[#changes+1]={id,delta};local data=H.getData()
 if id=='1001'then data[roleMoney]=data[roleMoney]+delta;H.event(roleMoney)
 else data[rolePack][id]=(data[rolePack][id]or 0)+delta;H.event(rolePack)end
end
dm.createSuccessCheck=function(_,kind,id)
 assert(kind==expectedKind and id==expectedId,'transaction receives exact original type and ID/sortId')
 unlocks=unlocks+1;local data=H.getData()
 if kind==kUnlockBuild then
  for _,entry in ipairs(data[roleBuilding])do if entry[dataKeyID]==id then entry[dataKeyNum]=1 end end
  H.event(roleBuilding)
 else
  if removeMade then
   local rows={};for _,entry in ipairs(data[roleMake])do if entry.sortId~=id then rows[#rows+1]=entry end end;data[roleMake]=rows
  end
  H.event(roleMake)
 end
end
ToastUtil.downString=function(_,text)assert(text=='建造成功' or text=='制造成功');toasts=toasts+1 end
DialogueViewManager={sharedInstance=function()return{empty=function()return not modal end}end}
local shortages,missing,missingCallback=0,nil,nil
Lackmaterial.create=function(_,items,callback)shortages=shortages+1;missing=items;missingCallback=callback;return{show=function()end}end
local assertions=0
local function check(ok,why)assertions=assertions+1;assert(ok,why)end
local function equal(a,b,why)check(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function fillCosts(recipe)
 for _,cost in ipairs(recipe.resume)do local id,n=tostring(cost[1]),tonumber(cost[2]);local data=H.getData();if id=='1001'then data[roleMoney]=n else data[rolePack][id]=n end end
end
local function checkBounds(node,w,h,why,viewSize)
 local z=viewSize or node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(z.width,z.height))
 check(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,why..' screen bounds')
end
local function inspect(page,w,h)
 check(page.approvedPage and page.keepNavigation==false,'page owns framing')
 check(not page.isHaveInfo and not page.storeMenu:isVisible(),'no competing shop/feed/alchemy controls')
 equal(page.tableview:getViewSize().height,204,'three quiet rows with an independent detail')
 checkBounds(page.tableview,w,h,'table',page.tableview:getViewSize());checkBounds(page.coherentShell.back,w,h,'Back')
 H.visit(page.coherentShell.canvas,function(n,visible)
  if visible and n.getString then
   local text=n:getString()
   for _,bad in ipairs({'钻石商城','炼金','首返补助'})do check(text~=bad,'unrelated chrome: '..text)end
   if n.getFontName then equal(n:getFontName(),W.font,'coherent font')end
   -- TableView clips its native offscreen cells; other native text must fit.
   local p=n:getParent();local inTable=false
   while p do if p==page.tableview then inTable=true end;p=p:getParent()end
   if not inTable then checkBounds(n,w,h,'label '..text)end
  end
 end)
 if page.recipeAction then checkBounds(page.recipeAction,w,h,'primary action')end
 equal(H.countEvents(),4,'four relevant state observers')
end
local function finishPage(page)
 page:viewWillDestory();page:destory();page:removeFromParent(true);page:release();equal(H.countEvents(),0,'page observers cleaned')
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1136},{720,1280}})do
 local w,h=size[1],size[2];H.fixture();local scene=H.prepare(w,h);local data=H.getData()
 data[roleBuilding]={{[dataKeyID]='58',[dataKeyNum]=0},{[dataKeyID]='57',[dataKeyNum]=0},{[dataKeyID]='6',[dataKeyNum]=1},{[dataKeyID]='59',[dataKeyNum]=0},{[dataKeyID]='60',[dataKeyNum]=0}}
 data[roleMake]={{[dataKeyID]='1036',[dataKeyNum]=-1,sortId='1'},{[dataKeyID]='1037',[dataKeyNum]=-1,sortId='2'},{[dataKeyID]='1038',[dataKeyNum]=-1,sortId='3'},{[dataKeyID]='1070',[dataKeyNum]=-1,sortId='53'}}
 data[roleMoney]=0;data[rolePack]={};locked=false
 local before=H.serialize(data);local view=assert(BuildLayer:create());view:retain();scene:addChild(view)
 inspect(view,w,h);equal(H.serialize(data),before,'opening construction never changes state')
 equal(view.roleBuildingData,data[roleBuilding],'original full building list identity')
 equal(view.tableview:getContentOffset().y,-136,'initial list opens at first row')
 CoherentRecipePage.select(view,2);equal(view.recipeSelectedId,'57','select original forge ID')
 equal(#view.recipeCostRows,3,'all forge costs visible')
 local oldOffset=-100;view.tableview:setContentOffset(cc.p(0,oldOffset),false);H.event(roleMoney)
 equal(view.tableview:getContentOffset().y,oldOffset,'inventory refresh retains scroll')
 local d,u,s=#changes,unlocks,shortages;view.recipeAction.item:activate()
 equal(shortages,s+1,'shortage dialog reached')
 equal(#changes,d,'shortage cannot spend');equal(unlocks,u,'shortage cannot unlock')
 local missingById={};for _,cost in ipairs(missing)do missingById[cost.mtId]=tonumber(cost.mtnum)end
 equal(missingById['1001'],25,'exact missing coins');equal(missingById['1006'],15,'exact missing stone');equal(missingById['1008'],2,'exact missing iron')
 fillCosts(H.tables[csvOfBuild]['57']);missingCallback();inspect(view,w,h)
 local stale=view.recipeAction.item;stale:retain();H.event(rolePack);stale:activate();stale:release();equal(#changes,d,'stale refreshed action inert')
 stale=view.recipeAction.item;stale:retain();expectedKind=kUnlockBuild;expectedId='57';stale:activate();stale:activate();stale:release()
 equal(#changes,d+3,'one deduction per original build cost');equal(unlocks,u+1,'repeated old action cannot build twice')
 equal(data[roleMoney],0,'forge coins exact');equal(data[rolePack]['1006'],0,'forge stone exact');equal(data[rolePack]['1008'],0,'forge iron exact')
 equal(view.recipeSelectedId,'57','selection survives build');check(view.recipeAction==nil,'built item has no repeat action')
 local infos=0;local D=require 'LuaClass/WarmDialog';local originalShow=D.show
 D.show=function(title,body,options,owner)infos=infos+1;equal(title,H.tables[csvOfBuild]['57'].name,'native info original name');check(body:find(H.tables[csvOfBuild]['57'].info,1,true),'native info original body');equal(owner,view,'info modal owner')end
 local icon=view.recipeInfo;icon:retain()
 getSystemTimeMilliSecond=function()return 1000 end
 local z=icon:getContentSize();local point=icon:convertToWorldSpace(cc.p(z.width/2,z.height/2))
 local touch={getLocation=function()return point end}
 check(icon:onTouchBegan(touch),'scaled native SDButton accepts its real world-space hitbox');icon:onTouchEnded(touch)
 check(icon:onTouchBegan(touch),'second native SDButton press accepted');icon:updatelongprogress();icon:onTouchEnded(touch)
 equal(infos,2,'native single and long-press touch paths trigger once each')
 point=cc.p(-100,-100);check(not icon:onTouchBegan(touch),'native SDButton rejects outside touch')
 icon:release();D.show=originalShow
 -- Live removal and guide changes cannot execute the previously selected row.
 CoherentRecipePage.select(view,4);fillCosts(H.tables[csvOfBuild]['59']);H.event(rolePack)
 stale=view.recipeAction.item;stale:retain();locked=true;stale:activate();stale:release();equal(unlocks,u+1,'late tutorial gate blocks construction');check(not view.recipeAction,'locked detail removes action');locked=false
 finishPage(view)
 -- Focused navigation retains complete manufacturing list and original offset.
 view=assert(MakeLayer:create('1038'));view:retain();scene:addChild(view);inspect(view,w,h)
 equal(view.workerData,data[roleMake],'original full manufacturing list identity');equal(view.recipeSelectedId,'1038','focus selects resource');equal(view.recipeSelectedSortId,'3','focus keeps original sort ID')
 equal(view.tableview:getContentOffset().y,HarborGoals.focusOffset(4,3,204,68),'focus uses original offset algorithm')
 local recipe=H.tables[csvOfResourceInfo]['1038'];fillCosts(recipe);H.event(rolePack);d,u=#changes,unlocks
 stale=view.recipeAction.item;stale:retain();expectedKind=kUnlockMake;expectedId='3';removeMade=true;stale:activate();stale:activate();stale:release();removeMade=false
 equal(#changes,d+#recipe.resume+1,'manufacture consumes exact costs and grants exactly one item');equal(changes[#changes][1],'1038','resource grant uses original ID');equal(changes[#changes][2],1,'manufacturing grants one');equal(unlocks,u+1,'manufacturing unlock executes once')
 equal(view.recipeSelectedId,'1070','exhausted recipe picks its live neighbor');equal(#view.workerData,3,'original unlock owner controls remaining rows')
 fillCosts(H.tables[csvOfResourceInfo]['1070']);H.event(rolePack);d=#changes
 modal=true;view.recipeAction.item:activate();modal=false;equal(#changes,d,'existing modal blocks click-through')
 view.coherentPageLeaving=true;view.recipeAction.item:activate();view.coherentPageLeaving=false;equal(#changes,d,'Back navigation in progress blocks stale action')
 stale=view.recipeAction.item;stale:retain();finishPage(view);stale:activate();stale:release();equal(#changes,d,'disposed action inert')
 -- Empty state is honest, and close does not change recipe/stock.
 data[roleMake]={};before=H.serialize(data);view=assert(MakeLayer:create());view:retain();scene:addChild(view);inspect(view,w,h);check(not view.recipeAction,'empty manufacturing offers no action');equal(H.serialize(data),before,'empty state read-only')
 data[roleMake]={{[dataKeyID]='1036',[dataKeyNum]=-1,sortId='1'}};H.event(roleMake)
 equal(view.recipeSelectedId,'1036','newly unlocked first recipe replaces empty state');check(view.recipeAction~=nil,'empty-to-unlocked transition gets current action');inspect(view,w,h)
 finishPage(view)
 H.finish();print('PASS coherent recipe native '..w..'x'..h..': read-only lists, costs, ID/sortId transactions, focus/offset, SDButton, stale/lock/modal/exit guards')
end
-- Every shipped construction and produce recipe is reachable by the same
-- unfiltered TableView at the smallest accepted native viewport.
H.fixture();local scene=H.prepare(480,800);local data=H.getData()
local function sortedKeys(t)local keys={};for key in pairs(t)do keys[#keys+1]=key end;table.sort(keys,function(a,b)return tonumber(a)<tonumber(b)end);return keys end
local buildRows,makeRows={},{}
for _,id in ipairs(sortedKeys(H.tables[csvOfBuild]))do
 buildRows[#buildRows+1]={[dataKeyID]=id,[dataKeyNum]=0}
end
local produce=H.csv('produce')
for _,sortId in ipairs(sortedKeys(produce))do
 local id=produce[sortId].resourceInfoID
 if H.tables[csvOfResourceInfo][id]then makeRows[#makeRows+1]={[dataKeyID]=id,[dataKeyNum]=-1,sortId=sortId}end
end
data[roleBuilding]=buildRows;data[roleMake]=makeRows;data[roleMoney]=100000;data[rolePack]={}
for id in pairs(H.tables[csvOfResourceInfo])do data[rolePack][id]=100000 end
for _,class in ipairs({BuildLayer,MakeLayer})do
 local view=assert(class:create());view:retain();scene:addChild(view)
 local rows=class==BuildLayer and buildRows or makeRows
 local before=H.serialize(data)
 for index,entry in ipairs(rows)do
  CoherentRecipePage.select(view,index)
  view:focusEntry(entry[dataKeyID])
  inspect(view,480,800)
  local recipe=(class==BuildLayer and H.tables[csvOfBuild]or H.tables[csvOfResourceInfo])[entry[dataKeyID]]
  equal(#view.recipeCostRows,#recipe.resume,'full catalog preserves every material row')
  local selected=CoherentRecipePage.selected(view);equal(selected,entry,'full catalog preserves original row identity and make sortId')
  H.visit(view.recipeDetail,function(n,visible)
   if visible and n.getFontSize then check(n:getFontSize()*n:getScaleX()>=16,'all catalog detail text remains readable: '..n:getString())end
  end)
 end
 equal(H.serialize(data),before,'full catalog browsing is read-only')
 -- The native cleanup event alone must invalidate callbacks, without destory.
 view:removeFromParent(true);check(view.recipeDisposed,'native cleanup disposes recipe observers');equal(H.countEvents(),0,'native cleanup removes observers');view:release()
 print('PASS native recipe full catalog '..(class==BuildLayer and 'construction' or 'manufacturing')..': '..#rows..' original rows')
end
H.finish()
cc.Director.getInstance=H.realGet
equal(toasts,unlocks,'one toast per successful transaction')
check(#H.failures==0,table.concat(H.failures,'\n'))
print('PASS coherent recipe native assertions: '..assertions)
