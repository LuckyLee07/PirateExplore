-- Shared clean chrome contracts. Native-shaped fixtures, not screenshot QA.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
-- Run full navigation lifecycle while asserting clean business-header paint.
local navigation=read('tools/tests/warm_navigation_settings_regression.lua')
local needle='local menu=dispatch.mainMenu'
local i,j=assert(navigation:find(needle,1,true))
navigation=navigation:sub(1,j).."\n"..[[
local function allClean(n)
    if n.path then assert(not n.path:find('Adventure/Master',1,true),'clean business header cannot use legacy painted art')end
    for _,child in ipairs(n:getChildren())do allClean(child)end
end
assert(menu.coinValueLabel.font==theme.font and menu.diamondValueLabel.font==theme.font,'business currencies use shared sans')
allClean(menu.legacyTopBg);allClean(menu.coinNode);allClean(menu.diamondNode)
assert(menu.legacyTopBg:getContentSize().height==100 and menu.navigationHeight==118 and UIBottomHeight==136,'original page safe areas remain')
]]..navigation:sub(j+1)
-- Let the legacy first-stage fixture select its opt-out before real Warm reload.
WarmTheme=nil;WARM_PIRATE_V1=false
assert(loadstring(navigation,'@coherent-navigation-chrome'))()
print('PASS coherent business header/currency art and fonts with full legacy/Warm navigation and modal lifecycle')
