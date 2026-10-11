# Reverse-direction boat asset provenance

Generated October 11, 2026 with the supported built-in imagegen tool, using `transparent_background=true` and the existing `bin/res/assets/Images/UI/CleanVoyage/boat-clean-ne.png` as the sole inspected image-edit reference. The asset is a newly rendered opposing three-dimensional view, not a rigid two-dimensional rotation or mirrored copy.

## Deliverable

- `bin/res/assets/Images/UI/CleanVoyage/boat-clean-sw.png`
- Unmodified copy of `generated_images/exec-a4569281-c396-4b93-8f30-8482e5d91899.png`
- 1293 × 1216 pixels, RGBA
- Alpha extrema 0–255; 984,983 fully transparent pixels
- Suggested lower-hull waterline registration anchor: normalized **(0.50, 0.105)**, with y increasing upward, approximately source pixel (647, 1088) from the top left. This is an art-estimated integration anchor, not a physically measured water plane. Test alongside the NE boat's existing (0.48, 0.105) anchor.
- Bow points toward lower left (SW); transom and stern are upper right (NE). Upright mast; both pirates coherently viewed from behind, captain at stern.
- Preserves honey timber, cream sail with blue edging, broad clean low-poly-style planes, modest adult-proportioned figures, elevated isometric camera, and warm upper-left lighting.
- No baked water, foam, wake, scenery, or external cast shadow. Generated alpha was preserved without background removal or pixel editing.

## Visual validation

Inspected the reference and final image with the image viewer. The bow is foreground lower-left, with the bow-facing hull plane correctly newly visible. The rear-facing captain remains in the upper-right stern; the rear-facing blond mate stands nearer midships. The new geometry is coherent for the reverse travel heading and the mast is still vertical. Character, sail and plank details are regenerated and are not pixel-identical to the reference, as expected for a generated opposing view.

## Exact prompt

Use case: precise-object-edit. Asset type: transparent native isometric game sailboat sprite. Input image is the exact design reference and edit target. Re-render this same three-dimensional boat and the same two occupants after a 180-degree turn on the flat water plane. Keep the camera and its upright screen vertical direction fixed: elevated orthographic isometric view, roughly 45 degree elevation. The pointed bow must now aim toward SCREEN LOWER LEFT (southwest) and be nearest the viewer, while the flat transom stern must be SCREEN UPPER RIGHT (northeast), farther from the viewer. This is a true new 3D view of the rotated boat, absolutely not a 2D image rotation, not a simple mirror. The mast stays upright vertically in the image. Preserve the exact honey timber hull, modest deep hull size, broad low-poly material planes, cream triangular sail with narrow royal-blue outer edging, single simple mast, soft internal shadows and warm upper-left daylight. Keep exactly the two same small adult-proportioned pirates onboard: black-tricorn captain in muted blue shirt at the stern, blond mate in cream shirt nearer midships, small heads around one-fifth body height. They turn coherently with the boat and can be seen from rear or three-quarter rear. The stern, captain, and transom are now at upper right; the pointed prow at lower left is clearly visible in the foreground. Match apparent scale and same slim tall sail. Fit the entire boat, mast, sail and characters with a small clear margin; do not crop. Fully transparent background, preserve genuine alpha. No sea, ground, foam, wake, external cast shadow, scenery, text, UI, border, logo, new characters, weapons or extra decoration.

## Additional NW and SE heading views

Generated October 11, 2026 with the supported built-in imagegen tool, each a separate call with `transparent_background=true`. Both inspected existing NE and SW assets were supplied as image references. Each deliverable is an unmodified generated PNG, with genuine alpha preserved. No file mirroring or planar rotation was used.

### Northwest

- `bin/res/assets/Images/UI/CleanVoyage/boat-clean-nw.png`
- Source: `generated_images/exec-b7b4f7b8-5d25-44a0-985a-fdc1830680f2.png`
- 1293 × 1216 RGBA; alpha extrema 0–255; 1,103,342 fully transparent pixels
- Solid-content bounds (alpha ≥ 128): (207, 4)–(1141, 1199), top-left source coordinates; visible width 934 pixels
- Suggested lower-hull waterline anchor: normalized **(0.52, 0.175)**, y-up, approximately pixel (672, 1003)
- Full-sprite render width **0.998 × NE render width** gives the same visible horizontal artwork width as the NE's 932-pixel solid width. This is a silhouette-width normalization rather than proof of identical physical dimensions; tune visually in the map.
- Bow clearly upper-left; flat transom and captain lower-right; rear three-quarter pirate views coherent with this heading. Mast vertical, lighting from upper-left, same honey timber and cream/blue sail. More of the left-facing hull is visible. No sea or wake.

### Southeast

