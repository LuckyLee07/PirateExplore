# Whole-project B refresh — first-round acceptance and limits

Baseline: `414172e`. Local Linux evidence recorded 2026-10-09. This document accepts only the explicitly verified presentation and interaction coverage below. The [coverage ledger](global-b-refresh-coverage.md) keeps the remaining routes visible; implementation coverage is not completed gameplay acceptance.

## Scope and protected behavior

- `ManagementTheme`, `DialogTheme`, `CombatTheme` and `StartupTheme` extend the approved harbor palette, paper/ink/coral surfaces and typography into management pages, dialogs, events, battle/reward frames and startup. BaseView management styling is opt-in.
- This is a framework/material/font first pass. Existing ship and deck artwork, characters, item icons and story illustrations remain. It is not an all-new-art release.
- `SeaChartWorldTheme` selects sand, forest, volcanic, ice, violet and ghost materials from the actual layer atlas. Original land alpha, flipped tiles, layer offsets and z order remain authoritative; the accepted chapter-1 coast is retained. Sparse accents use safe original land bases, with bounded batches and fallback paths.
- The new read-only Lua binding `TMXLayer:getTileFlagsAt` returns original tile flip flags using initialized native output storage. It does not write tiles or change GIDs. The sixteen original TMX files, packaged economy/event CSV data and save format are unchanged.
- Production gains continue through the existing calculation/save path. Only routine production floating text is quiet on Home and `managementTheme`/`dialogTheme` pages. Error, unlock and reward feedback retains its existing route.
- Native QA used separate disposable profiles. `protected-save-hashes-final.json` records all eight protected historical files, verified unchanged against the starting hashes. No historical profile was used as the writable QA target. The pass is prepared for a local commit; no push or remote publication is included. The native test process was stopped after verification.

## Native checks completed

Normal GUI checks used the native Linux game at 540×960, with final cold checks, the empty-profile smoke and selected fixtures at 480×800. Existing callbacks and saved data were used unless a fixture is explicitly identified.

- Repository display/navigation; gathering plus/minus and restoration of the prior worker count; successful construction (house count 5→6, costing 80 coins and 40 stone), followed by the next construction shortfall (50 stone needed, 23 available, short by 27); crafting display without a transaction; market list and bulk dialog cancellation; recruitment/change-job entries and nested material-dialog close.
- Achievement, settings and help display/close; automatic promotion display/cancel; actual group/auxiliary navigation callbacks. These checks do not imply completed purchases, recruitment, crafting, job conversion, reward claims or every auxiliary screen.
- Actual sea cargo, guide, return cancellation, movement and world chapter chart. Clicking locked chapter 4 kept the original lock and did not open the chapter; the expansion offer remains untested. The corrected iron marker appears on the live map. A return-cancel check does not claim an actual return voyage in this pass.
- Final cold construction (`28`) and achievement (`29`) at 480×800 show the corrected shared layout and quiet routine-production presentation. The initial repository font-alpha issue was corrected by retaining RGBA8888 while creating its materials and TTF labels. Intermediate construction/crafting captures are diagnosis evidence, not final visual approval.
- An independent empty-profile cold start displayed the opening story with the original illustration and updated serif text (`30`). Two story advances reached the real fresh Home, then the original island/alchemy route. An actual alchemy click increased gold from 0 to 1 (`32`/`33`); the island title and gesture guide appeared. `32` precedes the original first-tick title refresh; `33` shows the title after it. This is a startup/early-tutorial smoke, not full tutorial acceptance.

### Controlled sea-theme and performance fixtures

`prepare-theme-fixtures.py` copied the disposable sea profile for maps 4, 6 and 13 and changed chapter/state fields. `reveal-theme-fixture.py` then revealed fixture fog records and positioned the player to show the relevant terrain. These are native render fixtures, not evidence of naturally unlocking or exploring those chapters.

