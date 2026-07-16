#!/usr/bin/env python3
"""Validate the unsigned or signed NewPirate iOS xcarchive payload."""

from __future__ import annotations

import argparse
import plistlib
import subprocess
from pathlib import Path


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def command(*args: str) -> str:
    return subprocess.run(args, check=True, text=True, capture_output=True).stdout


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
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
