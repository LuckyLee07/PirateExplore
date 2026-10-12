-- Real Cocos lists/labels/touches, decoded shipped records and original model
-- methods over disposable in-memory state. No GUI, persistent save or payment.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local override=os.getenv('COHERENT_EVENT_DETAIL_SOURCE')
if override then package.preload['LuaClass/EventDetailsLayer']=function()return assert(loadfile(override))()end end
local source=read('tools/tests/coherent_event_pages_native.lua')
local stop=assert(source:find('local families={}',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,sites=sites,resources=resources,soldiers=soldiers,controller=controller,inspect=inspect,bag=bag,
 seed=function(rows)roles={[roleMoney]=307,[roleSoildierQueue]={},[roleBlackMarketRestrictions]={}};black=rows or {} end,
 roles=function()return roles end,setMarket=function(rows)black=rows end}
]],'@event-list-feedback-fixture'))()
local H=F.H;local dm=H.dm
-- Execute unchanged original debit/grant functions, including precise crew
-- receipts, mission side effects, row limits and original save boundaries.
local function originalMethod(path,class,name)
 local s=read(path);local start=assert(s:find('function '..class..':'..name..'(',1,true))
 local after=s:find('\nfunction '..class..':',start+1,true)or(#s+1)
 return assert(loadstring('local '..class..'=...\n'..s:sub(start,after-1)..'\nreturn '..class..'.'..name,'@original-'..name))({})
end
dm.addCoin=originalMethod('bin/res/scripts/LuaClass/DataManager.lua','DataManager','addCoin')
dm.addSoilderWithId=originalMethod('bin/res/scripts/LuaClass/DataManager.lua','DataManager','addSoilderWithId')
F.bag.addItemToBattlePack=originalMethod('bin/res/scripts/LuaClass/ExploreBagController.lua','ExploreBagController','addItemToBattlePack')
F.bag.itemIsConsumedSpaceById=function()return 1 end;F.bag.getBreads=function()return 0 end
F.bag.owner={updataCapacityTips=function()end,bread={setString=function()end}}
local shortages=0;dm.showBuyGoldBox=function()shortages=shortages+1 end
local missions=0;MissionManagers={getInstance=function()return{onTriggerMission=function()missions=missions+1;ToastUtil:downString('任务进度已更新')end}end}
package.loaded['LuaClass/NotificationNode']=true
require 'LuaClass/ToastUtil'
local receipts={};local originalDown=ToastUtil.downString
function ToastUtil:downString(text,...)receipts[#receipts+1]=text;return originalDown(self,text,...)end
local notice;local get=cc.Director.getInstance
cc.Director.getInstance=function()local d=get();d.getNotificationNode=function()return notice end;return d end
local assertions=0
local function check(ok,why)assertions=assertions+1;assert(ok,why)end
local function equal(a,b,why)check(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,why)check(math.abs(a-b)<.1,why..': '..a..' ~= '..b)end
local out=os.getenv('COHERENT_EVENT_LIST_CAPTURE_DIR')or'/workspace/shared/pirate-audit/event-list-feedback'
local function frames(n)
 for _=1,n or 15 do local untilAt=os.clock()+.01;while os.clock()<untilAt do end;cc.Director:getInstance():mainLoop()end
end
local function clearNotices()
 notice:removeAllChildren();ToastUtil.infoQueue={};ToastUtil.infoKinds={};receipts={}
end
local function capture(scene,page,w,h,name)
 F.inspect(page,w,h)
 check(coherentCapture(scene,w,h,out..'/'..name..'-'..w..'x'..h..'.png'),'native evidence capture')
end
local function point(node)local z=node:getContentSize();return node:convertToWorldSpace(cc.p(z.width/2,z.height/2))end
local function gesture(phase,p,dx,dy)coherentEventGesture(phase,p.x+(dx or 0),p.y+(dy or 0))end
local function tap(node)local p=point(node);gesture(0,p);gesture(2,p)end
local function fresh(w,h)
 H.fixture();F.seed();F.bag.battlePackData={};F.bag.costSpace=0;F.bag.limited=40;screenSize=cc.size(w,h);local scene=H.prepare(w,h)
 notice=cc.Node:create();scene:addChild(notice,999);clearNotices();coherentEventEnter(scene,w,h)
 return scene
end
local function open(scene,kind,rows)
 if kind==3 then F.setMarket(rows)end
 EventDetailsLayer.type=kind;EventDetailsLayer.data=rows
 local page=assert(EventDetailsLayer:create());scene:addChild(page);return page
end
local item=F.resources['1005'];local soldier=F.soldiers['144']
check(soldier.name=='探险者','actual shipped explorer ID144')
local function row(kind,index)
 if kind==1 then return{id='144',name=soldier.name,icon=soldier.icon,star=tonumber(soldier.star),hp=soldier.hp,attack=soldier.attack,speed=soldier.speed,num=2,skillName=dataController.getSkillValueByIdAndKey(soldier.skill,'name'),cost={id='1035',name='尸尘',costNum=50}}
 elseif kind==2 then return{id='144',name=soldier.name,icon=soldier.icon,star=tonumber(soldier.star),hp=soldier.hp,power=soldier.attack,speed=soldier.speed,costType='1',costs=300}
 else return{id='1005',name=item.name,icon=item.iconName,num=index or 5,costType='1',costs=12}end
end
local function layout(page,count)
 local subtitleTop=page.eventSubtitle:convertToWorldSpace(cc.p(0,page.eventSubtitle:getContentSize().height)).y
 local closeBottom=page.eventClose:convertToWorldSpace(cc.p(0,0)).y
 check(subtitleTop<=closeBottom-2,'child subtitle stays below return control')
 local height=math.min(240,math.floor((page.eventSize.height-130)*.34),count*80)
 equal(page.eventListHeight,height,'content-sized native list height')
 near(page.tableview:getPositionY()+height,page.eventListTop,'native list top anchored')
 near(page.eventDetailScroll:getPositionY()+page.eventDetailScroll:getViewSize().height,page.eventListTop-height-30,'detail uses recovered list space')
 if count>0 then
  local first=assert(page.tableview:cellAtIndex(0),'first actual native row exists')
  near(first:convertToWorldSpace(cc.p(0,80)).y,page.eventListTop,'first actual row reaches list top')
 end
end
for _,size in ipairs({{360,640},{480,800}})do
 local w,h=unpack(size);local scene=fresh(w,h)
 for kind=1,4 do
  local one={row(kind)};local page=open(scene,kind,one);local before=H.serialize(F.roles())
  layout(page,1);capture(scene,page,w,h,'kind'..kind..'-short')
  local oldOffset=page.tableview:getContentOffset().y
  coherentDescriptionDrag(page.tableview,0)
  near(page.tableview:getContentOffset().y,oldOffset,'short list cannot drift below header')
  equal(H.serialize(F.roles()),before,'list dragging never mutates model')
  local rows={};for i=1,40 do rows[i]=row(kind,i)end
  page.data=rows;page:reloadDetails();layout(page,40)
  capture(scene,page,w,h,'kind'..kind..'-long')
  local offset=page.tableview:getContentOffset().y;local selected=page.eventSelectedIndex
  coherentDescriptionDrag(page.tableview,0)
  check(page.tableview:getContentOffset().y>offset,'long list scrolls with real GLView drag')
  equal(page.eventSelectedIndex,selected,'drag does not select or activate a row')
  equal(H.serialize(F.roles()),before,'long-list browsing never mutates model')
  page.tableview:setContentOffset(cc.p(0,0));page:showCellInfo(40)
  equal(page.eventSelectedData,rows[40],'last row remains selectable')
  capture(scene,page,w,h,'kind'..kind..'-last')
  -- Selection refresh preserves native scroll; replacing with short/empty rows
  -- clamps it and expands the body without leaking controls from the last row.
  page.data=one;page:reloadDetails();layout(page,1)
  page.data={};page:reloadDetails();layout(page,0)
  check(not page.tableview:isVisible()and not page.eventPrimary,'empty page has no stale row action')
  capture(scene,page,w,h,'kind'..kind..'-empty');page:close()
 end
 -- Open original tavern route and verify actual ID, stock and 300-coin price.
 local owner=assert(EventLayer:create());scene:addChild(owner);owner:setController(F.controller())
 owner:refreshLayerByInfo(F.sites['3004'],false);owner:show();owner:enterPubLayer(F.sites['3004'])
 local page=assert(owner.eventDetails);local stock=H.serialize(page.data)
 equal(page.data[1].id,'144','original route selects explorer144');equal(page.data[1].costs,300,'original recruitment price')
 layout(page,1);capture(scene,page,w,h,'original-tavern')
 local before=H.serialize(F.roles());local p=point(page.eventPrimary.item)
 gesture(0,p);gesture(1,p,0,32);gesture(2,p,0,32)
 check(not page.adventureDialog,'action drag does not open confirmation');equal(H.serialize(F.roles()),before,'drag never spends')
 tap(page.eventPrimary.item);local dialog=assert(page.adventureDialog);local confirm=dialog.warmOptions[1].item;confirm:retain()
 -- Rebinding selection while confirmation is open invalidates its callback.
 page:showCellInfo(1);confirm:activate();confirm:release();equal(H.serialize(F.roles()),before,'rebound confirmation cannot spend')
 clearNotices();tap(page.eventPrimary.item);dialog=assert(page.adventureDialog);confirm=dialog.warmOptions[1].item;confirm:retain()
 tap(confirm);confirm:activate();confirm:activate();confirm:release()
 equal(F.roles()[roleMoney],7,'original model debit 307 to7')
 equal(F.roles()[roleSoildierQueue]['144'][dataKeyNum],1,'original crew grant exactly one')
 equal(#receipts,1,'recruitment emits one precise receipt')
 equal(receipts[1],'探险者+1 总共 1','original precise crew quantity receipt')
 equal(H.serialize(page.data),stock,'recruitment preserves original repeatable stock')
 frames();capture(scene,page,w,h,'recruit-receipt')
 -- A second deliberate request is still allowed by original stock, but with
 -- seven coins fails through unchanged shortage UI/message without a grant.
 clearNotices();local s=shortages;tap(page.eventPrimary.item);tap(page.adventureDialog.warmOptions[1].item)
 equal(shortages,s+1,'original insufficient-funds path preserved');equal(F.roles()[roleMoney],7,'shortage does not spend')
 equal(receipts[1],'金币不足！','shortage notice preserved')
 -- Existing crew uses original mission branch; unrelated feedback survives.
 F.roles()[roleMoney]=307;clearNotices();local m=missions
 tap(page.eventPrimary.item);tap(page.adventureDialog.warmOptions[1].item)
 equal(missions,m+1,'original mission callback preserved');equal(#receipts,2,'one crew receipt plus unrelated mission notice')
 equal(receipts[1],'任务进度已更新','unrelated mission feedback is not suppressed')
 equal(receipts[2],'探险者+1 总共 2','existing crew exact quantity receipt')
 page:close();owner:removeFromParent(true);clearNotices()
 -- Original limited-stock callback and exact receipt. Retained old purchase
 -- controls cannot spend twice, and no second generic success is emitted.
 local limitedId;for id,r in pairs(F.resources)do if tonumber(r.limits)==1 then limitedId=id;break end end
 local r=F.resources[limitedId];local goods={id=limitedId,name=r.name,icon=r.iconName,num=1,costType='1',costs=12}
 F.roles()[roleMoney]=307;page=open(scene,3,{goods});local buy=page.eventPrimary.item;buy:retain();tap(buy);buy:activate();buy:release()
 equal(F.roles()[roleMoney],295,'market original debit once');equal(#page.data,0,'once-only stock exhausted')
 equal(F.roles()[roleBlackMarketRestrictions][limitedId],0,'original once-only limit persisted')
 equal(F.bag.battlePackData[limitedId].num,1,'original bag model receives exactly one limited item')
 equal(#receipts,1,'market emits one receipt');equal(receipts[1],r.name..' × 1 · 金币 −12','market exact item quantity cost receipt')
 frames();capture(scene,page,w,h,'market-receipt');page:close();clearNotices()
 page=open(scene,3,{row(3,5)});buy=page.eventPrimary.item;buy:retain();tap(buy);buy:activate();buy:release()
 equal(F.roles()[roleMoney],283,'ordinary market debit once')
 equal(F.bag.battlePackData['1005'].num,5,'original bag model receives five food')
 equal(receipts[1],item.name..' × 5 · 金币 −12','ordinary market receipt matches exact five-item grant')
 equal(#receipts,1,'ordinary market no duplicate receipt');page:close();clearNotices()
 -- Closing with a pending tavern confirmation keeps every retained callback inert.
 page=open(scene,2,{row(2)});tap(page.eventPrimary.item);local stale=page.adventureDialog.warmOptions[1].item;stale:retain()
 local state=H.serialize(F.roles());page:close();stale:activate();stale:release();equal(H.serialize(F.roles()),state,'closed child confirmation cannot spend/grant')
 H.finish();notice=nil
 print('PASS shared event list short/long/empty, native drag, exact receipt, rapid/rebind/close '..w..'x'..h)
end
print('PASS '..assertions..' native event list/feedback assertions')
