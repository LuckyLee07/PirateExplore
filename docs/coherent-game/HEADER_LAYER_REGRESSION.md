# Consecutive-frame page header regression

## Observed failure and bounded repair

Actual-window review reproduced permanent title/subtitle disappearance on both
Talent and Achievement after their first manual alchemy receipt. The grant and
navy header remained. Checking `isVisible()`, geometry, or only an initial
screenshot did not detect the fault.

The shared `BaseView:applyCoherentPageShell` added its opaque `DrawNode` header
and both labels as z=0 siblings. This engine's `CCNode::visit` resets the
arrival-order field after rendering; a later child insertion invokes an
unstable `std::sort`. Inserting the z=99 receipt could therefore reorder the
old z=0 siblings and place the header over the labels.

The repair sets only the shared header background's local z to -1. All labels,
page geometry, receipt z=99, original buttons/controllers, subscriptions,
transactions, saves, art and engine source are unchanged. It protects every
page that uses the shared shell, including future dynamic-child additions.

## Native pixel regression

`coherent_progress_support_render.py` reuses the existing surfaceless Cocos/EGL
capture harness and additionally runs `coherent_header_layers_native.lua`.
The latter reuses the production-backed transaction fixture and its real
`AlchemyButtonDidClick`, `addCoin`, achievement counter, SDButton callback and
native action manager against in-memory role data. No player profile or GUI
is opened.

The pixel matrix contains 225 full-size captures of the same live page across
successive actual `CCNode::visit`/renderer passes:

- Talent, Achievement and the shared BaseView shell
- 480×800, 540×900, 640×960, 640×1067 and 720×1280
- Initial and second frame; first real +3 grant/receipt and the next frame
- Receipt accumulation, timed expiry, removal and recreation
- 28 dynamic same-z children added in bursts of 1/4/16/7 and removed in reverse,
  rendering after every burst and once more after settling

The fixed run requires both title/subtitle lines to have visible initial ink
and then requires their cropped RGB pixels to remain exactly identical in
every later frame. Thirty receipt crops separately require a dark backdrop
and light glyph pixels, using an inset region that excludes background edges.
This confirms receipt visibility on both pages at first creation, accumulation
and recreation, rather than inferring it from node visibility.

A second process restores only the old equal-z header statement in memory,
without editing production files. The same pixel checks must reject its first
Talent receipt, first Achievement receipt and generic-shell child mutations.
At 480×800, the old first receipts reduce light header pixels from 2,007 to zero
on Talent and 2,071 to zero on Achievement. The old shared-shell mutation
reduces 1,842 light header pixels to zero. The receipts themselves render in
these old frames, so a missed actual-window Achievement receipt alone does not
establish an additional receipt defect; its 1.6-second lifetime matters.

## Reproduction and verification

From the repository root, with the existing Linux SDK environment loaded:

```sh
PIRATE_BUILD_DIR=/path/to/existing/build/linux \
COHERENT_SUPPORT_CAPTURE_DIR=/tmp/coherent-header-check \
python3 tools/tests/coherent_progress_support_render.py
```

The runner is already part of `run-coherent-game-tests.sh`. Its capture
directory contains initial support-page images plus `header-layers/*.png`,
`frames.tsv` and `receipts.tsv`. Temporary compiler outputs and counterfactual
captures are private to that invocation. Python Pillow is required for the
pixel checks. Running the Lua fixture alone in the geometry-only harness
explicitly skips pixels; that does not replace this render command.

Verified on 2026-10-11: all 225 fixed frames, all 30 receipt crops, and the
required old-code counterfactual failures; the existing support render and
actual dispatched Achievement scroll also pass. Additional native checks cover
support, receipts, transactions, shared shell, supply, recipes, crew, market,
forge, preparation/return, events, growth, loot and chrome. Existing alchemy,
voluntary-alchemy, theme, chrome, loot and recipe logic regressions pass.

These are production-backed native offscreen component/pixel regressions.
Independent actual-window replay against the final integrated commit remains
the reviewer's acceptance gate; this change does not claim full-game, mobile,
service, payment or publication acceptance.
