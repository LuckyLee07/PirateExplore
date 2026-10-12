-- Native EventLayer entry, actual selector confirmation, actual debit/shortage
-- and real gift. This suite requires the selector's genuine GLView harness.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local realDirector=cc.Director.getInstance;local director=realDirector(cc.Director)
local source=read('tools/tests/world_chart_selector_native.lua');local stop=assert(source:find('for _,size in ipairs(',1,true))
local F=assert(loadstring(source:sub(1,stop-1)..[[
return {H=H,T=T,S=S,fresh=fresh,select=select,tap=tap,scene=function()return scene end,view=function()return view end,clear=function()if view then view:release();view=nil end;event=nil end}
]],'@selector-shortage-owner-fixture'))()
local H=F.H;local T=dofile('tools/tests/fixtures/real_shortage_owner_fixture.lua')(H,director)
local errors={};__G__TRACKBACK__=function(e)errors[#errors+1]=e;return e end
local record
for _,row in pairs(H.tables[csvOfShopItem])do if tonumber(row.unlock)and tonumber(row.unlock)>0 then record=row;break end end
assert(record);local index=tonumber(record.unlock);local grants=0;H.dm.buyGoodsInDiamondStore=function()grants=grants+1 end
local function open()
 local view=F.fresh(480,800,index,1,index-1,0,index);F.T.roles()[roleDiamond]=0;isEnterMap=true
 F.select(index);F.tap(view.worldPrimary);F.tap(assert(view.worldModal).confirm)
 return F.scene(),view
end
for _,how in ipairs({'remove','detach','new-modal','scene'})do
 for _,phase in ipairs({'prompt','gift'})do
  local scene,view=open();local prompt,context=T.prompt(view);local gift=phase=='gift'and T.gift(prompt,context)or nil
  T.eq(grants,0,'shortage never unlocks');T.eq(F.T.roles()[roleDiamond],0,'shortage never debits');local parent=view:getParent()
  T.expired(scene,view,prompt,context,gift,function()
   if how=='remove'then view:removeFromParent(true)
   elseif how=='detach'then view:removeFromParent(false)
   elseif how=='new-modal'then F.S.modal(view,'New generation','Changed selection','Continue',function()end)
   else director:replaceScene(cc.Scene:create());for _=1,4 do director:drawScene()end end
  end)
  if how=='detach'then
   parent:addChild(view);T.ok(not view.worldSuspended,'native reentry resumes selector')
   F.S.select(view,index);F.S.confirm(view);assert(view.worldModal).worldAccept()
   local fresh=assert(view.warmShortageContext);T.ok(fresh~=context and fresh.isActive(),'reentry creates fresh context')
   fresh.owner.adventureDialog.warmOptions[2].item:activate()
  end
  H.finish();F.clear();if gift then gift:release()end;prompt:release()
  print('PASS actual selector '..phase..' '..how)
 end
end
local scene,view=open();local prompt,context=T.prompt(view);prompt.warmOptions[2].item:activate();prompt:release()
F.T.roles()[roleDiamond]=tonumber(record.price);local before=T.writes;F.S.confirm(view);view.worldModal.worldAccept()
T.eq(F.T.roles()[roleDiamond],0,'exact original expansion price');T.eq(T.writes,before+1,'one original expansion debit');T.eq(grants,1,'one original expansion grant')
H.finish();F.clear()
assert(#errors==0,table.concat(errors,'\n'));T.finish('actual selector shortage native detach/reentry/generation/full-scene lifecycle');cc.Director.getInstance=realDirector
