#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase4.sh
tools/release/test_record_codec.sh
tools/release/test_ccdata_ownership.sh
tools/release/test_fileutils_read.sh
tools/release/test_userdefault_xml.sh
tools/release/test_texture_atlas_allocation.sh
python3 tools/release/test_eaglview_contract.py
python3 -B tools/release/test_apple_signing_readiness.py
python3 -B tools/release/test_validate_ios_signed_app.py
python3 -B tools/release/test_final_app_store_gate.py
python3 -B tools/release/test_validate_device_acceptance.py
python3 -B tools/release/test_final_product_launch_gate.py
python3 -B tools/release/test_archive_provenance.py
python3 tools/release/validate_ios_release.py
python3 tools/release/validate_app_store_assets.py
python3 tools/release/validate_public_release_pages.py
python3 tools/release/validate_app_store_submission.py

echo "iOS V2 release regression and static validation passed"
