-- Exercise the existing full purchase/decline suite with the honest Warm labels.
WARM_PIRATE_V1=true
local f=assert(io.open('tools/tests/purchase_availability_regression.lua'));local source=f:read('*a');f:close()
source=source:gsub("label%(alert, '安全回城'%)", "label(alert, os==cc.PLATFORM_OS_ANDROID and '查看返航购买' or '购买不可用')")
-- This logic-only harness has no Cocos service-sheet implementation. Exercise
-- its old gift routing through the explicit opt-out; the coherent service native
-- suite covers the new gift sheet. Keep Warm enabled for all hunger controls.
local old='assert(PushGiftView.init(pushed))'
local replacement='(function() local warm=WARM_PIRATE_V1; WARM_PIRATE_V1=false; local ok=PushGiftView.init(pushed); WARM_PIRATE_V1=warm; return assert(ok) end)()'
local a,b=assert(source:find(old,1,true));source=source:sub(1,a-1)..replacement..source:sub(b+1)
assert(loadstring(source,'@coherent-hunger-production-fixture'))()
print('PASS coherent hunger labels retain actual platform availability, decline, native product request and no fake rescue')
