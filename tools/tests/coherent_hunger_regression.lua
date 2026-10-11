-- Exercise the existing full purchase/decline suite with the honest Warm labels.
WARM_PIRATE_V1=true
local f=assert(io.open('tools/tests/purchase_availability_regression.lua'));local source=f:read('*a');f:close()
source=source:gsub("label%(alert, '安全回城'%)", "label(alert, os==cc.PLATFORM_OS_ANDROID and '查看返航购买' or '购买不可用')")
assert(loadstring(source,'@coherent-hunger-production-fixture'))()
print('PASS coherent hunger labels retain actual platform availability, decline, native product request and no fake rescue')
