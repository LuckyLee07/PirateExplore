# Warm v1 layered artwork

Generated with OpenAI image generation for this native game adaptation, October
2026. Prompts are preserved here. Runtime assets live in
`bin/res/assets/Images/UI/Warm/`; no complete concept-screen image is used as UI.

- `sea-home.png`: 1024×1536 RGB scenery, without ship or controls.
- `ship-home.png`: 1024×1536 RGBA ship, without characters or UI.
- `crew.png`: 1536×1024 RGBA, two 768×1024 decorative character cells.
- `crew-100.png`: 1254×1254 RGBA adult starter-profession portrait. Other
  professions retain their own existing identity artwork.
- `icons.png`: 1254×1254 RGBA, nine 418×418 cells. Runtime texture rectangles
  optically center sail, map, crew, hammer, chest, journal, gear, backpack, arrow.

Native labels, buttons, quantities, panels, confirmations, selection state,
upgrade crate and owned memorial display are independent Cocos nodes. PNG alpha
is preserved; no image-processing replacement of the approved artwork was used.
The existing bundled Noto-derived heading font and its license are retained.
