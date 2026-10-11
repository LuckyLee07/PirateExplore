-- Coherent support-page navigation and emphasis, using native Cocos/EGL nodes.
-- Reuses real CSV/Memory preparation fixtures, never opens a GUI or player save.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_collection_native.lua')
local stop=assert(source:find('\nfor _,height in ipairs({960,1067,1136})do',1,true))
local fixture=assert(loadstring(source:sub(1,stop-1)..'\n'..[[
return {H=H,settle=settle,tap=tap,findText=findText,screenBounds=screenBounds,
 saved=function()return saveAttempts end}
]],'@coherent-growth-native-fixture'))()
local H=fixture.H
local A=require 'LuaClass/WarmActivities'
local C=require 'LuaClass/WarmCollection'
local W=require 'LuaClass/WarmTheme'
local Memories=require 'LuaClass/WarmMemories'
local button=W.button
W.button=function(text,w,h,callback,opts)
 local node=button(text,w,h,callback,opts)
 node.growthTestPrimary=opts and opts.primary==true
 return node
end
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function textExists(root,text)
 local found=false
 H.visit(root,function(n)if n.getString and n:getString()==text then found=true end end)
 return found
end
local function review(root,context)
 local primary=0
 H.visit(root,function(n,visible)
  if visible and n.growthTestPrimary then primary=primary+1 end
  if visible and n.getString then
   assert(not n:getString():find('收藏尚未开放',1,true),context..' must not hide real keepsakes')
   if n.getFontName then equal(n:getFontName(),W.font,context..' uses the shared readable font')end
  end
 end)
 assert(primary<=1,context..' has '..primary..' competing primary actions')
 fixture.screenBounds(root,context)
 return primary
end
for _,height in ipairs({960,1067,1136})do
 H.setViewport(height);H.fixture()
 local data=H.getData();data[rolePack]={};data[rolePackSize]=20;data[roleAlchemyUnit]=1
 data[roleBuilding]={{[dataKeyID]='57',[dataKeyNum]=0}};data[roleMoney]=0
 local home=H.fresh();local saved=fixture.saved();local before=H.serialize(data)
 local stock=A.open('collection',home);stock:retain()
 assert(textExists(stock,'物品库存'));review(stock,'Empty stock '..height)
 local oldLink=stock.buttons.keepsakes.item;oldLink:retain();oldLink:activate()
 equal(home.warmActivity,nil,'stock closes before keepsakes opens')
 local collection=assert(home.warmCollection);collection:retain()
 equal(collection.tab,'collection','stock routes to real collection')
 assert(textExists(collection,'航程收藏'));review(collection,'Empty keepsakes '..height)
 oldLink:activate();equal(home.warmCollection,collection,'stale stock route cannot stack another page')
 oldLink:release();stock:release()
 fixture.tap(collection,'航程记录');assert(textExists(collection,'航海日志'))
 review(collection,'Empty voyage log '..height)
 fixture.tap(collection,'航线线索');equal(home.warmCollection,nil,'log closes before current progress opens')
 local progress=assert(home.warmActivity);progress:retain()
 assert(textExists(progress,'航线线索'));assert(textExists(progress,'当前进展 · 下一程从这里开始'))
 review(progress,'Current progress '..height)
 progress.buttons.voyages.item:activate();equal(home.warmActivity,nil,'progress closes before actual log opens')
 local log=assert(home.warmCollection);log:retain();equal(log.tab,'log','voyage action opens durable log')
 assert(textExists(log,'航海日志'));review(log,'Actual log route '..height)
 log:close();log:release();progress:release();collection:release()
 equal(H.serialize(data),before,'navigation never changes inventory, ownership, progress or money')
 equal(fixture.saved(),saved,'read-only navigation never attempts a save')
 equal(H.countEvents(),11,'sibling transitions release every temporary subscription')

 local ship=A.open('ship',home);ship:retain()
 assert(ship.buttons['goal:1148'] and ship.buttons['goal:1176'],'both real growth goals remain accessible')
 equal(review(ship,'Two growth choices '..height),1,'only one ship action is emphasized')
 ship.buttons['sources:1148'].item:activate()
 assert(#ship.sourceEntries>=2,'fixture includes multiple actual material shortages')
 equal(review(ship,'Multiple material sources '..height),1,'only one material action is emphasized')
 assert(not ship.buttons.sourceBack.growthTestPrimary,'return from material sources is secondary')
 ship.buttons.sourceBack.item:activate();equal(ship.sourceGoalId,nil,'source Back retains ship context')
 ship:close();ship:release()
 local crew=A.open('crew',home);review(crew,'Crew roster '..height)
 crew.buttons['crew:100'].item:activate();review(crew,'Crew details '..height)
 crew.buttons.back.item:activate();equal(crew.detailId,nil,'crew detail Back keeps its roster')
 crew:close()

 for count=1,6 do
  data[rolePack][tostring(1004+count)]=count
  stock=A.open('collection',home);review(stock,'Stock density '..count..' at '..height)
  stock:close()
 end
 for voyage=1,5 do fixture.settle(voyage,{['1008']={num=voyage}})end
 collection=C.open(home);collection:retain();review(collection,'Owned keepsake '..height)
 before=H.serialize(data);saved=fixture.saved()
 fixture.tap(collection,'摆到船上');equal(review(collection,'Display preview '..height),1,'display preview has one confirmation')
 local staleConfirm=assert(H.buttonWithText(collection,'确认摆放'));staleConfirm:retain()
 collection:showTab('log');equal(collection.preview,nil,'changing tab cancels display preview')
 staleConfirm:activate();staleConfirm:release()
 equal(fixture.saved(),saved,'stale display confirmation cannot save after tab change')
 local previous=assert(H.buttonWithText(collection,'上一页'))
 assert(not previous:isEnabled(),'first voyage page has disabled Previous')
 review(collection,'Populated voyage log '..height)
 fixture.tap(collection,'下一页');equal(collection.page,2,'log pagination remains available')
 assert(not assert(H.buttonWithText(collection,'下一页')):isEnabled(),'last voyage page has disabled Next')
 review(collection,'Last voyage page '..height)
 fixture.tap(collection,'详情');assert(collection.logDetail,'log detail opens from later pages')
 equal(review(collection,'Voyage detail '..height),0,'a read-only detail does not promote Back to a primary action')
 fixture.tap(collection,'返回航程记录');equal(collection.page,2,'detail Back preserves the log page')
 fixture.tap(collection,'查看收藏');equal(collection.page,1,'switching collection tab resets page')
 equal(collection.logDetail,nil,'switching collection tab clears stale log detail')
 fixture.tap(collection,'查看库存');equal(home.warmCollection,nil,'keepsakes close before stock opens')
 assert(home.warmActivity and home.warmActivity.kind=='collection','keepsakes lead to real inventory')
 home.warmActivity:close();collection:release()
 equal(H.serialize(data),before,'log and display cancellation preserve all live data')
 equal(fixture.saved(),saved,'read-only log and canceled preview never save')
 equal(H.countEvents(),11,'collection/stock round trip removes temporary listeners')
 local teardown=C.open(home);teardown:retain();H.finish(home)
 assert(teardown.closed,'owner cleanup closes collection');teardown:close();teardown:release()
 print('PASS coherent growth '..height..': stock/keepsakes/log/clue round trip, one primary, native bounds, stale preview, paging, read-only lifecycle')
end
assert(#H.failures==0,table.concat(H.failures,'\n'))
W.button=button;cc.Director.getInstance=H.realGet
