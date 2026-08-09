#!/usr/bin/env python3
"""Validate the playable Tide Graveyard second-voyage baseline."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def ids(name: str) -> set[str]:
    return {row["id"] for row in rows(name)}


required = {
    "map_node.csv": {"node_tide_gate", "node_tide_guardian", "node_tide_rune"},
    "event.csv": {"event_tide_route_choice", "event_tide_guardian", "event_tide_rune"},
    "route.csv": {"tide_breaker_channel", "tide_cannon_pass"},
    "enemy.csv": {"enemy_tide_warden"},
    "reward.csv": {"reward_tide_guardian", "reward_tide_rune"},
    "battle_action.csv": {"tide_barrage", "tide_ram"},
    "telemetry_event.csv": {
        "tide_guardian_action", "tide_guardian_result",
        "second_rune_claimed", "second_voyage_completed",
    },
}
for filename, required_ids in required.items():
    missing = required_ids - ids(filename)
    if missing:
        raise SystemExit(f"{filename} is missing second-voyage ids: {sorted(missing)}")

routes = {row["id"]: row for row in rows("route.csv")}
if int(routes["tide_breaker_channel"]["hull_damage"]) != 30:
    raise SystemExit("breaker channel no longer exposes the authored hull tradeoff")
if int(routes["tide_cannon_pass"]["supply_cost"]) != 2:
    raise SystemExit("cannon pass no longer exposes the authored supply tradeoff")

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    "tide_route_choice = true",
    "tide_guardian = true",
    "tide_rune_clue = true",
    "tide_settlement = true",
    "tide_complete = true",
    'state.stage = "tide_route_choice"',
    'state.stage = "tide_guardian"',
    'state.stage = "tide_rune_clue"',
    'state.stage = "tide_settlement"',
    'state.stage = "tide_complete"',
    'balanceValue("tide_hull_route_reduction")',
    'balanceValue("tide_gun_route_reduction")',
    "local function resolveTideAttack",
    'elseif action == "return_from_tide"',
):
    if marker not in state:
        raise SystemExit(f"second-voyage state contract is missing: {marker}")

theme = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
layer = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
for marker in (
    "V2UITheme.tide_progress_labels",
    'tide_shield", label = "潮盾"',
    'tide_ram = "守卫潮锚已撞击"',
    'stage == "tide_settlement"',
):
    if marker not in theme:
        raise SystemExit(f"second-voyage theme contract is missing: {marker}")
for marker in (
    'stage == "tide_guardian"',
    '"守卫潮盾"',
    "local progressLabels = V2UITheme.progressLabels(state.stage)",
    'and "潮汐墓场  /  CAPTAIN\'S LOG"',
):
    if marker not in layer:
        raise SystemExit(f"second-voyage layer contract is missing: {marker}")

config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
for profile in (
    "qa_tide_route", "qa_tide_guardian", "qa_tide_rune",
    "qa_tide_settlement", "qa_tide_complete",
):
    if f"{profile} = true" not in config or f'profile == "{profile}"' not in state:
        raise SystemExit(f"second-voyage QA profile is missing: {profile}")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"second-voyage evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in (
    "second-voyage-iteration-1-route.png",
    "second-voyage-iteration-1-guardian.png",
    "second-voyage-iteration-1-settlement.png",
):
    screenshot = ROOT / "docs" / "v2" / filename
    if not screenshot.is_file() or png_dimensions(screenshot) != (1206, 2622):
        raise SystemExit(f"second-voyage iPhone evidence is missing: {filename}")
    if screenshot.stat().st_size < 500_000:
        raise SystemExit(f"second-voyage iPhone evidence appears incomplete: {filename}")

record = (ROOT / "docs/v2/second-voyage-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why", "破潮水道", "炮门航道", "沉锚符文守卫",
    "第二枚沉锚符文", "后续海域仍在制作", "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"second-voyage record is missing: {marker}")
for marker in ("第二次远航第 1 轮", "沉锚符文守卫", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing second-voyage marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "lua tools/v2/test_v2_second_voyage.lua",
    "python3 tools/v2/validate_second_voyage.py",
):
    if command not in phase4:
        raise SystemExit(f"second-voyage validation is not in the Phase 4 chain: {command}")

print("V2 second-voyage baseline OK: growth routes, Tide Guardian, second rune, UI and iPhone evidence passed")
