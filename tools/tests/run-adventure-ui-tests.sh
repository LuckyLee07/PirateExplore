#!/usr/bin/env bash
# Native Lua logic smoke tests; these do not replace the documented GUI checks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
LUA="${LUA_BIN:-}"
if [[ -z "$LUA" ]]; then
  for candidate in lua5.1 lua; do
    if command -v "$candidate" >/dev/null; then LUA="$(command -v "$candidate")"; break; fi
  done
fi
if [[ -z "$LUA" ]]; then
  BUILD="${PIRATE_BUILD_DIR:-$ROOT/build/linux}"
  if [[ ! -f "$BUILD/lib/liblua.a" ]]; then
    echo 'Build the native Linux target first, or set LUA_BIN to a Lua 5.1 interpreter.' >&2
    exit 1
  fi
  mkdir -p "$BUILD/tests"
  cc -I src/engine/cocos2d-x/external/lua/lua \
    src/engine/cocos2d-x/external/lua/lua/lua.c "$BUILD/lib/liblua.a" \
    -lm -ldl -o "$BUILD/tests/lua-ui-tests"
  LUA="$BUILD/tests/lua-ui-tests"
fi
"$LUA" -e 'for _,f in ipairs({"BTheme","HomeTheme","MasterTheme","Home","HarborGoals","CrewRecovery","LocalProduction","MainMenu","Dispatch","Expedition","DepartureTheme","Explore","SeaChartTheme","SeaChartWorldTheme","SeaChartSlice","Talent","ToastUtil","NotificationNode","ManagementTheme","DialogTheme","CombatTheme","ResourceTheme","ItemIcon","CrewSkillDetails","EventDetailsLayer","TrainMode","PurchaseAvailability","StartupTheme","WorldMapLayer","EventLayer","FightMode","Update","LoadingScene"}) do assert(loadfile("bin/res/scripts/LuaClass/"..f..".lua")); print("PARSE PASS "..f) end'
for test in crew_recovery_regression loot_capacity_regression large_crew_portrait_regression gather_cooldown_regression local_production_regression local_production_integration harbor_goals_regression refined_icons_regression management_ui_regression dialog_theme_regression dialogue_lifecycle_regression home_master_regression static_home_art_regression home_polish_regression expedition_ui_regression explore_hud_smoke food_warning_regression talent_ui_regression intelligence_expiry_regression quest_reward_regression tutorial_lifecycle_regression onboarding_navigation_regression alchemy_feedback_regression toast_stack_regression auxiliary_ui_regression item_icon_offer_regression crew_skill_details_regression purchase_availability_regression material_caption_regression chest_footer_regression resource_theme_regression sea_chart_camera_regression sea_chart_slice_regression sea_slice_event_regression; do
  "$LUA" "tools/tests/$test.lua"
done

python3 tools/tests/draw_triangle_regression.py
python3 tools/tests/sea_chart_renderer_regression.py
python3 tools/tests/sea_chart_coast_renderer_regression.py
python3 tools/tests/sea_chart_world_regression.py "$LUA"

python3 tools/tests/tile_flags_binding_regression.py
python3 tools/tests/sea_event_semantics_regression.py

python3 tools/tests/remaining_art_semantics_regression.py

python3 tools/tests/viewport_pixel_regression.py

python3 tools/tests/sea_chart_atlas_sampling_regression.py

python3 tools/tests/build_entry_regression.py
python3 tools/tests/occupied_event_copy_regression.py "$LUA"

python3 tools/tests/run_atomic_save_regression.py

python3 tools/tests/refined_icon_assets_regression.py

python3 tools/tests/large_crew_assets_regression.py

python3 tools/tests/missing_item_icons_regression.py "$LUA"
