#!/usr/bin/env python3
"""Filesystem preflight regressions; never execute a game or modify a git repository."""
import argparse
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('launcher', Path(__file__).with_name('launch-linux-isolated.py'))
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)


class Preflight(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source'
        self.source.mkdir()
        for rel in ('bin/res/scripts', 'bin/res/assets', 'build/bin',
                    'src/engine/cocos2d-x/cocos/scripting/lua-bindings/script',
                    'src/engine/cocos2d-x/cocos/2d/platform/linux'):
            (self.source / rel).mkdir(parents=True, exist_ok=True)
        (self.source / 'linux.sh').write_text('export XDG_CONFIG_HOME="${PIRATE_SAVE_DIR}"')
        (self.source / 'src/engine/cocos2d-x/cocos/2d/platform/linux/CCFileUtilsLinux.cpp').write_text('getenv("XDG_CONFIG_HOME")')
        self.binary = self.source / 'build/bin/PirateExplore'
        elf = bytearray(64)
        elf[:6] = b'\x7fELF\x02\x01'
        elf[18:20] = b'\x3e\x00'
        self.binary.write_bytes(elf + b'XDG_CONFIG_HOME')
        self.binary.chmod(0o700)
        (self.binary.parent / 'Resources').symlink_to(self.source / 'bin/res')
        (self.binary.parent / 'engine-scripts').symlink_to(self.source / 'src/engine/cocos2d-x/cocos/scripting/lua-bindings/script')
        self.args = argparse.Namespace(source=str(self.source), commit='a' * 40,
            binary=str(self.binary), binary_sha256=launcher.sha(self.binary),
            label='A-original-linux', save_root=str(self.root / 'new-run'), width=480, height=800)
        self.dirty = ''
        def fake_git(source, *args):
            return {('rev-parse', '--show-toplevel'): str(self.source),
                    ('rev-parse', 'HEAD'): 'a' * 40,
                    ('rev-parse', 'HEAD^{tree}'): 'b' * 40,
                    ('status', '--porcelain', '--untracked-files=all'): self.dirty}.get(args, '')
        self.patcher = patch.object(launcher, 'git', side_effect=fake_git)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def test_valid_preflight_creates_no_save(self):
        self.assertEqual(launcher.inspect(self.args)[3]['local_commit'], 'a' * 40)
        self.assertFalse(Path(self.args.save_root).exists())

    def test_wrong_commit(self):
        self.args.commit = 'c' * 40
        with self.assertRaisesRegex(ValueError, 'HEAD mismatch'): launcher.inspect(self.args)

    def test_branch_name(self):
        self.args.commit = 'main'
        with self.assertRaisesRegex(ValueError, 'complete local'): launcher.inspect(self.args)

    def test_dirty_source(self):
        self.dirty = ' M bin/res/scripts/main.lua'
        with self.assertRaisesRegex(ValueError, 'dirty'): launcher.inspect(self.args)

    def test_stale_resources(self):
        link = self.binary.parent / 'Resources'
        link.unlink()
        link.symlink_to(self.root)
        with self.assertRaisesRegex(ValueError, 'Resources'): launcher.inspect(self.args)

    def test_stale_engine_scripts(self):
        link = self.binary.parent / 'engine-scripts'
        link.unlink()
        link.symlink_to(self.root)
        with self.assertRaisesRegex(ValueError, 'engine-scripts'): launcher.inspect(self.args)

    def test_existing_save_untouched(self):
        path = Path(self.args.save_root)
        path.mkdir()
        (path / 'old-save').write_text('preserve me')
        with self.assertRaisesRegex(ValueError, 'must not exist'): launcher.inspect(self.args)
        self.assertEqual((path / 'old-save').read_text(), 'preserve me')

    def test_hash_mismatch(self):
        self.args.binary_sha256 = '0' * 64
        with self.assertRaisesRegex(ValueError, 'SHA-256'): launcher.inspect(self.args)

    def test_missing_save_support(self):
        self.binary.write_bytes(self.binary.read_bytes().replace(b'XDG_CONFIG_HOME', b'NO_SAVE_CONFIG'))
        self.args.binary_sha256 = launcher.sha(self.binary)
        with self.assertRaisesRegex(ValueError, 'save boundary'): launcher.inspect(self.args)

    def test_inside_source(self):
        self.args.save_root = str(self.source / 'my-run')
        with self.assertRaisesRegex(ValueError, 'outside'): launcher.inspect(self.args)


if __name__ == '__main__':
    unittest.main()
