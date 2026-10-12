# Event-child shutdown lifetime repair

## Failure and scope

The reviewed black-market route opened the original EventDetailsLayer with an
empty/sold-out stock list. Native window-close then returned 139. The same
original main/Update/bootstrap and original market primary reproduced the fault
on surfaceless EGL when the C++ loop called Director::end/mainLoop, rather than
terminating the test with `_exit(0)`.

EventLayer's cleanup callback erased its scene-owned child while Node::cleanup
was traversing the scene's child vector. The guard tested child:isRunning(),
but onExit had already cleared that flag. Removing the sibling invalidated the
native traversal. The captured stack ends at CCNode.cpp:687 and
Director::purgeDirector at CCDirector.cpp:785.

Only Lua presentation lifetime changes:

- EventLayer invalidates its exact owned child on owner/child exit or cleanup,
  removes its shield, stops its timer, retires its owned prompts, and defers the
  child erasure to a safe running tick. Whole-scene teardown destroys it normally.
  Ordinary explicit dismissal is still immediate. No leave/settlement callback
  is invoked by lifecycle retirement.
- EventBaseView's retained Close callback uses a closure-local cleanup flag, so
  it cannot call native methods after the original userdata is destroyed.
- WarmDialog's retirement uses a closure-local one-shot flag. A surviving owner
  observer after push/pop cannot schedule work on an already-destroyed dialog.
  Existing deferred sibling retirement is preserved.

No prices, stock, grant quantities, market refresh policy, transaction functions,
entry route, original leave callback or engine code changed. There is no global
modal clear and no real payment or service call in the tests.

## Regression command

With the existing corrected Linux Makefiles build and runtime dependencies:

    PIRATE_BUILD_DIR=/path/to/build/linux PIRATE_RUNTIME=/path/to/runtime \
      python3 tools/tests/coherent_event_child_shutdown_regression.py

The test does not open the GUI or a player profile. It checks 28 combinations of
owner/child removal, cleanup-free detach, replacement, cleanup and repeated
push/pop, with empty and stocked markets and both sibling orders. Retained stale
Close, Buy and confirmation controls cannot mutate currency, stock, cargo or
leave callbacks. Unrelated nodes/dialogs survive local child/owner retirement.
An original 12-coin transaction still grants exactly five of item 1005.

C++ then runs real Director purge with an unretained child and unrelated
siblings, checking exactly one exit and cleanup for every witness. Counting
cleanup is essential: allocator/layout differences can mask a use-after-free as
an apparent successful exit with a duplicate/skipped cleanup.

Four isolated rollback cases must fail: original exited-child guard, missing
child-detach observer, stale dialog observer and destroyed Close callback. The
runner rejects logged Lua/native errors even if exit status is zero. Existing
pause shutdown counterfactuals continue to exercise unsafe sibling erasure.

Full original-app offscreen evidence records two pristine crashes and clean
same-executable candidate purges. Native purge tests do not replace final
physical desktop-X acceptance on the frozen integrated candidate.

## Adjacent world-selector successor

The same exited-child guard remained in EventLayer's worldMapLayer cleanup.
An unretained real WorldMapLayer reached through EventLayer reproduced duplicate
native cleanup in both sibling orders. Its cleanup now hides/invalidates only
that selector and defers scene-sibling erasure. A separate direct-destroy probe
also reproduced the owner's stale selector userdata; WorldChartSelector cleanup
now clears owner.worldMapLayer only if it still points to that exact selector.

The successor adds 12 native selector cases: terminal purge, owner removal,
direct child destruction, cleanup-free detach/reentry, replacement, and repeated
push/pop, each in both sibling orders. Detach/reentry preserves ownership and
resumability but invalidates the old confirmation. Role/currency/write state
remains exact. Three targeted rollback negatives cover unsafe owner-first
cleanup and missing exact-pointer cleanup in either sibling order. The existing
16-chapter identities and transaction/route conservation audit still passes.

The C++ harness also rejects any captured Lua error occurring during terminal
purge, after the Lua test body has returned. Each runner invocation uses a unique
native build directory to permit independent reviewers to run concurrently.
