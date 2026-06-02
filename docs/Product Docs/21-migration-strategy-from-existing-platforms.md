# Loom Product Definition 21: Migration Strategy from Existing Platforms

Status: Draft for review  
Product area: 21 of 22  
Depends on: 04 Creator Channel and Metadata Architecture; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 06 Hosting Provider Lifecycle and Progressive Unbundling; 08 Revenue, Receipts, Ledgers, and Settlement; 11 AI Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights; 17 Trust, Safety, Fraud, and Compliance; 19 Governance, Certification, and Foundation Model

## 1. Product Definition

Loom should not ask creators to abandon YouTube, TikTok, Instagram, Substack, Patreon, Discord, X, Facebook, or other existing platforms on day one. Loom should first become the creator's owned home, then gradually absorb more audience, monetization, community, archive, AI-searchable, and sponsor value.

Migration is both a product strategy and a technical right. Creators and fans should be able to import, link, mirror, cross-post, capture follows, and eventually exit providers inside Loom.

Imported archive references are neutral-search eligible only when policy allows. They do not enter creator-led recommendations unless a creator explicitly includes them in a `RecommendationManifest` or a certified community feed.

## 2. Scope

This product area covers:

- Creator-owned hub strategy.
- Import public metadata.
- Link existing social accounts.
- Cross-posting and mirroring.
- Link-in-bio creator page.
- Email capture and fan follow capture.
- Membership migration support.
- Content archive import where rights/APIs allow.
- YouTube/TikTok/Instagram/X/Facebook/Substack/Patreon/Discord integrations where feasible.
- Sponsor-free/exclusive migration path.
- Creator announcement templates.
- Fan onboarding flows.
- Provider migration and exit button.
- Creator/fan export systems.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Owned creator hub | Loom starts as canonical home even before full audience migration. | Lowers switching cost. | Creator Experience |
| Import public metadata | Bring titles, links, descriptions, thumbnails, and archive references where allowed. | Gives creator immediate value. | Creator Channel and Metadata Architecture |
| Follow capture | Existing fans can follow on Loom through links, email, QR, or campaigns. | Builds portable audience gradually. | Fan Experience |
| Cross-posting | Creator can publish to Loom and promote elsewhere. | Coexists with existing platforms. | Creator Experience |
| Membership migration | Fans can move from Patreon/Substack/etc. where feasible. | Moves revenue gradually. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Archive AI/search value | Existing content can become searchable or AI-queryable where rights allow. | Creates new reason to adopt Loom. | AI Layer; Neutral Public Search Utility |
| Provider exit button | Once on Loom, creators can leave any certified provider. | Preserves long-term portability. | Provider Marketplace and Certified APIs |

## 4. Migration Stages

Stage 1: Owned presence.

- Creator page.
- Links to external platforms.
- Public profile.
- Email/follow capture.
- Basic posts and announcements.

Stage 2: Mirror and enhance.

- Import public metadata.
- Cross-post updates.
- AI-searchable archive where allowed.
- Sponsor-free or exclusive versions.

Stage 3: Monetize on Loom.

- Memberships.
- Premium no-ad.
- Paid events/courses.
- Campaigns.
- Sponsor tools.

Stage 4: Community migration.

- Fan Passport follows.
- Community surfaces.
- Rewards and campaigns.
- Direct contact permissions.

Stage 5: Provider independence.

- Hosting migration.
- Metadata export.
- Payment/payout provider control.
- Extension/campaign state portability.

## 5. User Stories

### Story 1: Creator creates owned hub

As a creator, I want a Loom home that links my existing platforms.

End state:

- Creator channel exists.
- External accounts are linked.
- Fans can follow on Loom.

### Story 2: Creator imports public archive metadata

As a creator, I want to import public metadata from existing platforms.

End state:

- Public content references are stored in catalog.
- Rights and availability are clear.

### Story 3: Creator captures fan follows

As a creator, I want my existing fans to follow me on Loom.

End state:

- Fan Passport follow records are created.
- Creator Audience Vault receives creator-scoped state.

### Story 4: Fan migrates membership

As a fan, I want to move my creator support to Loom where the creator offers migration.

End state:

- Fan Wallet records membership.
- External proof or transition logic is recorded.

### Story 5: Creator exits host provider

As a creator, I want to move from one certified host to another.

End state:

- Migration plan is generated.
- Media and metadata references migrate.
- Registry pointers update.

### Story 6: Creator drives an audience re-acquisition funnel

As a creator, I want announcement templates, a link-in-bio page, a QR code, and a shareable follow-capture landing so I can drive my existing audience to re-follow me on Loom. My follower graph cannot be imported from other platforms, so re-follows must be captured manually.

