# Encounter and event-detail pages

Local presentation work in `codex/coherent-pages-v3`. Owned implementation is
`EventBaseView.lua`, `EventLayer.lua`, and `EventDetailsLayer.lua`. Shared themes,
map layouts, event manager, save owners, economy tables and combat are unchanged.

## Composition

- Encounters have a compact navy name/type header, restrained site illustration
  and status, cream reading surface, separated entry requirements, and one teal
  action beside a quiet leave control. Narrative and prepared enemy information
  flow vertically in a clipped native scroll area above the fixed action dock.
- Illustrations use the exact source record's `gid`/`occupationgid` in the shipped
  map-event atlas. High-resolution clean stone/iron/timber props apply only to
  their documented stronghold IDs 3067/3068/3070. Missing mappings produce no
  substitute art. No illustrated object is a new owned item or reward.
- Cemetery, tavern, black market and cargo have a native selectable quiet list
  with the selected record's full details below it. Only that selection offers a
  primary action. Burial is secondary; cargo is read-only. Names, quantities,
  prices, revival material costs and black-market remaining limits are visible.
- Actual skill IDs still resolve through `CrewSkillDetails`, preserving skill
  versus buff provenance. Long skill text scrolls without overlapping actions.
- Eternal-arena checkpoints use a clipped native selection table. Selection
  updates the one fixed challenge action with the original level/cost record.
  Leave never scrolls away. No checkpoint is synthesized into saved records.
- Explicit Warm opt-out keeps the old event compositions and label contracts.
  Unknown legacy modal callers do not receive a global light-body override.

## Controller and transaction boundaries

All ten shipped dispatch families remain bound to their original entry methods:
combat, materials, supply, tavern, black market, resurrection, next-map,
teleport, arena and eternal arena. Original gates, prepared fighter/drop data,
combat callbacks and active `FightRewardScene` collection remain authoritative.
Original `checkEnterNext` behavior is retained, including the existing
resurrection handler's entry check. No renderer-owned save, free item, unlock,
combat outcome or change to map geography is added.

The revival, burial and recruitment transaction closures remain the original
ones. Their confirmation presentation is now an owner-bound clean dialog.
The market still performs its original price deduction, battle-pack insertion,
resource-unit upgrade and `trySaveLimitedData` operation. `checkDatas` still
removes exhausted records. Timer refresh updates the actual market list and
invalidates any old selected action. No new confirmation is added to the
original direct in-game market purchase.

Encounter buttons retain native `SDButton` objects and listeners with measured
faces and zero extra hit padding. Dragged releases, stale event generations,
repeated in-flight actions, children and active modals block click-through.
Selection-generation guards invalidate old detail actions after a purchase or
refresh. A family gate that installs no action cannot inherit the previous
site's callback. The guide finger uses the relocated real primary control.

Details are tracked by their event owner; leaving invokes the original callback
once. Parent cleanup removes an orphaned detail/confirmation and makes retained
callbacks inert. No detail page directly unfreezes the map. `EventManger` remains
the owner of freeze/unfreeze, queue completion and HUD restoration.

## Verification

Run from this worktree with the frozen existing Linux native harness:

```sh
source ../linux-runtime/env.sh
EGL_PLATFORM=surfaceless MESA_SHADER_CACHE_DISABLE=true \
  ../PirateExplore-coherent/build/linux/tests/tutorial-log-native \
  tools/tests/coherent_event_pages_native.lua
python3 tools/tests/occupied_event_copy_regression.py /workspace/shared/lua51
```

The native suite uses real Cocos `LabelTTF`, `ScrollView`, `TableView`, menus,
`SDButton` touch methods and cleanup, with shipped CSV records and isolated
in-memory transaction/controller boundary fixtures. It covers all **344
records with dispatch functions**, all **10 families**, unoccupied and occupied
variants, at **480×800, 540×900, 640×960, 640×1136 and 720×1280**. The 345th source
record is the initial-point record without an event dispatch function.

Coverage includes actual prepared enemy names/stats, original occupation copy,
required tools, native dock press/release/drag rejection, stale and repeated
callbacks, checkpoint cost/level routing, all four detail categories, exact
revival/recruitment/limited-market deltas, modal cancel, long/empty lists,
original next-map/teleport gates, active material/supply reward handoff and
owner teardown with a retained confirmation callback. Real `EventManger`
freeze/unfreeze/completion methods are exercised against both clean/legacy map
owner fixtures and minesweeper completion. This checks their shared lifecycle
contract; it is not an actual TMX/render-path gameplay run.

The existing occupied-event regression also verifies all nine material-site
completion/revisit transitions, the exact reef-copy correction, both reef enemy
identities and drops, the five original difficulty ranks and preserved history.
The final native run passed **88,756 assertions**, with no Lua errors.
Syntax and `git diff --check` pass. No player save or app profile was touched.

Actual desktop visual acceptance and natural full-game progression remain the
independent reviewer's gate. No Mac/mobile or complete low-poly art refresh is
claimed. No commit or publication is part of this worker's scope.
