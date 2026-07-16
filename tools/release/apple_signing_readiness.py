#!/usr/bin/env python3
"""Read-only Apple signing readiness audit for the NewPirate iOS release."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import plistlib
import re
import ssl
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PROJECT = ROOT / "projects/ios_mac/NewPirate.xcodeproj/project.pbxproj"
DEFAULT_BUNDLE_ID = "com.fancyGame.NewPirate"
PROFILE_DIRECTORIES = (
    Path.home() / "Library/MobileDevice/Provisioning Profiles",
    Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
)


@dataclass(frozen=True)
class Identity:
    fingerprint: str
    label: str
    kind: str
    team_id: str | None
    expires_at: datetime | None

    @property
    def unexpired(self) -> bool:
        return self.expires_at is not None and self.expires_at > datetime.now(timezone.utc)


@dataclass(frozen=True)
class Profile:
    path: str
    name: str
    uuid: str
    kind: str
    team_ids: tuple[str, ...]
    application_identifier: str
    expires_at: datetime | None
    certificate_fingerprints: tuple[str, ...]

    @property
    def unexpired(self) -> bool:
        return self.expires_at is not None and self.expires_at > datetime.now(timezone.utc)


@dataclass(frozen=True)
class Device:
    identifier: str
    marketing_name: str
    product_type: str
    platform: str
    reality: str
    pairing_state: str
    tunnel_state: str
    developer_mode: str
    ddi_services_available: bool

    @property
    def development_ready(self) -> bool:
        return (
            self.platform == "iOS"
            and self.reality == "physical"
            and self.pairing_state == "paired"
            and self.tunnel_state in {"available", "connected"}
            and self.developer_mode == "enabled"
            and self.ddi_services_available
        )

    @property
    def audit_key(self) -> str:
        return hashlib.sha256(self.identifier.encode("utf-8")).hexdigest()[:12]


def run(command: list[str], *, input_bytes: bytes | None = None) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(command, input=input_bytes, check=False, capture_output=True)


def parse_identities(output: str) -> list[tuple[str, str]]:
    identities: list[tuple[str, str]] = []
    pattern = re.compile(r'^\s*\d+\)\s+([0-9A-Fa-f]{40})\s+"([^"]+)"\s*$')
    for line in output.splitlines():
        match = pattern.match(line)
        if match:
            identities.append((match.group(1).upper(), match.group(2)))
    return identities


def split_pem_certificates(output: bytes) -> list[bytes]:
    return re.findall(
        br"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----\s*",
        output,
        flags=re.DOTALL,
    )


def certificate_fingerprint(pem: bytes) -> str:
    der = ssl.PEM_cert_to_DER_cert(pem.decode("ascii"))
    return hashlib.sha1(der).hexdigest().upper()


def parse_openssl_datetime(value: str) -> datetime | None:
    normalized = " ".join(value.strip().split())
    try:
        return datetime.strptime(normalized, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
    except ValueError:
        return None


def parse_certificate_metadata(pem: bytes) -> tuple[str | None, datetime | None]:
    result = run(["openssl", "x509", "-noout", "-subject", "-enddate"], input_bytes=pem)
    if result.returncode != 0:
        return None, None
    text = result.stdout.decode("utf-8", errors="replace")
    subject = next((line for line in text.splitlines() if line.startswith("subject=")), "")
    expiry = next((line.split("=", 1)[1] for line in text.splitlines() if line.startswith("notAfter=")), "")
    team_match = re.search(r"(?:^|,\s*)OU\s*=\s*([^,]+)", subject)
    return (team_match.group(1).strip() if team_match else None, parse_openssl_datetime(expiry))


def identity_kind(label: str) -> str:
    if label.startswith("Apple Distribution:") or label.startswith("iPhone Distribution:"):
        return "distribution"
    if label.startswith("Apple Development:") or label.startswith("iPhone Developer:"):
        return "development"
    return "other"


def collect_identities(errors: list[str]) -> list[Identity]:
    identity_result = run(["security", "find-identity", "-v", "-p", "codesigning"])
    if identity_result.returncode != 0:
        errors.append("security find-identity failed")
        return []

    certificate_result = run(["security", "find-certificate", "-a", "-p"])
    if certificate_result.returncode != 0:
        errors.append("security find-certificate failed")
        return []

    certificate_metadata: dict[str, tuple[str | None, datetime | None]] = {}
    for pem in split_pem_certificates(certificate_result.stdout):
        fingerprint = certificate_fingerprint(pem)
        certificate_metadata[fingerprint] = parse_certificate_metadata(pem)

    identities: list[Identity] = []
    output = identity_result.stdout.decode("utf-8", errors="replace")
    for fingerprint, label in parse_identities(output):
        team_id, expires_at = certificate_metadata.get(fingerprint, (None, None))
        identities.append(Identity(fingerprint, label, identity_kind(label), team_id, expires_at))
    return identities


def classify_profile(payload: dict) -> str:
    entitlements = payload.get("Entitlements", {})
    if entitlements.get("get-task-allow") is True:
        return "development"
    if payload.get("ProvisionedDevices"):
        return "ad_hoc"
    return "distribution"


def normalized_datetime(value: object) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def profile_from_payload(path: Path, payload: dict) -> Profile:
    certificates = payload.get("DeveloperCertificates", [])
    fingerprints = tuple(hashlib.sha1(cert).hexdigest().upper() for cert in certificates if isinstance(cert, bytes))
    team_ids = tuple(str(value) for value in payload.get("TeamIdentifier", []) if value)
    entitlements = payload.get("Entitlements", {})
    return Profile(
        path=str(path),
        name=str(payload.get("Name", "")),
        uuid=str(payload.get("UUID", "")),
        kind=classify_profile(payload),
        team_ids=team_ids,
        application_identifier=str(entitlements.get("application-identifier", "")),
        expires_at=normalized_datetime(payload.get("ExpirationDate")),
        certificate_fingerprints=fingerprints,
    )


def collect_profiles(errors: list[str]) -> list[Profile]:
    profiles: list[Profile] = []
    seen: set[Path] = set()
    for directory in PROFILE_DIRECTORIES:
        if not directory.is_dir():
            continue
        for path in sorted(directory.glob("*.mobileprovision")):
            resolved = path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            result = run(["security", "cms", "-D", "-i", str(path)])
            if result.returncode != 0:
                errors.append(f"unable to decode profile: {path.name}")
                continue
            try:
                payload = plistlib.loads(result.stdout)
            except plistlib.InvalidFileException:
                errors.append(f"invalid profile plist: {path.name}")
                continue
            profiles.append(profile_from_payload(path, payload))
    return profiles


def profile_matches_bundle(profile: Profile, bundle_id: str) -> bool:
    identifier = profile.application_identifier
    if "." not in identifier:
        return False
    pattern = identifier.split(".", 1)[1]
    return fnmatch.fnmatchcase(bundle_id, pattern)


def profile_matches_team(profile: Profile, team_id: str | None) -> bool:
    return team_id is None or team_id in profile.team_ids


def project_team_ids(project: Path) -> tuple[str, ...]:
    if not project.is_file():
        return ()
    source = project.read_text(encoding="utf-8")
    return tuple(sorted(set(re.findall(r"DEVELOPMENT_TEAM\s*=\s*([A-Z0-9]+)\s*;", source))))


def devices_from_payload(payload: dict) -> list[Device]:
    raw_devices = payload.get("result", {}).get("devices", [])
    if not isinstance(raw_devices, list):
        return []

    devices: list[Device] = []
    for item in raw_devices:
        if not isinstance(item, dict):
            continue
        connection = item.get("connectionProperties", {})
        properties = item.get("deviceProperties", {})
        hardware = item.get("hardwareProperties", {})
        identifier = item.get("identifier")
        if not isinstance(identifier, str) or not identifier:
            continue
        devices.append(
            Device(
                identifier=identifier,
                marketing_name=str(hardware.get("marketingName", "Unknown Apple device")),
                product_type=str(hardware.get("productType", "")),
                platform=str(hardware.get("platform", "")),
                reality=str(hardware.get("reality", "")),
                pairing_state=str(connection.get("pairingState", "")),
                tunnel_state=str(connection.get("tunnelState", "")),
                developer_mode=str(properties.get("developerModeStatus", "")),
                ddi_services_available=properties.get("ddiServicesAvailable") is True,
            )
        )
    return devices


def collect_device_sample(errors: list[str]) -> list[Device]:
    with tempfile.TemporaryDirectory(prefix="newpirate-devicectl-") as directory:
        output = Path(directory) / "devices.json"
        result = run(
            [
                "xcrun",
                "devicectl",
                "list",
                "devices",
                "--quiet",
                "--json-output",
                str(output),
            ]
        )
        if result.returncode != 0 or not output.is_file():
            errors.append("xcrun devicectl JSON device audit failed")
            return []
        try:
            payload = json.loads(output.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            errors.append("xcrun devicectl returned invalid JSON")
            return []
        if payload.get("info", {}).get("outcome") != "success":
            errors.append("xcrun devicectl reported an unsuccessful outcome")
            return []
        return devices_from_payload(payload)


def collect_device_samples(errors: list[str], count: int, interval: float) -> list[list[Device]]:
    samples: list[list[Device]] = []
    for index in range(count):
        samples.append(collect_device_sample(errors))
        if index + 1 < count and interval > 0:
            time.sleep(interval)
    return samples


def summarize_device_samples(samples: list[list[Device]]) -> dict:
    observations: dict[str, dict] = {}
    for sample in samples:
        unique_devices = {device.identifier: device for device in sample}
        for device in unique_devices.values():
            entry = observations.setdefault(
                device.identifier,
                {
                    "device": device,
                    "seen_samples": 0,
                    "ready_samples": 0,
                },
            )
            entry["device"] = device
            entry["seen_samples"] += 1
            entry["ready_samples"] += int(device.development_ready)

    sample_count = len(samples)
    serialized: list[dict] = []
    for entry in observations.values():
        device = entry["device"]
        ready_samples = entry["ready_samples"]
        serialized.append(
            {
                "device_key": device.audit_key,
                "marketing_name": device.marketing_name,
                "product_type": device.product_type,
                "pairing_state": device.pairing_state,
                "last_tunnel_state": device.tunnel_state,
                "developer_mode": device.developer_mode,
                "last_ddi_services_available": device.ddi_services_available,
                "seen_samples": entry["seen_samples"],
                "ready_samples": ready_samples,
                "stable_ready": sample_count > 0 and ready_samples == sample_count,
            }
        )
    serialized.sort(key=lambda item: (item["marketing_name"], item["device_key"]))
    return {
        "device_sample_count": sample_count,
        "consecutive_ready_device_count": sum(item["stable_ready"] for item in serialized),
        "device_observations": serialized,
    }


def matching_profiles(profiles: Iterable[Profile], bundle_id: str, team_id: str | None, kind: str) -> list[Profile]:
    return [
        profile
        for profile in profiles
        if profile.kind == kind
        and profile.unexpired
        and profile_matches_bundle(profile, bundle_id)
        and profile_matches_team(profile, team_id)
    ]


def matching_identity(profile: Profile, identities: Iterable[Identity], kind: str) -> Identity | None:
    fingerprints = set(profile.certificate_fingerprints)
    return next(
        (
            identity
            for identity in identities
            if identity.kind == kind and identity.unexpired and identity.fingerprint in fingerprints
        ),
        None,
    )


def evaluate(
    identities: list[Identity],
    profiles: list[Profile],
    bundle_id: str,
    team_id: str | None,
    configured_team_ids: tuple[str, ...],
    devices_available: int,
) -> dict:
    development_profiles = matching_profiles(profiles, bundle_id, team_id, "development")
    distribution_profiles = matching_profiles(profiles, bundle_id, team_id, "distribution")
    usable_development = [p for p in development_profiles if matching_identity(p, identities, "development")]
    usable_distribution = [p for p in distribution_profiles if matching_identity(p, identities, "distribution")]
    project_team_matches = bool(team_id and team_id in configured_team_ids)

    development_ready = bool(usable_development and devices_available > 0 and project_team_matches)
    distribution_ready = bool(usable_distribution and project_team_matches)
    blockers: list[str] = []
    if not project_team_matches:
        blockers.append("project has no confirmed matching DEVELOPMENT_TEAM")
    if not usable_development:
        blockers.append("no unexpired development identity/profile chain matches the Bundle ID")
    if devices_available == 0:
        blockers.append("no physical Apple device remained development-ready across all samples")
    if not usable_distribution:
        blockers.append("no unexpired App Store distribution identity/profile chain matches the Bundle ID")

    return {
        "bundle_id": bundle_id,
        "expected_team_id": team_id,
        "project_team_ids": list(configured_team_ids),
        "identity_count": len(identities),
        "unexpired_identity_count": sum(identity.unexpired for identity in identities),
        "profile_count": len(profiles),
        "unexpired_profile_count": sum(profile.unexpired for profile in profiles),
        "matching_development_profile_count": len(development_profiles),
        "usable_development_profile_count": len(usable_development),
        "matching_distribution_profile_count": len(distribution_profiles),
        "usable_distribution_profile_count": len(usable_distribution),
        "available_device_count": devices_available,
        "consecutive_ready_device_count": devices_available,
        "development_ready": development_ready,
        "distribution_ready": distribution_ready,
        "blockers": blockers,
    }


def serializable_identity(identity: Identity) -> dict:
    payload = asdict(identity)
    payload["expires_at"] = identity.expires_at.isoformat() if identity.expires_at else None
    payload["unexpired"] = identity.unexpired
    return payload


def serializable_profile(profile: Profile) -> dict:
    payload = asdict(profile)
    payload["expires_at"] = profile.expires_at.isoformat() if profile.expires_at else None
    payload["unexpired"] = profile.unexpired
    return payload


def print_human(report: dict) -> None:
    print(f"Apple signing readiness: {report['bundle_id']}")
    print(
        "identities: "
        f"{report['identity_count']} installed, {report['unexpired_identity_count']} unexpired"
    )
    print(
        "development: "
        f"{report['matching_development_profile_count']} matching profiles, "
        f"{report['usable_development_profile_count']} usable chains, "
        f"{report['consecutive_ready_device_count']} devices ready across "
        f"{report['device_sample_count']} samples"
    )
    print(
        "distribution: "
        f"{report['matching_distribution_profile_count']} matching profiles, "
        f"{report['usable_distribution_profile_count']} usable chains"
    )
    print(f"development_ready: {str(report['development_ready']).lower()}")
    print(f"distribution_ready: {str(report['distribution_ready']).lower()}")
    for blocker in report["blockers"]:
        print(f"BLOCKER: {blocker}")
    for error in report["audit_errors"]:
        print(f"AUDIT_ERROR: {error}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-id", default=DEFAULT_BUNDLE_ID)
    parser.add_argument("--team-id")
    parser.add_argument("--project", type=Path, default=DEFAULT_PROJECT)
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON")
    parser.add_argument("--require-development", action="store_true")
    parser.add_argument("--require-distribution", action="store_true")
    parser.add_argument(
        "--device-samples",
        type=int,
        help="Consecutive CoreDevice JSON samples (development strict mode enforces at least 3)",
    )
    parser.add_argument("--device-sample-interval", type=float, default=1.0)
    args = parser.parse_args()

    if args.device_samples is not None and args.device_samples < 1:
        parser.error("--device-samples must be at least 1")
    if args.device_sample_interval < 0:
        parser.error("--device-sample-interval must not be negative")
    minimum_samples = 3 if args.require_development else 1
    requested_samples = args.device_samples if args.device_samples is not None else minimum_samples
    device_sample_count = max(requested_samples, minimum_samples)

    errors: list[str] = []
    identities = collect_identities(errors)
    profiles = collect_profiles(errors)
    device_samples = collect_device_samples(errors, device_sample_count, args.device_sample_interval)
    device_report = summarize_device_samples(device_samples)
    devices_available = device_report["consecutive_ready_device_count"]
    configured_team_ids = project_team_ids(args.project)
    report = evaluate(
        identities,
        profiles,
        args.bundle_id,
        args.team_id,
        configured_team_ids,
        devices_available,
    )
    report["audit_errors"] = errors
    report.update(device_report)
    report["identities"] = [serializable_identity(identity) for identity in identities]
    report["matching_profiles"] = [
        serializable_profile(profile)
        for profile in profiles
        if profile.unexpired
        and profile_matches_bundle(profile, args.bundle_id)
        and profile_matches_team(profile, args.team_id)
    ]

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_human(report)

    if errors:
        return 1
    if args.require_development and not report["development_ready"]:
        return 2
    if args.require_distribution and not report["distribution_ready"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
