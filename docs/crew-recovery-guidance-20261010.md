# Crew recovery guidance — 2026-10-10

## Observed problem and unchanged economy

The separate natural-play owner lost the original crew on green reef3106 floor2. Home displayed “请招募船员”, while its primary action opened preparation; the recruitment menu only reported a missing training camp. The owner then naturally earned and spent30 gold building the camp and3 gold recruiting a replacement. With the earned apprentice furnace,17 effective alchemy clicks paid34 gold, leaving1. This establishes a viable33-gold recovery path, not a balance change or a combat-win claim.

Shipped CSV records establish shipyard56 unlocks camp58, camp58 costs30 gold, and crew100 costs3 gold (HP5, attack1, speed4.3). The new helper reads the actual CSV prices and current money. No resource, entitlement, paid-revival, recruitment, or construction rule changes.

## Narrow change

Only Home gains a contextual, opt-in recovery preview. With no selected or reserve crew, after the original starter grant has already occurred, both its status and primary CTA say “补充船员”. The existing AlertView shows the original camp/recruit costs, current-step shortfall, and instruction to assign crew and food afterward.

- Unbuilt, available camp: missing funds routes to original alchemy; enough funds focuses original building58.
- Built camp plus original recruitment gate: missing funds routes to alchemy; enough funds uses guarded menu route2.
- Missing/inconsistent building/gate data or unsupported CSV cost shape: no navigation action.
- Crew in reserve: existing preparation action remains.
- First-run alchemy, unopened dock, and the dock's original first-entry crew/food grant retain priority. In particular, guide30:true must already exist before recovery can replace preparation.

Each primary/preview action re-reads current role data and gates. Opening, dismissing or navigating spends nothing. The original screen's explicit purchase confirmation remains required. The dialog closes on Home destruction or when newly acquired crew makes it irrelevant.

## Verification boundary

Passed focused Lua tests:

- tools/tests/crew_recovery_regression.lua: decoded shipped CSV and runtime matrix costs; current shortfall; absent/unbuilt/built/inconsistent gates; original tutorial/starter-award priority; reserve/selected crew priority; stale money/gate/crew changes; guarded recruit navigation; no role/CSV writes from previews; repeated open, dismissal, reopen, and page destruction; both portrait-size constructions.
- tools/tests/home_master_regression.lua
- tools/tests/harbor_goals_regression.lua

The new test uses controlled in-memory state and does not modify player saves. Portrait construction checks are not native screenshot acceptance. The observed natural33-gold recovery predates this guidance; a separate cold native recovery-copy check is still required to accept the new dialog's layout/routes. Shared aggregate runner integration is owned by the parent task.
