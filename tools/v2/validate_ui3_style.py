#!/usr/bin/env python3
"""Validate the structural UI 3.1 style contract and mainstream-iPhone evidence."""

from __future__ import annotations

import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
LAYOUT = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayout.lua").read_text(encoding="utf-8")
THEME = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")

for marker in (
    'separator = { 76, 96, 96 }',
    'shell = { 5, 16, 23 }',
    'ink = { 244, 238, 218 }',
    "function V2UITheme.actionRole(stage, actionId, actionIndex, actionCount, selectedModule)",
    "function V2UITheme.battleIcon(kind)",
    "function V2UITheme.actionFeedbackTitle(actionId, nextStage)",
    "function V2UITheme.feedbackChanges(before, after)",
    'icon = "Images/V2/Icons/resource-gold.png"',
):
    if marker not in THEME:
        raise SystemExit(f"UI 3.0 theme is missing marker: {marker}")

for marker in (
    'fontName or "Arial"',
    "function V2ChapterLayer:addVoyageRail",
    "function V2ChapterLayer:addContextColumns",
    "local function createActionFace",
    'local chapterPlate = cc.LayerColor:create',
    'local logTab = cc.LayerColor:create',
    'local resourceName = createLabel(item.name',
    "local function addTintedIcon",
    "function V2ChapterLayer:showActionFeedback",
    "function V2ChapterLayer:performAction(actionId)",
    'os.getenv("NEWPIRATE_V2_QA_ACTION")',
    'cc.FadeTo:create(0.14, 255)',
    'local isBattleStage = state.stage == "naval" or state.stage == "boarding"',
    'createButtonFace(infoWidth, infoHeight, "utility"',
):
    if marker not in LAYER:
        raise SystemExit(f"UI 3.1 layer is missing marker: {marker}")

for forbidden in (
    "cc.RepeatForever:create",
    "function V2ChapterLayer:addObjectiveBanner(parent, state, layout)\n    local width",
    "function V2ChapterLayer:addMapStrip",
    "function V2ChapterLayer:addMetaRow",
    'table.concat(segments, "   ·   ")',
    "addPill(",
):
    if forbidden in LAYER:
        raise SystemExit(f"UI 3.1 reintroduced a noisy or obsolete pattern: {forbidden}")

for marker in (
    "title_y = 30",
    "objective_panel_height = 70",
    "voyage_rail_gap = 38",
    "card_y = 400",
    "story_card_height = 285",
    "action_button_height = 64",
):
    if marker not in LAYOUT:
        raise SystemExit(f"UI 3.1 mainstream-iPhone layout is missing marker: {marker}")


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

matrix = ROOT / "docs/v2/ui32-iphone-state-matrix.png"
if not matrix.is_file() or png_dimensions(matrix) != (1687, 1018):
    raise SystemExit("UI 3.2 fourteen-state iPhone matrix is missing")

feedback_capture = ROOT / "docs/v2/ui32-iphone-action-feedback.png"
if not feedback_capture.is_file() or png_dimensions(feedback_capture) != (1206, 2622):
    raise SystemExit("UI 3.2 runtime action feedback capture is missing")

for profile in ("qa_route_event", "qa_black_tide", "qa_whisper", "qa_curse"):
    if f"{profile} = true" not in CONFIG or f'profile == "{profile}"' not in STATE:
        raise SystemExit(f"UI 3.2 intermediate-state profile is missing: {profile}")

icon_names = (
    "resource-gold",
    "resource-timber",
    "resource-iron",
    "resource-provisions",
    "resource-rune",
    "battle-hull",
    "battle-deck",
    "battle-cannon",
    "battle-crew",
)
for icon_name in icon_names:
    runtime_icon = ROOT / "bin/res/assets/Images/V2/Icons" / f"{icon_name}.png"
    source_icon = ROOT / "design/v2/assets/icons" / f"{icon_name}.svg"
    if not runtime_icon.is_file() or png_dimensions(runtime_icon) != (64, 64):
        raise SystemExit(f"UI 3.2 runtime icon is missing or invalid: {icon_name}")
    if not source_icon.is_file():
        raise SystemExit(f"UI 3.2 vector source is missing: {icon_name}")

doc = (ROOT / "docs/v2/ui-3.0-style-system.md").read_text(encoding="utf-8")
for marker in (
    "克制的航海日志",
    "UI 3.1",
    "UI 3.2",
    "主流 iPhone",
    "纵向航程",
    "指令编号",
    "单阶段强调色",
    "标题粗体、正文常规字重",
    "玩法状态机、数值和存档不变",
    "14 个状态",
    "BASELINED",
    "ACTIVE",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in doc:
        raise SystemExit(f"UI 3.0 style record is missing marker: {marker}")

if "python3 tools/v2/validate_ui3_style.py" not in PHASE4:
    raise SystemExit("UI 3.0 validation is not in the Phase 4 chain")

print("V2 UI 3.2 style OK: semantic instruments, causal feedback and mainstream-iPhone captures")
