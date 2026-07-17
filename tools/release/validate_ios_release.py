#!/usr/bin/env python3
"""Static release checks for the NewPirate V2 iOS target."""

from __future__ import annotations

import csv
import json
import plistlib
import re
import struct
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True

from archive_provenance import ProvenanceError, validate_record_shape


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
CCDATA = ROOT / "src/engine/cocos2d-x/cocos/base/CCData.cpp"
CCDATA_TEST = ROOT / "tools/release/test_ccdata_ownership.sh"
NATIVE_MEMORY_DOC = ROOT / "docs/release/native-memory-safety-iteration-1.md"
FILEUTILS = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/CCFileUtils.cpp"
FILEUTILS_READER = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/CCFileUtilsRead.h"
FILEUTILS_TEST = ROOT / "tools/release/test_fileutils_read.sh"
FILEUTILS_TEST_SOURCE = ROOT / "tools/release/test_fileutils_read.cpp"
FILEUTILS_DOC = ROOT / "docs/release/fileutils-read-safety-iteration-1.md"
USERDEFAULT = ROOT / "src/engine/cocos2d-x/cocos/2d/CCUserDefault.mm"
USERDEFAULT_XML = ROOT / "src/engine/cocos2d-x/cocos/2d/CCUserDefaultXML.h"
USERDEFAULT_XML_TEST = ROOT / "tools/release/test_userdefault_xml.sh"
USERDEFAULT_XML_TEST_SOURCE = ROOT / "tools/release/test_userdefault_xml.cpp"
USERDEFAULT_XML_FIXTURE = ROOT / "tools/release/fixtures/userdefault-legacy-migration.xml"
USERDEFAULT_XML_DOC = ROOT / "docs/release/userdefault-xml-ownership-iteration-1.md"
USERDEFAULT_XML_SCREENSHOT = ROOT / "docs/release/userdefault-xml-migration-player.png"
TEXTURE_ATLAS = ROOT / "src/engine/cocos2d-x/cocos/2d/CCTextureAtlas.cpp"
TEXTURE_ATLAS_ALLOCATION = ROOT / "src/engine/cocos2d-x/cocos/2d/CCTextureAtlasAllocation.h"
TEXTURE_ATLAS_TEST = ROOT / "tools/release/test_texture_atlas_allocation.sh"
TEXTURE_ATLAS_TEST_SOURCE = ROOT / "tools/release/test_texture_atlas_allocation.cpp"
TEXTURE_ATLAS_DOC = ROOT / "docs/release/texture-atlas-allocation-iteration-1.md"
TEXTURE_ATLAS_SCREENSHOT = ROOT / "docs/release/texture-atlas-render-player.png"
EAGLVIEW_HEADER = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCEAGLView.h"
EAGLVIEW = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCEAGLView.mm"
EAGLVIEW_TEST = ROOT / "tools/release/test_eaglview_contract.py"
EAGLVIEW_DOC = ROOT / "docs/release/eaglview-ime-contract-iteration-1.md"
EAGLVIEW_SCREENSHOT = ROOT / "docs/release/eaglview-lifecycle-player.png"
APPLE_SIGNING_AUDIT = ROOT / "tools/release/apple_signing_readiness.py"
APPLE_SIGNING_AUDIT_TEST = ROOT / "tools/release/test_apple_signing_readiness.py"
APPLE_SIGNING_AUDIT_DOC = ROOT / "docs/release/apple-signing-readiness-iteration-2.md"
APPLE_DEVICE_STABILITY_DOC = ROOT / "docs/release/apple-device-stability-iteration-1.md"
SIGNED_APP_VALIDATOR = ROOT / "tools/release/validate_ios_signed_app.py"
SIGNED_APP_VALIDATOR_TEST = ROOT / "tools/release/test_validate_ios_signed_app.py"
SIGNED_APP_VALIDATOR_DOC = ROOT / "docs/release/signed-app-integrity-iteration-1.md"
FINAL_APP_STORE_GATE = ROOT / "tools/release/final_app_store_gate.py"
FINAL_APP_STORE_GATE_TEST = ROOT / "tools/release/test_final_app_store_gate.py"
FINAL_APP_STORE_GATE_DOC = ROOT / "docs/release/final-app-store-gate-iteration-1.md"
DEVICE_ACCEPTANCE_VALIDATOR = ROOT / "tools/release/validate_device_acceptance.py"
DEVICE_ACCEPTANCE_TEST = ROOT / "tools/release/test_validate_device_acceptance.py"
DEVICE_ACCEPTANCE_TEMPLATE = ROOT / "docs/release/device-acceptance-template.csv"
DEVICE_ACCEPTANCE_DOC = ROOT / "docs/release/device-acceptance-evidence-iteration-1.md"
FINAL_PRODUCT_LAUNCH_GATE = ROOT / "tools/release/final_product_launch_gate.py"
FINAL_PRODUCT_LAUNCH_GATE_TEST = ROOT / "tools/release/test_final_product_launch_gate.py"
PRODUCT_LAUNCH_MANIFEST = ROOT / "docs/release/product-launch-manifest.json"
FINAL_PRODUCT_LAUNCH_DOC = ROOT / "docs/release/final-product-launch-gate-iteration-1.md"
XCODE_SCRIPT = ROOT / "xcode.sh"
ARCHIVE_PROVENANCE = ROOT / "tools/release/archive_provenance.py"
ARCHIVE_PROVENANCE_TEST = ROOT / "tools/release/test_archive_provenance.py"
ARCHIVE_VALIDATOR = ROOT / "tools/release/validate_ios_archive.py"
ARCHIVE_PROVENANCE_DOC = ROOT / "docs/release/archive-provenance-iteration-1.md"
INTERNAL_CANDIDATE_RECORD = ROOT / "docs/release/internal-candidate-provenance-2.0.0-1.json"
INTERNAL_CANDIDATE_DOC = ROOT / "docs/release/internal-candidate-freeze-iteration-1.md"


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
    require(info.get("NewPirateCandidateID") == "$(NEWPIRATE_CANDIDATE_ID)", "candidate ID must come from build settings")
    require(info.get("NewPirateSourceCommit") == "$(NEWPIRATE_SOURCE_COMMIT)", "source commit must come from build settings")
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


