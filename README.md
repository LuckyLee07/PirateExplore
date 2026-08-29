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
./xcode.sh ios-archive
./xcode.sh open
```

`ios-device` performs a compile-only device build with code signing disabled. `ios-archive`
creates a deterministic unsigned Release archive at `build/archives/NewPirate.xcarchive`;
set `CODE_SIGNING_ALLOWED=YES` only after selecting the App Store Connect team and signing assets.

## Product Documentation

- Current product and development baseline (Chinese):
  [`docs/product-iteration-plan-v2.md`](docs/product-iteration-plan-v2.md)
- Historical management-first plan:
  [`docs/product-long-term-iteration-plan.md`](docs/product-long-term-iteration-plan.md)
- Art direction:
  [`docs/art-direction-app-store.md`](docs/art-direction-app-store.md)
- Iteration log:
  [`docs/product-iteration-log.md`](docs/product-iteration-log.md)
- V2 Phase 1 playable graybox and validation:
  [`docs/v2/phase-1-graybox.md`](docs/v2/phase-1-graybox.md),
  [`docs/v2/phase-1-validation.md`](docs/v2/phase-1-validation.md)
- V2 Phase 2 exploration/combat decisions and validation:
  [`docs/v2/phase-2-exploration-combat.md`](docs/v2/phase-2-exploration-combat.md),
  [`docs/v2/phase-2-validation.md`](docs/v2/phase-2-validation.md)
- V2 Phase 3 content/art sample and validation:
  [`docs/v2/phase-3-content-art.md`](docs/v2/phase-3-content-art.md),
  [`docs/v2/phase-3-validation.md`](docs/v2/phase-3-validation.md)
- V2 Phase 4 testing, internal quality audit, and provisional decision:
  [`docs/v2/phase-4-user-test-protocol.md`](docs/v2/phase-4-user-test-protocol.md),
  [`docs/v2/phase-4-quality-audit.md`](docs/v2/phase-4-quality-audit.md),
  [`docs/v2/phase-4-decision.md`](docs/v2/phase-4-decision.md),
  [`docs/v2/phase-4-completion-audit.md`](docs/v2/phase-4-completion-audit.md)
- V2 retained-growth loop, playable Tide Graveyard second voyage, Royal Port logistics, crew growth, character event, and Guardian visual:
  [`docs/v2/repeat-voyage-iteration-1.md`](docs/v2/repeat-voyage-iteration-1.md),
  [`docs/v2/second-voyage-iteration-1.md`](docs/v2/second-voyage-iteration-1.md),
  [`docs/v2/port-logistics-iteration-1.md`](docs/v2/port-logistics-iteration-1.md),
  [`docs/v2/crew-growth-iteration-1.md`](docs/v2/crew-growth-iteration-1.md),
  [`docs/v2/tide-character-event-iteration-1.md`](docs/v2/tide-character-event-iteration-1.md),
  [`docs/v2/tide-guardian-visual-iteration-1.md`](docs/v2/tide-guardian-visual-iteration-1.md),
  [`docs/v2/content-expansion-pipeline-iteration-1.md`](docs/v2/content-expansion-pipeline-iteration-1.md)
- iOS release engineering baseline and App Store metadata draft:
  [`docs/release/ios-release-readiness.md`](docs/release/ios-release-readiness.md),
  [`docs/release/app-store-metadata-zh-CN.md`](docs/release/app-store-metadata-zh-CN.md),
  [`docs/release/ios-release-engineering-iteration-1.md`](docs/release/ios-release-engineering-iteration-1.md)
