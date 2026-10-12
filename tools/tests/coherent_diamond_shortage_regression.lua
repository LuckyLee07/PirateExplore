-- Production addDiamond and platform guard; options observed without a purchase.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
cc={};dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/Cocos2dConstants.lua')
local platform=cc.PLATFORM_OS_LINUX;cc.Application={getInstance=function()return{getTargetPlatform=function()return platform end}end}
local notices={};ToastUtil={downString=function(_,s)notices[#notices+1]=s end}
local savedRequire=require;require=function()return true end
local PA=dofile('bin/res/scripts/LuaClass/PurchaseAvailability.lua');require=savedRequire
local options,body,shown,checks,writes,routes,created
local originalAvailable=PA.isAvailable;PA.isAvailable=function()checks=checks+1;return originalAvailable()end
require=function(name)
 if name=='LuaClass/PurchaseAvailability'then return PA end
 if name=='LuaClass/WarmDialog'then return{show=function(title,message,choices)assert(title=='钻石不足');shown=shown+1;body=message;options=choices end}end
 return savedRequire(name)
end
local data={};roleDiamond='diamond';DataManager={};local dm=DataManager
function dm:getRoleData(key)return data[key]end
function dm:setRoleData(key,value)writes=writes+1;data[key]=value end
local source=read('bin/res/scripts/LuaClass/DataManager.lua');local a=assert(source:find('function DataManager:addDiamond(',1,true));local b=assert(source:find('function DataManager:unlockTallentByKey(',a,true));assert(loadstring(source:sub(a,b-1)))()
local trap=function()error('no billing allowed')end
PushGiftView={create=function()created=created+1;return{show=function(_,depth)routes[#routes+1]=depth or 'home'end}end}
local function reset()data.diamond=0;options=nil;body=nil;shown=0;checks=0;writes=0;routes={};created=0;notices={};purchase=trap;WARM_PIRATE_V1=true end
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
for _,os in ipairs({cc.PLATFORM_OS_LINUX,cc.PLATFORM_OS_MAC,cc.PLATFORM_OS_WINDOWS,999})do
 reset();platform=os;eq(dm:addDiamond(-1),0,'unsupported shortage return');eq(writes,0,'no shortage writes');eq(data.diamond,0,'balance untouched')
 eq(body,'钻石不足，当前平台暂不支持充值购买。','truthful unavailable explanation');eq(#options,1,'one dismiss choice');eq(options[1].label,'知道了','dismiss label');eq(options[1].action,nil,'no actionable recharge');eq(created,0,'no gift route')
end
for _,os in ipairs({cc.PLATFORM_OS_IPHONE,cc.PLATFORM_OS_IPAD,cc.PLATFORM_OS_ANDROID})do
 for _,inMap in ipairs({false,true})do
  reset();platform=os;isEnterMap=inMap;eq(dm:addDiamond(-1),0,'supported shortage return');eq(writes,0,'supported shortage never writes');eq(#options,2,'route plus cancel')
  eq(body,'钻石不足，可查看充值选项。购买结果由平台确认。','honest supported explanation');eq(options[1].label,'查看充值选项','explicit route label');eq(options[2].label,'取消','cancel');eq(options[2].action,nil,'cancel side-effect free')
  options[1].action();eq(options[1].action(),false,'reentry keeps sheet open until original route returns');eq(created,1,'repeated action creates once');eq(#routes,1,'repeated action shows once');eq(routes[1],inMap and 999 or 'home','original route argument');eq(writes,0,'options never credits or spends')
 end
end
reset();platform=cc.PLATFORM_OS_ANDROID;purchase=nil;dm:addDiamond(-1);eq(#options,1,'missing bridge is unavailable')
reset();platform=nil;dm:addDiamond(-1);eq(#options,1,'unknown platform is unavailable')
reset();eq(dm:addDiamond(-1,false),0,'suppressed shortage return');eq(shown,0,'suppressed shortage has no surface');eq(checks,0,'suppression occurs before platform lookup');eq(writes,0,'suppressed shortage no writes')
reset();eq(dm:addDiamond(5,false,false),1,'positive succeeds');eq(dm:addDiamond(-3),1,'cost succeeds');eq(dm:addDiamond(0),1,'zero succeeds');eq(writes,3,'original write count');eq(data.diamond,2,'original arithmetic');eq(checks,0,'success never checks platform');eq(#notices,0,'quiet positive and ordinary costs unchanged')
require=savedRequire
print('PASS production shortage logic: unsupported/missing/unknown platform dismiss-only, all supported platform routes, explicit Cancel, repeated action once, false short-circuit and unchanged arithmetic')
