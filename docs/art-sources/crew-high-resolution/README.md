# Identity-preserving large portrait reconstruction

The original generated100/101 high-resolution source was unavailable locally.
Exact source-filename/ID-fragment and crew-pair/common-crew/crew-100/crew-101
Library title searches plus tricorn/bald-sailor content searches did not recover
it. These are new built-in-imagegen reconstructions, NOT recovered originals and
NOT enlarged/sharpened64px files.

Both actual64px production portraits were visually inspected before generation.
The references were those exact identity images plus the approved
`Master/crew-trio.png` for paint style only. The approved trio's professions,
props and costumes were not substituted into100/101.

-100 低级船员: brown tricorn, grey scruffy hair/beard, cream shirt, brown leather
 vest/diagonal strap, weathered tan face oriented slightly screen-right.
-101 水手: bald head, dark beard, deep brown skin, broad bare muscular shoulders,
 diagonal brown leather straps, slightly screen-right head orientation.

Raw masters retain original imagegen alpha and metadata:

- `crew-100-master.png`:1278×1230, source exec-ddec49e3-2b3a-431e-811d-d2dcce27f3aa.png.
- `crew-101-master.png`:1402×1122, source exec-5711dfce-1880-4f52-a0a9-9dc5ad71ee9f.png.

## Import / runtime

Run `python3 tools/import_large_crew_art.py`. A meaningful alpha bound is cropped
without replacing pixels; premultiplied-alpha Lanczos reduction sets the longest
content edge to512px. Eight transparent pixels are added on every edge. Ordinary
straight RGBA runtime outputs are528×505 and528×438 respectively, preserving
their different original aspect ratios.

Only `MasterTheme.portrait` requests larger than64px try these independent files.
The same native w×h node, uniform aspect-preserving fit, centered X and bottom
anchor are retained. Bilinear/clamp texture sampling is explicit. Missing,
undecodable or zero-size large art falls back to the correct existing64px
portrait. Missing both remains neutral. Other professions keep their approved
atlas crops. No ResourceTheme/CSV/combat/list icon mapping is changed; all five
existing64px B crew files are byte-identical.

The Chinese comparison04 shows equal185px and64px candidate previews, clearly
labelled as reconstruction candidates rather than screenshots. Runtime acceptance
is established separately below.

## Final native review (2026-10-10)

- `30-natural-portrait100-540.png`:540×900, actual natural profile, selected100.
  Compared at the same native position with `29-final-icons-home-540.png`, the
  tricorn edge, face, beard and leather strap are clear. Hat/shoulders remain
  within the original roster region and do not touch the name or locked slots.
- `31-fixture-portraits100-101-480.png`:480×800, isolated QA fixture displaying
  both100 and101. This is explicitly not natural recruitment/progression.
  The bald101 sailor and tricorn100 veteran retain distinct identities, align
  at the existing portrait baseline, and fit their separate blue brush areas.
  Neither portrait collides with its name or the third locked slot. No opaque
  background or light/dark transparency fringe is visible.
- The existing five64px icons and original ResourceTheme/CSV mappings remain
  unchanged. This acceptance covers large Home display, not a combat reskin.

Both above screenshots were visually inspected. The comparison
`06-natural100-native-before-after.png` contains direct510×184 crops of the same
roster region from29/30, without resizing or painting screenshot pixels. It is
labelled as540px native evidence, with natural resource-number variation noted.

Validation: existing adventure runner273PASS lines at integration time; separate
large_crew_portrait_regression.lua covers present, missing-high, decode-high,
zero-high, missing-small, both-missing and all-decode cases, plus strict isolation
of64px requests. large_crew_assets_regression.py verifies true RGBA, padded
resolution, deterministic import and unchanged small-icon hashes. No native
GUI control or QA/save edits were performed by the art worker.

## Generation prompts

All calls used the built-in imagegen tool and transparent_background=true.

###100

Use case: identity-preserve / style-transfer. Image1 is the CURRENT EXACT
character identity to redraw at higher quality, NOT a generic pirate. This is
ID100 low-rank crew: middle-aged-to-older weathered male pirate, large worn brown
tricorn hat with irregular bent brim and slight ochre edge, shaggy grey-brown
hair, thick scruffy grey moustache and beard, tan skin, rough friendly-veteran
expression, cream open-neck shirt with folded collar, old brown leather vest
and diagonal brown strap. Keep image1 face direction slightly toward viewer's
RIGHT, body and shoulders broadly frontal, same bust crop mid-chest. Image2 is
approved B hand-painted gouache style reference ONLY, do NOT copy any of its
characters, headscarves, wheel, sword or doctor tools. Reconstruct image1
faithfully with confident ink-contour/gouache planes, expressive eyes, clear
nose/beard separation and readable hat silhouette. Intended for native185px
roster portrait plus64px thumbnail. High resolution clean character art, not
sharpening/upscaling the low-resolution file. Full hat and shoulders inside
frame with breathing room, no hands, no props, no new jewelry, no badges, no
text, no square background tile, no decorative frame. True transparent
background, clean transparent cutout. Maintain warm sunlit palette, muted cool
shadow planes and rough but restrained painterly details matching image2. Do
not make character younger, glamorous, anime, photorealistic or toy-like.

###101

Use case: identity-preserve / style-transfer. Image1 is the CURRENT EXACT
character identity to redraw at higher quality, NOT a generic pirate. This is
ID101 sailor: strong broad muscular adult male with deep brown skin, completely
bald/shaven head, short dense dark beard and moustache, heavy brow, serious calm
expression, bare chest and bare shoulders, old rough brown leather straps
crossing diagonally over chest with modest small brass buckles. Preserve image1
gaze/head direction slightly toward viewer's RIGHT, broadly frontal torso and
same mid-chest bust crop. Image2 is approved B hand-painted gouache style
reference ONLY; do not copy its three characters, headscarves, clothing, wheel,
sword or doctor's props. Reconstruct image1 faithfully with confident
ink-contour and gouache painted planes, expressive eyes and clear face structure,
warm sunlit highlights and muted cool-brown shadows. Intended for native185px
roster portrait and64px thumbnail; high-resolution newly painted character art,
NOT sharpening/upscaling tiny source. Full head and shoulders inside frame with
breathing room. No hands, no weapons, no added clothing or headwear, no earrings,
no tattoos, no badges, no text, no frame or square background tile. True
transparent background with clean cutout edges. Keep this character's identity
and powerful silhouette without glamorizing or making anime, photorealistic or
toy-like.
