#!/usr/bin/env python3
"""Validate retained growth and the second-voyage preparation baseline."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
THEME = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
PORT = (ROOT / "bin/res/scripts/LuaClass/V2PortModel.lua").read_text(encoding="utf-8")
TELEMETRY = (ROOT / "bin/res/scripts/LuaClass/V2Telemetry.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in (
    'and "restart_chapter" or "prepare_next_voyage"',
    '"准备下一次远航\\n保留升级与库存"',
    'elseif action == "prepare_next_voyage" and state.stage == "complete" then',
    'state.flags = { chapter_01_complete = true }',
    'state.claimed_rewards.reward_battle = nil',
    '"第 %d 次远航整备开始：船只升级、库存与符文线索已保留。"',
    'return string.format("皇家港 · 第 %d 次整备"',
):
    if marker not in STATE:
        raise SystemExit(f"repeat-voyage state contract is missing: {marker}")

if "再次体验第一章" in STATE:
    raise SystemExit("player completion still exposes the old destructive replay copy")
if "V2ChapterState.SCHEMA_VERSION = 4" not in STATE:
    raise SystemExit("repeat voyage unexpectedly changed the persisted save schema")

for marker in (
    'prepare_next_voyage = true',
    'prepare_next_voyage = "成长已装载"',
):
    if marker not in THEME:
        raise SystemExit(f"repeat-voyage theme contract is missing: {marker}")

for marker in (
    'prepare_next_voyage = true',
    '"第 %d 次远航准备中；船只成长、库存与符文线索已保留"',
):
    if marker not in PORT:
        raise SystemExit(f"repeat-voyage port contract is missing: {marker}")

if 'if action == "prepare_next_voyage" then return "next_voyage_prepared" end' not in TELEMETRY:
    raise SystemExit("repeat-voyage telemetry classification is missing")
if TELEMETRY.count("voyage_count = state.voyage_count or 0") < 2:
    raise SystemExit("voyage count is not retained in session and action telemetry")

with (ROOT / "design/v2/data/telemetry_event.csv").open(encoding="utf-8", newline="") as handle:
    events = list(csv.DictReader(handle))
event = next((row for row in events if row["id"] == "next_voyage_prepared"), None)
if event is None or "voyage_count" not in event["required_fields"]:
    raise SystemExit("next-voyage telemetry source row is missing or incomplete")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"repeat-voyage evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in ("ui4-0-second-voyage-port.png", "ui4-0-second-voyage-chapter.png"):
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"repeat-voyage iPhone evidence is missing: {filename}")

matrix = ROOT / "docs/v2/ui40-second-voyage-preparation.png"
if not matrix.is_file() or png_dimensions(matrix) != (1048, 1111):
    raise SystemExit("repeat-voyage comparison evidence is missing")

record = (ROOT / "docs/v2/repeat-voyage-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "prepare_next_voyage",
    "最大耐久从 120 提高到 140",
    "基础甲板齐射从 175 提高到 200",
    "潮汐墓场",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"repeat-voyage record is missing: {marker}")
for marker in ("重复远航第 1 轮", "潮汐墓场", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing repeat-voyage marker: {marker}")

if "lua tools/v2/test_v2_repeat_voyage.lua" not in PHASE4:
    raise SystemExit("repeat-voyage behavior test is not in the Phase 4 chain")
if "python3 tools/v2/validate_repeat_voyage.py" not in PHASE4:
    raise SystemExit("repeat-voyage evidence validation is not in the Phase 4 chain")

print("V2 repeat-voyage baseline OK: retained growth, second preparation, telemetry and iPhone evidence passed")
