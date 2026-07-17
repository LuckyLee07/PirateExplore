#!/usr/bin/env python3
"""Validate internal sample polish round 5: loot-to-upgrade conversion."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
ROUND_TEST = (ROOT / "tools/v2/test_v2_internal_sample_5.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

if "qa_upgrade = true" not in CONFIG or 'profile == "qa_upgrade"' not in STATE:
    raise SystemExit("internal sample round 5 upgrade QA profile is missing")

for marker in (
    "追猎者战利品｜金币 +%d · 木材 +%d · 铁料 +%d · 符文尘 +%d",
    "符文碎片｜符文尘 +%d，并指向潮汐墓场",
    "返航后可选：耐久 +%d，或单次齐射 +%d",
    'label = "加固船体\\n木材-"',
    'label = "强化火炮\\n铁料-"',
    "木材 -%d → 最大耐久 +%d",
    "铁料 -%d → 单次齐射 +%d",
):
    if marker not in STATE:
        raise SystemExit(f"internal sample round 5 state marker missing: {marker}")

for marker in (
    "battle loot is itemized",
    "rune clue reward and purpose are itemized",
    "hull upgrade explains cost and outcome before payment",
    "gun upgrade explains cost and outcome before payment",
    "gun completion agrees with the pre-commitment preview",
):
    if marker not in ROUND_TEST:
        raise SystemExit(f"internal sample round 5 regression missing: {marker}")

for command in (
    "lua tools/v2/test_v2_internal_sample_5.lua",
    "python3 tools/v2/validate_internal_sample_5.py",
):
    if command not in PHASE4:
        raise SystemExit(f"internal sample round 5 is not in the Phase 4 chain: {command}")

with (ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
issue = issues.get("V2-035")
if issue is None or issue["severity"] != "P2" or issue["status"] != "fixed":
    raise SystemExit("loot conversion issue V2-035 is not recorded as fixed P2")

doc_path = ROOT / "docs/v2/internal-sample-polish-5.md"
if not doc_path.is_file():
    raise SystemExit("internal sample round 5 acceptance record is missing")
doc = doc_path.read_text(encoding="utf-8")
for marker in (
    "V2-035", "金币 +35", "木材 +10", "铁料 +15", "符文尘 +5",
    "耐久+20", "齐射+25", "不扩建第二海域", "本轮验收结果：通过",
    "NewPirate-internal-sample-5-final.xcarchive",
):
    if marker not in doc:
        raise SystemExit(f"internal sample round 5 record missing marker: {marker}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample round 5 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in ("internal-sample-5-settlement.png", "internal-sample-5-upgrade.png"):
    screenshot = ROOT / "docs/v2" / filename
    if not screenshot.is_file() or png_dimensions(screenshot) != (750, 1334):
        raise SystemExit(f"internal sample round 5 evidence has unexpected dimensions: {filename}")

print("V2 internal sample polish round 5 contract OK: loot and upgrade conversion")
