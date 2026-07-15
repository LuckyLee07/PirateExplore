#!/usr/bin/env python3
"""Validate the Phase 3 content and presentation sample."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "design" / "v2" / "data"
ASSETS = ROOT / "bin" / "res" / "assets"


def rows(name: str) -> list[dict[str, str]]:
    with (DATA / name).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


events = rows("event.csv")
if len(events) != 8:
    raise SystemExit("Phase 3 requires exactly eight Chapter 1 events")
required_events = {
    "event_route_choice", "event_safe_cove", "event_wreck_survivors",
    "event_black_tide", "event_whisper", "event_cursed_compass",
    "event_raider_encounter", "event_rune_clue",
}
if {row["id"] for row in events} != required_events:
    raise SystemExit("Phase 3 event set is incomplete")

choices = rows("event_choice.csv")
if len(choices) < 13 or any(not row["action_id"] for row in choices):
    raise SystemExit("Phase 3 event choices need runtime action mappings")
if len({row["action_id"] for row in choices}) != len(choices):
    raise SystemExit("Phase 3 event choice action ids must be unique")

dialogue = rows("dialogue.csv")
if len(dialogue) < 18:
    raise SystemExit("Phase 3 requires plot and voyage dialogue coverage")
required_triggers = {
    "chapter_start", "node_enter", "choice_prompt", "choice_resolved",
    "battle_start", "naval_hint", "boarding_start", "boarding_hint",
    "chapter_complete", "return_to_port",
}
if not required_triggers.issubset({row["trigger"] for row in dialogue}):
    raise SystemExit("Phase 3 dialogue is missing a voyage or combat trigger")

presentations = rows("presentation.csv")
required_groups = {"harbor", "map", "combat", "rune"}
if {row["hero_group"] for row in presentations} != required_groups:
    raise SystemExit("presentation.csv must cover the four hero compositions")
required_stages = {"opening", "harbor", "route_choice", "naval", "boarding", "rune_clue", "settlement"}
if not required_stages.issubset({row["stage"] for row in presentations}):
    raise SystemExit("presentation.csv is missing a required hero stage")
for row in presentations:
    if not row["animation"] or not row["background"]:
        raise SystemExit(f"presentation {row['id']} needs art and key animation")
    for field in ("background", "foreground", "portrait"):
        if row[field] and not (ASSETS / row[field]).is_file():
            raise SystemExit(f"presentation {row['id']} references missing {row[field]}")
        if "generated" in row[field].lower() or "placeholder" in row[field].lower():
            raise SystemExit(f"presentation {row['id']} uses temporary generated placeholder art")

audio = rows("audio_cue.csv")
required_audio = {"wave", "cannon", "boarding", "victory", "curse", "sinking"}
if {row["id"] for row in audio} != required_audio:
    raise SystemExit("audio_cue.csv does not cover the approved Phase 3 cue set")
for row in audio:
    if not (ASSETS / row["file"]).is_file():
        raise SystemExit(f"audio cue {row['id']} references missing {row['file']}")
    if "approved" not in row["source_status"]:
        raise SystemExit(f"audio cue {row['id']} lacks source approval status")

state = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
for marker in (
    'state.stage = "black_tide"', 'state.stage = "curse_choice"',
    'balanceValue("black_tide_hull_damage")', 'balanceValue("compass_ship_damage")',
    "dialogueBlock", "getPresentation",
):
    if marker not in state:
        raise SystemExit(f"state machine missing Phase 3 marker: {marker}")

layer = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
for marker in ("addHeroArt", "playActionFeedback", "NEWPIRATE_V2_AUDIO_CUE", "RepeatForever", "正式样片构图"):
    if marker not in layer:
        raise SystemExit(f"presentation layer missing Phase 3 marker: {marker}")
if "AudioEngine.playEffect" in layer:
    raise SystemExit("V2 presentation still calls the unstable legacy audio backend")

bridge = (ROOT / "src/NewPirate/runtime/ios/CppOCBridge.mm").read_text(encoding="utf-8")
binding = (ROOT / "src/NewPirate/game/ToLua/TOLUA_GameBaseUtil.cpp").read_text(encoding="utf-8")
for marker in ("AVAudioPlayer", "AVAudioSessionCategoryAmbient", "assets"):
    if marker not in bridge:
        raise SystemExit(f"native V2 audio bridge missing marker: {marker}")
if 'tolua_function(tolua_S,"playV2Sound"' not in binding:
    raise SystemExit("native V2 audio bridge is not exposed to Lua")

config = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
if "CURRENT_PHASE = 3" not in config or "SAVE_SCHEMA_VERSION = 3" not in config:
    raise SystemExit("V2Config does not identify the Phase 3 content sample")

controller = (ROOT / "bin/res/scripts/LuaClass/controller.lua").read_text(encoding="utf-8")
if 'isFeatureEnabled("legacy.missions")' not in controller:
    raise SystemExit("legacy mission toast is not isolated from the V2 sample")

info_plist = (ROOT / "src/NewPirate/runtime/ios/Info.plist").read_text(encoding="utf-8")
if "UILaunchScreen" not in info_plist:
    raise SystemExit("iOS build lacks the modern full-screen launch declaration")

print(
    f"V2 Phase 3 data OK: {len(events)} events, {len(dialogue)} dialogue lines, "
    f"{len(presentations)} presentations, {len(audio)} audio cues"
)
