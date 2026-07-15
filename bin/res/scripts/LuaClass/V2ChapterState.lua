-- Pure Lua state machine for the V2 Chapter 1 vertical slice.
-- This module intentionally has no Cocos dependencies so the complete chapter
-- and every recovery path can be tested from the command line.

local ChapterData = require "LuaClass/V2ChapterData"

local V2ChapterState = {}

V2ChapterState.SCHEMA_VERSION = 1
V2ChapterState.STAGES = {
    opening = true,
    harbor = true,
    route_choice = true,
    route_event = true,
    whisper = true,
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

local function resetBattle(state)
    local enemy = ChapterData.by_id.enemy.enemy_cursed_raider
    state.battle = {
        enemy_ship_hp = enemy.ship_hp,
        enemy_ship_hp_max = enemy.ship_hp,
        deck_damage = 0,
        deck_broken = false,
        player_hull = state.ship.hull_max,
        player_hull_max = state.ship.hull_max,
        enemy_boarding_hp = enemy.boarding_power,
        enemy_boarding_hp_max = enemy.boarding_power,
        crew_hp = 100,
        crew_hp_max = 100,
        medic_used = false,
        volley_count = 0,
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
            gold = 40,
            timber = 0,
            iron = 0,
            provisions = 8,
            rune_dust = 0,
        },
        ship = {
            hull_level = 0,
            gun_level = 0,
            hull_max = 120,
        },
        flags = {},
        claimed_rewards = {},
        upgrades = {},
        battle = {},
        history = {},
        turn = 0,
        voyage_count = 0,
        failure_reason = nil,
        chapter_complete = false,
        next_voyage_objective = nil,
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
        state.resources.provisions = 7
    elseif profile == "qa_combat" then
        state.stage = "naval"
        state.current_node = "node_raider"
        state.route = "risky_shortcut"
        state.flags.voyage_ready = true
        state.flags.route_chosen = true
        state.flags.risky_route = true
        state.flags.salvage_found = true
        state.flags.curse_heard = true
        applyReward(state, "reward_salvage")
        state.resources.provisions = 5
        state.objective = "炮击敌舰甲板，再决定接舷时机"
        state.last_result = "QA 战斗档已定位到诅咒追猎者。"
    end
    return state
end

function V2ChapterState.normalize(savedState, profile)
    local state = V2ChapterState.new(profile)
    if type(savedState) == "table"
        and savedState.schema_version == V2ChapterState.SCHEMA_VERSION
        and savedState.chapter_id == "chapter_01"
        and V2ChapterState.STAGES[savedState.stage] then
        overwrite(state, savedState)
    end
    state.profile = profile or state.profile or "player"
    return state
end

local actionsByStage = {
    opening = {
        { id = "accept_call", label = "握住水晶瓶" },
    },
    route_choice = {
        { id = "choose_safe_route", label = "外海安全航线" },
        { id = "choose_risky_route", label = "暗礁高风险近路" },
    },
    route_event = {
        { id = "resolve_route_event", label = "处理当前据点" },
    },
    whisper = {
        { id = "resist_whisper", label = "拒绝海盗王" },
        { id = "listen_whisper", label = "借用诅咒力量" },
    },
    naval = {
        { id = "fire_at_deck", label = "标记甲板并齐射" },
        { id = "board_now", label = "立即接舷" },
        { id = "retreat", label = "撤退返航" },
    },
    boarding = {
        { id = "boarding_attack", label = "稳步推进" },
        { id = "boarding_rush", label = "冒险强攻" },
        { id = "medic_heal", label = "紧急包扎" },
        { id = "retreat", label = "撤退返航" },
    },
    rune_clue = {
        { id = "take_rune_clue", label = "收下符文碎片" },
    },
    settlement = {
        { id = "return_to_port", label = "带着战利品返航" },
    },
    upgrade = {
        { id = "upgrade_hull", label = "升级船体（10 木材）" },
        { id = "upgrade_guns", label = "升级火炮（15 铁料）" },
    },
    complete = {
        { id = "restart_chapter", label = "重玩首章（测试）" },
    },
    failed = {
        { id = "retry_battle", label = "从战斗前重试" },
        { id = "recover_at_port", label = "返回皇家港整备" },
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

    local actions = copy(actionsByStage[state.stage] or {})
    if state.stage == "naval" and state.battle.enemy_ship_hp <= 0 then
        actions = {
            { id = "board_now", label = "敌舰失去抵抗，开始接舷" },
            { id = "retreat", label = "放弃战利品并返航" },
        }
    elseif state.stage == "boarding" and state.battle.medic_used then
        local filtered = {}
        for _, action in ipairs(actions) do
            if action.id ~= "medic_heal" then
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
    whisper = "诅咒事件 · 海盗王低语",
    naval = "战斗 I · 舰炮战",
    boarding = "战斗 II · 接舷战",
    rune_clue = "章节目标 · 符文回响",
    settlement = "首次返航 · 战利品结算",
    upgrade = "皇家港 · 首次升级",
    complete = "第一章灰盒完成",
    failed = "本次远航失败",
}

function V2ChapterState.getStageTitle(state)
    return stageTitles[state.stage] or "皇家港与瓶中海域"
end

function V2ChapterState.getNarrative(state)
    if state.stage == "opening" then
        return "海盗王：终于有人打开了这只瓶子。\n\n卡特琳娜：想活着离开，就先修好船。迷雾里的东西已经发现我们了。"
    elseif state.stage == "harbor" then
        return "四名船员已经就位：炮手罗克、水手米克、航海士卡特琳娜、医师艾琳。\n选择一项船只模块；当前配置可直接出航。"
    elseif state.stage == "route_choice" then
        return "卡特琳娜：外海更安全，但会多消耗补给；暗礁近路危险，可能发现额外战利品。"
    elseif state.stage == "route_event" then
        if state.route == "risky_shortcut" then
            return "暗礁后露出一艘沉船。搜索可能取得修船材料，但这条航线已经惊动迷雾中的追猎者。"
        end
        return "船驶入避风海湾。船员得到休整，但绕行让补给消耗得更快。"
    elseif state.stage == "whisper" then
        return "海盗王：借用我的力量，你会更快找到符文。\n这份力量能强化下一轮炮击，也会留下诅咒印记。"
    elseif state.stage == "naval" then
        return "罗克：先轰碎它的甲板，再让米克带人登船！\n甲板破坏达到 300 时，接舷敌人会以受伤状态开场。"
    elseif state.stage == "boarding" then
        return state.battle.transfer_summary
            .. "\n米克负责前排推进；艾琳可在本场使用一次紧急包扎。"
    elseif state.stage == "rune_clue" then
        return "敌舰货舱里的碎片正与水晶瓶共鸣。海盗王的第一道封印已经松动。"
    elseif state.stage == "settlement" then
        return "追猎者战利品已经装船。返航后可在船体耐久与火炮效率之间完成一次有效升级。"
    elseif state.stage == "upgrade" then
        return "船体升级提高下一次远航容错；火炮升级提高舰炮阶段输出。两项资源都来自刚完成的远航。"
    elseif state.stage == "complete" then
        return "第一枚符文线索：潮汐墓场。\n下一次远航目标已明确——穿过更深的迷雾，寻找符文守卫。"
    elseif state.stage == "failed" then
        return "失败原因：" .. tostring(state.failure_reason)
            .. "\n你可以从战斗前重试，或返回皇家港重新整备。"
    end
    return ""
end

local function failBattle(state, reason, action)
    state.failure_reason = reason
    state.stage = "failed"
    state.objective = "选择重试战斗或返回皇家港"
    addHistory(state, action, reason)
end

local function winBoarding(state, action)
    grantFlag(state, "raider_defeated")
    applyReward(state, "reward_battle")
    state.stage = "rune_clue"
    state.current_node = "node_rune_clue"
    state.objective = "检查与水晶瓶共鸣的符文碎片"
    addHistory(state, action, "接舷队击败追猎者，舰炮战结果已影响敌方开场状态。")
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
        state.ship.hull_max = 120 + state.ship.hull_level * 20
        resetBattle(state)
        addHistory(state, action, "已装配加固船体：更高耐久，舰炮伤害不变。")
    elseif action == "select_heavy_guns" and state.stage == "harbor" then
        state.selected_module = "module_heavy_guns"
        state.ship.hull_max = 100 + state.ship.hull_level * 20
        resetBattle(state)
        addHistory(state, action, "已装配重炮甲板：舰炮更强，但船体容错较低。")
    elseif action == "start_voyage" and state.stage == "harbor" then
        if state.resources.provisions < 1 then
            return false, "补给不足，无法出航"
        end
        state.resources.provisions = state.resources.provisions - 1
        state.voyage_count = state.voyage_count + 1
        grantFlag(state, "voyage_ready")
        state.stage = "route_choice"
        state.current_node = "node_fog_gate"
        state.objective = "在安全航线与暗礁近路之间做出选择"
        addHistory(state, action, "船离开皇家港，第一片迷雾在海图上展开。")
    elseif action == "choose_safe_route" and state.stage == "route_choice" then
        if state.resources.provisions < 2 then
            return false, "安全航线需要 2 份补给"
        end
        state.resources.provisions = state.resources.provisions - 2
        state.route = "safe_route"
        grantFlag(state, "route_chosen")
        grantFlag(state, "safe_route")
        state.stage = "route_event"
        state.current_node = "node_safe_cove"
        state.objective = "在避风海湾完成休整"
        addHistory(state, action, "你选择较远的安全航线，消耗 2 份补给。")
    elseif action == "choose_risky_route" and state.stage == "route_choice" then
        if state.resources.provisions < 1 then
            return false, "暗礁近路需要 1 份补给"
        end
        state.resources.provisions = state.resources.provisions - 1
        state.route = "risky_shortcut"
        grantFlag(state, "route_chosen")
        grantFlag(state, "risky_route")
        state.stage = "route_event"
        state.current_node = "node_wreck"
        state.objective = "搜索暗礁后的沉船残骸"
        addHistory(state, action, "你穿过暗礁走近路，船体受到轻微擦伤。")
    elseif action == "resolve_route_event" and state.stage == "route_event" then
        if state.route == "risky_shortcut" then
            applyReward(state, "reward_salvage")
            grantFlag(state, "salvage_found")
            state.battle.player_hull = math.max(1, state.battle.player_hull - 10)
            addHistory(state, action, "沉船搜索完成：获得金币、木材、铁料和补给。")
        else
            grantFlag(state, "crew_restored")
            state.battle.crew_hp = state.battle.crew_hp_max
            addHistory(state, action, "船员在避风海湾恢复到最佳状态。")
        end
        state.stage = "whisper"
        state.current_node = "node_whisper"
        state.objective = "回应海盗王提出的诅咒交易"
    elseif (action == "resist_whisper" or action == "listen_whisper") and state.stage == "whisper" then
        if state.resources.provisions < 1 then
            return false, "剩余补给不足以抵达追猎者"
        end
        state.resources.provisions = state.resources.provisions - 1
        grantFlag(state, "curse_heard")
        if action == "listen_whisper" then
            grantFlag(state, "curse_marked")
            addHistory(state, action, "你接受短暂的炮击强化，也留下了诅咒印记。")
        else
            grantFlag(state, "curse_resisted")
            addHistory(state, action, "你拒绝海盗王，船员士气保持稳定。")
        end
        resetBattle(state)
        state.stage = "naval"
        state.current_node = "node_raider"
        state.objective = "炮击敌舰甲板，再决定接舷时机"
    elseif action == "fire_at_deck" and state.stage == "naval" then
        if state.battle.enemy_ship_hp <= 0 then
            return false, "敌舰已经失去舰炮抵抗，请开始接舷"
        end
        local damage = 175 + state.ship.gun_level * 25
        if state.selected_module == "module_heavy_guns" then
            damage = damage + 45
        end
        if state.flags.curse_marked and state.battle.volley_count == 0 then
            damage = damage + 50
        end
        state.battle.volley_count = state.battle.volley_count + 1
        state.battle.deck_damage = state.battle.deck_damage + damage
        state.battle.enemy_ship_hp = math.max(0, state.battle.enemy_ship_hp - damage)
        if state.battle.deck_damage >= 300 then
            state.battle.deck_broken = true
        end
        if state.battle.enemy_ship_hp > 0 then
            state.battle.player_hull = state.battle.player_hull - 14
        end
        if state.battle.player_hull <= 0 then
            failBattle(state, "船体在舰炮交火中沉没", action)
        else
            state.objective = state.battle.enemy_ship_hp <= 0
                and "敌舰舰炮已停火，现在开始接舷"
                or "继续破坏甲板，或承担更高风险提前接舷"
            addHistory(state, action, string.format("齐射造成 %d 点甲板伤害。", damage))
        end
    elseif action == "board_now" and state.stage == "naval" then
        state.stage = "boarding"
        if state.battle.deck_broken then
            state.battle.enemy_boarding_hp = 65
            state.battle.transfer_summary = "舰炮阶段击毁敌方甲板：接舷敌人以 65/100 状态开场。"
        else
            state.battle.enemy_boarding_hp = 100
            state.battle.transfer_summary = "敌方甲板仍完整：接舷敌人以 100/100 状态开场。"
        end
        state.objective = "击败敌方接舷队，夺取符文线索"
        addHistory(state, action, state.battle.transfer_summary)
    elseif (action == "boarding_attack" or action == "boarding_rush") and state.stage == "boarding" then
        local damage = action == "boarding_rush" and 42 or 30
        local retaliation = action == "boarding_rush" and 34 or 18
        state.battle.enemy_boarding_hp = math.max(0, state.battle.enemy_boarding_hp - damage)
        if state.battle.enemy_boarding_hp <= 0 then
            winBoarding(state, action)
        else
            state.battle.crew_hp = state.battle.crew_hp - retaliation
            if state.battle.crew_hp <= 0 then
                failBattle(state, "接舷队在甲板上失去战斗力", action)
            else
                addHistory(state, action, string.format("接舷造成 %d 点伤害，船员承受 %d 点反击。", damage, retaliation))
            end
        end
    elseif action == "medic_heal" and state.stage == "boarding" then
        if state.battle.medic_used then
            return false, "紧急包扎本场已经使用"
        end
        state.battle.medic_used = true
        state.battle.crew_hp = math.min(state.battle.crew_hp_max, state.battle.crew_hp + 28)
        addHistory(state, action, "艾琳完成紧急包扎，接舷队恢复 28 点状态。")
    elseif action == "retreat" and (state.stage == "naval" or state.stage == "boarding") then
        failBattle(state, "船长主动撤退，未取得追猎者战利品", action)
    elseif action == "take_rune_clue" and state.stage == "rune_clue" then
        applyReward(state, "reward_rune_clue")
        grantFlag(state, "chapter_01_complete")
        state.chapter_complete = true
        state.stage = "settlement"
        state.objective = "确认战利品用途并返回皇家港"
        addHistory(state, action, "第一枚符文线索被记录：潮汐墓场。")
    elseif action == "return_to_port" and state.stage == "settlement" then
        state.stage = "upgrade"
        state.current_node = "node_port"
        state.objective = "使用本次远航资源完成一次船只升级"
        addHistory(state, action, "追猎者战利品已入库，船坞开放首次升级。")
    elseif action == "upgrade_hull" and state.stage == "upgrade" then
        if state.resources.timber < 10 then
            return false, "木材不足，船体升级需要 10"
        end
        state.resources.timber = state.resources.timber - 10
        state.ship.hull_level = state.ship.hull_level + 1
        state.ship.hull_max = state.ship.hull_max + 20
        state.upgrades.hull = true
        state.stage = "complete"
        state.next_voyage_objective = "前往潮汐墓场寻找符文守卫"
        state.objective = "查看下一次远航目标"
        addHistory(state, action, "船体升级完成：最大耐久提高 20。")
    elseif action == "upgrade_guns" and state.stage == "upgrade" then
        if state.resources.iron < 15 then
            return false, "铁料不足，火炮升级需要 15"
        end
        state.resources.iron = state.resources.iron - 15
        state.ship.gun_level = state.ship.gun_level + 1
        state.upgrades.guns = true
        state.stage = "complete"
        state.next_voyage_objective = "前往潮汐墓场寻找符文守卫"
        state.objective = "查看下一次远航目标"
        addHistory(state, action, "火炮升级完成：后续齐射伤害提高。")
    elseif action == "retry_battle" and state.stage == "failed" then
        resetBattle(state)
        state.failure_reason = nil
        state.stage = "naval"
        state.current_node = "node_raider"
        state.objective = "重新进行舰炮战并理解甲板破坏传递"
        addHistory(state, action, "战斗状态已重置到舰炮战开始前。")
    elseif action == "recover_at_port" and state.stage == "failed" then
        resetBattle(state)
        state.failure_reason = nil
        state.stage = "harbor"
        state.current_node = "node_port"
        state.objective = "重新整备后再次出航"
        addHistory(state, action, "船只与船员已在皇家港恢复。")
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
