#!/usr/bin/env python3
"""Render host-ready NewPirate privacy and support pages from verified values."""

from __future__ import annotations

import argparse
import html
import re
import shutil
import sys
from datetime import date
from pathlib import Path

from validate_public_release_pages import ROOT, TEMPLATE_DIR, validate_https_url, validate_rendered_site


EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validated_values(args: argparse.Namespace) -> dict[str, str]:
    base_url = validate_https_url(args.base_url).rstrip("/")
    legal_name = args.legal_name.strip()
    email = args.support_email.strip()
    require(len(legal_name) >= 2 and "{{" not in legal_name, "legal name is blank or a placeholder")
    require(bool(EMAIL_RE.fullmatch(email)), "support email is invalid")
    email_domain = email.rsplit("@", 1)[1].lower()
    require(email_domain not in {"example.com", "example.org", "example.net"}, "support email uses a reserved example domain")
    effective = date.fromisoformat(args.effective_date)
    return {
        "APP_NAME": "海上探险家",
        "APP_VERSION": "2.0.0",
        "LEGAL_NAME": legal_name,
        "SUPPORT_EMAIL": email,
        "EFFECTIVE_DATE": effective.isoformat(),
        "COPYRIGHT_YEAR": str(effective.year),
        "PRIVACY_URL": base_url + "/privacy/",
        "SUPPORT_URL": base_url + "/support/",
    }


def render(template: str, values: dict[str, str]) -> str:
    result = template
    for key, value in values.items():
        result = result.replace("{{" + key + "}}", html.escape(value, quote=True))
    require("{{" not in result and "}}" not in result, "unresolved template placeholder")
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--legal-name", required=True, help="verified operator/legal entity name")
    parser.add_argument("--support-email", required=True, help="verified monitored support mailbox")
    parser.add_argument("--base-url", required=True, help="public HTTPS site root")
    parser.add_argument("--effective-date", required=True, help="policy effective date in YYYY-MM-DD")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "build/public-release-pages")
    args = parser.parse_args()

    values = validated_values(args)
    output = args.output_dir.resolve()
    for relative in ("privacy", "support", "assets"):
        (output / relative).mkdir(parents=True, exist_ok=True)

    targets = {
        "privacy-policy.zh-CN.html": output / "privacy/index.html",
        "support.zh-CN.html": output / "support/index.html",
    }
    for template_name, target in targets.items():
        source = (TEMPLATE_DIR / template_name).read_text(encoding="utf-8")
        target.write_text(render(source, values), encoding="utf-8")
    shutil.copyfile(TEMPLATE_DIR / "release.css", output / "assets/release.css")
    validate_rendered_site(output)

    print(f"rendered and validated public release pages: {output}")
    print(f"privacy URL: {values['PRIVACY_URL']}")
    print(f"support URL: {values['SUPPORT_URL']}")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, OSError, UnicodeError, ValueError) as error:
        print(f"public release page rendering failed: {error}", file=sys.stderr)
        raise SystemExit(1)
