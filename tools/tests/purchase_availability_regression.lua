-- Executes the production guard, UI methods and existing result callback with
-- strict Cocos/in-memory fixtures. Never loads a native billing library, sends
-- a request, writes a player save, or claims store/device purchase acceptance.
local root = 'bin/res/scripts/LuaClass/'
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s
end
local fixture = read('tools/tests/home_master_regression.lua')
local stop = assert(fixture:find("\ndofile(root..'Header.lua')", 1, true))
local H = assert(loadstring(fixture:sub(1, stop - 1) ..
    '\nreturn {node=node, methods=Node}', '@purchase-node-fixture'))()
local N = H.methods
local function equal(a, b, why)
    assert(a == b, (why or 'value') .. ': ' .. tostring(a) .. ' ~= ' .. tostring(b))
end
local function find(n, predicate)
    if predicate(n) then return n end
    for _, child in ipairs(n.children) do local found = find(child, predicate); if found then return found end end
end
local function label(n, text) return assert(find(n, function(c) return c.text == text end), text) end
local function collect(n, predicate, out)
    out = out or {}; if predicate(n) then out[#out + 1] = n end
    for _, child in ipairs(n.children) do collect(child, predicate, out) end
    return out
end
local function instance(cls)
    return setmetatable(H.node('Fixture'), {__index = function(_, k) return cls[k] or N[k] end})
end
function class(_, factory)
    local cls = {}
    function cls.new(...)
        local n = factory(); setmetatable(n, {__index = function(_, k) return cls[k] or N[k] end})
        if cls.ctor then cls.ctor(n, ...) end
        return n
    end
    return cls
end
function N:getTag() return self.tag end
function N:getViewSize() return self.viewSize or self.size end
function N:setViewSize(s) self.viewSize = s end
function N:setContentOffset(p) self.offset = p end
function N:setContainer(n) self.container = n; self:addChild(n) end
function N:setClippingToBounds(v) self.clipping = v end
function N:setBounceable(v) self.bounce = v end
function N:setDirection(v) self.direction = v end
function N:setDelegate() end
function N:setTouchEnabled(v) self.touchEnabled = v end
function N:setSize(s) self.size = s end
function N:addPage(n) self:addChild(n) end
function N:addEventListenerPageView(f) self.pageCallback = f end
function N:getSpriteFrame() return self.path end
function N:setSpriteFrame(frame) self.frame = frame end
function N:setFontSize(v) self.fontSize = v end
function N:disableStroke() end
cc.ScrollView = {create = function(_, size) local n = H.node('ScrollView'); n.viewSize = size; return n end}
cc.Show = {create = function() return {kind = 'Show', args = {}} end}
ccui = {TouchEventType = {ended = 2},
    Layout = {create = function() return H.node('Layout') end},
    PageView = {create = function() return H.node('PageView') end}}
local scene = H.node('Scene')
local scheduler = {scheduleScriptFunc = function() return 1 end, unscheduleScriptEntry = function() end}
cc.Director = {getInstance = function() return {
    getVisibleSize = function() return cc.size(640, 1136) end,
    getWinSize = function() return cc.size(640, 1136) end,
    getRunningScene = function() return scene end,
    getScheduler = function() return scheduler end} end}

-- Read shipped constants, rather than repeating the C++ build-macro values.
dofile('src/engine/cocos2d-x/cocos/scripting/lua-bindings/script/Cocos2dConstants.lua')
local platform = cc.PLATFORM_OS_LINUX
cc.Application = {getInstance = function() return {getTargetPlatform = function() return platform end} end}
local notices, requests = {}, {}
ToastUtil = {downString = function(_, text) notices[#notices + 1] = text end}
local function purchaseStub(id) requests[#requests + 1] = id end
purchase = purchaseStub
require = function(name) return _G[name:match('([^/]+)$')] or true end
local availability = dofile(root .. 'PurchaseAvailability.lua')
local fixtureRequire = require
require = function(name)
    if name == 'LuaClass/PurchaseAvailability' then return availability end
    if name == 'LuaClass/AdventureProgress' then return {getState=function()return {enabled=false}end} end
    return fixtureRequire(name)
end
for _, name in ipairs({'Header', 'HomeTheme', 'MasterTheme', 'DialogTheme', 'SDButton', 'AlertView', 'ChargeMode', 'DiamondStore', 'Explore'}) do
    dofile(root .. name .. '.lua')
end
cclog = function() end
json = {encode = function() return 'fixture' end}
getTableRowNum = function(t) return #t end

-- API contract evidence: these are the actual shipped native methods.
local binding = read('src/engine/cocos2d-x/cocos/scripting/lua-bindings/auto/lua_cocos2dx_auto.cpp')
assert(binding:find('cobj->getTargetPlatform()', 1, true))
local native = read('src/NewPirate/common/UtilTools/GameBaseUtil.cpp')
assert(native:find('#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)', native:find('void purchase', 1, true), true))
assert(native:find('#elif (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)', native:find('void purchase', 1, true), true))
assert(read('src/NewPirate/game/ToLua/TOLUA_GameBaseUtil.cpp'):find('purchase(parm);', 1, true))
for _, os in ipairs({cc.PLATFORM_OS_WINDOWS, cc.PLATFORM_OS_LINUX, cc.PLATFORM_OS_MAC,
    cc.PLATFORM_OS_BLACKBERRY, cc.PLATFORM_OS_EMSCRIPTEN, 999}) do
    platform = os; assert(not availability.isAvailable()); assert(not availability.request('2'))
    equal(notices[#notices], '当前平台暂不支持充值购买')
end
platform = nil; assert(not availability.request('2')); equal(#requests, 0, 'unsupported targets never invoke bridge')
for _, os in ipairs({cc.PLATFORM_OS_IPHONE, cc.PLATFORM_OS_IPAD, cc.PLATFORM_OS_ANDROID}) do
    platform = os; assert(availability.isAvailable()); assert(availability.request('unchanged-fixture-id'))
    equal(requests[#requests], 'unchanged-fixture-id', 'no product coercion')
end
purchase = nil; assert(not availability.request('2')); purchase = purchaseStub
requests, notices = {}, {}
print('PASS actual platform constants/API: unsupported and missing bridge fail visibly; mobile delegates original ID only')

local ownsOneTime = false
GuideController = {getInstance = function() return {getIsHaveStep = function() return ownsOneTime end} end}
local function expectUnavailable(callback, why)
    local n, r = #notices, #requests
    callback(); equal(#requests, r, why .. ' never purchases'); equal(#notices, n + 1, why .. ' gives feedback')
    equal(notices[#notices], '当前平台暂不支持充值购买')
end
local function chargeList()
    local view = instance(ChargeLayer)
    view.scrollView = H.node('ScrollView'); view.scrollView.size = cc.size(578, 730)
    view.scrollViewContainer = H.node('Layer')
    ChargeLayer.loadData(view)
    return view, view.scrollViewContainer.children[1].children
end
for _, os in ipairs({cc.PLATFORM_OS_LINUX, cc.PLATFORM_OS_MAC}) do
    platform = os
    local charge, offers = chargeList(); equal(#offers, 3)
    for _, offer in ipairs(offers) do expectUnavailable(offer.callback, 'full charge') end
    expectUnavailable(offers[1].callback, 'repeat full charge')
    local mini = instance(ChargeMiniLayer); mini.s_position = cc.p(320, 568)
    mini.setCancelCallback = AlertView.setCancelCallback
    assert(ChargeMiniLayer.init(mini))
    local button = assert(find(mini, function(c) return c.callback ~= nil end))
    expectUnavailable(button.callback, 'mini charge')
end
platform = cc.PLATFORM_OS_IPHONE
local _, offers = chargeList()
for _, offer in ipairs(offers) do offer.callback() end
equal(table.concat(requests, ','), '2,3,1', 'full charge keeps configured IDs')
local mini = instance(ChargeMiniLayer); mini.s_position = cc.p(320, 568); mini.setCancelCallback = AlertView.setCancelCallback
ChargeMiniLayer.init(mini); find(mini, function(c) return c.callback ~= nil end).callback()
equal(requests[#requests], '2', 'mini charge original ID')
-- The dormant one-time branch remains guarded too, without changing shipped data.
local chargeData
for index = 1, 20 do
    local name, value = debug.getupvalue(ChargeLayer.loadData, index)
    if name == 'chargeData' then chargeData = value; break end
end
assert(chargeData); local previousId = chargeData[1].id; chargeData[1].id = '5'
platform = cc.PLATFORM_OS_LINUX; _, offers = chargeList()
expectUnavailable(offers[1].callback, 'one-time unowned charge')
ownsOneTime = true; local r = #requests; offers[1].callback(); equal(#requests, r); equal(notices[#notices], '该商品不能重复购买')
ownsOneTime = false; platform = cc.PLATFORM_OS_ANDROID; offers[1].callback(); equal(requests[#requests], '5')
chargeData[1].id = previousId
print('PASS real full/mini/one-time offer handlers preserve IDs, repeat restrictions, and unsupported retry feedback')

-- Only in-memory records; production economy and persistent saves are forbidden.
local writes = 0
local storeData = {['1'] = {{'gift', -1, 0}}, ['2'] = {}}
local gift = {name = 'Fixture gift', payType = '5', item = {}, desc = {}, price = '8'}
local push = {name = 'Fixture push', payType = '7', title = {}, price = {},
    desc = {{'Fixture contents'}}, bestIcon = '0', allPrice = '16', nowPrice = '8', icon = 'dazhe_05.png'}
local dm = {
    getRoleData = function(_, key) if key == roleDiamondStoreData then return storeData end end,
    setRoleData = function(_, key, value)
        -- loadData clears this ephemeral per-map bookkeeping even for an empty store.
        equal(key, roleMapBuyItems); equal(value, nil); writes = writes + 1
    end,
    getCurDiamondStoreGoods = function() return 'gift' end,
    getCSVByID = function(_, key)
        if key == csvOfShopGift then return {gift = gift} end
        if key == csvOfPushGift then return {gift = push} end
        equal(key, csvOfShopItem); return {}
    end,
    addDiamond = function() error('purchase UI must not award diamonds') end,
    addCoin = function() error('purchase UI must not award coins') end,
}
DataManager = {getInstance = function() return dm end}
SaveDataManager = {getInstance = function() error('purchase UI must not access a save') end}
local store = instance(DiamondStore)
store.originPos = cc.p(0, 0); store.areaWidth = 610; store.areaHeight = 900
store.s_position = cc.p(320, 568); store.pointArr = {}
DiamondStore.loadData(store)
local banner = store:getChildByTag(1):getChildByTag(1):getChildByTag(1):getChildByTag(1)
local function openGift()
    banner.callback(1, banner)
    return scene.children[#scene.children]
end
for _, os in ipairs({cc.PLATFORM_OS_LINUX, cc.PLATFORM_OS_MAC, cc.PLATFORM_OS_IPAD}) do
    platform = os
    local before = #requests; local writeBefore = writes
    local alert = openGift(); label(alert, '取 消').parent.callback(); equal(#requests, before); equal(alert:getParent(), nil)
    alert = openGift()
    if os == cc.PLATFORM_OS_IPAD then
        label(alert, '购 买').parent.callback(); equal(requests[#requests], '5')
    else expectUnavailable(label(alert, '购 买').parent.callback, 'recommended gift') end
    equal(alert:getParent(), nil, 'gift details preserves close-on-confirm')
    alert = openGift(); alert.closeBtn:onSingleCLick(); equal(alert:getParent(), nil, 'gift close remains available')
    equal(writes, writeBefore, 'purchase and cancel do not write economy/state')

    local pushed = instance(PushGiftView); local closed = 0; pushed.close = function() closed = closed + 1 end
    local purchaseBefore = #requests; assert(PushGiftView.init(pushed)); equal(#requests, purchaseBefore, 'showing push offer never charges')
    local controls = collect(pushed, function(c) return c.callback ~= nil end); equal(#controls, 2)
    if os == cc.PLATFORM_OS_IPAD then controls[2].callback(); equal(requests[#requests], '7')
    else expectUnavailable(controls[2].callback, 'push gift'); expectUnavailable(controls[2].callback, 'push gift repeat') end
    controls[1].callback(); equal(closed, 1, 'push gift close callback retained')
    equal(writes, writeBefore, 'push offer never writes economy/state')
end
print('PASS real recommended/push gift methods: unchanged product IDs, close/cancel behavior, no fake rewards or writes')

local deaths, returns, clears, transformed = 0, 0, 0, 0
local explore = instance(Explore)
explore.isHungry = true; explore.eventManger = {eventWaitingQueue = {0}}
explore.getNumberOfRunningActions = function() return 1 end
explore.bagController = {
    safeClearMissionData = function() clears = clears + 1 end,
    safeTransformCoinToPack = function(_, isDead) equal(isDead, true); transformed = transformed + 1 end}
explore.clearMapInfoData = function() clears = clears + 1 end
explore.addDeadData = function() deaths = deaths + 1 end
explore.returnToBase = function(_, reason) equal(reason, 'NoBread'); returns = returns + 1 end
local deathWrites = {}
dm.setRoleData = function(_, key, value) deathWrites[#deathWrites + 1] = {key, value} end
TransformLayer = {create = function() return {
    setCalback = function(self, callback) self.callback = callback end,
    transform = function(self) self.callback() end} end}
for _, os in ipairs({cc.PLATFORM_OS_LINUX, cc.PLATFORM_OS_MAC, cc.PLATFORM_OS_ANDROID}) do
    platform = os; Explore.moveEnd(explore)
    local alert = scene.children[#scene.children]; equal(alert.isAutoClose, false)
    local r, d, w = #requests, deaths, #deathWrites
    local safe = label(alert, '安全回城').parent.callback
    if os == cc.PLATFORM_OS_ANDROID then safe(); equal(requests[#requests], '4'); equal(#requests, r + 1)
    else expectUnavailable(safe, 'safe return'); expectUnavailable(safe, 'safe return repeat') end
    equal(alert:getParent(), scene, 'safe-return request leaves retry/decline choices available')
    equal(deaths, d); equal(#deathWrites, w, 'safe-return request never simulates death or rescue')
    label(alert, '确认死亡').parent.callback(); equal(alert:getParent(), nil)
    equal(deaths, d + 1); equal(#deathWrites, w + 2)
    equal(deathWrites[w + 1][1], roleStatue); equal(deathWrites[w + 1][2], 0)
    equal(deathWrites[w + 2][1], roleBreadCostDecimal); equal(deathWrites[w + 2][2], 0)
end
equal(deaths, 3); equal(returns, 3); equal(transformed, 3); equal(clears, 6)
-- Existing native-result handler is unchanged; test only with synthetic callbacks.
local callbackReturns = 0
paySuccess = function() callbackReturns = callbackReturns + 1 end
local notification = {}; NotificationNode = {getInstance = function() return notification end}
dofile(root .. 'CCall.lua')
chargeSuccess(2004); equal(callbackReturns, 0); equal(notification.buyStatus, nil)
chargeSuccess(1004); equal(callbackReturns, 1); equal(notification.buyStatus, 4)
print('PASS real hunger modal retains retry/decline; explicit death and synthetic native-result callbacks retain their outcomes')

-- Every production real-money UI call must pass the shared guard. Virtual
-- currency shop methods are deliberately outside this routing requirement.
for file, count in pairs({ChargeMode = 3, DiamondStore = 2, Explore = 1}) do
    local source = read(root .. file .. '.lua')
    local _, actual = source:gsub('PurchaseAvailability%.request%(', '')
    equal(actual, count, file .. ' guards every purchase call')
    assert(not source:find('%f[%w]purchase%s*%('), file .. ' cannot bypass shared guard')
end
print('PASS all six real-money call sites use the shared guard; no live billing or service call performed')
