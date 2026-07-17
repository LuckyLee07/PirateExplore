#!/usr/bin/env python3
"""Validate the unsigned or signed NewPirate iOS xcarchive payload."""

from __future__ import annotations

import argparse
import plistlib
import struct
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True

from archive_provenance import ProvenanceError, validate_identity


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def command(*args: str) -> str:
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def png_metadata(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        header = handle.read(26)
    require(header[:8] == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("--expected-source-commit")
    parser.add_argument("--expected-candidate-id")
    parser.add_argument("--require-clean-provenance", action="store_true")
    args = parser.parse_args()

    archive = args.archive.resolve()
    apps = list((archive / "Products/Applications").glob("*.app"))
    require(len(apps) == 1, f"expected exactly one app in archive, found {len(apps)}")
    app = apps[0]

    with (app / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    require(info.get("CFBundleIdentifier") == "com.fancyGame.NewPirate", "unexpected bundle identifier")
    require(info.get("CFBundleDisplayName") == "海上探险家", "unexpected display name")
    require(info.get("CFBundleShortVersionString") == "2.0.0", "unexpected marketing version")
    require(info.get("CFBundleVersion") == "1", "unexpected build number")
    require(info.get("MinimumOSVersion") == "12.0", "unexpected minimum iOS version")
    require(info.get("UIDeviceFamily") == [1, 2], "archive must support iPhone and iPad")
    require(info.get("ITSAppUsesNonExemptEncryption") is False, "offline archive must declare no non-exempt encryption")
    try:
        validate_identity(
            info,
            expected_source_commit=args.expected_source_commit,
            expected_candidate_id=args.expected_candidate_id,
            require_clean=args.require_clean_provenance,
        )
    except ProvenanceError as error:
        raise AssertionError(str(error)) from error

    for filename, expected in (
        ("AppIcon60x60@2x.png", (120, 120)),
        ("AppIcon76x76@2x~ipad.png", (152, 152)),
    ):
        path = app / filename
        require(path.is_file(), f"compiled archive icon missing: {filename}")
        width, height, color_type = png_metadata(path)
        require((width, height) == expected, f"compiled archive icon has wrong size: {filename}")
        require(color_type in {0, 2, 3}, f"compiled archive icon contains alpha: {filename}")

    privacy_path = app / "PrivacyInfo.xcprivacy"
    require(privacy_path.is_file(), "privacy manifest missing from app root")
    with privacy_path.open("rb") as handle:
        privacy = plistlib.load(handle)
    require(privacy.get("NSPrivacyTracking") is False, "archive privacy manifest must disable tracking")
    require(privacy.get("NSPrivacyTrackingDomains") == [], "archive must not declare tracking domains")
    require(privacy.get("NSPrivacyCollectedDataTypes") == [], "archive must not declare collected data")
    accessed = {
        item["NSPrivacyAccessedAPIType"]: set(item["NSPrivacyAccessedAPITypeReasons"])
        for item in privacy.get("NSPrivacyAccessedAPITypes", [])
    }
    require(
        accessed
        == {
            "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
            "NSPrivacyAccessedAPICategoryFileTimestamp": {"C617.1"},
        },
        "archive required-reason API declarations drifted",
    )

    dsyms = list((archive / "dSYMs").glob("*.app.dSYM"))
    require(len(dsyms) == 1, f"expected one app dSYM, found {len(dsyms)}")

    update_lua = (app / "scripts/LuaClass/Update.lua").read_text(encoding="utf-8")
    require("正在准备本地航海资源，请稍候" in update_lua, "archive does not contain offline loading copy")
    require("联网游戏可以获取离线资源" not in update_lua, "archive contains retired online-loading copy")
    require("finishSize >= totalSize and not didFinish" in update_lua, "archive loading completion is not one-shot")

    v2_config = (app / "scripts/LuaClass/V2Config.lua").read_text(encoding="utf-8")
    require('["legacy.network_time"] = false' in v2_config, "archive enables the retired server-clock path")
    notification = (app / "scripts/LuaClass/NotificationNode.lua").read_text(encoding="utf-8")
    require(
        notification.count('V2Config:isFeatureEnabled("legacy.network_time")') >= 2,
        "archive startup and foreground server-clock paths are not guarded",
    )

    chapter_state = (app / "scripts/LuaClass/V2ChapterState.lua").read_text(encoding="utf-8")
    for retired_copy in (
        "QA 探索档已定位",
        "QA 战斗档已定位",
        "QA 接舷档已定位",
        "QA 符文档",
        "QA 结算档",
        "QA 完成档",
    ):
        require(retired_copy not in chapter_state, f"archive contains player-visible QA seed copy: {retired_copy}")
    chapter_layout = (app / "scripts/LuaClass/V2ChapterLayout.lua").read_text(encoding="utf-8")
    for marker in ("height < 1050", "action_button_scale = 1.28", "top_bar_height = 145"):
        require(marker in chapter_layout, f"archive responsive layout missing marker: {marker}")

    save_manager = (app / "scripts/LuaClass/SaveDataManager.lua").read_text(encoding="utf-8")
    require(
        "containerLoadFailed" in save_manager and "existedBeforeLoad" in save_manager,
        "archive does not distinguish a fresh install from a rejected save container",
    )
    chapter_controller = (app / "scripts/LuaClass/V2ChapterController.lua").read_text(encoding="utf-8")
    require(
        "containerLoadFailed" in chapter_controller and "SAVE_RECOVERY_MESSAGE" in chapter_controller,
        "archive does not surface native save-container recovery to the player",
    )

    executable = app / info["CFBundleExecutable"]
    require(executable.is_file(), "app executable is missing")
    architecture = command("xcrun", "lipo", "-info", str(executable))
    require("arm64" in architecture, "archive executable is not arm64")

    dependencies = command("xcrun", "otool", "-L", str(executable))
    for forbidden in ("AdSupport.framework", "StoreKit.framework", "libcurl", "libssl", "libcrypto"):
        require(forbidden not in dependencies, f"legacy framework linked in archive: {forbidden}")

    symbols = command("xcrun", "nm", "-u", str(executable))
    for forbidden in ("ASIdentifierManager", "getIDFA", "GADBanner", "GADRequest", "SKPayment"):
        require(forbidden not in symbols, f"legacy symbol remains in archive: {forbidden}")
    for required in ("_fsync", "_rename"):
        require(required in symbols, f"atomic save durability symbol missing from archive: {required}")

    all_symbols = command("xcrun", "nm", "-j", str(executable))
    for forbidden in (
        "curl_easy_init",
        "SSL_connect",
        "AES_set_encrypt_key",
        "HttpClient",
        "XMLHttpRequest",
        "WebSocket",
    ):
        require(forbidden not in all_symbols, f"disabled legacy network/crypto symbol remains in archive: {forbidden}")

    print(f"iOS archive validation passed: {archive}")


if __name__ == "__main__":
    main()
