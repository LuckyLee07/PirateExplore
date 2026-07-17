#!/usr/bin/env python3
"""Run the non-bypassable overall product launch gate for NewPirate."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOOLS_RELEASE = ROOT / "tools/release"
TOOLS_V2 = ROOT / "tools/v2"
LAUNCH_MANIFEST = ROOT / "docs/release/product-launch-manifest.json"
SUBMISSION_MANIFEST = ROOT / "docs/release/app-store-submission-manifest.json"
QUALITY_GATES = ROOT / "design/v2/data/quality_gate.csv"
ISSUE_REGISTER = ROOT / "docs/v2/phase-4-issue-register.csv"
PHASE4_DECISION = ROOT / "docs/v2/phase-4-decision.md"
sys.path.insert(0, str(TOOLS_RELEASE))

from validate_app_store_submission import pending_release_gates  # noqa: E402


EXPECTED_CHECKS = (
    "internal_release_regression",
    "external_user_evidence",
    "device_acceptance_testflight",
    "app_store_submission",
    "candidate_consistency",
)


class ValidationError(Exception):
    pass


def load_json(path: Path) -> dict:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValidationError(f"cannot read {path.relative_to(ROOT)}: {error}") from error
    if not isinstance(payload, dict):
        raise ValidationError(f"{path.relative_to(ROOT)} root must be an object")
    return payload


def load_csv(path: Path) -> list[dict[str, str]]:
    try:
        with path.open(encoding="utf-8", newline="") as handle:
            return list(csv.DictReader(handle))
    except (OSError, UnicodeError, csv.Error) as error:
        raise ValidationError(f"cannot read {path.relative_to(ROOT)}: {error}") from error


def expected_candidate_id(submission: dict) -> str:
    try:
        candidate = submission["candidate"]
        version = str(candidate["marketing_version"]).strip()
        build = str(candidate["build_number"]).strip()
    except (KeyError, TypeError) as error:
        raise ValidationError("submission manifest candidate version/build is invalid") from error
    if not version or not build:
        raise ValidationError("submission manifest candidate version/build is empty")
    return f"{version}-{build}"


def grouped_pending_gates(pending: list[str]) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}
    for gate in pending:
        group = gate.split(".", 1)[0]
        groups.setdefault(group, []).append(gate)
    return groups


def pending_product_gates(
    launch: dict,
    submission: dict,
    quality_rows: list[dict[str, str]],
    issue_rows: list[dict[str, str]],
) -> list[str]:
    pending: list[str] = []
    try:
        candidate = launch["candidate"]
        evidence = launch["evidence"]
        decision = launch["decision"]
    except (KeyError, TypeError) as error:
        raise ValidationError("product launch manifest sections are incomplete") from error

    if launch.get("schema_version") != 1:
        raise ValidationError("product launch manifest schema_version must be 1")
    if candidate.get("candidate_id") != expected_candidate_id(submission):
        raise ValidationError("product launch candidate_id does not match submission manifest")
    if not candidate.get("release_commit"):
        pending.append("launch.release_commit")
    if not evidence.get("external_test_records"):
        pending.append("launch.external_test_records")
    if not evidence.get("device_acceptance_records"):
        pending.append("launch.device_acceptance_records")
    if decision.get("phase4_status") != "GO":
        pending.append("launch.phase4_status")
    if decision.get("product_scope_approved") is not True:
        pending.append("launch.product_scope_approved")
    if decision.get("second_map_budget_approved") is not True:
        pending.append("launch.second_map_budget_approved")
    if not decision.get("approved_by"):
        pending.append("launch.approved_by")
    if not decision.get("approved_date"):
        pending.append("launch.approved_date")

    pending.extend(f"app_store.{gate}" for gate in pending_release_gates(submission))

    expected_quality_status = {
        "independent_first_voyage": "external_pass",
        "battle_understanding": "external_pass",
        "second_voyage_intent": "external_pass",
        "fantasy_recall": "external_pass",
        "critical_crash": "internal_pass",
        "save_recovery": "internal_pass",
        "mapped_assets": "internal_pass",
        "simulator_memory": "internal_pass",
        "target_frame_rate": "device_pass",
        "second_map_pipeline": "internal_estimate",
    }
    quality_by_id = {row.get("id", ""): row for row in quality_rows}
    if set(quality_by_id) != set(expected_quality_status):
        raise ValidationError("quality_gate.csv gate set does not match the product launch contract")
    for gate_id, expected_status in expected_quality_status.items():
        if quality_by_id[gate_id].get("evidence_status") != expected_status:
            pending.append(f"quality_gate.{gate_id}")

    for row in issue_rows:
        if row.get("severity") not in {"P0", "P1"}:
            continue
        if row.get("status") != "fixed" or row.get("release_effect") != "closed":
            issue_id = row.get("issue_id") or "unknown"
            pending.append(f"issue_register.{issue_id}")
    return pending


def resolve_evidence_path(value: object, label: str) -> Path:
    if not isinstance(value, str) or not value:
        raise ValidationError(f"{label} is empty")
    path = (ROOT / value).resolve()
    if ROOT not in path.parents or path.suffix.lower() != ".csv" or not path.is_file():
        raise ValidationError(f"{label} must be an existing CSV inside the repository")
    return path


def condensed_output(result: subprocess.CompletedProcess[str], limit: int = 4000) -> str:
    output = "\n".join(value.strip() for value in (result.stdout, result.stderr) if value.strip())
    return output if len(output) <= limit else "…" + output[-limit:]


def run_plain_check(name: str, command: list[str]) -> tuple[dict, None]:
    result = subprocess.run(command, cwd=ROOT, check=False, text=True, capture_output=True)
    return {
        "name": name,
        "status": "passed" if result.returncode == 0 else "failed",
        "exit_code": result.returncode,
        "output": condensed_output(result),
    }, None


def run_json_check(name: str, command: list[str], ready_key: str) -> tuple[dict, dict | None]:
    result = subprocess.run(command, cwd=ROOT, check=False, text=True, capture_output=True)
    payload: dict | None = None
    parse_error = ""
    try:
        candidate_payload = json.loads(result.stdout)
        if isinstance(candidate_payload, dict):
            payload = candidate_payload
        else:
            parse_error = "JSON report root is not an object"
    except json.JSONDecodeError as error:
        parse_error = f"invalid JSON report: {error}"
    passed = result.returncode == 0 and payload is not None and payload.get(ready_key) is True
    output = condensed_output(result)
    if parse_error:
        output = "\n".join(value for value in (output, parse_error) if value)
    return {
        "name": name,
        "status": "passed" if passed else "failed",
        "exit_code": result.returncode,
        "output": output,
    }, payload


def git_commit_exists(commit: str) -> bool:
    return subprocess.run(
        ["git", "cat-file", "-e", f"{commit}^{{commit}}"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    ).returncode == 0


def git_is_ancestor(ancestor: str, descendant: str) -> bool:
    return subprocess.run(
        ["git", "merge-base", "--is-ancestor", ancestor, descendant],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    ).returncode == 0


def candidate_consistency_errors(
    launch: dict,
    submission: dict,
    external_report: dict | None,
    device_report: dict | None,
    decision_text: str,
) -> list[str]:
    errors: list[str] = []
    release_commit = str(launch.get("candidate", {}).get("release_commit") or "")
    expected_id = expected_candidate_id(submission)
    upload_build_id = str(submission.get("distribution", {}).get("upload_build_id") or "")
    if not release_commit or not git_commit_exists(release_commit):
        errors.append("release_commit does not identify a repository commit")
    if not external_report or external_report.get("external_gates_pass") is not True:
        errors.append("external test report is not PASS")
    if not device_report or device_report.get("ready_for_device_release") is not True:
        errors.append("device acceptance report is not PASS")
    if device_report:
        if device_report.get("candidate_id") != expected_id:
            errors.append("device candidate_id does not match submission candidate")
        if device_report.get("build_commit") != release_commit:
            errors.append("device build_commit does not match release_commit")
        if str(device_report.get("app_store_build_id") or "") != upload_build_id:
            errors.append("device TestFlight build does not match uploaded App Store build")
    if external_report and release_commit:
        rounds = external_report.get("rounds")
        r2_commit = rounds.get("R2", {}).get("build_commit") if isinstance(rounds, dict) else None
        if not isinstance(r2_commit, str) or not git_commit_exists(r2_commit):
            errors.append("external R2 build_commit is missing or invalid")
        elif git_commit_exists(release_commit) and not git_is_ancestor(r2_commit, release_commit):
            errors.append("release_commit does not include the frozen external R2 build")
    if "当前决策：**GO" not in decision_text:
        errors.append("phase-4-decision.md is not a final GO decision")
    return errors


def checks_passed(checks: list[dict]) -> bool:
    return (
        [check.get("name") for check in checks] == list(EXPECTED_CHECKS)
        and all(check.get("status") == "passed" for check in checks)
    )


def evaluate_current_state() -> tuple[dict, int]:
    launch = load_json(LAUNCH_MANIFEST)
    submission = load_json(SUBMISSION_MANIFEST)
    quality_rows = load_csv(QUALITY_GATES)
    issue_rows = load_csv(ISSUE_REGISTER)
    pending = pending_product_gates(launch, submission, quality_rows, issue_rows)
    if pending:
        return {
            "product_launch_ready": False,
            "pending_gate_count": len(pending),
            "pending_gates": pending,
            "pending_groups": grouped_pending_gates(pending),
            "checks": [
                {
                    "name": name,
                    "status": "skipped",
                    "reason": "all product, quality, issue and App Store prerequisites must be complete",
                }
                for name in EXPECTED_CHECKS
            ],
            "audit_errors": [],
        }, 2

    evidence = launch["evidence"]
    external_records = resolve_evidence_path(evidence["external_test_records"], "external_test_records")
    device_records = resolve_evidence_path(evidence["device_acceptance_records"], "device_acceptance_records")
    approved_date = launch["decision"]["approved_date"]
    try:
        dt.date.fromisoformat(approved_date)
    except (TypeError, ValueError) as error:
        raise ValidationError("decision.approved_date must use YYYY-MM-DD") from error

    python = sys.executable
    checks: list[dict] = []
    internal_check, _ = run_plain_check(
        "internal_release_regression",
        [str(TOOLS_RELEASE / "validate_ios_release.sh")],
    )
    checks.append(internal_check)
    external_check, external_report = run_json_check(
        "external_user_evidence",
        [python, str(TOOLS_V2 / "analyze_user_tests.py"), str(external_records), "--format", "json"],
        "external_gates_pass",
    )
    checks.append(external_check)
    device_check, device_report = run_json_check(
        "device_acceptance_testflight",
        [python, str(TOOLS_RELEASE / "validate_device_acceptance.py"), str(device_records), "--require-testflight", "--json"],
        "ready_for_device_release",
    )
    checks.append(device_check)
    app_store_check, _ = run_json_check(
        "app_store_submission",
        [python, str(TOOLS_RELEASE / "final_app_store_gate.py"), "--json"],
        "ready_for_submission",
    )
    checks.append(app_store_check)
    consistency_errors = candidate_consistency_errors(
        launch,
        submission,
        external_report,
        device_report,
        PHASE4_DECISION.read_text(encoding="utf-8"),
    )
    checks.append(
        {
            "name": "candidate_consistency",
            "status": "passed" if not consistency_errors else "failed",
            "exit_code": 0 if not consistency_errors else 2,
            "output": "\n".join(consistency_errors),
        }
    )
    ready = checks_passed(checks)
    return {
        "product_launch_ready": ready,
        "pending_gate_count": 0,
        "pending_gates": [],
        "pending_groups": {},
        "checks": checks,
        "audit_errors": [],
    }, (0 if ready else 2)


def print_human(report: dict) -> None:
    print("Final product launch gate: " + ("GO" if report["product_launch_ready"] else "HOLD"))
    if report["pending_gate_count"]:
        print(f"pending gates: {report['pending_gate_count']}")
        for group, gates in report["pending_groups"].items():
            print(f"  {group}: {len(gates)}")
    for check in report["checks"]:
        print(f"CHECK {check['name']}: {check['status']}")
        if check.get("output"):
            print(check["output"])
    for error in report["audit_errors"]:
        print(f"AUDIT_ERROR: {error}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        report, exit_code = evaluate_current_state()
    except (OSError, UnicodeError, ValidationError, KeyError, TypeError) as error:
        report = {
            "product_launch_ready": False,
            "pending_gate_count": 0,
            "pending_gates": [],
            "pending_groups": {},
            "checks": [],
            "audit_errors": [str(error)],
        }
        exit_code = 1
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_human(report)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
