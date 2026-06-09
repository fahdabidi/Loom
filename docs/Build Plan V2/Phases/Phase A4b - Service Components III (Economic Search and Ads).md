# Phase A4b - Service Components III (Economic Search and Ads)

Layer: service
Components: Wallet/Dues/Donations, Ad Decision Service, Ad Campaign Service, Search Service, Indexing
Service, AI Gateway, Digest Service, Settlement Engine, Utility Funding Service, Fraud Signal Service.
Depends on: A4a
Parallelism: one agent per component
Gate: economic/search/ad-service validation and contract tests pass

## 0. Prerequisite Gate

- A4a complete and committed.
- A1-A4a manifest has no stale required tests.
- Export/import and protected-vault contract tests are current.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| wallet-dues-donations | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunityWalletApi` |
| ad-decision-service | [Arch 11](../../Architecture%20V2/11-monetization-and-ad-delivery-architecture.md) | `CommunityAdDecisionApi` |
| ad-campaign-service | [Arch 11](../../Architecture%20V2/11-monetization-and-ad-delivery-architecture.md) | `CommunityAdCampaignApi` |
| search-service | [Arch 07](../../Architecture%20V2/07-search-discovery-connections-and-ai.md) | `CommunitySearchApi` |
| indexing-service | [Arch 07](../../Architecture%20V2/07-search-discovery-connections-and-ai.md) | `CommunityIndexingApi` |
| ai-gateway | [Arch 07](../../Architecture%20V2/07-search-discovery-connections-and-ai.md) | `CommunityAiGatewayApi` |
| digest-service | [Arch 07](../../Architecture%20V2/07-search-discovery-connections-and-ai.md) | `CommunityDigestApi` |
| settlement-engine | [Arch 05](../../Architecture%20V2/05-content-publishing-payments-ads-and-settlement.md) | `CommunitySettlementApi` |
| utility-funding-service | [Arch 11](../../Architecture%20V2/11-monetization-and-ad-delivery-architecture.md) | `CommunityUtilityFundingApi` |
| fraud-signal-service | [Arch 09](../../Architecture%20V2/09-trust-safety-moderation-and-compliance.md) | `CommunityFraudApi` |

## 2. Agent Assignment and Parallelism

Run one agent per component. Merge order:

1. Indexing and Search.
2. AI Gateway and Digest.
3. Wallet.
4. Ad Campaign and Ad Decision.
5. Settlement and Utility Funding.
6. Fraud Signal.

## 3. Per-Component Build Spec

Economic/search/ad services must consume A1-A4a providers through contracts and fakes. Search cannot
use paid ranking. Ads cannot use protected data. Settlement consumes receipts and appends statements or
adjustments; it never mutates receipts.

## 4. Basic Validation Tests

Required:

- `vt_wallet_payment`
- `vt_wallet_ad-off`
- `vt_ad-decision_slot-eligibility`
- `vt_ad-decision_sensitive-no-fill`
- `vt_ad-campaign_setup`
- `vt_search_permission-aware`
- `vt_search_deindex`
- `vt_ai-gateway_answer`
- `vt_ai-gateway_source-policy`
- `vt_digest_on-demand`
- `vt_settlement_run`
- `vt_utility-funding_calculate`
- `vt_fraud_create-signal`

## 5. Consumer-Contract Tests Authored for Dependents

Author and register:

- `ct_wallet__payment-surface_checkout`
- `ct_wallet__ad-decision_ad-off-entitlement`
- `ct_ad-decision__app-shell_banner-fill`
- `ct_ad-decision__stream-renderer_in-stream-ad`
- `ct_search__ai-gateway_retrieval`
- `ct_search__app-shell_result-explanations`
- `ct_ai-gateway__digest_citations`
- `ct_receipt-ledger__settlement_read-window`
- `ct_settlement__utility-funding_allocation`
- `ct_fraud__settlement_apply-adjustment`

## 6. Cross-Component Test Gate

Run A4b validation tests, all consumed foundation/registry/service provider tests, all unblocked
contract tests to A6/A5 pending consumers where available, and all affected A1-A4a regressions.

## 7. Tenet-Adherence Checks

Verify no paid search fields, no protected ad targeting, immutable receipts, idempotent payment/ad
decisions, and redacted audit for sensitive search/AI contexts.

## 8. Skill Contribution

Add component guides for wallet, ads, ad campaign, search, indexing, AI gateway, digest, settlement,
utility funding, and fraud. Guides must teach extension builders how to request payments, ad-off,
search/AI, and reports without violating data-rights or monetization rules.

## 9. Manifest Update

Stamp A4b tests and resolve pending counterpart tests unblocked by economic/search/ad services.

## 10. API Review

Create `Phase A4b - API Review.md`. Record OpenAPI specs for payment, ads, search, AI, settlement,
utility funding, and fraud.

## 11. Definition of Done

A4b tests, regressions, manifest, Skill guides, API Review, tracker, and commit SHA complete.

## 12. Next Phase

Proceed to [Phase A5 - Extension Engine Components.md](./Phase%20A5%20-%20Extension%20Engine%20Components.md).
