# Phase 26 - UX Decisions

## Reference Patterns Applied

- Final demo scripts should make the story obvious through a short sequence: connect agent, search, inspect compliant mixed results, play embedded video, then open a creator channel and play a creator-linked tile.
- External content should feel native in the feed while keeping platform attribution, original title, and source context visible.
- Network-dependent playback needs explicit fallback/error state and must avoid covering the official player with app ads or overlays.
- Phone validation must check safe areas, text wrapping, scroll reachability, tap targets, contrast, and real playback on hardware.

## Implementation Decisions

- Inserted one seeded YouTube tile into each of the five gaming creator channel module stacks.
- Kept seeded tiles creator-specific by reusing their accurate-match labels and creator notes.
- Kept all external tiles powered by the same `external_content` module path introduced in Phase 25.
- Updated the demo runbook with the AI-search and external-content showcase loop.

## Workflow Walkthrough

1. Fan connects a simulated AI search agent and enables YouTube.
2. Fan searches a gaming topic and sees creator-preferred mixed results.
3. Fan opens a YouTube result and gets the official embedded player plus AI-driven next rail.
4. Fan opens a gaming creator channel and sees a creator-linked YouTube tile in the native module stack.
5. Fan taps the tile and returns to the same external playback flow.
6. Final validator repeats the loop on a physical Android phone and records hardware evidence.
