#!/usr/bin/env python3
"""Standalone Linux helper test. Never launches or accesses a game profile."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='pirate-atomic-build-') as temp:
    out = str(Path(temp) / 'atomic-save-test')
    subprocess.run(['c++', '-std=c++11', '-Wall', '-Wextra', '-Werror',
                    '-I'+str(root/'src/NewPirate/common/UtilTools'),
                    str(root/'tools/tests/atomic_save_regression.cpp'), '-o', out], check=True)
    subprocess.run([out], check=True)
