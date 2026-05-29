# Loom Product Definition 07: Provider Marketplace and Certified APIs

Status: Draft for review  
Product area: 7 of 22  
Depends on: 01 Core Thesis and Platform Principles; 04 Creator Channel and Metadata Architecture; 06 Hosting Provider Lifecycle and Progressive Unbundling

## 1. Product Definition

The Provider Marketplace lets companies, developers, and infrastructure operators compete to provide Loom services through certified, versioned, machine-readable APIs. Providers compete on price, reliability, performance, trust, terms, support, features, geography, and specialization, not on trapping creators or fans.

The marketplace is not just a listing directory. It is the product expression of Loom's open architecture: every major service role must be declared, tested, certified, observable, and replaceable.

## 2. Scope

This product area covers:

- Provider capability declarations.
- Provider marketplace listings.
- Certified APIs and conformance tests.
- Provider pricing, contracts, and terms.
- Provider public keys and signing.
- Provider scorecards, incidents, and audit status.
- Provider comparison and selection in Creator Studio and other surfaces.
- Provider certification states: `Draft`, `Submitted`, `Certified`, `Limited`, `Suspended`, `Revoked`.
- Capability-level certification for identity/passport, metadata, vaults, fan apps, content hosting, storage, transcoding, CDN, ads, payments, payouts, settlement, AI, search, recommendations, extensions, campaigns/sponsors, analytics, moderation, and backup.

It does not define every provider role in detail. Individual provider-dependent areas define deeper requirements.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Capability-level certification | Providers are certified by specific service role and API version. | Prevents broad trust claims from hiding weak capabilities. | Governance, Certification, and Foundation Model |
| Provider Capability Manifest | Machine-readable declaration of supported capabilities, versions, regions, limits, pricing, and data use. | Apps and creators can compare providers consistently. | Developer Ecosystem and DevOps Supply Chain |
| Conformance tests | Automated and manual checks validate provider behavior, including data-rights enforcement. | Certification is tested, not merely claimed. | Trust, Safety, Fraud, and Compliance |
| Marketplace listings | Public provider listings show certification, capabilities, terms, incidents, and performance. | Creators and apps can choose providers transparently. | Creator Experience |
| Provider scorecards | Reliability, support, export success, incident history, pricing, and audit signals. | Encourages competition on quality and trust. | Business Model and Incentive Design |
| Signed provider terms | Providers sign participation terms, contracts, and key records. | Supports accountability and dispute handling. | Governance, Certification, and Foundation Model |
| API versioning | Providers declare supported API versions and migration plans. | Keeps interoperability stable as the protocol evolves. | Developer Ecosystem and DevOps Supply Chain |
| Provider receipts | Service usage creates signed receipts for payment and audit. | Providers get paid for real services and can be audited. | Revenue, Receipts, Ledgers, and Settlement |
| Swappable roles | Providers can bundle services but each role remains separately declared. | Bundling does not become lock-in. | Core Thesis and Platform Principles |

## 4. Product Experience Requirements

### 4.1 Creator Marketplace Experience

Creators should be able to:

- See current provider stack.
- Compare certified alternatives by role.
- Understand cost, revenue share, data use, export rights, support, and reliability.
- Run upgrade or migration simulations.
- Choose bundled or modular providers.
- See certification status and incident history.

### 4.2 Provider Experience

Providers should be able to:

- Register provider identity and public keys.
- Publish Provider Capability Manifest.
- Accept Provider Participation Terms.
- Run conformance tests.
- Submit certification evidence.
- Prove enforcement of follow visibility, direct-contact grants, revocation, export limits, and creator-scoped tombstones where the provider handles fan or creator audience data.
- Publish pricing and terms.
- Receive service receipts and settlement statements.
- Manage incidents, audits, and version upgrades.

Provider Console should expose capability registration, certification state, API status, contracts, incidents, service metrics, signed receipts, payout statements, audit notices, and key status.

### 4.3 Developer and App Experience

Developers and apps should be able to:

- Query provider capabilities.
- Validate provider support before integration.
- Route API calls to certified providers.
- Verify provider signatures.
- Handle provider suspension or revocation.

## 5. User Stories

### Story 1: Provider certifies a hosting API

As a hosting provider, I want to certify my content host APIs so creators can trust my service and attach me to their channels.

End state:

- Provider Capability Manifest is submitted.
- Conformance tests pass.
- Certification scope is recorded.
- Marketplace listing becomes available.

### Story 2: Creator compares AI providers

