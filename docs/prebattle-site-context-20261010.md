# Accurate site context before battle

## Natural failure and source diagnosis

Independent natural continuation screenshot `58-natural-reef-description-mismatch.png` shows two contradictory current labels: a skeleton scene narrative above a deep-sea octopus description. This is not the system-history log. Screenshots 59/60 show the subsequent loss to the second-floor strongman and the first explanation of map-color rank only after defeat.

Decoded shipped `strongholdAttribute` row 3106 is the reef: its obsolete description names skeleton warriors, but its actual `enemys` is `10002;10098`, `layers=2`, `especial=2`. Shipped soldier 10002 is an octopus with 4 HP/1 attack; 10098 is a strongman with 6 HP/2 attack. The natural runtime log confirms coefficient 1 and those exact combat values at lines 1921 and 1962. The event description is copied to `midTip` by `refreshLayerByInfo`; preparing each enemy replaces the lower description and shows the retained upper site narrative. Combat is correct; the site narrative is not.

## Bounded correction

- Only unoccupied ID 3106 with that exact obsolete skeleton text displays: “礁石间潜伏着危险的敌人，挡住了前路。” Future revised CSV prose is not overridden. No encrypted resource is rewritten.
- The same truthful scene narrative remains above each original current-enemy description. Actual enemy identity, queue, HP, attack, drops, occupation and saved/logged history are unchanged.
- An unoccupied `changeToEnemyLayer` site with `especial` 1–5 displays its existing color name and rank under the title, e.g. “绿色 · 中级据点”. Labels are white/low, green/middle, blue/high, purple/elite, orange/boss and special. Exact source mapping is the original map halo in `Explore:showStrongholdTipAction` and original defeat legend in `FightScene:showFailInfoAndReturn`. `MapLayoutManagers` derives the halo from `especial`.
- This is advance information at the existing entry screen before committing to battle, and on prebattle floor screens. It is not a map-movement preview, enemy-strength prediction, or recommendation that a particular crew will win. No extra modal, resource, revived crew, combat change or exit-rule change is added.
- Unknown ranks, including 6, absent ranks, non-enemy event types, completed sites and occupied revisits do not receive a guessed label. Existing defeat teaching remains intact.

The rank text uses the existing shallow paper-white color, with a separate 10×10 px original-rank color marker and a 12 px gap. Marker and text are centered and fitted as one group; hidden states hide the complete group. This prevents low-contrast blue/purple text on dark sea and does not rely on color vision. The added line is 22 px at x=viewport/2, y=height−104; titles retain y=height−50. Labels and long single-line titles fit to viewport width minus 48. Native screenshot acceptance must verify actual Chinese fonts, colors, paper/ink contrast and title separation at 480×800 and 540×900; source geometry alone is insufficient.

## Regression and acceptance boundary

The real packaged-CSV regression failed first on the obsolete reef description. Extended production-callback tests verify the entry and both real enemy preparations, actual HP/attack/drop ranges, correct current descriptions, occupied and other-reef text, exact obsolete-text guard, original history identity, all five source-derived ranks, long titles at both viewports, and completion/unknown/noncombat hiding. Both encrypted CSV files remain byte-identical. The standalone regression passes. Full aggregate and independent native acceptance are recorded by the final checkpoint; no new natural first-floor replay or paid revival is claimed by these controlled tests.
