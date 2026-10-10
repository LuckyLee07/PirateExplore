#!/usr/bin/env python3
"""Guarded Linux launcher. Never checks out code, patches files, or deletes saves."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timezone


def fail(message):
    raise ValueError(message)


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def git(source, *args):
    return subprocess.check_output(['git', '-C', str(source), *args], text=True).strip()


def inspect(args):
    source = Path(args.source).resolve(strict=True)
    if git(source, 'rev-parse', '--show-toplevel') != str(source):
        fail('--source must be the repository root')
    if not re.fullmatch(r'[0-9a-f]{40}', args.commit):
        fail('--commit must be the complete local commit SHA; branches are not pins')
    head = git(source, 'rev-parse', 'HEAD')
    if head != args.commit:
        fail('HEAD mismatch; prepare another directory explicitly, never switch the active checkout')
    if git(source, 'status', '--porcelain', '--untracked-files=all'):
        fail('Source is dirty; prepare a clean pinned snapshot, including any explicitly recorded compatibility commit')
    binary = Path(args.binary).resolve(strict=True)
    if binary.name != 'PirateExplore' or not os.access(binary, os.X_OK):
        fail('Expected an executable named PirateExplore')
    content = binary.read_bytes()
    if content[:6] != b'\x7fELF\x02\x01' or content[18:20] != b'\x3e\x00':
        fail('Expected a Linux-compatible little-endian x86-64 ELF, not a mobile or desktop installer')
    if not re.fullmatch(r'[0-9a-f]{64}', args.binary_sha256) or sha(binary) != args.binary_sha256:
        fail('Binary SHA-256 mismatch; use the hash from the matching build verification record')
    engine_path = 'src/engine/cocos2d-x/cocos/2d/platform/linux/CCFileUtilsLinux.cpp'
    engine = (source / engine_path).read_text()
    wrapper = (source / 'linux.sh').read_text()
    # Tracking plus clean-tree checks ensure these checks are against the pinned source.
    git(source, 'ls-files', '--error-unmatch', engine_path, 'linux.sh')
    if 'getenv("XDG_CONFIG_HOME")' not in engine or b'XDG_CONFIG_HOME' not in content:
        fail('Cannot verify this source/binary supports the required XDG save boundary')
    if 'PIRATE_SAVE_DIR' not in wrapper or 'export XDG_CONFIG_HOME=' not in wrapper:
        fail('Cannot verify the linux.sh PIRATE_SAVE_DIR to XDG_CONFIG_HOME interface')
    links = {}
    for name, expected in [('Resources', source / 'bin/res'),
                           ('engine-scripts', source / 'src/engine/cocos2d-x/cocos/scripting/lua-bindings/script')]:
        actual = binary.parent / name
        if not actual.is_symlink() or actual.resolve(strict=True) != expected.resolve(strict=True):
            fail(f'{name} does not point to the selected source; stale or cross-version resources are refused')
        links[name] = str(actual.resolve())
    if not (source / 'bin/res/scripts').is_dir() or not (source / 'bin/res/assets').is_dir():
        fail('Selected resource tree is incomplete')
    run_root = Path(args.save_root).absolute()
    if run_root.exists() or run_root.is_symlink():
        fail('--save-root must not exist; existing profiles are never reused or cleared')
    if source == run_root.resolve() or source in run_root.resolve().parents:
        fail('Keep --save-root outside the source snapshot')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,63}', args.label):
        fail('Use an explicit simple label such as A-original-linux, B-ui-frozen, or C-gameplay')
    if args.width < 320 or args.height < 480:
        fail('Minimum viewport is 320 by 480')
    return source, binary, run_root, {
        'label': args.label, 'local_commit': head,
        'tree': git(source, 'rev-parse', 'HEAD^{tree}'),
        'binary': str(binary), 'binary_sha256': args.binary_sha256,
        'source': str(source), 'resource_paths': links,
        'save_root': str(run_root), 'viewport': [args.width, args.height],
        'save_contract': 'PIRATE_SAVE_DIR = XDG_CONFIG_HOME; engine appends /PirateExplore/',
        'note': 'Preflight checks are not proof of native gameplay or binary build provenance.',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ('label', 'source', 'commit', 'binary', 'binary-sha256', 'save-root'):
        parser.add_argument('--' + flag, required=True)
    parser.add_argument('--width', type=int, default=480)
    parser.add_argument('--height', type=int, default=800)
    parser.add_argument('--check', action='store_true', help='Validate only; create nothing and do not start the game')
    args = parser.parse_args()
    try:
        source, binary, root, manifest = inspect(args)
        if args.check:
            print(json.dumps(manifest, ensure_ascii=False, indent=2))
            return 0
        if not os.environ.get('DISPLAY'):
            fail('No DISPLAY; launch only in the verified graphical Linux environment')
        # mkdir without exist_ok prevents accidental profile reuse, including a concurrent launch.
        root.mkdir(mode=0o700, parents=False)
        for name in ('home', 'config', 'data', 'cache'):
            (root / name).mkdir(mode=0o700)
        (root / 'config/PirateExplore').mkdir(mode=0o700)
        env = os.environ.copy()
        # Preserve a verified existing X11 authorization path before isolating HOME.
        authority = Path(env.get('XAUTHORITY', str(Path.home() / '.Xauthority')))
        if authority.is_file():
            env['XAUTHORITY'] = str(authority.resolve())
        env.update(HOME=str(root / 'home'), XDG_CONFIG_HOME=str(root / 'config'),
                   PIRATE_SAVE_DIR=str(root / 'config'), XDG_DATA_HOME=str(root / 'data'),
                   XDG_CACHE_HOME=str(root / 'cache'))
        manifest['started_at_utc'] = datetime.now(timezone.utc).isoformat()
        (root / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        print(f"{args.label}: {args.commit}\nNew save: {root / 'config/PirateExplore'}", flush=True)
        # Direct exec sets both variables explicitly; it does not rely on inherited PIRATE_SAVE_DIR.
        # Existing dependency paths and DISPLAY/audio configuration remain unchanged.
        with (root / 'runtime.log').open('xb') as log:
            result = subprocess.run([str(binary), str(args.width), str(args.height)],
                                    cwd=source, env=env, stdout=log, stderr=subprocess.STDOUT)
        manifest['exit_code'] = result.returncode
        manifest['finished_at_utc'] = datetime.now(timezone.utc).isoformat()
        (root / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        return result.returncode if result.returncode >= 0 else 128 - result.returncode
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f'Refused: {error}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
