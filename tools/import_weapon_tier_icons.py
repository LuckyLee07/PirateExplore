#!/usr/bin/env python3
"""Import original transparent weapon-tier masters with the accepted 64px policy."""
from pathlib import Path
from import_missing_item_icons import render

ROOT = Path(__file__).resolve().parents[1]
NAMES = ('steel-sword-1053', 'sacred-silver-sword-1073')

if __name__ == '__main__':
    for name in NAMES:
        output = ROOT / 'bin/res/assets/Images/Icon/B' / (name + '.png')
        render(ROOT / 'docs/art-sources/weapon-tier-icons' / (name + '-master.png')).save(output)
        print(output.relative_to(ROOT))
