-- Pure Lua 5.1 route/selection/transaction contracts; native geometry is separate.
local realRequire=require
require=function()return true end
class=function()return {}end
BaseView={};cc={p=function(x,y)return{x=x,y=y}end}
rolePack='pack';roleMoney='money';roleBuilding='build';roleMake='make';roleGuideStep='guide'
dataKeyID='id';dataKeyNum='num';csvOfBuild='buildCsv';csvOfResourceInfo='resources'
kUnlockBuild='build';kUnlockMake='make';EFFECT_Button='button'
dofile('bin/res/scripts/LuaClass/BuildMode.lua');dofile('bin/res/scripts/LuaClass/MakeMode.lua')
require=realRequire
local count=0
local function equal(a,b,why)count=count+1;assert(a==b,why..': '..tostring(a)..' ~= '..tostring(b))end
local R=CoherentRecipePage
local rows={{id='1036',num=1,sortId='1'},{id='1036',num=1,sortId='100'}}
local view=setmetatable({recipeKind='make',workerData=rows,recipeSelectedId='1036',recipeSelectedSortId='100',
 ResoucecsvData={['1036']={resume={{'1007',5}}}}},{__index=MakeLayer})
local selected,index=R.selected(view);equal(selected,rows[2],'duplicate resources use original distinct produce sort ID');equal(index,2,'identity preserves row order')
view.recipeSelectedSortId='missing';equal(R.selected(view),nil,'removed sort ID cannot fall through to same resource');view.recipeSelectedSortId='100'
local refreshes,shortages,spends,unlocks,toasts=0,0,0,0,0
local order={};local enough,unlocked,modal=1,true,false
view.initdata=function(self)self.workerData=rows end
view.cheackResoucesOK=function(_,id)equal(id,'1036','exact original resource check');return enough,{{mtId='1007',mtnum='2'}}end
view.useResouces=function(_,id)equal(id,'1036','exact original resource transaction');spends=spends+1;order[#order+1]='resources' end
local originalRefresh=R.refresh;R.refresh=function()refreshes=refreshes+1;order[#order+1]='refresh'end
DataManager={getInstance=function()return{
 getSound_off=function()return 1 end,
 createSuccessCheck=function(_,kind,id)equal(kind,kUnlockMake,'manufacturing unlock owner');equal(id,'100','uses original sort ID, never resource ID');unlocks=unlocks+1;order[#order+1]='unlock';rows={rows[1]}end
}end}
GuideController={getInstance=function()return{getIsHaveStep=function(_,step)equal(step,10,'original manufacture gate');return unlocked end}end}
DialogueViewManager={sharedInstance=function()return{empty=function()return not modal end}end}
ToastUtil={downString=function(_,text)equal(text,'制造成功','original manufacturing toast');toasts=toasts+1;order[#order+1]='toast'end}
Lackmaterial={create=function(_,missing,callback)equal(missing[1].mtnum,'2','shortage exact payload');return{show=function()shortages=shortages+1 end}end}
equal(R.attempt(view),true,'available live recipe succeeds');equal(table.concat(order,','),'resources,unlock,toast,refresh','same original transaction order')
equal(R.attempt(view),false,'disappeared finite recipe cannot replay');equal(spends,1,'no spend replay');equal(unlocks,1,'no unlock replay')
rows={{id='1036',num=-1,sortId='100'}};view.workerData=rows
enough=0;equal(R.attempt(view),false,'shortage does not manufacture');equal(shortages,1,'shortage uses explicit existing acquisition flow');equal(spends,1,'shortage cannot spend')
enough=1;unlocked=false;equal(R.attempt(view),false,'late tutorial lock');equal(spends,1,'lock cannot spend');unlocked=true
modal=true;equal(R.attempt(view),false,'legacy modal blocks underlying action');modal=false
for _,key in ipairs({'recipeDisposed','coherentPageDisposed','coherentPageLeaving','recipeBusy','adventureDialog'})do
 view[key]=true;equal(R.attempt(view),false,key..' prevents stale action');view[key]=false
end
equal(spends,1,'all interruptions preserve resources')
R.refresh=originalRefresh
-- Existing focused construction still wins over the new ordinary-page branch.
local oldInit=R.init;R.init=function(_,kind)return kind end
local initView={applyManagementTheme=function()end,applyCoherentPageShell=function()end,focusTargetId='57',initFocusedBuild=function()return'focused'end}
WarmTheme={enabled=function()return true end}
equal(BuildLayer.init(initView),'focused','focused construction preserved');initView.focusTargetId=nil
equal(BuildLayer.init(initView),'build','ordinary construction opts into recipe composition')
require=function()return true end;equal(MakeLayer.init(initView),'make','ordinary manufacturing uses same composition');require=realRequire
R.init=oldInit
-- Unregister both the legacy full-key slot and its stale short-key alias.
local removed={};local bucket={eventKey=function()end}
DataManager={getInstance=function()return{__eventListener={pack=bucket},unregisterEvent=function(_,key,name)removed[#removed+1]=key..':'..name end}end}
view.recipePresentation=true;view.recipeEvents={'pack','make'};view.recipeEventKey='eventKey'
R.dispose(view);R.dispose(view);equal(#removed,2,'cleanup is idempotent');equal(bucket.eventKey,nil,'legacy short-key listener alias removed')
print('PASS coherent recipe Lua 5.1 routing, duplicate sort IDs, exact transaction owner/order, interruptions, and cleanup: '..count..' assertions')
