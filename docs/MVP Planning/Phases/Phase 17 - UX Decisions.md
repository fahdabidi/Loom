# Phase 17 - UX Decisions

Date: 2026-06-02

## Reference Patterns Applied

The modules use common competitive/social patterns without copying brand assets:
- Clip leaderboards use compact rank rows, clear vote actions, and a seasonal context line similar to short-form/video community ranking surfaces.
- Pick'Em uses chip-style choices, locked-in selected state, and a small ladder inspired by sports/esports prediction cards.
- HypeWars uses a visible progress meter, simulated wallet balance, and one clear contribution action like modern creator support flows.

## Implementation Decisions

- Modules render inside the existing creator-channel surface stack instead of taking over navigation, so the channel remains scannable.
- Clip Arena exposes two primary actions: submit a clip and vote the current leader. The leaderboard remains legible on phone width with one-line titles and score labels.
- Pick'Em options come from module config, which lets NovaClutch and FrameByFrame use different prediction prompts without a bespoke widget.
- HypeWars labels the wallet as simulated and shows progress toward a creator-configured goal.
- The app composes `feature_extensions` from `loom_demo` through a callback. This preserves the no feature-to-feature import rule while still letting channel slots render live modules.

## UX Validation Notes

Automated widget coverage validates that:
- NovaClutch renders Clip Arena, Pick'Em, and HypeWars as live modules.
- Submitting a clip updates the rendered module state.
- DriftAndChill HypeWars can send simulated hype and update the meter/wallet copy.

Manual emulator screenshots remain pending until WSL sees an Android emulator.
