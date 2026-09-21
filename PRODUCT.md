# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

One Flutter codebase shipped to iOS and Android. Confirmed by the owner: the game keeps a single, own visual language on both systems; it does not switch between Cupertino and Material idioms. Portrait only.

## Users

Casual players from teens to adults, in short sessions of one to five minutes: on the train, in a break, on the sofa. Usually one-handed, often with the sound off, frequently on inexpensive Android phones.

## Product Purpose

Gridmaster is a memory puzzle. A colored pattern is shown on a grid (preview), the player rebuilds it from memory against a timer (rebuild), the game checks automatically, and the next level starts. On a mistake or timeout the solution is shown for two seconds, then the run ends. Success is a player who starts another run.

## Positioning

A pure recall loop with no meta layer in the way: 200 generated levels growing from 3x3 with 3 colors to 5x5 with 5 colors, score driven by speed and combo.

## Operating Context

- Flow: start screen, game, pause overlay, game-over overlay, shop, settings.
- Free to play. Banner ads on the start and game screens, an interstitial after every third loss, rewarded ads for continue, double bonus and free coins.
- Coins (bought through RevenueCat or earned in play) buy cosmetics: 8 themes, 5 grid styles, 4 cell animations, 4 sound packs. A one-time purchase removes ads.
- German and English, German is the fallback.

## Capabilities and Constraints

- Flutter with Provider, go_router, google_fonts, audioplayers, google_mobile_ads, purchases_flutter.
- Game logic, level generation, scoring, storage keys and JSON formats, cosmetic ids and prices, product ids, ad unit ids, ad flows, translation keys and routes are fixed. Visual work never changes them.
- Ads: nothing animates in, on or next to a banner, nothing overlays a banner, controls keep a clear distance from it.
- Performance target: 60 fps on low-end Android.
- Purchased cosmetics must stay clearly distinguishable and must never lose value against the free defaults.

## Brand Commitments

- Name: Gridmaster, wordmark GRID + MASTER. App icon at `assets/img/appicon.png`, coin at `assets/img/coin.png`.
- Binding visual constraint from the owner: "soft 3D / tactile", touch-first, a phone game and not a website. No landing-page, hero or web UI patterns.
- Existing copy stays as written; new text only as new translation keys.

## Evidence on Hand

Real game loop, shop catalogue and sound packs in the repository. No screenshots, store listing, reviews or player numbers on hand; do not invent any.

## Product Principles

1. The grid is the game. Everything else supports reading and rebuilding the pattern.
2. Feedback is physical: every touch answers immediately, by sight and by haptics.
3. Memory must never be confused by decoration. During preview and rebuild, color means pattern color.
4. Paid things feel paid. Cosmetics add on top of a good default, never replace a missing one.
5. Ads stay in their lane.

## Accessibility & Inclusion

Respect the system's reduce-motion setting. Pattern colors must stay distinguishable from each other in every theme. Touch targets stay comfortably large for one-handed play.
