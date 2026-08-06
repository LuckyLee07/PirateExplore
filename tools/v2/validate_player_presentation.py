#!/usr/bin/env python3
"""Prevent internal QA/sample labels from leaking into the player presentation."""

import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYER = (ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua").read_text(encoding="utf-8")
STATE = (ROOT / "bin/res/scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
CONFIG = (ROOT / "bin/res/scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
DOC = ROOT / "docs/v2/internal-sample-polish-1.md"

for marker in (
    "function V2Config:isQAProfile(profile)",
    "function V2Config:getPresentationMode(profile)",
):
    if marker not in CONFIG:
        raise SystemExit(f"presentation mode config missing marker: {marker}")

for marker in (
    "local isQA = V2Config:isQAProfile(state.profile)",
    'local kicker = createLabel("第一章  ·  瓶中海域"',
    'local profile = createLabel("QA  ·  " .. state.profile',
    "if isQA then",
    "local footerText = string.format(",
    '"QA 记录 %d 条｜决策 %d｜舰炮 %d｜接舷 %d｜无效 %d"',
):
    if marker not in LAYER:
        raise SystemExit(f"player/QA presentation isolation missing marker: {marker}")

for leaked_label in (
    "CONTENT SAMPLE",
    "正式样片构图",
    "V2 样片：",
    "QA 构图",
    "迷雾会记住你的每一次选择。",
):
    if leaked_label in LAYER:
        raise SystemExit(f"internal label still leaks from presentation layer: {leaked_label}")

if 'complete = "第一章完成"' not in STATE:
    raise SystemExit("player completion title still exposes internal sample terminology")
if 'complete = "第一章样片完成"' in STATE:
    raise SystemExit("internal sample completion title still exists")


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise SystemExit(f"player presentation evidence is not a valid PNG: {path.name}")
    return struct.unpack(">II", header[16:24])


for filename in (
    "internal-sample-1-player-opening.png",
    "internal-sample-1-qa-opening.png",
):
    path = ROOT / "docs/v2" / filename
    if not path.is_file() or png_dimensions(path) != (750, 1334):
        raise SystemExit(f"player presentation evidence is missing or has unexpected dimensions: {filename}")

if not DOC.is_file():
    raise SystemExit("player presentation acceptance record is missing")
doc = DOC.read_text(encoding="utf-8")
for marker in ("玩家档 `player`", "QA 档 `qa_*`", "自动验收", "本轮验收结果：通过"):
    if marker not in doc:
        raise SystemExit(f"player presentation acceptance record missing marker: {marker}")

print("V2 player/QA presentation isolation OK")
