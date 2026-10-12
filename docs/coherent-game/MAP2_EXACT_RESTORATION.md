# Map2 exact restoration hotfix

Base: `3bbee62f16083526f62312370d0ff7857a737c22`, tree `01a98a274113647cf8641cd030888ca0ec42c9d3`.
Production scope is only `RaisedSeaMap2Live.lua`. No map3 enablement, renderer optimization, engine, source geometry, TMX/CSV, actor/controller/save/economy or art changes.

## Reproduced baseline defect

The unchanged 24-equal-Z-sibling/six-dirty-round probe failed on the exact base at its first dirty rebuild. A separate stationary 227-source-node probe reached unmount and found map arrival `0 → 3913`, camera drift `(0.00003051757, 0.00001525880)`, and 3,591 changed pixels. The older ff6127b probe was a different source revision and is not used as exact-base evidence.

This is a presentation restoration defect. No save/economy corruption or input-routing failure has been demonstrated. The simplified stress fixture's event-layer/FogManager swap is not proof of production event overlay inversion: original `EventManger` is Z10 with a nested event layer.

## Supported transitions

- `Explore:initMapByMapIndex` explicitly unmounts before clearing the previous map. The owner survives chapter travel.
- Same-scene runtime disable and renderer rebuild failure explicitly unmount. Startup opt-out or failed preparation never reparents nodes.
- Native non-cleanup exit, detach/reentry and scene push/pop keep the mounted hierarchy. Existing HUD gesture invalidation handles interruption. No exit callback reparents native children or mutates the vector being traversed.
- True cleanup releases retained leases/references without moving dying map children. Explicit unmount restores the native hierarchy outside native exit traversal.
- Rebound map/moveLayer ownership restores the recorded old hierarchy, leaving the newly assigned camera/actions alone.

## Restoration policy

Native reparenting preserves the current arrival value, Z, transforms and actions. Persistent tie ledgers cover map, owner and transformed moveLayer siblings. Cocos clears visible arrivals on visit but not hidden arrivals; those native resets must not be misread as new ordering requests. Newly requested nonzero arrivals and current Z changes remain authoritative. Initial original-parent capture observes native pending sort work before adding an adapter marker; when pending work changes the vector, native Z/arrival comparison is honored with stable pre-sort equal ties. Clean visited parents keep their existing order, and reparented children never undergo that initial native sort. Temporary unique arrival ranks are used only during sorting, then every current value is restored. An unchanged sibling identity/order/Z/arrival signature returns without sorting, dirtying any node, rewriting arrivals or allocating rank records; additions/removals/reorders and visit-reset arrivals invalidate that signature.

An unchanged camera, actor, scale, viewport and HUD boundary returns its exact original coordinates, avoiding float inverse-transform drift. A changed pan/zoom/follow state preserves the current map point under the chart viewport center and applies the original native clamp. Actor coordinates and scale are never reset. The original explicitly tagged camera-tween cancellation remains established behavior on coordinate-system conversion; unrelated camera/actor actions retain identity. This does not promise identity preservation of that tagged camera tween.

The moveLayer addChild hook restores only its own field. A newer decorator stays installed, and calls through the retired wrapper delegate to the original method rather than a removed projection node. Fresh post-unmount insertion is tested. Coast edges restore their current Z/arrival rather than stale values recorded at mount.

New restoration API/order/camera checks run inside read-only preparation before any live node is moved.

## Additive gate

`tools/tests/raised_map2_restoration_native.lua` uses the existing native harness and seeded HUD fixture. It covers 258 original nodes in production EventManger class/Z10/nested-layer topology (deterministic event queue, not full application startup), zero/one/multiple rendered cycles, disable/rebuild-failure fallback, 27 restoration-preflight negatives, pending native same-Z reorders at owner/map/moveLayer mount boundaries, current actor/visibility/new-child properties, action identity, newer decorator chains, pan/zoom/follow focus, active owner rebound, exit/detach/push-pop and cleanup witnesses on both sides of the observer. It runs at 480×800 and 360×640; all original-reference/restored pixel pairs must be identical.

Run from the exact worktree root with the existing `raised-map2-live-native` runner, `LIVE_FULL_THEME=1`, `RAISED_MAP2_LIVE_CAPTURE_DIR=<new evidence dir>`, and optional `HUD_WIDTH`/`HUD_HEIGHT`. No engine rebuild or runtime copy is required. The original unchanged stress diagnostic is also replayed independently. Existing guard/HUD/boat/objects/controller/context/input suites remain required. Actual original-selector chapter travel and actual AppDelegate UI acceptance are separate gates; a seeded native pass does not replace them.

## Remaining baseline context issue

A separate original-route paused GL-context recovery test loses pixels from `SeaChartTheme.shipHalo(64)` in cycles 2/4/6. Hiding only that authentic source halo removes the difference; the historical map2 controller fixture did not seed that halo. This is separate from unmount restoration, is not repaired here, and cannot excuse unmount pixel/property mismatches. No shared theme/engine/halo changes are included.
