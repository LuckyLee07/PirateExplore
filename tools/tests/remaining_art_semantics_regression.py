#!/usr/bin/env python3
"""Check all reskinned resource identities against the real packaged CSV."""
from pathlib import Path
from PIL import Image
import ast
import csv
import io
import re

root=Path(__file__).resolve().parents[2]
module=ast.parse((root/'tools/build_harbor_heading_font.py').read_text())
fn=next(n for n in module.body if isinstance(n,ast.FunctionDef) and n.name=='decode_packaged_csv')
scope={'root':root}
exec(compile(ast.Module(body=[fn],type_ignores=[]),'<real csv decoder>','exec'),scope)
rows=list(csv.reader(io.StringIO(scope['decode_packaged_csv'](root/'bin/res/assets/data/resourceInfo.csv'))))
records={r['ID']:r for row in rows[2:] if (r:=dict(zip(rows[1],row))).get('ID')}
expected={'1001':('金币','r_9.png'),'1004':('小麦','r_1.png'),'1005':('食物','r_2.png'),
          '1006':('石头','r_3.png'),'1007':('木头','r_4.png'),'1008':('铁','r_5.png'),
          '1009':('金','r_6.png'),'1011':('钢','r_8.png'),'1017':('皮革','r_19.png'),
          '1018':('布料','r_20.png'),'1019':('丝绸','r_21.png'),
          '1037':('简易钥匙','r_16.png'),'1120':('图书馆钥匙','r_16.png')}
source=(root/'bin/res/scripts/LuaClass/ResourceTheme.lua').read_text()
mapping=dict(re.findall(r"\['(\d+)'\]='([^']+)'",source))
assert mapping=={id:pair[1] for id,pair in expected.items()}
for id,(name,icon) in expected.items():
    assert records[id]['name']==name and records[id]['iconName']==icon,(id,name)
    image=Image.open(root/'bin/res/assets/Images/Icon/B'/icon)
    assert image.mode=='RGBA' and image.size==(64,64)
    alpha=image.getchannel('A');bounds=alpha.getbbox()
    assert bounds and bounds[0]>=4 and bounds[1]>=4 and bounds[2]<=60 and bounds[3]<=60
    assert alpha.getextrema()==(0,255)
for name,legacy in [('ship-deck-b.png','chuan_04.png'),('boarding-deck-b.png','chuan_01.png')]:
    image=Image.open(root/'bin/res/assets/Images/UI/Adventure/Combat'/name)
    original=Image.open(root/'bin/res/assets/Images/Fight'/legacy)
    assert image.mode=='RGBA' and image.size==original.size
    alpha=image.getchannel('A')
    assert alpha.getextrema()==(0,255) and alpha.getpixel((image.width//2,image.height-1))>=240
rows=list(csv.reader(io.StringIO(scope['decode_packaged_csv'](root/'bin/res/assets/data/soilderAttribute.csv'))))
crew={r['ID']:r for row in rows[2:] if (r:=dict(zip(rows[1],row))).get('ID')}
expected_crew={'100':('低级船员','j_1.png'),'101':('水手','j_2.png'),'102':('突击水手','j_3.png'),
               '107':('木盾舵手','j_4.png'),'124':('船医','j_7.png')}
mapping={id:(original,replacement) for id,original,replacement in
         re.findall(r"\['(\d+)'\]=\{'([^']+)', '([^']+)'\}",source)}
assert mapping=={id:(pair[1],'crew-'+id+'.png') for id,pair in expected_crew.items()}
approved=Image.open(root/'bin/res/assets/Images/UI/Adventure/Master/crew-trio.png').convert('RGBA')
cells={'107':(37,70,663,587),'102':(764,87,666,570),'124':(1488,70,647,587)}
for id,(name,icon) in expected_crew.items():
    assert crew[id]['name']==name and crew[id]['icon']==icon
    image=Image.open(root/'bin/res/assets/Images/Icon/B'/('crew-'+id+'.png'))
    assert image.mode=='RGBA' and image.size==(64,64)
    bounds=image.getchannel('A').getbbox()
    assert bounds and bounds[0]>=2 and bounds[1]>=2 and bounds[2]<=62 and bounds[3]<=62
    if id in cells:
        x,y,w,h=cells[id];crop=approved.crop((x,y,x+w,y+h))
        crop=crop.crop(crop.getchannel('A').getbbox());crop.thumbnail((60,60),Image.Resampling.LANCZOS)
        expected_icon=Image.new('RGBA',(64,64));expected_icon.paste(crop,((64-crop.width)//2,62-crop.height))
        assert image.tobytes()==expected_icon.tobytes(), 'accepted character art was altered'
print('PASS real CSV identity for all 13 resource IDs, 12 transparent icons with 4px gutters, original-sized transparent ship/boarding deck imports')
print('PASS real CSV identity for 5 crew IDs; exact existing approved 102/107/124 portrait pixels reused at 64px')
for name,legacy in [('chest-closed-b.png','baoxiang01.png'),('chest-open-b.png','baoxiang02.png')]:
    image=Image.open(root/'bin/res/assets/Images/UI/Adventure/Combat'/name)
    original=Image.open(root/'bin/res/assets/Images/Fight'/legacy)
    assert image.mode=='RGBA' and image.size==original.size==(184,239)
    alpha=image.getchannel('A');bounds=alpha.getbbox()
    assert alpha.getextrema()==(0,255)
    assert bounds[0]>=4 and bounds[1]>=4 and bounds[2]<=180 and bounds[3]<=235
print('PASS both original-size 184x239 chest states with transparent gutters')
