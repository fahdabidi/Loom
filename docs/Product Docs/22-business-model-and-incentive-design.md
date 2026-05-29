# Loom Product Definition 22: Business Model and Incentive Design

Status: Draft for review  
Product area: 22 of 22  
Depends on: 06 Hosting Provider Lifecycle and Progressive Unbundling; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 09 Monetization Models; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 16 Developer Ecosystem and DevOps Supply Chain; 18 Brand/Sponsor/Advertiser Tools; 19 Governance, Certification, and Foundation Model

## 1. Product Definition

Loom's business model should align incentives among creators, fans, providers, developers, advertisers, and the open-source foundation. No single actor should own the whole stack. Revenue should flow to whoever creates value, and shared utilities should be funded transparently.

The business model should avoid recreating monopoly platform economics under an open-source label. Provider competition, creator ownership, fan data rights, transparent receipts, and neutral governance must remain economically reinforced.

## 2. Scope

This product area covers:

- Creator revenue models.
- Fan paid models.
- Provider revenue models.
- Developer revenue models.
- Sponsor/advertiser revenue models.
- Foundation and utility funding.
- Certification fees.
- Enterprise support.
- Revenue shares, direct fees, utility fees, and settlement.
- Incentive guardrails for search, recommendations, data, and AI.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Provider competition | Providers earn through services, not lock-in. | Reduces monopoly extraction. | Provider Marketplace and Certified APIs |
| Creator choice | Creators can choose revenue share or direct-cost models. | Aligns with creator maturity. | Hosting Provider Lifecycle and Progressive Unbundling |
| Fan understandable value | Fans pay for no-ad, memberships, AI, privacy, events, and content. | Avoids charging for abstract infrastructure. | Fan Experience |
| Utility fee model | Shared identity, vaults, search, and settlement are transparently funded. | Keeps utilities sustainable. | Governance, Certification, and Foundation Model |
| Receipt-based economics | Revenue allocation follows receipts and manifests. | Makes incentives auditable. | Revenue, Receipts, Ledgers, and Settlement |
| Developer marketplace | Developers earn through extensions, apps, AI tools, and provider services. | Expands ecosystem. | Developer Ecosystem and DevOps Supply Chain |
| Search guardrails | Search is not paid ranking or per-click monetization. | Protects trust. | Neutral Public Search Utility |
| Recommendation guardrails | Referral revenue is disclosed and capped. | Reduces predatory engagement loops. | Creator-Led Recommendation Economy |
| Data rights economics | Privacy and data access are explicit products and permissions. | Aligns fan control with business model. | Audience Data Firewall and Data Rights |

## 4. Revenue Participants

### 4.1 Creators

Creators can earn from:

- Ads.
- Global no-ad premium allocation.
- Memberships.
- Tips and boosts.
- Paid content.
- Paid events.
- Courses.
- AI source royalties.
- Referrals.
- Sponsors.
- Campaigns.
- Commerce and affiliate.
- Bundles.

### 4.2 Fans

Fans pay for understandable value:

- Creator memberships.
- Global no-ad premium.
- Premium delivery.
- AI credits/subscriptions.
- Paid events/courses/content.
- Tips and boosts.
- Gifts/gifted memberships.
- Premium private mode.

### 4.3 Providers

Providers earn through:

- Free managed hosting revenue share.
- Growth hosting fees.
- Direct paid hosting.
- SaaS/provider fees.
- AI provider fees.
- Payment/settlement fees.
- Search/vault/identity/settlement utility funding.
- Certification-supported services.
- Enterprise support.

Search utility funding is cost/budget based through `SearchUtilityFundingPolicy`; it cannot depend on result order, clicks, opens, conversions, routing priority, merge priority, provider self-preference, or search-originated purchases.

### 4.4 Developers and Apps

Developers and apps earn through:

- Extension marketplace fees.
- App subscriptions.
- Premium app features.
- AI/search/recommendation tools.
- Provider services.
- Campaign modules.

Search tools may charge for app UX, workflow automation, or developer tooling. They cannot charge for public-search ranking, clicks, search-originated conversions, paid routing, or merge priority.

### 4.5 Sponsors and Advertisers

Sponsors pay for:

- Creator-sold ads.
- Sponsor campaigns.
- Product cards.
- Promo codes.
- Giveaways.
- Clean-room measurement.

