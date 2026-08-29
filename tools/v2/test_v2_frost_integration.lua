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
    return message
end

local function actionLabel(state, actionId)
    for _, action in ipairs(State.getActions(state)) do
        if action.id == actionId then return action.label end
    end
    return nil
end

-- Formal authored ids exist, but the finished second-voyage player state still
-- has no action that opens unfinished third-voyage presentation.
truthy(Data.by_id.route.frost_pack_channel, "Frostbound has an authored turn route")
truthy(Data.by_id.route.frost_flare_pass, "Frostbound has an authored cannon route")
truthy(Data.by_id.enemy.enemy_frost_giant, "Frostbound has a distinct moving-hazard enemy")
equal(Data.by_id.route.frost_pack_channel.supply_cost,
    Data.by_id.balance.frost_pack_route_supply_cost.value,
    "pack route cost agrees with the authored Frost rules")
equal(Data.by_id.route.frost_flare_pass.supply_cost,
    Data.by_id.balance.frost_flare_route_supply_cost.value,
    "flare route cost agrees with the authored Frost rules")
equal(#State.getActions(State.new("qa_tide_complete")), 0,
    "player entry remains closed until Frost art and forecast UI are ready")

-- Navigator path: exact previews remain equal to applied state deltas and the
-- changing spatial window reaches the third rune without hull loss.
local navigator = State.new("qa_frost_route")
contains(actionLabel(navigator, "choose_frost_pack"), "错舵船体-14",
    "hull growth and sailor payoff are visible before route commitment")
apply(navigator, "choose_frost_pack")
equal(navigator.stage, "frost_character_event", "Frost route reaches the beacon decision")
apply(navigator, "read_ice_chart")
equal(navigator.stage, "frost_hazard", "navigator choice reaches the moving ice")
contains(actionLabel(navigator, "frost_turn_port"), "【本轮窗口】",
    "the first left opening is mapped to the matching spatial action")
contains(actionLabel(navigator, "frost_turn_port"), "推进+2｜船体-0｜补给-0",
    "navigator path exposes exact pre-commit consequences")
local hullBefore = navigator.frost.hull
local firstResult = apply(navigator, "frost_turn_port")
contains(firstResult, "下一轮冰潮位置已经更新",
    "a non-terminal action reports the changed forecast state")
equal(navigator.frost.hull, hullBefore, "applied correct turn matches the zero-damage preview")
contains(actionLabel(navigator, "frost_turn_starboard"), "【本轮窗口】",
    "the next round visibly moves the best action to starboard")
apply(navigator, "frost_turn_starboard")
local terminalResult = apply(navigator, "frost_turn_port")
contains(terminalResult, "航道已经贯通",
    "the terminal action reports passage completion instead of generic movement")
equal(navigator.stage, "frost_rune_clue", "three correct turns cross the authored hazard")
truthy(navigator.flags.frost_giant_passed, "passage completion is persisted")
truthy(navigator.claimed_rewards.reward_frost_passage, "passage reward is source driven")
apply(navigator, "take_frost_rune")
equal(navigator.stage, "frost_settlement", "third rune reaches a distinct settlement")
truthy(navigator.flags.frost_voyage_complete, "third rune records voyage completion")
apply(navigator, "return_from_frost")
equal(navigator.stage, "frost_complete", "third settlement returns to a distinct completion")

-- Medic path deliberately hides exact values, then makes its one-use recovery
-- visible in the applied ship state.
local medic = State.new("qa_frost_beacon_medic")
apply(medic, "warm_rescue_team")
contains(actionLabel(medic, "frost_turn_starboard"), "船体 0～-24",
    "medic path shows an honest range instead of fake precision")
local medicHull = medic.frost.hull
local medicResult = apply(medic, "frost_turn_port")
contains(medicResult, "艾琳同时恢复 6 船体",
    "medic recovery is visible in the committed result")
equal(medic.frost.hull, medicHull,
    "sailor reduction plus the one-use recovery can fully absorb this first mistake")

