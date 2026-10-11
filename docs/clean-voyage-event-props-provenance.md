# Clean first-voyage event prop provenance

Generated 2026-10-11 with the built-in `image_gen.imagegen` tool, one call per prop, each with `transparent_background: true`. Three calls generated new props; a fourth generated the iron-material edit of the quarry raft. No fallback CLI, procedural replacement art, raster postprocessing, uploads, or map edits were used. The PNGs were copied unmodified into the game asset directory. All four have actual RGBA alpha spanning 0 to 255.

## Scope and style references

These are visual replacements for the existing first-map interaction props. Quarry event 3067, iron event 3068, and timber event 3070 remain traversable interaction-sea events: their resources float on compact low rafts. The original tutorial wreck is a broken floating hull. No prop introduces solid island terrain, a collision change, a character, or a new interaction system.

The existing approved `iron-clean-islet.png`, `boat-clean-ne.png`, and `harbor-clean-ne.png` were visually inspected before generation. Their clean dimensional 2.5D facets, warm light, grey rocks, honey-colored wood, and fresh tropical greens informed the prompts. For the first three props they were visual style references, not copied pixels or edit targets. The iron-islet's orange veins and solid island base were explicitly excluded from those props. For the fourth iron prop, the generated quarry raft was the edit target and the approved iron islet was supplied as a material-only reference. Only this iron cargo variant uses rusty mineral seams; it does not use the islet's solid terrain base.

## Renderer guidance

All PNGs are standalone full-texture sprites. Pixel rectangles below use top-left origin; suggested anchors use Cocos normalized bottom-left origin. Suggested widths are full-texture logical widths, chosen for about 100 logical pixels of visible opaque artwork. They are integration starting points and should be visually checked in the real game. The existing logical event tile is 134 × 74. No water/background plate is baked into these images.

### event-quarry-raft-clean-v1.png

- Game role: 3067
- Final path: `bin/res/assets/Images/UI/CleanVoyage/event-quarry-raft-clean-v1.png`
- Original generated source: `generation-id:exec-c3fd0c5b-b925-4395-ade6-13d7856d3191.png`
- Texture dimensions: 1619 × 971
- Visible bounds at alpha > 32: `[72,85,1575,917]`
- Suggested normalized anchor: `[0.5,0.38]`
- Suggested full-texture logical width: 108 pixels
- SHA-256: `2a9e6e9a4b7642e06149a0d92875276f6e062d91d0ed34eeffcdd7c867235900`

Exact generation prompt:

Use case: stylized-concept. Asset type: production 2.5D isometric tropical pirate game sprite. Create exactly ONE isolated prop on a genuinely transparent background with real alpha; no backdrop. Clean dimensional low-poly modeled/rendered art, crisp large faceted planes, softly beveled edges, warm sunlit top-left lighting and restrained ambient occlusion. Match a friendly polished low-poly pirate game with honey-gold wooden boats and neutral grey faceted rocks. Orthographic isometric camera about 30 degrees above horizontal; long object axis lower-left to upper-right. Strong readable compact silhouette at 100 game pixels wide, footprint about a 134 by 74 isometric event tile. Close framing and minimal transparent margins. No characters, text, interface, selection circles, badges, pedestals, ground tiles, solid terrain islands, coastline, sea background, large shadows, ore, gems, crystals or glow. Subject: one very small flat floating cargo raft made of five honey-brown timber planks tied with discreet rope, holding a squat cluster of three plain grey quarry stones and two small rubble pieces. Stones are a little rounded but have clean large low-poly polygon facets, warm neutral light grey top faces and cool grey shaded sides; no orange ore veins or colored mineral speckles. The center stone is only moderately taller than the others; this is a compact obtainable stone cargo resource, not a gigantic geological formation. Raft remains visible along the base edges. Entire prop low and broad, 1.6:1 bounding silhouette. The floating raft touches the waterline but draw no water. Everything fully visible and isolated.

### event-timber-raft-clean-v1.png

- Game role: 3070
- Final path: `bin/res/assets/Images/UI/CleanVoyage/event-timber-raft-clean-v1.png`
- Original generated source: `generation-id:exec-c3bdc87c-5bf9-44d2-8d27-bddefb8bb3bf.png`
- Texture dimensions: 1642 × 958
- Visible bounds at alpha > 32: `[67,46,1611,916]`
- Suggested normalized anchor: `[0.5,0.38]`
- Suggested full-texture logical width: 106 pixels
- SHA-256: `5958fd1aeaf129eae96ded739b9cbd4907ca63df0c8538de1e9aa78a571ecbcf`

Exact generation prompt:

Use case: stylized-concept. Asset type: production 2.5D isometric tropical pirate game sprite. Create exactly ONE isolated prop on a genuinely transparent background with real alpha; no backdrop. Clean dimensional low-poly modeled/rendered art, crisp large faceted planes, softly beveled edges, warm sunlit top-left lighting and restrained ambient occlusion. Match a friendly polished low-poly pirate game with honey-gold wooden boats and neutral grey faceted rocks. Orthographic isometric camera about 30 degrees above horizontal; long object axis lower-left to upper-right. Strong readable compact silhouette at 100 game pixels wide, footprint about a 134 by 74 isometric event tile. Close framing and minimal transparent margins. No characters, text, interface, selection circles, badges, pedestals, ground tiles, solid terrain islands, coastline, sea background, large shadows, ore, gems, crystals or glow. Subject: one compact flat floating wooden cargo bundle/raft made from about five warm honey-brown logs, with three short neatly stacked timber logs on top, two discreet rope ties and a small fresh green palm frond with a few modest tropical leaves caught at one rear corner. Clearly readable cut circular log ends in warm pale wood. Polished clean wood facets with only two or three broad wood-grain accents, not photoreal noise. No palm tree, no trunk growing out of earth, no soil. Low broad silhouette about 1.7:1 bounding silhouette. The floating timber prop touches the waterline but draw no water. Everything fully visible and isolated.

### event-wreck-hull-clean-v1.png

- Game role: original tutorial wreck
- Final path: `bin/res/assets/Images/UI/CleanVoyage/event-wreck-hull-clean-v1.png`
- Original generated source: `generation-id:exec-2383a87a-e7eb-41d4-b63b-1b061d309887.png`
- Texture dimensions: 1672 × 941
- Visible bounds at alpha > 32: `[182,29,1537,915]`
- Suggested normalized anchor: `[0.5,0.4]`
- Suggested full-texture logical width: 123 pixels
- SHA-256: `f205002fef3f39c2022c816fa16f01720e1f2f41cb16745106bfeac540e6c9c8`

Exact generation prompt:

Use case: stylized-concept. Asset type: production 2.5D isometric tropical pirate game sprite. Create exactly ONE isolated prop on a genuinely transparent background with real alpha; no backdrop. Clean dimensional low-poly modeled/rendered art, crisp large faceted planes, softly beveled edges, warm sunlit top-left lighting and restrained ambient occlusion. Match a friendly polished low-poly pirate game with honey-gold wooden boats and neutral grey faceted rocks. Orthographic isometric camera about 30 degrees above horizontal; long object axis lower-left to upper-right. Strong readable compact silhouette at 100 game pixels wide, footprint about a 134 by 74 isometric event tile. Close framing and minimal transparent margins. No characters, text, interface, selection circles, badges, pedestals, ground tiles, solid terrain islands, coastline, sea background, large shadows, ore, gems, crystals or glow. Subject: a small broken wooden rowboat hull floating as salvage wreckage, NO people. One partial honey-brown boat hull with visible ribs and snapped planking, its bow still recognizable at upper right and a broken open stern at lower left. Three broad loose wood plank fragments float close beside it in a tight footprint; one short broken spar lies diagonally inside the hull. No intact tall mast, no sail, no flag, no treasure, no skull, no skeleton. Warm weathered amber wood with broad darker interior facets, clean softened broken edges without tiny debris noise. Low broad silhouette about 1.8:1 bounding silhouette. Hull touches the waterline but draw no water. Everything fully visible and isolated.

### event-iron-raft-clean-v1.png

- Game role: 3068
- Final path: `bin/res/assets/Images/UI/CleanVoyage/event-iron-raft-clean-v1.png`
- Original generated source: `generation-id:exec-1461d06e-881e-4e9f-a352-fb3a944b6a86.png`
- Texture dimensions: 1619 × 971
- Visible bounds at alpha > 32: `[71,83,1575,917]`
- Suggested normalized anchor: `[0.5,0.38]`
- Suggested full-texture logical width: 108 pixels
- SHA-256: `446d355b4e0bf30f514ffee542626f2400e18a68eccd25162c73a6c0fc8e4aca`
- Editing inputs: quarry raft target and approved iron islet as material-only reference. Only the stone material was varied; the raft composition was retained.

Exact generation prompt:

Use case: precise-object-edit. Asset type: production 2.5D isometric tropical pirate game sprite. Input image 1 is the target: a compact low floating quarry-stone cargo raft. Input image 2 is a material reference only: the approved iron islet. Create the IRON ORE resource variant of image 1 by changing ONLY the stone material. Add a few broad subtle rusty orange and ochre iron-mineral seams on the three larger grey faceted stones, inspired by image 2, and very modest mineral color on the two rubble pieces. Keep grey rock as the majority of each stone, with warm beige-lit top facets and cool grey shaded facets. Preserve image 1's exact raft, rope, stone shapes and placement, proportions, orthographic 30-degree isometric camera, top-left lighting, honey-gold wood, compact low silhouette, framing, and clean polished low-poly rendering. This is a floating cargo resource on traversable sea, not terrain. Do not copy any island, grass, soil, foliage, ground, coastline, or background from image 2. No gold nuggets, gems, crystals, neon, UI, text, characters or water. Genuinely transparent background with real alpha; preserve transparent isolation and minimal margins. Exactly one prop.


## Verification

The generated outputs were visually inspected for subject, isometric orientation, style, transparent isolation, and absent forbidden content. A read-only Pillow inspection verified the dimensions, alpha extrema, visible bounds, and file digests. Quarry shows plain grey stones without ore; iron varies that same cargo raft with rusty mineral seams; timber includes a modest leaf accent; wreck is an empty broken hull with nearby debris. Metadata is also available in `bin/res/assets/Images/UI/CleanVoyage/event-props-clean-v1.json`.
