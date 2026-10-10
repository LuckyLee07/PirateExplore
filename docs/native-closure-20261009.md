# Native Linux baseline closure — 2026-10-09

## Tested revision and environment

This closes the bounded native baseline through commit `d74ca9f63bd2717f1a812830f7de4989fba99fa0`, tree `3ac192a419da970c93623a2f49ddeb5a1db8716c`. It includes the restored v10 game, current art, quest fixes, camera/desktop viewport fixes and replacement-TMX nearest sampling. Auxiliary/tutorial/render edits begun after this baseline are **not covered** by this report.

- Assistant cloud Linux desktop; Cocos2d-x native executable, not browser/LÖVE. Real 480×800 and 540×960 windows were exercised.
- Clean recovered-source build completed. Native engine was rebuilt after both base and actual desktop viewport overrides changed; it includes the tile-flags binding and restored render-texture matrix fixes.
- Final executable SHA-256: `84220ebf5044be21b7e3e15a1c3a9443971ac10bb1f3ae1a829d25df80358330`. Repository `build/linux/bin/PirateExplore` and the tested overlay executable match.
- Build dependencies: `linux-runtime/env.sh`; build: `BUILD_JOBS=6 ./linux.sh build` after sourcing that environment. Run only with an isolated `XDG_CONFIG_HOME`.
- Evidence directory: `linux-runtime/native-qa-continuation-20261009` beside the repository. Logs, screenshots and disposable profiles are external evidence, not shipping game resources.
- Window title retains a historical “Initial” label; the hashes and copied source establish the tested version.

## Passed native interactions

### Ordinary navigation on a copied earlier QA save

No resource/party injection preceded these checks:

- Recruit: actual confirmation charged 3 gold, 3471→3468; standby ID100 increased by one, diamonds unchanged.
- Departure and directional movement reached the cemetery. Revival cancel returned to the list; actual revival changed deceased sailor ID101 2→1 and standby 0→1. Warehouse Gospel supplied the 50-item cost after battle-bag fallback; net 329→283 included existing +4 production.
- Burial removed the last deceased sailor row and added corpse dust1035×1; standby roster stayed unchanged.
- Actual portals/world chart traversed chapter1→chapter2→chapter1. Cold restart preserved chapter, fog progress, food/keys/dust and recruit/revival/burial results. `natural-roundtrip-completed` preserves this state before later fixtures.
- Screenshot41 is current-source ordinary chapter1 navigation with normal fog and HUD, cold-restored from that round trip.

### Controlled setup, production GUI callbacks and persistence

Virtual resources and encounter inputs were injected only into disposable profiles. These checks do not represent natural game balance or chapter completion.

- Quests: one real reward click produced exactly108 coins/12 diamonds/12 food/2 heroes, removed the claim, and retained successor plus unrelated quest. Reopen, production save reload and no-reseed process restart passed. Three adjacent/interleaved expired quests disappeared while completed/two live quests survived. Non-last quest progress retained the unrelated final quest through restart. `quest-results.log` contains the assertions. Direct duplicate-claim idempotency is covered by production-Lua regression, not an unsafe second physical click on a shifted row.
- Boarding victory: real combat updates ran against shortened synthetic HP; three first-open chest clicks yielded three rewards, including diamonds1000→1005. Actual loot-row pickup, empty-pick-all feedback, close-to-map and15-diamond return-to-base passed.
- Chest retry: first failure was free; actual retry charged2 diamonds (1000→998), awarded5 food, then another seeded failure and Give Up revealed remaining contents without granting them or charging again. Actual pick-all collected subsequent combat loot.
- Ship victory: real attack/update, victory, pick-all and return-to-map passed. Ship defeat: actual50-diamond revival charged1000→950 and retained crew. Boarding defeat: Confirm Death→Return increased deceased sailor count2→3, removed him from battle queue, returned home and spent no diamonds.
- Promotion: actual sailor101→102 consumed exactly one armor1043 and sword1053. Craft: actual recipe produced item1336 once and consumed its supplied ingredient exactly.
- Market: real long-press dialog bought10 and100 leather, charging30 and300 gold exactly. A2.6-second hold created one dialog, not stacked duplicates. This continuation does not claim a separate single-buy test.
- Inventory: actual long-press sale of10 Gospel deducted10 and added10 gold. Unsupported-item feedback was also observed. Filter and material-shortcut coverage is not claimed.
- Learning: real coin-learning event for talent2006 charged700 gold, learned it once and removed its event. Diamonds unchanged.
- Seven-day: day1 eligibility was seeded; real Claim awarded100 gold/1000 food and advanced the day/date flag. This is one claim plus cold persistence, not seven elapsed days or same-process repeated-claim proof.
- One cold restart verified the combined promotion/craft/bulk-purchase/sale/learning/day1 results:99060 gold,214 diamonds,1755 food,110 leather,433 Gospel, promoted sailor102×1, crafted1336×1 and learned talent2006 once.
- Valid expansion: original shop row1 unlocks chapter6 for100 diamonds and extends limit5→10. Cancel preserved state; Confirm charged100 and original achievement66 awarded5, yielding1000→905. Shop row1 recorded once; actual chapter6 entry and no-reseed cold restart retained905 diamonds, limit10 and chapter6. Initial impossible chapter5 setup is excluded below.

