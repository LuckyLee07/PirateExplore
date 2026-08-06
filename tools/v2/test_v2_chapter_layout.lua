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
truthy(phone.top_bar_height - phone.title_y >= 105, "iPhone title clears the Dynamic Island zone")
truthy(phone.action_base_y + phone.action_button_height * 0.5 < phone.card_y,
    "iPhone action row stays below the story card")
truthy(phone.action_button_height >= 44, "iPhone actions meet the minimum touch target")
truthy(phone.resource_y - phone.resource_chip_height > phone.map_y + 48,
    "iPhone resource chips stay above the voyage progress strip")

local ipad = Layout.build(640, 960)
equal(ipad.compact, true, "4:3 iPad uses the compact composition")
truthy(ipad.card_y > 250, "iPad story card leaves a dedicated action area")
truthy(ipad.action_base_y + ipad.action_button_height * 0.5 < ipad.card_y,
    "iPad first action row stays below the story card")
truthy(ipad.action_button_height >= 44, "iPad actions meet the minimum touch target")
truthy(ipad.action_label_width < 128 * ipad.action_button_scale,
    "iPad action text stays inside the scaled button")
truthy(ipad.action_base_y - 2 * ipad.action_row_gap - ipad.action_button_height * 0.5
        > ipad.footer_y + ipad.footer_size,
    "iPad third action row stays above the footer")
truthy(ipad.card_battle_y - ipad.card_battle_size * 3
        > ipad.card_result_y + ipad.card_result_size,
    "iPad three-line combat feedback stays above the latest-result line")
truthy(ipad.art_y + ipad.art_height < ipad.map_y + 6,
    "iPad hero art stays below the route strip")
truthy(ipad.resource_y - ipad.resource_chip_height >= ipad.map_y + 48,
    "iPad resource chips stay above the voyage progress strip")

print("V2 chapter responsive layout OK: iPhone safe-area and iPad compact constraints passed")
