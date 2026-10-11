# Warm return result (S08)

`WarmReturnResult` presents a receipt after the existing successful
`Explore:returnToBase` transaction and Home transition. It does not save, grant,
claim, retry return, change inventory, or adjust payment/reward rules.

The hook captures a detached pre-return snapshot only when an actual adventure
voyage is active. After the original `AdventureProgress.returnVoyage` succeeds,
it reads the committed state and computes the real net currency, material and
returned-crew changes. Matching `WarmMemories.get(dm).lastResult` identifies an
actually earned memorial and durable voyage record. The amounts include the
original first-return subsidy and any actual return payment. The material list
is explicitly titled “仓库物资净变化” (net warehouse material changes), with the
explanation “含带回物资（包括原有补给）、补助及返航消耗”. Thus returned food is not
presented as newly earned loot, and subsidy materials or consumed return items
are not misrepresented as pure sea cargo.

An already-active pre-feature voyage can show its real just-committed receipt,
but it never generates a historical log or memorial. Its sheet explicitly says
the old voyage was not backfilled. Legacy saves without an adventure ledger,
failed returns, failed saves, warm opt-out and reentrant callbacks do not show a
new result. No receipt is auto-restored at cold startup; durable history remains
available through the normal collection/log page.

The sheet is owned directly by the new warm Home, rather than by the outgoing
Explore or its old scene. It has bounded native text pagination, a read-only
Close action, and a collection route only when a memorial was actually earned.
Close, duplicate clicks, stale pagination callbacks and owner teardown cannot
claim or save anything. A presented transient receipt cannot reopen itself.

## Checks

```
build/linux/tests/lua-ui-tests tools/tests/warm_return_result_regression.lua
LD_LIBRARY_PATH=/path/to/runtime/usr/lib/x86_64-linux-gnu \
  /path/to/tutorial-log-native tools/tests/warm_return_result_native.lua
```

The regression uses actual encrypted UserData, AdventureProgress, and extracted
production Explore/return-confirm callbacks. It verifies free, scroll and
diamond settlement, failed-save retry, reentry and honest old-active behavior.
The native test checks real Cocos labels and buttons at 480×800, 640×960,
640×1067 and 640×1136, long material pagination, stale callbacks, Close,
collection routing, owner cleanup and zero UI writes. These are isolated
component/transaction tests; the full-game journey remains a separate check.

The Warm test runner automatically discovers both new test files.
