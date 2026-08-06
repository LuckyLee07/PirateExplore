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
    complete = "success",
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
    complete = "首航完成",
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
    complete = 5,
}

V2UITheme.progress_labels = { "港口", "航线", "异象", "追猎者", "符文" }

local forwardActions = {
    accept_call = true,
    start_voyage = true,
    board_now = true,
    take_rune_clue = true,
    return_to_port = true,
    restart_chapter = true,
}

local utilityActions = {
    reveal_route_intel = true,
    gunner_mark_deck = true,
    sailor_guard = true,
    medic_heal = true,
}

local dangerActions = {
    retreat = true,
    ride_black_tide = true,
    boarding_rush = true,
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
    if stage == "upgrade" or stage == "route_choice" or stage == "harbor" then
        return "choice"
    end
    if actionIndex == 1 and actionCount > 2 then
        return "primary"
    end
    return "choice"
end

function V2UITheme.resourceItems(resources)
    return {
        { name = "金币", value = resources.gold, accent = "gold" },
        { name = "木材", value = resources.timber, accent = "success" },
        { name = "铁料", value = resources.iron, accent = "muted" },
        { name = "补给", value = resources.provisions, accent = "sea" },
        { name = "符文", value = resources.rune_dust, accent = "purple" },
    }
end

return V2UITheme
