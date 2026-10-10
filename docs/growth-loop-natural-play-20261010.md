# Growth-loop natural replay — 2026-10-10

## Scope and reproducibility

This is a **new empty test profile**, not a continuation of the missing October 9 thirty-capacity save. A full fresh Linux CMake build at restored `08659d78261e0637ebd57f4c0397e22886693d08` (tree `9ff80b2ac93f7786f457573e00ea178df655ce11`) succeeded. Binary SHA-256: `51ef863474d418e7d70a48d97df7c3e244b4c0ce38c5f420aff5fd414822039a`. Production main SHA-256: `a20c125972cae7b0e5f193f34eec8806291077295a145abed80194e00255a9bd`.

The real native 540×900 window ran on the assistant cloud desktop, with physical GUI inputs. The opening's original advance/skip control was used. No QA bootstrap, resource, guide, time, HP, map or unlock injection was used. All virtual spending below was naturally earned. No real purchase, external name/CDK/ranking submission or GitHub action occurred. The original eight historical save files were never launch targets and all hashes remained unchanged.

Evidence is external to the repo, under `linux-runtime/growth-play-20261010`: build.log, natural.log, launch-source.txt, initial-empty-profile.txt, screenshots 01–15, protected-before.json and protected-after-first-voyage.json. Runtime profile is `fresh-profile/PirateExplore`; the naturally earned checkpoint is separately copied to `natural-after-voyage-one-closed` (post-window-close copy; the earlier `natural-after-voyage-one` copy was taken while the window was still live). The game was closed with the native window × at 01:08 UTC; the subsequent window inventory contained no game window. Alt+F4 via the bound window had not closed it and is not counted as shutdown.

## Observed natural ledger

- Start: zero coins and diamonds, no food or crew. Home gave the visible “先炼金，再建港 / 前往炼金” goal (01).
- First 10 real alchemy presses took 3.596 seconds and paid 10 gold. An original achievement paid 1 diamond. A compact +10 receipt appeared (03).
- Warehouse cost 1 gold. First Gather at 01:00:13 gave 11 stone and 11 wood (05).
- House cost 5 gold and 5 stone, granting 5 villagers. One alchemy press funded the 5-gold Market. Another 22 presses took 7.993 seconds; Farm cost 2 gold and Dock cost 20. Total early construction funding was exactly 33 alchemy presses, plus 5 construction presses and one Gather. No economy values changed during this baseline.
- First Dock navigation granted the original one crew and 100 food. Two Fill presses loaded one crew and 20 food, leaving 80 food in reserve (07). Approximately 52 physical inputs from the first home CTA through departure were required, including 33 alchemy clicks and two attempts on the sailing navigation. Story advance and the initial accidental harbor menu close are excluded from that count.
- Four guided sea clicks, right/right/up/up, reached the iron mine. Food was 17 on entry. Both original 3-HP skeleton encounters were won automatically with the original 5-HP crew; no healing, instant kill or revival was used.
- First reward was 5 gold. Second reward was 5 iron. “全部拾取” could take only 3 iron alongside 17 food, filling capacity 20 (08). Two physical food-quantity taps moved 2 food to the drop side; two iron-quantity taps took the remaining 2 iron. Final cargo: 15 food + 5 iron (09).
- Original first-free-return confirmation brought the crew home and transferred the 5 iron and 15 food, leaving 95 food in reserve and 5 gold/1 diamond. The automatic real-money gift then covered Home (10); it was closed without purchase.
- Subsequent genuine Gather rewards raised stone 6→16→26→36 and wood 11→21→31→41. Assigned 2 farmers and 1 cook, retaining 2 free villagers; actual timed food production was visible. No system-time change was made. A read-only decode of the post-close saved state showed 99 food, 41 wood, 36 stone, 5 iron, 5 gold and 1 diamond; the 4 additional food came from real foreground production. `baseline-closed-state.json` records the encoded-save-derived observation.

## Reproducible friction

### 1. Tutorial/history area clips its second line

At 540×900 the bottom text area shows about one line plus a clipped second line, while the early main area is largely empty. The construction/collection path is sometimes the clipped line. Screenshots 03–06 show this on several transitions. Screenshot 03 was taken shortly after the tenth click, so by itself it cannot prove settled animation behavior. Later captures confirm the narrow viewport; messages also visibly change after the screen is already actionable. The specific first-line path appeared later, so this is not a claim that the path never exists.

