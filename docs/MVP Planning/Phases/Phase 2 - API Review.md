# Phase 2 - API Conformance & Efficiency Review

Date: 2026-05-31

## Scope

Phase 2 added the Creator Studio publishing setup surface over typed contracts and fake implementations:

- `CreatorMetadataApi`: `publishContent`, `updateMonetizationManifest`, `defineMembershipTiers`, `setCreatorAdPolicy`, `setAIContentPolicy`, readbacks for manifests, tiers, ad policy, and AI policy.
- `ContentHostApi`: `ingestMedia`, `createPlaybackAsset`, `getContentPerformanceMetadata`.
- `MigrationExportApi`: `startImportJob`, `getImportJob`.
- `EntitlementLedgerApi`: `registerMembershipTierDefinitions`, `entitlementDefinitions`.
- `AiGatewayApi`: `generateSummaryDraft`.

## Conformance Notes

- Publish requires `ContentManifest.summary`; the fake returns `ApiError(code: summary_required)` when a creator tries to publish without one.
- UI request fields are sourced from creator-entered form state, generated summary draft output, or the Phase 1 channel id. No feature code imports the fake backend or local store.
- Creator-authored content writes to Drift/SQLite through the fake backend and can later be consumed through the same Creator Metadata catalog path as seeded content.
- Catalog import is modeled as an async job. The UI starts the import, waits before polling once, and receives `ExternalContentReference` records with summaries.
- Membership tiers are mirrored into entitlement definitions so later wallet/playback phases can check member access without reading Studio-only state.
- `CreatorAdPolicy` and `AIContentPolicy` persist as channel-scoped policy documents.

## Efficiency Notes

- Writes use idempotency keys and fake-store idempotency records.
- Phase 2 UI batches the membership tier setup into one `defineMembershipTiers` call and one entitlement registration call.
- `getContentPerformanceMetadata` exposes aggregate metrics only; it does not expose per-fan behavior.
- Import polling is not a tight loop. The demo uses one delayed poll because the fake import completes deterministically.
- The Studio screen refreshes its read model after publish/import/setup writes. This is acceptable for the demo, but a real API should return enough post-write state to avoid extra readbacks where possible.

## Findings

- A future edit endpoint should be explicit, for example `updateContentManifest`, to bump `schemaVersion` for republishing an existing content id. `publishContent` correctly dedupes by idempotency key; it is not the right contract for edit/version bumps.
- `ImportJob` should include a server-provided `pollAfterMs` or equivalent backoff hint before real HTTP implementation.
- `CreatorAdPolicy` currently covers categories, formats, and surfaces. If brand-specific allow/block is required, the OpenAPI schema should add brand identifiers separately from category strings.
- AI summary drafting and AI archive enablement are separate product actions and should remain separate API surfaces in the real implementation.

## Validation

- `melos run analyze`
- `melos run lint:boundaries`
- `melos run test`
- `melos run test:integration` on `emulator-5554`
- Focused Phase 2 integration group: `flutter test integration_test/it_p2_*_test.dart -d emulator-5554`
