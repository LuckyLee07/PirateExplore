# Whole-project B refresh — second-round cohesion and acceptance

Baseline: `0c0921a`. Evidence date: 2026-10-09. This round refines the shared paper, ink, typography and coastal depth introduced by the [first-round refresh](global-b-refresh-acceptance.md). The [first-round coverage ledger](global-b-refresh-coverage.md) remains the record of broader routes; a shared visual change does not turn its pending gameplay or platform checks into passes.

The round's native checks, aggregate regressions, QA-hook cleanup and protected-save verification are complete within the coverage below. This is local Linux acceptance; the untested gameplay branches and platforms remain explicit.

## Changes in this round

### Management pages and controls

- The legacy header uses smaller paper currency faces inside the original 59-unit touch targets. Existing currency purchase callbacks remain in place; this does not replace the approved Home header.
- `ManagementTheme` and opt-in `BaseView` pages use a continuous paper workspace. The oversized central port watermark is removed while the legacy background handle remains available to callers.
- The footer presents alchemy, recruitment or gathering as a horizontal coral action, with lighter secondary controls and fine separators. The original action callback, cooldown progress, tap and long-press paths remain; the cooldown is displayed as an underline. The horizontal face has a matching expanded touch area. `TrainMode` removes its duplicate halo only.
- Gathering uses a compact production-summary band and consistent scroll-content sizes and edge padding. The worker list can expose the last of all eight worker types without clipping, and the summary calculates its height from the number of visible resource entries. The last-row evidence is the actual 480×800 scroll in `20`; the seven rows visible in the earlier 540×960 capture `07` were not the entire list.

### Dialogs, cargo, rewards and battle status

- `DialogTheme` replaces luminous rectangular borders with paper/ink edges and restrained separators. Paper bodies are explicit opt-ins for help, sea guide, bulk purchase and coin-purchase presentation; caller-owned text and callbacks remain authoritative.
- Native repeated long press exposed stacked bulk-purchase dialogs. `StoreMode` now checks current scene children for the same `bulkBuyOwner` before opening another, without introducing global modal state. The 10/100/1000 purchase callbacks are unchanged. Repeated native long-press/open/single-close checks pass after the guard.
- Cargo and reward lists use one continuous parchment sheet, dark serif labels and fine row rules. Original item icons, native rows, quantities, capacity calculations and pickup actions remain in use.
- `CombatTheme` draws rounded HP fills at 20 logical units high inside 98-unit ink status plates. Enemy HP is coral and player HP is teal. Existing numeric HP values sit below the bar so the fill no longer competes with the number. Ship and boarding scene presentation are adapted; a native ship fixture is not a complete battle-flow check.

### Routine production feedback while a modal is open

`ToastUtil:isProductionQuiet()` retains the existing Home/management/dialog-page checks and also inspects the current scene's visible direct children for `isAdventureModal`. `AlertView` marks its own modal layer and clears already visible routine-production text when opened. The queue checks the same state before presenting production text.

Only the `production` category is quieted. Important messages retain their original route, production calculations and saving continue, and ordinary production presentation can resume after the modal is removed. This uses scene state rather than a new modal counter or event listener.

### Original-alpha coastal depth

- `SeaChartWorldTheme` builds a GPU union of the actual source-atlas land alpha, including neighboring cells, their original flip flags and layer offsets. The edge follows the union rather than outlining each individual tile.
- Each 960-logical-unit core has a 32-unit gutter and a 256×256 power-of-two render target. The shader adds turquoise shallows, an inward ledge/shadow, a south-facing undercut and broken foam. Its phase remains continuous across chunk boundaries. Safe raised terrain groups remain governed by the original layer ordering.
- The accepted native result strengthens shoreline thickness, shallow water and selected thematic landmarks. Inland terrain remains substantially flat-topped; this is not a complete cliff/rock reconstruction of every island.
- Original event GIDs, fog records and TMX files are not rewritten. Missing native APIs, unsupported tile/target sizes, unknown source atlases and unsafe overlay order have explicit fallback paths.
- Two native rendering defects found during QA were corrected: this Cocos version needs an explicit `RenderTexture:setVirtualViewport`, and the displayed standalone sprite needs the projection matrix because its vertices are already transformed on the CPU. The mask's `SpriteBatchNode` still needs the model-view-projection matrix. Earlier failed captures remain diagnostic evidence.

