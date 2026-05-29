# Loom Product Definition 08: Revenue, Receipts, Ledgers, and Settlement

Status: Draft for review  
Product area: 8 of 22  
Depends on: 01 Core Thesis and Platform Principles; 02 Creator Experience; 03 Fan Experience

## 1. Product Definition

Revenue, Receipts, Ledgers, and Settlement are the economic foundation of Loom. Every meaningful monetized action should produce signed receipts, and settlement should allocate revenue according to manifests, provider contracts, fan entitlements, fraud signals, and governance rules.

Creators should understand why they were paid. Providers should be paid for real services. Fans should be able to see how premium subscriptions support creators where applicable. Governance should be able to audit disputes, fraud, and provider claims.

## 2. Scope

This product area covers:

- Economic receipts, audit receipts, and utility-funding receipts.
- Receipt ingestion and validation.
- Money, usage, entitlement, and settlement ledgers.
- Playback, ad, premium no-ad, delivery, AI, campaign, referral, search, membership, payment, refund, chargeback, and settlement receipts.
- Settlement manifests and payout calculations.
- Creator payout statements.
- Provider payout statements.
- Fan subscription allocation statements.
- Fraud adjustments, disputes, reserves, and corrections.
- Utility fee policies for identity, vaults, search, and settlement.

It does not define every monetization product. Monetization Models defines those revenue products, while this area defines how activity becomes auditable economics.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Signed receipts | Standard records for monetized and auditable events. | Creates trustable inputs for settlement. | Trust, Safety, Fraud, and Compliance |
| Receipt classes | `EconomicReceipt`, `AuditReceipt`, and `UtilityFundingReceipt`. | Keeps monetization, audit, and utility funding distinct. | Core Thesis and Platform Principles |
| No receipt, no payout | Settlement requires valid receipts. | Reduces opaque payout logic and fraud. | Business Model and Incentive Design |
| `SettlementManifest` | Machine-readable allocation rules. | Revenue distribution can be audited and replayed. | Monetization Models |
| `CreatorPayoutStatement` | Creator-facing gross-to-net explanation. | Creators can understand revenue and costs. | Creator Experience |
| `ProviderPayoutStatement` | Provider-facing service payment explanation. | Providers are compensated for real usage. | Provider Marketplace and Certified APIs |
| `FanSubscriptionAllocationStatement` | Fan-facing allocation for premium/no-ad pools where applicable. | Fans can see how they supported creators. | Fan Experience |
| Search receipt guardrails | `SearchReceipt` is audit and utility-funding only. | Prevents paid ranking drift. | Neutral Public Search Utility |
| Fraud adjustments | Invalid activity can be adjusted through auditable records. | Protects creators, fans, sponsors, and providers. | Trust, Safety, Fraud, and Compliance |
| Dispute-ready ledgers | Receipts, manifests, and adjustments preserve evidence. | Enables governance and support workflows. | Governance, Certification, and Foundation Model |

## 4. Product Experience Requirements

### 4.1 Creator Revenue Experience

Creators should see:

- Revenue by source: ads, premium no-ad, memberships, tips, AI, referrals, sponsors, campaigns, events, courses, commerce, and bundles.
- Gross revenue.
- Provider costs.
- Utility fees.
- Fraud adjustments.
- Refunds and chargebacks.
- Net payout.
- Pending, settled, disputed, and held amounts.
- Receipt-level drilldown when needed.

### 4.2 Provider Revenue Experience

Providers should see:

- Service usage receipts.
- Revenue by service role.
- Adjustments and invalid traffic.
- Payout status.
- Disputes.
- Certification or audit holds.

### 4.3 Fan Transparency Experience

Fans should see:

- Purchases, memberships, and subscriptions.
- Active entitlements.
- Refunds and failed payments.
- Premium subscription allocation where applicable.
- Data that affects no-ad or premium modes without exposing private settlement internals.

## 5. User Stories

### Story 1: Creator reviews payout

