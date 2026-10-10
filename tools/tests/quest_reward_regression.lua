-- Executes production Mission/MissionManagers and getCustomTable with isolated,
-- in-memory CSV/save/inventory fixtures. This is not a native Cocos UI test and
-- never opens or changes a player save or the shipped economy data tables.
package.path = 'bin/res/scripts/?.lua;' .. package.path
package.loaded['LuaClass/Header'] = true
cc = {
    c3b = function(r, g, b) return {r=r, g=g, b=b} end,
    Director = {getInstance=function()
        return {getVisibleSize=function() return {width=640, height=1136} end}
    end},
}
function class(_, constructor)
    local cls = {}
    cls.new = function() return setmetatable(constructor(), {__index=cls}) end
    return cls
end
function clone(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = clone(item) end
    return result
end
local report = print
print = function() end
printn = function() end
csvOftask = 'quests'
csvOfResourceInfo = 'resources'
csvOfSoilderAttribute = 'heroes'
roleMission = 'mission_save'
roleCompletedMissionHistory = 'mission_history'
local now = 1000
NotificationNode = {getInstance=function()
    return {GetGameTime=function() return now end}
end}
ToastUtil = {toastString=function() end}
local state, tables, rewards, saves, nextTriggers, manager
local data = {}
function data:getCSVByID(key) return tables[key] end
function data:getRoleData(key) return state[key] end
function data:setRoleData(key, value)
    state[key] = clone(value)
    if key == roleMission then saves = saves + 1 end
end
local function record(kind, id, amount)
    rewards[#rewards+1] = {kind=kind, id=id, amount=amount}
end
function data:addCoin(amount) record('coin', nil, amount); return 1 end
function data:addDiamond(amount) record('diamond', nil, amount); return 1 end
function data:addPackItemWithId(id, amount) record('item', id, amount) end
function data:addSoilderWithId(id, amount) record('hero', id, amount) end
DataManager = {getInstance=function() return data end}
require 'LuaClass/MissionManagers'
-- Observe the real quest-manager entry point. DataManager has no such method:
-- adding one to the mock would hide an incorrect reward-chain receiver.
local triggerMission = MissionManagers.triggerMissionByIDAndStepInfos
function MissionManagers:triggerMissionByIDAndStepInfos(id, step, reason)
    if reason == 'auto' then nextTriggers[#nextTriggers+1] = id end
    return triggerMission(self, id, step, reason)
end

local function reset()
    now = 1000
    state = {[roleMission]={}, [roleCompletedMissionHistory]={}}
    tables = {
        quests={},
        resources={coin={name='金币'}, diamond={name='钻石'}, item={name='测试物品'}},
        heroes={hero={name='测试船员'}},
    }
    rewards, nextTriggers, saves = {}, {}, 0
    manager = MissionManagers:getInstance()
    manager:init()
    saves = 0
end
local function definition(id)
    tables.quests[id] = {
        complete={{'step', '2'}}, time='10', reward={{'0'}},
        frequency='0', cost='7', trigger='1', killItems={{'0'}},
        next='0', desc='Isolated quest fixture '..id,
    }
    return tables.quests[id]
end
local function add(id, status, duration, start)
    if not tables.quests[id] then definition(id) end
    tables.quests[id].time = tostring(duration or 10)
    local mission = Mission:createMissionByMissionID(id)
    mission.statue = status or 'wait'
    mission.time = duration or 10
    mission.startTime = start or 900
    manager.missions[id] = mission
    manager.datas[id] = mission:getSaveData()
    if mission.statue == 'complete' then
        manager.completedMissions[id] = mission
    else
        manager.waitingMissions[id] = mission
    end
    manager.validMissions[id] = mission
    manager.UIMissions[#manager.UIMissions+1] = mission
    return mission
end
local function savedIDs()
    local ids = {}
    for _, mission in ipairs(state[roleMission]) do
        assert(not ids[mission.id], 'duplicate quest in serialized save')
        ids[mission.id] = mission
    end
    return ids
end
local function assertRemoved(id)
    for _, collection in ipairs({'missions', 'waitingMissions', 'completedMissions', 'validMissions', 'datas'}) do
        assert(manager[collection][id] == nil, collection..' still contains '..id)
    end
    for _, mission in ipairs(manager.UIMissions) do
        assert(mission.id ~= id, 'UI still contains '..id)
    end
    assert(not savedIDs()[id], 'serialized save still contains '..id)
end
local function assertReward(index, kind, id, amount)
    local reward = assert(rewards[index], 'missing reward/cost call '..index)
    assert(reward.kind == kind and reward.id == id and reward.amount == amount,
        'reward/cost identity or amount changed at '..index)
end
local passed, failed = 0, 0
local function test(name, run)
    reset()
    local ok, err = pcall(run)
    if ok then
        passed = passed + 1
        report('PASS '..name)
    else
        failed = failed + 1
        report('FAIL '..name..': '..tostring(err))
    end
end

test('manager claim, repeat claim and survivor persistence', function()
    definition('claim').reward = {{'2', 'coin', '11'}}
    local mission = add('claim', 'complete')
    local survivor = add('survivor', 'wait', -1)
    manager:tryReceiveMissionRewardsByMissionID('claim')
    assert(mission.statue == 'receive' and #rewards == 1)
    assertReward(1, 'coin', nil, 11)
    assertRemoved('claim')
    assert(savedIDs().survivor and manager.missions.survivor == survivor)
    mission:receive()
    manager:tryReceiveMissionRewardsByMissionID('claim')
    assert(#rewards == 1, 'repeat claim duplicated reward')
end)

test('direct mixed hero/item/currency claim preserves costs and starts next quest once', function()
    local info = definition('claim')
    info.reward = {{'1', 'hero', '2'}, {'2', 'coin', '13'}, {'2', 'diamond', '3'}, {'2', 'item', '4'}}
    info.killItems = {{'coin', '5'}, {'diamond', '1'}, {'item', '2'}}
    info.next = 'next'
    definition('next')
    local mission = add('claim', 'complete')
    add('survivor', 'wait', -1)
    mission:receive()
    assert(#rewards == 7)
    assertReward(1, 'coin', nil, -5)
    assertReward(2, 'diamond', nil, -1)
    assertReward(3, 'item', 'item', -2)
    assertReward(4, 'hero', 'hero', 2)
    assertReward(5, 'coin', nil, 13)
    assertReward(6, 'diamond', nil, 3)
    assertReward(7, 'item', 'item', 4)
    assertRemoved('claim')
    assert(savedIDs().survivor and savedIDs().next)
    assert(manager.waitingMissions.next.startTime == now and #nextTriggers == 1)
    mission:receive()
    manager:tryReceiveMissionRewardsByMissionID('claim')
    assert(#rewards == 7 and #nextTriggers == 1, 'repeat claim changed rewards/chain')
end)

test('missing and waiting quest claims are inert', function()
    manager:tryReceiveMissionRewardsByMissionID('missing')
    local waiting = add('waiting', 'wait', -1)
    manager:tryReceiveMissionRewardsByMissionID('waiting')
    waiting:receive()
    assert(waiting.statue == 'wait' and manager.waitingMissions.waiting == waiting)
    assert(#rewards == 0 and #nextTriggers == 0 and saves == 0)
end)

test('UI removal uses requested ID and exact array position', function()
    local first = add('first', 'wait', -1)
    add('middle', 'wait', -1)
    local last = add('last', 'wait', -1)
    manager:removeMissionInUI(nil, 'middle')
    assert(#manager.UIMissions == 2 and manager.UIMissions[1] == first and manager.UIMissions[2] == last)
    manager:removeMissionInUI(first)
    assert(#manager.UIMissions == 1 and manager.UIMissions[1] == last)
    manager:removeMissionInUI(nil, 'missing')
    assert(#manager.UIMissions == 1)
end)

local function expiryFixture()
    add('expired1')
    add('expired2')
    add('live1', 'wait', 100, 990)
    add('expired3')
    add('live2', 'wait', -1)
    add('complete', 'complete')
end
test('waiting-list read removes adjacent expired quests and retains all survivors on reload', function()
    expiryFixture()
    local waiting = manager:getWaitingMissions()
    assert(waiting.len == 2 and waiting[1].id == 'live1' and waiting[2].id == 'live2')
    for _, id in ipairs({'expired1', 'expired2', 'expired3'}) do assertRemoved(id) end
    local ids = savedIDs()
    assert(ids.live1 and ids.live2 and ids.complete and #state[roleMission] == 3)
    assert(saves == 1, 'expiration sweep should persist once')
    manager:init()
    assert(manager.waitingMissions.len == 2 and manager.completedMissions.len == 1)
end)

test('all-quests read preserves display order while expiring adjacent quests', function()
    expiryFixture()
    local all = manager:getAllMissions()
    assert(#all == 3 and all[1].id == 'complete' and all[2].id == 'live1' and all[3].id == 'live2')
    for _, id in ipairs({'expired1', 'expired2', 'expired3'}) do assertRemoved(id) end
    assert(#state[roleMission] == 3 and saves == 1)
    manager:getAllMissions()
    manager:getWaitingMissions()
    assert(saves == 1, 'unchanged reads must not rewrite saves')
end)

test('expired quest trigger removes all indexes and persists cleanup', function()
    add('expired')
    add('survivor', 'wait', -1)
    manager:triggerMissionByIDAndStepInfos('expired', {id='step', num=1}, 'taskOk')
    assertRemoved('expired')
    assert(savedIDs().survivor and saves == 1 and #rewards == 0)
end)

test('explicit timeout clears valid/UI/save indexes', function()
    local expired = add('expired')
    add('survivor', 'wait', -1)
    manager:theMissionIsTimeout(expired)
    assertRemoved('expired')
    assert(savedIDs().survivor)
end)

test('progress updates do not duplicate one quest or drop an unrelated save', function()
    add('first', 'wait', -1)
    add('last', 'wait', -1)
    manager:triggerMissionByIDAndStepInfos('first', {id='step', num=1}, 'taskOk')
    local ids = savedIDs()
    assert(#state[roleMission] == 2 and ids.first and ids.last)
    assert(ids.first.complete.step.num == 1 and ids.first.statue == 1)
end)

test('existing exact-deadline, unlimited and completed timing semantics stay intact', function()
    local deadline = add('deadline', 'wait', 10, 990)
    local unlimited = add('unlimited', 'wait', -1)
    local complete = add('complete', 'complete')
    assert(deadline:checkTime() and unlimited:checkTime() and complete:checkTime())
    now = 1001
    assert(not deadline:checkTime() and unlimited:checkTime() and complete:checkTime())
end)

print = report
assert(failed == 0, string.format('%d quest regression groups failed; %d passed', failed, passed))
print(string.format('PASS: %d production quest regression groups with isolated mocks; no native UI coverage', passed))
