# Raised original-map2 prototype

Status: opt-in fixture only. No production importer, Explore hook, save flag, map
migration or later-map activation exists. Based on frozen clean-world gate
`923a04b6b2afabb53248d52ea5f2ea958b509245`; that checkpoint and its imagegen masters
remain untouched. Parent accepted the geometry-preserving direction at the v3
native comparison, not production readiness.

## Smallest implemented adapter

[`RaisedSeaMap2.lua`](../../bin/res/scripts/LuaClass/RaisedSeaMap2.lua) accepts only
the original 31×31, 64-pixel map2 with its actual sand/forest layer textures and
zero layer offsets. Unsupported maps/assets/APIs return a fallback reason. It
returns a detached presentation and does not hide or mutate the source map.

- Forward projection is `(sqrt(.5)*(wx+wy), sqrt(.5)*.56*(wy-wx)+height)`.
  The inverse is exact. Original TMX cells, source layer GIDs/properties/flags,
  object positions and gameplay collision remain authoritative.
- The elevated top is the original alpha/flip footprint, reused at runtime. Walls
  extrude its pixel boundary union by 30 screen units. Shared internal edges are
  discarded. There are 214 source land cells, 17,483 retained union boundary edges
  and 8,742 front-facing wall quads. No coast/path/island is authored or relocated.
- A wall-only visual LOD omits disconnected source-tile alpha components smaller
  than 16 pixels. The original top alpha, hit model and collision are unchanged.
  This prevents tiny original alpha speckles becoming tall isolated posts.
- Two restrained cream wall bands and a faint water contact line give actual
  depth. Eleven upright generated-art scenery accents use fully opaque original
  foundations and avoid neighboring events. The optional 64-pixel ship uses the real Objects/Start cell; a cosmetic berth shift of (-16,-9) screen units stays inside that same cell and writes no actor coordinate. The original three events remain at
  `(15,12)` GID47, `(15,15)` GID51 and `(18,15)` GID46.
- Port scale is 1.5, legacy portal/revive icon scale .7; contact ovals are runtime
  vectors at the same source cells. The two legacy event drawings are explicitly
  unfinished art. This is not a completed semantic event-model atlas.
- Source-cell depth is a unique lexicographic `(x+y,x,slot)` integer. Water/fog,
  base/material top, walls, scenery, contact plates, events and the optional ship
  have explicit planes. No sibling insertion-order tie controls rendering.
- Screen selection uses the root's real inverse transform, the raised top plane,
  indexed wall quads, and actual upright event bounds with source depth priority.
  `eventAt` returns exact live-layout ID/state/GID separately from the native TMX
  trigger ID. Shared GID48 does not infer supply or occupation semantics.
- The source map's discovery data clips all elevated geometry and actors to
  fully known ground-plane cells. Missing/nonzero fog remains unknown. Selection
  requires both the rendered discovery snapshot and current known state.
- Exterior sea repeats beyond the source rectangle only to fill the viewport.
  Out-of-bounds input still rejects it; it creates no playable coordinates.
- DrawNode-only native context listeners remain awake under scene suspension.
  No gameplay target, scheduler or action is resumed. Actual active and paused
  EGL context reconstruction is covered by pixel comparisons.

## Art and geometry provenance

All raster art is reused unchanged from the imagegen masters and deterministic
packing recorded in [`../clean-world-gate/ART_PROVENANCE.json`](../clean-world-gate/ART_PROVENANCE.json).
This change creates no bitmap artwork and edits no atlas. Source-alpha metadata
is reproducibly extracted by [`build_raised_source_alpha.py`](../../tools/build_raised_source_alpha.py)
from untouched original `dt_ludi.png` and `dt_senlin.png`; exact hashes and the
threshold/LOD distinction are in [SOURCE_ALPHA.json](SOURCE_ALPHA.json).

Native screenshots are actual offscreen Cocos captures. Python only reads their
pixels and writes test receipts; it never repaints, composites or labels them.

## Reproduce

Use the additive native fixture executable described in
[`clean_world_native.md`](../../tools/tests/clean_world_native.md). It creates no
window, starts no game session, reads no player profile, and writes no source TMX.

```sh
LUA_BIN=/workspace/shared/lua51 LUA_INIT='WARM_PIRATE_V1=false' \
  bash tools/tests/run-adventure-ui-tests.sh
/workspace/shared/lua51 tools/tests/raised_map2_contract.lua
PIRATE_RUNTIME=/path/to/extracted/linux-runtime \
  python3 tools/tests/raised_map2_render.py \
    --native-bin /path/to/clean-world-native \
    --capture-dir /path/to/isolated/evidence
```

The wrapper checks every original map/CSV/atlas, all clean-art masters and the
protected gameplay/presentation modules against the frozen base and across the
run. It records exact PNG hashes in `evidence.json`.

## Required checks and limits

The native fixture checks exact source GID/flag/position/z-order invariance,
three event targets across three zooms plus panning, raised/water/shore selection,
all eight source-alpha transforms, both context recovery modes, child insertion
and removal, and a known→half-known→unknown→known rebuild. The pure model suite
checks 1,922 center projections, all flip inverses, overloaded GID48 live IDs and
raw states, fallback, and forbidden save-singleton access.

Production remains blocked on:

1. Partial native fog silhouettes and reveal animation: the prototype uses a
   conservative hard, fully-known-only clip. It deliberately crops tall art at
   unknown cells rather than leaking it.
2. A lifecycle-aware live adapter for movement, discovery/event updates, camera,
   selection affordances, effects and return-from-battle. This detached snapshot
   requires rebuilding after model changes and performs no movement dispatch.
3. New semantic portal/revive and live event-state art. Exact identities are
   tested, but visual coverage of dynamic randomized events is not complete.
4. Pixel-level event/scenery occlusion in a populated live route, Android GPU
   checks and profiling: 214 tile clips and a pixel-derived wall mesh are bounded
   here, not a proven map16 budget. No mobile frame-rate claim is made.
5. Compatible art and alpha metadata for other families, then separate native
   mixed-map/late-map acceptance. No automatic extension or profile opt-in.

The existing runtime route remains the default and the immediate fallback.

## Immutable native evidence

Renderer `4efff328a23c4d2aee18b83c945341994e7a96e8` was rendered and verified in
`/workspace/shared/pirate-audit/raised-map2-4efff32-verified/`.
The [verification receipt](VERIFICATION.json) contains exact hashes for 16 native
PNGs and 96 unchanged protected source files. Best review pairs are
`map2-raised-viewport-v8.png` / `map2-source-projected-viewport-v8.png` and
`map2-raised-mixed-coast-v8.png` / `map2-source-projected-mixed-coast-v8.png`.
`map2-start-ship-v8.png` shows the original port/start cell with the optional
actor. All-known recovery/insertion/removal/reveal-return images are byte-level
pixel-identical. Fog checks report zero leakage in 912,000 fully hidden pixels
and 421,776 partially hidden samples; all 32,768 native flip pixels match.
