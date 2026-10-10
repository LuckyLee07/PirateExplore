# New gameplay branch: encounter and paid-boat baseline

Scope: `work/gameplay-redesign-v1`, based on c1c7c8a. No changes to the frozen UI checkout, payments, prices, product contents, recharge or 398 entitlements.

## Encounter probability

`SkirmishLogicManagers:useTheDice` previously read the configured rate and then replaced it with 100. The legacy `random()*100000%101` plus `rate > roll-1` was also not a conventional percentage test. The new branch uses one `math.random()*100` draw at the same point, rates 0 never/100 always, and `roll < rate` for intermediate percentages. The candidate selection draw remains unchanged, as do position, mission, encounter count, enemies, drops and consumption paths. This intentionally changes outcomes for the same random stream but not draw count/placement. The CSV rate is each candidate encounter’s probability of passing this filter, not necessarily that enemy’s final appearance probability: candidates share the same roll, then the existing random selection chooses among all passing candidates. With multiple candidates, their correlated pass results and the later selection affect the final appearance distribution.

The dedicated regression covers actual packaged mission-24 encounter rate 20, roll 87.354 rejection, 0/20/100 edges, map and inclusive area bounds, inactive missions, exhausted counts, candidate selection and prebattle consumption. It is a deterministic production-method fixture, not a statistical or native UI acceptance test.

## Paid boat

The moving golden boat is now a plain Sprite instead of an SDButton. The 60-second timer remains decorative and has no offer callback or touch listener. The fixed Port `礼包（付费）` entry and original dialog remain intact. Returning home does not auto-open an offer. Tests exercise the exact decoration block, repeat timer, no listeners/callbacks, pre-voyage state and cleanup; the existing Home suite covers fixed-entry gates and offer close/reopen/repeat.

Native acceptance still needs a returned-harbor profile: wait through multiple boat passes at 540x900 and click the historical conflict at screen (128,756), plus compact/regular sizes. Verify the underlying intended Home action receives the click and no paid dialog appears; verify fixed Port entry still opens the unchanged offer. Plain sprites cannot swallow touches, but visual occlusion at the original high-z trajectory is not certified by node mocks. No purchase should be executed during QA. Linux checks do not certify iOS/Android payment SDKs or device rendering.

## F07: confirmed cache issue and separate unresolved frequency rule

The production abandonment method removed the active/waiting/completed/save entries but left `validMissions`. Its real encounter condition reader therefore still accepted the abandoned mission until map refresh. The fix clears that cache immediately. Regression covers the real condition filter immediately after abandonment, map refresh, reload, and real packaged task 24 abandonment/reacceptance; duplicate claim calls on the same completed instance invoke its reward effect only once. Full reward dispatch remains covered by the existing quest suite.

A separate diagnostic confirms `triggerMissionByIDAndStepInfos` reads the saved remaining count and then overrides it with nil. For a configured limit of 3, saved 0, saved 2 and absent history all accept and store 2. This behavior is intentionally unchanged in this patch. Actual task 24 has frequency 1, deducted at acceptance. Removing the override alone would permanently block its current abandon/retry path. Whether frequency should limit acceptance or completion, and how abandonment restores an allowance, requires a separate rule and migration decision. No blanket refund, reward change or history migration was introduced. New gameplay one-time payouts must use their own stable settlement state and cannot rely on this legacy frequency behavior.

## Verification commands

Run from repository root with `/workspace/shared/lua51`:

- `tools/tests/encounter_rate_regression.lua`
- `tools/tests/decorative_gift_boat_regression.lua`
- `tools/tests/mission_abandon_limits_regression.lua`
- `tools/tests/home_master_regression.lua`
- `tools/tests/quest_reward_regression.lua`

The parent owns aggregate integration and native QA.
