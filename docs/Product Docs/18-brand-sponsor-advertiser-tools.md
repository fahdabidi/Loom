# Loom Product Definition 18: Brand/Sponsor/Advertiser Tools

Status: Draft for review  
Product area: 18 of 22  
Depends on: 04 Creator Channel and Metadata Architecture; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 09 Monetization Models; 10 Creator Plugins / Extensions / Campaign Layer; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 17 Trust, Safety, Fraud, and Compliance

## 1. Product Definition

Brand/Sponsor/Advertiser Tools let sponsors work directly with creators through transparent, measurable, permissioned campaigns. Loom should support sponsor activations, product cards, giveaways, promo codes, creator-sold ads, sponsor-free variants, brand-safe reporting, and campaign measurement without giving advertisers unrestricted fan data.

The creator should control sponsor relationships. Fans should see disclosures and understand data grants. Sponsors should get useful measurement through receipts, aggregate reporting, and clean rooms.

Sponsor inventory is creator-opt-in B2B inventory. It is separate from neutral public search and fan recommendation ranking. Public campaign exposure can be searchable only through `SearchAccessPolicy`, `PublicSearchResultSchema`, and `SponsorDisclosurePolicy`, with no paid routing, merge priority, or ordering advantage.

## 2. Scope

This product area covers:

- Sponsor Dashboard.
- Sponsor campaign setup.
- Creator sponsor inventory.
- Creator-sold ads.
- Product cards and promo codes.
- Giveaways and campaign sponsorship.
- Sponsor disclosures.
- Sponsor-free variants.
- Brand safety labels.
- Campaign clean-room measurement.
- Aggregate and permissioned reporting.
- Sponsor delivery, campaign entry, conversion, and reward receipts.
- Click and interaction metrics as aggregate reporting, not a default paid-click receipt.
- Campaign compliance manifests.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator-controlled sponsors | Creators approve sponsor campaigns and inventory. | Keeps brand relationships creator-owned. | Creator Experience |
| Permissioned measurement | Sponsors receive aggregate or explicitly granted data only. | Protects fans while enabling sponsor ROI. | Audience Data Firewall and Data Rights |
| Sponsor data boundaries | Sponsors cannot pressure creators or tools to export follower lists, direct-contact data, or private relationship state outside valid grants. | Prevents sponsor-driven fan-data extraction. | Trust, Safety, Fraud, and Compliance |
| Campaign extensions | Sponsor campaigns can run through certified extensions. | Supports interactive activations. | Creator Plugins / Extensions / Campaign Layer |
| Sponsor disclosures | Fan-facing labels identify sponsored content or offers. | Builds trust and compliance. | Trust, Safety, Fraud, and Compliance |
| Clean-room reporting | Sponsors measure performance without raw data export. | Enables privacy-preserving advertising. | Audience Data Firewall and Data Rights |
| Sponsor receipts | Delivery, entry, conversion, and reward events are auditable; clicks are aggregate interaction metrics unless explicitly mapped to a permitted conversion. | Supports settlement and reporting without search-style per-click incentives. | Revenue, Receipts, Ledgers, and Settlement |
| Sponsor-free variants | Creators can offer premium sponsor-free versions. | Aligns fan premium value and creator monetization. | Monetization Models |

## 4. Product Experience Requirements

Sponsors should:

- Find eligible creator-opt-in inventory where marketplace is enabled.
- Propose campaigns or accept creator offers.
- Configure product cards, promo codes, giveaway rewards, and conversion goals.
- See disclosures and compliance requirements.
- Receive aggregate reporting and permitted conversion data.
- Avoid raw follower-list, direct-contact, or private relationship exports unless a valid fan grant explicitly allows them.

Creators should:

- Approve or reject sponsors.
- Control placement, disclosure, timing, and fan experience.
- See sponsor revenue and obligations.
- Offer sponsor-free variants where desired.

Fans should:

- See sponsor disclosures.
- Understand campaign terms and data grants.
- Participate voluntarily.
- Access alternate entry where required.

## 5. User Stories

### Story 1: Sponsor proposes campaign

As a sponsor, I want to propose a campaign to a creator so I can reach that creator's audience.

End state:

- Sponsor campaign proposal is created.
- Creator reviews terms and disclosure.
- Accepted campaign becomes a `CampaignManifest`.

### Story 2: Creator sells product card

As a creator, I want to attach a sponsor product card to content.

End state:

- Product card is configured.
- Sponsor disclosure is shown.
- Delivery and conversion receipts are generated where permitted.

### Story 3: Fan joins sponsor giveaway

As a fan, I want to join a sponsored giveaway with clear data terms.

End state:

- Fan sees sponsor and data grant.
- Campaign entry is recorded.
- Reward state is tracked.

### Story 4: Sponsor receives report

As a sponsor, I want campaign reporting without receiving raw fan data.

End state:

- Sponsor dashboard shows aggregate delivery, engagement, conversion, and reward metrics.
- Clean room or permissioned reporting is used.

### Story 5: Creator offers sponsor-free version

As a creator, I want to offer premium fans a sponsor-free version.

End state:

- Content manifest points to sponsor-free variant.
- Entitlements determine access.
- Settlement reflects sponsor and premium terms.

## 6. End-to-End Workflows

### Workflow 1: Sponsor campaign setup

Actors:

- Sponsor
- Sponsor Dashboard
- Creator
- Creator Studio
- Campaign System
- Governance/Compliance

Steps:

1. Sponsor creates campaign proposal.
2. Sponsor defines objective, budget, product, target creator, required disclosures, reporting needs, data needs, and sponsor obligations; raw follower-list, direct-contact, or private relationship exports are rejected unless valid fan grants allow them.
3. `SponsorCampaignAPI` verifies sponsor/provider certification scope for campaign, ad-decision, clean-room, reporting, and receipt-signing roles.
4. Creator reviews terms.
5. `CampaignComplianceManifest` defines eligibility, age/region rules, odds/rules, alternate entry, rewards, data use, brand-safety constraints, and dispute paths.
6. `EligibilityAPI`, `ModerationLabelAPI`, and `SafetyPolicyManifest` checks run.
7. Creator accepts and configures campaign.
8. `CampaignManifest`, `SponsorDisclosurePolicy`, and compliance rules are stored.
9. Campaign becomes active or enters `Limited`, `Paused`, `Corrected`, or `Ended` state if compliance requires it.

### Workflow 2: Fan campaign participation

Actors:

- Fan
- Fan App
- Campaign Extension
- Audience Data Firewall
- Campaign Ledger
- Reward Ledger

Steps:

1. Fan sees sponsored campaign with disclosure.
2. Fan opens terms, eligibility, reward, and data grant.
3. `EligibilityAPI` checks eligibility without exporting raw Private Event Vault data.
4. Fan accepts `CampaignDataGrant` or uses `AlternateEntryMethodPolicy`.
5. `ConsentGrantAPI` and `DataUseGrant` record purpose, scope, duration, destination, and revocation behavior where broader data access is needed.
6. Campaign Ledger records `CampaignEntryReceipt`.
7. Reward Ledger records reward state through `RewardReceipt` where applicable.
8. `DataAccessReceipt` records grant-protected sponsor or clean-room access.
9. Fan access history shows campaign grants, access receipts, retained receipt exceptions, and revocation controls.
10. Sponsor reporting receives only permitted aggregate, clean-room, or conversion data; `FollowVisibilityPolicy` and `DirectContactGrant` prevent sponsor access to restricted follower or direct-contact data.

### Workflow 2A: Sponsor request for audience data is narrowed or denied

Actors:

- Sponsor
- Creator
- Sponsor Dashboard
- Creator Studio
- Audience Data Firewall
- CleanRoomMeasurementAPI
- Governance/Compliance

Steps:

1. Sponsor requests a follower list, direct-contact data, lookalike file, or private relationship segment.
2. Sponsor Dashboard classifies the request as raw audience export, clean-room measurement, aggregate reporting, or explicitly granted campaign data.
3. `AudienceDataFirewallPolicy` checks `FollowVisibilityPolicy`, `DirectContactGrant`, `CampaignDataGrant`, `DataUseGrant`, and `CreatorAudienceExportPolicy`.
4. If raw export is not permitted, Sponsor Dashboard returns a clean-room, aggregate, or alternate campaign option instead of a follower list.
5. If explicit fan grants allow limited data, `DataAccessReceipt` records the sponsor/clean-room access and retention rules.
6. Suspicious sponsor pressure, resale terms, or repeated denied requests route to governance through sponsor/provider audit evidence.

### Workflow 3: Sponsor reporting and settlement

Actors:

- Sponsor Dashboard
- Campaign Ledger
- Receipt Ledger
- Settlement Engine
- Creator Studio

Steps:

1. Signed campaign receipts are submitted through `ReceiptIngestAPI`.
2. Receipt validation checks app/provider keys, certification scope, API version, key status, and effective `CampaignManifest`, `CampaignComplianceManifest`, `SponsorDisclosurePolicy`, and `SettlementManifest` versions.
3. Fraud scoring and compliance checks attach holds, exclusions, or `FraudAdjustmentRecord` where needed.
4. Metrics are aggregated and filtered by permissions through `CleanRoomMeasurementAPI`.
5. Sponsor sees delivery, interaction, conversion, entry, and reward reporting; clicks are reported as aggregate interaction metrics unless a campaign explicitly maps them to a permitted conversion.
6. Settlement Engine allocates sponsor funds to creator, extension developer, providers, and utilities.
7. `SettlementRunRecord`, `SponsorCampaignStatement`, and creator payout statements show spend, receipts, adjustments, and payout status.

### Workflow 4: Sponsor-free premium variant

Actors:

- Creator
- Fan
- Fan App
- Entitlement Ledger
- Content Host

Steps:

1. Creator configures sponsor-free variant.
2. `ContentManifest` and `MonetizationManifest` define access.
3. Fan with eligible entitlement opens content.
4. Fan App plays sponsor-free version.
5. Premium or membership receipts support replacement revenue.

## 7. Cross-Area Interactions

- Creator Experience: creators approve and manage `CampaignManifest`, `SponsorDisclosurePolicy`, and sponsor placements in Creator Studio.
- Fan Experience: fans see `SponsorDisclosurePolicy`, campaign terms, `CampaignDataGrant`, and `AlternateEntryMethodPolicy`.
- Creator Channel and Metadata Architecture: `ContentManifest`, `MonetizationManifest`, and `SearchAccessPolicy` define sponsor-related content state.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `CampaignDataGrant`, rewards, and entitlements depend on fan identity and wallet state.
- Provider Marketplace and Certified APIs: sponsor, clean-room, ad-decision, reporting, and receipt-signing roles need `CertificationScopeRecord`.
- Revenue, Receipts, Ledgers, and Settlement: `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `RewardReceipt`, `ConversionReceipt`, and `SponsorCampaignStatement` settle.
- Monetization Models: `SponsorCampaignAPI`, sponsor receipts, and sponsor-free premium entitlements define sponsor revenue and premium alternatives.
- Creator Plugins / Extensions / Campaign Layer: campaigns often run through `ExtensionManifest`, `CampaignLedgerAPI`, and `ExtensionRuntimeGateway`.
- Neutral Public Search Utility: sponsor inventory cannot buy `SearchDirectoryAPI` routing, `NeutralSearchMergePolicy` priority, or public search ranking.
- Audience Data Firewall and Data Rights: sponsor data access is permissioned by `DataUseGrant`, `CampaignDataGrant`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `DataAccessReceipt`, and `CleanRoomMeasurementAPI`.
- Trust, Safety, Fraud, and Compliance: `CampaignComplianceManifest`, `EligibilityAPI`, `ModerationLabelAPI`, and `SafetyPolicyManifest` enforce rules.
- Fan Apps and App Ecosystem: apps display `SponsorDisclosurePolicy`, enforce `CampaignDataGrant`, and generate `CampaignEntryReceipt` and sponsor receipts.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `SponsorDashboard`: campaign setup, reporting, budget, compliance, and invoices.
- `SponsorCampaignAPI`: proposals, campaign setup, creator approvals, and reporting.
- `CreatorSponsorInventoryAPI`: creator-approved placements and terms, separate from neutral search and fan recommendation ranking.
- `CampaignManifest`: campaign rules, sponsor terms, eligibility, rewards, and dates.
- `CampaignComplianceManifest`: legal, regional, age, giveaway, and alternate entry requirements.
- `SponsorDisclosurePolicy`: labels and disclosure requirements.
- `ProductCardAPI`: sponsor products, links, promo codes, and offers.
- `EligibilityAPI`: campaign eligibility checks.
- `AlternateEntryMethodPolicy`: required alternate entry rules for giveaways and regulated campaigns.
- `CampaignDataGrant`: fan campaign permissions.
- `FollowVisibilityPolicy`: fan relationship visibility state that sponsor tools and reporting must respect.
- `DirectContactGrant`: explicit fan permission required before direct-contact data can be exported or used in sponsor-linked creator campaigns.
- `CreatorAudienceExportPolicy`: field, destination, retention, no-resale, watermarking, and breach-notice rules that block sponsor-driven follower-list extraction.
- `ConsentGrantAPI`: fan grant and revocation lifecycle.
- `DataUseGrant`: broader sponsor/clean-room access purpose, scope, duration, and destination.
- `DataAccessReceipt`: sponsor/clean-room data access audit.
- `CleanRoomMeasurementAPI`: aggregate or permissioned reporting.
- `SponsorDeliveryReceipt`: sponsor impression or delivery event.
- `CampaignEntryReceipt`: campaign entry event.
- `ConversionReceipt`: permitted conversion or promo-code event.
- `RewardReceipt`: reward issuance/redemption.
- `ReceiptIngestAPI`: signed campaign receipt validation and ledger submission.
- `SettlementManifest`: sponsor revenue routing, fees, adjustments, and required receipt rules.
- `SettlementRunRecord`: campaign settlement run output.
- `SponsorCampaignStatement`: sponsor-facing reporting and spend.
- `ProviderCertificationAPI`: sponsor/campaign provider certification.
- `CertificationScopeRecord`: role, API-version, key, and certification state.
- `ProviderKeyManagementAPI`: receipt-signing and provider key lifecycle.
- `ProviderAuditAPI`: sponsor, clean-room, reporting, and data-use audit evidence.
- `ModerationLabelAPI`: brand-safety and compliance labels.
- `SafetyPolicyManifest`: sponsor/content safety state.
