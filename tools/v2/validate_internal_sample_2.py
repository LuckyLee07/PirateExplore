#!/usr/bin/env python3
"""Validate internal sample polish round 2: copy, completion QA, and save recovery."""

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
CONTROLLER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterController.lua").read_text(encoding="utf-8")
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
STATE_TEST = (ROOT / "tools/v2/test_v2_chapter_state.lua").read_text(encoding="utf-8")
PHASE4_TEST = (ROOT / "tools/v2/test_v2_phase4.lua").read_text(encoding="utf-8")

for marker in (
    "V2ChapterState.SAVE_RECOVERY_MESSAGE",
    "local function isRestorableState(state)",
    "local function hasNumberFields(value, fields)",
    "local function hasBooleanFields(value, fields)",
    "routeRequiredStages",
    'profile == "qa_complete"',
    'and "restart_chapter" or "prepare_next_voyage"',
    'and "重置首章（QA）" or "准备下一次远航\\n保留升级与库存"',
    'or "迷雾重新聚拢，新的首章航程已经开始。"',
):
    if marker not in STATE:
        raise SystemExit(f"internal sample round 2 state marker missing: {marker}")

for marker in (
    "local normalized, validationMessage = V2ChapterState.normalize(decoded, profile)",
    'self.state.objective = "存档已安全恢复，可以重新开始第一章"',
    "self.state.last_result = recoveryMessage",
):
    if marker not in CONTROLLER:
        raise SystemExit(f"save recovery controller marker missing: {marker}")

if "qa_complete = true" not in CONFIG:
    raise SystemExit("QA completion profile is not registered")
for marker in (
    'addMeter(parent, "我方船体"',
    'addMeter(parent, "敌方船体"',
    'addMeter(parent, "我方接舷队"',
    'addMeter(parent, "敌方甲板部队"',
):
    if marker not in LAYER:
        raise SystemExit(f"player-facing combat composition is missing marker: {marker}")

for leaked_label in (
    "重玩首章（测试）",
    "首章测试进度已重置",
    "理解甲板破坏传递",
    "双阶段战斗",
):
    if leaked_label in STATE or leaked_label in LAYER:
        raise SystemExit(f"internal/development copy still leaks into player runtime: {leaked_label}")

for marker in (
    'brokenResources.resources = "corrupted"',
    'brokenBattle.battle.crew_hp = "unknown"',
    'brokenBattle.battle.actions_log = "missing"',
    "valid current save does not report recovery",
):
    if marker not in STATE_TEST:
        raise SystemExit(f"nested recovery regression coverage missing: {marker}")
for marker in (
    'malformed.ship = { hull_level = "broken" }',
    "malformed nested save explains the recovery",
):
    if marker not in PHASE4_TEST:
        raise SystemExit(f"Phase 4 recovery regression coverage missing: {marker}")

with (ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
issue = issues.get("V2-010")
if issue is None or issue["severity"] != "P1" or issue["status"] != "fixed":
    raise SystemExit("nested save recovery issue V2-010 is not recorded as a fixed P1")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample round 2 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


screenshot = ROOT / "docs/v2/internal-sample-2-qa-complete.png"
if not screenshot.is_file() or png_dimensions(screenshot) != (750, 1334):
    raise SystemExit("internal sample round 2 completion evidence is missing or has unexpected dimensions")

doc_path = ROOT / "docs/v2/internal-sample-polish-2.md"
if not doc_path.is_file():
    raise SystemExit("internal sample round 2 acceptance record is missing")
doc = doc_path.read_text(encoding="utf-8")
for marker in ("V2-010", "qa_complete", "本轮验收结果：通过", "外测 HOLD"):
    if marker not in doc:
        raise SystemExit(f"internal sample round 2 acceptance record missing marker: {marker}")

print("V2 internal sample polish round 2 OK: copy, completion QA, nested save recovery")
