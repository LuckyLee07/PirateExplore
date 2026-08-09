-- Pure presentation model for the V2 Royal Port preparation surface.
--
-- The port reads the same chapter save and generated content tables as the
-- voyage. It never owns economy or upgrade rules; actionable rows are filtered
-- from V2ChapterState.getActions so there is still one gameplay authority.

local V2PortModel = {}

V2PortModel.sections = {
    { id = "chart", index = "01", label = "航海桌", caption = "目标与出航", icon = "Images/V2/Icons/resource-rune.png" },
    { id = "ship", index = "02", label = "船只", caption = "模块与强化", icon = "Images/V2/Icons/battle-hull.png" },
    { id = "crew", index = "03", label = "船员", caption = "技能与特性", icon = "Images/V2/Icons/battle-crew.png" },
    { id = "cargo", index = "04", label = "货舱", caption = "库存与用途", icon = "Images/V2/Icons/resource-provisions.png" },
}

local roleLabels = {
    gunner = "炮手",
    sailor = "水手",
    navigator = "航海士",
    medic = "医师",
}

local roleAccents = {
    gunner = "danger",
    sailor = "gold",
    navigator = "sea",
    medic = "success",
}

local stageStatus = {
    opening = { label = "召唤待回应", detail = "先确认瓶中召唤，再进入皇家港整备", accent = "muted" },
    harbor = { label = "可以出航", detail = "船只、四名船员与基础补给已经就绪", accent = "success" },
    route_choice = { label = "远航进行中", detail = "正在瓶中海域选择航线", accent = "sea" },
    route_event = { label = "远航进行中", detail = "当前航线出现待处理事件", accent = "sea" },
    black_tide = { label = "海况危险", detail = "黑潮正在影响本次远航", accent = "danger" },
    whisper = { label = "诅咒活动", detail = "海盗王的低语正在影响船员", accent = "purple" },
    curse_choice = { label = "诅咒活动", detail = "必须处理失控的诅咒罗盘", accent = "purple" },
    naval = { label = "舰炮交火", detail = "追猎者正在阻断当前航线", accent = "danger" },
    boarding = { label = "接舷交战", detail = "接舷队正在争夺敌方甲板", accent = "danger" },
    failed = { label = "需要恢复", detail = "远航受挫，可重试或返港恢复", accent = "danger" },
    rune_clue = { label = "发现符文", detail = "第一枚符文线索等待确认", accent = "purple" },
    settlement = { label = "等待返港", detail = "战利品已经清点，可以返回皇家港", accent = "gold" },
    upgrade = { label = "可以强化", detail = "本次战利品足够完成首次船只升级", accent = "gold" },
    crew_growth = { label = "等待任命", detail = "选择一名首席船员，让专长进入下一次远航", accent = "sea" },
    complete = { label = "首航完成", detail = "新的远航目标已经记录", accent = "success" },
    tide_route_choice = { label = "墓场航线", detail = "成长正在改变两条航道的实际代价", accent = "sea" },
    tide_character_event = { label = "墓场求救火", detail = "首席船员正在提出两种互斥处理方案", accent = "gold" },
    tide_guardian = { label = "潮盾交战", detail = "沉锚守卫要求用船体或火炮成长破盾", accent = "danger" },
    tide_rune_clue = { label = "第二符文", detail = "沉锚符文等待收入水晶瓶", accent = "purple" },
    tide_settlement = { label = "等待返港", detail = "第二次远航的符文与残骸已经清点", accent = "gold" },
    tide_complete = { label = "墓场完成", detail = "第二次远航完成，已取得两枚符文", accent = "success" },
}

local function rowById(data, group, id)
    local byId = data and data.by_id
    return byId and byId[group] and byId[group][id] or nil
end

local function balanceValue(data, id)
    local row = rowById(data, "balance", id)
    return row and row.value or 0
end

local function copy(item)
    local result = {}
    for key, value in pairs(item or {}) do
        result[key] = value
    end
    return result
end

local function crewUpgradeEffectText(upgrade)
    if upgrade == nil then return nil end
    local sign = upgrade.effect_kind == "ram_hull_reduction" and "-" or "+"
    return string.format("%s %s%d", upgrade.effect_label, sign, upgrade.effect_value)
end

function V2PortModel.section(sectionId)
    for _, section in ipairs(V2PortModel.sections) do
        if section.id == sectionId then
            return section
        end
    end
    return V2PortModel.sections[1]
end

