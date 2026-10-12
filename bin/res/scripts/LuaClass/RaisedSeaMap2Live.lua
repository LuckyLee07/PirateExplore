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
 child:retain();child:removeFromParent(false);parent:addChild(child,z);child:release()
end
-- Cocos resets arrival order on visit and later uses an unstable equal-Z sort.
-- Adding/removing the presentation root must not reshuffle native coast/land
-- siblings. Temporarily rank the existing order, sort once, then restore every
-- original arrival value. No source child is removed, retagged or re-Z-ordered.
local function stableMapOrder(map,changing,operation)
 map:sortAllChildren()
 local saved={}
 for index,child in ipairs(map:getChildren())do
  if child~=changing then
   saved[#saved+1]={node=child,order=child:getOrderOfArrival()};child:setOrderOfArrival(index)
  end
 end
 operation();map:sortAllChildren()
 for _,entry in ipairs(saved)do entry.node:setOrderOfArrival(entry.order)end
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
   entry.edge:removeFromParent(false);entry.group:addChild(entry.edge,entry.z);entry.edge:setOrderOfArrival(entry.order)
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
 if not L.enabled(owner)then L.unmount(owner);return false end
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
 local state={view=view,dirty=false,rebuilds=0,originalAddChild=owner.moveLayer.addChild}
 local squash,turn=node(),node();squash:setScaleY(.56);turn:setRotation(45);squash:addChild(turn)
 state.squash,state.turn=squash,turn
 local children=owner.moveLayer:getChildren()
 state.originalAddChild(owner.moveLayer,squash)
 for _,child in ipairs(children)do move(child,turn,child:getLocalZOrder())end
 -- Existing game code can continue adding route, glow and particle nodes to
 -- moveLayer with the same source positions. Only their presentation parent is
 -- redirected. No actor coordinate, callback, scheduler or action is replaced.
 owner.moveLayer.addChild=function(_,child,...)
  return turn:addChild(child,...)
 end
 local unturn,unsquash=node(),node();unturn:setRotation(-45);unsquash:setScaleY(1/.56);unturn:addChild(unsquash)
 -- Raised ground is above both original land layers, below Meta/grid/fog/ship.
 stableMapOrder(owner.map,unturn,function()owner.map:addChild(unturn,owner.map:getLayer('Blocks_2'):getLocalZOrder())end)
 unsquash:addChild(view.root);state.overlay=unsquash;state.overlayRoot=unturn
 owner.raisedMap2Live=state;owner.raisedMap2Status='clean-map2-native-fog'
 clipCoasts(owner,state);coverBackground(owner,state)
 state.objects=Objects.create(owner,view)
 state.boat=Boat.create(owner);state.hud=HUD.create(owner,state)
 arrows(owner,true)
 local observer=node();owner:addChild(observer);state.observer=observer
 observer:registerScriptHandler(function(event)
  if event=='cleanup' then
   restoreCoasts(owner,state,true);restoreBackground(state,true)
   HUD.dispose(state.hud,true);state.hud=nil;Boat.dispose(state.boat);state.boat=nil
   Objects.dispose(state.objects);state.objects=nil
   -- Parent cleanup is not a route toggle: never reparent dying children.
   if owner.raisedMap2Live==state then
    owner.moveLayer.addChild=state.originalAddChild;owner.raisedMap2Live=nil
    forget(state)
   end
  end
 end)
 observer:scheduleUpdateWithPriorityLua(function()L.refresh(owner)end,0)
 -- Camera changes only presentation; the player position and save stay exact.
 recenter(owner)
 return true
end
function L.unmount(owner)
 local state=owner and owner.raisedMap2Live;if not state then return end
 owner.raisedMap2Live=nil
 restoreCoasts(owner,state,false);restoreBackground(state,false)
 HUD.dispose(state.hud);state.hud=nil;Boat.dispose(state.boat);state.boat=nil
 Objects.dispose(state.objects);state.objects=nil
 state.observer:unscheduleUpdate();state.observer:removeFromParent(true)
 owner.moveLayer.addChild=state.originalAddChild
 stableMapOrder(owner.map,state.overlayRoot,function()state.overlayRoot:removeFromParent(true)end)
 local children=state.turn:getChildren()
 for _,child in ipairs(children)do move(child,owner.moveLayer,child:getLocalZOrder())end
 state.squash:removeFromParent(true)
 arrows(owner,false);owner.raisedMap2Status='original'
 recenter(owner);forget(state)
end
return L
