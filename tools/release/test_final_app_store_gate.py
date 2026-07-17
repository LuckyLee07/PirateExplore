#!/usr/bin/env python3
"""Pure regression tests for the unified final App Store gate."""

from __future__ import annotations

import copy
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/release"))

import final_app_store_gate as gate  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    pending = [
        "app_record.apple_id",
        "app_record.sku",
        "product_page.privacy_policy_url",
        "distribution.signed_archive",
        "distribution.upload_build_id",
    ]
    grouped = gate.grouped_pending_gates(pending)
    require(grouped["app_record"] == pending[:2], "pending app-record grouping drifted")
    require(grouped["product_page"] == pending[2:3], "pending product-page grouping drifted")
    require(grouped["distribution"] == pending[3:], "pending distribution grouping drifted")

    require(not gate.checks_passed([]), "an empty final check list passed")
    require(
        gate.checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "passed"},
        ]),
        "all-passed final checks failed",
    )
    require(
        not gate.checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "failed"},
        ]),
        "one failed final check still produced GO",
    )
    require(
        not gate.checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "skipped"},
        ]),
        "one skipped final check still produced GO",
    )

    manifest = gate.load_manifest()
    launch = gate.load_manifest(gate.PRODUCT_LAUNCH_MANIFEST)
    head = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    ready_launch = copy.deepcopy(launch)
    ready_launch["candidate"]["release_commit"] = head
    require(
        gate.expected_archive_identity(manifest, ready_launch) == (head, "2.0.0-1"),
        "valid final archive identity failed",
    )

    wrong_candidate = copy.deepcopy(ready_launch)
    wrong_candidate["candidate"]["candidate_id"] = "2.0.0-2"
    try:
        gate.expected_archive_identity(manifest, wrong_candidate)
    except ValueError as error:
        require("does not match" in str(error), "wrong candidate failed for the wrong reason")
    else:
        raise AssertionError("wrong product launch candidate passed")

    missing_commit = copy.deepcopy(ready_launch)
    missing_commit["candidate"]["release_commit"] = None
    try:
        gate.expected_archive_identity(manifest, missing_commit)
    except ValueError as error:
        require("clean full Git SHA" in str(error), "missing release commit failed for the wrong reason")
    else:
        raise AssertionError("missing product launch release commit passed")

    unknown_commit = copy.deepcopy(ready_launch)
    unknown_commit["candidate"]["release_commit"] = "f" * 40
    try:
        gate.expected_archive_identity(manifest, unknown_commit)
    except ValueError as error:
        require("does not identify" in str(error), "unknown release commit failed for the wrong reason")
    else:
        raise AssertionError("unknown product launch release commit passed")

    original_root = gate.ROOT
    with tempfile.TemporaryDirectory() as temporary:
        temporary_root = Path(temporary).resolve()
        archive = temporary_root / "build/final.xcarchive"
        product_app = archive / "Products/Applications/NewPirate.app"
        split_app = archive / "Other/Split.app"
        product_app.mkdir(parents=True)
        split_app.mkdir(parents=True)
        with (archive / "Info.plist").open("wb") as handle:
            plistlib.dump({"ApplicationProperties": {"ApplicationPath": "Other/Split.app"}}, handle)
        gate.ROOT = temporary_root
        try:
            gate.resolve_archive({"distribution": {"signed_archive": "build/final.xcarchive"}})
        except ValueError as error:
            require("only product app" in str(error), "split ApplicationPath failed for the wrong reason")
        else:
            raise AssertionError("split archive ApplicationPath passed")
        finally:
            gate.ROOT = original_root

    prepared_manifest = copy.deepcopy(manifest)
    prepared_manifest["distribution"]["developer_team_id"] = "TEAM123456"
    original_resolver = gate.resolve_archive
    gate.resolve_archive = lambda _: (Path("/tmp/NewPirate.xcarchive"), Path("/tmp/NewPirate.app"))
    try:
        specs = gate.build_check_specs(prepared_manifest, ready_launch)
    finally:
        gate.resolve_archive = original_resolver
    require([spec.name for spec in specs] == [
        "submission_manifest_strict",
        "public_pages_live",
        "archive_content",
        "signed_app_distribution",
    ], "final App Store check set drifted")
    for spec in specs[2:]:
        require("--expected-source-commit" in spec.command, f"{spec.name} lacks source identity")
        require(head in spec.command, f"{spec.name} lacks the final release commit")
        require("--expected-candidate-id" in spec.command, f"{spec.name} lacks candidate identity")
        require("2.0.0-1" in spec.command, f"{spec.name} lacks the final candidate ID")
        require("--require-clean-provenance" in spec.command, f"{spec.name} accepts dirty provenance")

    print(
        "Final App Store gate OK: grouped blockers, non-bypassable checks and "
        "release-commit provenance binding"
    )


if __name__ == "__main__":
    main()
