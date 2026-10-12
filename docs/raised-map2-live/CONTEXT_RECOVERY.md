# Separately reviewable context-recovery repairs

**The adapter remains dormant. Passing this native fixture is not activation or
Android-device acceptance.** Frozen adapter `19eff906e66d73647b421d78e1cadd7d2b771e3e`
and its historical `ACCEPTANCE.md` / `VERIFICATION.json` are unchanged. This
receipt supersedes only their context diagnosis, not their remaining visual,
input-device, gameplay-session or mobile gates.

## Minimal production patches

1. `e395c3bcbc1d3281fd744e0d9c6236979f90e5f8` changes only
   `CCTexture2D.cpp`. During the existing volatile reload phase, forget the
   destroyed context's numeric texture handle instead of deleting that number
   from the replacement context. Same-context texture replacement still deletes
   its own old texture. The existing cache macro excludes the guard on ordinary
   desktop builds. No header, public API or class layout changes.
2. `ae79225784b78abd950e0058694f61d82fa0a998` changes only
   `AdventureNavigationView.lua`. The passive route DrawNode alone keeps its
   native context event listener eligible while its map is scene-suspended;
   cleanup pauses it again. No owner, scheduler or action target is resumed.
3. `5cf2f5d7123908b9a7072c2fc7cef13cd00c2ce8` changes only
   `CCDrawNode.cpp`. Move the existing scene-priority context listener to the
   constructor, registering once for the Node's lifetime. The existing Node
   destructor owns removal. The callback forgets old-context VBO/VAO numbers
   without deleting them, then rebuilds via the existing init. No header, public
   API or class layout changes; all code remains under the existing cache macro.

The presentation feature flag is never enabled here. No EventLayer patch, map,
CSV, alpha mask, collision, event ID, movement/cost/timer/save or source art is
changed. Do not merge the historical ancestor over the current candidate; apply
only reviewed patches and retain the candidate's `E.alive` input shield.

## Demonstrated causes and counterfactuals

The native fixture destroys/recreates an actual Mesa EGL context, then follows
this revision's Android `javaactivity.cpp::nativeInit` recovery sequence exactly:
GL state-cache invalidation, default shaders, DrawPrimitives, volatile textures,
foreground dispatch, default GL state. Native Android pause code is reused. It
is a Linux emulation of that sequence, not an Android runtime claim.

- Unfixed Texture2D deleted **11 already-live texture names per restore**, 22
  across two restores, detected at the real GL call boundary. Clean water and
  sand GPU bytes changed. The separate ordinary route had exact active pixels.
  Rebuilding adapter nodes did not repair those corrupted GPU bytes.
- Texture repair restored exact active pixels and GPU hashes. Suspended route
  lines still differed by 434 pixels live and 388 pixels on the independent
  ordinary route. Only the passive route listener correction removed that
  discrepancy; scene/action suspension remains in force.
- A broader buffer probe then found a separate native lifetime defect despite
  correct pixels. Unfixed DrawNode's context callback calls init, which registers
  another callback. Across cycles 2–6, maximum listeners per DrawNode doubled
  4, 8, 16, 32, 64. Live route: 19 nodes accumulated 54, 108, 172, 344, 600
  listeners; original route: 12 nodes accumulated 26, 52, 60, 120, 152. VBO names
  grew in both fresh processes. The counterfactual verifier reports failure.

Historical failure images/logs remain outside the repository under the audit
root listed below. `CONTEXT_COUNTERFACTUALS.json` records their hashes and narrow
comparison results. The original failed `VERIFICATION.json` is not overwritten.

## Fixed native results

`CONTEXT_VERIFICATION.json` separates pixel/texture parity, resource lifetime,
and activation readiness. Activation readiness remains false.

- Six alternating active/suspended context recreations on each route: every
  compared native image has zero changed pixels and maximum channel error 0.
- All sampled source/clean GPU texture hashes match before/after and cycles 3–6.
- Live texture names / volatile cache entries stay **41 / 41**; stale live-name
  deletion count remains zero. Same-context texture replacement deletes exactly
  one old texture and final release returns the resource count to baseline.
- Live route: **19 DrawNodes / 19 listeners**, maximum one listener per node.
  VBO counts are stable per recovery phase: suspended 50, active 61.
- Original route: **12 / 12**, maximum one per node; suspended 43, active 54.
  Comparing like phases matters because scene-paused native listeners and
  temporary rendering resources differ between active and suspended recovery.
- The dormant adapter's movement/input/fog/save contracts still pass: 2,883
  transforms, identical movement/cost/reveal/event/occupied traces, zero toggle
  save writes, native animated fog action identity, pause/save/resume, child
  insertion/removal, 638,309 exact partial/unknown pixels and 96 protected files.
