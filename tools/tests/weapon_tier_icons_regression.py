#!/usr/bin/env python3
"""Validate tier-specific imports and real-CSV guarded mappings, without a GUI."""
from pathlib import Path
import ast
import hashlib
import subprocess
import sys
import tempfile
from PIL import Image

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
import import_weapon_tier_icons as importer

for name in importer.NAMES:
    image = Image.open(root / 'bin/res/assets/Images/Icon/B' / (name + '.png'))
    expected = importer.render(root / 'docs/art-sources/weapon-tier-icons' / (name + '-master.png'))
    assert image.mode == 'RGBA' and image.size == (64, 64)
    assert image.tobytes() == expected.tobytes(), 'import must reproduce exactly'
    alpha = image.getchannel('A')
    bounds = alpha.getbbox()
    assert alpha.getextrema() == (0, 255)
    assert bounds and min(bounds[:2]) >= 4 and max(bounds[2:]) <= 60
    assert sum(alpha.histogram()[128:]) > 250, 'readable silhouette area'
assert hashlib.sha256((root / 'bin/res/assets/Images/Icon/w_12.png').read_bytes()).hexdigest() == 'de24f31b0076f9344c03d14fad4c978b8fd4ccfca609abaa49418aa2cdfe5d86'
module = ast.parse((root / 'tools/build_harbor_heading_font.py').read_text())
fn = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == 'decode_packaged_csv')
scope = {'root': root}
exec(compile(ast.Module(body=[fn], type_ignores=[]), '<packaged csv decoder>', 'exec'), scope)
with tempfile.TemporaryDirectory() as temporary:
    csv = Path(temporary) / 'resourceInfo.csv'
    csv.write_text(scope['decode_packaged_csv'](root / 'bin/res/assets/data/resourceInfo.csv'))
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else str(root / 'build/linux/tests/lua-ui-tests'),
                    'tools/tests/weapon_tier_icons_regression.lua', str(csv)], cwd=root, check=True)
print('PASS two distinct padded transparent deterministic 64px tier icons and unchanged shared original')
