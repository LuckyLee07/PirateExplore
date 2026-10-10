# Voluntary harbor gift entry

## Scope and evidence

The preserved natural replay had a 15-yuan gift cover Home after the first return. The next independent native continuation reproduced the same unsolicited offer on cold launch at 02:07:37 UTC, before any game input. This is not restricted to the first return: the former `MainMenuLayer:init` condition was saved map state present and not at sea.

This bounded patch adds `礼包（付费）` in the existing port menu's tenth, previously empty cell. It opens the same `PushGiftView` deliberately and retains that saved-map / harbor gate. No panel growth, red point, countdown, free reward, checkout action, offer price or purchased entitlement is added. The original transient golden boat remains, using the same guarded opener. Only the MainMenu automatic return/cold-start opening is removed; defeat and explicitly requested insufficient-diamond flows remain unchanged.

Dialog ownership prevents repeated stale callbacks from stacking offers. A native cleanup observer clears ownership on dismissal or scene destruction without querying a destroyed Cocos wrapper. Closing the port overlay precedes opening the gift. Locked states explain that the offer can be viewed after sailing and returning.

## Tests

The extended `home_master_regression.lua` failed first on the missing stable entry. It now exercises the actual production port and opener callbacks for pre-voyage, sea and returned-harbor states, clear paid labeling, original dialog opening, repeated stale taps, close/reopen and no navigation. It retains all existing navigation/guide/lifecycle checks. A source contract confirms initialization no longer directly creates the gift.

`LUA_BIN=build/linux/tests/lua-ui-tests ./tools/tests/run-adventure-ui-tests.sh` exited 0 after this patch. This includes the existing production `PushGiftView` unsupported-platform purchase guard and dialogue lifecycle suite. Mock geometry and callbacks are not native visual acceptance. Native 480/540 port layout, voluntary open/close/reopen, quiet cold start/return and unavailable-payment handling are pending independent acceptance. No real payment is performed.

## Read-only economy and interruption audit

The shipped encrypted CSV was decoded with the existing Record/LZSS regression decoder; the following are source-model facts, not measured playtimes or new unlock guarantees.

- First cargo recipe 1148: 5 wood + 5 cloth, capacity 30. Cloth is 2 gold each. After furnace yield 2, buying all five cloth costs five successful alchemy clicks from zero; the natural continuation started with 2 gold and needed four. That independent run paid 10 gold, then consumed 5 cloth and 5 wood to reach capacity 30.
- Next cargo recipe 1149: 20 wood + 30 leather, capacity 40. Leather costs 3 gold. If wood is already available, all leather costs 90 gold, or 45 successful clicks at yield 2. Including all wood costs 110 gold, or 55 clicks. Availability still depends on original unlock state.
- Next furnace recipe 1177: 15 steel, yield 3. Steel's price is 15 gold. Buying all steel costs 225 gold, or 113 successful clicks at yield 2 from zero; marginal +1 gold/click recoups 225 gold over 225 subsequent clicks. This is substantially different from the first 15-gold furnace and should not be automatically recommended as another equally cheap goal. Found steel or production changes the tradeoff.
- Ship factory is another branch: 100 gold + 180 stone + 160 wood, with a 6-gold processing-workshop prerequisite. Training camp costs 30 gold. These are possible original choices, not new objectives selected by this patch.
- `AlchemyButtonDidClick` retains automatic 5,000-gold offers at the first two 100-click thresholds, then the 398-diamond long-press offer at the next 100-click threshold (roughly the 300th successful click overall); subsequent long-press prompts recur every 300. Exact stored-counter starting state can affect boundary numbering. Existing owners retain their flag and 0.3-second input cadence.
- There is no permanent voluntary 398-diamond long-press entry in the reviewed source. This patch therefore does not remove its prompt, grant the entitlement, or change counters.
- The automatic 5,000-gold offer costs 40 diamonds (`DataManager.lua`, alchemy callback), while the existing voluntary `showBuyGoldBox` offers 5,000 for 30 diamonds. This discrepancy is recorded for a later deliberate decision; both prices remain unchanged here.
- After furnace and capacity goals complete, `HarborGoals.list` intentionally returns no further beginner choices. Native continuation found the five-cloth requirement understandable but had to discover the market source unaided. A concise source hint is a candidate for later analysis, not included in the gift patch.