def validate_native_memory_safety() -> None:
    for path in (CCDATA, CCDATA_TEST, NATIVE_MEMORY_DOC):
        require(path.is_file(), f"native-memory component is missing: {path.relative_to(ROOT)}")

    ccdata = CCDATA.read_text(encoding="utf-8")
    for marker in (
        "if (this != &other)",
        "clear();\n        move(other);",
        "Allocate and copy before releasing the current buffer",
        "unsigned char* copiedBytes",
        "if (bytes == _bytes)",
        "fastSet transfers ownership",
    ):
        require(marker in ccdata, f"CCData ownership guard is missing: {marker}")

    test_script = CCDATA_TEST.read_text(encoding="utf-8")
    for marker in ("-fsanitize=address,undefined", "test_ccdata_ownership.cpp", "CCData.cpp"):
        require(marker in test_script, f"CCData ownership sanitizer test is missing: {marker}")
    test_source = (ROOT / "tools/release/test_ccdata_ownership.cpp").read_text(encoding="utf-8")
    for marker in (
        "data = data",
        "data.copy(data.getBytes(), data.getSize())",
        "data.fastSet(data.getBytes(), data.getSize())",
        "target = std::move(data)",
        "target = std::move(target)",
        "__asan_address_is_poisoned",
    ):
        require(marker in test_source, f"CCData ownership regression case is missing: {marker}")

    memory_doc = NATIVE_MEMORY_DOC.read_text(encoding="utf-8")
    for marker in ("V2-021 / P1", "xcodebuild", "Use of memory after it is freed", "ASan/UBSan"):
        require(marker in memory_doc, f"native-memory evidence is missing: {marker}")


