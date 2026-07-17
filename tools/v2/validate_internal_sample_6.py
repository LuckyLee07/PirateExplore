#!/usr/bin/env python3
"""Validate internal sample polish round 6: transparent failure recovery."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
ROUND_TEST = (ROOT / "tools/v2/test_v2_internal_sample_6.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

if "qa_failed = true" not in CONFIG or 'profile == "qa_failed"' not in STATE:
    raise SystemExit("internal sample round 6 failure QA profile is missing")

for marker in (
    'label = "原地重试\\n补给-"',
    'label = "返港恢复\\n金币-"',
    "保留当前航线与已确认战利品",
    "保留已确认战利品，清除航线损伤",
    "选择原地重试或带着已确认收获返港",
):
    if marker not in STATE:
        raise SystemExit(f"internal sample round 6 state marker missing: {marker}")

for marker in (
    "retry spends the previewed supply",
    "retry preserves the route",
    "retry preserves route damage context",
    "port recovery spends the previewed gold",
    "port recovery clears the old route",
    "port recovery clears route damage",
    "insufficient retry directs the player to the valid recovery",
):
    if marker not in ROUND_TEST:
        raise SystemExit(f"internal sample round 6 regression missing: {marker}")

for command in (
    "lua tools/v2/test_v2_internal_sample_6.lua",
    "python3 tools/v2/validate_internal_sample_6.py",
):
    if command not in PHASE4:
        raise SystemExit(f"internal sample round 6 is not in the Phase 4 chain: {command}")

with (ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
issue = issues.get("V2-036")
if issue is None or issue["severity"] != "P2" or issue["status"] != "fixed":
    raise SystemExit("failure recovery issue V2-036 is not recorded as fixed P2")

doc_path = ROOT / "docs/v2/internal-sample-polish-6.md"
if not doc_path.is_file():
    raise SystemExit("internal sample round 6 acceptance record is missing")
doc = doc_path.read_text(encoding="utf-8")
for marker in (
    "V2-036", "补给 -1", "金币 -5", "保留当前航线", "清除航线损伤",
    "保留已确认战利品", "不改变战斗数值", "本轮验收结果：通过",
    "NewPirate-internal-sample-6-final.xcarchive",
):
    if marker not in doc:
        raise SystemExit(f"internal sample round 6 record missing marker: {marker}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample round 6 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


screenshot = ROOT / "docs/v2/internal-sample-6-failed.png"
if not screenshot.is_file() or png_dimensions(screenshot) != (750, 1334):
    raise SystemExit("internal sample round 6 evidence has unexpected dimensions")

print("V2 internal sample polish round 6 contract OK: transparent failure recovery")
