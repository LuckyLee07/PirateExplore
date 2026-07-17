#!/usr/bin/env python3
"""Regression tests for embedded archive source provenance."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

from archive_provenance import (
    ProvenanceError,
    archive_tree_fingerprint,
    current_head,
    validate_identity,
    validate_record_match,
    validate_record_shape,
)


HEAD = current_head()


def expect_error(info: dict, expected: str, **kwargs: object) -> None:
    try:
        validate_identity(info, **kwargs)
    except ProvenanceError as error:
        if expected not in str(error):
            raise AssertionError(f"expected {expected!r}, got {error!r}") from error
        return
    raise AssertionError(f"expected provenance failure containing {expected!r}")


clean = {
    "NewPirateSourceCommit": HEAD,
    "NewPirateCandidateID": "2.0.0-1-internal",
}
source, candidate = validate_identity(
    clean,
    expected_source_commit=HEAD,
    expected_candidate_id="2.0.0-1-internal",
)
assert source == HEAD and candidate == "2.0.0-1-internal"

dirty = dict(clean, NewPirateSourceCommit=f"{HEAD}-dirty")
validate_identity(dirty)
expect_error(dirty, "dirty source", require_clean=True)
expect_error(clean, "source commit mismatch", expected_source_commit="0" * 40)
expect_error(clean, "candidate ID mismatch", expected_candidate_id="2.0.0-2-internal")
expect_error(dict(clean, NewPirateSourceCommit="unknown"), "missing or malformed")
expect_error(dict(clean, NewPirateSourceCommit="f" * 40), "does not identify")
expect_error(dict(clean, NewPirateCandidateID="bad candidate"), "missing or malformed")

record = {
    "schema_version": 2,
    "candidate_id": "2.0.0-1-internal",
    "source_commit": HEAD,
    "bundle_id": "com.fancyGame.NewPirate",
    "marketing_version": "2.0.0",
    "build_number": "1",
    "archive_path": "build/archives/NewPirate.xcarchive",
    "captured_at_utc": "2026-07-17T15:15:48+00:00",
    "executable": {
        "sha256": "1" * 64,
        "bytes": 100,
        "macho_uuids": ["609B891E-7C3C-3FA8-97E6-2A697E6BB57E"],
    },
    "dsym": {
        "sha256": "2" * 64,
        "bytes": 200,
        "macho_uuids": ["609B891E-7C3C-3FA8-97E6-2A697E6BB57E"],
    },
    "info_plist_sha256": "3" * 64,
    "archive_tree": {
        "sha256": "4" * 64,
        "entries": 10,
        "file_bytes": 300,
    },
}
validate_record_shape(record)


def expect_record_error(mutator, expected: str) -> None:
    import copy

    changed = copy.deepcopy(record)
    mutator(changed)
    try:
        validate_record_shape(changed)
    except ProvenanceError as error:
        if expected not in str(error):
            raise AssertionError(f"expected {expected!r}, got {error!r}") from error
        return
    raise AssertionError(f"expected record failure containing {expected!r}")


expect_record_error(lambda value: value.update(source_commit=f"{HEAD}-dirty"), "clean full SHA")
expect_record_error(lambda value: value.update(schema_version=1), "schema version is not 2")
expect_record_error(lambda value: value["executable"].update(sha256="bad"), "SHA-256")
expect_record_error(lambda value: value["archive_tree"].update(sha256="bad"), "tree SHA-256")
expect_record_error(lambda value: value["archive_tree"].update(entries=True), "tree entries")
expect_record_error(
    lambda value: value["dsym"].update(macho_uuids=["AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"]),
    "UUIDs do not match",
)
expect_record_error(lambda value: value.update(extra="unexpected"), "fields do not match")
expect_record_error(lambda value: value.update(archive_path="../escape.xcarchive"), "path is unsafe")
expect_record_error(lambda value: value.update(candidate_id="2.0.0-2-internal"), "version and build")

import copy

changed_bytes = copy.deepcopy(record)
changed_bytes["executable"]["sha256"] = "4" * 64
try:
    validate_record_match(record, changed_bytes)
except ProvenanceError as error:
    assert "does not match archive bytes" in str(error)
else:
    raise AssertionError("valid-looking but changed archive bytes passed record comparison")

with tempfile.TemporaryDirectory() as temporary:
    tree = Path(temporary)
    (tree / "Payload").mkdir()
    resource = tree / "Payload/content.lua"
    resource.write_text("return 'first'\n", encoding="utf-8")
    os.chmod(resource, 0o644)
    baseline = archive_tree_fingerprint(tree)

    resource.write_text("return 'second'\n", encoding="utf-8")
    changed_content = archive_tree_fingerprint(tree)
    assert baseline["sha256"] != changed_content["sha256"], "resource replacement did not change tree digest"
    resource.write_text("return 'first'\n", encoding="utf-8")
    assert baseline == archive_tree_fingerprint(tree), "restored resource did not restore tree digest"

    os.chmod(resource, 0o600)
    changed_mode = archive_tree_fingerprint(tree)
    assert baseline["sha256"] != changed_mode["sha256"], "permission replacement did not change tree digest"
    os.chmod(resource, 0o644)
    assert baseline == archive_tree_fingerprint(tree), "restored permission did not restore tree digest"

    os.utime(resource, (1_000_000_000, 1_000_000_000))
    assert baseline == archive_tree_fingerprint(tree), "mtime changed canonical tree digest"

    link = tree / "Payload/current.lua"
    link.symlink_to("content.lua")
    linked = archive_tree_fingerprint(tree)
    link.unlink()
    link.symlink_to("other.lua")
    relinked = archive_tree_fingerprint(tree)
    assert linked["sha256"] != relinked["sha256"], "symlink replacement did not change tree digest"
    link.unlink()
    assert baseline == archive_tree_fingerprint(tree), "removed symlink did not restore tree digest"

    resource.rename(tree / "Payload/renamed.lua")
    changed_path = archive_tree_fingerprint(tree)
    assert baseline["sha256"] != changed_path["sha256"], "path replacement did not change tree digest"

print("Archive provenance OK: identity, clean/dirty, mismatch and candidate-record contracts")
