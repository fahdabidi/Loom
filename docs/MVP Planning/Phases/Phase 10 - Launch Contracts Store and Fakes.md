# Phase 10 — Launch Contracts, Store & Fakes

**Surface:** core · **UX gate:** low (API/data foundation only) · **On green:** AUTO → Phase 11
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution. This phase starts the launch-demo sequence from the
> [MVP Gap Analysis — Launch Scope](../../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md)
> by implementing the typed API contracts, Drift/local-store state, fake backend behavior, and seed
> data required by Phases 11-14. It deliberately avoids building the main user-facing launch UX so
> contract correctness, idempotency, persistence, and provenance are validated before screens depend
> on them.

## 0. Prerequisite gate (validate Phase 9 emulator gates)
README gate + confirm the full Phase 0-9 demo is green on the Flutter Android emulator: author→consume
loop, recommendations & referral (Phase 8), wallet/settlement (Phase 6), data-for-value (Phase 7), and
export/reset (Phase 9). Phase 9 changes must be committed and recorded in the tracker.

## 1. Workflows & user stories in this phase
This phase is the contract/data foundation for:
- **CE-S10 foundation** — Creator re-acquisition funnel contract state: templates, link-in-bio,
  capture links, QR payload data, external account references, and cross-post delivery status.
- **FE-S13 foundation** — Starter-pack contract state: source creator, recommended creators,
  toggleable members, and idempotent bulk-follow write path.
- **CE-S11 foundation** — Conversion-yield analytics contract state: reached → re-followed → member
  → premium aggregates, sourced from capture, follow, entitlement, and wallet state.
- **Single-player utility foundation** — Public catalog import, ad-policy versioning, premium no-ad,
  and contextual ad-decision surfaces needed by Phase 13.

No new fan or creator screen is required in Phase 10 beyond keeping the app bootable. The phase should
prove the APIs and fake backend can support the later UX without magic values.

## 2. Tools (WSL Ubuntu)
Standard set. Run Drift generation after schema changes:
- `dart run build_runner build --delete-conflicting-outputs` in `app/packages/core/loom_local_store`
- `melos bootstrap` after new package exports or dependencies

No network is required. QR code rendering is deferred to Phase 11; this phase only stores the QR/capture
payload data.

## 2A. UX reference research & decision output
This is a low-UX phase, but it still creates [Phase 10 - UX Decisions.md](./Phase%2010%20-%20UX%20Decisions.md)
because API/data choices shape future screens.

Review reference patterns only to extract data requirements, not visual implementation:
- Bluesky Starter Packs: starter-pack composition, recommended account lists, bulk follow, and
  re-opening behavior.
- Linktree/link-in-bio and QR follow flows: fields needed for preview cards, destination links, and
  attribution channel labels.
- YouTube Studio / Patreon analytics: aggregate funnel fields and trend windows.
- Google/YouTube public-metadata imports: import-job status, provenance, and external references.

Decision doc must record:
- Which fields are persisted versus computed.
- How capture links and starter packs stay idempotent.
- How conversion analytics avoids per-fan behavioral rows or universal fan IDs.
- Which API fields are needed by Phases 11-14 and which OpenAPI gaps, if any, were found.

## 3. APIs invoked & stubs to implement
Implement typed Dart client interfaces and models matching the OpenAPI specs already added to `docs/API/OpenAPI/**`.

New clients:
- **Fan Follow Capture API:** `createCaptureLink`, `resolveCaptureLink`, `recordReFollow`.
- **Creator Announcement API:** `listTemplates`, `renderAnnouncement`, `getLinkInBio`.
- **Starter Pack API:** `getStarterPack`, `bulkFollow`.
- **Audience Analytics API:** `getConversionFunnel`.
- **External Account Link API:** `listExternalAccounts`, `verifyExternalAccount`, `unlinkExternalAccount`
  or the nearest spec-defined methods.
- **Import Public Metadata API:** import-job creation/status/result mapping.
- **Cross-Posting API:** cross-post request/status stub; no real external publishing.
- **Ad Decision API:** contextual ad decision and impression recording shape.
- **Premium No-Ad API:** no-ad entitlement status and qualifying no-ad consumption shape.

Reuse/extend:
- **Creator Metadata API:** ad-policy and membership tier persistence where existing contracts own it.
- **Fan Passport API:** bulk-follow writes must still honor follow visibility and pairwise identity.
- **Entitlement Ledger / Fan Wallet / Recommendation & Referral:** funnel and starter pack read paths.

Fake implementations:
- Add one fake per new API surface in `core/loom_fake_backend`.
- Register every new fake in `apps/loom_demo/lib/main.dart`.
- Fakes must read/write `loom_local_store` and simulate latency/error/idempotency semantics like earlier phases.

## 4. Data storage (local store)
Add Drift tables or extend existing ones:
- `capture_links`: token, creatorId, channel, destination, createdAt, expiresAt, idempotencyKey.
- `re_follow_events`: captureLinkId, fanId or pairwise actor id, creatorId, channel, createdAt,
  idempotencyKey, visibility policy reference.
