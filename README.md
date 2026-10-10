# NewPirate

This repository keeps the original Cocos2d-x project intact, but exposes a flatter project layout similar to `HelloOgre3D`.

## Layout

- `src/NewPirate/client` - application bootstrap and native bridge entry points.
- `src/NewPirate/common` - shared native utilities.
- `src/NewPirate/game` - Lua binding/game-facing native code.
- `src/NewPirate/runtime` - platform app shell code for iOS and macOS.
- `src/engine/cocos2d-x` - Cocos2d-x engine source.
- `bin/res/scripts` - Lua scripts and legacy script archives.
- `bin/res/assets` - data tables, images, effects, fonts, and music.
- `projects` - platform project entry points.
- `tools` - local and legacy project tools.
- `build` - local generated build output.
- `bin` - reserved for runnable/package outputs.

The top-level project layout owns the real source and platform project directories. Resources live under `bin/res` so runnable/package outputs and source resources share the same shape. The engine source is under `src/engine`, and the old Cocos `frameworks/` layout now lives under `tools/legacy/frameworks` as compatibility links for older scripts and relative paths.

The old Cocos simulator launcher previously stored at the repository root under `runtime/` now lives in `tools/legacy/runtime/ios/ios-sim`.

## Build status and prerequisites

This checkout contains a working **Linux x86-64** application entry and bundled
engine source. The original `projects/ios_mac/NewPirate.xcodeproj`, Android app
project, and Windows app project are **not included**. Platform bridge source
and legacy links do not constitute complete application projects. The top-level
`.gitignore` excludes `projects/*`; `projects/linux/main.cpp` is explicitly
tracked. Preserve the original platform projects separately until they can be
reviewed and deliberately added to version control.

### Linux (implemented and natively tested)

Requires CMake 3.18+, a C/C++11 toolchain, GLFW development headers/libraries,
FreeType, WebP, and the dependencies used by the bundled Cocos engine. The
bundled FMOD/WebSockets libraries require 64-bit x86 Linux. A graphical display
is needed for the real application; source/GL tests do not replace UI tests.

```bash
./linux.sh build
./linux.sh run 480 800
LUA_BIN=/path/to/lua5.1 ./tools/tests/run-adventure-ui-tests.sh
```

`linux.sh run` uses a separate `build/linux/player-data` profile by default.
Set `PIRATE_SAVE_DIR` to another disposable profile for tests. Never point test
fixtures at a player's existing save. The runtime dependency directory used
in the cloud QA environment is external to the repository; it is not an
installed-system dependency guarantee.

### Apple (original application project required)

Restore the original application project, then use a Mac with Xcode. The
wrapper below now reports missing project/toolchain prerequisites before
attempting a build. No macOS, iOS simulator or physical iOS-device build has
been accepted for this reconstructed checkout.

```bash
./xcode.sh mac
./xcode.sh ios-sim
./xcode.sh ios-device
./xcode.sh open
```

`ios-device` performs a compile-only device build with code signing disabled.

### Release and service boundaries

- Diagnostic logging (`zqDebug`) is separate from the default-off destructive
  developer menu (`zqDebugMenuEnabled`). Keep the latter off in player builds.
- The legacy leaderboard endpoint is empty and redemption has no working
  backend in the supplied project. Offline failure handling is testable;
  working online services, purchases and mobile SDK integration need their
  actual configuration and platform verification.
- Android context restoration, mobile performance/audio, signing and store
  deployment need platform/device checks; Linux validation does not cover them.
- See `docs/native-closure-20261009.md`, `docs/chart-edge-repair.md` and
  `docs/remaining-b-art-progress.md` for exact native/fixture boundaries.
