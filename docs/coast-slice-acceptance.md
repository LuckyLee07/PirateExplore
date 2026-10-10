# First-chapter coast slice acceptance — 2026-10-09

This is one playable coastline sample and two refreshed event types. It is not a full-map art completion. Baseline: `8bb4590335ed82762a8b0e8b085b4f8839960791`.

**Event identity correction, 2026-10-09:** The historical slice below labelled GIDs 30/31 as white-skull events from their authored appearance. The packaged `strongholdAttribute.csv` identifies them as the iron mine/material event (`铁矿`, `changeToMaterialsLayer`), unoccupied/occupied respectively; GID 47 is the revival point/cross. The [global B refresh](global-b-refresh-acceptance.md#event-identity-correction) corrects 30/31 to iron artwork. The historical slice's render-fixture evidence remains valid as a GID-state check, but it is not skull-combat or stronghold-victory evidence.

## Bounded implementation

- Chapter 1, original 21×21 TMX, 64-unit grid. The coordinated RGBA coast covers a 5×6-cell canvas at grid (3,2), logical 320×384, world origin (192,832). Its eleven original land cells and nineteen surrounding empty cells are validated before display. It is uniformly scaled without cropping the canvas to its alpha bounds.
- Raised rock silhouettes are deliberately not clipped to the old flat land mask. Every passable cell center has alpha 0. Existing Meta, grid and fog layers remain above the art. No TMX, collision, fog, movement, resource, event or save-format code changed.
- Event art replaces only atlas local frames 28 / 11 / 12 (GIDs 47 / 30 / 31): cross, white skull, occupied white skull. The two skulls share scale and baseline. All other 45 atlas frames are pixel-identical. No static event overlay exists; the original Meta GID controls replacement and removal.
- Event gating independently requires chapter 1, 21×21 map, 64-unit tiles and the original Meta texture. Coast gating additionally requires the complete thirty-cell shoreline signature and layer order. Missing or incompatible art retains prior rendering.
- Coast texture explicitly uses local LINEAR / CLAMP parameters. Runtime observed RGBA8888 (enum 2). This was not a global texture-format or TMX sampling change. The substantive improvement is simplified coherent rock / vegetation / sand / surf artwork. Normal Lanczos downsampling to twice logical size reduces excessive source detail.

## Native verification

All gameplay used `build/linux/coast-slice-qa-data`, copied from the separate UI QA profile. The original six-chapter profile was never loaded.

- At 540×960, actual movement beside the coast consumed food normally, uncovered real fog and advanced exploration from 47% to 49%. Attempting to move from (7,6) into original land (6,6) was blocked without food cost. Original automatic combat and a giant-wave event appeared while approaching the coast; this is not a full combat/chapter acceptance.
- An attempted approach to water cell (4,6) encountered the original giant-wave event and was cancelled at (4,7). We do not claim that cell was traversed. Visible passable-cell alpha checks and the original collision logic are covered separately.
- Actual return confirmation and return to Home, then preparation and departure, restored the normal port-centered composition. It used the existing 15 in-game diamond return option; no store purchase. Food 46 / cargo 49 of 60 / exploration 49% persisted through cold restart at 480×800.
- Independent render fixtures copied the QA profile and changed only `gameMap1/titlesInfo/180/gid` to 30 and 0. Native screenshots show unoccupied without flag, occupied with flag (real QA state 31), and cleared without residual artwork. These are rendering-state tests, not claims of winning the stronghold story or running a live 30→31→0 battle sequence.
- Missing both new image assets falls back correctly. At the previously visited (4,7), top and left black map-boundary bands remain in fallback as with the new art. They are an existing camera/map-edge limitation; this slice does not change camera behavior.
- The native process was stopped after verification. All eight protected historical save SHA-256 hashes exactly match the initial baseline.

## Evidence and checks

External evidence folder: `/workspace/shared/b-sea-slice-evidence` (not committed, no saves included).

- `10-final-coast-events-540.png`: final actual gameplay, 540×960.
- `11-approved-vs-final-slice-540.png`: approved reference left / actual screenshot right, 1080×960.
- `12-final-coast-events-480.png`: final actual cold-restored gameplay, 480×800.
- `07-passable-water-beside-cliff-540.png`, `08-original-shore-collision-540.png`, `09-coast-water-gap-fog-540.png`: movement, collision, and final adjacent-water position; filename 09 does not imply traversal of (4,6).
- `13-render-fixture-gid30-480.png`, `14-render-fixture-gid0-480.png`: explicitly controlled render fixtures; fixture preparation and exact modifications recorded alongside them.
- `15-missing-art-fallback-edge-540.png`: prior rendering fallback and existing camera edge bands.
- `final-regression.log`: complete `tools/tests/run-adventure-ui-tests.sh` passed. Includes new real-TMX thirty-cell/scale/layer/fallback/cleanup test and actual event-art function guard test; existing UI, expiry, long-press stock, C++ triangle and native GL renderer regressions remain passing.
- `protected-save-final-hashes.json`: all eight unchanged hashes. `native.log`: complete runtime log, no Lua traceback or assertion; inherited no-audio-device ALSA/FMOD and malformed legacy network URL messages still occur.

Independent code review and local 540 visual review passed. The coast and these two event types are accepted as a local quality baseline. Unconverted flat islands, old gray event icons, water repetition, faint grid and fog shape remain outside this slice. Apple rendering and full combat/chapter completion remain unverified. No GitHub update was performed.
