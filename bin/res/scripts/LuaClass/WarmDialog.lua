-- Contextual warm sheet; owns presentation only. Actions remain caller-owned.
local W=require 'LuaClass/WarmTheme'
local D={}
function D.show(title,body,options,owner)
 local scene=cc.Director:getInstance():getRunningScene()
 owner=owner or scene
 if owner.adventureDialog then return owner.adventureDialog end
 local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin();local k=size.width/640
 local w=size.width-44*k;local h=math.min(size.height-48*k,(240+#options*91)*k)
 local layer=cc.LayerColor:create(cc.c4b(25,49,52,157),size.width,size.height);layer.isAdventureModal=true;owner.adventureDialog=layer
 scene:addChild(layer,3000)
 local p=W.panel(w,h,W.colors.paper,28*k);p:setPosition(cc.p(origin.x+22*k,origin.y+(size.height-h)/2));layer:addChild(p)
 local heading=W.label(title,30*k,W.colors.ink,w/2,h-39*k,true,.5);W.fit(heading,w-48*k);p:addChild(heading)
 local text=W.label(body,20*k,W.colors.muted,24*k,h-85*k,false);text:setAnchorPoint(cc.p(0,1));text:setDimensions(cc.size(w-48*k,132*k));text:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);p:addChild(text)
 local closed=false;local listener
 local ownerToken=cc.Node:create();owner:addChild(ownerToken)
 local function dispose()
  if closed then return end
  closed=true
  if owner.adventureDialog==layer then owner.adventureDialog=nil end
  if listener then layer:getEventDispatcher():removeEventListener(listener);listener=nil end
  local token=ownerToken;ownerToken=nil
  -- With the default scene owner, this observer is a sibling. Never remove
  -- it from the child list while the native scene is traversing onExit.
  if token and (owner~=scene or scene:isRunning())then token:removeFromParent(true)end
 end
 local function close()
  if closed or owner.adventureDialog~=layer then return end
  dispose();layer:removeFromParent(true)
 end
 ownerToken:registerScriptHandler(function(event)
  if event=='exit' or event=='cleanup'then
   ownerToken=nil
   -- A non-running scene still has running children during its exit walk.
   if not scene:isRunning() and layer:isRunning()then dispose()else close()end
  end
 end)
 layer.close=close;layer.warmOptions={}
 for i,o in ipairs(options)do
  local caption=o.label..(o.detail and ('\n'..o.detail)or'')
  local b=W.button(caption,w-44*k,77*k,function()
   if closed or owner.adventureDialog~=layer then return end
   if o.disabled then if ToastUtil then ToastUtil:toastString(o.reason or '条件尚未满足')end;return end
   if o.action and o.action()==false then return end
   close()
  end,{primary=i==1 and not o.disabled,size=(o.detail and 20 or 24)*k})
  b.label:setDimensions(cc.size(w-68*k,64*k));b.label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER);b.label:setScale(1)
  b:setPosition(cc.p(w/2,(#options-i)*91*k+59*k));p:addChild(b);layer.warmOptions[i]=b
  if o.disabled then b:setOpacity(130)end
 end
 listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(true);listener:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN);layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,layer)
 layer:registerScriptHandler(function(event)if event=='exit' or event=='cleanup'then dispose()end end)
 return layer
end
return D
