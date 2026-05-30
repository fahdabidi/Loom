# Loom Product Definition 09: Monetization Models

Status: Draft for review  
Product area: 9 of 22  
Depends on: 08 Revenue, Receipts, Ledgers, and Settlement

## 1. Product Definition

Monetization Models define the ways creators, providers, apps, developers, sponsors, and shared utilities can earn revenue inside Loom. The product should support simple monetization for new creators and more sophisticated revenue control for mature creators.

Loom's monetization should not be a single platform take-rate. Revenue should be tied to explicit value creation: content, memberships, AI source usage, referrals, sponsorships, campaigns, hosting, apps, extensions, payments, and shared utilities.

Session intent can affect ad load, contextual ad category, and eligible creator breadth for a fan session, but it does not create behavioral ad targeting or override creator ad policy. Which ads are eligible remains controlled by `CreatorAdPolicy`, sponsor/campaign policy, fan privacy mode, and safety rules.

## 2. Scope

This product area covers:

- Free ad-supported consumption.
- Global no-ad premium.
- Premium delivery or quality plans.
- Paid private / premium private vault mode.
- Creator memberships.
- Tips and boosts.
- Gifts and gifted memberships.
- Pay-per-view and paid content.
- Paid events and courses.
- AI subscriptions, credits, and source royalties.
- Sponsor campaigns and creator-sold ads.
- Affiliate and commerce.
- Creator bundles.
- Creator-to-creator referrals.
- Extension marketplace fees.
- Provider SaaS or infrastructure fees.
- Utility fees for identity, vaults, search, and settlement.

It does not define exact pricing, but it defines the product models and required infrastructure.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Free with ads | Fans can consume free content supported by ads or sponsors. | Low-friction fan acquisition and creator monetization. | Fan Experience; Trust, Safety, Fraud, and Compliance |
| Intent-aware ad load | `SessionIntent` can set how many ads may appear, the contextual ad category, and how wide the eligible creator set is for a session. | Supports higher-value contextual sessions while keeping fan control and creator ad policy. | Creator-Led Recommendation Economy; Brand/Sponsor/Advertiser Tools |
| Global no-ad premium | Fan pays once for no-ad access across eligible content. | Better fan experience without starving creators. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Paid private mode | Fan pays for stronger privacy, no external ad targeting, no raw behavior export, and stricter AI memory/training defaults. | Makes privacy an understandable paid product. | Audience Data Firewall and Data Rights |
| Creator memberships | Recurring creator-specific support and benefits. | Direct creator revenue and fan loyalty. | Creator Experience |
| AI source royalties | AI usage of creator content generates source attribution and royalties. | Creator archives become monetizable knowledge assets. | AI Layer |
| Creator referrals | Creator recommendations can generate referral revenue. | Aligns discovery with trust and accountability. | Creator-Led Recommendation Economy |
| Sponsor campaigns | Sponsors fund creator-controlled campaigns with consented measurement. | Structured brand revenue without unrestricted fan data. | Brand/Sponsor/Advertiser Tools |
| Extension marketplace | Developers earn from creator-installed plugins and campaign tools. | Expands product capability without central build bottleneck. | Creator Plugins / Extensions / Campaign Layer |
| Provider direct fees | Creators or apps pay providers for infrastructure and services. | Enables unbundling from revenue-share models. | Provider Marketplace and Certified APIs |
| Utility fees | Small transparent fees fund shared identity, vault, search, and settlement utilities. | Shared infrastructure has sustainable funding. | Business Model and Incentive Design |

## 4. Monetization Products

### 4.1 Free Ad-Supported

Fans watch or read free content. Ads, sponsor placements, or creator-sold inventory generate revenue. Receipts must separate playback, ad decision, ad impression, completion, fraud signals, and settlement.