End state:

- Creator picks an announcement template and gets a rendered announcement, a link-in-bio page, and a QR code.
- A shareable capture link resolves to a creator-branded follow-capture landing.
- Fans arriving via the link can re-follow; re-follows are recorded as audit events — there is no automatic follower import and no economic receipt tied to a follow.
- `CreatorAnnouncementTemplatesAPI` and `FanFollowCaptureAPI` back the funnel; `FollowVisibilityPolicy` and pairwise identity apply.

> Identified in the [GTM Launch Gap Analysis](../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) §A(a) (MVP scope id **CE-S10**); launch scope, implemented in Phase 10. Makes the manual-conversion funnel first-class; complements Stories 1 and 3 and Workflow 1.

## 6. End-to-End Workflows

### Workflow 1: Existing creator starts owned hub

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- External Platforms
- Fan App

Steps:

1. Creator creates Loom channel.
2. Creator links existing platform accounts through `ExternalAccountLinkAPI`.
3. Creator imports public profile and allowed metadata.
4. Creator configures link-in-bio and follow capture.
5. Follow capture uses Fan Passport, `FollowRelationshipAPI`, `FollowVisibilityPolicy`, `PairwiseIdentityAPI`, explicit notification/direct-contact grants, `CreatorAudienceExportPolicy`, Creator Audience Vault state, and revocation behavior.
6. Creator publishes announcement.
7. Fans follow on Loom.

### Workflow 2: Public metadata import

Actors:

- Creator
- Import Service
- External Platform API or Export File
- Creator Metadata Host

Steps:

1. Creator selects platform import.
2. `ArchiveImportService` checks available rights, API/export support, source provenance, and rights basis.
3. `ImportPublicMetadataAPI` imports public metadata into `ExternalContentReferenceSchema`.
4. Imported references map into `ContentManifest`, `ContentCatalogAPI`, and `PublicCatalogAPI` records without claiming ownership of external content.
5. Creator reviews and edits.
6. Creator sets `SearchAccessPolicy` and `AIContentPolicy` for imported references.
7. Search records include indexability, snippet, and full-content flags with policy versions and indexing errors.
8. `AIIndexingAPI` stores source provenance and purge/revocation state where AI access is enabled.
9. Search and AI use only permitted metadata/content.

### Workflow 3: Membership migration

Actors:

- Creator
- Fan
- Fan Wallet
- External Platform
- Entitlement Ledger

Steps:

1. Creator offers membership migration.
2. Fan verifies `ExternalMembershipProof` or receives migration link.
3. Fan signs in with Fan Passport.
4. `MembershipTierMapping` maps external tier, benefits, start date, end date, overlap rules, and cancellation behavior.
5. Fan chooses Loom tier.
6. `PaymentReceipt`, `MembershipReceipt`, and `MembershipEntitlement` are created where Loom billing begins.
7. Entitlement Ledger records access and external proof retention policy.
8. Duplicate billing, refunds, chargebacks, and negative balance handling are linked to `RefundChargebackRecord` and settlement impact.
9. Creator sees migrated member.

### Workflow 4: Cross-post and exclusive migration

Actors:

- Creator
- Creator Studio
- External Platforms
- Fan App

Steps:

1. Creator publishes public teaser or mirrored content.
2. Creator designates exclusive, early, sponsor-free, AI-searchable, or member content on Loom.
3. External platforms receive link or announcement.
4. Fans come to Loom for higher-value experience.
5. Creator tracks conversion to follows/members.

### Workflow 5: Provider exit button

Actors:

- Creator
- Migration System
- Current provider by role
- Destination provider by role
- Creator Channel Registry
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator requests provider migration for a specific `providerRole`, such as metadata host, content host, payment provider, vault provider, extension host, or search/index provider.
2. `MigrationPlanAPI` reads current contracts, role-specific export obligations, destination capabilities, and `CertificationScopeRecord`.
3. Required export state is prepared by role, including manifests, catalog, media references, receipts, settlement/audit history, consent records, app permissions, extension/campaign state, failures, and dispute evidence.
4. Destination validates import.
5. Settlement Engine calculates final settlement and permitted cost-based export fees.
6. Creator confirms cutover.
7. Registry pointers update.
8. `ChannelMigrationRecord` and `MigrationReceipt` record policy versions, safety labels, takedown status, external source evidence, provider incident/export-failure evidence, and dispute references.

## 7. Cross-Area Interactions

