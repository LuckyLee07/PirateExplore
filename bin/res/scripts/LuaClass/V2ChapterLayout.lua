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
            top_bar_height = 96,
            kicker_y = 70,
            title_y = 30,
            title_size = 28,
            profile_y = 70,
            objective_y = height - 132,
            objective_size = 16,
            objective_panel_height = 64,
            resource_y = height - 188,
            resource_size = 13,
            resource_chip_height = 42,
            resource_chip_gap = 0,
            map_y = height - 258,
            voyage_rail_gap = 32,
            art_height = 564,
            art_y = height - 660,
            card_height = 330,
            card_y = height - 629,
            story_card_height = 260,
            story_card_offset = 48,
            card_title_y = 294,
            card_title_size = 20,
            card_meta_y = 294,
            card_meta_size = 12,
            card_narrative_y = 258,
            card_narrative_size = 16,
            card_battle_y = 118,
            card_battle_size = 13,
            card_result_y = 22,
            card_result_size = 12,
            -- Current iPads are slightly wider than legacy 4:3. Tie the
            -- action stack to the short edge so a 640 x 921 canvas keeps the
            -- same gap below the story sheet as a 640 x 960 canvas.
            action_base_y = height - 682,
            action_row_gap = 64,
            action_button_scale = 1.0,
            action_button_width = 276,
            action_button_height = 54,
            action_label_width = 250,
            action_font_size = 14,
            footer_y = 8,
            footer_size = 11,
        }
    end

    return {
        compact = false,
        width = width,
        height = height,
        top_bar_height = 132,
        kicker_y = 98,
        title_y = 30,
        title_size = 32,
        profile_y = 98,
        objective_y = height - 170,
        objective_size = 18,
        objective_panel_height = 70,
        resource_y = height - 230,
        resource_size = 15,
        resource_chip_height = 46,
        resource_chip_gap = 0,
        map_y = height - 294,
        voyage_rail_gap = 38,
        art_height = 611,
        art_y = height - 743,
        card_height = 380,
        -- UI 3.0 is composed around the mainstream tall-iPhone canvas. Keep
        -- the story/action cluster anchored to the lower half while the extra
        -- height belongs to the scene art, not to a growing empty gap.
        card_y = 400,
        story_card_height = 285,
        story_card_offset = 55,
        card_title_y = 330,
        card_title_size = 22,
        card_meta_y = 330,
        card_meta_size = 14,
        card_narrative_y = 292,
        card_narrative_size = 18,
        card_battle_y = 138,
        card_battle_size = 14,
        card_result_y = 26,
        card_result_size = 14,
        action_base_y = 355,
        action_row_gap = 70,
        action_button_scale = 1.0,
        action_button_width = 276,
        action_button_height = 64,
        action_label_width = 250,
        action_font_size = 15,
        footer_y = 10,
        footer_size = 12,
    }
end

return V2ChapterLayout
