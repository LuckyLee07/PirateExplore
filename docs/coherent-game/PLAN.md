# Coherent game presentation plan

Baseline: published ca9d4f397ea15731937f21187be6df799af68b8f, exact tree 2a3c24b18c8e48b0f7ee53f9e85944f66bdcc8c1. Local work branch: codex/coherent-game-v2. No new engine, economy, free sailing, save reset, or migration.

## Screen and navigation inventory

- Entry / original story / tutorial → MainMenu/Dispatch → WarmHome.
- Home → preparation (WarmDeparture + Expedition) → original guarded departure → Explore. New-profile map 1 uses CleanVoyageView/HUD; existing saves and later chapters retain their map renderer.
- Explore → actual events / AdventureDialog / WarmDialog; original encounters → FightMode / CombatTheme; actual loot → FightRewardScene / DialogTheme; bag, chart, pause, settings, return quote and resume are owner-bound overlays.
- Successful return → original settlement → WarmReturnResult → Home. Failure/no-food retains original losses/recovery.
- Home → crew / profession detail / ship upgrades / material sources / inventory / current route clues (WarmActivities); permanent keepsakes, display and actual voyage history (WarmCollection); direct recipe confirmation (WarmUpgrade).
- Home → ship business → original build, make, gather, repository/alchemy, store, training/talent, achievements, ranking, diamonds/gift utility pages. MainMenu framing + ManagementTheme and DialogTheme support these routes.
- Settings/help, pause/checkpoint, resumed voyage, confirmation, shortage and empty states must read as part of the same game.

## Priorities and batch ownership

1. P0 shared visual language: clean sans, navy/cream/teal, quiet surfaces, one primary action; same shipped low-poly harbor/boat/sea assets in Home and preparation as map 1. No decorative extra actor layer or claim of new owned crew.
2. P0 complete loop: coherent Home → manifest → exploration → event/battle → durable return receipt → useful growth route. Actual transactions remain sole state owners.
3. P1 support-page continuity: remove contradictory unavailable-collection text and duplicate log labels; distinguish current stock, permanent collection, current clues and true history. Quiet repeated actions.
4. P1 business/battle framing: preserve caller label contrast, safe areas, hidden tutorial targets and callbacks; remove obsolete brush/dark-brown visual family.
5. QA and independent review before any publication. Freeze a tested local commit and immutable source backup after accepted batch.

## Acceptance matrix

| Area | Required verification | Status |
|---|---|---|
| Source baseline | Exact public commit/tree; separate local branch | PASS |
| New profile | Original story/bootstrap, prep crew+food, guarded departure, clean map1 | PASS actual native first voyage |
| Legacy profile | No new marker/migration; original map/input/inventory retained | Pending regression/native |
| Home/preparation | Native 540×900 and 480×800, readable labels, single primary, real totals | PASS actual native |
| Event/battle/reward | Original callbacks, outcome/rewards, modal input block, readable native UI | Pending |
| Return/growth | Commit-once receipt, actual stock, onward route, cancel/no re-grant | PASS natural return + forge + cargo upgrade; final focused-layout recheck pending |
| Support/empty states | Crew recovery, collection empty/owned, log/clues distinction, shortages | Pending |
| Business routes | Original locked/unlocked routes and return, hidden guide targets | Pending |
| Interruption | Close/cancel/repeated clicks/pause/resume/cold save | Pending |
| Automated | Warm 8 logic + 12 native; new focused suites; legacy aggregate with explicit legacy fixture flag; clean-map tests | PASS frozen aggregate |
| Platforms | Linux native only; no Mac/Xcode project or mobile/audio acceptance | Explicit limitation |

Screenshots must be actual native captures, not concept art. Document fixture checks separately from natural full-game play. Historical evidence in older docs is not acceptance of this batch.
