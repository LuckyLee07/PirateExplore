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

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then error(string.format("%s failed: %s", action, tostring(message))) end
end

local explore = State.new("qa_explore")
local beforeIntel = explore.resources.provisions
local actions = State.getActions(explore)
equal(actions[1].id, "reveal_route_intel", "navigator intel is offered before route choice")
apply(explore, "reveal_route_intel")
equal(explore.resources.provisions, beforeIntel - Data.by_id.balance.navigator_intel_cost.value, "intel has source-driven supply cost")
truthy(explore.flags.route_intel, "navigator intel flag is stored")
actions = State.getActions(explore)
truthy(string.find(actions[1].label, "风险 1", 1, true), "safe route exact risk is revealed")
truthy(string.find(actions[2].label, "风险 3", 1, true), "risky route exact risk is revealed")

local heavy = State.new("qa_fresh")
apply(heavy, "accept_call")
apply(heavy, "select_heavy_guns")
apply(heavy, "start_voyage")
equal(heavy.resources.provisions, 6, "heavy guns enforce lower supply capacity before departure")

local suppress = State.new("qa_combat")
local startingHull = suppress.battle.player_hull
apply(suppress, "fire_at_guns")
equal(suppress.battle.guns_suppressed, false, "one gun attack does not suppress enemy guns")
apply(suppress, "fire_at_guns")
truthy(suppress.battle.guns_suppressed, "second gun attack suppresses enemy guns")
local normalRetaliation = Data.by_id.battle_action.fire_at_guns.retaliation
local reduced = Data.by_id.balance.suppressed_retaliation_reduction.value
equal(suppress.battle.player_hull, startingHull - normalRetaliation - (normalRetaliation - reduced), "gun suppression reduces retaliation immediately and visibly")

local transfer = State.new("qa_combat")
apply(transfer, "gunner_mark_deck")
apply(transfer, "fire_at_deck")
local expectedMarkedDamage = Data.by_id.battle_action.fire_at_deck.damage
    + Data.by_id.balance.gunner_mark_bonus.value
equal(transfer.battle.deck_damage, expectedMarkedDamage, "gunner mark modifies the next deck volley")
apply(transfer, "fire_at_deck")
truthy(transfer.battle.deck_broken, "source threshold controls deck break")
apply(transfer, "board_now")
equal(transfer.battle.enemy_boarding_hp, Data.by_id.balance.boarding_wounded_hp.value, "deck break transfers into boarding")
local guardedCrew = transfer.battle.crew_hp
apply(transfer, "sailor_guard")
apply(transfer, "boarding_rush")
equal(transfer.battle.crew_hp, guardedCrew, "sailor guard cancels one retaliation")
apply(transfer, "boarding_rush")
equal(transfer.stage, "rune_clue", "boarding completes after transferred advantage")
truthy(string.find(transfer.battle_report, "胜因", 1, true), "victory generates a causal battle report")
truthy(string.find(transfer.battle_report, "舰炮优势成功传递", 1, true), "report names the winning transfer mechanism")

local recovery = State.new("qa_combat")
apply(recovery, "board_now")
recovery.battle.crew_hp = 1
apply(recovery, "boarding_attack")
equal(recovery.stage, "failed", "defeat reaches failure state")
truthy(string.find(recovery.recovery_summary, "金币", 1, true), "failure explains port recovery cost")
local goldBeforeRecovery = recovery.resources.gold
apply(recovery, "recover_at_port")
equal(recovery.resources.gold, goldBeforeRecovery - Data.by_id.balance.port_recovery_gold_cost.value, "port recovery charges source-driven cost")
equal(recovery.stage, "harbor", "paid recovery returns to harbor")
equal(recovery.route, nil, "recovery clears previous route damage context")

local retry = State.new("qa_combat")
apply(retry, "retreat")
local provisionsBeforeRetry = retry.resources.provisions
apply(retry, "retry_battle")
equal(retry.resources.provisions, provisionsBeforeRetry - Data.by_id.balance.retry_supply_cost.value, "battle retry has an explicit supply cost")
equal(retry.stage, "naval", "paid retry returns to naval battle")

print("V2 Phase 2 decisions OK: intel, route tradeoff, target choice, crew skills, report, recovery")
