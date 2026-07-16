#!/usr/bin/env python3
"""Static release checks for the NewPirate V2 iOS target."""

from __future__ import annotations

import json
import plistlib
import re
import struct
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
IOS = ROOT / "src/NewPirate/runtime/ios"
PROJECT = ROOT / "projects/ios_mac/NewPirate.xcodeproj/project.pbxproj"
ENGINE_PROJECT = ROOT / "src/engine/cocos2d-x/build/cocos2d_libs.xcodeproj/project.pbxproj"
LUA_STACK = ROOT / "src/engine/cocos2d-x/cocos/scripting/lua-bindings/manual/CCLuaStack.cpp"
ASSETS_MANAGER = ROOT / "src/engine/cocos2d-x/extensions/assets-manager/AssetsManager.cpp"
APPICON = IOS / "Images.xcassets/AppIcon.appiconset"
V2_CONFIG = ROOT / "bin/res/scripts/LuaClass/V2Config.lua"
V2_RELEASE_INFO = ROOT / "bin/res/scripts/LuaClass/V2ReleaseInfo.lua"
V2_CHAPTER_LAYER = ROOT / "bin/res/scripts/LuaClass/V2ChapterLayer.lua"
NOTIFICATION_NODE = ROOT / "bin/res/scripts/LuaClass/NotificationNode.lua"
UPDATE_LAYER = ROOT / "bin/res/scripts/LuaClass/Update.lua"
SAVE_MANAGER = ROOT / "bin/res/scripts/LuaClass/SaveDataManager.lua"
V2_CHAPTER_CONTROLLER = ROOT / "bin/res/scripts/LuaClass/V2ChapterController.lua"
RECORD = ROOT / "src/NewPirate/common/UtilTools/Record.cpp"
RECORD_CODEC = ROOT / "src/NewPirate/common/UtilTools/RecordCodec.cpp"
RECORD_CODEC_HEADER = ROOT / "src/NewPirate/common/UtilTools/RecordCodec.h"
LZSS = ROOT / "src/NewPirate/common/UtilTools/LZSS.cpp"
RECORD_CODEC_TEST = ROOT / "tools/release/test_record_codec.sh"
SAVE_DURABILITY_DOC = ROOT / "docs/release/save-durability-iteration-1.md"
SAVE_RECOVERY_SCREENSHOT = ROOT / "docs/release/save-container-recovery-player.png"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def read_plist(path: Path) -> dict:
    with path.open("rb") as handle:
        return plistlib.load(handle)


def object_block(project: str, object_id: str) -> str:
    match = re.search(
        rf"^\s*{re.escape(object_id)}\b[^\n]*= \{{(.*?)^\s*\}};",
        project,
        flags=re.MULTILINE | re.DOTALL,
    )
    require(match is not None, f"missing Xcode object {object_id}")
    return match.group(1)


