-- Presentation leases for the opt-in live map2 adapter. Never changes a tile,
-- layout record, source coordinate, action, callback, collision or save value.
local M={}
local R=require('LuaClass/RaisedSeaMap2')
local O=require('LuaClass/RaisedSeaObjectPresentation')
local function field(target,name)
 local peer=tolua.getpeer(target);return peer and rawget(peer,name) or nil
end
local function hook(target,name,make)
 local inherited,saved=target[name],field(target,name)
 local replacement=make(inherited);target[name]=replacement
 return function()if target[name]==replacement then target[name]=saved end end
end
local function known(a,x,y)
 local key=tostring(x+y*a.view.model.width)
 return a.view.known[key] and a.owner.fogManager and tonumber(a.owner.fogManager.data[key])==0
end
local function release(a,key)
 local lease=a.leases[key];if not lease then return end
 a.leases[key]=nil
 -- Restore the latest requested visibility, not a stale mount-time default.
 -- Opacity/color/transform/actions were never changed by this adapter.
 for _,restore in ipairs(lease.restore)do restore()end
 lease.nativeSetVisible(lease.source,lease.visible)
 lease.group:removeFromParent(true);lease.group:release();lease.source:release()
 lease.source=nil;lease.group=nil
end
local function releaseAll(a)
 local keys={};for key in pairs(a.leases)do keys[#keys+1]=key end
 for _,key in ipairs(keys)do release(a,key)end
end
local function invalidate(a)
 if a.disposed then return end
 a.invalid=true
 for _,lease in pairs(a.leases)do lease.group:setVisible(false)end
 if a.owner.raisedMap2Live then a.owner.raisedMap2Live.dirty=true end
end
local function drawContact(parent,appearance,onLand)
 local d=cc.DrawNode:create();local points={}
 -- Match the reviewed native-context handling of the raised terrain DrawNodes.
 local dispatcher=d:getEventDispatcher()
 d:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(d)end end)
 for i=0,23 do local angle=i*math.pi/12
  points[#points+1]=cc.p(math.cos(angle)*appearance.contactX,appearance.contactCenterY+math.sin(angle)*appearance.contactY)
 end
 local color=onLand and cc.c4f(114/255,116/255,57/255,.20)or cc.c4f(17/255,120/255,124/255,.14)
 for i=2,#points-1 do d:drawTriangle(points[1],points[i],points[i+1],color)end
 parent:addChild(d,-1)
end
local function show(a,lease)
 lease.group:setVisible(not a.invalid and lease.visible and a.meta:isVisible() and known(a,lease.x,lease.y) or false)
end
local function acquire(a,event,appearance,source,key)
 -- Native actions run on their original sprite. Animated sites conservatively
 -- retain source artwork; the runAction hook restores it before an action starts.
 if source:getNumberOfRunningActions()>0 then return end
 local sprite=cc.Sprite:create(appearance.path);if not sprite then return end
 local group=cc.Node:create();group:setCascadeOpacityEnabled(true);group:setCascadeColorEnabled(true)
 sprite:getTexture():setAntiAliasTexParameters();sprite:setScale(appearance.scale)
 sprite:setAnchorPoint(cc.p(appearance.anchorX,appearance.anchorY));group:addChild(sprite)
 local onLand=R.alphaAt(a.view.model,(event.x+.5)*64,(a.view.model.height-event.y-.5)*64)
 local support=onLand and a.view.rise or 0
 group:setPosition(R.tilePoint(a.owner.map,event.x,event.y,support));drawContact(group,appearance,onLand)
 a.view.clip:addChild(group,R.depth(a.view.model,event.x,event.y,12))
 source:retain();group:retain()
 local lease={source=source,group=group,sprite=sprite,x=event.x,y=event.y,event=event,appearance=appearance,support=support,
  visible=source:isVisible(),nativeSetVisible=source.setVisible,restore={}}
 a.leases[key]=lease
 lease.restore[#lease.restore+1]=hook(source,'setVisible',function(native)return function(_,visible)
  lease.visible=visible;native(source,false);show(a,lease)
 end end)
 lease.restore[#lease.restore+1]=hook(source,'isVisible',function()return function()return lease.visible end end)
 lease.restore[#lease.restore+1]=hook(source,'runAction',function(native)return function(_,action)
  release(a,key);return native(source,action)
 end end)
 lease.nativeSetVisible(source,false);show(a,lease)
 return lease
end
function M.sync(a)
 if not a or a.disposed or a.invalid then return end
 for _,cell in ipairs(a.cells)do
  local key=cell.x+cell.y*a.view.model.width
  local event=R.eventAt(a.owner,cell.x,cell.y)
  local appearance=event and O.resolve(event)
  local source=a.meta:getChildByTag(key)
  local lease=a.leases[key]
  -- This legacy TMX getTileAt materializes an unflipped sprite even when the
  -- batch quad carries flags. Leave an unmaterialized flagged tile entirely
  -- native instead of changing its visual meaning as a side effect of reading.
  if not source and a.meta:getTileFlagsAt(cc.p(cell.x,cell.y))~=0 then appearance=nil end
  if appearance and not cc.FileUtils:getInstance():isFileExist(appearance.path)then appearance=nil end
  if not known(a,cell.x,cell.y)then appearance=nil end
  if lease and (not appearance or source~=lease.source or source:getParent()~=a.meta or source:getNumberOfRunningActions()>0
   or tostring(event.id)~=tostring(lease.event.id)or event.gid~=lease.event.gid or event.state~=lease.event.state
   or event.layoutGid~=lease.event.layoutGid or appearance.path~=lease.appearance.path)then release(a,key);lease=nil end
  if appearance and not lease then
   source=a.meta:getTileAt(cc.p(cell.x,cell.y))
   if source then lease=acquire(a,event,appearance,source,key)end
  end
  if lease then
   lease.group:setOpacity(source:getDisplayedOpacity());lease.group:setColor(source:getDisplayedColor());show(a,lease)
  end
 end
end
function M.rebuild(a,view)
 releaseAll(a);a.view=view;a.cells={};a.invalid=false
 -- Only event-bearing native cells are polled thereafter. Tile mutation hooks
 -- invalidate this list even for empty-to-object and same-cell replacement.
 for y=0,view.model.height-1 do for x=0,view.model.width-1 do
  if a.meta:getTileGIDAt(cc.p(x,y))~=0 then a.cells[#a.cells+1]={x=x,y=y}end
 end end
 M.sync(a)
end
function M.create(owner,view)
 local a={owner=owner,meta=owner.meta or owner.map:getLayer('Meta'),leases={},restore={}}
 a.meta:retain();owner.fogLayer:retain();a.fog=owner.fogLayer
 for _,name in ipairs({'setTileGID','removeTileAt'})do
  a.restore[#a.restore+1]=hook(a.meta,name,function(native)return function(target,...)
   local args={...};local p=name=='setTileGID' and args[2]or args[1]
   if p then release(a,p.x+p.y*a.view.model.width)end
   local result=native(target,unpack(args));invalidate(a);return result
  end end)
 end
 a.restore[#a.restore+1]=hook(a.meta,'setVisible',function(native)return function(target,visible)
  native(target,visible);for _,lease in pairs(a.leases)do show(a,lease)end
 end end)
 a.restore[#a.restore+1]=hook(a.fog,'setTileGID',function(native)return function(target,...)
  local result=native(target,...);invalidate(a);return result
 end end)
 M.rebuild(a,view);return a
end
function M.dispose(a)
 if not a or a.disposed then return end
 a.disposed=true;releaseAll(a)
 for _,restore in ipairs(a.restore)do restore()end
 a.meta:release();a.fog:release()
 a.owner=nil;a.meta=nil;a.fog=nil;a.view=nil;a.cells=nil;a.restore=nil
end
return M
