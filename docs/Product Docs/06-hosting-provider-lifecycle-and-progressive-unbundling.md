# Loom Product Definition 06: Hosting Provider Lifecycle and Progressive Unbundling

Status: Draft for review  
Product area: 6 of 22  
Depends on: 01 Core Thesis and Platform Principles; 02 Creator Experience; 04 Creator Channel and Metadata Architecture

## 1. Product Definition

The Hosting Provider Lifecycle lets creators start with free managed hosting and progressively unbundle provider roles as their business matures. A creator should not need infrastructure expertise on day one, and should not need to abandon their channel when they become large enough to control hosting, ads, CDN, storage, analytics, AI, moderation, search, or settlement relationships directly.

The same provider may serve a creator as a free managed host, growth partner, direct paid infrastructure provider, modular service provider, or self-hosting support vendor. Provider incentives should shift from lock-in to lifecycle support.

## 2. Scope

This product area covers:

- Free Managed Hosting.
- Growth Managed Hosting.
- Direct Paid Hosting.
- Modular Hosting.
- Self-host / enterprise mode.
- `HostingContractManifest`.
- Provider capability control states.
- Hosting upgrade, downgrade, and unbundling workflows.
- Ad, CDN, storage, analytics, AI, moderation, search, and lifecycle controls as they relate to hosting.
- Media export, backup, retention, and lifecycle policies.
- Cost/revenue simulations for hosting decisions.

It does not define the entire Provider Marketplace or settlement engine, but it relies on both.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Free Managed Hosting | Provider covers hosting in exchange for defined monetization rights or revenue share. | New creators can start with no infrastructure cost. | Monetization Models; Business Model and Incentive Design |
| Growth Managed Hosting | Provider offers better limits, support, analytics, or revenue terms as creator grows. | Keeps creator on a smoother maturity path. | Creator Experience |
| Direct Paid Hosting | Creator pays provider directly and controls more monetization choices. | Mature creators can improve margins and control. | Revenue, Receipts, Ledgers, and Settlement |
| Modular Hosting | Creator can unbundle content hosting from ads, CDN, storage, analytics, search, AI, or settlement. | Provider roles become swappable. | Provider Marketplace and Certified APIs |
| Self-host / enterprise | Large creator or organization can operate certified infrastructure. | Supports high-control creators without leaving Loom. | Governance, Certification, and Foundation Model |
| `HostingContractManifest` | Machine-readable contract for hosting tier, costs, revenue split, rights, lifecycle, export, and controls. | Apps and settlement can enforce hosting terms. | Creator Channel and Metadata Architecture |
| `SettlementManifest` integration | Hosting tier, revenue share, direct fees, premium no-ad replacement, utility fees, and provider cost allocation are reflected in settlement rules. | Hosting economics stay transparent through tier changes. | Revenue, Receipts, Ledgers, and Settlement |
| Control state model | Capabilities can be provider-managed, creator-controlled, delegated, or external. | Makes progressive unbundling explicit. | Provider Marketplace and Certified APIs |
| Export and exit support | Host exports media, host-held lifecycle state, delivery/export receipts, and media references while Creator Metadata Host and Receipt Ledger remain authoritative for channel metadata and receipts. | Host switching becomes real without blurring ownership. | Migration Strategy from Existing Platforms |
| Cost and revenue simulation | Creator can see impact of hosting tier or provider changes. | Makes business decisions concrete. | Creator Experience; Business Model and Incentive Design |

## 4. Hosting Tiers

### 4.1 Tier 1: Free Managed Hosting

Best for new creators.

Typical provider responsibilities:

- Media upload and storage.
- Transcoding and playback.
- CDN/delivery.
- Basic public catalog integration.
- Basic ads or provider-managed monetization.
- Basic export support.

Creator tradeoff:

- Lower setup complexity.
- Less control over ads, retention, costs, and provider choices.
- Revenue share may be higher.

### 4.2 Tier 2: Growth Managed Hosting

Best for creators with meaningful audience or revenue.

Adds:

- Higher limits.
- Better analytics.
- Improved support.
- Optional external ad provider.
- Better revenue share or predictable pricing.
- More lifecycle controls.

### 4.3 Tier 3: Direct Paid Hosting

Best for creators who want cost transparency and more control.

Adds:

- Creator pays hosting costs.
- Creator controls ad provider or no-ad strategy.
- Provider compensation is direct fee plus service receipts.
- Creator may keep more monetization upside.

### 4.4 Tier 4: Modular Provider Stack

Best for mature creators with specialized needs.

Creator can choose separate providers for:

- Storage.
- Transcoding.
- CDN.
- Playback authorization.
- Ads.
- Analytics.
- AI access.
- Search indexing.
- Moderation.
- Metadata host coordination.
- Payment/payout provider coordination.
- Settlement.
- Backup.

### 4.5 Tier 5: Self-Host / Enterprise

Best for organizations, major creators, or networks.

Requires:

- Certification.
- Conformance tests.
- Public key management.
- Audit support.
- Export support.
- Incident and dispute workflows.

## 5. User Stories

### Story 1: New creator starts free

As a new creator, I want free managed hosting so I can publish without infrastructure cost.

End state:

- Default host is attached through `HostingContractManifest`.
- Creator can publish content.
- Provider-managed monetization terms are visible.
- Export rights are declared.

### Story 2: Creator sees hosting economics

As a creator, I want to understand hosting costs and revenue share so I can decide when to upgrade.

End state:

- Creator sees delivery costs, storage, provider share, ad revenue, premium allocation, and net revenue.
- Simulation compares current tier with alternatives.

### Story 3: Creator upgrades to growth hosting

As a growing creator, I want better limits and support without migrating my whole channel.

End state:

- Hosting contract updates.
- Provider capability controls change.
- Existing content, fans, and receipts continue.

### Story 4: Creator takes over ad provider

As a mature creator, I want to use my own ad provider so I can control sponsor strategy and revenue.

End state:

- Hosting provider remains content host.
- Ad provider role is unbundled.
- Playback and settlement systems use updated provider pointers.

### Story 5: Creator switches CDN

As a creator with global audience, I want to use a different CDN so fans get better performance.

End state:

- CDN role is delegated to certified provider.
- Delivery receipts identify the new provider.
- Playback remains available in fan apps.

### Story 6: Creator exits hosting provider

As a creator, I want to leave a hosting provider if cost, reliability, or terms become unacceptable.

End state:

- Media export is available according to contract.
- Metadata remains with Creator Metadata Host.
- New host validates import.
- Channel registry and provider pointers update.

## 6. End-to-End Workflows

### Workflow 1: Free managed hosting onboarding

Actors:

- Creator
- Creator Studio
- Provider Marketplace
- Content Host
- Creator Metadata Host
- Settlement Engine

Steps:

1. Creator creates channel.
2. Creator Studio recommends free managed hosting provider.
3. Creator reviews key terms: storage limits, revenue share, ads, export, data use, and support.
4. `HostingContractManifest` is generated.
5. Creator publishes first content.
6. Host ingests media and serves playback.
7. Playback, ad, and delivery receipts flow to settlement.
8. Creator dashboard shows hosting tier and economics.

### Workflow 2: Hosting upgrade simulation

Actors:

- Creator
- Creator Studio
- Provider Marketplace
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator opens provider controls.
2. System reads recent usage, storage, delivery, ad revenue, no-ad revenue, and provider costs.
3. Provider Marketplace returns certified alternatives.
4. Creator Studio simulates revenue and cost impact by tier.
5. Creator compares managed, direct paid, modular, and self-host options.
6. Creator saves scenario or initiates change.

### Workflow 3: Upgrade from free managed to direct paid

Actors:

- Creator
- Current Host
- Creator Metadata Host
- Payment Provider
- Settlement Engine

Steps:

1. Creator chooses direct paid hosting.
2. Payment method or billing account is configured.
3. HostingContractManifest changes from revenue share to direct fee terms.
4. `SettlementManifest` updates hosting-tier revenue share, direct fee, provider cost allocation, utility fees, and premium no-ad replacement rules.
5. Ad control and monetization settings update.
6. Receipts continue with new provider cost allocation.
7. Creator dashboard shows new gross-to-net economics.

### Workflow 4: Unbundle ad provider

Actors:

- Creator
- Current Host
- External Ad Provider
- Playback Service
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator selects external certified ad provider.
2. Hosting contract is updated to remove or limit host ad control.
3. MonetizationManifest points to external ad provider.
4. Playback calls external AdDecisionAPI.
5. Ad receipts identify the external provider.
6. Settlement allocates ad revenue across creator, host, ad provider, and utilities.

### Workflow 5: Media export and host migration

Actors:

- Creator
- Current Host
- New Host
- Migration System
- Creator Metadata Host
- Creator Channel Registry
- Receipt Ledger
- Settlement Engine
- Governance Admin

Steps:

1. Creator requests host migration.
2. Migration System reads HostingContractManifest and MigrationManifest.
3. Current Host exports originals, renditions, host-held lifecycle state, delivery/export receipts, and media references according to contract.
4. `CreatorExportAPI` exports channel metadata from Creator Metadata Host where needed.
5. `ReceiptExportAPI` exports relevant delivery, export, and final settlement references from Receipt Ledger.
6. New Host imports and validates media.
7. Temporary rehydration or reference routing keeps playback available during cutover where supported.
8. Creator Metadata Host updates content host references.
9. Creator Channel Registry updates provider pointers.
10. Settlement Engine calculates final host settlement, export fees, and adjustments.
11. Creator confirms cutover.
12. MigrationReceipt records completion.
13. Governance handles failures or disputes.

### Workflow 6: Self-host certification

Actors:

- Creator or Enterprise Operator
- Developer Console
- Provider Certification System
- Governance Admin
- Provider Marketplace

Steps:

1. Operator declares self-host capability.
2. Operator implements required content host APIs.
3. Conformance tests verify ingest, playback authorization, public catalog, search, export, receipts, and safety hooks.
4. Governance reviews certification scope.
5. Self-host listing is certified for private or public use.
6. Creator attaches self-host provider role to channel.

### Workflow 7: Hosting downgrade or rollback

Actors:

- Creator
- Creator Studio
- Current Host
- Destination Host
- Creator Metadata Host
- Settlement Engine

Steps:

1. Creator requests downgrade or rollback from direct paid/modular hosting to growth or free managed hosting.
2. Creator Studio warns about control changes, including ad provider control, retention policy, export rights, lifecycle rules, support levels, and settlement terms.
3. Destination host terms are fetched through `ProviderPricingAPI` and `ProviderCapabilityManifest`.
4. Creator reviews changes to `HostingContractManifest`, `MonetizationManifest`, `SettlementManifest`, and `LifecyclePolicyAPI`.
5. Creator confirms downgrade.
6. Provider pointers and control states update.
7. Fan playback and entitlements remain continuous.
8. Settlement Engine applies new revenue-share, no-ad replacement, provider cost, and utility-fee rules from the effective date.

## 7. Cross-Area Interactions

- Creator Experience: Creator Studio exposes `HostingContractManifest`, provider selection, migration, and hosting-tier controls.
- Creator Channel and Metadata Architecture: `HostingContractManifest`, content host pointers, and provider role state live in `CreatorChannelManifest`.
- Provider Marketplace and Certified APIs: hosts are certified through `ProviderCapabilityManifest`, `ProviderCertificationAPI`, and `CertificationScopeRecord`.
- Revenue, Receipts, Ledgers, and Settlement: `CDNDeliveryReceipt`, hosting service receipts, and `SettlementManifest` affect payouts.
- Monetization Models: hosting tier influences `AdDecisionAPI`, `PremiumNoAdReceipt`, direct fees, and revenue share.
- Neutral Public Search Utility: hosts expose `HostPublicCatalogAPI`, `HostPublicSearchAPI`, `PublicSearchResultSchema`, and `OpenSearchKernelConformance`.
- Migration Strategy from Existing Platforms: `MediaExportAPI`, `MigrationPlanAPI`, `MigrationManifest`, and `MigrationReceipt` prove portability.
- Trust, Safety, Fraud, and Compliance: hosts participate in `TakedownAPI`, `SafetyPolicyManifest`, `FraudSignalAPI`, and provider incident workflows.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Hosting contracts and control

