#!/usr/bin/env python3
"""Conserve 3138685 callers and compare both new actions with original bodies.
No engine, economy, saved data, tables, fonts or established entry routes change.
The legacy RandomEventView is byte-identical after removing one exact opt-in.
"""
from pathlib import Path
import hashlib
import re
import subprocess
from fontTools.ttLib import TTFont
ROOT=Path(__file__).resolve().parents[2]
BASE='3138685614d1d38a5be0b838a5ea04d3bdf8ad47'
OPT_IN="    if require('LuaClass/WarmTheme').enabled() then\n        return require('LuaClass/IntelligencePresentation').mount(self, formatSecondToTimeCn)\n    end\n"
PREFIX='-- init\nfunction RandomEventView:init()\n    if self.warmShortageContext then self.warmShortageContext.retire() end\n    self.warmIntelligenceGeneration=(self.warmIntelligenceGeneration or 0)+1\n    RandomEventView.instance = self\n'
SUFFIX='\n--    DataManager:getInstance():addDiamond(100000)\n\n'
ANCHOR=PREFIX+OPT_IN+SUFFIX
SEALED={'RandomEventMode': '590d813c920c08667125f5615bb613c07f9ec74eec0de43bec57e3cf44683a6a', 'DataManager': '0114f9385ef5beb60c11cdf1a1f45e5e3ecb3bbf14aefc279b0ad10a1f05a1e9', 'MissionManagers': 'ecad8eadeabfc57a90ed6c02bee020b541134c6d9095034f402632750c4c7e80', 'Explore': 'a63a6fb353fc5ad027922c3a73bf3d06e51f3a1bca2de0e1fafaf58e3941e254', 'Talent': '438a4c886d3dfce98f1ee36ed2ca42b400ca42dbbebf43b57ddfb7c898784572', 'Achievement': '553889fcddba6c6f26e11d91c58798255ac4933794dbfdb244e6543a96ae1045', 'WarmTheme': '110907a6ff9dde9bdc12764e3da152a959a6c17fecdda45f96c5802f44919d10', 'WarmShortageOwnership': '35978737046d097cc2160688f363945a55d9e903f5643fe54e65ed8cf861b042'}
current=(ROOT/'bin/res/scripts/LuaClass/RandomEventMode.lua').read_text()
def normalize_dispatch(source):
 assert source.count(OPT_IN)==1,'Missing or duplicated exact intelligence style opt-in'
 assert source.count(ANCHOR)==1,'Intelligence dispatch must follow exact ownership setup and precede legacy boundary'
 return source.replace(ANCHOR,PREFIX+SUFFIX,1)
baseline=normalize_dispatch(current)
for label,index in [('before-retirement',2),('before-generation',3),('before-singleton',4)]:
 lines=PREFIX.splitlines(keepends=True)
 misplaced=''.join(lines[:index])+OPT_IN+''.join(lines[index:])+SUFFIX
 relocated=current.replace(ANCHOR,misplaced,1)
 assert relocated!=current and relocated.count(OPT_IN)==1
 try:normalize_dispatch(relocated)
 except AssertionError as error:
  assert 'exact ownership setup'in str(error),error
  print('PASS sheet normalization rejects dispatch relocation: '+label)
 else:raise AssertionError('Relocated dispatch escaped sheet conservation: '+label)
assert hashlib.sha256(baseline.encode()).hexdigest()==SEALED['RandomEventMode'],'Only the exact presentation opt-in may differ'
# Test-only integration fix: use the existing strict reviewed map2 normalizer.
# It verifies exact anchors, rejects mutation/relocation and restores the original sealed bytes.
import runpy
map2_contract=runpy.run_path(str(ROOT/'tools/tests/coherent_intelligence_return_conservation.py'))
for name,digest in SEALED.items():
 if name=='RandomEventMode':continue
 data=(ROOT/('bin/res/scripts/LuaClass/'+name+'.lua')).read_bytes()
 if name=='Explore':data=map2_contract['normalize_dormant_map2'](data.decode()).encode()
 assert hashlib.sha256(data).hexdigest()==digest,name+' changed outside presentation scope'
print('PASS byte-conserved 3138685 gameplay, ownership, legacy view and entry routes')
ui=(ROOT/'bin/res/scripts/LuaClass/IntelligencePresentation.lua').read_text()
def squash(body):return re.sub(r'\s+','',body.replace('view.','self.').replace('view:','self:'))
for old,new in [('jinbiButton','secondaryAction'),('diamondButton','primaryAction')]:
 original=re.search(old+r':registerScriptTapHandler\(function\(\)\n(.*?)\n        end\)',baseline,re.S).group(1)
 original=original.replace('            if not activeRow() then return end\n','')
 action=re.search(r'  local function '+new+r'\(\)\n(.*?)\n  end\n',ui,re.S).group(1)
 assert squash(original)==squash(action),new+' original callbacks/order changed'
 print('PASS exact original action body after whitespace/owner-name normalization: '+new)
for token in ('addDiamond(', 'addCoin(', 'setRoleData(', 'unlockTallentByKey(', 'saveEvents(', 'saveMissionDatas(', 'purchase('):
 assert token not in ui,'Presentation must not own transactions: '+token
font=TTFont(ROOT/'bin/res/assets/fonts/CleanVoyageSans-Regular.ttf').getBestCmap()
missing={char for char in ui if ord(char)>127 and ord(char)not in font};assert not missing,missing
assert "local W=require 'LuaClass/WarmTheme'" in ui and 'cc.LabelTTF:create'not in ui
print('PASS shared CleanVoyageSans covers every adapter glyph; all labels use shared typography')
# Keep the unchanged aggregate invocation honest against the actual source.
subprocess.run(['python3','tools/tests/coherent_intelligence_return_conservation.py'],cwd=ROOT,check=True)
print('PASS original strict ownership conservation gate on actual source, including exact dispatch counterfactuals')
