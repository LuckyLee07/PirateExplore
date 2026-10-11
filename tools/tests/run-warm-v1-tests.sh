#!/usr/bin/env bash
# Warm-v1 fixture and real Cocos/EGL checks. No player profile or GUI is opened.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
BUILD="${PIRATE_BUILD_DIR:-$ROOT/build/linux}"
MODE="${1:-all}"
case "$MODE" in
  all|--all) LOGIC=1; NATIVE=1 ;;
  logic|--logic-only) LOGIC=1; NATIVE=0 ;;
  native|--native-only) LOGIC=0; NATIVE=1 ;;
  -h|--help)
    cat <<'HELP'
Usage: tools/tests/run-warm-v1-tests.sh [all|logic|native]
  all (default)  Parse Warm modules; run every warm regression and native test.
  logic          Parse Warm modules; run warm_*_regression.lua with Lua 5.1.
  native         Run warm_*_native.lua with the real Cocos/EGL LuaEngine harness.
Environment:
  LUA_BIN             Lua 5.1 executable (otherwise build/tests, then PATH).
  WARM_NATIVE_BIN     tutorial-log-native-compatible native executable.
  PIRATE_BUILD_DIR    Existing Linux build (default: build/linux).
  PIRATE_RUNTIME      Optional extracted SDK/runtime, as in linux.sh.
The runner never silently skips native tests in all mode. Native results are
isolated component/fixture checks, not full-game GUI or save acceptance.
HELP
    exit 0 ;;
  *) echo "Unknown mode: $MODE. Use all, logic, native, or --help." >&2; exit 2 ;;
esac
if (( $# > 1 )); then echo 'Only one mode argument is supported.' >&2; exit 2; fi
if [[ -n "${PIRATE_RUNTIME:-}" ]]; then
  export PATH="$PIRATE_RUNTIME/usr/bin:$PATH"
  export LD_LIBRARY_PATH="$PIRATE_RUNTIME/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
export MESA_SHADER_CACHE_DISABLE="${MESA_SHADER_CACHE_DISABLE:-true}"
LUA="${LUA_BIN:-}"
if (( LOGIC )); then
  if [[ -z "$LUA" && -x "$BUILD/tests/lua-ui-tests" ]]; then LUA="$BUILD/tests/lua-ui-tests"; fi
  if [[ -z "$LUA" ]]; then
    for candidate in lua5.1 lua; do
      if command -v "$candidate" >/dev/null 2>&1; then LUA="$(command -v "$candidate")"; break; fi
    done
  fi
  if [[ -z "$LUA" ]] || ! command -v "$LUA" >/dev/null 2>&1; then
    echo 'Lua 5.1 unavailable. Set LUA_BIN or build the native Linux target/tests first.' >&2
    exit 2
  fi
  env -u LUA_INIT "$LUA" -e 'assert(_VERSION == "Lua 5.1", "Warm tests require Lua 5.1 or LuaJIT (set LUA_BIN)")'
fi
NATIVE_BIN="${WARM_NATIVE_BIN:-$BUILD/tests/tutorial-log-native}"
if (( NATIVE )) && ! command -v "$NATIVE_BIN" >/dev/null 2>&1; then
  cat >&2 <<'HELP'
Native Cocos/EGL harness unavailable. Set WARM_NATIVE_BIN to an existing
tutorial-log-native executable, or build it from an existing Linux Makefiles
build with python3 tools/tests/run_tutorial_log_native.py (honors
PIRATE_BUILD_DIR and PIRATE_RUNTIME). Use logic mode for logic-only checks.
HELP
  exit 2
fi
shopt -s nullglob
LOGIC_TESTS=(tools/tests/warm_*_regression.lua)
NATIVE_TESTS=(tools/tests/warm_*_native.lua)
SOURCES=(bin/res/scripts/LuaClass/Warm*.lua)
if (( ${#LOGIC_TESTS[@]} == 0 || ${#NATIVE_TESTS[@]} == 0 || ${#SOURCES[@]} == 0 )); then
  echo 'Warm test or source discovery returned an empty set.' >&2; exit 2
fi
PASS=0; FAIL=0; LOGIC_PASS=0; NATIVE_PASS=0
FAILED=()
if (( LOGIC )); then
  echo "== Parse ${#SOURCES[@]} Warm modules =="
  env -u LUA_INIT "$LUA" - "${SOURCES[@]}" <<'LUA'
for _,path in ipairs(arg) do assert(loadfile(path));print('PARSE PASS '..path) end
LUA
  for test in "${LOGIC_TESTS[@]}"; do
    echo "== LOGIC $test =="
    if env -u LUA_INIT "$LUA" "$test"; then
      PASS=$((PASS+1)); LOGIC_PASS=$((LOGIC_PASS+1))
      echo "SUITE PASS $test"
    else
      FAIL=$((FAIL+1)); FAILED+=("$test")
      echo "SUITE FAIL $test" >&2
    fi
  done
fi
if (( NATIVE )); then
  for test in "${NATIVE_TESTS[@]}"; do
    echo "== NATIVE $test =="
    if env -u LUA_INIT "$NATIVE_BIN" "$test"; then
      PASS=$((PASS+1)); NATIVE_PASS=$((NATIVE_PASS+1))
      echo "SUITE PASS $test"
    else
      FAIL=$((FAIL+1)); FAILED+=("$test")
      echo "SUITE FAIL $test" >&2
    fi
  done
fi
echo "WARM V1 SUMMARY: passed=$PASS failed=$FAIL logic=$LOGIC_PASS native=$NATIVE_PASS mode=$MODE"
if (( FAIL )); then
  printf 'Failed suite: %s\n' "${FAILED[@]}" >&2
  exit 1
fi
