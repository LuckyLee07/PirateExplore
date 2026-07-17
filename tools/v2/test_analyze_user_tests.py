#!/usr/bin/env python3
"""Unit tests for the Phase 4 external-test aggregator."""

from __future__ import annotations

import importlib.util
import subprocess
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


def git_revision(revision: str) -> str:
    return subprocess.run(
        ["git", "rev-parse", revision],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


BUILDS = {"R1": git_revision("HEAD~1"), "R2": git_revision("HEAD")}


def record(round_id: str, index: int, **overrides: str) -> dict[str, str]:
    build_commit = BUILDS[round_id]
    row = {
        "round_id": round_id,
        "participant_id": f"{round_id}-P{index:02d}",
        "test_date": "2026-07-17",
        "facilitator": "F01",
        "device": "iPhone SE" if index == 1 else "iPhone 15",
        "device_segment": "small_iphone" if index == 1 else "regular_large_iphone",
        "os_version": "26.2",
        "build_commit": build_commit,
        "prior_genre_experience": "每月 1 款" if index <= 2 else "每周游玩",
        "experience_segment": "light" if index <= 2 else "mid_heavy",
        "technical_failure": "0",
        "t0_start": "10:00:00",
        "t1_goal_understood_sec": "10",
        "t2_first_voyage_sec": "20",
        "t3_battle_entry_sec": "30",
        "t4_boarding_entry_sec": "40",
        "t5_rune_sec": "50",
        "t6_upgrade_sec": "60",
        "t7_second_voyage_sec": "70",
        "independent_first_voyage": "1",
        "battle_understanding": "1",
        "second_voyage_intent": "1",
        "fantasy_first_recall": "1",
        "goal_summary": "出海寻找线索",
        "route_reason": "风险与补给平衡",
        "battle_transfer_explanation": "舰炮削弱接舷敌人",
        "loot_purpose": "回港升级船只",
        "next_action": "继续下一次远航",
        "strongest_pirate_moment": "接舷和夺取符文",
        "most_menu_like_moment": "返港升级选择",
        "desired_content": "想看新海域和船员",
        "observed_blockers": "",
    }
    row.update(overrides)
    return row


def expect_validation_error(rows: list[dict[str, str]], message: str) -> None:
    try:
        MODULE.analyze(rows, targets)
    except MODULE.ValidationError as error:
        assert message in str(error), str(error)
    else:
        raise AssertionError(f"expected validation failure containing {message!r}")


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
        observed_blockers="系统来电中断",
    )
)
incomplete = MODULE.analyze(incomplete_rows, targets)
assert incomplete["rounds"]["R2"]["valid"] == 4
assert incomplete["rounds"]["R2"]["technical_failures"] == 1
assert incomplete["sample_complete"] is False

invalid_rows = [record("R1", 1, battle_understanding="maybe")]
expect_validation_error(invalid_rows, "expected a boolean value")

mixed_build_rows = [dict(row) for row in passing_rows]
mixed_build_rows[0]["build_commit"] = BUILDS["R2"]
expect_validation_error(mixed_build_rows, "mix multiple build_commit")

same_build_rows = [dict(row) for row in passing_rows]
for row in same_build_rows:
    if row["round_id"] == "R2":
        row["build_commit"] = BUILDS["R1"]
expect_validation_error(same_build_rows, "R2 must use a new frozen build_commit")

reversed_build_rows = [dict(row) for row in passing_rows]
for row in reversed_build_rows:
    row["build_commit"] = BUILDS["R2"] if row["round_id"] == "R1" else BUILDS["R1"]
expect_validation_error(reversed_build_rows, "R2 build_commit must descend")

unknown_build = [record("R1", 1, build_commit="f" * 40)]
expect_validation_error(unknown_build, "does not identify a repository commit")

wrong_round_id = [record("R1", 1, participant_id="R2-P01")]
expect_validation_error(wrong_round_id, "participant_id must match the row round")

missing_interview = [record("R1", 1, battle_transfer_explanation="")]
expect_validation_error(missing_interview, "battle_transfer_explanation is required")

ambiguous_technical_failure = [
    record(
        "R1",
        1,
        technical_failure="1",
        observed_blockers="安装失败",
    )
]
expect_validation_error(ambiguous_technical_failure, "technical-failure metric cells must remain blank")

backward_timing = [record("R1", 1, t4_boarding_entry_sec="25")]
expect_validation_error(backward_timing, "is earlier than")

unstratified_rows = [dict(row) for row in passing_rows]
for row in unstratified_rows:
    if row["round_id"] == "R2":
        row["experience_segment"] = "mid_heavy"
unstratified = MODULE.analyze(unstratified_rows, targets)
assert unstratified["sample_complete"] is False
assert "R2 still needs 2 light participant(s)" in unstratified["blockers"]

print(
    "V2 Phase 4 external-test analyzer OK: provenance, frozen builds, stratification, "
    "evidence, timing, exclusion and thresholds"
)
