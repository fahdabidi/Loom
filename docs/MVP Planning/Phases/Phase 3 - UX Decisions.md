# Phase 3 - UX Decisions

Date: 2026-06-01

## Reference patterns applied

- YouTube-style top utility actions: prominent search, notification/tuning controls, and predictable creator/content entry points.
- Instagram/TikTok-style feed cards: large visual poster, creator identity, compact engagement actions, and direct tap-to-open behavior.
- Modern social-app intent chips: horizontally scrollable startup modes with a clear selected state.
- Trust-forward recommendation disclosure: visible "why this" access on every card and a session-level explanation above the feed.
- Neutral search treatment: search is presented as a direct query path, not as an ad surface or sponsored placement area.

## Key implementation decisions

- The fan home now opens directly to `DiscoveryHomeScreen` rather than the single-creator Phase 0 list.
- Startup tiles create or switch a session intent without leaving the home surface, supporting mid-session intent switching.
- The disclosure card stays above the feed and shows included interests plus excluded signals such as paid placement and private contact scraping.
- Feed cards are fully tappable and open a content sheet, fixing the earlier issue where creator/content cards felt inert.
- The "Why" control opens a scrollable bottom sheet so longer score explanations fit emulator-sized screens.
- Feedback buttons are icon-first with tooltips and stable keys for validation.

## Workflow walkthrough

- Cold start: the fan sees a social-app style toolbar, search field, startup intent rail, disclosure card, and ranked feed in the first screen.
- Intent selection: tapping For you, Learn, Trending, or Reset switches the session and refreshes the ranked feed while keeping the disclosure visible.
- Ranking inspection: tapping "Why" on a feed card shows matched intent signals, summary-first ranking evidence, trending velocity, external-provider rationale when present, and excluded signals.
- Feedback shaping: dislike removes that content from the next feed; mute and block persist creator-level suppression.
- Neutral search: entering a query shows search results with a visible "no ads, boosts, or paid placement" label.
- Content opening: tapping a card opens a compact content sheet so feed items behave like modern social-media content cards.

## Validation notes

- The emulator screenshot after install/launch showed the discovery toolbar, startup intent tiles, session disclosure, paid-placement exclusion, and the first feed poster.
- Full integration validation passed on the Flutter Android Emulator, including previous Phase 0-2 flows and all Phase 3 workflows.
