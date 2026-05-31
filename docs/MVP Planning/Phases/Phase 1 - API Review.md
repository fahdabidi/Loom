# Phase 1 — API Conformance & Efficiency Review

## Scope reviewed

- `FanPassportApi.createPassport`, `getPassport`, `setPersona`, `createFollow`, `setFollowVisibility`, `createConsentGrant`, `listFollows`
- `FanVaultApi.getInterestTaxonomy`, `getInterestProfile`, `putInterests`, `putDislikes`, `getAdPreferences`
- `CreatorChannelRegistryApi.createChannel`, `bindHandle`, `getChannel`
- `CreatorMetadataApi.createChannelProfile`, `attachHostingContract`
- Fan onboarding and creator onboarding screens backed by the fake APIs over Drift/SQLite

## Conformance findings

- **Contract boundary preserved:** `feature_fan_onboarding` and `feature_creator_onboarding` import only `loom_api_contracts`, `loom_design_system`, and `loom_app_shell`; concrete fake/store bindings remain in `apps/loom_demo`.
- **Fan passport provenance:** passport creation returns the passport id and active persona id used by later persona, interest, consent, and follow writes.
- **First-follow provenance:** the fan onboarding controller fetches one seeded creator catalog item through `CreatorMetadataApi.getPublicCatalog` and uses that returned `creatorId` for `createFollow`.
- **Creator channel provenance:** `createChannel` returns `channelId`; `bindHandle`, `createChannelProfile`, and `attachHostingContract` use that returned id rather than a magic UI constant.
- **State persistence:** Phase 1 tables are Drift/SQLite-backed for app runs and in-memory Drift-backed for tests.

## Efficiency findings

- **Interest taxonomy fetch:** the fan onboarding controller fetches the interest taxonomy once per onboarding session and keeps it in controller state.
- **Batched interest write:** selected interests are persisted with one `putInterests` call, not one write per chip.
- **Idempotent mutations:** passport creation, persona creation, consent grant creation, follow creation, follow visibility updates, channel creation, handle binding, profile creation, and hosting acceptance all accept idempotency keys and dedupe through local idempotency records.
- **Minimal payload:** Phase 1 DTOs expose only fields rendered by the UX or required as provenance for the next request.

## Residual notes

- `getInterestTaxonomy` was added to `FanVaultApi` because the phase requires a seeded taxonomy to be fetched and cached; the Phase 1 plan named the taxonomy asset but did not list the read method explicitly.
- The fake uses deterministic demo timestamps and ids for stable tests. Real HTTP clients should return server-generated ids/timestamps while preserving idempotency semantics.
- Follow visibility currently records the latest state. A future receipt-ledger phase should attach immutable visibility-change receipts if auditability becomes user-visible.

## Proposed OpenAPI/spec notes

- Add `GET /v1/fan-vault/interest-taxonomy` returning ordered `InterestToken` records (`id`, `label`, `category`).
- Require `Idempotency-Key` for all Phase 1 mutations and document same-key replay behavior.
- Keep `createFollow.creatorId` sourced from a prior creator/catalog/search response.
- Specify that `putInterests` replaces the selected token set in one batched request.
- Define managed-hosting acceptance as an explicit `HostingContract` response from Creator Metadata.
