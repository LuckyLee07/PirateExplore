#!/usr/bin/env python3
"""Validate the prepared App Store Connect package and its external release gates."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/release/app-store-submission-manifest.json"
PROJECT = ROOT / "projects/ios_mac/NewPirate.xcodeproj/project.pbxproj"
INFO_PLIST = ROOT / "src/NewPirate/runtime/ios/Info.plist"
PRIVACY_MANIFEST = ROOT / "src/NewPirate/runtime/ios/PrivacyInfo.xcprivacy"
APP_LINKS = ROOT / "bin/res/scripts/LuaClass/V2ReleaseInfo.lua"

EXPECTED_DESCRIPTORS = {
    "parental_controls",
    "age_assurance",
    "unrestricted_web_access",
    "user_generated_content",
    "messaging_or_chat",
    "social_media",
    "advertising",
    "profanity_or_crude_humor",
    "horror_or_fear_themes",
    "alcohol_tobacco_or_drug_use",
    "medical_or_wellness_topics",
    "mature_or_suggestive_themes",
    "sexual_content_or_nudity",
    "graphic_sexual_content_or_nudity",
    "cartoon_or_fantasy_violence",
    "realistic_violence",
    "prolonged_graphic_or_sadistic_realistic_violence",
    "guns_or_other_weapons",
    "simulated_gambling",
    "contests",
    "gambling",
    "loot_boxes",
}
VALID_FREQUENCIES = {"none", "infrequent", "frequent"}
VALID_RATINGS = {"4+", "9+", "13+", "16+", "18+"}
PLACEHOLDER_MARKERS = ("TODO", "TBD", "待定", "待提供", "示例域名", "example.com", "{{", "}}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def load_json(path: Path) -> dict:
    require(path.is_file(), f"missing JSON file: {path.relative_to(ROOT)}")
    data = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(data, dict), f"JSON root must be an object: {path.relative_to(ROOT)}")
    return data


def repo_path(relative: str) -> Path:
    require(isinstance(relative, str) and relative, "manifest file reference is empty")
    candidate = (ROOT / relative).resolve()
    require(candidate == ROOT or ROOT in candidate.parents, f"manifest path escapes repository: {relative}")
    require(candidate.is_file(), f"manifest file reference is missing: {relative}")
    return candidate


def read_metadata_file(relative: str) -> str:
    source = repo_path(relative).read_text(encoding="utf-8")
    require(source == source.strip() + "\n", f"metadata file must end with exactly one newline: {relative}")
    value = source.strip()
    require(value, f"metadata file is empty: {relative}")
    for marker in PLACEHOLDER_MARKERS:
        require(marker not in value, f"metadata file contains placeholder {marker}: {relative}")
    return value


def public_https_url(value: object, field: str) -> str:
    require(isinstance(value, str) and value, f"{field} is empty")
    parsed = urlparse(value)
    host = (parsed.hostname or "").lower()
    require(parsed.scheme == "https" and bool(host), f"{field} is not a public HTTPS URL")
    reserved = (
        host == "localhost"
        or host.startswith("127.")
        or host in {"example.com", "example.org", "example.net"}
        or host.endswith((".invalid", ".localhost", ".test", ".example"))
    )
    require(not reserved and "{{" not in value, f"{field} uses a placeholder or reserved host")
    return value


def validate_candidate(manifest: dict) -> None:
    require(manifest.get("schema_version") == 1, "unsupported submission manifest schema")
    candidate = manifest.get("candidate", {})
    require(candidate.get("platform") == "iOS", "submission platform must be iOS")
    require(candidate.get("locale") == "zh-CN", "prepared locale must be zh-CN")
    require(candidate.get("app_name") == "海上探险家", "candidate app name drifted")
    require(candidate.get("bundle_id") == "com.fancyGame.NewPirate", "candidate bundle id drifted")
    require(candidate.get("marketing_version") == "2.0.0", "candidate version drifted")
    require(candidate.get("build_number") == "1", "candidate build number drifted")

    project = PROJECT.read_text(encoding="utf-8")
    require(project.count("PRODUCT_BUNDLE_IDENTIFIER = com.fancyGame.NewPirate;") == 2, "iOS bundle id build settings drifted")
    require(project.count("MARKETING_VERSION = 2.0.0;") == 2, "iOS marketing version build settings drifted")
    require(project.count("CURRENT_PROJECT_VERSION = 1;") == 2, "iOS build number settings drifted")

    with INFO_PLIST.open("rb") as handle:
        info = plistlib.load(handle)
    require(info.get("CFBundleDisplayName") == candidate["app_name"], "display name does not match submission manifest")
    require(info.get("ITSAppUsesNonExemptEncryption") is False, "encryption declaration does not match prepared answer")


def validate_product_page(manifest: dict) -> dict[str, int]:
    candidate = manifest["candidate"]
    product = manifest.get("product_page", {})
    name = product.get("name")
    subtitle = product.get("subtitle")
    require(name == candidate["app_name"], "product-page name does not match the candidate")
    require(isinstance(name, str) and 2 <= len(name) <= 30, "App Store name must contain 2-30 characters")
    require(isinstance(subtitle, str) and 1 <= len(subtitle) <= 30, "subtitle exceeds the 30-character limit")

    promotional = read_metadata_file(product.get("promotional_text_file"))
    description = read_metadata_file(product.get("description_file"))
    keywords_text = read_metadata_file(product.get("keywords_file"))

    require("\n" not in promotional, "promotional text must be a single paragraph")
    require(len(promotional) <= 170, "promotional text exceeds 170 characters")
    require(len(description) <= 4000, "description exceeds 4000 characters")
    require(re.search(r"^#{1,6}\s", description, flags=re.MULTILINE) is None, "description contains Markdown headings")
    require("**" not in description and "```" not in description, "description contains Markdown formatting")
    for marker in ("第一章", "舰炮战", "接舷战", "不包含广告", "抽卡"):
        require(marker in description, f"description is missing candidate-scope marker: {marker}")
    for unsupported in ("十六海域", "多人联机", "全球排行榜", "开放世界"):
        require(unsupported not in description, f"description claims an unsupported feature: {unsupported}")

    require("\n" not in keywords_text, "keywords must be stored on one line")
    require(len(keywords_text.encode("utf-8")) <= 100, "keywords exceed the 100-byte limit")
    keywords = [item.strip() for item in keywords_text.split(",")]
    require(all(keywords), "keywords contain an empty item")
    require(all(len(item) > 2 for item in keywords), "each keyword must contain more than two characters")
    require(len({item.casefold() for item in keywords}) == len(keywords), "keywords contain duplicates")
    require(name not in keywords_text, "keywords must not repeat the App name")

    require(product.get("primary_category") == "Games", "prepared primary category must remain Games")
    return {
        "name_characters": len(name),
        "subtitle_characters": len(subtitle),
        "promotional_characters": len(promotional),
        "description_characters": len(description),
        "keywords_bytes": len(keywords_text.encode("utf-8")),
    }


def validate_review_notes(manifest: dict) -> int:
    review = manifest.get("review", {})
    require(review.get("sign_in_required") is False, "candidate must remain usable without sign-in")
    require(review.get("demo_account") is None, "offline candidate must not invent a demo account")
    notes = read_metadata_file(review.get("notes_file"))
    note_bytes = len(notes.encode("utf-8"))
    require(note_bytes <= 4000, "review notes exceed 4000 UTF-8 bytes")
    for marker in (
        "无需注册或登录",
        "审核路径",
        "握住水晶瓶",
        "驶入第一片迷雾",
        "开始接舷",
        "隐私与支持",
        "不展示广告",
        "不提供应用内购买",
        "只保存在本机",
    ):
        require(marker in notes, f"review notes are missing: {marker}")
    for forbidden in ("QA 模式", "测试环境地址", "示例账号"):
        require(forbidden not in notes, f"review notes expose non-player review instructions: {forbidden}")
    return note_bytes


def validate_privacy(manifest: dict) -> None:
    privacy = manifest.get("privacy", {})
    require(privacy.get("tracking") is False, "submission manifest must declare no tracking")
    require(privacy.get("data_collected") is False, "submission manifest must declare no collected data")
    with PRIVACY_MANIFEST.open("rb") as handle:
        bundled = plistlib.load(handle)
    require(bundled.get("NSPrivacyTracking") is False, "bundled privacy manifest enables tracking")
    require(bundled.get("NSPrivacyTrackingDomains") == [], "bundled privacy manifest has tracking domains")
    require(bundled.get("NSPrivacyCollectedDataTypes") == [], "bundled privacy manifest declares collected data")


def validate_age_rating(manifest: dict) -> None:
    age = manifest.get("age_rating", {})
    inventory = load_json(repo_path(age.get("inventory_file")))
    require(inventory.get("schema_version") == 1, "unsupported age-rating inventory schema")
    require(inventory.get("candidate_version") == manifest["candidate"]["marketing_version"], "age-rating inventory version drifted")
    descriptors = inventory.get("descriptors", {})
    require(set(descriptors) == EXPECTED_DESCRIPTORS, "age-rating descriptor inventory is incomplete or contains unknown keys")
    for key, entry in descriptors.items():
        require(entry.get("frequency") in VALID_FREQUENCIES, f"invalid age-rating frequency: {key}")
        require(isinstance(entry.get("owner_confirmation_required"), bool), f"missing owner-confirmation flag: {key}")
        require(isinstance(entry.get("evidence"), str) and entry["evidence"].strip(), f"missing age-rating evidence: {key}")

    conservative = {
        "horror_or_fear_themes": "frequent",
        "cartoon_or_fantasy_violence": "frequent",
        "guns_or_other_weapons": "frequent",
        "simulated_gambling": "none",
        "gambling": "none",
        "loot_boxes": "none",
    }
    for key, expected in conservative.items():
        require(descriptors[key]["frequency"] == expected, f"conservative content rating drifted: {key}")

    inference = inventory.get("rating_inference", {})
    require(inference.get("expected_minimum_on_ios_26") == "13+", "age-rating inference must remain the conservative 13+ baseline")
    require(
        inference.get("made_for_kids_selected") == age.get("made_for_kids_selected"),
        "Made for Kids state differs between the content inventory and submission manifest",
    )
    require(
        inference.get("owner_content_confirmation") == age.get("content_inventory_confirmed_by_owner"),
        "owner confirmation differs between the content inventory and submission manifest",
    )
    require(age.get("expected_minimum_on_ios_26") == "13+", "submission manifest age-rating baseline drifted")


def validate_assets(manifest: dict) -> None:
    assets = manifest.get("assets", {})
    screenshot_manifest = load_json(repo_path(assets.get("screenshot_manifest")))
    require(screenshot_manifest.get("locale") == manifest["candidate"]["locale"], "screenshot locale does not match submission locale")
    source = screenshot_manifest.get("source_build", {})
    require(source.get("bundle_id") == manifest["candidate"]["bundle_id"], "screenshot bundle id drifted")
    require(source.get("marketing_version") == manifest["candidate"]["marketing_version"], "screenshot version drifted")
    require(source.get("build_number") == manifest["candidate"]["build_number"], "screenshot build number drifted")
    groups = {entry.get("id") for entry in screenshot_manifest.get("groups", [])}
    require(groups == set(assets.get("screenshot_groups", [])) == {"iphone-6.9", "ipad-13"}, "submission screenshot groups drifted")
    repo_path(assets.get("app_icon_catalog"))


def pending_release_gates(manifest: dict) -> list[str]:
    app_record = manifest["app_record"]
    product = manifest["product_page"]
    review = manifest["review"]
    privacy = manifest["privacy"]
    age = manifest["age_rating"]
    export = manifest["export_compliance"]
    distribution = manifest["distribution"]
    availability = manifest["availability"]
    checks = (
        ("app_record.apple_id", isinstance(app_record.get("apple_id"), str) and bool(app_record.get("apple_id"))),
        ("app_record.sku", isinstance(app_record.get("sku"), str) and bool(app_record.get("sku"))),
        ("app_record.bundle_id_verified_in_team", app_record.get("bundle_id_verified_in_team") is True),
        ("app_record.name_available_in_storefront", app_record.get("name_available_in_storefront") is True),
        ("product_page.privacy_policy_url", isinstance(product.get("privacy_policy_url"), str) and bool(product.get("privacy_policy_url"))),
        ("product_page.support_url", isinstance(product.get("support_url"), str) and bool(product.get("support_url"))),
        ("product_page.copyright", isinstance(product.get("copyright"), str) and bool(product.get("copyright"))),
        ("product_page.primary_category_confirmed", product.get("primary_category_confirmed") is True),
        ("product_page.game_subcategories", isinstance(product.get("game_subcategories"), list) and bool(product.get("game_subcategories"))),
        ("product_page.price", product.get("price") is not None),
        ("review.contact_name", isinstance(review.get("contact_name"), str) and bool(review.get("contact_name"))),
        ("review.contact_email", isinstance(review.get("contact_email"), str) and bool(review.get("contact_email"))),
        ("review.contact_phone", isinstance(review.get("contact_phone"), str) and bool(review.get("contact_phone"))),
        ("review.build_selected_in_version", review.get("build_selected_in_version") is True),
        ("privacy.questionnaire_status", privacy.get("questionnaire_status") == "submitted"),
        ("privacy.testflight_network_review", privacy.get("testflight_network_review") == "passed"),
        ("age_rating.questionnaire_status", age.get("questionnaire_status") == "submitted"),
        ("age_rating.calculated_rating", age.get("calculated_rating") in VALID_RATINGS),
        ("age_rating.content_inventory_confirmed_by_owner", age.get("content_inventory_confirmed_by_owner") is True),
        ("age_rating.made_for_kids_selected", isinstance(age.get("made_for_kids_selected"), bool)),
        ("export_compliance.backend_questionnaire_status", export.get("backend_questionnaire_status") == "submitted"),
        ("distribution.developer_team_id", isinstance(distribution.get("developer_team_id"), str) and bool(distribution.get("developer_team_id"))),
        ("distribution.distribution_identity", isinstance(distribution.get("distribution_identity"), str) and bool(distribution.get("distribution_identity"))),
        ("distribution.app_store_profile", isinstance(distribution.get("app_store_profile"), str) and bool(distribution.get("app_store_profile"))),
        ("distribution.signed_archive", isinstance(distribution.get("signed_archive"), str) and bool(distribution.get("signed_archive"))),
        ("distribution.upload_build_id", isinstance(distribution.get("upload_build_id"), str) and bool(distribution.get("upload_build_id"))),
        ("distribution.upload_validation_status", distribution.get("upload_validation_status") == "passed"),
        ("availability.territories", isinstance(availability.get("territories"), list) and bool(availability.get("territories"))),
        ("availability.territories_confirmed", availability.get("territories_confirmed") is True),
        ("availability.release_option", isinstance(availability.get("release_option"), str) and bool(availability.get("release_option"))),
    )
    return [name for name, passed in checks if not passed]


def validate_strict(manifest: dict) -> None:
    pending = pending_release_gates(manifest)
    require(not pending, "strict submission gates remain open:\n  - " + "\n  - ".join(pending))

    app_record = manifest["app_record"]
    require(re.fullmatch(r"\d{6,}", app_record["apple_id"]) is not None, "Apple ID must be numeric")
    require(re.fullmatch(r"[A-Za-z0-9._-]+", app_record["sku"]) is not None, "SKU contains unsupported characters")

    product = manifest["product_page"]
    privacy_url = public_https_url(product["privacy_policy_url"], "privacy_policy_url")
    support_url = public_https_url(product["support_url"], "support_url")
    require(privacy_url != support_url, "privacy and support URLs must be distinct")
    require(re.fullmatch(r"\d{4}\s+.+", product["copyright"]) is not None, "copyright must be a year followed by the rights holder")

    review = manifest["review"]
    require(re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", review["contact_email"]) is not None, "review contact email is invalid")

    app_links = APP_LINKS.read_text(encoding="utf-8")
    for key, expected in (("PRIVACY_POLICY_URL", privacy_url), ("SUPPORT_URL", support_url)):
        match = re.search(rf'^\s*{key}\s*=\s*"([^"]+)"', app_links, flags=re.MULTILINE)
        require(match is not None and match.group(1) == expected, f"{key} does not match the submission manifest")

    distribution = manifest["distribution"]
    require(re.fullmatch(r"[A-Z0-9]{10}", distribution["developer_team_id"]) is not None, "developer team id must contain 10 characters")
    archive = (ROOT / distribution["signed_archive"]).resolve()
    require(ROOT in archive.parents, "signed archive path escapes repository")
    require(archive.is_dir() and archive.suffix == ".xcarchive", "signed archive reference must point to an existing xcarchive")
    with (archive / "Info.plist").open("rb") as handle:
        archive_info = plistlib.load(handle)
    properties = archive_info.get("ApplicationProperties", {})
    app_relative = properties.get("ApplicationPath")
    require(isinstance(app_relative, str) and app_relative, "xcarchive has no application path")
    app = archive / app_relative
    require(app.is_dir(), "xcarchive application bundle is missing")
    require((app / "_CodeSignature").is_dir(), "xcarchive application has no code signature")
    require((app / "embedded.mobileprovision").is_file(), "xcarchive application has no provisioning profile")
    signature = subprocess.run(
        ["codesign", "--verify", "--deep", "--strict", str(app)],
        text=True,
        capture_output=True,
    )
    require(signature.returncode == 0, "xcarchive code signature verification failed: " + signature.stderr.strip())

    territories = set(manifest["availability"]["territories"])
    if territories.intersection({"CN", "CHN", "China mainland", "中国大陆"}):
        require(manifest["availability"].get("mainland_china_compliance") is not None, "China mainland availability needs a compliance decision")
    if territories.intersection({"KR", "KOR", "South Korea", "韩国"}):
        require(manifest["availability"].get("korea_compliance") is not None, "Korea availability needs a compliance decision")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true", help="require account, legal, signing, upload and backend evidence")
    args = parser.parse_args()

    manifest = load_json(MANIFEST)
    validate_candidate(manifest)
    sizes = validate_product_page(manifest)
    review_note_bytes = validate_review_notes(manifest)
    validate_privacy(manifest)
    validate_age_rating(manifest)
    validate_assets(manifest)

    if args.strict:
        validate_strict(manifest)
        print("App Store submission strict validation passed")
        return

    pending = pending_release_gates(manifest)
    size_summary = ", ".join(f"{key}={value}" for key, value in sizes.items())
    print(f"App Store submission preparation passed: {size_summary}, review_notes_bytes={review_note_bytes}")
    print(f"External submission gates remain open ({len(pending)}): " + ", ".join(pending))


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, UnicodeError, json.JSONDecodeError) as error:
        print(f"App Store submission validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
