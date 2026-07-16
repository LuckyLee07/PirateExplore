#!/usr/bin/env python3
"""Regression tests for the Apple signing readiness preflight."""

from __future__ import annotations

import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/release"))

from apple_signing_readiness import (  # noqa: E402
    Identity,
    Profile,
    available_device_count,
    evaluate,
    parse_identities,
    profile_matches_bundle,
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


def main() -> None:
    parsed = parse_identities('  1) AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA "Apple Development: QA"\n')
    require(parsed == [("A" * 40, "Apple Development: QA")], "identity parser drifted")

    wildcard = profile("development", "TEAM123.*", "A" * 40)
    exact = profile("distribution", "TEAM123.com.fancyGame.NewPirate", "B" * 40)
    wrong = profile("distribution", "TEAM123.com.example.Other", "B" * 40)
    require(profile_matches_bundle(wildcard, "com.fancyGame.NewPirate"), "wildcard profile must match")
    require(profile_matches_bundle(exact, "com.fancyGame.NewPirate"), "exact profile must match")
    require(not profile_matches_bundle(wrong, "com.fancyGame.NewPirate"), "wrong Bundle ID matched")

    device_table = "Phone host UUID available iPhone\nTablet host UUID unavailable iPad\n"
    require(available_device_count(device_table) == 1, "available device parser drifted")

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

    print("Apple signing readiness OK: wildcard, expiry, private-key match, team and device gates")


if __name__ == "__main__":
    main()