function V2PortModel.logistics(state, data)
    local resources = state.resources or {}
    local module = rowById(data, "ship_module", state.selected_module) or {}
    local capacity = balanceValue(data, "initial_provisions")
        + (module.supply_capacity_modifier or 0)
    local provisions = resources.provisions or 0
    local beginsTideVoyage = state.chapter_complete
        and not (state.flags or {}).tide_voyage_complete
        and (state.voyage_count or 0) + 1 >= 2
    local edge = rowById(data, "map_edge", beginsTideVoyage and "edge_10" or "edge_01") or {}
    local departureCost = edge.supply_cost or 0
    local resupplyCost = balanceValue(data, "port_resupply_gold_cost")
    local missingToFull = math.max(0, capacity - provisions)
    local actualGain = math.min(balanceValue(data, "port_resupply_gain"), missingToFull)
    local blocked = provisions < departureCost
    local canResupply = state.stage == "harbor"
        and actualGain > 0
        and (resources.gold or 0) >= resupplyCost
    local canClaimRelief = state.stage == "harbor"
        and blocked
        and (resources.gold or 0) < resupplyCost
        and not (state.flags or {}).harbor_relief_used
    local status = blocked and "blocked" or (missingToFull > 0 and "low" or "ready")
    local label = blocked and "补给不足" or (status == "low" and "可以离港 · 储备偏低" or "补给舱已满")
    local accent = blocked and "danger" or (status == "low" and "gold" or "success")
    local detail
    if canClaimRelief then
        detail = "金币不足，可领取一次免费应急补给，保证本次离港。"
    elseif blocked then
        detail = string.format("购买航海补给需要 %d 金币，本次可增加 %d 份。", resupplyCost, actualGain)
    elseif provisions > capacity then
        detail = string.format("当前船装最多装载 %d 份；库存超出的 %d 份不会随船出航。", capacity, provisions - capacity)
    elseif status == "low" then
        detail = string.format("离港需要 %d 份；也可花 %d 金币补充 %d 份。", departureCost, resupplyCost, actualGain)
    else
        detail = string.format("离港需要 %d 份，当前船装的补给容量已经装满。", departureCost)
    end
    return {
        capacity = capacity,
        provisions = provisions,
        loaded = math.min(provisions, capacity),
        departure_cost = departureCost,
        missing_to_depart = math.max(0, departureCost - provisions),
        missing_to_full = missingToFull,
        resupply_cost = resupplyCost,
        resupply_gain = actualGain,
        relief_gain = balanceValue(data, "port_relief_gain"),
        can_resupply = canResupply,
        can_claim_relief = canClaimRelief,
        status = status,
        label = label,
        detail = detail,
        accent = accent,
    }
end

function V2PortModel.status(state, data)
    local status = copy(stageStatus[state.stage] or stageStatus.harbor)
    if state.stage == "harbor" and data ~= nil then
        local logistics = V2PortModel.logistics(state, data)
        if logistics.status == "blocked" then
            status.label = "航程受阻"
            status.detail = "补给不足；前往货舱处理港务补给后即可离港"
            status.accent = "danger"
        elseif logistics.status == "low" then
            status.label = "可以出航 · 储备偏低"
            status.detail = "当前满足离港门槛；货舱可补足后续航程储备"
            status.accent = "gold"
        end
    end
    if state.stage == "harbor"
        and (state.voyage_count or 0) > 0
        and (data == nil or V2PortModel.logistics(state, data).status == "ready") then
        status.detail = string.format("第 %d 次远航准备中；船只成长、库存与符文线索已保留", state.voyage_count + 1)
    end
    return status
end

function V2PortModel.ship(state, data)
    local selected = rowById(data, "ship_module", state.selected_module)
    local modules = {}
    for _, module in ipairs(data.ship_module or {}) do
        table.insert(modules, {
            id = module.id,
            name = module.name,
            effect = module.effect,
            tradeoff = module.tradeoff,
            hull_bonus = module.hull_bonus or 0,
            cannon_bonus = module.cannon_bonus or 0,
            supply_modifier = module.supply_capacity_modifier or 0,
            selected = module.id == state.selected_module,
            accent = module.id == "module_heavy_guns" and "danger" or "sea",
        })
    end
    return {
        name = "皇家港旗舰",
        selected_module = selected and selected.name or "未装配",
        selected_effect = selected and selected.effect or "等待装配",
        hull_max = (state.ship or {}).hull_max or 0,
        hull_level = (state.ship or {}).hull_level or 0,
        gun_level = (state.ship or {}).gun_level or 0,
        voyage_damage = state.voyage_hull_damage or 0,
        voyages = state.voyage_count or 0,
        modules = modules,
        hull_upgrade = {
            cost = balanceValue(data, "hull_upgrade_timber_cost"),
            gain = balanceValue(data, "hull_level_bonus"),
        },
        gun_upgrade = {
            cost = balanceValue(data, "guns_upgrade_iron_cost"),
            gain = balanceValue(data, "gun_level_bonus"),
        },
    }