Sponsor-free variants are fan/member premium economics, not sponsor spend. Sponsors pay for campaign delivery, product cards, promo codes, clean-room measurement, and approved campaign spend.

### 4.6 Foundation / Shared Utilities

The foundation and shared utilities may be funded by:

- Utility fees.
- Certification fees.
- Marketplace fees.
- Enterprise support.
- Grants or sponsorships consistent with neutrality.
- Shared infrastructure allocations from settlement.

Foundation funding must follow `FoundationFundingPolicy`: public budgets, fee caps, conflict rules, sponsor/grant neutrality tests, independent certification funding, and public utility reports.

## 5. Incentive Guardrails

- Search cannot use paid ranking, search ads, per-click monetization, or ordering advantages.
- `SearchReceipt` is audit/utility-funding only.
- `SearchUtilityFundingPolicy` must be cost/budget based, capped, governance-approved, and independent of ranking, clicks, opens, conversions, routing, merge priority, or provider self-preference.
- Recommendations must disclose editorial, paid, affiliate, sponsored, or referral relationships.
- Referral payouts require `ReferralTermsManifest`, `RecommendationManifest`, `DiscoveryReceipt`, `CreatorReferralReceipt`, manifest-version binding, disclosure rules, caps, windows, reserves, and fraud checks.
- Data access should require explicit grants and receipts.
- Payment and settlement liability must be explicit through `MerchantOfRecordContract`, `TaxReservePolicy`, `PaymentReceipt`, `RefundChargebackRecord`, payout instructions, reserve rules, dispute windows, and negative-balance handling.
- Providers should not earn by making export difficult; export fees must be predeclared, cost-based, capped, receipt-backed, scorecard-visible, and disputeable.
- Extensions, sponsors, and creator CRM tools should not monetize unauthorized follower visibility, direct-contact data, or audience exports.
- AI providers should not train or retain data beyond creator/fan policy.
- Utility fees should be visible and governed.

### 5.1 Premium Mode Economics

| Premium mode | Payer | Entitlement | Receipt | Settlement pool and allocation |
| --- | --- | --- | --- | --- |
| Global no-ad premium | Fan | `PremiumNoAdEntitlement` | `PaymentReceipt`, `PremiumNoAdReceipt` | Allocates to creators, apps, providers, and utilities based on eligible consumption and `SettlementManifest`. |
| Premium delivery | Fan or creator | `PremiumDeliveryEntitlement` | `PaymentReceipt`, `CDNDeliveryReceipt` | Covers provider delivery cost and optional premium experience allocation. |
| AI credits/subscription | Fan or creator | `AICreditEntitlement` | `PaymentReceipt`, `AIUsageReceipt`, `SourceAttributionReceipt` | Pays AI provider, source creators, apps, and utilities according to AI policy. |
| Premium private mode | Fan | `PrivateVaultEntitlement` | `PaymentReceipt`, `VaultServiceReceipt`, `DataAccessReceipt` | Funds private vault operations, privacy utility costs, and any creator allocation allowed by policy. |
| Sponsor-free/member variant | Fan or member | Membership or paid-content entitlement | `PaymentReceipt`, `PlaybackReceipt`, `PremiumNoAdReceipt` where applicable | Premium/member revenue replaces sponsor exposure according to `MonetizationManifest`. |

## 6. User Stories

### Story 1: Creator chooses revenue-share hosting

As a new creator, I want free managed hosting with revenue share so I can start without upfront costs.

End state:

- Hosting and settlement terms are clear.
- Provider is paid through receipts.

### Story 2: Creator moves to direct-cost model

As a mature creator, I want to pay hosting costs directly and keep more revenue.

End state:

- Hosting contract changes.
- Settlement rules update.

### Story 3: Fan pays for clear value

As a fan, I want to pay for no-ad, memberships, AI, privacy, events, or content rather than abstract identity hosting.

End state:

- Fan Wallet shows value and entitlements.
- Settlement allocates revenue.

### Story 4: Developer earns from extension

As a developer, I want creators to pay for my extension.

End state:

- Extension marketplace fee is recorded.
- Developer payout is settled.

### Story 5: Foundation funds shared utilities

As governance, I want identity, vault, search, and settlement utilities sustainably funded.

