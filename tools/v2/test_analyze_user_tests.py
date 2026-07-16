#!/usr/bin/env python3
"""Unit tests for the Phase 4 external-test aggregator."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/v2/analyze_user_tests.py"
SPEC = importlib.util.spec_from_file_location("analyze_user_tests", MODULE_PATH)
assert SPEC and SPEC.loader and SPEC.name
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def record(round_id: str, index: int, **overrides: str) -> dict[str, str]:
    row = {
        "round_id": round_id,
        "participant_id": f"{round_id}-P{index:02d}",
        "technical_failure": "0",
        "independent_first_voyage": "1",
        "battle_understanding": "1",
        "second_voyage_intent": "1",
        "fantasy_first_recall": "1",
    }
    row.update(overrides)
    return row


targets = MODULE.load_targets()
passing_rows = [record(round_id, index) for round_id in ("R1", "R2") for index in range(1, 6)]
passing = MODULE.analyze(passing_rows, targets)
assert passing["sample_complete"] is True
assert passing["external_gates_pass"] is True
assert passing["external_decision"] == "PASS"

failing_rows = [dict(row) for row in passing_rows]
for row in failing_rows:
    if row["round_id"] == "R2" and row["participant_id"] in {"R2-P01", "R2-P02"}:
        row["battle_understanding"] = "0"
failing = MODULE.analyze(failing_rows, targets)
assert failing["external_gates_pass"] is False
battle = next(metric for metric in failing["metrics"] if metric["gate_id"] == "battle_understanding")
assert battle["ratio"] == 0.6
assert battle["passed"] is False

incomplete_rows = [record("R1", index) for index in range(1, 6)]
incomplete_rows.extend(record("R2", index) for index in range(1, 5))
incomplete_rows.append(
    record(
        "R2",
        5,
        technical_failure="1",
        independent_first_voyage="",
        battle_understanding="",
        second_voyage_intent="",
        fantasy_first_recall="",
    )
)
incomplete = MODULE.analyze(incomplete_rows, targets)
assert incomplete["rounds"]["R2"]["valid"] == 4
assert incomplete["rounds"]["R2"]["technical_failures"] == 1
assert incomplete["sample_complete"] is False

invalid_rows = [record("R1", 1, battle_understanding="maybe")]
try:
    MODULE.analyze(invalid_rows, targets)
except MODULE.ValidationError:
    pass
else:
    raise AssertionError("invalid boolean value must fail validation")

print("V2 Phase 4 external-test analyzer OK: pass, threshold fail, exclusion, and invalid input")
