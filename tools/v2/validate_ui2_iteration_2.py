#!/usr/bin/env python3
"""Validate UI 2.0 iteration 2 stage art, mappings and runtime evidence."""

from __future__ import annotations

import csv
import hashlib
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "bin/res/assets/Images/V2"

expected_assets = {
    "ui2_harbor.png": (1900416, "d05496b739a5ab572f74fe919a6f5591353bf227e29e93e593ba68cd5e32962c"),
    "ui2_exploration.png": (2016280, "d1cb54ae073154b8d42637b422ef792a690e8ca61d3bfe68a0d1029e44f728b6"),
    "ui2_combat.png": (1969072, "800de7d4630093c38c4a29c6317a541fd81a20ed45e65c852714d618f79dac27"),
    "ui2_rune.png": (1724118, "49f73240fcd4399b69c24909823afb1ff06d69b327cf31bad38aeb1e0055ba46"),
}


def png_info(path: Path) -> tuple[int, int, int]:
    header = path.read_bytes()[:26]
    if len(header) != 26 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"UI 2.0 stage art is not a valid PNG: {path.name}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]


for filename, (expected_size, expected_hash) in expected_assets.items():
    path = ASSETS / filename
    if not path.is_file():
        raise SystemExit(f"UI 2.0 stage art is missing: {filename}")
    if png_info(path) != (1024, 1024, 2):
        raise SystemExit(f"UI 2.0 stage art must be 1024x1024 RGB without alpha: {filename}")
    if path.stat().st_size != expected_size:
        raise SystemExit(f"UI 2.0 stage art size drifted: {filename}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != expected_hash:
        raise SystemExit(f"UI 2.0 stage art hash drifted: {filename}")

with (ROOT / "design/v2/data/presentation.csv").open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))
if len(rows) != 14:
    raise SystemExit("UI 2.0 stage mapping must keep all 14 Chapter 1 presentations")

expected_by_stage = {
    "opening": "Images/V2/ui2_harbor.png",
    "harbor": "Images/V2/ui2_harbor.png",
    "upgrade": "Images/V2/ui2_harbor.png",
    "complete": "Images/V2/ui2_harbor.png",
    "route_choice": "Images/V2/ui2_exploration.png",
    "route_event": "Images/V2/ui2_exploration.png",
    "black_tide": "Images/V2/ui2_exploration.png",
    "naval": "Images/V2/ui2_combat.png",
    "boarding": "Images/V2/ui2_combat.png",
    "failed": "Images/V2/ui2_combat.png",
    "whisper": "Images/V2/ui2_rune.png",
    "curse_choice": "Images/V2/ui2_rune.png",
    "rune_clue": "Images/V2/ui2_rune.png",
    "settlement": "Images/V2/ui2_rune.png",
}
actual_by_stage = {row["stage"]: row["background"] for row in rows}
if actual_by_stage != expected_by_stage:
    raise SystemExit("UI 2.0 stage-to-background mapping drifted")
if any(row["foreground"] or row["portrait"] for row in rows):
    raise SystemExit("UI 2.0 still mixes legacy foreground or portrait layers with the new stage art")
if any(not row["animation"] or not row["audio_cue"] for row in rows):
    raise SystemExit("UI 2.0 art mapping dropped a stage animation or audio cue")

runtime = (ROOT / "bin/res/scripts/LuaClass/V2ChapterData.lua").read_text(encoding="utf-8")
for background in set(expected_by_stage.values()):
    if background not in runtime:
        raise SystemExit(f"runtime export is missing UI 2.0 stage art: {background}")

evidence = {
    "ui2-iteration2-se-player-opening.png": (750, 1334),
    "ui2-iteration2-se-harbor.png": (750, 1334),
    "ui2-iteration2-se-exploration.png": (750, 1334),
    "ui2-iteration2-se-combat.png": (750, 1334),
    "ui2-iteration2-se-rune.png": (750, 1334),
    "ui2-iteration2-se-upgrade.png": (750, 1334),
    "ui2-iteration2-se-failed.png": (750, 1334),
    "ui2-iteration2-ipad-exploration.png": (1640, 2360),
    "ui2-iteration2-ipad-combat.png": (1640, 2360),
}
for filename, expected in evidence.items():
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_info(path)[:2] != expected:
        raise SystemExit(f"UI 2.0 iteration 2 evidence is missing or has unexpected dimensions: {filename}")

doc = (ROOT / "docs/v2/ui-2.0-iteration-2.md").read_text(encoding="utf-8")
for marker in (
    "14 个演出状态",
    "图像生成工具",
    "1024×1024 RGB PNG",
    "默认玩家首屏",
    "iPhone SE 3",
    "iPad A16",
    "HOLD",
    "不继续扩建第二海域",
):
    if marker not in doc:
        raise SystemExit(f"UI 2.0 iteration 2 acceptance record is missing marker: {marker}")

phase4 = (ROOT / "tools/v2/validate_phase4.sh").read_text(encoding="utf-8")
if "python3 tools/v2/validate_ui2_iteration_2.py" not in phase4:
    raise SystemExit("UI 2.0 iteration 2 validation is not in the Phase 4 chain")

print("V2 UI 2.0 iteration 2 OK: 4 stage art assets, 14 mappings and 9 runtime captures")