def png_metadata(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as handle:
        header = handle.read(26)
    require(header[:8] == b"\x89PNG\r\n\x1a\n", f"not a PNG: {path}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]


def validate_info_plist() -> None:
    info = read_plist(IOS / "Info.plist")
    require(info.get("CFBundleDisplayName") == "海上探险家", "unexpected display name")
    require(info.get("CFBundleShortVersionString") == "$(MARKETING_VERSION)", "marketing version must come from build settings")
    require(info.get("CFBundleVersion") == "$(CURRENT_PROJECT_VERSION)", "build number must come from build settings")
    require(info.get("UILaunchScreen") == {}, "modern UILaunchScreen declaration is required")
    require(info.get("ITSAppUsesNonExemptEncryption") is False, "offline release must declare that it has no non-exempt encryption")
    require(info.get("UIRequiresFullScreen") is True, "portrait game must require full screen")
    require(info.get("UISupportedInterfaceOrientations") == ["UIInterfaceOrientationPortrait"], "release must remain portrait-only")
    require(info.get("UIRequiredDeviceCapabilities") == {"opengles-2": True}, "release capability declaration drifted")


def validate_privacy_manifest() -> None:
    privacy = read_plist(IOS / "PrivacyInfo.xcprivacy")
    require(privacy.get("NSPrivacyTracking") is False, "tracking must remain disabled")
    require(privacy.get("NSPrivacyTrackingDomains") == [], "tracking domains must remain empty")
    require(privacy.get("NSPrivacyCollectedDataTypes") == [], "this build declares no collected data")
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
        "required-reason API declarations drifted",
    )


def validate_app_icons() -> None:
    catalog = json.loads((APPICON / "Contents.json").read_text(encoding="utf-8"))
    require(catalog.get("images"), "AppIcon catalog is empty")
    referenced_files: set[str] = set()
    for entry in catalog["images"]:
        filename = entry.get("filename")
        require(bool(filename), f"AppIcon slot has no file: {entry}")
        referenced_files.add(filename)
        size = float(entry["size"].split("x", 1)[0])
        scale = int(entry["scale"].removesuffix("x"))
        expected = round(size * scale)
        path = APPICON / filename
        require(path.is_file(), f"missing AppIcon image: {filename}")
        width, height, color_type = png_metadata(path)
        require((width, height) == (expected, expected), f"wrong AppIcon dimensions for {filename}: {width}x{height}, expected {expected}x{expected}")
        require(color_type in {0, 2, 3}, f"AppIcon must not contain alpha: {filename}")

    actual_files = {path.name for path in APPICON.glob("*.png")}
    require(actual_files == referenced_files, "AppIcon catalog contains missing or unassigned PNG files")

    marketing_entries = [entry for entry in catalog["images"] if entry.get("idiom") == "ios-marketing"]
    require(len(marketing_entries) == 1, "AppIcon catalog must contain exactly one iOS marketing slot")
    marketing = APPICON / marketing_entries[0]["filename"]
    width, height, color_type = png_metadata(marketing)
    require((width, height) == (1024, 1024), "marketing icon must be 1024x1024")
    require(color_type in {0, 2, 3}, "marketing icon must not contain an alpha channel")


def validate_project() -> None:
    require(PROJECT.is_file(), "tracked Xcode project is missing")
    project = PROJECT.read_text(encoding="utf-8")
    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    require("!/projects/ios_mac/NewPirate.xcodeproj/project.pbxproj" in gitignore, "Xcode project is still excluded by .gitignore")
    require("!/src/engine/cocos2d-x/build/cocos2d_libs.xcodeproj/project.pbxproj" in gitignore, "referenced cocos2d Xcode project is still excluded by .gitignore")

    resources = object_block(project, "F293B3C615EB7BE500256477")
    require("PrivacyInfo.xcprivacy in Resources" in resources, "privacy manifest is not in the iOS resource phase")

    frameworks = object_block(project, "F293B3C515EB7BE500256477")
    for forbidden in ("AdSupport", "StoreKit", "GoogleMobileAds"):
        require(forbidden not in frameworks, f"legacy framework remains in iOS target: {forbidden}")

    sources = object_block(project, "F293B3C415EB7BE500256477")
    require("RecordCodec.cpp in Sources" in sources, "bounds-checked save codec is not in the iOS target")
    for forbidden in (
        "IapManager",
        "SBJSON",
        "SBJson",
        "NSData+Base64",
        "AdmobManager",
        "DES3Tools",
        "GlobalObject",
        "GTMBase64",
        "MBProgressHUD",
        "AES.cpp",
    ):
        require(forbidden not in sources, f"legacy source remains in iOS target: {forbidden}")

    for config_id in ("F293B6C515EB7BEA00256477", "F293B6C615EB7BEA00256477"):
        config = object_block(project, config_id)
        require("CODE_SIGN_STYLE = Automatic;" in config, f"automatic signing missing in {config_id}")
        require("MARKETING_VERSION = 2.0.0;" in config, f"marketing version missing in {config_id}")
        require("CURRENT_PROJECT_VERSION = 1;" in config, f"build number missing in {config_id}")
        for forbidden in ("CODE_SIGN_IDENTITY", "DEVELOPMENT_TEAM", "PROVISIONING_PROFILE", "LD_NO_PIE"):
            require(forbidden not in config, f"hard-coded release setting remains in {config_id}: {forbidden}")

    require("AdSupport" not in project, "AdSupport must not be referenced by the project")
    require("GoogleMobileAds" not in project, "GoogleMobileAds must not be referenced by the project")
    require("StoreKit" not in project, "StoreKit must not be referenced by the project")

    for scheme in ("NewPirate iOS.xcscheme", "NewPirate Mac.xcscheme"):
        require((PROJECT.parent / "xcshareddata/xcschemes" / scheme).is_file(), f"missing shared scheme: {scheme}")

    mac_sources = object_block(project, "5023813117EBBCE400990C9B")
    require("RecordCodec.cpp in Sources" in mac_sources, "bounds-checked save codec is not in the macOS target")

    require(ENGINE_PROJECT.is_file(), "referenced cocos2d Xcode project is missing")
    engine = ENGINE_PROJECT.read_text(encoding="utf-8")
    engine_frameworks = object_block(engine, "A07A4CAD1783777C0073F6A7")
    for forbidden in ("libcurl", "libwebsockets"):
        require(forbidden not in engine_frameworks, f"legacy network archive remains in iOS engine target: {forbidden}")
    engine_sources = object_block(engine, "A07A4C251783777C0073F6A7")
    for forbidden in ("HttpClient.cpp", "SocketIO.cpp", "WebSocket.cpp"):
        require(forbidden not in engine_sources, f"legacy network source remains in iOS engine target: {forbidden}")
    for config_id in ("A07A4D621783777C0073F6A7", "A07A4D631783777C0073F6A7"):
        config = object_block(engine, config_id)
        for forbidden in ("-lcurl", "-lwebsockets"):
            require(forbidden not in config, f"legacy network linker flag remains in iOS engine config: {forbidden}")


def validate_native_surface() -> None:
    files = {
        "OpenUrl": ROOT / "src/NewPirate/client/OpenUrl.mm",
        "GameBaseUtil": ROOT / "src/NewPirate/common/UtilTools/GameBaseUtil.cpp",
        "AppController": IOS / "AppController.mm",
        "CppOCBridge": IOS / "CppOCBridge.mm",
    }
    forbidden = {
        "OpenUrl": ("AdSupport", "ASIdentifierManager", "getIDFA", "getMacAddress"),
        "GameBaseUtil": ("getIDFA", "purchaseCall", "showCcMoreScene", "showCcRateScene", "decodeCdkey", "enableToSDK"),
        "AppController": ("AdmobManager", "showRateReward"),
        "CppOCBridge": ("AdmobManager", "IapManager", "purchaseCall", "decodeCdkey", "enableToSDK"),
    }
    for name, path in files.items():
        source = path.read_text(encoding="utf-8")
        for token in forbidden[name]:
            require(token not in source, f"legacy native surface remains in {name}: {token}")

    open_url = files["OpenUrl"].read_text(encoding="utf-8")
    require('isEqualToString:@"https"' in open_url, "iOS external links must reject non-HTTPS URLs")
    require("openURL:target options:@{} completionHandler:nil" in open_url, "iOS external links must use the modern system API")

    release_info = V2_RELEASE_INFO.read_text(encoding="utf-8")
    for marker in ("PRIVACY_POLICY_URL", "SUPPORT_URL", "getCombinedText", "isPublishableHttpsUrl"):
        require(marker in release_info, f"V2 release information is missing {marker}")
    for forbidden in ("探险科技有限公司", "106134362", "1976428305@qq.com", "example.com"):
        require(forbidden not in release_info, f"unverified legacy or example contact leaked into V2 release information: {forbidden}")

    chapter_layer = V2_CHAPTER_LAYER.read_text(encoding="utf-8")
    for marker in (
        "隐私与支持", "隐私说明", "支持说明", "showReleaseInfo", "openReleaseUrl",
        "body:setDimensions(cc.size(panelWidth - 48, panelHeight - 150))",
        "NEWPIRATE_V2_RELEASE_INFO",
    ):
        require(marker in chapter_layer, f"V2 player privacy/support entry is missing {marker}")

    lua_stack = LUA_STACK.read_text(encoding="utf-8")
    require("#if (CC_TARGET_PLATFORM != CC_PLATFORM_IOS)\n    register_xml_http_request(_state);" in lua_stack, "iOS XMLHttpRequest registration must remain disabled")
    require("#if (CC_TARGET_PLATFORM != CC_PLATFORM_IOS)\n    luaopen_socket_core(_state);" in lua_stack, "iOS LuaSocket registration must remain disabled")
    ios_websocket_guard = "#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID || CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)"
    require(ios_websocket_guard in lua_stack, "iOS WebSocket registration must remain disabled")

    assets_manager = ASSETS_MANAGER.read_text(encoding="utf-8")
    require(assets_manager.count("V2 iOS release: legacy remote AssetsManager") == 2, "iOS AssetsManager network stubs are missing")

    v2_config = V2_CONFIG.read_text(encoding="utf-8")
    require('["legacy.network_time"] = false' in v2_config, "legacy server-clock path must remain disabled")

    notification = NOTIFICATION_NODE.read_text(encoding="utf-8")
    network_time_guard = 'V2Config:isFeatureEnabled("legacy.network_time")'
    require(notification.count(network_time_guard) >= 2, "startup and foreground server-clock paths must remain guarded")

    update_layer = UPDATE_LAYER.read_text(encoding="utf-8")
    require("正在准备本地航海资源，请稍候" in update_layer, "offline loading copy drifted")
    require("联网游戏可以获取离线资源" not in update_layer, "retired online-loading copy remains")
    require("finishSize >= totalSize and not didFinish" in update_layer, "loading completion must remain one-shot")


def validate_save_durability() -> None:
    for path in (
        RECORD, RECORD_CODEC, RECORD_CODEC_HEADER, LZSS, SAVE_MANAGER,
        V2_CHAPTER_CONTROLLER, RECORD_CODEC_TEST, SAVE_DURABILITY_DOC,
        SAVE_RECOVERY_SCREENSHOT,
    ):
        require(path.is_file(), f"save-durability component is missing: {path.relative_to(ROOT)}")

    record = RECORD.read_text(encoding="utf-8")
    for marker in (
        "RecordCodec::encode",
        "RecordCodec::writeFileAtomically",
        "RecordCodec::readFile",
        "RecordCodec::decode",
        "Record rejected a corrupt or truncated save",
        "Invalidate only after the replacement succeeds",
    ):
        require(marker in record, f"native save persistence is missing: {marker}")

    codec = RECORD_CODEC.read_text(encoding="utf-8")
    for marker in (
        "kMaxDecodedBytes",
        "compressionBound",
        "lengthWidth != 4u && lengthWidth != 8u",
        "compressedLength != container.size() - headerSize",
        "writeFileAtomically",
        "fsync",
        "std::rename",
    ):
        require(marker in codec, f"save codec guard is missing: {marker}")

    lzss = LZSS.read_text(encoding="utf-8")
    for marker in ("delete []buffer", "OutDataCapacity", "OutputOverflow", "outCapacity"):
        require(marker in lzss or marker in RECORD_CODEC_HEADER.read_text(encoding="utf-8"), f"bounded LZSS guard is missing: {marker}")

    save_manager = SAVE_MANAGER.read_text(encoding="utf-8")
    require("containerLoadFailed" in save_manager and "existedBeforeLoad" in save_manager, "Lua save manager does not distinguish fresh install from corrupt container")
    controller = V2_CHAPTER_CONTROLLER.read_text(encoding="utf-8")
    require("containerLoadFailed" in controller and "SAVE_RECOVERY_MESSAGE" in controller, "V2 controller does not surface native container recovery")

    test_script = RECORD_CODEC_TEST.read_text(encoding="utf-8")
    for marker in ("-fsanitize=address,undefined", "test_record_codec.cpp", "RecordCodec.cpp"):
        require(marker in test_script, f"native save durability test is missing: {marker}")

    width, height, _ = png_metadata(SAVE_RECOVERY_SCREENSHOT)
    require((width, height) == (1170, 2532), "save-recovery runtime screenshot dimensions drifted")
    require(SAVE_RECOVERY_SCREENSHOT.stat().st_size > 500_000, "save-recovery runtime screenshot appears incomplete")
    durability_doc = SAVE_DURABILITY_DOC.read_text(encoding="utf-8")
    for marker in ("V2-020 / P0", "截断为 7 字节", "995 字节合法容器", "ASan/UBSan"):
        require(marker in durability_doc, f"save-durability evidence is missing: {marker}")


def validate_toolchain_and_repository() -> None:
    output = subprocess.run(
        ["xcodebuild", "-version"],
        check=True,
        text=True,
        capture_output=True,
    ).stdout
    match = re.search(r"Xcode\s+(\d+)", output)
    require(match is not None and int(match.group(1)) >= 26, "App Store upload requires Xcode 26 or newer")

    tracked = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    ).stdout.split(b"\0")
    require(not any(path.endswith(b".DS_Store") for path in tracked), "tracked .DS_Store file found")


def main() -> None:
    validate_info_plist()
    validate_privacy_manifest()
    validate_app_icons()
    validate_project()
    validate_native_surface()
    validate_save_durability()
    validate_toolchain_and_repository()
    print("iOS release static validation passed")


if __name__ == "__main__":
    main()
