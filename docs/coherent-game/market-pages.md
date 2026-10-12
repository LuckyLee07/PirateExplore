# Market and shared management shell, tranche 2

Status: implemented locally, native callback/layout coverage passed; independent actual-window visual QA pending. Not part of frozen checkpoint 1.

- Explicit warm-only full-page shell shares preparation's navy task header and cream content, with scaled 480×800 layout. It hides inherited chrome only after opt-in; legacy pages are unaffected. Back is single-flight and invalidated on owner exit.
- Market shows a quiet product list with the real resource illustration, unit price and current ownership. Selection reveals description and total cost. One native SDButton performs the purchase; long press or the secondary quantity control opens the same 1/10/100/1000 quantity choices. Selection itself changes no economy state.
- StoreLayer remains transaction owner: cost check → existing resource debit/item grant → original store unlock/sort ID. Original focus and bottom-entry routes remain. One-unit limits suppress bulk selection.
- Insufficient funds presents the real shortage and an explicit secondary route to the original coin-purchase interface. Cancel does not launch a payment flow. No live payment was used.
- No save migration, catalog change, price change or new reward.

Native tests: coherent_page_shell_native.lua and coherent_market_native.lua, actual Cocos/EGL, at 480×800, 540×900, 640×1136 and 720×1280. Checks include logical geometry, product focus, quantity-sheet singleton, read-only cancellation, real 10-item transaction boundary, insufficient funds, original coin-offer callback, stale purchase and repeated Back. Full shipped catalog coverage: all 62 entries browse read-only, one-unit items suppress bulk, and sold-out repeated input cannot silently buy the next product. Actual GUI review and compact end-to-end market entry remain integration gates.
