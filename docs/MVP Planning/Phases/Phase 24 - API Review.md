# Phase 24 - API Review

## Scope Reviewed

Phase 24 adds no new Loom backend API surface. It consumes:

- `AiGatewayApi.runAiSearch` for the "Next from your AI search" rail
- `AiSearchItem.embedDescriptor` for YouTube iframe IDs and external URLs
- `url_launcher` for non-YouTube external opens
- `youtube_player_iframe` for the official YouTube iframe player widget

## API Decisions

- `ExternalPlaybackScreen` receives the selected `AiSearchItem` from Discovery instead of refetching local store data. This preserves Phase 23 title, attribution, and embed metadata exactly.
- The YouTube path uses `EmbedKind.youtubeIframe` and `embedDescriptor.externalId`; no API key or platform data exchange is added.
- The AI-next rail calls `AiGatewayApi.runAiSearch` once with the current item's accurate-match label or original title. It excludes the currently playing item and does not use platform recommendations.
- Non-YouTube sources use `embedDescriptor.sourceUrl` through `url_launcher`; they are not embedded or re-syndicated.
- No Loom ad slot is rendered over or inside the external player. The compliance statement is outside the iframe frame.

## Validation Evidence

- Focused widget tests added in `apps/loom_demo/test/p24_external_playback_widget_test.dart`.
- Integration smokes added in `apps/loom_demo/integration_test/it_p24_external_playback.dart`.

## Follow-Up For Later Phases

- Phase 25 should route creator-linked external feed items into this same external playback surface.
- Phase 26 should manually verify live YouTube playback on emulator and physical phone with network available.
