-- Pure, non-Cocos prototype for the Frostbound third-voyage hazard.
--
-- The formal state machine references this pure model for hidden QA profiles.
-- Player entry remains closed until the dedicated art and forecast UI pass.

local V2FrostVoyageModel = {}

V2FrostVoyageModel.MODEL_STATUS = "runtime_integrated_unexposed"

V2FrostVoyageModel.RULES = {
    passage_target = 5,
    max_rounds = 3,
    pack_route_supply_cost = 0,
    flare_route_supply_cost = 1,
    correct_turn_progress = 2,
    wrong_action_progress = 1,
    cannon_progress = 2,
    gun_level_progress_bonus = 1,
    gunner_first_cannon_bonus = 1,
    cannon_supply_cost = 1,
    collision_damage = 24,
    hull_level_collision_reduction = 10,
    sailor_first_collision_reduction = 8,
    off_window_cannon_damage = 10,
    medic_recovery_amount = 18,
    retry_supply_cost = 1,
}

local PATTERNS = {
    frost_pack_channel = {
        { "port", "starboard", "port" },
        { "starboard", "port", "starboard" },
    },
    frost_flare_pass = {
        { "center", "port", "center" },
        { "center", "starboard", "center" },
    },
}

local CORRECT_ACTION = {
    port = "frost_turn_port",
    starboard = "frost_turn_starboard",
    center = "frost_break_ice",
}

local ACTION_LABEL = {
    frost_turn_port = "切入左舷裂口",
    frost_turn_starboard = "切入右舷裂口",
    frost_break_ice = "炮击中央冰脊",
}

local function copy(source)
    local result = {}
    for key, value in pairs(source or {}) do
        if type(value) == "table" then
            result[key] = copy(value)
        else
            result[key] = value
        end
    end
    return result
end

local function clampMinimum(value, minimum)
    return math.max(minimum, value)
end

local function selectedPattern(state)
    local patterns = PATTERNS[state.route]
    if patterns == nil then
        return nil
    end
    return patterns[state.pattern_index]
end

local function routeCost(route, rules)
    if route == "frost_pack_channel" then
        return rules.pack_route_supply_cost
    end
    return rules.flare_route_supply_cost
end

local function turnDirection(action)
    if action == "frost_turn_port" then
        return "port"
    elseif action == "frost_turn_starboard" then
        return "starboard"
    end
    return nil
end

local function actionOutcome(state, action)
    local rules = state.rules
    local pattern = selectedPattern(state)
    local window = pattern and pattern[state.round]
    if window == nil or CORRECT_ACTION[window] == nil then
        return nil, "当前没有可执行的冰潮预告"
    end
    if ACTION_LABEL[action] == nil then
        return nil, "未知冰潮操作：" .. tostring(action)
    end

    local correct = action == CORRECT_ACTION[window]
    local hullDamage = 0
    local supplyCost = 0
    local progress = rules.wrong_action_progress
    local usedSailor = false
    local usedGunner = false

    if action == "frost_break_ice" then
        supplyCost = rules.cannon_supply_cost
        if correct then
            progress = rules.cannon_progress
                + state.gun_level * rules.gun_level_progress_bonus
            if state.chief == "crew_upgrade_gunner" and not state.gunner_bonus_used then
                progress = progress + rules.gunner_first_cannon_bonus
                usedGunner = true
            end
        else
            hullDamage = rules.off_window_cannon_damage
            if state.chief == "crew_upgrade_gunner" and not state.gunner_bonus_used then
                hullDamage = 0
                usedGunner = true
            end
        end
    else
        if correct then
            progress = rules.correct_turn_progress
        else
            hullDamage = clampMinimum(
                rules.collision_damage
                    - state.hull_level * rules.hull_level_collision_reduction,
                0
            )
            if state.chief == "crew_upgrade_sailor" and not state.sailor_bonus_used then
                hullDamage = clampMinimum(
                    hullDamage - rules.sailor_first_collision_reduction,
                    0
                )
                usedSailor = true
            end
        end
    end

    local medicRecovery = 0
    if hullDamage > 0 and state.beacon_choice == "warm_rescue_team"
        and state.medic_recovery_available then
        medicRecovery = math.min(hullDamage, rules.medic_recovery_amount)
    end

    return {
        action = action,
        label = ACTION_LABEL[action],
        window = window,
        correct = correct,
        progress = progress,
        hull_damage = hullDamage,
        supply_cost = supplyCost,
        medic_recovery = medicRecovery,
        net_hull_damage = hullDamage - medicRecovery,
        used_sailor_bonus = usedSailor,
        used_gunner_bonus = usedGunner,
    }
end

function V2FrostVoyageModel.new(options)
    options = options or {}
    local rules = copy(V2FrostVoyageModel.RULES)
    for key, value in pairs(options.rules or {}) do
        rules[key] = value
    end
    return {
        phase = "route_choice",
        route = nil,
        beacon_choice = nil,
        pattern_index = options.pattern_index == 2 and 2 or 1,
        hull_level = options.hull_level or 0,
        gun_level = options.gun_level or 0,
        chief = options.chief,
        hull = options.hull or 120,
        hull_max = options.hull_max or options.hull or 120,
        provisions = options.provisions or 8,
        round = 1,
        progress = 0,
        navigator_exact_forecast = false,
        medic_recovery_available = false,
        sailor_bonus_used = false,
        gunner_bonus_used = false,
        failed_reason = nil,
        action_log = {},
        rules = rules,
    }
end

