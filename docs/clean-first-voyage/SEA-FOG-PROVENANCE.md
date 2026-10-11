# Sea and fog provenance

These two original generated raster assets are copied unmodified from the approved standalone prototype at commit `048b141f80ed04223a7865895abbe175f86a5bbe`. Only their pixels and rendering ideas are reused; real production fog data remains authoritative. Paths in this repository are `bin/res/assets/Images/UI/CleanVoyage/`. The generation records below are preserved from the prototype ASSET-PROVENANCE.md.

- `fog-bank-soft.png`: built-in imagegen, transparent_background=true; copied unchanged from generated_images/exec-566e4492-d3df-45d8-a1f3-0de586aa3b04.png. 1831×859 RGBA; alpha extrema 0–254; 604,235 fully transparent pixels. Prompt: one thick magical ocean fog bank, warm tropical game, painterly softly volumetric 3D, irregular overlapping white/pale icy-blue lobes, rich blue shadow pockets and luminous tops, asymmetric elongated silhouette and ragged feathered translucent wisps, substantial opaque center; no repetitive circles, no outlines, no sea/background/sky/text/UI. Native exploration masking remains separate.

- `sea-turquoise-caustics.png`: supported built-in imagegen, transparent_background=false; unchanged copy of generated_images/exec-9a344882-760d-4be4-8040-bc9fe37094a2.png. 1254×1254 RGB. Prompt: square seamless tileable repeating top-down tropical sea texture, polished warm 3D chibi game; bright cyan/turquoise sunlight, soft broad depth variations and delicate organic submerged caustics, saturated teal deeper patches and luminous turquoise, low contrast mid-frequency beneath separate thin native diamond grid; no shore, objects, boat, cloud, horizon, text, UI, grid, border or breakers. Visually inspected. Tileability was requested, but generated opposite-edge mean RGB differences are x=[13.68,8.01,6.42], y=[17.15,8.57,6.45], so mathematically seamless tiling is NOT claimed. Builder advised single viewport stretch or mirrored sampling and 35–55% native blend for visual restraint.

## Exact copied bytes
- fog-bank-soft.png: SHA-256 `9294c21e5fce5089a95a7287a4a4c8637ff22cb99d04c840cbdca408af559597`
- sea-turquoise-caustics.png: SHA-256 `5c96dcbf6fd17229d6c07e3cf11f6a9409f3397fb1952827178cfce581a1ed3a`
