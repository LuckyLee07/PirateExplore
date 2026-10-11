# Warm voyage memories v1

## Scope and eligibility

The sole collectible is `wreck_chart_fragment` (沉船航图残页). It is permanent,
non-tradeable and non-functional. It neither consumes inventory/cargo space nor
unlocks routes, chapters, buildings, objectives, rewards or v2 content.

Only a newly started warm-mode voyage gets `warmMemoriesVoyageV1` in the existing
atomic `AdventureProgress.depart` (or `beginVoyage`) commit. The existing wreck
`resolveEvent` stamps its actual episode, action, choice and map chapter on that
eligible voyage. The first successful original `returnVoyage` with that matching
pending event adds the memorial to `warmVoyageMemoriesV1` in the **same existing
return snapshot**. It does not issue a second save or inventory grant. Both the
first and actual crew follow-up wreck episodes qualify; the first acquired story
is never rewritten. Failure, abandonment, an unsuccessful save, an old completed
flag, or an already-active pre-feature voyage cannot grant the memorial.

Display is initially empty. Only an explicit confirmed `setDisplay(dm, id)` can
select an owned memorial; `nil` clears the display. Opening, previewing, Back and
Cancel call no setter. A failed display save keeps the previously selected item.

## Durable schema and API

`WarmMemories.KEY` is `warmVoyageMemoriesV1`, version 1. `ITEM_ID` (also `ID`) is
`wreck_chart_fragment`. The durable field contains `items`, `displayId`, `log`
and `lastVoyage`. It is created only in an actual eligible terminal voyage commit,
including a failed voyage or an ordinary return that earns no memorial.

- `definitions()` returns a detached definition list.
- `get(dm)` is read-only and returns detached `items`, owned `entries`, `displayId`,
  `log`/`logs` (newest first), `lastResult`, `lastVoyage`, `readOnly` and `reason`.
  Empty saves remain empty on read. `reason` can be `legacy`, `disabled`,
  `incompatible` or `corrupt`.
- An owned entry contains `id`, `name`, `description`, `firstVoyage`/`voyage`,
  `voyageId`, actual `episode`, `action`, `choice`, `chapter`/`mapIndex`,
  `source='wreck_event'`, `tradeable=false`, `functional=false`.
- `prepareDeparture`, `prepareEvent`, `prepareReturn`, `prepareFailure` only
  prepare detached data. Return/failure preparations require the original final
  settlement fields, and are consumed only by the existing atomic commit path.
- `setDisplay(dm, id or nil)` validates current ownership/schema, avoids no-op
  writes, and returns `true` or `false, reason`. It writes only this field and
  posts its change event after successful persistence.

Each newly eligible successful or failed voyage appends exactly one genuine
record. Records contain stable `adventure:<voyage number>` IDs, return outcome,
return chapter, settled cargo, returned/lost cargo, actual event provenance,
newly granted memory IDs, actual before/after currency amounts and stock deltas.
Return costs have already been applied when the snapshot is made, so a consumed
scroll cannot be reported as delivered cargo. Original failure mission-item
exceptions are recorded without changing them. The most recent 20 records are
retained; `lastVoyage` prevents replay even after a record ages out. No dates,
old voyages, rescue choices or quantities are inferred from historical flags.

Unsupported versions and corrupt known fields remain untouched and read-only.
Supported additive unknown fields survive. A missing adventure ledger is a
legacy save and remains a no-op. `WARM_PIRATE_V1=false` does not load or write the
extension and preserves the original settlement fields and reward behavior.
Lightweight fixtures whose `require()` returns `true` safely skip the extension.

## Verification

Run from the repository root:

```
build/linux/tests/lua-ui-tests tools/tests/warm_memories_regression.lua
build/linux/tests/lua-ui-tests tools/tests/adventure_state_audit.lua
build/linux/tests/lua-ui-tests tools/tests/adventure_progression_regression.lua
```

The focused test uses production AdventureProgress, encrypted UserData,
SaveDataManager and JSON serialization with isolated Record I/O. It covers all
eight first/crew wreck choices, once-only ownership, atomic-save failure, cold
reload, replay, no old-save backfill, all return payment variants, death and
mission-item survival, bounded genuine logs, incompatible/corrupt preservation,
read-only preview/cancel behavior, explicit display persistence, and full
original-field currency/material/crew/map/death parity with warm mode disabled.
These backend tests do not substitute for the separate native collection/display
UI lifecycle and pixel checks.