### 2. Cargo trade-off exists but has no visible instruction

The loot screen showed full capacity, remaining iron and two item columns, but no cue that clicking the left quantity discards one item or clicking the right takes one. The actual two-food-for-two-iron choice worked via four row taps. The user must discover a useful risk/reward mechanic by trying an unlabeled interaction. This is an observed discoverability problem, not a claim that taking all iron was impossible.

### 3. Gather cooldown restarts after page re-entry

A first timing attempt re-entered at T+37.384 seconds, after the original 30-second cooldown, and successfully gathered. It is **not** the reproducer.

The next successful Gather was at approximately 01:06:15. Returned through Warehouse to Gather at T+14.488 seconds. At T+35.743 seconds, clicking Gather produced no reward (13), even though the original cooldown should have ended. At T+55.302 seconds the same control paid +10 stone/+10 wood (14). This is consistent with the read-only source finding that page re-entry restarts a full 30-second UI timer. The GUI establishes the failure at +35.7 and success at +55.3; it does not measure the exact intermediate unlock instant.

### 4. First return interrupts the growth moment

Return displayed transient resource toasts, then an automatic 15-yuan gift modal. Closing it restored Home with “补给已备妥 / 整备出航”; no cheap cargo/alchemy upgrade destination was visible there in this baseline. The repeated-voyage motivation is therefore primarily another departure rather than a readable choice of spending the newly acquired iron. New growth UI is being implemented separately and was not loaded into this baseline instance.

### 5. Small-icon quality is inconsistent

The original 540×900 screenshot 01 has detailed coin/gem art and a richly painted harbor, while port navigation, food status and other tiny symbols use much simpler geometry. Screenshots 07–09 additionally show older small inventory art. New icon assets require a separate cold final-build comparison; these baseline screenshots do not accept them.

## Boundaries

This pass completed one original mine voyage, not sixteen chapters or late-game balance. No defeat occurred. Native audio and mobile/service behavior remain unverified. The run log contains no `LUA ERROR` or failed assertion. Code workers edited the shared tree after launch; this instance retained its loaded baseline modules. It was intentionally closed before any restart, pending an integrated native rebuild for the new engine/Lua changes. No mixed old-binary/new-Lua cold acceptance is claimed.

## Integrated natural recheck (closed)

Rebuilt the candidate at `5c0715edc0770afe6986d2630febfe28b40ee0d9`; executable SHA-256 is `14cbe4972a550dfaab8b9583c4513a9f1ab194f4e8ed8c453ac7defc177b370c`. Only test-runner commits followed before launch; the wrapper recorded `fc4028898c5065a1bd74658590b992ec0ac780ca` at launch. Newly required Record atomic-save bindings are in this binary. First integrated actual launch was 01:17:48 UTC.

- An old terminal failed to regain an interactive prompt after the previous window closed. This initially looked like a windowless game, but a fresh desktop terminal's `ps` plus `pgrep` found no game or wrapper process (`desktop-process-audit.txt`). No process was killed. The parent shell's PID namespace does not show a currently visible desktop game either, so desktop-side process checks plus window inventory are used for launch isolation.
- First migration read at 01:18:00: food stayed 99, the new ledger was `wall=1791595071, remaining=20`, while the earlier baseline had no ledger. It did not pay the roughly ten-minute old history. Normal foreground production then proceeded.
- Actual Home showed “回港升级” (16). Its card showed both capacity 20→30 and alchemy 1→2, each requiring the forge and showing the exact missing 20 gold (17). The original forge was focused at the top of Construction. Actual alchemy earned the 20 missing gold; forge purchase spent 25 gold, 2 iron and 15 stone.
- The card then showed 5 missing cloth and 2 missing iron (19). The alchemy action focused the real apprentice-furnace recipe. Six earned gold bought the original 2 iron; crafting consumed all 5 iron. One subsequent real alchemy click paid 0→2 gold (20). The card now contained only the remaining cargo goal (21). No cost, recipe or resource was injected.
- The 20-click fast funding attempt accepted only 16 clicks, followed by further actual clicks to reach the required balance; it is not claimed to have paid 20 immediately. Short-lived scene/modal transitions and the original cooldown can discard a too-early input. Resource/cost claims are based on visible final balances, not assumed click yields.
- At 540×900 both complete real log lines fit below the action row, without navigation overlap (20,22). New inventory food/wood/stone icons appear in the real warehouse (22). First new port icon was judged too light by visual review; that iteration is not final art acceptance.
- Repaired Gather was started at `1791595457058` ms. Re-entered after 13.930 seconds, then pressed at 34.819 seconds and received stone +10 (30→40) and wood +8 (51→59), before the old re-entry-based deadline (24). This is the direct counterpart to the baseline +35.743-second failed input. The exact +30.000-second boundary was not physically sampled.
- Closed the natural window at `1791595535023` ms (01:25:35 UTC) for a real offline interval. The static role contained food122, wood59, stone40, furnace1, gold2, diamond1, with two farmers/one cook and ledger `wall=1791595531,remaining=20`. Saved state and a complete independent profile copy were captured before reopening. The separate 480-pixel empty-profile test does not touch this natural profile.


