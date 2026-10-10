# Manual alchemy feedback

Fresh native play at 540×960 showed five overlapping coin messages after ten
clicks roughly 0.3 seconds apart. The legacy toast queue admitted a new floating
node every 0.6 seconds while each node remained alive for five seconds; its
`bIsLimit` option only limited pending messages, not visible nodes.

`DataManager:AlchemyButtonDidClick` now sends only its successful coin feedback
to `ToastUtil:alchemyCoins`. Coin arithmetic, costs, achievement increments,
guide thresholds and long-press entitlement are unchanged. Other rewards,
errors, unlocks and construction messages keep their existing queue.

A single compact receipt above the owning page's alchemy button shows only
that burst's earned coins ("金币+N"). The existing currency header remains the
live balance display: a receipt's event-time total became stale if a building
was purchased while it was still visible, so the duplicate total was removed.
It fades
out after 1.2 idle seconds, finishing at 1.6 seconds. The native-owned node is
reused on that page; exit/cleanup stops animations and clears the burst. It is
found through live children rather than a globally cached native wrapper, so
page destruction cannot leave a dangling singleton reference. No touch listener
or new scheduler entry is installed. A no-scene call safely omits presentation.

Regression: `tools/tests/alchemy_feedback_regression.lua` runs in both the normal
Lua aggregate and the existing `build/linux/tests/chart-lifecycle-native` harness.
The native mode uses real Cocos nodes, labels, actions and exit/cleanup; role
storage and guide/achievement-unlock side effects are isolated in memory. It
checks ten successive actual alchemy callbacks, coin/achievement counts,
intervening spending, important-message retention, expiration, paused/reentered
reuse, replacement/destruction and no-scene startup. It does not load a player
save or replace full Director-stack, GUI or device verification.