end

function V2PortModel.crew(state, data)
    local result = {}
    local promotions = {}
    for _, promotion in ipairs(data.crew_upgrade or {}) do
        promotions[promotion.crew_id] = promotion
    end
    for index, crewId in ipairs(state.crew or {}) do
        local crew = rowById(data, "crew", crewId)
        if crew ~= nil then
            local action = rowById(data, "battle_action", crew.active_action)
            local promotion = promotions[crew.id]
            local activeDetail = action and action.description or nil
            if crew.active_action == "reveal_route_intel" then
                activeDetail = string.format("消耗 %d 份补给，揭示两条航线的风险与后果", balanceValue(data, "navigator_intel_cost"))
            end
            table.insert(result, {
                id = crew.id,
                index = string.format("%02d", index),
                name = crew.name,
                role = roleLabels[crew.role] or crew.role,
                role_id = crew.role,
                active_skill = crew.active_skill,
                active_action = crew.active_action,
                active_detail = activeDetail or "在对应远航阶段开放",
                passive_trait = crew.passive_trait,
                accent = roleAccents[crew.role] or "sea",
                promotion_id = promotion and promotion.id or nil,
                promotion_title = promotion and promotion.title or nil,
                promotion_effect = crewUpgradeEffectText(promotion),
                promoted = promotion ~= nil and (state.upgrades or {}).crew == promotion.id,
            })
        end
    end
    return result
end

function V2PortModel.crewUpgrades(state, data)
    local result = {}
    for _, promotion in ipairs(data.crew_upgrade or {}) do
        local crew = rowById(data, "crew", promotion.crew_id) or {}
        table.insert(result, {
            id = promotion.id,
            crew_id = promotion.crew_id,
            action_id = promotion.action_id,
            name = crew.name or promotion.crew_id,
            role = roleLabels[crew.role] or crew.role,
            title = promotion.title,
            effect = crewUpgradeEffectText(promotion),
            description = promotion.description,
            active_skill = crew.active_skill,
            strategy = promotion.effect_kind == "barrage_damage"
                and "沉锚守卫 · 远距齐射"
                or "沉锚守卫 · 撞断潮锚",
            strategy_icon = promotion.effect_kind == "barrage_damage"
                and "Images/V2/Icons/battle-cannon.png"
                or "Images/V2/Icons/battle-hull.png",
            accent = promotion.accent or roleAccents[crew.role] or "sea",
            selected = (state.upgrades or {}).crew == promotion.id,
        })
    end
    return result
end

function V2PortModel.cargo(state, data)
    local result = {}
    local resources = state.resources or {}
    for _, resource in ipairs(data.resource or {}) do
        table.insert(result, {
            id = resource.id,
            name = resource.name,
            value = resources[resource.id] or 0,
            primary_use = resource.primary_use,
            secondary_use = resource.secondary_use,
        })
    end
    return result
end

function V2PortModel.readiness(state, data)
    local ship = V2PortModel.ship(state, data)
    local crew = V2PortModel.crew(state, data)
    local logistics = V2PortModel.logistics(state, data)
    return {
        { label = "船只", value = ship.selected_module, ready = ship.hull_max > 0 },
        { label = "船员", value = string.format("%d / 4 就位", #crew), ready = #crew == 4 },
        { label = "补给", value = string.format("%d / %d 份", logistics.loaded, logistics.capacity), ready = logistics.missing_to_depart == 0 },
    }
end

local actionsBySection = {
    chart = {
        start_voyage = true,
        return_to_port = true,
        return_from_tide = true,
        prepare_next_voyage = true,
    },
    ship = {
        select_reinforced_hull = true,
        select_heavy_guns = true,
        upgrade_hull = true,
        upgrade_guns = true,
    },
    crew = {
        promote_gunner = true,
        promote_sailor = true,
    },
    cargo = {
        return_to_port = true,
        return_from_tide = true,
        port_resupply = true,
        claim_harbor_relief = true,
    },
}

function V2PortModel.actions(sectionId, actions)
    local allowed = actionsBySection[sectionId] or {}
    local result = {}
    for _, action in ipairs(actions or {}) do
        if allowed[action.id] then
            table.insert(result, copy(action))
        end
    end
    return result
end

function V2PortModel.returnsToVoyage(actionId)
    return actionId == "start_voyage"
        or actionId == "return_to_port"
        or actionId == "return_from_tide"
        or actionId == "upgrade_hull"
        or actionId == "upgrade_guns"
end

return V2PortModel
