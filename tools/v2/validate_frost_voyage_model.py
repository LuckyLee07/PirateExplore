#!/usr/bin/env python3
"""Validate the pure Frostbound voyage model without exposing it to players."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

candidate = json.loads(
    (ROOT / "design/v2/content_slices/voyage-03-frostbound.json").read_text(encoding="utf-8")
)
prototype = candidate.get("prototype_evidence", {})
if prototype != {
    "module": "bin/res/scripts/LuaClass/V2FrostVoyageModel.lua",
    "test": "tools/v2/test_v2_frost_voyage_model.lua",
    "validated": True,
    "runtime_wiring": False,
}:
    raise SystemExit("Frostbound candidate prototype evidence drifted")
if candidate.get("runtime_exposed") is not False:
    raise SystemExit("Frostbound prototype cannot be exposed before runtime integration is complete")

model = (ROOT / prototype["module"]).read_text(encoding="utf-8")
test = (ROOT / prototype["test"]).read_text(encoding="utf-8")
for marker in (
    'V2FrostVoyageModel.MODEL_STATUS = "prototype_only"',
    'frost_pack_channel = {',
    'frost_flare_pass = {',
    'port = "frost_turn_port"',
    'starboard = "frost_turn_starboard"',
    'center = "frost_break_ice"',
    "function V2FrostVoyageModel.currentForecast(state)",
    "function V2FrostVoyageModel.getActionPreviews(state)",
    "function V2FrostVoyageModel.applyHazardAction(state, action)",
    "function V2FrostVoyageModel.retry(state)",
    "function V2FrostVoyageModel.returnToPort(state)",
    'state.phase = "failed"',
    'state.phase = "complete"',
):
    if marker not in model:
        raise SystemExit(f"Frostbound pure model is missing: {marker}")
for forbidden in ("cc.", "V2ChapterController", "tide_shield", "enemy_ship_hp"):
    if forbidden in model:
        raise SystemExit(f"Frostbound pure model contains runtime or renamed-shield coupling: {forbidden}")

for marker in (
    "the next round changes the optimal spatial action",
    "navigator choice exposes exact action consequences",
    "medic choice visibly restores one mistake",
    "sailor chief reduces the first wrong turn",
    "gun growth and gunner chief create a visible first-window payoff",
    "three wrong openings fail by passage progress, not a renamed shield",
    "retry preserves the selected route",
    "port recovery reopens the character choice",
):
    if marker not in test:
        raise SystemExit(f"Frostbound behavioral regression is missing: {marker}")

runtime_sources = (
    "bin/res/scripts/LuaClass/V2ChapterState.lua",
    "bin/res/scripts/LuaClass/V2ChapterLayer.lua",
    "bin/res/scripts/LuaClass/V2PortModel.lua",
    "bin/res/scripts/LuaClass/V2PortLayer.lua",
    "bin/res/scripts/LuaClass/V2Config.lua",
)
for filename in runtime_sources:
    source = (ROOT / filename).read_text(encoding="utf-8")
    if "V2FrostVoyageModel" in source:
        raise SystemExit(f"Frostbound prototype leaked into player runtime: {filename}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "lua tools/v2/test_v2_frost_voyage_model.lua",
    "python3 tools/v2/validate_frost_voyage_model.py",
):
    if command not in phase4:
        raise SystemExit(f"Frostbound prototype validation is not in Phase 4: {command}")

record = (ROOT / "docs/v2/frost-voyage-model-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why", "左舷裂口", "右舷裂口", "中央冰脊", "三轮",
    "六类成长", "runtime_exposed = false", "尚未可玩", "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"Frostbound model record is missing: {marker}")
for marker in ("霜冻航线状态模型第 1 轮", "航道推进不足", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing Frostbound model marker: {marker}")
if "frost-voyage-model-iteration-1.md" not in readme:
    raise SystemExit("README does not link the Frostbound model record")

print("V2 Frost voyage model baseline OK: changing telegraph, six growth payoffs, retry boundary and runtime isolation passed")