As a creator, I want to compare AI providers by cost, source attribution, privacy terms, and model quality so I can choose an approved provider for archive Q&A.

End state:

- Marketplace returns certified AI providers.
- Creator sees pricing, privacy, source royalty support, and certification status.
- Creator selects provider and updates channel AI settings.

### Story 3: Fan app routes to certified search providers

As a fan app developer, I want to discover certified search providers so my app can offer neutral search without private integrations.

End state:

- App queries provider registry.
- Certified search capabilities and versions are returned.
- App calls standard search APIs.

### Story 4: Governance suspends a provider capability

As governance, I want to suspend only the faulty capability of a provider so the network can reduce risk without over-penalizing unrelated certified roles.

End state:

- Certification state changes to `Suspended` for the affected capability.
- Marketplace listing updates.
- Apps and creators receive incident notifications.
- Existing contracts follow dispute and migration rules.

### Story 5: Creator switches provider

As a creator, I want to choose a new certified provider and migrate without losing channel state.

End state:

- Provider comparison is shown.
- Migration plan validates destination support.
- Provider contract manifest updates.
- Receipts and settlement continue.

## 6. End-to-End Workflows

### Workflow 1: Provider registration and certification

Actors:

- Provider
- Developer Console
- Provider Certification System
- Governance Admin
- Marketplace Listing API

Steps:

1. Provider creates provider account.
2. Provider completes business/legal identity verification.
3. Provider submits initial keys for review.
4. Provider accepts `ProviderParticipationTerms`.
5. Provider publishes `ProviderCapabilityManifest`.
6. Provider runs local conformance tests.
7. Provider submits certification request through `ProviderCertificationAPI`.
8. Certification system runs automated tests.
9. Governance reviews manual risk items where needed.
10. `CertificationScopeRecord` is created.
11. `ProviderKeyManagementAPI` issues or activates certified signing keys for approved service roles.
12. Marketplace Listing API publishes certified capability and certification-mark/public-record status.

### Workflow 2: Creator selects a provider

Actors:

- Creator
- Creator Studio
- Provider Marketplace
- Provider
- Creator Metadata Host

Steps:

1. Creator opens provider control panel.
2. Creator selects provider role, such as hosting, AI, analytics, or ads.
3. Marketplace returns certified providers and scorecards.
4. Creator filters by region, price, terms, certification status, and export support.
5. Creator reviews the role-specific contract and required manifest changes.
6. Creator selects provider.
7. Creator Metadata Host validates certification scope and creates or updates `ProviderRoleGrant`.
8. Correct role manifest is written, such as `HostingContractManifest`, `SettlementManifest`, `AIContentPolicy`, `MigrationManifest`, or provider-specific contract.
9. Audit record is generated for the provider attachment.
10. Provider starts receiving authorized API traffic and receipts.

### Workflow 3: App discovers provider capabilities

Actors:

- Fan App
- Provider Capability Registry
- Certified Provider
- Governance System

Steps:

1. App needs a provider role, such as public search or AI.
2. App queries registry by capability and API version.
3. Registry returns certified providers and signing keys.
4. App selects provider based on policy or user choice.
5. App verifies provider responses.
6. If provider is suspended, app fails over or degrades gracefully.

### Workflow 4: Continuous provider audit

Actors:

- Governance Admin
- Provider Audit API
- Provider
- Marketplace Listing API
- Affected Creators/Apps

Steps:

1. Governance runs automated audit probe.
2. Provider returns evidence or API responses.
3. Audit detects pass, warning, or violation.
4. Marketplace scorecard updates if relevant.
5. Severe violation changes certification state to `Limited`, `Suspended`, or `Revoked`.
6. Affected creators and apps receive notice.
7. Migration or dispute workflows become available.

### Workflow 5: Provider version migration

Actors:

- Provider
- Developer Console
- Governance Admin
- Apps and Creators

Steps:

1. Protocol defines new API version.
2. Provider declares upgrade plan.
3. Provider implements and tests new version.
4. Certification scope is updated.
5. Marketplace shows supported versions and deprecation dates.
6. Apps and creators migrate before older versions are retired.

## 7. Cross-Area Interactions

