#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase2.sh
lua tools/v2/test_v2_phase3.lua
python3 tools/v2/validate_phase3.py

echo "V2 Phase 3 validation passed"
