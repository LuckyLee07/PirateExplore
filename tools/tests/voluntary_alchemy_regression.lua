-- Real UserData proxy/encoding, SaveDataManager, GuideController, AlertView,
-- DataManager and Dispatch. Only Record disk I/O and Cocos rendering are mocked.
-- Never opens GUI, writes a player save, or calls a payment SDK.
local root='bin/res/scripts/LuaClass/'
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
local source=read('tools/tests/home_master_regression.lua')
local stop=assert(source:find("\ndofile(root..'Header.lua')",1,true))
local H=assert(loadstring(source:sub(1,stop-1)..'\nreturn {node=node,methods=Node}','@alchemy-node-fixture'))()
local N=H.methods
tolua={type=function(n)return n.kind=='Menu' and 'cc.Menu' or 'cc.Node' end}
function N:retain()end
function N:release()end
function N:setFontSize(v)self.fontSize=v end
function class(_,factory)
    local cls={}
    function cls.new(...)
        local n=factory();setmetatable(n,{__index=function(_,k)return cls[k] or N[k]end})
        if cls.ctor then cls.ctor(n,...)end
        return n
    end
    return cls
end
local width,height=640,1136
local scene=H.node('Scene')
cc.Director={getInstance=function()return {
    getVisibleSize=function()return cc.size(width,height)end,
    getVisibleOrigin=function()return cc.p(0,0)end,
    getWinSize=function()return cc.size(width,height)end,
    getRunningScene=function()return scene end
}end}
ccui={TouchEventType={ended=1}}
require=function(name)return _G[name:match('([^/]+)$')] or true end
for _,name in ipairs({'Header','DataManager','HomeTheme','MasterTheme','DialogTheme','SDButton','ItemIcon','AlertView','SaveDataManager','UserData','GuideController','Dispatch'})do dofile(name=='DataManager' and (os.getenv('PIRATE_ALCHEMY_DATA_SOURCE') or root..name..'.lua') or root..name..'.lua')end
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/json.lua')
cclog=function(format,...)return string.format(format,...)end
getTableRowNum=function(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function equal(a,b,why)assert(a==b,(why or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local function tree(n,match,out)
    out=out or {};if match(n)then out[#out+1]=n end
    for _,c in ipairs(n.children)do tree(c,match,out)end
    return out
end
local function label(n,text)return tree(n,function(c)return c.text==text end)[1]end
local disk,mode,writes,normalWrites,lastFile
Record={GetInstance=function(self)return self end,
    loadData=function(_,name)lastFile=name;return disk end,
    saveData=function(_,str,name)normalWrites=normalWrites+1;disk=str;lastFile=name end,
    saveDataAtomic=function(_,str,name)
        writes=writes+1;lastFile=name
        if mode=='throw' then error('injected save 100% failure')end
        if mode=='false' then return false end
        if mode=='nil' then return nil end
        disk=str;return true
    end}
local dm=DataManager.new();DataManagerSingleton=dm
local events,checks,unlocks={},0,0
function dm:getSound_off()return 1 end
function dm:getCSVByID()return {['1001']={iconName='r_9.png'}}end
function dm:postEvent(key)
    local stored=json.decode(disk)
    if self:getRoleData(roleAlchemyCanLongPress)==1 then
        equal(stored[roleAlchemyCanLongPress],-1,'ownership durable before observer')
        equal(stored[roleDiamond],-self:getRoleData(roleDiamond),'debit durable before observer')
    end
    events[#events+1]=key
end
function dm:checkAutoLearnedTallent()checks=checks+1;return {fixture=true}end
function dm:unlockTallentByKey()unlocks=unlocks+1 end
local toasts={}
ToastUtil={downString=function(_,text)toasts[#toasts+1]=text end,alchemyCoins=function()end}
function dm:getAchievementInfo()return self:getRoleData(roleStorageInfo)[achievement_Alchemy]end
function dm:setAchievementInfo(_,value)
    local info=self:getRoleData(roleStorageInfo);info[achievement_Alchemy]=value
    self:setRoleData(roleStorageInfo,info)
end
local function seed(diamonds,owned,guide)
    scene:removeAllChildren();dm.alchemyUnlockDialog=nil
    local data={
        [roleEncrypted]='1',[roleDiamond]=diamonds,[roleAlchemyCanLongPress]=owned,
        [roleGuideStep]=guide or 's001_s002',[roleMoney]=19,[roleAlchemyUnit]=2,
        [roleStorageInfo]={[achievement_Alchemy]=0},[roleAlchemyShowCount]=7,
        [roleAlchemyBtnClickCount]=83,[rolePack]={['1004']=29,deep={marker=13}},
        marker='preserved',localProductionV1={wall=1000,remaining=7}
    }
    disk=json.encode(simpleclone(data,-1));mode='ok';writes=0;normalWrites=0
    dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
    GuideController.instance=nil;events={};checks=0;unlocks=0;toasts={};zqDispatch=nil
    return disk
end
local function cold()
    dm.__roleData=UserData.new();assert(dm.__roleData:loadData())
    GuideController.instance=nil
end
local function balances(diamonds,owned)
    equal(dm:getRoleData(roleDiamond),diamonds,'diamonds');equal(dm:getRoleData(roleAlchemyCanLongPress),owned,'ownership')
end
local function preserved(before,after)
    local a,b=json.decode(before),json.decode(after)
    a[roleDiamond]=nil;a[roleAlchemyCanLongPress]=nil
    b[roleDiamond]=nil;b[roleAlchemyCanLongPress]=nil
    local function eq(x,y)
        equal(type(x),type(y));if type(x)~='table' then equal(x,y);return end
        for k,v in pairs(x)do eq(v,y[k])end;for k in pairs(y)do assert(x[k]~=nil)end
    end
    eq(a,b)
end
for _,case in ipairs({{397,0,'s001','insufficient'},{900,0,'','guide_locked'},
    {900,0,'s0010','guide_locked'},{900,0,'r001','guide_locked'},
    {900,1,'','already_owned'}})do
    local old=seed(case[1],case[2],case[3]);equal(dm.__roleData:commitAlchemyUnlock(),case[4]);equal(disk,old);equal(writes,0);balances(case[1],case[2])
end
for _,bad in ipairs({'398',-1,398.5,1e20,math.huge,-math.huge,0/0})do
    seed(900,0);dm.__roleData:setRoleData(roleDiamond,bad)
    equal(dm.__roleData:commitAlchemyUnlock(),'invalid');equal(writes,0);equal(dm:getRoleData(roleAlchemyCanLongPress),0)
end
for _,fault in ipairs({'false','nil','throw'})do
    local old=seed(900,0);mode=fault
    equal(dm.__roleData:commitAlchemyUnlock(),'save_failed');equal(disk,old);balances(900,0)
    dm.__roleData:saveData();preserved(old,disk);balances(900,0)
    equal(json.decode(disk)[roleDiamond],-900);equal(json.decode(disk)[roleAlchemyCanLongPress],0)
    cold();balances(900,0);mode='ok'
    equal(dm.__roleData:commitAlchemyUnlock(),'success');balances(502,1);equal(writes,2)
    preserved(old,disk)
    for _=1,3 do cold();balances(502,1);equal(dm.__roleData:commitAlchemyUnlock(),'already_owned')end
    equal(writes,2,'cold repeated commit never debits again')
end
seed(398,nil);equal(dm.__roleData:commitAlchemyUnlock(),'success');balances(0,1)
equal(json.decode(disk)[roleAlchemyCanLongPress],-1);equal(normalWrites,0,'one atomic save only')
zqUserId='alchemy-fixture';seed(900,0);equal(dm.__roleData:commitAlchemyUnlock(),'success');equal(lastFile,'gameRole_alchemy-fixture');zqUserId=nil
-- Legacy plain-number save migrates through the real loadData path first.
local before=seed(900,0)
local legacy=simpleclone(json.decode(disk),-1);legacy[roleEncrypted]=nil
disk=json.encode(legacy);cold();balances(900,0);equal(normalWrites,1)
equal(json.decode(disk)[roleEncrypted],'1')
equal(dm.__roleData:commitAlchemyUnlock(),'success');balances(502,1);preserved(before,disk)
-- The production JSON4Lua codec uses tostring and may round a large safe
-- integer. Fail before persistence if an exact 398 debit cannot survive it.
seed(900,0);dm.__roleData:setRoleData(roleDiamond,9007199254740991)
local oldDisk=disk
local highStatus=dm.__roleData:commitAlchemyUnlock()
if highStatus=='success' then
    equal(dm:getRoleData(roleDiamond),9007199254740593)
    equal(json.decode(disk)[roleDiamond],-9007199254740593)
else
    equal(highStatus,'save_failed');equal(disk,oldDisk);equal(writes,0)
    balances(9007199254740991,0)
end
for _,badOwned in ipairs({'1',true,2})do
    seed(900,badOwned);local old=disk
    equal(dm.__roleData:commitAlchemyUnlock(),'invalid');equal(writes,0);equal(disk,old)
end
local encode=json.encode
seed(900,0);json.encode=function()error('serialization failed')end
local old=disk;equal(dm.__roleData:commitAlchemyUnlock(),'save_failed');equal(disk,old);equal(writes,0);balances(900,0)
json.encode=encode
print('PASS true encoded proxy, exact 398 debit, all unrelated fields, old nil ownership, guide gate, invalid/insufficient balance, false/nil/throw persistence faults, retries and cold idempotence')

-- Real AlertView callbacks, including its Cancel and X controls.
local function open()
    dm:showBuyAlchemyLongPressBox();return dm.alchemyUnlockDialog
end
seed(900,0,'');assert(not open());equal(writes,0)
-- Fresh tutorial fixture must start with the original absent counter.
seed(900,0,'');dm.__roleData:setRoleData(roleAlchemyBtnClickCount,nil)
for i=1,9 do dm:AlchemyButtonDidClick();assert(not open())end
assert(not GuideController:getInstance():getIsHaveStep(1));equal(writes,0)
dm:AlchemyButtonDidClick();assert(GuideController:getInstance():getIsHaveStep(1))
local a=assert(open());a.callbackfunc();balances(502,1);equal(writes,1)
print('PASS nine clicks cannot buy; real tenth-click guide unlock permits purchase without changing tutorial count logic')
for _,kind in ipairs({'cancel','close','cleanup'})do
    seed(900,0);local a=assert(open());local oldCallback=a.callbackfunc
    if kind=='cancel' then label(a,'取 消').parent.callback()
    elseif kind=='close' then a.closeBtn.onSingleCLick()
    else a:removeFromParent()end
    oldCallback();balances(900,0);equal(writes,0);equal(dm.alchemyUnlockDialog,nil)
    local b=assert(open());assert(b~=a);label(b,'取 消').parent.callback();equal(writes,0)
end
seed(397,0);local a=assert(open());a.callbackfunc();a.callbackfunc();balances(397,0);equal(writes,0);assert(a:getParent())
seed(900,0);local a=assert(open());dm:showBuyAlchemyLongPressBox();equal(dm.alchemyUnlockDialog,a)
mode='false';a.callbackfunc();balances(900,0);equal(#events,0);equal(checks,0)
mode='ok';a.callbackfunc();a.callbackfunc();balances(502,1);equal(writes,2);equal(checks,1);equal(unlocks,1)
equal(dm.alchemyUnlockDialog,nil);assert(not open());equal(writes,2)
-- A stale cached guide cannot bypass transaction's saved-guide check.
seed(900,0);local a=assert(open());dm.__roleData:setRoleData(roleGuideStep,'');a.callbackfunc();balances(900,0);equal(writes,0)
print('PASS real cancel/X/removal invalidates old callbacks, duplicate-open guard, insufficient retry, save failure/retry, repeat confirmation and cached-guide mismatch')

-- Navigation uses the real current-page rebuild dispatcher, including no menu.
local notifyOriginal=dm.postEvent
for _,index in ipairs({0,4,3,6})do
    seed(900,0);local dispatch=Dispatch.new();local called={}
    dispatch.mainMenu={getSelectedIndex=function()return index end}
    for _,name in ipairs({'moveToHome','moveToRepository','gotoBuild','moveToResource'})do
        dispatch[name]=function()called[#called+1]=name end
    end
    zqDispatch=dispatch;local a=assert(open());a.callbackfunc();a.callbackfunc()
    equal(#called,1);equal(called[1],({[0]='moveToHome',[4]='moveToRepository',[3]='gotoBuild',[6]='moveToResource'})[index]);balances(502,1)
end
seed(900,0);zqDispatch=Dispatch.new();local a=assert(open());a.callbackfunc();balances(502,1)
seed(900,0);local refreshed=0
function dm:postEvent(key)notifyOriginal(self,key);error('observer failed at 100%')end
zqDispatch={backToLastView=function()refreshed=refreshed+1;error('refresh 100%')end}
local a=assert(open());a.callbackfunc();a.callbackfunc();balances(502,1);equal(writes,1);equal(#events,2);equal(checks,1);equal(refreshed,1)
cold();balances(502,1);equal(dm.__roleData:commitAlchemyUnlock(),'already_owned');dm.postEvent=notifyOriginal
print('PASS actual Home/repository/build/resource rebuild, absent mainMenu, percent-containing observer/refresh faults and durable no-double-charge after cold read')

-- Geometry is measured from packaged legacy PNG sizes by real DialogTheme.
for _,w in ipairs({480,540,640})do
    width=w;height=800
    for _,state in ipairs({{'',0,'长按炼金 · 先完成10次炼金'},{'s001',0,'长按炼金 · 398钻石'},{'s001',1,'长按炼金 · 已解锁'}})do
        seed(900,state[2],state[1]);dm:showBuyGoldBox()
        local shop=scene.children[#scene.children];assert(label(shop,state[3]))
        local scale=shop.alchemyBody:getScale();equal(scale,math.min(1,(w-24)/572))
        assert(572*scale<=w-24+.001,'fitted panel inside viewport')
        equal(shop.s_bg:getScale(),1,'scale applied once to content wrapper')
        local rows=tree(shop,function(n)local z=n:getContentSize();return z.width==530 and z.height==108 end)
        equal(#rows,2);equal(rows[1]:getPositionY(),height/2+35);equal(rows[2]:getPositionY(),height/2-94.6)
        equal(shop.alchemyUnlockEntry:getContentSize().height,44)
        assert(rows[2]:getPositionY()-54>shop.alchemyUnlockEntry:getPositionY()+22)
        assert(shop.alchemyUnlockEntry:getPositionY()-22>height/2-437/2)
        equal(writes,0);shop.alchemyUnlockEntry.callback()
        if state[1]=='s001' and state[2]==0 then
            local dialog=assert(dm.alchemyUnlockDialog)
            local caption=assert(label(dialog,'长按炼金按钮，可持续获得金币。\n\n花费398钻石解锁此功能？'))
            equal(caption.dimensions.width,476);equal(caption.dimensions.height,156);equal(caption.fontSize,28)
            assert(caption:getPositionY()-78>height/2-437/2+90,'body clears confirmation buttons')
            -- Test actual sibling paint order, not mere node presence: the
            -- panel's opaque base must precede paper; both menu subtrees and X
            -- must paint after paper at each fitted viewport size.
            local siblings=dialog.s_bg:getChildren()
            local paper,order={},{ }
            for i,n in ipairs(siblings)do
                local z=n:getContentSize()
                if z.width==556 and z.height==355 then paper=n end
                order[#order+1]={node=n,z=n.z or 0,index=i}
            end
            table.sort(order,function(a,b)return a.z==b.z and a.index<b.index or a.z<b.z end)
            local rank={};for i,v in ipairs(order)do rank[v.node]=i end
            assert(rank[paper],'actual opaque paper node is present')
            assert(rank[siblings[1]]<rank[paper],'paper remains above opaque panel paint')
            for _,title in ipairs({'取 消','398钻石解锁'})do
                local item=assert(label(dialog,title)).parent
                equal(tolua.type(item.parent),'cc.Menu')
                assert(rank[item.parent]>rank[paper],title..' must paint above opaque paper')
            end
            assert(rank[dialog.closeBtn]>rank[paper],'X remains above paper')
            label(dialog,'取 消').parent.callback()
        else assert(not dm.alchemyUnlockDialog)end
        equal(writes,0)
    end
end
print('PASS real gold dialog 480/540/640 fitted geometry, unchanged two row/button sizes, footer gap, three entry states, bounded confirmation prose and button/paper paint order; GUI typography still requires native acceptance')
