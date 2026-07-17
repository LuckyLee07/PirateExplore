#!/usr/bin/env python3
"""Regression tests for embedded archive source provenance."""

from __future__ import annotations

from archive_provenance import ProvenanceError, current_head, validate_identity


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

print("Archive provenance OK: clean/dirty, commit existence, source and candidate mismatch contracts")
