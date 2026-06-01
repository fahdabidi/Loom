# Phase 8 - API Review

## Scope

Phase 8 implemented recommendation publishing, referral terms, qualified discovery and referral conversion receipts, giveaway campaigns, fan campaign entry, reward issuance, and sponsor data-for-value offers that reuse Phase 7 consent.

## Contract Findings

- `RecommendationReferralApi` now exposes the creator write and attribution loop: `publishRecommendationManifest`, `publishReferralTerms`, `recordDiscovery`, and `recordReferralConversion`.
- `CampaignApi` now exposes the fan/creator giveaway loop: `createCampaign`, `getCampaign`, `listActiveCampaigns`, `participate`, and `issueReward`.
- `SponsorCampaignApi` now exposes sponsor proposal and fan data-grant offer attachment.
- New typed models cover `RecommendationManifest`, `ReferralTerms`, `DiscoveryReceipt`, `CreatorReferralReceipt`, `Campaign`, `CampaignEntry`, `Reward`, `SponsorProposal`, and `FanDataGrantOffer`.
- Receipt typing was extended with discovery/referral/campaign/reward categories so downstream ledgers and dashboards do not collapse Phase 8 receipts into playback.

## Provenance And Efficiency

- Recommendation disclosure data shown in fan discovery is sourced from the published manifest returned by the API.
- Referral conversion requires a prior `DiscoveryReceipt` and `ReferralTerms`; settlement reuses the Phase 6 settlement API and local receipt ledger.
- Campaign entry and reward issuance are idempotent in the fake API, avoiding double-entry and duplicate reward state.
- Sponsor data offers reuse Phase 7 `DataGrantRequest`, `DataConsentGrant`, and `DataAccessReceipt` behavior rather than creating a separate targeting/consent path.
- The fan campaign screen hydrates active campaigns and sponsor offers in batched calls, not per-row fan-data lookups.

## Follow-Ups

- The Phase 8 fake keeps authored recommendation, campaign, and sponsor-offer objects in process while persisting referral/discovery evidence through the receipt ledger. A production-ready fake should promote these authored objects into Drift tables before relying on relaunch persistence or export.
- Referral terms currently model the window/cap in the contract and UI, while cap enforcement is simplified to one deterministic demo conversion.
- Campaign entry and reward receipts are represented by typed campaign models in the UI; if the receipt ledger becomes the single audit stream for campaigns, add explicit `campaignEntry` and `reward` ledger ingestion.

## Gate Evidence

- Unit/API tests added in `apps/loom_demo/test/p8_referral_campaign_api_test.dart`.
- Integration tests added:
  - `it_p8_publish_recommendation`
  - `it_p8_referral_settlement`
  - `it_p8_campaign_entry`
  - `it_p8_sponsor_data_offer`
