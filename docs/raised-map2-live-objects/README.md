# Dormant live map2 object adapter

This isolated component is based on `e1e7fd8bddc960afe5a650092cb16bb7d7a98ebc`.
`RAISED_MAP2_LIVE` remains **off by default**. No engine, Explore, other page,
original TMX/atlas/CSV, gameplay or save module changed. The inherited base's
recovery-shortage ownership HOLD is unrelated and is not repaired or accepted
by this component. Integrate only onto the separately reviewed corrected base.

## Exact import and authority

`RaisedSeaObjectPresentation.lua`, its six runtime PNGs, retained master and
import metadata/recipe are byte-identical imports from object prototype
`62790b07a29f1c2ccdef84d4b319264e48b61532`. Shipped CSV checks cover 36 exact IDs:
port3001, world-chart3002, resurrection3003, taverns3004–3019, arenas3036–3051,
and gateway3052. In particular, world-chart and next-area gateway retain their
separate original IDs, labels and callbacks. Signed/unknown/generic IDs, occupied
enemies sharing GID48 and callback disagreement retain native drawing.

`RaisedSeaMap2.lua` has **only the two approved wall-color substitutions**:
upper wall218/198/161→231/211/174 and lower wall200/183/150→184/167/134.
All geometry, source-alpha topology, `options.liveOverlay`, `options.model`,
original Meta/player/fog ownership and input projection are retained.

`RaisedSeaMap2ObjectsLive.lua` adds presentation groups inside the existing
hard-known ground-plane clip. The groups are not added to `view.eventSprites`,
so no replacement silhouette becomes a hit target. Scale, contact ellipses and
support plane match the prototype. Original port(15,15), chart(18,15) and
resurrection(15,12) remain WATER with support0. No connecting land, coast,
collision or source coordinate is created.

## Native visual leases and fallback

Only source sprite rendering visibility is leased. The sprite stays owned by
its original TMX batch and is retained while leased. Its opacity, color,
transforms, GID/flags, actions and model fields are untouched. Lua visibility
requests are remembered and reflected immediately; visibility readers retain
the requested value. The latest requested visibility and original Lua peer
methods are restored on release, fallback and cleanup, including initially
hidden/translucent nodes. Object opacity/color mirror the native sprite.

Native `runAction` restores the source visual **before** starting the original
action; an actively animated site conservatively uses original artwork.
Missing art never suppresses its native source. The legacy engine materializes
an unflipped sprite for a previously unmaterialized flagged batch quad, so that
case also stays entirely native; the adapter does not materialize/reinterpret
it. Already materialized actors preserve their existing native flags/transform.

Meta mutation releases the old cell lease before native set/remove, including
same-cell GID/identity/state replacement and new actors after removal. Pure
record identity/state changes at existing event cells are checked by the
observer. Fog mutations synchronously suppress stale groups until the clipped
view rebuilds. Partial cells keep native source art; native fog/fade nodes and
actions remain authoritative. Whole-map geometry is rebuilt only on existing
invalidation, reusing the original immutable model.

Cleanup removes leases, peer hooks and owner references even when the parent
is destroyed without a route toggle. No dying actor is reparented in cleanup.

## Local equal-Z ordering repair

The old adapter added its root beside original equal-Z land/coast nodes. This
Cocos version resets arrival order after rendering and uses unstable std::sort.
A later insertion therefore reordered native siblings and changed coast pixels
on unmount, despite unchanged local Z. The frozen e1e7 counterfactual reproduces
this without the new objects.

`RaisedSeaMap2Live.lua` now temporarily ranks existing map children only around
its own root insertion/removal, explicitly sorts once, then restores their prior
arrival values. This is a local presentation operation, not an engine/global
sort change. Native child identity/order/local-Z and dynamic route/glow
positions, parents and actions are verified through six toggles.

## Verification

Evidence: `/workspace/shared/pirate-audit/live-map2-object-adapter/`.
`VERIFICATION.json` binds exact source/PNG hashes and the component result.
The reused headless EGL binary is the independently built e1e7 native fixture;
its donor/build provenance remains in `map2-integrated-native-build/BUILD_RECEIPT.json`.
No desktop GUI, personal profile, live payment, activation or publication ran.