As a creator, I want to understand why I was paid so I can trust the platform and optimize my business.

End state:

- `CreatorPayoutStatement` explains gross revenue, fees, costs, adjustments, and net payout.
- Receipts are traceable to revenue sources.

### Story 2: Fan watches ad-supported content

As a free fan, I want ad-supported viewing to support creators.

End state:

- Playback and ad receipts are generated.
- Fraud signals attach validity.
- Settlement allocates ad revenue.

### Story 3: Premium fan watches no-ad content

As a premium fan, I want no-ad viewing to still compensate creators.

End state:

- PremiumNoAdReceipt is generated.
- Subscription pool allocation is calculated.
- Creator and provider statements include the allocation.

### Story 4: AI answer uses creator archive

As a creator, I want AI usage of my archive to create attribution and royalties where enabled.

End state:

- AIUsageReceipt and SourceAttributionReceipt are generated.
- Settlement allocates AI revenue according to policy.

### Story 5: Provider gets paid

As a provider, I want to be paid for delivery, hosting, AI, search, vault, or settlement services I actually performed.

End state:

- Provider service receipts are ingested.
- Provider payout statement is generated.
- Fraud or dispute holds are visible.

### Story 6: Fraud adjustment is applied

As governance, I want invalid activity adjusted without corrupting the original ledger.

End state:

- Original receipts remain immutable.
- FraudAdjustmentRecord offsets or discounts settlement.
- Statements explain the adjustment.

### Story 7: Payment refund or chargeback adjusts settlement

As a fan, creator, provider, or governance operator, I want refunds and chargebacks to update entitlements and settlement without rewriting history.

End state:

- `RefundChargebackRecord` is created.
- Entitlements are updated if needed.
- Creator, provider, and fan statements show the adjustment.

## 6. End-to-End Workflows

### Workflow 1: Receipt generation and ingestion

Actors:

- Fan App
- Provider
- Receipt Ledger
- Fraud Signal Service
- Settlement Engine

Steps:

1. Fan or provider action occurs.
2. Responsible system creates signed receipt.
3. Receipt includes actor references, manifest versions, provider keys, timestamp, and event details.
4. Receipt Ledger validates signature, schema, provider certification scope, API version, service role, key status, and revocation state.
5. Fraud Signal Service adds or updates confidence score.
6. Receipt becomes available for settlement.

### Workflow 2: Monthly creator settlement

Actors:

- Settlement Engine
- Receipt Ledger
- Payment Provider
- Creator Studio
- Provider Console

Steps:

1. Settlement period closes.
2. Settlement Engine pulls valid receipts.
3. Engine resolves effective versions for `SettlementManifest`, `HostingContractManifest`, `MonetizationManifest`, `ReferralTermsManifest`, `CampaignManifest`, and `AIContentPolicy`.
4. `SettlementRunRecord` binds the run to receipt set, manifest versions, provider contract versions, adjustments, and execution timestamp.
5. Engine applies provider contracts, utility fees, reserves, and adjustments.
6. `CreatorPayoutStatement` and `ProviderPayoutStatement` records are generated.
7. Payment Provider executes payouts or prototype simulates payouts.
8. Creator and providers review statements.
9. Disputes can be opened within policy window.

### Workflow 3: Premium no-ad allocation

Actors:

- Fan
- Fan Wallet
- Playback Service
- Receipt Ledger
- Settlement Engine
- Creator Studio

Steps:

1. Fan pays for global no-ad premium.
2. Fan watches eligible creator content.
3. Playback service generates PremiumNoAdReceipt.
4. Settlement Engine aggregates qualified no-ad usage.
5. Subscription pool is allocated to creators and providers.
6. Fan may see allocation summary.
7. Creator sees no-ad replacement revenue.

### Workflow 3A: Payment, entitlement, refund, and chargeback

Actors:

