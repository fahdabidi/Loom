# Phase 8 — Recommendations, Campaigns & Referral

**Surface:** both · **UX gate:** med · **On green:** AUTO → Phase 9
**Shared conventions:** [README.md](./README.md).

## 0. Prerequisite gate (validate Phase 7 done)
README gate + confirm: discovery feed consumes recommendations (Phase 3), data-for-value consent works (Phase 7), settlement runs (Phase 6). Phase 7 integration tests pass.

## 1. Workflows & user stories in this phase
- **CE-S5 / RE-S1 / RE-W2** — Creator publishes a recommendation (appears in fan discovery).
- **RE-S4 / RE-W1** — Destination creator publishes referral terms.
- **RE-S2 / RE-W4 / MN-S6** — Referral attribution + settlement (simulated).
- **CE-W3 / AD-W1 / MN-S4** — Creator sets up a campaign (one built-in giveaway).
- **FE-S6 / FE-W6** — Fan participates in the giveaway + reward.
- **AD-S3A / AD-W2B** — Sponsor-linked data-for-value offer in the campaign (reuses Phase 7 consent).

## 2. Tools (WSL Ubuntu)
Standard set.

## 2A. UX reference research & decision output
Before implementing recommendations, campaigns, and referral UX, review reference mockups and design guidance from popular social/creator products such as YouTube community/recommendation surfaces, Instagram creator collaborations and giveaways, TikTok discovery/campaign patterns, Facebook groups/pages/campaigns, WhatsApp Channels, and adjacent referral/affiliate products. Focus on recommendation disclosures, campaign cards, giveaway entry flows, referral attribution transparency, rewards, sponsor-data offers, and creator-side campaign builders.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 8 specifics:
- Recommendation and campaign surfaces should feel like social feed/community posts: creator avatar, visual campaign media, concise terms, clear CTA, and disclosure badges.
- Fan giveaway entry should be a short progressive flow with eligibility, consent/data-value offer, reward status, and receipt confirmation, using sheets for detail.
- Referral attribution must be visible but lightweight: show "recommended by" context, terms/caps in a sheet, and conversion/settlement receipts after action.
- Creator campaign builders should follow Studio patterns: preview panel, task/status cards, validation, schedule/reward controls, and a final review state before publish.
- Sponsor-linked data offers must reuse Phase 7 consent card language and never introduce a separate behavioral-targeting UX path.

Create [Phase 8 - UX Decisions.md](./Phase%208%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented UX demonstrates creator recommendations, referral terms, fan participation, campaign entry, sponsor data-for-value, and settlement receipts using the collected guidance.

## 3. APIs invoked & stubs to implement
- **Recommendation & Referral API:** `publishRecommendationManifest`, `publishReferralTerms`, `recordDiscovery` → `DiscoveryReceipt`, `recordReferralConversion` → `CreatorReferralReceipt`. Extend `RecommendationReferralFake`.
- **Campaign API:** `createCampaign`, `getCampaign`, `participate`, `issueReward`. Fake: `CampaignFake`.
- **Sponsor Campaign API:** `createProposal`, `attachFanDataGrantOffer`. Fake: `SponsorCampaignFake`.
- **Receipt Ledger / Settlement Engine:** referral + campaign receipts → settlement allocation. Reuse fakes.

## 4. Data storage (local store)
New tables: `recommendation_manifests`, `referral_terms`, `campaigns`, `campaign_entries`, `rewards`, `referral_receipts(type=discovery|referral, window, cap)`. Reuse `consent_grants` for the data-for-value offer.

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: extend `recommendation_referral_api.dart`; fill `campaign_api.dart`, `sponsor_campaign_api.dart`. Models: `RecommendationManifest`, `ReferralTerms`, `Campaign`, `CampaignEntry`, `Reward`, `DiscoveryReceipt`, `CreatorReferralReceipt`, `FanDataGrantOffer`.
- `core/loom_fake_backend/`: extend `recommendation_referral_fake.dart`; add `campaign_fake.dart`, `sponsor_campaign_fake.dart`.
- `core/loom_design_system/components/`: `campaign_card.dart`, `studio/recommendation_builder.dart`, `studio/campaign_builder.dart`.
- `features/creator/feature_creator_recommendations/`: screens `recommendation_builder`, `referral_terms`; `CHARTER.md`.
- `features/creator/feature_creator_campaigns/`: screen `campaign_builder`; `CHARTER.md`.
- `features/fan/feature_campaigns/`: screens `campaign_entry`, `data_for_value_offer`; `CHARTER.md`.

## 6. API best-practice checks (phase-specific)
- Manifest/terms publish **idempotent + versioned**.
- **Distinct receipts:** `DiscoveryReceipt` (qualified discovery) vs `CreatorReferralReceipt` (qualified conversion) — not conflated; attribution honors window + caps.
- Campaign entry emits `CampaignEntryReceipt`/`RewardReceipt`; idempotent participation (no double-entry).
- Data-for-value offer **reuses Phase 7 consent** — no new behavioral targeting path; verify firewall + `DataAccessReceipt`.
- Minimal payloads; referral settlement reuses the Phase 6 settlement call (no bespoke chatty endpoints).

## 7. Component boundary / design checks
- The three features import only contracts + design_system + app_shell; no feature→feature imports (fan campaigns vs creator campaigns are separate).
- `melos run lint:boundaries` clean; charters updated.

## 8. Automated validation checks
README baseline. Unit tests: attribution window/cap logic, discovery-vs-referral receipt selection, idempotent participation, reward issuance.

## 9. Integration tests
- `it_p8_publish_recommendation` — creator publishes recommendation → it surfaces in fan discovery with disclosure.
- `it_p8_referral_settlement` — fan converts via recommendation → `CreatorReferralReceipt` → settlement allocates referral revenue.
- `it_p8_campaign_entry` — fan enters giveaway → `CampaignEntryReceipt` + reward issued.
- `it_p8_sponsor_data_offer` — fan accepts data-for-value offer → grant via Phase 7 consent + `DataAccessReceipt`; sponsor sees only aggregate/approved data.

## 10. Definition of done
Creator can publish recommendations/referral terms and run a giveaway; fan participates and converts; referral + campaign receipts settle; data-for-value reuses the consent model; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 8 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 8 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
Med UX, no API-shaping beyond validated. After Phase 8 changes are committed and the commit SHA is recorded, **AUTO-PROCEED: immediately begin [Phase 9 — Export, Transparency & Full Demo](./Phase%209%20-%20Export%20Transparency%20and%20Full%20Demo.md).**
