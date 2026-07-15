package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local State = require "LuaClass/V2ChapterState"

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function truthy(value, message)
    if not value then error(message) end
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then
        error(string.format("action %s failed: %s", action, tostring(message)))
    end
end

local safe = State.new("qa_fresh")
equal(safe.stage, "opening", "fresh profile starts at opening")
apply(safe, "accept_call")
apply(safe, "start_voyage")
apply(safe, "choose_safe_route")
apply(safe, "rest_at_cove")
apply(safe, "lash_cargo")
apply(safe, "resist_whisper")
apply(safe, "break_cursed_compass")
apply(safe, "fire_at_deck")
apply(safe, "fire_at_deck")
truthy(safe.battle.deck_broken, "two volleys must break the enemy deck")
apply(safe, "board_now")
equal(safe.battle.enemy_boarding_hp, 65, "deck damage transfers into boarding")
apply(safe, "boarding_attack")
apply(safe, "boarding_attack")
apply(safe, "boarding_attack")
equal(safe.stage, "rune_clue", "boarding win reaches rune clue")
apply(safe, "take_rune_clue")
apply(safe, "return_to_port")
apply(safe, "upgrade_hull")
equal(safe.stage, "complete", "safe route completes chapter")
truthy(safe.chapter_complete, "chapter completion flag is retained")
truthy(safe.upgrades.hull, "hull upgrade is recorded")
equal(safe.next_voyage_objective, "前往潮汐墓场寻找符文守卫", "next voyage has a clear objective")

local risky = State.new("qa_fresh")
apply(risky, "accept_call")
apply(risky, "select_heavy_guns")
apply(risky, "start_voyage")
apply(risky, "choose_risky_route")
apply(risky, "salvage_wreck")
truthy(risky.claimed_rewards.reward_salvage, "risky route grants salvage")
apply(risky, "ride_black_tide")
apply(risky, "listen_whisper")
apply(risky, "follow_cursed_compass")
apply(risky, "fire_at_deck")
truthy(risky.battle.deck_damage >= 270, "heavy guns and curse affect first volley")
apply(risky, "fire_at_deck")
apply(risky, "board_now")
apply(risky, "boarding_rush")
apply(risky, "boarding_rush")
equal(risky.stage, "rune_clue", "risky route reaches rune clue")
apply(risky, "take_rune_clue")
apply(risky, "return_to_port")
apply(risky, "upgrade_guns")
equal(risky.stage, "complete", "risky route completes chapter")
truthy(risky.upgrades.guns, "gun upgrade is recorded")

local failure = State.new("qa_combat")
apply(failure, "board_now")
failure.battle.crew_hp = 20
apply(failure, "boarding_rush")
equal(failure.stage, "failed", "boarding defeat reaches recoverable failure")
apply(failure, "retry_battle")
equal(failure.stage, "naval", "failed battle can retry")
apply(failure, "retreat")
equal(failure.stage, "failed", "retreat uses the explained failure state")
apply(failure, "recover_at_port")
equal(failure.stage, "harbor", "failure can recover at port")

local invalid = State.new("qa_fresh")
local ok = State.apply(invalid, "upgrade_hull")
equal(ok, false, "invalid stage action is rejected")
equal(invalid.stage, "opening", "invalid action does not advance state")

local normalized = State.normalize({ schema_version = 999, stage = "complete" }, "qa_explore")
equal(normalized.stage, "route_choice", "invalid save falls back to requested QA profile")

print("V2 Chapter 1 state machine OK: safe, risky, transfer, failure, recovery, upgrade")
