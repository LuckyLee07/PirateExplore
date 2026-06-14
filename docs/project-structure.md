# Project Structure

`NewPirate` started as a Cocos2d-x Lua project where native code, platform projects, and resources all lived under `frameworks/runtime-src`.

The current layout follows the same top-level idea as `HelloOgre3D`:

```text
NewPirate/
  src/NewPirate/       native project code
  src/engine/          engine source code
  bin/res/             game resources and Lua scripts
  projects/            platform project entry points
  tools/               local project tools
  build/               generated local build output
  bin/                 runnable/package output area
```

The migration now makes `src`, `bin/res`, and `projects` the real owners of source, resources, and platform projects. The old `frameworks/` layout has been moved under `tools/legacy/frameworks` and only remains there as compatibility links for older Cocos scripts and legacy relative paths.

Native code is grouped as:

```text
src/NewPirate/client/        AppDelegate and native bridge entry code
src/NewPirate/common/        UtilTools shared helpers
src/NewPirate/game/ToLua/    custom Lua bindings
src/NewPirate/runtime/ios/   iOS app shell, services, and IAP code
src/NewPirate/runtime/mac/   macOS app shell
src/engine/cocos2d-x/        Cocos2d-x engine source
```

Legacy tools are grouped under:

```text
tools/legacy/frameworks/              old Cocos project skeleton
tools/legacy/runtime/ios/ios-sim    old Cocos iOS simulator launcher
```

Resources are exposed through:

```text
bin/res/
  scripts/
    LuaClass/
    mobdebug.lua
    legacy/
    archive/
  assets/
    data/
    Effect/
    fonts/
    Images/
    music/
```
