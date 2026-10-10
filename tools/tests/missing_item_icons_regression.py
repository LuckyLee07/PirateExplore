#!/usr/bin/env python3
"""Real packaged CSV -> production Lua parser/resolver, plus pixel import contracts."""
from pathlib import Path
from PIL import Image
import ast
import hashlib
import importlib.util
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[2]
module = ast.parse((root/'tools/build_harbor_heading_font.py').read_text())
fn = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == 'decode_packaged_csv')
scope = {'root': root}
exec(compile(ast.Module(body=[fn], type_ignores=[]), '<packaged csv decoder>', 'exec'), scope)
spec = importlib.util.spec_from_file_location('importer', root/'tools/import_missing_item_icons.py')
importer = importlib.util.module_from_spec(spec); spec.loader.exec_module(importer)
for name in importer.NAMES:
    path = root/'bin/res/assets/Images/Icon/B'/(name+'.png')
    image = Image.open(path)
    expected = importer.render(root/'docs/art-sources/missing-item-icons'/(name+'-master.png'))
    assert image.size == (64, 64) and image.mode == 'RGBA'
    assert image.tobytes() == expected.tobytes(), 'exact deterministic import'
    alpha = image.getchannel('A'); bounds = alpha.getbbox()
    assert alpha.getextrema() == (0, 255)
    assert bounds and min(bounds[:2]) >= 4 and max(bounds[2:]) <= 60
# Preserve the shared original for every other sword tier.
assert hashlib.sha256((root/'bin/res/assets/Images/Icon/w_12.png').read_bytes()).hexdigest() == 'de24f31b0076f9344c03d14fad4c978b8fd4ccfca609abaa49418aa2cdfe5d86'
with tempfile.TemporaryDirectory() as temporary:
    csv_path = Path(temporary)/'resourceInfo.csv'
    csv_path.write_text(scope['decode_packaged_csv'](root/'bin/res/assets/data/resourceInfo.csv'))
    subprocess.run([sys.argv[1] if len(sys.argv)>1 else str(root/'build/linux/tests/lua-ui-tests'),
                    'tools/tests/missing_item_icons_regression.lua', str(csv_path)], cwd=root, check=True)
print('PASS original shared sword bytes, two 64px padded alpha icons, deterministic imports and real production CSV parser')
