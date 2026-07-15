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

local function trackedApply(state, action)
    local before = Telemetry.snapshot(state)
    local ok, message = State.apply(state, action)
    local event = Telemetry.record(state, action, before, ok, message)
    if not ok then
        error(string.format("%s failed: %s", action, tostring(message)))
    end
    return event
end

equal(#Data.telemetry_event, 17, "Phase 4 exports the full local event contract")
equal(#Data.quality_gate, 10, "Phase 4 exports every decision and quality gate")

local state = State.new("qa_fresh")
local telemetry = Telemetry.ensureSession(state)
equal(#telemetry.events, 1, "session initialization emits one start event")
equal(telemetry.events[1].session_id, telemetry.session_id, "session start carries its id")
equal(telemetry.events[1].profile, "qa_fresh", "session start carries its profile")

trackedApply(state, "accept_call")
local moduleEvent = trackedApply(state, "select_reinforced_hull")
equal(moduleEvent.event_id, "module_selected", "module selection is classified")
equal(moduleEvent.module_preference, "module_reinforced_hull", "module preference is recorded")
trackedApply(state, "start_voyage")
local intelEvent = trackedApply(state, "reveal_route_intel")
equal(intelEvent.event_id, "route_intel_revealed", "navigator intel is classified")
truthy(intelEvent.route_intel, "navigator intel result is recorded")
trackedApply(state, "choose_safe_route")
trackedApply(state, "rest_at_cove")
trackedApply(state, "lash_cargo")
trackedApply(state, "resist_whisper")
trackedApply(state, "break_cursed_compass")
trackedApply(state, "fire_at_deck")
trackedApply(state, "fire_at_deck")
trackedApply(state, "board_now")
trackedApply(state, "boarding_attack")
trackedApply(state, "boarding_attack")
local victoryEvent = trackedApply(state, "boarding_attack")
equal(victoryEvent.event_id, "battle_result", "the winning action is recorded as a battle result")
trackedApply(state, "take_rune_clue")
trackedApply(state, "return_to_port")
trackedApply(state, "upgrade_hull")

local summary = Telemetry.getSummary(state)
truthy(summary.completed, "session summary identifies a completed sample")
truthy(summary.chapter_complete, "session summary retains the chapter goal")
equal(summary.profile, "qa_fresh", "session summary retains the QA profile")
equal(summary.decisions, 5, "route and authored voyage decisions are counted")
equal(summary.naval_actions, 3, "two volleys and boarding choice are counted")
equal(summary.boarding_actions, 2, "non-terminal boarding actions are counted")
equal(summary.battle_results, 1, "terminal boarding action is counted once")
equal(summary.invalid_actions, 0, "valid completion has no friction events")

local invalid = State.new("qa_fresh")
Telemetry.ensureSession(invalid)
local beforeInvalid = Telemetry.snapshot(invalid)
local ok, message = State.apply(invalid, "upgrade_hull")
local invalidEvent = Telemetry.record(invalid, "upgrade_hull", beforeInvalid, ok, message)
equal(ok, false, "invalid action remains rejected")
equal(invalidEvent.event_id, "invalid_action", "rejected action is captured as friction")
equal(Telemetry.getSummary(invalid).invalid_actions, 1, "friction appears in the session summary")

for index = 1, Telemetry.MAX_EVENTS + 20 do
    Telemetry.record(invalid, "unknown_" .. index, Telemetry.snapshot(invalid), false, "test")
end
equal(#invalid.telemetry.events, Telemetry.MAX_EVENTS, "local records are bounded")

local restored = State.normalize(state, "qa_fresh")
equal(restored.telemetry.session_id, state.telemetry.session_id, "current schema restores telemetry with the save")
equal(#restored.telemetry.events, #state.telemetry.events, "save restoration retains the event history")

local phase3Save = State.new("qa_fresh")
phase3Save.schema_version = 3
phase3Save.stage = "route_choice"
phase3Save.resources.provisions = 4
local migrated = State.normalize(phase3Save, "qa_fresh")
equal(migrated.schema_version, 4, "Phase 3 save migrates to the current schema")
equal(migrated.stage, "route_choice", "Phase 3 save keeps chapter progress")
equal(migrated.resources.provisions, 4, "Phase 3 save keeps resources")
equal(migrated.telemetry, nil, "migration leaves telemetry initialization to the controller")

local damaged = State.normalize({ schema_version = 4, chapter_id = "chapter_01", stage = "broken" }, "qa_fresh")
equal(damaged.stage, "opening", "damaged save falls back to a valid fresh state")

print("V2 Phase 4 telemetry OK: contract, classification, completion summary, friction, cap and save migration")
