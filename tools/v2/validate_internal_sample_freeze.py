#!/usr/bin/env python3
"""Validate the V2 Chapter 1 internal-sample freeze boundary."""

from __future__ import annotations

import csv
import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs/v2"

round_docs = [DOCS / f"internal-sample-polish-{round_id}.md" for round_id in range(1, 7)]
for path in round_docs:
    if not path.is_file() or "本轮验收结果：通过" not in path.read_text(encoding="utf-8"):
        raise SystemExit(f"internal sample round is not accepted: {path.name}")

screenshot_names = (
    "internal-sample-1-player-opening.png",
    "internal-sample-1-qa-opening.png",
    "internal-sample-2-qa-complete.png",
    "internal-sample-3-combat-impact.png",
    "internal-sample-3-boarding-transfer.png",
    "internal-sample-4-harbor-preview.png",
    "internal-sample-4-route-preview.png",
    "internal-sample-5-settlement.png",
    "internal-sample-5-upgrade.png",
    "internal-sample-6-failed.png",
)


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"internal sample evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for name in screenshot_names:
    path = DOCS / name
    if not path.is_file() or png_dimensions(path) != (750, 1334):
        raise SystemExit(f"internal sample evidence has unexpected dimensions: {name}")

with (DOCS / "phase-4-issue-register.csv").open(encoding="utf-8", newline="") as handle:
    issues = {row["issue_id"]: row for row in csv.DictReader(handle)}
if len(issues) != 38:
    raise SystemExit(f"freeze audit expects 38 classified issues, got {len(issues)}")

for issue_id in ("V2-010", "V2-033", "V2-034", "V2-035", "V2-036", "V2-037", "V2-038"):
    issue = issues.get(issue_id)
    if issue is None or issue["status"] != "fixed" or issue["release_effect"] != "closed":
        raise SystemExit(f"internal sample blocker is not closed: {issue_id}")

allowed_outstanding = {
    "V2-004": ("P2", "mitigated_pending_device", "blocks_device_gate"),
    "V2-005": ("P2", "accepted_legacy_debt", "non_blocking"),
    "V2-006": ("P1", "open_external", "blocks_go_decision"),
    "V2-009": ("P2", "accepted_environment", "non_blocking_simulator_limit"),
    "V2-014": ("P0", "open_account", "blocks_submission"),
    "V2-018": ("P0", "mitigated_external", "blocks_submission"),
    "V2-019": ("P0", "mitigated_external", "blocks_submission"),
}
actual_outstanding = {
    issue_id: (row["severity"], row["status"], row["release_effect"])
    for issue_id, row in issues.items()
    if row["release_effect"] != "closed"
}
if actual_outstanding != allowed_outstanding:
    raise SystemExit("internal sample outstanding issues no longer match the reviewed external/debt boundary")

with (ROOT / "design/v2/data/quality_gate.csv").open(encoding="utf-8", newline="") as handle:
    gates = {row["id"]: row["evidence_status"] for row in csv.DictReader(handle)}
expected_gate_status = {
    "independent_first_voyage": "pending_external",
    "battle_understanding": "pending_external",
    "second_voyage_intent": "pending_external",
    "fantasy_recall": "pending_external",
    "critical_crash": "internal_pass",
    "save_recovery": "internal_pass",
    "mapped_assets": "internal_pass",
    "simulator_memory": "internal_pass",
    "target_frame_rate": "pending_device",
    "second_map_pipeline": "internal_estimate",
}
if gates != expected_gate_status:
    raise SystemExit("quality gate status drifted from the reviewed internal/external boundary")

decision = (DOCS / "phase-4-decision.md").read_text(encoding="utf-8")
if "当前决策：**HOLD" not in decision:
    raise SystemExit("Phase 4 decision must remain HOLD at internal sample freeze")

launch_manifest = json.loads((ROOT / "docs/release/product-launch-manifest.json").read_text(encoding="utf-8"))
if launch_manifest["decision"]["phase4_status"] != "HOLD":
    raise SystemExit("product launch manifest must remain HOLD at internal sample freeze")
if launch_manifest["decision"]["product_scope_approved"] is not False:
    raise SystemExit("product scope cannot be approved by the internal sample freeze")

freeze_doc = DOCS / "internal-sample-freeze-audit.md"
if not freeze_doc.is_file():
    raise SystemExit("internal sample freeze audit is missing")
freeze_text = freeze_doc.read_text(encoding="utf-8")
for marker in (
    "内部样片：FROZEN",
    "产品立项：HOLD",
    "不得扩建第二海域",
    "38 个问题",
    "10 张",
    "外部目标用户",
    "真实设备",
    "NewPirate-internal-sample-6-final.xcarchive",
):
    if marker not in freeze_text:
        raise SystemExit(f"internal sample freeze audit missing marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
if "python3 tools/v2/validate_internal_sample_freeze.py" not in phase4:
    raise SystemExit("internal sample freeze gate is not in the Phase 4 chain")

print("V2 internal sample freeze OK: 6 rounds, 10 small-screen captures, no open internal P0/P1")
