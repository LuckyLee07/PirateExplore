-- Shared visual contract for the V2 Chapter 1 presentation.
--
-- Keep this module independent from Cocos so its semantic decisions can be
-- regression-tested from the command line. V2ChapterLayer converts the RGB
-- tables to engine colours at the rendering boundary.

local V2UITheme = {}

V2UITheme.colors = {
    -- UI 3.0 keeps the world colourful and the chrome quiet. Surfaces stay
    -- close in value, so hierarchy comes from spacing and opacity instead of
    -- a border around every element.
    shell = { 5, 16, 23 },
    shell_raised = { 12, 30, 37 },
    surface = { 10, 27, 34 },
    surface_soft = { 20, 42, 47 },
    ink = { 244, 238, 218 },
    muted = { 145, 164, 163 },
    gold = { 224, 176, 84 },
    sea = { 84, 171, 175 },
    danger = { 211, 85, 72 },
    purple = { 154, 111, 185 },
    success = { 88, 163, 126 },
    track = { 43, 61, 63 },
    separator = { 76, 96, 96 },
}

local stageAccents = {
    opening = "gold",
    harbor = "sea",
    route_choice = "sea",
    route_event = "gold",
    black_tide = "danger",
    whisper = "purple",
    curse_choice = "purple",
    naval = "danger",
    boarding = "danger",
    rune_clue = "purple",
    settlement = "gold",
    upgrade = "gold",
    crew_growth = "sea",
    complete = "success",
    tide_route_choice = "sea",
    tide_guardian = "danger",
    tide_rune_clue = "purple",
    tide_settlement = "gold",
    tide_complete = "success",
    failed = "danger",
}

local stageKinds = {
    opening = "神秘来信",
    harbor = "出航整备",
    route_choice = "航线决策",
    route_event = "海上遭遇",
    black_tide = "危险海况",
    whisper = "诅咒异象",
    curse_choice = "诅咒抉择",
    naval = "舰炮交火",
    boarding = "甲板接舷",
    rune_clue = "符文发现",
    settlement = "战利品清点",
    upgrade = "船坞强化",
    crew_growth = "首席任命",
    complete = "首航完成",
    tide_route_choice = "成长航线",
    tide_guardian = "潮盾破袭",
    tide_rune_clue = "第二符文",
    tide_settlement = "航程清点",
    tide_complete = "墓场完成",
    failed = "远航受挫",
}

local progressByStage = {
    opening = 1,
    harbor = 1,
    route_choice = 2,
    route_event = 2,
    black_tide = 3,
    whisper = 3,
    curse_choice = 3,
    naval = 4,
    boarding = 4,
    failed = 4,
    rune_clue = 5,
    settlement = 5,
    upgrade = 5,
    crew_growth = 5,
    complete = 5,
    tide_route_choice = 2,
    tide_guardian = 4,
    tide_rune_clue = 5,
    tide_settlement = 5,
    tide_complete = 5,
}

V2UITheme.progress_labels = { "港口", "航线", "异象", "追猎者", "符文" }
V2UITheme.tide_progress_labels = { "港口", "墓场入口", "潮流", "沉锚守卫", "第二符文" }

function V2UITheme.progressLabels(stage)
    if stage == "tide_route_choice" or stage == "tide_guardian"
        or stage == "tide_rune_clue" or stage == "tide_settlement"
        or stage == "tide_complete" then
        return V2UITheme.tide_progress_labels
    end
    return V2UITheme.progress_labels
end

local forwardActions = {
    accept_call = true,
    start_voyage = true,
    board_now = true,
    take_rune_clue = true,
    return_to_port = true,
    take_tide_rune = true,
    return_from_tide = true,
    prepare_next_voyage = true,
    claim_harbor_relief = true,
    restart_chapter = true,
}

local utilityActions = {
    reveal_route_intel = true,
    gunner_mark_deck = true,
    sailor_guard = true,
    medic_heal = true,
    port_resupply = true,
}

local dangerActions = {
    retreat = true,
    ride_black_tide = true,
    boarding_rush = true,
    tide_ram = true,
}

function V2UITheme.accentName(stage)
    return stageAccents[stage] or "sea"
end

function V2UITheme.stageKind(stage)
    return stageKinds[stage] or "海上冒险"
end

function V2UITheme.progressIndex(stage)
    return progressByStage[stage] or 1
end

