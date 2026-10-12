# Boarding body provenance

The four shipped `body-ID-v2.png` files live under
`bin/res/assets/Images/UI/CleanVoyage/Combat/Actors/`. `assets.json` beside this
document records their original generated-image paths, exact SHA-256 hashes,
dimensions, alpha range and visible alpha bounds. `generation-prompts.json`
records the four v2 imagegen prompts. `reference-chain.json` identifies the
inspected portrait, exact-ID v1 study hash and accepted deck reference used in
each refinement. PNGs are copied byte-for-byte; no painting,
cropping, resampling, recoloring or background cleanup is baked into them.

All four were generated through the built-in imagegen tool with transparent
background requested. Fully transparent outside pixels can retain hidden RGB;
native composition uses alpha. A separate native DrawNode supplies the contact
shadow. The runtime normalizes each body's measured visible height and boot
anchor, and mirrors the enemy visual once.

The v2 identity reference was the previous full-body study for that exact ID,
which had itself used the shipped exact portrait. The style reference was the
accepted clean boarding deck from `../battle/PROVENANCE.md`. The v2 enemy prompts
also used the v2 ID100 illustration strictly as the clean material/proportion
reference. Original portraits were visually inspected before generation. V1
studies are not shipped: they were judged too gritty when minified and remain
only in the external preparation archive. They are not alternate semantic
mappings and are never selected by the game.

No generic face/species is substituted for an unsupported ID. See
`../battle/actor-identity-inventory.json` for the raw CSV identity/alias inventory
and `ACCEPTANCE.md` for the four explicit guards and remaining art coverage gaps.
Generation preserves the distinctive portrait species/outfit while inventing
the previously absent lower-body details; those additions are a bounded art
interpretation, not pre-existing canon asserted from a portrait.
