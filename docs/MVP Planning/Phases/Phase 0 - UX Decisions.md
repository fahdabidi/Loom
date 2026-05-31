# Phase 0 — UX Decisions

## Reference sources reviewed

- [Material Design layout guidance](https://m2.material.io/design/layout/understanding-layout.html) for mobile spacing, app bars, responsive regions, and consistent layout structure.
- [TikTok accessibility guidance](https://www.tiktok.com/accessibility) for screen-reader-aware feed navigation, readable text, and media accessibility expectations.
- [TikTok modular viewing experience notes](https://newsroom.tiktok.com/new-features-bring-tiktok-magic-to-desktop?lang=en&pubDate=20250227) for low-distraction content exploration and persistent navigation.
- [WhatsApp design principles from Meta](https://about.fb.com/br/news/2024/05/mantendo-o-whatsapp-moderno-simples-e-acessivel/) for keeping mobile flows simple, reliable, private, and natural to the device.
- [Facebook mobile timeline engineering note](https://engineering.fb.com/2012/01/19/core-infra/under-the-hood-mobile-timeline/) for adapting rich social content to constrained mobile screens.
- Public YouTube/YouTube Studio mobile references, including [YouTube Studio Android navigation help](https://support.google.com/youtubecreatorstudio/answer/7548152?co=GENIE.Platform%3DAndroid&hl=en), for creator/fan role separation and scan-first content management patterns.

## UX patterns extracted

- Keep primary mobile surfaces immediately usable: compact top app bar, icon actions, bottom navigation, and live content should be visible without explanatory text.
- Use a persistent bottom navigation bar for Fan App and Creator Studio, backed by a compact account/role chip. This follows modern social-app structure without letting role switching dominate the screen.
- Favor visual-first feed cards: poster area, content type badge, creator avatar/handle row, title, summary, and icon actions should scan like a social/video app rather than a form demo.
- Keep loading and pagination explicit. The proof slice should show a progress state for the first page and a clear "Load more" affordance for cursor pagination.
- Use restrained platform-native visual language: Material components, stable spacing, rounded media cards, strong hierarchy, and no branded imitation of the reference apps.
- Preserve accessibility fundamentals from the beginning: semantic text, normal text scaling behavior, button labels, and no critical information encoded only in color.

## Key UX decisions

- The app opens directly into the usable Fan App proof slice rather than a landing page. Phase 0's job is to prove the contract-to-UI path, so the first screen shows real seeded content plus a modern setup prompt.
- The shell now uses a Loom-branded top bar, search/notification icon affordances, compact role/account chip, and bottom navigation for Fan App and Creator Studio.
- The Creator Studio side is reachable through the bottom nav. Full creator onboarding starts in Phase 1, but the shell already supports the author-to-consume role loop.
- Content cards render only fields returned by `ContentSummaryView`: creator display name, content type, title, and required summary. This reinforces the API provenance rule.
- Seed `thumbnailRef` values are rendered as generated demo posters so the feed is media-first without introducing external assets.
- The proof slice uses manual cursor pagination through "Load more" instead of infinite scroll. This makes pagination testable and visible during the demo.

## Key implementation decisions

- `feature_creator_channel` owns the Phase 0 proof screen, notifier, and DTO-to-view-model mapper.
- Features resolve only abstract contracts from `loom_app_shell`; they do not import `loom_fake_backend`, `loom_local_store`, or other features.
- `CreatorMetadataFake` implements `CreatorMetadataApi.getPublicCatalog` and reads Drift-backed store tables through `DemoLocalStore`.
- `DemoLocalStore` uses Drift/SQLite for app runs and an in-memory Drift database for widget/integration tests. The persistent app path uses a foreground `NativeDatabase` open to avoid emulator startup hangs.
- `seedV1` in `loom_seed_data` is the authoritative generated seed representation for Phase 0. JSON files under `assets/seed/` are retained as human-readable seed mirrors and can become the loader source in a later seed-data hardening pass.
- Boundary checks live in `packages/tooling/loom_lints` and are exposed through `melos run lint:boundaries`.
- The refreshed shell and feed stay inside `loom_design_system` and `loom_app_shell`; feature code still only maps contract DTOs into view models.

## Workflow walkthrough

1. The app starts in the Fan App role and shows the modern Loom shell, setup prompt, topic rail, and seeded creator catalog for Solar Sarah.
2. The content-list screen calls `CreatorMetadataApi.getPublicCatalog` with a bounded page size.
3. `CreatorMetadataFake` reads `creators` and `content_items` from the local Drift store and returns a `Page<ContentSummaryView>`.
4. The feature mapper converts each DTO into a tile view model using only response fields, including `thumbnailRef`.
5. The list renders media-first content cards with generated posters, creator name, title, summary, type label, and familiar social action icons.
6. The user taps "Load more" to request the next cursor page, proving the UI does not fetch all data at once.
7. The user switches between Fan App and Creator Studio through bottom navigation or the compact account chip, proving the shared shell and role-surface swap are stable.

This is the best Phase 0 UX shape because it keeps the UI testable and honest while no longer feeling like a basic scaffold: every visible content field comes from the API contract, but the shell, navigation, and feed now match modern social-app expectations.

## Open questions / tradeoffs

- Phase 3 may replace manual "Load more" with feed-style pagination or infinite scroll, but Phase 0 keeps the pagination gate explicit for validation.
- JSON seed assets should either become the canonical loader input or be generated from `seedV1` to avoid long-term duplication.
- Phase 3 should decide whether the poster-title duplication remains desirable for discovery cards or becomes watch/detail-only metadata.
