-- Structured, local-only Chapter 1 test records.
--
-- Phase 4 deliberately keeps this independent from a network SDK. Records are
-- persisted inside the scoped V2 save and can be inspected in QA sessions
-- without sending player data anywhere.

local ChapterData = require "LuaClass/V2ChapterData"

local V2Telemetry = {}

V2Telemetry.SCHEMA_VERSION = 1
V2Telemetry.MAX_EVENTS = 240

local function now()
    if os ~= nil and os.time ~= nil then
        return os.time()
    end
    return 0
end

local function clockMilliseconds()
    if os ~= nil and os.clock ~= nil then
        return math.floor(os.clock() * 1000)
    end
    return 0
end

local function copyResources(resources)
    local result = {}
    for _, id in ipairs({ "gold", "timber", "iron", "provisions", "rune_dust" }) do
        result[id] = resources and resources[id] or 0
    end
    return result
end

local function battleSnapshot(battle)
    battle = battle or {}
    return {
        player_hull = battle.player_hull,
        enemy_ship_hp = battle.enemy_ship_hp,
        deck_damage = battle.deck_damage,
        gun_damage = battle.gun_damage,
        crew_hp = battle.crew_hp,
        enemy_boarding_hp = battle.enemy_boarding_hp,
    }
end

function V2Telemetry.ensureSession(state)
    if type(state.telemetry) == "table"
        and state.telemetry.schema_version == V2Telemetry.SCHEMA_VERSION
        and type(state.telemetry.events) == "table" then
        return state.telemetry
    end

    local timestamp = now()
    state.telemetry = {
        schema_version = V2Telemetry.SCHEMA_VERSION,
        session_id = string.format(
            "%s-%d-%d",
            tostring(state.profile or "player"),
            timestamp,
            clockMilliseconds()
        ),
        profile = state.profile or "player",
        started_at = timestamp,
        events = {},
    }
    table.insert(state.telemetry.events, {
        sequence = 1,
        timestamp = timestamp,
        event_id = "session_started",
        session_id = state.telemetry.session_id,
        profile = state.telemetry.profile,
        success = true,
        stage_after = state.stage,
        route = state.route,
        resources = copyResources(state.resources),
        provisions = state.resources and state.resources.provisions or 0,
        rune_dust = state.resources and state.resources.rune_dust or 0,
        route_intel = state.flags and state.flags.route_intel == true,
        module_preference = state.selected_module,
    })
    return state.telemetry
end

function V2Telemetry.snapshot(state)
    return {
        stage = state.stage,
        route = state.route,
        resources = copyResources(state.resources),
        battle = battleSnapshot(state.battle),
        turn = state.turn,
    }
end

local moduleActions = {
    select_reinforced_hull = true,
    select_heavy_guns = true,
}

local routeActions = {
    choose_safe_route = true,
    choose_risky_route = true,
}

local voyageEventActions = {
    rest_at_cove = true,
    press_through_cove = true,
    rescue_survivors = true,
    salvage_wreck = true,
    lash_cargo = true,
    ride_black_tide = true,
}

local curseActions = {
    resist_whisper = true,
    listen_whisper = true,
    follow_cursed_compass = true,
    break_cursed_compass = true,
}

local navalActions = {
    gunner_mark_deck = true,
    fire_at_deck = true,
    fire_at_guns = true,
    board_now = true,
}

local boardingActions = {
    boarding_attack = true,
    boarding_rush = true,
    sailor_guard = true,
    medic_heal = true,
}

local function classify(action, before, state, success)
    if not success then return "invalid_action" end
    if (before.stage == "naval" or before.stage == "boarding")
        and (state.stage == "failed" or state.stage == "rune_clue") then
        return "battle_result"
    end
    if action == "accept_call" then return "opening_accepted" end
    if moduleActions[action] then return "module_selected" end
    if action == "start_voyage" then return "voyage_started" end
    if action == "reveal_route_intel" then return "route_intel_revealed" end
    if routeActions[action] then return "route_selected" end
    if voyageEventActions[action] then return "voyage_event_choice" end
    if curseActions[action] then return "curse_decision" end
    if navalActions[action] then return "naval_action" end
    if boardingActions[action] then return "boarding_action" end
    if action == "retreat" then return "battle_result" end
    if action == "retry_battle" or action == "recover_at_port" then return "recovery_choice" end
    if action == "take_rune_clue" then return "rune_claimed" end
    if action == "return_to_port" then return "return_completed" end
    if action == "upgrade_hull" or action == "upgrade_guns" then return "upgrade_completed" end
    if action == "restart_chapter" then return "chapter_restarted" end
    return "invalid_action"
end

function V2Telemetry.record(state, action, before, success, message)
    local telemetry = V2Telemetry.ensureSession(state)
    before = before or V2Telemetry.snapshot(state)
    local eventId = classify(action, before, state, success)
    assert(ChapterData.by_id.telemetry_event[eventId], "Unknown telemetry event: " .. tostring(eventId))

    local battle = battleSnapshot(state.battle)
    local event = {
        sequence = #telemetry.events + 1,
        timestamp = now(),
        event_id = eventId,
        session_id = telemetry.session_id,
        profile = telemetry.profile,
        action = action,
        success = success == true,
        stage_before = before.stage,
        stage_after = state.stage,
        route = state.route,
        result = message or state.last_result,
        turn = state.turn,
        resources = copyResources(state.resources),
        provisions = state.resources and state.resources.provisions or 0,
        rune_dust = state.resources and state.resources.rune_dust or 0,
        route_intel = state.flags and state.flags.route_intel == true,
        module_preference = state.selected_module,
        player_hull = battle.player_hull,
        enemy_ship_hp = battle.enemy_ship_hp,
        deck_damage = battle.deck_damage,
        gun_damage = battle.gun_damage,
        crew_hp = battle.crew_hp,
        enemy_boarding_hp = battle.enemy_boarding_hp,
    }
    table.insert(telemetry.events, event)
    while #telemetry.events > V2Telemetry.MAX_EVENTS do
        table.remove(telemetry.events, 1)
    end
    return event
end

function V2Telemetry.getSummary(state)
    local telemetry = V2Telemetry.ensureSession(state)
    local summary = {
        session_id = telemetry.session_id,
        profile = telemetry.profile,
        total_events = #telemetry.events,
        decisions = 0,
        naval_actions = 0,
        boarding_actions = 0,
        invalid_actions = 0,
        battle_results = 0,
        completed = state.stage == "complete",
        chapter_complete = state.chapter_complete == true,
        route = state.route,
    }
    for _, event in ipairs(telemetry.events) do
        if event.event_id == "naval_action" then summary.naval_actions = summary.naval_actions + 1 end
        if event.event_id == "boarding_action" then summary.boarding_actions = summary.boarding_actions + 1 end
        if event.event_id == "invalid_action" then summary.invalid_actions = summary.invalid_actions + 1 end
        if event.event_id == "battle_result" then summary.battle_results = summary.battle_results + 1 end
        if event.event_id == "route_selected" or event.event_id == "voyage_event_choice"
            or event.event_id == "curse_decision" then
            summary.decisions = summary.decisions + 1
        end
    end
    return summary
end

return V2Telemetry
