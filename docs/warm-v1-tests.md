# Warm v1 test runner

Run from any directory:

```sh
/path/to/repo/tools/tests/run-warm-v1-tests.sh logic
```

The logic mode parses every `LuaClass/Warm*.lua` module, then runs all
`tools/tests/warm_*_regression.lua` suites in separate Lua 5.1 processes.
It prefers `LUA_BIN`, then `$PIRATE_BUILD_DIR/tests/lua-ui-tests`, then a Lua
5.1 interpreter on PATH. The default build directory is `build/linux`.

For all logic and real Cocos/EGL component tests:

```sh
LUA_BIN=/path/to/lua5.1 \
WARM_NATIVE_BIN=/path/to/build/tests/tutorial-log-native \
PIRATE_RUNTIME=/optional/extracted/runtime \
  tools/tests/run-warm-v1-tests.sh all
```

Omit `PIRATE_RUNTIME` when the system supplies the runtime libraries. As in
`linux.sh`, an extracted runtime adds its `usr/bin` to PATH and
`usr/lib/x86_64-linux-gnu` to `LD_LIBRARY_PATH`. `WARM_NATIVE_BIN` defaults to
`$PIRATE_BUILD_DIR/tests/tutorial-log-native`. To build that EGL/LuaEngine harness
from an existing Linux Makefiles build:

```sh
PIRATE_BUILD_DIR=/path/to/existing/build \
PIRATE_RUNTIME=/optional/extracted/runtime \
  python3 tools/tests/run_tutorial_log_native.py
```

Use `native` to run only native suites. `all` never silently skips missing native
checks: missing dependencies return exit 2; any failed suite returns exit 1.
Every suite runs even if another suite fails, and the final summary lists exact
pass/fail counts. The runner removes inherited `LUA_INIT` so unrelated baseline
opt-out overrides cannot alter isolated test fixtures.

## Coverage

Current discovery includes eight logic suites and twelve native suites:

- Activities, business surfaces, departure, persistent memories, navigation /
  settings, atomic upgrades, pause checkpoints, and successful-return regressions
- Native activities, business, collection / exhibit / cargo-log pagination,
  departure, exploration HUD, Home / contextual dialogs, settings, upgrades,
  pause lifecycle, real Director cold-resume transitions, and return summaries

The exploration native suite extends the isolated warm-v1 QA check with the
warm-only pause entry. It covers warm and legacy palettes, existing movement/return
callbacks, per-step food changes in its fixture, HUD bounds, navigation overlays,
and cleanup. It does not load a real map or player save.

All tests use isolated fixtures. Real native suites use Cocos nodes, shipped
assets/fonts, MenuItem callbacks, and lifecycle cleanup; some gameplay and
persistence boundaries remain in memory. They do not replace the separate
full-game visual, cold-restart, combat, map, and actual-save acceptance run.

## Final runner result

2026-10-11 UTC: eleven Warm modules parsed; eight logic suites passed; twelve
native suites passed, including actual pending scene replacement through the
production controller and running-dialog owner teardown. All 20 suites passed
after the cold-resume timing and reentrant owner-token cleanup fixes.
The activities fixture now loads the actual WarmUpgrade preview and verifies
read-only prerequisite/recipe handoff and cancellation instead of expecting the
superseded immediate construction/manufacturing route.
