local f=assert(io.open('bin/res/scripts/LuaClass/ToastUtil.lua'));local source=f:read('*a');f:close()
local start=assert(source:find('function ToastUtil:isProductionQuiet()',1,true))
local stop=assert(source:find('-- Remove only already-visible routine production',start,true))
ToastUtil={};local calls=0;function ToastUtil:downString()calls=calls+1 end
local scene={getChildren=function()return{}end};cc={Director={getInstance=function()return{getRunningScene=function()return scene end}end}}
local chunk='local function cleanToast()return rawget(_G,"WARM_PIRATE_V1")~=false end\n'..source:sub(start,stop-1)
assert(loadstring(chunk))()
pNeedUpdateLayer=nil;WARM_PIRATE_V1=true
local visible=true;local page={coherentShell={},isVisible=function()return visible end}
zqDispatch={rightNode=page}
ToastUtil:productionString('小麦+7');assert(calls==0,'visible market without feed suppresses passive harvest')
ToastUtil:downString('材料不足');assert(calls==1,'ordinary error remains visible')
visible=false;ToastUtil:productionString('食物+1');assert(calls==2,'hidden page cannot suppress unrelated route')
visible=true;page.coherentPageDisposed=true;ToastUtil:productionString('食物+1');assert(calls==3,'disposed page cannot suppress')
page.coherentPageDisposed=false;zqDispatch.dispatchDisposed=true;ToastUtil:productionString('食物+1');assert(calls==4,'disposed router cannot suppress')
zqDispatch.dispatchDisposed=false;WARM_PIRATE_V1=false;ToastUtil:productionString('食物+1');assert(calls==5,'legacy opt-out preserves feedback')
WARM_PIRATE_V1=true;zqDispatch.rightNode=nil;ToastUtil:productionString('食物+1');assert(calls==6,'leaving coherent page restores ordinary feedback')
print('PASS passive production quiet on live coherent route only; ordinary feedback and legacy preserved')
