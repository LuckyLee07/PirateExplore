-- Focused clean preparation + receipt checks using actual Cocos nodes and
-- CleanVoyage font metrics. Uses in-memory data only; no scene or save is opened.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_departure_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,csv=csv,row=row,director=director,realGet=oldDirector,
 prepare=function(w,h)
  viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain()
  state={money=4651,diamond=213,ship='1299',capacity=60,cabin=3,pack={['1005']=100,['1006']=2},crew={['100']={num=3}},selection={['1005']=10,['10100']=1}}
  local view=cc.Layer:create();scene:addChild(view)
  for _,key in ipairs({'mainBg','titleBg','storeMenu','infoNode','setBtn','setBtnLight','bottomInfoBox'})do view[key]=cc.Node:create();view:addChild(view[key])end
  view.infoBoxLabel=cc.LabelTTF:create('',BoldFont,20);view.infoNode:addChild(view.infoBoxLabel)
  view.departureAction=function()departures=departures+1 end
  view.produceCsv=csv.resources;view.updateAdventureReadiness=ExpeditionLayer.updateAdventureReadiness
  view.showInfoBox=function()end
  WarmDeparture.create(view);ExpeditionLayer.setResourceUIWithData(view);return view
 end,
 close=close,getState=function()return state end,
 newScene=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end}
]],'@coherent-prepare-native-fixture'))()
local function textWithin(n,w,h)
 local s=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(s.width,s.height))
 assert(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,'visible label bounds: '..n:getString())
end
local function visit(n,fn,visible)
 visible=visible~=false and n:isVisible();fn(n,visible)
 for _,child in ipairs(n:getChildren())do visit(child,fn,visible)end
end
for _,size in ipairs({{480,800},{540,960},{720,1280}})do
 local w,h=size[1],size[2];local view=H.prepare(w,h)
 assert(view.departureWorld:getChildrenCount()==3,'shared clean sea, harbor and boat are present')
 assert(view.departureButton.label:getString()=='驶向大海','ready action identifies the next location')
 for _,name in ipairs({'readyLabel','readinessRequirement','shipNameLabel','departureCoinLabel'})do textWithin(view[name],w,h)end
 for _,id in ipairs({'1005','10100','1006'})do
  local row=H.row(view,id);assert(row.manifestDivider,'inventory remains an open manifest with separators')
 end
 local food=H.row(view,'1005');local before=H.getState().selection['1005']
 food.controls.plus.onSingleCLick();assert(H.getState().selection['1005']==before+1)
 food.controls.minus.onLongPressed();assert(H.getState().selection['1005']==before)
 food.controls.minus.onSingleCLick();assert(view.readyLabel:getString()=='食物偏少，建议补足后再出航','low-food advisory preserves legal departure')
 assert(view.departureButton.item:isEnabled(),'advisory does not change original departure eligibility')
 food.controls.plus.onSingleCLick()
 assert(view.cargoRemainingLabel:getString()=='空余货舱 50 / 60 格')
 assert(math.abs(view.cargoCapacityBar:getScaleX()-50/60)<1e-5)
 H.close()
 print('PASS coherent native manifest '..w..'x'..h..': shared clean art, ready action, live quantities and footer bounds')
end
local R=require 'LuaClass/WarmReturnResult'
local writes=0
local dm={getCSVByID=function()return {['1005']={name='食物'},['1008']={name='木材'}}end,
 setRoleData=function()writes=writes+1;error('receipt must never save')end,
 addPackItemWithId=function()writes=writes+1;error('receipt must never grant')end}
local function receipt(memory,long)
 local result={committed=true,voyage=3,moneyDelta=25,diamondDelta=-8,crewReturned=1,
  stockDelta={['1005']=7,['1008']=2},historyRecorded=memory,memoryIds=memory and {'wreck_map'} or {}}
 if long then for id=1100,1160 do result.stockDelta[tostring(id)]=id-1000 end end
 return result
end
for _,size in ipairs({{480,800},{640,960},{640,1136}})do
 local w,h=size[1],size[2]
 for _,memory in ipairs({true,false})do
  local scene=H.newScene(w,h);local owner=cc.Layer:create();scene:addChild(owner)
  owner.warmHomePresentation=true
  local prepares,collections=0,0
  owner.openPrimary=function(self)assert(not self.warmReturnResult,'receipt closes before guarded Home route');prepares=prepares+1 end
  owner.openActivity=function(self,kind)assert(not self.warmReturnResult and kind=='collection');collections=collections+1 end
  local result=receipt(memory,true);local layer=assert(R.show(dm,result,owner));layer:retain()
  assert(R.show(dm,result,owner)==layer,'duplicate show reuses receipt')
  local found={}
  visit(layer,function(n,visible)if visible and n.getString then found[n:getString()]=true;textWithin(n,w,h)end end)
  assert(found['平安返回港口'] and found['金币 +25  ·  钻石 -8'],'quiet receipt uses committed net figures')
  assert(found['仓库物资净变化'],'receipt does not call returned supplies newly earned loot')
  assert(layer.buttons.prepare and layer.buttons.close,'return supports onward preparation and staying home')
  assert((layer.buttons.collection~=nil)==memory,'collection CTA requires genuine new memory')
  local nextPage=assert(layer.buttons.next);nextPage:retain();nextPage.item:activate();assert(layer.page==2)
  nextPage.item:activate();assert(layer.page==2,'stale pagination cannot change current page');nextPage:release()
  local prepare=layer.buttons.prepare;prepare:retain();prepare.item:activate();prepare.item:activate()
  assert(prepares==1 and collections==0 and layer.closed and owner.warmReturnResult==nil,'onward CTA closes and routes exactly once')
  assert(R.show(dm,result,owner)==nil,'receipt cannot replay after its onward route')
  prepare:release();layer:release();H.close()
 end
 print('PASS coherent native receipt '..w..'x'..h..': actual typography bounds, truthful saved figures, pagination and single-use preparation route')
end
assert(writes==0)
cc.Director.getInstance=H.realGet
print('PASS coherent preparation and return: no transaction owner, save, economy or reward behavior changed')
