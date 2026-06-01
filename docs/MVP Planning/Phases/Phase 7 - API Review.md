# Phase 7 - API Conformance And Efficiency Review

## Scope

Phase 7 implemented fan data-rights controls, creator audience grant requests, permissioned audience reads, category defaults, relationship-contact revocation, tombstones, ad preference writes, and data access receipts.

## APIs Reviewed

- `CreatorAudienceApi`: `createDataGrantRequest`, `pendingGrantRequests`, `queryPermissionedInterestData`, `getAudienceInsights`, `dataAccessReceipts`.
- `FanPassportApi`: `reviewDataGrantRequest`, `narrowGrant`, `revokeGrant`, `setCategoryDefault`, `revokeDirectContact`, `requestTombstone`.
- `FanVaultApi`: added `putAdPreferences` for fan ad preference changes.
- `loom_local_store`: Drift schema version 8 adds audience grant requests, data consent grants, category defaults, data access receipts, and tombstones.

## Findings

| Area | Result | Evidence |
| --- | --- | --- |
| Grant lifecycle | Pass | Creator requests are persisted, fan review supports approve/deny/narrow, and revoked grants stop future data reads. Covered by `p7_data_rights_api_test.dart` and `it_p7_interest_grant` / `it_p7_revoke`. |
| Minimal field exposure | Pass | `queryPermissionedInterestData` returns only approved fields. Narrowing to `interest_categories` excludes `interest_tokens`. |
| Data access receipts | Pass | A `DataAccessReceipt` is emitted only on actual approved data access, not on denied/revoked/no-permission reads. |
| Category defaults | Pass | `setCategoryDefault` can auto-deny matching future creator grant requests. Covered by `it_p7_category_default`. |
| Relationship controls | Pass | Direct-contact revocation sets relationship visibility private and tombstone requests are persisted. Covered by `it_p7_relationship_controls`. |
| Audience dashboard efficiency | Pass | Creator dashboard uses one aggregate `getAudienceInsights` read and one explicit permissioned data read instead of per-field calls. |
| Idempotency | Pass | Grant request, review, narrow, revoke, category default, tombstone, and data access receipt writes use idempotency keys in the fake backend/local store. |

## API Shape Decisions

- Kept creator audience reads explicit: aggregate insights and permissioned fan data are separate calls so the UI cannot accidentally pull fan-level fields while loading a dashboard.
- Modeled pending grant requests separately from reviewed grants. This keeps fan review queues simple and lets reviewed grant state remain auditable.
- Data access receipts are created by the store only when approved fields are actually returned.
- Category defaults use the creator vertical from the creator record, so future real APIs can apply defaults without client-side category guessing.
- Relationship controls remain on `FanPassportApi` because they change fan-to-creator relationship visibility rather than audience analytics.

## Spec Follow-Ups

- OpenAPI should model `DataGrantRequest`, `DataConsentGrant`, `CategoryDefault`, `DataAccessReceipt`, `PermissionedInterestData`, `AudienceInsight`, and `TombstoneRequest`.
- `queryPermissionedInterestData` should explicitly document that empty `fields` means no approved access and does not emit an access receipt.
- `reviewDataGrantRequest` should define allowed state transitions and reject unsupported transitions in the real API.
- Audience insight responses should keep aggregate metrics compact and avoid returning fan identifiers.

## Verification

- `melos bootstrap`
- Drift generation: `dart run build_runner build --delete-conflicting-outputs`
- `melos run analyze`
- `melos run lint:boundaries`
- `melos run test` (23 tests)
- Focused Phase 7 integration tests (4/4) on `emulator-5554`
- Full `melos run test:integration` (31/31) on `emulator-5554` from a WSL-native mirror of the same `app/` tree to avoid OneDrive Gradle asset lock races
- `flutter build apk --debug`
- `adb install -r`
- App launch and screenshot: `data/validation/phase7-manual-checkpoint.png`
