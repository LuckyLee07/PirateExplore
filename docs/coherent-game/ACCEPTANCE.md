# Coherent loop checkpoint 1 — 2026-10-11

This is a tested local visual-loop checkpoint, not a claim of a fully finished all-page game or a published release. Baseline is public `ca9d4f397ea15731937f21187be6df799af68b8f` / tree `2a3c24b18c8e48b0f7ee53f9e85944f66bdcc8c1`. Work is isolated on `codex/coherent-game-v2`.

## Implemented

Shared clean fonts/colors/surfaces/functional icons; same voyage harbor/boat/sea in Home and preparation; quieter real manifest; low-food advisory; clear return/failure receipts with state-responsive onward routes; distinct stock/keepsakes/history/clues; less competing growth emphasis; focused real forge construction; shared business/dialog/battle framing; narrative vignette frame and readable Next; consistent alerts/toasts. The original transaction and gameplay owners remain authoritative. See ART_AND_SCOPE.md for inherited artwork and remaining page-composition depth.

## Automated verification: PASS

Native Linux source build completed. Executable SHA-256: `8037868ad30d834927637c20aeac02e355ade05d5bbfc3fe2e4f58dfe5f169ed`.

Run from the checkout with the README dependencies and real Lua 5.1:

```sh
LUA_BIN=/path/to/lua5.1 bash tools/tests/run-coherent-game-tests.sh
```

The final frozen-source aggregate passed:

- Warm: 8 logic and 12 real Cocos/EGL native suites, 20 total.
- New focused chrome, navigation, growth, preparation/return, failure, focused forge, hunger availability and shared-theme checks.
- Real narrative/toast suite: 13,816 assertions at 480×800 and 640×1136; all seven opening stories and 24 overlay stories.
- Real running-scene teardown and exact Director shutdown with unretained pause/dialog/settings sheets. Five independent guard-removal counterfactuals reproduce native SIGSEGV; fixed code passes.
- Original legacy aggregate with explicit `WARM_PIRATE_V1=false` fixture mode.
- Clean map/view/HUD conservation, font coverage and whitespace checks.

Native component fixtures are in-memory controlled tests. They are not a substitute for the full-game checks below. The fixture update for navigation adds the native `isRunning` API that the production lifecycle guard now uses; running-scene exit semantics are tested by the separate real-native suite.

## Actual native application checks

Independent reviewer used a new isolated profile, then actual mouse input and production saves. No role/cargo injection was used in this natural loop.

- Clean Home/preparation at 540×900 and 480×800; body/font/icon/compact bounds rechecked after fixes.
- Missing-food departure warns and remains in preparation; low-food advisory does not change legality.
- Actual first voyage departed with 20 food and one sailor; real rescue choice, checkpoint and cold restore: map 1, position (7,7), food 13, cargo 15/20 restored exactly.
- Walked port return: food 10, one crew returned. Original settlement receipt: +25 gold, +10 food, +15 stone, +5 wood, +2 iron, +5 cloth; earned first memorial.
- Collection Cancel/reopen/place and genuine first-voyage log worked.
- Actual forge construction consumed 25 gold, 15 stone, 2 iron; actual cargo recipe consumed 5 wood, 5 cloth and changed capacity 20→30.
- A second deliberately under-supplied voyage reached original NoBread handling, new saved failure result and real empty-crew recovery/recruitment.

The final focused-forge layout and latest hunger/alert copy were added after those original natural-route transactions and require their separate final desktop recheck. Their source/native transaction tests pass; this distinction is intentional.

## Release blockers / unfinished acceptance at this checkpoint

- The baseline pause assertion and separate native HTTP shutdown hang are resolved in the stability follow-up. Independent actual pause/resume, Home settings and preparation dialog window-X paths each returned exit 0; the same voyage 3 checkpoint reopened exactly. See `../coherent_http_shutdown_lifecycle.md` for isolated HTTP/cancellation and bundled-curl API checks. This is Linux acceptance only.
- Independent actual old-save-copy compatibility passed on original chapter 6: active position, food, cargo and existing chart were retained; movement, checkpoint save and exit 0 worked. Original historical save hashes remain unchanged. Comprehensive rapid-input and final battle/late-page visual coverage remain pending, using disposable fixtures only.
- Some original business/utility layouts, story/combat actors/decks and later-map composition retain inherited content with shared framing. They require subsequent redesign and review; see PLAN.md and ART_AND_SCOPE.md.
- Linux native only. No macOS/iOS project restoration, Apple build, mobile/touch/audio/performance acceptance, signing, store release or working online-service acceptance.

No remote push, PR, merge or deployment belongs to this checkpoint. Source backups exclude player saves, native build output, accounts and temporary test evidence.
