-- Executes production footer/resume callbacks with a controlled wall-clock.
-- This is a source contract, separate from the natural GUI reproduction.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function eq(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local source=read('tools/tests/management_ui_regression.lua')
local cutoff=assert(source:find('-- Real resource row controls',1,true))
local F=assert(loadstring(source:sub(1,cutoff-1)..'\nreturn {node=H.node,methods=N}','@cooldown-fixture'))()
local oldTime=os.time;local now=1014;os.time=function()return now end
BaseViewLastClickCDTime=1000
local function page(duration,light)
 local p=F.node('CooldownPage');setmetatable(p,{__index=function(_,k)return BaseView[k] or F.methods[k]end})
 p.titleBg=F.node();p.titleBg:setPosition(320,999)
 p.areaWidth=610;p.areaHeight=833;p.centerPos=cc.p(320,500);p.originPos=cc.p(15,136);p.titleHeight=67
 p:addInfoNode(nil,nil,nil,nil,'Images/MainMenu/an_caiji_a.png','Images/MainMenu/an_caiji_b.png',function()end,nil,true,duration or 30,light~=false)
 return p
end
for _,elapsed in ipairs({14,20,29})do
 now=1000+elapsed;local p=page()
 eq(p.setButtonProgrees.actions[1].args[1].args[1],30-elapsed,'reentry remaining duration')
 eq(p.setButtonProgrees.percentage,math.floor(elapsed/30*100),'elapsed progress retained')
 assert(not p.bIsCenterBtnCanClick);eq(BaseViewLastClickCDTime,1000,'reentry does not move original deadline')
 p.setButtonProgrees.actions[1].args[2].args[1]();assert(p.bIsCenterBtnCanClick,'remaining action unlocks')
end
now=1030;local p=page();assert(p.bIsCenterBtnCanClick,'exact deadline immediately available')
now=1050;assert(page().bIsCenterBtnCanClick,'past deadline immediately available')
now=999;p=page();eq(p.setButtonProgrees.actions[1].args[1].args[1],30,'backward clock clamps maximum wait')
now=1030;p=page(.3,false);p.setBtn.onSingleCLick()
eq(p.setButtonProgrees.actions[1].args[2].args[1],.3,'alchemy retains its exact repeat cooldown')
-- Execute the actual registered Resource foreground callback without its GUI setup.
local rsource=read('bin/res/scripts/LuaClass/Resource.lua')
local start=assert(rsource:find('DataManager:getInstance():registerEvent("kSystemBackToForward", "resource", function()',1,true))
local finish=assert(rsource:find('\n    end)',start,true))
local code=rsource:sub(start,finish+#'\n    end)'-1)
local object=page()
local resume;local savedDM=DataManager
DataManager={getInstance=function()return {registerEvent=function(_,event,key,callback)eq(event,'kSystemBackToForward','real resume event');resume=callback end}end}
assert(loadstring('local self,progressTime=...\n'..code,'@actual-resource-resume'))(object,30)
for _,elapsed in ipairs({14,20,29})do
 now=1000+elapsed;resume();eq(object.setButtonProgrees.actions[1].args[1].args[1],30-elapsed,'foreground uses same original deadline')
 eq(BaseViewLastClickCDTime,1000,'foreground does not change deadline')
end
now=1030;resume();assert(object.bIsCenterBtnCanClick);eq(#object.setButtonProgrees.actions,0,'expired foreground clears stale action')
DataManager=savedDM;os.time=oldTime
print('PASS gather reentry/foreground preserve original 30-second deadline; repeated navigation cannot add delay; alchemy remains 0.3 seconds')