- `bin/res/assets/Images/UI/CleanVoyage/boat-clean-se.png`
- Source: `generated_images/exec-2a45796b-408a-4f22-8b5a-ccad3b0b1b23.png`
- 1293 × 1216 RGBA; alpha extrema 0–255; 968,224 fully transparent pixels
- Solid-content bounds (alpha ≥ 128): (128, 6)–(1188, 1196), top-left source coordinates; visible width 1060 pixels
- Suggested lower-hull waterline anchor: normalized **(0.50, 0.15)**, y-up, approximately pixel (647, 1034)
- Full-sprite render width **0.879 × NE render width** gives the same visible horizontal artwork width as NE. This is silhouette normalization; tune visually in the map.
- Bow clearly lower-right; stern and captain upper-left; front three-quarter pirate views coherent with heading. Upright mast, fixed upper-left lighting, cream/blue sail, matching honey timber. No sea or wake.

### Integration notes

Anchor locations are art estimates near the middle lower hull, not measured geometry. All assets retain generated, slightly different framing and silhouette proportions. The original NE solid-content width is 932 px. The SW solid-content width is 1041 px, so its corresponding equal-visible-width render multiplier is **0.895 × NE**. Avoid changing texture x-scale sign: the four painted headings now provide light-consistent alternatives directly.

### Exact NW prompt

Use case: precise-object-edit. Asset type: transparent native isometric game sailboat sprite. Inputs: image 1 is the northeast-heading original design; image 2 is the southwest-heading reverse view of the same boat. Use both as exact coherent design references. Re-render this same three-dimensional honey timber sailboat and exactly the same two small adult-proportioned pirates from the specified new heading. This is a newly rendered three-dimensional view with correctly consistent lighting, absolutely not a two-dimensional mirror or rotation. Camera is fixed elevated orthographic isometric, roughly 45 degree elevation; the mast stays upright vertical on screen. Preserve the exact modest deep honey timber hull with two broad seats and simple broad planks, same single mast, slim tall cream triangular sail with narrow royal-blue outer edge, broad clean low-poly material planes, restrained bevels, and soft internal shadows. Preserve exactly the black-tricorn captain in muted blue shirt at the stern and blond mate in cream shirt nearer midships. Heads are small around one-fifth body height, same adult proportions and clothes. Position and face both coherently with the boat, allowing partial sail occlusion. Warm key daylight remains from SCREEN UPPER LEFT regardless of boat heading, with darker planes facing lower right: do not mirror lighting. Preserve same perspective, scale, hull proportions and amount of detail as the references. Fit entire boat, mast, sail and characters with small clear margin; no crop. Fully transparent genuine alpha, no background, sea, wake, foam, external shadow, scenery, ground, text, logo, weapons or extra people. Required heading: pointed bow is SCREEN UPPER LEFT (northwest) and farther from the camera; flat transom stern is SCREEN LOWER RIGHT (southeast) and nearer the camera. Hull long axis clearly runs top-left to bottom-right. Captain at the lower-right stern, mate just behind mast. The reference boat is turned ninety degrees on water into this heading, while lighting stays at screen upper-left. Output one northwest-heading boat only.

### Exact SE prompt

Use case: precise-object-edit. Asset type: transparent native isometric game sailboat sprite. Inputs: image 1 is the northeast-heading original design; image 2 is the southwest-heading reverse view of the same boat. Use both as exact coherent design references. Re-render this same three-dimensional honey timber sailboat and exactly the same two small adult-proportioned pirates from the specified new heading. This is a newly rendered three-dimensional view with correctly consistent lighting, absolutely not a two-dimensional mirror or rotation. Camera is fixed elevated orthographic isometric, roughly 45 degree elevation; the mast stays upright vertical on screen. Preserve the exact modest deep honey timber hull with two broad seats and simple broad planks, same single mast, slim tall cream triangular sail with narrow royal-blue outer edge, broad clean low-poly material planes, restrained bevels, and soft internal shadows. Preserve exactly the black-tricorn captain in muted blue shirt at the stern and blond mate in cream shirt nearer midships. Heads are small around one-fifth body height, same adult proportions and clothes. Position and face both coherently with the boat, allowing partial sail occlusion. Warm key daylight remains from SCREEN UPPER LEFT regardless of boat heading, with darker planes facing lower right: do not mirror lighting. Preserve same perspective, scale, hull proportions and amount of detail as the references. Fit entire boat, mast, sail and characters with small clear margin; no crop. Fully transparent genuine alpha, no background, sea, wake, foam, external shadow, scenery, ground, text, logo, weapons or extra people. Required heading: pointed bow is SCREEN LOWER RIGHT (southeast) and nearer the camera; flat transom stern is SCREEN UPPER LEFT (northwest) and farther from the camera. Hull long axis clearly runs top-left to bottom-right. Captain at the upper-left stern, mate just behind mast. The reference boat is turned ninety degrees on water into this heading, while lighting stays at screen upper-left. Output one southeast-heading boat only.