- Existing native controller fixture: 2,883 original/live transforms, identical
  arrow/touch movement, food, event/occupation and blocked-coast traces, native
  fog action identity, pause/save/resume and zero presentation-save writes.
- Object fixture at480×800 and360×640: six exact visual-property restorations;
  initial hidden/opacity/color handling; source actions; occupancy/rebind/hide;
  flags; removed actor/new actor; missing-asset and active whole-view fallback;
  source sibling/local-Z and dynamic route/glow ownership.
- Exact-camera before/after toggle images and all six alternating active/paused
  context images are pixel-identical at both sizes. New object groups change
  zero sampled unknown-fog pixels:184,443 at480 and97,138 at360. The controller
  separately samples638,309 unchanged partial/unknown pixels.
- Context runs retain35 DrawNodes/35 listeners, maximum1 per node; VBO names
  remain77 active/66 paused. Final parent cleanup has0 DrawNodes/0 listeners
  (8 unrelated fixture/renderer buffer names remain).
- Original controller context baseline, GPU texture equality/lifetime checks,
  shipped-CSV semantics, retained asset hashes/contact and the existing
  adventure UI aggregate pass. The aggregate includes only synthetic billing
  mocks; it makes no real charge.

### Honest capture boundaries

The first exploratory run alternated framebuffer dimensions and repeatedly
recentered through the production inverse-transform camera. Keep `objects/`,
`fixed-recentering-*`, `pre-order-fix/`, `mixed-original/`, `mixed-geometry/`,
and `equal-z-base/` as diagnostics, not accepted captures.

The never-enabled native route itself differs in its first mixed480 capture.
The geometry-only live counterfactual additionally reproduces equal-Z sibling
reordering and floating camera shifts of approximately0.000061 source points.
The local ordering defect is fixed. Final recovery captures hold the exact
native camera matrix constant; they do not silently round, crop or alter image
pixels. Repeated recenter/resize behavior is recorded separately and **not**
claimed as production desktop-window resize acceptance. Independent desktop,
full-session/combat, device/mobile-GPU/performance and later-map acceptance
remain separate gates. The component is map2-only and stays dormant.

## Reproduce

Use fresh output directories; never overwrite a frozen receipt. From this tree:

```sh
export LD_LIBRARY_PATH=/workspace/scratch/79976da795e7/linux-runtime/usr/lib/x86_64-linux-gnu
export EGL_PLATFORM=surfaceless MESA_SHADER_CACHE_DISABLE=true LIVE_FULL_THEME=1
BINARY=/workspace/shared/pirate-audit/map2-integrated-native-build/raised-map2-live-native
OUT=/path/to/new-evidence
mkdir -p "$OUT"/{controller,baseline,objects-480,objects-360}
LIVE_BASELINE_ONLY=1 RAISED_MAP2_LIVE_CAPTURE_DIR="$OUT/baseline" "$BINARY" tools/tests/raised_map2_live_native.lua > "$OUT/baseline/native.log" 2>&1
RAISED_MAP2_LIVE_CAPTURE_DIR="$OUT/controller" "$BINARY" tools/tests/raised_map2_live_native.lua > "$OUT/controller/native.log" 2>&1
for width in 480 360; do
  OBJECT_WIDTH=$width RAISED_MAP2_LIVE_CAPTURE_DIR="$OUT/objects-$width" "$BINARY" tools/tests/raised_map2_live_objects_native.lua > "$OUT/objects-$width/native.log" 2>&1
done
/workspace/shared/lua51 tools/tests/raised_map2_objects_contract.lua
python3 tools/tests/raised_map2_objects_assets.py
python3 tools/tests/verify_raised_map2_live_objects.py --evidence "$OUT"
LUA_BIN=/workspace/shared/lua51 LUA_INIT='WARM_PIRATE_V1=false' bash tools/tests/run-adventure-ui-tests.sh
```
