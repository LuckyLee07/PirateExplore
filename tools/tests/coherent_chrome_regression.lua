-- Shared clean chrome contracts. Native-shaped fixtures, not screenshot QA.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
assert(loadstring(source:sub(1,stop-1),'@coherent-chrome-node-fixture'))()
require=function()return true end
local root='bin/res/scripts/LuaClass/'
dofile(root..'Header.lua');dofile(root..'HomeTheme.lua');dofile(root..'MasterTheme.lua')
WARM_PIRATE_V1=true
local W=dofile(root..'WarmTheme.lua')
local C=dofile(root..'CombatTheme.lua')
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local function shape(n)return n:getChildren()[1].draws[1]end
local function cleanOnly(n)
    if n.path then assert(not n.path:find('brush',1,true),'no brush material in clean combat chrome') end
    for _,child in ipairs(n:getChildren())do cleanOnly(child)end
end
local font=C.label('航行与战斗',nil,30)
equal(font.font,W.font,'combat shared sans font');equal(font.color,W.colors.white,'existing light text retained')
for _,height in ipairs({960,1067,1136})do
    local size=cc.size(640,height);local parent=cc.Node:create()
    local bg=C.background(size);parent:addChild(bg)
    equal(bg:getContentSize(),size,'combat background size');equal(#bg:getChildren(),3,'sea field, caustics and retained bottom action strip')
    equal(bg:getChildren()[2].path,'Images/UI/CleanVoyage/sea-turquoise-caustics.png','same sunny voyage water')
    local caption=C.captionPlate(parent,size,12)
    equal(caption:getPositionX(),-10,'caption x');equal(caption:getPositionY(),height-62,'caption y');equal(caption.z,12,'caption layering')
    equal(caption:getContentSize().width,660,'caption width');equal(caption:getContentSize().height,62,'caption height')
    local status=C.statusPlate(parent,320,200,10)
    equal(status:getPositionX(),125,'status x');equal(status:getPositionY(),163,'status y');equal(status.z,10,'status layering')
    equal(status:getContentSize().width,390,'status width');equal(status:getContentSize().height,98,'status height')
    equal(shape(status).fill.r,38/255,'status navy backing')
    local bar=C.bar(true,nil,nil,'player');equal(bar:getContentSize().width,313,'bar width');equal(bar:getContentSize().height,23,'bar height')
    equal(shape(bar:getChildren()[1]).fill.g,126/255,'player teal health bar')
    cleanOnly(parent)
end
WARM_PIRATE_V1=false
equal(C.label('旧界面',nil,30).font,MasterTheme.headingFont(true),'combat legacy font opt-out')
local bg=C.background(cc.size(640,960));equal(#bg:getChildren(),4,'legacy sea shade and brush framing remain')
local plate=C.captionPlate(cc.Node:create(),cc.size(640,960))
assert(plate.kind~='DrawNode','legacy material wrapper retained')
WarmTheme=nil;WARM_PIRATE_V1=true
assert(C.label('Fixture',nil,24),'non-table require falls back safely')
print('PASS coherent combat palette/font, sunny shared water, caption/status/HP geometry, legacy opt-out and fixture fallback')
