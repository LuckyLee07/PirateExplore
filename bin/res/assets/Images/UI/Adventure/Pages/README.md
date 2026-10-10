# Approved preparation / talents / sea-chart assets

These local runtime assets were created with the built-in image-generation tool using the project owner's approved B-style designs. They contain no interactive UI or baked game values. Actual names, counts, buttons, selection, progress, currency and unlock states are native Cocos components.

- `../Departure/backdrop.png`: clean harbor background derived from the approved preparation v2 design,941×1672.
- `../Talent/backdrop.png`: clean harbor background derived from the approved talent v2 design,941×1672.
- `../Talent/paper.png`: dedicated blank vertical cream paper,1118×1407 with real alpha; uniformly scaled at runtime.
- `icons.png`:1536×1024 RGBA, three512px columns and two rows: food, key, precision, dodge, hunger, scout. Original Library asset ID: `libfile_9716b79e8df08191ac15b2237511ccd9`. Native texture rectangles select the actual semantic asset. First strike uses a native lightning symbol rather than the precision image.
- `../SeaChart/Tiles/sea-water-repeat.png`: continuous1024×1024 generated sea surface used with a native repeating texture. It is only a visual backing of the original supported Sea layer; tile data stays intact.
- `../SeaChart/Tiles/dt_ludi.png`: same-size original tile atlas with legal sea-cell artwork replacements; original cell order and shoreline alpha are preserved.
- SeaChart decor sprites are transparent generated rock/palm/grass visuals. Runtime placement is restricted to tested land cells without events and remains under the original fog.

Source approval images and high-resolution generation evidence are stored separately. No approved screenshot is used as a whole interactive-screen texture. The final first-version coast uses the original land alpha as an independent display stencil for `../SeaChart/Tiles/land-surface-repeat.png` (1024×1024 RGB golden sand/rock/grass). It never changes TMX geometry or collision. Sea art remains a first-version interpretation: flat islands, older event sprites, visible water repetition and square fog boundaries are documented limitations, not claimed as exact design reproduction.
