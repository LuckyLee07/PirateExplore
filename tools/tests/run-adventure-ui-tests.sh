#!/usr/bin/env bash
# Native Lua logic smoke tests; these do not replace the documented GUI checks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
LUA="${LUA_BIN:-}"
if [[ -z "$LUA" ]]; then
  for candidate in lua5.1 lua; do
    if command -v "$candidate" >/dev/null; then LUA="$(command -v "$candidate")"; break; fi
  done
fi
if [[ -z "$LUA" ]]; then
  BUILD="${PIRATE_BUILD_DIR:-$ROOT/build/linux}"
  if [[ ! -f "$BUILD/lib/liblua.a" ]]; then
    echo 'Build the native Linux target first, or set LUA_BIN to a Lua 5.1 interpreter.' >&2
    exit 1
  fi
  mkdir -p "$BUILD/tests"
  cc -I src/engine/cocos2d-x/external/lua/lua \
    src/engine/cocos2d-x/external/lua/lua/lua.c "$BUILD/lib/liblua.a" \
    -lm -ldl -o "$BUILD/tests/lua-ui-tests"
  LUA="$BUILD/tests/lua-ui-tests"
fi
"$LUA" -e 'for _,f in ipairs({"BTheme","HomeTheme","MasterTheme","Home","MainMenu","Dispatch","Expedition","Explore","ToastUtil","NotificationNode"}) do assert(loadfile("bin/res/scripts/LuaClass/"..f..".lua")); print("PARSE PASS "..f) end'
for test in home_master_regression expedition_ui_regression explore_hud_smoke; do
  "$LUA" "tools/tests/$test.lua"
done
