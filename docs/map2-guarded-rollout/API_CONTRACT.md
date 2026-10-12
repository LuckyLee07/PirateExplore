# Bounded optional-package compatibility contract

The adapter validates the installed callable surface before constructing the
live presentation. It does not certify arbitrary behavior inside a function,
protect against a package being modified after mount, or suppress installation
and lifetime exceptions. Native Cocos APIs and original Explore/save/controller
implementations remain the unchanged reviewed runtime, not interchangeable
optional implementations.

## Inventory

- Renderer: build, project, inverse, depth, tilePoint, transform, alphaAt,
  eventAt. The detached build and later event/object sync use these helpers.
- Object adapter: create, sync, rebuild, dispose. Object catalog: resolve.
- Boat adapter: create, sync, dispose, heading.
- HUD: create, sync, dispose, canAct, invalidate, arrowPoints, contains, details.
- Original HUD hit/readiness boundaries: AdventureSea.isHudPoint and
  CleanVoyageHUD.canAct.
- HUD navigation read path: AdventureNavigation.query/snapshot/port;
  KnownRoute.key/inBounds/direction/foodCost/find; AdventureNavigationView.lines.
- Shared HUD construction and immediate sheet helpers: WarmTheme.panel, label,
  button, fit, enabled, icon, sprite. In particular button calls fit during
  installation, before any control can be used.
- HUD status/objective read path: AdventureProgress.getState,
  showHarborBrief/getHarborStatus.
- Deferred sheets: AdventureDialog.show, WarmDialog.show,
  WarmPause.open/canOpen/checkpoint, WarmCollection.open,
  WarmMemories.get/setDisplay/definitions, WarmActivities.open/textPages.
  These are static API checks; no sheet is opened and no save action is called.
  Delegation into original cargo/return/gameplay and existing downstream pages
  remains owned by the unchanged original implementations.
- Detached material/source preparation: CleanSeaPresentation.gate and
  SeaChartWorldTheme.landLayers/familyForLayer/placeMaskTile.

The61 listed functions each receive independent missing and noncallable native
counterexamples (122 cases). The tests inspect original ownership/hooks, source
geometry/save state, native DrawNode/listener counts and original pixels.

## Consumed metadata

Before scene mutation, check HUD/font/boat-path strings are nonempty; actual
font/texture files are available; renderer halfX/halfY/rise are finite positive
numbers; and the shared Warm palette has finite RGB channels in0–255 for ink,
navy, paper, coral, sea, muted, line, white and gold. Fifty independent invalid
palette/font/path/projection cases verify fallback. The material manifest and
source map/model are also consumed within detached preparation, so malformed
structures there fail before reparenting.

A missing function reports unsupported-api:<module>.<method>. Malformed consumed
metadata reports unsupported-package-metadata. Missing files retain their
existing missing-art diagnostic. An exception during detached preparation
reports incompatible-package and stores its diagnostic on the owner only.

The only pcall boundary remains detached read/preparation. There is no blanket
catch around install, update, callbacks, disposal or native lifetime management.