def validate_file_read_safety() -> None:
    for path in (FILEUTILS, FILEUTILS_READER, FILEUTILS_TEST, FILEUTILS_TEST_SOURCE, FILEUTILS_DOC):
        require(path.is_file(), f"file-read component is missing: {path.relative_to(ROOT)}")

    fileutils = FILEUTILS.read_text(encoding="utf-8")
    for marker in (
        '#include "CCFileUtilsRead.h"',
        "fileutils_detail::readFile(",
        "std::numeric_limits<ssize_t>::max()",
        "if (!succeeded)",
        "buffer != nullptr && size > 0",
    ):
        require(marker in fileutils, f"FileUtils safe-read integration is missing: {marker}")

    reader = FILEUTILS_READER.read_text(encoding="utf-8")
    for marker in (
        "endPosition < 0",
        "fileSize > maximumSize",
        "fileSize == 0",
        "buffer == nullptr",
        "std::fread(buffer, 1, fileSize, file) != fileSize",
        "std::free(buffer)",
        "std::fclose(file)",
    ):
        require(marker in reader, f"bounded file reader guard is missing: {marker}")

    test_script = FILEUTILS_TEST.read_text(encoding="utf-8")
    for marker in ("-fsanitize=address,undefined", "-Werror", "test_fileutils_read.cpp"):
        require(marker in test_script, f"FileUtils sanitizer test is missing: {marker}")
    test_source = FILEUTILS_TEST_SOURCE.read_text(encoding="utf-8")
    for marker in (
        "empty file must be a valid empty result",
        "text result must be null terminated",
        "maximum size must reject oversized input before allocation",
        "allocation failure must be reported safely",
        "missing input must fail",
        "directory input must not be treated as an empty regular file",
    ):
        require(marker in test_source, f"FileUtils regression case is missing: {marker}")

    read_doc = FILEUTILS_DOC.read_text(encoding="utf-8")
    for marker in ("V2-022 / P1", "CCFileUtils.plist", "ASan/UBSan", "ftell"):
        require(marker in read_doc, f"file-read evidence is missing: {marker}")


def validate_userdefault_xml_ownership() -> None:
    paths = (
        USERDEFAULT,
        USERDEFAULT_XML,
        USERDEFAULT_XML_TEST,
        USERDEFAULT_XML_TEST_SOURCE,
        USERDEFAULT_XML_FIXTURE,
        USERDEFAULT_XML_DOC,
        USERDEFAULT_XML_SCREENSHOT,
    )
    for path in paths:
        require(path.is_file(), f"UserDefault XML component is missing: {path.relative_to(ROOT)}")

    userdefault = USERDEFAULT.read_text(encoding="utf-8")
    for marker in (
        '#import "CCUserDefaultXML.h"',
        "LegacyXMLLookup lookup = getXMLNodeForKey(pKey)",
        "unsigned char * decodedData = nullptr",
        "deleteNode(lookup)",
    ):
        require(marker in userdefault, f"UserDefault XML integration is missing: {marker}")

    ownership = USERDEFAULT_XML.read_text(encoding="utf-8")
    for marker in (
        "std::unique_ptr<tinyxml2::XMLDocument>",
        "LegacyXMLStatus::KeyNotFound",
        "LegacyXMLLookup(const LegacyXMLLookup&) = delete",
        "static LegacyXMLLookup parse",
        "removeNodeAndSave",
    ):
        require(marker in ownership, f"UserDefault XML ownership guard is missing: {marker}")

    test_script = USERDEFAULT_XML_TEST.read_text(encoding="utf-8")
    for marker in ("-fsanitize=address,undefined", "-Werror", "test_userdefault_xml.cpp"):
        require(marker in test_script, f"UserDefault XML sanitizer test is missing: {marker}")
    test_source = USERDEFAULT_XML_TEST_SOURCE.read_text(encoding="utf-8")
    for marker in (
        "missing key must not retain the parsed document",
        "migrated key must be removed from legacy XML",
        "unrelated legacy keys must remain",
        "index < 20000",
    ):
        require(marker in test_source, f"UserDefault XML regression case is missing: {marker}")

    fixture = USERDEFAULT_XML_FIXTURE.read_text(encoding="utf-8")
    require("<kItWasChangeData>true</kItWasChangeData>" in fixture, "legacy migration fixture lost its startup key")
    require("<unrelatedKey>kept</unrelatedKey>" in fixture, "legacy migration fixture lost its preserved key")

    ownership_doc = USERDEFAULT_XML_DOC.read_text(encoding="utf-8")
    for marker in ("V2-023 / P1", "CCUserDefault", "ASan/UBSan", "20,000", "userdefault-xml-migration-player.png"):
        require(marker in ownership_doc, f"UserDefault XML evidence is missing: {marker}")
    width, height, _ = png_metadata(USERDEFAULT_XML_SCREENSHOT)
    require((width, height) == (1170, 2532), "UserDefault migration screenshot dimensions drifted")
    require(USERDEFAULT_XML_SCREENSHOT.stat().st_size > 500_000, "UserDefault migration screenshot appears incomplete")


