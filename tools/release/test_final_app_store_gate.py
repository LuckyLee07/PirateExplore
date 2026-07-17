#!/usr/bin/env python3
"""Pure regression tests for the unified final App Store gate."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/release"))

from final_app_store_gate import checks_passed, grouped_pending_gates  # noqa: E402


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    pending = [
        "app_record.apple_id",
        "app_record.sku",
        "product_page.privacy_policy_url",
        "distribution.signed_archive",
        "distribution.upload_build_id",
    ]
    grouped = grouped_pending_gates(pending)
    require(grouped["app_record"] == pending[:2], "pending app-record grouping drifted")
    require(grouped["product_page"] == pending[2:3], "pending product-page grouping drifted")
    require(grouped["distribution"] == pending[3:], "pending distribution grouping drifted")

    require(not checks_passed([]), "an empty final check list passed")
    require(
        checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "passed"},
        ]),
        "all-passed final checks failed",
    )
    require(
        not checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "failed"},
        ]),
        "one failed final check still produced GO",
    )
    require(
        not checks_passed([
            {"name": "metadata", "status": "passed"},
            {"name": "binary", "status": "skipped"},
        ]),
        "one skipped final check still produced GO",
    )

    print("Final App Store gate OK: grouped blockers and non-bypassable check aggregation")


if __name__ == "__main__":
    main()
