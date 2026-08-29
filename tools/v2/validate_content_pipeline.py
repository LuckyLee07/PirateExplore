#!/usr/bin/env python3
"""Validate the whole-content contract and non-runtime voyage design candidates."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/v2"))

from content_contract import load_tables, validate_repository  # noqa: E402


issues = validate_repository(ROOT)
if issues:
    raise SystemExit("V2 authored-content contract failed:\n" + "\n".join(map(str, issues)))

tables, loading_issues = load_tables(ROOT / "design/v2/data")
if loading_issues:
    raise SystemExit("V2 content tables could not be loaded")

all_runtime_values = {
    value
    for rows in tables.values()
    for row in rows
    for value in row.values()
    if value
}
config_text = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
state_text = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")

candidate_path = ROOT / "design/v2/content_slices/voyage-03-frostbound.json"
candidate = json.loads(candidate_path.read_text(encoding="utf-8"))

required_top_level = {
    "schema_version", "id", "status", "runtime_exposed", "title", "player_promise",
    "source_trace", "non_goals", "structure", "routes", "character_event", "encounter",
    "growth_payoffs", "ui_contract", "asset_budget", "reserved_runtime_ids",
    "qa_profiles", "telemetry", "acceptance_gates",
}
missing = required_top_level - set(candidate)
if missing:
    raise SystemExit(f"third-voyage candidate is missing fields: {sorted(missing)}")
if candidate["schema_version"] != 1 or candidate["status"] != "design_candidate":
    raise SystemExit("third-voyage candidate must use schema 1 and remain a design_candidate")
if candidate["runtime_exposed"] is not False:
    raise SystemExit("unfinished third-voyage content cannot be exposed to players")
if len(candidate["player_promise"]) < 30:
    raise SystemExit("third-voyage candidate needs a player-facing promise, not an asset list")

sources = candidate["source_trace"]
if len(sources) < 3:
    raise SystemExit("third-voyage candidate needs world, enemy and plot source traces")
for source in sources:
    if not {"path", "record", "adopt", "reject"}.issubset(source):
        raise SystemExit("each source trace must state its record, adoption and rejection boundary")
    if not Path(source["path"]).is_file():
        raise SystemExit(f"third-voyage source is missing: {source['path']}")

structure = candidate["structure"]
stages = structure.get("stages", [])
if not 8 <= int(structure.get("target_minutes", 0)) <= 12:
    raise SystemExit("third voyage must remain a focused 8–12 minute slice")
if not 4 <= int(structure.get("meaningful_nodes", 0)) <= 6:
    raise SystemExit("third voyage must use 4–6 meaningful nodes")
if len(stages) != 6 or len(stages) != len(set(stages)):
    raise SystemExit("third voyage needs six unique route/event/hazard/rune/settlement/complete stages")

routes = candidate["routes"]
if len(routes) != 2:
    raise SystemExit("third voyage needs exactly two comparable routes")
for route in routes:
    for field in ("id", "label", "visible_cost", "growth_payoff", "why_not_dominant"):
        if not route.get(field):
            raise SystemExit(f"third-voyage route is missing {field}")

event = candidate["character_event"]
if len(event.get("focus_characters", [])) != 2 or len(event.get("choices", [])) != 2:
    raise SystemExit("third voyage needs a focused two-character, two-choice event")
if "最终决定" not in event.get("agency_rule", ""):
    raise SystemExit("third-voyage character advice must preserve captain agency")
crew_ids = {row["id"] for row in tables["crew"]}
if not set(event["focus_characters"]).issubset(crew_ids):
    raise SystemExit("third-voyage focus characters must already exist in the retained crew")
if any(not choice.get("consequence") for choice in event["choices"]):
    raise SystemExit("each third-voyage character choice needs an immediate visible consequence")

encounter = candidate["encounter"]
for field in ("name", "mechanic", "difference_from_previous", "telegraph", "failure_recovery"):
    if not encounter.get(field):
        raise SystemExit(f"third-voyage encounter is missing {field}")
if "不是把单一护盾打到零" not in encounter["mechanic"]:
    raise SystemExit("third-voyage encounter must explicitly reject a renamed Tide shield")
if "预告" not in encounter["telegraph"]:
    raise SystemExit("third-voyage hazard must be readable before commitment")

required_growth = {
    "ship_hull_level", "ship_gun_level", "crew_upgrade_sailor",
    "crew_upgrade_gunner", "crew_navigator", "crew_medic",
}
growth_ids = {item.get("growth") for item in candidate["growth_payoffs"]}
if growth_ids != required_growth:
    raise SystemExit(f"third-voyage growth coverage drifted: {sorted(growth_ids)}")

ui = candidate["ui_contract"]
for field in ("stable_shell", "new_focus", "decision_preview", "result_feedback", "motion"):
    if not ui.get(field):
        raise SystemExit(f"third-voyage UI contract is missing {field}")
if "只新增一条" not in ui["new_focus"] or "不循环" not in ui["motion"]:
    raise SystemExit("third-voyage UI must keep one new focus and restrained one-time motion")

assets = candidate["asset_budget"]
if len(assets) != 3 or any(item.get("required_before_runtime") is not True for item in assets):
    raise SystemExit("third voyage requires exactly three approved hero assets before runtime exposure")

reserved = candidate["reserved_runtime_ids"]
if len(reserved) != len(set(reserved)) or len(reserved) < 25:
    raise SystemExit("third-voyage reserved runtime ids are incomplete or duplicated")
for identifier in reserved:
    if identifier in all_runtime_values or identifier in config_text or identifier in state_text:
        raise SystemExit(f"unfinished third-voyage id leaked into runtime: {identifier}")
if set(candidate["qa_profiles"]) - set(reserved):
    raise SystemExit("all planned third-voyage QA profiles must be reserved")
if set(candidate["telemetry"]) - set(reserved):
    raise SystemExit("all planned third-voyage telemetry ids must be reserved")

gates = candidate["acceptance_gates"]
required_gate_markers = ("三次航程", "正反路径", "失败", "QA", "1206×2622", "Phase 4", "iOS Simulator", "不出现")
for marker in required_gate_markers:
    if not any(marker in gate for gate in gates):
        raise SystemExit(f"third-voyage acceptance gates are missing: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "python3 tools/v2/test_content_contract.py",
    "python3 tools/v2/validate_content_pipeline.py",
):
    if command not in phase4:
        raise SystemExit(f"content pipeline is not in the Phase 4 chain: {command}")

record = (ROOT / "docs/v2/content-expansion-pipeline-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why", "19 张", "极地港 · 霜冻航线", "移动冰潮",
    "runtime_exposed = false", "不暴露出航按钮", "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"content-pipeline record is missing: {marker}")
for marker in ("内容扩展管线第 1 轮", "移动冰潮", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing content-pipeline marker: {marker}")
if "content-expansion-pipeline-iteration-1.md" not in readme:
    raise SystemExit("README does not link the content-expansion pipeline record")

print("V2 content expansion pipeline OK: 19-table contract and unexposed Frostbound voyage candidate passed")
