# Loom Product Definition 04: Creator Channel and Metadata Architecture

Status: Draft for review  
Product area: 4 of 22  
Depends on: 01 Core Thesis and Platform Principles; 02 Creator Experience

## 1. Product Definition

The Creator Channel is the core portable business object in Loom. It is the creator-owned representation of identity, public profile, content catalog, monetization settings, provider contracts, recommendation metadata, extension installs, campaign settings, AI permissions, receipt references, and migration state.

The Creator Channel must outlive any individual host, app, payment provider, ad provider, AI provider, search provider, recommendation provider, analytics provider, or extension runtime. Hosting providers may serve media, apps may display content, and service providers may process specific capabilities, but the channel remains the creator's portable business state.

## 2. Scope

This product area covers the architecture and product behavior of creator channel identity and portable metadata.

It includes:

- Canonical Creator Channel identity.
- `CreatorChannelManifest`.
- Creator public keys and signed metadata.
- Creator Metadata Host.
- Content catalog metadata.
- Content, monetization, hosting, recommendation, referral, extension, campaign, AI, search, settlement, safety, and migration manifests.
- Provider relationship pointers.
- Metadata versioning, export, backup, and migration.
- Multi-provider support without splitting creator identity.

It does not cover media storage internals, fan identity internals, or full governance processes, except where they interact with creator metadata.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator Channel as root object | Portable business object that represents the creator's owned channel. | Creator identity and catalog do not belong to a host. | Creator Experience; Core Thesis and Platform Principles |
| `CreatorChannelManifest` | Signed root contract for creator identity, metadata host, public keys, and channel state. | Enables verification, migration, and app/provider interoperability. | Governance, Certification, and Foundation Model |
| Metadata separate from media | Metadata lives in Creator Metadata Host while media can live with one or more content hosts. | Creators can switch hosts without rebuilding the channel. | Hosting Provider Lifecycle and Progressive Unbundling |
| Content Catalog API | Standard API for content metadata across videos, shorts, posts, newsletters, events, courses, livestreams, and community updates. | Apps and search can understand creator catalogs consistently. | Fan Apps and App Ecosystem; Neutral Public Search Utility |
| Manifest-based business rules | Monetization, hosting, AI, search, recommendations, extensions, campaigns, and settlement are explicit manifests. | Apps and providers enforce creator rules consistently. | Revenue, Receipts, Ledgers, and Settlement; AI Layer |
| Signed metadata versioning | Metadata updates are signed and versioned. | Supports audit, rollback, dispute handling, and migration. | Trust, Safety, Fraud, and Compliance |
| Provider relationship pointers | Channel stores current and historical provider roles. | Provider switching and unbundling are transparent. | Provider Marketplace and Certified APIs |
| Portable extension and campaign state | Extension installs and campaign config live with channel metadata. | Creator customization survives provider moves. | Creator Plugins / Extensions / Campaign Layer |
| Export and migration state | Channel records migration readiness, exports, backups, and cutovers. | Exit rights become operational. | Migration Strategy from Existing Platforms |

## 4. Product Experience Requirements

### 4.1 Creator-Facing Requirements

Creators should be able to see and manage:

- Channel identity, handle, domain, and verification status.
- Public profile and brand assets.
- Content catalog and access modes.
- Active provider stack.
- Manifests that affect monetization, AI, search, recommendations, and extensions.
- Export and migration readiness.
- Metadata health warnings, including unsigned changes, provider sync failures, or manifest validation errors.

### 4.2 App and Provider Requirements

Apps and providers should be able to:

- Resolve a Creator Channel ID.
- Verify signed channel metadata.
- Read public catalog data.
- Request authorized access to private or creator-admin metadata.
- Respect content, monetization, AI, search, safety, and extension manifests.
- Write only the metadata they are authorized to write.
- Generate receipts for relevant state changes.

### 4.3 Portability Requirements

The channel must classify state as:

- Canonical Portable State: identity, public keys, metadata host pointer, content catalog, manifest history, provider pointers, and channel ownership records.
- Required Export State: content metadata, extension state, campaign state, receipt references, settlement history, provider contracts, and migration records.
- Optional Export State: derived analytics and provider-specific enhancements.
- Non-portable Provider Runtime State: internal provider caches, implementation logs, and proprietary operational metrics outside audit requirements.

## 5. User Stories

### Story 1: Creator owns canonical channel identity

As a creator, I want a canonical channel identity so apps and providers can find my channel even if I switch services.

End state:

- Creator Channel ID exists in registry.
- `CreatorChannelManifest` names current metadata host and public keys.
- Apps resolve the channel without depending on one content host.

### Story 2: Creator separates metadata from hosting

As a creator, I want my catalog and business rules separate from media hosting so I can change hosts without losing my channel.

End state:

- Metadata host stores catalog and manifests.
- Content host stores or serves media.
- Hosting contract points to provider responsibilities.

### Story 3: Creator updates monetization rules

As a creator, I want to update monetization settings once so all apps and providers respect the same business rules.

End state:

- `MonetizationManifest` updates.
- Fan Apps, playback, ad decision, wallet, and settlement systems read the new version.
- Receipt generation follows the updated rules.

### Story 4: Creator enables AI archive Q&A

As a creator, I want to define AI permissions for my content so fans can use approved AI features and I can receive source attribution.

End state:

- `AIContentPolicy` updates.
- AI Gateway can request permitted content access.
- AI usage and source attribution receipts are generated.

### Story 5: Creator installs an extension

As a creator, I want extension install state stored with my channel so it survives app or provider changes.

End state:

- `ExtensionInstallRecord` is stored in channel metadata.
- Extension permissions are explicit.
- Export includes extension config and portable campaign state.

### Story 6: Creator migrates metadata host

As a creator, I want to move my metadata host if I outgrow or distrust my provider.

End state:

- Export package is produced.
- New metadata host validates import.
- Registry pointer updates.
- Signed migration record preserves auditability.

## 6. End-to-End Workflows

### Workflow 1: Channel creation

Actors:

- Creator
- Creator Studio
- Creator Channel Registry
- Creator Metadata Host
- Provider Capability Registry
- Content Host
- Payment/Payout Provider
- Settlement Provider

Steps:

1. Creator creates channel.
2. Registry creates Creator Channel ID and key records.
3. Creator Studio provisions or selects metadata host.
4. `CreatorChannelManifest` is generated and signed.
5. Public profile and handle/domain binding are written.
6. Provider Marketplace verifies default provider certification through `ProviderCapabilityManifest`.
7. Initial content host, payment/payout provider, and settlement provider pointers are attached.
8. `HostingContractManifest`, initial `MonetizationManifest`, and initial `SettlementManifest` are written.
9. Creator Studio shows channel identity, provider stack, payout readiness, and portability status.

### Workflow 2: Publish content metadata

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- Content Host
- `ContentCatalogAPI`
- `PublicCatalogAPI`
- Fan App

Steps:

1. Creator uploads or composes content.
2. Content Host ingests media or stores content body.
3. Creator Studio creates `ContentManifest`.
4. Creator configures access, search, AI, and monetization rules.
5. Creator Metadata Host stores metadata.
6. `ContentCatalogAPI` exposes public/private views, and `PublicCatalogAPI` exposes eligible public metadata.
7. Fan App renders content according to manifest rules.

### Workflow 3: Update channel business rules

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- Fan App
- Playback Service
- Settlement Engine

Steps:

1. Creator changes ads, memberships, premium eligibility, or sponsor rules.
2. Creator Studio validates `MonetizationManifest`.
3. Metadata Host stores signed version.
4. Playback and wallet services use the new rules.
5. Receipts reference the manifest version.
6. Settlement Engine applies the correct manifest version.

### Workflow 4: Multi-provider channel operation

Actors:

- Creator
- Metadata Host
- Content Host
- AI Provider
- Search Provider
- Settlement Provider
- Fan App

Steps:

1. Creator uses one metadata host for channel state.
2. Creator uses one or more content hosts for media.
3. AI provider accesses content only through approved AI permissions.
4. Search provider indexes only allowed public metadata.
5. Settlement provider consumes receipts tied to manifest versions.
6. Fan App resolves one channel identity and hides provider complexity from fans.

### Workflow 5: Metadata host migration

Actors:

- Creator
- Current Metadata Host
- New Metadata Host
- Creator Channel Registry
- Migration System
- Governance Admin

Steps:

1. Creator requests metadata host migration.
2. Migration System verifies export rights.
3. Current Metadata Host exports canonical portable state and required export state.
4. New Metadata Host validates manifests, signatures, and references.
5. Creator confirms cutover.
6. Registry updates metadata host pointer.
7. MigrationReceipt records the cutover.
8. Governance handles disputes if export is incomplete or invalid.

### Workflow 6: Manifest conflict or invalid update

Actors:

- Creator
- Creator Studio
- Metadata Host
- Conformance Validator
- Governance Admin

Steps:

1. Creator or provider attempts metadata update.
2. Metadata Host checks `CreatorMetadataWriteGrant`, `ProviderRoleGrant`, `AppPermissionGrant`, and manifest schema.
3. Validator rejects invalid or conflicting rules.
4. Creator Studio explains the issue.
5. Valid update is signed and versioned.
6. Permission changes, key rotation, revocation, and rejected writes generate audit records where needed.

### Workflow 7: Metadata host key rotation or recovery

Actors:

- Creator
- Creator Studio
- Creator Channel Registry
- Creator Metadata Host
- Governance Admin

Steps:

1. Creator or governance detects compromised key, expired key, or metadata host risk.
2. Creator Studio starts key rotation or recovery workflow.
3. Creator Channel Registry validates creator authority and current `CreatorChannelManifest`.
4. New public key records are added and compromised keys are revoked.
5. Metadata Host signs a new manifest version.
6. Apps and providers verify the updated key state before accepting writes.
7. Audit receipts record the rotation or recovery event.

## 7. Cross-Area Interactions

