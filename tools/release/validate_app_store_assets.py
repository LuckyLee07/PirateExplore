#!/usr/bin/env python3
"""Validate the checked-in App Store screenshot package."""

from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCREENSHOTS = ROOT / "docs/release/app-store-screenshots"
MANIFEST = SCREENSHOTS / "manifest.json"
EXPECTED_IMAGES = (
    "01-exploration.png",
    "02-naval-combat.png",
    "03-return-and-upgrade.png",
    "04-rune-clue.png",
)
EXPECTED_GROUPS = {
    "iphone-6.9": (1320, 2868),
    "ipad-13": (2064, 2752),
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def png_metadata(path: Path) -> tuple[int, int, int, int, bool]:
    with path.open("rb") as handle:
        require(handle.read(8) == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}")
        width = height = bit_depth = color_type = None
        has_transparency_chunk = False
        found_end = False
        while True:
            raw_length = handle.read(4)
            require(len(raw_length) == 4, f"truncated PNG chunk length: {path}")
            length = struct.unpack(">I", raw_length)[0]
            chunk_type = handle.read(4)
            data = handle.read(length)
            crc = handle.read(4)
            require(len(chunk_type) == 4 and len(data) == length and len(crc) == 4, f"truncated PNG chunk: {path}")
            if chunk_type == b"IHDR":
                require(length == 13, f"invalid PNG IHDR: {path}")
                width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
                    ">IIBBBBB", data
                )
                require((compression, filtering, interlace) == (0, 0, 0), f"unsupported PNG encoding: {path}")
            elif chunk_type == b"tRNS":
                has_transparency_chunk = True
            elif chunk_type == b"IEND":
                found_end = True
                break

    require(found_end and None not in (width, height, bit_depth, color_type), f"incomplete PNG: {path}")
    return width, height, bit_depth, color_type, has_transparency_chunk


def main() -> None:
    require(MANIFEST.is_file(), "App Store screenshot manifest is missing")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    require(manifest.get("locale") == "zh-CN", "unexpected screenshot locale")
    source = manifest.get("source_build", {})
    require(source.get("bundle_id") == "com.fancyGame.NewPirate", "screenshot bundle id drifted")
    require(source.get("marketing_version") == "2.0.0", "screenshot marketing version drifted")
    require(source.get("build_number") == "1", "screenshot build number drifted")
    require(source.get("configuration") == "Release", "screenshots must come from a Release build")

    capture = manifest.get("capture", {})
    require(capture.get("presentation_profile") == "player", "screenshots must use the player presentation")
    require(capture.get("alpha_removed_losslessly") is True, "screenshot alpha-removal record is missing")

    groups = {group["id"]: group for group in manifest.get("groups", [])}
    require(set(groups) == set(EXPECTED_GROUPS), "screenshot device groups drifted")
    scenes = [item.get("scene") for item in manifest.get("images", [])]
    require(
        scenes == ["exploration", "naval-combat", "return-and-upgrade", "rune-clue"],
        "screenshot scene order drifted",
    )

    review = manifest.get("visual_review", {})
    require(review.get("status") == "passed", "full-resolution visual review is not passed")
    require(review.get("qa_markers_visible") is False, "visual review found QA markers")
    require(review.get("iphone_title_clears_dynamic_island") is True, "iPhone safe-area review is not passed")
    require(review.get("ipad_controls_overlap") is False, "iPad overlap review is not passed")
    require(review.get("reviewed_at_full_resolution") is True, "screenshots were not reviewed at full resolution")

    hashes: set[str] = set()
    for group_id, expected_dimensions in EXPECTED_GROUPS.items():
        group = groups[group_id]
        require(
            (group.get("pixel_width"), group.get("pixel_height")) == expected_dimensions,
            f"manifest dimensions drifted for {group_id}",
        )
        directory = SCREENSHOTS / "zh-CN" / group_id
        require(directory.is_dir(), f"missing screenshot group: {group_id}")
        actual = tuple(sorted(path.name for path in directory.glob("*.png")))
        require(actual == EXPECTED_IMAGES, f"unexpected screenshot inventory for {group_id}: {actual}")
        for filename in EXPECTED_IMAGES:
            path = directory / filename
            width, height, bit_depth, color_type, has_transparency = png_metadata(path)
            require((width, height) == expected_dimensions, f"wrong screenshot dimensions: {path}")
            require(bit_depth == 8 and color_type == 2, f"screenshot must be 8-bit RGB without alpha: {path}")
            require(not has_transparency, f"screenshot contains a transparency chunk: {path}")
            require(path.stat().st_size >= 200_000, f"screenshot appears blank or over-compressed: {path}")
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            require(digest not in hashes, f"duplicate screenshot payload: {path}")
            hashes.add(digest)

    print("App Store assets validation passed: 8 RGB screenshots across iPhone 6.9-inch and iPad 13-inch groups")


if __name__ == "__main__":
    main()
