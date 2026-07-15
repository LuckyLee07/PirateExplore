#!/usr/bin/env python3
"""Static acceptance checks for the V2 Chapter 1 graybox integration."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


required_files = (
    "bin/res/scripts/LuaClass/V2ChapterData.lua",
    "bin/res/scripts/LuaClass/V2ChapterState.lua",
    "bin/res/scripts/LuaClass/V2ChapterController.lua",
    "bin/res/scripts/LuaClass/V2ChapterLayer.lua",
    "tools/v2/export_runtime.py",
    "tools/v2/test_v2_chapter_state.lua",
)
for required in required_files:
    if not (ROOT / required).is_file():
        raise SystemExit(f"missing Phase 1 file: {required}")

config = read("bin/res/scripts/LuaClass/V2Config.lua")
if "CURRENT_PHASE = 1" not in config:
    raise SystemExit("V2Config must identify Phase 1")

state = read("bin/res/scripts/LuaClass/V2ChapterState.lua")
for marker in (
    "choose_safe_route",
    "choose_risky_route",
    "fire_at_deck",
    "board_now",
    "deck_broken",
    "retry_battle",
    "recover_at_port",
    "upgrade_hull",
    "upgrade_guns",
    "next_voyage_objective",
):
    if marker not in state:
        raise SystemExit(f"state machine missing acceptance marker: {marker}")

dispatch = read("bin/res/scripts/LuaClass/Dispatch.lua")
if "self:moveToV2Chapter()" not in dispatch:
    raise SystemExit("new saves do not enter the V2 chapter surface")
if 'if not V2Config:isFeatureEnabled("v2.chapter_01") then' not in dispatch:
    raise SystemExit("legacy random event overlay is not isolated")

menu = read("bin/res/scripts/LuaClass/MainMenu.lua")
if "function MainMenuLayer:setV2Mode" not in menu:
    raise SystemExit("legacy menu chrome is not isolated from the vertical slice")

print("V2 Phase 1 integration OK: runtime data, state machine, save controller, graybox entry")
