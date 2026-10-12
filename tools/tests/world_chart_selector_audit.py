#!/usr/bin/env python3
"""Narrow selector conservation and glyph audit; no changed shared fonts/assets."""
from pathlib import Path
import hashlib
import re
from fontTools.ttLib import TTFont
root=Path(__file__).resolve().parents[2]
legacy=(root/'bin/res/scripts/LuaClass/WorldMapLayer.lua').read_text()
selector=(root/'bin/res/scripts/LuaClass/WorldChartSelector.lua').read_text()
def between(source,start,end):
    a=source.index(start)
    return source[a:source.index(end,a)]
old_names=re.findall('"([^"\n]+)"',between(legacy,'local names = {','local chapterString'))
new_names=re.findall("'([^'\n]+)'",between(selector,'S.names={','function S.enabled'))
assert len(new_names)==16 and new_names==old_names, 'Original chapter identity/order changed'
expected={
 ('function getMapShopInfoByMapIndex','WorldMapLayer = class'):'e1a9eb0f2020ff26dea15534702970db92cb44fe6e77f78b546448844666f6d7',
 ('function WorldMapLayer:unlockMapDatas','--解锁动画'):'9101e7eba709f5664381c303e8aa1c3754e5a129200c44005427572d8a72ab8e',
}
for (start,end),digest in expected.items():
    assert hashlib.sha256(between(legacy,start,end).encode()).hexdigest()==digest, start+' original transaction changed'
for contract in ['if index > self.mapMaxIndex  or self.statue ~= "ready" then',
                 'self.owner:enterNextMapEnter(false,index,true)',
                 'self.owner:enterNextMapEnter(true,index)',
                 'self.owner:enterNextLayer(false)']:
    assert contract in legacy,contract
font=TTFont(root/'bin/res/assets/fonts/CleanVoyageSans-Regular.ttf').getBestCmap()
missing=sorted(c for c in set(selector) if 0x3400<=ord(c)<=0x9fff and ord(c) not in font)
assert not missing, 'Missing unchanged clean font glyphs: '+''.join(missing)
assert "if WorldChartSelector.enabled()then return WorldChartSelector.build(self)end" in legacy
assert "getMapShopInfoByMapIndex" in selector and 'purchase(' not in selector
print('PASS original 16 identities, exact shop lookup/unlock transaction bodies, route gates, legacy opt-out, and unchanged font glyph coverage')