- `HostingContractManifest`: tier, provider roles, revenue share, direct fees, ad control, CDN/storage/transcoding responsibilities, lifecycle rules, export rights, support level, and settlement terms.
- `SettlementManifest`: hosting-tier revenue-share transitions, direct fees, provider cost allocation, premium no-ad replacement, utility fees, and required receipts.
- Capability Control State: provider-managed, creator-controlled, delegated, external, or self-hosted.
- Tier Upgrade/Downgrade API: structured change from one hosting tier to another.
- `ProviderPricingAPI`: machine-readable pricing, limits, usage costs, and revenue-share terms.
- Provider Comparison API: price, quality, reliability, export support, certification scope, and support.

#### Content host systems

- `ContentIngestAPI`: uploads, metadata, originals, and content validation.
- `TranscodingAPI`: renditions, thumbnails, captions, and processing state.
- `PlaybackAuthorizationAPI`: access checks against content, monetization, and fan entitlements.
- `PlaybackManifestAPI`: playable renditions, CDN references, ad mode, and restrictions.
- `CDNDeliveryReceipt`: delivery usage and provider compensation.
- `LifecyclePolicyAPI`: retention, hot/cold storage, archival, deletion, and age-out.
- `MediaExportAPI`: originals, renditions, captions, thumbnails, and content references.
- `HostPublicCatalogAPI`: host-level public catalog exposure.
- `HostPublicSearchAPI`: certified host-local search exposure.
- `OpenSearchKernelConformance`: verifies neutral host search behavior. Host search exposure must not create host-controlled paid ranking, search ads, or per-click search monetization.

#### Provider marketplace and certification systems

- Provider Capability Registry: content hosting roles, supported media types, regions, limits, export capabilities, and pricing.
- `ProviderCapabilityManifest`: declared host capabilities, versions, limits, regions, pricing, export support, and dependencies.
- `ProviderParticipationTerms`: legal, data, audit, export, and marketplace obligations.
- `ProviderCertificationAPI`: capability certification submission.
- `CertificationScopeRecord`: certified host roles, API versions, restrictions, and status.
- Conformance Test Suite: ingest, playback, catalog, search, export, receipts, and safety tests.
- Provider Audit API: reliability, export compliance, delivery reporting, and incident review.
- Provider Key Management API: signing keys for host receipts and manifests.

#### Monetization and settlement systems

- MonetizationManifest integration: ad provider, premium no-ad eligibility, memberships, paid content, and sponsor rules.
- `PremiumNoAdAPI`: premium no-ad eligibility and replacement settlement mode.
- `PremiumNoAdReceipt`: qualified no-ad consumption.
- Receipt Ledger: playback, ad, premium no-ad, delivery, storage, export, and settlement receipts.
- Settlement Engine API: allocates revenue and costs under hosting contract terms.
- `ProviderPayoutStatement`: host service revenue, direct fees, adjustments, and disputes.
- `CreatorPayoutStatement`: revenue after hosting costs and provider fees.

#### Migration and backup systems

- MigrationPlanAPI: evaluates source and destination host compatibility.
- MigrationManifest: export and rehydration terms.
- MigrationReceipt: records migration steps and cutover.
- BackupProviderAPI: backup and archive storage.
- MediaExportAPI: required for real host portability.

#### Creator-facing systems

- Creator Provider Control Panel: tier status, provider stack, control states, cost/revenue simulation, upgrade prompts, and migration controls.
- Hosting Health Dashboard: storage use, bandwidth, playback errors, regions, export readiness, provider incidents, and cost alerts.
- Provider Change Wizard: explains tradeoffs, validates dependencies, updates manifests, and monitors cutover.
