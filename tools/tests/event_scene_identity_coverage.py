#!/usr/bin/env python3
"""Audit exact entry-scene coverage against shipped CSV; no game writes/network."""
from pathlib import Path
import argparse,ast,csv,hashlib,io,json,subprocess
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--lua',default='/workspace/shared/lua51');parser.add_argument('--write-ledger',action='store_true');args=parser.parse_args()
a=ast.parse((root/'tools/build_harbor_heading_font.py').read_text());fn=next(n for n in a.body if isinstance(n,ast.FunctionDef)and n.name=='decode_packaged_csv');scope={'root':root};exec(compile(ast.Module(body=[fn],type_ignores=[]),'<original packaged decoder>','exec'),scope)
raw=root/'bin/res/assets/data/strongholdAttribute.csv';table=list(csv.reader(io.StringIO(scope['decode_packaged_csv'](raw))));rows=[dict(zip(table[1],r))for r in table[2:]if len(r)>2]
rows=[r for r in rows if r['eventFucString']]
program="local S=dofile('bin/res/scripts/LuaClass/EventSceneIdentity.lua')\n"
for row in rows:
    fields=','.join(k+'='+json.dumps(row[k],ensure_ascii=False)for k in ['ID','eventFucString','enemys'])
    program+="do local r={"+fields+"};local m=S.resolve(r,false);local occupied=S.resolve(r,true);if m then assert(occupied and occupied.occupied);print(r.ID..'|'..m.kind..'|'..(m.prop or m.actor or ''));else print(r.ID..'|fallback|')end end\n"
program+="assert(not S.resolve({ID='3108',eventFucString='changeToSupplyPoint'},false));assert(S.resolve({ID='3108',eventFucString='changeToEnemyLayer',enemys='10001'},true).enemy==nil)\n"
result=subprocess.run([args.lua,'-'],input=program,cwd=root,text=True,capture_output=True,check=True)
resolved={line.split('|')[0]:line.split('|')[1:]for line in result.stdout.splitlines()if'|'in line}
families={}
for row in rows:
    family=families.setdefault(row['eventFucString'],{'total':0,'entry_scene_ids':[],'fallback_ids':[],'fallback_sites':[]})
    family['total']+=1;kind,path=resolved[row['ID']]
    if kind!='fallback':
        family['entry_scene_ids'].append(row['ID'])
        assert (root/'bin/res/assets/Images/UI/CleanVoyage'/path).is_file(),(row['ID'],path)
    else:
        family['fallback_ids'].append(row['ID']);family['fallback_sites'].append({'id':row['ID'],'name':row['name'],'reason':'distinct semantic artwork not reviewed; legacy entry presentation remains'})
for family in families.values():
    family['entry_scene_count']=len(family['entry_scene_ids']);family['fallback_count']=len(family['fallback_ids'])
ledger={'scope':'EventLayer entry scene presentation only; downstream surfaces are not accepted by this ledger','packaged_stronghold_sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'dispatched_records':len(rows),'families':families,'entry_scene_total':sum(f['entry_scene_count']for f in families.values()),'fallback_total':sum(f['fallback_count']for f in families.values()),'remaining_reachable_surfaces':[{'surface':'WorldMapLayer.lua chapter/map selector','status':'legacy layout; not changed or accepted by entry-scene art','proposed_followup':'Separate presentation-only pass preserving original chapter IDs, unlocked state, teleport/next-map ownership, payment gates and callbacks; native compact/large pixels plus locked/unlocked/select/cancel/input/cleanup checks before acceptance.'},{'surface':'EventDetailsLayer recruitment, resurrection, black-market and cargo child pages','status':'existing coherent implementation retained; no new scene-art acceptance in this change'}]}
assert len(families)==10 and len(rows)==344
assert ledger['entry_scene_total']==57 and ledger['fallback_total']==287
path=root/'docs/coherent-game/event-scene-coverage-v2.json'
if args.write_ledger:path.write_text(json.dumps(ledger,ensure_ascii=False,indent=2)+'\n')
else:assert json.loads(path.read_text())==ledger,'Coverage ledger drift: update only after semantic review'
print('PASS exact original CSV entry-scene ledger: 57/344 records, 10 represented families, 287 explicit fallbacks; world selector remains separate')
