-- Pure Lua state machine for the V2 Chapter 1 vertical slice.
-- This module intentionally has no Cocos dependencies so the complete chapter
-- and every recovery path can be tested from the command line.

local ChapterData = require "LuaClass/V2ChapterData"

local V2ChapterState = {}

local function balanceValue(id)
    local row = ChapterData.by_id.balance[id]
    assert(row, "Unknown V2 balance value: " .. tostring(id))
    return row.value
end

local function moduleData(state)
    return ChapterData.by_id.ship_module[state.selected_module]
end

local function routeData(routeId)
    local row = ChapterData.by_id.route[routeId]
    assert(row, "Unknown V2 route: " .. tostring(routeId))
    return row
end

local function edgeData(edgeId)
    local row = ChapterData.by_id.map_edge[edgeId]
    assert(row, "Unknown V2 map edge: " .. tostring(edgeId))
    return row
end

local function battleAction(actionId)
    local row = ChapterData.by_id.battle_action[actionId]
    assert(row, "Unknown V2 battle action: " .. tostring(actionId))
    return row
end

local function eventChoice(actionId)
    for _, row in ipairs(ChapterData.event_choice) do
        if row.action_id == actionId then
            return row
        end
    end
    error("Unknown V2 event choice action: " .. tostring(actionId))
end

local function choiceLabel(actionId)
    return eventChoice(actionId).label
end

local function dialogueBlock(nodeId, triggers)
    local accepted = {}
    for _, trigger in ipairs(triggers or {}) do
        accepted[trigger] = true
    end
    local lines = {}
    for _, row in ipairs(ChapterData.dialogue) do
        if row.node_id == nodeId and accepted[row.trigger] then
            table.insert(lines, row.speaker .. "：" .. row.text)
        end
    end
    return table.concat(lines, "\n")
end

V2ChapterState.SCHEMA_VERSION = 4
V2ChapterState.STAGES = {
    opening = true,
    harbor = true,
    route_choice = true,
    route_event = true,
    black_tide = true,
    whisper = true,
    curse_choice = true,
    naval = true,
    boarding = true,
    rune_clue = true,
    settlement = true,
    upgrade = true,
    complete = true,
    failed = true,
}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

