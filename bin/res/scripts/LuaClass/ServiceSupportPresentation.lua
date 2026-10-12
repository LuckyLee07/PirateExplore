-- Explicit Warm service/reward presentation. No request, spend or reward logic.
local W=require 'LuaClass/WarmTheme'
local P=require 'LuaClass/ProgressSupportPresentation'
local S={label=P.label,rule=P.rule,move=P.move}
S.chestPath='Images/UI/CleanVoyage/Support/reward-chest-clean-v1.png'
function S.art(parent,kind,x,y,size)
 local n
 if kind=='chest'then n=W.sprite(S.chestPath,size,size)
 elseif kind=='hourglass'then n=W.sprite('Images/UI/CleanVoyage/Support/hourglass-clean-v1.png',size,size)
 elseif kind=='coins'then n=W.sprite('Images/Icon/B/r_9.png',size,size)
 elseif kind=='medal'then n=W.sprite('Images/UI/CleanVoyage/Support/ranking-medal-clean-v1.png',size,size)
 else n=P.symbol(kind,size);n:setAnchorPoint(cc.p(.5,.5))end
 if n then
  if n.getTexture and n:getTexture()then n:getTexture():setAntiAliasTexParameters()end
  n:setPosition(cc.p(x,y));parent:addChild(n)
 end;return n
end
function S.mount(view,title,subtitle)
 local legacy=cc.Node:create();local children=view:getChildren();view:addChild(legacy);legacy:setVisible(false)
 for _,n in ipairs(children)do P.move(n,legacy)end
 view.serviceLegacy=legacy;view.serviceWarm=true
 local shell=view:applyCoherentPageShell(title,subtitle,function()zqDispatch:backToLastView()end)
 shell.back.label:setString('返回')
 local owner=cc.Node:create();shell.canvas:addChild(owner)
 owner:registerScriptHandler(function(event)if event=='exit'or event=='cleanup'then view:destory(event)end end)
 return shell
end
function S.canvas(view)
 local size=cc.Director:getInstance():getVisibleSize();local origin=cc.Director:getInstance():getVisibleOrigin()
 local k=math.min(size.width/480,size.height/800)
 local root=cc.Node:create();root:setContentSize(cc.size(480,800));root:setScale(k)
 root:setPosition(cc.p(origin.x+(size.width-480*k)/2,origin.y+(size.height-800*k)/2));view:addChild(root)
 view.serviceCanvas=root;view.serviceWarm=true;return root
end
function S.sheet(view,title,subtitle,kind)
 local root=S.canvas(view);local paper=W.panel(448,624,W.colors.paper,8);paper:setPosition(cc.p(16,88));root:addChild(paper,-2)
 local band=W.panel(448,94,W.colors.ink,0);band:setPosition(cc.p(16,618));root:addChild(band,-1)
 S.label(root,title,29,40,677,352,W.colors.paper)
 S.label(root,subtitle,17,40,641,400,W.colors.paper)
 if kind~=false then S.art(root,kind or 'chest',240,521,148)end
 local close=W.button('关闭',76,42,function()view:close()end,{size=17});close:setPosition(cc.p(397,677));root:addChild(close)
 view.serviceClose=close;return root
end
function S.entry(view,opts)
 local root=S.sheet(view,opts.title,opts.subtitle,opts.art)
 S.label(root,opts.hint,20,240,419,384,W.colors.ink,.5)
 local field=W.panel(376,64,W.colors.white,6);field:setPosition(cc.p(52,326));root:addChild(field,-1)
 local input=ccui.TextField:create();input:setMaxLengthEnabled(true);input:setMaxLength(opts.maxLength)
 input:setTouchEnabled(true);input:setFontName(W.font);input:setFontSize(23);input:setColor(W.colors.ink)
 input:setPlaceHolder(opts.placeholder);input:setTouchSize(cc.size(376,64));input:setPosition(cc.p(240,358));root:addChild(input)
 view.textField=input
 view.serviceStatus=S.label(root,opts.status or '',17,240,287,376,W.colors.muted,.5)
 view.serviceStatus:setDimensions(cc.size(376,64));view.serviceStatus:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
 local cancel=W.button('取消',170,52,function()view:close()end,{size=20});cancel:setPosition(cc.p(141,177));root:addChild(cancel)
 local submit=W.button(opts.submit or '确定',170,52,opts.callback,{size=20,primary=true});submit:setPosition(cc.p(339,177));root:addChild(submit)
 view.submitButton=submit.item;view.serviceSubmit=submit;view.serviceCancel=cancel
 return true
end
function S.rowAction(text,scroll,callback)
 require 'LuaClass/SDButton'
 local button=SDButton:create('Images/btn/ann03_a.png','Images/btn/ann03_b.png',callback)
 button.normalSpr:removeFromParent();button.selectSpr:removeFromParent()
 button.normalSpr=W.panel(90,46,W.colors.paper,6);button.selectSpr=W.panel(90,46,W.colors.line,6);button.selectSpr:setVisible(false)
 button:addChild(button.normalSpr);button:addChild(button.selectSpr);button:setContentSize(cc.size(90,46));button:setSwallowTouches(false)
 button.label=S.label(button,text,18,45,23,76,W.colors.ink,.5);P.clip(button,scroll);return button
