-- Shared visual contract for the V2 Chapter 1 presentation.
--
-- Keep this module independent from Cocos so its semantic decisions can be
-- regression-tested from the command line. V2ChapterLayer converts the RGB
-- tables to engine colours at the rendering boundary.

local V2UITheme = {}

V2UITheme.colors = {
    shell = { 7, 20, 29 },
    shell_raised = { 12, 35, 44 },
    surface = { 10, 31, 39 },
    surface_soft = { 23, 48, 54 },
    ink = { 247, 238, 211 },
    muted = { 174, 190, 184 },
    gold = { 235, 183, 78 },
    sea = { 91, 189, 190 },
    danger = { 226, 92, 77 },
    purple = { 171, 119, 205 },
    success = { 102, 190, 142 },
    track = { 37, 58, 62 },
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
