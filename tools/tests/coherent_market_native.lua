local f=assert(io.open('tools/tests/warm_home_dialog_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find('for _,height in ipairs({960,1067,1136})do',1,true))
local H=assert(loadstring(source:sub(1,stop-1)..[[
return {dm=dm,tables=tables,csv=csv,fixture=fixture,serialize=serialize,visit=visit,getData=function()return data end,
prepare=function(w,h)viewport=cc.size(w,h);scene=cc.Scene:create();scene:retain();return scene end,
finish=function()scene:cleanup();scene:release();scene=nil end}
]],'@market-native-fixture'))()
local assertSubscriptionClean=dofile('tools/tests/coherent_subscription_probe.lua')(H.dm)
UITopHeight=100;UIBottomHeight=136;WriteColor=cc.c3b(255,255,255);BaseColor=cc.c3b(38,65,68)
local dm=H.dm;H.tables[csvOfStore]=H.csv('store')
local guide=GuideController:getInstance();guide.addRedPoint=function()end;guide.removeRedPoint=function()end
local deductions,unlocks,paidOffers=0,0,0
local removeOnUnlock=false
ToastUtil.downString=function()end
dm.isShowDiamondStoreRedPointer=function()return false end
dm.getPackNumWithId=function(_,id)local d=H.getData();return id=='1001' and d[roleMoney]or(d[rolePack][id]or 0)end
dm.addPackItemWithId=function(_,id,num)local d=H.getData();if id=='1001'then d[roleMoney]=d[roleMoney]+num;deductions=deductions+1 else d[rolePack][id]=(d[rolePack][id]or 0)+num end end
dm.sendSystemInfo=function()end;dm.createSuccessCheck=function(_,kind,id)assert(kind==kUnlockStore);unlocks=unlocks+1;if removeOnUnlock then local rows=H.getData()[roleStore];for i=#rows,1,-1 do if rows[i].sortId==id then table.remove(rows,i)end end end end
dm.showBuyGoldBox=function()paidOffers=paidOffers+1 end
require 'LuaClass/StoreMode'
local M=require 'LuaClass/WarmMarket'
for _,size in ipairs({{480,800},{540,900},{640,1136},{720,1280}})do
 H.fixture();local scene=H.prepare(size[1],size[2]);local data=H.getData()
 data[roleMoney]=100000;data[rolePack]={};data[roleStore]={{[dataKeyID]='1006',sortId='1'},{[dataKeyID]='1007',sortId='2'}}
 local view=assert(StoreLayer:create(false,'1007'));scene:addChild(view);view:retain()
 assert(view.marketSelected=='1007' and view.approvedPage)
 if coherentCapture and size[1]==480 and os.getenv('COHERENT_MARKET_CAPTURE_PATH') then assert(coherentCapture(view,480,800,os.getenv('COHERENT_MARKET_CAPTURE_PATH')))end
 local before=H.serialize(data);M.quantities(view);local modal=assert(view.adventureDialog);M.quantities(view);assert(view.adventureDialog==modal,'one bulk sheet')
 modal.warmOptions[2].item:activate();assert(view.marketQuantity==10 and not view.adventureDialog)
 assert(H.serialize(data)==before,'quantity selection read-only')
 local price=tonumber(H.tables[csvOfResourceInfo]['1007'].price);local count=deductions
 view.marketPurchase.onSingleCLick();assert(data[rolePack]['1007']==10 and data[roleMoney]==100000-price*10 and deductions==count+1)
 assert(unlocks>0,'real store unlock boundary')
 H.visit(view.coherentShell.canvas,function(n,visible)
  if visible and n.getString and n:getString()~='' then
   local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height))
   assert(a.x>=-1 and b.x<=size[1]+1 and a.y>=-1 and b.y<=size[2]+1,'market label bounds: '..n:getString())
  end
 end)
 data[roleMoney]=0;local shortage=H.serialize(data);local beforeOffers=paidOffers
 view.marketPurchase.onSingleCLick();assert(view.adventureDialog and H.serialize(data)==shortage,'insufficient funds cannot grant')
 view.adventureDialog.warmOptions[1].item:activate();assert(not view.adventureDialog and paidOffers==beforeOffers,'cancel never opens paid route')
 view.marketPurchase.onSingleCLick();view.adventureDialog.warmOptions[2].item:activate();assert(paidOffers>0,'explicit original buy-gold route retained')
 data[roleMoney]=10000;view.marketSelected='1007';view.marketQuantity=1;M.refresh(view)
 removeOnUnlock=true;local once=deductions;view.marketPurchase.onSingleCLick();view.marketPurchase.onSingleCLick();removeOnUnlock=false
 assert(deductions==once+1 and view.marketSelected==nil,'sold-out product cannot silently purchase next product on repeated input')
 local saved=H.serialize(data);view:superDestory();view.marketPurchase.onSingleCLick();assert(H.serialize(data)==saved,'stale purchase cannot mutate')
 view:release();H.finish();assertSubscriptionClean()
end
H.fixture();local scene=H.prepare(480,800);local data=H.getData();data[roleMoney]=100000;data[rolePack]={};data[roleStore]={}
for id,row in pairs(H.tables[csvOfStore])do
 if H.tables[csvOfResourceInfo][tostring(row.resourceInfoID)]then
  data[roleStore][#data[roleStore]+1]={[dataKeyID]=tostring(row.resourceInfoID),sortId=tostring(id)}
 end
end
table.sort(data[roleStore],function(a,b)return tonumber(a.sortId)<tonumber(b.sortId)end)
local view=assert(StoreLayer:create());scene:addChild(view)
local catalogCount=#data[roleStore];assert(catalogCount>40,'full actual shipped market catalog')
local before=H.serialize(data)
for _,row in ipairs(data[roleStore])do
 assert(view:focusEntry(row[dataKeyID]));view.marketSelected=row[dataKeyID];M.refresh(view)
 local item=H.tables[csvOfResourceInfo][row[dataKeyID]]
 if tonumber(item.limits)==1 then M.quantities(view);assert(not view.adventureDialog and view.marketQuantity==1,'single-unit items suppress bulk')end
end
assert(H.serialize(data)==before,'full catalog browsing is read-only');H.finish();assertSubscriptionClean()
print('coherent market native: PASS ('..catalogCount..' shipped catalog entries)')