function V2UITheme.actionRole(stage, actionId, actionIndex, actionCount, selectedModule)
    if actionId == "select_reinforced_hull" and selectedModule == "module_reinforced_hull" then
        return "selected"
    end
    if actionId == "select_heavy_guns" and selectedModule == "module_heavy_guns" then
        return "selected"
    end
    if forwardActions[actionId] or actionCount == 1 then
        return "primary"
    end
    if utilityActions[actionId] then
        return "utility"
    end
    if dangerActions[actionId] then
        return "danger"
    end
    if stage == "failed" and actionId == "recover_at_port" then
        return "utility"
    end
    if stage == "failed" and actionId == "retry_battle" then
        return "primary"
    end
    if stage == "upgrade" or stage == "route_choice" or stage == "tide_route_choice"
        or stage == "harbor" or stage == "crew_growth" then
        return "choice"
    end
    if actionIndex == 1 and actionCount > 2 then
        return "primary"
    end
    return "choice"
end

function V2UITheme.resourceItems(resources)
    return {
        { id = "gold", name = "金币", value = resources.gold, accent = "gold", icon = "Images/V2/Icons/resource-gold.png" },
        { id = "timber", name = "木材", value = resources.timber, accent = "success", icon = "Images/V2/Icons/resource-timber.png" },
        { id = "iron", name = "铁料", value = resources.iron, accent = "muted", icon = "Images/V2/Icons/resource-iron.png" },
        { id = "provisions", name = "补给", value = resources.provisions, accent = "sea", icon = "Images/V2/Icons/resource-provisions.png" },
        { id = "rune_dust", name = "符文", value = resources.rune_dust, accent = "purple", icon = "Images/V2/Icons/resource-rune.png" },
    }
end

local battleIcons = {
    hull = "Images/V2/Icons/battle-hull.png",
    deck = "Images/V2/Icons/battle-deck.png",
    cannon = "Images/V2/Icons/battle-cannon.png",
    crew = "Images/V2/Icons/battle-crew.png",
}

function V2UITheme.battleIcon(kind)
    return battleIcons[kind]
end

local actionFeedbackTitles = {
    accept_call = "召唤已回应",
    select_reinforced_hull = "船装已切换",
    select_heavy_guns = "船装已切换",
    start_voyage = "远航已启程",
    reveal_route_intel = "航线情报已展开",
    choose_safe_route = "安全航线已锁定",
    choose_risky_route = "暗礁近路已锁定",
    rest_at_cove = "避风湾休整完成",
    press_through_cove = "已驶离避风湾",
    rescue_survivors = "幸存者已救起",
    salvage_wreck = "沉船物资已打捞",
    lash_cargo = "货舱已加固",
    ride_black_tide = "已穿过黑潮",
    resist_whisper = "低语已压制",
    listen_whisper = "诅咒交易已接受",
    follow_cursed_compass = "罗盘航向已锁定",
    break_cursed_compass = "诅咒罗盘已摧毁",
    gunner_mark_deck = "甲板弱点已标记",
    fire_at_deck = "齐射命中甲板",
    fire_at_guns = "齐射压制火炮",
    board_now = "接舷战开始",
    boarding_attack = "接舷推进",
    boarding_rush = "强攻完成",
    sailor_guard = "甲板防线已建立",
    medic_heal = "紧急包扎完成",
    retreat = "已脱离战斗",
    take_rune_clue = "符文线索已收录",
    return_to_port = "战利品已入库",
    upgrade_hull = "船体强化完成",
    upgrade_guns = "火炮强化完成",
    promote_gunner = "炮术长任命完成",
    promote_sailor = "大副任命完成",
    retry_battle = "战斗状态已重置",
    recover_at_port = "港口整备完成",
    prepare_next_voyage = "成长已装载",
    restart_chapter = "首航记录已重置",
    choose_tide_breaker = "破潮水道已锁定",
    choose_tide_cannon = "炮门航道已锁定",
    tide_barrage = "远距齐射命中潮盾",
    tide_ram = "守卫潮锚已撞击",
    take_tide_rune = "第二枚符文已收录",
    return_from_tide = "潮汐墓场航程完成",
    port_resupply = "航海补给已入库",
    claim_harbor_relief = "应急补给已领取",
}

function V2UITheme.actionFeedbackTitle(actionId, nextStage)
    return actionFeedbackTitles[actionId] or (V2UITheme.stageKind(nextStage) .. "已更新")
end

