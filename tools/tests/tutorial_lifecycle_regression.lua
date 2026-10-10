-- Production tutorial/dialog methods with isolated Cocos test doubles and CSV/save
-- fixtures. Uses the shipped class implementation and real PNG geometry. This is
-- a logic/geometry regression, not native GUI acceptance, and opens no player save.
unpack=unpack or table.unpack
local root='bin/res/scripts/LuaClass/'
local Node={}
local dispatcher={}
local function node(kind) return setmetatable({kind=kind,children={},size={width=0,height=0},x=0,y=0,visible=true,scale=1},{__index=Node}) end
function Node:addChild(c,z) assert(c and not c.parent);self.children[#self.children+1]=c;c.parent=self;c.z=z or 0 end
function Node:removeFromParent() if self.parent then for i,c in ipairs(self.parent.children) do if c==self then table.remove(self.parent.children,i);break end end end;self.parent=nil;if self.scriptHandler then self.scriptHandler('exit') end end
function Node:getParent() return self.parent end
function Node:getChildren() return self.children end
function Node:setContentSize(s) self.size=s end
function Node:getContentSize() return self.size end
function Node:setPosition(x,y) if type(x)=='table' then self.x=x.x;self.y=x.y else self.x=x;self.y=y end end
function Node:getPosition() return self.x,self.y end
function Node:getPositionX() return self.x end
function Node:getPositionY() return self.y end
function Node:setPositionY(v) self.y=v end
function Node:setAnchorPoint(a) self.anchor=a end
function Node:getBoundingBox() return {x=self.x-self.size.width*self.anchor.x,y=self.y-self.size.height*self.anchor.y,width=self.size.width,height=self.size.height} end
function Node:setVisible(v) self.visible=v end
function Node:isVisible() return self.visible end
function Node:setScale(v) self.scale=v end
function Node:setColor(v) self.color=v end
function Node:setOpacity(v) self.opacity=v end
function Node:getOpacity() return self.opacity or 255 end
function Node:setFontName(v) self.font=v end
function Node:setFontSize(v) self.fontSize=v end
function Node:disableStroke() self.strokeDisabled=true end
function Node:setString(v) self.text=v;self.size=cc.size(#v*(self.fontSize or 20)*.4,self.fontSize or 20) end
function Node:getString() return self.text end
function Node:setTag(v) self.tag=v end
function Node:getTag() return self.tag end
function Node:setCascadeOpacityEnabled(v) self.cascade=v end
function Node:setLocalZOrder(v) self.z=v end
function Node:ignoreAnchorPointForPosition() end
function Node:drawPolygon() end
function Node:drawSegment() end
function Node:drawTriangle(...) self.triangles=self.triangles or {};self.triangles[#self.triangles+1]={...} end
function Node:getViewSize() return self.viewSize or self.size end
function Node:setContentOffset(v) self.offset=v end
function Node:stopAllActions() end
function Node:getEventDispatcher() return dispatcher end
function Node:registerScriptTapHandler(f) self.callback=f end
function Node:setNormalImage(n) self.normal=n end
function Node:setSelectedImage(n) self.selected=n end
function dispatcher:addEventListenerWithSceneGraphPriority(listener,owner) owner.touchListener=listener end
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/extern.lua')
cc={p=function(x,y)return{x=x,y=y}end,size=function(w,h)return{width=w,height=h}end,
    rect=function(x,y,w,h)return{x=x,y=y,width=w,height=h}end,
    c3b=function(r,g,b)return{r=r,g=g,b=b}end,c4b=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    c4f=function(r,g,b,a)return{r=r,g=g,b=b,a=a}end,
    Handler={EVENT_TOUCH_BEGAN=1,EVENT_TOUCH_MOVED=2,EVENT_TOUCH_ENDED=3}}
for _,kind in ipairs({'Node','Layer','DrawNode','Scene','NodeGrid'}) do local k=kind;cc[k]={create=function()return node(k)end} end
cc.LayerColor={create=function(_,c,w,h)local n=node('LayerColor');n.color=c;n.size=cc.size(w or 640,h or 1136);return n end}
cc.Sprite={create=function(_,path,rect)
    local f=assert(io.open('bin/res/assets/'..path,'rb'));local h=f:read(24);f:close()
    local function u32(i)local a,b,c,d=h:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
    local n=node('Sprite');n.size=rect and cc.size(rect.width,rect.height) or cc.size(u32(17),u32(21));n.path=path;return n
end}
cc.LabelTTF={create=function(_,s,font,size)local n=node('LabelTTF');n.text=tostring(s);n.font=font;n.fontSize=size;n.size=cc.size(#n.text*size*.4,size);return n end}
cc.MenuItemSprite={create=function(_,normal,selected,disabled)local n=node('MenuItemSprite');n.size=normal:getContentSize();n.normal=normal;n.selected=selected;n.disabled=disabled;n:addChild(normal);n:addChild(selected);return n end}
cc.Menu={create=function(_,...)local n=node('Menu');for _,c in ipairs({...})do n:addChild(c)end;return n end}
cc.EventListenerTouchOneByOne={create=function()return{handlers={},registerScriptHandler=function(self,f,id)self.handlers[id]=f end,setSwallowTouches=function(self,v)self.swallow=v end}end}
cc.FileUtils={getInstance=function()return{isFileExist=function()return false end}end}
local scene=node('Scene');local viewport=cc.size(640,1136)
cc.Director={getInstance=function()return{getWinSize=function()return viewport end,getVisibleSize=function()return viewport end,getRunningScene=function()return scene end}end}
ccui={TouchEventType={ended=2}}
BoldFont='legacy-bold';WriteColor=cc.c3b(255,255,255);cclog=function()end
cc.PLATFORM_OS_LINUX=1;cc.Application={getInstance=function()return{getTargetPlatform=function()return 1 end}end}
require=function()return true end
dofile(root..'HomeTheme.lua');dofile(root..'MasterTheme.lua');dofile(root..'DialogTheme.lua')
dofile(root..'SDButton.lua');dofile(root..'AlertView.lua')
local function equal(a,b,why)assert(a==b,(why or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function findLabel(n,text)
    if n.text==text then return n end
    for _,c in ipairs(n.children) do local found=findLabel(c,text);if found then return found end end
end

function Node:setHorizontalAlignment(v) self.horizontal=v end
function Node:setVerticalAlignment(v) self.vertical=v end
function Node:registerScriptHandler(f) self.scriptHandler=f end
function Node:getSpriteFrame() return self.path end
function Node:removeAllChildren() while #self.children>0 do self.children[1]:removeFromParent() end end
function Node:runAction(a) self.actions=self.actions or {};self.actions[#self.actions+1]=a;return a end
function Node:stopAllActions() self.actions={} end
function Node:setScaleX(v) self.scaleX=v end
function Node:setScaleY(v) self.scaleY=v end
function Node:setRotation(v) self.rotation=v end
function dispatcher:setPriority(listener,value) listener.priority=value end
cc.Scale9Sprite={create=function(_,path) local n=cc.Sprite:create(path);n.kind='Scale9Sprite';return n end}
cc.MenuItemImage={create=function(_,path,selected)local n=node('MenuItemImage');n.path=path;n.size=cc.Sprite:create(path):getContentSize();return n end}
cc.SpriteFrameCache={getInstance=function()return{addSpriteFrame=function()end}end}
for _,kind in ipairs({'FadeIn','FadeOut','DelayTime','ScaleTo','RotateBy','MoveBy','EaseOut','Sequence','Spawn','RepeatForever'}) do
    local k=kind;cc[k]={create=function(_,...)return{kind=k,args={...}}end}
end
cc.CallFunc={create=function(_,fn)return{kind='CallFunc',callback=fn}end}
EffectUtil={getAnimate=function(_,path,first,last,time)return{kind='Animate',path=path,first=first,last=last,time=time}end}
local function executeAction(a,owner)
    if a.kind=='CallFunc' then a.callback(owner)
    elseif a.kind=='Sequence' or a.kind=='Spawn' then for _,child in ipairs(a.args)do executeAction(child,owner)end end
end
local tables,state,rewards,writes,now={},{},{},0,20000*86400
roleSevenDayBonus='seven';csvOfLogingReward='login';csvOfPlot='plot'
local data={}
function data:getRoleData(key)return state[key]end
function data:setRoleData(key,value)state[key]=value;writes=writes+1 end
function data:getCSVByID(key)return tables[key]end
function data:addPackItemWithId(id,num,toast)rewards[#rewards+1]={'item',id,num,toast}end
function data:addSoilderWithId(id,num,toast)rewards[#rewards+1]={'hero',id,num,toast}end
DataManager={getInstance=function()return data end}
NotificationNode={getInstance=function()return{GetGameTime=function()return now end}end}
dofile(root..'ExploreGuideComponent.lua');dofile(root..'PlotMode.lua');dofile(root..'PlotLayer.lua')
dofile(root..'SevenDayBonus.lua')
local passed,failed=0,0
local function test(name,fn)
    local ok,err=pcall(fn)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name..': '..tostring(err))end
end

test('first-sailing descriptor and tip surfaces resize without accumulating art',function()
    local screen,mapLayer,map=node('Screen'),node('MapLayer'),node('Map')
    screen:addChild(mapLayer);mapLayer:addChild(map)
    local guide=assert(ExploreGuideComponent:create(map))
    equal(guide.desBox.kind,'Scale9Sprite','descriptor keeps native resize contract')
    equal(guide.tipBox.kind,'Scale9Sprite','tip keeps native resize contract')
    equal(guide.desBox.parent,screen);equal(guide.tipBox.parent,screen)
    equal(guide.desBox.x,320);equal(guide.desBox.y,618)
    equal(guide.desLaebl.x,320);equal(guide.desLaebl.y,623)
    equal(guide.tipBox.x,320);equal(guide.tipBox.y,852)
    equal(guide.tipLable.x,320);equal(guide.tipLable.y,852)
    equal(guide.desLaebl.font,MasterTheme.headingFont(false),'descriptor B font')
    equal(guide.tipLable.font,MasterTheme.headingFont(false),'tip B font')
    equal(guide.desBox.opacity,0,'legacy descriptor artwork hidden')
    equal(guide.tipBox.opacity,0,'legacy tip artwork hidden')
    for _,text in ipairs({'这是哪,我在瓶子中吗?','这片海域看起来好恐怖..','先驾驶海盗船到旁边看看','短句'})do
        guide:showDes(text,cc.p(1,2))
        local z=guide.desLaebl:getContentSize();local box=guide.desBox:getContentSize()
        equal(box.width,z.width*1.1);equal(box.height,z.height*1.4)
        equal(#guide.desBox.children,1,'one descriptor material after each resize')
        equal(guide.desBox.children[1]:getContentSize().width,box.width)
        equal(guide.desBox.children[1]:getContentSize().height,box.height)
        equal(guide.desBox.x,320,'original screen-space position retained')
    end
    for _,text in ipairs({'点击右侧屏幕可向右移动','酷!我们已经开始航行了','报告船长远处发现一座小岛','让我们过去一探究竟!','点击上方屏幕向小岛移动'})do
        guide:showTipsByPosition(text,cc.p(1,2))
        local z=guide.tipLable:getContentSize();local box=guide.tipBox:getContentSize()
        equal(box.width,z.width*1.1);equal(box.height,z.height*1.1)
        equal(#guide.tipBox.children,1,'one tip material after each resize')
        equal(guide.tipBox.children[1]:getContentSize().width,box.width)
        equal(guide.tipBox.children[1]:getContentSize().height,box.height)
    end
    guide:showFingerActionByPosition(cc.p(120,300))
    equal(guide.halo.x,120);equal(guide.halo.y,300)
    equal(guide.finger.path,'Images/Map/Guide/finger_1.png')
    equal(guide.halo.path,'Images/Map/Guide/halo.png')
    equal(guide.finger.actions[1].args[1].time,.3,'finger animation speed retained')
    guide:hideAllComponents()
    for _,key in ipairs({'finger','halo','desLaebl','desBox','tipLable','tipBox'})do equal(guide[key].visible,false,key..' hides')end
    local mine=node('Mine');guide:changeFingerParent(mine);guide:showFingerActionByPosition(cc.p(77,88))
    equal(guide.finger.parent,mine);equal(guide.halo.parent,mine)
    equal(guide.halo.x,77);equal(guide.halo.y,88)
    equal(#map.children,0,'old map pointers removed')
    equal(guide.desBox.parent,screen,'mine does not move tutorial prose')
    -- Exercise the bundled material path as well as the missing-art fallback.
    local oldFiles=cc.FileUtils
    cc.FileUtils={getInstance=function()return{isFileExist=function(_,path)
        local file=io.open('bin/res/assets/'..path,'rb');if file then file:close();return true end;return false
    end}end}
    guide:showDes('真实材质');guide:showTipsByPosition('点击右侧屏幕可向右移动')
    equal(#guide.desBox.children,1);equal(#guide.tipBox.children,1)
    equal(guide.desBox.children[1].children[2].children[1].path,MasterTheme.path..'materials.png','shipped ink material')
    cc.FileUtils=oldFiles
end)

test('opening plot skip retains geometry, one-shot callback and story timing',function()
    tables.plot={['1']={ID='1',iconID='juqing_1',stayTime='6',story={{'one'},{'two'}}},
        ['8']={ID='8',iconID='juqing_1',stayTime='6',story={{'one'},{'two'}}}}
    local callbacks=0
    local plot=assert(PlotScene:create(1,function()callbacks=callbacks+1 end))
    local menu=plot.children[3];local skip=assert(menu.children[1])
    equal(skip.kind,'MenuItemSprite','B-material native menu item')
    equal(skip:getContentSize().width,36);equal(skip:getContentSize().height,36)
    equal(skip.x,540);equal(skip.y,100);equal(menu.z,1000)
    equal(#skip.children[3].triangles,2,'two native skip marks')
    local action=plot.actions[1];equal(action.kind,'Sequence')
    equal(action.args[4].args[1],3,'first original story duration')
    equal(action.args[6].args[1],3,'second original story duration')
    equal(action.args[7].args[1],1.5,'original final story pause')
    executeAction(action.args[1],plot)
    equal(plot.children[1].children[1].children[1].path,'Images/Plot/juqing_1.png','original story art')
    skip.callback();skip.callback();equal(#plot.actions,2,'repeat skip schedules callback once')
    executeAction(plot.actions[2],plot);equal(callbacks,1)
    local later=assert(PlotScene:create(8,function()end));equal(#later.children,2,'no new skip for later stories')
end)

test('plot overlay claims and swallows touch without changing delay',function()
    tables.plot={}
    local plot=assert(PlotLayer:create(nil,{{'fixture'}}))
    equal(plot.touchListener.swallow,true)
    equal(plot.touchListener.handlers[cc.Handler.EVENT_TOUCH_BEGAN]({},{}),true,'touch-began must claim the touch')
    equal(plot.touchListener.priority,-1000);equal(plot.delayTime,2)
end)

local function resetBonus()
    -- Each isolated case loads the actual module, resetting only its private
    -- singleton; the tested create/init/claim/destory methods remain untouched.
    scene:removeAllChildren()
    dofile(root..'SevenDayBonus.lua')
    state={seven=0};rewards={};writes=0;now=20000*86400;tables.login={}
    for i=1,7 do tables.login[tostring(i)]={ID=tostring(i),day='day '..i,Tips={{'fixture'}},
        reward={{'1','item-'..i,'3'},{'2','hero-'..i,'2'}}}end
end
local function claimButton(view)return assert(findLabel(view,'领  取'),'real claim label').parent end

test('seven-day claim releases singleton and permits next-day show in same process',function()
    resetBonus()
    local first=assert(SevenDayBonusLayer:create());equal(SevenDayBonusLayer:create(),nil,'one open bonus only')
    claimButton(first).callback();equal(first:getParent(),nil)
    equal(state.seven,1020000,'first claim saves original epoch-day encoding')
    equal(#rewards,2);equal(rewards[1][1],'item');equal(rewards[1][2],'item-1');equal(rewards[1][3],3)
    equal(rewards[2][1],'hero');equal(rewards[2][2],'hero-1');equal(rewards[2][3],2)
    now=now+86400
    local second=assert(SevenDayBonusLayer:create(),'claimed dialog leaves stale singleton')
    equal(SevenDayBonusLayer:create(),nil)
    claimButton(second).callback();equal(state.seven,2020001,'next-day count and timestamp retain original encoding')
    equal(rewards[3][2],'item-2');equal(rewards[4][2],'hero-2')
end)

test('repeated or reentrant seven-day claim cannot award or save twice',function()
    resetBonus()
    local first=assert(SevenDayBonusLayer:create());local callback=claimButton(first).callback
    local original=data.addPackItemWithId
    function data:addPackItemWithId(...) original(self,...);callback() end
    local ok,err=pcall(callback);data.addPackItemWithId=original;assert(ok,err)
    callback();equal(#rewards,2,'one reward payload');equal(writes,1,'one encoded-day save')
end)

test('same-date reopen and queued delayed shows cannot claim tomorrow early',function()
    resetBonus()
    -- NotificationNode queues this production create call after checking the
    -- date. Eligibility must still hold when each queued callback actually runs.
    local delayedShow=function()return SevenDayBonusLayer:create()end
    local first=assert(delayedShow());claimButton(first).callback()
    equal(state.seven,1020000);equal(#rewards,2);equal(writes,1)
    equal(delayedShow(),nil,'second queued show on the claimed date is suppressed')
    equal(SevenDayBonusLayer:create(),nil,'same-date manual reopen is suppressed')
    equal(state.seven,1020000);equal(#rewards,2);equal(writes,1)
    now=now+86400
    local nextDay=assert(delayedShow(),'next calendar day remains eligible')
    claimButton(nextDay).callback()
    equal(state.seven,2020001);equal(rewards[3][2],'item-2');equal(rewards[4][2],'hero-2')
    equal(writes,2);equal(delayedShow(),nil,'next date is also claimable only once')
end)

test('stale seven-day view rechecks date eligibility before rewards',function()
    resetBonus()
    local stale=assert(SevenDayBonusLayer:create());local callback=claimButton(stale).callback
    -- A persisted/current claim can become visible after this view was built.
    state.seven=1020000
    callback();equal(#rewards,0);equal(writes,0);equal(state.seven,1020000)
    equal(stale:getParent(),nil,'outdated claim view is dismissed')
    now=now+86400
    assert(SevenDayBonusLayer:create(),'stale dismissal releases the singleton')
end)

test('seven-day completion and clock rollback retain original eligibility rules',function()
    resetBonus()
    state.seven=7020000;now=now+86400
    equal(SevenDayBonusLayer:create(),nil,'completed week never creates an eighth claim')
    state.seven=1020000;now=19999*86400
    equal(SevenDayBonusLayer:create(),nil,'clock earlier than prior claim remains ineligible')
    state.seven=1020000;now=20001*86400
    local stale=assert(SevenDayBonusLayer:create());state.seven=7020000
    claimButton(stale).callback();equal(#rewards,0);equal(writes,0)
    equal(state.seven,7020000,'week completed after opening cannot save an eighth day')
end)

test('seven-day scene exit and stale cleanup do not block or clear a newer dialog',function()
    resetBonus()
    local first=assert(SevenDayBonusLayer:create());local callback=claimButton(first).callback
    first:removeFromParent()
    local second=assert(SevenDayBonusLayer:create(),'scene exit must clear singleton')
    first:destory();equal(SevenDayBonusLayer:create(),nil,'stale cleanup must not clear current singleton')
    callback();equal(#rewards,0,'removed view cannot award');equal(writes,0)
    second:removeFromParent();assert(SevenDayBonusLayer:create(),'repeat scene cleanup permits next show')
end)

print(string.format('Tutorial/lifecycle regressions: %d passed, %d failed',passed,failed))
assert(failed==0,'tutorial/lifecycle regression failures')