- Creator Experience: creators select and compare providers through `ProviderMarketplaceAPI`, `ProviderComparisonAPI`, and Creator Studio provider controls.
- Hosting Provider Lifecycle and Progressive Unbundling: hosting tiers depend on `ProviderCapabilityManifest`, `HostingContractManifest`, and certified provider roles.
- Revenue, Receipts, Ledgers, and Settlement: provider payments depend on signed service receipts, `ReceiptIngestAPI`, `ProviderPayoutStatement`, and valid key scope.
- Developer Ecosystem and DevOps Supply Chain: `SDKRegistry`, `ConformanceTestSuite`, and `ProviderCertificationAPI` help providers certify.
- Governance, Certification, and Foundation Model: governance defines `CertificationScopeRecord`, `ProviderAuditAPI`, `ProviderKeyManagementAPI`, and suspension states.
- Trust, Safety, Fraud, and Compliance: `ProviderIncidentReport`, `DataAccessReceipt`, invalid receipts, and key revocation trigger enforcement.
- Migration Strategy from Existing Platforms: provider exit and replacement depend on `MigrationPlanAPI`, role-specific export APIs, and certified export support.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Marketplace and registry systems

- `ProviderCapabilityRegistry`: provider identities, service roles, API versions, regions, limits, terms, pricing, export support, public keys, and certification states.
- `ProviderMarketplaceAPI`: creator/app-facing marketplace browsing, filtering, and provider selection.
- `ProviderComparisonAPI`: provider side-by-side comparison across pricing, scorecards, export support, incidents, roles, and certification scope.
- `MarketplaceListingAPI`: public and creator-facing provider listings, filters, comparisons, scorecards, and incident history.
- `ProviderDiscoveryAPI`: app/provider routing by capability, version, region, and certification state.
- `ProviderConsoleAPI`: capability registration, metrics, contracts, incidents, receipts, payouts, certification state, API status, and key status.
- `ProviderScorecardService`: reliability, export success, dispute history, incident count, audit state, support metrics, and performance.

#### Certification systems

- Provider Certification API: certification applications, evidence, test results, and review status.
- Conformance Test Suite: automated tests for each API role.
- Certification Scope Record: certified capability, API version, restrictions, status, expiration, and revocation state.
- Provider Audit API: continuous checks, probes, evidence collection, and remediation tracking.
- Provider Key Management API: signing keys, rotation, suspension, revocation, and incident recovery.

#### Contract and terms systems

- Provider Capability Manifest: supported capabilities, API versions, data handling, pricing, regions, limits, and dependencies.
- Provider Participation Terms: legal, privacy, audit, export, settlement, and marketplace obligations.
- `ProviderPricingAPI`: machine-readable pricing, usage limits, revenue share, direct fees, and creator-facing summaries.
- Data Use Claims: provider statements about data processing, retention, training, resale, and third-party sharing.
- Data Processing Certification: capability-specific checks for `DataUseGrant`, `DataAccessReceipt`, `AudienceDataFirewallPolicy`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `CreatorScopedTombstoneRecord`, retention, training limits, revocation, and audit probes.

#### Role-specific certification requirements

- Search providers: `HostPublicSearchAPI`, `PublicSearchResultSchema`, `OpenSearchKernelConformance`, `SearchReceipt`, and no paid ranking, search ads, per-click monetization, or search ordering advantage.
- Recommendation providers: `FanScopedRecommendationAPI`, `CommunityRecommendationProviderManifest`, `CommunityFeedAPI`, disclosure rules, and no broad autonomous crawler behavior outside permitted candidate sources.
- Migration/export providers: `MigrationPlanAPI`, `MigrationManifest`, `MigrationReceipt`, `ChannelMigrationRecord`, `MediaExportAPI`, `ReceiptExportAPI`, export fees, final settlement, and scorecard reporting.
- Payment/payout providers: `PaymentProviderAPI`, `PayoutProviderAPI`, `PayoutAPI`, `MerchantOfRecordContract`, `PayoutInstructionAPI`, and chargeback/refund handling.

#### Integration and routing systems

- Provider SDKs: client and server SDKs for standard roles.
- API Gateway / Routing Layer: optional routing to selected providers.
- Failover Policy: behavior when a provider is suspended, down, or uncertified.
- Provider Receipt Signing: signed service receipts for settlement and audit, validated against provider certification scope, API version, service role, key status, and revocation state.
- `ReceiptIngestAPI`, `ReceiptLedger`, `SettlementManifest`, `SettlementEngineAPI`, and `ProviderPayoutStatement` integration for economic, audit, and utility-funding receipts.

#### Governance and enforcement systems

- Incident Report API: provider incidents, severity, affected capabilities, and remediation.
- Suspension and Revocation Workflow: capability-level restrictions and marketplace updates.
- Dispute Resolution API: provider disputes with creators, fans, apps, or governance.
- Public Certification Records: trust-facing status and historical changes.
