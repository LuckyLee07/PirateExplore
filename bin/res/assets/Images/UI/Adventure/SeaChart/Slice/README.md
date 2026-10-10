# First-chapter slice artwork

Generated through built-in image generation using the approved sea-chart design and actual first-chapter shoreline contract. These are reusable transparent world artwork and real event-atlas frames, never a flattened UI screenshot.

- `coast-piece.png`: source `coast-piece-simplified-v4.png` (1145×1374 RGBA), whole 5:6 canvas normally resized with Pillow Lanczos to 640×768. Runtime uniform scale to 320×384, world origin (192,832). Never crop to alpha bounds. Source retained externally in `/workspace/shared/b-sea-slice-art/`.
- `events-map1.png`: generated `event-frames-v2.png` (2172×724 RGBA), imported using `python tools/import_sea_slice_events.py SOURCE`. Only original atlas local frames 28 / 11 / 12 change. Native nodes remain 64×64; both skull variants share crop, scale and baseline, with safe transparent margins.

Original source artwork and approved reference are retained by the project Library workflow. This repository includes only compact runtime assets, not large generation sheets or QA saves.

## Superseded event interpretation

The 2026-10-09 global CSV audit identified GIDs 30/31 as iron mines, despite
the skull appearance authored for this earlier slice. Runtime event art now uses
`../Tiles/events-world.png`, which corrects those two frames to iron and retains
this atlas only as the source of the correctly identified revival cross (47).
The historical 30/31/0 tests demonstrate tile-state rendering, not skull combat.
