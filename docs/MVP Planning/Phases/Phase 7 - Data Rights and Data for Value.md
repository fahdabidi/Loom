# Phase 7 — Data Rights & Data-for-Value

**Surface:** both · **UX gate:** HIGH · **On green:** STOP for manual UX validation
**Shared conventions:** [README.md](./README.md).

## 0. Prerequisite gate (validate Phase 6 done)
README gate + confirm: consent baseline + interest/ad-preference profile exist (Phases 1, 5–6), creator audience surfaces have something to request against. Phase 6 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S6A / FE-W6A** — Creator interest-data grant request → fan approve / deny / narrow + category defaults (both sides).
- **FE-W7** — Fan revokes app/campaign/creator/provider access.
- **FE-W1A** — Fan limits/revokes creator relationship data (visibility, direct-contact, block, tombstone).
- **CE-S3A** — Creator uses permissioned audience data (aggregate/approved fields only).
- **AD-S3A (data-grant portion)** — sponsor-linked creator ad-relevance grant (campaign mechanics land Phase 8).

## 2. Tools (WSL Ubuntu)
Standard set.

## 2A. UX reference research & decision output
Before implementing data-rights and consent UX, review reference mockups and design guidance from popular social/privacy surfaces such as Facebook/Meta privacy controls, Instagram account/privacy settings, YouTube ad personalization/privacy controls, TikTok privacy controls, WhatsApp privacy/permissions flows, and adjacent consent-management products. Focus on consent request review, approve/deny/narrow flows, revocation, defaults by creator/category, data-access receipts, minimal-field disclosure, and how to keep privacy controls understandable on mobile.

Create [Phase 7 - UX Decisions.md](./Phase%207%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented UX demonstrates grant requests, narrowing, category defaults, revocation, relationship controls, and DataAccessReceipts using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Fan Passport API:** `createConsentGrant` / `narrowGrant` / `revokeGrant`, `setCategoryDefault`, `setFollowVisibility`, `revokeDirectContact`, `block`, `requestTombstone`. Extend `FanPassportFake`.
- **Creator Audience API:** `createDataGrantRequest`, `queryPermissionedInterestData` (returns **only approved creator-scoped fields or aggregates**), `getAudienceInsights` (aggregate). Fake: `CreatorAudienceFake` — implements the **Audience Data Firewall stricter-of** evaluation (privacy mode ∧ grant ∧ age/region ∧ block/dislike ∧ category default).
- **Fan Vault API:** `getAdPreferences` / `putAdPreferences`, interest read (reuse `FanVaultFake`).
- **Receipt Ledger API:** `DataAccessReceipt` emitted on **actual access**. Reuse `ReceiptLedgerFake`.

## 4. Data storage (local store)
New/extended tables: `consent_grants(type=creator_interest_data, fields[], purpose, retention, adUse, sponsorContext, state)`, `category_defaults`, `data_access_receipts`, `audience_grant_requests`, `ad_preferences`, `tombstones`. Firewall evaluation is a pure function over these.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: extend `fan_passport_api.dart`, `creator_audience_api.dart`, `fan_vault_api.dart`. Models: `ConsentGrant`, `CreatorInterestDataGrant`, `CategoryDefault`, `DataGrantRequest`, `DataAccessReceipt`, `AudienceInsight`.
- `core/loom_fake_backend/`: `creator_audience_fake.dart` (+ firewall evaluator); extend `fan_passport_fake.dart`, `fan_vault_fake.dart`.
- `core/loom_design_system/components/`: `consent_grant_card.dart` (approve/deny/narrow), `data_dashboard_row.dart`, `category_default_control.dart`, `studio/audience_panel.dart`.
- `features/fan/feature_data_rights/`: screens `data_and_ads_dashboard`, `grant_request_review`, `relationship_controls`; `data_rights_notifier`; `CHARTER.md`.
- `features/creator/feature_creator_audience/`: screens `audience_insights`, `request_interest_data`; `audience_notifier`; `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- **Grant lifecycle idempotent:** create/narrow/revoke use `Idempotency-Key`; re-submit is safe.
- **`DataAccessReceipt` on actual access**, not on grant creation — verify it is emitted when `queryPermissionedInterestData` returns data, with actor/grant/fields/purpose.
- **Stricter-of firewall** correctly applied: a query returns the **intersection** of all constraints; add tests for conflicting constraints.
- **Minimal field exposure:** permissioned queries return **only** approved creator-scoped fields or aggregates — never raw private behavior or universal fan ids. Verify payload.
- Revocation **blocks future access** while retaining required historical receipts.

## 7. Component boundary / design checks
- `feature_data_rights` and `feature_creator_audience` import only contracts + design_system + app_shell.
- Firewall logic lives entirely in `loom_fake_backend` (server side); features never evaluate firewall rules locally.
- `melos run lint:boundaries` clean.

## 8. Automated validation checks
README baseline. Unit tests: firewall stricter-of (incl. conflicting constraints), grant narrow/revoke transitions, DataAccessReceipt-on-access, minimal-field projection.

## 9. Integration tests
- `it_p7_interest_grant` — creator requests interest data → fan approves & narrows fields → creator query returns **only** approved fields + `DataAccessReceipt` written.
- `it_p7_revoke` — fan revokes → subsequent creator query returns nothing new; past receipts retained.
- `it_p7_category_default` — fan sets a creator-category default → matching future requests auto-handled per default.
- `it_p7_relationship_controls` — change visibility / block / request tombstone → future eligibility recalculated (FE-W1A).

## 10. Definition of done
Creator can request interest data; fan can approve/deny/narrow + set category defaults + revoke; firewall enforces stricter-of and minimal exposure; DataAccessReceipts on access; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 7 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 7 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
**STOP for manual UX validation (HIGH).** The consent model shapes Passport/Vault/Audience/Firewall contracts and the data-for-value UX. Get human sign-off on: grant-request review UX, category defaults, dashboard clarity, relationship controls. After sign-off, proceed to [Phase 8 — Recommendations, Campaigns & Referral](./Phase%208%20-%20Recommendations%20Campaigns%20and%20Referral.md).
