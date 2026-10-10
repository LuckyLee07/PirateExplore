# Explicit weapon-tier icon pass

2026-10-10. Presentation-only continuation of the accepted iron sword1049.
The two final masters use built-in imagegen; exact generation/edit prompts and
source output filenames are in `prompts.md`. No API/CLI fallback was used.

## Authoritative semantic audit

The packaged resourceInfo.csv was independently decoded with the existing
packaged-data decoder and parsed with the production Lua CSVParser and Utils.
All seven rows originally sharing `w_12.png` are:

| ID | Actual name | Tier / actual description | This pass |
|---|---|---|---|
|1049|铁剑|1 / 初级武器|Keep accepted B iron art|
|1053|钢剑|2 / 中级武器|New steel art|
|1065|辰光巨剑|5 / 史诗武器|Keep original shared art|
|1069|夜莺短剑|5 / 史诗武器|Keep original shared art|
|1073|圣银长剑|4 / 顶级武器|New silver longsword art|
|1081|夜莺短剑（重复）|0 / 重复|Keep original shared art|
|1083|辰光之剑|0 / 顶级武器|Keep original shared art|

1053's actual recipe is1011_20;1007_50 (steel and wood).1073's is
1022_90;1007_20 (mithril and wood). The latter name is retained exactly even
though its recipe names mithril; the icon is bright silver-toned metal rather
than an invented faction or magical identity. Ordinary steel material1011
remains the existing `B/r_8.png` and is not this task's steel sword.

## Small-size identity and import

-1053: broader cool steel blade, dark fuller, sturdy squared steel crossguard,
 dark grip and steel pommel; distinct from1049's plain brass hilt.
-1073: bright silver blade, wider open curved silver guard, blue grip and
 strong dark contour. No symbols, jewels, magic effects or background frame.
- The first silver candidate was rejected at30/40px on paper as too thin.
 Built-in image editing widened the blade and strengthened guard/outline;
 only the selected master is committed. The parent independently inspected
 and approved the corrected30/40/64px comparison before runtime integration.
- `tools/import_weapon_tier_icons.py` reuses the accepted alpha-aware importer:
 alpha>=32 bounds, premultiplied-alpha Lanczos downscale to a maximum56px
 extent, centered on an unchanged64×64 RGBA canvas with4px minimum gutter.
 No source color recoloring or global replacement is involved.
- `true-size-preview.png` compares1049/1053/1073 at actual30/40/64px on paper
 and ink. It is a pixel-review board, not a native game screenshot.

## Integration and protections

Only `ResourceTheme.itemIcons` receives two entries:

- exact1053 + original `w_12.png` → `B/steel-sword-1053.png`
- exact1073 + original `w_12.png` → `B/sacred-silver-sword-1073.png`

The existing StaticData resourceInfo hook resolves these in-memory records
before warehouse, manufacturing, store, event and loot consumers read them.
ID and original-path guards and file-existence fallback remain intact. A
missing new file preserves the original icon; unexpected/nil/empty names and
mismatched IDs remain unchanged. Reapplying is harmless. No consumer/layout,
packaged CSV, recipe, stat, cost, quantity, volume or raw original asset changes.

## Verification

- `weapon_tier_icons_regression.py`: exact deterministic64px imports, actual
 RGBA/alpha/padding and minimum silhouette coverage, original shared w_12 hash;
 invokes the production CSV parser and resolver via its Lua companion.
- Lua coverage: exact seven aliases, actual item names, both guarded paths,
 all non-icon fields on every resource row, all unmapped icons, unchanged
 iron identity and1011 material, missing files, mismatched IDs, numeric row IDs,
 nil/empty/unexpected paths and idempotence.
- Updated existing missing-icon regression for17 central mappings and retained
 negative case on the unselected1065 alias. Original ram/iron tests still pass.
- Production warehouse/ItemIcon.sprite/menuItem regression now covers1039,
1049,1053,1073 and unchanged1065 together, including names and64px boxes.
- All four focused suites passed: weapon-tier, missing-item, item-icon-offer,
 resource-theme. Aggregate integration and native GUI acceptance are owned by
 the parent/GUI task and must be reported separately. No GUI test is claimed here.