## Final compact-layout and offline acceptance

- Final art revision `bcb00f4` was cold-loaded in both 480×800 and 540×900. Screenshots25 and29 show the final heavier port icon; screenshot22 shows the unchanged final food/wood/stone inventory assets. The earlier lightweight port in16 is superseded, not counted as final acceptance.
- A separate genuinely empty `fresh480-profile` used normal story advance, ten alchemy clicks, the1-gold warehouse and one Gather. Two full tutorial lines including Harbor→Gather fit with no action/navigation overlap (27); the actual menu, build, alchemy and gather inputs worked (26–28). This small replay did not touch the primary natural save.
- The first real offline settlement changed food122→141. Saved ledger wall1791595531/remaining20 became wall1791595916/remaining15: elapsed385 seconds, exactly19 production periods. Formula: floor((385−20)/20)+1=19. The process had actually been stopped for more than60 seconds before reopening; this is not a synthetic time fixture. The startup's first atomic save was captured by a read-only file observer.
- A subsequent cold restart was requested immediately after closing the resumed test window. UI/shell startup operations took about22 seconds; it was not a zero-time replay. Food146→147, ledger wall1791596011/remaining20→wall1791596038/remaining13: elapsed27 seconds, exactly1 newly earned period. It did not pay the earlier19 again. Legal foreground production between the first reopening and the next close accounts for141→146.
- Portable, minimal reconciliation records are checked in as `docs/evidence/offline-natural-20261010.json` and `docs/evidence/offline-repeat-20261010.json`. They contain only virtual-food/ledger arithmetic, not full saves, private user data or machine details.

### Shutdown boundary and final checkpoint

The Linux window × stops visible gameplay but can leave the native process alive without continuing saves. This is a Linux runtime shutdown limitation, separate from offline-reward accounting. Actual desktop-side `/proc` executable/arguments and `pgrep` were used to identify only the isolated test process before TERM. Every new profile launch first checked the same desktop process namespace and refused to launch if a game remained. The first480 launch was correctly blocked by that guard, then retried after exact-process cleanup. No two games ran together.

Final test process was verified and terminated at01:35:20UTC. The subsequent desktop `pgrep` was empty (`desktop-final-stop.txt`); the parent shell alone is not a valid desktop-process audit. Final original8file hash/size verification passed. Both completed natural and480profiles were copied only after closure.

Primary final natural state: gold2, diamond1, wood59, stone40, food151, apprentice furnace1, alchemy2coins/click,2farmers/1cook, capacity20. Ledger wall1791596111/remaining20. The extra food after the repeat-start observation is ordinary foreground production. No cargo upgrade is claimed in this pass. The source at checkpoint preparation is `adabec230f188ebfe5c270268f814ca324142049`; its intervening changes after the integrated native build were art/docs/test wiring, not missing compiled runtime changes. The same reviewed rebuilt executable was used throughout integrated acceptance.

Both natural and480logs contain no Lua error or failed assertion. Existing audio-device and empty-time-URL warnings remain. Native process cleanup was necessary and is explicitly not claimed fixed. This closes the first growth/icon/cooldown/offline acceptance round and preserves its real-save checkpoint for a separately verified later iteration.
