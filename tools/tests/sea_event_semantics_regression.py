#!/usr/bin/env python3
"""Join authored event frame IDs to the real packaged CSV and original pixels."""
from pathlib import Path
from PIL import Image
import ast,csv,io
root=Path(__file__).resolve().parents[2]
module=ast.parse((root/'tools/build_harbor_heading_font.py').read_text())
fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='decode_packaged_csv')
scope={'root':root};exec(compile(ast.Module(body=[fn],type_ignores=[]),'<real csv decoder>','exec'),scope)
rows=list(csv.reader(io.StringIO(scope['decode_packaged_csv'](root/'bin/res/assets/data/strongholdAttribute.csv'))))
records=[dict(zip(rows[1],row)) for row in rows[2:]]
expected={('30','31'):('铁矿','changeToMaterialsLayer'),('32','32'):('酒馆','changeToPubLayer'),('52','52'):('黑市','changeToBlackMarket'),('47','47'):('复活点','changeToResurrectionLayer'),('49','50'):('传送点','changeToNextMapEnter'),('45','45'):('竞技场','changeToArenaLayer'),('48','44'):('补给点','changeToSupplyPoint')}
for pair,(name,func) in expected.items():
 assert any(r.get('gid')==pair[0] and r.get('occupationgid')==pair[1] and r.get('name')==name and r.get('eventFucString')==func for r in records),(pair,name)
original=Image.open(root/'bin/res/assets/Images/Map/t_00.png').convert('RGBA');new=Image.open(root/'bin/res/assets/Images/UI/Adventure/SeaChart/Tiles/events-world.png').convert('RGBA');assert new.size==original.size==(512,384)
changed={30,31,32,45,47,48,49,50,52}
def box(gid):
 i=gid-19;return(i%8*64,i//8*64,i%8*64+64,i//8*64+64)
for gid in range(19,67):
 a=original.crop(box(gid));b=new.crop(box(gid))
 assert (a.tobytes()!=b.tobytes())==(gid in changed),gid
for base,flagged in ((30,31),(49,50)):
 a=new.crop(box(base));b=new.crop(box(flagged));assert a.crop((0,0,64,38)).tobytes()==b.crop((0,0,64,38)).tobytes()
 assert a.getchannel('A').getbbox()[2]<=61 and b.getchannel('A').getbbox()[2]<=62
print('PASS real event CSV meanings; iron is material mine, 9 changed frames only, consumed supply44 retained, occupation bases aligned')
