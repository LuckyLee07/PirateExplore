#!/usr/bin/env python3
"""Validate Phase 2 source-driven exploration and combat contracts."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


route_rows = rows("route.csv")
if {row["id"] for row in route_rows} != {"safe_route", "risky_shortcut"}:
    raise SystemExit("route.csv must define exactly safe and risky Chapter 1 routes")
for row in route_rows:
    if not row["intel_hint"] or not row["outcome_hint"]:
        raise SystemExit(f"route {row['id']} needs intel and outcome explanations")
    for field in ("supply_cost", "risk", "hull_damage", "crew_max_bonus"):
        if int(row[field]) < 0:
            raise SystemExit(f"route {row['id']} has invalid {field}")
reward_ids = {row["id"] for row in rows("reward.csv")}
for row in route_rows:
    if row["reward_id"] and row["reward_id"] not in reward_ids:
        raise SystemExit(f"route {row['id']} references unknown reward")
if int(next(row for row in route_rows if row["id"] == "safe_route")["risk"]) >= int(
    next(row for row in route_rows if row["id"] == "risky_shortcut")["risk"]
):
    raise SystemExit("risky route must expose higher risk than safe route")

balance_rows = rows("balance.csv")
balance_ids = [row["id"] for row in balance_rows]
if len(balance_ids) != len(set(balance_ids)):
    raise SystemExit("balance.csv contains duplicate ids")
required_balance = {
    "deck_break_threshold",
    "gun_suppression_threshold",
    "navigator_intel_cost",
    "boarding_wounded_hp",
    "retry_supply_cost",
    "port_recovery_gold_cost",
    "hull_upgrade_timber_cost",
    "guns_upgrade_iron_cost",
}
if not required_balance.issubset(balance_ids):
    raise SystemExit(f"balance.csv missing {sorted(required_balance - set(balance_ids))}")

action_rows = rows("battle_action.csv")
action_ids = {row["id"] for row in action_rows}
required_actions = {
    "gunner_mark_deck",
    "fire_at_deck",
    "fire_at_guns",
    "boarding_attack",
    "boarding_rush",
    "sailor_guard",
    "medic_heal",
}
if action_ids != required_actions:
    raise SystemExit("battle_action.csv does not match the Phase 2 action set")
for row in action_rows:
    if row["stage"] not in {"naval", "boarding"}:
        raise SystemExit(f"battle action {row['id']} has invalid stage")
    for field in ("damage", "deck_damage", "gun_damage", "retaliation"):
        if int(row[field]) < 0:
            raise SystemExit(f"battle action {row['id']} has invalid {field}")

crew_actions = {row["active_action"] for row in rows("crew.csv")}
if crew_actions != {"gunner_mark_deck", "sailor_guard", "reveal_route_intel", "medic_heal"}:
    raise SystemExit("crew active actions do not match the Phase 2 skill set")

for row in rows("ship_module.csv"):
    for field in ("hull_bonus", "cannon_bonus", "supply_capacity_modifier"):
        int(row[field])

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    'balanceValue("deck_break_threshold")',
    'routeData("safe_route")',
    'battleAction(action)',
    'action == "fire_at_guns"',
    'action == "sailor_guard"',
    "state.battle_report",
    "state.recovery_summary",
):
    if marker not in state:
        raise SystemExit(f"state machine missing Phase 2 marker: {marker}")

for forbidden in ("damage = 175", "deck_damage >= 300", "crew_hp + 28"):
    if forbidden in state:
        raise SystemExit(f"core numeric tuning remains hard-coded: {forbidden}")

config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
if not any(f"CURRENT_PHASE = {phase}" in config for phase in range(2, 5)):
    raise SystemExit("V2Config does not identify Phase 2 or a later runtime baseline")
if not any(f"SAVE_SCHEMA_VERSION = {version}" in config for version in range(2, 6)):
    raise SystemExit("V2Config save schema predates the Phase 2 runtime baseline")

print(
    "V2 Phase 2 data OK: "
    f"{len(route_rows)} routes, {len(balance_rows)} balance values, "
    f"{len(action_rows)} battle actions"
)
