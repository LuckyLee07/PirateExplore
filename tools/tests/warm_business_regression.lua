-- Re-run real legacy business actions with the warm presentation enabled.
-- No real save/profile, economy table, network or purchase is initialized.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local actualRequire=require
local function run(name,needle)
    WarmTheme=nil;WARM_PIRATE_V1=true
    local source=read('tools/tests/'..name..'.lua')
    local i,j=assert(source:find(needle,1,true))
    source=source:sub(1,j).."\ndofile('bin/res/scripts/LuaClass/WarmTheme.lua')\n"..source:sub(j+1)
    assert(loadstring(source,'@warm-'..name))()
    assert(WarmTheme and WarmTheme.enabled(),'real WarmTheme loaded')
    print('PASS warm business variant: '..name)
end
run('management_ui_regression',"dofile('bin/res/scripts/LuaClass/MasterTheme.lua')")
local T=ManagementTheme
assert(T.colors.ink.r==83 and T.colors.paper.r==255 and T.colors.coral.g==108,'management uses warm palette')
local warmPanel=T.panel(128,59,'coral')
assert(warmPanel:getContentSize().width==128 and warmPanel:getContentSize().height==59,'warm action geometry')
assert(warmPanel:getChildren()[1].kind=='DrawNode','warm action is native rounded geometry')
local paint=warmPanel:getChildren()[1].draws[1]
assert(#paint.points==36 and paint.fill.r==1 and paint.fill.g==108/255,'warm coral rounded field')
WARM_PIRATE_V1=false
assert(T.colors.ink==MasterTheme.colors.ink and T.colors.coral==MasterTheme.colors.coral,'live opt-out restores original palette')
WARM_PIRATE_V1=true
run('dialog_theme_regression',"dofile(root..'MasterTheme.lua');")
assert(DialogTheme.colors.ink.r==83 and DialogTheme.colors.white.g==252,'dialog warm palette')
local warmLabel=DialogTheme.label('真实内容',24)
assert(warmLabel.color.r==255 and warmLabel.color.g==252,'caller default stays light on chocolate')
WARM_PIRATE_V1=false
assert(DialogTheme.colors.ink==MasterTheme.colors.ink,'dialog opt-out restores original palette')
-- Legacy fixtures may intentionally return true from require. Do not index it.
WarmTheme=nil;WARM_PIRATE_V1=true
assert(DialogTheme.panel(572,437),'sentinel require safely falls back')
require=actualRequire
print('PASS warm native-style surfaces, palette opt-out and non-table fixture guards')
