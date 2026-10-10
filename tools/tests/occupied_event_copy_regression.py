#!/usr/bin/env python3
"""Exercise completion copy with the shipped stronghold records, no save/GUI."""
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
path = ROOT / 'bin/res/assets/data/strongholdAttribute.csv'
before = path.read_bytes()
rows = list(csv.reader(io.StringIO(scope['decode_packaged_csv'](path))))
records = [dict(zip(rows[1], row)) for row in rows[2:]]
materials = [r for r in records if r.get('eventFucString') == 'changeToMaterialsLayer']
assert len(materials) == 9
assert {'铁矿', '石矿', '金矿'} <= {r['name'] for r in materials}
pub = next(r for r in records if r.get('eventFucString') == 'changeToPubLayer')
boss = next(r for r in records if r.get('plotID') not in (None, '', '0'))

def lua(value):
    if isinstance(value, dict):
        return '{' + ','.join('[' + lua(k) + ']=' + lua(v) for k, v in value.items()) + '}'
    if isinstance(value, list):
        return '{' + ','.join(lua(v) for v in value) + '}'
    return json.dumps(value, ensure_ascii=False)

# Only no-cost/no-drop test boundaries are substituted. All displayed text,
# identities and event method names come directly from the packaged records.
fields = ('ID', 'name', 'description', 'occupationdescription', 'eventFucString')
fixture = {'materials': [{k: r[k] for k in fields} for r in materials],
           'pub': {k: pub[k] for k in fields}, 'boss': {k: boss[k] for k in fields}}
with tempfile.TemporaryDirectory(prefix='occupied-event-copy-') as tmp:
    data = Path(tmp) / 'records.lua'
    data.write_text('return ' + lua(fixture), encoding='utf-8')
    env = dict(os.environ, PIRATE_EVENT_COPY_FIXTURE=str(data))
    executable = sys.argv[1] if len(sys.argv) > 1 else 'build/linux/tests/lua-ui-tests'
    subprocess.run([executable, 'tools/tests/occupied_event_copy_regression.lua'],
                   cwd=ROOT, env=env, check=True)
assert path.read_bytes() == before, 'packaged stronghold data must remain untouched'
print('PASS shipped stronghold CSV: all nine resource variants plus tavern/boss completion copy, package unchanged')