def validate_texture_atlas_allocation() -> None:
    paths = (
        TEXTURE_ATLAS,
        TEXTURE_ATLAS_ALLOCATION,
        TEXTURE_ATLAS_TEST,
        TEXTURE_ATLAS_TEST_SOURCE,
        TEXTURE_ATLAS_DOC,
        TEXTURE_ATLAS_SCREENSHOT,
    )
    for path in paths:
        require(path.is_file(), f"TextureAtlas allocation component is missing: {path.relative_to(ROOT)}")

    atlas = TEXTURE_ATLAS.read_text(encoding="utf-8")
    for marker in (
        '#include "CCTextureAtlasAllocation.h"',
        "textureatlas_detail::allocateAtlasBuffers(_capacity, &_quads, &_indices)",
        "CC_SAFE_RELEASE_NULL(_texture)",
    ):
        require(marker in atlas, f"TextureAtlas bounded allocation integration is missing: {marker}")

    allocation = TEXTURE_ATLAS_ALLOCATION.read_text(encoding="utf-8")
    for marker in (
        "capacity < 0",
        "count == 0",
        "maximumQuads",
        "checkedMultiply",
        "std::free(allocatedQuads)",
        "std::memset(allocatedQuads, 0, quadBytes)",
    ):
        require(marker in allocation, f"TextureAtlas allocation guard is missing: {marker}")

    test_script = TEXTURE_ATLAS_TEST.read_text(encoding="utf-8")
    for marker in ("-fsanitize=address,undefined", "-Werror", "test_texture_atlas_allocation.cpp"):
        require(marker in test_script, f"TextureAtlas sanitizer test is missing: {marker}")
    test_source = TEXTURE_ATLAS_TEST_SOURCE.read_text(encoding="utf-8")
    for marker in (
        "zero capacity must not call malloc(0)",
        "negative capacity must be rejected in release builds",
        "partial allocation must release the first buffer",
        "capacity beyond 16-bit vertex indices must be rejected",
    ):
        require(marker in test_source, f"TextureAtlas regression case is missing: {marker}")

    atlas_doc = TEXTURE_ATLAS_DOC.read_text(encoding="utf-8")
    for marker in ("V2-024 / P1", "CCTextureAtlas.plist", "ASan/UBSan", "16,384"):
        require(marker in atlas_doc, f"TextureAtlas allocation evidence is missing: {marker}")
    width, height, _ = png_metadata(TEXTURE_ATLAS_SCREENSHOT)
    require((width, height) == (1170, 2532), "TextureAtlas runtime screenshot dimensions drifted")
    require(TEXTURE_ATLAS_SCREENSHOT.stat().st_size > 500_000, "TextureAtlas runtime screenshot appears incomplete")


