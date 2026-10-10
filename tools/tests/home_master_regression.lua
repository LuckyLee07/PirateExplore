-- Run from the repository root with Lua 5.1 (or build/linux/tests/lua-ui-tests).
-- Cocos rendering is mocked, but Header constants, packaged CSV data,
-- DataManager event dispatch, Home/MasterTheme, MainMenu and Dispatch are real.
-- Pixel fidelity remains a separate native GUI acceptance requirement.
-- These contract/lifecycle tests complement native GUI acceptance.
unpack = unpack or table.unpack
local root = 'bin/res/scripts/LuaClass/'
local originalRequire = require
require = function(name)
    if name == 'LuaClass/BTheme' then return BTheme end
    if name == 'LuaClass/HomeTheme' then return HomeTheme end
    if name == 'LuaClass/MasterTheme' then return MasterTheme end
    return true
end

local function equal(actual, expected, context)
    assert(actual == expected, (context or 'value') .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function snapshot(value,seen)
    if type(value) ~= 'table' then return type(value) .. ':' .. tostring(value) end
    seen=seen or {}
    if seen[value] then return 'ref:'..tostring(value) end
    seen[value]=true
    local keys, parts = {}, {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do parts[#parts + 1] = snapshot(key,seen) .. '=' .. snapshot(value[key],seen) end
    return '{' .. table.concat(parts, ',') .. '}'
end
local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local Node = {}
local function node(kind)
    return setmetatable({kind=kind or 'Node', children={}, size={width=80,height=80},
        pos={x=0,y=0}, anchor={x=0,y=0}, visible=true, scale=1}, {__index=Node})
end
function Node:addChild(child, z)
    assert(child and not child.parent, 'Cocos child must exist and have no parent')
    self.children[#self.children + 1] = child; child.parent = self; child.z = z or 0
end
function Node:getChildren() return self.children end
function Node:getChildByTag(tag)for _,n in ipairs(self.children) do if n.tag==tag then return n end end end
function Node:setTag(tag)self.tag=tag end
function Node:getParent() return self.parent end
function Node:cleanup()
    self:stopAllActions()
    for _, child in ipairs(self.children) do child:cleanup() end
    if self.scriptHandler then self.scriptHandler('cleanup') end
    self.cleaned = true
end
function Node:removeFromParent(cleanup)
    if self.parent then
        local siblings = self.parent.children
        for i, child in ipairs(siblings) do if child == self then table.remove(siblings, i); break end end
        self.parent = nil
        if cleanup ~= false then self:cleanup() end
    end
end
function Node:removeAllChildren(cleanup)
    while #self.children > 0 do self.children[#self.children]:removeFromParent(cleanup) end
end
function Node:setContentSize(a,b) self.size=type(a)=='table' and a or {width=a,height=b} end
function Node:getContentSize()
    if self.kind == 'LabelTTF' then
        return {width=self.dimensions and self.dimensions.width > 0 and self.dimensions.width or #self.text*self.fontSize*0.45,
            height=self.dimensions and self.dimensions.height > 0 and self.dimensions.height or self.fontSize}
    end
    return self.size
end
function Node:setPosition(a,b) self.pos=type(a)=='table' and a or {x=a,y=b} end
function Node:getPosition() return self.pos.x,self.pos.y end
function Node:getPositionX() return self.pos.x end
function Node:getPositionY() return self.pos.y end
function Node:setPositionX(x) self.pos.x=x end
function Node:setPositionY(y) self.pos.y=y end
function Node:setAnchorPoint(a,b) self.anchor=type(a)=='table' and a or {x=a,y=b} end
function Node:getAnchorPoint() return self.anchor end
function Node:setString(s) self.text=tostring(s) end
function Node:setFontName(v) self.font=v end
function Node:getFontName() return self.font end
function Node:getString() return self.text end
function Node:setDimensions(v) self.dimensions=v end
function Node:setHorizontalAlignment(v) self.horizontalAlignment=v end
function Node:setVerticalAlignment(v) self.verticalAlignment=v end
function Node:setScale(x,y) self.scale=x;self.scaleX=x;self.scaleY=y or x end
function Node:setScaleX(v) self.scaleX=v end
function Node:setScaleY(v) self.scaleY=v end
function Node:getScale() return self.scale end
function Node:getScaleX() return self.scaleX or self.scale end
function Node:getScaleY() return self.scaleY or self.scale end
function Node:setColor(v) self.color=v end
function Node:setOpacity(v) self.opacity=v end
function Node:getOpacity() return self.opacity or 255 end
function Node:setVisible(v) self.visible=v end
function Node:isVisible() return self.visible end
function Node:getBoundingBox() return {x=self.pos.x-self.size.width*self.anchor.x,y=self.pos.y-self.size.height*self.anchor.y,width=self.size.width,height=self.size.height} end
function Node:convertToNodeSpace(p) return {x=p.x-self.pos.x,y=p.y-self.pos.y} end
function Node:setEnabled(v) self.enabled=v end
function Node:isEnabled() return self.enabled ~= false end
function Node:setLocalZOrder(v) self.z=v end
function Node:setCascadeOpacityEnabled(v) self.cascadeOpacity=v end
function Node:setCascadeColorEnabled(v) self.cascadeColor=v end
function Node:ignoreAnchorPointForPosition(v) self.ignoreAnchor=v end
function Node:setTextureRect(v) self.textureRect=v;self.size={width=v.width,height=v.height} end
function Node:setFlippedX(v) self.flippedX=v end
function Node:setFlippedY(v) self.flippedY=v end
function Node:registerScriptTapHandler(fn) self.callback=fn end
function Node:registerScriptHandler(fn) self.scriptHandler=fn end
function Node:runAction(a) self.actions=self.actions or {};self.actions[#self.actions+1]=a;return a end
function Node:stopAllActions() self.actions={} end
function Node:addClickArea() end
function Node:drawPolygon(points,count,fill,borderWidth,border)
    equal(#points,count,'DrawNode polygon count')
    self.draws=self.draws or {};self.draws[#self.draws+1]={points=points,fill=fill,borderWidth=borderWidth,border=border}
end
function Node:drawTriangle(a,b,c,fill) self:drawPolygon({a,b,c},3,fill,0,fill) end
function Node:drawDot(...) self.draws=self.draws or {};self.draws[#self.draws+1]={...} end
function Node:drawSegment(...) self.draws=self.draws or {};self.draws[#self.draws+1]={...} end
function Node:clear() self.draws={} end

cc = {
    p=function(x,y)return {x=x,y=y}end,
    size=function(w,h)return {width=w,height=h}end,
    rect=function(x,y,w,h)return {x=x,y=y,width=w,height=h}end,
    c3b=function(r,g,b)return {r=r,g=g,b=b}end,
    c4b=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,
    c4f=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end,
    TEXT_ALIGNMENT_LEFT=0,TEXT_ALIGNMENT_CENTER=1,TEXT_ALIGNMENT_RIGHT=2,
    VERTICAL_TEXT_ALIGNMENT_TOP=0,VERTICAL_TEXT_ALIGNMENT_CENTER=1,
}
for _, kind in ipairs({'Node','Layer','DrawNode'}) do
    local name=kind;cc[name]={create=function()return node(name)end}
end
local function fileExists(path)
    local f=io.open('bin/res/assets/'..path,'rb')
    if f then f:close();return true end
    return false
end
local missingArt=false
cc.FileUtils={getInstance=function()return {isFileExist=function(_,path)return not missingArt and fileExists(path)end}end}
cc.Sprite={create=function(_,path,rect)
    if path and (missingArt or not fileExists(path)) then return nil end
    local n=node('Sprite');n.path=path
    if path then
        local f=assert(io.open('bin/res/assets/'..path,'rb'));local h=f:read(24);f:close()
        if h and h:sub(1,8)=='\137PNG\r\n\26\n' then
            local function uint32(i)local a,b,c,d=h:byte(i,i+3);return ((a*256+b)*256+c)*256+d end
            n.size={width=uint32(17),height=uint32(21)}
        end
    end
    if rect then n.textureRect=rect;n.size={width=rect.width,height=rect.height} end
    return n
end}
cc.LayerColor={create=function(_,color,w,h)local n=node('LayerColor');n.color=color;n.size={width=w,height=h};return n end}
cc.LabelTTF={create=function(_,text,font,size)
    local n=node('LabelTTF');n.text=tostring(text or '');n.font=font;n.fontSize=size;return n
end}
cc.MenuItemSprite={create=function(_,normal,selected)
    assert(normal and selected,'MenuItemSprite requires both states')
    local n=node('MenuItemSprite');n.size=normal:getContentSize();n:addChild(normal);n:addChild(selected);return n
end}
cc.Menu={create=function(_,...)local n=node('Menu');for _,v in ipairs({...})do n:addChild(v)end;return n end}
local viewport={width=640,height=1136}
cc.Director={getInstance=function()return {getVisibleSize=function()return viewport end,getVisibleOrigin=function()return {x=0,y=0}end}end}
cc.Texture2D={setDefaultAlphaPixelFormat=function()end}
for _, name in ipairs({'FadeOut','FadeIn','FadeTo','ScaleTo','DelayTime','Sequence','CallFunc','EaseExponentialIn','EaseExponentialOut','MoveTo','MoveBy','RepeatForever'})do
    local kind=name;cc[name]={create=function(_,...)return {kind=kind,args={...}}end}
end
local dispatcher={listeners={}}
function Node:getEventDispatcher() return dispatcher end
cc.Handler={EVENT_TOUCH_BEGAN=1,EVENT_TOUCH_MOVED=2,EVENT_TOUCH_ENDED=3,EVENT_TOUCH_CANCELLED=4}
cc.rectContainsPoint=function(r,p)return p.x>=r.x and p.x<=r.x+r.width and p.y>=r.y and p.y<=r.y+r.height end
cc.EventListenerTouchOneByOne={create=function()return {handlers={},setSwallowTouches=function(self,v)self.swallow=v end,registerScriptHandler=function(self,f,event)self.handlers[event]=f end} end}
cc.EventListenerCustom={create=function(_,name,callback)return {name=name,callback=callback}end}
cc.EventCustom={new=function(_,name)return {name=name}end}
function dispatcher:addEventListenerWithFixedPriority(listener,priority)
    self.listeners[#self.listeners+1]=listener;listener.priority=priority
end
function dispatcher:addEventListenerWithSceneGraphPriority(listener,owner)
    self.listeners[#self.listeners+1]=listener;listener.owner=owner
end
function dispatcher:removeEventListenersForTarget(owner)
    for i=#self.listeners,1,-1 do if self.listeners[i].owner==owner then table.remove(self.listeners,i) end end
end
function dispatcher:removeEventListener(listener)
    for i,v in ipairs(self.listeners)do if v==listener then table.remove(self.listeners,i);return end end
end
function dispatcher:dispatchEvent(event)
    local current={};for i,v in ipairs(self.listeners)do current[i]=v end
    for _,v in ipairs(current)do if v.name and v.name==event.name then v.callback(event)end end
end
function class(name,factory)
    local cls={}
    function cls.new()local n=factory();setmetatable(n,{__index=function(_,k)return cls[k] or Node[k]end});return n end
    return cls
end

dofile(root..'Header.lua')
cclog=function()end
-- Loading definitions does not initialize real saves or static data.
dofile(root..'DataManager.lua')
local dm=DataManager.new()
DataManagerSingleton=dm
dm.__eventListener={};dm.__eventDispatcher=dispatcher
local data={}
local writes=0
local function forbidden(name)
    return function()writes=writes+1;error('Home attempted a game-state/economy write: '..name,2)end
end
for _,name in ipairs({'setRoleData','addCoin','addDiamond','addPackItemWithId','addSoilderWithId','mixPackAndSoildier','showBuyGoldBox','setMusic_off','setSound_off'})do dm[name]=forbidden(name)end
local save={saveData=forbidden('saveData')}
SaveDataManager={getInstance=function()return save end}
dm.__roleData={getRoleData=function(_,key)return data[key]end,getSound=function()return 1 end,saveData=forbidden('UserData.saveData')}
-- Read the same packaged CSV bytes as the game, using the legacy Record/LZSS
-- format. This fixture cannot silently invent a ship name or crew profession.
local function readFile(path)
    local f=assert(io.open(path,'rb'));local text=f:read('*a');f:close();return text
end
local function xor(a,b)
    local value,place=0,1
    while a>0 or b>0 do
        if a%2~=b%2 then value=value+place end
        a=math.floor(a/2);b=math.floor(b/2);place=place*2
    end
    return value
end
local function packagedCSV(name)
    local source=readFile('src/NewPirate/common/UtilTools/Record.cpp')
    local key=assert(source:match('m_keys = "([^"]+)"'))..'\0'
    local file=readFile('bin/res/assets/data/'..name..'.csv');local bytes={}
    for i=1,#file do
        local keyIndex=i==1 and 1 or ((i-2)%(#key-1)+2)
        bytes[i]=xor(file:byte(i),key:byte(keyIndex))
    end
    local width=bytes[1]
    assert(width==4 or width==8,'supported packaged CSV word width')
    local expected=0
    for i=width,1,-1 do expected=expected*256+bytes[1+i] end
    local p=2+width*2;local ring={};local r=4078;local flags=0;local out={}
    for i=0,4095 do ring[i]=32 end
    local function emit(c)
        out[#out+1]=string.char(c);ring[r]=c;r=(r+1)%4096
    end
    while p<=#bytes do
        flags=math.floor(flags/2)
        if math.floor(flags/256)%2==0 then flags=bytes[p]+65280;p=p+1 end
        if flags%2==1 then
            if p>#bytes then break end
            emit(bytes[p]);p=p+1
        else
            if p+1>#bytes then break end
            local i,j=bytes[p],bytes[p+1];p=p+2;i=i+math.floor(j/16)*256
            for k=0,j%16+2 do emit(ring[(i+k)%4096]) end
        end
    end
    local decoded=table.concat(out);equal(#decoded,expected,'packaged '..name..' byte count')
    local lines={};for line in (decoded..'\n'):gmatch('([^\n]*)\n') do lines[#lines+1]=line:gsub('\r$','') end
    local function fields(line)
        local result={};for value in (line..','):gmatch('(.-),') do result[#result+1]=value end;return result
    end
    local keys=fields(lines[2]);local result={}
    for i=3,#lines do
        local row=fields(lines[i])
        if row[2] and row[2]~='' then
            local record={};for j=2,#keys do record[keys[j]]=row[j] end;result[row[2]]=record
        end
    end
    return result
end
local soldiers=packagedCSV('soilderAttribute')
local resources=packagedCSV('resourceInfo')
equal(soldiers['107'].name,'木盾舵手','packaged crew 107')
equal(soldiers['124'].name,'船医','packaged crew 124')
equal(resources['1299'].name,'单人战船','packaged starter ship')
local csv={[csvOfSoilderAttribute]=soldiers,[csvOfResourceInfo]=resources}
local csvBaseline=snapshot(csv)
dm.__staticData={getCSVByID=function(_,id)return csv[id] or {}end}
local guideUnlocked=true
local alchemyUnlocked=true
local guideOverrides={}
local guideReads={}
local allowedGuideCalls=nil
local guide={getIsHaveStep=function(_,step,flag)
        guideReads[#guideReads+1]={step=step,flag=flag==true}
        local key=tostring(step)..':'..tostring(flag==true)
        if guideOverrides[key]~=nil then return guideOverrides[key] end
        if step==8 then return guideUnlocked end
        if step==1 then return alchemyUnlocked end
        return true
    end,
    addStep=function(_,step,flag)
        if not allowedGuideCalls then forbidden('GuideController.addStep')() end
        allowedGuideCalls[#allowedGuideCalls+1]={step=step,flag=flag==true}
    end,removeRedPoint=function()end,addRedPoint=function()end}
GuideController={getInstance=function()return guide end}
ToastUtil={downString=function(_,text)_G.lastToast=text end,quietHomeProductionToasts=function()end}
AudioEngine={playEffect=function()end}
SDButton={create=function()return node('SDButton')end}
PushGiftView={create=function()return {show=function()end}end}
ChargeLayer={create=forbidden('ChargeLayer.create')}
RandomEventLayer={create=function()return node('RandomEventLayer')end}
local expeditionCreates=0
ExpeditionLayer={create=function()expeditionCreates=expeditionCreates+1;error('Home must not initialize ExpeditionLayer')end}

dofile(root..'BTheme.lua')
dofile(root..'HomeTheme.lua')
dofile(root..'MasterTheme.lua')
dofile(root..'HarborGoals.lua')
dofile(root..'CrewRecovery.lua')
dofile(root..'Home.lua')
dofile(root..'MainMenu.lua')
dofile(root..'Dispatch.lua')
local refresh=HomeLayer.refreshSummary
function HomeLayer:refreshSummary(...)
    self.refreshCount=(self.refreshCount or 0)+1
    return refresh(self,...)
end

local HOME_EVENTS={rolePack,roleSelectUnit,roleSoildierQueue,rolePackSize,roleCabinSize,roleGuideStep,roleShipId,roleMake,roleBuilding,roleAlchemyUnit,roleMoney}
local function fixture()
    data={
        [roleMoney]=1250,[roleDiamond]=213,[roleCabinSize]=3,[rolePackSize]=60,[roleShipId]='1299',
        [rolePack]={['1005']=100,['1037']=5},
        [roleSoildierQueue]={['107']={[dataKeyID]='107',[dataKeyNum]=5},['124']={[dataKeyID]='124',[dataKeyNum]=2}},
        [roleSelectUnit]={['10107']=3,['1005']=40,['1037']=3},
        [roleBattleQueue]={},[roleBattlePack]={},[roleGuideStep]={},
    }
    guideUnlocked=true;alchemyUnlocked=true;guideOverrides={};guideReads={};allowedGuideCalls=nil
    UITopHeight=100;UIBottomHeight=136;lastToast=nil
end
local function walkTree(n,callback)
    callback(n);for _,child in ipairs(n.children) do walkTree(child,callback) end
end
local function textTree(n)
    local lines={};walkTree(n,function(v)if v.kind=='LabelTTF' then lines[#lines+1]=v.text end end)
    return table.concat(lines,'\n')
end
local function countText(n,text)
    local count=0;walkTree(n,function(v)if v.kind=='LabelTTF' and v.text==text then count=count+1 end end)
    return count
end
local function assertReadonly(before,context)
    equal(snapshot(data),before,context..' role data changed directly')
    equal(snapshot(csv),csvBaseline,context..' static CSV changed directly')
    equal(writes,0,context..' write API count')
    equal(expeditionCreates,0,context..' Expedition init count')
end
local function countListeners()return #dispatcher.listeners end
local function countTouches()
    local count=0;for _,listener in ipairs(dispatcher.listeners) do if listener.handlers then count=count+1 end end;return count
end
local function tap(button,context)
    assert(button,context..' button exists')
    local item=button.item or button
    assert(item.callback,context..' callback exists')
    item.callback()
end
local function assertSlots(home,expected)
    equal(#home.crewSlots,3,'exactly three presentation slots')
    for i=1,3 do
        local slot=home.crewSlots[i];local id=expected[i]
        if id then
            equal(tostring(slot.id),id,'slot '..i..' actual type')
            equal(slot.name,soldiers[id].name,'slot '..i..' real CSV name')
            equal(slot.num,1,'slot '..i..' one real crew member')
            assert(not slot.empty,'slot '..i..' is occupied')
        else
            assert(slot.empty,'slot '..i..' is neutral and empty')
            equal(slot.num,0,'empty slot contains no selected member')
            assert(slot.id==nil or slot.id=='','empty slot must not impersonate a profession')
        end
    end
end
local function assertNoProfessionArt(home,context)
    for _,slot in ipairs(home.crewSlots) do assert(slot.neutral,context..' slot needs neutral art') end
    walkTree(home.crewNode,function(v)
        assert(not (v.path and (v.path:find('107',1,true) or v.path:find('124',1,true) or v.path:find('106',1,true) or v.path:find('crew-trio',1,true))),context..' fabricated profession art')
    end)
end
local function portraitRegions(home)
    local regions={}
    walkTree(home.crewNode,function(v)
        if v.path and v.path:find('crew-trio.png',1,true) then
            assert(v.textureRect,'portrait uses a bounded atlas crop')
            regions[#regions+1]=snapshot(v.textureRect)
        end
    end)
    return regions
end
local function assertMature(home)
    assert(home.isAdventureHome,'Home marker')
    equal(home.summary.crew,3,'selected crew')
    equal(home.summary.cargo,43,'selected cargo volume')
    equal(home.summary.food,40,'selected food')
    equal(home.summary.keys,3,'selected keys')
    equal(home.summary.standby,4,'unselected inventory crew')
    equal(home.summary.unlocked,true,'shipyard unlocked')
    equal(#home.crewEntries,1,'only selected crew types')
    equal(tostring(home.crewEntries[1].id),'107','10107 offset decoded')
    equal(home.crewEntries[1].name,soldiers['107'].name,'real selected crew name')
    equal(home.crewEntries[1].num,3,'real selected crew count')
    assertSlots(home,{'107','107','107'})
    if not missingArt and fileExists('Images/UI/Adventure/Master/crew-trio.png') then
        local regions=portraitRegions(home);equal(#regions,3,'three real portrait atlas crops')
        equal(regions[1],regions[2],'107 first two portrait regions identical')
        equal(regions[2],regions[3],'107 last two portrait regions identical')
        for _,slot in ipairs(home.crewSlots)do assert(not slot.neutral,'available 107 art uses its real crop')end
    end
    equal(countText(home.crewNode,'木盾舵手'),3,'three repeated real crew labels')
    assert(not textTree(home.crewNode):find('船医',1,true),'unselected doctor not fabricated')
    assert(not textTree(home.crewNode):find('突击水手',1,true),'unselected assault sailor not fabricated')
    assert(textTree(home):find(resources['1299'].name,1,true),'ship title read from current resource CSV')
end

fixture()
local routes={}
zqDispatch={mainMenu={openRoute=function(_,index)routes[#routes+1]=index end},
    moveToRepository=function()routes[#routes+1]='alchemy' end}
local before=snapshot(data)
local home=assert(HomeLayer:create())
assertMature(home)
tap(home.departureButton,'ready CTA');equal(routes[#routes],1,'ready CTA opens preparation')
equal(countListeners(),#HOME_EVENTS,'Home subscriptions')
assertReadonly(before,'mature Home')
local childCount=#home.crewNode:getChildren()
for _=1,5 do home:refreshSummary();assertMature(home)end
equal(#home.crewNode:getChildren(),childCount,'crew redraw leaves no stale cards')
equal(countListeners(),#HOME_EVENTS,'refresh subscription stability')
for _,key in ipairs(HOME_EVENTS)do
    local calls=home.refreshCount;dm:postEvent(key,nil);equal(home.refreshCount,calls+1,'one refresh for '..key)
end
assertReadonly(before,'repeat refresh and source events')
-- Verify that another actual ship row changes the rendered title, then restore.
local nextShip
for id,row in pairs(resources) do
    if id~='1299' and row.name and row.name:find('战船',1,true) then nextShip=id;break end
end
assert(nextShip,'second packaged ship for dynamic title test')
data[roleShipId]=nextShip;before=snapshot(data);dm:postEvent(roleShipId,nil)
assert(textTree(home):find(resources[nextShip].name,1,true),'ship change event refreshes the real ship title')
assertReadonly(before,'ship change')
pNeedUpdateLayer=home;home:destory()
equal(countListeners(),0,'Home destroy removes native listeners')
equal(pNeedUpdateLayer,nil,'Home releases active-log pointer')
local stopped=home.refreshCount;dm:postEvent(roleSelectUnit,nil)
equal(home.refreshCount,stopped,'destroyed Home does not receive events')
home:destory();equal(countListeners(),0,'idempotent destroy')
print('PASS Master Home real packaged CSV, 107 x 3 identical slots, ship title, read-only refresh and eleven-event lifecycle')

for selected=0,2 do
    fixture();data[roleSelectUnit]=selected>0 and {['10107']=selected} or {}
    before=snapshot(data);home=assert(HomeLayer:create())
    equal(home.summary.crew,selected,'partial formation count')
    equal(home.summary.cargo,0,'partial formation cargo')
    equal(home.summary.standby,7-selected,'partial formation standby')
    local expected={};for i=1,selected do expected[i]='107' end
    assertSlots(home,expected)
    equal(countText(home.crewNode,'木盾舵手'),selected,'no duplicated crew beyond actual selection')
    if selected==0 then equal(#home.crewEntries,0,'empty formation no types');assertNoProfessionArt(home,'empty formation')end
    assertReadonly(before,'partial formation '..selected)
    home:destory();equal(countListeners(),0,'partial formation cleanup')
end
for capacity=1,2 do
    fixture();data[roleCabinSize]=capacity;data[roleSelectUnit]={}
    before=snapshot(data);home=assert(HomeLayer:create())
    for i,slot in ipairs(home.crewSlots) do
        equal(slot.locked,i>capacity,'slot respects real cabin capacity')
        equal(slot.name,i>capacity and '未解锁' or '待编入','locked empty-slot label')
    end
    equal(countText(home.crewNode,'未解锁'),3-capacity,'only unavailable positions say locked')
    assertReadonly(before,'capacity-aware slots');home:destory();equal(countListeners(),0,'capacity slots cleanup')
end
-- The actual starting profession must not look like an unfilled berth. Use
-- identity-matched100/101 art without altering data or the existing slot box.
for _,id in ipairs({'100','101'}) do
    fixture();data[roleCabinSize]=1
    data[roleSelectUnit]={[tostring(10000+tonumber(id))]=1}
    data[roleSoildierQueue]={[id]={[dataKeyID]=id,[dataKeyNum]=1}}
    equal(soldiers[id].name,id=='100' and '低级船员' or '水手','real starter/sailor CSV identity')
    equal(soldiers[id].icon,id=='100' and 'j_1.png' or 'j_2.png','original CSV icon remains unchanged')
    before=snapshot(data);home=assert(HomeLayer:create());assertSlots(home,{id})
    assert(not home.crewSlots[1].neutral,'selected starter/sailor has its own portrait')
    equal(home.summary.crew,1,'starter selected count');equal(home.summary.standby,0,'starter standby count')
    local artCount=0
    walkTree(home.crewNode,function(v)
        local high='Images/UI/Adventure/Master/Portraits/crew-'..id..'.png'
        local expected=fileExists(high) and high or ('Images/Icon/B/crew-'..id..'.png')
        if v.path==expected then
            artCount=artCount+1
            equal(v:getScaleX(),v:getScaleY(),'starter portrait uniform aspect')
            local z=v:getContentSize()
            equal(v:getScaleX(),math.min(home.slotWidth/z.width,home.slotPortraitHeight/z.height),'original slot fit')
        end
    end)
    equal(artCount,1,'one portrait for exactly one selected starter/sailor')
    for i=2,3 do assert(home.crewSlots[i].empty and home.crewSlots[i].neutral and home.crewSlots[i].locked) end
    assertReadonly(before,'starter/sailor portrait-only change');home:destory()
end
local originalPortraitSprite=cc.Sprite.create
cc.Sprite.create=function()return nil end
assert(MasterTheme.portrait('100',185,155)==nil,'failed starter portrait decoding keeps neutral fallback')
cc.Sprite.create=originalPortraitSprite
missingArt=true
assert(MasterTheme.portrait('100',185,155)==nil and MasterTheme.portrait('101',185,155)==nil,'missing starter assets keep neutral fallback')
missingArt=false
print('PASS Master Home real 100/101 occupied portraits, distinct empty/locked slots and unchanged roster data')
fixture();data[roleSelectUnit]={['10108']=1}
before=snapshot(data);home=assert(HomeLayer:create())
assertSlots(home,{'108'})
assert(textTree(home.crewNode):find(soldiers['108'].name,1,true),'unillustrated profession retains actual name')
assertNoProfessionArt(home,'unillustrated profession')
assertReadonly(before,'unillustrated profession');home:destory();equal(countListeners(),0,'unknown art cleanup')
print('PASS Master Home zero/one/two real crew, three neutral empty slots and real unillustrated profession names')

fixture();data[roleSelectUnit]={['10124']='2',['10107']='1',['1005']=7,['1037']=1,['1038']=2,['1061']=3}
data[roleSoildierQueue]['124'][dataKeyNum]='2';before=snapshot(data)
home=assert(HomeLayer:create());assertSlots(home,{'107','124','124'})
equal(home.summary.crew,3,'mixed crew with string quantities')
equal(home.summary.cargo,13,'mixed cargo')
equal(home.summary.food,7,'selected food separated from inventory')
equal(home.summary.keys,6,'three actual usable key types')
equal(home.summary.standby,4,'mixed selected crew subtracted once')
equal(#home.crewEntries,2,'mixed real selected types')
equal(home.crewEntries[2].name,'船医','CSV 124 is the ship doctor')
if fileExists('Images/UI/Adventure/Master/crew-trio.png') then
    local regions=portraitRegions(home);equal(#regions,3,'mixed portrait count')
    assert(regions[1]~=regions[2],'actual doctor art differs from helmsman')
    equal(regions[2],regions[3],'two real doctors share the doctor crop')
end
assertReadonly(before,'mixed formation');home:destory();equal(countListeners(),0,'mixed cleanup')
for _,state in ipairs({{shipyard=false,alchemy=true,route=3},{shipyard=false,alchemy=false,route='alchemy'}})do
    fixture();guideUnlocked=state.shipyard;alchemyUnlocked=state.alchemy;data[roleSelectUnit]={}
    before=snapshot(data);home=assert(HomeLayer:create())
    equal(home.summary.unlocked,false,'locked shipyard')
    assert(textTree(home):find(state.alchemy and '船坞' or '炼金',1,true),'locked state explains required step')
    tap(home.departureButton,'newcomer CTA');equal(routes[#routes],state.route,'newcomer primary route')
    assertReadonly(before,'newcomer guidance');home:destory();equal(countListeners(),0,'newcomer cleanup')
end
print('PASS Master Home mixed real crew and newcomer alchemy / construction / preparation CTA routing')

-- Production Dispatch owns page destruction and currency/log synchronization.
fixture();before=snapshot(data);SystemInfoData={'更早历史','上一条港口消息','最新港口消息'}
local scene=node('Scene')
local dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
local menu=dispatch.mainMenu
local HOME_TOTAL=#HOME_EVENTS+5
assertMature(dispatch.rightNode)
equal(UITopHeight,100,'legacy top safe area unchanged')
equal(UIBottomHeight,136,'legacy bottom safe area unchanged')
equal(countListeners(),HOME_TOTAL,'Home, MainMenu and Dispatch listeners')
equal(pNeedUpdateLayer,dispatch.rightNode,'Home current log receiver')
local function assertFourNavigation(context)
    equal(#menu.navigationButtons,4,context..' exactly four persistent tabs')
    assert(menu.groupNavigation:isVisible(),context..' grouped navigation visible')
    assert(not menu.MainMenuButtonGroup:isVisible(),context..' old eight-button group stays hidden')
    for i,title in ipairs({'基地','航行','船员','港务'})do
        equal(menu.navigationButtons[i].bLabel:getString(),title,context..' group label '..i)
        assert(menu.navigationButtons[i]:isVisible(),context..' visible group '..i)
    end
end
assertFourNavigation('Home')
assert(menu.homePresentation and menu.homeHeader:isVisible(),'Home header enabled')
assert(not menu.legacyTopBg:isVisible() and not menu.coinNode:isVisible() and not menu.diamondNode:isVisible(),'legacy header hidden on Home')
local homeHeader=menu.homeHeader;local headerChildren=#homeHeader:getChildren()
data[roleMoney]=4321;data[roleDiamond]=234;before=snapshot(data)
dm:postEvent(roleMoney,nil);dm:postEvent(roleDiamond,nil)
equal(menu.homeCoinLabel:getString(),'4321','live Home coin')
equal(menu.homeDiamondLabel:getString(),'234','live Home diamond')
equal(menu.coinValueLabel:getString(),'4321','hidden legacy coin synchronized')
equal(menu.diamondValueLabel:getString(),'234','hidden legacy diamond synchronized')
local sameHome=dispatch.rightNode;dispatch:moveToHome()
equal(dispatch.rightNode,sameHome,'repeat Home entry reuses layer')
equal(countListeners(),HOME_TOTAL,'repeat Home entry has one listener set')
local logUpdates=0;local updateInfo=sameHome.updateInfoLabel
sameHome.updateInfoLabel=function(self,text)logUpdates=logUpdates+1;return updateInfo(self,text)end
dm:sendSystemInfo('刚刚更新的消息')
equal(logUpdates,1,'one latest-log update')
assert(sameHome.infoLabel:getString():find('刚刚更新的消息',1,true),'latest log remains available')
assertReadonly(before,'currency and system-log events')
-- Read-only initialization must never open a purchase flow. Only these taps do.
local goldCalls,chargeCalls=0,0
local originalBuy=dm.showBuyGoldBox;local originalCharge=ChargeLayer.create
dm.showBuyGoldBox=function()goldCalls=goldCalls+1 end
ChargeLayer.create=function()chargeCalls=chargeCalls+1 end
assert(menu.homeCoinAddButton:getContentSize().width>=44 and menu.homeCoinAddButton:getContentSize().height>=44,'Home gold has a usable native hitbox')
assert(menu.homeDiamondAddButton:getContentSize().width>=44 and menu.homeDiamondAddButton:getContentSize().height>=44,'Home diamond has a usable native hitbox')
tap(menu.homeCoinAddButton,'Home gold add');equal(goldCalls,1,'Home gold opens original purchase entry')
tap(menu.homeDiamondAddButton,'Home diamond add');equal(chargeCalls,1,'Home diamond opens original recharge entry')
equal(countListeners(),HOME_TOTAL,'purchase-entry stubs do not add Home subscriptions')
dm.showBuyGoldBox=originalBuy;ChargeLayer.create=originalCharge
assertReadonly(before,'explicit original purchase entry taps')

local function legacyPage()
    local page=node('LegacyPage')
    function page:viewWillDestory()end
    function page:destory()self.destroyed=true end
    function page:updateInfoLabel(text)self.latestInfo=text end
    return page
end
for _=1,5 do
    local oldHome=dispatch.rightNode;local page=legacyPage()
    dispatch:setViewWithDirection(page,false,1)
    equal(countListeners(),5,'leaving Home removes its seven subscriptions')
    assertFourNavigation('legacy page')
    equal(pNeedUpdateLayer,page,'legacy log receiver')
    assert(not menu.homePresentation and not menu.homeHeader:isVisible(),'Home header hidden on other pages')
    assert(menu.legacyTopBg:isVisible() and menu.coinNode:isVisible() and menu.diamondNode:isVisible(),'legacy page header restored')
    local calls=oldHome.refreshCount;dm:postEvent(roleSelectUnit,nil);equal(oldHome.refreshCount,calls,'departed Home stays unsubscribed')
    dm:sendSystemInfo('其它页面新消息');assert(page.latestInfo:find('其它页面新消息',1,true),'legacy full system-log path retained')
    dispatch:moveToHome();assertMature(dispatch.rightNode)
    equal(countListeners(),HOME_TOTAL,'Home round trip one subscription set')
    equal(menu.homeHeader,homeHeader,'Home header reused')
    equal(#homeHeader:getChildren(),headerChildren,'Home header nodes not duplicated')
    equal(menu.homeCoinLabel:getString(),'4321','current currency after return')
    assertFourNavigation('return Home')
end
assertReadonly(before,'five full page round trips')
print('PASS Master Home live currency, original purchase entries, four persistent tabs and legacy header preservation')

-- Mock only destination creation: the original navigation callbacks, unlock
-- rules, selected state, sounds and guide effects remain production code.
local originalRoutes={};local routed={}
for _,method in ipairs({'moveToHome','moveToExpedition','gotoTrain','gotoBuild','moveToRepository','gotoMake','moveToResource','gotoStore',
    'gotoTalent','gotoAchievement','gotoRanking','gotoSetting','gotoDiamondStore'})do
    local name=method;originalRoutes[name]=dispatch[name]
    dispatch[name]=function()routed[#routed+1]=name end
end
local function assertOverlayClosed(context)
    equal(menu.navigationOverlay,nil,context..' overlay reference cleared')
    equal(menu.navigationOverlayListener,nil,context..' touch reference cleared')
    equal(menu.groupRouteButtons,nil,context..' route references cleared')
    equal(menu.navigationCloseButton,nil,context..' close reference cleared')
    equal(countListeners(),HOME_TOTAL,context..' listener baseline')
    equal(countTouches(),0,context..' no leaked touch listener')
end
local expectedGroups={crew={'recruit','growth','achievement'},port={'build','repository','make','resource','store','alchemy','ranking','settings','diamondStore','gift'}}
for group,keys in pairs(expectedGroups)do
    tap(menu.navigationButtons[group=='crew' and 3 or 4],group..' persistent tab')
    assert(menu.navigationOverlay and menu.navigationOverlay:getParent()==menu,'group overlay attached')
    equal(countTouches(),1,'one overlay touch listener')
    equal(countListeners(),HOME_TOTAL+1,'overlay does not multiply data subscriptions')
    for _,key in ipairs(keys)do assert(menu.groupRouteButtons[key],group..' exposes '..key)end
    local itemCount=0;for _ in pairs(menu.groupRouteButtons)do itemCount=itemCount+1 end
    equal(itemCount,#keys,group..' preserves approved grouping without legacy strip')
    tap(menu.navigationCloseButton,'close '..group);assertOverlayClosed('close '..group)
end
-- A stable opt-in paid gift occupies the existing tenth port cell. It must
-- not spend or navigate, and an already-open offer cannot be stacked.
local giftCreates=0
local giftScene=node('Scene')
PushGiftView={create=function()
    giftCreates=giftCreates+1
    local view=node('Gift')
    function view:show()giftScene:addChild(self)end
    function view:close()self:removeFromParent()end
    return view
end}
local savedMap=data[roleMapInfo];local savedSea=isEnterMap
for _,state in ipairs({{map=false,sea=false},{map=true,sea=true},{map=true,sea=false}})do
    data[roleMapInfo]=state.map and {} or nil;isEnterMap=state.sea
    local previous=giftCreates;local oldRoutes=#routed
    menu:openNavigationGroup('port')
    equal(menu.groupRouteButtons.gift.bLabel:getString(),'礼包（付费）','paid entry is explicit')
    local stale=menu.groupRouteButtons.gift
    tap(stale,'voluntary gift')
    assertOverlayClosed('gift route')
    if state.map and not state.sea then
        equal(giftCreates,previous+1,'returned harbor opens original offer')
        local gift=menu.giftDialog;assert(gift and gift:getParent()==giftScene)
        tap(stale,'repeated stale gift tap');equal(giftCreates,previous+1,'cannot stack gifts')
        gift:close();equal(menu.giftDialog,nil,'cleanup releases offer owner')
        menu:openNavigationGroup('port');tap(menu.groupRouteButtons.gift,'reopen gift')
        equal(giftCreates,previous+2,'closed offer can reopen');menu.giftDialog:close()
    else
        equal(giftCreates,previous,'pre-voyage and sea states preserve availability gate')
    end
    equal(#routed,oldRoutes,'gift does not navigate or enter checkout')
end
data[roleMapInfo]=savedMap;isEnterMap=savedSea
local menuSource=assert(io.open('bin/res/scripts/LuaClass/MainMenu.lua')):read('*a')
local initSource=menuSource:sub(assert(menuSource:find('function MainMenuLayer:init()',1,true)),assert(menuSource:find('function MainMenuLayer:playStory',1,true))-1)
assert(not initSource:find('PushGiftView:create()',1,true),'no direct automatic return offer')
print('PASS voluntary paid gift gate, original dialog route, repeat/close/reopen and no return auto-open')
for _=1,8 do
    menu:openNavigationGroup('crew');local old=menu.navigationOverlay
    menu:openNavigationGroup('port')
    assert(old.cleaned and old:getParent()==nil,'opening new group cleans old overlay')
    equal(countTouches(),1,'rapid group replacement has one touch listener')
    local listener=menu.navigationOverlayListener
    local outside={getLocation=function()return {x=1,y=1}end}
    equal(listener.handlers[cc.Handler.EVENT_TOUCH_BEGAN](outside),true,'modal blocks background gesture')
    listener.handlers[cc.Handler.EVENT_TOUCH_CANCELLED]()
    listener.handlers[cc.Handler.EVENT_TOUCH_ENDED](outside)
    assert(menu.navigationOverlay,'cancelled gesture must not dismiss current overlay')
    listener.handlers[cc.Handler.EVENT_TOUCH_BEGAN](outside)
    listener.handlers[cc.Handler.EVENT_TOUCH_ENDED](outside)
    assertOverlayClosed('outside dismissal')
end
local routeCases={
    {index=1,step=8,flag=false,method='moveToExpedition',label='船坞'},
    {index=2,step=103,flag=true,method='gotoTrain',key='recruit',group='crew',effect=3,label='训练营'},
    {index=3,step=1,flag=false,method='gotoBuild',key='build',group='port',label='炼金'},
    {index=4,step=2,flag=false,method='moveToRepository',key='repository',group='port',label='仓库'},
    {index=5,step=102,flag=true,method='gotoMake',key='make',group='port',effect=2,label='铁匠铺'},
    {index=6,step=2,flag=false,method='moveToResource',key='resource',group='port',label='仓库'},
    {index=7,step=104,flag=true,method='gotoStore',key='store',group='port',effect=4,label='市场'},
}
for _,case in ipairs(routeCases)do
    local key=tostring(case.step)..':'..tostring(case.flag)
    guideOverrides[key]=false;menu.selectedIndex=-1;lastToast=nil;allowedGuideCalls={}
    local oldCount=#routed
    if case.group then
        menu:openNavigationGroup(case.group);tap(menu.groupRouteButtons[case.key],'locked '..case.key)
    else tap(menu.navigationButtons[2],'locked navigation sail')end
    equal(#routed,oldCount,'locked route '..case.index..' cannot enter destination')
    assert(lastToast and lastToast:find(case.label,1,true),'locked route '..case.index..' explains original gate')
    equal(#allowedGuideCalls,0,'locked route has no guide side effect');assertOverlayClosed('locked route '..case.index)
    guideOverrides[key]=true;lastToast=nil
    if case.group then
        menu:openNavigationGroup(case.group);tap(menu.groupRouteButtons[case.key],'unlocked '..case.key)
    else tap(menu.navigationButtons[2],'unlocked navigation sail')end
    equal(routed[#routed],case.method,'unlocked route '..case.index..' destination')
    equal(menu.selectedIndex,case.index,'original route index '..case.index)
    equal(#allowedGuideCalls,case.effect and 1 or 0,'original route guide side effect count')
    if case.effect then
        equal(allowedGuideCalls[1].step,case.effect,'original guide step');equal(allowedGuideCalls[1].flag,true,'original guide flag')
    end
    equal(lastToast,nil,'unlocked route has no gate toast');assertOverlayClosed('unlocked route '..case.index)
    guideOverrides={};allowedGuideCalls=nil
end
-- Settings keeps the old warehouse gate; alchemy remains exempt below.
guideOverrides['2:false']=false;lastToast=nil
menu:openNavigationGroup('port');local settingsCount=#routed
tap(menu.groupRouteButtons.settings,'locked settings')
equal(#routed,settingsCount,'settings keeps original warehouse gate')
assert(lastToast and lastToast:find('仓库',1,true),'settings gate explains warehouse')
assertOverlayClosed('locked settings');guideOverrides={}
-- Achievement/rank grouped shortcuts inherit the original expedition gate.
for _,case in ipairs({{'achievement','crew'},{'ranking','port'}}) do
    guideOverrides['8:false']=false;lastToast=nil
    local oldCount=#routed
    menu:openNavigationGroup(case[2]);tap(menu.groupRouteButtons[case[1]],'locked '..case[1])
    equal(#routed,oldCount,'grouped utility cannot bypass shipyard: '..case[1])
    assert(lastToast and lastToast:find('船坞',1,true),'utility explains shipyard gate')
    assertOverlayClosed('locked '..case[1]);guideOverrides={}
end
local utilityCases={
    {'growth','crew','gotoTalent',3}, {'achievement','crew','gotoAchievement',3},
    {'alchemy','port','moveToRepository',4}, {'ranking','port','gotoRanking',4},
    {'settings','port','gotoSetting',4}, {'diamondStore','port','gotoDiamondStore',4,61},
}
for _,case in ipairs(utilityCases)do
    menu:openNavigationGroup(case[2]);allowedGuideCalls={}
    tap(menu.groupRouteButtons[case[1]],'utility '..case[1])
    equal(routed[#routed],case[3],'utility destination '..case[1])
    equal(menu.utilityRoute,case[1],'utility key '..case[1])
    equal(menu.navigationGroupOverride,case[4],'utility selected group '..case[1])
    equal(#allowedGuideCalls,case[5] and 1 or 0,'utility guide side effects')
    if case[5] then equal(allowedGuideCalls[1].step,case[5],'original diamond shop guide step')end
    allowedGuideCalls=nil;assertOverlayClosed('utility '..case[1])
end
-- A utility page may retain the previous legacy index. Returning to that index
-- must not be blocked by the old same-route optimization.
menu:activeButtonWithIndex(4);menu:openUtilityRoute('growth')
local oldCount=#routed;menu:openRoute(4)
equal(#routed,oldCount+1,'utility page can return to same stored legacy index')
equal(routed[#routed],'moveToRepository','same-index return target')
-- The alchemy route remains available before any buildings have unlocked.
guideUnlocked=false;alchemyUnlocked=false
menu:openNavigationGroup('port');tap(menu.groupRouteButtons.alchemy,'first-run grouped alchemy')
equal(routed[#routed],'moveToRepository','first-run grouped alchemy destination')
assertOverlayClosed('first-run grouped alchemy');guideUnlocked=true;alchemyUnlocked=true
for method,fn in pairs(originalRoutes)do dispatch[method]=fn end
menu:activeButtonWithIndex(0)
menu:openNavigationGroup('crew');dispatch:setViewWithDirection(legacyPage(),false,1)
equal(menu.navigationOverlay,nil,'navigating to legacy page closes open overlay')
equal(countListeners(),5,'legacy page after overlay navigation listener baseline')
tap(menu.navigationButtons[1],'return to Home tab');equal(countListeners(),HOME_TOTAL,'return Home after overlay navigation')
assertReadonly(before,'all original and utility routes')
menu:openNavigationGroup('port');dispatch:destory()
equal(countListeners(),0,'Dispatch destroy closes open overlay and all data listeners')
equal(pNeedUpdateLayer,nil,'Dispatch clears system-log pointer')
print('PASS Master four-group routes, all seven original unlock gates, guide effects and modal close/cancel/replacement cleanup')

-- Node-level construction on both acceptance sizes and without optional art.
-- The application's native GUI still owns real pixel placement and hit testing.
for _,size in ipairs({{width=540,height=960},{width=480,height=800}})do
    viewport={width=640,height=size.height*(640/size.width)}
    fixture();before=snapshot(data);missingArt=true
    home=assert(HomeLayer:create());assertMature(home)
    for _,slot in ipairs(home.crewSlots)do assert(slot.neutral,'missing portrait falls back to neutral')end
    assertReadonly(before,'compact missing-art Home');home:destory();equal(countListeners(),0,'compact Home cleanup')
end
viewport={width=640,height=1136};missingArt=false
print('PASS Master compact safe construction and missing-art neutrality (not native pixel acceptance)')

-- Use the real production-only toast filter and original downString queue path.
-- Do not run NotificationNode production callbacks or touch the economy.
local notification=node('NotificationLayer')
local originalDirector=cc.Director.getInstance
cc.Director.getInstance=function()
    local director=originalDirector()
    director.getNotificationNode=function()return notification end
    director.getRunningScene=function()return scene end
    return director
end
dofile(root..'ToastUtil.lua')
local originalDownString=ToastUtil.downString
local routine=node('RoutineToast');routine.isRoutineProductionToast=true;notification:addChild(routine)
local important=node('ImportantToast');notification:addChild(important)
ToastUtil:quietHomeProductionToasts()
equal(routine:getParent(),nil,'already-visible routine production clears on Home entry')
equal(important:getParent(),notification,'important notification is never hidden')
important:removeFromParent()
local downCalls=0
ToastUtil.downString=function(self,...)
    downCalls=downCalls+1
    return originalDownString(self,...)
end
fixture();missingArt=false;before=snapshot(data)
dispatch=assert(Dispatch:create(false));scene:addChild(dispatch)
local listenersBefore=countListeners()
local toastBefore=snapshot(ToastUtil)
local logsBefore=snapshot(SystemInfoData)
for _,message in ipairs({'金币+3','食物+5','木材+2'})do ToastUtil:productionString(message)end
equal(downCalls,0,'Home routine production never enters downString')
equal(#ToastUtil.infoQueue,0,'Home routine production is not queued for later replay')
equal(snapshot(ToastUtil),toastBefore,'silent production creates no toast state')
equal(#(notification.actions or {}),0,'silent production schedules no toast work')
equal(countListeners(),listenersBefore,'silent production adds no listener')
equal(snapshot(SystemInfoData),logsBefore,'presentation filter does not edit system log')
-- Important messages use downString directly and remain available on Home.
ToastUtil:downString('支付失败，请重试！',true)
ToastUtil:downString('船坞已解锁')
equal(downCalls,2,'errors and unlocks still enter original downString')
equal(ToastUtil.infoQueue[1],'支付失败，请重试！','error retained in original toast queue')
equal(ToastUtil.infoQueue[2],'船坞已解锁','unlock retained in original toast queue')
local toastStack=notification:getChildren()[1]
assert(toastStack and toastStack.isOrdinaryToastStack,'important Home toasts own their driver node')
equal(#(notification.actions or {}),0,'notification host has no retained toast actions')
equal(#toastStack.actions,1,'important Home toasts share one lifecycle-owned pending pump')
local legacy=node('LegacyPage')
function legacy:viewWillDestory()end
function legacy:destory()end
function legacy:updateInfoLabel(text)self.latestInfo=text end
dispatch:setViewWithDirection(legacy,false,1)
ToastUtil:productionString('食物+7')
equal(downCalls,3,'leaving Home restores routine production downString')
equal(ToastUtil.infoQueue[3],'食物+7','legacy production uses the original queue')
equal(#toastStack.actions,1,'legacy production uses the same pending pump')
dispatch:moveToHome()
local returnToastState=snapshot(ToastUtil)
ToastUtil:productionString('金币+9')
equal(downCalls,3,'returning Home silences routine production again')
equal(snapshot(ToastUtil),returnToastState,'returning Home adds no deferred production queue')
equal(countListeners(),listenersBefore,'toast filtering adds no listener on round trip')
assertReadonly(before,'production-only toast filtering')
dispatch:destory();equal(countListeners(),0,'toast exercise leaves no listeners')
ToastUtil:productionString('木材+1')
equal(downCalls,4,'no active Home preserves original production feedback')
equal(ToastUtil.infoQueue[4],'木材+1','no-view production still uses original queue')
-- Guard the intentionally small call-site scope without executing production.
local sourceFile=assert(io.open(root..'NotificationNode.lua','rb'))
local source=sourceFile:read('*a');sourceFile:close()
local _,productionCalls=source:gsub('ToastUtil:productionString%(', '')
equal(productionCalls,1,'the shared local production notification uses the routine filter')
assert(source:find('ToastUtil:downString("支付失败，请重试！")',1,true),'payment failure must retain direct error feedback')
assertReadonly(before,'toast filter final state')
-- Visible native modal ownership suppresses only routine production. No global
-- counter survives removal, and nested dialogs remain independently accounted for.
local modalA=node('Modal');modalA.isAdventureModal=true;scene:addChild(modalA)
local modalB=node('Modal');modalB.isAdventureModal=true;scene:addChild(modalB)
local priorCalls=downCalls
ToastUtil:productionString('食物+5');equal(downCalls,priorCalls,'visible modal suppresses routine production')
modalA:removeFromParent()
ToastUtil:productionString('小麦+1');equal(downCalls,priorCalls,'remaining nested modal keeps production quiet')
ToastUtil:downString('库存不足',true)
equal(downCalls,priorCalls+1,'important modal error retains original feedback route')
modalB:removeFromParent()
ToastUtil:productionString('木材+2');equal(downCalls,priorCalls+2,'last modal close restores ordinary feedback')
assertReadonly(before,'modal presentation isolation')
cc.Director.getInstance=originalDirector
require=originalRequire
print('PASS Master Home production-only toast silence, original error/unlock feedback and off-Home restoration')
