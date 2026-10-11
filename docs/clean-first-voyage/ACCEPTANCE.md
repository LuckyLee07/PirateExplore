# Clean first-voyage integration, 2026-10-11

## Scope and provenance

This isolated branch integrates the approved clean harbor presentation into the real recovered PirateExplore first-map flow. It is a first-voyage checkpoint, not a completed all-page redesign. Recovered Warm Stage 1 is exact tree `1f70a95424e1cf885c4ad3007c5f3be2c9a9711e`, locally committed as `f9691e6cc593e7a3320611cf0da86f1bf74ceb96`, on public C `57c5c14c25bddce268c138f003d44166f3495d94`. Later historical Warm commits `2d199e7` and `52a6a32` were unavailable and are not represented as restored.

Only confirmed new-role initialization writes `cleanFirstMapVersion=1`, inside the existing atomic initialization. That marker plus map index 1 selects the authored map and display adapter. Unversioned saves, prior AdventureProgress version-1 saves, and later chapters retain the original map and view. No saved geography is migrated. The independent prototype model/controller/save is not used.

## Actual native first voyage

The full application and Cocos engine were rebuilt from recovered native source. Binary SHA-256: `9e292e313ea60446e3db75d0f1643a2d03b00195ad837deb70db271a3ec108c3`. Native build details are adjacent. Natural play used a genuinely fresh isolated profile after the 50-cell coastline and slot layout froze. Linux GLFW window: 480 × 900. Screenshots are actual native captures, not mockups.

1. New role, original story/preparation, one crew and 16 food; new port (7,11).
2. North to (7,10): 15 food. Cold restart restored (7,10), 15 food/cargo, original resume sheet.
3. North to (7,9): 14 food. North to actual timber event (7,8): still 14. Opened the original event panel and explicitly chose Leave.
4. East to the actual dynamically selected wreck (8,8): 13 food. Original rescue choice charged 3 food and loaded 2 iron: 10 food, cargo 12/20. No alternative choice was executed.
5. Original pause/save reported the current map and voyage saved. An independent copy of this checkpoint was retained for cold/input QA.
6. Returned via (8,9), (7,9), (7,10), (7,11): food 9, 8, 7, 7. Original port event safely settled and saved the voyage.

Original event tiles can have free entry. This was preserved: ordinary sea steps cost food, timber and port event entry did not. The earlier WIP voyage used another layout/route and returned 6 food; it is not the final run's ledger or a universal per-step rule.

`FIRST-VOYAGE-LEDGER.json` contains sanitized before/after production-save values. Gold 0 → 25; warehouse food 84 → 91, stone 0 → 15, wood 0 → 5, iron 0 → 2, cloth 0 → 5. Diamonds stayed 0. The one embarked crew returned; it is not a newly awarded crew. The original first-return subsidy accounts for the additional materials and gold. No reward values were changed by this branch. Battle cargo was cleared by the original settlement.

## Independent old-save parity

The reviewer naturally created a prior Stage-1 save using the exact baseline resources and matching rebuilt binary: original port (10,10), one crew, 16 food; moved north and saved (10,9), 15 food. A copy cold-loaded under integration resources with the original orthogonal map and HUD, no clean marker and no clean-view mount. `gameMap1` and `UserDefault.xml` remained byte-identical; decoded role differences were only original login-day and production-clock bookkeeping. Inventory, progression and position were unchanged. Native south movement entered the original port and safely returned 15 food and one crew, with zero gold/diamond rewards.

## Conservation and presentation checks

- Original DataManager, UserData, SaveDataManager, ExploreDataManager, FogManager, map layout managers, EventManger, bag controller, KnownRoute, AdventureNavigation and WarmPause remain byte-identical to Stage 1.
- Explore's original `initPlayer`, `tryToMoveForDirction` and `costbread` bodies remain byte-identical. New code only selects/gates the authored map, adapts presentation and routes clean-screen input to original callbacks.
- Actual fog value zero is required for geometry/semantic visibility. Partial masks are not treated as known. Harbor ground is clipped to actual known blocked cells plus the logical port, so large art cannot silently claim navigable sea. Traversable resource events use floating rafts, not invented solid islands.
- Four native ship headings, camera tween, animation input barrier, logical inverse picking and cosmetic port-only berth offset. No free continuous sailing or 3D movement.
- Compact sans HUD retains original cargo, chart/strategy, pause, event and return transactions. Original hidden HUD remains alive as callback owner but cannot reappear after EventManger unfreezes.
- Root and independent reviewer accepted `native-polished-departure-v2.jpg` as the first integrated visual checkpoint at 10:11 UTC.

