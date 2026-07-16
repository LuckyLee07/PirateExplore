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
truthy(phone.action_base_y + 34 < phone.card_y, "iPhone action row stays below the story card")

local ipad = Layout.build(640, 960)
equal(ipad.compact, true, "4:3 iPad uses the compact composition")
truthy(ipad.card_y > 250, "iPad story card leaves a dedicated action area")
truthy(ipad.action_base_y + 28 < ipad.card_y, "iPad first action row stays below the story card")
truthy(ipad.action_base_y - 2 * ipad.action_row_gap - 24 > ipad.footer_y + ipad.footer_size,
    "iPad third action row stays above the footer")
truthy(ipad.card_battle_y > ipad.card_result_y + ipad.card_result_size,
    "iPad battle metrics stay above the latest-result line")
truthy(ipad.art_y + ipad.art_height < ipad.map_y + 6,
    "iPad hero art stays below the route strip")

print("V2 chapter responsive layout OK: iPhone safe-area and iPad compact constraints passed")