def validate_eaglview_contract() -> None:
    paths = (
        EAGLVIEW_HEADER,
        EAGLVIEW,
        EAGLVIEW_TEST,
        EAGLVIEW_DOC,
        EAGLVIEW_SCREENSHOT,
    )
    for path in paths:
        require(path.is_file(), f"CCEAGLView contract component is missing: {path.relative_to(ROOT)}")

    header = EAGLVIEW_HEADER.read_text(encoding="utf-8")
    for marker in (
        "NSDictionary *          markedTextStyle_;",
        "@property (nonatomic, copy) NSDictionary *markedTextStyle;",
    ):
        require(marker in header, f"CCEAGLView header contract is missing: {marker}")

    view = EAGLVIEW.read_text(encoding="utf-8")
    for marker in (
        "@synthesize markedTextStyle = markedTextStyle_;",
        "[[NSNotificationCenter defaultCenter] removeObserver:self]",
        "[markedText_ release]",
        "[markedTextStyle_ release]",
        "markedTextStyle_ = [markedTextStyle copy]",
        "return [NSArray array];",
    ):
        require(marker in view, f"CCEAGLView implementation contract is missing: {marker}")

    test = EAGLVIEW_TEST.read_text(encoding="utf-8")
    for marker in (
        "dealloc ownership cleanup is missing",
        "style replacement must honor the copy property",
        "UITextInput selection rect contract must return a non-null array",
    ):
        require(marker in test, f"CCEAGLView source regression is missing: {marker}")

    evidence = EAGLVIEW_DOC.read_text(encoding="utf-8")
    for marker in ("V2-025 / P1", "CCEAGLView.plist", "diagnostics", "UITextInput"):
        require(marker in evidence, f"CCEAGLView evidence is missing: {marker}")
    width, height, _ = png_metadata(EAGLVIEW_SCREENSHOT)
    require((width, height) == (1170, 2532), "CCEAGLView runtime screenshot dimensions drifted")
    require(EAGLVIEW_SCREENSHOT.stat().st_size > 500_000, "CCEAGLView runtime screenshot appears incomplete")


def validate_apple_signing_readiness_audit() -> None:
    for path in (
        APPLE_SIGNING_AUDIT,
        APPLE_SIGNING_AUDIT_TEST,
        APPLE_SIGNING_AUDIT_DOC,
        APPLE_DEVICE_STABILITY_DOC,
    ):
        require(path.is_file(), f"Apple signing readiness component is missing: {path.relative_to(ROOT)}")

    audit = APPLE_SIGNING_AUDIT.read_text(encoding="utf-8")
    for marker in (
        '"security", "find-identity"',
        '"security", "find-certificate"',
        '"security", "cms"',
        '"xcrun",\n                "devicectl"',
        "DEVELOPMENT_TEAM",
        "certificate_fingerprints",
        "--require-development",
        "--require-distribution",
        '"--json-output"',
        "TemporaryDirectory",
        "minimum_samples = 3",
        "audit_key",
        "ddiServicesAvailable",
    ):
        require(marker in audit, f"Apple signing readiness audit is missing: {marker}")

    regression = APPLE_SIGNING_AUDIT_TEST.read_text(encoding="utf-8")
    for marker in (
        "wildcard profile must match",
        "expired identity must not pass development",
        "profile certificate without private key matched",
        "blocked chain must explain all four gaps",
        "flapping device passed stability",
        "raw CoreDevice identifier leaked into report",
        "duplicate rows passed consecutive samples",
    ):
        require(marker in regression, f"Apple signing readiness regression is missing: {marker}")

    evidence = APPLE_SIGNING_AUDIT_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-026 / P1",
        "find-identity",
        "2027-04-19",
        "24U7H6TL68",
        "distribution_ready: false",
    ):
        require(marker in evidence, f"Apple signing readiness evidence is missing: {marker}")

    stability_evidence = APPLE_DEVICE_STABILITY_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-027 / P1",
        "jsonVersion",
        "device_sample_count: 3",
        "serialNumber",
        "退出码 2",
    ):
        require(marker in stability_evidence, f"Apple device stability evidence is missing: {marker}")