end
function S.scroll(parent,x,y,width,height)
 local container=cc.Layer:create();local scroll=cc.ScrollView:create(cc.size(width,height));scroll:setContainer(container)
 scroll:setPosition(cc.p(x,y));scroll:setClippingToBounds(true);scroll:setBounceable(false);scroll:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
 parent:addChild(scroll);return scroll,container
end
-- Keep the actual AlertView OK_CANCEL handlers and mask. Only its surfaces
-- are hidden; clean actions activate those original native MenuItems.
function S.itemKind(record)
 local resume=record and record[dataKeyResume]
 if not resume then return false end
 if resume[1]=='2' or resume[1]=='4' then return 'hourglass' end
 if resume[1]=='3' and resume[2]=='2005' then return 'lightning' end
 if resume[1]=='3' and resume[2]=='2003' then return 'food' end
 if resume[1]=='7' then return 'coins' end
 -- Portal, return-scroll, dragon and pure-diamond art still require exact
 -- approved family props. A generic badge/crew/chest would change the meaning.
 return false
end
function S.retireConfirmation(alert)
 -- An owner may be removed alone or inside a scene traversal. Disable the
 -- sibling immediately; defer structural removal until after that traversal.
 -- Scene cleanup cancels this action when it reaches the alert itself.
 alert:invalidateServiceConfirmation()
 alert:setVisible(false)
 alert:getEventDispatcher():removeEventListenersForTarget(alert,true)
 alert:runAction(cc.Sequence:create(cc.DelayTime:create(0),cc.CallFunc:create(function()
  alert:removeFromParent(true)
 end)))
end
local function decorateConfirmation(alert,title,subtitle,body,artKind,cancelCallback,confirmCallback)
 alert.s_bg:setVisible(false)
 local root=S.sheet(alert,title,subtitle,artKind)
 local viewHeight=artKind==false and 300 or 158
 local scroll,container=S.scroll(root,48,259,384,viewHeight)
 local text=S.label(container,body,20,0,0,nil,W.colors.ink);text:setAnchorPoint(cc.p(0,1));text:setDimensions(cc.size(384,0));text:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
 local height=math.max(viewHeight,text:getContentSize().height);text:setPositionY(height);container:setContentSize(cc.size(384,height));scroll:setContentSize(cc.size(384,height));scroll:setContentOffset(cc.p(0,viewHeight-height))
 local cancel=W.button('取消',170,52,cancelCallback,{size=20});cancel:setPosition(cc.p(141,177));root:addChild(cancel)
 local confirm=W.button('购买',170,52,confirmCallback,{size=20,primary=true});confirm:setPosition(cc.p(339,177));root:addChild(confirm)
 alert.serviceConfirm=confirm;alert.serviceCancel=cancel;alert.serviceDescription=scroll
end
function S.confirm(owner,title,subtitle,body,onConfirm,artKind)
 if owner.serviceAlert then return nil end
 local resolved=false;local alert
 alert=AlertView:create(2,0,title,function()
  if resolved then return end;resolved=true
  if owner.serviceAlert==alert then owner.serviceAlert=nil end
  onConfirm()
 end,function()
  if resolved then return end;resolved=true
  if owner.serviceAlert==alert then owner.serviceAlert=nil end
 end,'取消','购买')
 owner.serviceAlert=alert
 local controls={}
 for _,child in ipairs(alert.s_bg:getChildren())do
  if tolua.type(child)=='cc.Menu'then for _,item in ipairs(child:getChildren())do controls[#controls+1]=item end end
 end
 table.sort(controls,function(a,b)return a:getPositionX()<b:getPositionX()end)
 assert(#controls==2,'service confirmation retains original AlertView two-button contract')
 alert.close=function()if resolved then return end;controls[1]:activate()end
 decorateConfirmation(alert,title,subtitle,body,artKind,alert.close,function()if not resolved then controls[2]:activate()end end)
 alert.invalidateServiceConfirmation=function()
  resolved=true;if owner.serviceAlert==alert then owner.serviceAlert=nil end
 end
 alert:registerScriptHandler(function(event)
  if event=='exit' or event=='cleanup'then alert:invalidateServiceConfirmation()end
 end)
 return alert
end
-- Virtual goods originally use dtype=0 with manually owned OK/Cancel actions,
-- unlike gift dtype=2. Preserve its early-failure stay-open behavior.
function S.virtualConfirm(owner,title,subtitle,body,onConfirm,artKind)
 if owner.serviceAlert then return nil end
 local closed,attempted=false,false
 local alert=AlertView:create(0,0,title,'',nil)
 owner.serviceAlert=alert
 alert.close=function()if not closed then alert.closeBtn.onSingleCLick()end end
 decorateConfirmation(alert,title,subtitle,body,artKind,alert.close,function()
  if closed or attempted then return end
  attempted=true
  local close=onConfirm()
  if close~=false then alert:removeFromParent()
  else alert.serviceConfirm.item:setEnabled(false)end
 end)
 alert.invalidateServiceConfirmation=function()
  closed=true;if owner.serviceAlert==alert then owner.serviceAlert=nil end
 end
 alert:registerScriptHandler(function(event)
  if event=='exit' or event=='cleanup'then alert:invalidateServiceConfirmation()end
 end)
 return alert
end
return S
