#!/usr/bin/env python3
"""Behavioral regressions for the reusable V2 content contract."""

from __future__ import annotations

import copy
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/v2"))

from content_contract import load_tables, validate_repository, validate_tables  # noqa: E402


def require_code(issues, code: str, message: str) -> None:
    if not any(issue.code == code for issue in issues):
        raise AssertionError(message)


actual = validate_repository(ROOT)
if actual:
    raise AssertionError("current authored content violates the contract:\n" + "\n".join(map(str, actual)))

tables, loading_issues = load_tables(ROOT / "design/v2/data")
if loading_issues:
    raise AssertionError(loading_issues)

unknown = copy.deepcopy(tables)
unknown["map_node"][0]["event_id"] = "event_missing"
require_code(validate_tables(unknown), "unknown_reference", "unknown cross-table references must fail")

duplicate = copy.deepcopy(tables)
duplicate["event_choice"][1]["action_id"] = duplicate["event_choice"][0]["action_id"]
require_code(validate_tables(duplicate), "duplicate_action", "duplicate player action ids must fail")

stage = copy.deepcopy(tables)
stage["presentation"][1]["stage"] = stage["presentation"][0]["stage"]
require_code(validate_tables(stage), "duplicate_stage_presentation", "one stage cannot map to two hero presentations")

orphan = copy.deepcopy(tables)
orphan["map_node"][2]["event_id"] = ""
require_code(validate_tables(orphan), "unmapped_event", "authored events cannot survive outside the runtime graph")

print("V2 content contract OK: 19 tables, references, actions, stage art and orphan detection passed")
