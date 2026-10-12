-- Explicit Warm presentation for Talent/Achievement. No reward or save ownership.
local W=require 'LuaClass/WarmTheme'
local P={};local serial=0
function P.open(view)return not view.supportDisposed and not view.coherentPageLeaving and not view.adventureDialog end
function P.move(node,parent)
 node:retain();node:removeFromParent(false);parent:addChild(node);node:release()
end
function P.label(parent,text,size,x,y,width,color,anchor)
 local n=W.label(text,size,color or W.colors.ink,x,y,false,anchor or 0)
 if width then W.fit(n,width)end;parent:addChild(n);return n
end
function P.rule(parent,y,width)
 local d=cc.DrawNode:create();d:drawSegment(cc.p(0,y),cc.p(width or 416,y),.5,HomeTheme.rgba(W.colors.line));parent:addChild(d);return d
end
-- Namespaced generated game props. Explicit texture rectangles keep semantic
-- identities stable without replacing any packed asset or gameplay item icon.
P.artPath='Images/UI/CleanVoyage/Support/progress-props-v1.png'
P.artRects={compass={26,2,388,402},medal={473,39,310,370},alchemy={879,20,365,381},
 target={40,431,395,391},feather={458,454,356,353},food={870,430,375,387},
 lightning={68,830,285,402},scout={440,880,389,307},badge={856,830,378,384}}
function P.symbol(kind,size)
 local root=cc.Node:create();root:setContentSize(cc.size(size,size))
 local box=P.artRects[kind]or P.artRects.badge
 local sprite=cc.Sprite:create(P.artPath,cc.rect(unpack(box)))
 if sprite then
  sprite:setScale(math.min(size/box[3],size/box[4]));sprite:setPosition(cc.p(size/2,size/2))
  sprite:getTexture():setAntiAliasTexParameters();root:addChild(sprite)
 end
 return root
end
function P.listen(view,keys,callback)
 serial=serial+1;view.supportListenerName='progressSupport'..serial;view.supportSubscriptions={}
 local dm=DataManager:getInstance()
 for _,key in ipairs(keys)do
  local fn=function()if not view.supportDisposed then callback(key)end end
  view.supportSubscriptions[#view.supportSubscriptions+1]={key=key,callback=fn}
  dm:registerEvent(key,view.supportListenerName,fn)
 end
end
function P.dispose(view)
 if view.supportDisposed then return false end
 view.supportDisposed=true
 local dm=DataManager:getInstance()
 for _,entry in ipairs(view.supportSubscriptions or {})do
  dm:unregisterEvent(entry.key,view.supportListenerName)
  -- DataManager removes the native handle but retains the closure alias. Only
  -- remove this instance's alias, never another page's or a gameplay listener.
  local bucket=dm.__eventListener and dm.__eventListener[entry.key]
  if bucket and bucket[view.supportListenerName]==entry.callback then bucket[view.supportListenerName]=nil end
 end
 view.supportSubscriptions={}
 if view.adventureDialog then view.adventureDialog:close()end
 for _,n in ipairs({view.setBtn,view.setBtn and view.setBtn.normalSpr,view.setButtonProgrees,view.supportAlchemyStatus})do if n then n:stopAllActions()end end
 return true
end
function P.mount(view,title,subtitle)
 view.supportDisposed=false
 -- Build the exact BaseView controller before adapting its presentation.
 view:addInfoNode(nil,nil,nil,function()zqDispatch:moveToExpedition()end,
  'Images/MainMenu/an_lianj_a.png','Images/MainMenu/an_lianj_b.png',
  function()DataManager:getInstance():AlchemyButtonDidClick()end,nil,true,zqAlchemyTime,false)
 local children=view:getChildren();local legacy=cc.Node:create();view:addChild(legacy);legacy:setVisible(false)
 for _,child in ipairs(children)do P.move(child,legacy)end;view.supportLegacy=legacy
 local shell=view:applyCoherentPageShell(title,subtitle,function()zqDispatch:backToLastView()end)
 shell.back.label:setString('返回');view.supportWarm=true;view.alchemyReceiptHost=shell.canvas
 local canvas=shell.canvas;local button=view.setBtn;P.move(button,canvas)
 local w,h=150,54
 for _,sprite in ipairs({button.normalSpr,button.selectSpr})do
  local size=sprite:getContentSize();sprite:setScaleX(w/size.width);sprite:setScaleY(h/size.height);sprite:setOpacity(0)
 end
 -- Retain both original sprite handles, listener and repeat scheduler.
 button:setContentSize(cc.size(w,h));button:addClickArea(cc.rect(0,0,0,0));button:setPosition(cc.p(373,169));button:setSwallowTouches(false)
 local face=W.panel(w,h,W.colors.sea,8);button:addChild(face,-1)
 P.label(button,'炼金',23,w/2,h/2,w-20,W.colors.white,.5)
 local click,hold=button.onSingleCLick,button.onLongPressed
 button:registerSingleCLick(function()if P.open(view) and button.bIsEnable then click()end end)
 if hold then button:registerLongPressed(function()if P.open(view) and button.bIsEnable then hold()end end)end
 view.setButtonProgrees:setVisible(false)
 local flask=P.symbol('alchemy',78);flask:setPosition(cc.p(25,144));canvas:addChild(flask)
 P.label(canvas,'炼金',22,114,216,178)
 view.supportAlchemyYield=P.label(canvas,'',18,114,181,178,W.colors.muted)
 view.supportAlchemyStatus=P.label(canvas,'',17,114,149,178,W.colors.muted)
 view.supportCooldown=cc.DrawNode:create();view.supportCooldown:setPosition(cc.p(32,122));canvas:addChild(view.supportCooldown)
 local function refresh()
  if view.supportDisposed then return end
  local unit=DataManager:getInstance():getRoleData(roleAlchemyUnit)
  view.supportAlchemyYield:setString(unit~=nil and ('每次获得 '..tostring(unit)..' 金币')or'点按获得金币');W.fit(view.supportAlchemyYield,178)
  local text=not button.bIsEnable and '正在准备炼金…' or (not view.bIsCenterBtnCanClick and '炼金中…' or (button.onLongPressed and '可长按连续炼金' or '点按炼金'))
  view.supportAlchemyStatus:setString(text)
  local d=view.supportCooldown;d:clear();d:drawSegment(cc.p(0,0),cc.p(416,0),1.5,HomeTheme.rgba(W.colors.line))
  if not view.bIsCenterBtnCanClick then d:drawSegment(cc.p(0,0),cc.p(416*view.setButtonProgrees:getPercentage()/100,0),1.5,HomeTheme.rgba(W.colors.sea))end
 end
 refresh();schedule(view.supportAlchemyStatus,refresh,.1);view.refreshSupportAlchemy=refresh
 local token=cc.Node:create();canvas:addChild(token)
 token:registerScriptHandler(function(event)if event=='exit' or event=='cleanup'then view:destory()end end)
 return shell
end
function P.scroll(view,y,height)
 local container=cc.Layer:create();local scroll=cc.ScrollView:create(cc.size(416,height))
 scroll:setContainer(container);scroll:setPosition(cc.p(32,y));scroll:setClippingToBounds(true)
 scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);scroll:setBounceable(false)
 view.coherentShell.canvas:addChild(scroll);view.scrollView=scroll;view.scrollViewContainer=container
 view.supportListHeight=height;return scroll
