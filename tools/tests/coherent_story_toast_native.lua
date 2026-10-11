-- Real Cocos/EGL story, startup and notification presentation verification.
-- Uses packaged plot CSV/assets/fonts and real native actions/MenuItem activation.
-- Only Director viewport/scene routing and read-only DataManager are fixtures;
-- no player profile, save, native desktop, network or economy is initialized.
require 'extern';require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true;printn=function()end
package.loaded['LuaClass/DataManager']=true
package.loaded['LuaClass/NotificationNode']=true
local failures={};local checks=0
local function check(v,message)checks=checks+1;if not v then failures[#failures+1]=message;print('FAIL '..message)end;return v end
local function equal(a,b,message)return check(a==b,message..' ['..tostring(a)..' ~= '..tostring(b)..']')end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local first=assert(source:find('local function readFile(path)',1,true))
local last=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",first,true))
local csv=assert(loadstring('local equal=function(a,b)assert(a==b)end\n'..source:sub(first,last-1)..'\nreturn packagedCSV','@coherent-story-native-csv'))()
local plots=csv('plot')
for _,row in pairs(plots)do local story={};for line in (row.story..';'):gmatch('(.-);')do story[#story+1]={line}end;row.story=story end
local dataReads=0
DataManager={getInstance=function()return{getCSVByID=function(_,key)equal(key,csvOfPlot,'only plot CSV requested');dataReads=dataReads+1;return plots end,
 setRoleData=function()error('presentation must not mutate player data')end}end}
local realGet=cc.Director.getInstance;local director=realGet(cc.Director);local actions=director:getActionManager()
local viewport,scene,notification;local replacements={};local retired={}
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,getWinSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end,getNotificationNode=function()return notification end,
 replaceScene=function(_,nextScene)retired[#retired+1]=scene;scene=nextScene;scene:retain();replacements[#replacements+1]=scene end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local W=require 'LuaClass/WarmTheme';local S=require 'LuaClass/StartupTheme'
require 'LuaClass/PlotMode';require 'LuaClass/ToastUtil'
local function visit(n,fn)fn(n);for _,child in ipairs(n:getChildren())do visit(child,fn)end end
local function bounds(n)local z=n:getContentSize();local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(z.width,z.height));return{left=a.x,bottom=a.y,right=b.x,top=b.y}end
local function within(n,context,minimumY)local b=bounds(n);return check(b.left>=-.1 and b.right<=viewport.width+.1 and b.bottom>=(minimumY or 0)-.1 and b.top<=viewport.height+.1,
 context..string.format(' bounds [%.1f %.1f %.1f %.1f]',b.left,b.bottom,b.right,b.top))end
local function dispose(n)if n then n:cleanup();n:release()end end
local function drainRetired()for _,n in ipairs(retired)do dispose(n)end;retired={}end
local function advance(seconds,inspect)
 for _=1,math.ceil(seconds/.025)do
  if scene then visit(scene,function(n)actions:resumeTarget(n)end)end
  if notification then visit(notification,function(n)actions:resumeTarget(n)end)end
  actions:update(.025);drainRetired();if inspect then inspect()end
 end
end
local function skip(root)local result;visit(root,function(n)if n.getString and n:getString()=='下一幕  ›' and n:getParent().activate then result=n:getParent()end end);return result end
local function body(root)local out={};visit(root,function(n)if n.getFontSize and n:getFontSize()==25 and n:getFontName()==W.font then out[#out+1]=n end end);return out end
local function assertStoryGeometry(id,mode)
 local context=mode..' '..viewport.width..'x'..viewport.height..' scene '..id
 local menu=assert(skip(scene),'clean native skip must exist')
 equal(menu:getContentSize().width,154,context..' skip width');equal(menu:getContentSize().height,58,context..' skip height');within(menu,context..' skip')
 local b=bounds(menu)
 local seen={};local narrativeTop=0
 for _,label in ipairs(body(scene))do
  seen[label:getString()]=true;within(label,context..' narrative '..label:getString())
  local l=bounds(label);narrativeTop=math.max(narrativeTop,l.top)
  local measured=cc.LabelTTF:create(label:getString(),W.font,25)
  check(measured:getContentSize().width<=viewport.width-64,context..' full sentence fits one line: '..label:getString())
  check(l.right<=b.left or l.left>=b.right or l.bottom>=b.top or l.top<=b.bottom,context..' narrative does not intersect Next button: '..label:getString())
  equal(label:getFontName(),W.font,context..' narrative font')
 end
 for _,row in ipairs(plots[tostring(id)].story)do check(seen[row[1]],context..' original text present '..row[1])end
 -- Original plot art is retained as a scaled vignette, not replaced by UI art.
 local base
 for _,child in ipairs(scene:getChildren())do if child:getLocalZOrder()==0 and child:getChildrenCount()>0 and not child.getString then base=child;break end end
 check(base~=nil,context..' narrative art root')
 if base then
  for _,group in ipairs(base:getChildren())do
   if not group.getString then for _,art in ipairs(group:getChildren())do if art.getTexture then within(art,context..' story art');check(bounds(art).bottom>=narrativeTop+8,context..' art clears narrative text by eight pixels')end end end
  end
 end
end
for _,z in ipairs({{480,800},{640,1136}})do
 viewport=cc.size(z[1],z[2]);local caption=z[1]..'x'..z[2]
 -- Same packaged startup world/ship and real CJK title, retaining loading footer.
 scene=cc.Scene:create();scene:retain();local bg=S.background(viewport);bg:setPosition(viewport.width/2,viewport.height/2);scene:addChild(bg)
 equal(bg:getChildrenCount(),2,caption..' startup world and footer');equal(bg:getChildren()[1]:getChildrenCount(),3,caption..' clean sea/harbor/boat')
 local title=S.title();title:setPosition(viewport.width/2,viewport.height-80);scene:addChild(title);within(title,caption..' startup title');equal(title:getFontName(),W.font,caption..' startup font')
 local ship=S.ship();scene:addChild(ship);check(ship:getChildrenCount()==1,caption..' loading ship marker')
 local footer=bg:getChildren()[2];equal(footer:getContentSize().height,240,caption..' opaque footer height');dispose(scene);scene=nil
 for id=1,7 do
  local callbacks=0;scene=assert(PlotScene:create(id,function()callbacks=callbacks+1 end));scene:retain()
  -- All original narrative lines must exist before natural completion.
  advance(tonumber(plots[tostring(id)].stayTime)+.6);assertStoryGeometry(id,'natural')
  equal(callbacks,0,caption..' scene '..id..' original final pause retained')
  advance(3);equal(callbacks,1,caption..' scene '..id..' natural callback exactly once');advance(2);equal(callbacks,1,caption..' scene '..id..' no repeat natural callback')
  dispose(scene);scene=nil
  callbacks=0;scene=assert(PlotScene:create(id,function()callbacks=callbacks+1 end));scene:retain();advance(.6)
  local nextButton=assert(skip(scene));nextButton:selected();nextButton:unselected();nextButton:activate();nextButton:activate()
  advance(.2);equal(callbacks,1,caption..' scene '..id..' double Next invokes callback once')
  advance(8);equal(callbacks,1,caption..' scene '..id..' scheduled natural end after Next cannot repeat callback');dispose(scene);scene=nil
 end
 print('PASS native coherent seven opening story actions, original text and repeated Next callbacks '..caption)
 -- The original multi-scene chain still replaces exactly once per Next.
 local completed=0;replacements={};scene=PlotScene:create({1,2,3,4,5,6,7},function()completed=completed+1 end);scene:retain()
 for id=1,7 do local current=scene;local nextButton=assert(skip(current));nextButton:activate();nextButton:activate();advance(.2)end
 equal(#replacements,6,caption..' opening chain replaces once per scene');equal(completed,1,caption..' opening chain completes once');advance(8);equal(completed,1,caption..' opening chain stays one-shot');dispose(scene);scene=nil
 -- Natural playback also completes the entire initial chain exactly once.
 completed=0;replacements={};scene=PlotScene:create({1,2,3,4,5,6,7},function()completed=completed+1 end);scene:retain();advance(60)
 equal(#replacements,6,caption..' natural chain replaces each scene once');equal(completed,1,caption..' natural chain completes once');dispose(scene);scene=nil
 -- Interrupted scene cleanup must cancel both scheduled and pending Next.
 local cancelled=0;scene=PlotScene:create(1,function()cancelled=cancelled+1 end);scene:retain();advance(.6);skip(scene):activate();dispose(scene);scene=nil;advance(10)
 equal(cancelled,0,caption..' interrupted scene cancels pending completion')
 -- Native PlotLayer uses the same clean font and original movement/callbacks.
 package.loaded['LuaClass/PlotLayer']=nil;require 'LuaClass/PlotLayer'
 for id=1,24 do
  scene=cc.Scene:create();scene:retain();local layer=PlotLayer:create(id);layer:retain();local done,stay=0,0
  layer:setCalback(function()done=done+1 end);layer:setStayCallback(function()stay=stay+1 end);layer:play();advance(1.1+#plots[tostring(id)].story)
  equal(#layer.ttfs,#plots[tostring(id)].story,caption..' overlay '..id..' original line count')
  for i,label in ipairs(layer.ttfs)do
   equal(label:getString(),plots[tostring(id)].story[i][1],caption..' overlay '..id..' original line order')
   equal(label:getFontName(),W.font,caption..' overlay '..id..' font');within(label,caption..' overlay '..id..' '..label:getString())
  end
  advance(4);equal(done,1,caption..' overlay '..id..' callback once');equal(stay,1,caption..' overlay '..id..' stay once');equal(layer:getParent(),nil,caption..' overlay '..id..' removed')
  layer:release();dispose(scene);scene=nil
 end
 -- Real clean font measurement/wrapping, FIFO queue and 12px separation.
 scene=cc.Scene:create();scene:retain();notification=cc.Node:create();notification:retain()
 ToastUtil.infoQueue={};ToastUtil.infoKinds={};local seen,order={},{};local peak=0
 local expected={'已解锁成就：炼金 I','钻石+1','建设已解锁！','金币不足','船坞已解锁','建造成功','获得食物+5','获得木头+2','任务完成','获得铁+1'}
 local function cards()local out={};for _,stack in ipairs(notification:getChildren())do if stack.isOrdinaryToastStack then for _,n in ipairs(stack:getChildren())do if n.toastText and n:isVisible()then out[#out+1]=n end end end end;table.sort(out,function(a,b)return a:getPositionY()>b:getPositionY()end);return out end
 local function inspectToasts()
  local current=cards();peak=math.max(peak,#current);check(#current<=3,caption..' at most three toast cards');local bottom
  for _,card in ipairs(current)do
   local backdrop,label=card:getChildren()[1],card:getChildren()[2];local b=bounds(backdrop)
   within(backdrop,caption..' toast backdrop');within(label,caption..' toast text')
   check(b.top<=viewport.height*.5+160+.1 and b.bottom>=viewport.height*.35-.1,caption..' central toast region')
   if bottom then check(b.top<=bottom-11.9,caption..' toast gap >=12')end;bottom=b.bottom
   equal(label:getFontName(),W.font,caption..' toast clean CJK font');equal(label:getFontSize(),28,caption..' toast 28px font')
   if not seen[card]then seen[card]=true;order[#order+1]=card.toastText end
  end
 end
 for _,text in ipairs(expected)do ToastUtil:downString(text)end;advance(.2,inspectToasts);equal(#cards(),3,caption..' free slots fill immediately')
 advance(12,inspectToasts);equal(#cards(),0,caption..' toast burst drains');equal(#ToastUtil.infoQueue,0,caption..' toast queue drains');equal(peak,3,caption..' toast peak')
 for i,text in ipairs(expected)do equal(order[i],text,caption..' FIFO message '..i)end;equal(#order,#expected,caption..' all messages once')
 local long='已解锁新的海域：请准备足够的食物和船员，再从港口整备出航。'..string.rep('不同的重要提示必须完整显示，不能覆盖或截断。',5)
 ToastUtil:downString(long);ToastUtil:downString('钻石+1');advance(.2,inspectToasts);local card=assert(cards()[1]);equal(card:getChildren()[2]:getString(),long,caption..' long content retained');advance(10,inspectToasts)
 local receipt=ToastUtil:alchemyCoins(5);equal(receipt.alchemyTitle:getFontName(),W.font,caption..' alchemy clean font');within(receipt.alchemyBackdrop,caption..' alchemy receipt');advance(2)
 dispose(notification);notification=nil;dispose(scene);scene=nil
 print('PASS native coherent startup, PlotLayer, FIFO/long toast and alchemy typography '..caption)
end
-- Explicit opt-out still uses the legacy font, skip geometry and startup art.
WARM_PIRATE_V1=false;viewport=cc.size(640,1136);local legacyCallbacks=0
scene=PlotScene:create(1,function()legacyCallbacks=legacyCallbacks+1 end);scene:retain();advance(.6)
equal(scene:getChildrenCount(),3,'legacy plot has original node/cover/menu structure')
local legacySkip=scene:getChildren()[3]:getChildren()[1]
equal(legacySkip:getContentSize().width,36,'legacy skip width');equal(legacySkip:getContentSize().height,36,'legacy skip height')
local legacyText=scene:getChildren()[1]:getChildren()[2]
equal(legacyText:getFontName(),MasterTheme.headingFont(false),'legacy narrative serif');equal(legacyText:getFontSize(),30,'legacy narrative size')
legacySkip:activate();legacySkip:activate();advance(9);equal(legacyCallbacks,1,'legacy repeated skip callback once');dispose(scene);scene=nil
local legacyStartup=S.title();equal(legacyStartup:getFontName(),MasterTheme.headingFont(true),'legacy startup serif')
scene=cc.Scene:create();scene:retain();notification=cc.Node:create();notification:retain();ToastUtil:downString('旧界面提示');advance(.2)
local legacyCard=notification:getChildren()[1]:getChildren()[1]
equal(legacyCard:getChildren()[2]:getFontName(),BoldFont,'legacy toast font');equal(legacyCard:getChildren()[2]:getFontSize(),38,'legacy toast size');advance(4)
dispose(notification);notification=nil;dispose(scene);scene=nil
cc.Director.getInstance=realGet
print('PASS native story/startup/toast explicit legacy opt-out')
print(string.format('Coherent story/toast native: %d assertions, %d failures, %d plot reads',checks,#failures,dataReads))
assert(#failures==0,table.concat(failures,'\n'))