## Native checks and their limits

Normal checks use the Linux game and a disposable QA profile. Dimensions below are screenshot/window pixels; presentation dimensions above are logical game units. A fixture is explicitly controlled scene setup, not naturally reached gameplay.

| Surface | Completed check | Boundary of the claim |
|---|---|---|
| Cargo | Native 540×960 display; inset parchment and original rows reviewed (`03`) | No new cargo-use or discard transaction is claimed. |
| Sea guide | Native 540×960 display and inset paper review (`04`) | Does not cover every help/guide text variant. |
| Repository | Native 540×960 coordinated header/workspace review (`05`) | Does not repeat every filter, detail or sale branch. |
| Gathering | Worker plus changed 11→12 and minus restored 11; the new manual action increased stone by 19. At 480×800, `19` shows six complete rows at the top; an actual drag reached the eighth/final worker type, monk (`僧侣`, assigned 4), fully visible in `20` without overlapping the production summary | `07` showed seven rows, not all eight worker types. Other worker bounds and long-press contracts have regression coverage, not a fresh native pass of every worker state. |
| Market / bulk dialog | Final 480×800 inset/button spacing was visually accepted (`21`). After the duplicate guard, a real 1.6-second hold produced one modal (`25`); one close returned directly to market (`26`). A second 1.6-second hold and single close also passed | `22` records the earlier duplicate-dialog defect; `08` has superseded spacing. The 10/100/1000 purchase options were not activated. QA currency continued to change through original timers/hold behavior, so this is not a claim of unchanged currency during the check. |
| Coin purchase | Actual native coin-purchase offer displayed at 480×800 (`23`) | Presentation only; no transaction was performed. |
| Ship battle HUD | Paused native fixture at 540×960 (`11`), with real HP numbers outside the colored fills | Presentation only. Full battle actions, victory, defeat and progression are not tested by this fixture. |
| Reward list | Native fixture at 480×800 (`14`); actual single pickup changed occupied cargo 50→51, pick-all reached 53/60, then close ran | The reward scene and drops are explicit fixtures, not a naturally earned battle reward. |
| Modal production feedback | External native fixture logged one visible production message before open, zero after open, suppression of new production, visible important feedback and production resumption after modal removal | Direct modal presentation/queue behavior, not every modal route or background transition. |
| Coast / terrain themes | Actual chapter-1 coast at 540×960 (`15`), map-4 forest/volcanic fixture at 540×960 (`16`) and map-6 sand/ice fixture at 480×800 (`17`) were independently reviewed; the new edge is visibly present. Final maximum-map violet/ghost fixture `24` has the statistics overlay hidden | The theme captures use controlled map fixtures, not natural unlocks. Inland terrain remains flat-topped. `09`, `12` and `13` are failed/debug attempts and are not accepted coast images. |
| Chapter-1 movement / return cancel / persistence | Cold start restored the original 49% fog state. Moving right one explored cell consumed one food (48→47) and changed occupied cargo 53→52. The 15-diamond return confirmation was cancelled and returned to the sea map (`27`). A second cold start restored the same position, 49% fog, food 47 and cargo 52 (`28`) | Movement was within an already explored cell; no new fog reveal or completion growth is claimed. The return was cancelled, not purchased or completed. |

The original action and navigation callbacks remain in use. The checks above do not establish successful recruitment, crafting, bulk/coin purchases, every alert branch, full combat, natural chapter progression or a complete fresh-player tutorial.

## Automated checks

