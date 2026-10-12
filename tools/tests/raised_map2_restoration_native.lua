local function main()
-- Additive restoration gate. Actual Cocos map2/controller nodes and actions;
-- only the established fixture's in-memory persistence and event dispatch.
local file=assert(io.open('tools/tests/raised_map2_hud_boat_native.lua'));local source=file:read('*a');file:close()
local stop=assert(source:find("if os.getenv('MAP2_GUARD_TEST')then",1,true))
local T=assert(loadstring(source:sub(1,stop-1)..[[
return {seed=seed,capture=capture,ticks=ticks,geometry=geometry,
 snapshot=function()return stable(data),writes end,stable=stable,json=json}
]],'@map2-restoration-fixture'))()
local L=require 'LuaClass/RaisedSeaMap2Live';local R=require 'LuaClass/RaisedSeaMap2'
local out=assert(os.getenv('RAISED_MAP2_LIVE_CAPTURE_DIR'))
local function write(name,value)local f=assert(io.open(out..'/'..name..'.json','w'));f:write(T.json.encode(value));f:close()end
local function snapshot(root)
 local nodes,identity={},{}
 local function walk(node,path)
  nodes[#nodes+1]={node=node,path=path};identity[node]=path
  for i,child in ipairs(node:getChildren())do walk(child,path..'/'..i..':'..tolua.type(child))end
 end
 walk(root,'owner')
 local function read()
  local result={}
  for _,entry in ipairs(nodes)do
   local n=entry.node;local props={parent=identity[n:getParent()] or tostring(n:getParent()),children={}}
   for _,child in ipairs(n:getChildren())do if identity[child]then props.children[#props.children+1]=identity[child]end end
   for _,key in ipairs({'getPositionX','getPositionY','getScaleX','getScaleY','getRotation','getRotationSkewX','getRotationSkewY','getSkewX','getSkewY','getLocalZOrder','getOrderOfArrival','getOpacity','getDisplayedOpacity','isVisible','isRunning','getNumberOfRunningActions','isCascadeColorEnabled','isCascadeOpacityEnabled','getAnchorPoint','getContentSize','getColor','getDisplayedColor'})do
    if type(n[key])=='function'then props[key]=n[key](n)end
   end
   result[entry.path]=props
  end
  return result
 end
 return read,#nodes
end
local function difference(before,after)
 local diff={}
 for path,props in pairs(before)do for key,value in pairs(props)do
  if T.stable(value)~=T.stable(after[path][key])then diff[#diff+1]={node=path,property=key,before=value,after=after[path][key]}end
 end end
 return diff
end
local function productionTopology(owner)
 -- Use the original EventManger class and eventOrderLevel=10 ownership shape.
 -- Keep this fixture's deterministic event queue rather than instantiate a
 -- full unrelated EventLayer/business UI stack or a real save manager.
 local events=owner.eventManger;events.layer:retain();events.layer:removeFromParent(false)
 local manager=EventManger.new();owner:addChild(manager,eventOrderLevel);manager:addChild(events.layer);events.layer:release()
 for key,value in pairs(events)do manager[key]=value end;owner.eventManger=manager
 assert(manager:getLocalZOrder()==10 and manager.layer:getParent()==manager)
end
local function seed()
 RAISED_MAP2_LIVE=false;local owner=T.seed();productionTopology(owner)
 owner:setZoomScale(.3);owner:setViewpointCenter(cc.p(owner.player:getPosition()))
 return owner
end
local function finish(owner)owner:removeFromParent(true);owner:release();cleanWorldDrain()end
local owner=seed();T.capture(owner,'original-reference')
local read,count=snapshot(owner);local before=read();local bytes,writes=T.snapshot()
local guardCases=0
local function guarded(target,key,value)
 local peer=tolua.getpeer(target);local saved=peer and rawget(peer,key)
 target[key]=value;RAISED_MAP2_LIVE=true;local ok,mounted,reason=pcall(L.mount,owner);target[key]=saved
 assert(ok and not mounted and not owner.raisedMap2Live and reason,'restoration API must fail before mutation '..key)
 assert(#difference(before,read())==0,'restoration preflight mutated source '..key)
 local now,n=T.snapshot();assert(now==bytes and n==writes);guardCases=guardCases+1
end
for _,target in ipairs({owner,owner.moveLayer,owner.map})do
 for _,method in ipairs({'getChildren','reorderChild','sortAllChildren','convertToNodeSpace','convertToWorldSpace'})do guarded(target,method,false)end
end
for _,method in ipairs({'stopChartCameraMotion','clampChartPosition','getCenterViewPositionByActualPosition'})do guarded(owner,method,false)end
for _,value in ipairs({'bad',-1,math.huge})do guarded(owner.map,'getOrderOfArrival',function()return value end)end
for _,value in ipairs({'bad',math.huge,0/0})do guarded(owner.map,'getLocalZOrder',function()return value end)end
for _,method in ipairs({'getPositionX','getScaleX','getScaleY'})do guarded(owner.moveLayer,method,function()return 'bad'end)end
write('restoration-preflight',{cases=guardCases,sourcePropertiesExact=true,presentationWrites=0})

local actorAction=cc.DelayTime:create(60);actorAction:setTag(314159);owner.player:runAction(actorAction)
local cameraAction=cc.DelayTime:create(60);cameraAction:setTag(314160);owner.moveLayer:runAction(cameraAction)
before=read()
for round=0,3 do
 RAISED_MAP2_LIVE=true;assert(L.mount(owner));local state=owner.raisedMap2Live
 for visit=1,round do T.capture(owner,'live-'..round..'-'..visit)end
 if round==1 then
  RAISED_MAP2_LIVE=false;assert(not L.refresh(owner))
 elseif round==2 then
  local build=R.build;R.build=function()return nil,'restoration-fixture-failure'end
  L.dirty(owner);assert(not L.refresh(owner));R.build=build
  assert(owner.raisedMap2Status=='fallback:restoration-fixture-failure')
 else L.unmount(owner)end
 local diff=difference(before,read());write('stationary-differences-'..round,diff)
 assert(#diff==0,'stationary original property restoration round '..round)
 assert(owner.player:getActionByTag(314159)==actorAction and owner.moveLayer:getActionByTag(314160)==cameraAction,'unrelated action identity')
 local now,n=T.snapshot();assert(now==bytes and n==writes,'presentation save writes')
 T.capture(owner,'original-restored-'..round)
end
write('stationary-summary',{nodes=count,cycles=4,propertiesExact=true,unrelatedActionsExact=true,presentationWrites=0})
owner.player:stopAction(actorAction);owner.moveLayer:stopAction(cameraAction)
-- Unchanged frames must not dirty/sort native parents. Actual additions and
-- explicit current-order requests must still invalidate the fast path.
RAISED_MAP2_LIVE=true;assert(L.mount(owner));L.refresh(owner);L.refresh(owner)
local state=owner.raisedMap2Live;local reorderCalls=0;local restores={}
for _,parent in ipairs({owner,owner.map,state.turn})do
 local target=parent;local native=target.reorderChild;local peer=tolua.getpeer(target);local saved=peer and rawget(peer,'reorderChild')
 target.reorderChild=function(self,child,z)reorderCalls=reorderCalls+1;return native(self,child,z)end
 restores[#restores+1]=function()target.reorderChild=saved end
end
for i=1,100 do assert(L.refresh(owner))end
assert(reorderCalls==0,'idle refresh dirtied native sibling sets')
local added=cc.Node:create();owner.moveLayer:addChild(added,0);local arrival=added:getOrderOfArrival();assert(L.refresh(owner))
assert(reorderCalls>0 and added:getOrderOfArrival()==arrival,'new child invalidation/arrival')
local previous=reorderCalls;owner.map:reorderChild(owner.player,owner.player:getLocalZOrder());arrival=owner.player:getOrderOfArrival();assert(L.refresh(owner))
assert(reorderCalls>=previous+2 and owner.player:getOrderOfArrival()==arrival,'explicit reorder invalidation/arrival')
for _,restore in ipairs(restores)do restore()end
added:removeFromParent(true);L.unmount(owner)
write('idle-order-fast-path',{unchangedRefreshes=100,nativeReorders=0,addInvalidates=true,explicitReorderInvalidates=true})
-- Existing current requested node state, new source child and a newer decorator
-- must survive removal. A changed arrival is a new order request, not old ties.
RAISED_MAP2_LIVE=true;assert(L.mount(owner));local state=owner.raisedMap2Live
local extra=cc.Node:create();owner.moveLayer:addChild(extra,7);extra:setPosition(cc.p(57,83));extra:setScale(.7);extra:setRotation(13);extra:setOpacity(117);extra:setVisible(false)
local extraAction=cc.DelayTime:create(60);extraAction:setTag(314161);extra:runAction(extraAction)
local inherited=owner.moveLayer.addChild;local calls=0
local decorated=function(target,child,...)calls=calls+1;return inherited(target,child,...)end
owner.moveLayer.addChild=decorated
owner.player:setPosition(cc.p(owner.player:getPositionX()+64,owner.player:getPositionY()-64));owner.player:setOpacity(201)
owner.tipLayer:setVisible(false)
local currentX,currentY=owner.player:getPosition();local arrival=extra:getOrderOfArrival()
L.unmount(owner)
assert(owner.moveLayer.addChild==decorated,'newer addChild decorator overwritten')
local new=cc.Node:create();owner.moveLayer:addChild(new,8);assert(calls>0 and new:getParent()==owner.moveLayer);new:removeFromParent(true)
assert(extra:getParent()==owner.moveLayer and extra:getPositionX()==57 and extra:getPositionY()==83 and math.abs(extra:getScaleX()-.7)<.0001)
assert(extra:getRotation()==13 and extra:getOpacity()==117 and not extra:isVisible() and extra:getOrderOfArrival()==arrival and extra:getActionByTag(314161)==extraAction)
assert(owner.player:getPositionX()==currentX and owner.player:getPositionY()==currentY and owner.player:getOpacity()==201 and not owner.tipLayer:isVisible(),'current requested properties lost')
extra:removeFromParent(true);owner.moveLayer.addChild=nil
write('current-properties',{newChild=true,newDecorator=true,actor=true,visibility=true,actions=true})
finish(owner)
-- Current focus survives conversion; original clamp is authoritative at edges.
local cameraResults={}
for _,case in ipairs({'pan','zoom','actor-follow','pan-and-zoom'})do
 owner=seed();RAISED_MAP2_LIVE=true;assert(L.mount(owner))
 if case=='zoom' or case=='pan-and-zoom'then owner:setZoomScale(.55)end
 if case=='pan' or case=='pan-and-zoom'then owner.moveLayer:setPosition(cc.p(owner.moveLayer:getPositionX()+31,owner.moveLayer:getPositionY()-27))end
 if case=='actor-follow'then owner.player:setPosition(cc.p(owner.player:getPositionX()+64,owner.player:getPositionY()-64));owner:setViewpointCenter(cc.p(owner.player:getPosition()))end
 local point=cc.p(screenSize.width/2,((owner.adventureHudBottom or 0)+(owner.adventureHudTop or screenSize.height))/2)
 local focus=owner.map:convertToNodeSpace(owner:convertToWorldSpace(point));local scale=owner.moveLayer:getScale()
 local actorX,actorY=owner.player:getPosition()
 L.unmount(owner)
 local after=owner:convertToNodeSpace(owner.map:convertToWorldSpace(focus));local expected=owner:clampChartPosition(cc.p(owner.moveLayer:getPositionX()+point.x-after.x,owner.moveLayer:getPositionY()+point.y-after.y))
 assert(math.abs(owner.moveLayer:getPositionX()-expected.x)<.001 and math.abs(owner.moveLayer:getPositionY()-expected.y)<.001,'current focus/native clamp '..case)
 assert(owner.moveLayer:getScale()==scale and owner.player:getPositionX()==actorX and owner.player:getPositionY()==actorY)
 cameraResults[case]=true;finish(owner)
end
write('camera-current-focus',cameraResults)
owner=seed();RAISED_MAP2_LIVE=true;assert(L.mount(owner));local state=owner.raisedMap2Live
local oldMap,oldCamera=owner.map,owner.moveLayer
local newCamera=cc.Layer:create();owner:addChild(newCamera);newCamera:setPosition(cc.p(123,456));newCamera:setScale(.8)
local newMap=cc.TMXTiledMap:create('Images/Map/map_2.tmx');newCamera:addChild(newMap)
local newActor=cc.Node:create();newMap:addChild(newActor)
local newAction=cc.DelayTime:create(60);newAction:setTag(7101);newCamera:runAction(newAction)
owner.moveLayer,owner.map,owner.player=newCamera,newMap,newActor
assert(not L.refresh(owner) and not owner.raisedMap2Live)
assert(oldMap:getParent()==oldCamera and newMap:getParent()==newCamera)
assert(newCamera:getPositionX()==123 and newCamera:getPositionY()==456 and newCamera:getActionByTag(7101)==newAction,'rebound mutated unrelated camera')
write('active-rebound',{oldHierarchyRestored=true,newHierarchyUntouched=true,newCameraActionUntouched=true});finish(owner)

-- A source parent may already have an unconsumed same-Z reorder before
-- mounting. Establish its expected result through the original native sort,
-- then recreate the pending request without sorting/visiting it before mount.
local pendingResults={}
for _,kind in ipairs({'owner','map','moveLayer'})do
 owner=seed();local parent=kind=='owner' and owner or owner[kind];local children,names={},{}
 for i=1,3 do local child=cc.Node:create();parent:addChild(child,300);children[i]=child;names[child]=i end
 local function sequence(target)local values={};for _,child in ipairs(target:getChildren())do if names[child]then values[#values+1]=names[child]end end;return table.concat(values,',')end
 T.capture(owner,'pending-before-'..kind);parent:reorderChild(children[1],300);parent:sortAllChildren();local expected=sequence(parent)
 for _,child in ipairs(children)do parent:reorderChild(child,300)end;T.capture(owner,'pending-reset-'..kind)
 assert(sequence(parent)=='1,2,3');parent:reorderChild(children[1],300);local arrival=children[1]:getOrderOfArrival()
 RAISED_MAP2_LIVE=true;assert(L.mount(owner));local mounted=kind=='moveLayer' and owner.raisedMap2Live.turn or parent
 assert(sequence(mounted)==expected and children[1]:getOrderOfArrival()==arrival,'pending initial order '..kind)
 T.capture(owner,'pending-live-'..kind);arrival=children[1]:getOrderOfArrival();L.unmount(owner);parent:sortAllChildren()
 assert(sequence(parent)==expected and children[1]:getOrderOfArrival()==arrival,'pending order return '..kind)
 pendingResults[kind]={expectedNative=expected,actual=sequence(parent),currentArrivalExact=true};finish(owner)
end
write('pending-original-order',pendingResults)
-- Native exit/detach/push-pop may be traversing C++ child vectors. The adapter
-- remains installed until a safe explicit unmount or cleanup; no exit reparent.
owner=seed();RAISED_MAP2_LIVE=true;assert(L.mount(owner));local state=owner.raisedMap2Live
local scene=owner:getParent();cleanWorldExit(owner)
assert(owner.raisedMap2Live==state and owner.map:getParent()==state.turn,'exit changed hierarchy')
cleanWorldEnter(owner);owner:removeFromParent(false);assert(owner.raisedMap2Live==state);scene:addChild(owner);assert(L.refresh(owner))
local pushed=cc.Scene:create();cc.Director:getInstance():pushScene(pushed);T.ticks(.01,1);cc.Director:getInstance():popScene();T.ticks(.01,1)
assert(owner.raisedMap2Live==state and owner.map:getParent()==state.turn);assert(L.refresh(owner));L.unmount(owner);finish(owner)
for _,z in ipairs({-100,100})do
 owner=seed();local witness=cc.Node:create();owner:addChild(witness,z);local exits,cleanups=0,0
 witness:registerScriptHandler(function(event)if event=='exit'then exits=exits+1 elseif event=='cleanup'then cleanups=cleanups+1 end end)
 RAISED_MAP2_LIVE=true;assert(L.mount(owner));owner:removeFromParent(true)
 assert(exits==1 and cleanups==1 and owner.raisedMap2Live==nil,'cleanup traversal witness '..z)
 owner:release();cleanWorldDrain()
end
write('lifecycle',{nativeExit=true,detachReentry=true,pushPop=true,cleanupWitnessBothSides=true})
print('PASS map2 exact stationary/current properties, camera focus, decorator chains and native lifecycle restoration')

end
local ok,why=xpcall(main,debug.traceback);if not ok then error(why)end
