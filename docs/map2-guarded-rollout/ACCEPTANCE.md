# Guarded map2 presentation rollout

Base: `a18c54f05a3a678aabc957a0a3d07dc6c40faaf8` (reviewed map2 HUD/boat).
This checkpoint defaults to clean presentation on map2 only. Maps1 and3–16 retain
their existing route. The source grid, collision, original actors, fog, event
IDs/callbacks, movement, costs, reward logic and save format are unchanged.
No save marker, migration or QA overlay is installed.

## Selection and safe original route

- Normal production `LuaClass/main.lua` requires no hook or flag assignment.
  The existing end of `Explore:initMapByMapIndex` calls the guarded adapter.
- Linux: `PIRATE_MAP2_PRESENTATION=original ./linux.sh run 480 800` starts the
  original map2 presentation. Omit the variable (or use `clean`) for clean map2.
  Unknown, nonempty values conservatively select original. This is a process
  choice, never a saved preference. Use the existing `PIRATE_SAVE_DIR` interface
  to choose a separate test profile; do not test against a player's only copy.
- The existing runtime boolean `RAISED_MAP2_LIVE=false/true` takes precedence
  for original/clean comparison fixtures. Nonboolean overrides select original.
  The flag cannot enable maps other than map2. No flag is assigned in production.
- Missing art/dependencies, a non31×31/64px map, missing/rebound/offset/misordered
  TMX layers, incompatible owner/model/coast metadata or unsupported package
  preparation keeps the original route. All dependency loading, texture loading,
  model construction and validation happens before any live node changes.
  Optional module APIs are checked for callable installation, refresh, disposal
  and deferred HUD entry points before installation. Missing or noncallable APIs
  return `fallback:unsupported-api:<module>.<method>`. Preparation exceptions return `fallback:incompatible-package`; their detail
  is retained in the runtime-only `raisedMap2Diagnostic` field for diagnosis.
  The contract checks callable API and consumed metadata shapes; it does not
  certify arbitrary behavior inside an otherwise callable implementation.
  Installation and lifetime errors are not swallowed by a blanket exception
  handler. Optional event-art failures retain that event's original sprite.
- Every exit-to-next-map starts with the existing unmount. Explicit comparison
  teardown restores native nodes, hooks and visibility. Native scene cleanup
  releases leases without reparenting dying children. The native actor, fog and
  original save managers remain the authoritative objects throughout.

## Native regression commands

Use an already verified build of `tools/tests/raised_map2_live_native.cpp` plus
the unchanged bundled `CCTexture2D.cpp`/`CCDrawNode.cpp` fixes. The executable
loads source/assets from the current worktree; no new engine build is needed
for this Lua-only delta. Source the existing Linux runtime environment first.
Set `B` to that executable and `O` to a new evidence directory.

```sh
export LIVE_FULL_THEME=1 MESA_SHADER_CACHE_DISABLE=true
LUA_BIN=/path/to/lua5.1 LUA_INIT='WARM_PIRATE_V1=false' tools/tests/run-adventure-ui-tests.sh
LUA_BIN=/path/to/lua5.1 WARM_NATIVE_BIN=/path/to/tutorial-log-native tools/tests/run-warm-v1-tests.sh
/path/to/lua5.1 tools/tests/raised_map2_guard_regression.lua
mkdir -p "$O"/{guard-480,guard-360,hud-480,hud-360,objects-480,objects-360,controller,baseline}
for width in 480 360; do
  height=800; [ "$width" = 360 ] && height=640
  MAP2_GUARD_TEST=1 HUD_WIDTH=$width HUD_HEIGHT=$height RAISED_MAP2_LIVE_CAPTURE_DIR="$O/guard-$width" "$B" tools/tests/raised_map2_hud_boat_native.lua > "$O/guard-$width/native.log" 2>&1
  HUD_WIDTH=$width HUD_HEIGHT=$height RAISED_MAP2_LIVE_CAPTURE_DIR="$O/hud-$width" "$B" tools/tests/raised_map2_hud_boat_native.lua > "$O/hud-$width/native.log" 2>&1
  OBJECT_WIDTH=$width RAISED_MAP2_LIVE_CAPTURE_DIR="$O/objects-$width" "$B" tools/tests/raised_map2_live_objects_native.lua > "$O/objects-$width/native.log" 2>&1
done
RAISED_MAP2_LIVE_CAPTURE_DIR="$O/controller" "$B" tools/tests/raised_map2_live_native.lua > "$O/controller/native.log" 2>&1
LIVE_BASELINE_ONLY=1 RAISED_MAP2_LIVE_CAPTURE_DIR="$O/baseline" "$B" tools/tests/raised_map2_live_native.lua > "$O/baseline/native.log" 2>&1
python3 tools/tests/verify_raised_map2_hud_boat.py --guarded-rollout --evidence "$O"
```

The guard suite exercises exact original pixel fallback for sixteen missing
assets, six absent layers, malformed grid, duplicated layer, offset/bounds/order,
owner/model/coast/food/package mismatch, plus122 missing/noncallable optional API
entry points across install/refresh/disposal/deferred calls and50 malformed
palette/font/path/projection metadata cases; explicit opt-out and reentry preserve
original identities, hooks, bytes and zero presentation save writes. Existing
suites retain native movement/food/event/save parity, gesture cancellation,
object/art action fallback, nested owners, six active/paused context cycles and
listener/VBO stability. Native comparisons do not establish actual desktop UX.

## Acceptance bounds

- Fixed startup viewport480×800 and360×640 are the accepted desktop sizes.
  Existing zoom0.3/0.6/1 is covered by native controller projection tests.
  Live window resize/reflow, other aspect ratios, mobile and device performance
  are not accepted by this checkpoint. Restart at a supported startup size.
- Original-main application startup, controlled existing and markerless legacy
  map2 profiles, map1→map2 original selector reentry, cold save/reload, maps1/3
  unaffected and actual GUI gate are validated independently of the native
  component fixtures. A controlled markerless profile is not an authentic
  historical donor. No natural profile is edited for this work.
- The safe core280739a checkpoint and the original comparison route remain
  separately available. No remote publish, distribution or maps3–16 rollout.
- Historical `raised-map2-live`, `raised-map2-live-objects`, and `map2-hud-boat`
  acceptance records describe their original default-off gates. This document
  supersedes only their default selection for this guarded successor.