- Both modified native source files compile with **cache macro 0 and 1** using
  this worktree's bundled headers. This checks the existing desktop and
  Android/WP8 conditional branches with the Linux compiler; it is not a mobile
  cross-link or device build. Independent target-wrapper syntax attempts using
  host GCC were **blocked** by unavailable SDK headers: Android `android/log.h`,
  iOS `OpenGLES/ES2/gl.h`, macOS `OpenGL/gl.h`. No Android or Apple compile pass is
  claimed. Exact attempts are preserved in the independent review's
  `platform-header-checks.json` and `platform-{android,ios,macos}-{CCTexture2D,CCDrawNode}.log`.
  Legacy compiler warnings remain in bundled code.

These are bounded six-cycle texture/VBO-name/listener checks, not a blanket
process/driver memory-leak guarantee. Existing failed asset reload/uncached
texture behavior is not redesigned. Full event/combat/return, device rendering,
mobile profiling, native actors/semantic art and populated-route visual
acceptance remain pending. Independent review owns its additional evidence.

## Reproduce without profiles or GUI

Use a separate output directory. The script only reads donor objects/libraries,
compiles current Texture2D/DrawNode and fixture sources, and records source,
donor object, archive, compiler and binary provenance in `BUILD_RECEIPT.json`.
It must not link the old donor Texture2D or DrawNode objects alongside replacements.

```sh
ROOT=/workspace/scratch/79976da795e7/PirateExplore-live-map2-context-fix
AUDIT=/workspace/shared/pirate-audit
cd "$ROOT"
export PIRATE_BUILD_DIR=../PirateExplore-coherent/build/linux
export CLEAN_WORLD_BUILD_DIR="$AUDIT/clean-world-native"
export RAISED_MAP2_LIVE_BUILD_DIR="$AUDIT/raised-map2-lifetime-fixed-build"
export PIRATE_RUNTIME=/workspace/scratch/79976da795e7/linux-runtime
python3 tools/tests/build_raised_map2_live_native.py
export LD_LIBRARY_PATH="$PIRATE_RUNTIME/usr/lib/x86_64-linux-gnu"
export EGL_PLATFORM=surfaceless MESA_SHADER_CACHE_DISABLE=true LIVE_FULL_THEME=1
mkdir -p "$AUDIT/raised-map2-lifetime-fixed" "$AUDIT/raised-map2-lifetime-fixed-baseline"
LIVE_BASELINE_ONLY=1 RAISED_MAP2_LIVE_CAPTURE_DIR="$AUDIT/raised-map2-lifetime-fixed-baseline" \
  "$RAISED_MAP2_LIVE_BUILD_DIR/raised-map2-live-native" tools/tests/raised_map2_live_native.lua \
  > "$AUDIT/raised-map2-lifetime-fixed-baseline/native.log" 2>&1
RAISED_MAP2_LIVE_CAPTURE_DIR="$AUDIT/raised-map2-lifetime-fixed" \
  "$RAISED_MAP2_LIVE_BUILD_DIR/raised-map2-live-native" tools/tests/raised_map2_live_native.lua \
  > "$AUDIT/raised-map2-lifetime-fixed/native.log" 2>&1
python3 tools/tests/verify_raised_map2_live.py \
  --capture-dir "$AUDIT/raised-map2-lifetime-fixed" \
  --baseline-dir "$AUDIT/raised-map2-lifetime-fixed-baseline"
LUA_BIN=/workspace/shared/lua51 LUA_INIT='WARM_PIRATE_V1=false' \
  bash tools/tests/run-adventure-ui-tests.sh
```

For a new independent run, replace all output directories above so frozen
captures are preserved. Fixtures use disposable, explicitly seeded in-memory
state; native controller paths are real, event/combat completions deterministic
probes. No personal profile or disk game-save is loaded or mutated.

Audit evidence directories:

- `raised-map2-live-frozen-failure`, `raised-map2-live-frozen-baseline`: frozen
  adapter before native repairs, exact sequence and source/raised isolation.
- `raised-map2-context-probe`: original texture call-boundary collision evidence.
- `raised-map2-context-route-baseline`: ordinary suspended route-line failure.
- `raised-map2-buffer-counterfactual` and `-baseline`: repaired texture/route,
  original DrawNode; direct listener/VBO growth, preserved failing verifier.
- `raised-map2-lifetime-fixed`, `-baseline`, `-build`: final native fixes.

Final fixture EOF normalization was replayed with the unchanged hashed native
binary in `raised-map2-hygiene-final` and `-baseline`; all six-cycle contracts
pass. `CONTEXT_BUILD.json` binds the exact normalized Lua source and prior hash.