local flare = State.new("qa_frost_route")
apply(flare, "choose_frost_flare")
apply(flare, "read_ice_chart")
apply(flare, "frost_break_ice")
apply(flare, "frost_turn_port")
apply(flare, "frost_break_ice")
equal(flare.stage, "frost_rune_clue",
    "the authored flare route also completes through its changing center window")

-- Failure is caused by insufficient passage progress, retry retains route and
-- beacon, while port recovery clears both temporary decisions.
local failed = State.new("qa_frost_hazard")
apply(failed, "frost_turn_starboard")
apply(failed, "frost_turn_port")
apply(failed, "frost_turn_starboard")
equal(failed.stage, "failed", "three wrong windows reach shared recoverable failure")
equal(failed.failure_reason, "三轮冰潮结束时仍未驶出封锁",
    "failure explains the progress boundary rather than a renamed shield")
local routeBeforeRetry = failed.route
local beaconBeforeRetry = failed.frost.beacon_choice
apply(failed, "retry_battle")
equal(failed.stage, "frost_hazard", "retry restarts the moving-ice encounter")
equal(failed.route, routeBeforeRetry, "retry retains the Frost route")
equal(failed.frost.beacon_choice, beaconBeforeRetry, "retry retains the beacon decision")
equal(failed.frost.progress, 0, "retry clears only temporary passage progress")

local recovered = State.new("qa_frost_hazard")
apply(recovered, "frost_turn_starboard")
apply(recovered, "frost_turn_port")
apply(recovered, "frost_turn_starboard")
apply(recovered, "recover_at_port")
equal(recovered.stage, "harbor", "Frost failure can recover at the harbor")
equal(recovered.route, nil, "port recovery clears the Frost route")
equal(recovered.frost, nil, "port recovery clears temporary forecast state")
apply(recovered, "start_voyage")
equal(recovered.stage, "frost_route_choice",
    "QA recovery can re-enter Frost without exposing the Tide completion button")

-- Schema 4 saves remain compatible; schema 5 Frost QA states restore with
-- current authored rules instead of persisting stale tuning values.
local oldTide = State.new("qa_tide_complete")
oldTide.schema_version = 4
local migrated, migrationMessage = State.normalize(oldTide, "qa_tide_complete")
equal(migrationMessage, nil, "schema 4 Tide completion migrates without reset")
equal(migrated.schema_version, 5, "compatible saves advance to schema 5")
local savedFrost = State.new("qa_frost_hazard")
savedFrost.frost.rules.collision_damage = 999
local restored, recoveryMessage = State.normalize(savedFrost, "qa_frost_hazard")
equal(recoveryMessage, nil, "schema 5 Frost state is structurally restorable")
equal(restored.frost.rules.collision_damage,
    Data.by_id.balance.frost_collision_damage.value,
    "restored Frost state receives current authored balance rules")

-- Local telemetry records route, character and each hazard commitment with the
-- true round/progress fields needed to evaluate forecast understanding.
local tracked = State.new("qa_frost_hazard")
Telemetry.ensureSession(tracked)
local before = Telemetry.snapshot(tracked)
local ok, message = State.apply(tracked, "frost_turn_port")
local event = Telemetry.record(tracked, "frost_turn_port", before, ok, message)
equal(event.event_id, "frost_hazard_action", "Frost action has a dedicated telemetry event")
equal(event.frost_progress, 2, "telemetry records actual passage progress")
equal(event.frost_round, 2, "telemetry records the resulting round")
equal(Telemetry.getSummary(tracked).frost_hazard_actions, 1,
    "Frost actions appear in the local session summary")

for _, profile in ipairs({
    "qa_frost_route", "qa_frost_beacon_navigator", "qa_frost_beacon_medic",
    "qa_frost_hazard", "qa_frost_rune", "qa_frost_complete",
}) do
    local restoredProfile, warning = State.normalize(State.new(profile), profile)
    equal(warning, nil, profile .. " remains structurally restorable")
    truthy(State.STAGES[restoredProfile.stage], profile .. " restores a valid stage")
end

print("V2 Frost integration OK: authored data, QA loop, migration, recovery, telemetry and hidden player gate passed")
