#!/usr/bin/env python3
"""Run the non-bypassable final App Store gate for the NewPirate iOS candidate."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/release/app-store-submission-manifest.json"
PRODUCT_LAUNCH_MANIFEST = ROOT / "docs/release/product-launch-manifest.json"
TOOLS = ROOT / "tools/release"
sys.path.insert(0, str(TOOLS))

from validate_app_store_submission import pending_release_gates  # noqa: E402


@dataclass(frozen=True)
class CheckSpec:
    name: str
    command: tuple[str, ...]


def load_manifest(path: Path = MANIFEST) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("submission manifest root must be an object")
    return payload


def grouped_pending_gates(pending: list[str]) -> dict[str, list[str]]:
    groups: dict[str, list[str]] = {}
    for gate in pending:
        group = gate.split(".", 1)[0]
        groups.setdefault(group, []).append(gate)
    return groups


def expected_archive_identity(manifest: dict, launch: dict) -> tuple[str, str]:
    candidate = manifest.get("candidate", {})
    candidate_id = f"{candidate.get('marketing_version', '')}-{candidate.get('build_number', '')}"
    launch_candidate = launch.get("candidate", {})
    if launch.get("schema_version") != 1:
        raise ValueError("product launch manifest schema is invalid")
    if launch_candidate.get("candidate_id") != candidate_id:
        raise ValueError("product launch candidate does not match submission version/build")
    release_commit = launch_candidate.get("release_commit")
    if not isinstance(release_commit, str) or re.fullmatch(r"[0-9a-f]{40}", release_commit) is None:
        raise ValueError("product launch release_commit must be a clean full Git SHA")
    exists = subprocess.run(
        ["git", "cat-file", "-e", f"{release_commit}^{{commit}}"],
        cwd=ROOT,
        check=False,
        capture_output=True,
    )
    if exists.returncode != 0:
        raise ValueError("product launch release_commit does not identify a repository commit")
    return release_commit, candidate_id


def resolve_archive(manifest: dict) -> tuple[Path, Path]:
    relative = manifest["distribution"]["signed_archive"]
    if not isinstance(relative, str) or not relative:
        raise ValueError("distribution.signed_archive is empty")
    archive = (ROOT / relative).resolve()
    if ROOT not in archive.parents or archive.suffix != ".xcarchive" or not archive.is_dir():
        raise ValueError("signed archive must be an existing xcarchive inside the repository")
    info_path = archive / "Info.plist"
    if not info_path.is_file():
        raise ValueError("signed archive Info.plist is missing")
    with info_path.open("rb") as handle:
        info = plistlib.load(handle)
    app_relative = info.get("ApplicationProperties", {}).get("ApplicationPath")
    if not isinstance(app_relative, str) or not app_relative:
        raise ValueError("signed archive has no ApplicationPath")
    app = (archive / app_relative).resolve()
    if archive not in app.parents or not app.is_dir() or app.suffix != ".app":
        raise ValueError("signed archive application bundle is invalid")
    product_apps = [path.resolve() for path in (archive / "Products/Applications").glob("*.app")]
    if product_apps != [app]:
        raise ValueError("signed archive ApplicationPath must identify its only product app")
    return archive, app


def build_check_specs(manifest: dict, launch: dict) -> list[CheckSpec]:
    team_id = manifest["distribution"]["developer_team_id"]
    if not isinstance(team_id, str) or not team_id:
        raise ValueError("distribution.developer_team_id is empty")
    archive, app = resolve_archive(manifest)
    source_commit, candidate_id = expected_archive_identity(manifest, launch)
    python = sys.executable
    return [
        CheckSpec(
            "submission_manifest_strict",
            (python, str(TOOLS / "validate_app_store_submission.py"), "--strict"),
        ),
        CheckSpec(
            "public_pages_live",
            (
                python,
                str(TOOLS / "validate_public_release_pages.py"),
                "--require-app-links",
                "--check-live-urls",
            ),
        ),
        CheckSpec(
            "archive_content",
            (
                python,
                str(TOOLS / "validate_ios_archive.py"),
                str(archive),
                "--expected-source-commit",
                source_commit,
                "--expected-candidate-id",
                candidate_id,
                "--require-clean-provenance",
            ),
        ),
        CheckSpec(
            "signed_app_distribution",
            (
                python,
                str(TOOLS / "validate_ios_signed_app.py"),
                str(app),
                "--team-id",
                team_id,
                "--mode",
                "distribution",
                "--expected-source-commit",
                source_commit,
                "--expected-candidate-id",
                candidate_id,
                "--require-clean-provenance",
                "--json",
            ),
        ),
    ]


def condensed_output(result: subprocess.CompletedProcess[str], limit: int = 4000) -> str:
    combined = "\n".join(value.strip() for value in (result.stdout, result.stderr) if value.strip())
    if len(combined) <= limit:
        return combined
    return "…" + combined[-limit:]


def run_check(spec: CheckSpec) -> dict:
    result = subprocess.run(spec.command, cwd=ROOT, check=False, text=True, capture_output=True)
    return {
        "name": spec.name,
        "status": "passed" if result.returncode == 0 else "failed",
        "exit_code": result.returncode,
        "output": condensed_output(result),
    }


def checks_passed(checks: list[dict]) -> bool:
    return bool(checks) and all(check.get("status") == "passed" for check in checks)


def evaluate_current_state(manifest: dict, launch: dict | None = None) -> tuple[dict, int]:
    pending = pending_release_gates(manifest)
    if pending:
        report = {
            "ready_for_submission": False,
            "pending_gate_count": len(pending),
            "pending_gates": pending,
            "pending_groups": grouped_pending_gates(pending),
            "checks": [
                {
                    "name": name,
                    "status": "skipped",
                    "reason": "external manifest gates must be complete before final checks run",
                }
                for name in (
                    "submission_manifest_strict",
                    "public_pages_live",
                    "archive_content",
                    "signed_app_distribution",
                )
            ],
            "audit_errors": [],
        }
        return report, 2

    try:
        if launch is None:
            launch = load_manifest(PRODUCT_LAUNCH_MANIFEST)
        specs = build_check_specs(manifest, launch)
        checks = [run_check(spec) for spec in specs]
    except (OSError, ValueError, KeyError, plistlib.InvalidFileException) as error:
        return {
            "ready_for_submission": False,
            "pending_gate_count": 0,
            "pending_gates": [],
            "pending_groups": {},
            "checks": [],
            "audit_errors": [str(error)],
        }, 1

    ready = checks_passed(checks)
    return {
        "ready_for_submission": ready,
        "pending_gate_count": 0,
        "pending_gates": [],
        "pending_groups": {},
        "checks": checks,
        "audit_errors": [],
    }, (0 if ready else 2)


def print_human(report: dict) -> None:
    print("Final App Store gate: " + ("GO" if report["ready_for_submission"] else "HOLD"))
    if report["pending_gate_count"]:
        print(f"pending external gates: {report['pending_gate_count']}")
        for group, gates in report["pending_groups"].items():
            print(f"  {group}: {len(gates)}")
            for gate in gates:
                print(f"    - {gate}")
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
        manifest = load_manifest()
        report, exit_code = evaluate_current_state(manifest)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError, KeyError, TypeError) as error:
        report = {
            "ready_for_submission": False,
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
