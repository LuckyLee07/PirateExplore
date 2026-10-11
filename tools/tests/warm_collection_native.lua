-- Real Cocos WarmCollection + real WarmMemories backend with in-memory atomic
-- storage only. Uses the native Home fixture, actual packaged art and fonts.
local f=assert(io.open('tools/tests/warm_home_dialog_native.lua','rb'));local fixtureSource=f:read('*a');f:close()
local stop=assert(fixtureSource:find("for _,height in ipairs({960,1067,1136})do",1,true))
local H=assert(loadstring(fixtureSource:sub(1,stop-1)..[[
return {check=check,equal=equal,serialize=serialize,dm=dm,fixture=fixture,event=event,
 getData=function()return data end,setData=function(v)data=v end,
 setViewport=function(h)viewport=cc.size(640,h)end,fresh=fresh,finish=finish,
 countEvents=countEvents,visit=visit,labelsWithin=labelsWithin,buttonWithText=buttonWithText,
 failures=failures,tables=tables,routes=routes,realGet=realGet}
]],'@native-collection-fixture'))()
local check,equal,serialize=H.check,H.equal,H.serialize
local Memories=require 'LuaClass/WarmMemories'
local Collection=require 'LuaClass/WarmCollection'
local commits,saveAttempts=0,0
local failSave=false
local function copy(value)
 if type(value)~='table'then return value end
 local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
end
H.dm.__roleData.commitAdventure=function(_,fields)
 saveAttempts=saveAttempts+1
 if failSave then return false end
 for key,value in pairs(fields)do
  assert(key==Memories.KEY,'Collection must only commit its persistent display choice')
  H.getData()[key]=copy(value)
 end
 commits=commits+1;return true
end
H.dm.postEvent=function(_,key)H.event(key)end
local function tap(root,text)
 local item=H.buttonWithText(root,text)
 assert(item,'native button missing: '..text)
 item:activate()
end
local function findText(root,needle)
 local result
 H.visit(root,function(n)if n.getString and n:getString():find(needle,1,true)then result=n end end)
 return result
end
local function screenBounds(layer,context)
 H.labelsWithin(layer,context)
 H.visit(layer,function(n,visible)
  if visible and n.item and n.label then
   local size=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(size.width,size.height))
   local viewport=cc.Director:getInstance():getVisibleSize()
   check(a.x>=-1 and b.x<=viewport.width+1 and a.y>=-1 and b.y<=viewport.height+1,context..' button bounds: '..n.label:getString())
  end
 end)
end
-- Generate valid state exclusively through the backend's real prepare methods.
-- Fixture commits here model an already successful voyage; UI never runs them.
local function settle(voyage,cargo,outcome,eventChoice)
 local data=H.getData()
 local state={version=1,enabled=true,activeVoyage=voyage,voyage=voyage,
  firstReturnClaimed=false,pending={voyage=voyage,episode=eventChoice and 'crew' or 'first',action='rescue',choice=eventChoice or 'rescue'}}
 state.warmMemoriesVoyageV1=assert(Memories.prepareDeparture(H.dm,state))
 data[roleMapInfo]={curIndex=1}
 state.pending=assert(Memories.prepareEvent(H.dm,state))
 local fields={[rolePack]=copy(data[rolePack]),[roleMoney]=data[roleMoney],
  [roleDiamond]=data[roleDiamond]or 0,adventureProgressV1={version=1,enabled=true,voyage=voyage}}
 local raw,reason
 if outcome=='failed' then raw,reason=Memories.prepareFailure(H.dm,state,cargo,data[roleMapInfo],fields)
 else raw,reason=Memories.prepareReturn(H.dm,state,cargo,data[roleMapInfo],fields)end
 assert(raw,reason)
 data[Memories.KEY]=raw;H.event(Memories.KEY)
 local duplicate,duplicateReason=Memories.prepareReturn(H.dm,state,cargo,data[roleMapInfo],fields)
 equal(duplicate,nil,'same actual voyage cannot duplicate returned memory/log')
 equal(duplicateReason,'recorded','duplicate settlement explicitly recognized')
 return raw
