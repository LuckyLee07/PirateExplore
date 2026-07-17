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

local function contains(value, expected, message)
    if type(value) ~= "string" or not string.find(value, expected, 1, true) then
        error(string.format("%s: %s does not contain %s", message, tostring(value), expected))
    end
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

local naval = State.new("qa_combat")
local forecast = State.getCombatImpact(naval)
equal(forecast.phase, "forecast", "naval combat exposes a boarding forecast")
equal(forecast.opening_hp, 100, "an intact deck forecasts a full enemy boarding force")
equal(forecast.reduction, 0, "an intact deck grants no hidden reduction")
equal(forecast.remaining_deck_damage, 300, "forecast explains the remaining deck threshold")
contains(forecast.text, "甲板完整 → 敌军 100/100", "intact-deck forecast is player-readable")
contains(actionLabel(naval, "board_now"), "敌军 100/100", "boarding action previews the intact enemy force")

apply(naval, "fire_at_deck")
apply(naval, "fire_at_deck")
forecast = State.getCombatImpact(naval)
truthy(forecast.advantageous, "breaking the deck marks the forecast as advantageous")
equal(forecast.opening_hp, 65, "broken deck forecasts the wounded enemy force")
equal(forecast.reduction, 35, "broken deck quantifies its boarding reduction")
equal(forecast.remaining_deck_damage, 0, "broken deck has no remaining threshold")
contains(actionLabel(naval, "board_now"), "甲板优势", "boarding action names the earned advantage")
contains(actionLabel(naval, "board_now"), "65/100", "boarding action previews the weakened enemy force")

apply(naval, "board_now")
local transfer = State.getCombatImpact(naval)
equal(transfer.phase, "transfer", "boarding reports the resolved naval transfer")
equal(transfer.opening_hp, 65, "boarding transfer retains the forecast value")
equal(naval.battle.enemy_boarding_hp, transfer.opening_hp, "forecast and actual boarding state match")
contains(transfer.text, "削弱 35", "boarding transfer quantifies the earned advantage")

local immediate = State.new("qa_combat")
apply(immediate, "board_now")
local noAdvantage = State.getCombatImpact(immediate)
equal(noAdvantage.opening_hp, 100, "immediate boarding keeps the enemy force intact")
equal(immediate.battle.enemy_boarding_hp, noAdvantage.opening_hp, "intact forecast and actual state match")
contains(noAdvantage.text, "未削弱", "immediate boarding explains the missing advantage")

local hullComplete = State.new("qa_complete")
local hullNarrative = State.getNarrative(hullComplete)
contains(hullNarrative, "最大耐久 +20（当前 140）", "hull completion explains the concrete gain")
contains(hullNarrative, hullComplete.next_voyage_objective, "hull completion retains the next objective")
contains(hullNarrative, "暗礁与承受敌炮反击", "hull completion connects growth to the next voyage")

local gunsComplete = State.new("qa_fresh")
apply(gunsComplete, "accept_call")
apply(gunsComplete, "select_heavy_guns")
apply(gunsComplete, "start_voyage")
apply(gunsComplete, "choose_risky_route")
apply(gunsComplete, "salvage_wreck")
apply(gunsComplete, "ride_black_tide")
apply(gunsComplete, "listen_whisper")
apply(gunsComplete, "follow_cursed_compass")
apply(gunsComplete, "fire_at_deck")
apply(gunsComplete, "fire_at_deck")
apply(gunsComplete, "board_now")
apply(gunsComplete, "boarding_rush")
apply(gunsComplete, "boarding_rush")
apply(gunsComplete, "take_rune_clue")
apply(gunsComplete, "return_to_port")
apply(gunsComplete, "upgrade_guns")
local gunsNarrative = State.getNarrative(gunsComplete)
contains(gunsNarrative, "单次齐射伤害 +25（火炮等级 1）", "gun completion explains the concrete gain")
contains(gunsNarrative, "更快击毁敌舰甲板", "gun completion connects growth to the combat loop")

print("V2 internal sample polish round 3 OK: combat forecast, resolved transfer, and upgrade payoff")
