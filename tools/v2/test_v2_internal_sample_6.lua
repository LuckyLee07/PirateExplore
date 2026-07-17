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

local failed = State.new("qa_failed")
equal(failed.stage, "failed", "failed QA profile opens the recovery decision")
equal(failed.route, "risky_shortcut", "failed QA profile retains the current route")
truthy(failed.claimed_rewards.reward_salvage, "failed QA profile has confirmed salvage")
contains(failed.objective, "已确认收获", "failure objective reassures the player about confirmed loot")
local narrative = State.getNarrative(failed)
contains(narrative, "补给 -1；保留当前航线与已确认战利品", "retry consequence is explicit")
contains(narrative, "金币 -5；保留已确认战利品，清除航线损伤", "port recovery consequence is explicit")
contains(actionLabel(failed, "retry_battle"), "原地重试\n补给-1｜保留航线", "retry button previews cost and retention")
contains(actionLabel(failed, "recover_at_port"), "返港恢复\n金币-5｜重新整备", "port button previews cost and destination")

local retry = State.new("qa_failed")
local retryGold = retry.resources.gold
local retryTimber = retry.resources.timber
local retryIron = retry.resources.iron
local retryProvisions = retry.resources.provisions
local retryRuneDust = retry.resources.rune_dust
apply(retry, "retry_battle")
equal(retry.stage, "naval", "retry returns to naval combat")
equal(retry.resources.provisions, retryProvisions - 1, "retry spends the previewed supply")
equal(retry.resources.gold, retryGold, "retry does not spend gold")
equal(retry.resources.timber, retryTimber, "retry preserves confirmed timber")
equal(retry.resources.iron, retryIron, "retry preserves confirmed iron")
equal(retry.resources.rune_dust, retryRuneDust, "retry preserves confirmed rune dust")
equal(retry.route, "risky_shortcut", "retry preserves the route")
equal(retry.voyage_hull_damage, 10, "retry preserves route damage context")
truthy(retry.claimed_rewards.reward_salvage, "retry preserves the confirmed reward claim")

local port = State.new("qa_failed")
local portGold = port.resources.gold
local portTimber = port.resources.timber
local portIron = port.resources.iron
local portProvisions = port.resources.provisions
local portRuneDust = port.resources.rune_dust
apply(port, "recover_at_port")
equal(port.stage, "harbor", "port recovery returns to preparation")
equal(port.resources.gold, portGold - 5, "port recovery spends the previewed gold")
equal(port.resources.timber, portTimber, "port recovery preserves confirmed timber")
equal(port.resources.iron, portIron, "port recovery preserves confirmed iron")
equal(port.resources.provisions, portProvisions, "port recovery preserves remaining supply")
equal(port.resources.rune_dust, portRuneDust, "port recovery preserves confirmed rune dust")
equal(port.route, nil, "port recovery clears the old route")
equal(port.voyage_hull_damage, 0, "port recovery clears route damage")
truthy(port.claimed_rewards.reward_salvage, "port recovery preserves the confirmed reward claim")

local insufficient = State.new("qa_failed")
insufficient.resources.provisions = 0
local ok, message = State.apply(insufficient, "retry_battle")
equal(ok, false, "retry remains unavailable without supply")
contains(message, "必须返回皇家港恢复", "insufficient retry directs the player to the valid recovery")
equal(insufficient.stage, "failed", "failed retry does not mutate the recovery state")

print("V2 internal sample polish round 6 OK: retry and port recovery costs, retention, and reset boundaries")