- Fan
- Fan Wallet
- Payment Provider
- Merchant of Record
- Entitlement Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan purchases membership, premium no-ad, AI credits, paid content, event ticket, or private mode.
2. `PaymentProviderAPI` processes charge under `MerchantOfRecordContract`.
3. `PaymentReceipt` is generated.
4. Entitlement Ledger records relevant entitlement, such as `PremiumNoAdEntitlement`, `MembershipEntitlement`, or `AICreditEntitlement`.
5. Receipts become settlement inputs.
6. Refund or chargeback occurs.
7. `RefundChargebackRecord` is created.
8. Entitlement state and future access are adjusted where required.
9. Settlement Engine applies adjustment to creator, provider, and fan-facing statements.

### Workflow 4: AI source royalty settlement

Actors:

- Fan or Creator
- AI Gateway
- Creator Metadata Host
- Receipt Ledger
- Settlement Engine

Steps:

1. User asks AI question or requests summary.
2. AI Gateway checks creator AI policy and fan privacy settings.
3. AI provider returns response with source references.
4. AIUsageReceipt and SourceAttributionReceipt are generated.
5. Settlement Engine applies AI royalty rules.
6. Creator sees AI revenue and source usage.

### Workflow 5: Campaign settlement

Actors:

- Sponsor
- Creator
- Fan
- Campaign Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Sponsor funds campaign or agrees terms.
2. Fan participates.
3. `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `RewardReceipt`, or `ConversionReceipt` is generated.
4. Campaign compliance and fraud checks run against effective `CampaignManifest`, `CampaignComplianceManifest`, and `SettlementManifest` versions.
5. `ReceiptIngestAPI` validates signed receipts, provider/app keys, certification scope, and key status.
6. Settlement Engine allocates sponsor funds, extension fees, creator revenue, utility fees, and provider costs.
7. Creator and sponsor receive reports.

### Workflow 6: Dispute and adjustment

Actors:

- Creator
- Provider
- Fan
- Governance Admin
- Receipt Ledger
- Settlement Engine

Steps:

1. Actor opens dispute about payout, receipt, chargeback, fraud, or service usage.
2. Governance reviews receipts, manifests, contracts, and audit records.
3. Adjustment is approved or denied.
4. FraudAdjustmentRecord, RefundChargebackRecord, or SettlementAdjustmentRecord is created.
5. Future statements reflect the adjustment.
6. Original receipts remain available for audit.

## 7. Cross-Area Interactions

- Monetization Models: `MonetizationManifest`, typed entitlements, and payment contracts define revenue sources.
- Creator Experience: Creator Studio exposes `CreatorPayoutStatement`, receipt drilldowns, and settlement status.
- Fan Experience: Fan App exposes `FanWalletAPI`, entitlements, and `FanSubscriptionAllocationStatement`.
- Provider Marketplace and Certified APIs: providers receive service receipts and `ProviderPayoutStatement`.
- Provider certification scope and `ProviderKeyManagementAPI` key status constrain which provider receipts are valid.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `PaymentReceipt`, `EntitlementLedgerAPI`, and wallet entitlements create settlement inputs.
- Creator Channel and Metadata Architecture: `CreatorChannelManifest`, `HostingContractManifest`, `MonetizationManifest`, and `SettlementManifest` versions define historical settlement rules.
- Hosting Provider Lifecycle and Progressive Unbundling: hosting contracts, `CDNDeliveryReceipt`, and delivery costs affect payouts.
- Neutral Public Search Utility: `SearchReceipt` is audit/utility-funding only and never paid ranking.
- AI Layer: `AIUsageReceipt` and `SourceAttributionReceipt` feed settlement.
- Creator-Led Recommendation Economy: `DiscoveryReceipt` and `CreatorReferralReceipt` feed settlement.
- Trust, Safety, Fraud, and Compliance: `FraudSignalAPI`, `FraudAdjustmentRecord`, `RefundChargebackRecord`, and `DisputeResolutionAPI` affect settlement.
- Governance, Certification, and Foundation Model: `CertificationScopeRecord`, audit rules, and `DisputeCaseRecord` govern settlement trust.
- Business Model and Incentive Design: `UtilityFeePolicy`, `SearchUtilityFundingPolicy`, and revenue-share rules are applied by settlement.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Receipt systems

- `ReceiptIngestAPI`: validates and stores signed receipts.
- Receipt Schema Registry: schemas for `PlaybackReceipt`, `AdImpressionReceipt`, `AdCompletionReceipt`, `PremiumNoAdReceipt`, `AIUsageReceipt`, `SourceAttributionReceipt`, `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `RewardReceipt`, `ConversionReceipt`, `DiscoveryReceipt`, `CreatorReferralReceipt`, `SearchReceipt`, `CDNDeliveryReceipt`, `VaultServiceReceipt`, `DataAccessReceipt`, `MigrationReceipt`, `MembershipReceipt`, `PaymentReceipt`, `RefundChargebackRecord`, and `SettlementReceipt`.
- `PlaybackReceipt`: content playback or read/view event used for usage analytics and settlement eligibility.
- `AdImpressionReceipt`: ad or sponsor ad impression evidence.
- `AdCompletionReceipt`: completed ad view evidence where completion affects billing or allocation.
- `PremiumNoAdReceipt`: premium no-ad consumption evidence for subscription allocation.
- `MembershipReceipt`: membership purchase or renewal event.
- `SettlementReceipt`: payout or settlement execution evidence.
- `ReceiptSigningService`: provider keys, app keys, creator keys, and revocation checks.
- `ReceiptQueryAPI`: creator, provider, fan, governance, and settlement access.
- `ReceiptExportAPI`: exports revenue, usage, settlement, and audit history for migration, disputes, and creator portability.

