#!/usr/bin/env python3
"""Validate UI 2.0 iteration 1 without coupling it to gameplay state changes."""

import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
LAYOUT = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayout.lua").read_text(encoding="utf-8")
THEME = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in (
    "function V2UITheme.progressIndex(stage)",
    "function V2UITheme.actionRole(stage, actionId, actionIndex, actionCount, selectedModule)",
    "function V2UITheme.resourceItems(resources)",
    'naval = "舰炮交火"',
    'complete = "首航完成"',
):
    if marker not in THEME:
        raise SystemExit(f"UI 2.0 theme is missing marker: {marker}")

for marker in (
    'local V2UITheme = require "LuaClass/V2UITheme"',
    "function V2ChapterLayer:addObjectiveBanner",
    "function V2ChapterLayer:addResourceRow",
    "function V2ChapterLayer:addVoyageRail",
    "function V2ChapterLayer:addContextColumns",
    "function V2ChapterLayer:addBattleStatus",
    "cc.MenuItemSprite:create(normalFace, pressedFace)",
    "cc.Spawn:create(",
):
    if marker not in LAYER:
        raise SystemExit(f"UI 2.0 layer is missing marker: {marker}")

if "cc.RepeatForever:create" in LAYER:
    raise SystemExit("UI 2.0 must not use perpetual decorative animation")

for marker in (
    "resource_chip_height = 42",
    "resource_chip_height = 46",
    "action_button_width = 276",
    "action_button_height = 54",
    "action_button_height = 64",
):
    if marker not in LAYOUT:
        raise SystemExit(f"UI 2.0 responsive layout is missing marker: {marker}")

for command in (
    "lua tools/v2/test_v2_ui_theme.lua",
    "python3 tools/v2/validate_ui2_iteration_1.py",
):
    if command not in PHASE4:
        raise SystemExit(f"UI 2.0 regression is not in the Phase 4 chain: {command}")

def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"UI 2.0 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


evidence = {
    "ui2-iteration1-se-player-opening.png": (750, 1334),
    "ui2-iteration1-se-combat.png": (750, 1334),
    "ui2-iteration1-se-route.png": (750, 1334),
    "ui2-iteration1-se-settlement.png": (750, 1334),
    "ui2-iteration1-se-release-info.png": (750, 1334),
    "ui2-iteration1-ipad-route.png": (1640, 2360),
    "ui2-iteration1-ipad-combat.png": (1640, 2360),
}
for filename, expected in evidence.items():
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_dimensions(path) != expected:
        raise SystemExit(f"UI 2.0 evidence is missing or has unexpected dimensions: {filename}")

doc = (ROOT / "docs/v2/ui-2.0-iteration-1.md").read_text(encoding="utf-8")
for marker in (
    "第一章现有玩法纵切保留不动",
    "FROZEN",
    "HOLD",
    "V2ChapterState",
    "五段航程",
    "44 point",
    "iPhone SE 3",
    "iPad A16",
):
    if marker not in doc:
        raise SystemExit(f"UI 2.0 acceptance record is missing marker: {marker}")

print("V2 UI 2.0 iteration 1 OK: modern shell, unchanged gameplay boundary, 7 runtime captures")
