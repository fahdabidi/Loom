# Phase 2 — Creator Publishing & Monetization Setup

**Surface:** Creator Studio · **UX gate:** HIGH · **On green:** STOP for manual UX validation
**Shared conventions:** [README.md](./README.md). This doc adds Phase-2 specifics.

## 0. Prerequisite gate (validate Phase 1 done)
README gate + confirm: a creator channel exists from Phase 1 (`CreatorChannel` + manifest), fan passport + interest profile exist, Phase 1 integration tests pass. This phase **produces the live content/policies** later phases consume, so the channel must be real.

## 1. Workflows & user stories in this phase
- **CE-S2** — Publish multi-format content (scope: video + post).
- **CE-S2A (MISSING-S3)** — Publish requires a creator-approved `ContentManifest.summary`.
- **CE-S2B (MISSING-S5)** — Import existing catalog (async import job → `ExternalContentReferenceSchema`).
- **CE-S3** — Membership tiers + member-only content.
- **CE-S3B (MISSING-S1)** — Set `CreatorAdPolicy` (allow/block categories/brands).
- **CE-W7** — Enable AI archive Q&A / summaries (`AIContentPolicy`).
- Backing workflows: Doc 04 Workflow 2 (publish), Doc 09 Workflow 1 (configure monetization).

## 2. Tools (WSL Ubuntu)
Standard set. Add a tiny local media fixture for ingest simulation (no real transcoding).

## 2A. UX reference research & decision output
Before implementing Creator Studio publishing and monetization UX, review reference mockups and design guidance from popular creator/social products such as YouTube Studio, Instagram, TikTok, Facebook/Meta creator tools, WhatsApp Channels where relevant, and adjacent creator-dashboard products. Focus on publish composers, required summaries/descriptions, catalog import flows, membership tier setup, ad-policy controls, AI enablement controls, validation states, and creator-facing dashboard density.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 2 specifics:
- Make Creator Studio a compact work dashboard with task/status cards, draft state, channel/content preview, and a visible publish path instead of a sparse form page.
- Model the publish composer after modern social upload flows: media preview first, title/summary fields next, validation inline, and a sticky publish/save action.
- Use stepper or bottom-sheet flows for catalog import, membership tiers, ad policy, and AI enablement so advanced controls do not crowd the main Studio surface.
- Include real or generated media thumbnails/posters for every draft/imported item; do not represent content only with text labels.

Create [Phase 2 - UX Decisions.md](./Phase%202%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented Studio UX demonstrates publishing, import, monetization, ad policy, and AI setup workflows using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Creator Metadata API:** `publishContent` (creates `ContentManifest`, **rejects if `summary` missing** → `ApiError code=summary_required`), `updateMonetizationManifest`, `setCreatorAdPolicy`, `setAIContentPolicy`, `defineMembershipTiers`. Extend `CreatorMetadataFake`.
- **Content Host API:** `ingestMedia`/`createPlaybackAsset`, `getContentPerformanceMetadata`. Fake: `ContentHostFake`.
- **Migration & Export API:** `startImportJob`, `getImportJob` (async status). Fake: `MigrationExportFake`.
- **Entitlement Ledger API:** register membership-tier entitlement definitions. Fake: `EntitlementLedgerFake`.
- **AI Gateway API (optional draft):** `generateSummaryDraft` for the composer. Extend `AiGatewayFake`.

## 4. Data storage (local store)
Extend `content` (accessMode, monetizationMode, aiPolicyRef, searchPolicyRef, isExternalRef). New tables: `monetization_manifests`, `creator_ad_policies(allow[], block[], formats[], surfaces[])`, `membership_tiers`, `ai_content_policies`, `import_jobs(state, sourcePlatform, items[])`, `external_content_refs`, `content_perf`. Seed: ad-category vocabulary; a sample external export file fixture for import.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: extend `creator_metadata_api.dart`; fill `content_host_api.dart`, `migration_export_api.dart`, `entitlement_ledger_api.dart`. Models: `ContentManifest` (required `summary`), `MonetizationManifest`, `CreatorAdPolicy`, `MembershipTier`, `AIContentPolicy`, `ImportJob`.
- `core/loom_fake_backend/`: extend `creator_metadata_fake.dart`; add `content_host_fake.dart`, `migration_export_fake.dart`, `entitlement_ledger_fake.dart`.
- `core/loom_design_system/components/studio/`: `publish_composer.dart` (with **required summary field + validation**), `ad_policy_editor.dart`, `monetization_editor.dart`, `import_wizard.dart`.
- `features/creator/feature_creator_publishing/`: screens `publish_composer`, `catalog_import`; state; mappers; `CHARTER.md`.
- `features/creator/feature_creator_monetization/`: screens `membership_tiers`; state; `CHARTER.md`.
- `features/creator/feature_creator_ads/`: screen `ad_policy_editor`; state; `CHARTER.md`.
- `features/creator/feature_creator_ai/`: screen `ai_enable` (`AIContentPolicy`); state; `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- `publishContent` **idempotent** + writes a versioned manifest (`schemaVersion`); republish bumps version, no dup.
- **Summary-required** enforced server-side (fake returns `ApiError`) **and** client-side.
- Catalog **import is async**: client polls `getImportJob` with **backoff** (no tight loop); UI shows progress — verify cadence.
- Write payloads are **minimal/diff-based** (don't resend unchanged manifest fields).
- `getContentPerformanceMetadata` returns aggregate fields only (no per-fan data).

## 7. Component boundary / design checks
- All four creator features import only contracts + design_system + app_shell.
- Studio composer/editor components live in `loom_design_system/components/studio/`, contain no API calls (pure presentational + callbacks).
- `melos run lint:boundaries` clean.

## 8. Automated validation checks
README baseline. Unit tests: summary-required validation, manifest version bump, ad-policy serialization, import-job state machine.

## 9. Integration tests
- `it_p2_publish_requires_summary` — publish without summary → `summary_required`; with summary → succeeds, manifest v1 stored.
- `it_p2_catalog_import` — start import → poll → external refs appear in catalog with summaries required before search/AI eligibility.
- `it_p2_membership_setup` — define tiers → entitlement definitions registered.
- `it_p2_ad_policy` — set allow/block → `CreatorAdPolicy` persisted and queryable.
- `it_p2_ai_enable` — enable Q&A/summaries → `AIContentPolicy` stored.

## 10. Definition of done
Creator can publish video + post (summary required), import a catalog, define memberships, set an ad policy, and enable AI — all on the Flutter Android emulator, idempotent, versioned; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 2 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 2 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
**STOP for manual UX validation.** The publish composer (esp. the **required-summary** UX and ad-policy editor) shapes `ContentManifest`/`CreatorAdPolicy`/monetization write APIs. Get human sign-off on: composer flow, summary capture (manual vs AI-draft), ad-policy editor, membership setup. After sign-off, proceed to [Phase 3 — Discovery Core](./Phase%203%20-%20Discovery%20Core.md).