end
function P.rows(view,heights,build)
 local scroll,container=view.scrollView,view.scrollViewContainer
 local oldHeight=container:getContentSize().height;local oldOffset=scroll:getContentOffset().y
 local total=0;for _,h in ipairs(heights)do total=total+h end;total=math.max(view.supportListHeight,total)
 container:removeAllChildren();local top=total
 for i,h in ipairs(heights)do top=top-h;local row=build(i,h);row:setPosition(cc.p(0,top));container:addChild(row)end
 container:setContentSize(cc.size(416,total));scroll:setContentSize(cc.size(416,total))
 local min=view.supportListHeight-total;local offset=oldHeight==total and math.max(min,math.min(0,oldOffset))or min
 scroll:setContentOffset(cc.p(0,offset));scroll:setTouchEnabled(total>view.supportListHeight)
end
-- SDButton remains the informational action; cancel taps when the list moves.
function P.clip(button,scroll)
 local began,moved,ended=button.onTouchBegan,button.onTouchMoved,button.onTouchEnded
 local active,start,offset=false,nil,nil
 local function cancel(self)
  active=false;self.isTouch=false;self.isMoved=true;self.m_longProgress=false;self.pressTimes=0;self.touchCounts=0
  self.normalSpr:stopAllActions();self:setActive(false)
 end
 local function valid(point)
  local s=scroll:getViewSize();local current=scroll:getContentOffset()
  return cc.rectContainsPoint(cc.rect(0,0,s.width,s.height),point) and (not start or
   ((point.x-start.x)^2+(point.y-start.y)^2<=64 and math.abs(current.y-offset.y)<=1 and math.abs(current.x-offset.x)<=1))
 end
 button.onTouchBegan=function(self,touch,event)
  start=nil;local point=scroll:convertToNodeSpace(touch:getLocation());if not valid(point)then return false end
  active=began(self,touch,event);if active then start=point;offset=scroll:getContentOffset()end;return active
 end
 button.onTouchMoved=function(self,touch,event)
  if not active then return end
  if not valid(scroll:convertToNodeSpace(touch:getLocation()))then cancel(self);return end
  return moved(self,touch,event)
 end
 button.onTouchEnded=function(self,touch,event)
  if not active then return end
  if not valid(scroll:convertToNodeSpace(touch:getLocation()))then cancel(self);return end
  active=false;return ended(self,touch,event)
 end
 button.onTouchCancelled=function(self)cancel(self)end
 button.listener:registerScriptHandler(function()cancel(button)end,cc.Handler.EVENT_TOUCH_CANCELLED)
end
function P.information(view,title,text)
 if not P.open(view)then return end
 local modal=require('LuaClass/WarmDialog').show(title,text,{{label='知道了'}},view)
 local panel=modal:getChildren()[1];local body
 for _,n in ipairs(panel:getChildren())do if n.getString and n:getString()==text then body=n;break end end
 if body then
  local k=cc.Director:getInstance():getVisibleSize().width/640;local width=panel:getContentSize().width-48*k;local height=132*k
  local container=cc.Layer:create();P.move(body,container);body:setDimensions(cc.size(width,0));body:setFontSize(22*k)
  local full=math.max(height,body:getContentSize().height);body:setPosition(cc.p(0,full));container:setContentSize(cc.size(width,full))
  local scroll=cc.ScrollView:create(cc.size(width,height));scroll:setContainer(container);scroll:setContentSize(cc.size(width,full))
  scroll:setPosition(cc.p(24*k,panel:getContentSize().height-217*k));scroll:setClippingToBounds(true);scroll:setBounceable(false)
  scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL);scroll:setContentOffset(cc.p(0,height-full));panel:addChild(scroll)
  modal.supportDescription=scroll;modal.supportDetailText=text
 end
 return modal
end
return P
