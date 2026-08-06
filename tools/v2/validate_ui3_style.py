#!/usr/bin/env python3
"""Validate the calm UI 3.0 style contract and mainstream-iPhone evidence."""

from __future__ import annotations

import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
LAYOUT = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayout.lua").read_text(encoding="utf-8")
THEME = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in (
    'separator = { 76, 96, 96 }',
    'shell = { 5, 16, 23 }',
    'ink = { 244, 238, 218 }',
    "function V2UITheme.actionRole(stage, actionId, actionIndex, actionCount, selectedModule)",
):
    if marker not in THEME:
        raise SystemExit(f"UI 3.0 theme is missing marker: {marker}")

for marker in (
    'fontName or "Arial"',
    'table.concat(segments, "   ·   ")',
    'string.format("航程  %d / %d"',
    'local isBattleStage = state.stage == "naval" or state.stage == "boarding"',
    'local cardAccent = cc.LayerColor:create',
    'createButtonFace(infoWidth, infoHeight, "utility"',
):
    if marker not in LAYER:
        raise SystemExit(f"UI 3.0 layer is missing marker: {marker}")

for forbidden in (
    "cc.RepeatForever:create",
    "function V2ChapterLayer:addObjectiveBanner(parent, state, layout)\n    local width",
    "function V2ChapterLayer:addMetaRow(parent, state, moduleData, layout, cardWidth)\n",
    "addPill(",
):
    if forbidden in LAYER:
        raise SystemExit(f"UI 3.0 reintroduced a noisy or obsolete pattern: {forbidden}")

for marker in (
    "title_y = 30",
    "card_y = 410",
    "story_card_height = 270",
    "story_card_offset = 70",
    "action_button_height = 60",
):
    if marker not in LAYOUT:
        raise SystemExit(f"UI 3.0 mainstream-iPhone layout is missing marker: {marker}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"UI 3.0 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


evidence = (
    "ui3-style-iphone-player-opening.png",
    "ui3-style-iphone-exploration.png",
    "ui3-style-iphone-combat.png",
    "ui3-style-iphone-rune.png",
)
for filename in evidence:
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"UI 3.0 mainstream-iPhone evidence is missing: {filename}")

doc = (ROOT / "docs/v2/ui-3.0-style-system.md").read_text(encoding="utf-8")
for marker in (
    "克制的航海日志",
    "主流 iPhone",
    "单阶段强调色",
    "标题粗体、正文常规字重",
    "玩法状态机、数值和存档不变",
    "HOLD",
):
    if marker not in doc:
        raise SystemExit(f"UI 3.0 style record is missing marker: {marker}")

if "python3 tools/v2/validate_ui3_style.py" not in PHASE4:
    raise SystemExit("UI 3.0 validation is not in the Phase 4 chain")

print("V2 UI 3.0 style OK: calm hierarchy and 4 mainstream-iPhone runtime captures")
