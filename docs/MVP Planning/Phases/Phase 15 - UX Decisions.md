# Phase 15 - UX Decisions

Date: 2026-06-02

## Data Requirements Extracted From Reference Patterns

Modern creator/social app customization needs a renderer-friendly data model rather than per-creator UI branches:
- Creator channels need theme, banner, ordered modules, persona, and ad posture fields.
- Add-ons need manifest-declared surfaces and permissions before they can render in a channel.
- Fan participation mechanics need session/event/state records so votes, predictions, progress, badges, and rewards are portable.
- Extension state must be exportable by creator and/or fan ownership rules, not hidden in widget-only state.

## Decisions

- Persisted fields: `ChannelTheme`, `bannerRef`, ordered `surfaceModules`, `aiPersona`, `adPosture`, installed extension references, manifest surfaces/permissions, runtime sessions/events, and exportable state.
- Computed fields: installed extension display refs are derived from active installs plus manifests, and module IDs are derived from the config's ordered module list.
- Phase 15 keeps UX rendering unchanged. The new data exists so Phase 16 can replace hardcoded channel visual choices with config-driven rendering.
- The seeded gaming creators intentionally use different palettes and module orders to force Phase 16 to prove generic rendering.
- Certified extensions share one visual placement model: each extension declares approved surfaces such as `feed_module`, `channel_header`, `video_overlay`, `community_panel`, or `gallery_panel`.

## Workflow Fit

- Fans will later see each channel as a familiar modern social profile: strong banner, channel identity, follow/action row, content rail, and creator-selected interactive modules.
- Creators will later configure the same fields in Studio: theme/banner, installed modules, extension settings, and preview.
- Runtime events already support the workflows Phase 17-18 will render: clip votes, pick predictions, hype/reward activity, quest progress, build submissions, and guild milestones.
