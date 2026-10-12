-- Disposable seeded native controller fixture. No profile, GUI or game save I/O.
require 'extern';require 'LuaClass/Explore'
local L=require 'LuaClass/RaisedSeaMap2Live'
local R=require 'LuaClass/RaisedSeaMap2'
local A=require 'LuaClass/AdventureProgress'
local json=require 'LuaClass/simplejson.lua'
WARM_PIRATE_V1=false;BoldFont='fonts/CleanVoyageSans-Regular.ttf';screenSize=cc.size(1200,760)
local director=cc.Director:getInstance();local actions=director:getActionManager()
local output=assert(os.getenv('RAISED_MAP2_LIVE_CAPTURE_DIR'))
local writes,data=0,{}
local function stable(t)if type(t)~='table'then return tostring(t)end;local keys={};for k in pairs(t)do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b)end);local r={};for _,k in ipairs(keys)do r[#r+1]=tostring(k)..'='..stable(t[k])end;return '{'..table.concat(r,',')..'}'end
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
local roleDisk,mapDisk,roleCommits,mapWrites
local dm={getRoleData=function(_,k)return data[k]end,setRoleData=function(_,k,v)data[k]=copy(v);writes=writes+1 end,
 setMapData=function(_,index,k,v)assert(index==2);data[k]=copy(v);writes=writes+1 end,getSound_off=function()return 1 end}
dm.__roleData={commitAdventure=function(_,fields)for k,v in pairs(fields)do data[k]=copy(v)end;roleDisk=copy(data);roleCommits=(roleCommits or 0)+1;return true end}
DataManager={getInstance=function()return dm end}
SaveDataManager={getInstance=function(self)return self end,saveDataAtomic=function(_,bytes,name)assert(name=='gameMap2');mapDisk=json.decode(bytes);mapWrites=(mapWrites or 0)+1;return true end}
package.loaded['LuaClass/SaveDataManager']=true
GuideController.getInstance=function()return {getIsHaveStep=function()return true end}end
ToastUtil={toastString=function(_,message)print('FIXTURE_TOAST',message)end}
local function label()return cc.LabelTTF:create('',BoldFont,18)end
local function seed()
 data={[roleStatue]=1,[roleMapInfo]={curIndex=2,playerTitlePosition={x=15,y=16}},[roleBreadCostDecimal]=.25,[roleExtents]=0,
  [roleBattlePack]={['1005']={id='1005',num=30}},[roleBattleQueue]={['100']=1},[mapInfo]={titlesInfo={},fogs=0,curMapStrongholdNum=99,clearStrongHoldNum=0}}
 local owner=Explore.new();owner:retain()
 owner.mapIndex=2;owner.map=assert(cc.TMXTiledMap:create('Images/Map/map_2.tmx'))
 if os.getenv('LIVE_FULL_THEME') then SeaChartTheme.applyTileArt(owner.map);SeaChartTheme.addLandDetails(owner.map)
 else SeaChartTheme.tintFog(owner.map,owner.map:getLayer('Fogs'));SeaChartTheme.softenGrid(owner.map)end
 owner.moveLayer=cc.Layer:create();owner:addChild(owner.moveLayer);owner.moveLayer:addChild(owner.map)
 owner.meta=owner.map:getLayer('Meta');owner.fogLayer=owner.map:getLayer('Fogs');owner.mapSize=cc.size(1984,1984)
 owner.player=cc.Sprite:create();owner.player:setContentSize(cc.size(64,64));owner.map:addChild(owner.player,5)
 local ship=cc.Sprite:create('Images/UI/CleanSea/ship-clean.png');ship:setScale(64/ship:getContentSize().width);ship:setPosition(cc.p(32,32));owner.player:addChild(ship)
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
 local screen=screenSize;screenSize=cc.size(640,960);owner:initTipLayer();screenSize=screen
 owner.tipLayer:setVisible(false);owner.adventureHudBottom=nil;owner.adventureHudTop=nil
 Up.y=64;Down.y=-64;Left.x=-64;Right.x=64;addVision=0
 local scene=cc.Scene:create();scene:addChild(owner);liveMap2Scene(scene)
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
local function capture(owner,name)assert(cleanWorldCapture(owner,1200,760,output..'/'..name..'.png'))end
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
if os.getenv('LIVE_BASELINE_ONLY') then
 local owner=seed();RAISED_MAP2_LIVE=false
 for _,arrow in ipairs(owner.raisedMap2Arrows)do if arrow.direction==RightDircion then arrow.button:activate()end end;ticks(.1,35)
 owner:jointedCalBack(BottomDirction);ticks(.1,35)
 local P=require 'LuaClass/WarmPause';owner.statue='ready';owner.jointed.enable=true;owner.eventManger.eventWaitingQueue={}
 local modal=assert(P.open(owner));modal:retain();ticks(.1,8);modal.continueButton:activate();modal:release();ticks(.1,8)
 capture(owner,'original-context-before');textureProof('before',paths)
 cleanWorldBackground();cleanWorldRestore();capture(owner,'original-context-after');textureProof('after',paths)
 cleanWorldExit(owner);cleanWorldBackground();cleanWorldRestore();cleanWorldEnter(owner);capture(owner,'original-context-paused')
 cleanWorldDrain();local counts=assert(io.open(output..'/buffer-counts.txt','w'));buffers(counts,2)
 for i=3,6 do
  if i%2==0 then cleanWorldExit(owner)end;cleanWorldBackground();cleanWorldRestore();if i%2==0 then cleanWorldEnter(owner)end
  capture(owner,'original-context-repeat-'..i);cleanWorldDrain();buffers(counts,i)
 end;counts:close()
 owner:removeFromParent(true);owner:release();cleanWorldDrain();print('PASS original-route independent context capture');return
end
local owner=seed();RAISED_MAP2_LIVE=false;local before=geometry(owner);local bytes=json.encode(data);local beforeWrites=writes
assert(not L.mount(owner) and not owner.raisedMap2Live,'explicit original comparison is off')
RAISED_MAP2_LIVE=true;assert(L.mount(owner));assert(L.mount(owner))
assert(before==geometry(owner),'presentation modified original tile/event/fog/actor values')
assert(beforeWrites==writes and bytes==json.encode(data),'mount wrote a save')
local state=owner.raisedMap2Live
for _,scale in ipairs({.3,.6,1})do
 owner:setZoomScale(scale);owner.moveLayer:setPosition(cc.p(37,-83))
 for y=0,30 do for x=0,30 do
  local p=owner:positionForTilePosition(cc.p(x,y));local world=owner.map:convertToWorldSpace(p)
  local logical=owner.map:convertToNodeSpace(world)
  assert(math.abs(logical.x-p.x)<.002 and math.abs(logical.y-p.y)<.002,'native input inverse')
  local overlay=state.view.root:convertToWorldSpace(R.project(p.x,p.y))
  assert(math.abs(overlay.x-world.x)<.002 and math.abs(overlay.y-world.y)<.002,'native overlay/source mismatch')
 end end
end
owner:setZoomScale(1);owner:setViewpointCenter(cc.p(owner.player:getPosition()))
capture(owner,'live-partial-fog')
-- Original Fogs, including native materialized fade sprite, remain the same node.
local fog=owner.fogLayer;local point=cc.p(19,16);owner:changeFogByPosition(point,'15')
local tile=fog:getTileAt(point);owner:fadeFogByPosition(point);ticks(.125,2)
local alpha=tile:getOpacity();assert(alpha>0 and alpha<255,'real fade action advanced')
L.dirty(owner);assert(L.refresh(owner));assert(owner.fogLayer==fog and fog:getTileAt(point)==tile and tile:getOpacity()==alpha)
capture(owner,'live-animated-fog')
local beforeToggle=json.encode(data);beforeWrites=writes
L.unmount(owner);assert(owner.map:getParent()==owner.moveLayer and beforeToggle==json.encode(data) and writes==beforeWrites)
assert(tile:getOpacity()==alpha and tile:getNumberOfRunningActions()==1,'toggle retained active native fog action')
assert(L.mount(owner));ticks(.125,5);assert(tile:getOpacity()==0,'fade completes through toggle')

print('PASS live map2 initial native proof: 2883 cell transforms, original TMX identities and animated fog retained, zero presentation save writes')
-- Fog pixels use the exact native source layer, with no silhouette substitution.
owner:setViewpointCenter(cc.p(owner.player:getPosition()))
L.refresh(owner);capture(owner,'live-fog-overlay')
owner.raisedMap2Live.view.root:setVisible(false);capture(owner,'live-fog-reference');owner.raisedMap2Live.view.root:setVisible(true)
local f=assert(io.open(output..'/fog-transform.txt','w'))
for _,p in ipairs({cc.p(0,0),cc.p(1,0),cc.p(0,1)})do local q=owner.map:convertToWorldSpace(p);f:write(q.x,' ',q.y,'\n')end
for y=0,30 do for x=0,30 do f:write(tonumber(owner.fogManager.data[tostring(x+y*31)])==0 and '0' or '1')end;f:write('\n')end;f:close()
-- Differential movement trace runs identical actual controller/food/fog methods
-- against copied seeded state, once through the ordinary path and once live.
local function movementTrace(live)
 L.unmount(owner);owner:removeFromParent(true);owner:release();RAISED_MAP2_LIVE=live;owner=seed();if live then assert(L.mount(owner))end
 local trace={};local function saveTrace(label)
  trace[#trace+1]=label..':'..json.encode(data)..':'..geometry(owner)..':'..owner.statue..':'..tostring(owner.eventManger.lastTrigger)
 end
 local initialFood=data[roleBattlePack]['1005'].num
 local start=copy(owner.playerTitlePosition)
 for _,arrow in ipairs(owner.raisedMap2Arrows)do if arrow.direction==RightDircion then arrow.button:activate()end end;ticks(.1,1);assert(owner.playerTitlePosition.x==start.x+1)
 assert(data[roleBattlePack]['1005'].num==initialFood-1,'actual food cost')
 ticks(.1,34);L.refresh(owner);saveTrace('right')
 assert(data[roleMapInfo].playerTitlePosition.x==start.x+1,'original delayed save')
 -- Real native touch dispatcher, actual production listener and inverse projection.
 local target=owner:positionForTilePosition(cc.p(start.x+1,start.y+1));local world=owner.map:convertToWorldSpace(target)
 owner.statue='ready';owner.contentOffset=cc.p(0,0);owner.jointed.enable=true
 liveMap2Touch(world.x,world.y);ticks(.1,35);L.refresh(owner)
 assert(owner.playerTitlePosition.x==start.x+1 and owner.playerTitlePosition.y==start.y+1,'real touch heading')
 saveTrace('touch-down')
 -- Occupied shared GID48 retains exact live ID, state and original callback.
 local p=cc.p(start.x+2,start.y+1);local key=tostring(p.x+p.y*31)
 owner.mapLayoutManagers.data[key]={id='3108',gid=19,statues='1'}
 owner:changeTitleByTitlePosition(p,19);L.refresh(owner)
 owner.statue='ready';owner:jointedCalBack(RightDircion);ticks(.1,35);L.refresh(owner)
 assert(tostring(owner.eventManger.lastTrigger)=='10','unchanged generic native trigger')
 owner.mapLayoutManagers.data[key].gid=48;owner.mapLayoutManagers.data[key].statues='2';owner:changeTitleByTitlePosition(p,48);L.refresh(owner)
 local event=R.eventAt(owner,p.x,p.y);assert(event.id=='3108' and event.gid==48 and event.state=='2','occupied enemy never becomes supply')
 saveTrace('event-occupied')
 -- Blocked coast rejection is delegated to the unmodified controller.
 local blockedFrom,blockedDirection
 for y=1,29 do for x=1,29 do
  local b=owner.map:getLayer('Blocks_1'):getTileGIDAt(cc.p(x+1,y));local c=owner.map:getLayer('Blocks_2'):getTileGIDAt(cc.p(x+1,y))
  if type(owner.map:getPropertiesForGID(b))=='table' or type(owner.map:getPropertiesForGID(c))=='table' then blockedFrom=cc.p(x,y);blockedDirection=Right;break end
 end;if blockedFrom then break end end
 owner.player:setPosition(owner:positionForTilePosition(blockedFrom));owner.playerTitlePosition=blockedFrom;owner.statue='ready'
 local food=data[roleBattlePack]['1005'].num;owner:tryToMoveForDirction(blockedDirection)
 assert(owner.playerTitlePosition==blockedFrom and data[roleBattlePack]['1005'].num==food,'original collision/food unchanged')
 saveTrace('blocked')
 return table.concat(trace,'\n')
end
local legacy=movementTrace(false);local live=movementTrace(true)
assert(legacy==live,'live/original controller serialized trace differs')
print('PASS real controller parity: arrow/touch movement, food, delay, fog reveal, event, occupied GID48 and blocked coast')
-- Actual pause controls/checkpoint use isolated copied in-memory storage only.
local P=require 'LuaClass/WarmPause';owner.statue='ready';owner.jointed.enable=true
owner.moveWaitingQueue={};owner.moveDirectionQueue={};owner.eventManger.eventWaitingQueue={}
local witness=cc.Node:create();owner.map:addChild(witness);local work=0
witness:runAction(cc.Sequence:create(cc.DelayTime:create(.2),cc.CallFunc:create(function()work=work+1 end)))
local modal=assert(P.open(owner));modal:retain();ticks(.1,8);assert(work==0,'pause freezes native child actions')
local frozenBytes=json.encode(data);local count=writes;L.dirty(owner);L.refresh(owner)
assert(frozenBytes==json.encode(data) and count==writes,'presentation update is save-neutral while paused')
modal.saveButton:activate();assert(modal.saveResult=='saved' and roleCommits==1 and mapWrites==1)
assert(roleDisk[roleMapInfo].playerTitlePosition.x==owner.playerTitlePosition.x and roleDisk[roleBreadCostDecimal]==owner.breadCostDecimal)
assert(stable(mapDisk)==stable(data[mapInfo]),'pause saves exact authoritative map')
modal.continueButton:activate();modal:release();ticks(.1,8);assert(work==1 and not owner.warmPause)
local checkpointBytes=json.encode(data);local checkpointWrites=writes;local saved=copy(roleDisk[roleMapInfo].playerTitlePosition)
owner.player:setPosition(cc.p(1,1));owner.playerTitlePosition=cc.p(0,0);owner:initPlayer()
assert(owner.playerTitlePosition.x==saved.x and owner.playerTitlePosition.y==saved.y and checkpointBytes==json.encode(data) and checkpointWrites==writes,'actual initPlayer restores same saved tile read-only')
print('PASS native pause-save-resume: same child actions, exact map/position/fraction snapshot, no presentation save field')
-- Renderer reconstruction and sibling insertion never change final pixels.
owner.playerTitlePosition=cc.p(15,16);owner.player:setPosition(owner:positionForTilePosition(owner.playerTitlePosition))

owner.statue='ready';owner:setViewpointCenter(cc.p(owner.player:getPosition()));ticks(.1,35);L.refresh(owner)
local function raisedOnly(name)
 local root=owner.raisedMap2Live.view.root;local p=R.tilePoint(owner.map,15,16);root:setPosition(cc.p(600-p.x,380-p.y))
 assert(cleanWorldCapture(root,1200,760,output..'/'..name..'.png'));root:setPosition(cc.p(0,0))
end
textureProof('before',paths);raisedOnly('raised-only-before')
capture(owner,'live-context-before')
owner.raisedMap2Live.view.root:setVisible(false);capture(owner,'source-only-before');owner.raisedMap2Live.view.root:setVisible(true)
local extra=cc.Node:create();owner.moveLayer:addChild(extra,17);capture(owner,'live-child-added');extra:removeFromParent(true);capture(owner,'live-child-removed')
cleanWorldBackground();cleanWorldRestore();capture(owner,'live-context-active');capture(owner,'live-context-active-second')
textureProof('after',paths);raisedOnly('raised-only-after');owner.raisedMap2Live.view.root:setVisible(false);capture(owner,'source-only-after');owner.raisedMap2Live.view.root:setVisible(true)
cleanWorldExit(owner);cleanWorldBackground();cleanWorldRestore();cleanWorldEnter(owner);capture(owner,'live-context-paused')
cleanWorldDrain();local expectedLive,expectedCached,collisions=liveTextureCounts();assert(collisions==0,'stale names deleted during reload')
liveTextureReplace()
local countFile=assert(io.open(output..'/texture-counts.txt','w'));countFile:write('2 ',expectedLive,' ',expectedCached,' ',collisions,'\n')
local bufferFile=assert(io.open(output..'/buffer-counts.txt','w'));buffers(bufferFile,2)
for iteration=3,6 do
 local paused=iteration%2==0;if paused then cleanWorldExit(owner)end
 cleanWorldBackground();cleanWorldRestore();if paused then cleanWorldEnter(owner)end
 capture(owner,'live-context-repeat-'..iteration);textureProof('repeat-'..iteration,paths);cleanWorldDrain()
 buffers(bufferFile,iteration)
 local live,cached,bad=liveTextureCounts();countFile:write(iteration,' ',live,' ',cached,' ',bad,'\n')
 assert(live==expectedLive and cached==expectedCached and bad==0,'texture names/cache grew or a stale texture was deleted')
end
countFile:close();bufferFile:close()
print('PASS six active/paused context recoveries: no stale deletion or texture-name/cache-entry growth')
local frozen=json.encode(data);local count=writes
RAISED_MAP2_LIVE=false;L.refresh(owner);assert(not owner.raisedMap2Live and count==writes and frozen==json.encode(data))
print('PASS native context and original-route fallback capture fixtures')
owner:removeFromParent(true);owner:release();cleanWorldDrain()
