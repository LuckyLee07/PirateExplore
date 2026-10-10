# Adventure gameplay v1

## Runtime boundary

This branch starts only genuinely empty saves in version 1. No absent ledger on
an existing save is interpreted as a new game. Existing charts, inventory,
first three chapter access, paid entitlements and gift entry points are retained.
The original automatic battles, per-tile food use, crafting recipes and death
loss/revival-record rules remain in use. Continuous movement, individual named
combat characters and death protection are not included.

New saves contain built warehouse 1, house 2, market 53 and dock 56 (31 gold +
5 stone equivalent setup, not a cash reward). House population is 5, house 3,
farm 52 and training camp 58 are waiting, and market offers 1–3 are available.
The original first preparation gift remains exactly 100 stored food and one
low-level crew member 100. The player loads food and the real crew manually.
No diamonds or promoted crew are granted.

## First voyage and patrol

Rescue and supply are changeable plans on the same generated chart. A validated
empty sea tile two to four legal steps from the port is chosen without moving
existing events or revealing fog. Its return path costs at most eight base food
steps. The UI gives a direction, then shows the wreck only after revealing it.

The original forced map guide prevented random encounters. Its replacement
protects **only the verified port-to-wreck corridor in the first voyage of a
new save**. The HUD gives the next patrol direction and states that normal random
encounters are paused, while food and deliberately entered stronghold battles
remain unchanged. Leaving the corridor explicitly warns that ordinary random
risk resumes. The second voyage always uses the ordinary encounter logic.
This does not protect the entire chapter, prevent starvation, or soften enemies.

First wreck choices:
- Basic rescue: 3 food, 2 iron; successful return settles rescued NPC Lin En.
- Basic cargo: 0 extra food, 2 iron + 2 wood; no rescue NPC.
- Water sailor 101: rescue for 1 food with 2 iron.
- Knife crew 112: cargo for 0 extra food, 2 iron + 4 wood.

Only one option resolves. Profession actions inspect real battle-crew IDs.
Every option obeys actual item cubage. Full holds refuse the entire transaction;
the player may leave, discard selected cargo through the existing bag UI and
reopen the wreck. No food is discarded automatically. Choosing an objective
never forces its matching event branch.

## Return, upgrade and follow-up

A successful event return records its outcome. The one-time building subsidy
is paid only on a successful return actually carrying at least 2 iron:
25 gold + 15 stone + 5 wood + 5 cloth. Losing the iron delays the subsidy; the
NPC outcome can settle independently, and a later normal voyage with 2 iron
can satisfy the remaining requirement. There is no invented replacement iron.

Wreck resolution opens waiting forge 57. Building it still costs 25 gold,
15 stone and 2 iron; its original cascade opens produce 6. Producing resource
1148 costs 5 wood and 5 cloth and raises cargo capacity from 20 to 30. Guide
step 3 is genuinely available, so the original forge cascade is not skipped.
The Home goals show real shortages, and visual cargo crates use real capacity.
Farm, train camp, factory and double-person ship remain normal later goals.

After 30 cargo, the same marked wreck has one finite follow-up episode:
- Chart recovery: basic 3 food gives 2 iron + 8 leather (10 cargo); sailor 101
  for 1 food gives 3 iron + 12 leather (15 cargo). An actual generated chapter-gate
  bearing is settled after successful return.
- Cargo recovery: basic 6 iron + 6 wood (12 cargo), or knife crew 112 for
  8 iron + 8 wood (16 cargo), with no chart reward and no extra food cost.

The real market price equivalents are respectively 30/45/24/32 gold for those
material bundles (iron and leather 3 each, wood 1); they are physical cargo,
not cash. Basic chart recovery covers 8 of the 22 leather required by first
armour. Basic cargo covers half the 12 iron plus 6 of 10 wood for the first
sailor sword. Neither grants complete promotion gear or a free second crew.
At 30 cargo with 12 departure food and four outbound food steps, all four
bundles fit without automatic discarding. Full holds still reject the choice.
These two finite adventure nodes reduce part of initial growth friction; the
remaining normal economy and complete chapter balance are not claimed solved.

