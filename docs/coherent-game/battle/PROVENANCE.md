# Generated battle asset provenance

Date: 2026-10-11. Tool: supported built-in `image_gen.imagegen`, four calls, each `transparent_background=true`. No fallback API/CLI and no Python raster editing. Accepted and rejected outputs were copied unchanged from the tool's returned local paths. Generated masters remain at the returned paths.

The existing Adventure/Combat decks, both legacy cannon views, approved CleanVoyage boat and harbor and the generated full cannon were visually inspected before they were referenced. Deck/cannon target pixels define the original composition and attachment constraints. CleanVoyage boat/harbor define material, lighting and broad low-poly style only. No outside game asset or unverified reference was introduced.

Exact prompts and ordered image-reference roles are preserved in `generation-prompts.json`. No text or UI is baked into the new assets.

| Candidate | Tool source filename | Generated pixels | SHA-256 |
| --- | --- | --- | --- |
| boarding-deck-clean-v1.png | exec-09810571-e694-4a61-96c4-ef28ffff6600.png | 1330×1182 | ba56a6abb959826d7ba80d83f9a1dc39658777db29c2f14fc6e5c459f21e64c9 |
| ship-deck-clean-v1.png | exec-a7e46d1f-a9b2-4d2c-b8ac-f44fd6e6a492.png | 1542×1020 | f4d2a9a5187a8cb4bfc389680347c677ff0814a74bd44c9ffbda22e02da47f05 |
| cannon-full-clean-v1.png | exec-a53a9c0a-f46b-48f0-910c-0c80e86d2d88.png | 927×1697 | e43088fac3baada439c4ab42d1cae57f1f7a4a59af6decb068f5e4364a736ab3 |
| cannon-short-clean-v1.png, rejected direct use | exec-e9dfd39f-a2b4-4e0d-bb20-50e3d86b8d5e.png | 1475×1067 | 6ce0f0c2f2d4495c2275b786fce64efeffac161b13c544e4a8a38a6e602755c0 |

The three accepted PNGs are committed under the repository's
`bin/res/assets/Images/UI/CleanVoyage/Combat/` directory. The rejected short
cannon is intentionally not shipped. All four tool originals remain under
`/workspace/scratch/79976da795e7/generated_images/`; preparation-only copies
(including the rejected candidate) are under
`/workspace/shared/pirate-audit/battle-next/assets/`.

## Geometry and alpha inspection

Pixel bounds use top-left origin and exclusive right/bottom. All four assets are RGBA and have alpha extrema 0–255. Actual alpha is retained, including generated edge feathering. Threshold bounds are measurement tools, not pixel edits or collision bounds.

| Candidate | Alpha > 32 visible bounds | Fully transparent pixel count | Intended logical view |
| --- | --- | --- | --- |
| boarding deck | [0,21,1330,1182] | 322064 | 640×569 bottom-attached deck |
| ship deck | [0,35,1542,1020] | 84242 | 640×423 deck, mirror visual child for enemy |
| full cannon | [114,81,812,1626] | 956139 | 101×185, upright muzzle |
| rejected short barrel | [416,109,1053,961] | 1100545 | Do not use; see rejection below |

The deck bottom edges are continuous and near-opaque, not mathematically alpha-255 everywhere: minimum alpha 248 for boarding and 250 for broadside. Center sample alpha is 253 and 251 respectively. Top-center empty samples are alpha zero. This matches the tool's retained output behavior and is visually acceptable as an art candidate, but final native compositing must check for sea bleed and seams. Do not claim the output alpha mask exactly matches the original. The source files preserve aspect to better than 0.1% for boarding and 0.2% for broadside; normalize into the original logical boxes in presentation code rather than using generated pixel dimensions as coordinates.

Original alpha>32 bounds: boarding B [0,13,640,569], ship B [0,18,640,423], full cannon [12,5,90,182], short cannon [30,5,70,73]. These are retained in the full inventory for attachment comparisons. Neither generated dimensions nor alpha silhouettes should determine gameplay target selection.

## Visual QA result

Accepted as high-quality candidates:
- Boarding deck has polished broad material planes, clean seams, cream canvas and honey rail/wood, with low visual noise. Mast, rigging, rail openings and frame-edge attachment remain recognizable. Center deck is empty of characters/UI.
- Broadside deck retains source rail profile and prop distribution while removing distressed painterly/photographic wear. Top transparency and uninterrupted deck crop are intact.
- Full cannon preserves upright orientation, recognizable barrel/carriage silhouette and family palette. No smoke or flame is baked in. It has two visible wheel faces rather than a guaranteed four independent wheel silhouettes; weapon identity and the original attachment box remain recognizable. Full native overlay/effect acceptance is still required.

Rejected direct use:
- Independently generated short barrel has bottom padding through y1067 after artwork stops near y961, and its muzzle width is too broad for the original relative silhouette. It cannot be substituted solely by filename. The preferred short view is a runtime top crop of the accepted full cannon; this does not modify the PNG and ensures both cannon views match.

## Reproducibility and limits

The preparation-only script
`/workspace/shared/pirate-audit/battle-next/provenance/audit_assets.py` reads the shipped CSV envelope using the repository's established decoder, groups exact IDs/names/icons and measures images with read-only Pillow calls. It writes only that preparation directory. The committed adjacent
`asset-inventory.json` records originals and candidates; the adjacent
`actor-identity-inventory.json` contains 323 exact fighter records grouped into
42 aliases. `ACCEPTANCE.md` records the later implementation and native tests.

Original boss/crew review contact sheets were assembled with ImageMagick montage solely to inspect existing content; they are not new game art or actor replacements. No new semantic actor atlas was generated, and no existing character identity was replaced. No actor body, effect, battle callback, native layout, profile mutation or complete gameplay path has been tested by this preparation task.
