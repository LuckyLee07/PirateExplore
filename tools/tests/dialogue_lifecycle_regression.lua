-- Execute the actual DialogueView with strict native-lifecycle ordering.
-- No GUI, service or player save. A destroyed mock rejects native method calls.
local Node = {}
local function alive(n) assert(n and not n.dead, 'native node is destroyed') end
local function node(kind) return setmetatable({kind=kind,children={},actions={},visible=true,z=0,running=false},{__index=Node}) end
function Node:addChild(c,z)
    alive(self);alive(c);assert(not c.parent);self.children[#self.children+1]=c;c.parent=self;c.z=z or c.z
    if self.running then c:onEnter() end
end
function Node:getParent() alive(self);return self.parent end
function Node:getChildren() alive(self);local list={};for i,c in ipairs(self.children)do list[i]=c end;return list end
function Node:isRunning() alive(self);return self.running end
function Node:setVisible(v) alive(self);self.visible=v end
function Node:setLocalZOrder(z) alive(self);self.z=z end
function Node:getLocalZOrder() alive(self);return self.z end
function Node:reorderChild(c,z) alive(c);assert(c.parent==self,'reordering another scene child');c.z=z end
function Node:registerScriptHandler(f) self.handler=f end
function Node:onEnter() self.running=true;for _,c in ipairs(self.children)do c:onEnter()end;if self.handler then self.handler('enter')end end
function Node:onExit() self.running=false;for _,c in ipairs(self.children)do c:onExit()end;if self.handler then self.handler('exit')end end
function Node:stopAllActions() self.actions={} end
function Node:cleanup()
    self:stopAllActions();if self.handler then self.handler('cleanup')end
    local count=#self.children;for _,c in ipairs(self.children)do c:cleanup();assert(#self.children==count,'cleanup mutated sibling vector')end
end
function Node:removeChild(c,cleanup)
    alive(c);assert(c.parent==self,'removing another scene child')
    local count=#self.children
    if self.running then c:onExit()end;if cleanup~=false then c:cleanup()end
    assert(#self.children==count,'lifecycle callback mutated sibling vector')
    for i,v in ipairs(self.children)do if v==c then table.remove(self.children,i);break end end;c.parent=nil
end
function Node:removeFromParent(cleanup) if self.parent then self.parent:removeChild(self,cleanup)end end
function Node:runAction(a) self.actions[#self.actions+1]=a;return a end
local function destroy(n) for _,c in ipairs(n.children)do destroy(c)end;n.dead=true end
local dispatcher={addEventListenerWithSceneGraphPriority=function(_,listener,owner)owner.listenerCount=(owner.listenerCount or 0)+1;owner.touch=listener end}
function Node:getEventDispatcher() return dispatcher end
cc={Handler={EVENT_TOUCH_BEGAN=1,EVENT_TOUCH_MOVED=2,EVENT_TOUCH_ENDED=3},c4b=function(...)return {...}end}
for _,kind in ipairs({'Node','Layer','Scene'})do local k=kind;cc[k]={create=function()return node(k)end}end
cc.LayerColor={create=function()return node('Mask')end}
cc.EventListenerTouchOneByOne={create=function()return{setSwallowTouches=function(self,v)self.swallow=v end,registerScriptHandler=function(self,f,id)self[id]=f end}end}
cc.ScaleTo={create=function(_,time,scale)return{kind='scale',time=time,scale=scale}end}
cc.Sequence={create=function(_,...)return{kind='sequence',children={...}}end}
cc.CallFunc={create=function(_,callback)return{kind='callback',callback=callback}end}
local scene
cc.Director={getInstance=function()return{getRunningScene=function()return scene end}end}
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/extern.lua')
require=function()return true end
local function reset()
    scene=node('Scene');scene:onEnter();dofile('bin/res/scripts/LuaClass/DialogueView.lua')
    return DialogueViewManager:sharedInstance()
end
local function finish(view)
    local action=view.actions[#view.actions];assert(action and action.kind=='sequence')
    local callback=action.children[#action.children];assert(callback.kind=='callback');callback.callback();return callback.callback
end
local function masks(s)
    local count=0;for _,child in ipairs(s.children)do if child.kind=='Mask' and child.visible then count=count+1 end end;return count
end
local passed,failed=0,0
local function test(name,fn)local ok,err=pcall(fn);if ok then passed=passed+1;print('PASS '..name)else failed=failed+1;print('FAIL '..name..': '..tostring(err))end end
test('scene replacement after open modal cannot reuse destroyed native mask',function()
    local manager=reset();local first=DialogueView:create();first:show()
    local old=scene;old:onExit();old:cleanup();destroy(old)
    scene=node('Scene');scene:onEnter();local nextView=DialogueView:create();nextView:show()
    assert(manager:Count()==1 and nextView:getParent()==scene and masks(scene)==1)
    nextView:close();finish(nextView);assert(manager:Count()==0 and masks(scene)==0)
end)
test('push/pop keeps independent masks and close callbacks bound to their original scene',function()
    local manager=reset();local lowerScene=scene;local lower=DialogueView:create();lower:show();lower:close()
    lowerScene:onExit();scene=node('Scene');scene:onEnter();local upper=DialogueView:create();upper:show()
    finish(lower);assert(lower:getParent()==nil and masks(lowerScene)==0)
    assert(manager:Count()==1 and upper:getParent()==scene and masks(scene)==1)
    scene:onExit();scene:cleanup();destroy(scene);scene=lowerScene;scene:onEnter()
    assert(manager:Count()==0);local again=DialogueView:create();again:show();assert(manager:Count()==1)
end)
test('paused modal survives scene push and resumes without losing its mask',function()
    local manager=reset();local old=scene;local view=DialogueView:create();view:show()
    old:onExit();scene=node('Scene');scene:onEnter();assert(manager:Count()==0)
    scene:onExit();scene:cleanup();destroy(scene);scene=old;scene:onEnter()
    assert(manager:Count()==1 and view:getParent()==old and masks(old)==1)
    view:close();finish(view);assert(manager:Count()==0 and masks(old)==0)
end)
test('repeated show and close register once and never corrupt another modal',function()
    local manager=reset();local first=DialogueView:create();first:show();first:show()
    assert(first.listenerCount==1 and manager:Count()==1 and #first.actions==1)
    local second=DialogueView:create();second:show();assert(manager:Count()==2)
    first:close();first:close();assert(#first.actions==2)
    local stale=finish(first);stale();assert(manager:Count()==1 and masks(scene)==1)
    second:close();finish(second);assert(manager:Count()==0 and masks(scene)==0)
end)
test('removeAll during close is safe and an old callback cannot close reopened view',function()
    local manager=reset();local first=DialogueView:create();first:show();first:close()
    local stale=first.actions[#first.actions].children[3].callback
    local second=DialogueView:create();second:show();manager:removeAllView();manager:removeAllView()
    assert(first:getParent()==nil and second:getParent()==nil and manager:Count()==0 and masks(scene)==0)
    first:show();stale();assert(first:getParent()==scene and manager:Count()==1 and masks(scene)==1)
end)
test('external removal cleans membership without overriding subclass lifecycle handler',function()
    local manager=reset();local events={};local view=DialogueView:create()
    view:registerScriptHandler(function(event)events[event]=true end);view:show();view:removeFromParent()
    assert(events.exit and events.cleanup and manager:Count()==0 and masks(scene)==0)
    local nextView=DialogueView:create();nextView:show();assert(manager:Count()==1)
end)
test('bulk scene cleanup cannot remove siblings during native iteration',function()
    local manager=reset();local a=DialogueView:create();a:show();local b=DialogueView:create();b:show()
    scene:onExit();scene:cleanup();assert(manager:Count()==0)
end)
test('actual Lackmaterial reflush preserves modal ownership and can still close',function()
    local manager=reset();dofile('bin/res/scripts/LuaClass/Lackmaterial.lua')
    local view=Lackmaterial.new();local rows={{mtId='1007'}};local callback=function()end
    local rebuilt=0
    view.init=function(self,current,completion)
        assert(current==rows and completion==callback);rebuilt=rebuilt+1;self:addChild(node('RebuiltContent'))
    end
    view:addChild(node('OldContent'));view:show()
    local observer=view._dialogueLifecycle
    view:reflush(rows,callback) -- Unmodified production content-refresh method.
    assert(rebuilt==1 and view._dialogueLifecycle==observer and observer:getParent()==view)
    assert(manager:Count()==1 and masks(scene)==1 and view:getParent()==scene)
    view:close();finish(view);assert(manager:Count()==0 and masks(scene)==0 and view:getParent()==nil)
end)
print(string.format('Dialogue lifecycle regressions: %d passed, %d failed',passed,failed))
assert(failed==0,'dialogue lifecycle failures')
