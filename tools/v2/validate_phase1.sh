#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase0.sh
python3 tools/v2/export_runtime.py --check
lua tools/v2/test_v2_chapter_state.lua
python3 tools/v2/validate_phase1.py

echo "V2 Phase 1 validation passed"
