#!/usr/bin/env python3
"""Read and validate source provenance embedded in a NewPirate archive."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import stat
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATTERN = re.compile(r"^[0-9a-f]{7,40}(?:-dirty)?$")
CANDIDATE_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
UUID_PATTERN = re.compile(r"^[0-9A-F]{8}(?:-[0-9A-F]{4}){3}-[0-9A-F]{12}$")


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


def archive_tree_fingerprint(archive: Path) -> dict:
    digest = hashlib.sha256()
    entry_count = 0
    file_bytes = 0
    paths = sorted(archive.rglob("*"), key=lambda path: path.relative_to(archive).as_posix())
    for path in paths:
        relative = path.relative_to(archive).as_posix().encode("utf-8")
        metadata = path.lstat()
        mode = stat.S_IMODE(metadata.st_mode)
        if path.is_symlink():
            kind = b"L"
            payload = os.readlink(path).encode("utf-8")
            entry_size = len(payload)
        elif path.is_file():
            kind = b"F"
            file_bytes += metadata.st_size
            payload = bytes.fromhex(sha256(path))
            entry_size = metadata.st_size
        elif path.is_dir():
            kind = b"D"
            payload = b""
            entry_size = 0
        else:
            raise ProvenanceError(f"unsupported archive entry type: {path}")
        digest.update(kind)
        digest.update(b"\0")
        digest.update(relative)
        digest.update(b"\0")
        digest.update(f"{mode:o}".encode("ascii"))
        digest.update(b"\0")
        digest.update(str(entry_size).encode("ascii"))
        digest.update(b"\0")
        digest.update(payload)
        digest.update(b"\0")
        entry_count += 1
    return {
        "sha256": digest.hexdigest(),
        "entries": entry_count,
        "file_bytes": file_bytes,
    }


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


def build_record(archive: Path, *, require_head: bool = True, root: Path = ROOT) -> dict:
    archive = archive.resolve()
    app, info = read_archive_identity(archive)
    source, candidate = validate_identity(
        info,
        require_clean=True,
        require_head=require_head,
        root=root,
    )
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
        "schema_version": 2,
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
        "archive_tree": archive_tree_fingerprint(archive),
    }


def validate_record_shape(record: object, *, root: Path = ROOT) -> dict:
    if not isinstance(record, dict):
        raise ProvenanceError("candidate record root must be an object")
    expected_keys = {
        "schema_version",
        "candidate_id",
        "source_commit",
        "bundle_id",
        "marketing_version",
        "build_number",
        "archive_path",
        "captured_at_utc",
        "executable",
        "dsym",
        "info_plist_sha256",
        "archive_tree",
    }
    if set(record) != expected_keys:
        raise ProvenanceError("candidate record fields do not match schema 2")
    if record.get("schema_version") != 2:
        raise ProvenanceError("candidate record schema version is not 2")
    candidate = record.get("candidate_id")
    source = record.get("source_commit")
    if not isinstance(candidate, str) or not CANDIDATE_PATTERN.fullmatch(candidate):
        raise ProvenanceError("candidate record ID is malformed")
    if not isinstance(source, str) or not re.fullmatch(r"[0-9a-f]{40}", source):
        raise ProvenanceError("candidate record source commit must be a clean full SHA")
    if not commit_exists(source, root=root):
        raise ProvenanceError("candidate record source commit does not identify a repository commit")
    if record.get("bundle_id") != "com.fancyGame.NewPirate":
        raise ProvenanceError("candidate record bundle ID is invalid")
    for key in ("marketing_version", "build_number", "archive_path"):
        if not isinstance(record.get(key), str) or not record[key]:
            raise ProvenanceError(f"candidate record {key} is empty")
    expected_candidate_prefix = f"{record['marketing_version']}-{record['build_number']}"
    if candidate != expected_candidate_prefix and not candidate.startswith(f"{expected_candidate_prefix}-"):
        raise ProvenanceError("candidate record ID does not match version and build")
    archive_path = Path(record["archive_path"])
    if archive_path.is_absolute() or ".." in archive_path.parts or archive_path.suffix != ".xcarchive":
        raise ProvenanceError("candidate record archive path is unsafe")
    timestamp = record.get("captured_at_utc")
    if not isinstance(timestamp, str):
        raise ProvenanceError("candidate record capture timestamp is missing")
    try:
        parsed_timestamp = datetime.fromisoformat(timestamp)
    except ValueError as error:
        raise ProvenanceError("candidate record capture timestamp is malformed") from error
    if parsed_timestamp.tzinfo is None:
        raise ProvenanceError("candidate record capture timestamp has no timezone")

    for section_name in ("executable", "dsym"):
        section = record.get(section_name)
        if not isinstance(section, dict) or set(section) != {"sha256", "bytes", "macho_uuids"}:
            raise ProvenanceError(f"candidate record {section_name} fields are invalid")
        if not isinstance(section.get("sha256"), str) or not SHA256_PATTERN.fullmatch(section["sha256"]):
            raise ProvenanceError(f"candidate record {section_name} SHA-256 is invalid")
        if (
            not isinstance(section.get("bytes"), int)
            or isinstance(section["bytes"], bool)
            or section["bytes"] <= 0
        ):
            raise ProvenanceError(f"candidate record {section_name} size is invalid")
        uuids = section.get("macho_uuids")
        if (
            not isinstance(uuids, list)
            or not uuids
            or any(not isinstance(value, str) or not UUID_PATTERN.fullmatch(value) for value in uuids)
        ):
            raise ProvenanceError(f"candidate record {section_name} UUIDs are invalid")
        if uuids != sorted(set(uuids)):
            raise ProvenanceError(f"candidate record {section_name} UUIDs are not canonical")
    if record["executable"]["macho_uuids"] != record["dsym"]["macho_uuids"]:
        raise ProvenanceError("candidate record executable and dSYM UUIDs do not match")
    info_hash = record.get("info_plist_sha256")
    if not isinstance(info_hash, str) or not SHA256_PATTERN.fullmatch(info_hash):
        raise ProvenanceError("candidate record Info.plist SHA-256 is invalid")
    tree = record.get("archive_tree")
    if not isinstance(tree, dict) or set(tree) != {"sha256", "entries", "file_bytes"}:
        raise ProvenanceError("candidate record archive tree fields are invalid")
    if not isinstance(tree.get("sha256"), str) or not SHA256_PATTERN.fullmatch(tree["sha256"]):
        raise ProvenanceError("candidate record archive tree SHA-256 is invalid")
    for key in ("entries", "file_bytes"):
        if not isinstance(tree.get(key), int) or isinstance(tree[key], bool) or tree[key] <= 0:
            raise ProvenanceError(f"candidate record archive tree {key} is invalid")
    return record


def validate_record_match(record: dict, actual: dict) -> None:
    comparable_actual = dict(actual, captured_at_utc=record["captured_at_utc"])
    if comparable_actual != record:
        raise ProvenanceError("candidate record does not match archive bytes or embedded identity")


def verify_record(record_path: Path, *, root: Path = ROOT) -> dict:
    try:
        record = json.loads(record_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ProvenanceError(f"cannot read candidate record: {error}") from error
    record = validate_record_shape(record, root=root)
    archive = (root / record["archive_path"]).resolve()
    if root not in archive.parents:
        raise ProvenanceError("candidate record archive path escapes repository")
    actual = build_record(archive, require_head=False, root=root)
    validate_record_match(record, actual)
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path, nargs="?")
    parser.add_argument("--expected-source-commit")
    parser.add_argument("--expected-candidate-id")
    parser.add_argument("--require-clean-head", action="store_true")
    parser.add_argument("--record-output", type=Path)
    parser.add_argument("--verify-record", type=Path)
    args = parser.parse_args()

    try:
        if args.verify_record is not None:
            if args.archive is not None or args.record_output is not None:
                raise ProvenanceError("--verify-record cannot be combined with archive capture")
            record = verify_record(args.verify_record)
            print(
                "archive provenance record OK: "
                f"candidate={record['candidate_id']}, source={record['source_commit']}"
            )
            return 0
        if args.archive is None:
            raise ProvenanceError("archive path is required unless --verify-record is used")
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
            record = build_record(args.archive, require_head=True)
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
