#!/usr/bin/env python3
"""Regression tests for the overall NewPirate product launch gate."""

from __future__ import annotations

import copy
import importlib.util
import subprocess
import sys
from pathlib import Path


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/release/final_product_launch_gate.py"
SPEC = importlib.util.spec_from_file_location("final_product_launch_gate", MODULE_PATH)
assert SPEC and SPEC.loader and SPEC.name
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


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

launch = MODULE.load_json(MODULE.LAUNCH_MANIFEST)
submission = MODULE.load_json(MODULE.SUBMISSION_MANIFEST)
quality_rows = MODULE.load_csv(MODULE.QUALITY_GATES)
issue_rows = MODULE.load_csv(MODULE.ISSUE_REGISTER)
pending = MODULE.pending_product_gates(launch, submission, quality_rows, issue_rows)
grouped = MODULE.grouped_pending_gates(pending)
require(len(pending) == 47, f"current overall blocker count drifted: {len(pending)}")
require(len(grouped["launch"]) == 8, "launch manifest blocker grouping drifted")
require(len(grouped["app_store"]) == 30, "App Store blocker grouping drifted")
require(len(grouped["quality_gate"]) == 5, "quality-gate blocker grouping drifted")
require(len(grouped["issue_register"]) == 4, "issue-register blocker grouping drifted")

require(not MODULE.checks_passed([]), "an empty overall check list passed")
all_passed = [{"name": name, "status": "passed"} for name in MODULE.EXPECTED_CHECKS]
require(MODULE.checks_passed(all_passed), "all required overall checks did not pass")
missing_check = all_passed[:-1]
require(not MODULE.checks_passed(missing_check), "a missing overall check still produced GO")
failed_check = [dict(check) for check in all_passed]
failed_check[2]["status"] = "failed"
require(not MODULE.checks_passed(failed_check), "one failed overall check still produced GO")
skipped_check = [dict(check) for check in all_passed]
skipped_check[3]["status"] = "skipped"
require(not MODULE.checks_passed(skipped_check), "one skipped overall check still produced GO")

ready_launch = copy.deepcopy(launch)
ready_launch["candidate"]["release_commit"] = HEAD
ready_submission = copy.deepcopy(submission)
ready_submission["distribution"]["upload_build_id"] = "123456789"
external_report = {
    "external_gates_pass": True,
    "rounds": {"R2": {"build_commit": PREVIOUS}},
}
device_report = {
    "ready_for_device_release": True,
    "candidate_id": "2.0.0-1",
    "build_commit": HEAD,
    "app_store_build_id": "123456789",
}
errors = MODULE.candidate_consistency_errors(
    ready_launch,
    ready_submission,
    external_report,
    device_report,
    "当前决策：**GO（限额发布）**",
)
require(not errors, f"consistent launch candidate failed: {errors}")

wrong_device = dict(device_report)
wrong_device["build_commit"] = PREVIOUS
errors = MODULE.candidate_consistency_errors(
    ready_launch,
    ready_submission,
    external_report,
    wrong_device,
    "当前决策：**GO（限额发布）**",
)
require("device build_commit does not match release_commit" in errors, "device/build mismatch passed")

old_launch = copy.deepcopy(ready_launch)
old_launch["candidate"]["release_commit"] = PREVIOUS
future_external = {
    "external_gates_pass": True,
    "rounds": {"R2": {"build_commit": HEAD}},
}
old_device = dict(device_report)
old_device["build_commit"] = PREVIOUS
errors = MODULE.candidate_consistency_errors(
    old_launch,
    ready_submission,
    future_external,
    old_device,
    "当前决策：**GO（限额发布）**",
)
require("release_commit does not include the frozen external R2 build" in errors, "old release passed R2 ancestry")

errors = MODULE.candidate_consistency_errors(
    ready_launch,
    ready_submission,
    external_report,
    device_report,
    "当前决策：**HOLD**",
)
require("phase-4-decision.md is not a final GO decision" in errors, "HOLD decision passed")

print(
    "Final product launch gate OK: 47 grouped blockers, complete check set and "
    "cross-evidence candidate consistency"
)
