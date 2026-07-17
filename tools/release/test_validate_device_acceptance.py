#!/usr/bin/env python3
"""Regression tests for structured physical-device acceptance evidence."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
from pathlib import Path


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/release/validate_device_acceptance.py"
SPEC = importlib.util.spec_from_file_location("validate_device_acceptance", MODULE_PATH)
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


HEAD = git_revision("HEAD")
PREVIOUS = git_revision("HEAD~1")


def record(role: str, model: str, **overrides: str) -> dict[str, str]:
    row = {
        "candidate_id": "2.0.0-1",
        "device_role": role,
        "device_model": model,
        "os_version": "26.2",
        "build_commit": HEAD,
        "distribution_channel": "development",
        "app_store_build_id": "",
        "test_date": "2026-07-17",
        "tester_id": "QA01",
        "session_duration_min": "20",
        "voyage_duration_min": "5",
        "naval_duration_min": "3",
        "boarding_duration_min": "3",
        "thermal_duration_min": "15",
        "fresh_install": "1",
        "cold_launch": "1",
        "safe_area": "1",
        "touch_controls": "1",
        "text_readability": "1",
        "voyage_frame_rate": "1",
        "naval_frame_rate": "1",
        "boarding_frame_rate": "1",
        "thermal_acceptable": "1",
        "silent_switch": "1",
        "audio_mix": "1",
        "volume_acceptable": "1",
        "background_resume": "1",
        "save_recovery": "1",
        "issue_ids": "",
        "evidence_notes": "按协议完成全流程，未记录设备标识",
    }
    row.update(overrides)
    return row


def records(**overrides: str) -> list[dict[str, str]]:
    return [
        record("low_end_iphone", "iPhone SE (3rd generation)", **overrides),
        record("modern_iphone", "iPhone 15", **overrides),
        record("ipad", "iPad (A16)", **overrides),
    ]


def expect_validation_error(rows: list[dict[str, str]], message: str) -> None:
    try:
        MODULE.evaluate(rows)
    except MODULE.ValidationError as error:
        assert message in str(error), str(error)
    else:
        raise AssertionError(f"expected validation failure containing {message!r}")


empty_report, empty_exit = MODULE.evaluate(MODULE.load_records(MODULE.DEFAULT_RECORDS))
assert empty_exit == 2
assert empty_report["ready_for_device_release"] is False
assert empty_report["missing_roles"] == list(MODULE.REQUIRED_ROLES)

development_report, development_exit = MODULE.evaluate(records())
assert development_exit == 0
assert development_report["ready_for_device_release"] is True

strict_development, strict_development_exit = MODULE.evaluate(records(), require_testflight=True)
assert strict_development_exit == 2
assert strict_development["ready_for_device_release"] is False
assert "requires one TestFlight candidate" in strict_development["blockers"][-1]

testflight_rows = records(distribution_channel="testflight", app_store_build_id="123456789")
testflight_report, testflight_exit = MODULE.evaluate(testflight_rows, require_testflight=True)
assert testflight_exit == 0
assert testflight_report["ready_for_device_release"] is True

missing_role, missing_role_exit = MODULE.evaluate(records()[:2])
assert missing_role_exit == 2
assert missing_role["missing_roles"] == ["ipad"]

failed_check_rows = records()
failed_check_rows[1]["silent_switch"] = "0"
failed_check_rows[1]["issue_ids"] = "V2-TEST-DEVICE-AUDIO"
failed_check, failed_check_exit = MODULE.evaluate(failed_check_rows)
assert failed_check_exit == 2
assert "modern_iphone / iPhone 15: silent_switch failed" in failed_check["blockers"]

short_session_rows = records()
short_session_rows[0]["thermal_duration_min"] = "14"
short_session_rows[0]["issue_ids"] = "V2-TEST-DEVICE-DURATION"
short_session, short_session_exit = MODULE.evaluate(short_session_rows)
assert short_session_exit == 2
assert "thermal_duration_min is below 15 minutes" in short_session["blockers"][0]

unregistered_failure_rows = records()
unregistered_failure_rows[0]["touch_controls"] = "0"
expect_validation_error(unregistered_failure_rows, "failed device evidence requires issue_ids")

mixed_build_rows = records()
mixed_build_rows[0]["build_commit"] = PREVIOUS
expect_validation_error(mixed_build_rows, "mix multiple build_commit")

mixed_candidate_rows = records()
mixed_candidate_rows[0]["candidate_id"] = "2.0.0-2"
expect_validation_error(mixed_candidate_rows, "mix multiple candidate_id")

wrong_candidate_rows = records(candidate_id="1.9.9-99")
expect_validation_error(wrong_candidate_rows, "does not match submission candidate")

expect_validation_error(
    records(distribution_channel="testflight", app_store_build_id=""),
    "testflight device rows require app_store_build_id",
)
expect_validation_error(
    records(app_store_build_id="should-be-empty"),
    "development device rows must leave app_store_build_id blank",
)

invalid_boolean_rows = records()
invalid_boolean_rows[0]["safe_area"] = "maybe"
expect_validation_error(invalid_boolean_rows, "expected a boolean value")

duplicate_rows = records()
duplicate_rows.append(dict(duplicate_rows[0]))
expect_validation_error(duplicate_rows, "duplicate device role/model record")

unknown_commit_rows = records(build_commit="f" * 40)
expect_validation_error(unknown_commit_rows, "does not identify a repository commit")

print(
    "Physical-device acceptance validator OK: roles, candidate consistency, durations, "
    "checks, development and TestFlight gates"
)
