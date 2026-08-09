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

local function contains(text, expected, message)
    truthy(string.find(text or "", expected, 1, true), message)
end

local function apply(state, action)
    local ok, message = State.apply(state, action)
    if not ok then error(string.format("%s failed: %s", action, tostring(message))) end
end

local function advanceToNaval(state)
    apply(state, "start_voyage")
    apply(state, "choose_safe_route")
    apply(state, "rest_at_cove")
    apply(state, "lash_cargo")
    apply(state, "resist_whisper")
    apply(state, "break_cursed_compass")
    equal(state.stage, "naval", "repeat route reaches the real naval stage")
end

local hull = State.new("qa_complete")
hull.profile = "player"
local resourcesBefore = {}
for id, value in pairs(hull.resources) do resourcesBefore[id] = value end
local historyBefore = #hull.history

local completionActions = State.getActions(hull)
equal(completionActions[1].id, "prepare_next_voyage", "player completion prepares a retained-growth voyage")
apply(hull, "prepare_next_voyage")

equal(hull.stage, "harbor", "next voyage preparation returns to the harbor")
equal(hull.voyage_count, 1, "preparation does not count a voyage before departure")
equal(hull.ship.hull_level, 1, "hull growth survives the completion transition")
equal(hull.ship.hull_max, 140, "retained hull growth is recalculated into preparation")
equal(hull.selected_module, "module_reinforced_hull", "equipped module survives preparation")
equal(#hull.crew, 4, "crew roster survives preparation")
equal(#hull.history, historyBefore + 1, "voyage history remains continuous")
equal(hull.route, nil, "temporary route is cleared")
equal(hull.voyage_hull_damage, 0, "voyage damage is cleared at the port")
equal(hull.flags.curse_marked, nil, "temporary curse choices are cleared")
truthy(hull.flags.chapter_01_complete, "unique chapter completion remains recorded")
truthy(hull.claimed_rewards.reward_rune_clue, "unique rune reward remains claimed")
equal(hull.claimed_rewards.reward_battle, nil, "repeatable battle loot becomes eligible again")
for id, value in pairs(resourcesBefore) do
    equal(hull.resources[id], value, "preparation preserves resource " .. id)
end
contains(State.getStageTitle(hull), "第 2 次", "harbor title identifies the next voyage")
contains(State.getNarrative(hull), "成长与库存已经保留", "harbor narrative confirms persistence")

advanceToNaval(hull)
equal(hull.voyage_count, 2, "the next departure advances the voyage count")
equal(hull.battle.player_hull_max, 140, "retained hull growth changes the next battle")

local guns = State.new("qa_upgrade")
apply(guns, "upgrade_guns")
equal(guns.ship.gun_level, 1, "gun upgrade reaches completion")
apply(guns, "prepare_next_voyage")
advanceToNaval(guns)
apply(guns, "fire_at_deck")
equal(guns.battle.deck_damage, 200, "retained gun growth increases the next voyage volley")
equal(guns.battle.enemy_ship_hp, 300, "next voyage enemy health reflects upgraded damage")

print("V2 repeat voyage OK: growth, inventory, history and second-departure combat effects persist")