local function overwrite(target, source)
    for key, value in pairs(source or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            overwrite(target[key], value)
        else
            target[key] = copy(value)
        end
    end
end

local function addHistory(state, action, text)
    state.turn = state.turn + 1
    table.insert(state.history, {
        turn = state.turn,
        action = action,
        text = text,
    })
    state.last_result = text
end

local function grantFlag(state, flag)
    if flag then
        state.flags[flag] = true
    end
end

local function applyReward(state, rewardId)
    if state.claimed_rewards[rewardId] then
        return
    end
    local reward = ChapterData.by_id.reward[rewardId]
    assert(reward, "Unknown V2 reward: " .. tostring(rewardId))
    for _, resourceId in ipairs({ "gold", "timber", "iron", "provisions", "rune_dust" }) do
        state.resources[resourceId] = state.resources[resourceId] + (reward[resourceId] or 0)
    end
    state.claimed_rewards[rewardId] = true
end

local function applyChoiceOutcome(state, action)
    local choice = eventChoice(action)
    if choice.reward_id then
        applyReward(state, choice.reward_id)
    end
    grantFlag(state, choice.grants_flag)
    return choice.result_text
end

local function calculateHullMax(state)
    return balanceValue("base_hull")
        + (moduleData(state).hull_bonus or 0)
        + state.ship.hull_level * balanceValue("hull_level_bonus")
end

local function resetBattle(state)
    local enemy = ChapterData.by_id.enemy.enemy_cursed_raider
    local crewBonus = state.route and routeData(state.route).crew_max_bonus or 0
    if state.flags.compass_broken then
        crewBonus = crewBonus + balanceValue("compass_crew_bonus")
    end
    local crewMax = enemy.boarding_power + crewBonus
    local enemyShipHp = enemy.ship_hp
    if state.flags.compass_followed then
        enemyShipHp = enemyShipHp - balanceValue("compass_ship_damage")
    end
    state.ship.hull_max = calculateHullMax(state)
    state.battle = {
        enemy_ship_hp = enemyShipHp,
        enemy_ship_hp_max = enemy.ship_hp,
        deck_damage = 0,
        deck_threshold = balanceValue("deck_break_threshold"),
        deck_broken = false,
        gun_damage = 0,
        gun_threshold = balanceValue("gun_suppression_threshold"),
        guns_suppressed = false,
        player_hull = math.max(1, state.ship.hull_max - (state.voyage_hull_damage or 0)),
        player_hull_max = state.ship.hull_max,
        enemy_boarding_hp = enemy.boarding_power,
        enemy_boarding_hp_max = enemy.boarding_power,
        crew_hp = crewMax,
        crew_hp_max = crewMax,
        medic_used = false,
        sailor_guard_used = false,
        sailor_guarded = false,
        gunner_mark_used = false,
        gunner_marked = false,
        volley_count = 0,
        total_hull_damage = state.voyage_hull_damage or 0,
        naval_action_count = 0,
        boarding_action_count = 0,
        actions_log = {},
        transfer_summary = "尚未进入接舷阶段",
    }
end

local function baseState(profile)
    local state = {
        schema_version = V2ChapterState.SCHEMA_VERSION,
        chapter_id = "chapter_01",
        profile = profile or "player",
        stage = "opening",
        current_node = "node_port",
        objective = "回应瓶中低语，确认自己为何必须出海",
        last_result = "水晶瓶将你拖入一片被诅咒的海域。",
        route = nil,
        selected_module = "module_reinforced_hull",
        crew = {
            "crew_gunner",
            "crew_sailor",
            "crew_navigator",
            "crew_medic",
        },
        resources = {
            gold = balanceValue("initial_gold"),
            timber = 0,
            iron = 0,
            provisions = balanceValue("initial_provisions"),
            rune_dust = 0,
        },
        ship = {
            hull_level = 0,
            gun_level = 0,
            hull_max = balanceValue("base_hull")
                + ChapterData.by_id.ship_module.module_reinforced_hull.hull_bonus,
        },
        flags = {},
        claimed_rewards = {},
        upgrades = {},
        battle = {},
        history = {},
        turn = 0,
        voyage_count = 0,
        voyage_hull_damage = 0,
        route_intel = nil,
        battle_report = nil,
        recovery_summary = nil,
        failure_reason = nil,
        chapter_complete = false,
        next_voyage_objective = nil,
        active_event = "event_route_choice",
    }
    resetBattle(state)
    return state
end

function V2ChapterState.new(profile)
    local state = baseState(profile)
    if profile == "qa_explore" then
        state.stage = "route_choice"
        state.current_node = "node_fog_gate"
        state.flags.voyage_ready = true
        state.objective = "在安全航线与暗礁近路之间做出选择"
        state.last_result = "QA 探索档已定位到第一片迷雾。"
        state.resources.provisions = balanceValue("initial_provisions") - 1
    elseif profile == "qa_combat" then
        state.stage = "naval"
        state.current_node = "node_raider"
        state.route = "risky_shortcut"
        state.flags.voyage_ready = true
        state.flags.route_chosen = true
        state.flags.risky_route = true
        state.flags.salvage_found = true
        state.flags.curse_heard = true
        state.voyage_hull_damage = routeData("risky_shortcut").hull_damage
        applyReward(state, "reward_salvage")
        state.resources.provisions = 5
        resetBattle(state)
        state.objective = "选择击毁甲板或压制火炮，再决定接舷时机"
        state.last_result = "QA 战斗档已定位到诅咒追猎者。"
    elseif profile == "qa_boarding" then
        state.stage = "boarding"
        state.current_node = "node_raider"
        state.route = "risky_shortcut"
        state.flags.route_chosen = true
        state.flags.risky_route = true
        state.flags.black_tide_crossed = true
        state.flags.curse_heard = true
        state.flags.compass_resolved = true
        resetBattle(state)
        state.battle.deck_damage = state.battle.deck_threshold
        state.battle.deck_broken = true
        state.battle.enemy_boarding_hp = balanceValue("boarding_wounded_hp")
        state.battle.transfer_summary = string.format(
            "舰炮阶段击毁敌方甲板：接舷敌人以 %d/%d 状态开场。",
            state.battle.enemy_boarding_hp,
            state.battle.enemy_boarding_hp_max
        )
        state.objective = "击败敌方接舷队，夺取符文线索"
        state.last_result = "QA 接舷档已定位到追猎者甲板。"
    elseif profile == "qa_rune" then
        state.stage = "rune_clue"
        state.current_node = "node_rune_clue"
        state.route = "safe_route"
        state.flags.raider_defeated = true
        state.active_event = "event_rune_clue"
        applyReward(state, "reward_battle")
        state.battle_report = "QA 符文档：甲板优势已成功传递到接舷战。"
        state.objective = "检查与水晶瓶共鸣的符文碎片"
        state.last_result = "QA 符文档已定位到首章目标。"
    elseif profile == "qa_settlement" then
        state.stage = "settlement"
        state.current_node = "node_rune_clue"
        state.route = "safe_route"
        state.flags.raider_defeated = true
        state.flags.chapter_01_complete = true
        state.chapter_complete = true
        applyReward(state, "reward_battle")
        applyReward(state, "reward_rune_clue")
        state.objective = "确认战利品用途并返回皇家港"
        state.last_result = "QA 结算档已取得符文碎片和追猎者战利品。"
    end
    return state
end

function V2ChapterState.normalize(savedState, profile)
    local state = V2ChapterState.new(profile)
    if type(savedState) == "table"
        and (savedState.schema_version == V2ChapterState.SCHEMA_VERSION
            or savedState.schema_version == 3)
        and savedState.chapter_id == "chapter_01"
        and V2ChapterState.STAGES[savedState.stage] then
        overwrite(state, savedState)
        -- Phase 4 only adds local test records. Preserve the complete Phase 3
        -- chapter state and let V2Telemetry create a fresh session on load.
        state.schema_version = V2ChapterState.SCHEMA_VERSION
    end
    state.profile = profile or state.profile or "player"
    return state
end

local actionsByStage = {
    opening = {
        { id = "accept_call", label = "握住水晶瓶" },
    },
    black_tide = {
        { id = "lash_cargo", label = choiceLabel("lash_cargo") },
        { id = "ride_black_tide", label = choiceLabel("ride_black_tide") },
    },
    whisper = {
        { id = "resist_whisper", label = choiceLabel("resist_whisper") },
        { id = "listen_whisper", label = choiceLabel("listen_whisper") },
    },
    curse_choice = {
        { id = "follow_cursed_compass", label = choiceLabel("follow_cursed_compass") },
        { id = "break_cursed_compass", label = choiceLabel("break_cursed_compass") },
    },
    naval = {
        { id = "gunner_mark_deck", label = ChapterData.by_id.battle_action.gunner_mark_deck.label },
        { id = "fire_at_deck", label = ChapterData.by_id.battle_action.fire_at_deck.label },
        { id = "fire_at_guns", label = ChapterData.by_id.battle_action.fire_at_guns.label },
        { id = "board_now", label = "立即接舷" },
        { id = "retreat", label = "撤退返航" },
    },
    boarding = {
        { id = "boarding_attack", label = ChapterData.by_id.battle_action.boarding_attack.label },
        { id = "boarding_rush", label = ChapterData.by_id.battle_action.boarding_rush.label },
        { id = "sailor_guard", label = ChapterData.by_id.battle_action.sailor_guard.label },
        { id = "medic_heal", label = ChapterData.by_id.battle_action.medic_heal.label },
        { id = "retreat", label = "撤退返航" },
    },
    rune_clue = {
        { id = "take_rune_clue", label = choiceLabel("take_rune_clue") },
    },
    settlement = {
        { id = "return_to_port", label = "带着战利品返航" },
    },
    upgrade = {
        { id = "upgrade_hull", label = "升级船体（" .. balanceValue("hull_upgrade_timber_cost") .. " 木材）" },
        { id = "upgrade_guns", label = "升级火炮（" .. balanceValue("guns_upgrade_iron_cost") .. " 铁料）" },
    },
    complete = {
        { id = "restart_chapter", label = "重玩首章（测试）" },
    },
    failed = {
        { id = "retry_battle", label = "重试（" .. balanceValue("retry_supply_cost") .. " 补给）" },
        { id = "recover_at_port", label = "返港恢复（" .. balanceValue("port_recovery_gold_cost") .. " 金币）" },
    },
}

function V2ChapterState.getActions(state)
    if state.stage == "harbor" then
        local hullLabel = state.selected_module == "module_reinforced_hull"
            and "✓ 加固船体" or "选择加固船体"
        local gunsLabel = state.selected_module == "module_heavy_guns"
            and "✓ 重炮甲板" or "选择重炮甲板"
        return {
            { id = "select_reinforced_hull", label = hullLabel },
            { id = "select_heavy_guns", label = gunsLabel },
            { id = "start_voyage", label = "驶入第一片迷雾" },
        }
    end

    if state.stage == "route_choice" then
        local safe = routeData("safe_route")
        local risky = routeData("risky_shortcut")
        local safeLabel = state.flags.route_intel
            and string.format("%s｜风险 %d / 补给 %d", safe.label, safe.risk, safe.supply_cost)
            or "未知航线 A｜外海方向"
        local riskyLabel = state.flags.route_intel
            and string.format("%s｜风险 %d / 补给 %d", risky.label, risky.risk, risky.supply_cost)
            or "未知航线 B｜暗礁方向"
        local result = {
            { id = "choose_safe_route", label = safeLabel },
            { id = "choose_risky_route", label = riskyLabel },
        }
        if not state.flags.route_intel then
            table.insert(result, 1, {
                id = "reveal_route_intel",
                label = "卡特琳娜：测绘（" .. balanceValue("navigator_intel_cost") .. " 补给）",
            })
        end
        return result
    end

    if state.stage == "route_event" then
        if state.route == "risky_shortcut" then
            return {
                { id = "rescue_survivors", label = choiceLabel("rescue_survivors") },
                { id = "salvage_wreck", label = choiceLabel("salvage_wreck") },
            }
        end
        return {
            { id = "rest_at_cove", label = choiceLabel("rest_at_cove") },
            { id = "press_through_cove", label = choiceLabel("press_through_cove") },
        }
    end

    local actions = copy(actionsByStage[state.stage] or {})
    if state.stage == "naval" and state.battle.enemy_ship_hp <= 0 then
        actions = {
            { id = "board_now", label = "敌舰失去抵抗，开始接舷" },
            { id = "retreat", label = "放弃战利品并返航" },
        }
    elseif state.stage == "naval" and state.battle.gunner_mark_used then
        local filtered = {}
        for _, action in ipairs(actions) do
            if action.id ~= "gunner_mark_deck" then
                table.insert(filtered, action)
            end
        end
        actions = filtered
    elseif state.stage == "boarding" then
        local filtered = {}
        for _, action in ipairs(actions) do
            if not (action.id == "medic_heal" and state.battle.medic_used)
                and not (action.id == "sailor_guard" and state.battle.sailor_guard_used) then
                table.insert(filtered, action)
            end
        end
        actions = filtered
    end
    return actions
end

local stageTitles = {
    opening = "序章 · 瓶中召唤",
    harbor = "皇家港 · 远航整备",
    route_choice = "瓶中海域 · 迷雾海图",
    route_event = "航线据点",
    black_tide = "航行事件 · 黑潮浪墙",
    whisper = "诅咒事件 · 海盗王低语",
    curse_choice = "诅咒事件 · 失控罗盘",
    naval = "战斗 I · 舰炮战",
    boarding = "战斗 II · 接舷战",
    rune_clue = "章节目标 · 符文回响",
    settlement = "首次返航 · 战利品结算",
    upgrade = "皇家港 · 首次升级",
    complete = "第一章样片完成",
    failed = "本次远航失败",
}

function V2ChapterState.getStageTitle(state)
    return stageTitles[state.stage] or "皇家港与瓶中海域"
end

function V2ChapterState.getNarrative(state)
    if state.stage == "opening" then
        return dialogueBlock("node_port", { "chapter_start" })
    elseif state.stage == "harbor" then
        return "四名船员已经就位：炮手罗克、水手米克、航海士卡特琳娜、医师艾琳。\n选择一项船只模块；当前配置可直接出航。"
    elseif state.stage == "route_choice" then
        if state.flags.route_intel then
            return "卡特琳娜完成测绘：\n"
                .. routeData("safe_route").intel_hint .. "。\n"
                .. routeData("risky_shortcut").intel_hint .. "。"
        end
        return dialogueBlock("node_fog_gate", { "node_enter" })
            .. "\n前方两条航线都被迷雾覆盖；可以直接选择，也可以消耗补给测绘。"
    elseif state.stage == "route_event" then
        if state.route == "risky_shortcut" then
            return dialogueBlock("node_wreck", { "node_enter" })
                .. "\n救人获得信任；搜刮能取得完整升级资源。"
        end
        return dialogueBlock("node_safe_cove", { "node_enter" })
            .. "\n靠岸能提高接舷容错，不停船则维持航行节奏。"
    elseif state.stage == "black_tide" then
        return dialogueBlock("node_black_tide", { "node_enter" })
            .. string.format("\n固定货舱消耗 %d 补给；迎浪穿越承受 %d 船体损伤。",
                balanceValue("black_tide_supply_cost"), balanceValue("black_tide_hull_damage"))
    elseif state.stage == "whisper" then
        return dialogueBlock("node_whisper", { "node_enter", "choice_prompt" })
            .. "\n接受力量会强化首轮炮击，也会留下诅咒印记。"
    elseif state.stage == "curse_choice" then
        return dialogueBlock("node_cursed_compass", { "node_enter", "choice_prompt" })
            .. string.format("\n利用罗盘使敌舰预损 %d；砸碎罗盘使接舷状态上限提高 %d。",
                balanceValue("compass_ship_damage"), balanceValue("compass_crew_bonus"))
    elseif state.stage == "naval" then
        local gunStatus = state.battle.guns_suppressed
            and "敌炮已压制，后续反击降低。"
            or "压制敌炮不会推进接舷优势，但能降低后续反击。"
        return string.format(
            "%s\n甲板阈值 %d；火炮阈值 %d。%s",
            dialogueBlock("node_raider", { "battle_start", "naval_hint" }),
            state.battle.deck_threshold,
            state.battle.gun_threshold,
            gunStatus
        )
    elseif state.stage == "boarding" then
        return state.battle.transfer_summary
            .. "\n" .. dialogueBlock("node_raider", { "boarding_start", "boarding_hint" })
            .. "\n稳推损耗低，强攻结束更快。"
    elseif state.stage == "rune_clue" then
        return dialogueBlock("node_rune_clue", { "chapter_complete" })
            .. "\n战斗复盘：" .. tostring(state.battle_report)
    elseif state.stage == "settlement" then
        return "追猎者战利品已经装船。返航后可在船体耐久与火炮效率之间完成一次有效升级。"
    elseif state.stage == "upgrade" then
        return dialogueBlock("node_port", { "return_to_port" })
            .. "\n船体升级提高远航容错；火炮升级提高舰炮输出。"
    elseif state.stage == "complete" then
        return "第一枚符文线索：潮汐墓场。\n下一次远航目标已明确——穿过更深的迷雾，寻找符文守卫。"
    elseif state.stage == "failed" then
        return "失败原因：" .. tostring(state.failure_reason)
            .. "\n恢复方案：" .. tostring(state.recovery_summary)
    end
    return ""
end

function V2ChapterState.getPresentation(state)
    for _, row in ipairs(ChapterData.presentation) do
        if row.stage == state.stage then
            return row
        end
    end
    return ChapterData.by_id.presentation.presentation_harbor
end

local function failBattle(state, reason, action)
    state.failure_reason = reason
    state.recovery_summary = string.format(
        "原地重试消耗 %d 补给；返港恢复消耗 %d 金币。",
        balanceValue("retry_supply_cost"),
        balanceValue("port_recovery_gold_cost")
    )
    state.stage = "failed"
    state.objective = "选择重试战斗或返回皇家港"
    addHistory(state, action, reason)
end

local function winBoarding(state, action)
    grantFlag(state, "raider_defeated")
    applyReward(state, "reward_battle")
    state.stage = "rune_clue"
    state.current_node = "node_rune_clue"
    state.active_event = "event_rune_clue"
    state.objective = "检查与水晶瓶共鸣的符文碎片"
    local route = routeData(state.route)
    state.battle_report = string.format(
        "%s（风险 %d）；舰炮行动 %d 次；接舷行动 %d 次；甲板%s；敌炮%s；接舷队剩余 %d/%d。胜因：%s",
        route.label,
        route.risk,
        state.battle.naval_action_count,
        state.battle.boarding_action_count,
        state.battle.deck_broken and "已击毁" or "未击毁",
        state.battle.guns_suppressed and "已压制" or "未压制",
        state.battle.crew_hp,
        state.battle.crew_hp_max,
        state.battle.deck_broken and "舰炮优势成功传递到接舷" or "船员在完整敌阵下取胜"
    )
    addHistory(state, action, "接舷队击败追猎者，舰炮战结果已影响敌方开场状态。")
end

local function resolveNavalAttack(state, action)
    if state.battle.enemy_ship_hp <= 0 then
        return false, "敌舰已经失去舰炮抵抗，请开始接舷"
    end

    local data = battleAction(action)
    local damage = data.damage
        + state.ship.gun_level * balanceValue("gun_level_bonus")
        + (moduleData(state).cannon_bonus or 0)
    if state.flags.curse_marked and state.battle.volley_count == 0 then
        damage = damage + balanceValue("curse_first_volley_bonus")
    end
    if action == "fire_at_deck" and state.battle.gunner_marked then
        damage = damage + balanceValue("gunner_mark_bonus")
        state.battle.gunner_marked = false
    end

    state.battle.volley_count = state.battle.volley_count + 1
    state.battle.naval_action_count = state.battle.naval_action_count + 1
    state.battle.enemy_ship_hp = math.max(0, state.battle.enemy_ship_hp - damage)
    if action == "fire_at_deck" then
        state.battle.deck_damage = state.battle.deck_damage + damage
        state.battle.deck_broken = state.battle.deck_damage >= state.battle.deck_threshold
    else
        state.battle.gun_damage = state.battle.gun_damage + damage
        state.battle.guns_suppressed = state.battle.gun_damage >= state.battle.gun_threshold
    end

    local retaliation = data.retaliation
    if state.battle.guns_suppressed then
        retaliation = math.max(0, retaliation - balanceValue("suppressed_retaliation_reduction"))
    end
    if state.battle.enemy_ship_hp > 0 then
        state.battle.player_hull = state.battle.player_hull - retaliation
        state.battle.total_hull_damage = state.battle.total_hull_damage + retaliation
    end
    table.insert(state.battle.actions_log, action)

    if state.battle.player_hull <= 0 then
        failBattle(state, "船体在舰炮交火中沉没", action)
        return true, state.last_result
    end

    state.objective = state.battle.enemy_ship_hp <= 0
        and "敌舰舰炮已停火，现在开始接舷"
        or "比较甲板优势、敌炮威胁与剩余船体，再决定下一步"
    local targetName = action == "fire_at_deck" and "甲板" or "火炮"
    addHistory(state, action, string.format(
        "%s齐射造成 %d 伤害，承受 %d 反击；甲板 %d/%d，敌炮 %d/%d。",
        targetName,
        damage,
        state.battle.enemy_ship_hp > 0 and retaliation or 0,
        state.battle.deck_damage,
        state.battle.deck_threshold,
        state.battle.gun_damage,
        state.battle.gun_threshold
    ))
    return true, state.last_result
end

function V2ChapterState.apply(state, action)
    if type(state) ~= "table" or not V2ChapterState.STAGES[state.stage] then
        return false, "无效的首章状态"
    end

    if action == "accept_call" and state.stage == "opening" then
        state.stage = "harbor"
        state.objective = "确认船员与船只模块，然后从皇家港出航"
        addHistory(state, action, "你接受卡特琳娜的帮助，获得一艘可出航的受损船只。")
    elseif action == "select_reinforced_hull" and state.stage == "harbor" then
        state.selected_module = "module_reinforced_hull"
        state.ship.hull_max = calculateHullMax(state)
        resetBattle(state)
        addHistory(state, action, "已装配加固船体：更高耐久，舰炮伤害不变。")
    elseif action == "select_heavy_guns" and state.stage == "harbor" then
        state.selected_module = "module_heavy_guns"
        state.ship.hull_max = calculateHullMax(state)
        resetBattle(state)
        addHistory(state, action, "已装配重炮甲板：舰炮更强，但船体容错较低。")
    elseif action == "start_voyage" and state.stage == "harbor" then
        local capacity = balanceValue("initial_provisions")
            + (moduleData(state).supply_capacity_modifier or 0)
        state.resources.provisions = math.min(state.resources.provisions, capacity)
        local departureCost = edgeData("edge_01").supply_cost
        if state.resources.provisions < departureCost then
            return false, "补给不足，无法出航"
        end
        state.resources.provisions = state.resources.provisions - departureCost
        state.voyage_count = state.voyage_count + 1
        grantFlag(state, "voyage_ready")
        state.stage = "route_choice"
        state.current_node = "node_fog_gate"
        state.active_event = "event_route_choice"
        state.objective = "在安全航线与暗礁近路之间做出选择"
        addHistory(state, action, "船离开皇家港，第一片迷雾在海图上展开。")
    elseif action == "reveal_route_intel" and state.stage == "route_choice" then
        local intelCost = balanceValue("navigator_intel_cost")
        if state.resources.provisions < intelCost then
            return false, "补给不足，无法完成迷雾测绘"
        end
        state.resources.provisions = state.resources.provisions - intelCost
        grantFlag(state, "route_intel")
        state.route_intel = {
            safe = routeData("safe_route").intel_hint,
            risky = routeData("risky_shortcut").intel_hint,
        }
        addHistory(state, action, string.format("卡特琳娜消耗 %d 份补给，揭示了两条航线的风险与收益。", intelCost))
    elseif action == "choose_safe_route" and state.stage == "route_choice" then
        local route = routeData("safe_route")
        if state.resources.provisions < route.supply_cost then
            return false, "安全航线需要 " .. route.supply_cost .. " 份补给"
        end
        state.resources.provisions = state.resources.provisions - route.supply_cost
        state.route = "safe_route"
        state.voyage_hull_damage = route.hull_damage
        grantFlag(state, "route_chosen")
        grantFlag(state, "safe_route")
        state.stage = "route_event"
        state.current_node = "node_safe_cove"
        state.active_event = "event_safe_cove"
        state.objective = "在避风海湾完成休整"
        addHistory(state, action, string.format("选择%s：消耗 %d 补给，%s。", route.label, route.supply_cost, route.outcome_hint))
    elseif action == "choose_risky_route" and state.stage == "route_choice" then
        local route = routeData("risky_shortcut")
        if state.resources.provisions < route.supply_cost then
            return false, "暗礁近路需要 " .. route.supply_cost .. " 份补给"
        end
        state.resources.provisions = state.resources.provisions - route.supply_cost
        state.route = "risky_shortcut"
        state.voyage_hull_damage = route.hull_damage
        grantFlag(state, "route_chosen")
        grantFlag(state, "risky_route")
        state.stage = "route_event"
        state.current_node = "node_wreck"
        state.active_event = "event_wreck_survivors"
        state.objective = "搜索暗礁后的沉船残骸"
        addHistory(state, action, string.format("选择%s：船体预损 %d，%s。", route.label, route.hull_damage, route.outcome_hint))
    elseif (action == "rest_at_cove" or action == "press_through_cove")
        and state.stage == "route_event" and state.route == "safe_route" then
        local result = applyChoiceOutcome(state, action)
        if action == "rest_at_cove" then
            state.battle.crew_hp = state.battle.crew_hp_max
        end
        grantFlag(state, "route_event_resolved")
        state.stage = "black_tide"
        state.current_node = "node_black_tide"
        state.active_event = "event_black_tide"
        state.objective = "决定如何穿过异常黑潮"
        addHistory(state, action, result)
    elseif (action == "rescue_survivors" or action == "salvage_wreck")
        and state.stage == "route_event" and state.route == "risky_shortcut" then
        local result = applyChoiceOutcome(state, action)
        grantFlag(state, "route_event_resolved")
        state.stage = "black_tide"
        state.current_node = "node_black_tide"
        state.active_event = "event_black_tide"
        state.objective = "决定如何穿过异常黑潮"
        addHistory(state, action, result)
    elseif (action == "lash_cargo" or action == "ride_black_tide") and state.stage == "black_tide" then
        if action == "lash_cargo" then
            local tideCost = balanceValue("black_tide_supply_cost")
            if state.resources.provisions < tideCost then
                return false, "补给不足，无法固定货舱"
            end
            state.resources.provisions = state.resources.provisions - tideCost
        else
            state.voyage_hull_damage = state.voyage_hull_damage + balanceValue("black_tide_hull_damage")
        end
        local result = applyChoiceOutcome(state, action)
        grantFlag(state, "black_tide_crossed")
        state.stage = "whisper"
        state.current_node = "node_whisper"
        state.active_event = "event_whisper"
        state.objective = "回应海盗王提出的诅咒交易"
        addHistory(state, action, result)
    elseif (action == "resist_whisper" or action == "listen_whisper") and state.stage == "whisper" then
        grantFlag(state, "curse_heard")
        local result = applyChoiceOutcome(state, action)
        state.stage = "curse_choice"
        state.current_node = "node_cursed_compass"
        state.active_event = "event_cursed_compass"
        state.objective = "利用或摧毁失控的诅咒罗盘"
        addHistory(state, action, result)
    elseif (action == "follow_cursed_compass" or action == "break_cursed_compass")
        and state.stage == "curse_choice" then
        local convergenceCost = edgeData("edge_08").supply_cost
        if state.resources.provisions < convergenceCost then
            return false, "剩余补给不足以抵达追猎者"
        end
        state.resources.provisions = state.resources.provisions - convergenceCost
        local result = applyChoiceOutcome(state, action)
        grantFlag(state, "compass_resolved")
        resetBattle(state)
        state.stage = "naval"
        state.current_node = "node_raider"
        state.active_event = "event_raider_encounter"
        state.objective = "选择击毁甲板或压制火炮，再决定接舷时机"
        addHistory(state, action, result)
    elseif action == "gunner_mark_deck" and state.stage == "naval" then
        if state.battle.gunner_mark_used then
            return false, "齐射标记本场已经使用"
        end
        state.battle.gunner_mark_used = true
        state.battle.gunner_marked = true
        state.battle.naval_action_count = state.battle.naval_action_count + 1
        table.insert(state.battle.actions_log, action)
        addHistory(state, action, "罗克完成甲板标记：下一次甲板齐射获得额外破坏。")
    elseif (action == "fire_at_deck" or action == "fire_at_guns") and state.stage == "naval" then
        return resolveNavalAttack(state, action)
    elseif action == "board_now" and state.stage == "naval" then
        state.stage = "boarding"
        if state.battle.deck_broken then
            state.battle.enemy_boarding_hp = balanceValue("boarding_wounded_hp")
            state.battle.transfer_summary = string.format(
                "舰炮阶段击毁敌方甲板：接舷敌人以 %d/%d 状态开场。",
                state.battle.enemy_boarding_hp,
                state.battle.enemy_boarding_hp_max
            )
        else
            state.battle.enemy_boarding_hp = state.battle.enemy_boarding_hp_max
            state.battle.transfer_summary = string.format(
                "敌方甲板仍完整：接舷敌人以 %d/%d 状态开场。",
                state.battle.enemy_boarding_hp,
                state.battle.enemy_boarding_hp_max
            )
        end
        state.objective = "击败敌方接舷队，夺取符文线索"
        addHistory(state, action, state.battle.transfer_summary)
    elseif (action == "boarding_attack" or action == "boarding_rush") and state.stage == "boarding" then
        local data = battleAction(action)
        local damage = data.damage
        local retaliation = data.retaliation
        state.battle.enemy_boarding_hp = math.max(0, state.battle.enemy_boarding_hp - damage)
        state.battle.boarding_action_count = state.battle.boarding_action_count + 1
        table.insert(state.battle.actions_log, action)
        if state.battle.enemy_boarding_hp <= 0 then
            winBoarding(state, action)
        else
            if state.battle.sailor_guarded then
                retaliation = 0
                state.battle.sailor_guarded = false
            end
            state.battle.crew_hp = state.battle.crew_hp - retaliation
            if state.battle.crew_hp <= 0 then
                failBattle(state, "接舷队在甲板上失去战斗力", action)
            else
                addHistory(state, action, string.format("接舷造成 %d 点伤害，船员承受 %d 点反击。", damage, retaliation))
            end
        end
    elseif action == "sailor_guard" and state.stage == "boarding" then
        if state.battle.sailor_guard_used then
            return false, "甲板守卫本场已经使用"
        end
        state.battle.sailor_guard_used = true
        state.battle.sailor_guarded = true
        state.battle.boarding_action_count = state.battle.boarding_action_count + 1
        table.insert(state.battle.actions_log, action)
        addHistory(state, action, "米克建立甲板防线：下一次接舷反击伤害归零。")
    elseif action == "medic_heal" and state.stage == "boarding" then
        if state.battle.medic_used then
            return false, "紧急包扎本场已经使用"
        end
        state.battle.medic_used = true
        local heal = balanceValue("medic_heal_amount")
        state.battle.crew_hp = math.min(state.battle.crew_hp_max, state.battle.crew_hp + heal)
        state.battle.boarding_action_count = state.battle.boarding_action_count + 1
        table.insert(state.battle.actions_log, action)
        addHistory(state, action, string.format("艾琳完成紧急包扎，接舷队恢复 %d 点状态。", heal))
    elseif action == "retreat" and (state.stage == "naval" or state.stage == "boarding") then
        failBattle(state, "船长主动撤退，未取得追猎者战利品", action)
    elseif action == "take_rune_clue" and state.stage == "rune_clue" then
        local result = applyChoiceOutcome(state, action)
        state.chapter_complete = true
        state.stage = "settlement"
        state.objective = "确认战利品用途并返回皇家港"
        addHistory(state, action, result .. "：潮汐墓场。")
    elseif action == "return_to_port" and state.stage == "settlement" then
        state.stage = "upgrade"
        state.current_node = "node_port"
        state.objective = "使用本次远航资源完成一次船只升级"
        addHistory(state, action, "追猎者战利品已入库，船坞开放首次升级。")
    elseif action == "upgrade_hull" and state.stage == "upgrade" then
        local cost = balanceValue("hull_upgrade_timber_cost")
        if state.resources.timber < cost then
            return false, "木材不足，船体升级需要 " .. cost
        end
        state.resources.timber = state.resources.timber - cost
        state.ship.hull_level = state.ship.hull_level + 1
        state.ship.hull_max = calculateHullMax(state)
        state.upgrades.hull = true
        state.stage = "complete"
        state.next_voyage_objective = "前往潮汐墓场寻找符文守卫"
        state.objective = "查看下一次远航目标"
        addHistory(state, action, "船体升级完成：最大耐久提高 " .. balanceValue("hull_level_bonus") .. "。")
    elseif action == "upgrade_guns" and state.stage == "upgrade" then
        local cost = balanceValue("guns_upgrade_iron_cost")
        if state.resources.iron < cost then
            return false, "铁料不足，火炮升级需要 " .. cost
        end
        state.resources.iron = state.resources.iron - cost
        state.ship.gun_level = state.ship.gun_level + 1
        state.upgrades.guns = true
        state.stage = "complete"
        state.next_voyage_objective = "前往潮汐墓场寻找符文守卫"
        state.objective = "查看下一次远航目标"
        addHistory(state, action, "火炮升级完成：后续齐射伤害提高。")
    elseif action == "retry_battle" and state.stage == "failed" then
        local retryCost = balanceValue("retry_supply_cost")
        if state.resources.provisions < retryCost then
            return false, "补给不足，必须返回皇家港恢复"
        end
        state.resources.provisions = state.resources.provisions - retryCost
        resetBattle(state)
        state.failure_reason = nil
        state.stage = "naval"
        state.current_node = "node_raider"
        state.objective = "重新进行舰炮战并理解甲板破坏传递"
        addHistory(state, action, string.format("消耗 %d 补给，战斗状态重置到舰炮战开始前。", retryCost))
    elseif action == "recover_at_port" and state.stage == "failed" then
        local recoveryCost = balanceValue("port_recovery_gold_cost")
        if state.resources.gold < recoveryCost then
            return false, "金币不足，无法支付返港恢复"
        end
        state.resources.gold = state.resources.gold - recoveryCost
        state.route = nil
        state.voyage_hull_damage = 0
        state.route_intel = nil
        resetBattle(state)
        state.failure_reason = nil
        state.stage = "harbor"
        state.current_node = "node_port"
        state.active_event = "event_route_choice"
        state.objective = "重新整备后再次出航"
        addHistory(state, action, string.format("支付 %d 金币，船只与船员已在皇家港恢复。", recoveryCost))
    elseif action == "restart_chapter" and state.stage == "complete" then
        local restarted = V2ChapterState.new(state.profile)
        for key in pairs(state) do
            state[key] = nil
        end
        overwrite(state, restarted)
        addHistory(state, action, "首章测试进度已重置。")
    else
        return false, "当前阶段不能执行操作：" .. tostring(action)
    end

    return true, state.last_result
end

function V2ChapterState.getData()
    return ChapterData
end

return V2ChapterState
