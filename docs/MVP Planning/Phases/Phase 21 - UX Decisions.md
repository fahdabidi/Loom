# Phase 21 - UX Decisions

## Data Requirements Extracted From UX Patterns

Modern social apps keep connected-service settings explicit, reversible, and scoped. Phase 21 persists the minimum state later UX needs: provider, endpoint, connected flag, source toggles, source display labels, and last-updated timestamps.

Mixed-source result lists need clear attribution and must not make third-party content look native-owned. Phase 21 keeps `sourceAttribution`, original title, original thumbnail reference, and source URL on every external candidate.

External media playback must use the official platform player when embedded. Phase 21 stores `embedKind` so Phase 24 can route YouTube references to an unobscured IFrame player and route non-YouTube references to a link/open flow.

## Compliance Decisions

- AI “accurate match” wording is additive and separate from the external title.
- External title and thumbnail metadata remain unaltered in storage and API responses.
- Ranking reasons disclose that the fan’s agent ranked the result and that there is no paid placement.
- `ai_search_runs` is audit-only transparency state, not an ad or revenue event.

## Workflow Impact

- Phase 22 can render a Settings screen with disconnected defaults, provider selection, YouTube connect state, and query-egress disclosure.
- Phase 23 can render creator and external results with distinct source chips and accurate-match labels.
- Phase 24 can open YouTube items in an official embed using `EmbedDescriptor`.
- Phase 25 can persist creator-linked external references through the same public-reference path used by seeded external content.
