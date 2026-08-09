#!/usr/bin/env python3
"""Validate the Tide Graveyard character-event iteration and iPhone evidence."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def by_id(name: str) -> dict[str, dict[str, str]]:
    return {row["id"]: row for row in rows(name)}


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"Tide character-event evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


nodes = by_id("map_node.csv")
events = by_id("event.csv")
choices = by_id("event_choice.csv")
balances = by_id("balance.csv")
edges = by_id("map_edge.csv")
presentations = by_id("presentation.csv")
telemetry = by_id("telemetry_event.csv")

signal = nodes.get("node_tide_signal")
if signal is None or signal["event_id"] != "event_tide_signal" or signal["grants_flag"] != "tide_signal_resolved":
    raise SystemExit("Tide signal node contract is missing")
if events.get("event_tide_signal", {}).get("required_flag") != "tide_route_chosen":
    raise SystemExit("Tide signal event does not follow the route choice")
if nodes.get("node_tide_guardian", {}).get("required_flag") != "tide_signal_resolved":
    raise SystemExit("Tide Guardian can bypass the character event in authored data")
if events.get("event_tide_guardian", {}).get("required_flag") != "tide_signal_resolved":
    raise SystemExit("Tide Guardian event prerequisite drifted")

expected_edges = {
    "edge_11": ("node_tide_gate", "node_tide_signal"),
    "edge_12": ("node_tide_gate", "node_tide_signal"),
    "edge_13": ("node_tide_signal", "node_tide_guardian"),
    "edge_14": ("node_tide_guardian", "node_tide_rune"),
}
for identifier, pair in expected_edges.items():
    edge = edges.get(identifier, {})
    if (edge.get("from_node"), edge.get("to_node")) != pair:
        raise SystemExit(f"Tide character-event edge drifted: {identifier}")

expected_choices = {
    "choice_tide_bell": ("shatter_tide_bell", "tide_bell_shattered"),
    "choice_tide_keeper": ("rescue_anchor_keeper", "tide_keeper_rescued"),
}
for identifier, expected in expected_choices.items():
    choice = choices.get(identifier, {})
    if choice.get("event_id") != "event_tide_signal" or (
        choice.get("action_id"), choice.get("grants_flag")
    ) != expected:
        raise SystemExit(f"Tide character choice drifted: {identifier}")
if int(balances.get("tide_bell_shield_damage", {}).get("value", 0)) != 20:
    raise SystemExit("bell opening-shield damage drifted")
if int(balances.get("tide_keeper_ram_bonus", {}).get("value", 0)) != 25:
    raise SystemExit("keeper ram bonus drifted")
if presentations.get("presentation_tide_signal", {}).get("stage") != "tide_character_event":
    raise SystemExit("Tide character event has no presentation mapping")
event = telemetry.get("tide_character_event_choice")
if event is None or event["required_fields"] != "action|stage_after|crew_upgrade":
    raise SystemExit("Tide character-event telemetry contract is missing")

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    "tide_character_event = true",
    'profile == "qa_tide_signal_gunner" or profile == "qa_tide_signal_sailor"',
    'id = "shatter_tide_bell"',
    'id = "rescue_anchor_keeper"',
    'state.stage = "tide_character_event"',
    'grantFlag(state, "tide_signal_resolved")',
    'state.flags.tide_bell_shattered = nil',
    'state.flags.tide_keeper_rescued = nil',
    'balanceValue("tide_bell_shield_damage")',
    'balanceValue("tide_keeper_ram_bonus")',
    '"旧存档未经历求救火"',
):
    if marker not in state:
        raise SystemExit(f"Tide character-event state contract is missing: {marker}")

theme = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
model = (ROOT / "bin/res/scripts/LuaClass/V2PortModel.lua").read_text(encoding="utf-8")
telemetry_source = (ROOT / "bin/res/scripts/LuaClass/V2Telemetry.lua").read_text(encoding="utf-8")
config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
for marker in (
    'tide_character_event = "船员事件"',
    '"求救火"',
    'shatter_tide_bell = "引潮钟已击碎"',
    'rescue_anchor_keeper = "缚锚水手已救回"',
    'elseif stage == "tide_character_event" then',
):
    if marker not in theme:
        raise SystemExit(f"Tide character-event theme is missing: {marker}")
if 'tide_character_event = { label = "墓场求救火"' not in model:
    raise SystemExit("Royal Port status does not expose the pending character event")
if 'return "tide_character_event_choice"' not in telemetry_source or "tide_character_choices" not in telemetry_source:
    raise SystemExit("Tide character-event telemetry classification or summary is missing")
for profile in ("qa_tide_signal_gunner", "qa_tide_signal_sailor"):
    if f"{profile} = true" not in config:
        raise SystemExit(f"Tide character-event QA profile is missing: {profile}")

screenshots = (
    "tide-character-event-iteration-1-gunner.png",
    "tide-character-event-iteration-1-sailor.png",
    "tide-character-event-iteration-1-bell.png",
    "tide-character-event-iteration-1-rescue.png",
)
for filename in screenshots:
    path = ROOT / "docs" / "v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"Tide character-event iPhone evidence is missing: {filename}")
    if path.stat().st_size < 500_000:
        raise SystemExit(f"Tide character-event iPhone evidence appears incomplete: {filename}")

record = (ROOT / "docs/v2/tide-character-event-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why",
    "墓场求救火",
    "首席建议",
    "击碎引潮钟",
    "救下缚锚水手",
    "旧存档",
    "专属视觉",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"Tide character-event record is missing: {marker}")
for marker in ("潮汐墓场角色事件第 1 轮", "墓场求救火", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing Tide character-event marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "lua tools/v2/test_v2_tide_character_event.lua",
    "python3 tools/v2/validate_tide_character_event.py",
):
    if command not in phase4:
        raise SystemExit(f"Tide character-event validation is not in the Phase 4 chain: {command}")

print("V2 Tide character-event baseline OK: chief advice, branching consequence, recovery, telemetry and iPhone evidence passed")