function V2FrostVoyageModel.chooseRoute(state, route)
    if state.phase ~= "route_choice" then
        return false, "当前不能重新选择极地航道"
    end
    if PATTERNS[route] == nil then
        return false, "未知极地航道：" .. tostring(route)
    end
    local cost = routeCost(route, state.rules)
    if state.provisions < cost then
        return false, "补给不足，无法进入该航道"
    end
    state.route = route
    state.provisions = state.provisions - cost
    state.passage_start_hull = state.hull
    state.passage_start_provisions = state.provisions
    state.phase = "beacon"
    return true, "极地航道已锁定"
end

function V2FrostVoyageModel.chooseBeacon(state, choice)
    if state.phase ~= "beacon" then
        return false, "当前没有极地信标决策"
    end
    if choice ~= "read_ice_chart" and choice ~= "warm_rescue_team" then
        return false, "未知信标方案：" .. tostring(choice)
    end
    state.beacon_choice = choice
    state.navigator_exact_forecast = choice == "read_ice_chart"
    state.medic_recovery_available = choice == "warm_rescue_team"
    state.phase = "hazard"
    return true, "极地信标方案已进入冰潮航线"
end

function V2FrostVoyageModel.currentForecast(state)
    if state.phase ~= "hazard" then
        return nil
    end
    local pattern = selectedPattern(state)
    local window = pattern and pattern[state.round]
    if window == nil then
        return nil
    end
    return {
        round = state.round,
        max_rounds = state.rules.max_rounds,
        window = window,
        correct_action = CORRECT_ACTION[window],
        exact = state.navigator_exact_forecast,
        progress = state.progress,
        target = state.rules.passage_target,
    }
end

function V2FrostVoyageModel.getActionPreviews(state)
    local forecast = V2FrostVoyageModel.currentForecast(state)
    if forecast == nil then
        return {}
    end
    local result = {}
    for _, action in ipairs({ "frost_turn_port", "frost_turn_starboard", "frost_break_ice" }) do
        local outcome = actionOutcome(state, action)
        local preview = {
            id = action,
            label = ACTION_LABEL[action],
            recommended = action == forecast.correct_action,
            exact = forecast.exact,
        }
        if forecast.exact then
            preview.progress = outcome.progress
            preview.hull_damage = outcome.net_hull_damage
            preview.supply_cost = outcome.supply_cost
        else
            preview.progress_text = action == "frost_break_ice" and "推进 1～4" or "推进 1～2"
            preview.hull_text = action == "frost_break_ice" and "船体 0～-10" or "船体 0～-24"
            preview.supply_text = action == "frost_break_ice" and "补给 -1" or "补给 0"
        end
        table.insert(result, preview)
    end
    return result
end

function V2FrostVoyageModel.applyHazardAction(state, action)
    if state.phase ~= "hazard" then
        return false, "当前不在移动冰潮中"
    end
    local outcome, errorMessage = actionOutcome(state, action)
    if outcome == nil then
        return false, errorMessage
    end
    if state.provisions < outcome.supply_cost then
        return false, "补给不足，无法炮击中央冰脊"
    end

    state.provisions = state.provisions - outcome.supply_cost
    state.hull = state.hull - outcome.net_hull_damage
    state.progress = math.min(
        state.rules.passage_target,
        state.progress + outcome.progress
    )
    if outcome.medic_recovery > 0 then
        state.medic_recovery_available = false
    end
    if outcome.used_sailor_bonus then
        state.sailor_bonus_used = true
    end
    if outcome.used_gunner_bonus then
        state.gunner_bonus_used = true
    end
    table.insert(state.action_log, copy(outcome))

    if state.hull <= 0 then
        state.hull = 0
        state.phase = "failed"
        state.failed_reason = "船体在移动冰潮中失去航行能力"
        return true, state.failed_reason, outcome
    end
    if state.progress >= state.rules.passage_target then
        state.phase = "complete"
        return true, "已穿过移动冰潮", outcome
    end

    state.round = state.round + 1
    if state.round > state.rules.max_rounds then
        state.phase = "failed"
        state.failed_reason = "三轮冰潮结束时仍未驶出封锁"
        return true, state.failed_reason, outcome
    end
    return true, "冰潮位置已经更新", outcome
end

function V2FrostVoyageModel.retry(state)
    if state.phase ~= "failed" then
        return false, "当前不需要重试冰潮"
    end
    if (state.passage_start_provisions or 0) < state.rules.retry_supply_cost then
        return false, "补给不足，无法原地重试"
    end
    state.hull = state.passage_start_hull
    state.provisions = state.passage_start_provisions - state.rules.retry_supply_cost
    state.passage_start_provisions = state.provisions
    state.round = 1
    state.progress = 0
    state.navigator_exact_forecast = state.beacon_choice == "read_ice_chart"
    state.medic_recovery_available = state.beacon_choice == "warm_rescue_team"
    state.sailor_bonus_used = false
    state.gunner_bonus_used = false
    state.failed_reason = nil
    state.action_log = {}
    state.phase = "hazard"
    return true, "消耗一份补给，从第一轮冰潮重新开始"
end

function V2FrostVoyageModel.returnToPort(state)
    if state.phase ~= "failed" then
        return false, "当前不能从冰潮返港"
    end
    state.phase = "port"
    state.route = nil
    state.beacon_choice = nil
    state.round = 1
    state.progress = 0
    state.navigator_exact_forecast = false
    state.medic_recovery_available = false
    state.sailor_bonus_used = false
    state.gunner_bonus_used = false
    state.failed_reason = nil
    state.action_log = {}
    return true, "已返港，可重新选择极地航道与信标方案"
end

return V2FrostVoyageModel
