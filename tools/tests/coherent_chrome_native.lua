-- Real Cocos/EGL instantiation of clean combat chrome; no GUI or player data.
require 'extern'
require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC';WARM_PIRATE_V1=true
local W=require 'LuaClass/WarmTheme'
local C=require 'LuaClass/CombatTheme'
local D=require 'LuaClass/DialogTheme'
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function size(n,w,h,why)local z=n:getContentSize();equal(z.width,w,why..' width');equal(z.height,h,why..' height')end
local deck,chest=C.deckPath(false),C.chestPath(false)
for _,height in ipairs({960,1067,1136})do
    local scene=cc.Scene:create();scene:retain()
    local viewport=cc.size(640,height)
    local bg=C.background(viewport);scene:addChild(bg)
    size(bg,640,height,'sea backdrop');equal(#bg:getChildren(),3,'sunny sea, water detail, action strip')
    local caption=C.captionPlate(scene,viewport,8)
    size(caption,660,62,'caption');equal(caption:getPositionY(),height-62,'caption safe area')
    local status=C.statusPlate(scene,320,200,9)
    size(status,390,98,'status');equal(status:getPositionY(),163,'HP safe area')
    local label=C.label('一艘海盗船对你发起了炮击',nil,25);scene:addChild(label)
    equal(label:getFontName(),W.font,'real CJK clean font');assert(label:getContentSize().width<616,'encounter text fits original caption')
    for _,filled in ipairs({false,true})do
        local bar=C.bar(filled,nil,nil,'player');scene:addChild(bar);size(bar,313,23,'HP progress source')
    end
    for _,tone in ipairs({'card','ink','paper','panel'})do
        local normal=D.card(572,437,tone);local selected=D.card(572,437,tone,true)
        scene:addChild(normal);scene:addChild(selected)
        size(normal,572,437,'dialog');equal(normal:getAnchorPoint().x,.5,'dialog center anchor')
    end
    scene:cleanup();scene:release()
    print('PASS native coherent chrome '..height..': sunny sea, sans CJK, caption/status/HP and dialog bounds')
end
WARM_PIRATE_V1=false
local scene=cc.Scene:create();scene:retain()
local bg=C.background(cc.size(640,960));scene:addChild(bg);equal(#bg:getChildren(),4,'legacy background branch')
local label=C.label('旧界面',nil,30);scene:addChild(label)
equal(label:getFontName(),MasterTheme.headingFont(true),'legacy font branch')
equal(C.deckPath(false),deck,'deck asset unchanged');equal(C.chestPath(false),chest,'chest asset unchanged')
scene:cleanup();scene:release()
print('PASS native coherent combat opt-out and unchanged actor/reward asset selection')
