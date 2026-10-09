# Quiet harbor finishing materials

Generated using imagegen from the user-approved 941×1672 harbor master. The scene backdrop, title/currency art and real profession portraits are unchanged.

Source `brush-accents.png` is a 1254×1254 transparent atlas generated 2026-10-09: a layered sky-blue diagonal dry-brush wash and a thick coral brush strip, with no text, portraits or controls. One generation and one correction were used. Runtime crops are ordinary RGBA-preserving asset import with Lanczos downsampling, not repainting:

- `roster-blue.png`: source crop LTRB (203,116,1079,805), imported 420×330. Keeps blue depth and irregular edges behind the actual selected portrait.
- `coral-action.png`: source crop LTRB (16,898,1246,1186), imported 820×192. Used ONLY as a native ClippingNode alpha stencil at threshold .5. Visible interior is a continuous native coral fill (235,94,62); source RGB brush streaks never overlay the action text.

Brush materials can adapt independently in X/Y to the two supported portrait ratios. Actual portraits remain uniformly fitted; all letters, numbers, progress, button labels and click areas remain native.

A generated six-icon atlas was rejected after small-screen inspection and is not packaged. Icons instead use original native vector paths: broad cream silhouettes, sparse structural cutouts, asymmetric sails and curved anchor arms. No high-frequency image texture is used for those symbols.

Missing/decode-failed/zero-size brushes have safe native fallbacks. The blue wash falls back to blue. Production PNGs retain alpha; no black backdrop or hidden transparent RGB is baked into presentation.
