#!/usr/bin/env python3
"""Validate the V2 Phase 0 content contract and runtime integration points."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "design" / "v2" / "data"

REQUIRED_COLUMNS = {
    "chapter.csv": {
        "id", "name", "objective", "start_node", "end_node", "estimated_minutes"
    },
    "resource.csv": {"id", "name", "primary_use", "secondary_use"},
    "map_node.csv": {
        "id", "chapter_id", "type", "name", "risk", "visibility", "event_id",
        "enemy_id", "reward_id", "required_flag", "grants_flag"
    },
    "map_edge.csv": {
        "id", "chapter_id", "from_node", "to_node", "route", "risk",
        "supply_cost", "condition"
    },
    "event.csv": {"id", "chapter_id", "name", "description", "required_flag"},
    "event_choice.csv": {
        "id", "event_id", "label", "result_text", "reward_id", "grants_flag"
    },
    "crew.csv": {
        "id", "name", "role", "active_skill", "passive_trait", "chapter_id"
    },
    "ship_module.csv": {"id", "name", "slot", "effect", "tradeoff", "chapter_id"},
    "enemy.csv": {
        "id", "name", "chapter_id", "ship_hp", "boarding_power", "transfer_rule",
        "reward_id"
    },
    "reward.csv": {
        "id", "name", "gold", "timber", "iron", "provisions", "rune_dust",
        "purpose_hint"
    },
    "dialogue.csv": {"id", "chapter_id", "node_id", "speaker", "text", "trigger"},
}

REQUIRED_SOURCE_GATES = {
    "bin/res/scripts/LuaClass/SaveDataManager.lua": [
        'V2Config:scopedSaveName',
        'function SaveDataManager:resolveFileName',
    ],
    "bin/res/scripts/LuaClass/MainMenu.lua": [
        'legacy.charge',
        'legacy.push_gift',
        'legacy.diamond_store',
    ],
    "bin/res/scripts/LuaClass/BaseView.lua": [
        'legacy.ranking',
        'legacy.diamond_store',
    ],
    "bin/res/scripts/LuaClass/Dispatch.lua": [
        'legacy.achievement',
        'legacy.ranking',
        'legacy.diamond_store',
    ],
    "bin/res/scripts/LuaClass/controller.lua": [
        'scopedPreferenceKey',
        'legacy.rating_ads',
        'legacy.charge',
    ],
    "bin/res/scripts/LuaClass/NotificationNode.lua": ['legacy.seven_day_bonus'],
    "bin/res/scripts/LuaClass/EventManger.lua": ['legacy.eternal_arena'],
    "bin/res/scripts/LuaClass/EventLayer.lua": ['legacy.eternal_arena'],
    "bin/res/scripts/LuaClass/WorldMapLayer.lua": ['legacy.paid_map_unlock'],
}


class ValidationError(Exception):
    pass


def load_tables() -> dict[str, list[dict[str, str]]]:
    tables: dict[str, list[dict[str, str]]] = {}
    for filename, required_columns in REQUIRED_COLUMNS.items():
        path = DATA_DIR / filename
        if not path.is_file():
            raise ValidationError(f"missing table: {path.relative_to(ROOT)}")
        with path.open(newline="", encoding="utf-8-sig") as handle:
            reader = csv.DictReader(handle)
            actual_columns = set(reader.fieldnames or [])
            missing = required_columns - actual_columns
            if missing:
                raise ValidationError(f"{filename}: missing columns {sorted(missing)}")
            rows = list(reader)
        if not rows:
            raise ValidationError(f"{filename}: table is empty")
        ids = [row["id"].strip() for row in rows]
        if any(not item_id for item_id in ids):
            raise ValidationError(f"{filename}: contains an empty id")
        if len(ids) != len(set(ids)):
            raise ValidationError(f"{filename}: contains duplicate ids")
        tables[filename] = rows
    return tables


def id_set(tables: dict[str, list[dict[str, str]]], filename: str) -> set[str]:
    return {row["id"] for row in tables[filename]}


def require_ref(value: str, valid_ids: set[str], context: str) -> None:
    if value and value not in valid_ids:
        raise ValidationError(f"{context}: unknown reference {value!r}")


def validate_content(tables: dict[str, list[dict[str, str]]]) -> None:
    chapter_ids = id_set(tables, "chapter.csv")
    node_ids = id_set(tables, "map_node.csv")
    event_ids = id_set(tables, "event.csv")
    enemy_ids = id_set(tables, "enemy.csv")
    reward_ids = id_set(tables, "reward.csv")

    if chapter_ids != {"chapter_01"}:
        raise ValidationError("Phase 0 must define exactly chapter_01")

    chapter = tables["chapter.csv"][0]
    require_ref(chapter["start_node"], node_ids, "chapter.start_node")
    require_ref(chapter["end_node"], node_ids, "chapter.end_node")
    estimated_minutes = int(chapter["estimated_minutes"])
    if not 15 <= estimated_minutes <= 20:
        raise ValidationError("chapter_01 estimated_minutes must be between 15 and 20")

    chapter_nodes = [row for row in tables["map_node.csv"] if row["chapter_id"] == "chapter_01"]
    if not 7 <= len(chapter_nodes) <= 12:
        raise ValidationError("chapter_01 must contain 7 to 12 meaningful nodes")
    for row in tables["map_node.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"map_node.{row['id']}.chapter_id")
        require_ref(row["event_id"], event_ids, f"map_node.{row['id']}.event_id")
        require_ref(row["enemy_id"], enemy_ids, f"map_node.{row['id']}.enemy_id")
        require_ref(row["reward_id"], reward_ids, f"map_node.{row['id']}.reward_id")
        risk = int(row["risk"])
        if not 0 <= risk <= 3:
            raise ValidationError(f"map_node.{row['id']}.risk must be 0..3")
        if row["visibility"] not in {"visible", "fogged"}:
            raise ValidationError(f"map_node.{row['id']}.visibility is invalid")

    for row in tables["map_edge.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"map_edge.{row['id']}.chapter_id")
        require_ref(row["from_node"], node_ids, f"map_edge.{row['id']}.from_node")
        require_ref(row["to_node"], node_ids, f"map_edge.{row['id']}.to_node")
        if int(row["supply_cost"]) < 0:
            raise ValidationError(f"map_edge.{row['id']}.supply_cost must be non-negative")

    for row in tables["event.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"event.{row['id']}.chapter_id")
    for row in tables["event_choice.csv"]:
        require_ref(row["event_id"], event_ids, f"event_choice.{row['id']}.event_id")
        require_ref(row["reward_id"], reward_ids, f"event_choice.{row['id']}.reward_id")

    expected_roles = {"gunner", "sailor", "navigator", "medic"}
    actual_roles = {row["role"] for row in tables["crew.csv"]}
    if actual_roles != expected_roles:
        raise ValidationError(f"crew roles must be {sorted(expected_roles)}")
    for row in tables["crew.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"crew.{row['id']}.chapter_id")
        if not row["active_skill"] or not row["passive_trait"]:
            raise ValidationError(f"crew.{row['id']} needs one active skill and one passive trait")

    expected_resources = {"gold", "timber", "iron", "provisions", "rune_dust"}
    actual_resources = id_set(tables, "resource.csv")
    if actual_resources != expected_resources:
        raise ValidationError(f"resource ids must be {sorted(expected_resources)}")

    if len(tables["ship_module.csv"]) != 2:
        raise ValidationError("Phase 0 must define exactly two chapter ship-module choices")
    for row in tables["ship_module.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"ship_module.{row['id']}.chapter_id")

    for row in tables["enemy.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"enemy.{row['id']}.chapter_id")
        require_ref(row["reward_id"], reward_ids, f"enemy.{row['id']}.reward_id")
        if not row["transfer_rule"]:
            raise ValidationError(f"enemy.{row['id']} must define the ship-to-boarding transfer rule")

    for row in tables["dialogue.csv"]:
        require_ref(row["chapter_id"], chapter_ids, f"dialogue.{row['id']}.chapter_id")
        require_ref(row["node_id"], node_ids, f"dialogue.{row['id']}.node_id")


def validate_source_gates() -> None:
    for relative_path, markers in REQUIRED_SOURCE_GATES.items():
        path = ROOT / relative_path
        text = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in text:
                raise ValidationError(f"{relative_path}: missing V2 integration marker {marker!r}")


def main() -> int:
    try:
        tables = load_tables()
        validate_content(tables)
        validate_source_gates()
    except (OSError, ValueError, ValidationError) as exc:
        print(f"V2 Phase 0 validation failed: {exc}", file=sys.stderr)
        return 1

    total_rows = sum(len(rows) for rows in tables.values())
    print(
        "V2 Phase 0 content OK: "
        f"{len(tables)} tables, {total_rows} rows, "
        f"{len(REQUIRED_SOURCE_GATES)} runtime gate files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
