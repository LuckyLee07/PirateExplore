#!/usr/bin/env python3
"""Decode read-only shipped CSV; run the real preparation/presentation callback."""
import ast
import csv
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
ROOT = Path(__file__).resolve().parents[2]
module = ast.parse((ROOT / 'tools/build_harbor_heading_font.py').read_text())
decoder = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == 'decode_packaged_csv')
scope = {'root': ROOT}
exec(compile(ast.Module(body=[decoder], type_ignores=[]), '<packaged CSV decoder>', 'exec'), scope)
originals = {}
def records(name):
    path = ROOT / ('bin/res/assets/data/' + name + '.csv')
    originals[path] = path.read_bytes()
    rows = list(csv.reader(io.StringIO(scope['decode_packaged_csv'](path))))
    return {row[1]: dict(zip(rows[1], row)) for row in rows[2:] if len(row) > 1}
def matrix(text):
    return [row.split('_') for row in text.split(';')]
strongholds = records('strongholdAttribute')
soldiers = records('soilderAttribute')
fixture = {'reef': strongholds['3106'],
           'pub': next(r for r in strongholds.values() if r['eventFucString'] == 'changeToPubLayer'),
           'soldiers': {key: soldiers[key] for key in ('10002', '10098', '11005')}}
for row in (fixture['reef'], fixture['pub']):
    row['requiredtool'] = matrix(row['requiredtool'])
for row in fixture['soldiers'].values():
    row['dropitems'] = matrix(row['dropitems'])
def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return json.dumps(value, ensure_ascii=False)
with tempfile.TemporaryDirectory(prefix='enemy-preview-') as tmp:
    path = Path(tmp) / 'records.lua'
    path.write_text('return ' + lua(fixture), encoding='utf-8')
    subprocess.run([sys.argv[1] if len(sys.argv) > 1 else 'build/linux/tests/lua-ui-tests',
                    'tools/tests/prebattle_enemy_preview_regression.lua'], cwd=ROOT,
                   env=dict(os.environ, PIRATE_ENEMY_PREVIEW_FIXTURE=str(path)), check=True)
for path, before in originals.items():
    assert path.read_bytes() == before, 'packaged data must remain unchanged'
print('PASS preview uses unchanged packaged stronghold/soldier data')
