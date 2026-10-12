-- Actual Cocos geometry and retained callback checks for the explicit page shell.
local f=assert(io.open('tools/tests/warm_home_dialog_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {fixture=fixture,visit=visit,prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
finish=function()scene:cleanup();scene:release();scene=nil end}
]],'@coherent-shell-fixture'))()
UITopHeight=100;UIBottomHeight=136
WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
local dm=DataManager:getInstance();dm.isShowDiamondStoreRedPointer=function()return false end
local guide=GuideController:getInstance();guide.removeRedPoint=function()end;guide.addRedPoint=function()end
require 'LuaClass/BaseView'
for _,size in ipairs({{480,800},{540,900},{640,1136},{720,1280}})do
 H.fixture();local scene=H.prepare(size[1],size[2]);local view=BaseView:create();scene:addChild(view)
 local backs=0;local shell=view:applyCoherentPageShell('港口建设','准备材料，拓展船上的设施',function()backs=backs+1 end)
 assert(shell.width==480 and shell.body.top==650 and shell.body.y==104)
 assert(view.approvedPage and view.keepNavigation==false)
 assert(not view.mainBg:isVisible() and not view.titleBg:isVisible() and not view.storeMenu:isVisible())
 assert(view:applyCoherentPageShell('ignored')==shell,'idempotent shell')
 H.visit(shell.canvas,function(n,visible)
  if visible and n.getString then
   local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=size[1]+1 and a.y>=-1 and b.y<=size[2]+1,'shell text bounds '..n:getString())
  end
 end)
 -- W.button exposes its actual handler for native regression fixtures.
 shell.back.item:activate();shell.back.item:activate();assert(backs==1,'rapid back only leaves once')
 view:superDestory();assert(view.coherentPageDisposed);shell.back.item:activate();assert(backs==1,'stale back suppressed')
 H.finish()
end
print('coherent page shell native: PASS')
