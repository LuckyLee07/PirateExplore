# Reachable world-chart selector

This narrow pass starts from frozen event-scene commit `65927f332567f4e4bb8f62842ae8324787f2d6dc`. The event entry-scene branch remains untouched. Integrate only this commit's new/changed files; do not replace a newer working tree with this ancestor.

## Scope and route inventory

`EventLayer:enterTeleport()` still creates the actual `WorldMapLayer`, assigns the same owner before attaching it to the running scene, and rejects duplicate selectors. The warm selector replaces only its composition, local input ownership, confirmation presentation, and travel/unlock animation presentation. `WARM_PIRATE_V1=false` constructs the old geographic scroll chart unchanged.

The route list has the original sixteen IDs and names in exact order:

1. 瓶中船
2. 皇家港
3. 加勒比海
4. 白帽港
5. 深邃幽蓝
6. 极地港
7. 霜冻海湾
8. 冤嚎之境
9. 乱葬海
10. 无尽之海
11. 海中城堡
12. 幽魂之域
13. 神秘海域
14. 远古封印
15. 死亡之渊
16. 世界尽头

Names beyond the original `mapMaxIndex` are concealed as 未探索海域. The itinerary communicates chapter order, not geographic positions. Current, available, undiscovered, expansion-required, and newly opened tip states come from existing role data. Selecting a row only selects it. Its fixed destination summary and action do not travel, spend, or grant anything.

Original route and ownership contracts:

- The original `moveToMapByIndex(index)` `mapMaxIndex` / `statue == "ready"` checks remain authoritative.
- `owner:enterNextMapEnter(false,index,true)` remains the original check-only readiness/entitlement gate.
- Allowed destinations require an exact destination confirmation. The original `enterMapByIndex(index)` then calls `owner:enterNextMapEnter(true,index)` once.
- The current chapter retains its original re-entry route. Its primary is deliberately labeled **重新进入**, because the original callback reinitializes that map. **返回海域** calls only `owner:enterNextLayer(false)` and removes the selector, so these are genuinely distinct actions.
- The original newly opened chapter path returns false while its owner runs the chapter story, removes the selector, and later initializes the map. That handoff still owns completion. An unrelated late readiness denial simply releases the selector's presentation busy state, without bypassing or replaying its gate.
- `getMapShopInfoByMapIndex` and `unlockMapDatas` are byte-for-byte conserved, checked by source hashes. The exact in-memory original expansion records are shop ID 1: chapter 6, 100 diamonds, next limit 10; ID 2: chapter 11, 150 diamonds, next limit 14; ID 3: chapter 15, 200 diamonds, next limit 16.
- Purchase confirmation captures its exact record/price. The only deduction remains `addDiamond(-price)`, followed by the original `unlockMapDatas()` writes/achievement callback. Insufficient diamonds do not unlock. Changed entitlement, changed quote, removed/replaced owner, or late confirmation cannot spend. Successful purchase never automatically travels.
- The original tip's `fadeMapFogIndex` acknowledgement is retained; no progression reset or additional unlock is introduced.
- The existing optional charge view is owner-bound and closes on selector departure. All native real-money platform gating remains in the unchanged `PurchaseAvailability`/charge implementation. Linux native billing remains unsupported. No live purchase or online service was contacted.

## Composition and art

A sunny neutral field holds the already-approved clean world-chart table above one folded-paper chapter itinerary. The list uses numbered route markers and a current-ship marker rather than a new fantasy map. A persistent scroll-range hint and scroll thumb show that later chapters remain below; compact pages keep Back and the primary in a fixed bottom dock.

The reused asset is `Images/UI/CleanVoyage/Events/worldchart-table-clean-v2.png`, unchanged SHA-256 `951e865590f3ec8d3107d60c75ce54ab8b6d11adc3e51fb7c050a41d72008fe3`. Its existing event-family master/provenance remain authoritative. No new bitmap was needed or generated. No shared font, button, modal, event, controller, economy, or save file changed.

All background planes and live control layers use explicit depths. The selector's owned confirmation body scrolls when destination/cost prose is long, instead of painting over its actions. Local native listeners reject disabled, clipped, hidden, dragged, cancelled, removed-owner, and stale-generation gestures. Exit/re-entry cancels pending presentation work and leaves a still-owned selector usable; cleanup permanently invalidates it.

## Verification and evidence

All evidence and the reusable native executable are in `/workspace/shared/pirate-audit/world-chart-selector`.

- The pre-change actual native chart was captured first as `legacy-selector-360x640.png`.
- Final actual reachable selector frames cover 360×640, 480×800, 640×960, and 720×1280, with current/available/locked states, selected unknown chapter, and exact destination confirmation.
- The dedicated selector gate passes 2,678 native assertions and 54 exact dynamic-child pixel comparisons. Native GLView dispatch exercises row selection, Cancel, Back, current re-entry, all sixteen original destination IDs, rapid input, dragging, native cancellation, hidden/disabled states, ownership loss, modal/animation departure, and native detach/re-entry.
- Original expansion records exercise exact diamond deltas and original unlock callback argument identities, cancellation, shortage, late callback rejection, changed quote/entitlement rejection, and no automatic travel. Newly opened chapter story handoff uses its actual decoded plot identity and original EventLayer callbacks.
- Long destination titles and long prices remain bounded; long confirmation bodies are tested with real native scrolling.
- Dynamic insertion/removal at scene, selector, itinerary, dock, row, button and confirmation roots produces exact pixel equality.
- The unchanged event-page native regression passes 88,972 assertions. Existing real-money guard regression passes with legacy presentation selected; running that older regression under warm presentation still encounters its pre-existing `DiamondStore.lua:1459` boolean fixture dependency. The selector's dedicated native check independently verifies the real Linux Application enum rejects the original product request without invoking billing.
- The new conservation/glyph audit passes. There are no missing CJK glyphs in the unchanged CleanVoyageSans font. Lua 5.1 parse and `git diff --check` pass.

Run from this checkout:

```sh
source /workspace/scratch/79976da795e7/linux-runtime/env.sh
export PIRATE_BUILD_DIR=/workspace/scratch/79976da795e7/PirateExplore-shutdown-fix/build/linux
python3 tools/tests/world_chart_selector_render.py
python3 tools/tests/world_chart_selector_audit.py
LUA_INIT='WARM_PIRATE_V1=false' /workspace/shared/lua51 tools/tests/purchase_availability_regression.lua
```

The native harness is headless Cocos/EGL, not browser pixels or a mocked renderer. Role data/economy are controlled in-memory fixtures, not a player profile. No GUI was opened and nothing was published. Desktop visual review and actual mobile store/device acceptance are separate gates.

### Interrupted native gesture successor

Independent review found that a touch begun before native detach/reentry could finish on the reattached primary control and open a destination confirmation. Each local control now captures the selector generation at accepted BEGIN and requires that same generation at END, clearing it with its painted state on reset. No route, price, grant, entitlement or modal callback changes. The four-size real-GLView suite now detaches and reattaches mid-touch, verifies stale release rejection, and then verifies a fresh tap and cancel work normally. The original failing reproduction is preserved in the independent audit evidence.
