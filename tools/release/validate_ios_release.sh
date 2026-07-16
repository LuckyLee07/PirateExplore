#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

tools/v2/validate_phase4.sh
python3 tools/release/validate_ios_release.py

echo "iOS V2 release regression and static validation passed"
