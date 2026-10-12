-- Native semantic-object lease fixture. Seeded controller, no profile, GUI or save I/O.
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
local Objects=require 'LuaClass/RaisedSeaMap2ObjectsLive'
local Catalog=require 'LuaClass/RaisedSeaObjectPresentation'
local owner=seed();RAISED_MAP2_LIVE=false
-- Parse the shipped CSV, including its original labels and event callbacks.
local file=assert(io.open('tools/tests/home_master_regression.lua'));local source=file:read('*a');file:close()
local first=assert(source:find('local function readFile',1,true));local last=assert(source:find('local soldiers=packagedCSV',first,true))
local decode=assert(loadstring('local equal=function(a,b)assert(a==b)end\n'..source:sub(first,last-1)..'\nreturn packagedCSV'))()
owner.eventManger.csvData=decode('strongholdAttribute')
for y=9,19 do for x=11,22 do local key=tostring(x+y*31);owner.fogManager.data[key]=0;owner.fogLayer:setTileGID(0,cc.p(x,y))end end
local coords={cc.p(15,15),cc.p(18,15),cc.p(15,12)}
local originals={}
local function visual(s)
 local c=s:getColor();local anchor=s:getAnchorPoint()
 return table.concat({s:getPositionX(),s:getPositionY(),s:getScaleX(),s:getScaleY(),s:getRotation(),s:getSkewX(),s:getSkewY(),
  anchor.x,anchor.y,s:getOpacity(),c.r,c.g,c.b,tostring(s:isVisible()),s:getLocalZOrder(),s:getNumberOfRunningActions()},',')
