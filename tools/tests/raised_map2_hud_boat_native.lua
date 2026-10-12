-- Disposable seeded native controller fixture. No profile, GUI or game save I/O.
require 'extern';require 'LuaClass/Explore'
local L=require 'LuaClass/RaisedSeaMap2Live'
local R=require 'LuaClass/RaisedSeaMap2'
local A=require 'LuaClass/AdventureProgress'
local json=require 'LuaClass/simplejson.lua'
WARM_PIRATE_V1=true;BoldFont='fonts/CleanVoyageSans-Regular.ttf';screenSize=cc.size(tonumber(os.getenv('HUD_WIDTH'))or 480,tonumber(os.getenv('HUD_HEIGHT'))or 800)
local director=cc.Director:getInstance();local actions=director:getActionManager()
local output=assert(os.getenv('RAISED_MAP2_LIVE_CAPTURE_DIR'))
local writes,data=0,{}
local function stable(t)if type(t)~='table'then return tostring(t)end;local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end);local r={};for _,k in ipairs(keys)do r[#r+1]=tostring(k)..'='..stable(t[k])end;return '{'..table.concat(r,',')..'}'end
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local roleDisk,mapDisk,roleCommits,mapWrites
local dm={getRoleData=function(_,k)return data[k]end,setRoleData=function(_,k,v)data[k]=copy(v);writes=writes+1 end,
 setMapData=function(_,index,k,v)assert(index==2);data[k]=copy(v);writes=writes+1 end,getSound_off=function()return 1 end,getCSVByID=function()return{}end,registerEvent=function()end,unregisterEvent=function()end}
dm.__roleData={commitAdventure=function(_,fields)for k,v in pairs(fields)do data[k]=copy(v)end;roleDisk=copy(data);roleCommits=(roleCommits or 0)+1;return true end}
DataManager={getInstance=function()return dm end}
SaveDataManager={getInstance=function(self)return self end,saveDataAtomic=function(_,bytes,name)assert(name=='gameMap2');mapDisk=json.decode(bytes);mapWrites=(mapWrites or 0)+1;return true end}
package.loaded['LuaClass/SaveDataManager']=true
GuideController.getInstance=function()return {getIsHaveStep=function()return true end}end
ToastUtil={toastString=function(_,message)print('FIXTURE_TOAST',message)end}
local function label()return cc.LabelTTF:create('',BoldFont,18)end
local function seed(existingScene)
 data={[roleStatue]=1,[roleMapInfo]={curIndex=2,playerTitlePosition={x=15,y=16}},[roleBreadCostDecimal]=.25,[roleExtents]=0,
  [roleBattlePack]={['1005']={id='1005',num=30}},[roleBattleQueue]={['100']=1},[mapInfo]={titlesInfo={},fogs=0,curMapStrongholdNum=99,clearStrongHoldNum=0}}
 local owner=Explore.new();owner:retain();local bg=cc.LayerColor:create(cc.c4b(3,43,61,255),screenSize.width,screenSize.height);owner:addChild(bg,-10)
 owner.mapIndex=2;owner.map=assert(cc.TMXTiledMap:create('Images/Map/map_2.tmx'))
 if os.getenv('LIVE_FULL_THEME') then SeaChartTheme.applyTileArt(owner.map);SeaChartTheme.addLandDetails(owner.map)
 else SeaChartTheme.tintFog(owner.map,owner.map:getLayer('Fogs'));SeaChartTheme.softenGrid(owner.map)end
 owner.moveLayer=cc.Layer:create();owner:addChild(owner.moveLayer);owner.moveLayer:addChild(owner.map)
 owner.meta=owner.map:getLayer('Meta');owner.fogLayer=owner.map:getLayer('Fogs');owner.mapSize=cc.size(1984,1984)
 owner.player=cc.Sprite:create();owner.player:setContentSize(cc.size(64,64));owner.map:addChild(owner.player,5)
 local ship=cc.Sprite:create('Images/UI/Adventure/ship.png');ship:setScale(112/math.max(ship:getContentSize().width,ship:getContentSize().height));ship:setPosition(cc.p(32,32));owner.player:addChild(ship);owner.adventureShipVisual=ship;owner.player:addChild(SeaChartTheme.shipHalo(64),-1)
 owner.playerTitlePosition=cc.p(15,16);owner.player:setPosition(owner:positionForTilePosition(owner.playerTitlePosition))
 owner.jointed={enable=true,owner=owner.player,tipingByDirection=function()end,moveActed=function(direction)owner:jointedCalBack(direction)end}
 owner.contentOffset=cc.p(0,0);owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.visition=1;owner.isHungry=false
 owner.breadCostDecimal=.25;owner.breadNum=30;owner.bread=label();owner:addChild(owner.bread);owner.extentTip=label();owner:addChild(owner.extentTip)
 owner.checkBread=function()end;owner.startMapGuide=function()end
 owner.bagController={costSpace=30,limited=40,getBreads=function()return data[roleBattlePack]['1005'].num end,
  costGoodsByGoodsIdAndNum=function(_,id,num)assert(id==1005);data[roleBattlePack]['1005'].num=data[roleBattlePack]['1005'].num-num end}
 owner.mapLayoutManagers=MapLayoutManagers:create();owner:addChild(owner.mapLayoutManagers);owner.mapLayoutManagers:setOwner(owner);owner.mapLayoutManagers.data={}
 owner.eventManger={owner=owner,eventWaitingQueue={},csvData={},layer=cc.Node:create(),willTriggerEventById=function(self,id)self.eventWaitingQueue[#self.eventWaitingQueue+1]=id end,
  triggeringEventOfWating=function(self)self.lastTrigger=table.remove(self.eventWaitingQueue,1)end,minesweeper=function()return false end}
 owner.eventManger.layer:setVisible(false);owner:addChild(owner.eventManger.layer)
 local edm=ExploreDataManager:getInstance();edm.curIndex=2;edm.data=data[mapInfo];edm:setMapOwner(owner);edm.mapFogAssociatedDatas=nil
 owner.fogManager=FogManager:create();owner:addChild(owner.fogManager);owner.fogManager:setOwner(owner)
 owner:initMapFogs();owner.statue='ready'
 owner:initTipLayer();owner.tipLayer:setVisible(true)
 Up.y=64;Down.y=-64;Left.x=-64;Right.x=64;addVision=0
 local scene=existingScene or cc.Scene:create();scene:addChild(owner);if not existingScene then liveMap2Scene(scene)end
 owner:installChartTouchListener()
 owner:setViewpointCenter(cc.p(owner.player:getPosition()))
 return owner
end
local function geometry(owner)
 local t={}
 for _,name in ipairs({'Sea','Blocks_1','Blocks_2','Meta','GridLayer','Fogs'})do
  local layer=owner.map:getLayer(name);t[#t+1]=layer:getPositionX();t[#t+1]=layer:getPositionY();t[#t+1]=layer:getLocalZOrder()
  for y=0,30 do for x=0,30 do t[#t+1]=layer:getTileGIDAt(cc.p(x,y));t[#t+1]=layer:getTileFlagsAt(cc.p(x,y))end end
 end
 t[#t+1]=owner.player:getPositionX();t[#t+1]=owner.player:getPositionY()
 return table.concat(t,',')
end
local function capture(owner,name)assert(cleanWorldCapture(owner,screenSize.width,screenSize.height,output..'/'..name..'.png'))end
local function ticks(dt,n)for _=1,n do liveMap2Tick(dt)end end
local function buffers(file,cycle)local b,n,l,m=liveBufferCounts();file:write(cycle,' ',b,' ',n,' ',l,' ',m,'\n')end
local function textureProof(stage,paths)
 local f=assert(io.open(output..'/texture-'..stage..'.txt','w'))
 for _,path in ipairs(paths)do local t=director:getTextureCache():getTextureForKey(path);if t then f:write(path,' ',liveTextureHash(t,path),'\n')end end
 f:close()
end
local paths={'Images/UI/CleanSea/water-repeat.png','Images/UI/CleanSea/land-sand-repeat.png','Images/UI/CleanSea/land-forest-repeat.png',
 'Images/Map/dt_ludi.png','Images/Map/dt_senlin.png','Images/Map/t_00.png','Images/Map/dt_zhanzmw.png',
 'Images/UI/Adventure/SeaChart/Tiles/land-forest-repeat.png','Images/UI/Adventure/SeaChart/Tiles/grid.png'}


if os.getenv('MAP2_GUARD_TEST')then
 return assert(loadfile('tools/tests/raised_map2_guard_native.lua'))()({
  seed=seed,geometry=geometry,capture=capture,ticks=ticks,
  snapshot=function()return stable(data),writes end})
end

local H=require 'LuaClass/RaisedSeaMap2HUD'
local B=require 'LuaClass/RaisedSeaMap2Boat'
local Sea=require 'LuaClass/AdventureSea'
local originalHit=Sea.isHudPoint
local owner=seed();local before=geometry(owner);local serialized=stable(data);local count=writes
local coastParents={};for _,entry in ipairs(owner.map._seaChartWorldCoast.groups)do coastParents[entry.edge]={parent=entry.edge:getParent(),order=entry.edge:getOrderOfArrival(),z=entry.edge:getLocalZOrder()}end
local coastReport=owner.map._seaChartWorldCoast;coastReport.groups[#coastReport.groups+1]={group=coastReport.groups[1].group}
RAISED_MAP2_LIVE=true;assert(L.mount(owner));table.remove(coastReport.groups);local state=owner.raisedMap2Live;local h=state.hud
assert(state.hud and state.boat.lease and not cc.Node.isVisible(owner.adventureShipVisual))
assert(geometry(owner)==before and stable(data)==serialized and writes==count)
local cameraScale=screenSize.width/720
owner:setMapScale(cameraScale);owner:setViewpointCenter(cc.p(owner.player:getPosition()));ticks(.05,2);capture(owner,'initial')
local function fresh()
 owner.statue='ready';owner.jointed.enable=true;owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.eventManger.eventWaitingQueue={}
 owner.contentOffset=cc.p(0,0)
end
local function point(key)local n=h.buttons[key].item;return n:convertToWorldSpaceAR(cc.p(0,0))end
local function tap(key)local p=point(key);liveMap2Touch(p.x,p.y)end
local function gesture(phase,key)local p=point(key);liveMap2Gesture(phase,p.x,p.y)end
local function quiet()return stable(data)..':'..geometry(owner)..':'..tostring(writes)end
local function unchanged(callback,reason)local b=quiet();local x,y,food,w=owner.player:getPositionX(),owner.player:getPositionY(),owner.bagController:getBreads(),writes;callback();if quiet()~=b then print('MUTATED',reason,x,y,food,w,'to',owner.player:getPositionX(),owner.player:getPositionY(),owner.bagController:getBreads(),writes,owner.statue)end;assert(quiet()==b,reason)end
-- The inverse projection is actor-local; continuous MoveTo owns every frame.
local function attached(reason)
 local lease=assert(state.boat.lease,reason);assert(lease.actor==owner.player)
 local a=lease.upright:convertToWorldSpace(cc.p(0,0));local p=owner.player:convertToWorldSpaceAR(cc.p(0,0))
 assert(math.abs(a.x-p.x)<.002 and math.abs(a.y-p.y)<.002,reason..' drift')
 assert(not cc.Node.isVisible(owner.adventureShipVisual),reason..' duplicate')
end
owner.playerTitlePosition=cc.p(17,17);owner.player:setPosition(owner:positionForTilePosition(owner.playerTitlePosition));owner:setViewpointCenter(cc.p(owner.player:getPosition()));L.refresh(owner)
for _,r in ipairs({{'nw',-1,0},{'ne',0,-1},{'se',1,0},{'sw',0,1}})do
 fresh();local x,y=owner.playerTitlePosition.x,owner.playerTitlePosition.y;local food=owner.bagController:getBreads()
 tap(r[1]);ticks(.05,1);attached('native movement '..r[1]);capture(owner,'moving-'..r[1])
 for i=1,8 do ticks(.05,1);attached('native movement frame')end
 ticks(.1,31);assert(owner.playerTitlePosition.x==x+r[2] and owner.playerTitlePosition.y==y+r[3],'native arrow mapping '..r[1])
 assert(state.boat.lease.heading==r[1],'clean hull heading '..r[1]);assert(owner.bagController:getBreads()==food-1,'native food cost '..r[1]..' '..food..'→'..owner.bagController:getBreads())
 capture(owner,'arrived-'..r[1])
end
print('PASS shafted projected controls: NW/NE/SE/SW actual native movement, food and continuous attached clean hull')
-- Cancel, drag-away and repeated taps use the real native touch dispatcher.
fresh();unchanged(function()gesture(0,'ne');gesture(3,'ne');ticks(.1,2)end,'cancel moved boat')
unchanged(function()local p=point('ne');print('DRAG',p.x,p.y,owner.adventureHudBottom);liveMap2Gesture(0,p.x,p.y);liveMap2Gesture(1,p.x-130,p.y+150);liveMap2Gesture(2,p.x-130,p.y+150);ticks(.1,2)end,'drag-away activated')
fresh();local x,y=owner.playerTitlePosition.x,owner.playerTitlePosition.y;local food=owner.bagController:getBreads()
tap('se');tap('se');tap('se');ticks(.1,35)
assert(owner.playerTitlePosition.x==x+1 and owner.playerTitlePosition.y==y and owner.bagController:getBreads()==food-1,'rapid arrows queued extra motion')
-- Busy and modal guards hold even if state changes after touch begin.
fresh();for _,field in ipairs({'adventureDialog','warmSettingsModal','warmCollection','warmActivity'})do
 unchanged(function()gesture(0,'ne');owner[field]={};gesture(2,'ne');owner[field]=nil;ticks(.1,1)end,'held stale '..field)
end
unchanged(function()gesture(0,'ne');owner.eventManger.layer:setVisible(true);gesture(2,'ne');owner.eventManger.layer:setVisible(false);ticks(.1,1)end,'held event release')
unchanged(function()owner.jointed.enable=false;tap('ne');owner.jointed.enable=true end,'jointed guard')
unchanged(function()owner.moveWaitingQueue={{}};tap('ne');owner.moveWaitingQueue={}end,'queue guard')
print('PASS native touch cancellation, drag-away, rapid repeat and held-modal/busy suppression')
-- A hidden/reopened control is a different gesture generation, even when
-- both transitions happen between scheduler updates. A new tap still works.
local function interrupted(name,interrupt)
 fresh();owner.playerTitlePosition=cc.p(17,17);owner.player:setPosition(owner:positionForTilePosition(owner.playerTitlePosition));owner:setViewpointCenter(cc.p(owner.player:getPosition()));L.refresh(owner)
 unchanged(function()gesture(0,'ne');interrupt();gesture(2,'ne');ticks(.1,2)end,name..' revived held input')
 fresh();local food=owner.bagController:getBreads();tap('ne');ticks(.1,35)
 assert(owner.playerTitlePosition.x==17 and owner.playerTitlePosition.y==16 and owner.bagController:getBreads()==food-1,name..' fresh tap failed')
end
interrupted('tip hide/show across sync',function()owner.tipLayer:setVisible(false);L.refresh(owner);owner.tipLayer:setVisible(true);L.refresh(owner)end)
interrupted('tip hide/show without sync',function()owner.tipLayer:setVisible(false);owner.tipLayer:setVisible(true)end)
interrupted('owner visibility roundtrip',function()owner:setVisible(false);owner:setVisible(true)end)
interrupted('event show/hide without sync',function()owner.eventManger.layer:setVisible(true);owner.eventManger.layer:setVisible(false)end)
interrupted('pause/continue without sync',function()local p=assert(require('LuaClass/WarmPause').open(owner));p.continueButton:activate()end)
interrupted('dialog open/close without sync',function()local d=require('LuaClass/AdventureDialog').show('测试','原有模态生命周期',{{label='继续'}},owner);assert(d);d:close()end)
interrupted('journal open/close without sync',function()local d=assert(require('LuaClass/WarmCollection').open(owner,'log'));d:close()end)
interrupted('owner detach/reentry',function()local scene=owner:getParent();owner:removeFromParent(false);scene:addChild(owner)end)
interrupted('unrelated owner attachment',function()local n=cc.Node:create();owner:addChild(n);n:removeFromParent(true)end)
print('PASS interrupted HUD generations: synced/no-sync visibility, event, pause, dialog, journal, detach/reentry; every fresh tap recovers')
-- Actual pause/continue and actual chart dialog. Both retain native ownership.
fresh();tap('pause');assert(owner.warmPause);local pause=owner.warmPause;pause:retain();ticks(.1,1);assert(not h.root:isVisible())
unchanged(function()h.buttons.ne.item:activate()end,'paused control');capture(director:getRunningScene(),'pause')
pause.continueButton:activate();pause:release();ticks(.1,1);assert(not owner.warmPause and h.root:isVisible())
tap('chart');assert(owner.adventureDialog);capture(director:getRunningScene(),'chart-details')
local dialog=owner.adventureDialog;dialog:retain();dialog:removeFromParent(true);dialog:release();ticks(.1,1);assert(not owner.adventureDialog and h.root:isVisible())
tap('log');assert(owner.warmCollection and owner.warmCollection.tab=='log');capture(owner,'log');owner.warmCollection:close();ticks(.1,1)
-- These two probes verify delegation targets; integrated app exercises contents.
local cargo,returns=0,0;local oldCargo=owner.goBag;owner.goBag=function()cargo=cargo+1 end
local returnItem=owner.adventureReturnButton.item;local oldReturn=returnItem.activate;returnItem.activate=function()returns=returns+1 end
tap('cargo');tap('return');assert(cargo==1 and returns==1);owner.goBag=oldCargo;returnItem.activate=oldReturn
-- Full objective stays disclosed, warnings remain compact and truthful.
data[roleBattlePack]['1005'].num=4;L.refresh(owner);capture(owner,'low-food');assert(h.goalLabel:getString():find('口粮'))
data[roleBattlePack]['1005'].num=25;L.refresh(owner)
owner.tipLayer:setVisible(false);L.refresh(owner);assert(not h.root:isVisible() and not cc.Node.isVisible(owner.tipLayer))
owner.tipLayer:setVisible(true);L.refresh(owner);assert(h.root:isVisible() and not cc.Node.isVisible(owner.tipLayer))
print('PASS actual pause, chart and log access; original cargo/return dispatch; native tip visibility and low-food warning')
-- Restore latest art values, preserve active native actions and use conservative
-- source fallback for visual Show/Hide sequences that execute below Lua.
local art=owner.adventureShipVisual;local oldAnchor=art:getAnchorPoint();local oldRotation=art:getRotation()
art:setVisible(false);assert(not state.boat.lease.root:isVisible());art:setVisible(true)
art:setOpacity(127);art:setColor(cc.c3b(180,220,240));art:setRotation(7);art:setAnchorPoint(cc.p(.43,.47));L.refresh(owner)
assert(state.boat.lease.sprites[state.boat.lease.heading]:getOpacity()==127)
local a=cc.Sequence:create(cc.FadeTo:create(.2,91),cc.RotateBy:create(.2,11),cc.Hide:create(),cc.DelayTime:create(.2),cc.Show:create())
art:runAction(a);assert(not state.boat.lease and art:getNumberOfRunningActions()==1);ticks(.1,3)
assert(not state.boat.lease,'source action must not be visually replaced');capture(owner,'special-art-action')
local saved=quiet();L.unmount(owner);assert(quiet()==saved and art:getNumberOfRunningActions()==1)
assert(math.abs(art:getAnchorPoint().x-.43)<.00001);assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud
assert(not state.boat.lease);ticks(.1,8);L.refresh(owner);attached('reacquired after native action')
assert(art:isVisible() and art:getOpacity()==91 and math.abs(art:getRotation()-18)<.01 and math.abs(art:getAnchorPoint().x-.43)<.00001)
art:setOpacity(255);art:setColor(cc.c3b(255,255,255));art:setRotation(oldRotation);art:setAnchorPoint(oldAnchor);L.refresh(owner)
print('PASS native actor/art hide-show, opacity/rotation/anchor, action-time fallback and mid-action toggle restoration')
-- Native actor replacement retires only the old presentation lease.
local oldActor=owner.player;oldActor:retain();oldActor:removeFromParent(false)
local replacement=cc.Sprite:create();replacement:setContentSize(cc.size(64,64));replacement:setPosition(cc.p(oldActor:getPosition()));owner.map:addChild(replacement,5)
local replacementArt=cc.Sprite:create('Images/UI/Adventure/ship.png');replacementArt:setScale(112/math.max(replacementArt:getContentSize().width,replacementArt:getContentSize().height));replacementArt:setPosition(cc.p(32,32));replacement:addChild(replacementArt)
local replacementBefore=stable(data);local replacementWrites=writes
owner.player=replacement;owner.adventureShipVisual=replacementArt;owner.jointed.owner=replacement;L.refresh(owner)
assert(state.boat.lease.actor==replacement and cc.Node.isVisible(art),'old actor lease was not retired');attached('replacement actor')
replacement:removeFromParent(true);owner.map:addChild(oldActor,5);owner.player=oldActor;owner.adventureShipVisual=art;owner.jointed.owner=oldActor;oldActor:release();L.refresh(owner)
assert(state.boat.lease.actor==oldActor and stable(data)==replacementBefore and writes==replacementWrites);attached('restored native actor')
print('PASS native actor replacement retires old art lease without drift, duplicate presentation or save writes')
-- Runtime leases are owner-scoped, bounded, and stale callbacks are harmless.
local firstOwner,firstState,firstH=owner,state,h;local firstScene=director:getRunningScene()
local second=seed(firstScene);assert(L.mount(second));local secondState=second.raisedMap2Live
local fake={adventureHudBottom=100};assert(Sea.isHudPoint(fake,cc.p(20,180))==originalHit(fake,cc.p(20,180)))
L.unmount(firstOwner);assert(Sea.isHudPoint==nil or Sea.isHudPoint~=originalHit,'second owner still needs lease')
assert(not H.canAct(firstH));unchanged(function()firstH.disposed=true end,'stale HUD disposal')
L.unmount(second);assert(Sea.isHudPoint==originalHit,'last owner restores exact shared function')
second:removeFromParent(true);second:release();assert(L.mount(firstOwner));owner=firstOwner;state=owner.raisedMap2Live;h=state.hud
-- A stale held menu cannot activate after unmount/remount.
fresh();local oldButton=h.buttons.ne.item;oldButton:retain();local held=point('ne');gesture(0,'ne');local saved=quiet();L.unmount(owner);liveMap2Gesture(2,held.x,held.y);oldButton:activate();oldButton:release();assert(quiet()==saved)
assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud
print('PASS second-owner nested mount/unmount, unrelated-owner fallback, stale held input and exact shared-hit-hook restoration')
-- Existing decorators keep all overload arguments/return tuples. Leases retire
-- only their own installed function; a newer decorator survives stale teardown.
L.unmount(owner)
local targets={{target=owner,name='addChild'},{target=owner,name='setVisible'},{target=owner.tipLayer,name='setVisible'},{target=owner.eventManger.layer,name='setVisible'}}
local function pack(...)return {n=select('#',...),...}end
for _,lease in ipairs(targets)do
 local target,name=lease.target,lease.name;local peer=tolua.getpeer(target)
 lease.saved=peer and rawget(peer,name);lease.native=target[name]
 lease.decorated=function(self,...)
  lease.args=pack(...)
  if name=='setVisible'then lease.native(self,(...))else lease.native(self,...)end
  return 'decorator',nil,select('#',...)
 end
 target[name]=lease.decorated
end
assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud
for _,lease in ipairs(targets)do
 if lease.name=='addChild'then
  for _,args in ipairs({{}, {4}, {4,287}})do
   local node=cc.Node:create();local result=pack(owner:addChild(node,unpack(args)))
   assert(result.n==3 and result[1]=='decorator'and result[2]==nil and result[3]==#args+1)
   assert(lease.args.n==#args+1 and lease.args[1]==node)
   for i,value in ipairs(args)do assert(lease.args[i+1]==value)end
   assert(node:getParent()==owner,'decorated addChild did not attach native child')
   if args[1]then assert(node:getLocalZOrder()==args[1])end
   if args[2]then assert(node:getTag()==args[2])end
   node:removeFromParent(true)
  end
 else
  local visible=(lease.target==owner.tipLayer or lease.target==owner)
  local result=pack(lease.target:setVisible(visible,'metadata',nil,'tail'))
  assert(result.n==3 and result[1]=='decorator'and result[2]==nil and result[3]==4)
  assert(lease.args.n==4 and lease.args[2]=='metadata'and lease.args[3]==nil and lease.args[4]=='tail')
 end
end
L.unmount(owner)
for _,lease in ipairs(targets)do assert(lease.target[lease.name]==lease.decorated,'original decorator was not restored')end
assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud
for _,lease in ipairs(targets)do
 local installed=lease.target[lease.name]
 lease.newer=function(self,...)return installed(self,...)end
 lease.target[lease.name]=lease.newer
end
local stale=h;L.unmount(owner);assert(stale.disposed)
for _,lease in ipairs(targets)do
 assert(lease.target[lease.name]==lease.newer,'teardown overwrote a newer decorator')
 local result
 if lease.name=='addChild'then
  local node=cc.Node:create();result=pack(owner:addChild(node,4,288))
  assert(node:getParent()==owner and node:getLocalZOrder()==4 and node:getTag()==288,'stale decorator did not attach native child')
  node:removeFromParent(true)
 else result=pack(lease.target:setVisible((lease.target==owner.tipLayer or lease.target==owner),'after',nil,'dispose'))end
 assert(result.n==3 and result[1]=='decorator'and result[2]==nil)
end
-- Remount above a surviving newer wrapper, then remove just that newest lease.
assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud;L.unmount(owner)
for _,lease in ipairs(targets)do assert(lease.target[lease.name]==lease.newer);lease.target[lease.name]=lease.saved end
assert(L.mount(owner));state=owner.raisedMap2Live;h=state.hud
print('PASS owner-local method leases: overloads, nil return tuples, existing/newer decorators and nested stale teardown')
-- Reproduce the auditor's (12,17) compact camera. Outside-map coast gutter is
-- clipped; source fog/unknown cells stay exactly the same original node/data.
owner.player:setPosition(owner:positionForTilePosition(cc.p(12,17)));owner.playerTitlePosition=cc.p(12,17);fresh()
owner:setMapScale(.5);owner:setViewpointCenter(cc.p(owner.player:getPosition()));L.refresh(owner);capture(owner,'compact-edge-fixed')
state.view.root:setVisible(false);capture(owner,'compact-edge-source-only');state.view.root:setVisible(true)
local edgeBefore=quiet();local fog=owner.fogLayer
for _,clip in ipairs(state.coasts)do clip.clip:setInverted(true)end
capture(owner,'outside-coast-counterfactual')
for _,clip in ipairs(state.coasts)do clip.clip:setInverted(false)end
assert(quiet()==edgeBefore and owner.fogLayer==fog)
for _,p in ipairs({{0,0},{0,30},{30,0},{30,30}})do
 owner.player:setPosition(owner:positionForTilePosition(cc.p(unpack(p))));owner:setMapScale(.3);owner:setViewpointCenter(cc.p(owner.player:getPosition()));capture(owner,'boundary-'..p[1]..'-'..p[2])
end
owner.player:setPosition(owner:positionForTilePosition(owner.playerTitlePosition));owner:setMapScale(cameraScale);owner:setViewpointCenter(cc.p(owner.player:getPosition()));L.refresh(owner)
capture(owner,'context-before');local file=assert(io.open(output..'/context-counts.txt','w'))
for i=1,6 do
 if i%2==0 then cleanWorldExit(owner)end
 cleanWorldBackground();cleanWorldRestore();if i%2==0 then cleanWorldEnter(owner)end
 capture(owner,'context-'..i);cleanWorldDrain();local b,n,l,m=liveBufferCounts();file:write(i,' ',b,' ',n,' ',l,' ',m,'\n')
end;file:close()
local exact=quiet();L.unmount(owner);assert(quiet()==exact and owner.tipLayer:isVisible() and Sea.isHudPoint==originalHit)
for edge,s in pairs(coastParents)do assert(edge:getParent()==s.parent and edge:getLocalZOrder()==s.z,'coast parent/order restoration')end
assert(L.mount(owner));state=owner.raisedMap2Live
owner:removeFromParent(true);assert(not owner.raisedMap2Live and state.hud==nil and state.boat==nil and Sea.isHudPoint==originalHit)
owner:release();cleanWorldDrain()
print('PASS coast boundary clip, exact native invariance, six active/paused context recoveries and cleanup')
