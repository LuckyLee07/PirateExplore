# Workyard identity follow-up

Base: component checkpoint 169a4242. This separate visual pass responds to actual-window review of the resource page, which was functionally clear but too form-like.

- Adds a restrained illustrated harbor workyard beside the compact net-production ledger. It is decorative context, never a claim about constructed buildings or current worker counts. With more than two net production entries it disappears and the original full-width two-column ledger remains.
- Each of the 16 shipped worker roles shows its exact first output resource, using an explicit resource-ID mapping. Ore, ingots, coins, food and magical materials remain distinct. Unknown IDs have no fabricated substitute.
- Adds an explicit worker-list scroll cue only when there are more than two rows.
- Corrects Train's short-table positive offset, placing one sailor at the top instead of the bottom while preserving long-list scroll distance through refresh.

No worker allocations, rewards, timing, prices, saves, table contents or transaction callbacks change. The existing production SDButton/listeners and cooldown timer remain the same objects. Native supply/crew regressions and five-size offscreen captures cover geometry; actual desktop follow-up remains pending.

## Generated art provenance

Built-in image generation on 2026-10-11; no external artwork downloaded. Style reference: the existing approved `CleanVoyage/harbor-clean-ne.png`, used only for palette/material/camera matching. Original generated PNGs are preserved byte-exact in `Images/UI/CleanWorkyard/`; alpha is retained. No offline image recoloring, drawing or cropping is performed. The renderer selects atlas rectangles directly with `cc.Sprite:create(path, rect)`.

`workyard-v1.png` source: `exec-fb361ae9-fdaa-4abf-93fc-2b40da218912.png`. Prompt: production in-game compact horizontal dockside workyard, one continuous cream paved quay; blue-roof open shed, stacked timber and stone, wheat sack, cooking pot, two naturally scaled adult workers carrying timber and sorting stone. Match clean sunny faceted low-poly 2.5D harbor; lime palms, upper-left warm light, restrained detail, isometric camera. Entire vignette in frame with transparent margin, 2:1 composition. No ocean, detached platforms, floating objects, text, labels, cards, buttons or watermark.

`resources-v1.png` source: `exec-7d85f650-63c0-4c3a-b247-bc2e701de1da.png`. Prompt: transparent square 4×4 production inventory sprite atlas, isolated centered objects with margins, no grid/text/borders; same sunny faceted low-poly materials and consistent 3/4 angle, readable at 40px. Exact reading order: wheat sheaf, soup bowl, timber logs, quarried stone; iron ore, steel ingots, gold ore, gold coins; blue crystal, rune stone with abstract nonletter mark, cream/blue sacred book, charcoal steel ingots; purple powder jar, enchanted living log, silver ingots, warm gold ingot. Distinguish ore/forged bars/coins and ordinary/living wood. Native crop rectangles account for the actual generated spacing and do not change any source pixel.