function V2UITheme.feedbackChanges(before, after)
    local descriptors = {
        { key = "gold", label = "金币" },
        { key = "timber", label = "木材" },
        { key = "iron", label = "铁料" },
        { key = "provisions", label = "补给" },
        { key = "rune_dust", label = "符文" },
        { key = "voyage_hull_damage", label = "航行损伤" },
        { key = "ship_hull_max", label = "最大耐久" },
        { key = "ship_gun_level", label = "火炮等级" },
        { key = "enemy_ship_hp", label = "敌舰" },
        { key = "player_hull", label = "船体" },
        { key = "deck_damage", label = "甲板破坏" },
        { key = "gun_damage", label = "火炮压制" },
        { key = "enemy_boarding_hp", label = "敌军" },
        { key = "crew_hp", label = "接舷队" },
        { key = "crew_hp_max", label = "接舷上限" },
        { key = "tide_shield", label = "潮盾" },
    }
    local changes = {}
    for _, descriptor in ipairs(descriptors) do
        local delta = (after[descriptor.key] or 0) - (before[descriptor.key] or 0)
        if delta ~= 0 then
            table.insert(changes, string.format("%s %s%d", descriptor.label, delta > 0 and "+" or "", delta))
        end
    end
    return changes
end

local function stateDelta(before, after, key)
    return (after[key] or 0) - (before[key] or 0)
end

local function signedValue(value)
    return string.format("%s%d", value > 0 and "+" or "", value)
end

function V2UITheme.sceneFeedbackItems(actionId, before, after)
    local items = {}
    local function add(target, lane, label, value, accent, effect)
        table.insert(items, {
            target = target,
            lane = lane,
            label = label,
            value = value,
            accent = accent,
            effect = effect,
        })
    end

    if actionId == "fire_at_deck" or actionId == "fire_at_guns" then
        local enemyLoss = -stateDelta(before, after, "enemy_ship_hp")
        local playerLoss = -stateDelta(before, after, "player_hull")
        if enemyLoss > 0 then
            add("enemy", "primary", "敌舰受损", "-" .. enemyLoss, "danger", "impact")
        end
        local partKey = actionId == "fire_at_deck" and "deck_damage" or "gun_damage"
        local partLabel = actionId == "fire_at_deck" and "甲板破坏" or "火炮压制"
        local partGain = stateDelta(before, after, partKey)
        if partGain > 0 then
            add("enemy", "secondary", partLabel, signedValue(partGain), "gold", "status")
        end
        if playerLoss > 0 then
            add("player", "primary", "我方船体", "-" .. playerLoss, "sea", "impact")
        end
    elseif actionId == "boarding_attack" or actionId == "boarding_rush" then
        local enemyLoss = -stateDelta(before, after, "enemy_boarding_hp")
        local crewLoss = -stateDelta(before, after, "crew_hp")
        if enemyLoss > 0 then
            add("enemy", "primary", "敌方部队", "-" .. enemyLoss, "danger", "impact")
        end
        if crewLoss > 0 then
            add("player", "primary", "接舷队", "-" .. crewLoss, "sea", "impact")
        end
    elseif actionId == "medic_heal" then
        local healed = stateDelta(before, after, "crew_hp")
        if healed > 0 then
            add("player", "primary", "紧急包扎", "+" .. healed, "success", "heal")
        end
    elseif actionId == "sailor_guard" then
        add("player", "primary", "甲板防线", "已就绪", "sea", "guard")
    elseif actionId == "gunner_mark_deck" then
        add("enemy", "primary", "甲板弱点", "已锁定", "gold", "target")
    elseif actionId == "tide_barrage" or actionId == "tide_ram" then
        local shieldLoss = -stateDelta(before, after, "tide_shield")
        local hullLoss = -stateDelta(before, after, "player_hull")
        if shieldLoss > 0 then
            add("enemy", "primary", "守卫潮盾", "-" .. shieldLoss, "purple", "impact")
        end
        if hullLoss > 0 then
            add("player", "primary", "我方船体", "-" .. hullLoss, "sea", "impact")
        end
    end
    return items
end

local function authoredValue(chapterData, group, id, key, fallback)
    local groups = chapterData and chapterData.by_id
    local row = groups and groups[group] and groups[group][id]
    if row == nil then
        return fallback or 0
    end
    if key == nil then
        return row.value or fallback or 0
    end
    return row[key] or fallback or 0
end

