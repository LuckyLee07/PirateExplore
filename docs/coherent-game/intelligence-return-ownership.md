# Intelligence and old-save return shortage ownership

## Confirmed scope

This changes only three additional live coherent purchase-prompt routes:

- The old-save Explore paid-return fallback, after the free return has been used
  and the bag has no return scroll. The shipped chapter-2 return scroll is 1303,
  linked to shop item 12 at 15 diamonds.
- Original RandomEventView diamond learning through RandomEventLayer and
  DataManager:checkTallentPass. Shipped talent 2002 has resumeType 2 and costs
  3 diamonds on this route.
- Original RandomEventView waiting-mission quick completion through
  Mission:completedMissionByCosted. The fixture uses shipped mission 1 at
  50 diamonds.

Both the coherent Talent and Achievement intelligence buttons still open the
same original RandomEventView. New-schema return continues to exit through its
existing atomic AdventureProgress quote path, before the old-save fallback.
No mission reward debit or downstream successful talent-unlock debit is changed.
FightMode's legacy-only debit is unchanged. This is explicit known-caller
coverage, not a claim that every future purchase caller is automatically owned.

## Reproduction and implementation

Before changing these routes, native callbacks at zero balance opened an actual
scene-owned WarmDialog and PushGiftView. After removing the caller or replacing
its target, each retained gift's enabled Buy reached the supported-platform spy.
A retained push/pop scene already rejected buying through the gift's own service
flag, but the obsolete gift remained visible and in the modal stack.

The three callers now pass the optional presentation context already supported
by DataManager:addDiamond. DataManager:checkTallentPass and
Mission:completedMissionByCosted only forward that optional argument. There is
no global owner and no transaction logic in the ownership helper.

Explore captures its map index, rejects an obsolete confirmation synchronously,
and retires the context at the actual map-rebind boundary, including same-map
reload. Native owner exit/cleanup also retires it.

RandomEventView owns the presentation independently of its recycled table cells.
The context captures the view generation and the exact event or waiting-mission
identity. Close, view reinitialization, removal, expired/deleted targets, and
scene suspension invalidate it. A harmless list refresh after failed mission
completion deliberately keeps the same failed offer usable; the original
unconditional list reload is preserved. Retained source rows additionally check
their binding identity, view generation, scene, and current target/state, so
recycled controls cannot recreate an offer or charge a changed target.

The original no-owner API defaults and WARM=false paths remain unchanged. Prices,
resource grants, mission completion, talent learning, save schema, and the
original old-save returnToBase body are conserved. The shared native lifecycle
repair from ba8f58b and its test follow-up 5842954 are prerequisites: presentation
is disabled immediately and scene sibling removal is deferred past native
lifecycle traversal. This patch does not change that shared repair.

## Verification

Evidence is under
`/workspace/shared/pirate-audit/intelligence-return-ownership/`.
All fixtures use in-memory data, shipped CSVs, production Cocos components,
actual return/mission/talent source callbacks, and a supported-platform purchase
spy. No player profile, GUI, real billing, network service, or publication is used.

The native matrix covers all three routes at zero balance, one below the real
price, the exact price, and one above it. It exercises prompt-open and gift-open
removal, close, actual rebind, generation mismatch, replacement and push/pop in
both scene sibling orders. It retains and activates obsolete controls, checks
stopped Buy delays, checks actual native child vectors, and protects a separate
unrelated modal. It verifies cancel, refreshed same-target offers, model changes,
explicit live Buy with the shipped product, original successful mission/talent
callbacks, old-save return navigation, and no implicit schema conversion.

No-owner affordability/completion and WARM=false shortage/exact-price cases are
also covered. A separately labelled synthetic type-1 talent covers the optional
context on the non-random general-learning affordability branch; it is not
presented as a shipped live route.

Four-file byte conservation restores only the literal reviewed presentation
changes and checks the original SHA-256 values. Eight mutations must fail those
checks. The pre-existing chest whole-file checksum is unchanged; its allowlist
adds only the exact optional talent signature and the two exact owner-forwarding
calls, preserving its original economic counterfactual. Seven additional native
counterfactuals remove each ownership opt-in, alter each real debit, or disable
source-row validation; each must fail a specific behavioral assertion.

The aggregate runs the new native test, dedicated running-scene runner,
conservation checks, native counterfactuals, and the existing coherent, warm,
legacy opt-out and new-schema atomic return regressions.

## Separate visual finding

The unchanged original RandomEventView still uses the old dark table body.
Native 480×800 captures using the real Linux heading-font route show its fixed
size panel exceeding the viewport, clipping the title/close edge. Files:
`intelligence-talent-480x800.png` and `intelligence-mission-480x800.png`.
This ownership change makes no art or layout edits. These isolated component
captures are not natural desktop whole-game visual acceptance.
