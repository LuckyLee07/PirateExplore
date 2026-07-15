# Product Iteration Log

This log records product-facing changes made after the long-term roadmap was
created.

## 2026-06-18: Batch A, First-Session Clarity

Goal:

Make the first session point more clearly toward the core pirate loop:

```text
alchemy -> build warehouse -> gather resources -> build shipyard/training camp
-> assign food and crew -> sail
```

Changed files:

- `bin/res/scripts/LuaClass/MainMenu.lua`
- `bin/res/scripts/LuaClass/DataManager.lua`
- `bin/res/scripts/LuaClass/Resource.lua`
- `bin/res/scripts/LuaClass/Expedition.lua`
- `bin/res/scripts/LuaClass/BaseView.lua`

What changed:

- Rewrote the opening system messages to frame the fantasy as rebuilding a
  stranded pirate crew.
- Rewrote locked-button tips so they explain the unlock route instead of only
  saying the feature is unavailable.
- Added a one-time next-step message when alchemy unlocks construction.
- Rewrote the first gather message so it points back to building shipyard and
  training camp.
- Rewrote first shipyard reward messaging so the player knows to assign crew
  and food before sailing.
- Rewrote talent/intel locked tips to point back to the first expedition.

Validation:

- `luac -p bin/res/scripts/LuaClass/MainMenu.lua`
- `luac -p bin/res/scripts/LuaClass/DataManager.lua`
- `luac -p bin/res/scripts/LuaClass/Resource.lua`
- `luac -p bin/res/scripts/LuaClass/Expedition.lua`
- `luac -p bin/res/scripts/LuaClass/BaseView.lua`
- iOS simulator build:
  - `xcodebuild -project projects/ios_mac/NewPirate.xcodeproj -scheme 'NewPirate iOS' -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 12 Pro,OS=26.2' -derivedDataPath build/DerivedData/ios-sim USE_HEADERMAP=NO CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=NO build`
- iOS simulator launch:
  - installed and launched bundle `com.fancyGame.NewPirate`
- Launch screenshot:
  - `docs/product-iteration-launch-check.png`

Result:

- All five modified Lua files passed syntax checks.
- iOS simulator build succeeded.
- App launched into the current warehouse screen using the original UI art
  baseline.

Still required:

- Run a fresh-save iOS simulator session.
- Verify that the first-session message order is not too dense.
- Verify that locked-button toasts fit on the phone viewport.
- Verify that the player can reach first expedition without guessing.
- Tune building/resource pacing if first expedition takes too long.

## 2026-07-16: Product Baseline V2

Goal:

Reassess the product after reviewing the complete original planning, art, and
development archive under `/Users/lizi/Desktop/Pirate`, then establish one
authoritative baseline for future iteration.

Documentation changes:

- Added `docs/product-iteration-plan-v2.md` as the current Chinese product and
  development baseline.
- Repositioned the game from a management-first RPG to a story-driven dark
  fantasy pirate exploration RPG.
- Defined the four product pillars: cursed bottle and sixteen runes, fog-of-war
  sea exploration, ship-to-boarding combat, and crew/ship identity.
- Added a keep/rework/defer/archive matrix for legacy systems.
- Defined a 15-20 minute first-chapter vertical slice and a sixteen-week roadmap.
- Added product, art, engineering, data, QA, and decision acceptance criteria.
- Marked `docs/product-long-term-iteration-plan.md` as a historical document.
- Added the current documentation entry points to `README.md`.

Result:

Future product decisions should use `docs/product-iteration-plan-v2.md` as the
single current baseline. The next execution step is Phase 0: first-chapter flow,
map nodes, system isolation, minimal data definitions, and test-save setup.

## 2026-07-16: V2 Phase 0, Design And Engineering Baseline

Goal:

Create an isolated, testable V2 foundation before implementing the first-chapter
vertical slice.

Implemented:

- Added a central `V2Config` for product phase, feature gates, save namespace,
  QA profiles, and unavailable-feature messages.
- Isolated V2 role, map, mission, and first-plot state from legacy saves.
- Disabled legacy achievement, ranking, diamond store, charging, push gifts,
  seven-day rewards, eternal arena, rating/ads, and paid map unlock flows.
- Reframed the first-session system copy around the cursed bottle and damaged
  ship instead of a generic stranded-island management loop.
- Added the Chapter 1 flow, node map, system-isolation baseline, and validation
  report.
- Added 11 readable V2 source tables for the chapter, five resources, seven map
  nodes, four crew roles, two ship modules, events, enemies, rewards, and
  dialogue.
- Added automatic Lua, config, schema, foreign-key, scope, and runtime-gate
  validation.

Validation:

- `tools/v2/validate_phase0.sh` passed.
- 11 content tables and 46 rows passed validation.
- arm64 iOS simulator build, install, and launch passed on `NewPirate Fresh QA`.
- Fresh V2 save displayed the water-bottle opening sequence.
- iOS device compile-only build passed with code signing disabled.

