#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

while IFS= read -r -d '' lua_file; do
    luac -p "$lua_file"
done < <(find bin/res/scripts/LuaClass -type f -name '*.lua' -print0)

lua tools/v2/test_v2_config.lua
python3 tools/v2/validate_phase0.py

echo "V2 Phase 0 validation passed"
