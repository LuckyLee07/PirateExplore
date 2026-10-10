# Upgrade material sources

## Scope

The existing Home upgrade plaque and target/cost logic remain intact. Each unfinished goal has a voluntary 材料来源 action when its current recipe or forge prerequisite has shortages. This replaces the goal dialog with up to three shortage rows; 返回升级 returns to the choices and 关闭 dismisses. Navigation never buys, crafts, staffs workers, grants materials or changes unlocks. Existing manufacturing/building actions remain available.

Source selection uses current state, again at click time:

- Coins: original warehouse/alchemy page, with manual alchemy explicitly stated.
- Stone and wood: original resource/Gather page after its warehouse gate; original cooldown retained.
- Cloth/iron: saved market item must match its actual CSV store row, and market guide gate 104 in the secondary namespace must be open. The hint shows actual unit price and full current shortage cost, including when funds are insufficient. Clicking opens the original market focused on that material; purchasing remains a separate action.
- If no usable market route exists, production requires a saved unlocked worker, matching output in worker CSV, and a built saved prerequisite identified by its build CSV worker unlock. For early iron this is iron mine 61 and iron worker 5. Copy names the built mine, current assigned worker count and the original per-worker/per-cycle input cost. Viewing production does not guarantee sufficient food or workers and does not assign anyone.
- Locked market, absent listing, or unknown sources have explanatory text and disabled navigation. No invented cloth recipe or loot location is supplied.

Packaged CSV evidence: cloth 1018 / store 4 costs 2 gold each; iron 1008 / store 6 costs 3 each. Iron worker 5 consumes 2 food for 1 iron, unlocked by built iron mine 61. No worker or manufacturing output provides cloth. Market presence and production prerequisites are checked from the save, rather than inferred from price/CSV existence.

`Dispatch:gotoStore(boolean, optionalResourceId)` and `StoreLayer:create(boolean, optionalResourceId)` preserve all existing no-argument/boolean callers. Focus only changes the clamped view offset and never sorts saved entries.

## Validation

Passed with `build/linux/tests/lua-ui-tests`:

- `tools/tests/harbor_goals_regression.lua`: actual encrypted CSV decoding; exact 10-gold cloth / 15-gold iron shortages; market gate/entry mismatch; absent listings; worker and building prerequisites; unknown sources; original forge/make goals; live and click-time gate changes; fulfilled shortages; modal swap/back/close/reentry/destruction; no spending; clamped focus; actual Dispatch old/new signatures; 480×800 and 540×900 mocked geometry bounds.
- `tools/tests/home_master_regression.lua`: full event registration/single-refresh/unregistration matrix including market, production and workforce events; unchanged first-dock/free-crew and Home navigation contracts.
- `tools/tests/crew_recovery_regression.lua`: crew-recovery precedence, stale-click protection and original recruitment/building costs.
- `tools/tests/management_ui_regression.lua`: existing market purchase dialogs and management UI contracts.

These are source/model/callback and mocked geometry checks, not native visual acceptance. The shared aggregate runner is owned by the parent integration task. Native owner should verify the two supported portrait sizes, readable shortage/source text, focused cloth/iron market rows, back/close with no stacked dialogs, filled shortage removal, and the absence of purchases from navigation alone. The market-locked/unknown and production-fallback branches have controlled test coverage; natural play is not claimed for them.

## Market purchase eligibility audit

Coverage is intentionally bounded to initial cargo 1148, apprentice furnace 1176 and their forge 57 prerequisite, whose materials are coins, wood, stone, cloth and iron. This is not a universal acquisition planner for premium items or limited equipment.

The original StoreMode creates a single-buy button for every saved market row. Its `cheackResoucesOK` compares resource `price × quantity` against resource 1001 (gold), and `useResouces` spends gold. It has no separate `onlyProduce` or `diamond` eligibility branch. `limits == 1` prevents the long-press bulk action; after a purchase, DataManager decrements positive saved limits and removes exhausted rows. Thus a price alone is insufficient evidence of an available listing, but a valid currently displayed early-material market entry is a gold purchase.

Actual cloth 1018 and iron 1008 both have `limits = -1`, `onlyProduce = 0`, and an empty diamond field. Tests assert these packaged facts in addition to price, gate and saved-entry matching. A locked market and mismatched saved sortId are checked both as unavailable model results and as blocked navigation at click time. No runtime behavior was changed by this audit.

## Source footer touch separation

Native review found the previous centered 132×32 Back action at y=84 overlapped the unchanged legacy 176×61 Close target centered at (286,50). Back now sits at (96,50), with bounds x=30–162 / y=34–66. Close remains x=198–374 / y=19.5–80.5, leaving 36 design pixels of horizontal separation. The third source description ends at y=105, above both controls. Tests read the real PNG dimensions through `DialogTheme.legacySize` and assert this clearance at both supported portrait viewport classes. Native cold-start revalidation is requested; earlier center-tap success is not evidence of non-overlapping touch areas.