- Creator Experience: Creator Studio writes `CreatorChannelManifest`, `CreatorMetadataAPI`, `CreatorMetadataWriteGrant`, and signed metadata versions.
- Hosting Provider Lifecycle and Progressive Unbundling: `HostingContractManifest`, content-host pointers, and `ProviderRoleGrant` define provider responsibilities.
- Provider Marketplace and Certified APIs: `ProviderCapabilityManifest`, `ProviderCapabilityRegistry`, and `CertificationScopeRecord` determine attachable metadata roles.
- Revenue, Receipts, Ledgers, and Settlement: receipts reference manifest versions, `SettlementManifest`, and `SettlementRunRecord`.
- AI Layer: `AIContentPolicy`, AI source permissions, and no-training defaults live in channel metadata.
- Neutral Public Search Utility: `SearchAccessPolicy`, `PublicCatalogAPI`, and `PublicSearchResultSchema` define public search exposure.
- Creator Plugins / Extensions / Campaign Layer: `ExtensionInstallRecord`, `ExtensionManifest`, and `CampaignManifest` live with channel metadata.
- Fan Passport, Wallet, Vaults, and Identity Architecture: channel manifests define access requirements while `FanWalletAPI` and `EntitlementLedgerAPI` prove fan access.
- Migration Strategy from Existing Platforms: `MetadataExportAPI`, `MigrationManifest`, `MigrationPlanAPI`, and `ChannelMigrationRecord` rely on metadata boundaries.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Registry and identity systems

- Creator Channel Registry: create, resolve, update, and migrate Creator Channel identity.
- Creator Identity Claim: signed proof of creator/channel ownership.
- Creator Public Key Record: public keys for verifying signed manifests and receipts.
- Channel Migration Record: history of metadata/content provider changes.
- Handle and Domain Binding: public routing and creator verification.

#### Metadata systems

- `CreatorMetadataHost`: durable store for creator-owned portable business state.
- `CreatorMetadataAPI`: read/write channel metadata with authorization.
- `ContentCatalogAPI`: canonical content metadata for public and private catalog views.
- `PublicCatalogAPI`: app-facing public catalog views derived from allowed metadata.
- `HostPublicCatalogAPI`: host-level public catalog for host-owned indexes and search exposure.
- `MetadataExportAPI`: complete export of canonical portable state and required export state.
- `SignedMetadataVersioning`: version history, signatures, validation, rollback, and audit.
- `CreatorMetadataWriteGrant`: scoped permission for creator, app, or provider metadata writes.
- `ProviderRoleGrant`: provider-specific authority to update only the state for a certified role.
- `AppPermissionGrant`: app access to creator admin or public metadata.
- `KeyRotationRecord`: signing-key rotation event and new key validity window.
- `KeyRevocationRecord`: compromised provider, app, extension, or host key revocation event.

#### Core manifest contracts

- `CreatorChannelManifest`: root creator identity, metadata host, public keys, provider pointers, and channel state.
- `ContentManifest`: content metadata, access mode, media references, AI policy, and search policy.
- `MonetizationManifest`: ads, memberships, premium eligibility, AI royalties, sponsor rules, tips, and paid content.
- `HostingContractManifest`: hosting tier, revenue split, ad control, lifecycle, export, and provider obligations.
- `RecommendationManifest`: creator-authored recommendations.
- `ReferralTermsManifest`: referral payout terms.
- `ExtensionManifest`: extension surfaces, scopes, permissions, risk class, artifact certification, and data use.
- `ExtensionInstallRecord`: installed extension config and permissions.
- `CampaignManifest`: campaign rules, eligibility, sponsor terms, and rewards.
- `AIContentPolicy`: AI summary, Q&A, training, source attribution, and royalty permissions.
- `SearchAccessPolicy`: public searchability, transcript snippets, and indexing constraints.
- `SettlementManifest`: revenue allocation rules, required receipts, provider shares, utility fees, and payout requirements.
- `SafetyPolicyManifest`: moderation, safety labels, takedown requirements, age/region restrictions, and dispute behavior.
- `MigrationManifest`: export, rehydration, backup, and provider-exit terms.

`ExtensionInstallRecord` should reference the installed `ExtensionManifest` id/version, signed artifact, certification status, granted permissions, configuration, and export support.

#### Provider and app integration

- `ProviderCapabilityRegistry`: confirms which providers can host metadata, content, search, AI, settlement, and analytics roles.
- `AppPermissionGrant`: controls which apps can read or write creator metadata.
- `ManifestValidationService`: schema, version, policy, and conformance checks.
- `MetadataAuditReceipt`: receipts for sensitive metadata changes, exports, and migrations.

#### Migration and backup systems

- `CreatorExportAPI`: export channel metadata and manifests.
- `MediaExportAPI`: connect content references to media export rights.
- `ExtensionStateExportAPI`: export extension and campaign state.
- `ReceiptExportAPI`: export receipt references and settlement history.
- `BackupProviderAPI`: backup channel metadata and required export state.
- `MigrationPlanAPI`: compare source and destination provider support before migration.
