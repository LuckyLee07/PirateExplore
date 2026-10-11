# Coherent growth and support pages

## Scope

`WarmActivities.lua` and `WarmCollection.lua` use the shared CleanVoyageSans,
cream/navy/teal theme. The ship overview uses the same CleanVoyage boat as the
harbor. Support sheets use quiet backgrounds, short titles and a maximum of one
emphasized action. Back and alternate destinations remain secondary.

The four destinations are now explicit:

- **物品库存:** live stock and, while sailing, the separately identified cargo
- **航程收藏:** permanent, non-tradeable keepsakes and their display preview
- **航海日志:** the saved per-voyage outcomes provided by `WarmMemories`
- **航线线索:** current progression and full paginated harbor guidance

Inventory no longer claims that keepsakes are unavailable. Inventory can open
the real collection; progression can open the actual voyage log. Each sibling
transition closes and unsubscribes the old sheet before opening the new one.

Ship previews, material-source routes, real gate checks, crew recovery, stock
pagination, complete measured guidance/cargo pagination and the original
economy remain intact. No backend transaction, resource award, recipe, cost,
save format or ownership rule was changed. Collection display confirmation
still calls the existing atomic `WarmMemories.setDisplay` operation. Its removal
preview now correctly says **确认收回**. Cancellation, stale callback protection,
save failure and ownership revalidation are retained.

Collection subscriptions now have instance-specific keys and clear the legacy
dispatcher's retained short-key callback on dismissal. Closing an owner removes
the touch listener and subscription. Switching collection tabs clears a pending
display preview and stale log detail. Pagers disable the unavailable direction.

## Verification

Run from the repository root using Lua 5.1 and the existing native harness:

```sh
LUA_BIN=/path/to/lua5.1
"$LUA_BIN" tools/tests/warm_activities_regression.lua
build/linux/tests/tutorial-log-native tools/tests/warm_activities_native.lua
build/linux/tests/tutorial-log-native tools/tests/warm_collection_native.lua
build/linux/tests/tutorial-log-native tools/tests/coherent_growth_native.lua
```

If needed, put the already-provisioned runtime's `usr/lib/x86_64-linux-gnu` in
`LD_LIBRARY_PATH`. Set `MESA_SHADER_CACHE_DISABLE=true` for the surfaceless EGL
harness. The native tests do not start the game or load a player profile.

Passed on 2026-10-11:

- Existing activity logic tests: live CSV/state, no writes, gates, recovery,
  detail/source routes, stale actions, pagination and owner cleanup
- Existing activity native tests at 640 × 960, 640 × 1067 and 640 × 1136:
  native fonts, nodes, bounded labels, menus, details and lifecycle
- Existing collection native tests at the same sizes: true terminal-voyage
  records, one-time ownership, cold display, preview/cancel/place/remove,
  failed saves, late ownership loss, complete cargo pages and teardown
- New coherent growth native tests at the same sizes: inventory → collection
  → voyage log → route clues → actual log; inventory densities 0–6; two real
  growth choices; multiple source actions; crew/detail navigation; shared font
  and at most one primary; stale confirmation after tab change; first/last
  pager states; second-page detail Back; read-only state and listener counts

These are native component/fixture checks. They are not full-game screenshot
acceptance, a GUI playthrough, or platform/device acceptance. No GUI launch,
restart, publication or real player-save operation was performed for this work.