- `announcement_templates`: templateId, title, channel, bodyTemplate, variables, active.
- `rendered_announcements`: renderedId, creatorId, templateId, body, link, qrPayload, idempotencyKey.
- `link_in_bio_pages`: creatorId, headline, links, captureToken, updatedAt.
- `starter_packs`: creatorId, title, description, memberIds, defaultSelectedIds, updatedAt.
- `bulk_follow_jobs` or equivalent dedupe table for starter-pack idempotency.
- `external_accounts`: creatorId, platform, handle, verifiedStatus, publicUrl, provenance.
- `public_metadata_import_jobs`: jobId, creatorId, sourcePlatform, status, discoveredRefs, importedRefs.
- `cross_post_jobs`: jobId, renderedAnnouncementId, targetPlatform, status, deliveryUrl.
- `ad_policy_versions` if not already represented strongly enough for Phase 13.
- `ad_decisions` / `ad_impressions` and `premium_no_ad_events` if needed for ad/no-ad provenance.

Keep seeded data vertical-agnostic and reuse the existing mixed creator world.

## 5. Source files & components to create/update
API contracts:
- `core/loom_api_contracts/lib/clients/fan_follow_capture_api.dart`
- `core/loom_api_contracts/lib/clients/creator_announcement_api.dart`
- `core/loom_api_contracts/lib/clients/starter_pack_api.dart`
- `core/loom_api_contracts/lib/clients/audience_analytics_api.dart`
- `core/loom_api_contracts/lib/clients/external_account_link_api.dart`
- `core/loom_api_contracts/lib/clients/import_public_metadata_api.dart`
- `core/loom_api_contracts/lib/clients/cross_posting_api.dart`
- `core/loom_api_contracts/lib/clients/ad_decision_api.dart`
- `core/loom_api_contracts/lib/clients/premium_no_ad_api.dart`

Models:
- `CaptureLink`, `ResolvedCaptureLink`, `ReFollowReceipt`
- `AnnouncementTemplate`, `RenderedAnnouncement`, `LinkInBioPage`, `CrossPostJob`
- `StarterPack`, `StarterPackMember`, `BulkFollowResult`
- `ConversionFunnel`, `ConversionFunnelStep`, `ConversionTrendPoint`
- `ExternalAccount`, `PublicMetadataImportJob`, `ImportedContentReference`
- `AdDecision`, `AdPolicyVersion`, `PremiumNoAdStatus`

Fake backend/local store:
- Add matching fake files and exports in `loom_fake_backend`.
- Extend `loom_local_store` schema and generated Drift code.
- Add seed loader entries only where needed for templates/starter packs.

No new design-system component is required in this phase unless a tiny debug/state fixture is needed for tests.

## 6. API best-practice checks (phase-specific)
- Capture-link create, rendered announcement create, import-job create, cross-post create, and bulk-follow
  are idempotent by idempotency key.
- `resolveCaptureLink` is read-only and never records a follow by itself.
- `recordReFollow` emits an audit-class event, not an economic receipt.
- `bulkFollow` dedupes existing follows and reports created/skipped counts.
- `getConversionFunnel` returns aggregates only; no per-fan list, no universal fan IDs.
- Starter packs reuse Phase 8 creator recommendations; do not create a second ranking system.
- Public-metadata import stores provenance and imported references, not scraped private data.
- Ad decisions are contextual and creator-policy aware; no behavioral-targeting fields.

## 7. Component boundary / design checks
- `loom_api_contracts` remains pure Dart contracts/models.
- `loom_fake_backend` imports contracts + local store + seed data only.
- Features do not import the new fake files or local-store tables.
- `apps/loom_demo` is the only concrete DI binding location.
- Update affected package barrels and `CHARTER.md` files only where package scope changes.

## 8. Automated validation checks
README baseline plus focused unit tests:
- Capture-link create/resolve/re-follow idempotency.
- Announcement template rendering with missing/unknown variables handled.
- Starter-pack resolution from recommendation graph.
- Bulk-follow dedupe and visibility preservation.
- Conversion funnel aggregation math from capture/follow/entitlement/premium state.
- Public metadata import job state transition and provenance mapping.
- Cross-post stub job state transition.
- Ad-policy/ad-decision/no-ad eligibility shape and idempotent impression/no-ad event recording.
- Drift migration from the previous schema version and `resetDemo()` clearing Phase 10 mutable state.

## 9. Integration tests
- `it_p10_launch_contract_smoke` — app bootstraps with all new fakes registered, creates a capture link,
  resolves it, renders an announcement, resolves a starter pack, performs bulk follow, and reads the
  conversion funnel without opening a dedicated Phase 11-13 UI.
- `it_p10_reset_launch_state` — after creating launch state, `resetDemo()` clears mutable capture/follow/import
  jobs and restores seed templates/starter packs.

## 10. Definition of done
All Phase 10 typed clients, models, local-store tables, fake implementations, DI registrations, seed entries,
and tests are complete. The app still boots on the Flutter Android emulator. No main launch UX is required yet.
`melos bootstrap`, Drift generation, `melos run analyze`, `melos run lint:boundaries`, `melos run test`,
focused Phase 10 integration tests, full integration suite, debug APK build, emulator install, and app launch
are green. [Phase 10 - API Review.md](./Phase%2010%20-%20API%20Review.md) and
[Phase 10 - UX Decisions.md](./Phase%2010%20-%20UX%20Decisions.md) are filed. Update the Phase completion
tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 10
status, completion date, API review link/name, gate evidence, and commit SHA.

## 11. Next phase
After Phase 10 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 11 — Creator Launch Funnel.md](./Phase%2011%20-%20Creator%20Launch%20Funnel.md).**
