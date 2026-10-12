-- Warm market presentation; StoreLayer remains the sole transaction owner.
local W=require 'LuaClass/WarmTheme'
local D=require 'LuaClass/WarmDialog'
local M={}
local serial=0
function M.open(page,bottom,focus)
 local dm=DataManager:getInstance()
 page.roleStoreData=dm:getRoleData(roleStore)
 page.csvData=dm:getCSVByID(csvOfStore);page.ResoucecsvData=dm:getCSVByID(csvOfResourceInfo)
 if not page.csvData or not page.ResoucecsvData then return false end
 page.warmMarket=true;page.marketQuantity=1;page.marketGeneration=0
 local shell=page:applyCoherentPageShell('港口市场','选择物资，补足下一程的准备')
 local c=shell.canvas
 page.marketDetails=cc.Node:create();c:addChild(page.marketDetails)
 page.cellhight=76;page.areaHeight=330;page.showline=page.areaHeight/page.cellhight
 page.tableview=cc.TableView:create(cc.size(416,page.areaHeight))
 local t=page.tableview;t:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);t:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
 t:setPosition(cc.p(32,320));t.bIsScrollView=true;t:setDelegate();c:addChild(t)
 t:registerScriptHandler(function()return page.cellhight,416 end,cc.TABLECELL_SIZE_FOR_INDEX)
 t:registerScriptHandler(function()return #page.roleStoreData end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
 t:registerScriptHandler(function(view,index)
  local cell=view:dequeueCell() or cc.TableViewCell:create();cell:removeAllChildren(true)
  local entry=page.roleStoreData[index+1];local id=tostring(entry[dataKeyID]);local item=page.ResoucecsvData[id]
  local button=W.button('',408,68,function()
   if page.coherentPageDisposed or page.coherentPageLeaving then return end
   page.marketSelected=id;page.marketQuantity=1;t:reloadData();M.refresh(page)
  end,{color=page.marketSelected==id and cc.c3b(234,240,216) or W.colors.paper})
  button:setPosition(cc.p(208,38));cell:addChild(button)
  local art=W.sprite('Images/Icon/'..tostring(item.iconName),48,48)
  if art then art:setPosition(cc.p(34,34));button:addChild(art) end
  local title=W.label(item.name,21,W.colors.ink,68,44,false,0);W.fit(title,242);button:addChild(title)
  local price=W.label(tostring(item.price)..' 金币',17,W.colors.muted,68,20,false,0);W.fit(price,236);button:addChild(price)
  local stock=W.label('持有 '..tostring(dm:getPackNumWithId(id)or 0),16,W.colors.muted,390,33,false,1);W.fit(stock,100);button:addChild(stock)
  if entry.S~=nil then GuideController:getInstance():addRedPoint(button.item) end
  return cell
 end,cc.TABLECELL_SIZE_AT_INDEX)
 local purchase=SDButton:create('Images/btn/ann01_a.png','Images/btn/ann01_a.png',function()M.purchase(page)end)
 ManagementTheme.skinSDButton(purchase,'coral');purchase:setPosition(cc.p(363,48));c:addChild(purchase)
 local label=W.label('购买',22,W.colors.white,purchase:getContentSize().width/2,purchase:getContentSize().height/2,false,.5);purchase:addChild(label);page.marketPurchase=purchase
 purchase:registerLongPressedActiveOnce(function()M.quantities(page)end)
 local quantity=W.button('数量',100,48,function()M.quantities(page)end,{size=18})
 quantity:setPosition(cc.p(207,48));c:addChild(quantity);page.marketQuantityButton=quantity
 serial=serial+1;page.marketEventKey='coherentMarket'..serial
 local eventKeys={roleMoney,rolePack,roleStore}
 for _,key in ipairs(eventKeys)do dm:registerEvent(key,page.marketEventKey,function()
  if page.coherentPageDisposed or page.marketBusy then return end
  page:initdata();t:reloadData();M.refresh(page)
 end)end
 page.disposeMarket=function()
  if not page.marketEventKey then return end
  for _,key in ipairs(eventKeys)do
   dm:unregisterEvent(key,page.marketEventKey)
   local bucket=dm.__eventListener and dm.__eventListener[key]
   if bucket then bucket[page.marketEventKey]=nil end
  end
  page.marketEventKey=nil;page.coherentPageDisposed=true
 end
 page:registerScriptHandler(function(event)
  if event=='exit' or event=='cleanup' then page.disposeMarket() end
 end)
 if #page.roleStoreData>0 then page.marketSelected=tostring(page.roleStoreData[bottom and #page.roleStoreData or 1][dataKeyID]) end
 if focus then for _,entry in ipairs(page.roleStoreData)do if tostring(entry[dataKeyID])==tostring(focus)then page.marketSelected=tostring(focus) end end end
 t:reloadData();if bottom then t:setContentOffset(cc.p(0,0),false)end
 page:focusEntry(focus);M.refresh(page);return true
end
function M.selected(page)
 for _,entry in ipairs(page.roleStoreData or {})do
  if tostring(entry[dataKeyID])==page.marketSelected then return entry,page.ResoucecsvData[page.marketSelected] end
 end
end
function M.refresh(page)
 if page.coherentPageDisposed then return end
 page.marketGeneration=page.marketGeneration+1
 local contentHeight=#page.roleStoreData*page.cellhight
 if contentHeight<page.areaHeight then page.tableview:setContentOffset(cc.p(0,page.areaHeight-contentHeight),false)end
 local entry,item=M.selected(page)
 if not entry then page.marketSelected=nil;page.marketQuantity=1 end
 local n=page.marketDetails;n:removeAllChildren(true)
 local function label(text,size,color,x,y,width)
  local a=W.label(text,size,color,x,y,false,0);if width then W.fit(a,width)end;n:addChild(a);return a
 end
 local dm=DataManager:getInstance();label('金币 '..tostring(dm:getPackNumWithId('1001')or 0),19,W.colors.muted,32,288,416)
 if not item then
  label(#page.roleStoreData>0 and '请选择下一件物资' or '暂时没有可购买的物资',24,W.colors.ink,32,235,416)
  label(#page.roleStoreData>0 and '在上方列表查看价格与库存。' or '继续建设港口，解锁更多物资。',18,W.colors.muted,32,190,416)
 else
  if tonumber(item.limits)==1 then page.marketQuantity=1 end
  label(item.name,25,W.colors.ink,32,247,416)
  local desc=label(item.desc or '',18,W.colors.muted,32,208)
  desc:setDimensions(cc.size(416,60));desc:setAnchorPoint(cc.p(0,1));desc:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
  local total=tonumber(item.price)*page.marketQuantity
  label('购买 '..page.marketQuantity..' 个 · 共 '..total..' 金币',21,W.colors.ink,32,120,416)
 end
 page.marketPurchase:setVisible(item~=nil);page.marketQuantityButton:setVisible(item~=nil and tonumber(item.limits)~=1)
end
function M.quantities(page)
 if page.coherentPageDisposed or page.coherentPageLeaving then return end
 local entry,item=M.selected(page);if not item or tonumber(item.limits)==1 then return end
 local generation=page.marketGeneration;local options={}
 for _,num in ipairs({1,10,100,1000})do
  options[#options+1]={label=tostring(num)..' 个',detail='共 '..tostring(tonumber(item.price)*num)..' 金币',action=function()
   if page.coherentPageDisposed or generation~=page.marketGeneration then return end
   page.marketQuantity=num;M.refresh(page)
  end}
 end
 D.show('购买数量','选择本次需要的数量，确认后再购买。',options,page)
end
function M.purchase(page)
 if page.coherentPageDisposed or page.coherentPageLeaving or page.marketBusy then return end
 local entry,item=M.selected(page);if not entry then return end
 page.marketBusy=true
 page:buy(entry[dataKeyID],entry.sortId,page.marketQuantity,nil)
 page.marketBusy=false;M.refresh(page)
end
return M
