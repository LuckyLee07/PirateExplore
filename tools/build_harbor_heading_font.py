#!/usr/bin/env python3
"""Build the renamed, OFL harbor heading subset using an existing Noto CJK TTC.

Requires fontTools with Cu2Qu support. No network access or system font install.
Example:
  python3 tools/build_harbor_heading_font.py --source /path/to/NotoSerifCJK-Bold.ttc \
    --license-file /path/to/complete-font-license-notice
The generated font is limited to harbor headings and known game resource/type
names. Body numbers retain the platform serif/ordinary fallback.
"""
import argparse
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools import subset
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--output', type=Path, help='Optional output font path for validation/build staging')
parser.add_argument('--font-number', type=int, default=2, help='SC face index in source TTC')
parser.add_argument('--license-file', type=Path, required=True)
parser.add_argument('--extra-text', type=Path, action='append', default=[], help='Optional decoded data-table glyph coverage')
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
def decode_packaged_csv(path):
    # Same XOR/LZSS envelope as Record.cpp. Only reads original package bytes.
    import re
    key = re.search(r'm_keys = "([^"]+)"', (root/'src/NewPirate/common/UtilTools/Record.cpp').read_text()).group(1).encode() + b'\0'
    raw = path.read_bytes()
    data = bytes(value ^ key[0 if i == 0 else (i-1) % (len(key)-1)+1] for i,value in enumerate(raw))
    width = data[0]
    if width not in (4,8): raise ValueError(f'Invalid CSV envelope: {path}')
    expected = int.from_bytes(data[1:1+width], 'little')
    pos = 1+2*width; ring = bytearray(b' '*4096); cursor = 4078; flags = 0; out = bytearray()
    def emit(value):
        nonlocal cursor
        out.append(value); ring[cursor] = value; cursor = (cursor+1)%4096
    while pos < len(data):
        flags >>= 1
        if not flags & 256: flags = data[pos] | 0xff00; pos += 1
        if flags & 1:
            if pos >= len(data): break
            emit(data[pos]); pos += 1
        else:
            if pos+1 >= len(data): break
            a,b = data[pos:pos+2]; pos += 2; a += (b>>4)*256
            for offset in range((b&15)+3): emit(ring[(a+offset)%4096])
    if len(out) != expected: raise ValueError(f'CSV byte count differs: {path}')
    return out.decode('utf-8-sig')

# Cover runtime wording plus every real table entry, not only visible samples.
text = ''.join(path.read_text() for path in (root/'bin/res/scripts/LuaClass').glob('*.lua'))
text += ''.join(decode_packaged_csv(path) for path in (root/'bin/res/assets/data').glob('*.csv'))
# Preserve all previously shipped glyphs when regenerating the expanded subset.
existing = root/'bin/res/assets/fonts/HarborSerif-Bold.ttf'
if existing.exists(): text += ''.join(chr(cp) for cp in TTFont(existing).getBestCmap())
text += ''.join(path.read_text() for path in args.extra_text)
# Real current roster types plus ASCII and the remaining fixed navigation terms.
text += ''.join(chr(i) for i in range(32, 127)) + '×›←→海盗基地航行船员港务整备出航木盾舵手突击水手船医'
source = TTFont(args.source, fontNumber=args.font_number)
notices = {i: source['name'].getDebugName(i) for i in [0, 13, 14]}
options = subset.Options(); options.layout_features = []
subsetter = subset.Subsetter(options=options); subsetter.populate(text=text); subsetter.subset(source)
order = source.getGlyphOrder(); glyph_set = source.getGlyphSet(); glyphs = {}
for name in order:
    pen = TTGlyphPen(None)
    glyph_set[name].draw(Cu2QuPen(pen, 1.0, reverse_direction=True))
    glyphs[name] = pen.glyph()
font = FontBuilder(source['head'].unitsPerEm, isTTF=True)
font.setupGlyphOrder(order); font.setupCharacterMap(source.getBestCmap()); font.setupGlyf(glyphs)
font.setupHorizontalMetrics(source['hmtx'].metrics)
font.setupHorizontalHeader(ascent=source['hhea'].ascent, descent=source['hhea'].descent)
font.setupNameTable({'familyName': 'Pirate Harbor Serif', 'styleName': 'Bold',
    'uniqueFontIdentifier': 'PirateHarborSerif-Bold-UI-v1', 'fullName': 'Pirate Harbor Serif Bold',
    'psName': 'PirateHarborSerif-Bold', 'version': 'Version 1.0',
    'copyright': (notices[0] or '') + ' Renamed UI subset; outline conversion and subsetting only.',
    'licenseDescription': notices[13] or '', 'licenseInfoURL': notices[14] or ''})
font.setupOS2(sTypoAscender=source['OS/2'].sTypoAscender, sTypoDescender=source['OS/2'].sTypoDescender,
    usWinAscent=source['OS/2'].usWinAscent, usWinDescent=source['OS/2'].usWinDescent, usWeightClass=700)
font.setupPost(); font.setupMaxp()
out = args.output or root/'bin/res/assets/fonts/HarborSerif-Bold.ttf'; out.parent.mkdir(parents=True,exist_ok=True); font.save(out)
license_text = 'Pirate Harbor Serif is a renamed UI subset of Noto Serif CJK Bold. CFF outlines were converted to TrueType for the legacy renderer. The derivative remains under SIL OFL 1.1.\n\n'
license_text += '\n'.join(str(notices[i] or '') for i in [0, 13, 14]) + '\n\n' + args.license_file.read_text()
out.with_name('HarborSerif-LICENSE.txt').write_text(license_text)
print(f'{out}: {out.stat().st_size} bytes, {len(order)} glyphs')
