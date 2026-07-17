#!/usr/bin/env python3
"""Pure regression tests for signed iOS app payload validation."""

from __future__ import annotations

import hashlib
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/release"))

from validate_ios_signed_app import evaluate_payload, parse_codesign_details  # noqa: E402


BUNDLE_ID = "com.fancyGame.NewPirate"
TEAM_ID = "TEAM123456"
LEAF_CERTIFICATE = b"fixture signing certificate"
LEAF_FINGERPRINT = hashlib.sha1(LEAF_CERTIFICATE).hexdigest().upper()
FUTURE = datetime.now(timezone.utc) + timedelta(days=30)
PAST = datetime.now(timezone.utc) - timedelta(days=30)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def codesign(authority: str, *, team_id: str = TEAM_ID, identifier: str = BUNDLE_ID) -> dict:
    return {
        "Identifier": identifier,
        "TeamIdentifier": team_id,
        "authorities": [authority, "Apple Worldwide Developer Relations Certification Authority", "Apple Root CA"],
    }


def entitlements(*, team_id: str = TEAM_ID, debuggable: bool) -> dict:
    return {
        "application-identifier": f"{team_id}.{BUNDLE_ID}",
        "com.apple.developer.team-identifier": team_id,
        "get-task-allow": debuggable,
    }


def profile(*, debuggable: bool, expires_at: datetime = FUTURE, devices: bool = True, certificate: bytes = LEAF_CERTIFICATE) -> dict:
    payload = {
        "Name": "Fixture Profile",
        "UUID": "fixture-profile-uuid",
        "TeamIdentifier": [TEAM_ID],
        "ExpirationDate": expires_at,
        "DeveloperCertificates": [certificate],
        "Entitlements": {
            "application-identifier": f"{TEAM_ID}.*",
            "get-task-allow": debuggable,
        },
    }
    if devices:
        payload["ProvisionedDevices"] = ["fixture-device"]
    return payload


def evaluate(
    mode: str,
    *,
    codesign_payload: dict,
    entitlement_payload: dict,
    profile_payload: dict,
    fingerprint: str = LEAF_FINGERPRINT,
    leaf_expires_at: datetime = FUTURE,
) -> dict:
    return evaluate_payload(
        info={"CFBundleIdentifier": BUNDLE_ID},
        codesign=codesign_payload,
        entitlements=entitlement_payload,
        profile=profile_payload,
        leaf_fingerprint=fingerprint,
        leaf_expiration=leaf_expires_at,
        architecture_output="arm64\n",
        expected_bundle_id=BUNDLE_ID,
        expected_team_id=TEAM_ID,
        mode=mode,
        signature_verified=True,
    )


def main() -> None:
    parsed = parse_codesign_details(
        "Identifier=com.fancyGame.NewPirate\n"
        "Authority=Apple Development: QA\n"
        "Authority=Apple Root CA\n"
        "TeamIdentifier=TEAM123456\n"
    )
    require(parsed["Identifier"] == BUNDLE_ID, "codesign identifier parser drifted")
    require(parsed["authorities"] == ["Apple Development: QA", "Apple Root CA"], "authority chain parser drifted")

    development = evaluate(
        "development",
        codesign_payload=codesign("Apple Development: QA"),
        entitlement_payload=entitlements(debuggable=True),
        profile_payload=profile(debuggable=True),
    )
    require(development["passed"], f"valid development app failed: {development['failures']}")

    distribution_profile = profile(debuggable=False, devices=False)
    distribution_profile["Entitlements"]["application-identifier"] = f"{TEAM_ID}.{BUNDLE_ID}"
    distribution = evaluate(
        "distribution",
        codesign_payload=codesign("Apple Distribution: QA"),
        entitlement_payload=entitlements(debuggable=False),
        profile_payload=distribution_profile,
    )
    require(distribution["passed"], f"valid App Store app failed: {distribution['failures']}")

    wrong_team = evaluate(
        "development",
        codesign_payload=codesign("Apple Development: QA", team_id="WRONGTEAM1"),
        entitlement_payload=entitlements(team_id="WRONGTEAM1", debuggable=True),
        profile_payload=profile(debuggable=True),
    )
    require(not wrong_team["passed"], "wrong signing team passed")

    wrong_certificate = evaluate(
        "development",
        codesign_payload=codesign("Apple Development: QA"),
        entitlement_payload=entitlements(debuggable=True),
        profile_payload=profile(debuggable=True),
        fingerprint="0" * 40,
    )
    require(not wrong_certificate["passed"], "leaf certificate outside profile passed")

    expired = evaluate(
        "development",
        codesign_payload=codesign("Apple Development: QA"),
        entitlement_payload=entitlements(debuggable=True),
        profile_payload=profile(debuggable=True, expires_at=PAST),
    )
    require(not expired["passed"], "expired embedded profile passed")

    expired_leaf = evaluate(
        "development",
        codesign_payload=codesign("Apple Development: QA"),
        entitlement_payload=entitlements(debuggable=True),
        profile_payload=profile(debuggable=True),
        leaf_expires_at=PAST,
    )
    require(not expired_leaf["passed"], "expired signing leaf certificate passed")

    development_as_distribution = evaluate(
        "distribution",
        codesign_payload=codesign("Apple Development: QA"),
        entitlement_payload=entitlements(debuggable=True),
        profile_payload=profile(debuggable=True),
    )
    require(not development_as_distribution["passed"], "development payload passed App Store mode")
    require(any("get-task-allow" in value for value in development_as_distribution["failures"]), "debug entitlement failure missing")
    require(any("provisioned devices" in value for value in development_as_distribution["failures"]), "device profile failure missing")

    print("iOS signed app validator OK: identity, profile, entitlement, mode and expiry contracts")


if __name__ == "__main__":
    main()
