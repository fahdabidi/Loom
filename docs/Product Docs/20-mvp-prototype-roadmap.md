# Loom Product Definition 20: MVP / Prototype Roadmap

Status: Draft for review  
Product area: 20 of 22  
Depends on: 01 Core Thesis and Platform Principles; 04 Creator Channel and Metadata Architecture; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 06 Hosting Provider Lifecycle and Progressive Unbundling; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 10 Creator Plugins / Extensions / Campaign Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 15 Fan Apps and App Ecosystem; 16 Developer Ecosystem and DevOps Supply Chain; 17 Trust, Safety, Fraud, and Compliance; 19 Governance, Certification, and Foundation Model

## 1. Product Definition

The MVP / Prototype Roadmap defines the smallest credible Loom prototype that proves the core product thesis: creator-owned channels, fan-owned identity, swappable provider boundaries, neutral search, creator-led recommendations, signed receipts, settlement simulation, extension customization, and export/migration.

The MVP should not try to replace every social platform. It should prove the architecture and product experience through a narrow end-to-end slice.

## 2. Scope

This product area covers:

- Prototype scope.
- V1 system set.
- Sequencing.
- Acceptance criteria.
- What to simulate versus implement.
- End-to-end demo workflows.
- Risks and deferrals.

## 3. Key Features to Prove First

| Feature | Prototype proof |
| --- | --- |
| Creator Channel | Creator can create portable channel and export metadata. |
| Fan Passport | Fan can create identity, follow creator, and use entitlements. |
| Content publishing | Creator can publish basic video/post metadata and playback references. |
| Managed hosting | Prototype has a basic content host and hosting contract. |
| Receipts | Typed receipts can be generated with signature stubs, manifest-version binding, certification-scope checks, and ledger ingest; only external money movement is simulated. |
| Settlement simulator | Revenue allocation is explainable from receipts and manifests. |
| Neutral search | Fan can search public catalog with no paid ranking. |
| Recommendations | Destination creator can publish referral terms, source creator can publish recommendation manifest, and discovery/referral receipts can be generated. |
| Extension | Creator can install one poll/giveaway extension with signed artifact checks, certification scope, fail-closed runtime, and scoped permissions. |
| AI | Basic summary/search over transcript or metadata where available. |
| Export | Creator metadata export proves portability. |
| Provider registry | Basic provider capability manifest and certification sandbox. |

## 4. MVP System Set

Required V1 systems:

- Creator Channel Registry.
- Creator Metadata Host.
- Basic Content Host.
- Minimal `ProviderCapabilityRegistry`.
- `ProviderCapabilityManifest`, `ProviderRoleGrant`, `HostingContractManifest`, `SettlementManifest`, and manifest validation.
- Fan Passport Ledger.
- `FanPassportClaim`.
- Core Fan Vault.
- `ConsentGrantAPI`, `AppPermissionGrant`, `DataUseGrant`, `CampaignDataGrant`, and `DataAccessReceipt`.
- `FollowRelationshipAPI`, `FollowVisibilityPolicy`, `DirectContactGrant`, `PairwiseIdentityAPI`, `CreatorAudienceExportPolicy`, and basic Creator Audience Vault wiring.
- Entitlement Ledger.
- Basic Fan App.
- Minimal `AppCapabilityManifest`, `AppCertificationAPI`, and `CertificationScopeRecord`.
- Creator Studio.
- Receipt Ledger.
- `ReceiptIngestAPI` with typed schemas, signature stubs, manifest-version binding, and key/certification-scope validation.
- Settlement Simulator.
- `HostPublicSearchAPI`, `SearchDirectoryAPI`, `SearchDirectoryPolicy`, `PublicSearchResultSchema`, `NeutralSearchMergePolicy`, `SearchAccessPolicy`, `OpenSearchKernelConformance`, and audit-only `SearchReceipt`.
- `ReferralTermsManifest`, `RecommendationManifest`, `RecommendationDisclosurePolicy`, `FanScopedRecommendationAPI`, `DiscoveryReceipt`, and `CreatorReferralReceipt`.
- `ExtensionRuntimeGateway`, `ExtensionArtifactAPI`, artifact signature checks, and fail-closed runtime.
- `CampaignLedgerAPI`.
- `MetadataExportAPI`, `MediaExportAPI`, and `ReceiptExportAPI`.
- Basic AI Gateway.
- Minimal `AbuseReportAPI`, `SafetyPolicyManifest`, `FraudSignalAPI`, revocation state, and `DisputeCaseRecord`.

