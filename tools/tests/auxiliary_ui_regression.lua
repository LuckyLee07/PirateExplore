-- Execute the actual auxiliary-page methods with in-memory Cocos/SDK/network
-- fixtures. No HTTP socket, player save, purchase, or live redemption is used.
unpack=unpack or table.unpack
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local function equal(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local Node={}
local function node(kind)return setmetatable({kind=kind,children={},size={width=0,height=0},x=0,y=0,visible=true,enabled=true},{__index=Node})end
function Node:addChild(c,z)assert(c and not c.parent);self.children[#self.children+1]=c;c.parent=self;c.z=z end
function Node:getChildren()return self.children end
function Node:removeFromParent()if self.parent then for i,c in ipairs(self.parent.children)do if c==self then table.remove(self.parent.children,i);break end end end;self.parent=nil end
function Node:getParent()return self.parent end
function Node:setContentSize(v)self.size=v end
function Node:getContentSize()return self.size end
function Node:setPosition(x,y)if type(x)=='table'then self.x=x.x;self.y=x.y else self.x=x;self.y=y end end
function Node:getPosition()return self.x,self.y end
function Node:getPositionX()return self.x end
function Node:getPositionY()return self.y end
function Node:setAnchorPoint(v)self.anchor=v end
function Node:setVisible(v)self.visible=v end
function Node:isVisible()return self.visible end
function Node:setColor(v)self.color=v end
function Node:setOpacity(v)self.opacity=v end
function Node:setScale(v)self.scale=v end
function Node:setFontName(v)self.font=v end
function Node:setFontSize(v)self.fontSize=v end
function Node:setString(v)self.text=v end
function Node:getString()return self.text end
function Node:getStringValue()return self.text end
function Node:setEnabled(v)self.enabled=v end
function Node:setSelectedIndex(v)self.selectedIndex=v end
function Node:registerScriptHandler(v)self.lifecycle=v end
function Node:registerScriptTapHandler(v)self.callback=v end
function Node:setNormalImage(v)self.normal=v end
function Node:setSelectedImage(v)self.selected=v end
function Node:setCascadeOpacityEnabled()end
function Node:ignoreAnchorPointForPosition()end
function Node:drawPolygon()end
function Node:drawSegment()end
function Node:enableStroke()end
function Node:setMaxLengthEnabled(v)self.maxLengthEnabled=v end
function Node:setMaxLength(v)self.maxLength=v end
function Node:setTouchEnabled(v)self.touchEnabled=v end
function Node:setTouchSize(v)self.touchSize=v end
function Node:setPlaceHolder(v)self.placeholder=v end
function Node:addEventListenerTextField(v)self.textListener=v end
function class(_,factory)
    local c={}
    function c.new(...)local n=factory();setmetatable(n,{__index=function(_,k)return c[k] or Node[k] end});return n end
    return c
end
cc={p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end,
    c3b=function(r,g,b)return{r=r,g=g,b=b}end,c4b=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    c4f=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    PLATFORM_OS_LINUX=1,PLATFORM_OS_IPHONE=2,PLATFORM_OS_IPAD=3,PLATFORM_OS_ANDROID=4}
for _,kind in ipairs({'Node','Layer','DrawNode'})do local k=kind;cc[k]={create=function()return node(k)end}end
cc.LayerColor={create=function(_,c,w,h)local n=node('LayerColor');n.color=c;n.size=cc.size(w,h);return n end}
cc.Sprite={create=function(_,path)
    local h=read('bin/res/assets/'..path):sub(1,24)
    local function u32(i)local a,b,c,d=h:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
    local n=node('Sprite');n.size=cc.size(u32(17),u32(21));n.path=path;return n
end}
cc.LabelTTF={create=function(_,text,font,size)local n=node('Label');n.text=tostring(text);n.font=font;n.size=cc.size(#n.text*size*.4,size);return n end}
cc.MenuItemSprite={create=function(_,normal,selected,disabled)local n=node('MenuItemSprite');n.normal=normal;n.selected=selected;n.disabled=disabled;n.size=normal.size;n:addChild(normal);n:addChild(selected);return n end}
cc.MenuItemToggle={create=function(_,...)local n=node('MenuItemToggle');n.subItems={...};n.size=n.subItems[1].size;n.selectedIndex=0;return n end}
cc.Menu={create=function(_,...)local n=node('Menu');for _,c in ipairs({...})do n:addChild(c)end;return n end}
-- Creating the transparent debug entry is itself a failure in release settings.
cc.MenuItemLabel={create=function()error('release settings created a hidden debug target')end}
cc.FileUtils={getInstance=function()return{isFileExist=function()return false end}end}
local viewport=cc.size(640,1136)
cc.Director={getInstance=function()return{getVisibleSize=function()return viewport end,getVisibleOrigin=function()return cc.p(0,0)end}end}
local platform=cc.PLATFORM_OS_LINUX
cc.Application={getInstance=function()return{getTargetPlatform=function()return platform end}end}
ccui={TextField={create=function()return node('TextField')end}}
BoldFont='test';BaseColor=cc.c3b(255,248,224);WriteColor=BaseColor;cclog=function()end
local originalRequire=require
package.path='src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/?.lua;'..package.path
json=originalRequire('json') -- The exact module registered/loaded by the native app.
local _, decodeCursor=json.decode('{}trailing')
equal(decodeCursor,3,'test is using the permissive packaged JSON4Lua decoder')
require=function()return true end
dofile(root..'HomeTheme.lua');dofile(root..'MasterTheme.lua');dofile(root..'DialogTheme.lua')
BaseView={create=function()return node('BaseView')end}
local dialogs={}
DialogueView={create=function()local n=node('DialogueView');n.show=function(self)self.shown=true end;dialogs[#dialogs+1]=n;return n end,close=function(self)self.closed=(self.closed or 0)+1 end}
local messages={}
ToastUtil={toastString=function(_,text)assert(type(text)=='string' and text~='');messages[#messages+1]=text end}
local role={music=0,sound=0,effect=0,saves=0}
for _,name in ipairs({'Music','Sound','Effect'})do
    local key=name:lower()
    role['get'..name]=function(self)return self[key]end
    role['set'..name]=function(self,value)self[key]=value end
end
function role:saveData()self.saves=self.saves+1 end
DataManager={__roleData=role,roles={},achievements=0,rewards={}}
function DataManager:getInstance()return self end
function DataManager:getRoleData(key)return self.roles[key]end
function DataManager:setRoleData(key,value)self.roles[key]=value end
function DataManager:setAchievementInfo()self.achievements=self.achievements+1 end
function DataManager:getCSVByID(key)return self.tables[key]end
function DataManager:cdkExchangeGoods(a,b,c)self.rewards[#self.rewards+1]={a,b,c}end
-- Real persistence entry points, with only RoleData's disk boundary isolated.
local managerSource=read(root..'DataManager.lua')
local audioStart=assert(managerSource:find('function DataManager:getMusic_off()',1,true))
local audioEnd=assert(managerSource:find('\nend',assert(managerSource:find('function DataManager:setEffect_off(',audioStart,true)),true))+4
assert(loadstring(managerSource:sub(audioStart,audioEnd)))()
local audio={pause=0,resume=0,play=0}
AudioEngine={pauseMusic=function()audio.pause=audio.pause+1 end,resumeMusic=function()audio.resume=audio.resume+1 end,playMusic=function(track,loop)equal(track,'main');equal(loop,true);audio.play=audio.play+1 end}
HAS_MUSIC_FILE=1;MUSIC_Main='main'
getEnableInterface=function()return '{"UserCenter":"Disabled"}'end
showMoreGameCallback=function()error('unsupported platform invoked MoreGames')end
roleNickname='nickname';roleArenaMaxRecord='arena';roleExtents='exploration';achievement_Ranking='ranking';csvOfGift='gifts';dataKeyItems='items'
getonlyID=function()return 'local-fixture-user' end
local requests={}
cc.XMLHTTPREQUEST_RESPONSE_JSON=1;cc.XMLHTTPREQUEST_RESPONSE_STRING=2
cc.XMLHttpRequest={new=function()
    local xhr={}
    function xhr:registerScriptHandler(f)self.callback=f end
    function xhr:open(method,url)self.method=method;self.url=url end
    function xhr:send(body)self.body=body;requests[#requests+1]=self end
    return xhr
end}
dofile(root..'HttpSingleton.lua');dofile(root..'Setting.lua');dofile(root..'Ranking.lua');dofile(root..'CDKView.lua')
local function findLabel(n,text)
    if n.text==text then return n end
    for _,c in ipairs(n.children or {})do local r=findLabel(c,text);if r then return r end end
end
local function setting()
    local v=node('Settings');setmetatable(v,{__index=function(_,k)return SettingLayer[k] or Node[k]end})
    v.titleLabel=DialogTheme.label('Settings',36);v.titleBg=node('Title');v.titleHeight=67;v.titleBg.size=cc.size(640,67);v:addChild(v.titleBg)
    v.mainBg=node('Background');v:addChild(v.mainBg)
    v.topLeftBtn=DialogTheme.menuItem('Images/btn/ann02_a.png');v.topRightBtn=DialogTheme.menuItem('Images/btn/ann02_a.png')
    v.topLeftBtnLabel=DialogTheme.label('left',24);v.topRightBtnLabel=DialogTheme.label('back',24)
    v.centerPos=cc.p(320,560);v.originPos=cc.p(0,200);v.areaHeight=700
    function v:resetTopRightButtonToBack()self.backReset=true end
    assert(v:init());return v
end
assert(read(root..'Header.lua'):match('zqDebugMenuEnabled%s*=%s*false'),'release debug gate defaults off')
zqDebug=true;zqDebugMenuEnabled=false
local settings=setting()
equal(settings.backReset,true)
for _,key in ipairs({'musicToggle','soundToggle','effectToggle'})do
    local b=settings[key];equal(b.size.width,100,'original switch hitbox');equal(b.size.height,100)
    equal(b.selectedIndex,0,'initial enabled state');assert(findLabel(b.subItems[1],'开启'));assert(findLabel(b.subItems[2],'关闭'))
    assert(not b.subItems[1].normal.path,'switch no longer paints legacy icon')
    b.callback();equal(b.selectedIndex,1);b.callback();equal(b.selectedIndex,0)
end
equal(role.saves,6,'actual setters persist each setting toggle');equal(audio.pause,1);equal(audio.resume,1);equal(audio.play,0)
HAS_MUSIC_FILE=0;settings.musicToggle.callback();settings.musicToggle.callback();equal(audio.play,1,'missing music starts original track')
settings.soundToggle.callback();settings.effectToggle.callback();settings.musicToggle.callback()
local reopened=setting()
for _,key in ipairs({'musicToggle','soundToggle','effectToggle'})do equal(reopened[key].selectedIndex,1,'reopen reads saved off state')end
equal(role.saves,11,'opening settings never writes setting values')
findLabel(reopened,'更多游戏').parent.callback();equal(messages[#messages],'此平台暂不支持更多游戏')
zqDebugMenuEnabled=nil;setting() -- Missing flag must also create no debug target.

local function ranking()
    local r=setmetatable({ranktype=1,rankData={},button=node('Menu'),statusLabel=node('Label'),ranktypeLabel=node('Label'),reloads=0},{__index=RankingLayer})
    r.tableviewT={reloadData=function()r.reloads=r.reloads+1 end}
    function r:superDestory()self.destroyed=true end
    RankingLayer.instance=r;return r
end
local function respond(xhr,response,status)xhr.response=response;xhr.status=status or 200;xhr.callback()end
local r=ranking();local before=#requests
assert(not r:httpConnection(1,0));equal(#requests,before,'unconfigured ranking never sends');equal(r.button.enabled,true)
equal(r.statusLabel.text,'排行榜服务暂未配置')
for i=1,4 do r:changeRankType();equal(r.button.enabled,true)end
equal(r.ranktype,1);equal(#requests,before,'repeated tab changes cannot send malformed URLs')
r.serviceURL='https://ranking.invalid/?'
local failures={'{"mine":{"nickname":""},"top100":[]}','{"mine":{"nickname":"　"},"top100":[]}','{"mine":{"nickname":false},"top100":[]}','{"mine":1,"top100":[]}','{"mine":[],"top100":[]}','{"st\\u0061tus":1002,"top100":[]}','{"top100":[{"rank":1,"nickname":"\\u5929\\u4f7f","amount":3}]}','{"top100":{}}','{"top100":[{"rank":0.5,"nickname":"A","amount":3}]}','{"top100":[{"rank":1,"nickname":" ","amount":3}]}','{"top100":[]}garbage','{"status":1002,"top100":[]}','{"top100":[{"rank":"1e999","nickname":"A","amount":3}]}','{"top100":[{"rank":1,"nickname":"A","amount":"1e999"}]}','{"top100":[{"rank":1e999,"nickname":"A","amount":3}]}','{"top100":[] "mine":{}}','{"top100":[,]}','{"top100":[],}','{"top100":[],"top100":[]}','{"top100":[]}/*comment*/','','   ','{broken','null','true','{"top100":true}','{"top100":{"bad":1}}','{"top100":[null]}','{"top100":[{"rank":1}]}','{}'}
for _,response in ipairs(failures)do
    local success, beforeAchievements, beforeName = false, DataManager.achievements, DataManager.roles.nickname
    assert(r:httpConnection(1,0,nil,function(value)success=value end));equal(r.button.enabled,false);respond(requests[#requests],response)
    equal(r.button.enabled,true,'error restores ranking navigation');equal(r._requestPending,false);equal(#r.rankData,0)
    equal(success,false,'malformed/failed response never signals success');equal(DataManager.achievements,beforeAchievements,'malformed/failed response never grants achievement');equal(DataManager.roles.nickname,beforeName,'malformed/failed response never changes nickname')
end
assert(r:httpConnection(1,0));respond(requests[#requests],'{}',503);equal(r.button.enabled,true,'HTTP failure restores controls')
assert(r:httpConnection(1,0));respond(requests[#requests],'{"top100":[]}');equal(r.statusLabel.text,'暂无排名数据')
local valid='{"mine":{"nickname":"Sailor"},"top100":[{"rank":1,"nickname":"Sailor","amount":3}]}'
for i=1,2 do assert(r:httpConnection(1,3));respond(requests[#requests],valid);equal(#r.rankData,1,'reload replaces, not appends duplicate ranks')end
equal(DataManager.roles.nickname,'Sailor');equal(r.statusLabel.visible,false)
assert(r:httpConnection(1,3));respond(requests[#requests],'{"top100":[{"rank":1,"nickname":"海盗","amount":3}]}');equal(r.rankData[1].nickname,'海盗','raw UTF-8 nicknames remain unchanged')
DataManager.roles.arena='bad';equal(r:getValue(1),0,'malformed saved score is safe');DataManager.roles.arena='7';equal(r:getValue(1),'7')
local dialogCount=#dialogs
assert(r:httpConnection(1,0));respond(requests[#requests],'{"status":1001}');equal(#dialogs,dialogCount+1);equal(dialogs[#dialogs].shown,true,'missing nickname opens one bound input form');equal(dialogs[#dialogs].ranking,r)
local name=InputNameView:create(r)
equal(name.textField.font,MasterTheme.headingFont(false),'nickname editor uses full CJK body font')
for _,value in ipairs({'',' \t\n','　'})do name.textField.text=value;local count=#requests;name.submitButton.callback();equal(#requests,count);equal(name.closed,nil);equal(name.submitButton.enabled,true)end
name.textField.text=nil;assert(not name:submitName());equal(name.closed,nil)
name.textField.text='Sailor';assert(name:submitName());equal(name.submitButton.enabled,false);local sent=#requests;assert(not name:submitName());equal(#requests,sent,'double tap sends once')
respond(requests[#requests],'{"status":1002}');equal(name.closed,nil);equal(name.submitButton.enabled,true,'invalid nickname remains editable')
assert(name:submitName());respond(requests[#requests],'{"mine":{"nickname":""},"top100":[]}');equal(name.closed,nil,'malformed own nickname cannot close registration');equal(name.submitButton.enabled,true)
assert(name:submitName());respond(requests[#requests],valid);equal(name.closed,1,'only successful registration closes')
local noBackend=InputNameView:create(ranking());noBackend.textField.text='Sailor';assert(not noBackend:submitName());equal(noBackend.closed,nil);equal(noBackend.submitButton.enabled,true)
local cancelled=InputNameView:create(r);cancelled.textField.text='Sailor';assert(cancelled:submitName());cancelled:close();respond(requests[#requests],valid);equal(cancelled.closed,1,'late callback does not close removed form twice')
local exited=InputNameView:create(r);exited.textField.text='Sailor';assert(exited:submitName());exited.lifecycle('exit');respond(requests[#requests],valid);equal(exited.closed,nil,'scene exit makes nickname callback inert')
local replacement=RankingLayer.instance
assert(r:httpConnection(1,3));local abandoned=requests[#requests];local oldReloads=r.reloads;r:destory();respond(abandoned,valid);equal(r.reloads,oldReloads,'late result never touches destroyed ranking');equal(RankingLayer.instance,replacement,'old page cannot clear newer singleton');replacement:destory();equal(RankingLayer.instance,nil)
local transport=HttpSingleton:getInstance();local send=transport.send;transport.send=function()error('local send failure')end
r=ranking();r.serviceURL='https://ranking.invalid/?';assert(not r:httpConnection(1,0));equal(r.button.enabled,true,'synchronous transport error restores controls');transport.send=send

local encode=json.encode;json.encode=function()error('local encode failure')end
assert(not r:httpConnection(1,0));equal(r.button.enabled,true,'encoding failure restores controls');json.encode=encode

local cdk=CDKView:create();equal(cdk.textField.font,MasterTheme.headingFont(false),'CDK editor uses full CJK body font');local decodeCalls=0
decodeExKey=function()decodeCalls=decodeCalls+1;return false end
for _,value in ipairs({'',' \n','　'})do cdk.textField.text=value;cdk.submitButton.callback();equal(cdk.closed,nil);equal(decodeCalls,0)end
assert(not cdk:requestNetwork(nil));local count=#requests
assert(not cdk:requestNetwork('LOCAL-FIXTURE'));equal(#requests,count,'no unrelated connectivity probe');equal(decodeCalls,0,'unsupported platform never invokes SDK')
platform=cc.PLATFORM_OS_IPHONE
assert(not cdk:requestNetwork('LOCAL-FIXTURE'));equal(decodeCalls,0,'disabled capability never invokes SDK')
getEnableInterface=function()return '{broken' end;assert(not cdk:requestNetwork('LOCAL-FIXTURE'));equal(decodeCalls,0)
getEnableInterface=function()return '{"UserCenter":"Enabled"}' end
assert(not cdk:requestNetwork('LOCAL-FIXTURE'));equal(decodeCalls,1);equal(cdk.closed,nil);equal(cdk.submitButton.enabled,true)
decodeExKey=function()error('local SDK failure')end;assert(not cdk:requestNetwork('LOCAL-FIXTURE'));equal(cdk.submitButton.enabled,true)
decodeExKey=function(code)equal(code,'LOCAL-FIXTURE');return true end
assert(cdk:requestNetwork('LOCAL-FIXTURE'));equal(cdk.closed,1);equal(#DataManager.rewards,0,'SDK remains sole reward owner')
cdk=CDKView:create();assert(not cdk:httpConnection('LOCAL-FIXTURE'));equal(#requests,count,'empty CDK endpoint never sends');equal(cdk.closed,nil)
DataManager.tables={gifts={['1']={items={{1,'original-item',2},{2,'original-resource',3}}}}}
cdk.serviceURL='https://redemption.invalid/?'
for _,response in ipairs({'','{broken','null','false','{}','{"status":7}','{"dropId":"missing"}','{"dropId":1}garbage','{"status":null,"dropId":1}','{"status":7,"dropId":1}','{"dropId":1+0}'})do
    assert(cdk:httpConnection('LOCAL-FIXTURE'));equal(cdk.submitButton.enabled,false);respond(requests[#requests],response)
    equal(cdk.submitButton.enabled,true);equal(cdk.closed,nil);equal(#DataManager.rewards,0,'invalid response never grants goods')
end
DataManager.tables.gifts['bad']={items={{1,'item',1},{1}}}
assert(cdk:httpConnection('LOCAL-FIXTURE'));respond(requests[#requests],'{"dropId":"bad"}');equal(#DataManager.rewards,0,'validate all gifts before any grant')
assert(cdk:httpConnection('LOCAL-FIXTURE'));local success=requests[#requests];local sent=#requests;assert(not cdk:httpConnection('LOCAL-FIXTURE'));equal(#requests,sent)
respond(success,'{"dropId":1}');equal(#DataManager.rewards,2);equal(cdk.closed,1)
respond(success,'{"dropId":1}');equal(#DataManager.rewards,2,'duplicate callback never grants twice')
equal(table.concat(DataManager.rewards[1],','),'1,original-item,2','original gift tuple unchanged')
local dismissed=CDKView:create();dismissed.serviceURL=cdk.serviceURL;assert(dismissed:httpConnection('LOCAL-FIXTURE'));local pending=requests[#requests];dismissed:close();respond(pending,'{"dropId":1}');equal(#DataManager.rewards,4,'successful submitted redemption survives dismissal');equal(dismissed.closed,1)
local exitedCDK=CDKView:create();exitedCDK.serviceURL=cdk.serviceURL;assert(exitedCDK:httpConnection('LOCAL-FIXTURE'));local exitRequest=requests[#requests];exitedCDK.lifecycle('exit');respond(exitRequest,'{}');equal(exitedCDK.closed,nil,'scene exit never closes a removed CDK dialog')
-- Exercise the actual shared transport with two requests completing backwards.
local completions={}
transport:send(transport.POST,'https://first.invalid/',{type='local'},function(xhr)completions[#completions+1]='first:'..xhr.response end)
local first=requests[#requests]
transport:send(transport.POST,'https://second.invalid/',{type='local'},function(xhr)completions[#completions+1]='second:'..xhr.response end)
local second=requests[#requests]
respond(second,'B');respond(first,'A');equal(table.concat(completions,','),'second:B,first:A','callbacks stay request-local')
equal(first.timeout,6,'existing request timeout retained')
require=originalRequire
print('PASS actual settings/reopen/persistence entry points, release debug exclusion, ranking/nickname failure and close recovery, CDK validation/SDK/HTTP reward safety, and out-of-order HTTP callbacks (local fixtures only)')
