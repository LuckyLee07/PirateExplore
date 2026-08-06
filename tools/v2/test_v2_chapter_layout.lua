package.path = "bin/res/scripts/?.lua;bin/res/scripts/?/init.lua;" .. package.path

local Layout = require "LuaClass/V2ChapterLayout"

local function truthy(value, message)
    if not value then error(message) end
end

local function equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local phone = Layout.build(640, 1390)
equal(phone.compact, false, "tall iPhone uses the full composition")
truthy(phone.top_bar_height - phone.title_y >= 85, "iPhone title clears the Dynamic Island zone")
truthy(phone.action_base_y + phone.action_button_height * 0.5 < phone.card_y,
    "iPhone action row stays below the story card")
truthy(phone.action_button_height >= 44, "iPhone actions meet the minimum touch target")
truthy(phone.objective_panel_height >= 64, "iPhone mission order has a dedicated HUD plate")
truthy(phone.voyage_rail_gap >= 36, "iPhone vertical voyage rail keeps its milestones legible")
truthy(phone.resource_y - phone.resource_chip_height * 0.5 > phone.map_y + 20,
    "iPhone resource rail stays above the voyage progress line")
truthy(phone.art_y + phone.art_height == phone.height - phone.top_bar_height,
    "iPhone scene art meets the compact top bar without a dead band")
truthy(phone.card_y + phone.card_height < phone.map_y - 40,
    "mainstream iPhone reserves the visual middle for scene art")
truthy(phone.action_base_y - phone.story_card_offset + phone.action_button_height * 0.5
        < phone.card_y - phone.story_card_offset,
    "mainstream iPhone story action remains attached to the story sheet")

local se = Layout.build(640, 1138)
truthy(se.card_y + se.card_height < se.map_y - 40,
    "iPhone SE keeps a calm scene gap between route and story sheet")
truthy(se.art_y <= se.card_y,
    "iPhone SE story sheet remains grounded inside the scene")
truthy(se.action_base_y - se.story_card_offset + se.action_button_height * 0.5
        < se.card_y - se.story_card_offset,
    "iPhone SE quiet story actions remain below the shorter story sheet")
truthy(se.story_card_height < se.card_height,
    "iPhone SE non-combat stages reveal more scene art than combat")

local ipad = Layout.build(640, 960)
equal(ipad.compact, true, "4:3 iPad uses the compact composition")
truthy(ipad.card_y > 250, "iPad story card leaves a dedicated action area")
truthy(ipad.action_base_y + ipad.action_button_height * 0.5 < ipad.card_y,
    "iPad first action row stays below the story card")
truthy(ipad.action_button_height >= 44, "iPad actions meet the minimum touch target")
truthy(ipad.action_label_width < ipad.action_button_width,
    "iPad action text stays inside the button")
truthy(ipad.action_base_y - 2 * ipad.action_row_gap - ipad.action_button_height * 0.5
        > ipad.footer_y + ipad.footer_size,
    "iPad third action row stays above the footer")
truthy(ipad.card_battle_y - 38 > ipad.card_result_y + ipad.card_result_size * 2,
    "iPad combat meters stay above the latest-result line")
truthy(ipad.art_y + ipad.art_height == ipad.height - ipad.top_bar_height,
    "iPad scene art meets the compact top bar without a dead band")
truthy(ipad.resource_y - ipad.resource_chip_height * 0.5 > ipad.map_y + 20,
    "iPad resource rail stays above the voyage progress line")
truthy(ipad.card_y + ipad.card_height < ipad.map_y - 40,
    "iPad keeps a calm scene gap between route and story sheet")
truthy(ipad.action_base_y - ipad.story_card_offset + ipad.action_button_height * 0.5
        < ipad.card_y - ipad.story_card_offset,
    "iPad quiet story actions remain below the shorter story sheet")

local ipadA16 = Layout.build(640, 921)
truthy(ipadA16.action_base_y + ipadA16.action_button_height * 0.5
        < ipadA16.card_y,
    "wider iPad combat actions stay below the story sheet")
truthy(ipadA16.action_base_y - 2 * ipadA16.action_row_gap
        - ipadA16.action_button_height * 0.5
        > ipadA16.footer_y + ipadA16.footer_size,
    "wider iPad third combat action row stays above the footer")
truthy(ipadA16.action_base_y - ipadA16.story_card_offset
        + ipadA16.action_button_height * 0.5
        < ipadA16.card_y - ipadA16.story_card_offset,
    "wider iPad quiet story actions stay below the shorter story sheet")

print("V2 chapter responsive layout OK: UI 3.1 structural HUD and touch constraints passed")
