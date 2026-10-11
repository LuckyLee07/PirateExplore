-- Permanent, nontrade voyage keepsakes. Inventory remains a separate activity.
local W=require 'LuaClass/WarmTheme'
local Memories=require 'LuaClass/WarmMemories'
local C={}
local serial=0
function C.open(owner,initialTab)
 if not owner or owner.homeDisposed or owner.warmDisposed then return nil end
 if owner.warmCollection and not owner.warmCollection.closed then return owner.warmCollection end
 local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
 local dm=DataManager:getInstance();local c=W.colors
 local layer=cc.LayerColor:create(cc.c4b(c.paper.r,c.paper.g,c.paper.b,255),size.width,size.height)
 layer:setPosition(origin);owner.warmCollection=layer;owner:addChild(layer,18000)
 local u=math.min(size.width/480,size.height/800);local canvas=cc.Node:create();canvas:setContentSize(cc.size(480,800));canvas:setScale(u);canvas:setPosition(cc.p((size.width-480*u)/2,(size.height-800*u)/2));layer:addChild(canvas);layer.canvas=canvas
 layer.tab=initialTab=='log' and 'log' or 'collection';layer.page=1;layer.closed=false;layer.generation=0
 serial=serial+1;local eventKey='warmCollection'..serial
 local touch=cc.EventListenerTouchOneByOne:create();touch:setSwallowTouches(true);touch:registerScriptHandler(function()return not layer.closed end,cc.Handler.EVENT_TOUCH_BEGAN);layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touch,layer)
 local function dispose()
  if layer.closed then return end
  layer.closed=true
  if owner.warmCollection==layer then owner.warmCollection=nil end
  dm:unregisterEvent(Memories.KEY,eventKey)
  local bucket=dm.__eventListener and dm.__eventListener[Memories.KEY]
  if bucket then bucket[eventKey]=nil end
  layer:getEventDispatcher():removeEventListener(touch)
 end
 local function close()
  if layer.closed then return end
  dispose()
  layer:removeFromParent(true)
 end
 layer.close=close
 layer:registerScriptHandler(function(e)if e=='exit' or e=='cleanup'then dispose()end end)
 local function add(n,x,y)if not n then return end;n:setPosition(cc.p(x,y));canvas:addChild(n);return n end
 local function label(text,font,x,y,width,color,bold)
  local n=W.label(text,font,color or W.colors.ink,x,y,bold,0)
  if width then n:setDimensions(cc.size(width,0));n:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)end
  canvas:addChild(n);return n
 end
 local function card(x,y,w,h) return add(W.panel(w,h,W.colors.white,8),x,y)end
 local function button(text,x,y,w,h,fn,primary,icon,enabled)
  local gen=layer.generation
  local b=W.button(text,w,h,function()if layer.closed or gen~=layer.generation or owner.warmCollection~=layer then return end;fn()end,{primary=primary,icon=icon,size=20})
  b.item:setEnabled(enabled~=false)
  if enabled==false then b:setOpacity(140);b:setCascadeOpacityEnabled(true)end
  return add(b,x,y)
 end
 function layer:showTab(tab)
  if self.closed then return end
  self.tab=tab=='log' and 'log' or 'collection';self.page=1;self.preview=nil;self.logDetail=nil;self.cargoPage=1;self:refresh()
 end
 function layer:refresh()
  if self.closed then return end
  self.generation=self.generation+1;canvas:removeAllChildren(true)
  local state=Memories.get(dm);self.state=state
  if state.readOnly or not (state.items and state.items[Memories.ITEM_ID]) then self.preview=nil end
  card(14,678,452,104)
  button('‹',42,751,46,46,function()if self.preview then self.preview=nil;self:refresh()elseif self.logDetail then self.logDetail=nil;self:refresh()elseif self.detail then self.detail=nil;self:refresh()else close()end end)
  label(self.tab=='log' and '航海日志' or '航程收藏',27,82,753,365,W.colors.ink,true)
  label(self.tab=='log' and '每次归航与失利，留下航程的记录' or '安全带回的纪念 · 可陈列在船上',16,26,701,428,W.colors.muted)
  if state.readOnly then
   card(22,234,436,414);add(W.icon('log',90),195,489)
   label(state.reason=='legacy' and '这段旧航程，尚无纪念记录' or '暂时无法打开这份记录',25,49,443,390,W.colors.ink,true)
   label(state.reason=='legacy' and '可以继续航行，查看已有库存与成就。过去的航程不会补写到这本日志中。' or '记录暂时无法读取，已保存的内容会保留。请先返回船上。',20,49,362,382,W.colors.muted)
   button('回到船上',240,79,414,58,close,true);return
  end
  if self.tab=='log' then
   local logs=state.logs or state.log or {};local total=#logs
   if self.logDetail and logs[self.logDetail] then
    local r=logs[self.logDetail];local returned=r.outcome=='returned';local settlement=r.settlement or {}
    card(22,470,436,176)
    label('第 '..tostring(r.voyage)..' 次 · '..(returned and '平安归航' or '航行失利'),26,45,607,390,W.colors.ink,true)
    local choice=r.event and r.event.choice
    local eventText=choice=='rescue' and '沉船抉择：先救人' or (choice=='supply' and '沉船抉择：回收物资' or (choice=='chart' and '沉船回收：抢救航图' or (choice=='supplies' and '沉船回收：回收货箱' or '本航未记录沉船事件')))
    label(eventText,19,45,559,390,W.colors.muted)
    label('金币变化 '..tostring(settlement.moneyDelta or 0)..'  ·  纪念物 '..tostring(#(r.memoryIds or {})),19,45,513,390,W.colors.ink,true)
    card(22,198,436,253)
    label(returned and '已安全带回的物品' or '本次未带回的物品',24,44,415,390,W.colors.ink,true)
    local quantities=returned and r.returnedCargo or r.lostCargo;local texts={};local resources=dm:getCSVByID(csvOfResourceInfo)or{}
    for id,item in pairs(quantities or{})do texts[#texts+1]=(resources[id] and resources[id].name or id)..' ×'..tostring(item.num)end;table.sort(texts)
    local pages=require('LuaClass/WarmActivities').textPages(#texts>0 and table.concat(texts,'  ·  ')or'没有物品记录',18,390,102)
    self.cargoPage=math.min(self.cargoPage or 1,#pages)
    local body=label(pages[self.cargoPage],18,44,382,390,W.colors.muted);body:setAnchorPoint(cc.p(0,1));body:setDimensions(cc.size(390,104))
    if #pages>1 then
     button('上一页',128,250,154,34,function()self.cargoPage=math.max(1,self.cargoPage-1);self:refresh()end,false,nil,self.cargoPage>1)
     button('下一页',352,250,154,34,function()self.cargoPage=math.min(#pages,self.cargoPage+1);self:refresh()end,false,nil,self.cargoPage<#pages)
    end
    label('记录于航程结束时',15,44,219,390,W.colors.muted)
    button('返回航程记录',240,145,414,58,function()self.logDetail=nil;self:refresh()end,false,'log');return
   end
   if total==0 then
    card(22,239,436,412);add(W.icon('log',110),185,470)
    label('下一段航程，从这里记起',26,48,424,390,W.colors.ink,true)
    label('结束一次航程，这里就会记下你的选择、收获与归航结果。',20,48,336,382,W.colors.muted)
   else
    self.page=math.min(self.page,math.max(1,math.ceil(total/3)))
    for i=(self.page-1)*3+1,math.min(self.page*3,total)do
     local r=logs[i];local y=486-((i-1)%3)*139;card(22,y,436,128)
     local voyage=r.voyage or r.voyageId or '?'
     label('第 '..tostring(voyage)..' 次航程',23,42,y+94,382,W.colors.ink,true)
     local success=r.outcome=='success' or r.outcome=='returned' or r.success==true
     label(success and '已安全归航' or '本次航程已结束',18,42,y+59,382,success and W.colors.sea or W.colors.muted,true)
     local choice=r.event and r.event.choice or r.choice
     local text=not success and '这一程没能安全带回物品。' or (r.summary or (choice=='rescue' and '救起幸存者，平安回到港口。' or (choice=='supply' and '回收沉船物资，平安回港。' or (choice=='chart' and '抢救残骸航图，安全带回港口。' or (choice=='supplies' and '回收残骸货箱，平安回港。' or '带着这一程的收获回到港口。')))))
     label(text,16,42,y+26,284,W.colors.muted)
     button('详情',399,y+44,76,48,function()self.logDetail=i;self.cargoPage=1;self:refresh()end,false)
    end
    if total>3 then
     button('上一页',104,173,154,43,function()self.page=math.max(1,self.page-1);self:refresh()end,false,nil,self.page>1)
     label(self.page..' / '..math.ceil(total/3),16,213,173,75,W.colors.muted)
     button('下一页',376,173,154,43,function()self.page=math.min(math.ceil(total/3),self.page+1);self:refresh()end,false,nil,self.page<math.ceil(total/3))
    end
   end
   button('查看收藏',128,61,208,58,function()self:showTab('collection')end,false,'chest')
   button('航线线索',352,61,208,58,function()close();require('LuaClass/WarmActivities').open('log',owner)end,true,'map');return
  end
  local entry=state.items and state.items[Memories.ITEM_ID]
  if not entry then
   card(22,225,436,423)
   add(W.icon('chest',116),182,456)
   label('第一件纪念物，等你带回',26,44,410,394,W.colors.ink,true)
   label('在新的航程中处理沉船事件，再安全归航，就能收藏一张航图残页。',20,47,328,385,W.colors.muted)
   label('未归航的发现不会提前入藏。',17,47,264,385,W.colors.muted)
   button('去准备出航',240,158,414,60,function()close();if type(owner.openPrimary)=='function'then owner:openPrimary()end end,true,'sail',type(owner.openPrimary)=='function')
  elseif self.preview then
   card(22,209,436,439)
   add(W.icon('map',142),169,443)
   label(self.preview=='remove' and '让展台暂时空着' or '把航图残页摆在甲板上',25,46,394,391,W.colors.ink,true)
   label(self.preview=='remove' and '收回后，航图残页仍保留在收藏中。' or '让这份航程纪念陪着你，迎接下一次出海。',20,46,321,391,W.colors.muted)
   local warning=state.displayId and '当前展台：航图残页' or '当前展台：空'
   label(warning,17,46,251,391,W.colors.muted)
   button('取消',125,148,196,59,function()self.preview=nil;self:refresh()end)
   button(self.preview=='remove' and '确认收回' or '确认摆放',354,148,196,59,function()
    local id=Memories.ITEM_ID;if self.preview=='remove' then id=nil end
    local ok,reason=Memories.setDisplay(dm,id)
    if not ok then ToastUtil:toastString('陈列未保存，请重试。原陈列保持不变。');return end
    self.preview=nil;self:refresh()
   end,true)
  else
   card(22,215,436,433)
   add(W.icon('map',152),164,462)
   label('沉船航图残页',30,49,420,385,W.colors.ink,true)
   label('第 '..tostring(entry.firstVoyage or entry.voyage or '?')..' 次航程 · 安全归航入藏',17,49,376,385,W.colors.muted)
   local story=entry.choice=='rescue' and '那天，你先救起了沉船旁的幸存者。这张残页留下了我们平安回来的记忆。' or (entry.choice=='chart' and '那天，你从旧船残骸中抢救了受潮航图。这张残页留下了我们平安回来的记忆。' or '那天，你从沉船旁回收了物资。这张残页留下了我们平安回来的记忆。')
   label(story,20,49,307,382,W.colors.muted)
   label('航程纪念物 · 永久收藏',16,49,237,382,W.colors.muted)
   button(state.displayId==Memories.ITEM_ID and '已摆放 · 收回珍藏' or '摆到船上',240,156,414,60,function()self.preview=state.displayId==Memories.ITEM_ID and 'remove' or 'place';self:refresh()end,true,'map')
  end
  button('航程记录',128,61,208,58,function()self:showTab('log')end,false,'log')
  button('查看库存',352,61,208,58,function()close();require('LuaClass/WarmActivities').open('collection',owner)end,false,'bag')
 end
 dm:registerEvent(Memories.KEY,eventKey,function()if not layer.closed then layer:refresh()end end)
 layer:refresh();return layer
end
return C
