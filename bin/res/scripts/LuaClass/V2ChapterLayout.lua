-- Pure layout model for the V2 chapter screen.
--
-- The iPhone canvas is tall enough for the authored 640-point composition,
-- while a 4:3 iPad resolves to a much shorter 640 x 960 canvas. Keep the
-- measurements here independent from Cocos so overlap constraints can be
-- covered by command-line regression tests.

local V2ChapterLayout = {}

function V2ChapterLayout.build(width, height)
    local compact = height < 1050
    if compact then
        return {
            compact = true,
            width = width,
            height = height,
            top_bar_height = 104,
            kicker_y = 78,
            title_y = 40,
            title_size = 30,
            profile_y = 78,
            objective_y = height - 120,
            objective_size = 18,
            resource_y = height - 166,
            resource_size = 16,
            map_y = height - 226,
            art_height = 310,
            art_y = height - 565,
            card_height = 300,
            card_y = height - 585,
            card_title_y = 282,
            card_title_size = 23,
            card_meta_y = 246,
            card_meta_size = 14,
            card_narrative_y = 210,
            card_narrative_size = 16,
            card_battle_y = 70,
            card_battle_size = 16,
            card_result_y = 15,
            card_result_size = 14,
            action_base_y = 195,
            action_row_gap = 72,
            action_button_scale = 1.28,
            action_font_size = 14,
            footer_y = 4,
            footer_size = 12,
        }
    end

    return {
        compact = false,
        width = width,
        height = height,
        -- The larger top bar places the long chapter title below Dynamic
        -- Island/notch occlusion while the left-aligned kicker stays above it.
        top_bar_height = 145,
        kicker_y = 115,
        title_y = 28,
        title_size = 34,
        profile_y = 115,
        objective_y = height - 166,
        objective_size = 21,
        resource_y = height - 218,
        resource_size = 18,
        map_y = height - 292,
        art_height = 540,
        art_y = height - 860,
        card_height = 470,
        card_y = height - 835,
        card_title_y = 446,
        card_title_size = 28,
        card_meta_y = 402,
        card_meta_size = 17,
        card_narrative_y = 358,
        card_narrative_size = 19,
        card_battle_y = 126,
        card_battle_size = 19,
        card_result_y = 22,
        card_result_size = 17,
        action_base_y = 270,
        action_row_gap = 92,
        action_button_scale = 1.55,
        action_font_size = 15,
        footer_y = 18,
        footer_size = 15,
    }
end

return V2ChapterLayout
