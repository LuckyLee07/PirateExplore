# Warm v1 real upgrade preview and confirmation

## Scope and API

`WarmUpgrade.open(owner, goalId)` opens a native, owner-bound preview for `1148` (first cargo upgrade) or `1176` (apprentice furnace). It shows the Warm ship artwork, a clearly labelled visual effect preview, current → resulting capability, the exact original recipe, current stock/shortfall, and separate Confirm/Cancel controls. Confirm crafts directly; it does not send a sufficiently prepared player to the old manufacturing table.

- Cargo 1148 / produce 6: wood 1007 ×5 + cloth 1018 ×5; `rolePackSize` becomes 30 from the original `raiseType`.
- Furnace 1176 / produce 30: iron 1008 ×5; `roleAlchemyUnit` becomes 2 from the original `raiseType`.
- If forge 57 is waiting and building is accessible, the same preview explains its exact original prerequisite cost: gold ×25, stone ×15, iron ×2. Its action opens the existing build page focused on 57; that prerequisite is not silently purchased or constructed.
- Other locked, unavailable, at-sea, insufficient, already-owned and invalid states cannot confirm. Advanced capacities cannot be downgraded, and an already-present crafted item cannot be charged a second time even if a malformed old save lacks its effect.

Read-only model APIs are `inspect(dm, goalId)` and `quote(dm, goalId)`. `confirm(dm, quote)` revalidates current inventory, saved recipe availability, matching produce ID, manufacturing guide gate, effect and full CSV quote signature. `cancel(quote)` invalidates a preview. Quotes are bound privately to their manager and target; public table edits cannot alter the transaction.

The parent ship page owns navigation integration. The Home cargo decoration already observes the authoritative `rolePackSize`, so the ordinary original capacity event updates it after successful commit. This module adds no new sail speed, damage, cargo balancing, fixed 80-resource charge, reward, ship ownership or guide unlock rule.

## Transaction boundary

The original `DataManager:addPackItemWithId` and `createSuccessCheck` code executes synchronously against an isolated role-data candidate. The latter still executes the original next-recipe unlock, hidden crafted inventory item, capacity/alchemy effect, guide transitions and automatic-talent checks. Dynamic locked talents and guide state are staged separately. UI events, success logs and toasts are deferred until storage succeeds.

The bounded call temporarily redirects the three legacy singleton accessors to staging objects. It cannot yield or dispatch UI. The accessors, toast object and legacy `actId` global are restored even when an original method throws. No live role, guide or dynamic-talent state is changed by a staging or persistence failure. The complete changed role fields are published through the existing encrypted `UserData.commitAdventure` → `commitLocalProduction` → `SaveDataManager.saveDataAtomic` boundary, once. There are no intermediate sequential saves.

The actual shipped produce rows 6/30 contain no mission triggers. This module fails closed if future content adds a nonzero mission hook, rather than falsely claiming a generic transaction over the mission manager's closure-backed mutable indexes. Existing missions and guide rules are otherwise untouched. Native/menu generation guards and used/cancelled private quotes prevent retained, repeated or reentrant callbacks from charging again. Postcommit observer/cache/log/toast exceptions cannot report a durable success as an uncommitted failure or keep the global craft lock stuck.

## Verification

Passed:

- `build/linux/tests/lua-ui-tests tools/tests/warm_upgrade_regression.lua`
  - Decrypts the actual packaged CSV. Uses real original DataManager, GuideController, UserData and SaveDataManager methods with an isolated in-memory Record implementation.
  - Full resulting-state parity against the original sequential craft, for cargo and furnace, including next recipe, guide flags, crafted item and automatic-talent-check cadence.
  - One atomic encrypted snapshot, zero sequential saves, cold JSON reload, cancel, repeated confirm, insufficient/stale inventory, revoked recipe/guide, at-sea, changed recipe, public-quote tampering, owned/advanced state, exact forge prerequisite costs.
  - Atomic-save false/throw, original-method exception, rollback of live/disk/guide state, no failed events/toasts/logs, safe retry, reentrant observer, postcommit cache/observer failures and a subsequent different upgrade.
  - Real nonempty automatic-talent code using packaged talent 2025. A clearly synthetic test-only achievement row exercises the optional achievement/diamond cascade. All talent, bonus-attribute, guide, achievement, diamond and dynamic-lock changes match the original successful craft and roll back on save failure.
- Real `tutorial-log-native` Cocos/EGL execution of `tools/tests/warm_upgrade_native.lua` at 640×960, 640×1067 and 640×1136.
  - Real artwork, LabelTTF bounds, disjoint native Confirm/Cancel targets, cancel/reopen, actual transaction from native menu activation, completed/owned states, live stock event refresh, retained stale native button, failed-save retry, focused forge route, ancestor cleanup and event unsubscription.

Native tests use isolated fixture storage and do not load a player profile. This is not a claim of natural gameplay or mobile/device testing. Actual physical atomic file replacement remains covered by the repository's existing atomic-save regression; this feature's test injects the Record boundary to force failures deterministically. No desktop input, commit, push or deployment was performed.