function V2UITheme.outcomeGroups(state, chapterData)
    local stage = state.stage
    local hullBonus = authoredValue(chapterData, "balance", "hull_level_bonus")
    local gunBonus = authoredValue(chapterData, "balance", "gun_level_bonus")
    local hullCost = authoredValue(chapterData, "balance", "hull_upgrade_timber_cost")
    local gunCost = authoredValue(chapterData, "balance", "guns_upgrade_iron_cost")
    if stage == "settlement" then
        local battleGold = authoredValue(chapterData, "reward", "reward_battle", "gold")
        local battleTimber = authoredValue(chapterData, "reward", "reward_battle", "timber")
        local battleIron = authoredValue(chapterData, "reward", "reward_battle", "iron")
        local battleRune = authoredValue(chapterData, "reward", "reward_battle", "rune_dust")
        local clueRune = authoredValue(chapterData, "reward", "reward_rune_clue", "rune_dust")
        return {
            { label = "追猎者战利品", value = string.format("金币 +%d\n木材 +%d", battleGold, battleTimber), accent = "gold" },
            { label = "强化物资", value = string.format("铁料 +%d\n符文 +%d", battleIron, battleRune + clueRune), accent = "purple" },
            { label = "返港可选", value = string.format("耐久 +%d\n或齐射 +%d", hullBonus, gunBonus), accent = "sea" },
        }
    elseif stage == "upgrade" then
        local resources = state.resources or {}
        return {
            { label = "当前库存", value = string.format("木材 %d\n铁料 %d", resources.timber or 0, resources.iron or 0), accent = "muted" },
            { label = "船体方案", value = string.format("木材 -%d\n耐久 +%d", hullCost, hullBonus), accent = "sea" },
            { label = "火炮方案", value = string.format("铁料 -%d\n齐射 +%d", gunCost, gunBonus), accent = "gold" },
        }
    elseif stage == "crew_growth" then
        local gunner = authoredValue(chapterData, "crew_upgrade", "crew_upgrade_gunner", "effect_value")
        local sailor = authoredValue(chapterData, "crew_upgrade", "crew_upgrade_sailor", "effect_value")
        return {
            { label = "任命席位", value = "首席船员 1 名\n选择后永久保留", accent = "muted" },
            { label = "炮术长 · 罗克", value = string.format("远距破盾 +%d\n稳定齐射方案", gunner), accent = "gold" },
            { label = "大副 · 米克", value = string.format("撞锚自损 -%d\n稳定近身方案", sailor), accent = "sea" },
        }
    elseif stage == "failed" then
        local retryCost = authoredValue(chapterData, "balance", "retry_supply_cost")
        local recoverCost = authoredValue(chapterData, "balance", "port_recovery_gold_cost")
        return {
            { label = "失利原因", value = tostring(state.failure_reason or "战斗失利"), accent = "danger" },
            { label = "原地重试", value = string.format("补给 -%d\n保留航线", retryCost), accent = "sea" },
            { label = "返港恢复", value = string.format("金币 -%d\n清除损伤", recoverCost), accent = "gold" },
        }
    elseif stage == "complete" then
        local upgradeValue = "船只强化\n已经完成"
        if state.upgrades and state.upgrades.hull then
            upgradeValue = string.format("耐久 +%d\n当前 %d", hullBonus, (state.ship or {}).hull_max or 0)
        elseif state.upgrades and state.upgrades.guns then
            upgradeValue = string.format("齐射 +%d\n火炮等级 %d", gunBonus, (state.ship or {}).gun_level or 0)
        end
        return {
            { label = "本次升级", value = upgradeValue, accent = "success" },
            { label = "线索已确认", value = "第一枚符文\n潮汐墓场", accent = "purple" },
            { label = "下一航程", value = "寻找符文守卫\n准备再次出航", accent = "sea" },
        }
    elseif stage == "tide_settlement" then
        local guardianGold = authoredValue(chapterData, "reward", "reward_tide_guardian", "gold")
        local guardianTimber = authoredValue(chapterData, "reward", "reward_tide_guardian", "timber")
        local guardianIron = authoredValue(chapterData, "reward", "reward_tide_guardian", "iron")
        local guardianRune = authoredValue(chapterData, "reward", "reward_tide_guardian", "rune_dust")
        local clueRune = authoredValue(chapterData, "reward", "reward_tide_rune", "rune_dust")
        return {
            { label = "守卫残骸", value = string.format("金币 +%d\n木材 +%d", guardianGold, guardianTimber), accent = "gold" },
            { label = "强化物资", value = string.format("铁料 +%d\n符文 +%d", guardianIron, guardianRune), accent = "sea" },
            { label = "第二符文", value = string.format("符文 +%d\n线索已确认", clueRune), accent = "purple" },
        }
    elseif stage == "tide_complete" then
        return {
            { label = "航程进度", value = "2 次完成\n2 枚符文", accent = "success" },
            { label = "成长兑现", value = "航线代价\n破盾策略", accent = "sea" },
            { label = "当前边界", value = "后续海域\n仍在制作", accent = "muted" },
        }
    end
    return {}
end

return V2UITheme
