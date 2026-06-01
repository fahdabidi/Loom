# Phase 9 - API Review

## Scope

Phase 9 closes the demo with export/portability, fan and creator transparency, reset orchestration, and full-demo validation.

## Contract Changes

- `MigrationExportApi.createExportJob` creates an async creator export job.
- `MigrationExportApi.getExportJob` advances/polls export status and returns the completed bundle.
- `MigrationExportApi.resetDemo` restores seed v1 for the demo menu.
- `ExportJob`, `ExportJobState`, `ExportBundle`, and `ExportBundleSection` model queued, processing, and complete export states.

## Persistence

- Added `export_jobs` to Drift/SQLite with `state`, `pollCount`, `bundleRef`, and `bundleJson`.
- `resetDemo()` clears export jobs along with authored/payment/session state before reseeding.

## Bundle Contents

The export fake assembles a local JSON bundle from existing API-backed store rows:

- Creator/channel identity.
- Public creator content catalog.
- Creator-published content manifests.
- Creator transcripts.
- Receipt ledger rows tied to exported creator content.
- Creator payout/settlement history.
- Configured creator ad policy when present.

## Provenance

- Creator export screen fields come from `MigrationExportApi` job and bundle responses.
- Wallet supported-creators transparency comes from `SettlementEngineApi.getFanSubscriptionAllocation`.
- Creator revenue transparency continues to come from `SettlementEngineApi.getCreatorPayoutStatement`.
- Reset menu calls `MigrationExportApi.resetDemo` and rebuilds the active app surface from seed state.

## Efficiency And Correctness

- Export remains async: create job, then poll until completion.
- Bundle assembly is a single local read pass across existing store methods; no network or cloud dependency.
- Export job creation is idempotent by key.
- Reset is intentionally non-idempotency-preserving because a reviewer expects each reset action to restore seed v1.

## Validation

- Unit coverage: export bundle completeness and reset clearing authored payment state.
- Integration coverage: export flow, reset menu, author-to-consume loop, and six-step demo smoke flow.