def validate_signed_app_validator() -> None:
    for path in (SIGNED_APP_VALIDATOR, SIGNED_APP_VALIDATOR_TEST, SIGNED_APP_VALIDATOR_DOC):
        require(path.is_file(), f"signed-app validator component is missing: {path.relative_to(ROOT)}")

    validator = SIGNED_APP_VALIDATOR.read_text(encoding="utf-8")
    for marker in (
        "codesign",
        "--verify",
        "--extract-certificates=",
        "certificate_expiration",
        "embedded.mobileprovision",
        "get-task-allow",
        "App Store profile must not contain provisioned devices",
        "signing leaf certificate is not embedded in the profile",
        'choices=("development", "distribution")',
    ):
        require(marker in validator, f"signed-app validator is missing: {marker}")

    regression = SIGNED_APP_VALIDATOR_TEST.read_text(encoding="utf-8")
    for marker in (
        "valid development app failed",
        "valid App Store app failed",
        "wrong signing team passed",
        "leaf certificate outside profile passed",
        "expired signing leaf certificate passed",
        "development payload passed App Store mode",
    ):
        require(marker in regression, f"signed-app regression is missing: {marker}")

    evidence = SIGNED_APP_VALIDATOR_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-028 / P1",
        "551AA974D457F137BFEE66838213D36FB327AF47",
        "passed: true",
        "退出码 2",
        "get-task-allow",
    ):
        require(marker in evidence, f"signed-app evidence is missing: {marker}")


def validate_final_app_store_gate() -> None:
    for path in (FINAL_APP_STORE_GATE, FINAL_APP_STORE_GATE_TEST, FINAL_APP_STORE_GATE_DOC):
        require(path.is_file(), f"final App Store gate component is missing: {path.relative_to(ROOT)}")

    gate = FINAL_APP_STORE_GATE.read_text(encoding="utf-8")
    for marker in (
        "pending_release_gates",
        "submission_manifest_strict",
        "public_pages_live",
        "archive_content",
        "signed_app_distribution",
        "ready_for_submission",
        "external manifest gates must be complete before final checks run",
    ):
        require(marker in gate, f"final App Store gate is missing: {marker}")

    regression = FINAL_APP_STORE_GATE_TEST.read_text(encoding="utf-8")
    for marker in (
        "pending distribution grouping drifted",
        "an empty final check list passed",
        "one failed final check still produced GO",
        "one skipped final check still produced GO",
    ):
        require(marker in regression, f"final App Store gate regression is missing: {marker}")

    submission = (ROOT / "tools/release/validate_app_store_submission.py").read_text(encoding="utf-8")
    for marker in (
        "validate_ios_signed_app.py",
        '"--mode",\n            "distribution"',
        "xcarchive app is not a valid App Store distribution payload",
    ):
        require(marker in submission, f"strict submission validator is missing: {marker}")

    evidence = FINAL_APP_STORE_GATE_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-029 / P1",
        "pending_gate_count: 30",
        "ready_for_submission: false",
        "public_pages_live",
        "退出码 2",
    ):
        require(marker in evidence, f"final App Store gate evidence is missing: {marker}")


