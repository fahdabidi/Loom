# Phase A4b - API Review

Status: Completed in A4b

## Scope

Economic/search/ad service APIs: wallet, ad decision, ad campaign, search, indexing, AI gateway,
digest, settlement, utility funding, fraud signals.

## Review Checklist

- Payment/ad-off idempotency.
- Sensitive ad no-fill reason shape.
- No paid search ranking fields.
- AI citation/source policy fields.
- Receipt and settlement allocation fields.
- Fraud hold/adjustment shape.

## OpenAPI Outputs

Record economic/search/ad-service spec additions and gaps.

## A4b Contract Additions

- `CommunityWalletApi`
- `CommunityAdCampaignApi`
- `CommunityAdDecisionApi`
- `CommunityIndexingApi`
- `CommunitySearchApi`
- `CommunityAiGatewayApi`
- `CommunityDigestApi`
- `CommunitySettlementApi`
- `CommunityUtilityFundingApi`
- `CommunityFraudApi`

These contracts are currently implemented as typed Dart contracts in
`app/packages/core/loom_api_contracts/lib/clients/community_economic_apis.dart` and in-memory fakes in
`app/packages/core/loom_fake_backend/lib/community_economic_fake.dart`.

## OpenAPI Follow-Ups

- Add public specs for wallet payments, ad-off entitlements, ad campaigns, ad decisions, indexing,
  permission-aware search, AI answers, digests, settlement windows, utility allocation, and fraud
  signals.
- Keep App Shell, stream renderer, and payment surface consumers pending until A6.

## Validation Evidence

- `vt_wallet_payment`
- `vt_wallet_ad-off`
- `vt_ad-campaign_setup`
- `vt_ad-decision_slot-eligibility`
- `vt_ad-decision_sensitive-no-fill`
- `vt_search_permission-aware`
- `vt_search_deindex`
- `vt_ai-gateway_answer`
- `vt_ai-gateway_source-policy`
- `vt_digest_on-demand`
- `vt_settlement_run`
- `vt_utility-funding_calculate`
- `vt_fraud_create-signal`
- `ct_wallet__ad-decision_ad-off-entitlement`
- `ct_search__ai-gateway_retrieval`
- `ct_ai-gateway__digest_citations`
- `ct_receipt-ledger__settlement_read-window`
- `ct_settlement__utility-funding_allocation`
- `ct_fraud__settlement_apply-adjustment`

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