## 5. User Stories

### Story 1: Creator publishes owned channel

As a creator, I want to create a channel and publish content that is separate from the host.

End state:

- Channel exists.
- Metadata and content host are separate.
- Export works.

### Story 2: Fan follows and watches

As a fan, I want to follow a creator and watch/read content.

End state:

- Fan Passport exists.
- Follow is recorded.
- Playback/read receipt is generated.

### Story 3: Premium no-ad simulation

As a fan, I want to simulate no-ad premium and see creator allocation.

End state:

- Premium entitlement exists.
- No-ad receipt is generated.
- Settlement simulator allocates value.

### Story 4: Creator installs giveaway extension

As a creator, I want to install a simple extension and run a campaign.

End state:

- Extension manifest exists.
- Fan grants scoped campaign permission.
- `CampaignEntryReceipt` is generated.

### Story 5: Creator recommendation

As a creator, I want to recommend another creator.

End state:

- Recommendation manifest exists.
- Fan sees recommendation.
- `DiscoveryReceipt` and eligible `CreatorReferralReceipt` can be generated.

## 6. End-to-End Prototype Workflows

### Workflow 1: Creator onboarding to public content

Steps:

1. Create creator account and channel.
2. Minimal `ProviderCapabilityRegistry` verifies `ProviderCapabilityManifest`, content/metadata host roles, and `CertificationScopeRecord`.
3. Generate `CreatorChannelManifest`, `HostingContractManifest`, `SettlementManifest`, and `ProviderRoleGrant`.
4. Attach basic metadata host and content host.
5. Publish content with `ContentManifest`, `MonetizationManifest`, `SearchAccessPolicy`, and `SafetyPolicyManifest`.
6. Fan app validates manifest versions, signatures, and provider pointers.
7. Fan app displays content.
8. Export channel metadata through `MetadataExportAPI`.

### Workflow 2: Fan follow and playback

Steps:

1. Fan creates `FanPassportClaim` and default persona.
2. Fan grants prototype app access through `ConsentGrantAPI` and `AppPermissionGrant`.
3. Fan follows creator through `FollowRelationshipAPI`.
4. `PairwiseIdentityAPI` and Creator Audience Vault record creator-scoped state.
5. Fan opens content.
6. Playback authorization runs through Entitlement Ledger.
7. `PlaybackReceipt` is generated and submitted through `ReceiptIngestAPI`.
8. Settlement simulator shows creator/provider allocation through `SettlementRunRecord`.

### Workflow 3: Search and recommendation

Steps:

1. Creator publishes public catalog entry and `SearchAccessPolicy`.
2. Host search indexes it with `PublicSearchResultSchema`.
3. Fan searches public catalog through `SearchDirectoryAPI`.
4. Search returns neutral results under `SearchDirectoryPolicy` and `NeutralSearchMergePolicy`.
5. Audit-only `SearchReceipt` is generated and cannot affect ranking or monetization.
6. Destination creator publishes `ReferralTermsManifest` where referral economics are enabled.
7. Source creator publishes `RecommendationManifest` after `RecommendationDisclosurePolicy` validation.
8. Fan opens recommendation through `FanScopedRecommendationAPI`.
9. `DiscoveryReceipt` and eligible `CreatorReferralReceipt` are generated.

### Workflow 4: Extension campaign

Steps:

1. Developer or prototype seed creates poll/giveaway extension.
2. `ExtensionArtifactAPI` stores signed artifact and prototype `CertificationScopeRecord`.
3. Creator installs extension.
4. `ExtensionRuntimeGateway` verifies artifact signature, manifest-version match, certification scope, and fails closed on invalid state.
5. Fan views campaign.
6. Fan grants campaign permission through `CampaignDataGrant`; broader access uses `DataUseGrant`.
7. `DataAccessReceipt`, `CampaignEntryReceipt`, and `RewardReceipt` are generated where applicable.
8. Settlement simulator includes campaign event if monetized.

### Workflow 5: AI summary

Steps:

1. Creator enables basic AI summary for content.
2. `AIContentPolicy` and transcript/text metadata are available.
3. Fan requests summary.
4. AI Gateway checks fan privacy/data policy where private context is used.
5. AI Gateway returns summary.
6. `AIUsageReceipt` and `SourceAttributionReceipt` are generated through `ReceiptIngestAPI`.

