# Voluntary alchemy purchase, 2026-10-10

## Bounded behavior change

The existing gold `+` dialog now includes a stable long-press-alchemy entry. No
additional port-navigation tile is added. Its original exchanges remain **30
diamonds / 5000 gold** and **500 diamonds / 120000 gold**, with their purchase
callbacks unchanged. Ordinary alchemy no longer automatically opens the old
40-diamond gold promotion or 398-diamond long-press offer.

All old alchemy counter rules remain: missing click/show counts default to 1;
100-click thresholds while show count is below 4, then 300; at each threshold,
click count resets to 0, show count increments, then click count increments to 1.
The ten-click tutorial, coin/achievement increments, owned counter behavior,
existing entitlement and 0.3-second interaction cadence are unchanged.

## Entry and confirmation

- Before basic alchemy guide `s001`: entry explains the ten-click prerequisite;
  it cannot open a purchase confirmation or debit diamonds.
- Unowned after the guide: entry states **398 diamonds** and opens an explicit
  Cancel/Confirm dialog. Opening is free. Insufficient balance/save errors leave
  the dialog open for an explicit retry; they do not launch payment or recharge.
- Owned: entry states unlocked and gives a usage hint, with no purchase path.
- Cancel, X, scene cleanup and successful completion invalidate old callbacks.
- Success closes the offer, then independently protects currency/entitlement
  observers, talent checks and the existing current-page rebuild dispatcher.
  Presentation errors cannot roll back durable ownership or retry the charge.

`Dispatch:backToLastView` rebuilds the selected page; it is not browser/history
back. Home, repository, construction and gathering destinations are covered,
along with absent main-menu state and injected observer/navigation failures.

## Persistence contract

`UserData:commitAlchemyUnlock` is a narrow transaction. It accepts no arbitrary
price/field set. It checks the saved, exact `s001` token independently of the UI,
rejects malformed entitlement states, and requires a finite nonnegative safe
integer diamond balance. Already owned, insufficient or invalid data do not save.

The transaction copies private encoded `realDatas`, changing only diamond
balance and ownership. It validates exact 398 subtraction and round-trips those
two fields through the production JSON encoder to reject large-number rounding.
It passes the complete existing-format candidate to the existing
`SaveDataManager:saveDataAtomic` and publishes memory only on explicit success.
False/nil/throw/serialization failure leaves both fields unchanged. It does not
use separately saving `addDiamond`/`setRoleData` calls. No migration, compensation,
new save field, native purchase SDK call or general shop refactor is introduced.

The two existing gold-exchange callbacks still have their pre-existing sequential
save behavior; this patch changes atomicity only for the 398 entitlement.

## Geometry

Actual source assets: dialog 572×437; gold rows 530×108; original gold purchase
buttons 116×69. Within the unchanged panel:

- explanation center: panel-center y +114;
- gold row centers: +35 and −94.6;
- new 530×44 entry center: −180;
- second-row/entry gap: 9.4; entry/panel-bottom gap: 16.5.

A content wrapper fits the complete panel/controls within the viewport with
12-unit horizontal margins at 480/540 widths. The full-screen modal shade and
input listener remain unscaled. Confirmation prose uses a bounded 476×156 box
and 28-point type instead of the old unbounded 36-point label. Geometry checks
cover 480, 540 and 640 widths; these are not pixel/typography GUI acceptance.

## Verification

New command (runner intentionally unchanged):

```sh
build/linux/tests/lua-ui-tests tools/tests/voluntary_alchemy_regression.lua
```

The new test runs actual UserData proxies/encoding, production JSON4Lua,
SaveDataManager, GuideController, AlertView callbacks, DataManager and Dispatch.
Only Record disk I/O and Cocos rendering are mocked. It covers legacy plain-save
migration, unknown/nested-field retention, nil ownership, exact guide matching,
397/398 balances, malformed/unsafe balances, failed serialization and atomic
saves, retry, repeated cold reads, canceled/stale callbacks, duplicate opening,
owned reopening, tenth-click eligibility, current-page rebuilding and observer
failures containing `%`. It checks real asset dimensions and three entry states.

The existing item-icon test now checks the unchanged voluntary gold callbacks
and unchanged 100/300 counter rollover without automatic dialogs. Relevant
onboarding, alchemy-feedback, management, local-production, Home and dialog
regressions also pass. The full existing `run-adventure-ui-tests.sh` suite passed
with the new test run separately. Native GUI acceptance and native filesystem-failure
acceptance remain separate; this worker did not launch GUI or touch player saves.

## Native GUI correction: confirmation controls

Native GUI found that `AlertView:usePaperBody()` appends an opaque paper sheet
above its pre-existing, same-z confirmation/cancel menus. The initial logical
fixture checked presence and geometry but missed this sibling paint order.
The correction applies only to the new 398 offer: its native `cc.Menu` children
and X receive z=2; panel paint and paper retain their original order at z=0.
No global AlertView behavior or transaction logic changes.

The regression now orders the real AlertView sibling tree by z and insertion
order, requiring panel paint < paper < Cancel/Confirm/X at 480/540/640. Running
that test against the pre-fix DataManager source fails with “取 消 must paint
above opaque paper”; current source passes. Native GUI must still re-accept the
corrected visual controls before any actual fixture purchase.
