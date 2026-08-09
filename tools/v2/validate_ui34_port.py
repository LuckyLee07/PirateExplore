#!/usr/bin/env python3
"""Validate the UI 3.4 Royal Port product-interface contract and evidence."""

from __future__ import annotations

import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PORT_LAYER = (ROOT / "bin/res/scripts/LuaClass/V2PortLayer.lua").read_text(encoding="utf-8")
PORT_MODEL = (ROOT / "bin/res/scripts/LuaClass/V2PortModel.lua").read_text(encoding="utf-8")
DISPATCH = (ROOT / "bin/res/scripts/LuaClass/Dispatch.lua").read_text(encoding="utf-8")
CHAPTER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
PHASE4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")


def require_markers(text: str, label: str, markers: tuple[str, ...]) -> None:
    for marker in markers:
        if marker not in text:
            raise SystemExit(f"UI 3.4 {label} is missing marker: {marker}")


require_markers(
    PORT_MODEL,
    "port model",
    (
        '{ id = "chart", index = "01", label = "航海桌"',
        '{ id = "ship", index = "02", label = "船只"',
        '{ id = "crew", index = "03", label = "船员"',
        '{ id = "cargo", index = "04", label = "货舱"',
        "function V2PortModel.ship(state, data)",
        "function V2PortModel.crew(state, data)",
        "function V2PortModel.cargo(state, data)",
        "function V2PortModel.readiness(state, data)",
        "function V2PortModel.actions(sectionId, actions)",
        'return_to_port = true',
        'active_detail = activeDetail or "在对应远航阶段开放"',
    ),
)

require_markers(
    PORT_LAYER,
    "port layer",
    (
        'V2PortLayer = class("V2PortLayer"',
        "function V2PortLayer:addChartSection",
        "function V2PortLayer:addShipSection",
        "function V2PortLayer:addCrewSection",
        "function V2PortLayer:addCargoSection",
        "function V2PortLayer:addSectionNavigation",
        "self.controller:getActions()",
        "self.controller:dispatch(actionId)",
        'os.getenv("NEWPIRATE_V2_PORT_SECTION")',
        'os.getenv("NEWPIRATE_V2_QA_ACTION")',
        'createLabel(item.active_detail',
    ),
)

for forbidden in (
    "cc.RepeatForever:create",
    'require "LuaClass/Repository"',
    'require "LuaClass/MakeMode"',
    'require "LuaClass/TrainMode"',
):
    if forbidden in PORT_LAYER:
        raise SystemExit(f"UI 3.4 port reintroduced an obsolete dependency or motion: {forbidden}")

require_markers(
    DISPATCH,
    "routing",
    (
        'require "LuaClass/V2PortLayer"',
        'os.getenv("NEWPIRATE_V2_START_SURFACE")',
        'if V2Config:isQAProfile()',
        "function Dispatch:moveToV2Port()",
    ),
)
require_markers(
    CHAPTER,
    "chapter entry",
    (
        "function V2ChapterLayer:openPort()",
        'local portLabel = createLabel("整备"',
        "zqDispatch:moveToV2Port()",
    ),
)


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"UI 3.4 evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in (
    "ui3-4-port-chart.png",
    "ui3-4-port-ship.png",
    "ui3-4-port-crew.png",
    "ui3-4-port-cargo.png",
    "ui3-4-port-upgrade.png",
    "ui3-4-chapter-entry.png",
):
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_dimensions(path) != (1206, 2622):
        raise SystemExit(f"UI 3.4 mainstream-iPhone evidence is missing: {filename}")

matrix = ROOT / "docs/v2/ui34-iphone-port-matrix.png"
if not matrix.is_file() or png_dimensions(matrix) != (1296, 676):
    raise SystemExit("UI 3.4 four-section iPhone matrix is missing")

record = (ROOT / "docs/v2/ui-3.4-royal-port.md").read_text(encoding="utf-8")
style = (ROOT / "docs/v2/ui-3.0-style-system.md").read_text(encoding="utf-8")
plan = (ROOT / "docs/product-iteration-plan-v2.md").read_text(encoding="utf-8")
log = (ROOT / "docs/product-iteration-log.md").read_text(encoding="utf-8")
for marker in (
    "UI 3.4",
    "航海桌",
    "船只",
    "船员",
    "货舱",
    "DEFERRED_UNTIL_FINAL",
    "第二次远航",
):
    if marker not in record or marker not in style or marker not in plan or marker not in log:
        raise SystemExit(f"UI 3.4 records are missing marker: {marker}")

if "lua tools/v2/test_v2_port_model.lua" not in PHASE4:
    raise SystemExit("UI 3.4 port model test is not in the Phase 4 chain")
if "python3 tools/v2/validate_ui34_port.py" not in PHASE4:
    raise SystemExit("UI 3.4 evidence validation is not in the Phase 4 chain")

print("V2 UI 3.4 port OK: four real-data sections, routing and iPhone evidence passed")
