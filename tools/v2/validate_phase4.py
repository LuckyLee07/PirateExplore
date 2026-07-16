#!/usr/bin/env python3
"""Validate the Phase 4 test, quality, performance, and decision baseline."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


telemetry = rows("telemetry_event.csv")
expected_events = {
    "session_started", "opening_accepted", "module_selected", "voyage_started",
    "route_intel_revealed", "route_selected", "voyage_event_choice", "curse_decision",
    "naval_action", "boarding_action", "battle_result", "recovery_choice",
    "rune_claimed", "return_completed", "upgrade_completed", "chapter_restarted",
    "invalid_action",
}
if {row["id"] for row in telemetry} != expected_events:
    raise SystemExit("Phase 4 telemetry contract is incomplete")
for row in telemetry:
    for field in ("trigger", "description", "required_fields", "decision_metric"):
        if not row[field]:
            raise SystemExit(f"telemetry event {row['id']} is missing {field}")

gates = rows("quality_gate.csv")
expected_gates = {
    "independent_first_voyage", "battle_understanding", "second_voyage_intent",
    "fantasy_recall", "critical_crash", "save_recovery", "mapped_assets",
    "simulator_memory", "target_frame_rate", "second_map_pipeline",
}
if {row["id"] for row in gates} != expected_gates:
    raise SystemExit("Phase 4 quality-gate set is incomplete")
external = [row for row in gates if row["category"] == "external_test"]
if len(external) != 4 or any(row["evidence_status"] != "pending_external" for row in external):
    raise SystemExit("external user-test gates must remain pending until real sessions exist")
for row in gates:
    if not all(row[field] for field in ("metric", "target", "decision_rule", "evidence_status")):
        raise SystemExit(f"quality gate {row['id']} is incomplete")

telemetry_source = (ROOT / "bin/res/scripts/LuaClass/V2Telemetry.lua").read_text(encoding="utf-8")
for marker in (
    "V2Telemetry.MAX_EVENTS = 240", "session_started", "invalid_action",
    "module_preference", "function V2Telemetry.getSummary",
):
    if marker not in telemetry_source:
        raise SystemExit(f"local telemetry implementation is missing {marker}")

controller = (ROOT / "bin/res/scripts/LuaClass/V2ChapterController.lua").read_text(encoding="utf-8")
for marker in ("V2Telemetry.snapshot", "V2Telemetry.record", "getTelemetrySummary", "self:save()"):
    if marker not in controller:
        raise SystemExit(f"chapter controller does not persist Phase 4 records: {marker}")

config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
if "CURRENT_PHASE = 4" not in config or "SAVE_SCHEMA_VERSION = 4" not in config:
    raise SystemExit("V2 config does not identify the Phase 4 baseline")
if "V2ChapterState.SCHEMA_VERSION = 4" not in state:
    raise SystemExit("V2 state schema was not advanced for persisted telemetry")

app_delegate = (ROOT / "src/NewPirate/client/AppDelegate.cpp").read_text(encoding="utf-8")
for marker in ("1.0 / 30", "getContentScaleFactor() > 2.0f", "setContentScaleFactor(2.0f)"):
    if marker not in app_delegate:
        raise SystemExit(f"the V2 runtime is missing an audited performance setting: {marker}")

ios_glview = (ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCGLView.mm").read_text(encoding="utf-8")
for marker in ("setContentScaleFactor:contentScaleFactor", "_screenSize.width", "_screenSize.height"):
    if marker not in ios_glview:
        raise SystemExit(f"the iOS framebuffer cap is incomplete: {marker}")

game_util = (ROOT / "src/NewPirate/common/UtilTools/GameBaseUtil.cpp").read_text(encoding="utf-8")
if "static std::string md5" not in game_util:
    raise SystemExit("the audited MD5 return value still has unsafe lifetime")

xhr = (ROOT / "src/engine/cocos2d-x/cocos/scripting/lua-bindings/manual/lua_xml_http_request.cpp").read_text(encoding="utf-8")
if "const auto httpHeader = self->getHttpHeader()" not in xhr:
    raise SystemExit("XMLHttpRequest response-header lookup still iterates a temporary map")

renderer = (ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCES2Renderer.m").read_text(encoding="utf-8")
if '@"<%@ = %p | size = %ix%i>"' not in renderer:
    raise SystemExit("iOS renderer description still truncates 64-bit pointers")

info_plist = (ROOT / "src/NewPirate/runtime/ios/Info.plist").read_text(encoding="utf-8")
if "UILaunchScreen" not in info_plist:
    raise SystemExit("the audited iOS target lacks a modern launch screen")
project = (ROOT / "projects/ios_mac/NewPirate.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
if "ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME" in project:
    raise SystemExit("the iOS target still enables deprecated launch images")

bindings_project_path = (
    ROOT / "src/engine/cocos2d-x/cocos/scripting/lua-bindings/proj.ios_mac/"
    "cocos2d_lua_bindings.xcodeproj/project.pbxproj"
)
if "IPHONEOS_DEPLOYMENT_TARGET = 8.0" in bindings_project_path.read_text(encoding="utf-8"):
    raise SystemExit("legacy iOS 8 deployment target remains in the tracked Lua bindings project")

xcode_script = (ROOT / "xcode.sh").read_text(encoding="utf-8")
if 'ARCHS="${ARCHS:-$(uname -m)}"' not in xcode_script:
    raise SystemExit("ios-sim does not default to the current host architecture")
if xcode_script.count("IPHONEOS_DEPLOYMENT_TARGET=12.0") < 2:
    raise SystemExit("iOS builds do not override ignored legacy engine projects to iOS 12")

required_docs = (
    "phase-4-completion-audit.md",
    "phase-4-user-test-protocol.md",
    "phase-4-quality-audit.md",
    "phase-4-decision.md",
    "phase-4-test-record-template.csv",
    "phase-4-issue-register.csv",
)
for filename in required_docs:
    path = ROOT / "docs" / "v2" / filename
    if not path.is_file() or path.stat().st_size < 200:
        raise SystemExit(f"Phase 4 deliverable is missing or incomplete: {filename}")

analyzer = ROOT / "tools/v2/analyze_user_tests.py"
analyzer_test = ROOT / "tools/v2/test_analyze_user_tests.py"
if not analyzer.is_file() or not analyzer_test.is_file():
    raise SystemExit("Phase 4 external-test aggregation tooling is missing")
analyzer_source = analyzer.read_text(encoding="utf-8")
for marker in ("ROUND_IDS =", "technical_failure", "external_gates_pass", "scope_warning"):
    if marker not in analyzer_source:
        raise SystemExit(f"external-test analyzer is missing {marker}")

record_rows = list(csv.DictReader((ROOT / "docs/v2/phase-4-test-record-template.csv").open(encoding="utf-8", newline="")))
if record_rows:
    raise SystemExit("external test record template must not contain fabricated participant results")

issue_rows = list(csv.DictReader((ROOT / "docs/v2/phase-4-issue-register.csv").open(encoding="utf-8", newline="")))
if not issue_rows or not {"P0", "P1", "P2"}.issubset({row["severity"] for row in issue_rows}):
    raise SystemExit("Phase 4 issue register needs evidence-backed P0/P1/P2 coverage")

print(
    f"V2 Phase 4 baseline OK: {len(telemetry)} events, {len(gates)} gates, "
    f"{len(issue_rows)} audited issues, external results pending"
)