- Creator Experience: migration starts from Creator Studio through `ExternalAccountLinkAPI`, `ImportPublicMetadataAPI`, and creator announcement tools.
- Fan Experience: fan follow and membership migration use `FollowRelationshipAPI`, `FanPassportClaim`, `ExternalMembershipProof`, and migration links.
- Creator Channel and Metadata Architecture: imported metadata, `ExternalContentReferenceSchema`, and provider pointers live in `ContentManifest` and channel metadata.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `MembershipEntitlement`, `EntitlementLedgerAPI`, `PairwiseIdentityAPI`, and fan vault state make follows and memberships portable.
- Hosting Provider Lifecycle and Progressive Unbundling: exit button depends on `MediaExportAPI`, role-specific export obligations, and `MigrationPlanAPI`.
- AI Layer: imported archive value depends on `AIContentPolicy`, `AIIndexingAPI`, source provenance, purge, and revocation records.
- Neutral Public Search Utility: imported archive search depends on `SearchAccessPolicy`, `PublicSearchResultSchema`, and policy-versioned index records.
- Revenue, Receipts, Ledgers, and Settlement: `PaymentReceipt`, `MembershipReceipt`, `RefundChargebackRecord`, and `SettlementRunRecord` handle membership and provider migration impacts.
- Creator-Led Recommendation Economy: imported references need explicit `RecommendationManifest` or certified community feed inclusion before entering recommendation surfaces.
- Audience Data Firewall and Data Rights: follow capture, direct-contact permissions, and archive access require `ConsentGrantAPI`, `DataUseGrant`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `DataAccessReceipt`, and revocation.
- Trust, Safety, Fraud, and Compliance: `SafetyPolicyManifest`, takedown status, AI purge, and `ProviderIncidentReport` support enforcement.
- Governance, Certification, and Foundation Model: provider migration depends on `CertificationScopeRecord`, `DisputeCaseRecord`, and dispute process.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `ExternalAccountLinkAPI`: YouTube, TikTok, Instagram, X, Facebook, Substack, Patreon, Discord, and others where feasible.
- `ImportPublicMetadataAPI`: titles, descriptions, thumbnails, links, timestamps, rights status, source provenance, and rights basis.
- `ExternalContentReferenceSchema`: catalog entries that point to external content without claiming ownership.
- `ContentManifest`, `ContentCatalogAPI`, and `PublicCatalogAPI`: imported reference publication and catalog integration.
- `SearchAccessPolicy`: policy-versioned indexability, snippet, and full-content flags.
- `AIContentPolicy`: imported-source AI use, retention, revocation, and no-training rules.
- `AIIndexingAPI`: imported-source indexing, provenance, purge, and revocation records.
- `CrossPostingTools`: announcements, links, previews, and mirrored posts where allowed.
- `FanFollowCapture`: links, QR, campaign capture, Fan Passport follow, fan-selected follow visibility, explicit contact grant, and revocation.
- `FollowVisibilityPolicy`: fan-selected relationship visibility applied during migrated follow capture.
- `DirectContactGrant`: explicit fan permission required before migrated followers can be contacted directly or exported to CRM flows.
- `CreatorAudienceExportPolicy`: export and destination constraints for creator audience data captured during migration.
- `ConsentGrantAPI`, `DataUseGrant`, and `DataAccessReceipt`: permissioned direct-contact and archive access evidence.
- `FollowRelationshipAPI` and `PairwiseIdentityAPI`: portable follow and creator-scoped identity.
- `ExternalMembershipProof`: external membership verification evidence.
- `MembershipTierMapping`: external-to-Loom tier and benefit mapping.
- `PaymentReceipt`, `MembershipReceipt`, `MembershipEntitlement`, and `RefundChargebackRecord`: migration billing, access, refund, and chargeback contracts.
- `MembershipMigrationTool`: external proof, migration links, tier mapping, duplicate-billing handling, and entitlement creation.
- `ArchiveImportService`: content archive import where rights/API/export allow.
- `MigrationManifest`: backup, provider-exit, privacy, failure, cutover, rehydration, and dispute terms.
- `MigrationPlanAPI`: provider and platform migration planning.
- `ChannelMigrationRecord`: role-specific provider migration, cutover, and pointer update evidence.
- `CreatorExportAPI`: creator metadata export.
- `FanExportAPI`: fan identity and vault export.
- `MediaExportAPI`: media export from certified hosts.
- `ReceiptExportAPI`: revenue, usage, settlement, audit, adjustment, and dispute history export.
- `ExtensionStateExportAPI`: extension and campaign state export.
- `MigrationReceipt`: audit record of migration steps, safety status, policy versions, source evidence, failures, and dispute references.
- `ProviderIncidentReport`: provider export failure or misconduct evidence.
- `DisputeCaseRecord`: migration, export, membership, or provider dispute.
- `CreatorAnnouncementTemplates`: fan-facing migration messaging.
