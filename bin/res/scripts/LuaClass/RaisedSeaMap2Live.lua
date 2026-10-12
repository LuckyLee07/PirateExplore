-- Guarded, runtime-only map2 presentation. Never reads/writes a save singleton.
-- The native map, actors, fog, callbacks and actions remain the source of truth.
local L={flag='RAISED_MAP2_LIVE'}
local HUD,Boat -- Map2-only presentation; original controls/actor remain owners.
local Objects -- Object catalog/art are also lazy and runtime-only.
local R -- The ordinary route does not load source-alpha geometry or gate art.
local function node()return cc.Node:create()end
local function recenter(owner)
 if owner.player and owner.getCenterViewPositionByActualPosition then
  owner:stopChartCameraMotion()
  owner.moveLayer:setPosition(owner:getCenterViewPositionByActualPosition(cc.p(owner.player:getPosition())))
 end
end
local function move(child,parent,z)
 local arrival=child:getOrderOfArrival()
 child:retain();child:removeFromParent(false);parent:addChild(child,z)
 child:setOrderOfArrival(arrival);child:release()
end
-- A visit resets native arrivals to zero. Cocos then uses an unstable sort
-- when another child is added. Remember ties only; current Z/arrival requests
-- still take precedence, including reorders made by newer callers.
local function orderLedger(parent,marker,last,pending)
 local ledger={parent=parent,marker=marker,last=last,ranks={},arrivals={}}
 local children=parent:getChildren()
 if pending then
  -- First observe native pending work BEFORE adding our own marker. A clean
  -- visited parent may retain old nonzero arrivals on hidden children; those
  -- must not be mistaken for fresh requests. A dirty native parent does sort.
  parent:sortAllChildren();local sorted=parent:getChildren();local changed=false
  for index,child in ipairs(children)do if sorted[index]~=child then changed=true;break end end
  if changed then
   local rank={};for index,child in ipairs(children)do rank[child]=index end
   -- Honor the pending native Z/arrival comparison, but stabilize equal ties
   -- using the pre-sort vector instead of retaining std::sort's tie shuffle.
   table.sort(children,function(a,b)
    local az,bz=a:getLocalZOrder(),b:getLocalZOrder();if az~=bz then return az<bz end
    local aa,ba=a:getOrderOfArrival(),b:getOrderOfArrival();if aa~=ba then return aa<ba end
    return rank[a]<rank[b]
   end)
  end
 end
 for index,child in ipairs(children)do ledger.ranks[child]=index;ledger.arrivals[child]=child:getOrderOfArrival() end
 return ledger,children