### New-save opening

A genuinely empty profile, without currency/guide injection, passed storyboard advancement, home→alchemy route,10 actual short taps, construction gate and first warehouse build (10→9 gold). Cold restart retained guide steps1/2. This is **new-save opening through warehouse build and cold restart**, not the entire tutorial or first-sea movement sequence.

## Visual/render acceptance

- Current crew portraits, resource icons, ship/boarding decks, six terrain landmarks and both chest states rendered in native windows.
- Final cold ship caption39 and chest Give Up40 were accepted. Give Up hides both cost/free footer nodes; a fresh screen still displayed free opening and subsequent2-diamond offer.
- Actual camera geometry audit passed45 checks each on chapter1 and maximum map13: zoom0.3/0.8/1, corners, recenter and repeated zoom using production methods. Representative native renders supplement this; these are not45 physical drags.
- Replacement TMX sampling defect was isolated by hiding Blocks_1 and then restoring it with nearest sampling. Final cold source capture49 verified original GID91 tile13,17 inside the chart with camera focus15,16 and fog visibility off, without a sampler override. Exact former false edge segments were absent. Normal fog/player camera was restored afterward.
- Final theme captures44/45/46 are controlled camera/fog-hidden fixtures on original maps4/6/13, at0.65/0.65/0.8. Screenshot21 is a paused synthetic boarding encounter. They are not natural exploration-progress evidence.

## Failed fixture attempts and limits

- Early event logging serialized cyclic scene objects and overflowed; changed to bounded scalar logging before successful combat tests.
- Screenshot47 is rejected: a diagnostic ran immediately after asynchronous `gotoMap`, touched a destroyed Explore and captured the wrong chapter. Final49 used the attached Explore, explicit map/GID/fog assertions and `SEAM_FINAL_V1_READY`.
- Original expansion fixture incorrectly used limit4/chapter5, a state with no shop row. The real callback logged nil `lockMapInfo`; the fixture was corrected from actual CSV to limit5/chapter6 and delayed chart creation until scene attachment. A900-diamond assertion also omitted the legitimate +5 achievement; corrected evidence proves905. These failed attempts remain in logs and are not concealed or counted as passes.
- Long holds on fresh alchemy do not invoke short-tap actions; the unsuccessful hold attempt was followed by10 real short taps.
- No natural full-chapter/story completion, all-endgame coverage, device audio, real-money/SDK transactions, iOS/Android/macOS acceptance, arena/tavern/black-market route coverage, DiamondStore subpage coverage or complete first-sea tutorial is claimed.
- Existing no-audio-device FMOD/ALSA, empty time-sync URL, legacy particle and optional unused atlas lookup warnings remain. Native window close leaves its foreground process alive; the process was explicitly terminated after testing.

## Final verification and cleanup

- `bash tools/tests/run-adventure-ui-tests.sh` passed at the baseline, exit0,120 `PASS` lines. Final log: `regression-final-closure.log`, SHA-256 `d1b40bd1cb94b2e708f3e2b2ba381e1cb49da8754d2d16eb91c2e370bd2d46c4`. `git diff --check` passed at closure.
- All eight historical files under the old repository's `build/linux/initial-player-data/PirateExplore` match the before-manifest: `gameRole`, `UserDefault.xml`, and `gameMap1` through `gameMap6`. `protected-final.json` records all hashes; manifest SHA-256 `b6e0abdbe6e8afb5c1793c2dc0b1e47a95762998150bd67c582d04643b53a749`. Those saves were never used as writable launch targets.
- No production bootstrap hook was installed. External overlay `main.lua` was restored byte-for-byte to production; no pending QA command remains. Harnesses remain external for reproducibility.
- Desktop window inventory shows the game closed; desktop-side `pgrep -x PirateExplore` verified no remaining process (`process-stop.txt`).
- No remaining non-platform blocker for this bounded baseline. Later audit repairs require their own regression/native acceptance. No GitHub publication occurred.