The complete `tools/tests/run-adventure-ui-tests.sh` rerun passed; final evidence is `regression-final.log`. Earlier `regression-first.log` and `regression-current.log` remain intermediate records. Passing coverage includes:

- Management control/list contracts, including SDButton behavior, sizing, gathering scroll layout and the existing production/economy paths.
- Home/production feedback contracts, including important-message preservation and off-Home restoration; the native modal fixture independently exercises modal-open clearing and resumption.
- All sixteen real TMX files: 27,206 land cells, 158 flipped cells, all eight flip states, all six layer-selected terrain families, original offsets/ordering, the 101×101 maximum map, bounded GPU coast masks, safe raised groups, idempotence and missing-art/API/order fallbacks. These are automated map-data and Lua checks, not sixteen native playthroughs.
- Actual coast GLSL rendered on surfaceless GL against original atlas alpha: clear opaque-land/open-water centers, visible shallows and inner ledge, broken foam and a seamless 960-unit chunk join (maximum sampled channel difference 0). The displayed-quad test includes a nonidentity transform to catch double transformation.
- Coast mask/edge shader compile and link in GLES2 with matching varying precision. This verifies shader compatibility in that context, not mobile-device rendering or performance.
- Existing fog/grid/terrain-alpha renderer checks, the read-only tile-flags binding checks, and event-atlas/CSV identity guards.

### Maximum-map native draw-cost sample

The 101×101 map-13 fixture was sampled with the same scene, camera and fog, first hiding and then showing the coast groups. The external `coast-perf-ab.lua` harness collected six frame-rate samples per state, with settling time between states, and restored the visible coast and prior statistics-display setting.

| Coast groups | Mean FPS | Minimum | Maximum | Samples |
|---|---:|---:|---:|---:|
| Hidden | 61.297 | 59.806 | 62.514 | 6 |
| Visible | 55.964 | 53.479 | 58.421 | 6 |

The visible overlay reduced mean FPS by about 8.7% in this short native sample. This isolates a presentation/draw-cost comparison in one scene; it is not a sustained device benchmark. The 53 RGBA masks account for 13.25 MiB of color storage in addition to the reported 28.44 MiB texture cache. The largest allocation among the sixteen map-data tests is 58 masks / 14.5 MiB in map 16. These figures are not RSS or a complete GPU/process-memory budget.

An initial A/B attempt returned zero FPS because the statistics display was disabled; that measurement is invalid. The harness was corrected to enable statistics for measurement and restore the previous setting afterward. The first round's 61.75 FPS and this round's standalone 52.88 FPS sample have different conditions and must not be used to claim a performance improvement or a controlled regression. No sustained performance result, total-memory measurement or Apple-device acceptance is claimed.

## Evidence index

Evidence is outside the repository at `/workspace/shared/b-cohesion-round2-evidence`. It contains screenshots, logs and QA tooling; screenshots do not contain protected save files.