def validate_device_acceptance_gate() -> None:
    for path in (
        DEVICE_ACCEPTANCE_VALIDATOR,
        DEVICE_ACCEPTANCE_TEST,
        DEVICE_ACCEPTANCE_TEMPLATE,
        DEVICE_ACCEPTANCE_DOC,
    ):
        require(path.is_file(), f"device acceptance component is missing: {path.relative_to(ROOT)}")

    validator = DEVICE_ACCEPTANCE_VALIDATOR.read_text(encoding="utf-8")
    for marker in (
        "low_end_iphone",
        "modern_iphone",
        "ipad",
        "require_testflight",
        "app_store_build_id",
        "does not match submission candidate",
        "thermal_duration_min",
        "ready_for_device_release",
        "failed device evidence requires issue_ids",
        "build_commit does not identify a repository commit",
    ):
        require(marker in validator, f"device acceptance validator is missing: {marker}")

    with DEVICE_ACCEPTANCE_TEMPLATE.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = set(reader.fieldnames or [])
        rows = list(reader)
    for field in (
        "device_role",
        "build_commit",
        "distribution_channel",
        "silent_switch",
        "voyage_frame_rate",
        "save_recovery",
        "evidence_notes",
    ):
        require(field in fields, f"device acceptance template is missing: {field}")
    require(not rows, "device acceptance template must not contain fabricated physical-device results")

    evidence = DEVICE_ACCEPTANCE_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-031 / P1",
        "ready_for_device_release: false",
        "low_end_iphone",
        "modern_iphone",
        "TestFlight",
        "零记录",
    ):
        require(marker in evidence, f"device acceptance evidence is missing: {marker}")


def validate_final_product_launch_gate() -> None:
    for path in (
        FINAL_PRODUCT_LAUNCH_GATE,
        FINAL_PRODUCT_LAUNCH_GATE_TEST,
        PRODUCT_LAUNCH_MANIFEST,
        FINAL_PRODUCT_LAUNCH_DOC,
    ):
        require(path.is_file(), f"final product launch component is missing: {path.relative_to(ROOT)}")

    gate = FINAL_PRODUCT_LAUNCH_GATE.read_text(encoding="utf-8")
    for marker in (
        "pending_release_gates",
        "internal_release_regression",
        "external_user_evidence",
        "device_acceptance_testflight",
        "app_store_submission",
        "candidate_consistency",
        "release_commit does not include the frozen external R2 build",
        "product_launch_ready",
    ):
        require(marker in gate, f"final product launch gate is missing: {marker}")

    regression = FINAL_PRODUCT_LAUNCH_GATE_TEST.read_text(encoding="utf-8")
    for marker in (
        "47 grouped blockers",
        "an empty overall check list passed",
        "a missing overall check still produced GO",
        "one failed overall check still produced GO",
        "one skipped overall check still produced GO",
    ):
        require(marker in regression, f"final product launch regression is missing: {marker}")

    manifest = json.loads(PRODUCT_LAUNCH_MANIFEST.read_text(encoding="utf-8"))
    require(manifest.get("schema_version") == 1, "product launch manifest schema drifted")
    require(manifest.get("candidate", {}).get("release_commit") is None, "release commit was filled without final evidence")
    require(
        manifest.get("evidence", {}).get("external_test_records") is None
        and manifest.get("evidence", {}).get("device_acceptance_records") is None,
        "product launch evidence paths were filled without real records",
    )
    require(manifest.get("decision", {}).get("phase4_status") == "HOLD", "product launch decision is not HOLD")

    evidence = FINAL_PRODUCT_LAUNCH_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-032 / P1",
        "pending_gate_count: 47",
        "product_launch_ready: false",
        "issue_register: 4",
        "退出码 2",
    ):
        require(marker in evidence, f"final product launch evidence is missing: {marker}")


