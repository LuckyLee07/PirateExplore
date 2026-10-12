-- Clean harbor intelligence sheet. Presentation owns layout, scrolling and
-- gesture lifetime only; RandomEventLayer/Mission keep every transaction.
local W=require 'LuaClass/WarmTheme'
local P=require 'LuaClass/ProgressSupportPresentation'
local I={};local C=W.colors
local function label(parent,value,size,x,y,width,color,anchor)
 local n=W.label(value,size,color or C.ink,x,y,false,anchor or 0)
 if width then W.fit(n,width)end;parent:addChild(n,10);return n
end
local function panel(parent,w,h,color,x,y)
 local n=W.panel(w,h,color,8);n:setPosition(cc.p(x,y));parent:addChild(n,-10);return n
end
local function contains(node,point,w,h)
 local p=node:convertToNodeSpace(point);return p.x>=0 and p.y>=0 and p.x<=w and p.y<=h
end
local function visible(node)
 while node do if not node:isVisible()then return false end;node=node:getParent()end;return true
end
local function live(view)
 return view:getParent()~=nil and not view._dialogueClosing and not view.intelligenceSuspended and visible(view)
  and cc.Director:getInstance():getRunningScene()==view.intelligenceScene
end
-- Use the shared button face, but own its local input so a native Menu cannot
-- consume a drag, a cancellation, or a touch begun in a previous generation.
local function button(view,parent,title,w,h,x,y,primary,callback,guard,scroll)
 local control;local buildEpoch=view.intelligenceRenderGeneration
 local function allowed()
  return buildEpoch==view.intelligenceRenderGeneration and live(view) and control:getParent()~=nil and visible(control) and (not guard or guard())
 end
 control=W.button(title,w,h,function()if allowed()then callback()end end,{primary=primary,size=20})
 control:setPosition(cc.p(x,y));parent:addChild(control,20);control.menu:setEnabled(false)
 local item=control.item;local armed,start,offset,epoch
 local function reset()armed=false;start=nil;item:unselected()end
 local listener=cc.EventListenerTouchOneByOne:create();listener:setSwallowTouches(scroll==nil)
 local function inViewport(point)
  if not scroll then return true end
  local s=scroll:getViewSize();return contains(scroll,point,s.width,s.height)
 end
 listener:registerScriptHandler(function(touch)
  reset();local p=touch:getLocation()
  if not allowed()or not contains(item,p,w,h)or not inViewport(p)then return false end
  armed=true;start=p;epoch=view.intelligenceInputEpoch;offset=scroll and scroll:getContentOffset().y;item:selected();return true
 end,cc.Handler.EVENT_TOUCH_BEGAN)
 listener:registerScriptHandler(function(touch)
  local p=touch:getLocation()
  if armed and (math.abs(p.x-start.x)>8 or math.abs(p.y-start.y)>8)then reset()end
 end,cc.Handler.EVENT_TOUCH_MOVED)
 listener:registerScriptHandler(function(touch)
  local p=touch:getLocation()
  local use=armed and epoch==view.intelligenceInputEpoch and allowed() and contains(item,p,w,h) and inViewport(p)
  if scroll then use=use and math.abs(scroll:getContentOffset().y-offset)<1 end
  reset();if use then item:activate()end
 end,cc.Handler.EVENT_TOUCH_ENDED)
 listener:registerScriptHandler(reset,cc.Handler.EVENT_TOUCH_CANCELLED)
 item:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,item)
 control.resetIntelligencePress=reset;return control
