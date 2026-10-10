# Remaining B-style art: native acceptance and retained-art inventory

2026-10-09. Recovered baseline tree: `255ce7a05105fb6a05ca745d1eb6eb41d6141eb8`.
This records the completed bounded art pass, its source checks and native visual
acceptance. Controlled fixtures are identified below; no full natural battle,
chapter progression, all-assets-new or Apple-platform pass is implied.

## Included

- Two built-in-imagegen painted deck assets, imported at exactly the legacy
  640×423 ship-deck and 640×569 boarding-deck sizes. Original sprite anchors,
  player/enemy transforms, actor positions and combat actions are unchanged.
  `CombatTheme.deckPath` retains the original file if the replacement is absent.
- Twelve 64×64 transparent common-resource images with at least four pixels of
  empty gutter. The thirteen guarded CSV IDs are coins 1001, wheat 1004, food 1005,
  stone 1006, wood 1007, iron 1008, gold 1009, steel 1011, leather 1017, cloth 1018,
  silk 1019, simple key 1037 and library key 1120. Both keys already shared one
  original icon. Gold ore remains visually distinct from currency.
- `ResourceTheme.applyIcons` runs after resource CSV loading. It changes only
  `iconName` when both the real record ID and its expected original filename
  match and the new file exists. Original CSV bytes, quantities, costs, effects,
  names and save formats are unchanged. Unknown/mismatched/missing-art cases
  preserve the original icon; repeated application is harmless.
- A six-frame 1536×1024 raised-landmark atlas with transparent gutters. It uses
  actual sand, forest, volcanic, ice, violet and ghost layer identities. It
  replaces only previously selected paired/broad decoration candidates, keeping
  their positions, maximum extents, opaque source-land foundations, event spacing,
  fog and layer ordering. It does not replace geographical map artwork. Missing
  or wrong-sized new artwork falls back to the existing decoration atlas.

## Source checks completed

- `resource_theme_regression.lua`: all thirteen mappings, exact non-icon field
  preservation, shared keys, ore/currency separation, absent/mismatched/idempotent
  cases, and both deck fallback paths.
- `remaining_art_semantics_regression.py`: joins every mapping to the decoded
  packaged CSV, checks runtime dimensions, alpha and icon gutters.
- Extended real-TMX world regression passes all sixteen unchanged maps,
  27,206 land cells and 158 flipped cells. New landmark bases stay on their
  original safe foundations, all six theme identities are checked, and absent /
  malformed artwork keeps the previous decor. Existing coast, geometry, z-order,
  flip, event spacing and scale-factor checks still pass.
- `git diff --check` and the final complete aggregate runner pass. GUI
  verification is recorded separately below, not inferred from mocked tests.

## Scope and intentionally retained assets

This is not a claim that every old image was replaced. Existing character and
enemy portraits, rare equipment/material icons, cannons, battle effect sprites,
star images and geographically registered world-chart artwork remain. The
accepted Home, preparation and talent compositions remain intact. The player
ship on the sea already uses the prior B-style `Adventure/ship.png` when present.
Original map ship tiers are compatibility fallbacks. Original uncommon event
states and occupation flags are also retained.

Native review specifically flagged old crew portraits in recruitment and
cemetery as a visible cohesion gap. A follow-on source update now supplies five
64×64 portraits through the same guarded presentation-only pattern: exact
approved 102/107/124 cells are reused, and generated 100/101 portraits retain the
original tricorn veteran and bare-shouldered sailor identity cues. Actual names,
stats, roles and advanced units sharing the old icon filename remain unchanged.
The crew importer and tests verify that the three accepted portraits reuse the
exact source pixels with crop/scale/pad only. New common crew portraits were
reviewed in native UI and boarding screenshots. Common resource icons were
reviewed in native chest/reward contexts; this is not every inventory variant.
The fixed-layout world chart cannot be freely regenerated without moving
registered landmarks.

There are 22 new runtime image files: two decks, two chest states, twelve
resource icons, five crew portraits and one six-frame landmark sheet. The
original package contains 179 standalone icon files and 20 boss images; most
rare/advanced artwork is deliberately retained rather than silently counted as
redrawn. The actual resource CSV uses 125 distinct nonempty icon names and the
soldier CSV uses 42. These counts describe packaged artwork, not native-route
coverage.

## Reproduction

`tools/import_remaining_b_art.py` performs ordinary crop, resize and transparent
padding only. Source masters were generated with the built-in imagegen tool,
then inspected before import; no hand-painted or programmatically synthesized
raster substitutes were used. Full prompts are in `remaining-b-art-prompts.json`.
The generated source names are provenance labels, not runtime dependencies.