end
for i,p in ipairs(coords)do originals[i]=owner.meta:getTileAt(p);originals[i]:setOpacity(255-i*17)end
originals[2]:setVisible(false)
owner.map:sortAllChildren();local childOrder=owner.map:getChildren();local childZ={}
for _,child in ipairs(childOrder)do childZ[child]=child:getLocalZOrder()end
local originalAddChild=owner.moveLayer.addChild
local function sameChildOrder()
 owner.map:sortAllChildren();local index=0
 for _,child in ipairs(owner.map:getChildren())do
  if not owner.raisedMap2Live or child~=owner.raisedMap2Live.overlayRoot then
   index=index+1;assert(child==childOrder[index],'native equal-Z sibling order changed')
   assert(child:getLocalZOrder()==childZ[child],'native local Z changed')
  end
 end
 assert(index==#childOrder)
end
local before=geometry(owner);local saved=json.encode(data);local writeCount=writes;local visuals={}
for i,s in ipairs(originals)do visuals[i]=visual(s)end
local captureWidth=tonumber(os.getenv('OBJECT_WIDTH') or '480')
assert(captureWidth==480 or captureWidth==360)
local cameras={}
local function compact(width,name)
 screenSize=cc.size(width,width==480 and 800 or 640)
 local key=tostring(width)..(owner.raisedMap2Live and ':live' or ':original')
 if not cameras[key] then
  owner:setZoomScale(width==480 and .9 or .8);owner:setViewpointCenter(cc.p(owner.player:getPosition()))
  cameras[key]={position=cc.p(owner.moveLayer:getPosition()),scale=owner.moveLayer:getScale()}
 end
 -- Freeze the exact native camera matrix across recovery/restoration captures.
 -- Repeated inverse-transform recentering is a separate diagnostic below.
 owner.moveLayer:setScale(cameras[key].scale);owner.moveLayer:setPosition(cameras[key].position)
 assert(cleanWorldCapture(owner,screenSize.width,screenSize.height,output..'/'..name..'.png'))
end
compact(captureWidth,'warmup')
compact(captureWidth,'compact'..captureWidth..'-original-before')
assert(not L.mount(owner));RAISED_MAP2_LIVE=true;assert(L.mount(owner))
sameChildOrder()
local a=owner.raisedMap2Live.objects;local function lease(p)return a.leases[p.x+p.y*31]end
for i,p in ipairs(coords)do
 local item=assert(lease(p));assert(item.source==originals[i] and item.support==0,'canonical sites stay on original water')
 assert(not cc.Node.isVisible(originals[i]) and visual(originals[i])==visuals[i],'only rendering visibility is leased')
 assert(owner.meta:getTileAt(p)==originals[i] and originals[i]:getParent()==owner.meta)
end
assert(lease(coords[1]).appearance.family=='port' and lease(coords[2]).appearance.family=='world-chart' and lease(coords[3]).appearance.family=='resurrection')
assert(not lease(coords[2]).group:isVisible(),'initial hidden site remains hidden')
originals[2]:setVisible(true);assert(lease(coords[2]).group:isVisible(),'native Show reflected immediately')
originals[2]:setVisible(false);assert(not lease(coords[2]).group:isVisible(),'native Hide reflected immediately')
originals[1]:setOpacity(127);originals[1]:setColor(cc.c3b(180,220,240));L.refresh(owner)
assert(lease(coords[1]).group:getOpacity()==127 and lease(coords[1]).group:getColor().r==180)
originals[1]:setOpacity(238);originals[1]:setColor(cc.c3b(255,255,255))
owner.meta:setVisible(false);for _,item in pairs(a.leases)do assert(not item.group:isVisible())end
owner.meta:setVisible(true);assert(lease(coords[1]).group:isVisible())
assert(before==geometry(owner) and saved==json.encode(data) and writes==writeCount,'presentation writes native model/save')
local route,glow=cc.Node:create(),cc.Node:create()
route:setPosition(cc.p(97,113));glow:setPosition(cc.p(211,223))
owner.moveLayer:addChild(route,0);owner.moveLayer:addChild(glow,17)
route:runAction(cc.DelayTime:create(100));glow:runAction(cc.DelayTime:create(100))
local function dynamicChildren(parent)
 assert(route:getParent()==parent and glow:getParent()==parent,'dynamic source parent changed')
 assert(route:getLocalZOrder()==0 and glow:getLocalZOrder()==17,'dynamic source local Z changed')
 assert(route:getPositionX()==97 and route:getPositionY()==113 and glow:getPositionX()==211 and glow:getPositionY()==223)
 assert(route:getNumberOfRunningActions()==1 and glow:getNumberOfRunningActions()==1,'dynamic source actions lost')
 local seenMap,seenRoute,seenGlow=false,false,false;parent:sortAllChildren()
 for _,child in ipairs(parent:getChildren())do
  if child==owner.map then seenMap=true elseif child==route then assert(seenMap);seenRoute=true elseif child==glow then assert(seenRoute);seenGlow=true end
 end
 assert(seenGlow,'dynamic source sibling order changed')
end
dynamicChildren(owner.raisedMap2Live.turn)
for iteration=1,6 do
 L.unmount(owner);sameChildOrder();dynamicChildren(owner.moveLayer)
 assert(owner.moveLayer.addChild==originalAddChild,'native addChild method not restored')
 for i,s in ipairs(originals)do assert(visual(s)==visuals[i] and owner.meta:getTileAt(coords[i])==s,'toggle failed exact restoration')end
 assert(a.disposed and a.owner==nil and next(a.leases)==nil,'retained object references')
 assert(L.mount(owner));sameChildOrder();dynamicChildren(owner.raisedMap2Live.turn);a=owner.raisedMap2Live.objects
end
route:removeFromParent(true);glow:removeFromParent(true)
local build=R.build;R.build=function()return nil,'fixture-missing-art'end
L.dirty(owner);assert(not L.refresh(owner) and not owner.raisedMap2Live and a.disposed,'active fallback did not release leases')
R.build=build
for i,native in ipairs(originals)do assert(visual(native)==visuals[i],'fallback failed native visual restoration')end
compact(captureWidth,'compact'..captureWidth..'-original-after')
assert(L.mount(owner));a=owner.raisedMap2Live.objects
print('PASS six exact semantic-object toggles: native visual properties, actor identities, coordinates, GID/flags and zero writes')
-- Real source actions always keep their native actor and presentation.
local s=originals[1];local completed=0
s:runAction(cc.Sequence:create(cc.FadeTo:create(.25,71),cc.Hide:create(),cc.CallFunc:create(function()completed=completed+1 end)))
assert(not lease(coords[1]) and cc.Node.isVisible(s),'restore before native action begins')
ticks(.05,8);assert(completed==1 and s:getOpacity()==71 and not s:isVisible(),'native fade/hide action altered')
L.refresh(owner);assert(lease(coords[1]) and not lease(coords[1]).group:isVisible())
s:setVisible(true);s:setOpacity(238);L.refresh(owner)
-- Same native sprite, same cell, changing identity/state/GID/flags. Model owns it.
local p=cc.p(17,13);local key=tostring(p.x+p.y*31)
local function bind(id,gid,state)
 owner.mapLayoutManagers.data[key]={id=id,gid=gid,statues=state}
 owner:changeTitleByTitlePosition(p,gid);assert(L.refresh(owner));a=owner.raisedMap2Live.objects
 return lease(p)
end
owner.meta:removeTileAt(p);owner.mapLayoutManagers.data[key]={id='3004',gid=47,statues='1'}
owner.meta:setTileGID(47,p,2147483648);L.refresh(owner)
assert(not lease(p) and not owner.meta:getChildByTag(p.x+p.y*31) and owner.meta:getTileFlagsAt(p)==2147483648,'flagged native quad was materialized/reinterpreted')
local tavern=assert(bind('3004',47,'1'));local native=tavern.source;native:retain();native:setOpacity(193)
local arena=assert(bind('3036',48,'2'));assert(arena.source==native and arena.appearance.family=='arena' and native:getOpacity()==193)
assert(arena.event.gid==48 and arena.event.id=='3036' and arena.event.state=='2')
owner.mapLayoutManagers.data[key].id='3002';L.refresh(owner);assert(lease(p).source==native and lease(p).appearance.family=='world-chart','same-GID record rebind ignored')
local gateway=assert(bind('3052',50,'00'));assert(gateway.source==native and gateway.appearance.family=='gateway')
assert(not bind('3108',48,'2') and native:isVisible() and native:getOpacity()==193,'occupied enemy became supply/site')
assert(not bind('-3052',50,'1'),'signed trigger invented site')
owner.eventManger.csvData['3002'].eventFucString='unrelated';assert(not bind('3002',46,'00'),'callback conflict invented site')
owner.eventManger.csvData['3002'].eventFucString='changeToTeleportLayer'
assert(bind('3002',46,'00').appearance.family=='world-chart')
owner.meta:setTileGID(46,p,2147483648);L.refresh(owner);assert(owner.meta:getTileFlagsAt(p)==2147483648,'source flags replaced')
-- Native removal releases the old lease before deletion; reinsert is a new actor.
local removalOpacity=native:getOpacity()
owner.meta:removeTileAt(p);assert(not lease(p));L.refresh(owner);assert(owner.meta:getTileGIDAt(p)==0 and native:getParent()==nil)
assert(native:isVisible() and native:getOpacity()==removalOpacity,'removed retained source not restored')
local replacement=assert(bind('3004',47,'1'));assert(replacement.source~=native,'stale actor rebound')
native:release()
-- Missing asset uses unchanged native art immediately, then safely recovers.
local oldResolve=Catalog.resolve;Catalog.resolve=function(event)local q=oldResolve(event);if q and event.id=='3004' then q.path='Images/UI/CleanSeaObjects/absent.png'end;return q end
local replacementSource=replacement.source;L.refresh(owner);assert(not lease(p) and replacementSource:isVisible(),'missing art hid native site')
Catalog.resolve=oldResolve;L.refresh(owner);assert(lease(p).source==replacementSource)
print('PASS live occupancy, same-cell identity rebind, flags, removal/new actor, ambiguity, callback conflict and missing-art fallback')
-- Fog invalidation suppresses all stale silhouettes synchronously. New billboard
-- geometry shares the original fully-known ground-plane stencil, never picking.
local fogPoint=coords[1];local fogKey=tostring(fogPoint.x+fogPoint.y*31)
owner.fogManager.data[fogKey]='15';owner:changeFogByPosition(fogPoint,'15')
for _,item in pairs(a.leases)do assert(not item.group:isVisible(),'stale fog silhouettes')end
L.refresh(owner);assert(not lease(fogPoint) and originals[1]:isVisible(),'partial cell failed native fallback')
owner.fogManager.data[fogKey]=0;owner:fadeFogByPosition(fogPoint);L.dirty(owner);L.refresh(owner)
local fade=owner.fogLayer:getTileAt(fogPoint);local actionCount=fade:getNumberOfRunningActions();ticks(.05,3)
local alpha=fade:getOpacity();assert(alpha>0 and alpha<255 and actionCount==1)
L.unmount(owner);assert(fade:getOpacity()==alpha and fade:getNumberOfRunningActions()==1);assert(L.mount(owner));a=owner.raisedMap2Live.objects
ticks(.05,10);assert(fade:getOpacity()==0,'native fog fade changed')
assert(#owner.raisedMap2Live.view.eventSprites==0,'object silhouettes entered live picking')
originals[2]:setVisible(true);owner.meta:removeTileAt(p);owner.mapLayoutManagers.data[key]=nil;L.refresh(owner)
for _,width in ipairs({captureWidth})do
 compact(width,'compact'..width..'-live-before')
 local q=owner:positionForTilePosition(cc.p(15,15));local world=owner.map:convertToWorldSpace(q)
 local logical=owner.map:convertToNodeSpace(world);assert(math.abs(q.x-logical.x)<.001 and math.abs(q.y-logical.y)<.001)
end
print('PASS hidden/partial/animated fog, original projection and no replacement hit targets')
-- Pixel comparison outside known cells against the native-only route underneath.
owner:setZoomScale(.8);screenSize=cc.size(captureWidth,captureWidth==480 and 800 or 640);owner:setViewpointCenter(cc.p(owner.player:getPosition()))
local hideKey=tostring(16+14*31);owner.fogManager.data[hideKey]='15';owner:changeFogByPosition(cc.p(16,14),'15');L.refresh(owner)
compact(captureWidth,'objects-fog-overlay')
local groups={};for key,item in pairs(a.leases)do groups[key]=item.group:isVisible();item.group:setVisible(false)end
compact(captureWidth,'objects-fog-reference')
for key,item in pairs(a.leases)do item.group:setVisible(groups[key])end
local f=assert(io.open(output..'/fog-transform.txt','w'))
for _,p in ipairs({cc.p(0,0),cc.p(1,0),cc.p(0,1)})do local q=owner.map:convertToWorldSpace(p);f:write(q.x,' ',q.y,'\n')end
for y=0,30 do for x=0,30 do f:write(tonumber(owner.fogManager.data[tostring(x+y*31)])==0 and '0' or '1')end;f:write('\n')end;f:close()
owner.fogManager.data[hideKey]=0;owner:changeFogByPosition(cc.p(16,14),'0');L.refresh(owner)
-- Retain a stable rendering layout for context/lifetime comparisons.
for _,width in ipairs({captureWidth})do compact(width,'compact'..width..'-context-before')end
local counts=assert(io.open(output..'/object-buffer-counts.txt','w'))
for iteration=1,6 do
 local paused=iteration%2==0;if paused then cleanWorldExit(owner)end
 cleanWorldBackground();cleanWorldRestore();if paused then cleanWorldEnter(owner)end
 for _,width in ipairs({captureWidth})do compact(width,'compact'..width..'-context-'..iteration)end
 cleanWorldDrain();buffers(counts,iteration)
end
counts:close()
assert(saved==json.encode(data) and writes==writeCount,'object test wrote save')
print('PASS six active/paused object context recoveries and compact480/360 capture fixtures')
-- Parent disposal can happen without route unmount. Leases/hook closures must
-- disappear even when the original map children have already been cleaned.
local final=a;local meta=owner.meta;meta:retain();local fog=owner.fogLayer;fog:retain()
local nativeSetTile=cc.TMXLayer.setTileGID;local liveState=owner.raisedMap2Live
owner:removeFromParent(true);cleanWorldDrain()
assert(owner.raisedMap2Live==nil and final.disposed and final.owner==nil and next(final.leases)==nil,'parent cleanup retained adapter')
assert(meta.setTileGID==nativeSetTile and fog.setTileGID==nativeSetTile,'parent cleanup retained layer hooks')
assert(liveState.objects==nil and liveState.view==nil and liveState.turn==nil and liveState.observer==nil,'parent cleanup retained presentation references')
meta:release();fog:release();owner:release();cleanWorldDrain()
local cleanupBuffers,cleanupDraws,cleanupListeners=liveBufferCounts()
assert(cleanupDraws==0 and cleanupListeners==0,'parent cleanup retained native DrawNode listeners')
print('CLEANUP_NATIVE_COUNTS',cleanupBuffers,cleanupDraws,cleanupListeners)
print('PASS parent cleanup: no object leases, layer hooks or owner references remain')
