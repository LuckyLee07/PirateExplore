#!/usr/bin/env python3
"""Validate public privacy/support templates and optionally their live URLs."""

from __future__ import annotations

import argparse
import re
import sys
import urllib.request
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_DIR = ROOT / "docs/release/public-pages/templates"
APP_LINKS = ROOT / "bin/res/scripts/LuaClass/V2ReleaseInfo.lua"
PLACEHOLDER_RE = re.compile(r"\{\{[A-Z0-9_]+\}\}")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def validate_https_url(url: str) -> str:
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    require(parsed.scheme == "https" and bool(host), f"not a public HTTPS URL: {url}")
    reserved = (
        host == "localhost"
        or host.startswith("127.")
        or host in {"example.com", "example.org", "example.net"}
        or host.endswith((".invalid", ".localhost", ".test", ".example"))
    )
    require(not reserved and "{{" not in url, f"placeholder or reserved public URL: {url}")
    return url


def validate_templates() -> None:
    expected = {
        "privacy-policy.zh-CN.html": {
            "{{APP_NAME}}", "{{APP_VERSION}}", "{{LEGAL_NAME}}", "{{SUPPORT_EMAIL}}",
            "{{EFFECTIVE_DATE}}", "{{COPYRIGHT_YEAR}}", "{{PRIVACY_URL}}", "{{SUPPORT_URL}}",
        },
        "support.zh-CN.html": {
            "{{APP_NAME}}", "{{APP_VERSION}}", "{{LEGAL_NAME}}", "{{SUPPORT_EMAIL}}",
            "{{EFFECTIVE_DATE}}", "{{COPYRIGHT_YEAR}}", "{{PRIVACY_URL}}", "{{SUPPORT_URL}}",
        },
    }
    combined = ""
    for filename, placeholders in expected.items():
        path = TEMPLATE_DIR / filename
        require(path.is_file(), f"missing public-page template: {filename}")
        source = path.read_text(encoding="utf-8")
        require(set(PLACEHOLDER_RE.findall(source)) == placeholders, f"placeholder set drifted: {filename}")
        for marker in ('lang="zh-CN"', 'name="viewport"', "../assets/release.css"):
            require(marker in source, f"{filename} is missing {marker}")
        combined += source

    for marker in (
        "不收集、上传或向服务器传输个人数据",
        "删除并重装应用会删除这些本地数据",
        "不使用代表我们收集或处理个人数据的第三方 SDK",
        "邮件建议包含",
        "设备型号",
        "隐私政策",
    ):
        require(marker in combined, f"public release content is missing: {marker}")
    for forbidden in ("探险科技有限公司", "106134362", "1976428305@qq.com", "example.com"):
        require(forbidden not in combined, f"unverified legacy or example contact leaked into templates: {forbidden}")

    css = TEMPLATE_DIR / "release.css"
    require(css.is_file() and css.stat().st_size > 1200, "public release stylesheet is missing or incomplete")
    css_source = css.read_text(encoding="utf-8")
    for marker in ("min(calc(100% - 40px), 880px)", "@media (max-width: 680px)", ":focus-visible", "prefers-reduced-motion"):
        require(marker in css_source, f"public release stylesheet is missing: {marker}")


def validate_rendered_site(site_dir: Path) -> None:
    files = {
        "privacy": site_dir / "privacy/index.html",
        "support": site_dir / "support/index.html",
        "style": site_dir / "assets/release.css",
    }
    for name, path in files.items():
        require(path.is_file() and path.stat().st_size > 500, f"rendered {name} file is missing or incomplete: {path}")

    combined = files["privacy"].read_text(encoding="utf-8") + files["support"].read_text(encoding="utf-8")
    require(PLACEHOLDER_RE.search(combined) is None, "rendered public pages still contain placeholders")
    require("mailto:" in combined, "rendered support page has no email link")
    links = re.findall(r'href="(https://[^"#]+)"', combined)
    require(len(set(links)) >= 2, "rendered pages do not link both public destinations")
    for link in links:
        validate_https_url(link)


def configured_app_links() -> dict[str, str]:
    source = APP_LINKS.read_text(encoding="utf-8")
    links: dict[str, str] = {}
    for key, kind in (("PRIVACY_POLICY_URL", "privacy"), ("SUPPORT_URL", "support")):
        match = re.search(rf'^\s*{key}\s*=\s*"([^"]+)"', source, flags=re.MULTILINE)
        require(match is not None, f"{key} is not configured in V2ReleaseInfo.lua")
        links[kind] = validate_https_url(match.group(1))
    require(links["privacy"] != links["support"], "privacy and support URLs must be distinct pages")
    return links


def check_live_urls(links: dict[str, str]) -> None:
    for kind, url in links.items():
        request = urllib.request.Request(url, headers={"User-Agent": "NewPirate-release-preflight/1.0"})
        with urllib.request.urlopen(request, timeout=12) as response:
            require(response.status == 200, f"{kind} URL returned HTTP {response.status}")
            content_type = response.headers.get_content_type()
            require(content_type == "text/html", f"{kind} URL is not HTML: {content_type}")
            body = response.read(1_000_001)
            require(len(body) <= 1_000_000, f"{kind} page exceeds 1 MB")
            text = body.decode(response.headers.get_content_charset() or "utf-8")
            marker = "隐私政策" if kind == "privacy" else "玩家支持"
            require(marker in text and "海上探险家" in text, f"{kind} live page content is unexpected")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site-dir", type=Path, help="validate a rendered site directory")
    parser.add_argument("--require-app-links", action="store_true", help="require real HTTPS URLs in the app")
    parser.add_argument("--check-live-urls", action="store_true", help="fetch and verify the configured app URLs")
    args = parser.parse_args()

    validate_templates()
    if args.site_dir:
        validate_rendered_site(args.site_dir.resolve())
    links = configured_app_links() if args.require_app_links or args.check_live_urls else None
    if args.check_live_urls:
        require(links is not None, "live URL check requires configured app links")
        check_live_urls(links)

    suffix = "; public app links verified" if links else "; public URLs remain an external release gate"
    print("public privacy/support release templates passed" + suffix)


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, UnicodeError) as error:
        print(f"public release page validation failed: {error}", file=sys.stderr)
        raise SystemExit(1)
