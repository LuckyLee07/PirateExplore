-- A presentation child of the real moving actor. No replacement actor, movement
-- action, logical position or save. The existing clean-voyage art is reused.
local B={path='Images/UI/CleanVoyage/'}
local widths={ne=88,nw=88,sw=82,se=78}
local anchors={ne={.48,.105},nw={.52,.175},sw={.5,.105},se={.5,.15}}
local function hook(target,name,make)
 local peer=tolua.getpeer(target);local saved=peer and rawget(peer,name)
 local replacement=make(target[name]);target[name]=replacement
 return function()if target[name]==replacement then target[name]=saved end end
end
function B.heading(dx,dy)
 if math.abs(dx)>math.abs(dy)then return dx>0 and 'se' or 'nw' end
 if dy~=0 then return dy>0 and 'ne' or 'sw' end
end
local function release(a)
 local lease=a.lease;if not lease then return end;a.lease=nil
 for _,entry in ipairs(lease.hidden)do
  for _,restore in ipairs(entry.restore)do restore()end
  entry.nativeVisible(entry.node,entry.visible);entry.node:release()
 end
 lease.root:removeFromParent(true);lease.root:release();lease.actor:release()
end
local function heading(lease,value)
 if lease.heading==value then return end;lease.heading=value
 for direction,sprite in pairs(lease.sprites)do sprite:setVisible(direction==value)end
end
local function acquire(a,actor,source)
 -- C++ Show/Hide and other actions bypass Lua visibility hooks. Preserve those
 -- actions exactly by retaining the original art until they have completed.
 if source:getNumberOfRunningActions()>0 then return end
 local halo
 for _,child in ipairs(actor:getChildren())do
  if child~=source and child:getLocalZOrder()==-1 and tolua.type(child)=='cc.DrawNode' then
   if child:getNumberOfRunningActions()>0 then return end
   if halo then halo=nil;break end
   halo=child
  end
 end
 for direction in pairs(widths)do
  if not cc.FileUtils:getInstance():isFileExist(B.path..'boat-clean-'..direction..'.png')then return end
 end
 local root=cc.Node:create();root:setRotation(-45)
 local upright=cc.Node:create();upright:setScaleY(1/.56);root:addChild(upright)
 local lease={root=root,upright=upright,actor=actor,source=source,sprites={},hidden={}}
 actor:retain();root:retain();actor:addChild(root,source:getLocalZOrder());a.lease=lease
 local contact=cc.DrawNode:create();upright:addChild(contact,-1);lease.contact=contact
 local dispatcher=contact:getEventDispatcher()
 contact:registerScriptHandler(function(event)if event=='exit'then dispatcher:resumeEventListenersForTarget(contact)end end)
 local points={};for i=0,23 do local r=i*math.pi/12;points[#points+1]=cc.p(25*math.cos(r),-2+6*math.sin(r))end
 local c=cc.c4f(16/255,97/255,109/255,.22)
 for i=2,#points-1 do contact:drawTriangle(points[1],points[i],points[i+1],c)end
 for direction,width in pairs(widths)do
  local s=cc.Sprite:create(B.path..'boat-clean-'..direction..'.png');s:getTexture():setAntiAliasTexParameters()
  s:setScale(width/s:getContentSize().width);s:setAnchorPoint(cc.p(unpack(anchors[direction])));upright:addChild(s)
  lease.sprites[direction]=s
 end
 for _,n in ipairs(halo and {source,halo}or{source})do
  n:retain();local entry={node=n,visible=n:isVisible(),nativeVisible=n.setVisible,restore={}}
  lease.hidden[#lease.hidden+1]=entry
  entry.restore[#entry.restore+1]=hook(n,'setVisible',function(native)return function(_,visible)
   entry.visible=visible;native(n,false)
   if n==source then root:setVisible(visible)end
  end end)
  entry.restore[#entry.restore+1]=hook(n,'isVisible',function()return function()return entry.visible end end)
  entry.restore[#entry.restore+1]=hook(n,'runAction',function(native)return function(target,action)
   release(a);return native(target,action)
  end end)
  entry.nativeVisible(n,false)
 end
 heading(lease,a.heading or 'ne')
 return lease
end
function B.sync(a)
 if not a or a.disposed then return end
 local owner=a.owner;local actor,source=owner.player,owner.adventureShipVisual
 local lease=a.lease
 if lease and (actor~=lease.actor or source~=lease.source or source:getParent()~=actor or actor:getParent()~=owner.map)then release(a);lease=nil end
 if not actor or not source or source:getParent()~=actor or actor:getParent()~=owner.map then return end
 local x,y=actor:getPosition()
 if a.actor==actor and a.x then a.heading=B.heading(x-a.x,y-a.y)or a.heading end
 a.actor,a.x,a.y=actor,x,y
 if not lease then lease=acquire(a,actor,source)end
 if not lease then return end
 -- Position is actor-local and therefore follows every native movement frame.
 -- Never cache or replace the actor's transform. Restore needs no transform copy.
 lease.root:setPosition(cc.p(source:getPosition()))
 heading(lease,a.heading or 'ne')
 lease.root:setVisible(source:isVisible())
 for _,sprite in pairs(lease.sprites)do
  sprite:setOpacity(source:getDisplayedOpacity());sprite:setColor(source:getDisplayedColor())
  sprite:setRotation(source:getRotation());sprite:setSkewX(source:getSkewX());sprite:setSkewY(source:getSkewY())
 end
 lease.contact:setOpacity(source:getDisplayedOpacity())
end
function B.create(owner)
 local direction=owner.jointed and owner.jointed.dirction
 local headings={[UpDiriction]='ne',[LeftDirction]='nw',[RightDircion]='se',[BottomDirction]='sw'}
 local a={owner=owner,heading=headings[direction]};B.sync(a);return a
end
function B.dispose(a)
 if not a or a.disposed then return end;a.disposed=true;release(a)
 a.owner=nil;a.actor=nil
end
return B
