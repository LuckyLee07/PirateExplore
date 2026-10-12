-- Real ToastUtil receipt against actual redesigned native page containers.
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local function fixture(path,tail)
 local s=read(path);local cut=assert(s:find('for _,size in ipairs(',1,true))
 return assert(loadstring(s:sub(1,cut-1)..tail,'@receipt-page-fixture'))()
end
local function verify(page,w,h)
 pNeedUpdateLayer=page
 dofile('bin/res/scripts/LuaClass/ToastUtil.lua')
 local receipt=assert(ToastUtil:alchemyCoins(3));assert(receipt:getParent()==page.alchemyReceiptHost)
 local node=receipt;while node do assert(node:isVisible(),'manual receipt must have no hidden ancestor');node=node:getParent()end
 local z=receipt.alchemyBackdrop:getContentSize()
 local a=receipt.alchemyBackdrop:convertToWorldSpace(cc.p(0,0));local b=receipt.alchemyBackdrop:convertToWorldSpace(cc.p(z.width,z.height))
 assert(a.x>=0 and a.y>=0 and b.x<=w and b.y<=h,'receipt fits actual scaled viewport')
 assert(ToastUtil:alchemyCoins(2)==receipt and receipt.alchemyAmount==5,'same visible receipt accumulates exact manual delta')
end
local S=fixture('tools/tests/coherent_progress_support_native.lua','return {fresh=fresh,close=close,H=H}')
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 for _,class in ipairs({TalentLayer,AchievementLayer})do
  local scene,d=S.fresh(size[1],size[2]);local page=assert(class:create());page:retain();scene:addChild(page)
  local before=S.H.serialize(d);verify(page,size[1],size[2]);assert(S.H.serialize(d)==before,'receipt writes no gameplay state')
  S.close(page);S.H.finish()
 end
end
local R=fixture('tools/tests/coherent_supply_pages_native.lua','return {fresh=fresh,close=close,H=H}')
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1136},{720,1280}})do
 local scene,d=R.fresh(size[1],size[2]);local page=assert(RepositoryLayer:create());page:retain();scene:addChild(page)
 local before=R.H.serialize(d);verify(page,size[1],size[2]);assert(R.H.serialize(d)==before,'warehouse receipt writes no gameplay state')
 R.close(page);R.H.finish()
end
pNeedUpdateLayer=nil
print('PASS real manual alchemy receipt visible and bounded on warehouse/talent/achievement at five sizes')
