#!/usr/bin/env python3
"""Validate the actual signature, entitlements and embedded profile of an iOS app."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import plistlib
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_BUNDLE_ID = "com.fancyGame.NewPirate"


def run(command: list[str], *, input_bytes: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(command, input=input_bytes, check=False, capture_output=True)


def parse_codesign_details(output: str) -> dict:
    values: dict[str, str] = {}
    authorities: list[str] = []
    for line in output.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key == "Authority":
            authorities.append(value)
        else:
            values[key] = value
    values["authorities"] = authorities
    return values


def normalized_datetime(value: object) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def certificate_expiration(certificate: bytes) -> datetime | None:
    result = run(["openssl", "x509", "-inform", "DER", "-noout", "-enddate"], input_bytes=certificate)
    if result.returncode != 0:
        return None
    output = result.stdout.decode("utf-8", errors="replace").strip()
    if not output.startswith("notAfter="):
        return None
    try:
        return datetime.strptime(output.split("=", 1)[1], "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def profile_allows_bundle(application_identifier: str, team_id: str, bundle_id: str) -> bool:
    prefix = f"{team_id}."
    if not application_identifier.startswith(prefix):
        return False
    return fnmatch.fnmatchcase(bundle_id, application_identifier[len(prefix):])


def profile_certificate_fingerprints(profile: dict) -> set[str]:
    return {
        hashlib.sha1(certificate).hexdigest().upper()
        for certificate in profile.get("DeveloperCertificates", [])
        if isinstance(certificate, bytes)
    }


def evaluate_payload(
    *,
    info: dict,
    codesign: dict,
    entitlements: dict,
    profile: dict,
    leaf_fingerprint: str,
    leaf_expiration: datetime | None,
    architecture_output: str,
    expected_bundle_id: str,
    expected_team_id: str,
    mode: str,
    signature_verified: bool,
) -> dict:
    failures: list[str] = []

    def check(condition: bool, message: str) -> None:
        if not condition:
            failures.append(message)

    authorities = codesign.get("authorities", [])
    leaf_authority = authorities[0] if authorities else ""
    signed_application_identifier = str(entitlements.get("application-identifier", ""))
    signed_team_id = str(entitlements.get("com.apple.developer.team-identifier", ""))
    profile_entitlements = profile.get("Entitlements", {})
    profile_application_identifier = str(profile_entitlements.get("application-identifier", ""))
    profile_team_ids = [str(value) for value in profile.get("TeamIdentifier", [])]
    profile_expiration = normalized_datetime(profile.get("ExpirationDate"))
    profile_fingerprints = profile_certificate_fingerprints(profile)

    check(signature_verified, "codesign strict verification failed")
    check(info.get("CFBundleIdentifier") == expected_bundle_id, "Info.plist Bundle ID does not match")
    check(codesign.get("Identifier") == expected_bundle_id, "code signature identifier does not match")
    check(codesign.get("TeamIdentifier") == expected_team_id, "code signature TeamIdentifier does not match")
    check(signed_team_id == expected_team_id, "signed team entitlement does not match")
    check(
        signed_application_identifier == f"{expected_team_id}.{expected_bundle_id}",
        "signed application-identifier does not match",
    )
    check(expected_team_id in profile_team_ids, "embedded profile team does not match")
    check(
        profile_allows_bundle(profile_application_identifier, expected_team_id, expected_bundle_id),
        "embedded profile does not allow the Bundle ID",
    )
    check(leaf_fingerprint in profile_fingerprints, "signing leaf certificate is not embedded in the profile")
    check(leaf_expiration is not None and leaf_expiration > datetime.now(timezone.utc), "signing leaf certificate is expired")
    check(profile_expiration is not None and profile_expiration > datetime.now(timezone.utc), "embedded profile is expired")
    check("arm64" in architecture_output.split(), "signed app executable is not arm64")

    signed_debuggable = entitlements.get("get-task-allow") is True
    profile_debuggable = profile_entitlements.get("get-task-allow") is True
    provisioned_devices = profile.get("ProvisionedDevices", [])
    provisions_all_devices = profile.get("ProvisionsAllDevices") is True

    if mode == "development":
        check(leaf_authority.startswith(("Apple Development:", "iPhone Developer:")), "not signed by a development identity")
        check(signed_debuggable, "development app must have get-task-allow=true")
        check(profile_debuggable, "development profile must have get-task-allow=true")
        check(isinstance(provisioned_devices, list) and bool(provisioned_devices), "development profile has no devices")
    else:
        check(leaf_authority.startswith(("Apple Distribution:", "iPhone Distribution:")), "not signed by a distribution identity")
        check(not signed_debuggable, "distribution app must not have get-task-allow=true")
        check(not profile_debuggable, "distribution profile must not have get-task-allow=true")
        check(not provisioned_devices, "App Store profile must not contain provisioned devices")
        check(not provisions_all_devices, "enterprise profile is not an App Store profile")

    return {
        "passed": not failures,
        "mode": mode,
        "bundle_id": info.get("CFBundleIdentifier"),
        "expected_bundle_id": expected_bundle_id,
        "team_id": codesign.get("TeamIdentifier"),
        "expected_team_id": expected_team_id,
        "authority": leaf_authority,
        "leaf_certificate_fingerprint": leaf_fingerprint,
        "leaf_certificate_expiration": leaf_expiration.isoformat() if leaf_expiration else None,
        "profile_name": profile.get("Name"),
        "profile_uuid": profile.get("UUID"),
        "profile_expiration": profile_expiration.isoformat() if profile_expiration else None,
        "profile_application_identifier": profile_application_identifier,
        "signed_application_identifier": signed_application_identifier,
        "get_task_allow": signed_debuggable,
        "signature_verified": signature_verified,
        "architecture": architecture_output.strip(),
        "failures": failures,
    }


def load_plist_result(result: subprocess.CompletedProcess[bytes], label: str, errors: list[str]) -> dict:
    if result.returncode != 0:
        errors.append(f"{label} command failed")
        return {}
    try:
        return plistlib.loads(result.stdout)
    except plistlib.InvalidFileException:
        errors.append(f"{label} returned an invalid plist")
        return {}


def inspect_app(app: Path, bundle_id: str, team_id: str, mode: str) -> tuple[dict, list[str]]:
    errors: list[str] = []
    info_path = app / "Info.plist"
    profile_path = app / "embedded.mobileprovision"
    if not app.is_dir():
        return {}, ["signed app directory does not exist"]
    if not info_path.is_file():
        return {}, ["signed app Info.plist is missing"]
    if not profile_path.is_file():
        return {}, ["signed app embedded.mobileprovision is missing"]

    try:
        with info_path.open("rb") as handle:
            info = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException):
        return {}, ["signed app Info.plist is invalid"]

    executable_name = info.get("CFBundleExecutable")
    executable = app / str(executable_name or "")
    if not executable.is_file():
        return {}, ["signed app executable is missing"]

    verify = run(["codesign", "--verify", "--deep", "--strict", str(app)])
    detail = run(["codesign", "-dvvv", str(app)])
    if detail.returncode != 0:
        errors.append("codesign detail command failed")
    codesign = parse_codesign_details((detail.stdout + detail.stderr).decode("utf-8", errors="replace"))

    entitlement_result = run(["codesign", "-d", "--entitlements", "-", "--xml", str(app)])
    entitlements = load_plist_result(entitlement_result, "codesign entitlements", errors)
    profile_result = run(["security", "cms", "-D", "-i", str(profile_path)])
    profile = load_plist_result(profile_result, "embedded profile decode", errors)
    architecture_result = run(["xcrun", "lipo", "-archs", str(executable)])
    if architecture_result.returncode != 0:
        errors.append("lipo architecture command failed")
    architecture = architecture_result.stdout.decode("utf-8", errors="replace")

    leaf_fingerprint = ""
    leaf_expiration: datetime | None = None
    with tempfile.TemporaryDirectory(prefix="newpirate-signed-app-") as directory:
        prefix = Path(directory) / "certificate"
        extract = run(["codesign", "-d", f"--extract-certificates={prefix}", str(app)])
        leaf_path = Path(f"{prefix}0")
        if extract.returncode != 0 or not leaf_path.is_file():
            errors.append("codesign certificate extraction failed")
        else:
            leaf_certificate = leaf_path.read_bytes()
            leaf_fingerprint = hashlib.sha1(leaf_certificate).hexdigest().upper()
            leaf_expiration = certificate_expiration(leaf_certificate)
            if leaf_expiration is None:
                errors.append("signing leaf certificate expiration could not be read")

    if errors:
        return {}, errors
    return (
        evaluate_payload(
            info=info,
            codesign=codesign,
            entitlements=entitlements,
            profile=profile,
            leaf_fingerprint=leaf_fingerprint,
            leaf_expiration=leaf_expiration,
            architecture_output=architecture,
            expected_bundle_id=bundle_id,
            expected_team_id=team_id,
            mode=mode,
            signature_verified=verify.returncode == 0,
        ),
        errors,
    )


def print_human(report: dict, errors: list[str]) -> None:
    if errors:
        for error in errors:
            print(f"AUDIT_ERROR: {error}")
        return
    print(f"iOS signed app: {report['bundle_id']} ({report['mode']})")
    print(f"authority: {report['authority']}")
    print(f"team: {report['team_id']}")
    print(f"profile: {report['profile_name']} ({report['profile_uuid']})")
    print(f"application-identifier: {report['signed_application_identifier']}")
    print(f"get-task-allow: {str(report['get_task_allow']).lower()}")
    print(f"passed: {str(report['passed']).lower()}")
    for failure in report["failures"]:
        print(f"FAILURE: {failure}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--team-id", required=True)
    parser.add_argument("--mode", choices=("development", "distribution"), required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report, errors = inspect_app(args.app.resolve(), args.bundle_id, args.team_id, args.mode)
    if args.json:
        print(json.dumps({"audit_errors": errors, **report}, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_human(report, errors)
    if errors:
        return 1
    return 0 if report["passed"] else 2


if __name__ == "__main__":
    sys.exit(main())