| Evidence | Interpretation |
|---|---|
| `01-cargo-paper-540.png`, `02-guide-paper-540.png` | Earlier paper-layout captures, superseded by `03`/`04` |
| `03-cargo-inset-540.png`, `04-guide-inset-540.png` | Reviewed cargo and guide paper insets |
| `05-repository-coordinated-540.png` | Reviewed repository/header/workspace |
| `06-gathering-coordinated-540.png`, `07-gathering-scroll-end-540.png` | Earlier gathering layout; despite its filename, `07` shows seven rows rather than the actual eighth/final worker type |
| `08-market-modal-540.png` | Actual market modal check; button spacing superseded by `21` |
| `09-coast-depth-first-540.png`, `12-coast-viewport-fixed-540.png`, `13-coast-alpha-diagnostic-540.png` | Failed/debug coast attempts; not final visual acceptance |
| `10-reward-paper-fixture-540.png` | Earlier reward fixture; final fixture capture is `14` |
| `11-ship-status-fixture-540.png` | Reviewed paused ship HUD fixture |
| `14-reward-final-fixture-480.png` | Accepted final reward parchment fixture; pickup/pick-all/close were separately exercised in the GUI |
| `15-coast-native-corrected-540.png` | Accepted actual chapter-1 coast, with visible shoreline depth and shallow water |
| `16-forest-volcano-depth-fixture-540.png`, `17-sand-ice-depth-fixture-480.png` | Accepted controlled map-4/map-6 fixtures showing four terrain families and stronger raised landmarks |
| `18-maximum-violet-ghost-fixture-540.png` | Earlier maximum-map fixture/metrics context; final presentation capture is `24` |
| `19-gathering-final-480.png`, `20-gathering-last-row-480.png` | Real 480×800 gathering top view and actual drag to the complete eighth/final worker row, with the summary separate |
| `21-bulk-buy-inset-final-480.png` | Accepted bulk-purchase spacing and paper inset |
| `22-bulk-duplicate-observed-480.png` | Duplicate-dialog diagnostic capture before the repetition guard; not an accepted final state |
| `23-coin-purchase-final-480.png` | Actual coin-purchase offer presentation without a transaction |
| `24-violet-ghost-final-fixture-540.png` | Final map-13 violet/ghost fixture with statistics hidden |
| `25-bulk-single-window-480.png`, `26-bulk-single-close-480.png` | Native guard verification: 1.6-second hold produces one modal, one close returns to market; the sequence was repeated successfully |
| `27-coast-move-return-cancel-540.png`, `28-sea-restart-540.png` | Actual explored-cell movement and return cancellation, then cold-restart persistence of position, fog and consumed food/cargo |
| `native.log`, `modal-toast-qa.lua` | Native runtime and explicit modal fixture; `MODAL_QA` records `visibleBefore=1`, `visibleAfterOpen=0`, `productionSuppressed=true`, `importantVisible=true`, `resumed=true; PASS` |
| `29-second-round-overview.png` | Eight actual final screenshots, scaled without content changes; Chinese labels identify controlled battle/reward/map fixtures |
| `regression-final.log` | Complete passing aggregate rerun |
| `regression-first.log`, `regression-current.log`, `home-modal-test.log`, `management-final.log` | Intermediate aggregate and focused test evidence |
| `coast-diagnostics.lua`, `coast-perf-ab.lua`, `main-before-qa.lua` | External QA tooling, same-scene draw-cost harness and pre-hook backup, not natural gameplay acceptance |
| `existing-edge-comparison.json` | Pixel comparison supporting the inherited top-strip observation below |
| `protected-save-hashes-final.json` | Final hashes of all eight protected historical files, each matching its original baseline |

## Final integrity checks and remaining work

- The temporary QA entry in `main.lua` has been removed. The file has no diff against baseline; QA harnesses remain outside the production source tree.
- Native testing used disposable profiles. The final hashes of all eight protected historical files match their original baseline; no historical save was used as the writable QA target.
- The game was stopped after verification, and the window list confirmed no `PirateExplore` window remained. `git diff --check` passes. No GitHub push or other remote publication is included.
- Two pre-existing visual boundaries remain visible in the native map evidence. The top black strip in `16` is byte-identical to the corresponding first-round `23` region `(0,106,540,113)`, as verified by pixel SHA. An isolated vertical line was already present in `09`, before the new coast layer rendered; that crop is not pixel-identical across captures. Neither observation establishes a complete root cause or a fix for those artifacts.
- Mobile foreground restoration is unverified. This old engine resets RenderTexture filtering to alias on foreground notification, so the explicitly linear coast target may need a later mobile lifecycle fix; no engine-wide change is included here.
- Shared presentation coverage does not replace branch acceptance. Full running combat, all shop/alert/event states, natural chapter progression, full tutorial, mobile/Apple rendering and sustained device performance remain unverified. Existing ship/deck/character/item art remains; this round does not claim an all-new-art release.
