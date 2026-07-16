#!/usr/bin/env python3
"""Validate and aggregate two rounds of anonymized V2 target-user records.

This tool deliberately reports only the external-user gates. It never turns an
external pass into an overall Go decision; device, quality, issue, and budget
evidence remain separate Phase 4 requirements.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
QUALITY_GATES = ROOT / "design/v2/data/quality_gate.csv"

REQUIRED_COLUMNS = {
    "round_id",
    "participant_id",
    "technical_failure",
    "independent_first_voyage",
    "battle_understanding",
    "second_voyage_intent",
    "fantasy_first_recall",
}
ROUND_IDS = ("R1", "R2")
METRIC_COLUMNS = {
    "independent_first_voyage": "independent_first_voyage",
    "battle_understanding": "battle_understanding",
    "second_voyage_intent": "second_voyage_intent",
    "fantasy_recall": "fantasy_first_recall",
}
TRUE_VALUES = {"1", "true", "yes", "y", "是", "通过"}
FALSE_VALUES = {"0", "false", "no", "n", "否", "未通过"}


class ValidationError(Exception):
    pass


@dataclass(frozen=True)
class MetricResult:
    gate_id: str
    passed_count: int
    denominator: int
    ratio: float
    target: float

    @property
    def passed(self) -> bool:
        return self.denominator > 0 and self.ratio >= self.target


def parse_bool(value: str, context: str, *, allow_blank: bool = False) -> bool | None:
    normalized = (value or "").strip().lower()
    if allow_blank and not normalized:
        return None
    if normalized in TRUE_VALUES:
        return True
    if normalized in FALSE_VALUES:
        return False
    raise ValidationError(f"{context}: expected a boolean value, got {value!r}")


def load_records(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValidationError(f"record file does not exist: {path}")
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            raise ValidationError(f"record file is missing columns: {sorted(missing)}")
        rows = list(reader)
    if not rows:
        raise ValidationError("record file contains no participant rows")
    return rows


def load_targets(path: Path = QUALITY_GATES) -> dict[str, float]:
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    targets: dict[str, float] = {}
    for row in rows:
        if row["id"] not in METRIC_COLUMNS:
            continue
        match = re.fullmatch(r">=(\d+)%", row["target"].strip())
        if not match:
            raise ValidationError(f"gate {row['id']} has an unsupported target: {row['target']!r}")
        targets[row["id"]] = int(match.group(1)) / 100.0
    if set(targets) != set(METRIC_COLUMNS):
        raise ValidationError("quality_gate.csv does not define every external metric")
    return targets


def validate_rows(rows: Iterable[dict[str, str]]) -> list[dict[str, object]]:
    validated: list[dict[str, object]] = []
    participants: set[str] = set()
    for line_number, row in enumerate(rows, start=2):
        round_id = (row.get("round_id") or "").strip().upper()
        if round_id not in ROUND_IDS:
            raise ValidationError(f"line {line_number}: round_id must be R1 or R2")
        participant_id = (row.get("participant_id") or "").strip()
        if not participant_id:
            raise ValidationError(f"line {line_number}: participant_id is required")
        if participant_id in participants:
            raise ValidationError(f"line {line_number}: duplicate participant_id {participant_id!r}")
        participants.add(participant_id)

        technical_failure = parse_bool(
            row.get("technical_failure", ""),
            f"line {line_number} technical_failure",
        )
        metrics: dict[str, bool | None] = {}
        for gate_id, column in METRIC_COLUMNS.items():
            metrics[gate_id] = parse_bool(
                row.get(column, ""),
                f"line {line_number} {column}",
                allow_blank=technical_failure is True,
            )
        validated.append(
            {
                "round_id": round_id,
                "participant_id": participant_id,
                "technical_failure": technical_failure,
                "metrics": metrics,
            }
        )
    return validated


def analyze(
    rows: Iterable[dict[str, str]],
    targets: dict[str, float],
    minimum_per_round: int = 5,
) -> dict[str, object]:
    if minimum_per_round < 1:
        raise ValidationError("minimum_per_round must be positive")
    validated = validate_rows(rows)
    round_summary: dict[str, dict[str, int]] = {}
    valid_by_round: dict[str, list[dict[str, object]]] = {}
    for round_id in ROUND_IDS:
        round_rows = [row for row in validated if row["round_id"] == round_id]
        valid_rows = [row for row in round_rows if not row["technical_failure"]]
        valid_by_round[round_id] = valid_rows
        round_summary[round_id] = {
            "total": len(round_rows),
            "valid": len(valid_rows),
            "technical_failures": len(round_rows) - len(valid_rows),
        }

    sample_complete = all(
        round_summary[round_id]["valid"] >= minimum_per_round for round_id in ROUND_IDS
    )
    second_round = valid_by_round["R2"]
    metric_results: list[MetricResult] = []
    for gate_id in METRIC_COLUMNS:
        passed_count = sum(
            1
            for row in second_round
            if isinstance(row["metrics"], dict) and row["metrics"].get(gate_id) is True
        )
        denominator = len(second_round)
        metric_results.append(
            MetricResult(
                gate_id=gate_id,
                passed_count=passed_count,
                denominator=denominator,
                ratio=passed_count / denominator if denominator else 0.0,
                target=targets[gate_id],
            )
        )

    external_gates_pass = sample_complete and all(result.passed for result in metric_results)
    blockers: list[str] = []
    for round_id in ROUND_IDS:
        missing = minimum_per_round - round_summary[round_id]["valid"]
        if missing > 0:
            blockers.append(f"{round_id} still needs {missing} valid participant(s)")
    for result in metric_results:
        if result.denominator and not result.passed:
            blockers.append(
                f"{result.gate_id} is {result.ratio:.0%}, below {result.target:.0%}"
            )

    return {
        "minimum_valid_per_round": minimum_per_round,
        "rounds": round_summary,
        "sample_complete": sample_complete,
        "metrics": [
            {
                "gate_id": result.gate_id,
                "passed_count": result.passed_count,
                "denominator": result.denominator,
                "ratio": result.ratio,
                "target": result.target,
                "passed": result.passed,
            }
            for result in metric_results
        ],
        "external_gates_pass": external_gates_pass,
        "external_decision": "PASS" if external_gates_pass else "HOLD",
        "blockers": blockers,
        "scope_warning": (
            "External PASS is not an overall Go decision; device, P0/P1, quality, "
            "budget, and final regression evidence must also pass."
        ),
    }


def markdown_report(result: dict[str, object], source: Path) -> str:
    rounds = result["rounds"]
    metrics = result["metrics"]
    assert isinstance(rounds, dict) and isinstance(metrics, list)
    lines = [
        "# V2 Phase 4 External Test Aggregate",
        "",
        f"Source: `{source}`",
        "",
        f"External gate result: **{result['external_decision']}**",
        "",
        "## Sample",
        "",
        "| Round | Total | Valid | Technical failures |",
        "| --- | ---: | ---: | ---: |",
    ]
    for round_id in ROUND_IDS:
        summary = rounds[round_id]
        assert isinstance(summary, dict)
        lines.append(
            f"| {round_id} | {summary['total']} | {summary['valid']} | "
            f"{summary['technical_failures']} |"
        )
    lines.extend(
        [
            "",
            "## Second-round gates",
            "",
            "| Gate | Result | Target | Status |",
            "| --- | ---: | ---: | --- |",
        ]
    )
    for metric in metrics:
        assert isinstance(metric, dict)
        ratio = float(metric["ratio"])
        target = float(metric["target"])
        lines.append(
            f"| {metric['gate_id']} | {metric['passed_count']}/{metric['denominator']} "
            f"({ratio:.0%}) | {target:.0%} | "
            f"{'PASS' if metric['passed'] else 'HOLD'} |"
        )
    blockers = result["blockers"]
    assert isinstance(blockers, list)
    if blockers:
        lines.extend(["", "## Blockers", ""])
        lines.extend(f"- {blocker}" for blocker in blockers)
    lines.extend(["", f"> {result['scope_warning']}", ""])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("records", type=Path, help="CSV copied from the Phase 4 template")
    parser.add_argument("--output", type=Path, help="optional report path")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--minimum-per-round", type=int, default=5)
    args = parser.parse_args()

    try:
        rows = load_records(args.records)
        result = analyze(rows, load_targets(), args.minimum_per_round)
    except (OSError, ValidationError) as exc:
        print(f"V2 external test analysis failed: {exc}", file=sys.stderr)
        return 1

    output = (
        json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if args.format == "json"
        else markdown_report(result, args.records)
    )
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output, encoding="utf-8")
    else:
        print(output, end="")
    return 0 if result["external_gates_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
