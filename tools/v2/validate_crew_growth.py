#!/usr/bin/env python3
"""Validate the first crew-growth iteration and its iPhone evidence."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"crew-growth evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


upgrades = {row["id"]: row for row in rows("crew_upgrade.csv")}
expected = {
    "crew_upgrade_gunner": ("crew_gunner", "炮术长", "promote_gunner", "barrage_damage", "20"),
    "crew_upgrade_sailor": ("crew_sailor", "大副", "promote_sailor", "ram_hull_reduction", "10"),
}
if set(upgrades) != set(expected):
    raise SystemExit("crew-growth source must expose exactly the two first-slice appointments")
for identifier, values in expected.items():
    row = upgrades[identifier]
    actual = tuple(row[key] for key in ("crew_id", "title", "action_id", "effect_kind", "effect_value"))
    if actual != values:
        raise SystemExit(f"crew-growth source drifted: {identifier}")

telemetry = {row["id"]: row for row in rows("telemetry_event.csv")}
event = telemetry.get("crew_upgrade_selected")
if event is None or event["required_fields"] != "action|stage_after|crew_upgrade":
    raise SystemExit("crew-growth telemetry contract is missing")

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    "local function selectedCrewUpgrade(state)",
    "local function crewUpgradeEffect(state, upgradeId)",
    "local function tideDamagePreview(state, potential)",
    'profile == "qa_crew_growth"',
    'profile == "qa_tide_guardian_gunner" or profile == "qa_tide_guardian_sailor"',
    "for _, upgrade in ipairs(ChapterData.crew_upgrade or {}) do",
    "id = upgrade.action_id",
    'state.upgrades.crew = upgrade.id',
    'state.stage = "crew_growth"',
    'return false, "请先完成一次首席船员任命"',
    'string.format("%d（火力%d）", actual, potential)',
    'string.format("最终破盾 %d（方案火力 %d）", damage, potential)',
):
    if marker not in state:
        raise SystemExit(f"crew-growth state contract is missing: {marker}")

model = (ROOT / "bin/res/scripts/LuaClass/V2PortModel.lua").read_text(encoding="utf-8")
for marker in (
    'crew_growth = { label = "等待任命"',
    "function V2PortModel.crewUpgrades(state, data)",
    "promotion_effect = crewUpgradeEffectText(promotion)",
    "promote_gunner = true",
    "promote_sailor = true",
):
    if marker not in model:
        raise SystemExit(f"crew-growth presentation model is missing: {marker}")

layer = (ROOT / "bin/res/scripts/LuaClass/V2PortLayer.lua").read_text(encoding="utf-8")
for marker in (
    "function V2PortLayer:addCrewGrowthSection",
    'if state.stage == "crew_growth" then',
    '"一次任命  ·  永久保留"',
    "item.strategy_icon",
):
    if marker not in layer:
        raise SystemExit(f"crew-growth UI hierarchy is missing: {marker}")

theme = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
telemetry_source = (ROOT / "bin/res/scripts/LuaClass/V2Telemetry.lua").read_text(encoding="utf-8")
config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
for marker in ('crew_growth = "首席任命"', 'promote_gunner = "炮术长任命完成"',
               'promote_sailor = "大副任命完成"'):
    if marker not in theme:
        raise SystemExit(f"crew-growth theme contract is missing: {marker}")
if 'return "crew_upgrade_selected"' not in telemetry_source or "crew_growth_decisions" not in telemetry_source:
    raise SystemExit("crew-growth telemetry classification or summary is missing")
for profile in ("qa_crew_growth", "qa_tide_guardian_gunner", "qa_tide_guardian_sailor"):
    if f"{profile} = true" not in config:
        raise SystemExit(f"crew-growth QA profile is missing: {profile}")

screenshots = (
    "crew-growth-iteration-1-choice.png",
    "crew-growth-iteration-1-selected.png",
    "crew-growth-iteration-1-guardian.png",
    "crew-growth-iteration-1-chapter.png",
)
for filename in screenshots:
    path = ROOT / "docs" / "v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"crew-growth iPhone evidence is missing: {filename}")
    if path.stat().st_size < 500_000:
        raise SystemExit(f"crew-growth iPhone evidence appears incomplete: {filename}")

record = (ROOT / "docs/v2/crew-growth-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why",
    "罗克 · 炮术长",
    "米克 · 大副",
    "旧存档兼容",
    "潮汐墓场角色事件",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"crew-growth iteration record is missing: {marker}")
for marker in ("船员成长第 1 轮", "首席任命", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing crew-growth marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "lua tools/v2/test_v2_crew_growth.lua",
    "python3 tools/v2/validate_crew_growth.py",
):
    if command not in phase4:
        raise SystemExit(f"crew-growth validation is not in the Phase 4 chain: {command}")

print("V2 crew growth baseline OK: appointment, retained effects, guardian payoff, telemetry and iPhone evidence passed")