end
for _,height in ipairs({960,1067,1136})do
 H.setViewport(height);H.fixture();local data=H.getData();local before=serialize(data)
 local home=H.fresh();equal(home.exhibit:getChildrenCount(),0,'new Home has no fake exhibit')
 local baselineCommits=commits
 home.collectionButton.item:activate();local layer=assert(home.warmCollection);layer:retain()
 equal(Collection.open(home),layer,'collection duplicate-open reuses existing view')
 check(findText(layer,'第一件纪念物'),'empty collection is honest')
 screenBounds(layer,'Empty collection '..height)
 equal(serialize(data),before,'opening empty collection never initializes a ledger')
 tap(layer,'航程记录');check(findText(layer,'下一段航程'),'empty log is honest')
 screenBounds(layer,'Empty log '..height)
 tap(layer,'查看收藏');tap(layer,'‹');equal(home.warmCollection,nil,'native collection back closes page')
 layer:release();equal(commits,baselineCommits,'empty collection/log/back never save')
 equal(H.countEvents(),11,'closed collection removes only its extra event subscription')
 -- Real return grants exactly one permanent keepsake and one record.
 settle(1,{['1005']={num=7},['1008']={num=2}})
 local state=Memories.get(H.dm)
 equal(#state.entries,1,'real safe return grants one permanent entry')
 equal(#state.logs,1,'real safe return grants one voyage log')
 equal(state.displayId,nil,'owning a memory does not auto-display')
 equal(home.exhibit:getChildrenCount(),0,'ownership alone does not fabricate deck exhibit')
 before=serialize(data)
 home.collectionButton.item:activate();layer=assert(home.warmCollection);layer:retain()
 check(findText(layer,'沉船航图残页'),'owned detail names real keepsake')
 screenBounds(layer,'Owned collection '..height)
 tap(layer,'摆到船上');screenBounds(layer,'Display preview '..height)
 equal(serialize(data),before,'preview never saves display selection')
 tap(layer,'取消');equal(serialize(data),before,'preview cancel keeps prior saved state')
 tap(layer,'摆到船上');local confirm=assert(H.buttonWithText(layer,'确认摆放'));confirm:retain();confirm:activate()
 local attemptsAfterConfirm=saveAttempts;confirm:activate();confirm:release()
 equal(saveAttempts,attemptsAfterConfirm,'stale native confirm callback cannot replay a display save')
 equal(Memories.get(H.dm).displayId,Memories.ITEM_ID,'confirm persists actual display selection')
 equal(home.exhibit:getChildrenCount(),1,'actual memory event renders one deck exhibit')
 for _=1,4 do H.event(Memories.KEY)end
 equal(home.exhibit:getChildrenCount(),1,'repeated memory events never duplicate exhibit')
 equal(#Memories.get(H.dm).logs,1,'display selection never duplicates a log')
 -- Cold read through an independent copy retains the saved display.
 local cold=copy(data);H.setData(cold);data=cold
 equal(Memories.get(H.dm).displayId,Memories.ITEM_ID,'cold state restores chosen exhibit')
 H.event(Memories.KEY);equal(home.exhibit:getChildrenCount(),1,'cold state refresh restores one exhibit')
 tap(layer,'已摆放 · 收回珍藏');tap(layer,'取消')
 equal(Memories.get(H.dm).displayId,Memories.ITEM_ID,'remove preview cancel keeps exhibit')
 tap(layer,'已摆放 · 收回珍藏');tap(layer,'确认摆放')
 equal(Memories.get(H.dm).displayId,nil,'remove confirm persists empty display')
 equal(home.exhibit:getChildrenCount(),0,'remove event clears deck exhibit')
 equal(#Memories.get(H.dm).entries,1,'remove does not delete the owned keepsake')
 -- Persist failure must leave live choice unchanged and keep preview reviewable.
 tap(layer,'摆到船上');local failedBefore=serialize(data);local callsBefore=commits
 failSave=true;tap(layer,'确认摆放');failSave=false
 equal(serialize(data),failedBefore,'failed atomic display save leaves state identical')
 equal(commits,callsBefore,'failed save never commits')
 equal(layer.preview,'place','failed save keeps display preview open')
 tap(layer,'取消')
 -- Ownership is revalidated at actual confirmation, even after preview opens.
 tap(layer,'摆到船上');data[Memories.KEY].items={};data[Memories.KEY].displayId=nil
 for _,r in ipairs(data[Memories.KEY].log)do r.memoryIds={}end
 local unownedBefore=serialize(data);callsBefore=commits
 tap(layer,'确认摆放')
 equal(serialize(data),unownedBefore,'late unowned confirmation keeps state unchanged')
 equal(commits,callsBefore,'late unowned confirmation never commits')
 H.event(Memories.KEY);check(findText(layer,'第一件纪念物'),'late unowned refresh returns honest empty state')
 equal(layer.preview,nil,'late unowned refresh discards invisible preview state')
 layer:close();layer:release()
 -- Restore valid owned state through a later real voyage, without UI grants.
 settle(2,{['1008']={num=3}})
 equal(#Memories.get(H.dm).entries,1,'later real return still yields only one collection entry')
 equal(#Memories.get(H.dm).logs,2,'new voyage adds one distinct log')
 local cargo={};local n=0
 for id,row in pairs(H.tables[csvOfResourceInfo])do
  local volume=tonumber(row.cubage)
  if volume and volume>0 and volume<=2 and tonumber(id) and n<30 then cargo[id]={num=1};n=n+1 end
 end
 assert(n>=20,'long log covers actual packaged cargo types')
 settle(3,cargo)
 local inventoryBefore=serialize(data[rolePack]);local recordsBefore=serialize(data[Memories.KEY])
 home.logButton.item:activate();layer=assert(home.warmCollection);layer:retain()
 equal(layer.tab,'log','Home log hotspot opens actual permanent voyage log')
 screenBounds(layer,'Voyage list '..height)
 -- Identify the first (newest) native detail control by highest y.
 local topButton,topY
 H.visit(layer,function(node)if node.label and node.item and node.label:getString()=='详情'then
  local y=node:getPositionY();if not topY or y>topY then topButton=node.item;topY=y end
 end end)
 assert(topButton):activate();equal(layer.logDetail,1,'top detail opens newest actual voyage')
 screenBounds(layer,'Long cargo log detail '..height)
 local cargoLabel
 H.visit(layer,function(n)if n.getString and n:getPositionX()==44 and n:getPositionY()==382 then cargoLabel=n end end)
 if check(cargoLabel~=nil,'long log shows actual returned cargo descriptions')then
  local z=cargoLabel:getContentSize();local y=cargoLabel:getPositionY();local a=cargoLabel:getAnchorPoint()
  check(y-z.height*a.y>=277.9 and y+z.height*(1-a.y)<=390,'long cargo detail stays inside available body area; height='..z.height..', y='..y..', anchor='..a.y)
 end
 local texts={};for id,item in pairs(cargo)do texts[#texts+1]=(H.tables[csvOfResourceInfo][id].name or id)..' ×'..item.num end;table.sort(texts)
 local textPages=require('LuaClass/WarmActivities').textPages(table.concat(texts,'  ·  '),18,390,102)
 check(#textPages>1,'long cargo fixture really requires multiple measured pages')
 local rendered={}
 for page=1,#textPages do
  local body
  H.visit(layer,function(n)if n.getString and n:getPositionX()==44 and n:getPositionY()==382 then body=n end end)
  assert(body,'bounded cargo text body');rendered[#rendered+1]=body:getString()
  equal(body:getString(),textPages[page],'native cargo page retains complete measured text')
  screenBounds(layer,'Paged log '..height..':'..page)
  if page<#textPages then tap(layer,'下一页')end
 end
 equal(table.concat(rendered),table.concat(texts,'  ·  '),'cargo pagination preserves all logged quantities')
 equal(serialize(data[rolePack]),inventoryBefore,'opening log never replays inventory return')
 equal(serialize(data[Memories.KEY]),recordsBefore,'opening log never creates duplicate event or reward')
 tap(layer,'返回航程记录');tap(layer,'查看收藏');tap(layer,'查看库存')
 equal(home.warmCollection,nil,'inventory action closes keepsake page')
 check(home.warmActivity and home.warmActivity.kind=='collection','inventory action opens original read-only stock activity')
 if home.warmActivity then home.warmActivity:close()end
 layer:release()
 home.logButton.item:activate();layer=assert(home.warmCollection);layer:retain();tap(layer,'航线线索')
 check(home.warmActivity and home.warmActivity.kind=='log','route-clue action opens original exploration activity')
 if home.warmActivity then home.warmActivity:close()end
 layer:release()
 -- Failed voyages and later chart recovery keep their actual, localized outcome.
 settle(4,{['1008']={num=2}},'failed')
 home.logButton.item:activate();layer=assert(home.warmCollection);layer:retain()
 local newest
 H.visit(layer,function(node)if node.label and node.item and node.label:getString()=='详情' and node:getPositionY()==530 then newest=node.item end end)
 assert(newest):activate();check(findText(layer,'航行失利'),'failed voyage detail is not presented as a safe return')
 check(findText(layer,'本次未带回的物品'),'failed voyage identifies lost cargo')
 screenBounds(layer,'Failed voyage '..height);layer:close();layer:release()
 settle(5,{['1008']={num=3}},nil,'chart')
 home.logButton.item:activate();layer=assert(home.warmCollection);layer:retain()
 H.visit(layer,function(node)if node.label and node.item and node.label:getString()=='详情' and node:getPositionY()==530 then newest=node.item end end)
 assert(newest):activate();check(findText(layer,'抢救航图'),'later-episode chart choice has a readable Chinese label')
 check(not findText(layer,'chart'),'later-episode detail hides raw backend choice identifier')
 screenBounds(layer,'Chart recovery '..height);layer:close();layer:release()
 equal(#Memories.get(H.dm).entries,1,'later return/failure never duplicates permanent memento')
 equal(#Memories.get(H.dm).logs,5,'five distinct terminal voyages yield five records')
 -- Legacy/corrupt state must not be silently rewritten by opening this page.
 data.adventureProgressV1=nil;before=serialize(data)
 local readOnly=Collection.open(home);readOnly:retain()
 check(readOnly.state.readOnly,'legacy collection explicitly read-only');screenBounds(readOnly,'Legacy collection '..height)
 tap(readOnly,'回到船上');readOnly:release();equal(serialize(data),before,'legacy close leaves original data intact')
 data.adventureProgressV1={version=1,enabled=true};data[Memories.KEY].version=99;before=serialize(data)
 readOnly=Collection.open(home);readOnly:retain();check(readOnly.state.readOnly,'future schema is read-only')
 screenBounds(readOnly,'Future schema '..height);readOnly:close();readOnly:release();equal(serialize(data),before,'future schema is not overwritten')
 data[Memories.KEY]=nil
 local teardown=Collection.open(home);teardown:retain();H.finish(home)
 check(not teardown:getParent() or not teardown:getParent():getParent(),'Home teardown detaches collection owner tree')
 check(teardown.closed,'Home teardown marks collection closed');teardown:close();teardown:release()
 print('CHECKED native WarmCollection '..height..': real backend empty/owned, preview/cancel/confirm/remove, failures, cold display, log/inventory handoffs, native bounds')
end
-- Cold presentation reconstruction reads the persisted snapshot independently.
H.setViewport(960);H.fixture();settle(1,{['1008']={num=2}})
assert(Memories.setDisplay(H.dm,Memories.ITEM_ID))
local persisted=copy(H.getData());local warm=H.fresh()
equal(warm.exhibit:getChildrenCount(),1,'initial Home reads confirmed exhibit')
H.finish(warm);H.setData(copy(persisted))
local coldHome=H.fresh();equal(coldHome.exhibit:getChildrenCount(),1,'new Home instance restores confirmed exhibit from cold snapshot')
local coldBefore=serialize(H.getData());coldHome:refreshSummary()
equal(serialize(H.getData()),coldBefore,'cold Home refresh does not alter saved collection/log')
H.finish(coldHome)
cc.Director.getInstance=H.realGet
assert(#H.failures==0,table.concat(H.failures,'\n'))
print('PASS native WarmCollection/WarmMemories/Home exhibit; display commits='..commits..', attempted='..saveAttempts)
