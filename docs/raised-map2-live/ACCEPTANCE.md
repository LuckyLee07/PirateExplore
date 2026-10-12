# Dormant map2 live presentation milestone

**Activation blocked. This is an explicit developer opt-in, not a production
rollout.** `RAISED_MAP2_LIVE` must be the boolean `true`; it is never initialized
by normal startup, read from a profile, inferred from a new/legacy save, or
written to a save. Map 1 and maps 3–16 remain on their existing routes.

Base: frozen `4925032767ae9ab1451623d4e9c3cca81aabcd7e`, tree
`471761eb4becc9ce06dec01b751f91801b11b6d0`. That worktree is unchanged. Only this
milestone's commit should be applied; do not merge its historical ancestor over
a newer candidate or restore its older EventLayer input shield.

## Implemented

- `RaisedSeaMap2Live.lua` wraps the real native map and moveLayer children in
  the accepted projection. Source map/layer positions, GIDs, flags, object IDs,
  player coordinates, collision checks, movement queues, event dispatch,
  movement/save timing, food and pathfinding remain authoritative and unchanged.
- Original native Meta, Fogs, ship, Jointed children, route, glow and particle
  nodes remain alive. Future direct moveLayer children enter the same projection.
  Unmount restores original parentage and the original addChild method. It does
  not resume gameplay actions or change Jointed enable state.
- Raised ground is an overlay below the original Meta/grid/fog/ship planes.
  The original alpha footprint and geometry cache are reused. Geometry refreshes
  only after real discovery/event notifications, not by scanning the map each
  frame. Source terrain and fog remain underneath, including partial cells.
- The exact native Fogs layer and its materialized fade sprites preserve every
  original GID, alpha, action and timer. Raised geometry remains clipped to fully
  known ground cells; partial cells keep their original ground presentation.
- Camera/pan/zoom keep the original camera owner and zoom range. Touch is inverted
  through the native map transform; arrow drawings point along projected map
  directions while their original movement callbacks stay unchanged. A robust
  opt-in angle calculation avoids the old arcsine function's exact vertical
  singularity. The ordinary route retains its existing input math.
- Unsupported map/grid/source/API/art falls back before attaching. Turning the
  flag off restores the ordinary route without changing serialized game data.
  The ordinary route does not load the source-alpha geometry or clean gate art.

The ten new Explore hook lines plus a verbatim touch-listener extraction are
presentation integration. `FogManager`, `MapLayoutManagers`, `ExploreDataManager`,
`AdventureSea`, navigation, event handlers and save modules are not edited.

## Native evidence and boundaries

`tools/tests/raised_map2_live_native.lua` uses actual Cocos nodes, production
Explore movement/food/camera/input methods, the production touch listener and
native touch dispatch, original FogManager/ExploreDataManager, original HUD arrow
MenuItem callbacks and original WarmPause controls/checkpoint. Its role/map
storage is a disposable seeded in-memory copy. Random encounters and event
completion are deterministic callback probes; this is not an end-to-end combat
or chapter-transition session. No GUI, player profile, source map, CSV or art is
written by the fixture.

Passed checks:

- 2,883 native source/overlay projections across three zooms and panning;
- byte-identical serialized legacy/live movement traces: food, delayed saved
  tile, reveal, source trigger ID, occupied enemy GID48 identity, blocked coast;
- zero presentation writes on mount, repeated mount, refresh and on/off toggle;
- the same real fading native fog sprite/action continues through toggles;
- exact original partial/unknown pixels outside raised known cells: 638,309
  samples, maximum channel error 0 (two source pixels excluded at cell borders);
- actual pause freezes the same native actions; save preserves map, position,
  fractional food, cargo and crew; Continue resumes those actions;
- native child insertion/removal pixel comparisons: maximum channel error 0;
- all 96 protected original maps/CSVs/atlases/art and gameplay modules unchanged;
- original camera regression: 384 cases and 59,520 edge-cell checks; full explicit
  legacy-opt-out aggregate; original 1,922-center raised projection contract.

## Blocking context-recreation result

The fixture follows `platform/android/javaactivity.cpp` nativeInit ordering:
state-cache invalidation, default shaders, DrawPrimitives initialization,
volatile texture reload, foreground event dispatch, default GL state. Its native
pause body is compiled from the repository. The actual engine renderer and
texture/DrawNode context listeners run; no restoration callback is simulated in
Lua. The harness flushes queued native coast FBO commands before its first
zero-delta scene frame, and drains autorelease between deterministic ticks.

A separate fresh **original-route process** has zero changed context pixels and
all sampled GPU texture hashes match. The **live process fails active/paused
context pixels**. Clean water and sand GPU texture bytes change on reload;
original atlas hashes remain identical. Rebuilding presentation nodes does not
repair that GPU corruption. The exact failures and native image hashes are in
`VERIFICATION.json`, not described as passing because the scene kept running.

A stale numeric GL texture name being deleted during reload is a hypothesis,
not a confirmed engine diagnosis. This commit makes no engine change. A later
resource-lifetime fix must be separately reviewed and rerun against both routes.
Linux EGL emulation does not establish Android-device restoration.

## Remaining visual/activation gates

- Native source actors/Meta/effects are projected with the world; complete upright
  semantic actor art and populated-route occlusion acceptance remain pending.
  Legacy portal/revive/cross/occupied icon art is explicitly unfinished here.
- Partial cells retain source ground art while fully known cells are raised.
  This preserves discovery but is not a final seamless reveal-art treatment.
- Full event/combat/return, chapter changes, real desktop input review, Android
  GPU behavior, memory/leak checks and mobile frame-time profiling are pending.
- No later-map geometry/family conversion, save migration or publication exists.

## Reproduce

See `tools/tests/clean_world_native.md` for the read-only Cocos donor build.

```sh
PIRATE_BUILD_DIR=/path/to/built/linux \
CLEAN_WORLD_BUILD_DIR=/path/to/clean-world-native-objects \
RAISED_MAP2_LIVE_BUILD_DIR=/path/to/separate/live-build \
PIRATE_RUNTIME=/path/to/linux-runtime \
python3 tools/tests/build_raised_map2_live_native.py

# Both run in separate fresh processes and isolated output folders.
LIVE_BASELINE_ONLY=1 LIVE_FULL_THEME=1 RAISED_MAP2_LIVE_CAPTURE_DIR=/tmp/baseline \
  /path/to/live-build/raised-map2-live-native tools/tests/raised_map2_live_native.lua
LIVE_FULL_THEME=1 RAISED_MAP2_LIVE_CAPTURE_DIR=/tmp/live \
  /path/to/live-build/raised-map2-live-native tools/tests/raised_map2_live_native.lua
python3 tools/tests/verify_raised_map2_live.py \
  --capture-dir /tmp/live --baseline-dir /tmp/baseline
```

Set `EGL_PLATFORM=surfaceless` and the runtime library path as in the donor
instructions. Create capture directories before running. The verifier exits
nonzero while activation is blocked; `--record-only` writes a failure receipt
without claiming acceptance. It only reads native image pixels.