end
local function stabilizeOrder(ledger)
 local parent,marker=ledger.parent,ledger.marker
 if marker:getParent()~=parent then return end
 local children=parent:getChildren();local observed=ledger.observed
 local changed=not observed or ledger.count~=#children
 if not changed then
  for index,child in ipairs(children)do
   local before=observed[child]
   if not before or before.index~=index or before.z~=child:getLocalZOrder() or before.arrival~=child:getOrderOfArrival()then changed=true;break end
  end
 end
 -- Idle refresh only observes the small native sibling sets. Never dirty a
 -- parent, sort, rewrite arrival values or allocate rank records unnecessarily.
 if not changed then return end
 local saved={};local ranks=ledger.ranks
 for index,child in ipairs(children)do
  local arrival=child:getOrderOfArrival()
  local requested=arrival~=0 and arrival~=ledger.arrivals[child] and arrival or 0
  saved[#saved+1]={node=child,z=child:getLocalZOrder(),arrival=arrival,requested=requested,rank=ranks[child] or #children+index}
 end
 table.sort(saved,function(a,b)
  if a.node==b.node then return false end
  if a.z~=b.z then return a.z<b.z end
  if ledger.last and (a.node==marker or b.node==marker)then return b.node==marker end
  if a.requested~=b.requested then return a.requested<b.requested end
  return a.rank<b.rank
 end)
 local markerRank
 ledger.ranks={};ledger.arrivals={};ledger.observed={};ledger.count=#children
 for index,entry in ipairs(saved)do
  entry.node:setOrderOfArrival(index);ledger.ranks[entry.node]=index;ledger.arrivals[entry.node]=entry.arrival
  ledger.observed[entry.node]={index=index,z=entry.z,arrival=entry.arrival}
  if entry.node==marker then markerRank=index end
 end
 -- Mark only our node dirty, then recover every current native property.
 parent:reorderChild(marker,marker:getLocalZOrder());marker:setOrderOfArrival(markerRank)
 parent:sortAllChildren()
 for _,entry in ipairs(saved)do entry.node:setOrderOfArrival(entry.arrival)end
end
local function cameraSnapshot(owner,camera)
 camera=camera or owner.moveLayer;local size=screenSize or cc.Director:getInstance():getVisibleSize()
 return {x=camera:getPositionX(),y=camera:getPositionY(),sx=camera:getScaleX(),sy=camera:getScaleY(),
  width=size.width,height=size.height,bottom=owner.adventureHudBottom,top=owner.adventureHudTop,
  actor=owner.player,px=owner.player and owner.player:getPositionX(),py=owner.player and owner.player:getPositionY()}
end
local function sameCamera(a,b)
 for _,key in ipairs({'x','y','sx','sy','width','height','bottom','top','actor','px','py'})do if a[key]~=b[key]then return false end end
 return true
end
local function returnCamera(owner,state,focus)
 local camera=state.moveLayer
 if sameCamera(cameraSnapshot(owner,camera),state.mountedCamera)then
  -- No float inverse round trip for the overwhelmingly common unchanged case.
  camera:setPosition(cc.p(state.originalCamera.x,state.originalCamera.y));return
 end
 -- Preserve the CURRENT chart point under the viewport center after a pan,
 -- zoom or movement. Do not restore a stale actor position or camera snapshot.
 local actual=owner:convertToNodeSpace(state.map:convertToWorldSpace(focus.source))
 local position=cc.p(camera:getPositionX()+focus.point.x-actual.x,camera:getPositionY()+focus.point.y-actual.y)
 if owner.map==state.map and owner.moveLayer==camera then
  owner:stopChartCameraMotion();position=owner:clampChartPosition(position)
 end
 camera:setPosition(position)
end
-- Legacy coast FBOs include a sampling gutter beyond the TMX rectangle.
-- The original rectangular camera never sees it; the projected camera does.
-- Bound these cosmetic groups only, leaving native fog and all TMX cells alone.
local function clipCoasts(owner,state)
 state.coasts={};local report=owner.map._seaChartWorldCoast
 if not report then return end
 local size=owner.map:getContentSize()
 for _,chunk in ipairs(report.groups or{})do
  local group,edge=chunk.group,chunk.edge;local box=edge and edge:getBoundingBox()
  if group and edge and group:getParent()==owner.map and edge:getParent()==group and box and (box.x<0 or box.y<0 or box.x+box.width>size.width or box.y+box.height>size.height)then
   local stencil=cc.DrawNode:create();local color=cc.c4f(1,1,1,1)
   stencil:drawTriangle(cc.p(0,0),cc.p(size.width,0),cc.p(size.width,size.height),color)
   stencil:drawTriangle(cc.p(0,0),cc.p(size.width,size.height),cc.p(0,size.height),color)
   local dispatcher=stencil:getEventDispatcher()
   stencil:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(stencil)end end)
   local clip=cc.ClippingNode:create(stencil);clip:setAlphaThreshold(.5)
   local z,order=edge:getLocalZOrder(),edge:getOrderOfArrival();edge:retain();clip:retain();group:retain()
   -- The source group stays in place, preserving every native map sibling.
   edge:removeFromParent(false);clip:addChild(edge,z);edge:setOrderOfArrival(order)
   group:addChild(clip,z);clip:setOrderOfArrival(order)
   state.coasts[#state.coasts+1]={group=group,edge=edge,clip=clip,z=z,order=order}
  end
 end
end
local function restoreCoasts(owner,state,cleanup)
 for _,entry in ipairs(state.coasts or{})do
  if not cleanup and entry.edge:getParent()==entry.clip and entry.clip:getParent()==entry.group then
   local arrival=entry.edge:getOrderOfArrival();entry.edge:removeFromParent(false);entry.group:addChild(entry.edge,entry.edge:getLocalZOrder());entry.edge:setOrderOfArrival(arrival)
   entry.clip:removeFromParent(true)
  end
  entry.edge:release();entry.clip:release();entry.group:release()
 end
 state.coasts=nil
end
-- Match the native fog's opaque ink outside the rectangular map. This cover
-- belongs to the existing background, so camera/world ownership is unchanged.
local function coverBackground(owner,state)
 local size=screenSize or cc.Director:getInstance():getVisibleSize()
 for _,child in ipairs(owner:getChildren())do
  local bounds=child:getContentSize()
  if tolua.type(child)=='cc.LayerColor' and child:isVisible() and bounds.width==size.width and bounds.height==size.height then
   local cover=cc.LayerColor:create(cc.c4b(3,35,52,255),size.width,size.height)
   child:addChild(cover,1);cover:retain();state.backdrop=cover;return
  end
 end
end
local function restoreBackground(state,cleanup)
 if not state.backdrop then return end
 if not cleanup then state.backdrop:removeFromParent(true)end
 state.backdrop:release();state.backdrop=nil
end
local function forget(state)
 state.view=nil;state.overlay=nil;state.overlayRoot=nil;state.turn=nil
 state.squash=nil;state.observer=nil;state.originalAddChild=nil
 state.mapOrder=nil;state.ownerOrder=nil;state.turnOrder=nil
 state.originalCamera=nil;state.mountedCamera=nil
 state.map:release();state.moveLayer:release();state.map=nil;state.moveLayer=nil
end
function L.enabled(owner)
 if not owner or tonumber(owner.mapIndex)~=2 then return false end
 -- The legacy boolean remains a process-local comparison override. Neither
 -- choice is persisted or inferred from a profile, tutorial or voyage marker.
 local override=rawget(_G,L.flag)
 if override~=nil then return override==true end
 local mode=os and os.getenv and os.getenv('PIRATE_MAP2_PRESENTATION')
 return mode==nil or mode=='' or mode=='clean'
end
-- Validate lifecycle and deferred-call entry points as well as constructors.
-- Merely requiring a table does not establish an installed package's API.
local function api(module,name,methods)
 if type(module)~='table' then return false,'unsupported-api:'..name end
 for _,method in ipairs(methods)do
  if type(module[method])~='function' then return false,'unsupported-api:'..name..'.'..method end
 end
 return true
end
local dependencies={
 {'CleanVoyageHUD',{'canAct'}},
 {'AdventureNavigation',{'query','snapshot','port'}},{'KnownRoute',{'key','inBounds','direction','foodCost','find'}},
 {'AdventureNavigationView',{'lines'}},
 {'AdventureDialog',{'show'}},
 {'AdventureProgress',{'getState','showHarborBrief','getHarborStatus'}},
 {'AdventureSea',{'isHudPoint'}},
 {'WarmTheme',{'panel','label','button','fit','enabled','icon','sprite'}},
 {'WarmPause',{'open','canOpen','checkpoint'}},
 {'WarmCollection',{'open'}},{'WarmDialog',{'show'}},{'WarmMemories',{'get','setDisplay','definitions'}},{'WarmActivities',{'open','textPages'}},
 {'CleanSeaPresentation',{'gate'}},
 {'RaisedSeaObjectPresentation',{'resolve'}},
 {'SeaChartWorldTheme',{'landLayers','familyForLayer','placeMaskTile'}},
}
local function prepare(owner)
 if not owner.moveLayer or not owner.map or not owner.player or not owner.fogLayer or not owner.tipLayer then return nil,'not-ready' end
 local map=owner.map
 -- New restoration entry points must be usable before any node is moved.
 for _,target in ipairs({owner,owner.moveLayer,map})do
  for _,method in ipairs({'getChildren','reorderChild','sortAllChildren','convertToNodeSpace','convertToWorldSpace'})do
   if type(target[method])~='function'then return nil,'unsupported-restoration-api:'..method end
  end
  for _,child in ipairs(target:getChildren())do
   for _,method in ipairs({'getLocalZOrder','getOrderOfArrival','setOrderOfArrival'})do
    if type(child[method])~='function'then return nil,'unsupported-restoration-api:'..method end
   end
   local z,arrival=child:getLocalZOrder(),child:getOrderOfArrival()
   if type(z)~='number'or z~=z or math.abs(z)==math.huge or type(arrival)~='number'or arrival~=arrival or arrival<0 or arrival==math.huge then
    return nil,'unsupported-restoration-order'
   end
  end
 end
 for _,method in ipairs({'stopChartCameraMotion','clampChartPosition','getCenterViewPositionByActualPosition'})do
  if type(owner[method])~='function'then return nil,'unsupported-restoration-api:'..method end
 end
 local camera=cameraSnapshot(owner)
 for _,key in ipairs({'x','y','sx','sy','width','height','px','py'})do
  local value=camera[key]
  if type(value)~='number'or value~=value or math.abs(value)==math.huge then return nil,'unsupported-restoration-camera' end
 end
 for _,key in ipairs({'bottom','top'})do
  local value=camera[key]
  if value~=nil and(type(value)~='number'or value~=value or math.abs(value)==math.huge)then return nil,'unsupported-restoration-camera'end
 end
 if camera.sx==0 or camera.sy==0 then return nil,'unsupported-restoration-camera'end
 if tolua.type(map)~='cc.TMXTiledMap' or map:getParent()~=owner.moveLayer or owner.player:getParent()~=map then return nil,'unsupported-owner' end
 local size,tile=map:getMapSize(),map:getTileSize()
 if size.width~=31 or size.height~=31 or tile.width~=64 or tile.height~=64 then return nil,'unsupported-grid' end
 local layers={}
 for _,name in ipairs({'Sea','Blocks_1','Blocks_2','Meta','GridLayer','Fogs'})do
  local layer=map:getLayer(name)
  if not layer or tolua.type(layer)~='cc.TMXLayer' or layer:getParent()~=map or layer:getLayerName()~=name then return nil,'unsupported-layer:'..name end
  local bounds=layer:getLayerSize()
  if bounds.width~=31 or bounds.height~=31 or layer:getPositionX()~=0 or layer:getPositionY()~=0 then return nil,'unsupported-layer-bounds:'..name end
  layers[name]=layer
 end
 if owner.meta~=layers.Meta or owner.fogLayer~=layers.Fogs then return nil,'unsupported-layer-owner' end
 for _,name in ipairs({'Meta','GridLayer','Fogs'})do
  if layers[name]:getLocalZOrder()<=math.max(layers.Blocks_1:getLocalZOrder(),layers.Blocks_2:getLocalZOrder())then return nil,'unsupported-layer-order' end
 end
 if not owner.fogManager or type(owner.fogManager.data)~='table'
  or not owner.mapLayoutManagers or type(owner.mapLayoutManagers.data)~='table'
  or not owner.eventManger or type(owner.eventManger.csvData)~='table'
  or not owner.bagController or type(owner.bagController.getBreads)~='function' then return nil,'unsupported-model' end
 local size=screenSize or cc.Director:getInstance():getVisibleSize()
 if not size or not tonumber(size.width)or not tonumber(size.height)or size.width<=0 or size.height<=0 then return nil,'unsupported-viewport' end
 -- All fallible dependency, source-model and asset preparation occurs before
 -- touching any live node. A bad optional package keeps the original route.
 R=R or require('LuaClass/RaisedSeaMap2')
 Objects=Objects or require('LuaClass/RaisedSeaMap2ObjectsLive')
 HUD=HUD or require('LuaClass/RaisedSeaMap2HUD');Boat=Boat or require('LuaClass/RaisedSeaMap2Boat')
 for _,entry in ipairs({
  {R,'RaisedSeaMap2',{'build','project','inverse','depth','tilePoint','transform','alphaAt','eventAt'}},
  {Objects,'RaisedSeaMap2ObjectsLive',{'create','sync','rebuild','dispose'}},
  {Boat,'RaisedSeaMap2Boat',{'create','sync','dispose','heading'}},
  {HUD,'RaisedSeaMap2HUD',{'create','sync','dispose','canAct','invalidate','arrowPoints','contains','details'}},
 })do
  local valid,reason=api(entry[1],entry[2],entry[3]);if not valid then return nil,reason end
 end
 for _,entry in ipairs(dependencies)do
  local valid,reason=api(require('LuaClass/'..entry[1]),entry[1],entry[2]);if not valid then return nil,reason end
 end
 local warm=require('LuaClass/WarmTheme')
 for _,value in ipairs({HUD.font or false,Boat.path or false,warm.font or false})do
  if type(value)~='string' or value=='' then return nil,'unsupported-package-metadata' end
 end
 local function finite(value)return type(value)=='number' and value==value and value>-math.huge and value<math.huge end
 for _,value in ipairs({R.halfX or false,R.halfY or false,R.rise or false})do
  if not finite(value)or value<=0 then return nil,'unsupported-package-metadata' end
 end
 if type(warm.colors)~='table' then return nil,'unsupported-package-metadata' end
 for _,name in ipairs({'ink','navy','paper','coral','sea','muted','line','white','gold'})do
  local color=warm.colors[name]
  if type(color)~='table' and type(color)~='userdata' then return nil,'unsupported-package-metadata' end
  for _,channel in ipairs({'r','g','b'})do
   if not finite(color[channel])or color[channel]<0 or color[channel]>255 then return nil,'unsupported-package-metadata' end
  end
 end
 if type(owner.bagController:getBreads())~='number' then return nil,'unsupported-food' end
 require('LuaClass/CleanVoyageHUD').canAct(owner)
 require('LuaClass/AdventureNavigation').query(owner,{breadCoefficient=owner.adventureBreadCoefficient or 0})
 require('LuaClass/AdventureProgress').getState(DataManager:getInstance())
 local coast=map._seaChartWorldCoast
 if coast then
  if type(coast)~='table' or type(coast.groups)~='table' then return nil,'unsupported-coast' end
  for _,entry in ipairs(coast.groups)do
   if type(entry)~='table' or (entry.group and not entry.group.getParent)or(entry.edge and not entry.edge.getBoundingBox)then return nil,'unsupported-coast' end
  end
 end
 local manifest=require('LuaClass/CleanSeaPresentation').gate()
 local paths={manifest.water,manifest.decor,manifest.landmarks,manifest.ship,HUD.font,warm.font}
 for _,path in pairs(manifest.atlases)do paths[#paths+1]=path end
 for _,path in pairs(manifest.surfaces)do paths[#paths+1]=path end
 for _,direction in ipairs({'ne','nw','sw','se'})do paths[#paths+1]=Boat.path..'boat-clean-'..direction..'.png' end
 for _,path in ipairs(paths)do
  if not cc.FileUtils:getInstance():isFileExist(path)then return nil,'missing-art:'..path end
  if path:sub(-4)=='.png' then
   local texture=cc.Director:getInstance():getTextureCache():addImage(path)
   if not texture or texture:getPixelsWide()<=0 or texture:getPixelsHigh()<=0 then return nil,'invalid-art:'..path end
  end
 end
 return R.build(owner,{liveOverlay=true})
end
local function fallback(owner,reason)
 owner.raisedMap2Status='fallback:'..tostring(reason)
 return false,reason
end
local function arrows(owner,enabled)
 for _,entry in ipairs(owner.raisedMap2Arrows or {})do
  local angle=entry.angle
  if enabled then
   if angle==0 then angle=60.7512 elseif angle==180 then angle=-119.2488
   elseif angle==90 then angle=119.2488 elseif angle==-90 then angle=-60.7512 end
  end
  entry.node:setRotation(angle)
 end
end
function L.projectPoint(owner,p)
 if not owner.raisedMap2Live then return p end
 return R.project(p.x,p.y)
end
function L.inputPoints(owner,world,playerWorld)
 if not owner.raisedMap2Live then return world,playerWorld end
 return owner.map:convertToNodeSpace(world),owner.map:convertToNodeSpace(playerWorld)
end
function L.inputAngle(owner,world,playerWorld)
 if not owner.raisedMap2Live then return nil end
 local a,b=L.inputPoints(owner,world,playerWorld)
 local dx,dy=a.x-b.x,a.y-b.y
 if math.abs(dx)<.001 then dx=0 end;if math.abs(dy)<.001 then dy=0 end
 if dx==0 and dy==0 then return nil end
 return (math.deg(math.atan2(dy,dx))+360)%360
end
function L.clamp(owner,position)
 local state=owner.raisedMap2Live;if not state then return nil end
 local size=owner.map:getContentSize();local scale=owner.moveLayer:getScale()
 local origin=owner:convertToNodeSpace(owner.moveLayer:convertToWorldSpace(cc.p(0,0)))
 local offsetX,offsetY=origin.x-owner.moveLayer:getPositionX(),origin.y-owner.moveLayer:getPositionY()
 local bottom,top=owner.adventureHudBottom or 0,owner.adventureHudTop or screenSize.height
 local minX,maxX=0,R.halfX*(size.width+size.height)
 local minY,maxY=-R.halfY*size.width,R.halfY*size.height
 local function axis(value,lo,hi,mn,mx)
  if (mx-mn)*scale<=hi-lo then return (lo+hi-(mn+mx)*scale)/2 end
  return math.max(hi-mx*scale,math.min(lo-mn*scale,value))
 end
 return cc.p(axis(position.x+offsetX,0,screenSize.width,minX,maxX)-offsetX,
  axis(position.y+offsetY,bottom,top,minY,maxY)-offsetY)
end
function L.dirty(owner)
 local state=owner.raisedMap2Live;if state then state.dirty=true end
end
function L.refresh(owner)
 local state=owner.raisedMap2Live;if not state then return false end
 if not L.enabled(owner)or owner.map~=state.map or owner.moveLayer~=state.moveLayer then L.unmount(owner);return false end
 stabilizeOrder(state.mapOrder);stabilizeOrder(state.ownerOrder);stabilizeOrder(state.turnOrder)
 HUD.sync(state.hud);Boat.sync(state.boat)
 if not state.dirty then Objects.sync(state.objects);return true end
 -- Rebuild only after an authoritative discovery/event notification, never by
 -- scanning the map every frame. Source-alpha geometry is immutable and reused.
 local view,reason=R.build(owner,{liveOverlay=true,model=state.view.model})
 if not view then L.unmount(owner);owner.raisedMap2Status='fallback:'..tostring(reason);return false end
 state.overlay:addChild(view.root)
 Objects.rebuild(state.objects,view)
 state.view.root:removeFromParent(true);state.view=view;state.dirty=false
 state.rebuilds=state.rebuilds+1
 return true
end
function L.mount(owner)
 if owner.raisedMap2Live then return true end
 if not L.enabled(owner)then return false,'disabled' end
 -- Preserve unknown semantics rather than inventing replacement visibility.
 -- The exact original Fogs TMX layer and every materialized fade sprite remain
 -- in the original map. Partial cells retain their native ground presentation;
 -- elevated geometry exists only inside the hard-known ground-plane stencil.
 -- This exception boundary is read-only preparation, never a catch around
 -- installation, cleanup or lifetime code. Nothing can be half-mounted here.
 local ok,view,reason=pcall(prepare,owner)
 if not ok then owner.raisedMap2Diagnostic=tostring(view);return fallback(owner,'incompatible-package')end
 if not view then return fallback(owner,reason)end
 local peer=tolua.getpeer(owner.moveLayer)
 local state={view=view,map=owner.map,moveLayer=owner.moveLayer,dirty=false,rebuilds=0,originalAddChild=owner.moveLayer.addChild,
  savedAddChild=peer and rawget(peer,'addChild'),originalCamera=cameraSnapshot(owner)}
 state.map:retain();state.moveLayer:retain()
 state.observer=node();state.ownerOrder=orderLedger(owner,state.observer,true,true)
 local squash,turn=node(),node();squash:setScaleY(.56);turn:setRotation(45);squash:addChild(turn)
 state.squash,state.turn=squash,turn
 local _,children=orderLedger(owner.moveLayer,squash,true,true)
 state.originalAddChild(owner.moveLayer,squash)
 for _,child in ipairs(children)do move(child,turn,child:getLocalZOrder())end
 local marker=node();state.turnOrder=orderLedger(turn,marker,true);turn:addChild(marker)
 stabilizeOrder(state.turnOrder)
 -- Existing game code can continue adding route, glow and particle nodes to
 -- moveLayer with the same source positions. Only their presentation parent is
 -- redirected. No actor coordinate, callback, scheduler or action is replaced.
 local originalAddChild=state.originalAddChild
 state.addChild=function(target,child,...)
  if owner.raisedMap2Live==state then return state.turn:addChild(child,...)end
  return originalAddChild(target,child,...)
 end
 owner.moveLayer.addChild=state.addChild
 local unturn,unsquash=node(),node();unturn:setRotation(-45);unsquash:setScaleY(1/.56);unturn:addChild(unsquash)
 -- Raised ground is above both original land layers, below Meta/grid/fog/ship.
 state.mapOrder=orderLedger(owner.map,unturn,true,true)
 owner.map:addChild(unturn,owner.map:getLayer('Blocks_2'):getLocalZOrder());stabilizeOrder(state.mapOrder)
 unsquash:addChild(view.root);state.overlay=unsquash;state.overlayRoot=unturn
 owner.raisedMap2Live=state;owner.raisedMap2Status='clean-map2-native-fog'
 clipCoasts(owner,state);coverBackground(owner,state)
 state.objects=Objects.create(owner,view)
 state.boat=Boat.create(owner);state.hud=HUD.create(owner,state)
 arrows(owner,true)
 local observer=state.observer;owner:addChild(observer);stabilizeOrder(state.ownerOrder)
 observer:registerScriptHandler(function(event)
  if event=='cleanup' then
   restoreCoasts(owner,state,true);restoreBackground(state,true)
   HUD.dispose(state.hud,true);state.hud=nil;Boat.dispose(state.boat);state.boat=nil
   Objects.dispose(state.objects);state.objects=nil
   -- Parent cleanup is not a route toggle: never reparent dying children.
   if owner.raisedMap2Live==state then
    if state.moveLayer.addChild==state.addChild then state.moveLayer.addChild=state.savedAddChild end
    owner.raisedMap2Live=nil
    forget(state)
   end
  end
 end)
 observer:scheduleUpdateWithPriorityLua(function()L.refresh(owner)end,0)
 -- Camera changes only presentation; the player position and save stay exact.
 recenter(owner);state.mountedCamera=cameraSnapshot(owner)
 return true
end
function L.unmount(owner)
 local state=owner and owner.raisedMap2Live;if not state then return end
 stabilizeOrder(state.mapOrder);stabilizeOrder(state.ownerOrder);stabilizeOrder(state.turnOrder)
 local size=screenSize or cc.Director:getInstance():getVisibleSize()
 local point=cc.p(size.width/2,((owner.adventureHudBottom or 0)+(owner.adventureHudTop or size.height))/2)
 local focus={point=point,source=state.map:convertToNodeSpace(owner:convertToWorldSpace(point))}
 owner.raisedMap2Live=nil
 restoreCoasts(owner,state,false);restoreBackground(state,false)
 HUD.dispose(state.hud);state.hud=nil;Boat.dispose(state.boat);state.boat=nil
 Objects.dispose(state.objects);state.objects=nil
 state.observer:unscheduleUpdate()
 stabilizeOrder(state.ownerOrder);state.observer:removeFromParent(true)
 -- New decorators may still call our wrapper. Leave them installed; the
 -- retired wrapper delegates to the original method without retaining nodes.
 if state.moveLayer.addChild==state.addChild then state.moveLayer.addChild=state.savedAddChild end
 state.overlayRoot:removeFromParent(true)
 state.turnOrder.marker:removeFromParent(true)
 local children=state.turn:getChildren()
 local returned=orderLedger(state.moveLayer,state.squash,true)
 for child,rank in pairs(returned.ranks)do returned.ranks[child]=#children+rank end
 for index,child in ipairs(children)do returned.ranks[child]=index;returned.arrivals[child]=child:getOrderOfArrival() end
 for _,child in ipairs(children)do move(child,state.moveLayer,child:getLocalZOrder())end
 stabilizeOrder(returned);state.squash:removeFromParent(true)
 arrows(owner,false);owner.raisedMap2Status='original'
 returnCamera(owner,state,focus);forget(state)
end
return L