Result:

Phase 0 acceptance gates passed. Phase 1 can implement the playable gray-box
Chapter 1 slice using the isolated V2 data and save baseline.

## 2026-07-16: V2 Phase 1, Playable Chapter 1 Graybox

Goal:

Turn the Phase 0 design contract into a complete, recoverable Chapter 1 flow
that starts from a fresh save and does not depend on legacy long-term systems.

Implemented:

- Added deterministic CSV-to-Lua runtime export with stale-output checks.
- Added a pure Lua Chapter 1 state machine covering opening, preparation,
  exploration, events, naval combat, boarding combat, rune clue, settlement,
  upgrade, completion, failure, retry, and port recovery.
- Added immediate scoped saving after every valid chapter action.
- Added isolated `player`, `qa_explore`, and `qa_combat` runtime entries.
- Added a full-screen graybox surface with a seven-node map, current objective,
  resources, route/module context, battle transfer feedback, and valid actions.
- Hid legacy economy/menu chrome and the legacy random-event overlay in V2.
- Moved the V2 opening into the chapter flow and isolated the legacy audio
  backend after diagnosing a CoreAudio deadlock on the iOS 26.2 simulator.

Validation:

- `tools/v2/validate_phase1.sh` passed.
- Safe and risky routes, both upgrades, ship-to-boarding transfer, defeat,
  retreat, retry, recovery, invalid actions, and save fallback passed.
- arm64 iOS simulator build, install, fresh entry, combat QA entry, and extended
  process stability passed.
- Validation screenshots are stored in `docs/v2/phase-1-opening.png` and
  `docs/v2/phase-1-combat.png`.

Result:

The Chapter 1 graybox is playable as a complete product loop. Phase 2 can now
deepen exploration and combat decisions without replacing the data, save, or
chapter-flow foundations.

## 2026-07-16: V2 Phase 2, Exploration And Combat Decisions

Goal:

Turn the complete graybox into an explainable decision prototype with meaningful
route, target, timing, skill, and recovery tradeoffs.

Implemented:

- Added source-driven route, balance, and battle-action tables.
- Added navigator intel that trades provisions for exact route risk and reward.
- Quantified reinforced-hull and heavy-gun module tradeoffs.
- Added deck targeting, gun suppression, retaliation reduction, and explicit
  boarding timing.
- Added one active skill for each Chapter 1 crew role.
- Preserved one clear ship-to-boarding transfer rule and surfaced its result.
- Added causal victory reports and explicit retry/port-recovery costs.
- Upgraded the V2 save schema to 2 with safe profile fallback.

Validation:

- `tools/v2/validate_phase2.sh` passed, including all Phase 0 and Phase 1 tests.
- 14 source/runtime tables and 72 records passed export and contract checks.
- Exploration intel, module capacity, naval targets, crew skills, transfer,
  battle reports, retreat, retry, and recovery costs passed pure Lua tests.
- arm64 simulator build, `qa_explore`/`qa_combat` runtime layouts, and device
  compile-only build passed.

Result:

Phase 2 acceptance gates passed. Phase 3 can focus on content, art, dialogue,
animation, and approved audio without changing the Chapter 1 decision model.

## 2026-07-16: V2 Phase 3, Content And Art Sample

Goal:

Turn the explainable Chapter 1 prototype into a representative product sample
with authored events, distinct hero compositions, character dialogue, enemy
presentation, animation, and stable audio cues.

Implemented:

- Expanded Chapter 1 to eight authored events and thirteen source-mapped
  choices, including route-specific events, black tide, and cursed compass.
- Added eighteen plot, voyage, naval, boarding, rune, and return-to-port lines.
- Added fourteen source-driven presentation mappings across harbor, map,
  combat, and rune hero groups using approved original project art.
- Added full-screen iOS launch metadata and isolated the legacy mission toast.
- Added distinct naval enemy, boarding deck/leader, rune reward, and lightweight
  key-animation presentation.
- Added six source-mapped audio cues for sailing, cannon, boarding, victory,
  curse, and sinking.
- Reproduced the legacy iOS audio termination and replaced V2 effect playback
  with an AVFoundation bridge exposed to Lua.
- Upgraded the V2 save schema to 3 and added isolated boarding, rune, and
  settlement QA profiles.

Validation:

- `tools/v2/validate_phase3.sh` passed, including all earlier phase suites.
- 16 source/runtime tables and 124 records passed export, reference, asset,
  event, dialogue, presentation, audio, and animation checks.
- Map, naval, boarding, and rune hero compositions passed full-screen simulator
  screenshot review on iOS 26.2.
- Native cannon-cue smoke test remained stable after the old backend's failure
  was reproduced.
- arm64 simulator and compile-only iOS device builds passed.

Result:

Phase 3 implementation and automated acceptance passed. Phase 4 owns real
device experience records, two external user-test rounds, issue triage,
performance/save/resource audits, and the final Go/No-Go decision.