`SearchReceipt` is an `AuditReceipt` and `UtilityFundingReceipt` only. It must not create paid ranking, search ads, per-click search monetization, or ordering advantage.

#### Ledger systems

- `UsageLedger`: playback, delivery, AI, search, campaign, and referral usage.
- `MoneyLedger`: charges, subscriptions, refunds, payouts, reserves, and adjustments.
- `EntitlementLedger`: access rights that affect settlement eligibility.
- `SettlementLedger`: calculated allocations, statements, payouts, disputes, and corrections.

#### Settlement systems

- `SettlementManifest`: revenue split rules and required receipts.
- `SettlementEngineAPI`: calculates allocations.
- `SettlementRunRecord`: effective receipt set, manifest versions, provider contract versions, adjustment records, and execution timestamp.
- `PayoutAPI`: executes or simulates payouts.
- `UtilityFeePolicy`: shared infrastructure fees.
- `TaxReservePolicy`: taxes, reserves, and jurisdiction-dependent withholding.
- `FraudAdjustmentRecord`: invalid traffic and fraud offsets.
- `RefundChargebackRecord`: payment dispute adjustments.

#### Statement systems

- `CreatorPayoutStatement`: gross-to-net revenue by source.
- `ProviderPayoutStatement`: service receipts and provider payouts.
- `FanSubscriptionAllocationStatement`: premium/no-ad support allocation.
- `SponsorCampaignStatement`: sponsor delivery, conversion, rewards, and fees.

#### Integration systems

- `PlaybackSessionAPI`: playback and ad receipts.
- `PaymentProviderAPI`: payment, subscription, refund, and chargeback receipts.
- `MerchantOfRecordContract`: payment/legal responsibility.
- `AIGateway`: AI usage and source attribution receipts.
- `CampaignLedgerAPI`: campaign entry and reward receipts.
- `RecommendationReferralEngine`: discovery and referral receipts.
- `ProviderCapabilityRegistry`: provider keys and certification status.

#### Trust and governance systems

- `FraudSignalAPI`: bot, invalid traffic, fake engagement, and suspicious payment scoring.
- `DisputeResolutionAPI`: receipt, settlement, payout, chargeback, and fraud disputes.
- `AuditAPI`: governance access to receipts, contracts, manifests, and adjustments.
- `KeyRevocationRecord`: invalidates compromised receipt signers.
