#!/usr/bin/env python3
"""Read-only packaged-art/provenance/unchanged-story contract for this tranche."""
from pathlib import Path
import ast, csv, hashlib, io, json
from PIL import Image
root=Path(__file__).resolve().parents[2]
manifest=json.loads((root/'docs/coherent-game/opening-story/generated-manifest.json').read_text())
assert manifest['generator']=='built-in image_gen'
assert {a['id'] for a in manifest['assets']}==set(range(1,10))
for asset in manifest['assets']:
 path=root/asset['output'];im=Image.open(path)
 assert hashlib.sha256(path.read_bytes()).hexdigest()==asset['sha256']
 assert list(im.size)==asset['size'] and im.mode==asset['mode']
 assert im.size[0]>1000 and im.size[1]>700
 if asset['id']>=7:
  assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
 else:assert 1.87<im.width/im.height<1.89
 assert asset['prompt'] and 'no' in asset['prompt'].lower()
# Decoder is the existing read-only implementation, not a rewritten game parser.
module=ast.parse((root/'tools/build_clean_voyage_font.py').read_text())
fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='decode_packaged_csv')
scope={'root':root};exec(compile(ast.Module(body=[fn],type_ignores=[]),'<packaged CSV decoder>','exec'),scope)
rows=list(csv.reader(io.StringIO(scope['decode_packaged_csv'](root/'bin/res/assets/data/plot.csv'))))
rows=[dict(zip(rows[1],row)) for row in rows[2:] if row]
assert len(rows)==24
for row in rows[:7]:
 expected=manifest['story'][int(row['ID'])-1]
 assert row['iconID']==expected['iconID'] and row['story']==expected['story'] and row['stayTime']==str(expected['stayTime'])
assert all(row['iconID']=='0' for row in rows[7:]),'later PlotLayer chapters are text-only in shipped CSV'
for path,digest in manifest['unchangedFiles'].items():
 assert hashlib.sha256((root/path).read_bytes()).hexdigest()==digest,'story/startup contract changed: '+path
source=(root/'bin/res/scripts/LuaClass/PlotMode.lua').read_text()
normalized=source.replace("local OpeningStoryArt = require 'LuaClass/OpeningStoryArt'\n",'')
for i in (7,8,9):normalized=normalized.replace('cleanStory() and OpeningStoryArt.sprite(\'juqing_%d\') or cc.Sprite:create("Images/Plot/juqing_%d.png")'%(i,i),'cc.Sprite:create("Images/Plot/juqing_%d.png")'%i)
normalized=normalized.replace('cleanStory() and OpeningStoryArt.sprite(iconId) or cc.Sprite:create("Images/Plot/"..iconId..".png")','cc.Sprite:create("Images/Plot/"..iconId..".png")')
assert hashlib.sha256(normalized.encode()).hexdigest()==manifest['plotModeBeforeSha256'],'only art construction changes are authorized in PlotMode'
print('PASS nine generated assets/provenance, all shipped story beats, original art/startup hashes and unchanged PlotMode timing/skip/controller code')
