#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase3.sh
lua tools/v2/test_v2_phase4.lua
lua tools/v2/test_v2_release_info.lua
python3 tools/v2/test_analyze_user_tests.py
python3 tools/v2/validate_phase4.py
python3 tools/v2/validate_player_presentation.py
python3 tools/v2/validate_internal_sample_2.py
lua tools/v2/test_v2_internal_sample_3.lua
python3 tools/v2/validate_internal_sample_3.py
lua tools/v2/test_v2_internal_sample_4.lua
python3 tools/v2/validate_internal_sample_4.py
lua tools/v2/test_v2_internal_sample_5.lua
python3 tools/v2/validate_internal_sample_5.py
lua tools/v2/test_v2_internal_sample_6.lua
python3 tools/v2/validate_internal_sample_6.py
python3 tools/v2/validate_internal_sample_freeze.py
lua tools/v2/test_v2_ui_theme.lua
python3 tools/v2/validate_ui2_iteration_1.py
python3 tools/v2/validate_ui2_iteration_2.py
python3 tools/v2/validate_ui3_style.py

echo "V2 Phase 4 internal validation passed; external gates remain pending"
