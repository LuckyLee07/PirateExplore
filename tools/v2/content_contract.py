#!/usr/bin/env python3
"""Reusable whole-repository contract for authored V2 content tables."""

from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path


TABLE_COLUMNS: dict[str, set[str]] = {
    "chapter": {"id", "name", "objective", "start_node", "end_node", "estimated_minutes"},
    "resource": {"id", "name", "primary_use", "secondary_use"},
    "map_node": {"id", "chapter_id", "type", "name", "risk", "visibility", "event_id", "enemy_id", "reward_id", "required_flag", "grants_flag"},
    "map_edge": {"id", "chapter_id", "from_node", "to_node", "route", "risk", "supply_cost", "condition"},
    "event": {"id", "chapter_id", "name", "description", "required_flag"},
    "event_choice": {"id", "event_id", "action_id", "label", "result_text", "reward_id", "grants_flag"},
    "crew": {"id", "name", "role", "active_skill", "active_action", "passive_trait", "chapter_id"},
    "crew_upgrade": {"id", "crew_id", "title", "action_id", "effect_kind", "effect_value", "effect_label", "description", "accent"},
    "ship_module": {"id", "name", "slot", "effect", "tradeoff", "hull_bonus", "cannon_bonus", "supply_capacity_modifier", "chapter_id"},
    "enemy": {"id", "name", "chapter_id", "ship_hp", "boarding_power", "transfer_rule", "reward_id"},
    "reward": {"id", "name", "gold", "timber", "iron", "provisions", "rune_dust", "purpose_hint"},
    "dialogue": {"id", "chapter_id", "node_id", "speaker", "text", "trigger"},
    "route": {"id", "chapter_id", "label", "supply_cost", "risk", "reward_id", "hull_damage", "crew_max_bonus", "status_id", "intel_hint", "outcome_hint"},
    "balance": {"id", "category", "value", "description"},
    "battle_action": {"id", "stage", "label", "damage", "deck_damage", "gun_damage", "retaliation", "once_flag", "description"},
    "presentation": {"id", "hero_group", "stage", "background", "foreground", "portrait", "accent", "animation", "audio_cue"},
    "audio_cue": {"id", "file", "trigger", "volume", "loop", "source_status"},
    "telemetry_event": {"id", "trigger", "description", "required_fields", "decision_metric"},
    "quality_gate": {"id", "category", "metric", "target", "decision_rule", "evidence_status"},
}

INTEGER_FIELDS: dict[str, set[str]] = {
    "chapter": {"estimated_minutes"},
    "map_node": {"risk"},
    "map_edge": {"risk", "supply_cost"},
    "crew_upgrade": {"effect_value"},
    "ship_module": {"hull_bonus", "cannon_bonus", "supply_capacity_modifier"},
    "enemy": {"ship_hp", "boarding_power"},
    "reward": {"gold", "timber", "iron", "provisions", "rune_dust"},
    "route": {"supply_cost", "risk", "hull_damage", "crew_max_bonus"},
    "balance": {"value"},
    "battle_action": {"damage", "deck_damage", "gun_damage", "retaliation"},
    "audio_cue": {"loop"},
}


@dataclass(frozen=True)
class ContractIssue:
    code: str
    context: str
    detail: str

    def __str__(self) -> str:
        return f"[{self.code}] {self.context}: {self.detail}"