End state:

- `UtilityFeePolicy` is published.
- `UtilityFundingReceipt` supports transparent allocation.

## 7. End-to-End Workflows

### Workflow 1: Free managed hosting revenue share

Actors:

- Creator
- Hosting Provider
- Fan
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator accepts free managed hosting.
2. `HostingContractManifest` and `SettlementManifest` define revenue share.
3. Fan consumes content.
4. Playback/ad/no-ad/delivery receipts are generated.
5. Settlement allocates revenue to creator, host, app, providers, and utilities.

### Workflow 2: Direct paid hosting economics

Actors:

- Creator
- Hosting Provider
- Payment Provider
- Settlement Engine

Steps:

1. Creator switches to direct paid hosting.
2. Creator pays hosting provider directly or through settlement.
3. Provider service receipts track usage.
4. Creator keeps more monetization revenue subject to direct costs.
5. `CreatorPayoutStatement` shows gross-to-net.

### Workflow 3: Utility fee allocation

Actors:

- Fan
- Creator
- Providers
- Foundation
- Settlement Engine

Steps:

1. Monetized event occurs.
2. Settlement Engine applies `UtilityFeePolicy`.
3. `UtilityFundingReceipt` measures identity, vault, search, or settlement utility usage.
4. Funds are allocated transparently.
5. Search utility funding is cost/budget based and cannot create paid ranking, search ads, per-click monetization, routing priority, merge priority, or ordering advantage.
6. Governance reports utility funding through `FoundationUtilityReport`.

### Workflow 4: Developer extension revenue

Actors:

- Creator
- Extension Developer
- Extension Registry
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator installs paid extension.
2. Extension usage or subscription is recorded.
3. `ExtensionUsageReceipt` is generated.
4. Settlement applies `MarketplaceFeePolicy` and allocates developer revenue, app/registry fees, and utilities.
5. Developer sees `DeveloperPayoutStatement`.

### Workflow 5: Sponsor campaign economics

Actors:

- Sponsor
- Creator
- Fan
- Extension Developer
- Settlement Engine

Steps:

