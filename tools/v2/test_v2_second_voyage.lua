package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Telemetry = require "LuaClass/V2Telemetry"
local Data = State.getData()

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

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then error(string.format("%s failed: %s", action, tostring(message))) end
end

local function actionLabel(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action.label end
    end
    return nil
end

truthy(Data.by_id.route.tide_breaker_channel, "Tide Graveyard has a hull-growth route")
truthy(Data.by_id.route.tide_cannon_pass, "Tide Graveyard has a gun-growth route")
truthy(Data.by_id.enemy.enemy_tide_warden, "Tide Graveyard has a distinct guardian")
truthy(Data.by_id.reward.reward_tide_rune, "the second rune has a unique reward id")

local hull = State.new("qa_complete")
hull.profile = "player"
apply(hull, "prepare_next_voyage")
apply(hull, "start_voyage")
equal(hull.stage, "tide_route_choice", "second departure no longer replays the first route")
contains(actionLabel(hull, "choose_tide_breaker"), "航损-10", "hull route previews reduced damage")
contains(actionLabel(hull, "choose_tide_cannon"), "补给-2", "non-gun growth leaves cannon route cost intact")
apply(hull, "choose_tide_breaker")
equal(hull.stage, "tide_character_event", "second route now reaches the character event before combat")
apply(hull, "rescue_anchor_keeper")
equal(hull.battle.player_hull, 130, "hull route applies ten damage after growth reduction")
contains(actionLabel(hull, "tide_ram"), "潮盾-100", "hull growth previews a decisive ram")
contains(actionLabel(hull, "tide_ram"), "船体-10", "hull growth previews reduced ram damage")
apply(hull, "tide_ram")
equal(hull.stage, "tide_rune_clue", "decisive ram defeats the guardian")
truthy(hull.flags.tide_guardian_defeated, "guardian defeat is persisted")
truthy(hull.claimed_rewards.reward_tide_guardian, "guardian reward is claimed once")

local guns = State.new("qa_upgrade")
apply(guns, "upgrade_guns")
apply(guns, "promote_sailor")
apply(guns, "prepare_next_voyage")
apply(guns, "start_voyage")
contains(actionLabel(guns, "choose_tide_breaker"), "航损-30", "non-hull growth leaves breaker damage intact")
contains(actionLabel(guns, "choose_tide_cannon"), "补给-0", "gun growth removes cannon route cost")
apply(guns, "choose_tide_cannon")
equal(guns.stage, "tide_character_event", "cannon route also reaches the shared character event")
apply(guns, "rescue_anchor_keeper")
contains(actionLabel(guns, "tide_barrage"), "潮盾-100", "gun growth previews a decisive barrage")
apply(guns, "tide_barrage")
equal(guns.stage, "tide_rune_clue", "decisive barrage defeats the guardian")
equal(guns.battle.player_hull, guns.battle.player_hull_max, "terminal barrage avoids retaliation")

local runeDustBefore = guns.resources.rune_dust
apply(guns, "take_tide_rune")
equal(guns.stage, "tide_settlement", "second rune opens its own settlement")
equal(guns.resources.rune_dust, runeDustBefore + Data.by_id.reward.reward_tide_rune.rune_dust,
    "second rune reward is source driven")
apply(guns, "return_from_tide")
equal(guns.stage, "tide_complete", "second settlement returns to a distinct completion state")
truthy(guns.flags.tide_voyage_complete, "second voyage completion remains recorded")
equal(#State.getActions(guns), 0, "unfinished third-voyage content is not exposed as a fake action")

local failed = State.new("qa_tide_guardian")
failed.battle.player_hull = 5
apply(failed, "tide_barrage")
equal(failed.stage, "failed", "guardian defeat reaches the shared recoverable failure state")
truthy(failed.flags.failed_tide_guardian, "failure remembers the guardian context")
apply(failed, "retry_battle")
equal(failed.stage, "tide_guardian", "guardian retry returns to the correct encounter")
equal(failed.battle.tide_shield, failed.battle.tide_shield_max, "guardian retry restores the full tide shield")

local recovered = State.new("qa_tide_guardian")
recovered.battle.player_hull = 5
apply(recovered, "tide_barrage")
apply(recovered, "recover_at_port")
equal(recovered.stage, "harbor", "guardian recovery returns to the harbor")
equal(recovered.route, nil, "guardian recovery clears the selected route")
equal(recovered.flags.tide_route_chosen, nil, "guardian recovery clears the route marker")
apply(recovered, "start_voyage")
equal(recovered.stage, "tide_route_choice", "recovered voyage can choose a Tide Graveyard route again")

for _, profile in ipairs({
    "qa_tide_route", "qa_tide_signal_gunner", "qa_tide_signal_sailor",
    "qa_tide_guardian", "qa_tide_rune",
    "qa_tide_settlement", "qa_tide_complete",
}) do
    local restored, recovery = State.normalize(State.new(profile), profile)
    equal(recovery, nil, profile .. " remains structurally restorable")
    truthy(State.STAGES[restored.stage], profile .. " restores a valid stage")
end

local tracked = State.new("qa_tide_guardian")
Telemetry.ensureSession(tracked)
local before = Telemetry.snapshot(tracked)
local ok, message = State.apply(tracked, "tide_ram")
local event = Telemetry.record(tracked, "tide_ram", before, ok, message)
equal(event.event_id, "tide_guardian_result", "terminal guardian action has a distinct telemetry result")
equal(Telemetry.getSummary(tracked).tide_guardian_actions, 1, "guardian actions appear in the session summary")

print("V2 second voyage OK: growth routes, Tide Guardian, second rune, recovery, QA and telemetry")
