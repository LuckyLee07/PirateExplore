# Chart camera and edge investigation

Evidence date: 2026-10-09. This follows the two unresolved visual boundaries in
`global-b-cohesion-round2.md`; source checks below are not native acceptance.

## Camera repair

The original drag/recenter limits admitted half a screen outside the map. They
also mixed unscaled TMX dimensions at initial zoom with scaled dimensions after
pinch. `Explore:clampChartPosition` now uses the native map content size times
the actual camera scale for drag, initial scale, pinch and recenter. The map's
real world-to-Explore origin also accounts for the native Layer anchor's scaling
offset; raw Layer position alone is not its rendered lower-left corner. Large maps
cover the chart between the unchanged HUD bands; smaller dimensions center at
the existing minimum zoom. Intentional outer margins use the chart's ink color.

A tagged camera tween is cancelled when explicitly repositioning or changing
scale so its old-scale endpoint cannot overwrite the new clamp. Only that tag
is cancelled; gameplay completion, event and save callbacks remain on their
original owners with their original timing. Terrain, events, collision, fog and
save data are unchanged.

`tools/tests/sea_chart_camera_regression.lua` invokes the production methods and
actual touch callbacks. It passes 384 combinations across all 16 real map
dimensions, four viewport sizes, three zooms and native content factors 1/2.
59,520 edge-cell checks invoke the original `positionForTilePosition` helper at
the application's actual content factor 1 and keep every boundary cell visible.
Factor 2 exercises camera bounds in isolation only: the existing gameplay
conversion uses source tile pixels, so this is not factor-2 gameplay or mobile
compatibility acceptance. Repeated/interrupted scale changes retain unrelated actions. A separate
in-memory movement fixture runs the original explored-water movement branch and
its callbacks after zoom interruption: ready state, event dispatch, fog callback
and saved tile position are preserved. These are runtime-independent checks,
not a native playthrough. The full existing aggregate suite also passes.

## Native camera checks

The disposable native session passed 45 real-transform camera checks on map 1
and 45 on maximum-sized map 13. These cover minimum/default/maximum zoom, repeated
zoom, all four original-helper corner targets and pan limits. Screenshot
`28-max-map-corner-minzoom-fixture-480.png` shows the northeast corner at 0.3 with
the HUD and no exposed off-map strip. These are controlled map/geometry fixtures,
not natural chapter-13 progression. The exact historical top-strip frame was
not recovered for a pixel-matched before/after comparison.

## Internal atlas seam

The initial native session reproduced the older internal line in
`05-sea-vertical-line-before-480.png`. After the viewport correction, a residual
one-tile horizontal segment was isolated in `18-diagnostic-no-fog-480.png` near
y726. Hiding coast, land-fill or grid individually was inconclusive. Hiding the
original `Blocks_1` layer removed the segment (`31`); restoring that layer with
nearest atlas sampling also removed it (`32`). The sampled water-edge crops in
`31-diagnostic-blocks-hidden-no-fog-480.png` and
`32-diagnostic-original-land-alias-480.png` are byte-identical. The corresponding
left segment's mean green channel rises from 118 to 155, matching the adjacent
water. These diagnostic fixtures temporarily hide fog/HUD and are not final UI
screenshots.

The source cause is the replacement texture's sampler: `TMXLayer::setupTiles`
sets nearest filtering on original tightly packed atlases; `applyTileArt` then
loaded a replacement with the default linear sampler. At fractional zoom, a
clear edge in one tile sampled opaque pixels from the adjacent atlas frame.
`SeaChartTheme.applyTileArt` now preserves native nearest sampling for validated,
same-size replacement atlases. No GIDs, tile geometry, alpha images, fog records
or save rules change. Continuous water, painted land and coast targets retain
their own linear sampling. There is no global texture default change.

The production adapter's valid/invalid replacement paths are tested in
`explore_hud_smoke.lua`. `sea_chart_atlas_sampling_regression.py` renders the real
replacement GID91 edge with unmodified UVs/geometry on surfaceless GL: 28
fractional scale/edge-phase cases reproduce neighboring-frame alpha with linear
sampling and keep the originally clear edge fully clear with nearest. Both pass.

Cold-restart verification is complete. `42-final-seam-area-normal-fog-480.png`
shows the chart with normal fog/HUD and the former strong vertical artifact
absent; faint regular chart-grid lines are intentionally retained. The exact
former horizontal-edge tiles are visible inside the chart in
`49-final-chapter-one-gid91-seam-480.png`, with no false horizontal segment. Its
unique `SEAM_FINAL_V1_READY` log confirms map 1, original GID91 at (13,17), fog
hidden for diagnosis, target logical position (230.4,426.8), and no runtime
sampler toggle. This acceptance uses the cold-loaded production sampler fix.
Normal fog and the player's camera were restored afterward. The earlier `47`
capture is rejected: an asynchronous-navigation harness timing failure left it
on chapter 13 and did not display the target tiles.

## Separate outer viewport column

The native 480×800 capture also has a dark final column spanning the HUD and
map. The production aspect calculation yields a 479.999969-pixel viewport width
at 480×800 and 539.999939 at 540×960; integer truncation in
`GLViewProtocol::setViewPortInPoints` discards one rendered column. That method
now rounds origins and dimensions to the nearest device pixel, keeping the
existing design resolution and letterboxing policy. The compiled production-
method regression `tools/tests/viewport_pixel_regression.py` checks seven real
window dimensions, signed fractional origins, integral dimensions and existing
letterboxing. The desktop `GLView` override has the same final rounding, with
its retina and frame-zoom factors retained. The test compiles both actual
production method bodies and also exercises combined retina/frame zoom. It
passes. The native desktop rebuild is complete and the final column renders in
the 480×800 map-13 screenshot `28` and 540×960 ship fixture `35`. This uses the
ship fixture only to verify full-width viewport rendering, not battle gameplay
or final battle-art acceptance. Apple/mobile builds and lifecycle rendering have
not been verified by this repair.
