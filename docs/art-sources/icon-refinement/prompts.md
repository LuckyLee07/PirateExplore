# Built-in imagegen prompt set

All calls used transparent_background=true. Approved images were actually
viewed before being supplied as references. Raw masters in this directory are
unmodified generated PNGs, including their original alpha and metadata.

## Food

Use case: style-transfer. Asset type: production game inventory icon, ID1005
food. Image1 is approved restrained B light-cartoon pirate adventure style
reference: warm parchment, navy ink contours, hand-painted gouache, comfortable
cohesive shapes. Image2 is the existing FOOD identity: a warm rustic bread loaf
and one sliced piece. Redraw this single bread icon at high quality for actual
30–64px rendering, not a decorative illustration. Preserve loaf plus slice
subject. One compact substantial centered silhouette occupies 84% square width;
clean dark toasted contour, 3 broad scored highlights on crust, warm golden crumb
on visible slice, subtle 2-tone painterly shading only. Large readable planes,
no tiny stipple, no noisy specks, no decorative props or bag, no plate, no cast
shadow outside silhouette, no glow, no text, no border. Fully transparent
background, truly transparent outside the loaf. Isolated single icon, square
composition. Avoid shiny mobile-casino aesthetic. Final appearance must be clear
at30px, confident hand-painted outlined icon matching first reference.

## Wood / stone shared prompt

Use case: style-transfer. Production game inventory icon. Image1 is approved
restrained B light-cartoon pirate adventure style reference; Image2 preserves
the exact existing object's identity. Subject: [subject below]. Redraw the
object for30–64px native UI display with confident hand-painted gouache and
lightly inked warm dark contours, broad readable shapes, subtle 2-tone shading,
no tiny stippling or noise. One isolated centered compact silhouette,84% square
frame width, optical center at middle. Transparent background with no shadow
outside silhouette, no glow, no border, no text, no extra props. Visually
cohesive with first reference's comfortable paper-and-ink adventure aesthetic;
do not make glossy casino art.

- Wood subject: A compact tied bundle of three cut timber logs, clearly showing
  three golden endgrain circles and dark brown bark; one simple rope binding.
  Preserve wooden construction-material identity.
- Stone subject: A compact cluster of three angular grey building stones. Broad
  pale slate lit planes, navy-grey shaded planes, one clear largest block; no
  gems, no ore veins. Preserve ordinary building-stone identity.

## Port initial

Use case: style-transfer. Asset: single monochrome harbor-management navigation
icon for the exact approved pirate harbor UI shown on LEFT HALF of reference.
Recreate the LEFT design's bottom-right small warehouse-with-crate symbol as a
clean standalone production icon. Subject identity must be a squat harbor
warehouse, visible triangular pediment roof with one small round attic window,
open arched dark doorway, pale sturdy corner posts, and one small shipping crate
standing in front at lower right, X bracing cut out. A short quay baseline. NOT
a home icon, not a lighthouse. Silhouette in one warm ivory cream color
(#F6EBCF), a few large truly transparent negative spaces only. Restrained
hand-painted/ink-cut edge personality with slightly uneven contours but NO
textured holes or granular noise. Broad simple sturdy features optimized for
actual40px display, matching reference LEFT icon's sophistication. Fill most of
a centered square frame with6% padding, fully transparent background. No
lettering, no separate background panel, no drop shadow, no blue fill inside
openings, no colored details, no black outlines. One icon only.

## Port final edit

Precise object edit: keep this same single warehouse and shipping crate icon
identity and arrangement. Repair ALL its transparency and edge problems. Remove
every single white, grey or black speck and all texture from between or outside
the cream shapes. All background and every opening must be completely
transparent clean empty alpha: roof gap, attic hole, doorway, spaces around
crate, rope and columns. Keep only flat solid uniform ivory (#F6EBCF) positive
shapes, smooth antialiased continuous edges, large negative spaces. No grain,
no paper texture, no drop shadow, no outline, no new details, no text. This is
a tiny40px UI pictogram; contours can be pleasantly organic but must be clean.
Repair sparse transparent flecks and make cutouts clean.

## Barrel initial

Use case: style-transfer. Asset: ONE isolated monochrome food-and-water supply
barrel icon for pirate harbor UI. Reference is side-by-side approved LEFT
design vs old RIGHT game. Faithfully recreate the small LEFT DESIGN supply
barrel next to food count, with large readable hand-painted shapes. One upright
small stout wooden supply barrel, slightly visible oval open top lip, broad
curved sides, two sturdy horizontal hoops, exactly two wide vertical stave seams
cut out so the barrel remains recognizable at24–30px. Warm uniform ivory cream
(#F6EBCF) symbol, no dark outline, true transparent negative-space grooves and
barrel opening. A lightly hand-cut contour but NOT grain or speckled texture.
Barrel silhouette occupies78% width,87% height, centered on square. No badge,
background, text, plate, lid, extra props, or shadow. Avoid fragmented isolated
tiny lines. This is a refined symbolic navigation/UI icon, not a full-color
wooden inventory illustration. Background must be truly transparent including
the openings.

## Barrel final edit

Precise object edit: repair this barrel icon's transparency defects. Preserve
the barrel shape and broad hoop design exactly. Remove ALL white specks and grey
mottles from outside and between cream shapes. The center oval hole and all
stave/hoop gaps must be completely empty transparent pixels, no white flecks or
colored pattern. Keep only solid flat uniform ivory #F6EBCF positive shapes,
clean smooth antialiased contours. No distress, no grain, no paper texture, no
shadow, no new details, no outlines. This is a24px production UI icon.
Transparency everywhere outside the clean cream symbol.

## Inspection outcome

## Port optical-weight revision after native540px inspection

Precise object edit. Image1 is the standalone harbor warehouse+crate UI icon to
improve; image2 is actual game context, where this bottom-right symbol looks too
thin and empty beside anchor/sail/crew icons. Change only optical weight of
image1; do not redesign identity. The warehouse must have stout SOLID cream side
walls on left/right of its arched central doorway, not separate thin posts
surrounding empty space. Make the triangular roof pediment solid with a small
circular transparent attic opening, eliminate the thin extra parallel roof gap.
Increase thickness of arch and crate outer edges so all structures survive at
40px. Keep the short baseline and one distinct X-braced shipping crate at lower
right; keep squat overall square silhouette and same scale, no extra objects.
Use single flat ivory cream positive shapes, truly transparent clean background/
open doorway/window/X spaces. No gradients, texture, grain, white specks,
shadows, outlines, text, or background panel. Aim total filled area about50%
inside its bounding box, similar visual mass to the three-person navigation
pictogram; strong readable filled pictogram, not architectural line drawing.
Output only the single isolated warehouse-with-crate icon on transparent background.

The selected result increases integrated alpha area by approximately21% without
increasing the runtime box. It retains some roof separation despite the prompt;
it is reviewed on its actual pixels rather than assumed to satisfy every phrase.

The final navigation files retain faint alpha1–9/255 background fragments, not
opaque white dirt. Production import uses meaningful alpha bounds, preserves
antialiasing, and exports neutral masks. Same-size dark/paper previews are clean.
Do not use a viewer's misleading alpha display as evidence of an opaque defect.