end
local function rows()
 local out={}
 for _,event in ipairs(RandomEventManager:getInstance().eventList)do out[#out+1]={event=event}end
 for _,mission in ipairs(MissionManagers:getInstance():getAllMissions())do
  local start,time=mission:getMissionTimes()
  out[#out+1]={mission=mission,event=RandomEvent:create(RandomEvent.EventType.RandomEventMission,0,0,start,time,mission:getDescription())}
 end
 return out
end
local function rewardsText(mission)
 local parts={};for _,reward in ipairs(mission:getRewards())do parts[#parts+1]=tostring(reward.name)..' × '..tostring(reward.num)end
 return #parts>0 and ('奖励  '..table.concat(parts,' · '))or''
end
local names={'海上赌局','物资借用','天赋线索','海图出售','钥匙收购','航海任务'}
local symbols={'coins','bag','compass','map','chest','target'}
local function symbol(kind,size)
 if kind=='coins'then
  local node=cc.Node:create();node:setContentSize(cc.size(size,size))
  local art=W.sprite('Images/Icon/B/r_9.png',size,size)
  if art then art:setPosition(cc.p(size/2,size/2));node:addChild(art)end
  return node
 end
 if kind=='bag'or kind=='map'or kind=='chest'then return W.icon(kind,size)end
 return P.symbol(kind,size)
end
local function wrapped(value,width,size)
 local text=W.label(value,size,C.ink,0,0);text:setAnchorPoint(cc.p(0,1));text:setDimensions(cc.size(width,0))
 text:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT);text:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP);return text
end
function I.build(view,formatTime)
 local old=view.intelligenceScroll
 local oldDistance=old and (old:getContainer():getContentSize().height-old:getViewSize().height+old:getContentOffset().y)or 0
 view.intelligenceInputEpoch=(view.intelligenceInputEpoch or 0)+1
 view.intelligenceRenderGeneration=(view.intelligenceRenderGeneration or 0)+1
 if view.intelligenceCanvas then view.intelligenceCanvas:removeFromParent(true)end
 local viewport=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
 local width=math.min(560,viewport.width-32);local listWidth=width-32;local bodyWidth=listWidth-32
 local entries=rows();local total=0
 for _,entry in ipairs(entries)do
  entry.body=wrapped(tostring(entry.event.description or ''),bodyWidth,20)
  entry.reward=entry.mission and wrapped(rewardsText(entry.mission),bodyWidth,18)or nil
  entry.bodyHeight=entry.body:getContentSize().height
  entry.rewardHeight=entry.reward and math.max(22,entry.reward:getContentSize().height)or 0
  entry.height=66+entry.bodyHeight+24+entry.rewardHeight+82+16
  total=total+entry.height+12
 end
 local header,hero,footer=82,92,36
 local content=math.max(190,total)
 local height=math.min(viewport.height-32,header+hero+footer+content+16)
 local listHeight=height-header-hero-footer-16
 local root=cc.Node:create();root:setContentSize(cc.size(width,height))
 root:setPosition(cc.p(origin.x+(viewport.width-width)/2,origin.y+(viewport.height-height)/2));view:addChild(root)
 view.intelligenceCanvas=root;view.s_bg=root;view.s_size=cc.size(width,height);view.s_position=cc.p(root:getPositionX(),root:getPositionY())
 -- Cocos re-sorts equal-z nodes after later insertion. Keep the sheet below
 -- its header/ribbon explicitly, rather than depending on arrival order.
 panel(root,width,height,C.paper,0,0):setLocalZOrder(-30)
 panel(root,width,header,C.ink,0,height-header):setLocalZOrder(-20)
 label(root,'航海情报',28,20,height-29,width-112,C.paper)
 label(root,'海上传来的新消息',17,20,height-61,width-40,C.paper)
 view.intelligenceClose=button(view,root,'关闭',66,44,width-47,height-30,false,function()view:close()end)
 local ribbon=panel(root,listWidth,76,cc.c3b(229,239,218),16,height-header-hero+8)
 local art=symbol('map',62);art:setPosition(cc.p(10,7));ribbon:addChild(art,1)
 label(ribbon,#entries>0 and ('待处理 · '..#entries..' 条')or'海面风平浪静',21,86,49,listWidth-102,C.ink)
 label(ribbon,#entries>0 and '发现、任务与天赋线索'or'新的发现会记在这里',17,86,22,listWidth-102,C.muted)
 local container=cc.Layer:create();local scroll=cc.ScrollView:create(cc.size(listWidth,listHeight));scroll:setContainer(container)
 scroll:setPosition(cc.p(16,footer));scroll:setClippingToBounds(true);scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);scroll:setBounceable(false)
 root:addChild(scroll,2);view.intelligenceScroll=scroll;view.intelligenceRows={}
 local full=math.max(listHeight,total);container:setContentSize(cc.size(listWidth,full));scroll:setContentSize(cc.size(listWidth,full))
 local generation=view.warmIntelligenceGeneration;local scene=view.intelligenceScene
 local top=full
 for index,entry in ipairs(entries)do
  local event,mission=entry.event,entry.mission;local eventType=tonumber(event.type);local state=mission and mission:getMissionStatue()
  local row=cc.Node:create();row:setContentSize(cc.size(listWidth,entry.height));top=top-entry.height;row:setPosition(cc.p(0,top));container:addChild(row);top=top-12
  local binding={};row.warmIntelligenceBinding=binding;entry.node=row;view.intelligenceRows[index]=entry
  local function activeRow()
   local context=view.warmShortageContext
   if context and (context.owner.adventureDialog or context.gift)then return false end
   return live(view) and cc.Director:getInstance():getRunningScene()==scene
    and view.warmIntelligenceGeneration==generation and row.warmIntelligenceBinding==binding and row:getParent()~=nil
    and (mission and MissionManagers:getInstance().missions[mission.id]==mission and mission:getMissionStatue()==state and mission:checkTime()
     or not mission and view:isIntelligenceTargetActive(event))
  end
  panel(row,listWidth,entry.height,C.white,0,0)
  local mark=symbol(symbols[eventType]or'compass',38);mark:setPosition(cc.p(14,entry.height-52));row:addChild(mark,2)
  label(row,names[eventType]or'海上消息',21,62,entry.height-27,listWidth-78)
  entry.timeLabel=label(row,'',16,62,entry.height-50,listWidth-78,C.muted)
  entry.body:setPosition(cc.p(16,entry.height-68));row:addChild(entry.body,10)
  if entry.reward then entry.reward:setColor(C.sea);entry.reward:setPosition(cc.p(16,entry.height-68-entry.bodyHeight-14));row:addChild(entry.reward,10)end
  local secondary,primary='取消',({[1]='参与赌局',[2]='借出物资',[4]='购买海图',[5]='出售钥匙'})[eventType]or'确定';local leftCost,rightCost='',''
  if eventType==RandomEvent.EventType.RandomEventTalent then
   local talent=DataManager:getInstance():getCSVByID(csvOfTalent)[tostring(event.talentId)]
   secondary,primary='金币学习','钻石学习';leftCost='金币 × '..talent.resumeCoin;rightCost='钻石 × '..talent.resumeNum
  elseif mission then
   secondary='放 弃';primary=state=='complete'and'领 奖'or'一键完成'
   rightCost=state=='complete'and'任务已完成'or('钻石 × '..tostring(mission:getCosts()))
  end
  local actionWidth=(bodyWidth-12)/2;local leftX=16+actionWidth/2;local rightX=listWidth-16-actionWidth/2
  label(row,leftCost,17,leftX,86,actionWidth,C.muted,.5);label(row,rightCost,17,rightX,86,actionWidth,state=='complete'and C.sea or C.muted,.5)
  local function secondaryAction()
   if RandomEventLayer.instance then
    if tonumber(event.type) == RandomEvent.EventType.RandomEventTalent then
     if not RandomEventLayer.instance:handleEvent(event, 1) then
      RandomEventManager:getInstance():removeEvent(event)
      view.tableview1:reloadData()
     end
    elseif tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
     MissionManagers:getInstance():giveUpTheMission(mission)
     view.tableview1:reloadData()
    else
     RandomEventManager:getInstance():removeEvent(event)
     view.tableview1:reloadData()
    end
   end
  end
  local function primaryAction()
   if RandomEventLayer.instance then
    if tonumber(event.type) == RandomEvent.EventType.RandomEventTalent then
     if not RandomEventLayer.instance:handleEvent(event, 2, view:intelligencePresentation(event)) then
      RandomEventManager:getInstance():removeEvent(event)
      view.tableview1:reloadData()
     end
    elseif tonumber(event.type) == RandomEvent.EventType.RandomEventMission then
     if mission:getMissionStatue() == "wait" then
      mission:completedMissionByCosted(view:intelligencePresentation(event,mission))
     elseif mission:getMissionStatue() == "complete" then
      mission:receive()
     end
     view.tableview1:reloadData()
    else
     if not RandomEventLayer.instance:handleEvent(event) then
      RandomEventManager:getInstance():removeEvent(event)
      view.tableview1:reloadData()
     end
    end
   end
  end
  entry.secondary=button(view,row,secondary,actionWidth,48,leftX,44,false,secondaryAction,activeRow,scroll)
  entry.primary=button(view,row,primary,actionWidth,48,rightX,44,true,primaryAction,activeRow,scroll)
 end
 if #entries==0 then
  local art=symbol('map',100);art:setPosition(cc.p((listWidth-100)/2,full/2-20));container:addChild(art)
  label(container,'继续探索，寻找新的线索',19,listWidth/2,full/2-48,listWidth-28,C.muted,.5)
 end
 scroll:setContentOffset(cc.p(0,math.min(0,listHeight-full+math.max(0,oldDistance))));scroll:setTouchEnabled(full>listHeight)
 view.intelligenceScrollHint=label(root,full>listHeight and '上下滑动查看 · 操作在每条情报下方'or'关闭后仍可从天赋与成就查看',16,width/2,17,width-32,C.muted,.5)
 view.intelligenceUpdateTimes=function()
  for _,entry in ipairs(view.intelligenceRows)do
   -- The original TableView's timer refresh lets the mission manager remove
   -- expired waiting missions. Keep that model-owned cleanup, including its
   -- own game clock, without retaining a clickable expired source row.
   if entry.mission and not entry.mission:checkTime()then view.tableview1:reloadData();return end
   local event=entry.event;local state=entry.mission and entry.mission:getMissionStatue()
   local now=entry.mission and NotificationNode:getInstance():GetGameTime()or os.time()
   local text=state=='complete'and'已完成 · 等待领奖'or(tonumber(event.lifeTime)==-1 and'探索中 · 无时间限制'or('剩余 '..formatTime(event.lifeTime-(now-event.startTime))))
   entry.timeLabel:setString(text);W.fit(entry.timeLabel,listWidth-78)
  end
 end
 view.intelligenceUpdateTimes()
end
function I.mount(view,formatTime)
 view.intelligenceScene=cc.Director:getInstance():getRunningScene()
 if view.intelligenceLifecycle then view.intelligenceLifecycle:removeFromParent(true)end
 view.intelligenceSuspended=false;view.intelligenceRetired=false
 local lifetime=cc.Node:create();view.intelligenceLifecycle=lifetime
 lifetime:registerScriptHandler(function(event)
  if event=='exit'or event=='cleanup'then
   if event=='cleanup'then view.intelligenceRetired=true end
   view.intelligenceSuspended=true;view.intelligenceInputEpoch=(view.intelligenceInputEpoch or 0)+1
   for _,entry in ipairs(view.intelligenceRows or {})do entry.primary.resetIntelligencePress();entry.secondary.resetIntelligencePress()end
  elseif event=='enter'then view.intelligenceSuspended=false end
 end)
 view:addChild(lifetime)
 -- Preserve the public list-refresh contract used by random-event producers,
 -- the expiry loop, and the original successful transaction callbacks.
 view.tableview1={reloadData=function()
  -- The legacy producer retains RandomEventView.instance after dismissal.
  -- Never rebuild disposed native nodes through that public refresh handle.
  if view.intelligenceRetired or view.intelligenceSuspended or view._dialogueClosing or not view:getParent()then return end
  I.build(view,formatTime)
 end}
 I.build(view,formatTime)
 view:scheduleUpdateWithPriorityLua(function()view:update();if view.intelligenceUpdateTimes then view.intelligenceUpdateTimes()end end,0)
 return true
end
return I