## Reproducible test commands

Run from the integration repository. A correct Lua 5.1 interpreter is required; the recovery-only helper's `os.execute` exit status was broken and was not used for shell-backed acceptance.

The recorded cloud commands use an external isolated SDK and test executables. On another machine, install the README prerequisites and substitute its Lua 5.1 and rebuilt native harness paths. These executables and SDK are not source-package contents.

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
LUA_BIN=/workspace/shared/lua51 LUA_INIT='WARM_PIRATE_V1=false' bash tools/tests/run-adventure-ui-tests.sh
LUA_BIN=/workspace/shared/lua51 WARM_NATIVE_BIN=/workspace/scratch/79976da795e7/independent-first-voyage-qa/tutorial-log-native-current bash tools/tests/run-warm-v1-tests.sh all
/workspace/shared/lua51 tools/tests/clean_voyage_view_regression.lua
/workspace/shared/lua51 tools/tests/clean_voyage_hud_regression.lua
python3 tools/tests/clean_first_map_regression.py /workspace/shared/lua51
python3 tools/tests/heading_font_coverage_regression.py
git diff --check
```

The Warm native harness is compiled from recovered test source against newly rebuilt exact-current engine libraries. Its 12 native suites are real Cocos/EGL component fixtures, not substitutes for natural full-game acceptance. EGL component fixture lacks stencil; actual GLFW captures/logs provide the stencil/clipping check.

The legacy aggregate passes with the explicit legacy fixture flag. The default-Warm invocation has three pre-existing fixture mismatches (expedition header expectation, dialogue WarmTheme mock resolution, and cold-position fixture lacking cc.c3b). They are not represented as fixed or green by the legacy-mode result. The dedicated Warm runner passes all 20 suites (8 logic, 12 native). Focused clean map/view/HUD/font checks and git diff whitespace checks pass. Independent final native input results follow below when complete.

## Known limits

No Mac, iPhone or physical-device build was run. Old later pages retain only the recovered Stage-1 baseline. Audio backend initialization is unavailable in this cloud desktop; native logs show existing FMOD failures, so sound is unverified. The baseline and integration also report an existing missing `Images/Map/Particles/particleTexture.png`; unrelated particle effects were not repaired in this bounded change. The original backend request produces an existing malformed-URL message; this offline first voyage does not verify network services. No Lua exception or stencil-buffer failure was observed in the final full-game loop. No public push, pull request, merge or deployment was performed. QA profiles, binaries, accounts and Git history are excluded from the source artifact.

## Final independent native input QA: PASS, 10:23 UTC

Used a separate copy of the real final-layout rescue checkpoint. Cold load restored (8,8), food 10 and 2 iron (cargo 12), without replaying the rescue. Actual pause, cargo, chart, original return confirmation/cancel and original timber event panels blocked underlying controls and repeated sea taps. Leaving the timber event restored only the compact HUD and preserved food 10 plus 2 iron. Two blocked-coast taps and a canceled drag consumed nothing. A held cardinal press lasting 1.8 seconds moved exactly once from (7,8) to (7,9), charging food 10 → 9. No map click-through was exposed. The reviewer left the polished new-map scene open for viewing.

All five compact callbacks share a ready-state, animation, queue, disabled-control, modal and visible-event barrier. Regression tests exercise all five production registrations under eleven blocking conditions, then verify one delegation each when ready. Tapping either the logical port center or the visually offset boat contact is inert; all four adjacent logical tiles retain cardinal picking at four scales. Current guarded source was independently rerun: full legacy aggregate PASS; dedicated Warm runner 20/20 PASS; focused map, view, HUD and font checks PASS.
