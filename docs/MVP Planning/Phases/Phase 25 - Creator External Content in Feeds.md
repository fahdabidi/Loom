# Phase 25 — Creator External Content in Feeds

**Surface:** both (Creator Studio + Fan render) · **UX gate:** HIGH · **On green:** AUTO → Phase 26
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 24. Lets a creator **link external content** (YouTube now;
> twitch/discord/blog/webpage modeled generically) into their channel / recommendation feed from Creator
> Studio. External items render as **native tiles** in the main feed and channel (unaltered thumbnail + source
> chip) and play via the embedded player (Phase 24) for YouTube, or open externally for other sources. Reuses
> `ExternalContentReferenceSchema` and the `CreatorExperienceConfig` content modules.

## 0. Prerequisite gate (validate Phase 24 done)
README gate + confirm Phase 24 committed/recorded: embedded YouTube player + AI-next rail work; external title
compliance holds; Phase 24 integration tests pass.

## 1. Workflows & user stories in this phase
- **CE-S14 / link external content** — In Creator Studio, a creator adds an external item (paste a YouTube URL/ID
  now; generic source picker for twitch/discord/blog/webpage) to their channel/recommendation feed, with an
  optional creator note; the creator sets `searchIndexable`/`aiQueryable`.
- **CE-S14 / native render** — The linked item appears as a **native tile** in the main feed + channel (unaltered
  thumbnail + source chip + creator note), consistent with Loom styling.
- **CE-S14 / playback** — Tapping a linked YouTube tile uses the Phase 24 embedded player; non-YouTube opens externally.
- Compliance: creator-linked external items follow the same rules (unaltered title/thumbnail, attribution, official player).

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of: the Studio link-external flow, and an external tile rendered in a creator's feed.

## 2A. UX reference research & decision output
Record in [Phase 25 - UX Decisions.md](./Phase%2025%20-%20UX%20Decisions.md):
- Creator "add link/embed" flows (paste URL → resolve preview → confirm) in creator tools.
- Native rendering of third-party media as first-class feed tiles with clear source attribution.
- Generic source handling (so the same flow covers youtube/twitch/discord/blog/webpage).

Apply the shared Studio baseline plus: the link flow resolves a preview (thumbnail/title) and shows the source +
compliance note; the rendered tile matches native content tiles but carries a source chip; creator note is additive
and clearly the creator's voice (not a replacement of the platform title).

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse Phase 21:
- **External Content Source API:** resolve a pasted URL/ID → `ExternalContentCandidate` + `embedDescriptor` + preview.
- **Creator Metadata API:** persist the external content reference as **feed** content on the channel (reuse
  `ExternalContentReferenceSchema`); place it within a `CreatorExperienceConfig` content/feed module.
- **Recommendation & Referral API:** include creator-linked external items in the channel's recommendation feed.

## 4. Data storage (local store)
Reuse `public_imported_references` (+ the Phase 21 `embed_kind`/`source_attribution` columns) for creator-linked
external content; link to the channel + the relevant surface module. Confirm `resetDemo()` restores seeded links
and clears creator-added ones.

## 5. Source files & components to create/update
- Design system: `studio/link_external_sheet.dart` (paste/resolve/confirm + source picker + indexable/AI toggles),
  reuse Phase 24 `external_source_banner` / tile styling for the rendered feed tile.
- `features/creator/feature_creator_publishing` (extend) or `feature_creator_customize`: the link-external action + management.
- `features/fan/feature_creator_channel` + `feature_discovery`: render external tiles inside the channel/feed via the existing surface-module renderer (Phase 16).

## 6. API best-practice checks (phase-specific)
- Link create is **idempotent**; resolve is bounded (one preview fetch); reference stored with provenance + `rightsBasis`.
- Rendered external tiles keep **unaltered title + thumbnail** + source attribution; creator note is additive.
- `searchIndexable`/`aiQueryable` are respected by search/AI (ties to Phases 21/23).
- No re-syndication/storage beyond the reference + public preview; YouTube uses the official player on tap.

## 7. Component boundary / design checks
- Link/resolve UI in `loom_design_system`; persist/manage logic in the creator feature; render via the existing module renderer.
- No feature→feature/fake/store imports; `lint:boundaries` clean; charters updated.

## 8. Automated validation checks
README baseline plus unit/widget tests: paste→resolve→persist an external reference; rendered tile shows unaltered
title/thumbnail + source chip + creator note; indexable/AI toggles persist and gate search/AI inclusion; idempotent link create.

## 9. Integration tests
- `it_p25_link_external` — Creator links a YouTube video in Studio; it persists as feed content on the channel.
- `it_p25_render_external_tile` — The linked item renders as a native tile in the creator's channel/feed with source attribution.
- `it_p25_play_linked_external` — Tapping the linked YouTube tile opens the Phase 24 embedded player.

## 10. Definition of done
A creator can link external content (YouTube now; generic source model) into their channel/recommendation feed;
it renders as a native tile (unaltered title/thumbnail + source chip + creator note) and plays via the embedded
player (YouTube) or opens externally; indexable/AI toggles respected; compliance holds; all checks + integration
tests green; screenshots captured. [Phase 25 - API Review.md](./Phase%2025%20-%20API%20Review.md) and
[Phase 25 - UX Decisions.md](./Phase%2025%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 25 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 26 — Gaming Seed, Full AI-Search Showcase & Final Physical-Phone Validation](./Phase%2026%20-%20Gaming%20Seed%20Showcase%20and%20Final%20Validation.md).**
