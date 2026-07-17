#!/usr/bin/env python3
"""Validate internal sample polish round 3: visible cause-and-effect feedback."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
CONTROLLER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterController.lua").read_text(encoding="utf-8")
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
LAYOUT_TEST = (ROOT / "tools/v2/test_v2_chapter_layout.lua").read_text(encoding="utf-8")
ROUND_TEST = (ROOT / "tools/v2/test_v2_internal_sample_3.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in (
    "function V2ChapterState.getCombatImpact(state)",
    'phase = "forecast"',
    'phase = "transfer"',
    "接舷预估｜甲板完整",
    "接舷预估｜甲板已击毁",
    "舰炮传递｜甲板完整",
    "舰炮传递｜甲板已击毁",
    "带着甲板优势接舷",
    "本次升级｜",
    "最大耐久 +%d（当前 %d）",
    "单次齐射伤害 +%d（火炮等级 %d）",
):
    if marker not in STATE:
        raise SystemExit(f"internal sample round 3 state marker missing: {marker}")

if "function V2ChapterController:getCombatImpact()" not in CONTROLLER:
    raise SystemExit("controller does not expose the combat impact model")
for marker in ("battleLine(state, impact)", "self.controller:getCombatImpact()", 'metrics .. "\\n" .. impact.text'):
    if marker not in LAYER:
        raise SystemExit(f"combat impact is not visibly wired into the layer: {marker}")

for marker in (
    "iPad three-line combat feedback stays above the latest-result line",
    "ipad.card_battle_size * 3",
):
    if marker not in LAYOUT_TEST:
        raise SystemExit(f"compact layout regression is missing: {marker}")

for marker in (
    "intact-deck forecast is player-readable",
    "forecast and actual boarding state match",
    "immediate boarding explains the missing advantage",
    "hull completion connects growth to the next voyage",
    "gun completion connects growth to the combat loop",
):
    if marker not in ROUND_TEST:
        raise SystemExit(f"round 3 behavioral regression is missing: {marker}")

if "lua tools/v2/test_v2_internal_sample_3.lua" not in PHASE4:
    raise SystemExit("round 3 behavioral regression is not part of the Phase 4 chain")

with (ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
issue = issues.get("V2-033")
if issue is None or issue["severity"] != "P2" or issue["status"] != "fixed":
    raise SystemExit("visible combat/payoff feedback issue V2-033 is not recorded as fixed P2")

doc_path = ROOT / "docs/v2/internal-sample-polish-3.md"
if not doc_path.is_file():
    raise SystemExit("internal sample round 3 acceptance record is missing")
doc = doc_path.read_text(encoding="utf-8")
for marker in (
    "V2-033", "甲板完整", "甲板已击毁", "船体", "火炮", "不扩建第二海域",
    "本轮验收结果：通过", "NewPirate-internal-sample-3-final.xcarchive",
):
    if marker not in doc:
        raise SystemExit(f"internal sample round 3 record missing marker: {marker}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample round 3 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in (
    "internal-sample-3-combat-impact.png",
    "internal-sample-3-boarding-transfer.png",
):
    screenshot = ROOT / "docs/v2" / filename
    if not screenshot.is_file() or png_dimensions(screenshot) != (750, 1334):
        raise SystemExit(f"internal sample round 3 evidence has unexpected dimensions: {filename}")

print("V2 internal sample polish round 3 contract OK: combat causality and upgrade payoff")
