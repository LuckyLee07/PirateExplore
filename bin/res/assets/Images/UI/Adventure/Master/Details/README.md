# Approved static micro-detail polish

Only four unlettered/static ornaments are replaced: skull coin, faceted gem,
fixed “海盗基地” wordmark (including its ink rule and compass), and the coral
navigation selection brush. Dynamic amounts, plus signs, controls and all
hitboxes remain native Cocos components.

Source: `micro-assets.png`, a 1536×1024 transparent RGBA atlas generated from the
approved harbor master direction. The original atlas is retained separately,
unmodified, as Library source `libfile_19d519414fd08191b7a915ed68fb5f77`. Rectangles use top-left pixel coordinates `(x, y, width, height)`:

- Title: (79, 164, 1410, 361)
- Coin: (139, 614, 308, 306)
- Gem: (564, 654, 325, 254)
- Selection brush: (972, 766, 485, 50)

These alpha-content crops were resized with Lanczos, preserving aspect ratio
and RGBA transparency. Production sizes are title 480×123, coin 120×119,
gem 120×94, and brush 200×21. No glow, background color, typography or geometry
was painted during import. Colored RGB values in fully transparent source
pixels were not composited into a black background.

The runtime uses explicit bilinear texture filtering and uniform sprite scale.
The legacy renderer requires power-of-two textures for generated mipmaps, so
these small non-power-of-two ornaments are prefiltered instead. Runtime boxes
remain title 240×58 logical, icons 40×40, selection brush 50×7. Missing/failed
assets retain the previously tested native ornaments; a loaded title hides the
old visible label and compass to prevent duplication.
