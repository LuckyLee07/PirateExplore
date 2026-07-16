#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase3.sh
lua tools/v2/test_v2_phase4.lua
python3 tools/v2/test_analyze_user_tests.py
python3 tools/v2/validate_phase4.py

echo "V2 Phase 4 internal validation passed; external gates remain pending"
