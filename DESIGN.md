---
name: Gridmaster
description: A memory puzzle built as a box of chunky plastic tiles you press with your thumb.
colors:
  ground: "#1B1F3B"
  ground-deep: "#101327"
  panel-face: "#2A2F57"
  panel-lip: "#11142B"
  raised-face: "#3D4379"
  raised-lip: "#191D3C"
  well-face: "#2A2F57"
  well-lip: "#1D2142"
  tile-red: "#FF6B5E"
  tile-red-lip: "#C4463B"
  tile-blue: "#3BA3F5"
  tile-blue-lip: "#2372B5"
  tile-green: "#2CCB8C"
  tile-green-lip: "#1C9063"
  tile-yellow: "#FFC83D"
  tile-yellow-lip: "#C9901A"
  tile-purple: "#9D7BFF"
  tile-purple-lip: "#6B4FC9"
  tile-orange: "#FF9447"
  tile-orange-lip: "#C46522"
  tile-pink: "#FF72B6"
  tile-pink-lip: "#C4468A"
  accent-mint: "#5FE0B0"
  text-primary: "#F4F5FF"
  text-secondary: "#A3A9D6"
  text-muted: "#969DCB"
  scrim: "#0E1024E6"
typography:
  display:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "48px"
    fontWeight: 700
    lineHeight: 1
    letterSpacing: "-1px"
  headline:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1.05
  title:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "24px"
    fontWeight: 600
  body:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "16px"
    fontWeight: 500
  button:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "18px"
    fontWeight: 600
  label:
    fontFamily: "Fredoka, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    letterSpacing: "1.2px"
  number:
    fontFamily: "Fredoka, sans-serif"
    fontWeight: 700
    lineHeight: 1.05
    fontFeature: "tnum"
rounded:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "22px"
  xl: "28px"
  pill: "999px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  key-primary:
    backgroundColor: "{colors.tile-green}"
    textColor: "#0A241A"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  key-cta:
    backgroundColor: "{colors.tile-yellow}"
    textColor: "#4C370A"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "12px 20px"
  key-neutral:
    backgroundColor: "{colors.raised-face}"
    textColor: "{colors.text-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.md}"
    padding: "11px 16px"
  key-icon:
    backgroundColor: "{colors.raised-face}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    size: "48px"
  tab:
    backgroundColor: "{colors.raised-face}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    padding: "10px 16px"
  tab-selected:
    backgroundColor: "{colors.tile-green}"
    textColor: "#0A241A"
    rounded: "{rounded.sm}"
    padding: "10px 16px"
  panel:
    backgroundColor: "{colors.panel-face}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.xl}"
    padding: "28px 24px 24px"
  board-tray:
    backgroundColor: "{colors.ground-deep}"
    rounded: "{rounded.lg}"
    padding: "10px"
  stat-well:
    backgroundColor: "{colors.ground-deep}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "12px"
  coin-pill:
    backgroundColor: "{colors.raised-face}"
    textColor: "{colors.tile-yellow}"
    rounded: "{rounded.pill}"
    padding: "5px 14px 5px 10px"
  timer-track:
    backgroundColor: "{colors.ground-deep}"
    rounded: "{rounded.pill}"
    padding: "3px"
    height: "16px"
---

# Design System: Gridmaster

## Overview

**Creative North Star: "The Box of Plastic Tiles"**

Gridmaster looks and behaves like a box of chunky plastic tiles on a dark felt ground. Every surface is a physical piece: a face sitting on a solid, darker lip. Pressing sinks the face onto the lip; releasing springs it back with a small overshoot. Things that hold pieces (the board tray, the timer track, stat slots) are the opposite shape: sunk into the ground with an inner top shadow and no lip. There are exactly these two states of matter, raised and sunken, and every screen is built from them.

The system is one shared custom game look on iOS and Android. It does not switch between Cupertino and Material idioms; Material splash and highlight are switched off, and all feedback is the piece's own travel plus a haptic tick. Units are logical pixels. The tokens in the frontmatter describe the free default theme; seven purchasable themes replace the faces and get their lips computed by the same formula, so depth survives every reskin. It is a phone game, not a website: no hairline-bordered cards, no translucent slate panels, no landing-page composition.