- Map 4: forest and volcanic; map 6: sand and ice; map 13: violet and ghost. Captures `22`–`24` show all six terrain families.
- The maximum 101×101 map was opened natively (`21`). `native.log` records a sampled 61.75399 FPS and a texture-cache report of 31 textures / 29,120 KiB, approximately 28.44 MiB. The screenshot independently shows an instantaneous reading around 62.7 FPS.
- These figures are one native scene sample, not a sustained benchmark or total process-memory measurement. `map13-memory.json` contains `[]`; no RSS result is available. The texture figure must not be reported as RSS or as a full memory budget.

### Controlled battle and reward fixtures

`combat-qa.lua` is external evidence tooling. It requires an isolated QA save and invokes native scene/data setup using the real saved roster, ship, talents and current cargo plus enemies from the packaged CSV. Fixture logs explicitly state `naturallyEncountered=false` and `naturalVictory=false`.

- Ship and boarding battle screenshots (`25`/`26`) are paused native scenes. The saved crew was three ID-107 fighters; the ship was ID 1159; enemy setup used ship ID 11001 and fighter ID 10001. The screens verify rendering of the actual data and HP bars, not a combat win, loss or full action flow.
- The reward scene (`27`) uses actual current cargo and explicit UI fixture drops: food ID 1005 ×2 and simple key ID 1037 ×1. The initial occupied capacity was 47/60; a real GUI single-food pickup increased it to 48/60, then pick-all reached 50/60 and emptied the drop list. Close returned to the original underlying sea-map event-selector scene (not the chapter chart) through the native callback. This is reward interaction coverage, not a naturally earned victory reward.
- The temporary QA load/metrics hook in production `main.lua` was removed; that file was restored to its exact pre-hook contents and has no Git diff. The fixture harness remains only in the external evidence folder.

## Event identity correction

The earlier coast-slice document called GIDs 30/31 white-skull events. The actual packaged `strongholdAttribute.csv` identifies them as iron mine/material events (`铁矿`, `changeToMaterialsLayer`), with 31 the occupied variant. GID 47 is the revival point/cross. The global atlas corrects the iron artwork rather than changing any event identity.

| GIDs | Packaged event meaning | Global artwork |
|---|---|---|
| 30 / 31 | Iron mine, unoccupied / occupied | Iron material base; occupied flag |
| 32 | Tavern | Tavern marker |
| 45 | Arena | Arena marker |
| 47 | Revival point | Revival cross |
| 48 | Supply point | Supply marker |
| 49 / 50 | Transfer point variants | Shared transfer base; occupied flag |
| 52 | Black market | Market marker |

The replacement is still 512×384 with original 64-unit atlas cells. Exactly nine frames differ from original `t_00.png`; the other 39 are byte-identical. Consumed supply GID 44 is unchanged. Actual Meta GIDs continue to control event replacement, occupation and disappearance; there is no independent event overlay or gameplay GID remapping. Material provenance and the frame map are recorded in [GLOBAL-ART.md](../bin/res/assets/Images/UI/Adventure/SeaChart/Tiles/GLOBAL-ART.md).

## Automated verification

`tools/tests/run-adventure-ui-tests.sh` completed successfully; the complete current evidence is `regression-final.log`. The earlier `regression-current.log` is retained as an intermediate run.

- Management regressions cover SDButton listeners, hitboxes, disabled/tap/long-press behavior, BaseView opt-in isolation, worker boundaries/save cadence, repository filters/details/sale values/alpha, and purchase/build/craft cost contracts.
- Dialog regressions cover geometry, dismiss/confirm/cancel routes, manual close, SDButton state/long press and actual charge-price rendering. Existing Home, preparation, talent, intelligence-expiry, coast-slice and event-atlas guard regressions pass.
- The world regression reads all sixteen actual TMX files and original atlas alpha, then exercises production world Lua against those fixtures without a GUI: 27,206 land cells, 158 flipped cells, all six terrain families, all eight flip states, 101×101 coverage, offsets/z order, bounded groups, idempotence and missing-art/API/order fallbacks. This is not sixteen native chapter playthroughs.
- The actual new C++ tile-flags binding body is compiled against a small Lua/TMX boundary stub and checked for all eight flags, initialized output and invalid-input no-read behavior. The native Linux game was rebuilt for the GUI runs.
- Native surfaceless GL checks pass for fog alpha, grid opacity and the independent terrain alpha stencil. The existing DrawNode triangle regression passes. The real packaged CSV/pixel regression checks event meanings, nine-frame scope and occupation-base alignment.
- `git diff --check` passes. Automated tests do not substitute for the pending GUI and platform checks in the ledger.

