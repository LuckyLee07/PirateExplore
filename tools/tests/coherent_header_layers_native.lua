-- Consecutive rendered frames are essential: CCNode::visit clears each node's
-- arrival order, so geometry/visibility checks alone miss equal-z occlusion.
-- Reuse real alchemy transactions with an in-memory profile and no GUI/save.
local function read(path)
 local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s
end
local source=read('tools/tests/coherent_alchemy_transaction_native.lua')
local cut=assert(source:find('for _,size in ipairs(',1,true))
local S=assert(loadstring(source:sub(1,cut-1)..[[
return {fresh=fresh,close=close,step=step,receipt=receipt,H=H}
]],'@header-layers-fixture'))()
-- Restore only the previous equal-z composition in memory. This must fail the
-- same rendered-pixel check as the fixed version, without touching source.
if os.getenv('COHERENT_HEADER_COUNTERFACTUAL')=='1' then
 local base=read('bin/res/scripts/LuaClass/BaseView.lua')
 local first=assert(base:find('function BaseView:applyCoherentPageShell(',1,true))
 local last=assert(base:find('\nfunction BaseView:init()',first,true))
 local old,count=base:sub(first,last-1):gsub('canvas:addChild%(header,%-1%)','canvas:addChild(header)')
 assert(count==1,'counterfactual restores only the explicit header background layer')
 assert(loadstring(old,'@old-equal-z-header'))()
end
local output=os.getenv('COHERENT_HEADER_CAPTURE_DIR')
-- The ordinary non-rendering native aggregate runs this file too. The pixel
-- runner below is mandatory for the actual regression, not replaced by this.
if not coherentCapture or not output then
 print('SKIP header pixels: use coherent_progress_support_render.py')
 return
end
local manifest=assert(io.open(output..'/frames.tsv','w'))
local receipts=assert(io.open(output..'/receipts.tsv','w'))
local function capture(page,w,h,name,state)
 local path=output..'/'..name..'-'..w..'x'..h..'-'..state..'.png'
 assert(coherentCapture(page,w,h,path),'actual native frame '..state)
 manifest:write(name,'\t',w,'\t',h,'\t',state,'\t',path,'\n');manifest:flush()
 if state=='first-receipt' or state=='receipt-accumulated' or state=='receipt-recreated'then
  local receipt=S.receipt(page);local backdrop=receipt.alchemyBackdrop
  local size=backdrop:getContentSize()
  local a=backdrop:convertToWorldSpace(cc.p(0,0));local b=backdrop:convertToWorldSpace(cc.p(size.width,size.height))
  receipts:write(name,'\t',w,'\t',h,'\t',state,'\t',path,'\t',a.x,'\t',h-b.y,'\t',b.x,'\t',h-a.y,'\n');receipts:flush()
 end
end
local function dynamicChildren(page,w,h,name)
 local canvas=page.coherentShell.canvas;local children={}
 -- Cross std::sort's small/large child-count paths, rendering between each
 -- burst so every old sibling has gone through the real arrival-order reset.
 for step,count in ipairs({1,4,16,7})do
  for _=1,count do local child=cc.Node:create();canvas:addChild(child);children[#children+1]=child end
  capture(page,w,h,name,'children-added-'..step)
 end
 for step,count in ipairs({7,16,4,1})do
  for _=1,count do local child=table.remove(children);child:removeFromParent(true)end
  capture(page,w,h,name,'children-removed-'..step)
 end
 capture(page,w,h,name,'settled')
end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2]
 for _,kind in ipairs({{'talent',TalentLayer},{'achievement',AchievementLayer},{'shared-shell',BaseView}})do
  local name,class=kind[1],kind[2]
  local scene,d=S.fresh(w,h);d[roleStorageInfo][achievement_Alchemy]=0
  local page=assert(class:create());page:retain();scene:addChild(page)
  if class==BaseView then page:applyCoherentPageShell('港口建设','准备材料，拓展船上的设施')end
  capture(page,w,h,name,'initial')
  capture(page,w,h,name,'second-frame')
  if class~=BaseView then
   pNeedUpdateLayer=page;dofile('bin/res/scripts/LuaClass/ToastUtil.lua')
   local money=d[roleMoney]
   page.setBtn.onSingleCLick();S.step(scene,.01);S.step(scene,.01)
   assert(d[roleMoney]==money+3,'real manual alchemy grant before rendered receipt')
   local receipt=S.receipt(page);assert(receipt:isVisible() and receipt.alchemyAmount==3)
   capture(page,w,h,name,'first-receipt')
   capture(page,w,h,name,'receipt-next-frame')
   assert(ToastUtil:alchemyCoins(2)==receipt and receipt.alchemyAmount==5)
   capture(page,w,h,name,'receipt-accumulated')
   S.step(scene,.01);S.step(scene,2);assert(not receipt:isVisible() and receipt.alchemyAmount==0)
   capture(page,w,h,name,'receipt-expired')
   receipt:removeFromParent(true)
   capture(page,w,h,name,'receipt-removed')
   assert(ToastUtil:alchemyCoins(3):isVisible())
   capture(page,w,h,name,'receipt-recreated')
  end
  dynamicChildren(page,w,h,name)
  S.close(page);S.H.finish()
 end
end
manifest:close();receipts:close();pNeedUpdateLayer=nil
print('PASS native consecutive-frame header fixtures: real alchemy, receipt lifecycle and repeated child insertion/removal at five sizes')
