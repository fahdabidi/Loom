# Phase 24 — Embedded Player & AI-Driven Next

**Surface:** Fan App · **UX gate:** HIGH · **On green:** AUTO → Phase 25
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 23. Tapping a YouTube result/tile launches the **official in-app
> embedded player** (IFrame Player API), unobscured; a **"Next from your AI search"** rail surrounds the player
> so the next recommendation comes from the **fan's AI search, not the platform**. This is the first phase that
> uses **real network at play time** (the YouTube IFrame) — all Loom APIs remain faked/offline. Non-YouTube
> sources open externally via the OS. Strict third-party compliance applies.

## 0. Prerequisite gate (validate Phase 23 done)
README gate + confirm Phase 23 committed/recorded: AI search returns merged creator+external results with embed
descriptors + compliant external titles; Phase 23 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S18 / embedded YouTube playback** — Tapping a YouTube item (`embedDescriptor.kind = youtube_iframe`)
  opens the **official IFrame player** in-app; the player and its controls are **not obscured**.
- **FE-S18 / AI-driven next** — Alongside/after the player, a **"Next from your AI search"** rail lists the
  fan's AI-search results (creator-preferred), not YouTube's recommendations.
- **FE-S18 / non-YouTube sources** — Other source types open externally (`url_launcher`); full Twitch embed deferred.
- Compliance: official unobscured player; unaltered title/thumbnail; source attribution retained; no Loom ads over the embed.

## 2. Tools (WSL Ubuntu)
Standard set. **Network required at play time** for the YouTube IFrame. Add deps `youtube_player_iframe` and
`url_launcher` to `apps/loom_demo` (and any package that owns the player widget). Emulator must have internet.

## 2A. UX reference research & decision output
Record in [Phase 24 - UX Decisions.md](./Phase%2024%20-%20UX%20Decisions.md):
- YouTube IFrame Player API requirements: official player, **no overlays in front of the player/controls**, a
  custom play button over the **unaltered** thumbnail is allowed and must start playback.
- "Up next" rails that are clearly the app's own recommendations (here, the fan's AI search), distinct from the embed.
- Graceful states when offline / video unavailable (the only network-dependent surface).

Apply the shared baseline plus: the player is full-width and unobscured; the AI-next rail sits **outside** the
player frame; the original title + source attribution remain visible on the player page; an offline/error state
explains that external playback needs a connection.

## 3. APIs invoked & stubs to implement
No new Loom API surfaces. Reuse:
- **AI Gateway API `runAiSearch`:** powers the "Next from your AI search" rail (creator-preferred).
- **External Content Source API:** resolves the `embedDescriptor` (externalId) for the player.
- **Receipt Ledger:** a playback-open audit event for external content (no economic receipt; external view isn't Loom-monetized).
- **YouTube IFrame Player API** (external, client-side): real playback; no API key; no Loom data sent.

## 4. Data storage (local store)
No new domain tables. Optionally record an audit "external_play_open" event (no economic receipt). Confirm `resetDemo()` clears it.

## 5. Source files & components to create/update
- Design system: `player/youtube_embed_player.dart` (wraps `youtube_player_iframe`, unobscured),
  `player/ai_next_rail.dart` ("Next from your AI search"), `player/external_source_banner.dart` (title + source attribution).
- `features/fan/feature_playback` (extend) **or** new `features/fan/feature_external_player`: route external items to the
  embed player + AI-next rail; route non-YouTube to `url_launcher`. Keep Loom-native playback (PlayerChrome) unchanged.
- `apps/loom_demo/pubspec.yaml`: add `youtube_player_iframe`, `url_launcher`.

## 6. API best-practice checks (phase-specific)
- The embed uses the **official player, unobscured**; the AI-next rail and attribution are **outside** the player frame.
- External title/thumbnail remain **unaltered**; source attribution retained; **no Loom ad** is shown over the embed.
- The AI-next rail comes from `runAiSearch` (fan's agent), not from YouTube; bounded calls.
- No platform API data is stored/re-syndicated beyond the seeded public video ID; offline/error handled gracefully.

## 7. Component boundary / design checks
- Player + rail components in `loom_design_system`; routing/state in the feature.
- The `youtube_player_iframe`/webview dependency is bound only where the player widget lives; `lint:boundaries` clean; charter updated.

## 8. Automated validation checks
README baseline plus widget tests (mock the embed in tests — no live network in CI): tapping a youtube_iframe item
opens the embed surface; the AI-next rail renders from AI-search results; non-YouTube opens via `url_launcher`
(mocked); offline/error state renders. Manual: confirm a real seeded video plays on the emulator with network.

## 9. Integration tests
- `it_p24_embed_launch` — Tapping a seeded YouTube item opens the embedded-player surface (player widget present, unobscured) with title + source attribution.
- `it_p24_ai_next_rail` — The "Next" rail is populated from AI search (creator-preferred), not platform recommendations.
- `it_p24_non_youtube_external` — A non-YouTube external item triggers an external open (mocked `url_launcher`).

## 10. Definition of done
YouTube items play in the official in-app IFrame player (unobscured, attribution retained, no Loom ads over it);
the "next" rail is AI-search-driven; non-YouTube sources open externally; offline/error handled; compliance holds;
all checks + integration tests green; a real video confirmed playing on the emulator (manual, with network);
screenshots captured. [Phase 24 - API Review.md](./Phase%2024%20-%20API%20Review.md) and
[Phase 24 - UX Decisions.md](./Phase%2024%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 24 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 25 — Creator External Content in Feeds](./Phase%2025%20-%20Creator%20External%20Content%20in%20Feeds.md).**
