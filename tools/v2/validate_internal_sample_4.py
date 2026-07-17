#!/usr/bin/env python3
"""Validate internal sample polish round 4: pre-commitment decision previews."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
ROUND_TEST = (ROOT / "tools/v2/test_v2_internal_sample_4.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in ("qa_harbor = true", "qa_explore_intel = true"):
    if marker not in CONFIG:
        raise SystemExit(f"internal sample round 4 QA profile missing: {marker}")

for marker in (
    'profile == "qa_harbor"',
    'profile == "qa_explore" or profile == "qa_explore_intel"',
    "默认已装配加固船体，可直接出航",
    "加固船体｜耐久 +%d",
    "%s%s\\n齐射+%d｜补给%d",
    "按" + '" .. selected.name .. "\\n' + "配置出航",
    "先测绘｜花 ",
    "盲选 A｜外海方向",
    "盲选 B｜暗礁方向",
    "安全外海｜风险 %d",
    "暗礁近路｜风险 %d",
    "获得升级资源",
):
    if marker not in STATE:
        raise SystemExit(f"internal sample round 4 state marker missing: {marker}")

for marker in ('string.gmatch(action.label, "[^\\n]+")', "maximumLineLength > 36"):
    if marker not in LAYER:
        raise SystemExit(f"multi-line action sizing is missing: {marker}")

if "layout.action_label_width" not in LAYER:
    raise SystemExit("action labels do not use the responsive width model")

for marker in (
    "preparation explains the safe default",
    "heavy-gun button previews its tradeoff",
    "mapping action is prioritized as decision support",
    "safe-route button previews boarding tolerance",
    "risky-route button previews damage and payoff",
):
    if marker not in ROUND_TEST:
        raise SystemExit(f"internal sample round 4 regression missing: {marker}")

for command in (
    "lua tools/v2/test_v2_internal_sample_4.lua",
    "python3 tools/v2/validate_internal_sample_4.py",
):
    if command not in PHASE4:
        raise SystemExit(f"internal sample round 4 is not in the Phase 4 chain: {command}")

with (ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
issue = issues.get("V2-034")
if issue is None or issue["severity"] != "P2" or issue["status"] != "fixed":
    raise SystemExit("module/route preview issue V2-034 is not recorded as fixed P2")

doc_path = ROOT / "docs/v2/internal-sample-polish-4.md"
if not doc_path.is_file():
    raise SystemExit("internal sample round 4 acceptance record is missing")
doc = doc_path.read_text(encoding="utf-8")
for marker in (
    "V2-034", "耐久+20", "齐射+45", "盲选", "接舷上限 +10", "升级资源",
    "不扩建第二海域", "本轮验收结果：通过", "NewPirate-internal-sample-4-final.xcarchive",
):
    if marker not in doc:
        raise SystemExit(f"internal sample round 4 record missing marker: {marker}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample round 4 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in (
    "internal-sample-4-harbor-preview.png",
    "internal-sample-4-route-preview.png",
):
    screenshot = ROOT / "docs/v2" / filename
    if not screenshot.is_file() or png_dimensions(screenshot) != (750, 1334):
        raise SystemExit(f"internal sample round 4 evidence has unexpected dimensions: {filename}")

print("V2 internal sample polish round 4 contract OK: preparation and route consequences")
