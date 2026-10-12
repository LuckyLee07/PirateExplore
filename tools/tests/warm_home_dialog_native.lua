-- Real Cocos/EGL assets, fonts, MenuItem activation and lifecycle; read-only
-- in-memory fixtures only. Run with the existing tutorial-log-native harness.
require 'extern'
require 'LuaClass/Header'
BoldFont='Noto Serif CJK SC'
package.loaded['LuaClass/DataManager']=true
package.loaded['LuaClass/GuideController']=true
local failures={}
local function check(value, message)
 if not value then failures[#failures+1]=message;print('FAIL '..message)end
 return value
end
local function equal(actual,expected,message)return check(actual==expected,message..' ['..tostring(actual)..' ~= '..tostring(expected)..']')end
local function serialize(v)
 if type(v)~='table' then return type(v)..':'..tostring(v)end
 local keys,parts={},{};for k in pairs(v)do keys[#keys+1]=k end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 for _,k in ipairs(keys)do parts[#parts+1]=serialize(k)..'='..serialize(v[k])end
 return '{'..table.concat(parts,',')..'}'
end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local first=assert(source:find('local function readFile(path)',1,true))
local last=assert(source:find("\nlocal soldiers=packagedCSV('soilderAttribute')",first,true))
local csv=assert(loadstring('local equal=function(a,b)assert(a==b)end\n'..source:sub(first,last-1)..'\nreturn packagedCSV','@warm-home-native-csv'))()
local tables={[csvOfResourceInfo]=csv('resourceInfo'),[csvOfSoilderAttribute]=csv('soilderAttribute'),[csvOfBuild]=csv('build')}
local data,events={},{}
local audioFlags={sound=0,music=0,effect=0}
local writes=0
local dm={
 getRoleData=function(_,key)return data[key]end,
 getCSVByID=function(_,key)return tables[key]or{}end,
 registerEvent=function(_,key,name,fn)events[key..':'..name]=fn end,
 unregisterEvent=function(_,key,name)events[key..':'..name]=nil end,
 getSound_off=function()return audioFlags.sound end,getMusic_off=function()return audioFlags.music end,getEffect_off=function()return audioFlags.effect end,
 setRoleData=function()writes=writes+1;error('Home must never write role state')end,
 __roleData={saveData=function()writes=writes+1;error('Home must never save')end,commitAdventure=function()writes=writes+1;error('Home must never commit')end}
}
DataManager={getInstance=function()return dm end}
local dockUnlocked,alchemyUnlocked,recoveryUnlocked=true,true,false
local guide={getIsHaveStep=function(_,step,red)
 if step==8 then return dockUnlocked end
 if step==1 then return alchemyUnlocked end
 if step==30 and red then return recoveryUnlocked end
 return true
end}
GuideController={getInstance=function()return guide end}
ToastUtil={toastString=function(_,text)_G.lastToast=text end}
AudioEngine={}
local scene,viewport
local realGet=cc.Director.getInstance;local director=realGet(cc.Director)
cc.Director.getInstance=function()return setmetatable({getVisibleSize=function()return viewport end,
 getVisibleOrigin=function()return cc.p(0,0)end,getRunningScene=function()return scene end},
 {__index=function(_,key)return function(_,...)return director[key](director,...)end end})end
local Home=require 'LuaClass/WarmHome'
local D=require 'LuaClass/WarmDialog'
local Settings=require 'LuaClass/WarmSettings'
local W=require 'LuaClass/WarmTheme'
local routes={}
zqDispatch={mainMenu={openRoute=function(_,index)routes[#routes+1]=index end},moveToRepository=function()routes[#routes+1]=4 end}
local function fixture()
 data={[roleMoney]=30,[rolePackSize]=20,[roleCabinSize]=1,[roleShipId]='1299',
  [roleSoildierQueue]={['100']={[dataKeyID]='100',[dataKeyNum]=1}},[roleSelectUnit]={['10100']=1,['1005']=12},
  [rolePack]={['1005']=100},[roleBuilding]={{[dataKeyID]='58',[dataKeyNum]=0}},
  adventureProgressV1={version=1,enabled=true,voyage=0,npcRescued=false}}
 dockUnlocked=true;alchemyUnlocked=true;recoveryUnlocked=false;events={}
end
local function event(key)
 local callbacks={};for name,fn in pairs(events)do if name:sub(1,#key+1)==key..':'then callbacks[#callbacks+1]=fn end end
 for _,fn in ipairs(callbacks)do fn()end
end
local function countEvents()local n=0;for _ in pairs(events)do n=n+1 end;return n end
local function visit(node,fn,visible)
 visible=visible~=false and node:isVisible();fn(node,visible)
 for _,child in ipairs(node:getChildren())do visit(child,fn,visible)end
end
local function labelsWithin(root,label)
 visit(root,function(n,visible)
  if visible and n.getString and n:getString()~='' then
   local sz=n:getContentSize()
   local a=n:convertToWorldSpace(cc.p(0,0));local b=n:convertToWorldSpace(cc.p(sz.width,sz.height))
   check(a.x>=-1 and b.x<=viewport.width+1,label..' horizontal: '..n:getString())
   check(a.y>=-1 and b.y<=viewport.height+1,label..' vertical: '..n:getString())
  end
 end)
end
local function buttonWithText(root,text)
 local found
 visit(root,function(n)if n.label and n.item and n.label:getString()==text then found=n.item end end)
 return found
end
local function fresh()
 scene=cc.Scene:create();scene:retain();local home=assert(Home:create());home:retain();scene:addChild(home);return home
end
local function finish(home)
 home:removeFromParent(true);home:release();scene:cleanup();scene:release();scene=nil
 equal(next(events),nil,'Home cleanup removes all read-only subscriptions')
end
for _,height in ipairs({960,1067,1136})do
 viewport=cc.size(640,height);fixture()
 local before=serialize(data);local home=fresh()
 equal(countEvents(),11,'Home subscribes once to eleven state keys')
 check(home.harborArt and home.boatArt and home.shipStage:getChildrenCount()==2,'same clean harbor/boat assets and state decorations constructed')
 check(home.shipW>300 and home.shipH>300,'harbor state decorations have usable world bounds')
 equal(home.crewButton.label:getString(),'船员 · 已选 1','actual crew state belongs to the crew action')
 equal(home.summary.crew,1,'actual selected crew summary')
 equal(home.summary.food,12,'actual selected food summary')
 equal(home.growth:getChildrenCount(),0,'capacity20 has no fabricated growth badge')
 labelsWithin(home,'Home '..height)
 for _=1,3 do home:refreshSummary()end
 equal(serialize(data),before,'Home read-only creation and refresh')
 equal(countEvents(),11,'refresh does not accumulate subscriptions')
 data[rolePackSize]=30;before=serialize(data);event(rolePackSize)
 equal(home.growth:getChildrenCount(),2,'capacity30 adds real growth crate and badge')
 equal(serialize(data),before,'growth event leaves input state unchanged')
 local badge
 visit(home.growth,function(n)if n.getString and n:getString():find('货舱',1,true)then badge=n end end)
 check(badge and badge:getString()=='货舱 30','growth badge reflects real capacity30')
 data[rolePackSize]=60;event(rolePackSize)
 equal(home.growth:getChildrenCount(),2,'growth refresh replaces old decoration rather than accumulating')
 visit(home.growth,function(n)if n.getString and n:getString():find('货舱',1,true)then badge=n end end)
 equal(badge:getString(),'货舱 60','growth badge reacts to capacity60')
 labelsWithin(home,'Grown Home '..height)
 data[rolePackSize]=20;event(rolePackSize);equal(home.growth:getChildrenCount(),0,'capacity20 removes growth decoration')
 data[roleSelectUnit]={};data[roleSoildierQueue]={};event(roleSelectUnit);event(roleSoildierQueue)
 equal(home.summary.crew,0,'zero crew never invents assigned crew')
 equal(home.crewButton.label:getString(),'船员 · 0 人','empty crew action never invents a companion')
 data.adventureProgressV1.npcRescued=true;event('adventureProgressV1')
 equal(home.crewButton.label:getString(),'船员 · 0 人','rescued NPC does not become an owned combat unit')
 data.adventureProgressV1=nil;event('adventureProgressV1');before=serialize(data)
 home:refreshSummary();equal(home.harborState.enabled,false,'absent ledger stays legacy')
 equal(serialize(data),before,'legacy Home refresh does not migrate or grant')
 equal(home.crewButton.label:getString(),'船员 · 0 人','legacy empty roster does not invent companion')
 dockUnlocked=false;event(roleGuideStep)
 equal(home.primaryButton.label:getString(),'准备我们的船','locked legacy Home names actual gate')
 home.primaryButton.item:activate();equal(routes[#routes],3,'real primary callback sends locked dock to construction')
 alchemyUnlocked=false;event(roleGuideStep);home.primaryButton.item:activate();equal(routes[#routes],4,'pre-alchemy callback uses original repository')
 dockUnlocked=true;alchemyUnlocked=true;event(roleGuideStep)
 local modal=Settings.open(home);modal:retain()
 check(home:blocked(),'Home actions blocked while WarmSettingsModal is live')
 modal.doneButton:activate();modal:release();equal(home.warmSettingsModal,nil,'settings Done clears live Home owner')
 for _=1,3 do
  home.portButton.item:activate();local port=assert(home.warmPort);port:retain()
  home:openPort();equal(home.warmPort,port,'duplicate port opens are gated')
  labelsWithin(port,'Port '..height)
  assert(buttonWithText(port,'回到甲板')):activate();equal(home.warmPort,nil,'native port cancel clears ownership')
  equal(port:getParent(),nil,'native port cancel detaches sheet');port:release()
 end
 local actionCalls=0
 modal=D.show('下一段冒险','货舱和补给准备好后，再出发吧。',{
  {label='暂时不能出航',disabled=true,reason='请先准备船员',action=function()actionCalls=actionCalls+1 end},
  {label='继续检查',action=function()actionCalls=actionCalls+1;return false end},
  {label='回到甲板'}},home);modal:retain()
 equal(D.show('重复','',{},home),modal,'contextual dialog duplicate guard')
 labelsWithin(modal,'Dialog '..height)
 modal.warmOptions[1].item:activate();equal(actionCalls,0,'disabled action is not invoked')
 equal(home.adventureDialog,modal,'disabled action keeps dialog visible')
 modal.warmOptions[2].item:activate();equal(actionCalls,1,'real native action called once')
 equal(home.adventureDialog,modal,'false result keeps contextual dialog open')
 modal.warmOptions[3].item:activate();equal(home.adventureDialog,nil,'native cancel closes contextual sheet')
 local replacement=D.show('再看一眼','可随时回到甲板。',{{label='知道了'}},home);replacement:retain()
 modal:close();equal(home.adventureDialog,replacement,'stale close cannot close newer contextual sheet')
 modal:release();replacement:close();replacement:close();replacement:release()
 modal=D.show('离开页面','页面关闭时，这张提示也应关闭。',{{label='知道了'}},home);modal:retain()
 finish(home);equal(modal:getParent(),nil,'Home teardown closes scene-owned WarmDialog');modal:close();modal:release()
 print('PASS native WarmHome/WarmDialog '..height..': assets/fonts, read-only state, zero crew/legacy, reactive growth, native modal callbacks and teardown')
end
-- WarmDialog is a shared utility: owners other than WarmHome also need cleanup.
viewport=cc.size(640,960);scene=cc.Scene:create();scene:retain()
local owner=cc.Node:create();owner:retain();scene:addChild(owner)
local modal=D.show('普通页面','关闭页面后不应留下提示。',{{label='知道了'}},owner);modal:retain()
owner:removeFromParent(true)
check(not modal:isVisible(),'generic owner removal immediately hides its scene-owned WarmDialog')
local actionManager=realGet(cc.Director):getActionManager();actionManager:resumeTarget(modal);actionManager:update(0);actionManager:update(.01)
check(modal:getParent()==nil,'safe later tick removes the generic owner dialog')
check(owner.adventureDialog==nil,'generic owner removal clears contextual dialog ownership')
modal:close();modal:release();owner:release();scene:cleanup();scene:release();scene=nil
local assetNames={'sea-home.png','ship-home.png','crew.png','icons.png'}
for _,name in ipairs(assetNames)do check(cc.FileUtils:getInstance():isFileExist(W.path..name),'real warm asset packaged: '..name)end
equal(writes,0,'native Home/Dialog test made no gameplay/profile/save writes')
cc.Director.getInstance=realGet
assert(#failures==0,table.concat(failures,'\n'))
print('PASS native WarmHome/WarmDialog complete; no gameplay/profile/save writes')