## Evidence index

Evidence is external to the repository at `/workspace/shared/b-global-refresh-evidence`; it contains screenshots, logs and fixture descriptions, not protected save contents.

| Files | Meaning |
|---|---|
| `01-repository-first-540.png` | Initial font-alpha defect, superseded by `03` |
| `02-promotion-first-540.png`, `03-repository-corrected-540.png` | Promotion display/cancel context; corrected repository |
| `04-build-540.png`–`12-job-material-540.png` | Management route evidence; `04`/`06` retain intermediate defects and are not final visual captures |
| `13-achievements-540.png`–`15-help-modal-540.png` | Achievement/settings/help; final achievement is `29` |
| `16-sea-iron-corrected-540.png`–`20-world-chapters-540.png` | Actual sea/event/cargo/guide/return-cancel/chart checks |
| `21-map13-101x101-performance.png` | Native maximum-map sample |
| `22-theme13-violet-ghost-fixture-540.png`–`24-theme6-sand-ice-fixture-480.png` | Explicit map/fog/position render fixtures for all six themes |
| `25-native-ship-battle-fixture-540.png`, `26-native-boarding-battle-fixture-540.png` | Paused native combat fixtures |
| `27-native-reward-fixture-480.png` | Initial reward fixture before actual pickup/pick-all/close interaction |
| `28-build-final-480.png`, `29-achievement-final-480.png` | Final cold 480×800 construction and achievement checks |
| `30-new-player-story-480.png`, `32-new-player-island-480.png`, `33-new-player-alchemy-480.png` | Independent empty-profile opening story and real early alchemy interaction |
| `31-global-first-pass-overview.png` | Overview presentation; individual captures establish the test conditions |
| `native.log` | Cumulative native runtime, metrics, fixture input and reward-close callback records; includes the incidents below |
| `regression-final.log`, `protected-save-hashes-final.json` | Complete passing regression run; eight protected historical file hashes |
| `theme-fixtures.json`, `prepare-theme-fixtures.py`, `reveal-theme-fixture.py` | Explicit copied-profile and fog/position fixture preparation |
| `combat-qa.lua`, `combat-csv-inputs.json` | External native combat/reward harness and decoded source data |
| `main-before-metrics.lua`, `map13-memory.json` | Pre-hook backup and empty RSS attempt; neither is additional gameplay acceptance |

## Incidents and remaining limits

- The cumulative native log contains two X11 `MIT-SHM` / `X_ShmPutImage` `BadValue` exits, one during the earlier theme sequence and one on the first reward-fixture attempt. The reward fixture was repeated successfully without a code change, including its real GUI interactions and close. The incidents remain in the log; their root cause has not been established, and a successful repeat does not erase them.
- Inherited no-audio-device ALSA/FMOD warnings, malformed legacy network-URL output and legacy particle-texture lookup warnings remain in the environment. No successful external payment, online service or audio acceptance is claimed.
- Linux fonts/rendering are verified. Apple font selection exists in source but macOS/iOS rendering has not been checked. This pass does not establish complete tutorial/story, every dialog/shop/event state, naturally completed chapters, sustained performance, total memory use or full combat progression.
- Old ships/decks/characters/item icons and other unconverted art remain visible. Follow-up work should use the ledger's specific pending rows, not treat first-pass theme application as complete artwork replacement.