Session intent can set session-level ad load, contextual ad category, and creator breadth. My Creators has low load and narrow creator-trust breadth. Trending or entertainment topic intents can allow higher contextual load and broader eligible creator breadth. Learn / Deep Dive and Wind-down / Calm use minimal ads. Search intent has no ads in search result lists. Friends and Family has no behavioral ads and strict family-safe limits.

### 4.2 Global No-Ad Premium

Fans pay for no-ad access across eligible content. Settlement allocates premium pool based on qualified consumption, creator rules, provider costs, and utility fees.

### 4.3 Creator Memberships

Creators define recurring tiers with benefits such as member-only content, community access, livestreams, early releases, badges, courses, downloads, or sponsor-free versions.

### 4.4 Tips and Boosts

Fans can give direct one-time support. Boosts may increase creator-visible support or explicitly disclosed creator/community placement, but never affect neutral public search, default fan-scoped recommendation ranking, or paid-ranking search behavior.

### 4.5 Paid Content, Events, and Courses

Creators can sell individual videos, posts, downloads, event tickets, livestream access, workshops, and courses.

### 4.5A Paid Private Mode

Fans can pay for stronger privacy defaults, including reduced data use, no external ad targeting, no AI training, and private in-vault recommendation behavior where available.

### 4.5B Premium Delivery

Fans can pay for premium bandwidth, higher resolution, downloads, or faster delivery where providers and creators support it.

### 4.6 AI Revenue

AI revenue can come from fan AI subscriptions, credits, creator archive Q&A, summaries, translation/dubbing, and source royalties.

### 4.7 Sponsorships and Campaigns

Creators can sell sponsor placements, product cards, giveaways, promo codes, reward campaigns, or sponsor-free variants.

### 4.8 Referrals and Discovery

Destination creators can publish referral terms. Source creators can earn when recommendations produce qualified engagement.

### 4.9 Provider and Developer Revenue

Providers earn through revenue share, direct fees, utility fees, certification-supported services, or marketplace sales. Developers earn through extensions, apps, AI tools, and provider services.

## 5. User Stories

### Story 1: Creator monetizes free fans

As a creator, I want free fans to generate revenue so my public content can grow reach.

End state:

- Content is ad eligible.
- Ad receipts and playback receipts are generated.
- Creator payout includes ad revenue.

### Story 2: Fan pays for no-ad premium

As a fan, I want no-ad access across eligible creators so I can improve my experience while supporting creators.

End state:

- Premium entitlement exists.
- No-ad playback receipts allocate value.
- Fan can see subscription status.

### Story 3: Creator launches membership tiers

As a creator, I want paid tiers so fans can support me directly.

End state:

- Membership tiers are published.
- Fan Wallet sells memberships.
- Entitlement Ledger gates member benefits.

### Story 4: Sponsor funds a campaign

As a sponsor, I want to fund a creator campaign and measure performance without unrestricted fan data or raw follower-list extraction.

End state:

- Campaign terms and disclosure are set.
- Fan data grants are explicit.
- Sponsor receives permitted reporting.

### Story 5: Creator earns AI royalties

As a creator, I want to earn when AI uses my content as a source.

End state:

- AI policy allows usage.
- Source attribution receipts are generated.
- Settlement allocates AI royalties.

### Story 6: Creator earns referral revenue

As a creator, I want to earn from trusted recommendations when they drive qualified engagement.

End state:

- Recommendation and referral terms are published.
- Discovery receipts are generated.
- Referral settlement occurs.

### Story 7: Fan pays for private data mode

As a fan, I want to pay for stronger privacy so my raw behavior is not exported for ad targeting, broad recommendations, or AI training.

End state:

- `PrivateVaultEntitlement` is active.
- `DataUseGrant` defaults are narrowed.
- Settlement allocates subscription value and utility fees.

### Story 8: Creator sells paid event, course, bundle, or commerce offer

As a creator, I want to sell events, courses, bundles, products, or affiliate offers.

End state:

- Entitlements or commerce terms are recorded.
- Payment and conversion receipts are generated.
- Refunds and chargebacks can adjust settlement.

## 6. End-to-End Workflows

### Workflow 1: Configure monetization for content

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- Fan App
- Playback Service
- Settlement Engine

Steps:

1. Creator selects content monetization mode.
2. Creator Studio validates ad, membership, premium, sponsor, AI, and paid access rules.
3. `MonetizationManifest` is updated.
4. Fan App displays access and payment options.
5. Playback or content access service enforces rules.
6. Receipts are generated.
7. Settlement applies manifest version.

`MonetizationManifest` defines product eligibility, pricing, access modes, and creator-facing monetization rules. `SettlementManifest` defines revenue splits, required receipts, utility fees, provider allocations, and payout rules. `HostingContractManifest` defines provider economics for hosting-related services.

### Workflow 2: Free ad-supported revenue

Actors:

- Fan
- Fan App
- Ad Decision Service
- Content Host
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan opens free content.
2. Ad Decision Service selects eligible ad.
3. Content and ad are delivered.
4. Playback, ad, completion, and delivery receipts are generated.
5. Fraud checks run.
6. Settlement allocates revenue to creator, host, ad provider, app, and utilities.

### Workflow 3: Membership monetization

Actors:

- Creator
- Fan
- Fan Wallet
- Entitlement Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator publishes membership tier.
2. Fan buys membership.
3. Entitlement Ledger records access.
4. Fan consumes member content.
5. Membership and usage receipts are generated.
6. Settlement allocates recurring revenue.

### Workflow 3A: Global no-ad premium

Actors:

- Fan
- Fan Wallet
- Payment Provider
- Entitlement Ledger
- Playback Service
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan buys global no-ad premium.
2. `PaymentReceipt` is generated.
3. Entitlement Ledger records `PremiumNoAdEntitlement`.
4. Fan watches eligible content.
5. `PremiumNoAdAPI` authorizes no-ad playback.
6. `PremiumNoAdReceipt` records qualified consumption.
7. Settlement Engine applies `SettlementManifest` and `UtilityFeePolicy`.
8. `FanSubscriptionAllocationStatement` shows support allocation where applicable.

### Workflow 3B: Paid private mode

Actors:

- Fan
- Fan Wallet
- Core Fan Vault
- Private Event Vault
- Recommendation Engine
- AI Gateway
- Settlement Engine

Steps:

1. Fan buys private data mode.
2. Entitlement Ledger records `PrivateVaultEntitlement`.
3. `DataUseGrant` defaults are narrowed.
4. Private Event Vault keeps behavior inside purpose-bound controls.
5. `PrivateRankingAPI` handles private recommendations where enabled.
6. External ad targeting and broad raw behavior export are disabled.
7. AI Gateway applies no-training and limited-memory defaults.
8. `DataAccessReceipt` records sensitive access.
9. Settlement allocates private subscription revenue and utility fees.

### Workflow 3C: Paid content, events, courses, bundles, gifts, and commerce

Actors:

- Creator
- Fan
- Fan Wallet
- Payment Provider
- Entitlement Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator publishes paid content, event, course, bundle, gift, or commerce offer.
2. Relevant contract is created, such as `PaidContentEntitlement`, `EventTicketEntitlement`, `CourseEntitlement`, `BundleManifest`, `BundleEntitlement`, `CommerceOfferManifest`, or `AffiliateTermsManifest`.
3. Fan purchases or gifts the product.
4. `PaymentProviderAPI` creates `PaymentReceipt`.
5. Entitlement Ledger records access or gift state.
6. Commerce or affiliate conversions create `CommerceConversionReceipt`.
7. Refunds or chargebacks create `RefundChargebackRecord`.
8. Settlement allocates creator, provider, affiliate, and utility amounts.

### Workflow 4: AI source royalty

Actors:

- Fan or Creator
- AI Gateway
- Creator Metadata Host
- Receipt Ledger
- Settlement Engine

Steps:

1. AI request uses creator content under approved policy.
2. AI Gateway records provider, source content, and usage type.
3. AIUsageReceipt and SourceAttributionReceipt are generated.
4. Settlement applies AI royalty rules.
5. Creator sees AI revenue and source usage.

### Workflow 5: Sponsor campaign monetization

Actors:

- Sponsor
- Creator
- Fan
- Campaign Extension
- Campaign Ledger
- Settlement Engine

Steps:

1. Sponsor and creator agree campaign terms.
2. `CampaignManifest` and `CampaignComplianceManifest` define rewards, eligibility, disclosures, data grants, alternate entry, and payment terms.
3. Fans participate.
4. Fans grant `CampaignDataGrant` where needed.
5. `DataAccessReceipt`, `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `RewardReceipt`, and `ConversionReceipt` are generated where relevant.
6. Clean-room reporting and revocation rules apply.
7. Settlement allocates sponsor funds and extension fees.
8. Sponsor and creator receive reports.

### Workflow 6: Referral monetization

Actors:

- Source Creator
- Destination Creator
- Fan
- Recommendation Engine
- Receipt Ledger
- Settlement Engine

Steps:

1. Destination creator publishes ReferralTermsManifest.
2. Source creator publishes RecommendationManifest.
3. Fan engages with destination creator.
4. Qualified discovery or referral receipt is generated.
5. Settlement applies referral window, caps, and fraud checks.
6. Source and destination creators see referral results.

## 7. Cross-Area Interactions

- Revenue, Receipts, Ledgers, and Settlement: `ReceiptIngestAPI`, `ReceiptLedger`, `SettlementManifest`, and `SettlementEngineAPI` convert monetization events into payouts.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `FanWalletAPI`, `EntitlementLedgerAPI`, and typed entitlements power fan payments.
- Hosting Provider Lifecycle and Progressive Unbundling: `HostingContractManifest` and hosting tier affect revenue share and direct costs.
- Creator Plugins / Extensions / Campaign Layer: `ExtensionManifest`, `ExtensionUsageReceipt`, and extension billing create new monetization surfaces.
- AI Layer: `AIUsageReceipt`, `SourceAttributionReceipt`, and `AICreditEntitlement` create source royalties and credits/subscriptions.
- Creator-Led Recommendation Economy: `ReferralTermsManifest`, `DiscoveryReceipt`, and `CreatorReferralReceipt` generate discovery revenue.
- Brand/Sponsor/Advertiser Tools: `SponsorCampaignAPI`, `SponsorDeliveryReceipt`, and `SponsorCampaignStatement` support sponsor campaigns and creator-sold ads.
- Business Model and Incentive Design: `MarketplaceFeePolicy`, `UtilityFeePolicy`, and `FoundationFundingPolicy` define fees and incentives.
- Neutral Public Search Utility: `SearchReceipt` and `SearchUtilityFundingPolicy` cannot create search ads, paid ranking, per-click search monetization, or ordering advantages.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Monetization configuration

- `MonetizationManifest`: ads, no-ad eligibility, memberships, paid content, tips, AI royalties, sponsor rules, referral eligibility, and provider revenue shares.
- `MembershipTierManifest`: recurring tier prices, benefits, renewal terms, trials, and access.
- `SettlementManifest`: revenue splits, required receipts, utility fees, provider allocations, and payout rules.
- `HostingContractManifest`: hosting provider economics and service costs.
- Creator Monetization Dashboard: product setup, status, conversion, revenue, and warnings.
- Pricing Rules Service: currency, region, taxes, discounts, trials, bundles, and creator-set prices.
- Access Mode Rules: public, free-with-ads, member-only, paid, premium, event, course, sponsor-free, or AI-enabled.

#### Wallet and payment systems

- `FanWalletAPI`: subscriptions, memberships, tips, boosts, gifts, AI credits, private mode, premium delivery, paid content, and paid events.
- `PaymentProviderAPI`: charges, refunds, subscriptions, cancellation, tax/reserve rules, and payment receipts.
- `MerchantOfRecordContract`: payment/legal responsibility.
- `PaymentReceipt`: proof of payment.
- `PayoutProviderAPI`: provider interface for payout account readiness, payout methods, and payout provider status.
- `PayoutAPI`: payout execution or simulation.
- `PayoutInstructionAPI`: payout destination and routing instructions.
- `TaxReservePolicy`: taxes and reserves.
- `ChargebackAPI`: chargeback intake, status, evidence, and representment workflow.
- `RefundChargebackRecord`: payment dispute and refund adjustment evidence.
- `EntitlementLedgerAPI`: signed access claims for paid and premium modes.
- `PremiumDeliveryEntitlement`: paid access to enhanced delivery quality or reliability.
- `PaidContentEntitlement`: access right for one-off paid posts, videos, newsletters, or downloads.
- `EventTicketEntitlement`: access right for paid live events.
- `CourseEntitlement`: access right for paid courses or learning bundles.
- `PrivateVaultEntitlement`: access right for premium private mode and stricter vault processing.
- `BundleEntitlement`: access right for bundled products or creator packages.
- `TipReceipt`: voluntary fan support event.
- `BoostReceipt`: voluntary boost event that can support a creator without buying search ranking.
- `CommerceConversionReceipt`: permitted commerce or affiliate conversion event.
- Gift receipts: gifted membership, content, event, or support events.

#### Ad and sponsor systems

- `AdDecisionAPI`: eligible ads, sponsor disclosures, targeting constraints, and invalid traffic checks.
- `SponsorCampaignAPI`: sponsor offers, product cards, promo codes, conversion tracking, and aggregate reporting.
- `SponsorDisclosurePolicy`: fan-facing labels and compliance.
- `CampaignDataGrant`, `CampaignComplianceManifest`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `DataAccessReceipt`, `SponsorDeliveryReceipt`, `ConversionReceipt`, and `SponsorCampaignStatement`: sponsor data rights, reporting, audience-export limits, and settlement.
- `CleanRoomMeasurementAPI`: campaign performance without unrestricted fan data export.

#### AI monetization systems

- `AIContentPolicy`: source usage permissions, summaries, Q&A, training, no-training defaults, and royalties.
- AI Gateway: provider calls and usage metering.
- `AIUsageReceipt`: usage for billing and audit.
- `SourceAttributionReceipt`: creator source credit and royalty basis.
- AI Credit Entitlement: fan or creator access to AI features.

#### Referral and extension systems

- `RecommendationManifest`: source creator recommendations.
- `ReferralTermsManifest`: destination creator payout terms.
- `CreatorReferralReceipt`: qualified referral events.
- `CommerceOfferManifest`: commerce offer terms, product metadata, price, and conversion policy.
- `AffiliateTermsManifest`: affiliate attribution, payout, disclosure, and conversion terms.
- `BundleManifest`: bundled content, membership, commerce, or event terms.
- `ExtensionBillingSystem`: extension purchase, subscription, usage, or campaign fee models.
- `CampaignLedgerAPI` and `RewardLedgerAPI`: campaign monetization and reward receipts.

#### Settlement systems

- `ReceiptLedger`: all monetization receipt ingestion.
- `SettlementEngineAPI`: revenue allocation by manifest and contract.
- `CreatorPayoutStatement`: creator gross-to-net.
- `ProviderPayoutStatement`: provider service revenue.
- `FanSubscriptionAllocationStatement`: premium/no-ad allocation.
- `UtilityFeePolicy` and `UtilityFundingReceipt`: shared infrastructure funding. Utility fees for search cannot create search ads, paid ranking, per-click search monetization, or ordering advantages.
