#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase4.sh
tools/release/test_record_codec.sh
tools/release/test_ccdata_ownership.sh
python3 tools/release/validate_ios_release.py
python3 tools/release/validate_app_store_assets.py
python3 tools/release/validate_public_release_pages.py
python3 tools/release/validate_app_store_submission.py

echo "iOS V2 release regression and static validation passed"
