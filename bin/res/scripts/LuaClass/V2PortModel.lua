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
    complete = { label = "首航完成", detail = "新的远航目标已经记录", accent = "success" },
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

function V2PortModel.section(sectionId)
    for _, section in ipairs(V2PortModel.sections) do
        if section.id == sectionId then
            return section
        end
    end
    return V2PortModel.sections[1]
end

function V2PortModel.status(state)
    return copy(stageStatus[state.stage] or stageStatus.harbor)
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
    for index, crewId in ipairs(state.crew or {}) do
        local crew = rowById(data, "crew", crewId)
        if crew ~= nil then
            local action = rowById(data, "battle_action", crew.active_action)
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
            })
        end
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
    local provisions = (state.resources or {}).provisions or 0
    return {
        { label = "船只", value = ship.selected_module, ready = ship.hull_max > 0 },
        { label = "船员", value = string.format("%d / 4 就位", #crew), ready = #crew == 4 },
        { label = "补给", value = string.format("%d 份", provisions), ready = provisions > 0 },
    }
end

local actionsBySection = {
    chart = {
        start_voyage = true,
        return_to_port = true,
    },
    ship = {
        select_reinforced_hull = true,
        select_heavy_guns = true,
        upgrade_hull = true,
        upgrade_guns = true,
    },
    cargo = {
        return_to_port = true,
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
        or actionId == "upgrade_hull"
        or actionId == "upgrade_guns"
end

return V2PortModel
