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

## Build

```bash
./xcode.sh mac
./xcode.sh ios-sim
./xcode.sh ios-device
./xcode.sh open
```

`ios-device` performs a compile-only device build with code signing disabled.
