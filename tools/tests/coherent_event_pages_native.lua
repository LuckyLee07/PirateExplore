-- Real Cocos nodes/fonts/touch methods, shipped CSV identities, in-memory state.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/warm_home_dialog_native.lua')
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,serialize=serialize,getData=function()return data end,visit=visit,
 prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
 finish=function()scene:cleanup();scene:release();scene=nil end}
]],'@coherent-event-native-fixture'))()
for _,name in ipairs({'FightMode','EventRewardLayer','WorldMapLayer','EternalArenaController','PlotLayer'})do package.loaded['LuaClass/'..name]=true end
require 'LuaClass/SDButton';require 'LuaClass/EventLayer';require 'LuaClass/EventManger'
local W=require 'LuaClass/WarmTheme'
WriteColor=W.colors.white;BaseColor=W.colors.ink
printn=function()end
local function matrix(text)local rows={};for row in tostring(text):gmatch('[^;]+')do local cells={};for v in row:gmatch('[^_]+')do cells[#cells+1]=v end;rows[#rows+1]=cells end;return rows end
local sites=H.csv('strongholdAttribute');local resources=H.tables[csvOfResourceInfo];local soldiers=H.tables[csvOfSoilderAttribute]
H.tables[csvOfSkillAttribute]=H.csv('skillAttribute');H.tables[csvOfBuff]=H.csv('buff')
for _,r in pairs(sites)do for _,key in ipairs({'requiredtool','Carryitems','dropitems'})do r[key]=matrix(r[key])end end
for _,r in pairs(soldiers)do r.dropitems=matrix(r.dropitems)end
local function row(t,id)return t[tostring(id)]end
dataController={getResourceInfoById=function(id)return row(resources,id)end,getResourceValueByIdAndKey=function(id,key)local r=row(resources,id);return r and r[key]end,
 getSoilderInfoById=function(id)return row(soldiers,id)end,getSoilderValueByIdAndKey=function(id,key)local r=row(soldiers,id);return r and r[key]end,
 getSkillValueByIdAndKey=function(id,key)local r=row(H.tables[csvOfSkillAttribute],id);return r and r[key]end}
H.dm.getSound_off=function()return 1 end;H.dm.getMusic_off=function()return 1 end
local roles,writes,coin,diamond,grants,bagGrants={},0,100000,100000,{},{}
local originalGet=H.dm.getRoleData
H.dm.getRoleData=function(self,key)if roles[key]~=nil then return roles[key]end;return originalGet(self,key)end
H.dm.setRoleData=function(_,key,value)roles[key]=value;writes=writes+1 end
H.dm.addCoin=function(_,n)if coin+n<0 then return 0 end;coin=coin+n;return 1 end
H.dm.addDiamond=function(_,n)if diamond+n<0 then return 0 end;diamond=diamond+n;return 1 end
H.dm.addSoilderWithId=function(_,id,n)grants[#grants+1]={id,n}end
H.dm.upgradeResourceUnitWithId=function()end
H.dm.getAchievementInfo=function()return 0 end;H.dm.setAchievementInfo=function()end
local bag={breads={{id='1005',num=7}},costGoodsByGoodsIdAndNum=function()return true end,
 checkItemsIsHave=function()return true end,addItemToBattlePack=function(_,id,n)bagGrants[#bagGrants+1]={id,n}end}
ExploreBagController={getBagController=function()return bag end}
local black,elapsed={},100
local exploreDM={checkBlackMarketDatas=function()end,getBlackMarketDatas=function()return black end,
 getBlackMarketRefreshTimeInterval=function()return 3600 end,getLastBlackMarketRefreshTime=function()return 0 end}
ExploreDataManager={getInstance=function()return exploreDM end}
NotificationNode={getInstance=function()return{GetGameTime=function()return elapsed end}end}
getSystemTimeMilliSecond=function()return 1000 end
getRandomNumByRange=function(range)return range.min end
local explor={mapGuideComponent={hideAllComponents=function()end,changeFingerParent=function()end,showFingerActionByPosition=function()end}}
getExplor=function()return explor end
local guide=GuideController:getInstance();guide.getIsHaveStep=function()return true end
FightDataManager={getInstance=function(self)return self end,clearEnemyData=function()end,addEnemyFighterData=function(_,data)FightDataManager.enemy=data end}
FightFighterData={new=function()return{}end};FightCannonData={new=function()return{}end}
local arenaLevel;EternalArenaController={getInstance=function(self)return self end,bagainControleEternalArenaByLevel=function(_,level)arenaLevel=level or 1 end}
local assertions=0
local function check(ok,why)assertions=assertions+1;assert(ok,why)end
local function equal(a,b,why)check(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function bounds(node,w,h,why,sz)
 local z=sz or node:getContentSize();local a=node:convertToWorldSpace(cc.p(0,0));local b=node:convertToWorldSpace(cc.p(z.width,z.height))
 check(a.x>=-1 and b.x<=w+1 and a.y>=-1 and b.y<=h+1,why..' '..a.x..','..a.y..' '..b.x..','..b.y)
end
local function inspect(view,w,h)
 H.visit(view,function(n,visible)
  if visible and n.getString then
   if n.getFontName then equal(n:getFontName(),W.font,'clean event font')end
   local parent=n:getParent();local clipped=false
   while parent do if parent==view.eventBody or parent==view.eventDetailScroll or parent==view.tableview or parent==view.scrollview then clipped=true end;parent=parent:getParent()end
   if not clipped then bounds(n,w,h,'event text '..n:getString())else
    local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
    check(a.x>=-1 and b.x<=w+1,'clipped text still fits horizontally: '..n:getString())
   end
  end
 end)
 if view.eventBody then bounds(view.eventBody,w,h,'event body',view.eventBody:getViewSize())end
 if view.tableview then bounds(view.tableview,w,h,'detail list',view.tableview:getViewSize())end
 if view.eventDetailScroll then bounds(view.eventDetailScroll,w,h,'detail body',view.eventDetailScroll:getViewSize())end
 if view.eventPrimary then bounds(view.eventPrimary,w,h,'detail primary')end
end
local function controller()
 return {owner={mapIndex=1},checkEnterNext=function()return true end,checkIsOpen=function()return false end,
 anEventHasTriggered=function(self)self.triggered=(self.triggered or 0)+1 end,
 anEventHasToGiveUp=function(self)self.left=(self.left or 0)+1 end}
end
local families={};for _,r in pairs(sites)do if r.eventFucString~=''then families[r.eventFucString]=r end end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1136},{720,1280}})do
 H.fixture();roles={};local w,h=size[1],size[2];screenSize=cc.size(w,h);local scene=H.prepare(w,h);roles[roleMapInfo]={mapIndex=2,curIndex=1};roles[roleArenaRecords]={}
 local view=assert(EventLayer:create());scene:addChild(view);view:setController(controller())
 for _,occupied in ipairs({false,true})do
  local count=0
  for _,info in pairs(sites)do if info.eventFucString~=''then
   local before=writes;view:refreshLayerByInfo(info,occupied);view:show();inspect(view,w,h)
   equal(writes,before,'site presentation never saves')
   equal(view.description:getString(),occupied and info.occupationdescription or (info.ID=='3106' and '礁石间潜伏着危险的敌人，挡住了前路。' or info.description),'actual site prose')
   equal(view.siteKind:getString()~='',true,'actual family labeled');count=count+1
  end end
  equal(count,344,'all dispatched shipped sites')
 end
 view:refreshLayerByInfo(sites['3106'],false);view:show()
 local b=view.buttons[1];local p=b:convertToWorldSpace(cc.p(b:getContentSize().width/2,30));local touch={getLocation=function()return p end}
 check(b:onTouchBegan(touch),'native primary press accepted');b:onTouchEnded(touch);equal(view.controller.triggered,1,'original event transition invoked')
 b:onSingleCLick();equal(view.controller.triggered,1,'repeated busy event action blocked')
 view.eventActionBusy=false;check(b:onTouchBegan(touch),'second press accepted');p=cc.p(p.x+18,p.y);b:onTouchMoved(touch);b:onTouchEnded(touch);equal(view.controller.triggered,1,'drag release cannot activate dock')
 local old=b.onSingleCLick;view:refreshLayerByInfo(families.changeToPubLayer,false);old();equal(view.controller.triggered,1,'stale event generation inert')
 view:refreshLayerByInfo(sites['3106'],false);view:getsAndSetsEnemyLayerInfoByEnemy({'10002'});inspect(view,w,h)
 check(view.enemyNameLabel:getString():find(soldiers['10002'].name,1,true),'prepared actual opponent preview')
 view:showTipOccupiedLayer(sites['3106']);inspect(view,w,h);check(not view.midTip:isVisible(),'completion hides preoccupation context')
 roles[roleArenaRecords]={{costs={id='1005',num=2},level=10},{costs={id='1005',num=4},level=20},{costs={id='1005',num=6},level=30},{costs={id='1005',num=8},level=40}}
 view:refreshLayerByInfo(families.changeToEternalArena,false);view:show();inspect(view,w,h);bounds(view.scrollview,w,h,'arena options',view.scrollview:getViewSize())
 view.selectArenaRecord(2);view.buttons[1]:onSingleCLick();equal(arenaLevel,20,'arena exact original level')
 view:removeFromParent(true)
 -- All four real child categories, selected actions and modal owner lifecycle.
 local soldier=soldiers['101'];local item=resources['1005']
 local dead={id='101',name=soldier.name,icon=soldier.icon,star=tonumber(soldier.star),hp=soldier.hp,attack=soldier.attack,speed=soldier.speed,num=2,skillName='fixture',cost={id='1035',name='尸尘',costNum=50}}
 local recruit={id='101',name=soldier.name,icon=soldier.icon,star=tonumber(soldier.star),hp=soldier.hp,power=soldier.attack,speed=soldier.speed,costType='1',costs=250}
 local goods={id='1005',name=item.name,icon=item.iconName,num=5,costType='1',costs=12}
 for kind=1,4 do
  local rows=kind==1 and {dead}or(kind==2 and {recruit}or{goods});black=rows
  EventDetailsLayer.type=kind;EventDetailsLayer.data=rows
  local page=assert(EventDetailsLayer:create());scene:addChild(page);inspect(page,w,h)
  equal(page.data,rows,'detail row identity unchanged');check(page.eventSelectedData==rows[1],'first detail selected')
  if kind==1 then
   local before=#grants;page.eventPrimary.item:activate();check(page.adventureDialog~=nil,'resurrection confirmation owner bound')
   page.adventureDialog.warmOptions[2].item:activate();equal(#grants,before,'cancel revival no grant')
   page.eventPrimary.item:activate();page.adventureDialog.warmOptions[1].item:activate();equal(#grants,before+1,'original resurrection grant');equal(dead.num,1,'death record decremented exactly once')
  elseif kind==2 then
   local before=coin;local n=#grants;page.eventPrimary.item:activate();page.adventureDialog.warmOptions[1].item:activate();equal(coin,before-250,'original recruitment price');equal(#grants,n+1,'one recruit')
  elseif kind==3 then
   local before=coin;local n=#bagGrants;local old=page.eventPrimary.item;old:retain();old:activate();old:activate();old:release()
   equal(coin,before-12,'market stale repeat spends once');equal(#bagGrants,n+1,'one market cargo grant')
  else check(not page.eventPrimary,'cargo is read only')end
  local left=0;page.leaveCalBack=function()left=left+1 end;page:retain();page:close();page:close();equal(left,1,'child leave callback exactly once');page:release()
 end
 H.finish();print('PASS native coherent events '..w..'x'..h)
end
-- Isolated real controller lifecycle: both world render modes use this same
-- owner contract. Child pages never unfreeze the owner themselves.
H.fixture();roles={};screenSize=cc.size(480,800);local scene=H.prepare(480,800)
roles[roleMapInfo]={mapIndex=2,curIndex=1};roles[roleTranslateDoor]=3;roles[roleBattlePack]={}
exploreDM.clearTempOccupationData=function()end
bag.refreshBattlePack=function()end
local rewards
FightRewardScene={create=function(_,have,drop)
 rewards={have=have,drop=drop};local n=cc.Node:create()
 function n:setFightOverCallback(fn)rewards.callback=fn end
 function n:setFightResult(result)rewards.result=result end
 return n
end}
local pushed,popped=0,0
local directorGet=cc.Director.getInstance
cc.Director.getInstance=function()
 local d=directorGet();d.pushScene=function(_,newScene)pushed=pushed+1;newScene:retain();scene:addChild(newScene);newScene:release()end
 d.popScene=function()popped=popped+1 end
 return d
end
local function owner(mode)
 local root=cc.Node:create();root.cleanVoyage=mode;root.tipLayer=cc.Node:create();root:addChild(root.tipLayer)
 root.playerTitlePosition=cc.p(3,4);root.mapIndex=1;root.checkBread=function(self)self.breadChecks=(self.breadChecks or 0)+1 end
 root.initMapByMapIndex=function(self,index)self.lastMap=index end
 root.mapLayoutManagers={};root.bagController=bag;return root
end
for _,mode in ipairs({false,true})do
 local map=owner(mode);scene:addChild(map)
 local manager=EventManger.new();map:addChild(manager);manager.owner=map;manager.enemys={};manager.eventWaitingQueue={}
 manager.layer=EventLayer:create();manager:addChild(manager.layer);manager.layer:setController(manager)
 manager.costTool=nil;manager.curStrongholdData=nil;manager.isMinesweeper=false;manager.isNeedOccupied=false
 manager:freezeOwnerOperations();equal(map.statue,'Triggering','real controller freezes map');check(not map.tipLayer:isVisible(),'HUD hidden during event')
 local view=manager.layer
 view:refreshLayerByInfo(families.changeToPubLayer,false);view:show();view:enterPubLayer(families.changeToPubLayer)
 local child=view.eventDetails;check(child and child:getParent()==scene,'real pub child opens in scene');check(not map.tipLayer:isVisible(),'opening child keeps map frozen')
 view:enterPubLayer(families.changeToPubLayer);equal(view.eventDetails,child,'duplicate child enter ignored')
 local trigger=manager.anEventHasTriggered;manager.anEventHasTriggered=function(self)self:allEventsHasTriggered(true)end
 child:retain();child:close();child:close();child:release();equal(map.statue,'ready','child leave uses real controller to restore map')
 check(map.tipLayer:isVisible(),'HUD restored by original controller');equal(map.breadChecks,1,'one close means one original bread check')
 manager.anEventHasTriggered=trigger
 manager:freezeOwnerOperations();manager.isMinesweeper=true
 SkirmishLogicManagers={getInstance=function()return{minesweeperFightIsOver=function()end}end}
 manager:allEventsHasTriggered(false);equal(map.statue,'ready','minesweeper restores owner');check(map.tipLayer:isVisible(),'minesweeper HUD restored')
 -- Gate checks still use original map unlock and no save in check-only mode.
 manager.checkEnterNext=function()return true end;local before=writes
 check(not view:enterNextMapEnter(false,4,true),'locked next map denied');check(view:enterNextMapEnter(false,3,true),'unlocked map check accepted');equal(writes,before,'check-only next map does not save')
 roles[roleMapInfo].mapIndex=1;view:refreshLayerByInfo(families.changeToTeleportLayer,false);view:show();check(not view.buttons[1]:isVisible(),'first-map teleport remains locked');inspect(view,480,800)
 roles[roleMapInfo].mapIndex=2
 local worldCreated=0
 WorldMapLayer={create=function()worldCreated=worldCreated+1;local n=cc.Node:create();function n:setOwner(o)self.owner=o end;return n end}
 view:refreshLayerByInfo(families.changeToTeleportLayer,false);view:enterTeleport();view:enterTeleport();equal(worldCreated,1,'teleport opens one original map picker');equal(view.worldMapLayer.owner,view,'picker owner retained')
 view.worldMapLayer:removeFromParent(true);view.worldMapLayer=nil
 -- Material/supply loot reaches the active FightRewardScene owner. No grant
 -- happens while constructing the view or handing it original drop tables.
 manager.received=function(self)self.receivedCount=(self.receivedCount or 0)+1 end
 local transitions=0;manager.anEventHasTriggered=function()transitions=transitions+1 end
 local n=#bagGrants;view:enterMaterials(sites['3067']);check(rewards and #rewards.drop>0,'material route reaches active reward allocation')
 equal(rewards.drop[1].id,sites['3067'].dropitems[1][1],'actual material drop ID');equal(rewards.drop[1].num,tonumber(sites['3067'].dropitems[1][2]),'actual material drop count')
 equal(#bagGrants,n,'material preview cannot grant cargo');rewards.callback();equal(manager.receivedCount,1,'reward owner marks collection');equal(transitions,1,'reward closes into original event transition')
 view:enterSupplyPoint();equal(rewards.drop[1].id,bag.breads[1].id,'supply original bread ID');equal(rewards.drop[1].num,7,'supply original available count')
 -- External teardown closes the owned child and invalidates its pending modal.
 view:refreshLayerByInfo(families.changeToPubLayer,false);view:show();view:enterPubLayer(families.changeToPubLayer)
 child=view.eventDetails;child:retain();child.eventPrimary.item:activate();local modal=child.adventureDialog;check(modal~=nil,'pub confirmation opened')
 local action=modal.warmOptions[1].item;action:retain();local beforeCoin=coin;view:removeFromParent(true)
 check(child.eventClosed and not child:isVisible() and child.ownerEvent==nil,'owner teardown immediately retires child');check(not modal:isVisible() and not child.adventureDialog,'owner teardown immediately retires confirmation');action:activate();equal(coin,beforeCoin,'disposed confirmation cannot spend');action:release();child:release()
 map:removeFromParent(true)
end
cc.Director.getInstance=directorGet
-- Long lists, empty states, late timer refresh, limited items and stale modals.
local goodsId
for id,r in pairs(resources)do if tonumber(r.limits)==1 then goodsId=id;break end end
check(goodsId~=nil,'shipped one-time item exists')
local r=resources[goodsId];local goods={id=goodsId,name=r.name,icon=r.iconName,num=1,costType='1',costs=37}
black={goods};roles[roleBlackMarketRestrictions]={};EventDetailsLayer.type=3;EventDetailsLayer.data=black
local page=EventDetailsLayer:create();scene:addChild(page);local before=coin
local old=page.eventPrimary.item;old:retain();old:activate();old:activate();old:release()
equal(coin,before-37,'one-time market item spends exactly once');equal(roles[roleBlackMarketRestrictions][goodsId],0,'original permanent limit exhausted');equal(#page.data,0,'sold-out original row removed');check(not page.eventPrimary,'sold-out page has no action');page:close()
EventDetailsLayer.type=4;local cargo={};for i=1,40 do cargo[i]={id='1005',name=resources['1005'].name,icon=resources['1005'].iconName,num=i}end
EventDetailsLayer.data=cargo;page=EventDetailsLayer:create();scene:addChild(page)
equal(page.tableview:getContentOffset().y,page.eventListHeight-3200,'long list starts at first native row');page:showCellInfo(40);equal(page.eventSelectedData,cargo[40],'all cargo rows selectable');inspect(page,480,800);page:close()
for kind=1,4 do
 EventDetailsLayer.type=kind;EventDetailsLayer.data={};black={};page=EventDetailsLayer:create();scene:addChild(page);check(not page.eventPrimary,'empty detail does not invent an action');inspect(page,480,800);page:close()
end
H.finish();print('PASS original controller freeze/restore on both render-owner modes, minesweeper, pub nesting, map gates, active collection handoff, limited-item and teardown guards')

print('PASS coherent event pages native assertions: '..assertions)
