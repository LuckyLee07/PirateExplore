# Event-child list placement and exact feedback

Bounded presentation delta from `ea0d6923c48bf7fbbfa34b3da97ccf8a5fba209a`.
This is not whole-game or physical desktop acceptance.

## Changes

Only `EventDetailsLayer.lua` changes at runtime:

- Cemetery, tavern, black-market and cargo lists use their actual content height,
  capped at the existing long-list height. The first row is top-aligned; the
  detail body reclaims unused space. Empty stock hides the zero-height list.
- Long native lists retain scrolling and their distance from the top across
  record changes. Short lists cannot bounce into a blank gap. Selection and
  transaction-generation guards remain original.
- The child subtitle sits beneath Return at the 360-pixel width.
- Coherent tavern recruitment no longer adds generic "purchase succeeded"
  feedback above the original precise crew-quantity receipt. The exact original
  cost remains in the row, detail and confirmation. Legacy presentation retains
  its old generic notice.
- Successful coherent market purchases emit one receipt with the actual item,
  quantity and currency cost after the original grant/limit operations.
  Shortage notices and unrelated mission/reward feedback are untouched.

No DataManager, ExploreBagController, EventLayer, EventBaseView, WarmDialog,
ToastUtil, price/stock tables, engine, save model or arena callbacks changed.
Cemetery transaction methods are byte-identical to the base. No global feedback
filter, monkeypatch or suppression is added to production.

## Reproduction

Use the existing native Linux Makefiles build and its runtime dependencies:

    source /path/to/linux-runtime/env.sh
    PIRATE_BUILD_DIR=/path/to/build/linux \
      python3 tools/tests/coherent_event_list_feedback_regression.py

The runner compiles the existing surfaceless event/gesture harness into a
throwaway directory. The dedicated Lua file is named `_cases.lua` deliberately:
the generic coherent native-test loop does not supply this gesture harness.
The coherent aggregate explicitly invokes its Python runner.

The runner checks original transaction/debit/grant/stock-route source conservation
without forbidding unrelated lifecycle changes during integration, plus 313 actual native assertions at 360×640
and 480×800, retained/rebound/rapid/closed callbacks, and native list drags. It
executes unchanged original debit, crew grant and bag grant functions against
in-memory disposable state. The original tavern entry decodes the actual
Explorer 144/300-coin offer, debits 307→7, grants exactly one crew member, leaves
repeatable tavern stock unchanged and emits exactly one quantity receipt.
Existing-crew recruitment retains unrelated mission feedback. A limited market
row spends once, grants once and exhausts the original restriction; ordinary
market stock grants exactly five food for 12 coins.

All four list families cover one row, forty rows, last-row selection and empty
content. Cemetery fixture labels come from the shipped skill record, matching
its detail text; forty-row lists are explicitly synthetic stress fixtures.
Native PNGs show the actual Cocos nodes/fonts/assets, not HTML approximations.
They are isolated component evidence, not a natural-play screenshot claim.

Eight isolated counterfactuals must fail for their specific assertions: old list
height/placement, duplicate recruitment success, generic market success, changed
recruitment price/debit/quantity, changed market grant quantity, and removal of
the once-only market restriction.
The same runner passes the existing entry-rebind checks and 348 real-component
assertions for diamond shortage ownership, including remove, close, reload,
reselect and scene replacement. No service, real payment or GUI is used.

Additional checks:

- Existing event-page suite: 88,972 native assertions passed across its five sizes,
  full dispatched site set, original controller transitions and arena callbacks.
- Freshly compiled event-child shutdown suite: 230 lifecycle assertions and real
  Director purge passed; all four isolated unsafe-lifecycle rollbacks rejected.
- Legacy adventure suite passed end to end with `LUA_INIT='WARM_PIRATE_V1=false'`, as
  required by `run-coherent-game-tests.sh`. An earlier invocation without that
  setting was invalid and is not a baseline defect.
- `git diff --check` passed.

Persistent evidence for this run is under
`/workspace/shared/pirate-audit/event-list-feedback/frozen/`, with summary
`frozen-runner.log`, `existing-pages.log`, `shutdown-verified-runner.log`,
and `legacy-optout.log` in its parent directory. The earlier `shutdown.log` used
an already-replaced shared harness with a different exported test contract;
only `shutdown-verified-runner.log` is the matched-source lifecycle result.

Physical desktop-X acceptance remains with the root auditor. This delta does
not alter or claim acceptance of any other full-game page or platform.