## Native-driven chest follow-on

The actual chest screen reached after a controlled boarding victory exposed a
large remaining mismatch: six legacy skull chests had pale yellow glow backing.
Two new, coordinated closed/open wooden/brass skull-lock states now replace
those files through `CombatTheme.chestPath`; absent assets retain the originals.
Both outputs remain 184×239 with transparent gutters. Open interiors stay empty
so real reward icons are still supplied by the original overlay code. Only the
two `MenuItemImage` path lines changed; tap centers, item overlays, callbacks,
probabilities, free opens, diamond costs and reward logic are untouched.
`import_chest_art.py` records the ordinary crop/resize/pad import. Both state
paths and original-size/gutter invariants pass the art regressions. Full prompt
provenance is in `chest-art-prompt.json`. Both new states passed native review.

The native paused boarding screenshot `21-boarding-deck-paused-fixture-480.png`
has been independently inspected: the new deck and 101 crew portrait are visible,
coherent and do not obstruct their native controls. Enemy ghost transparency
comes from the unchanged original fade animation and is acceptable in context.
That scenario deliberately used player HP 100000 and enemy HP 1, so its screenshot
is an art fixture and cannot establish natural combat balance or progression.

## Native art review and final presentation corrections

- `24-map-four-clean-art-fixture-480.png`, `26-map-six-clean-art-fixture-480.png`
  and `27-map-thirteen-art-fixture-480.png` show all six theme landmarks on the
  actual maps with the real HUD. They were independently visually accepted.
  Fog is hidden for review only. Maps 4/6 use final zoom 0.65; map 13 uses 0.8.
  They do not establish natural chapter unlocks or complete progression.
  Final presentation evidence after the atlas-sampler correction supersedes
  them with `44-final-map-four-fixture-480.png`,
  `45-final-map-six-fixture-480.png` and
  `46-final-map-thirteen-fixture-480.png`, using the same fixture/zoom boundaries.
- `33-new-chest-failure-fixture-480.png` and
  `34-new-chest-giveup-fixture-480.png` show the new closed/open art in the actual
  production chest flow. Chest bodies, skulls, reward icons and earned markers
  retain correct relative alignment. Original reward beams are retained as
  reward-state feedback; the old universal yellow chest backing is removed.
- The native Give Up route exposed stale paid-retry wording after only Close
  remained available. `giveUpCallback` now hides both free and paid instruction
  nodes. The production-method regression exercises fresh init, failure cost
  wording, Give Up and a fresh next chest, preserving rewards and balances.
  The cold native repeat `40-final-chest-giveup-fixture-480.png` passes with only
  Close remaining and diamonds unchanged. A fresh chest restored free wording,
  and a subsequent failure displayed the original 2-diamond paid offer.
- `35-ship-deck-paused-fixture-540.png` shows both new decks and original cannon
  anchors at 540×960. The art was accepted; the top white encounter sentence had
  weak contrast over golden wood. A 62-unit existing ink-brush backing now sits
  behind that unchanged sentence, above the original stars, HP and cannon rows.
  The cold native recapture `39-final-ship-caption-fixture-540.png` was visually
  accepted: the sentence is legible and the backing does not cover HP/cannons.
- `41-final-natural-navigation-480.png` is genuine ordinary navigation with
  normal fog/HUD, cold-restored after the actual chapter-2 round trip. It uses
  the final atlas sampler, without artificial currency, map changes or fog
  hiding before the capture. This is separate from the theme fixtures above.
- `48-final-crew-management-480.png` is the actual recruitment UI from the
  tested recruitment/revival save, with no portrait fixture injected. It shows
  the new 100/101/124 portraits in their unchanged native list layout.

The delivered `pirate-b-final-native-overview.png` contains eight clean actual
screenshots: crew management, ordinary navigation, both battle decks, finished
chest, and the three two-theme maps. Chinese labels explicitly identify every
controlled battle/chest/map fixture. Screenshots are never cropped or repainted;
seven 480×800 sources are included pixel-for-pixel and the 540×960 ship source is
uniformly reduced to fit. Four full-size original shots accompany the overview.

The remaining original characters, boss ghosts, rare icons, cannon/effect art,
small legacy event states and registered world-chart artwork are intentionally
retained. Common crew mismatches found in the reviewed screens were replaced;
no all-assets-new claim is made. Further elective art scope is closed for this
pass. Source, focused native art acceptance and final presentation corrections
are complete within the coverage and platform limits above.
