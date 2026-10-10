# Early harbor choices — 2026-10-10

## Evidence boundary

This change adds read-only suggestions and navigation, not rewards or balance changes. The numerical analysis below decodes the **shipped encrypted CSV** through the existing Record/LZSS test decoder. Source models are not natural-play evidence. Native acceptance for the forge prerequisite, apprentice furnace, completion filtering and Gather reentry is now recorded in the final section and linked natural-play report. Cargo manufacturing is not claimed in this pass.

Initial-state assumptions: zero coins, alchemy yield 1, gather base 10, capacity 20, no materials except genuinely earned tutorial/exploration rewards. Alchemy has a 0.3-second input cooldown. Exact elapsed time depends on physical clicks and navigation; the theoretical rate is not an observed playtime.

- Warehouse 1 + house 5 (and stone 5) + market 5 + farm 2 + dock 20 = 33 coins. Without other rewards, this is 33 successful alchemy clicks.
- Ordinary Gather independently yields 8–12 stone and 8–12 wood, with a nominal 30-second cooldown. It is not one material per click.
- First dock tutorial supplies 100 food. A default 2-farmer/1-chef assignment produces 2 wheat and consumes 2 wheat for 1 food per production cycle (nominally 20 seconds). Do not claim current server-backed offline accumulation works merely from this rate.
- Forge: 25 coins, 15 stone, 2 iron. Cargo upgrade: 5 wood + 5 cloth; capacity becomes 30. Cloth's shipped price is 2 coins each, making a five-cloth shortfall 10 coins through the existing missing-material flow.
- Apprentice alchemy furnace: 5 iron; alchemy becomes 2 coins per click. Iron's shipped price is 3 coins each. If all five iron are bought and initial yield is 1, the 15-coin outlay breaks even after 15 subsequent clicks; found iron makes this tradeoff different.
- Ship factory is a different, more expensive branch: 100 coins + 180 stone + 160 wood. It is not required for the first cargo upgrade.

## Minimal design and state matrix

The approved Home scene, artwork and geometry stay intact. Its existing lower-left 308×87 design-space ink status plaque becomes an opt-in “回港升级 ›” entry, only after the first actual return and when selected crew and food are available. The primary preparation action and urgent missing-crew/food hints remain unchanged.

The existing-style dialog shows up to two choices with actual target values and live inventory shortfalls. It never purchases, manufactures, grants resources or unlocks anything.

| State | Suggestion and navigation |
| --- | --- |
| Before first return | No upgrade suggestion; original tutorial/preparation flow |
| No selected crew or food | Original urgent preparation hint |
| Cargo below CSV target / alchemy below CSV target | Show the unfinished choices |
| Forge available but unbuilt | Name the forge prerequisite, show actual forge shortfall, open original construction list at forge 57 |
| Original recipe unlocked | Show actual recipe shortfall, open original manufacturing list at resource 1148 or 1176 |
| Forge/recipe not unlocked | Honest unavailable explanation; no false construction/manufacturing action |
| One upgrade complete | Hide that choice; retain the other |
| Both complete or advanced save already exceeds targets | Return to original readiness hint; never recommend a downgrade |

Navigation uses optional arguments to existing Dispatch and page constructors; calls without arguments preserve previous behavior. List positioning changes only the view offset, without reordering saved data. Manufacturing and construction continue through their existing callbacks and costs.

## Verification

Run from repository root using a Lua 5.1 interpreter:

```
$LUA tools/tests/harbor_goals_regression.lua
$LUA tools/tests/management_ui_regression.lua
$LUA tools/tests/home_master_regression.lua
```

The dedicated test reads actual packaged recipes and validates prerequisite gates, exact deficits, runtime parsed matrices, target changes derived from CSV, complete/advanced saves, immutable data, clamped list offsets, opt-in dialog lifecycle, repeated open, close/reopen, live changes, original route targets and original plaque dimensions at 480×800 and 540×900. These are mocked-rendering/source contracts, not a native screenshot claim.

No changes to DataManager, paid long-press entitlement, alchemy promotion thresholds, offline-production logic, CSV costs, generated art or the approved master scene are part of this work. Offline production and onboarding log layout have separate owners and acceptance.

## Observed waiting and payment interruptions

The native player reproduced the old Gather reentry defect without injected time or resources: gather at about 01:06:15 UTC, return to Gather at elapsed 14.488 seconds, then attempt again at elapsed 35.743 seconds. No materials were awarded and the button was still cooling down. Source used a fresh 30-second progress action after reentry instead of the remaining time. Commit `4a0969d` preserves the original click timestamp and resumes only the remaining duration in both page entry and foreground restoration. Exact-deadline, repeated reentry, foreground and unchanged 0.3-second alchemy behavior have production-callback tests in `gather_cooldown_regression.lua`; native after-fix acceptance is recorded below.

The native player's first return also displayed an unsolicited real-money gift dialog, which was declined without payment. Source confirms MainMenu creates `PushGiftView` after a 0.3-second delay whenever its saved map state exists and the player is at base. A voluntary route exists on the golden boat that crosses the screen for 10 seconds every 60 seconds, but that is a transient entry. A later change could first provide a stable voluntary entry to the same existing offer, then replace the automatic interruption with a quiet cue. This proposal is **not implemented** in this change; purchase callbacks and entitlements remain untouched.


## Native acceptance closure

The independent [natural replay report](growth-loop-natural-play-20261010.md), committed at `c9daa074`, closes this first iteration with exact build/profile boundaries and screenshot references.

- New card 17 showed both real target values and the forge prerequisite with 20 missing gold. Clicking it focused the original forge row. The naturally earned purchase deducted 25 gold, 2 iron and 15 stone.
- Card 19 showed the new exact shortages, 5 cloth and 2 iron. Its furnace action focused the original recipe. Six naturally earned gold bought 2 iron, crafting consumed 5 iron, and a subsequent alchemy click visibly paid 0→2 gold (20).
- Card 21 retained only the cargo goal after the furnace was completed. This is natural evidence of completed-goal filtering; the second cargo upgrade was deliberately not ground out solely for testing.
- Repaired Gather: reentered at T+13.930 seconds and successfully gathered at T+34.819 seconds, gaining 10 stone and 8 wood (24). The baseline had failed at T+35.743 seconds after a T+14.488-second reentry. This directly verifies that returning to the page no longer adds a fresh 30-second wait. The exact 30.000-second boundary remains covered by callback tests rather than a claimed physical timestamp.
- The native run ended safely, all eight protected historical save hashes remained unchanged, and both natural and 480 profiles were preserved. The natural final state retains capacity 20 and alchemy 2 coins/click. No real payment occurred.

See the canonical report for the separate offline-production, icon and compact-layout acceptance, plus the still-unfixed Linux window-close process limitation. Those systems are not part of this change's implementation scope.
