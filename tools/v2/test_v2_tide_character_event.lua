package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Telemetry = require "LuaClass/V2Telemetry"
local Theme = require "LuaClass/V2UITheme"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function contains(text, expected, message)
    truthy(string.find(text or "", expected, 1, true), message)
end

local function actionLabel(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action.label end
    end
    return nil
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    truthy(ok, message or (action .. " failed"))
    return message
end

local data = State.getData()
truthy(data.by_id.map_node.node_tide_signal, "Tide character event has an authored map node")
truthy(data.by_id.event.event_tide_signal, "Tide character event has an authored event")
equal(data.by_id.balance.tide_bell_shield_damage.value, 20, "bell opening damage stays source driven")
equal(data.by_id.balance.tide_keeper_ram_bonus.value, 25, "keeper ram bonus stays source driven")

local gunner = State.new("qa_tide_signal_gunner")
equal(gunner.stage, "tide_character_event", "gunner QA opens the character event")
equal(State.getStageTitle(gunner), "潮汐墓场 · 墓场求救火", "event has a distinct stage title")
contains(State.getNarrative(gunner), "罗克：现在开炮能打碎钟", "appointed gunner changes the event response")
contains(actionLabel(gunner, "shatter_tide_bell"), "【首席建议】", "appointed gunner recommendation is visible before commitment")
truthy(not string.find(actionLabel(gunner, "rescue_anchor_keeper"), "【首席建议】", 1, true),
    "the unappointed proposal remains available without false emphasis")

local before = Telemetry.snapshot(gunner)
local message = apply(gunner, "shatter_tide_bell")
equal(gunner.stage, "tide_guardian", "bell choice advances to the guardian")
truthy(gunner.flags.tide_bell_shattered, "bell choice is retained as an event consequence")
truthy(gunner.flags.tide_signal_resolved, "character event is recorded as resolved")
truthy(gunner.flags.tide_chief_followed, "following the appointed gunner is recorded")
equal(gunner.battle.tide_shield_max, 100, "guardian still exposes its authored maximum shield")
equal(gunner.battle.tide_shield, 80, "bell shot causes twenty real opening shield damage")
contains(gunner.battle.transfer_summary, "开场潮盾损失 20", "battle state explains the event transfer")
contains(actionLabel(gunner, "tide_barrage"), "潮盾-80", "guardian preview uses the weakened opening shield")
local event = Telemetry.record(gunner, "shatter_tide_bell", before, true, message)
equal(event.event_id, "tide_character_event_choice", "character choice has a distinct telemetry event")
equal(event.crew_upgrade, "crew_upgrade_gunner", "event telemetry retains the appointed officer")
equal(Telemetry.getSummary(gunner).tide_character_choices, 1, "summary counts the character choice")
equal(Telemetry.getSummary(gunner).decisions, 1, "character choice counts as a player decision")

apply(gunner, "tide_barrage")
equal(gunner.stage, "tide_rune_clue", "gunner and bell can resolve the weakened guardian")
contains(gunner.battle_report, "求救火：击碎引潮钟 · 开场削盾", "battle report preserves the event consequence")

local sailor = State.new("qa_tide_signal_sailor")
contains(State.getNarrative(sailor), "米克：给我一条小艇", "appointed sailor changes the event response")
contains(actionLabel(sailor, "rescue_anchor_keeper"), "【首席建议】", "appointed sailor recommendation is visible")
local hullBefore = sailor.ship.hull_max - sailor.voyage_hull_damage
apply(sailor, "rescue_anchor_keeper")
equal(sailor.battle.tide_shield, 100, "rescue preserves the guardian's full opening shield")
contains(sailor.battle.transfer_summary, "撞锚破盾伤害 +25", "rescue transfers readable weak-point knowledge")
contains(actionLabel(sailor, "tide_ram"), "潮盾-100（火力125）｜船体-0",
    "sailor rescue combines weak-point damage with the appointed hull protection")
apply(sailor, "tide_ram")
equal(sailor.stage, "tide_rune_clue", "rescued keeper enables the decisive close-range route")
equal(sailor.battle.player_hull, hullBefore, "sailor-led rescue route resolves without extra ram damage")
contains(sailor.battle_report, "求救火：救下守墓人 · 锚链弱点", "rescue remains visible in the final report")

local independent = State.new("qa_tide_signal_gunner")
apply(independent, "rescue_anchor_keeper")
truthy(not independent.flags.tide_chief_followed, "captain may reject the chief recommendation")
contains(independent.last_result, "另一名船员的方案", "the state acknowledges an independent command")

local retry = State.new("qa_tide_signal_sailor")
apply(retry, "shatter_tide_bell")
retry.battle.player_hull = 5
apply(retry, "tide_barrage")
equal(retry.stage, "failed", "event-prepared guardian can still reach recovery")
apply(retry, "retry_battle")
equal(retry.battle.tide_shield, 80, "retry preserves the resolved bell consequence")
retry.battle.player_hull = 5
apply(retry, "tide_barrage")
apply(retry, "recover_at_port")
equal(retry.flags.tide_bell_shattered, nil, "port recovery clears the abandoned event consequence")
equal(retry.flags.tide_signal_resolved, nil, "port recovery reopens the character event for the next route")

local groups = Theme.outcomeGroups(State.new("qa_tide_signal_sailor"), data)
equal(groups[1].value, "大副 · 米克\n建议先救人", "result groups identify the current chief")
equal(groups[2].value, "开场潮盾 -20\n失去救援窗口", "result groups preview the bell tradeoff")
equal(groups[3].value, "撞锚破盾 +25\n取得锚链弱点", "result groups preview the rescue tradeoff")

for _, profile in ipairs({ "qa_tide_signal_gunner", "qa_tide_signal_sailor" }) do
    local restored, recovery = State.normalize(State.new(profile), profile)
    truthy(recovery == nil and restored.stage == "tide_character_event", profile .. " remains restorable")
end

print("V2 Tide character event OK: chief advice, independent choice, guardian transfer, recovery and telemetry")
