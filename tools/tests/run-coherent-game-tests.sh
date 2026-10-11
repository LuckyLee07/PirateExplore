#!/usr/bin/env bash
# Native presentation and gameplay conservation. Full-game desktop QA is separate.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
LUA="${LUA_BIN:-lua5.1}"
NATIVE="${WARM_NATIVE_BIN:-${PIRATE_BUILD_DIR:-$ROOT/build/linux}/tests/tutorial-log-native}"
command -v "$LUA" >/dev/null
[[ -x "$NATIVE" ]] || { echo 'Build the Cocos/EGL harness first; see run-warm-v1-tests.sh.' >&2; exit 2; }
export MESA_SHADER_CACHE_DISABLE=true
LUA_BIN="$LUA" WARM_NATIVE_BIN="$NATIVE" bash tools/tests/run-warm-v1-tests.sh all
for test in tools/tests/coherent_*regression.lua; do
    env -u LUA_INIT "$LUA" "$test"
done
for test in tools/tests/coherent_*native.lua; do
    [[ "$test" == tools/tests/coherent_pause_close_native.lua ]] && continue
    env -u LUA_INIT "$NATIVE" "$test"
done
python3 tools/tests/coherent_pause_close_regression.py
python3 tools/tests/coherent_curl_headers_regression.py
python3 tools/tests/coherent_http_shutdown_regression.py
LUA_BIN="$LUA" LUA_INIT='WARM_PIRATE_V1=false' bash tools/tests/run-adventure-ui-tests.sh
"$LUA" tools/tests/clean_voyage_view_regression.lua
"$LUA" tools/tests/clean_voyage_hud_regression.lua
python3 tools/tests/clean_first_map_regression.py "$LUA"
python3 tools/tests/heading_font_coverage_regression.py
git diff --check
printf '\nPASS coherent game aggregate: Warm, focused native, legacy opt-out, clean map and fonts\n'
