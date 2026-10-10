# Next small experience iteration

Status at proposal: design only, 2026-10-10. The first build has since completed native acceptance. The cargo correctness/guidance portion is now implemented for a separate second-round native check; see [the implementation and test record](loot-choice-20261010.md). Gift and long-press proposals remain unimplemented. This document itself changes no runtime rules.

## 1. Make full-cargo choices discoverable

### Observed problem and actual behavior

Natural play found that a full hold appears to force abandoning loot. The existing interface does allow a deliberate tradeoff, but does not explain it. The current production screen is `FightRewardScene` in `FightMode.lua` (around lines 3254–3507), not the legacy `EventRewardLayer`.

- Clicking a left-column cargo item moves **one unit** to the right column and frees that item's actual `cubage`.
- Clicking a right-column item takes it aboard if it fits. This also lets the player reverse a previous move while the screen remains open.
- Closing saves the left-column inventory to `roleBattlePack`; items remaining on the right are abandoned. Moving an item right is therefore not yet an irreversible discard.
- Existing zero-volume cargo is reserved separately and restored on closing. A specific zero-volume gold row can be collected even at capacity. Bulk pickup retains its first-blocked-item stop, so gold after a blocked item is not automatically reached; normal initialization sorts zero-volume items first.
- Important task items left on the right already prevent closing through the existing rule.
- “全部拾取” can take previously moved-out food aboard again, because it is now part of the right-column list. Advice must tell the player to select the **specific desired loot**, rather than automatically pressing “全部拾取” after freeing space.

### Minimal UI proposal

Reuse the gap between the lists' lower edge at y=150 and the existing action buttons' upper edge near y=91. Add a two-line 20–22 point contextual hint around y=120, with no new panel and no moved buttons. Confirm this exact placement in native screenshots; source geometry is not visual acceptance.

Full hold with loot remaining:

- 货舱已满：点左侧物品腾位
- 再点右侧拾取；关闭会丢弃右侧物品

After moving food out, replace the first line with:

- 船上食物剩N，请留足返航补给

For ordinary non-full loot:

- 点左侧移出，点右侧拾取
- 关闭会丢弃右侧物品

The existing full-cargo failure toast should give the same actionable instruction rather than only “无法拾取”. The hint should clear or simplify when no loot remains. It must not suggest that a particular quantity of food guarantees a safe return: that depends on the actual route and current effects.

Do not automatically discard food, select items, collect rewards, alter capacity, add a free expansion, or change the close callback.

### Acceptance

1. Capacity 20 with 20 food: moving out 3 food and taking 3 iron leaves 17 food + 3 iron, without an automatic move.
2. Before closing, an item moved right can be taken back when space permits. Both displayed counts and occupied capacity stay correct.
3. Moving food to zero yields an honest warning, without an automatic purchase or redirect.
4. Closing preserves the left side and abandons the right side exactly as before; total quantities are conserved until that intentional close.
5. Task-item close blocking and zero-volume gold pickup remain unchanged.
6. “全部拾取” retains its existing semantics, including possible reloading of moved-out food; the hint does not claim otherwise.
7. Test repeated taps, empty loot, a single remaining unit, maximum-length material names, and narrow portrait viewports without covering either original action.
8. Record at least one natural capacity-limited loot screen before and after. Controlled callback tests complement, not replace, that evidence.

### First correctness priority: bulk-pickup capacity overflow

Read-only source analysis found that `FightRewardScene:pickUpAllRewards` in `FightMode.lua` (line 3636 in the reviewed source) uses `math.ceil(capLeft/cubage)`. With one space remaining and a two-space item, this can overfill the hold. Decoded shipped resources include dark steel 1012, mithril 1022 and eternal ingot 1076 at cubage 2, and siege ram 1039 at cubage 5. Early wood/iron loot has cubage 1, so the natural early voyages do not verify this boundary.

Treat this as a separate controlled-test/fix task. A future change should first reproduce the actual callback with these real rows and compare floor-based capacity handling, including zero-volume items. Do not fold an unverified inventory-rule change into the hint-only patch.

## 2. Replace unsolicited gift interruptions only after preserving voluntary access

The native player observed the first-return real-money gift automatically covering the screen, and declined it without paying. `MainMenu.lua` schedules `PushGiftView:create():show()` after 0.3 seconds when saved map state exists and the player is at base. The same offer has a voluntary golden-boat button, but that boat crosses for only 10 seconds every 60 seconds after sailing.

A later patch can first add a stable, player-invoked route to the **same existing offer**, preferably within an existing port utility group, then replace the automatic return interruption with a quiet cue at that route. Verify opening, closing, reopening, unavailable payments, and original offer/entitlement preservation. Do not change prices, add urgency, auto-open checkout, or claim native purchasing works on an unconfigured platform.

## 3. Alchemy repetition and paid long-press compatibility

Source currently interrupts repeated alchemy with coin-exchange offers around each of the first two 100-click thresholds, then offers long-press alchemy for 398 diamonds around the third. Subsequent long-press offers recur at 300-click thresholds. The saved `roleAlchemyCanLongPress` flag grants the existing behavior.

Unlike the return gift, there is **no existing permanent voluntary shop entry** for this 398-diamond long-press offer. Removing all threshold prompts without replacing that route would silently remove purchase access. Making long-press universally free would also change the meaning of an existing paid entitlement.

For the next iteration, preserve existing owners' flag and behavior. Design an explicit voluntary route before considering removal of automatic prompts; do not change counters or grant compensation incidentally. The current read-only harbor goal already exposes the inexpensive apprentice furnace: five iron raises alchemy from one to two coins per successful click. First measure whether that understandable earned goal reduces repetitive-click burden during natural play. Success is clearer choices and fewer unwanted interruptions, not more resources distributed or more payment conversions.

Potential acceptance later: old paid flags remain effective, no unexpected charge, voluntary open/close/reopen works, original 0.3-second cadence is unchanged, switching pages stops any active interaction correctly, and sustained ordinary alchemy no longer summons an offer once the replacement path is intentionally approved and implemented.