def load_tables(data_dir: Path) -> tuple[dict[str, list[dict[str, str]]], list[ContractIssue]]:
    tables: dict[str, list[dict[str, str]]] = {}
    issues: list[ContractIssue] = []
    for table_name, required in TABLE_COLUMNS.items():
        path = data_dir / f"{table_name}.csv"
        if not path.is_file():
            issues.append(ContractIssue("missing_table", table_name, "CSV file is absent"))
            continue
        with path.open(encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fields = set(reader.fieldnames or [])
            missing = sorted(required - fields)
            if missing:
                issues.append(ContractIssue("missing_columns", table_name, ", ".join(missing)))
            tables[table_name] = list(reader)
    return tables, issues


def _ids(tables: dict[str, list[dict[str, str]]], table: str) -> set[str]:
    return {row.get("id", "") for row in tables.get(table, []) if row.get("id")}


def validate_tables(
    tables: dict[str, list[dict[str, str]]],
    assets_dir: Path | None = None,
) -> list[ContractIssue]:
    issues: list[ContractIssue] = []

    for table_name, rows in tables.items():
        seen_ids: set[str] = set()
        for index, row in enumerate(rows, start=2):
            identifier = row.get("id", "").strip()
            context = f"{table_name}.row_{index}"
            if not identifier:
                issues.append(ContractIssue("empty_id", context, "id must not be empty"))
            elif identifier in seen_ids:
                issues.append(ContractIssue("duplicate_id", f"{table_name}.{identifier}", "id appears more than once"))
            seen_ids.add(identifier)
            for field in INTEGER_FIELDS.get(table_name, set()):
                value = row.get(field, "")
                if value == "" or (value.startswith("-") and value[1:].isdigit()) or value.isdigit():
                    continue
                issues.append(ContractIssue("invalid_integer", f"{table_name}.{identifier}.{field}", repr(value)))

    ids = {name: _ids(tables, name) for name in TABLE_COLUMNS}

    def ref(table: str, row: dict[str, str], field: str, target: str) -> None:
        value = row.get(field, "")
        if value and value not in ids[target]:
            issues.append(ContractIssue("unknown_reference", f"{table}.{row.get('id')}.{field}", value))

    for row in tables.get("chapter", []):
        ref("chapter", row, "start_node", "map_node")
        ref("chapter", row, "end_node", "map_node")
    for row in tables.get("map_node", []):
        ref("map_node", row, "chapter_id", "chapter")
        ref("map_node", row, "event_id", "event")
        ref("map_node", row, "enemy_id", "enemy")
        ref("map_node", row, "reward_id", "reward")
        if row.get("visibility") not in {"visible", "fogged"}:
            issues.append(ContractIssue("invalid_visibility", f"map_node.{row.get('id')}", row.get("visibility", "")))
        risk = row.get("risk", "")
        if risk.isdigit() and not 0 <= int(risk) <= 3:
            issues.append(ContractIssue("invalid_risk", f"map_node.{row.get('id')}", risk))
    for row in tables.get("map_edge", []):
        ref("map_edge", row, "chapter_id", "chapter")
        ref("map_edge", row, "from_node", "map_node")
        ref("map_edge", row, "to_node", "map_node")
        if row.get("from_node") == row.get("to_node"):
            issues.append(ContractIssue("self_edge", f"map_edge.{row.get('id')}", row.get("from_node", "")))
    for row in tables.get("event", []):
        ref("event", row, "chapter_id", "chapter")
    for row in tables.get("event_choice", []):
        ref("event_choice", row, "event_id", "event")
        ref("event_choice", row, "reward_id", "reward")
    for row in tables.get("crew", []):
        ref("crew", row, "chapter_id", "chapter")
    for row in tables.get("crew_upgrade", []):
        ref("crew_upgrade", row, "crew_id", "crew")
    for row in tables.get("ship_module", []):
        ref("ship_module", row, "chapter_id", "chapter")
    for row in tables.get("enemy", []):
        ref("enemy", row, "chapter_id", "chapter")
        ref("enemy", row, "reward_id", "reward")
    for row in tables.get("dialogue", []):
        ref("dialogue", row, "chapter_id", "chapter")
        ref("dialogue", row, "node_id", "map_node")
    for row in tables.get("route", []):
        ref("route", row, "chapter_id", "chapter")
        ref("route", row, "reward_id", "reward")
    for row in tables.get("presentation", []):
        ref("presentation", row, "audio_cue", "audio_cue")

    choice_actions: set[str] = set()
    for row in tables.get("event_choice", []):
        action = row.get("action_id", "")
        if not action:
            issues.append(ContractIssue("missing_action", f"event_choice.{row.get('id')}", "action_id is required"))
        elif action in choice_actions:
            issues.append(ContractIssue("duplicate_action", f"event_choice.{row.get('id')}", action))
        choice_actions.add(action)

    stages: set[str] = set()
    for row in tables.get("presentation", []):
        stage = row.get("stage", "")
        if stage in stages:
            issues.append(ContractIssue("duplicate_stage_presentation", f"presentation.{row.get('id')}", stage))
        stages.add(stage)
        if assets_dir is not None:
            for field in ("background", "foreground", "portrait"):
                value = row.get(field, "")
                if value and not (assets_dir / value).is_file():
                    issues.append(ContractIssue("missing_asset", f"presentation.{row.get('id')}.{field}", value))
    for row in tables.get("battle_action", []):
        if row.get("stage") not in stages:
            issues.append(ContractIssue("battle_stage_without_presentation", f"battle_action.{row.get('id')}", row.get("stage", "")))
    if assets_dir is not None:
        for row in tables.get("audio_cue", []):
            value = row.get("file", "")
            if value and not (assets_dir / value).is_file():
                issues.append(ContractIssue("missing_audio", f"audio_cue.{row.get('id')}", value))

    node_events = {row.get("event_id") for row in tables.get("map_node", []) if row.get("event_id")}
    for event_id in ids["event"] - node_events:
        issues.append(ContractIssue("unmapped_event", f"event.{event_id}", "no map node references this event"))
    node_enemies = {row.get("enemy_id") for row in tables.get("map_node", []) if row.get("enemy_id")}
    for enemy_id in ids["enemy"] - node_enemies:
        issues.append(ContractIssue("unmapped_enemy", f"enemy.{enemy_id}", "no map node references this enemy"))
    edge_routes = {row.get("route") for row in tables.get("map_edge", [])}
    for route_id in ids["route"] - edge_routes:
        issues.append(ContractIssue("unmapped_route", f"route.{route_id}", "no map edge uses this route"))

    known_actions = choice_actions | ids["battle_action"] | {"reveal_route_intel"}
    for row in tables.get("crew", []):
        action = row.get("active_action", "")
        if action and action not in known_actions:
            issues.append(ContractIssue("unknown_crew_action", f"crew.{row.get('id')}.active_action", action))

    return issues


def validate_repository(root: Path) -> list[ContractIssue]:
    tables, issues = load_tables(root / "design/v2/data")
    issues.extend(validate_tables(tables, root / "bin/res/assets"))
    return issues
