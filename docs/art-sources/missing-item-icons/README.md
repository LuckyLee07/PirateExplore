# Remaining item icon pass: siege ram and iron sword

2026-10-10. Bounded follow-on to `docs/icon-refinement-audit.md`.

## Audit and identity

1. **1039 攻城冲车** was genuinely missing: its packaged resourceInfo.csv iconName
   parses to a string equal to `''`, as verified using the production CSVParser
   and Utils.split implementations against independently decoded packaged bytes.
   Its description names a siege tool and its recipe uses timber and steel.
   The original generated painting depicts a timber wheeled battering ram with
   a steel striking cap. It does not borrow another item's icon.
2. **1049 铁剑** is an early basic sword whose old 64px w_12.png pixels were
   inspected: narrow shining sword, blue glow, dark framed square. That treatment
   conflicts with the restrained paper-and-ink B inventory. The new unadorned
   straight iron sword retains its diagonal direction, brass guard and brown
   grip, with readable matte metal planes and real transparency.

Both raw imagegen masters and exact prompts are retained here. The wood master
from the preceding accepted icon pass provided a style reference. Mechanical
import is `tools/import_missing_item_icons.py`: alpha>=32 bounds, premultiplied
resize, ordinary RGBA output, unchanged64×64 canvas and4px minimum gutter.
`true-size-preview.png` shows30/40/64px pixels on paper and ink. It is a material
preview, **not** an in-game screenshot. Actual pixels were inspected: the ram's
steel head, wheels and open frame read as a siege machine; the sword retains a
clear blade/hilt split without the legacy glow. Native GUI acceptance is
recorded separately below.

## Central integration and fallback

`ResourceTheme.itemIcons` is a separate explicit ID map. `applyIcons` executes
at the existing `StaticData.lua` resourceInfo load hook, before any consumer
receives the shared resource records. It requires the exact row ID and original
iconName, and a present replacement file. Only in-memory iconName changes;
packaged CSV bytes, names, tiers, descriptions, recipes and every numeric field
stay unchanged. No ItemIcon or FightMode edits are needed.

- 1039 + original empty string -> `B/siege-ram-1039.png`
- 1049 + original w_12.png -> `B/iron-sword-1049.png`
- 1053 and all other shared sword IDs retain original w_12.png byte-for-byte
- Missing new files preserve the old iconName; wrong IDs, nil, unexpected names
  and all unrelated empty strings are untouched. Reapplying is harmless.

Consumers include Repository's ItemIcon.sdButton warehouse row, MakeMode's
manufacturing SDButton, StoreMode's warehouse-capacity production row, event
item cells, and FightMode's ItemIcon.sprite loot rows. They all read the same
resourceInfo record. Existing per-screen fallback is preserved: ItemIcon uses
its neutral bounded slot when no art is supplied, while MakeMode retains its
existing empty-image fallback. No layout, hit-area, economy or gameplay changes.

## Verification

- `missing_item_icons_regression.py` invokes the real Lua CSV parser, verifies
  the actual empty-string type, exact mappings, all non-icon fields, every
  unmapped alias, ID/original guard, absent/nil/mismatched/idempotent behavior;
  checks original shared sword SHA256, alpha/padding and deterministic imports.
- `item_icon_offer_regression.lua` renders1039/1049/1053 using the real production
  warehouse and ItemIcon factories, verifies names, exact images and64px boxes.
- Existing common-resource and key mapping tests remain intact.
- Full aggregate test run and native GUI outcomes are reported separately.

## Native visual acceptance

The assigned GUI owner cold-loaded the completed mapping and captured actual
480×800 screenshots in the2026-10-10 growth-play native evidence directory:
`70-fixture-icons-right-480.png` and `71-fixture-icons-moved-480.png`.
The icon author independently inspected both original-resolution images.

- The controlled loot fixture shows steel sword1053, iron sword1049 and siege
  ram1039 together. Steel sword retains its original blue framed icon. The
  ram's timber frame, wheels and steel striking cap are legible; the basic
  sword's silver-grey blade and plain hilt are distinct. No edge contamination
  or clipping appears on the actual parchment surface.
- Clicking the ram moves it to the left cargo column and raises capacity1→6.
  Clicking the iron sword then moves it left while capacity stays6, preserving
  its original zero volume. Both screenshots retain the correct adjacent names
  and quantities; identities are preserved on either side.
- This accepts the new artwork in native480px loot presentation. These are
  explicitly controlled test fixtures, not evidence of natural drops, native
  manufacturing, all inventory screens,540px or Apple-platform acceptance.
- Full aggregate runner passed after integration. The final additional1049
  guard cases also passed the targeted regression before the code commit.