Motion is part of the material. Tiles pop in with an overshoot, bursts of chips fly out in the tile's own color, a solved board hops in a diagonal wave. All of it is decoration on top of state that is already legible without it, and all of it switches off under the system reduce-motion setting.

**Key Characteristics:**
- Face plus lip on everything raised; inner top shadow on everything sunken.
- Saturated tile colors on a deep indigo ground; chrome stays neutral indigo.
- One typeface (Fredoka), rounded and heavy, with tabular figures on every number.
- The grid is the largest object on the game screen; the palette row sits in thumb reach.
- Feedback is physical and immediate: 90 ms down, 180 ms back up.
- Ads live in a fenced, motionless lane at the bottom.

## Colors

Seven matched-saturation tile colors on a deep indigo ground, with neutral indigo chrome so that color on the board always reads as pattern.

### Primary
- **Tile Green** (`tile-green` on `tile-green-lip`): the `primary` role in the default theme. Confirming keys (retry, selected tab), the MASTER half of the wordmark, the equipped ring in the shop, the rebuild-phase timer fill. Also pattern color 3.
- **Key Yellow** (`tile-yellow` on `tile-yellow-lip`): the `cta` role, fixed across all eight themes. The play key, coin amounts, rewarded-ad offers, the paid hint key, the preview-phase timer fill. Also pattern color 4.

