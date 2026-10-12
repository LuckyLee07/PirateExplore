-- Actual GLView event dispatch; no manual listener/menu activation.
-- Reuse only fixture CSV/state and native module setup, not its test actions.
local f=assert(io.open('tools/tests/coherent_event_pages_native.lua','rb'));local source=f:read('*a');f:close()
local stop=assert(source:find("local W=require 'LuaClass/WarmTheme'",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn H','@event-shield-module-setup'))()
local checks=0
local function eq(a,b,msg)checks=checks+1;assert(a==b,msg..' ['..tostring(a)..' ~= '..tostring(b)..']')end
for _,size in ipairs({{480,800},{540,900},{640,960},{640,1067},{720,1280}})do
 local w,h=size[1],size[2];H.fixture();screenSize=cc.size(w,h)
 local scene=H.prepare(w,h);local taps=0
 local item=cc.MenuItemLabel:create(cc.LabelTTF:create('Underlying map HUD','fonts/CleanVoyageSans-Regular.ttf',20))
 item:setContentSize(cc.size(220,54));item:setPosition(cc.p(w/2,h-30));item:registerScriptTapHandler(function()taps=taps+1 end)
 local menu=cc.Menu:create(item);menu:setPosition(cc.p(0,0));scene:addChild(menu)
 eventShieldEnter(scene,w,h)
 local function tap()eventShieldTap(w/2,h-30)end
 tap();eq(taps,1,'underlying native menu works before event')
 local host=cc.Node:create();scene:addChild(host,100)
 local view=assert(EventLayer:create());view:retain();host:addChild(view)
 if os.getenv('EVENT_SHIELD_COUNTERFACTUAL')=='1' then
  -- Restore only the former production callback, without editing any source.
  view.eventShield:registerScriptHandler(function()return true end,cc.Handler.EVENT_TOUCH_BEGAN)
 end
 view:show();eventShieldFrames();tap();eq(taps,1,'visible encounter shields underlying map')
 view:hide();eventShieldFrames();tap();eq(taps,2,'hidden encounter must release underlying map input')
 view:show();eventShieldFrames();tap();eq(taps,2,'reshown encounter shields underlying map')
 host:setVisible(false);eventShieldFrames();tap();eq(taps,3,'hidden ancestor must release underlying map input')
 host:setVisible(true);eventShieldFrames();tap();eq(taps,3,'restored ancestor shields underlying map')
 for i=1,3 do
  view:hide();eventShieldFrames();tap();eq(taps,3+i,'repeated hide restores one underlying activation')
  view:show();eventShieldFrames();tap();eq(taps,3+i,'repeated show shields again')
 end
 view:removeFromParent(true);eventShieldFrames();tap();eq(taps,7,'cleanup releases underlying input')
 eq(view.eventDisposed,true,'event marked disposed');eq(view.eventShield,nil,'cleanup removes listener');view:release()
 print('PASS event shield native lifecycle '..w..'x'..h)
end
print('PASS '..checks..' event shield native input assertions')