def validate_archive_provenance() -> None:
    for path in (
        XCODE_SCRIPT,
        ARCHIVE_PROVENANCE,
        ARCHIVE_PROVENANCE_TEST,
        ARCHIVE_VALIDATOR,
        ARCHIVE_PROVENANCE_DOC,
        INTERNAL_CANDIDATE_RECORD,
        INTERNAL_CANDIDATE_DOC,
    ):
        require(path.is_file(), f"archive provenance component is missing: {path.relative_to(ROOT)}")

    xcode_script = XCODE_SCRIPT.read_text(encoding="utf-8")
    for marker in (
        "NEWPIRATE_SOURCE_COMMIT",
        "NEWPIRATE_CANDIDATE_ID",
        "HEAD-dirty",
        "diff --cached --quiet",
        '"${IOS_PROVENANCE_SETTINGS[@]}"',
    ):
        require(marker in xcode_script, f"Xcode provenance wiring is missing: {marker}")

    provenance = ARCHIVE_PROVENANCE.read_text(encoding="utf-8")
    for marker in (
        "NewPirateSourceCommit",
        "NewPirateCandidateID",
        "dirty source cannot be recorded as a frozen candidate",
        "archive executable and dSYM UUIDs do not match",
        "tracked worktree must be clean",
        "executable",
        "info_plist_sha256",
    ):
        require(marker in provenance, f"archive provenance validator is missing: {marker}")

    regression = ARCHIVE_PROVENANCE_TEST.read_text(encoding="utf-8")
    for marker in (
        "dirty source",
        "source commit mismatch",
        "candidate ID mismatch",
        "does not identify",
        "bad candidate",
    ):
        require(marker in regression, f"archive provenance regression is missing: {marker}")

    archive_validator = ARCHIVE_VALIDATOR.read_text(encoding="utf-8")
    for marker in (
        "--expected-source-commit",
        "--expected-candidate-id",
        "--require-clean-provenance",
        "validate_identity",
    ):
        require(marker in archive_validator, f"archive content validator lacks provenance enforcement: {marker}")

    evidence = ARCHIVE_PROVENANCE_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-037 / P1",
        "NewPirateSourceCommit",
        "NewPirateCandidateID",
        "NewPirate-provenance-iteration-1.xcarchive",
        "2.0.0-1-provenance-test",
        "预期拒绝",
        "30 项外部字段",
    ):
        require(marker in evidence, f"archive provenance evidence is missing: {marker}")

    try:
        record = validate_record_shape(
            json.loads(INTERNAL_CANDIDATE_RECORD.read_text(encoding="utf-8"))
        )
    except (OSError, UnicodeError, json.JSONDecodeError, ProvenanceError) as error:
        raise AssertionError(f"internal candidate record is invalid: {error}") from error
    require(record["candidate_id"] == "2.0.0-1-internal", "internal candidate ID drifted")
    require(
        record["source_commit"] == "e6dc27f2d03681d45582c88ad8dd70628f55a650",
        "internal candidate source commit drifted",
    )
    ancestry = subprocess.run(
        ["git", "merge-base", "--is-ancestor", record["source_commit"], "HEAD"],
        cwd=ROOT,
        check=False,
    )
    require(ancestry.returncode == 0, "internal candidate source commit is not in current history")

    candidate_evidence = INTERNAL_CANDIDATE_DOC.read_text(encoding="utf-8")
    for marker in (
        "V2-038 / P1",
        "2.0.0-1-internal",
        "e6dc27f2d03681d45582c88ad8dd70628f55a650",
        "1ccf65120976af304204bc0889081ea2259cba364178cc44bb3ba2c6ffc95beb",
        "609B891E-7C3C-3FA8-97E6-2A697E6BB57E",
        "--verify-record",
        "release_commit` 继续保持 `null",
    ):
        require(marker in candidate_evidence, f"internal candidate evidence is missing: {marker}")


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
    validate_native_memory_safety()
    validate_file_read_safety()
    validate_userdefault_xml_ownership()
    validate_texture_atlas_allocation()
    validate_eaglview_contract()
    validate_apple_signing_readiness_audit()
    validate_signed_app_validator()
    validate_final_app_store_gate()
    validate_device_acceptance_gate()
    validate_final_product_launch_gate()
    validate_archive_provenance()
    validate_toolchain_and_repository()
    print("iOS release static validation passed")


if __name__ == "__main__":
    main()
