# NewPirate Long-Term Product Iteration Plan

> **Historical document / 历史版本**
>
> This plan was written before the original design and art archive under
> `/Users/lizi/Desktop/Pirate` was fully reviewed. Its management-first product
> positioning has been superseded by the Chinese V2 baseline:
> [`product-iteration-plan-v2.md`](product-iteration-plan-v2.md). Keep this file
> only for historical context; new product and development decisions should use
> V2.

Date: 2026-06-18

This document analyzes the current project from a senior product manager
perspective and defines a long-term iteration plan. The goal is to turn the
current playable Cocos2d-x Lua project into a game that players can understand,
return to, recommend, and eventually support commercially.

The current project should be treated as a working prototype with many usable
systems already present, not as a finished product. The right path is not to
replace everything at once. The right path is to find the core fun, make the
first session understandable, then strengthen progression, battle, exploration,
presentation, and live-operation depth in that order.

## Product Positioning

### Current Best Fit

NewPirate is closest to a light pirate survival-management RPG:

- idle/manual resource loop
- base building and functional unlocks
- crafting and recruiting
- expedition preparation
- map exploration
- ship/crew combat
- random events, achievements, store, talents, and rewards

The strongest product fantasy is:

> Rebuild a broken pirate crew, prepare supplies, sail into dangerous seas,
> survive encounters, return with loot, and upgrade the ship and crew.

### Near-Term Target

The near-term product should become:

> A readable mobile pirate management RPG where the player always knows the next
> useful action and reaches the first expedition quickly.

### Long-Term Target

The long-term product should become:

> A polished pirate adventure RPG with satisfying preparation, risky voyages,
> readable ship battles, memorable crew/monster personality, and repeatable
> progression loops.

## Current Product Diagnosis

### Strengths

- The project already has a broad feature skeleton: buildings, resources,
  crafting, recruiting, warehouse, expedition, map, combat, random events,
  achievements, store, talents, login rewards, and monetization hooks.
- The game has a strong theme. Pirate survival, ship preparation, sea monsters,
  and loot runs are naturally understandable.
- The code already separates major gameplay screens in Lua, which makes
  iterative product changes possible without rewriting the engine.
- There is already a system info feed, guide-step state, locked buttons, red
  points, and first-time rewards. These are useful hooks for onboarding.

### Core Problems

1. The first-session objective is weak.
   The player sees systems and buttons, but the game does not consistently tell
   them why the next action matters.

2. The core loop is buried.
   The actual loop is gather/build/prepare/sail/fight/return/upgrade, but early
   screens present it as separate utility modules.

3. The game asks for repeated tapping before emotional payoff.
   Alchemy and resource collection are functional, but they do not immediately
   sell the pirate fantasy.

4. Progression is system-heavy and fantasy-light.
   Buildings, materials, troops, food, talents, and store entries exist, but
   their relationship to the player's pirate journey needs stronger framing.

5. Battle is likely the highest selling moment, but it is not the first polished
   slice yet.
   A pirate game must make sailing and ship conflict feel like the reason to
   play, not merely a reward calculation screen.

6. Monetization appears too early in the visual hierarchy.
   The top diamond store, charging flow, and gift push hooks are present before
   the product has clearly earned player trust.

7. Art replacement cannot be solved by bulk skinning.
   The failed Batch 1 UI experiment showed that replacing many assets with
   procedural placeholders lowers perceived quality. Future art work must start
   from high-value screen compositions and only then move into production assets.

## Product Principles

These principles should govern all future work:

1. Gameplay clarity before visual ambition.
   Players should always know what to do next and why it helps.

2. First expedition as the first real promise.
   The first session should drive toward "prepare and sail" quickly.

3. One loop polished before many loops expanded.
   Do not add more features until gather/build/prepare/sail/return feels good.

4. Keep old assets until a better screen-level solution exists.
   Do not batch replace UI assets unless a target screen has already proven the
   new direction.

5. Reward should explain progress.
   Loot should point back to a useful upgrade or next voyage.

6. Monetization must be trust-based.
   Purchase prompts should appear after players understand value and should not
   interrupt the first useful loop.

7. Every iteration needs a testable acceptance gate.
   A change is not complete until it can be checked in-game.

## North Star

Primary north-star behavior:

> A new player reaches the first successful expedition, understands what they
> gained, and wants to upgrade before sailing again.

Supporting metrics:

- first-session time to first meaningful choice
- time to first expedition
- first expedition start rate
- first expedition success/failure comprehension
- D1 return rate
- session count before uninstall
- number of useful upgrades completed before first session end
- battle completion rate
- store prompt dismiss rate

For local development before analytics are added, use proxy checks:

- can a tester explain the next goal after 60 seconds?
- can a tester reach the first expedition without developer help?
- does a tester understand why they lost or won after the first voyage?
- does a tester know what to upgrade next after returning?

## Long-Term Roadmap

### Phase 0: Current-State Stabilization

Purpose:

Make the existing project reliable and understandable enough for iteration.

Work:

- keep iOS simulator and device builds working
- keep resource layout stable
- remove or ignore failed generated UI experiments from production scope
- document current product loop and screen ownership
- define first-session acceptance criteria
- add simple internal QA checklist

Acceptance:

- iOS simulator builds and launches
- no missing-resource logs in the first loop
- team can name the intended first-session path
- product roadmap and current loop documentation exist

### Phase 1: First-Session Clarity

Purpose:

Make the player understand the first goal and reach the first expedition.

Work:

- rewrite first onboarding messages around a pirate survival objective
- make locked buttons explain the exact unlock route
- show next-step text after major unlocks
- reduce early monetization interruptions
- make first shipyard reward and first sail instruction explicit
- verify the player can reach first expedition without guessing

Acceptance:

- first-time player understands: gather resources, build key buildings, prepare
  crew and food, sail
- first expedition can be reached in a short test session
- locked features tell the player what to build first
- no early screen feels like a dead end

### Phase 2: Core Loop Compression

Purpose:

Reduce friction between resource production, building, and sailing.

Work:

- surface "needed for next goal" materials in resource/build screens
- simplify the first few building requirements if they delay sailing too much
- ensure warehouse items point to their practical use
- make expedition preparation auto-suggest food and first crew when possible
- create a clearer return path after exploration or failure

Acceptance:

- player can complete gather/build/prepare/sail without visiting irrelevant
  screens
- every material in the first loop has an obvious use
- expedition preparation communicates cargo and crew capacity clearly

### Phase 3: First Voyage And Battle Slice

Purpose:

Make sailing and battle the first memorable moment.

Work:

- tune first voyage to guarantee a clear event, reward, or battle
- make first combat readable: player ship, enemy, crew, health, skills
- add or improve battle result messaging
- show why food, crew, and ship upgrades matter
- make loss recoverable and educational

Acceptance:

- tester can describe what happened during the first voyage
- combat outcome is understandable
- player knows one concrete upgrade after battle
- no UI element blocks battle comprehension

### Phase 4: Progression Identity

Purpose:

Turn systems into a pirate crew fantasy.

Work:

- define crew roles and upgrade identities
- make buildings feel like rebuilding a pirate base or shipyard
- connect talents to captain identity
- make resources feel like voyage supplies rather than arbitrary materials
- add milestone names for first several progression beats

Acceptance:

- upgrades have fantasy meaning, not only numeric meaning
- player understands why recruiting, crafting, and building are different
- first 30 minutes have named milestones

### Phase 5: Art Direction Rebuild

Purpose:

Improve presentation only after the screen-level product loop is known.

Work:

- create one high-quality target screen for warehouse or expedition
- create one high-quality target battle screen
- replace assets screen by screen, not globally
- keep original UI unless a new screen clearly beats it
- focus first on readable ships, crew portraits, monster silhouettes, and reward
  icons

Acceptance:

- A/B screenshots show the new screen is clearly better than the old one
- no procedural placeholder assets are shipped as production art
- the first visual slice supports the product fantasy

### Phase 6: Retention And Content Depth

Purpose:

Give players reasons to return.

Work:

- daily/weekly voyage goals
- named sea zones
- event chains
- boss milestones
- equipment and crew upgrade arcs
- achievement cleanup
- long-term resource sinks

Acceptance:

- player has a reason to return tomorrow
- content pacing does not collapse after first voyage
- upgrades create new choices, not only bigger numbers

### Phase 7: Monetization And Store Readiness

Purpose:

Prepare for App Store or Steam only after the game earns player trust.

Work:

- audit all purchase prompts
- remove or delay aggressive early purchase prompts
- define fair convenience purchases
- prepare App Store screenshots from real gameplay
- prepare Steam trailer with direct gameplay footage if Steam remains a target
- add privacy, review, and platform compliance checklist

Acceptance:

- purchase prompts are clear and optional
- early game is fun without spending
- store assets truthfully represent actual gameplay
- platform metadata is accurate

## First Milestone: Playable Product Slice

The first serious milestone should be:

> A player starts from a fresh save, gathers/builds/prepares, launches the first
> expedition, sees an understandable outcome, and knows the next upgrade.

Recommended scope:

- current UI and art mostly unchanged
- no new monetization features
- onboarding text pass
- locked-feature clarity
- first expedition instruction
- battle/return messaging pass
- one screenshot-based review

## Work Batches

### Batch A: Product Documentation And First-Session Text

- document current loop
- document product roadmap
- improve first-session system messages
- improve locked-feature toasts
- add clear first-expedition instruction

### Batch B: Fresh-Save First Session Test

- run on iOS simulator
- reset local save if needed
- record first-session path
- note confusion points
- tune messages and unlock pacing

### Batch C: First Expedition UX

- make expedition preparation easier to understand
- clarify food and crew requirements
- add return/failure explanation
- verify first voyage can be completed

### Batch D: Battle Readability

- inspect battle scene
- improve first battle messaging and results
- adjust UI if text or touch targets are unclear

### Batch E: One Screen Art Target

- create a target screen mockup only after Batch A-D validate the loop
- do not batch replace assets
- compare old and new screenshots before committing art replacement

## Platform Notes

Official references used for planning:

- Steam store page documentation:
  `https://partner.steamgames.com/doc/store/page`
- Steam trailer guidance:
  `https://partner.steamgames.com/doc/store/trailer`
- Apple App Review Guidelines:
  `https://developer.apple.com/app-store/review/guidelines/`
- Apple Human Interface Guidelines for games:
  `https://developer.apple.com/design/human-interface-guidelines/games`

Implications:

- For Steam, the product must show actual gameplay clearly. The current game
  should not aim at Steam until the first playable slice and battle presentation
  are materially stronger.
- For App Store, the safer near-term path is a polished mobile game with clear
  onboarding, fair monetization, accurate screenshots, and stable iOS builds.

## Immediate Next Step

Start with Batch A. Improve first-session clarity with copy and light logic
changes. This has the best effort-to-impact ratio and avoids repeating the
failed global UI-skin replacement approach.