### Secondary
- **Tile Blue** (`tile-blue`): the `secondary` role. **Tile Purple** is the `hint` role tone in the palette (in purchased themes it is derived from the theme's secondary) and the shop key on the start screen.
- **Accent Mint** (`accent-mint`): flat ink only, never a piece: best-score numbers, text cursor and selection.

### Tertiary
- **Tile Red** (`tile-red`): doubles as `danger`, fixed across themes: failure titles, the 3 px error ring on wrong cells, the timer fill in the last 2 seconds of rebuild.
- **Tile Orange** (`tile-orange`): combo badge and the warning fill of the preview timer. **Tile Pink** is pattern-only.

### Neutral
- **Ground** (`ground`): scaffold background of every screen.
- **Deep Ground** (`ground-deep`): everything sunken: board tray, timer track, stat slots, the banner lane.
- **Panel** (`panel-face` on `panel-lip`): cards, the palette tray, overlay cards. The lip is darker than the ground itself, otherwise the panel reads flat.
- **Raised Key** (`raised-face` on `raised-lip`): neutral keys that sit on a panel or the ground: back, pause, settings, secondary actions, the hint key, unselected tabs.
- **Empty Well** (`well-face` on `well-lip`): an empty grid cell.
- **Text** (`text-primary`, `text-secondary`, `text-muted`): headings and numbers, body copy, stat labels.
- **Scrim** (`scrim`): 90 % deep indigo behind pause and game-over cards.

### Named Rules
**The Computed Lip Rule.** A lip is never picked by eye. It is the face in HSV with saturation x 1.08 and value x 0.76. The default theme's hand-set lips follow the same relationship; every purchased theme gets its lips from the formula. Two exceptions, both for legibility: the panel lip and the raised-key lip are set darker than the surface they sit on.

**The Ink Rule.** Text and icons on a colored face are computed, not chosen: if the face luminance is above 0.42 the ink is the lip mixed 62 % toward black, otherwise white.

**The Pattern Color Rule.** On the board and in the palette row a tile color means a pattern color. Pattern tiles and palette keys are never dimmed, tinted or made translucent, in any phase. A control that sits next to the pattern keys must not read as one of them: the hint key is the neutral raised key with a yellow bulb, not a colored key.

**The Disabled Rule.** Disabled pieces are muted by mixing face and lip 62 % toward the surface they sit on. They keep their lip. Opacity is not used for disabling.

**The Theme Parity Rule.** `cta` and `danger` keep their default tones in all eight themes. Everything else resolves from the theme: deep ground is background mixed 40 % to black, the panel lip is background mixed 45 % to black, the empty well is the surface lifted 7 % toward the text color so empty tiles stay readable on near-black themes.

## Typography

**Display Font:** Fredoka (via google_fonts, platform sans fallback)
**Body Font:** Fredoka
**Label/Mono Font:** Fredoka with tabular figures for numbers

**Character:** One rounded, heavy face for everything. It has the same soft corners as the tiles, so text reads as part of the toy rather than as UI laid over it. Weights stay between 500 and 700; there is no light or regular weight anywhere.

### Hierarchy
- **Display / wordmark** (700, 48, line-height 1, tracking -1): the GRID + MASTER wordmark only, scaled to fit. Set extruded (see Elevation).
- **Headline** (700, 36, line-height 1.05): overlay verdicts ("Falsch!"), one per overlay.
- **Title** (600, 24): screen titles in the top bar, section headings.
- **Body** (500, 16, secondary text color): explanatory copy in overlays, shop and settings.
- **Button** (600, 18; 15 on tabs): text on keys. Color comes from the Ink Rule.
- **Label** (600, 12, tracking 1.2, uppercase, muted color): the name of a stat directly beside or above its number (PUNKTE, MAX COMBO, FELDER, BESTLEISTUNG). 10 to 11 inside small badges.
- **Number** (700, any size, line-height 1.05, tabular figures): score, level, timer seconds, coins, prices, combo. Sizes observed from 10 (badge) to 64 (phase cue).

### Named Rules
**The Tabular Rule.** Every number that can change on screen uses tabular figures, so counters do not jitter while they count up or tick down.

**The Stat Label Rule.** The uppercase tracked label exists to name a number. It is not a heading ornament and does not sit above titles.

## Layout

Portrait only, one column, SafeArea on every screen. The game screen stacks top to bottom: coin pill and phase badge, level and score, timer bar, info row with pause key, the board, then the palette tray near the bottom in thumb reach, then the banner lane. Side padding is 16 (8 inside the header block).

The board is square: 92 % of screen width, capped at 95 % of the free space and at 420. Cells are separated by 8 with 10 tray padding (6 and 8 on small screens). Palette keys size themselves to the row between 36 and 52 (44 on small screens) with 6 between them, so five colors plus the hint key always fit on one line. The only breakpoint is height: below 600 on the game screen and below 667 on the start screen the compact spacings apply. Overlay cards are capped at 400 wide with 24 outer margin.

Spacing comes from the 4 / 8 / 12 / 16 / 24 / 32 scale. Layout slots that appear and disappear (the phase badge) keep their size reserved so the board never jumps.

### Named Rules
**The Ad Lane Rule.** The banner sits in its own 60-high lane on deep ground at the very bottom, separated from the controls by a 20 to 28 dead zone and a 2 px divider in the panel-lip color. Nothing animates at, on or over a banner. Pause and game-over overlays cover the play area only and stop above the lane. The whole play area is clipped, so particles, the shake and floating score text can never reach the lane.

## Elevation & Depth

Depth is structural, not ambient. It comes from three things in this order: the solid lip, a faint top-lit gradient on the face, and, on a few large pieces only, one soft offset shadow. There is no elevation scale; a piece is either raised, pressed or sunken.

### Shadow Vocabulary
- **Regular lip** (6 at rest, 2 pressed, travel 4): keys, filled grid tiles, panels.
- **Small lip** (4 at rest, 1.5 pressed, travel 2.5): icon keys, tabs, pills, badges, empty grid wells, the slider thumb.
- **Flat** (0): pieces that must not rise.
- **Face sheen**: vertical gradient, face mixed 10 % to white at the top, pure face at 45 %, face mixed 18 % toward the lip at the bottom; plus a 1.5 px top edge highlight, white 30 % fading to 0 by the middle, on faces taller than 14. Empty wells have no sheen.
- **Soft shadow** (black 28 %, blur 10, offset y 6, fading to half while pressed): only under large floating pieces: the palette tray, overlay cards, the play key. Never under grid cells.
- **Sunken well**: no lip; vertical gradient from the color mixed 35 % to black at the top, to the color at 12 %, to the color mixed 4 % to white at the bottom.
- **Extruded lettering**: the wordmark and the phase cue carry a hard, unblurred drop in their lip color (8.5 % of the font size; 6 on the 64 cue). This is the lip applied to letters, and it is reserved for those two.
- **Selection ring**: 3 px outline in primary text color, 4 outside the key, on the chosen palette key; 3 px ring in primary green on the equipped shop card; 3 px danger ring on wrong cells.

### Named Rules
**The Same Footprint Rule.** Pressing never changes a piece's outer size. The face moves down and the lip shrinks by the same amount, so nothing around a key shifts.

**The No Cell Blur Rule.** Nothing on a grid cell is blurred. A cell is pure paint so 25 of them stay at 60 fps on low-end Android. Cell halos in the paid grid styles are two stacked translucent outlines (inflated 5 at 35 % of the halo alpha, inflated 2.5 at full halo alpha), not a blur. Blur is allowed once per board, on the tray of the Glow and Neon Border styles, and in the soft shadow of large pieces.

## Shapes

Everything is a rounded rectangle with generous corners; there are no sharp corners in the default world and no circles except the play key, the slider thumb and round icon keys. Radii: 8 small badges, 12 tabs, pills and small keys, 16 standard keys and stat slots, 22 cards and the default board tray, 28 the palette tray and overlay cards, 999 for the coin pill and the timer. Keys sized by a number derive their corner from it: icon keys use 34 % of their size, palette keys 32 %.

Borders are not used for structure. Outlines appear only as state (selection, equipped, error) or as a purchased grid style. The five grid styles are the one place where shape varies, and each paid style adds to the default instead of replacing it:

- **Default**: tray 22, cells 12, no outline.
- **Rounded**: tray 34, cells 20, 3 px tray outline in the panel face.
- **Sharp**: tray 6, cells 3, 2 px tray outline in muted text at 50 %.
- **Glow**: tray 24, cells 12, 3 px tray outline in primary at 70 %, one blurred tray glow (primary 35 %, blur 24, spread 2), cell halo alpha 0.32.
- **Neon Border**: tray 14, cells 6, 3 px accent tray outline, two blurred tray glows (accent 55 % blur 16, accent 22 % blur 34), 2 px accent ring on colored cells, cell halo alpha 0.18.

## Components

### Buttons (keys)
Keys feel like real keys: they fire on release, not on touch-down.
- **Shape:** rounded rectangle (16), regular lip; default padding 20 x 12. Full-width overlay keys use 16 x 14 (large) or 16 x 11.
- **Primary:** green face, computed dark ink. **CTA:** yellow face, used for play and for anything that earns or spends coins. **Neutral:** raised indigo key with primary text color, for secondary actions.
- **Press:** face travels down over 90 ms ease-out with a selection haptic on touch-down; returns over 180 ms with a back-overshoot. Cancel returns without firing. There is no hover and no ripple.
- **Disabled:** muted tone per the Disabled Rule, no soft shadow, no haptic.
- **Icon key:** square, 48 by default, small lip, corner 34 % of size, icon at 50 % of size, always with a spoken label.

### Chips (pills and badges)
- **Coin pill:** raised tone, pill radius, small lip, coin image plus tabular yellow number.
- **Phase badge:** radius 12, small lip, icon plus uppercase label, tone by phase; its slot stays reserved when hidden.
- **Small badges** (x2 bonus, combo, hint count): radius 6 to 10, small lip or flat, number style at 10 to 14. The hint count badge sits 8 outside the key's top right corner with a 2 px outline in the panel face.

### Cards / Containers
- **Panel:** panel tone, regular lip, radius 22 (lists, shop cards, settings groups) or 28 with soft shadow (palette tray, overlay cards, padding 24 / 28 top).
- **Stat slot:** sunken well in deep ground, radius 16, padding 12, a stat label over a number.
- **Overlay:** scrim fades in, card scales from 0.86 to 1 with a back-overshoot over 280 ms. Under reduce-motion: 120 ms fade, no scale.

### Inputs / Fields
- **Slider:** 12-high track, active part in primary, inactive in deep ground; the thumb is a round face (radius 14) on a 4 lip that sinks while dragging.
- **Palette key:** a pattern tile as a key (32 % corner, regular lip, no content). The chosen key lifts 6, scales to 1.08 over 220 ms with back-overshoot and gains the 3 px selection ring.
- **Hint key:** neutral raised key with a yellow bulb and a count badge while free hints remain; yellow CTA key with a coin price badge when the hint costs coins; muted when unavailable.

### Navigation
- **Top bar:** 48 back key in the raised tone, 14 gap, title in the Title style scaled down to fit, optional trailing piece; padding 16 x 8.
- **Tabs:** a scrollable row of small keys (radius 12, small lip, 15 text, 8 apart). The selected tab is the primary tone held fully pressed; the others are raised neutral keys.

### Grid cell (signature)
Filled cells are regular-lip tiles with sheen; empty cells are small-lip wells without sheen. Pure paint, no blur, no soft shadow. Tiles enter with the pop scale 0.6, 1.12, 0.96, 1 over 380 ms, staggered by 70 ms; a solved board hops in a diagonal wave; when the pattern hides, the tray dips once to 0.97 over 250 ms; a wrong answer shakes the play area for 260 ms (amplitude 9, decaying) and rings the wrong cells in danger red. The window between a solved level and the next is 1200 ms.

### Timer bar (signature)
A pill track sunk into deep ground (3 padding, 10 fill height). The fill is a lit pill in a role tone that drains linearly, blends to its warning tone over the half second before the 2 s mark and swells vertically up to 1.35 while under 2 s. Under reduce-motion it still drains and changes color but does not swell.

### Particles (signature)
One fixed pool (220 particles, 12 rings) with no allocation during play; its ticker runs only while something is alive. A burst throws about 10 chips (rounded squares, or four-point stars for the Sparkle animation) about 46 outward in the tile's color and a 35 % lighter tint, with a little gravity, over 520 ms. Rings are expanding tile-shaped outlines. The layer ignores pointers, has its own repaint boundary and is clipped to the play area.

### Numbers in motion
Scores count up over 700 ms ease-out-cubic and only ever count upward; resets snap. A changed value gets a bump (scale 1.25, fast up, elastic settle, 420 ms). Gained points float up over 900 ms.

## Do's and Don'ts

### Do:
- **Do** build every raised thing from a face and a lip, and every container for pieces as a sunken well.
- **Do** derive lips with the Computed Lip Rule (saturation x 1.08, value x 0.76) and inks with the Ink Rule, so all eight themes keep the same depth.
- **Do** use regular depth (6 to 2) for keys and tiles and small depth (4 to 1.5) for icon keys, tabs, pills and empty wells.
- **Do** fire actions on release, with a selection haptic on touch-down, 90 ms down and 180 ms back.
- **Do** check `MediaQuery.disableAnimations` in every effect: pops, bumps, shake, count-up, selection lift, overlay scale and the timer swell all switch off; state stays readable without them.
- **Do** keep particles, shake and floating text inside the clipped play area, and keep a 20 to 28 dead zone plus divider above the banner.
- **Do** set every changing number in tabular figures.
- **Do** keep purchased themes and grid styles additive and clearly distinct from the default.

### Don't:
- **Don't** animate anything at, on or over an ad banner, and don't let an overlay cover the banner lane.
- **Don't** blur anything per grid cell. Halos are stacked outlines; blurred glow belongs to the tray of the Glow and Neon Border styles only.
- **Don't** dim, tint or fade pattern colors on the board or in the palette row, and don't give a control next to the pattern keys a pattern-colored face.
- **Don't** disable with opacity; mute toward the surface and keep the lip.
- **Don't** use hairline borders, translucent panels or Material ripples for structure or feedback.
- **Don't** change a piece's outer size on press.
- **Don't** switch to Cupertino or Material idioms per platform; the look is shared.
- **Don't** introduce a second typeface or a weight below 500.
- **Don't** extrude text other than the wordmark and the phase cue, and don't put a soft shadow under small pieces or cells.
