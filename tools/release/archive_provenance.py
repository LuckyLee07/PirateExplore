#!/usr/bin/env python3
"""Read and validate source provenance embedded in a NewPirate archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATTERN = re.compile(r"^[0-9a-f]{7,40}(?:-dirty)?$")
CANDIDATE_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")


class ProvenanceError(ValueError):
    pass


def git(*args: str, root: Path = ROOT, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        capture_output=True,
        check=False,
    )
    if check and result.returncode != 0:
        raise ProvenanceError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


def current_head(root: Path = ROOT) -> str:
    return git("rev-parse", "HEAD", root=root)


def tracked_worktree_clean(root: Path = ROOT) -> bool:
    unstaged = subprocess.run(["git", "diff", "--quiet", "--ignore-submodules", "--"], cwd=root).returncode
    staged = subprocess.run(["git", "diff", "--cached", "--quiet", "--ignore-submodules", "--"], cwd=root).returncode
    return unstaged == 0 and staged == 0


def commit_exists(commit: str, root: Path = ROOT) -> bool:
    return subprocess.run(
        ["git", "cat-file", "-e", f"{commit}^{{commit}}"],
        cwd=root,
        capture_output=True,
    ).returncode == 0


def archive_app(archive: Path) -> Path:
    apps = list((archive / "Products/Applications").glob("*.app"))
    if len(apps) != 1:
        raise ProvenanceError(f"expected exactly one archive app, found {len(apps)}")
    return apps[0]


def read_archive_identity(archive: Path) -> tuple[Path, dict]:
    app = archive_app(archive)
    try:
        with (app / "Info.plist").open("rb") as handle:
            info = plistlib.load(handle)
    except (OSError, plistlib.InvalidFileException) as error:
        raise ProvenanceError(f"cannot read archive app Info.plist: {error}") from error
    if not isinstance(info, dict):
        raise ProvenanceError("archive app Info.plist root is not a dictionary")
    return app, info


def validate_identity(
    info: dict,
    *,
    expected_source_commit: str | None = None,
    expected_candidate_id: str | None = None,
    require_clean: bool = False,
    require_head: bool = False,
    root: Path = ROOT,
) -> tuple[str, str]:
    source = info.get("NewPirateSourceCommit")
    candidate = info.get("NewPirateCandidateID")
    if not isinstance(source, str) or not SOURCE_PATTERN.fullmatch(source):
        raise ProvenanceError("archive source commit is missing or malformed")
    if not isinstance(candidate, str) or not CANDIDATE_PATTERN.fullmatch(candidate):
        raise ProvenanceError("archive candidate ID is missing or malformed")

    clean_commit = source.removesuffix("-dirty")
    if not commit_exists(clean_commit, root=root):
        raise ProvenanceError("archive source commit does not identify a repository commit")
    if expected_source_commit is not None and source != expected_source_commit:
        raise ProvenanceError(
            f"archive source commit mismatch: expected {expected_source_commit}, got {source}"
        )
    if expected_candidate_id is not None and candidate != expected_candidate_id:
        raise ProvenanceError(
            f"archive candidate ID mismatch: expected {expected_candidate_id}, got {candidate}"
        )
    if require_clean and source.endswith("-dirty"):
        raise ProvenanceError("dirty source cannot be recorded as a frozen candidate")
    if require_head and source != current_head(root=root):
        raise ProvenanceError("archive source commit does not match repository HEAD")
    if require_head and not tracked_worktree_clean(root=root):
        raise ProvenanceError("tracked worktree must be clean when recording a frozen candidate")
    return source, candidate


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def macho_uuids(path: Path) -> list[str]:
    result = subprocess.run(
        ["xcrun", "dwarfdump", "--uuid", str(path)],
        text=True,
        capture_output=True,
        check=True,
    )
    uuids = re.findall(r"UUID: ([0-9A-F-]+)", result.stdout)
    if not uuids:
        raise ProvenanceError(f"no Mach-O UUID found: {path}")
    return sorted(uuids)


def build_record(archive: Path, *, root: Path = ROOT) -> dict:
    archive = archive.resolve()
    app, info = read_archive_identity(archive)
    source, candidate = validate_identity(info, require_clean=True, require_head=True, root=root)
    executable = app / str(info.get("CFBundleExecutable") or "")
    if not executable.is_file():
        raise ProvenanceError("archive executable is missing")
    dsyms = list((archive / "dSYMs").glob("*.app.dSYM/Contents/Resources/DWARF/*"))
    if len(dsyms) != 1:
        raise ProvenanceError(f"expected one dSYM DWARF file, found {len(dsyms)}")
    app_uuids = macho_uuids(executable)
    dsym_uuids = macho_uuids(dsyms[0])
    if app_uuids != dsym_uuids:
        raise ProvenanceError("archive executable and dSYM UUIDs do not match")
    try:
        archive_path = str(archive.relative_to(root))
    except ValueError as error:
        raise ProvenanceError("candidate archive must be inside the repository workspace") from error
    return {
        "schema_version": 1,
        "candidate_id": candidate,
        "source_commit": source,
        "bundle_id": info.get("CFBundleIdentifier"),
        "marketing_version": info.get("CFBundleShortVersionString"),
        "build_number": info.get("CFBundleVersion"),
        "archive_path": archive_path,
        "captured_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "executable": {
            "sha256": sha256(executable),
            "bytes": executable.stat().st_size,
            "macho_uuids": app_uuids,
        },
        "dsym": {
            "sha256": sha256(dsyms[0]),
            "bytes": dsyms[0].stat().st_size,
            "macho_uuids": dsym_uuids,
        },
        "info_plist_sha256": sha256(app / "Info.plist"),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("--expected-source-commit")
    parser.add_argument("--expected-candidate-id")
    parser.add_argument("--require-clean-head", action="store_true")
    parser.add_argument("--record-output", type=Path)
    args = parser.parse_args()

    try:
        _, info = read_archive_identity(args.archive.resolve())
        source, candidate = validate_identity(
            info,
            expected_source_commit=args.expected_source_commit,
            expected_candidate_id=args.expected_candidate_id,
            require_clean=args.require_clean_head,
            require_head=args.require_clean_head,
        )
        if args.record_output is not None:
            if not args.require_clean_head:
                raise ProvenanceError("record output requires --require-clean-head")
            record = build_record(args.archive)
            args.record_output.parent.mkdir(parents=True, exist_ok=True)
            args.record_output.write_text(
                json.dumps(record, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    except (OSError, subprocess.CalledProcessError, ProvenanceError) as error:
        print(f"archive provenance validation failed: {error}")
        return 2

    print(f"archive provenance OK: candidate={candidate}, source={source}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
