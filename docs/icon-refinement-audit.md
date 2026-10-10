# Small-icon audit and first production group

## References actually inspected

- Approved B exploration concept and the precise `06-approved-vs-final.png` comparison, left approved 941×1672 composition (shown at 540px wide).
- The newly rebuilt 540×900 native empty-home screenshot dated 2026-10-10.
- Current `Master/materials.png`, production resource PNGs, and all five new generated masters.

The right half of the historical comparison is older than the current native
geometry. Current port already includes a crate and sail already has curved
contours; neither is described as the superseded house/triangle icon.

## Priority queue: 12 concrete targets

1. Harbor navigation `port`: UI route identity, no CSV item. 48 logical px,
   about40.5 physical px at540 width. Thin warehouse/crate structures need
   stronger recognition. First group implemented and native weight review passed.
2. Supply `food` barrel: displays selected resource1005 食物 (r_2.png in CSV),
   while intentionally using the approved supply-barrel UI symbol. 29 logical /
   about24.5 physical px. First group implemented with broader continuous hoops.
3. Sail `sail`/`ship`: navigation48, plaque34, CTA57 logical px. Existing curved
   vector retained pending comparison; no generic raster substitution.
4. Crew `crew`: roster36 and navigation48 logical px. Existing three-person
   vector retained, dark-on-paper and cream-on-ink checked.
5. Currency1001 金币: CSV r_9.png; Home independently uses120×119 skull-coin
   ornament in40×40 logical box. Existing clear semantic silhouette retained;
   very fine specular texture is lower priority than broken small contours.
6. Currency1002 钻石: CSV r_18.png; Home120×94 gem in40×40 box. Existing faceted
   gem retained. Do not accidentally map currency to1009 金 (ore).
7. Inventory1005 食物: r_2.png,64×64. Old alpha content44×38 at(10,22), causing
   undersized low-positioned bread. New generated loaf+slice, centered56px fit.
8. Inventory1006 石头: r_3.png,64×64. Old46×41 at(9,19); new broad stone planes
   and centered56px fit. Ordinary building stone, never gems/metal ore.
9. Inventory1007 木头: r_4.png,64×64. Old42×34 at(11,26); new three-log bundle,
   visible endgrain and rope, centered56px fit. All three inventory items shipped
   in first group without changing filenames, CSVs, numbers or native boxes.
10. Keys1037 简易钥匙 and1120 图书馆钥匙: both authoritative r_16.png; keep original
    shared identity and mapping. Home31px native key is separate presentation.
11. Weapon1049 铁剑: authoritative w_12.png. Other swords share that old file
    (e.g.1053 钢剑); future replacement must be guarded per ID, not overwrite
    w_12.png globally and inadvertently redefine higher-tier weapons.
12. Crew100 低级船员 /101 水手: CSV j_1.png /j_2.png, guarded B64px portraits.
    Home currently magnifies those64px sources; recover their original generated
    portrait master before improving Home fidelity. Existing107/102/124 use large
    approved individual atlas cells and must preserve identity.

Map landmark atlases remain outside this first group. Their shared cell UVs,
extrusion and event identities need separate native map-size acceptance; no map
object, map path, encounter or semantic mapping is changed here.

## Rendering and import decisions

- Runtime inventory stays64×64 to preserve sprite-dependent layout and touch
  contracts. Navigation masks are128×128 and uniformly fitted into unchanged
  native square nodes. They are standalone padded files, so no shared atlas UV
  can sample a neighbor. Four transparent pixels separate content from edges.
- Bounds use alpha>=32 only for identifying the real silhouette; alpha inside
  the crop is preserved. Some generated master pixels are white but alpha1/255,
  which look alarming in a transparency viewer yet are invisible on real paper
  and ink backgrounds. They are not opaque white contamination.
- Resize filters premultiplied RGBa, then exports ordinary straight RGBA PNG.
  This prevents hidden RGB from contaminating edge filtering. Cocos chooses
  premultiplied/straight blending from the decoded texture; do not double-
  premultiply the saved PNG.
- Navigation exports retain generated alpha as a white-RGB tint mask; runtime
  uses the exact caller paper/ink color. Bilinear min/mag and clamp-to-edge are
  explicit. No mipmap dependency or new renderer/global setting is introduced.
- Missing/failed/zero-size nav images use every existing vector fallback. Other
  five symbol types remain code-native; all negative-space fallback tests stay.

## Evidence and limitations

The Chinese preview `02-inventory-before-after-true-size.png` presents old/new
at equal30/40/64px on both matching ink and paper grounds. It is explicitly
labelled a material preview, not a native screenshot. Final native images below
establish the first group's visual acceptance separately from that preview.

First native inspection: `16-integrated-home-540.png` confirms the24px food
barrel's continuous outline and clean transparency. `22-integrated-inventory-
icons-540.png` confirms all three resources in the actual warehouse, readable
against native paper with correct names. Port was rejected as too light relative
to adjacent navigation; its next generated master increases alpha-covered area
approximately21% without changing128px texture/48px logical node bounds. The
replacement was installed only after the GUI owner confirmed shutdown; the
other four icon PNGs remain byte-identical.

Final native acceptance on2026-10-10: `25-final-icons-home-480.png` (480×800)
and `29-final-icons-home-540.png` (540×900) both cold-load port revision bcb00f4.
The reviewed port is approximately36/40.5 physical pixels respectively. Its
warehouse roof, arched doorway and right-hand crate stay distinct; increased
mass is closer to the adjacent anchor/sail symbols without enlarging its box.
No clipping or transparent fringe was observed. The supply barrel remains
readable at approximately22/24.5 physical pixels. Together with the actual
warehouse screenshot22, all five assets in this first group pass native visual
review. Screenshot filenames belong to the2026-10-10 growth-play native record;
no counts or UI pixels were painted into those screenshots.

Known next issue is explicitly excluded from this acceptance: Home's100/101
portraits still magnify64px thumbnails and visibly blur. Separate identity-
preserving high-resolution candidates have been generated and reviewed, but
are not runtime assets in this first-group checkpoint. Other navigation icons,
weapons and map objects remain future scoped work.

Tests: full existing adventure runner passes at integration time; additional
refined_icons_regression.lua covers present/missing/decode/zero-width/zero-height
at24/29/40/48/64 logical sizes, two tints, exact boxes, filtering and fallbacks.
refined_icon_assets_regression.py checks alpha, padding and deterministic import.