1. Sponsor funds campaign.
2. Creator approves and launches.
3. Fans participate.
4. `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `ConversionReceipt`, and `RewardReceipt` are generated where applicable.
5. Settlement allocates funds to creator, extension developer, providers, and utilities.

### Workflow 6: Referral economics

Actors:

- Source Creator
- Destination Creator
- Fan
- Receipt Ledger
- Settlement Engine

Steps:

1. Destination creator publishes `ReferralTermsManifest`.
2. Source creator publishes `RecommendationManifest` with required disclosure.
3. Fan discovers or converts through recommendation.
4. `DiscoveryReceipt` or `CreatorReferralReceipt` is submitted through `ReceiptIngestAPI`.
5. Settlement validates effective manifest versions, `SettlementManifest`, attribution window, caps, reserves, and fraud signals.
6. Source creator revenue, destination creator cost, fraud holds, and invalid-referral adjustments appear in payout statements.

### Workflow 7: Payment and settlement liability

Actors:

- Fan
- Creator
- Merchant of Record / Payment Provider
- Settlement Engine
- Governance Admin

Steps:

1. Paid event creates `PaymentReceipt` under `MerchantOfRecordContract`.
2. Settlement applies `TaxReservePolicy`, reserve windows, payout instructions, and provider responsibilities.
3. Refunds, chargebacks, and negative balances create `RefundChargebackRecord` and adjustment records.
4. Disputes use receipt and contract evidence without mutating original receipts.

## 8. Cross-Area Interactions

- Monetization Models: `MonetizationManifest`, typed entitlements, receipts, and access modes define revenue products.
- Revenue, Receipts, Ledgers, and Settlement: `ReceiptLedger`, `SettlementManifest`, `SettlementEngineAPI`, and payout statements execute allocation.
- Provider Marketplace and Certified APIs: `ProviderCapabilityManifest`, `ProviderPayoutStatement`, and certified service receipts support provider competition and fees.
- Hosting Provider Lifecycle and Progressive Unbundling: `HostingContractManifest`, revenue-share tiers, direct-cost models, and export fees define creator maturity economics.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `FanWalletAPI`, `EntitlementLedgerAPI`, `PaymentReceipt`, and typed entitlements support fan payments.
- Neutral Public Search Utility: `SearchUtilityFundingPolicy`, `SearchReceipt`, and `NeutralSearchMergePolicy` enforce utility-funded search guardrails.
- Creator-Led Recommendation Economy: `ReferralTermsManifest`, `RecommendationManifest`, `DiscoveryReceipt`, and `CreatorReferralReceipt` define referral incentive rules.
- Audience Data Firewall and Data Rights: `DataUseGrant`, `DataAccessReceipt`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `PrivateVaultEntitlement`, and `VaultServiceReceipt` define privacy and data-use incentives.
- Fan Apps and App Ecosystem: `AppSubscriptionManifest`, `AppUsageReceipt`, and `AppCertificationAPI` let apps monetize UX without owning identity or search ranking.
- Developer Ecosystem and DevOps Supply Chain: `MarketplaceFeePolicy`, `ExtensionBillingSystem`, and `DeveloperPayoutStatement` provide developer billing and payout evidence.
- Brand/Sponsor/Advertiser Tools: `SponsorCampaignBilling`, sponsor receipts, and premium sponsor-free entitlements keep sponsor economics separate from sponsor-free premium.
- Governance, Certification, and Foundation Model: `UtilityFeePolicy`, `FoundationFundingPolicy`, `FoundationUtilityReport`, and certification fees govern utility and certification funding.

## 9. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `UtilityFeePolicy`: identity, vault, search, settlement, and governance utility funding.
- `SearchUtilityFundingPolicy`: cost/budget based public search utility funding with no ranking, click, conversion, routing, or merge advantage.
- `SettlementManifest`: revenue split and required receipt rules.
- `HostingContractManifest`: hosting tier, direct fee, revenue share, and provider cost rules.
- `MonetizationManifest`: creator monetization product rules.
- `ReceiptLedger`: economic, audit, and utility receipts.
- `SettlementEngineAPI`: revenue allocation.
- `MerchantOfRecordContract`: payment liability, refunds, chargebacks, reserves, and negative-balance responsibility.
- `PaymentReceipt`: paid event evidence.
- `RefundChargebackRecord`: refund and chargeback adjustment evidence.
- `TaxReservePolicy`: tax reserve and jurisdictional withholding policy.
- `PayoutInstructionAPI`: creator/provider/developer payout destinations and update history.
- `ReferralTermsManifest`: destination creator referral economics.
- `RecommendationManifest`: source creator recommendation record.
- `DiscoveryReceipt`: recommendation-driven discovery evidence.
- `CreatorReferralReceipt`: qualified referral evidence.
- `FraudAdjustmentRecord`: invalid-referral or invalid-traffic adjustment.
- `PremiumNoAdEntitlement`, `PremiumDeliveryEntitlement`, `PrivateVaultEntitlement`, and `AICreditEntitlement`: fan paid-mode entitlements.
- `VaultServiceReceipt`: private-mode infrastructure cost evidence.
- `MarketplaceFeePolicy`: extension/app/developer marketplace fee caps and allocations.
- `AppSubscriptionManifest`: app subscription pricing and entitlement rules.
- `AppUsageReceipt`: app premium feature or usage evidence.
- `DeveloperPayoutStatement`: developer gross-to-net statement.
- `CreatorPayoutStatement`: creator gross-to-net statement.
- `ProviderPayoutStatement`: provider gross-to-net statement.
- `FanSubscriptionAllocationStatement`: fan-facing subscription allocation view.
- `FoundationFundingPolicy`: anti-capture funding policy, public budget, fee caps, conflict rules, and neutrality tests.
- `FoundationUtilityReport`: public utility funding report.
- `CertificationFeeSystem`: certification fee calculation and waivers.
- `ExtensionBillingSystem`: extension billing.
- `AppSubscriptionBilling`: app subscription billing.
- `SponsorCampaignBilling`: sponsor campaign billing.
- `ProviderSaaSBilling`: provider SaaS billing.
- `EnterpriseSupportBilling`: enterprise support billing.
- `ExportFeePolicy`: predeclared, cost-based, capped, receipt-backed, scorecard-visible, disputeable export fees.
- `IncentiveAudit`: search, recommendation, data, AI, utility funding, unauthorized audience export, and provider lock-in guardrails.
