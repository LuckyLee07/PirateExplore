-- Focused construction dispatch/transaction guard contracts with no Cocos/save.
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('bin/res/scripts/LuaClass/BuildMode.lua')
local originalRequire=require
require=function()return true end
class=function()return {}end
BaseView={};rolePack='pack';roleMoney='money';roleBuilding='build';roleGuideStep='guide'
dataKeyID='id';dataKeyNum='num';csvOfBuild='buildCsv';csvOfResourceInfo='resources'
kUnlockBuild='build';EFFECT_Button='button'
cc={p=function(x,y)return{x=x,y=y}end}
dofile('bin/res/scripts/LuaClass/BuildMode.lua')
require=originalRequire
local function equal(a,b,why)assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local rows={{id='58',num=0},{id='57',num=0},{id='6',num=1}}
local view=setmetatable({focusTargetId='57',roleBuildingData=rows},{__index=BuildLayer})
equal(view:focusedEntry(),rows[2],'lookup returns original row');equal(view:getDataNum(),3,'focused lookup preserves complete current list')
equal(rows[1].id,'58','lookup never sorts');equal(rows[3].num,1,'lookup never discards built entries')
local themed,focused=0,0
view.applyManagementTheme=function()themed=themed+1 end
view.initFocusedBuild=function()focused=focused+1;return 'focused' end
WarmTheme={enabled=function()return true end}
equal(view:init(),'focused','focused entry branches before legacy dashboard');equal(themed,1,'theme initializes before focused detail');equal(focused,1,'focus initializes once')
-- The full construction path and legacy opt-out still start with their original
-- event registration. Stop at that boundary without building fake UI nodes.
local calls=0
local dm={registerEvent=function(_,key,name,callback)
 equal(key,'roleMapInfo','full construction map observer');equal(name,'BuildLayer','original observer key')
 calls=calls+1;error('full-list-boundary')
end}
roleMapInfo='roleMapInfo';DataManager={getInstance=function()return dm end}
view.focusTargetId=nil
local ok,err=pcall(function()view:init()end)
assert(not ok and err:find('full%-list%-boundary'));equal(calls,1,'unfocused entry retains original flow')
view.focusTargetId='57';WarmTheme.enabled=function()return false end
ok,err=pcall(function()view:init()end)
assert(not ok and err:find('full%-list%-boundary'));equal(calls,2,'legacy opt-out retains original focused-scroll flow')
-- Original full-list utilities/table/transaction remain in the unfocused body.
local body=assert(source:match('function BuildLayer:init%(%)\n(.-)\nfunction BuildLayer:initdata'))
for _,fragment in ipairs({'self:addInfoNode(', 'DataManager:getInstance():AlchemyButtonDidClick()',
 'self.roleBuildingData[idx]', 'return self:getDataNum()', 'self:focusEntry(self.focusTargetId)',
 'self:useResouces(_csvID)', 'DataManager:getInstance():createSuccessCheck(kUnlockBuild, _csvID)',
 'Lackmaterial:create(templacktable,function ()'})do
 assert(body:find(fragment,1,true),'original full construction path missing: '..fragment)
end
-- A focused callback does not bypass the existing resource or unlock owners.
local order={};local locked=false;local enough=1;local built=0
view.focusedBuildPresentation=true;view.focusedBuildDisposed=false;view.focusedBuildLeaving=false
view.csvData={['57']={resume={{'1001',25},{'1006',15},{'1008',2}}}}
view.initdata=function(self)self.roleBuildingData=rows end
view.refreshFocusedBuild=function()order[#order+1]='refresh' end
view.cheackResoucesOK=function(_,id)equal(id,'57','original recipe check');return enough,{{mtId='1001',mtnum='1'}}end
view.useResouces=function(_,id)equal(id,'57','original recipe deduction');order[#order+1]='resources' end
dm.getSound_off=function()return 1 end
dm.createSuccessCheck=function(_,kind,id)equal(kind,kUnlockBuild,'original unlock kind');equal(id,'57','original forge unlock');order[#order+1]='unlock';rows[2].num=1;built=built+1 end
GuideController={getInstance=function()return{getIsHaveStep=function(_,step)equal(step,1,'construction gate');return not locked end}end}
ToastUtil={downString=function(_,text)equal(text,'建造成功','original success feedback');order[#order+1]='toast' end}
local modal=false;DialogueViewManager={sharedInstance=function()return{empty=function()return not modal end}end}
assert(view:attemptFocusedBuild());equal(table.concat(order,','),'resources,unlock,toast,refresh','original success call order')
assert(not view:attemptFocusedBuild());equal(built,1,'already built target cannot replay')
rows[2].num=0;locked=true;assert(not view:attemptFocusedBuild());equal(built,1,'late guide lock blocks build')
locked=false;modal=true;assert(not view:attemptFocusedBuild());equal(built,1,'existing modal blocks underlying construction')
modal=false;enough=0;local shows=0
Lackmaterial={create=function(_,missing,callback)equal(missing[1].mtnum,'1','original shortage payload');return{show=function()shows=shows+1 end}end}
assert(not view:attemptFocusedBuild());equal(shows,1,'shortage opens existing explicit material-acquisition UI');equal(built,1,'shortage does not build or auto-buy')
view.focusedBuildDisposed=true;assert(not view:attemptFocusedBuild());equal(shows,1,'disposed view cannot open dialog')
print('PASS coherent focused forge routing, unchanged full-list/legacy flow, full building list, transaction owners, live gates and no automatic purchase')
