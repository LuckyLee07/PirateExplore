# Global first-pass sea art

These runtime imports were derived from the project's imagegen-authored B-style
artwork on 2026-10-09. They are presentation resources, not new map geometry.

- `land-{sand,forest,volcanic,ice,violet,ghost}-repeat.png`: six 512×512 cells of
  `terrain-six-theme-sheet-v1.png` (1536×1024, RGB). Ordinary crop only. Generated
  cells are not mathematically seamless; mirrored repeat reduces boundary jumps.
- `decor-world.png`: `decor-six-kind-sheet-v1.png` (1536×1024, RGBA), warm rock,
  volcanic rock, ice peak, palm, broadleaf and ghost tree cells. Runtime placement
  uses sparse verified land bases and preserves the original map layer ordering.
- `events-world.png`: `event-six-types-v1.png` subjects imported by
  `tools/import_global_sea_events.py`, plus the accepted revive cross and original
  occupation flag. The importer preserves all other original atlas pixels.

Source masters are retained separately in the project Library/runtime art bundle;
large generation masters and QA saves are intentionally excluded from the repo.
The source master filenames are stable provenance labels, not runtime dependencies.

Event identity comes from the actual stronghold CSV: GIDs 30/31 are **iron mines**,
not skull encounters; 32 tavern, 45 arena, 47 revival, 48 available supply,
49/50 teleport, and 52 black market. Consumed supply GID44 remains the original
camp. Unchanged event families and existing item/character art have not been
redrawn in this first pass. Every event still uses its original Meta tile/GID.
