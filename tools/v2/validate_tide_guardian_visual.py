#!/usr/bin/env python3
"""Validate the Tide Guardian dedicated art and one-time shield-break feedback."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def png_contract(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        header = handle.read(29)
    if len(header) != 29 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"Tide Guardian visual is not a valid PNG: {path.name}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]


with (ROOT / "design/v2/data/presentation.csv").open(encoding="utf-8", newline="") as handle:
    presentations = {row["id"]: row for row in csv.DictReader(handle)}

expected_background = "Images/V2/ui2_tide_guardian.png"
guardian = presentations.get("presentation_tide_guardian", {})
if guardian.get("stage") != "tide_guardian" or guardian.get("background") != expected_background:
    raise SystemExit("Tide Guardian presentation is not mapped to its dedicated art")

asset = ROOT / "bin/res/assets/Images/V2/ui2_tide_guardian.png"
if not asset.is_file() or png_contract(asset) != (1024, 1024, 2):
    raise SystemExit("Tide Guardian art must be a 1024x1024 RGB PNG")
if asset.stat().st_size < 1_000_000:
    raise SystemExit("Tide Guardian art appears incomplete")

runtime_data = (ROOT / "bin/res/scripts/LuaClass/V2ChapterData.lua").read_text(encoding="utf-8")
if f'background = "{expected_background}"' not in runtime_data:
    raise SystemExit("generated runtime data is missing the dedicated Guardian art")

theme = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
layer = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
test = (ROOT / "tools/v2/test_v2_ui_theme.lua").read_text(encoding="utf-8")
for marker in (
    "function V2UITheme.tideShieldBreakFeedback(before, after)",
    'before.stage ~= "tide_guardian"',
    'after.stage ~= "tide_rune_clue"',
    'title = "潮盾崩解"',
    'value = "-" .. (shieldBefore - shieldAfter)',
):
    if marker not in theme:
        raise SystemExit(f"Tide shield-break semantic contract is missing: {marker}")
for marker in (
    "function V2ChapterLayer:showTideShieldBreakFeedback",
    "V2UITheme.tideShieldBreakFeedback(before, after)",
    "listener:setSwallowTouches(true)",
    "local holdDuration = self.qaFeedbackHold or 0.10",
    "cc.DelayTime:create(0.40 + holdDuration)",
    "self:refresh()",
    "self:showActionFeedback(actionId, before, after, nextLayout)",
):
    if marker not in layer:
        raise SystemExit(f"Tide shield-break runtime feedback is missing: {marker}")
for marker in (
    "local shieldBreak = Theme.tideShieldBreakFeedback(",
    'equal(shieldBreak.value, "-80"',
    "non-terminal Guardian hits keep the regular combat feedback",
):
    if marker not in test:
        raise SystemExit(f"Tide shield-break theme regression is missing: {marker}")

screenshots = (
    "tide-guardian-visual-iteration-1-guardian.png",
    "tide-guardian-visual-iteration-1-break.png",
    "tide-guardian-visual-iteration-1-resolved.png",
)
for filename in screenshots:
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_contract(path)[:2] != (1206, 2622):
        raise SystemExit(f"Tide Guardian iPhone evidence is missing: {filename}")
    if path.stat().st_size < 1_000_000:
        raise SystemExit(f"Tide Guardian iPhone evidence appears incomplete: {filename}")

record = (ROOT / "docs/v2/tide-guardian-visual-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why",
    "内置图像生成模式",
    "Use case: stylized-concept",
    "ui2_tide_guardian.png",
    "潮盾崩解",
    "0.4 秒",
    "1206×2622",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"Tide Guardian visual record is missing: {marker}")
for marker in ("沉锚守卫视觉第 1 轮", "潮盾崩解", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing Tide Guardian visual marker: {marker}")
if "tide-guardian-visual-iteration-1.md" not in readme:
    raise SystemExit("README does not link the Tide Guardian visual record")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
if "python3 tools/v2/validate_tide_guardian_visual.py" not in phase4:
    raise SystemExit("Tide Guardian visual validation is not in the Phase 4 chain")

print("V2 Tide Guardian visual baseline OK: dedicated RGB art, one-time shield break, transition and iPhone evidence passed")
