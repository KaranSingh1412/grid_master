---
version: 1
slug: "lib-widgets-screens-game-screen-dart"
primary_target: "lib/widgets/screens/game_screen.dart"
related_targets: ["lib/widgets/screens/start_screen.dart","lib/widgets/screens/shop_screen.dart","lib/widgets/screens/settings_screen.dart"]
---

# Game surfaces (start, game, overlays, shop, settings)

Scope: the whole playable app. Visitor mode: Operate, inside a game register. Audience: casual players, one-handed, 1-5 minute sessions, often muted, often low-end Android. Task: memorize a pattern, rebuild it under time pressure, start again. Constraints: logic, storage, ids, prices, ads, routes and copy are frozen; nothing animates at or over a banner; 60 fps; reduce-motion respected.

## Direction contract

THESIS: Gridmaster is a box of chunky plastic tiles you press with your thumb. Every surface is a physical key with a solid darker lip under it; pressing sinks the face 4 px and the lip shrinks from 6 to 2. It refuses the flat Tailwind dashboard the game was ported from: no hairline borders, no glow halos, no translucent slate panels.

OWN-WORLD: Pinned by the owner. Ground #1B1F3B, empty well #2A2F57 on #1D2142, tiles red #FF6B5E, blue #3BA3F5, green #2CCB8C plus yellow, purple, orange, pink at matched saturation, each with a lip about 25% darker; CTA yellow #FFC83D on #C9901A. Fredoka throughout, tabular numerals. Depth comes from lip plus one soft offset shadow and a faint top-lit gradient. All eight cosmetic themes get computed lips and stay distinct.

STORY: The player sees tiles pop onto the board, understands they are pressable objects, presses, feels the answer, and wants one more round.

FIRST VIEWPORT: The grid dominates the game screen, sunk into a tray, the palette below it as a row of keys within thumb reach, score and level above, the banner fenced off at the bottom. On the start screen a 2x2 tile board with the play key on top is the only hero.

FORM: Brief-pinned direction ("soft 3D / tactile"); no roll, no alternates, the owner specified world, palette, face and motion values. Code-led, no image generation in this session.

SIGNATURE INTERACTION: press-down tile with overshoot pop (0.6, 1.12, 0.96, 1 over 380 ms) and a particle burst in the tile's color; on success a diagonal wave hops across the board.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