The NPC refers to it on rescue saves; the port material record refers to it on
supply saves. No second Lin En is rescued. A successful follow-up return closes
it permanently; a failed voyage loses ordinary cargo and can retry. It never
repeats the first-return subsidy. Chapter two retains original map/resource/
crew gates and the chosen plan, known route and real discovered material clues.

## Persistence

Starter grant, departure, event choice, safe return and new-mode death each use
a complete encrypted atomic role snapshot. Departure includes the at-sea flag;
return includes inventory, money/diamonds, surviving crew, ledger, transit cleanup
and subsidy. Death retains carryType 2 mission items exactly as the old flow,
records the same revival information and loses ordinary sea cargo/crew. A failed
save leaves the pre-operation snapshot and live state intact. Repeated callbacks
cannot duplicate grants, cargo deposits, or death records.

Legacy save paths retain their old behavior and are not silently migrated into
this reward/tutorial system. Exact native UI and complete chapter playthrough
acceptance is tracked separately from Lua fixtures.

## Parameters versus proposal examples

This playable revision deliberately uses the explicit option amounts above,
rather than the proposal's illustrative 2/1 food and different material bundles.
For 12 loaded food and a four-step outbound/four-step return patrol, source
verification confirms the final return step enters the real Meta3001 port and
costs **zero** food. Thus the actual ordinary empty-sea route costs 4 outbound
+ 3 return food: basic rescue 4 + 3 + 3 = 10, leaving **2 food**; basic cargo
4 + 0 + 3 = 7, leaving **5 food**; sailor rescue 4 + 1 + 3 = 8, leaving 4.
If conservatively budgeting eight chargeable moves instead, rescue would leave
1, not 2; that eight-debit example is not the verified port route. All examples
exclude healing, additional events, detours and discarded food. The HUD uses
the actual path tile costs rather than these illustrative counts.

## Candidate-two native findings and repairs

The first pinned native candidate reached the wreck using four real food moves,
but its target label had a zero-size MenuItemLabel hit box captured from its
initial empty label. Updating only the child text made it draw rightward and
allowed clicks to reach the map. The replacement uses fixed dimensions before
menu construction, a centered real hit rectangle, separate backed objective/
patrol rows, and an explicit exclusion of that HUD rectangle from map touches.

The first-wreck modal was not observed in the initial native screenshots; the
cause of that observation is not established. Later diagnostic runs showed the
complete modal in a stable-frame screenshot, and a fresh 5af228e rescue workflow
also displayed and completed it. This is not evidence of a proven rendering
bug or a specific queue failure. The ready/non-battle/non-hungry movement check,
scene-enter handling and bounded arrival status line remain; there is no
per-frame event trigger. Temporary modal object/address diagnostics were removed.

Cold-start inspection did establish a separate logical-position issue: the ship
sprite restored its saved location while playerTitlePosition remained at its
class default. Initialization now derives that logical tile from the actual
restored sprite position, including the original pre-battle offset, without
mutating the saved coordinate table.
Four original step-71 teaching gates in EventLayer blocked new-mode exit and
referenced the intentionally absent old guide component. They now apply only
to legacy saves, rather than granting a fictitious completed step. Ordinary
stronghold choices and chapter gates remain in use.

Return-button free-use flags, scrolls and diamond fees are now quoted from the
actual current-map CSV and rechecked at confirmation. They commit together with
safe return. A stale offer requires a fresh confirmation; failed storage leaves
all fees, the free-use flag and at-sea assets untouched. Legacy save callbacks
retain their original paths. The new death path also avoids pre-clearing the
cold-start battle retry flag before its atomic death snapshot succeeds.

## Native chapter-transition lifecycle correction

Actual first-chapter gate combat succeeded, but the subsequent chapter-two
cutscene exposed an invalid Cocos node reference: Explore rebuilds moveLayer
children in place while retaining its Lua owner and tipLayer HUD. The old
route overlay was already released when navigation refresh tried to remove it.
The wreck marker shared the same lifetime risk. Both map decorations are now
explicitly removed and their owner references cleared before map destruction;
the surviving HUD is retained. No exception swallowing, chapter flag edit or
combat shortcut is used. The regression exercises the real map-reset prefix
and decoration functions with a node model that rejects access after release,
including two consecutive resets and the non-clearing initialization path.
