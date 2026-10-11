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
assert(T.colors.ink.r==38 and T.colors.ink.g==65 and T.colors.paper.g==247 and T.colors.coral==WarmTheme.colors.sea,'management uses shared clean palette')
assert(T.bodyFont()==WarmTheme.font and T.label('真实材料',24,'heading',0,0).font==WarmTheme.font,'business labels use shared sans font')
local warmPanel=T.panel(128,59,'coral')
assert(warmPanel:getContentSize().width==128 and warmPanel:getContentSize().height==59,'warm action geometry')
assert(warmPanel:getChildren()[1].kind=='DrawNode','warm action is native rounded geometry')
local paint=warmPanel:getChildren()[1].draws[1]
assert(#paint.points==36 and paint.fill.r==25/255 and paint.fill.g==126/255,'clean primary action uses teal native geometry')
assert(paint.points[1].y==51,'clean action corner radius is eight points')
WARM_PIRATE_V1=false
assert(T.colors.ink==MasterTheme.colors.ink and T.colors.coral==MasterTheme.colors.coral,'live opt-out restores original palette')
WARM_PIRATE_V1=true
run('dialog_theme_regression',"dofile(root..'MasterTheme.lua');")
assert(DialogTheme.colors.ink.r==38 and DialogTheme.colors.ink.g==65 and DialogTheme.colors.white.g==252,'dialog shared clean palette')
local warmLabel=DialogTheme.label('真实内容',24)
assert(warmLabel.color.r==255 and warmLabel.color.g==252,'caller default stays light on dark navy')
assert(warmLabel.font==WarmTheme.font,'dialog labels use shared sans font')
local function luminance(c)
    local function channel(v)v=v/255;return v<=.04045 and v/12.92 or ((v+.055)/1.055)^2.4 end
    return .2126*channel(c.r)+.7152*channel(c.g)+.0722*channel(c.b)
end
local white=luminance(DialogTheme.colors.white)
for _,bg in ipairs({WarmTheme.colors.ink,cc.c3b(48,78,83),cc.c3b(50,88,91)})do
    assert((white+.05)/(luminance(bg)+.05)>7,'unknown white labels retain strong normal/selected contrast')
end
WARM_PIRATE_V1=false
assert(DialogTheme.colors.ink==MasterTheme.colors.ink,'dialog opt-out restores original palette')
-- Legacy fixtures may intentionally return true from require. Do not index it.
WarmTheme=nil;WARM_PIRATE_V1=true
assert(DialogTheme.panel(572,437),'sentinel require safely falls back')
require=actualRequire
print('PASS warm native-style surfaces, palette opt-out and non-table fixture guards')
