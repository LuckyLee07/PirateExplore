#!/usr/bin/env python3
"""Validate structured physical-device acceptance evidence for NewPirate."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RECORDS = ROOT / "docs/release/device-acceptance-template.csv"
SUBMISSION_MANIFEST = ROOT / "docs/release/app-store-submission-manifest.json"
REQUIRED_ROLES = ("low_end_iphone", "modern_iphone", "ipad")
CHANNELS = ("development", "testflight")
TRUE_VALUES = {"1", "true", "yes", "y", "是", "通过"}
FALSE_VALUES = {"0", "false", "no", "n", "否", "未通过"}
BUILD_COMMIT_RE = re.compile(r"[0-9a-fA-F]{7,40}")
CHECK_COLUMNS = (
    "fresh_install",
    "cold_launch",
    "safe_area",
    "touch_controls",
    "text_readability",
    "voyage_frame_rate",
    "naval_frame_rate",
    "boarding_frame_rate",
    "thermal_acceptable",
    "silent_switch",
    "audio_mix",
    "volume_acceptable",
    "background_resume",
    "save_recovery",
)
DURATION_MINIMUMS = {
    "session_duration_min": 20,
    "voyage_duration_min": 5,
    "naval_duration_min": 3,
    "boarding_duration_min": 3,
    "thermal_duration_min": 15,
}
REQUIRED_COLUMNS = {
    "candidate_id",
    "device_role",
    "device_model",
    "os_version",
    "build_commit",
    "distribution_channel",
    "app_store_build_id",
    "test_date",
    "tester_id",
    "issue_ids",
    "evidence_notes",
    *CHECK_COLUMNS,
    *DURATION_MINIMUMS,
}


class ValidationError(Exception):
    pass


def required_text(row: dict[str, str], field: str, context: str) -> str:
    value = (row.get(field) or "").strip()
    if not value:
        raise ValidationError(f"{context}: {field} is required")
    return value


def parse_bool(value: str, context: str) -> bool:
    normalized = (value or "").strip().lower()
    if normalized in TRUE_VALUES:
        return True
    if normalized in FALSE_VALUES:
        return False
    raise ValidationError(f"{context}: expected a boolean value, got {value!r}")


def parse_duration(row: dict[str, str], field: str, context: str) -> int:
    raw = (row.get(field) or "").strip()
    if not raw.isdigit():
        raise ValidationError(f"{context}: {field} must be a whole number of minutes")
    return int(raw)


def load_records(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValidationError(f"device record file does not exist: {path}")
    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            raise ValidationError(f"device record file is missing columns: {sorted(missing)}")
        return list(reader)


def validate_commit(build_commit: str) -> None:
    if not BUILD_COMMIT_RE.fullmatch(build_commit):
        raise ValidationError("build_commit must be a 7–40 character Git SHA")
    result = subprocess.run(
        ["git", "cat-file", "-e", f"{build_commit}^{{commit}}"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise ValidationError(f"build_commit does not identify a repository commit: {build_commit}")


def expected_candidate_id() -> str:
    try:
        payload = json.loads(SUBMISSION_MANIFEST.read_text(encoding="utf-8"))
        candidate = payload["candidate"]
        marketing_version = str(candidate["marketing_version"]).strip()
        build_number = str(candidate["build_number"]).strip()
    except (OSError, UnicodeError, json.JSONDecodeError, KeyError, TypeError) as error:
        raise ValidationError(f"cannot read candidate version from submission manifest: {error}") from error
    if not marketing_version or not build_number:
        raise ValidationError("submission manifest candidate version/build is empty")
    return f"{marketing_version}-{build_number}"


def validate_rows(rows: Iterable[dict[str, str]]) -> list[dict[str, object]]:
    validated: list[dict[str, object]] = []
    device_keys: set[tuple[str, str]] = set()
    for line_number, row in enumerate(rows, start=2):
        context = f"line {line_number}"
        candidate_id = required_text(row, "candidate_id", context)
        role = required_text(row, "device_role", context).lower()
        if role not in REQUIRED_ROLES:
            raise ValidationError(f"{context}: device_role must be one of {REQUIRED_ROLES}")
        model = required_text(row, "device_model", context)
        device_key = (role, model.casefold())
        if device_key in device_keys:
            raise ValidationError(f"{context}: duplicate device role/model record: {role} / {model}")
        device_keys.add(device_key)
        os_version = required_text(row, "os_version", context)
        build_commit = required_text(row, "build_commit", context).lower()
        channel = required_text(row, "distribution_channel", context).lower()
        if channel not in CHANNELS:
            raise ValidationError(f"{context}: distribution_channel must be one of {CHANNELS}")
        app_store_build_id = (row.get("app_store_build_id") or "").strip()
        test_date = required_text(row, "test_date", context)
        try:
            dt.date.fromisoformat(test_date)
        except ValueError as error:
            raise ValidationError(f"{context}: test_date must use YYYY-MM-DD") from error
        tester_id = required_text(row, "tester_id", context)
        evidence_notes = required_text(row, "evidence_notes", context)
        checks = {column: parse_bool(row.get(column, ""), f"{context} {column}") for column in CHECK_COLUMNS}
        durations = {
            field: parse_duration(row, field, context)
            for field in DURATION_MINIMUMS
        }
        duration_failures = [
            field
            for field, minimum in DURATION_MINIMUMS.items()
            if durations[field] < minimum
        ]
        failed_checks = [column for column, passed in checks.items() if not passed]
        issue_ids = (row.get("issue_ids") or "").strip()
        if (failed_checks or duration_failures) and not issue_ids:
            raise ValidationError(f"{context}: failed device evidence requires issue_ids")
        validated.append(
            {
                "candidate_id": candidate_id,
                "device_role": role,
                "device_model": model,
                "os_version": os_version,
                "build_commit": build_commit,
                "distribution_channel": channel,
                "app_store_build_id": app_store_build_id,
                "test_date": test_date,
                "tester_id": tester_id,
                "evidence_notes": evidence_notes,
                "issue_ids": issue_ids,
                "checks": checks,
                "durations": durations,
                "failed_checks": failed_checks,
                "duration_failures": duration_failures,
                "passed": not failed_checks and not duration_failures,
            }
        )

    if validated:
        for field in ("candidate_id", "build_commit", "distribution_channel", "app_store_build_id"):
            values = {str(row[field]) for row in validated}
            if len(values) != 1:
                raise ValidationError(f"device rows mix multiple {field} values")
        candidate_id = str(validated[0]["candidate_id"])
        expected_id = expected_candidate_id()
        if candidate_id != expected_id:
            raise ValidationError(
                f"device candidate_id {candidate_id!r} does not match submission candidate {expected_id!r}"
            )
        build_commit = str(validated[0]["build_commit"])
        validate_commit(build_commit)
        channel = str(validated[0]["distribution_channel"])
        app_store_build_id = str(validated[0]["app_store_build_id"])
        if channel == "testflight" and not app_store_build_id:
            raise ValidationError("testflight device rows require app_store_build_id")
        if channel == "development" and app_store_build_id:
            raise ValidationError("development device rows must leave app_store_build_id blank")
    return validated


def evaluate(rows: Iterable[dict[str, str]], *, require_testflight: bool = False) -> tuple[dict, int]:
    validated = validate_rows(rows)
    roles_present = {str(row["device_role"]) for row in validated}
    missing_roles = [role for role in REQUIRED_ROLES if role not in roles_present]
    blockers = [f"missing required device role: {role}" for role in missing_roles]
    for row in validated:
        for check in row["failed_checks"]:
            blockers.append(f"{row['device_role']} / {row['device_model']}: {check} failed")
        for field in row["duration_failures"]:
            blockers.append(
                f"{row['device_role']} / {row['device_model']}: {field} is below "
                f"{DURATION_MINIMUMS[field]} minutes"
            )
    channel = str(validated[0]["distribution_channel"]) if validated else None
    if require_testflight and channel != "testflight":
        blockers.append("release device acceptance requires one TestFlight candidate across all roles")
    ready = bool(validated) and not blockers
    report = {
        "ready_for_device_release": ready,
        "require_testflight": require_testflight,
        "candidate_id": validated[0]["candidate_id"] if validated else None,
        "build_commit": validated[0]["build_commit"] if validated else None,
        "distribution_channel": channel,
        "app_store_build_id": validated[0]["app_store_build_id"] if validated else None,
        "required_roles": list(REQUIRED_ROLES),
        "missing_roles": missing_roles,
        "sessions": validated,
        "blockers": blockers,
    }
    return report, (0 if ready else 2)


def print_human(report: dict) -> None:
    print("Physical-device acceptance: " + ("PASS" if report["ready_for_device_release"] else "HOLD"))
    print(f"candidate: {report['candidate_id'] or 'pending'}")
    print(f"channel: {report['distribution_channel'] or 'pending'}")
    for session in report["sessions"]:
        status = "PASS" if session["passed"] else "HOLD"
        print(f"DEVICE {session['device_role']} / {session['device_model']}: {status}")
    for blocker in report["blockers"]:
        print(f"BLOCKER: {blocker}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("records", nargs="?", type=Path, default=DEFAULT_RECORDS)
    parser.add_argument("--require-testflight", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        report, exit_code = evaluate(load_records(args.records), require_testflight=args.require_testflight)
    except (OSError, UnicodeError, ValidationError) as error:
        report = {
            "ready_for_device_release": False,
            "require_testflight": args.require_testflight,
            "candidate_id": None,
            "build_commit": None,
            "distribution_channel": None,
            "app_store_build_id": None,
            "required_roles": list(REQUIRED_ROLES),
            "missing_roles": [],
            "sessions": [],
            "blockers": [],
            "audit_errors": [str(error)],
        }
        exit_code = 1
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_human(report)
        for error in report.get("audit_errors", []):
            print(f"AUDIT_ERROR: {error}")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
