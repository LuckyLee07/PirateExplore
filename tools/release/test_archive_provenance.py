#!/usr/bin/env python3
"""Regression tests for embedded archive source provenance."""

from __future__ import annotations

from archive_provenance import (
    ProvenanceError,
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
    "schema_version": 1,
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
expect_record_error(lambda value: value["executable"].update(sha256="bad"), "SHA-256")
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

print("Archive provenance OK: identity, clean/dirty, mismatch and candidate-record contracts")
