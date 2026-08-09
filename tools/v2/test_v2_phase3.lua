package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"
local Data = State.getData()

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function presentationCopyHasNoQAMarker(state, profile)
    for _, field in ipairs({ "objective", "last_result", "battle_report" }) do
        local value = state[field]
        if type(value) == "string" and string.find(value, "QA", 1, true) then
            error(string.format("%s embeds a QA marker in player-visible %s", profile, field))
        end
    end
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then error(string.format("%s failed: %s", action, tostring(message))) end
end

truthy(#Data.event >= 8, "Chapter 1 retains at least eight authored events")
truthy(#Data.dialogue >= 18, "Chapter 1 has plot and voyage dialogue coverage")
equal(#Data.audio_cue, 6, "approved V2 audio cue set is exported")

local safe = State.new("qa_explore")
apply(safe, "choose_safe_route")
equal(safe.active_event, "event_safe_cove", "safe route enters its authored event")
apply(safe, "press_through_cove")
equal(safe.stage, "black_tide", "route event converges at black tide")
apply(safe, "ride_black_tide")
equal(safe.stage, "whisper", "black tide advances to whisper")
equal(safe.voyage_hull_damage, Data.by_id.balance.black_tide_hull_damage.value, "black tide damage is source driven")
apply(safe, "resist_whisper")
equal(safe.stage, "curse_choice", "whisper advances to the cursed compass event")
apply(safe, "break_cursed_compass")
equal(safe.battle.crew_hp_max, Data.by_id.enemy.enemy_cursed_raider.boarding_power
    + Data.by_id.route.safe_route.crew_max_bonus
    + Data.by_id.balance.compass_crew_bonus.value, "breaking the compass strengthens boarding state")

local risky = State.new("qa_explore")
apply(risky, "choose_risky_route")
apply(risky, "rescue_survivors")
truthy(risky.claimed_rewards.reward_rescue, "rescuing survivors grants the authored smaller reward")
apply(risky, "lash_cargo")
apply(risky, "listen_whisper")
apply(risky, "follow_cursed_compass")
equal(risky.battle.enemy_ship_hp, Data.by_id.enemy.enemy_cursed_raider.ship_hp
    - Data.by_id.balance.compass_ship_damage.value, "following the compass damages the enemy opening state")

equal(State.new("qa_boarding").stage, "boarding", "boarding hero screen has an isolated QA profile")
equal(State.new("qa_route_event").stage, "route_event", "route encounter has an isolated QA profile")
equal(State.new("qa_black_tide").stage, "black_tide", "black tide has an isolated QA profile")
equal(State.new("qa_whisper").stage, "whisper", "whisper has an isolated QA profile")
equal(State.new("qa_curse").stage, "curse_choice", "cursed compass has an isolated QA profile")
equal(State.new("qa_rune").stage, "rune_clue", "rune hero screen has an isolated QA profile")
equal(State.new("qa_settlement").stage, "settlement", "settlement hero screen has an isolated QA profile")
equal(State.new("qa_complete").stage, "complete", "completion screen has an isolated QA profile")
local restoredComplete, completeRecovery = State.normalize(State.new("qa_complete"), "qa_complete")
equal(restoredComplete.stage, "complete", "QA completion profile is structurally restorable")
equal(completeRecovery, nil, "QA completion profile does not trigger recovery")
equal(State.getPresentation(State.new("qa_explore")).hero_group, "map", "exploration maps to the map hero composition")
equal(State.getPresentation(State.new("qa_combat")).hero_group, "combat", "naval maps to the combat hero composition")
equal(State.getPresentation(State.new("qa_boarding")).stage, "boarding", "boarding has distinct deck art")
equal(State.getPresentation(State.new("qa_rune")).hero_group, "rune", "rune clue maps to the rune hero composition")
for _, profile in ipairs({
    "qa_explore",
    "qa_route_event",
    "qa_black_tide",
    "qa_whisper",
    "qa_curse",
    "qa_combat",
    "qa_boarding",
    "qa_rune",
    "qa_settlement",
    "qa_complete",
}) do
    presentationCopyHasNoQAMarker(State.new(profile), profile)
end

print("V2 Phase 3 content OK: 8 events, voyage dialogue, hero art, enemy presentation, audio and animation mappings")
