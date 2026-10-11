# Focused forge construction

The clean Home → 改装 → missing iron forge route already passes build ID `57`
through `WarmActivities.route` and `Dispatch:gotoBuild`. `BuildLayer` now uses
that optional target for a quiet full-screen construction detail rather than
opening the complete harbor dashboard at a scroll position.

## Scope and preservation

- The detail uses the target's actual `build.csv` `name`, `iconName` and `resume`
  recipe. Forge `57` remains 25 coins, 15 stone and 2 iron. Each material displays
  current stock / required stock, with shortages visibly distinguished.
- One build action and a clear “返回船上” action replace the unrelated utility
  strip. Existing `approvedPage` / `keepNavigation` hooks hide shared currency
  controls and duplicate Back. No store, alchemy, talents, intelligence or system
  feed is created for the focused page.
- No focused table replaces or sorts `roleBuildingData`. The complete list stays
  owned by the existing DataManager, including previously built entries.
- The build click rechecks the real unlocked row, guide gate and current stock,
  then invokes the unchanged `cheackResoucesOK`, `useResouces` and
  `createSuccessCheck(kUnlockBuild,id)` transaction methods. The existing
  `Lackmaterial` flow remains explicit when stock is short. Opening, refreshing,
  focusing or going Back never buys, deducts, constructs or saves.
- Native button generations, current built state, modal presence and disposal
  checks prevent stale clicks from spending or constructing twice. Four focused
  subscriptions are removed on Back/cleanup; mid-transaction stock events do not
  replace the clicked native button.
- Ordinary `BuildLayer:create()` and `WARM_PIRATE_V1=false` continue through the
  untouched full-list constructor, original utility callbacks and scroll focus.
  MainMenu, BaseView, Dispatch, economy and persistence code were not edited.

## Verification

Passed with `/workspace/shared/lua51`:

- `tools/tests/coherent_forge_regression.lua`: route split, unchanged original
  full-list/opt-out boundaries, retained complete building list, transaction
  owner/call order, late guide gates, modal guards and no automatic purchase.
- `tools/tests/harbor_goals_regression.lua`: actual shipped recipes, existing
  Home/goal/focus/source navigation, unlock gates and no read-only mutation.
- `tools/tests/management_ui_regression.lua`: original resource costs, bulk
  purchase/sale interactions, filters and original management callback checks.

Passed using the existing `build/linux/tests/tutorial-log-native` Cocos/EGL
harness and sourced `linux-runtime/env.sh`:

- `tools/tests/coherent_forge_native.lua`: actual BuildLayer/BaseView, shipped
  forge icon and data, CleanVoyageSans text and button bounds at 480×800, 540×900,
  640×960, 640×1067 and 720×1280. Covers exact costs, read-only opening, current
  shortages, live refresh, deduction/unlock call order, repeated/stale native
  clicks, other current buildings retained, unknown/locked targets, Back and
  listener cleanup.

The native economy/unlock boundary uses isolated in-memory spies. It is not a
second natural fresh-save playthrough and does not replace the reviewer’s real
route/screenshot acceptance. No GUI instance was opened or restarted, no player
profile was touched, and no publishing was performed by this focused change.

Also passed: Lua source parsing, `heading_font_coverage_regression.py`, and
`git diff --check` for these files.
