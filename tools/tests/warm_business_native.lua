-- Real Cocos/EGL geometry, fonts, assets, menu activation and modal lifecycle.
-- Execute using tutorial-log-native from the repo root. No player save loaded.
require 'extern'
require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true
package.loaded['LuaClass/DataManager']=true
local writes=0
DataManager={getInstance=function()return {getSound_off=function()return 1 end,
 setRoleData=function()writes=writes+1;error('presentation must not write role state')end}end}
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
local viewport,scene
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,
 getWinSize=function()return viewport end,getVisibleOrigin=function()return cc.p(0,0)end,
 getRunningScene=function()return scene end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local W=require 'LuaClass/WarmTheme'
local T=require 'LuaClass/ManagementTheme'
local D=require 'LuaClass/DialogTheme'
local S=require 'LuaClass/StartupTheme'
require 'LuaClass/SDButton'
require 'LuaClass/AlertView'
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function size(node,w,h,why)local z=node:getContentSize();equal(z.width,w,why..' width');equal(z.height,h,why..' height')end
local function labels(node,text)
 local out={}
 local function walk(n)
  if n.getString and n:getString()==text then out[#out+1]=n end
  for _,child in ipairs(n:getChildren())do walk(child)end
 end
 walk(node);return out
end
local function contrast(fg,bg)
 local function lum(c)
  local function channel(v)v=v/255;return v<=.04045 and v/12.92 or ((v+.055)/1.055)^2.4 end
  return .2126*channel(c.r)+.7152*channel(c.g)+.0722*channel(c.b)
 end
 local a,b=lum(fg),lum(bg);return (math.max(a,b)+.05)/(math.min(a,b)+.05)
end
assert(contrast(W.colors.white,W.colors.ink)>10,'unowned white caller labels retain strong dark-panel contrast')
assert(contrast(W.colors.ink,W.colors.paper)>10,'business paper labels retain strong contrast')
for _,height in ipairs({960,1067,1136})do
 viewport=cc.size(640,height);scene=cc.Scene:create();scene:retain()
 local root=cc.Node:create();scene:addChild(root)
 local paper=T.pagePaper(640,height,136,100);root:addChild(paper)
 size(paper,640,height,'management backdrop');equal(paper:getAnchorPoint().x,0,'backdrop origin')
 for _,style in ipairs({'paper','light','section','ink','coral','line'})do
  local panel=T.panel(616,100,style);root:addChild(panel);size(panel,616,100,'business '..style)
  equal(panel:getAnchorPoint().x,.5,'legacy center anchor')
  local label=T.label('真实材料与数量',28,style=='ink' and 'action' or 'body',308,50,.5);panel:addChild(label)
  assert(label:getContentSize().width<592,'actual CJK material heading fits row')
 end
 local activations=0
 local menuItem=T.menuItem(128,59,'coral');menuItem:registerScriptTapHandler(function()activations=activations+1 end)
 root:addChild(cc.Menu:create(menuItem));size(menuItem,128,59,'primary action');menuItem:activate();equal(activations,1,'native menu callback')
 local button=SDButton:create('Images/UI/AddCircleBtn.png','Images/UI/AddCircleBtn1.png',function()activations=activations+1 end)
 root:addChild(button);button:registerLongPressed(function()activations=activations+10 end)
 local listener,callback,long=button.listener,button.onSingleCLick,button.onLongPressed
 local old=button:getContentSize();button:setEnabled(false)
 T.skinSDButton(button,'coral','crew')
 equal(button.listener,listener,'same native touch listener');equal(button.onSingleCLick,callback,'same tap closure');equal(button.onLongPressed,long,'same long-press closure')
 equal(button.bIsEnable,false,'disabled state retained');size(button.normalSpr,old.width,old.height,'SD hitbox')
 button:setActive(true);assert(button.selectSpr:isVisible() and not button.normalSpr:isVisible(),'selected native state')
 button:setActive(false);assert(button.normalSpr:isVisible() and not button.selectSpr:isVisible(),'normal native state')
 T.skinSDButton(button,'coral','crew');equal(button.listener,listener,'repeated skin is inert')
 local close=D.closeItem();root:addChild(cc.Menu:create(close));size(close,58,58,'close asset target')
 local startup=S.background(viewport);root:addChild(startup);size(startup,640,height,'warm loading backdrop')
 local title=S.title();root:addChild(title);assert(title:getContentSize().width<600,'actual loading title fits')
 local marker=S.ship();root:addChild(marker)
 local legacy=cc.Sprite:create('Images/UI/fmloding_01.png'):getContentSize();size(marker,legacy.width,legacy.height,'loading marker geometry')
 local accepted,cancelled=0,0
 for box=0,3 do
  local alert=AlertView:create(2,box,'确认建造',function()accepted=accepted+1 end,function()cancelled=cancelled+1 end,'取消','确定')
  alert:retain()
  local z=alert.s_size;size(alert.s_bg,z.width,z.height,'original modal size')
  local heading=assert(labels(alert,'确认建造')[1]);assert(heading:getContentSize().width*heading:getScale()<=z.width-160+1,'real modal title remains within safe area')
  assert(labels(alert,'确定')[1]):getParent():activate();equal(accepted,box+1,'native modal confirmation once')
  equal(alert:getParent(),nil,'confirm detaches modal');alert:release()
 end
 for _=1,3 do
  local alert=AlertView:create(2,0,'可取消',nil,function()cancelled=cancelled+1 end,'取消','确定');alert:retain()
  assert(labels(alert,'取消')[1]):getParent():activate();equal(alert:getParent(),nil,'cancel detaches modal');alert:release()
 end
 equal(cancelled,3,'repeated reopen/cancel exactly once each')
 local manual=AlertView:create(2,0,'保留提示',function()accepted=accepted+1 end,nil,'取消','确定');manual:retain();manual:setOkRemove(false)
 assert(labels(manual,'确定')[1]):getParent():activate();equal(manual:getParent(),scene,'manual-close content stays visible')
 manual.closeBtn:onSingleCLick();equal(manual:getParent(),nil,'native close callback');manual:release()
 scene:cleanup();scene:release();scene=nil
 print('PASS native warm business '..height..': native surfaces and CJK fonts, retained action geometry/listeners/state, loading assets, modal confirm/cancel/reopen/close')
end
-- Reuse the same modules after opt-out; no warm-only geometry leaks into B.
WARM_PIRATE_V1=false
assert(T.colors.ink==MasterTheme.colors.ink and D.colors.ink==MasterTheme.colors.ink,'original palettes restored')
local legacy=S.ship();local z=cc.Sprite:create('Images/UI/fmloding_01.png'):getContentSize();size(legacy,z.width,z.height,'legacy loading dimensions')
equal(writes,0,'no presentation state writes')
cc.Director.getInstance=realGet
print('PASS native warm business opt-out and no gameplay/save writes')
