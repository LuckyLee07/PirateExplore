#!/usr/bin/env python3
"""Read-only new service props/provenance and bounded item-art semantics."""
from pathlib import Path
import hashlib
import json
from PIL import Image
root = Path(__file__).resolve().parents[2]
folder = root / 'bin/res/assets/Images/UI/CleanVoyage/Support'
manifest = json.loads((folder / 'service-props-v1.json').read_text())
source = (root / 'bin/res/scripts/LuaClass/ServiceSupportPresentation.lua').read_text()
assert len(manifest['assets']) == 3
for entry in manifest['assets']:
    path = folder / entry['file']
    image = Image.open(path)
    assert image.mode == 'RGBA'
    assert list(image.size) == entry['dimensions']
    assert image.getchannel('A').getextrema() == (0, 255)
    assert hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256']
    assert entry['file'] in source
    assert entry['prompt'] and entry['source']
assert "resume[1]=='2' or resume[1]=='4'" in source
assert "resume[2]=='2005' then return 'lightning'" in source
assert "resume[2]=='2003' then return 'food'" in source
assert "resume[1]=='7' then return 'coins'" in source
assert len(manifest['remainingArtGates']) == 4
print('PASS three original generated RGBA props, hashes/prompts and exact effect-art mappings; four unmatched item-art families explicitly gated')