## 7. Sequencing

Phase 1:

- Creator Channel Registry.
- Creator Studio basics.
- Creator Metadata Host.
- Basic Content Host.
- Minimal `ProviderCapabilityRegistry`, `ProviderCapabilityManifest`, `ProviderRoleGrant`, `HostingContractManifest`, `SettlementManifest`, and manifest validation.
- Fan Passport, `FanPassportClaim`, Core Fan Vault, `ConsentGrantAPI`, `AppPermissionGrant`, `FollowRelationshipAPI`, and `PairwiseIdentityAPI`.
- Fan App basics.
- Minimal `AppCapabilityManifest`, `AppCertificationAPI`, and `CertificationScopeRecord`.

Phase 2:

- Receipt Ledger, `ReceiptIngestAPI`, typed receipt schemas, signature stubs, manifest-version binding, key/certification-scope validation, and `SettlementRunRecord`.
- Settlement Simulator.
- Fan Wallet/Entitlement simulation.
- Audience Data Firewall slice: `AudienceDataFirewallPolicy`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, revoke, and audit history.
- Search: `HostPublicSearchAPI`, `SearchDirectoryAPI`, `SearchDirectoryPolicy`, `PublicSearchResultSchema`, `NeutralSearchMergePolicy`, `SearchAccessPolicy`, `OpenSearchKernelConformance`, and `SearchReceipt`.

Phase 3:

- `ReferralTermsManifest`, `RecommendationManifest`, `RecommendationDisclosurePolicy`, `FanScopedRecommendationAPI`, `DiscoveryReceipt`, and `CreatorReferralReceipt`.
- `ExtensionRuntimeGateway`, `ExtensionArtifactAPI`, artifact signature checks, fail-closed runtime, and campaign permissions.
- `CampaignLedgerAPI`.
- Basic AI summary/search.

Phase 4:

- Export/migration.
- Provider comparison simulation.
- Governance/certification sandbox.
- Minimal trust/safety lane: `AbuseReportAPI`, takedown/safety label status, `FraudSignalAPI`, provider/app/extension revocation state, and `DisputeCaseRecord`.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- Prototype data model for creators, fans, content, manifests, providers, receipts, entitlements, campaigns, recommendations, grants, certification scopes, and trust/safety state.
- Creator Studio prototype.
- Fan App prototype.
- Creator Channel Registry.
- Creator Metadata Host.
- Basic Content Host and playback simulation.
- `ProviderCapabilityRegistry`, `ProviderCapabilityManifest`, `HostingContractManifest`, `SettlementManifest`, `ProviderRoleGrant`, and manifest validation.
- Fan Passport Ledger, `FanPassportClaim`, and basic Core Fan Vault.
- `ConsentGrantAPI`, `AppPermissionGrant`, `FollowRelationshipAPI`, `FollowVisibilityPolicy`, `DirectContactGrant`, `PairwiseIdentityAPI`, `CreatorAudienceExportPolicy`, and basic Creator Audience Vault wiring.
- `AudienceDataFirewallPolicy`, `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, revoke, relationship visibility controls, and audit history.
- Entitlement Ledger and Fan Wallet simulation.
- Receipt Ledger with core receipt schemas, `ReceiptIngestAPI`, signature stubs, manifest-version binding, key status checks, and `CertificationScopeRecord`.
- Settlement Simulator with visible allocation.
- `SearchDirectoryAPI`, `HostPublicSearchAPI`, `SearchDirectoryPolicy`, `PublicSearchResultSchema`, `NeutralSearchMergePolicy`, `SearchAccessPolicy`, `OpenSearchKernelConformance`, and audit-only `SearchReceipt`.
- `ReferralTermsManifest`, `RecommendationManifest`, `RecommendationDisclosurePolicy`, `FanScopedRecommendationAPI`, `DiscoveryReceipt`, and `CreatorReferralReceipt`.
- `ExtensionRuntimeGateway`, `ExtensionArtifactAPI`, artifact signature checks, fail-closed runtime, and `CampaignLedgerAPI`.
- Basic AI Gateway and summary workflow.
- `MetadataExportAPI`, `MediaExportAPI`, and `ReceiptExportAPI`.
- Minimal `AbuseReportAPI`, `SafetyPolicyManifest`, `FraudSignalAPI`, revocation state, and `DisputeCaseRecord`.
- Seed data and demo scripts.
- Test suite for prototype workflows.
