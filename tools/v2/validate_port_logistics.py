#!/usr/bin/env python3
"""Validate the first Royal Port logistics and softlock-protection iteration."""

from __future__ import annotations

import csv
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"port logistics evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


balance = {row["id"]: row for row in rows("balance.csv")}
expected_balance = {
    "port_resupply_gold_cost": 4,
    "port_resupply_gain": 3,
    "port_relief_gain": 1,
}
for identifier, expected in expected_balance.items():
    if identifier not in balance or int(balance[identifier]["value"]) != expected:
        raise SystemExit(f"port logistics balance drifted: {identifier}")

telemetry = {row["id"]: row for row in rows("telemetry_event.csv")}
event = telemetry.get("port_logistics_used")
if event is None or event["required_fields"] != "action|provisions|resources":
    raise SystemExit("port logistics telemetry contract is missing")

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    "local function supplyCapacity(state)",
    "local function departureSupplyCost(state)",
    'profile == "qa_port_low_supply"',
    'profile == "qa_port_blocked"',
    'id = "port_resupply"',
    'id = "claim_harbor_relief"',
    'state.flags.harbor_relief_used = true',
    'state.flags.harbor_relief_used = nil',
):
    if marker not in state:
        raise SystemExit(f"port logistics state contract is missing: {marker}")

model = (ROOT / "bin/res/scripts/LuaClass/V2PortModel.lua").read_text(encoding="utf-8")
for marker in (
    "function V2PortModel.logistics(state, data)",
    'status = blocked and "blocked"',
    'status.label = "航程受阻"',
    "can_claim_relief = canClaimRelief",
    "port_resupply = true",
    "claim_harbor_relief = true",
):
    if marker not in model:
        raise SystemExit(f"port logistics presentation model is missing: {marker}")

layer = (ROOT / "bin/res/scripts/LuaClass/V2PortLayer.lua").read_text(encoding="utf-8")
for marker in (
    'atHarbor and "港务后勤"',
    "V2PortModel.logistics(state, data)",
    '"Images/V2/Icons/resource-provisions.png"',
    'logistics.can_claim_relief and "救济 · 本次免费"',
):
    if marker not in layer:
        raise SystemExit(f"port logistics UI hierarchy is missing: {marker}")

theme = (ROOT / "bin/res/scripts/LuaClass/V2UITheme.lua").read_text(encoding="utf-8")
telemetry_source = (ROOT / "bin/res/scripts/LuaClass/V2Telemetry.lua").read_text(encoding="utf-8")
config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
for marker in ('port_resupply = "航海补给已入库"', 'claim_harbor_relief = "应急补给已领取"'):
    if marker not in theme:
        raise SystemExit(f"port logistics feedback is missing: {marker}")
if 'return "port_logistics_used"' not in telemetry_source or "port_logistics_actions" not in telemetry_source:
    raise SystemExit("port logistics telemetry classification or summary is missing")
for profile in ("qa_port_low_supply", "qa_port_blocked"):
    if f"{profile} = true" not in config:
        raise SystemExit(f"port logistics QA profile is missing: {profile}")

screenshots = (
    "port-logistics-iteration-1-resupply.png",
    "port-logistics-iteration-1-resupplied.png",
    "port-logistics-iteration-1-blocked.png",
)
for filename in screenshots:
    path = ROOT / "docs" / "v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"port logistics iPhone evidence is missing: {filename}")
    if path.stat().st_size < 500_000:
        raise SystemExit(f"port logistics iPhone evidence appears incomplete: {filename}")

record = (ROOT / "docs/v2/port-logistics-iteration-1.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "Before / After / Why",
    "常规补给",
    "港务救济",
    "软锁保护",
    "船员成长最小闭环",
    "DEFERRED_UNTIL_FINAL",
):
    if marker not in record:
        raise SystemExit(f"port logistics iteration record is missing: {marker}")
for marker in ("皇家港后勤第 1 轮", "港务救济", "DEFERRED_UNTIL_FINAL"):
    if marker not in plan or marker not in log:
        raise SystemExit(f"product records are missing port logistics marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
for command in (
    "lua tools/v2/test_v2_port_logistics.lua",
    "python3 tools/v2/validate_port_logistics.py",
):
    if command not in phase4:
        raise SystemExit(f"port logistics validation is not in the Phase 4 chain: {command}")

print("V2 port logistics baseline OK: resupply, relief, softlock protection, telemetry and iPhone evidence passed")
