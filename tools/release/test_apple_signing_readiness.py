#!/usr/bin/env python3
"""Regression tests for the Apple signing readiness preflight."""

from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/release"))

from apple_signing_readiness import (  # noqa: E402
    Device,
    Identity,
    Profile,
    devices_from_payload,
    evaluate,
    parse_identities,
    profile_matches_bundle,
    summarize_device_samples,
)


NOW = datetime.now(timezone.utc)
FUTURE = NOW + timedelta(days=30)
PAST = NOW - timedelta(days=30)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def profile(kind: str, app_identifier: str, fingerprint: str, expires_at: datetime = FUTURE) -> Profile:
    return Profile(
        path="fixture.mobileprovision",
        name="Fixture",
        uuid="fixture-uuid",
        kind=kind,
        team_ids=("TEAM123",),
        application_identifier=app_identifier,
        expires_at=expires_at,
        certificate_fingerprints=(fingerprint,),
    )


def device(identifier: str, *, state: str = "connected", developer_mode: str = "enabled", ddi: bool = True) -> Device:
    return Device(
        identifier=identifier,
        marketing_name="iPhone Fixture",
        product_type="iPhone99,1",
        platform="iOS",
        reality="physical",
        pairing_state="paired",
        tunnel_state=state,
        developer_mode=developer_mode,
        ddi_services_available=ddi,
    )


def main() -> None:
    parsed = parse_identities('  1) AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA "Apple Development: QA"\n')
    require(parsed == [("A" * 40, "Apple Development: QA")], "identity parser drifted")

    wildcard = profile("development", "TEAM123.*", "A" * 40)
    exact = profile("distribution", "TEAM123.com.fancyGame.NewPirate", "B" * 40)
    wrong = profile("distribution", "TEAM123.com.example.Other", "B" * 40)
    require(profile_matches_bundle(wildcard, "com.fancyGame.NewPirate"), "wildcard profile must match")
    require(profile_matches_bundle(exact, "com.fancyGame.NewPirate"), "exact profile must match")
    require(not profile_matches_bundle(wrong, "com.fancyGame.NewPirate"), "wrong Bundle ID matched")

    payload = {
        "result": {
            "devices": [
                {
                    "identifier": "private-coredevice-id",
                    "connectionProperties": {"pairingState": "paired", "tunnelState": "connected"},
                    "deviceProperties": {"developerModeStatus": "enabled", "ddiServicesAvailable": True},
                    "hardwareProperties": {
                        "marketingName": "iPhone Fixture",
                        "productType": "iPhone99,1",
                        "platform": "iOS",
                        "reality": "physical",
                        "serialNumber": "must-not-leak",
                        "udid": "must-not-leak",
                    },
                }
            ]
        }
    }
    parsed_devices = devices_from_payload(payload)
    require(len(parsed_devices) == 1 and parsed_devices[0].development_ready, "CoreDevice JSON parser drifted")
    sanitized_payload = str(summarize_device_samples([parsed_devices, parsed_devices, parsed_devices]))
    require("private-coredevice-id" not in sanitized_payload, "CoreDevice identifier was not hashed")
    require("must-not-leak" not in sanitized_payload, "serial number or UDID leaked into report")

    stable = summarize_device_samples([[device("same")], [device("same")], [device("same")]])
    require(stable["consecutive_ready_device_count"] == 1, "same ready device must pass stability")
    require(stable["device_observations"][0]["ready_samples"] == 3, "ready sample count drifted")
    require("same" not in str(stable), "raw CoreDevice identifier leaked into report")

    flapping = summarize_device_samples(
        [[device("same")], [device("same", state="unavailable", ddi=False)], [device("same")]]
    )
    require(flapping["consecutive_ready_device_count"] == 0, "flapping device passed stability")

    swapped = summarize_device_samples([[device("first")], [device("second")], [device("first")]])
    require(swapped["consecutive_ready_device_count"] == 0, "different transient devices passed stability")

    duplicated = summarize_device_samples([[device("same"), device("same"), device("same")], [], []])
    require(duplicated["consecutive_ready_device_count"] == 0, "duplicate rows passed consecutive samples")

    disabled = summarize_device_samples(
        [[device("same", developer_mode="disabled")], [device("same")], [device("same")]]
    )
    require(disabled["consecutive_ready_device_count"] == 0, "disabled developer mode passed stability")

    identities = [
        Identity("A" * 40, "Apple Development: QA", "development", "TEAM123", FUTURE),
        Identity("B" * 40, "Apple Distribution: QA", "distribution", "TEAM123", FUTURE),
    ]
    ready = evaluate(
        identities,
        [wildcard, exact],
        "com.fancyGame.NewPirate",
        "TEAM123",
        ("TEAM123",),
        1,
    )
    require(ready["development_ready"], "complete development chain must be ready")
    require(ready["distribution_ready"], "complete distribution chain must be ready")

    expired_identities = [
        Identity("A" * 40, "Apple Development: QA", "development", "TEAM123", PAST),
        Identity("B" * 40, "Apple Distribution: QA", "distribution", "TEAM123", PAST),
    ]
    blocked = evaluate(
        expired_identities,
        [wildcard, exact],
        "com.fancyGame.NewPirate",
        "TEAM123",
        (),
        0,
    )
    require(not blocked["development_ready"], "expired identity must not pass development")
    require(not blocked["distribution_ready"], "expired identity must not pass distribution")
    require(len(blocked["blockers"]) == 4, "blocked chain must explain all four gaps")

    mismatched_profile = profile("distribution", "TEAM123.com.fancyGame.NewPirate", "C" * 40)
    mismatch = evaluate(
        identities,
        [wildcard, mismatched_profile],
        "com.fancyGame.NewPirate",
        "TEAM123",
        ("TEAM123",),
        1,
    )
    require(not mismatch["distribution_ready"], "profile certificate without private key matched")

    print("Apple signing readiness OK: identity chain, official device JSON and stability gates")


if __name__ == "__main__":
    main()
