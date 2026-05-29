# Loom Product Definition 10: Creator Plugins / Extensions / Campaign Layer

Status: Draft for review  
Product area: 10 of 22  
Depends on: 02 Creator Experience; 03 Fan Experience; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 14 Audience Data Firewall and Data Rights; 16 Developer Ecosystem and DevOps Supply Chain; 18 Brand/Sponsor/Advertiser Tools; 17 Trust, Safety, Fraud, and Compliance; 19 Governance, Certification, and Foundation Model; 21 Migration Strategy from Existing Platforms

## 1. Product Definition

The Creator Plugins / Extensions / Campaign Layer lets creators customize their channels with certified, sandboxed, portable extensions. Extensions can power giveaways, polls, quizzes, rewards, sponsor campaigns, referral campaigns, merch drops, courses, games, live overlays, community tools, and AI modules.

Extensions turn Loom from a fixed social app into an open app ecosystem for creator-owned media businesses. The key product constraint is that extension power must not compromise portability, fan data rights, security, or settlement integrity.

## 2. Scope

This product area covers:

- Extension marketplace and registry.
- `ExtensionManifest`.
- Extension certification and risk levels.
- Verified build and artifact supply chain.
- Creator install and configuration.
- Scoped creator and fan permissions.
- Sandboxed fan-app runtime.
- Campaign, giveaway, reward, loyalty, and sponsor modules.
- Campaign and reward receipts.
- Extension analytics.
- Extension state export and migration.

It does not define the complete developer platform, but it depends heavily on it.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator-controlled customization | Creators install extensions into their own channels. | Channels can differentiate without platform roadmap bottlenecks. | Creator Experience |
| Certified extension marketplace | Extensions are listed only with manifests, testing, and certification status. | Reduces security, privacy, and fraud risk. | Governance, Certification, and Foundation Model |
| Verified supply chain | Source, CI/CD, signed artifacts, SBOM, scans, and attestations. | Prevents random code snippets from touching fan data. | Developer Ecosystem and DevOps Supply Chain |
| Scoped permissions | Extensions request explicit creator/fan scopes. | Data access is limited and auditable. | Audience Data Firewall and Data Rights |
| Direct-contact safeguards | CRM and direct-contact extensions must honor follow visibility, fan grants, revocation, and tombstones. | Prevents extensions from becoming a loophole for follower scraping or off-platform contact. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Sandboxed runtime | Fan apps render extensions through safe runtime boundaries. | Protects fans and apps from unsafe code. | Fan Apps and App Ecosystem |
| Campaign Ledger | Campaign entries, eligibility, compliance, and sponsor terms are tracked. | Campaigns become auditable. | Brand/Sponsor/Advertiser Tools |
| Reward Ledger | Points, badges, rewards, issuance, and redemption are portable. | Fans get persistent engagement value. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Portable extension state | Install config and campaign state export with channel. | Creator customization survives provider changes. | Migration Strategy from Existing Platforms |
| Extension receipts | Campaign, reward, conversion, and extension usage events generate receipts. | Settlement and audit can include extension activity. | Revenue, Receipts, Ledgers, and Settlement |

Extension risk tiers:

- Engagement extension: low-risk UI and interaction features, such as polls or simple quizzes.
- Campaign extension: giveaways, rewards, eligibility, or sponsor activations.
- Monetized extension: paid extension, commerce, conversion, or settlement impact.
- Sensitive/regulated extension: direct contact, sensitive data, age/region rules, financial implications, health/safety claims, or higher-risk sponsor/legal workflows.

Certification is version-scoped. Material updates require renewed review. Suspended or revoked extension versions should fail closed in certified fan apps.

## 4. Extension Categories

Initial categories:

- Polls and quizzes.
- Giveaways and sweepstakes.
- Loyalty points, badges, and rewards.
- Sponsor campaigns and product cards.
- Referral campaigns.
- Merch drops and commerce.
- Paid course modules and assessments.
- Fan challenges and competitions.
- Livestream overlays and interactive events.
- Community tools.
- AI modules.
- Creator CRM or direct-contact tools, subject to `FollowVisibilityPolicy`, `DirectContactGrant`, revocation state, and creator-scoped tombstones.

## 5. User Stories

### Story 1: Creator installs a poll extension

As a creator, I want to install a poll extension so I can engage fans on my channel.

End state:

- Creator reviews permissions.
- Extension install is stored in channel metadata.
- Fan App renders poll.
- Participation receipts are generated if needed.

### Story 2: Creator runs a giveaway

As a creator, I want to run a giveaway with eligibility rules and alternate entry paths.

End state:

- CampaignManifest defines rules.
- Fan permissions are explicit.
- Campaign Ledger records entries.
- Reward Ledger records winners and fulfillment.

### Story 3: Sponsor funds an extension campaign

As a sponsor, I want to fund a creator campaign and receive permitted aggregate reporting.

End state:

- Sponsor disclosure is visible.
- Fan data grants are scoped.
- Sponsor receives aggregate or permissioned conversion reporting.
- Settlement allocates sponsor funds.

### Story 4: Developer publishes extension

As a developer, I want to publish an extension so creators can install it and I can earn revenue.

End state:

- ExtensionManifest is validated.
- Build artifact is signed.
- Certification tests pass.
- Marketplace listing is available.

### Story 5: Fan revokes extension permission

As a fan, I want to revoke an extension's future access to my data.

End state:

- ConsentGrantAPI revokes access.
- Extension loses future data access.
- Historical campaign receipts remain auditable.

### Story 6: Creator migrates with extension state

As a creator, I want my installed extensions and campaign state to move with my channel.

End state:

- Extension install records export.
- Portable campaign and reward state export.
- Destination environment validates extension compatibility.

## 6. End-to-End Workflows

### Workflow 1: Developer publishes extension

Actors:

- Developer
- Developer Console
- Extension Registry
- CI/CD System
- Certification System
- Governance Admin

Steps:

1. Developer creates extension project from SDK template.
2. Developer defines `ExtensionManifest`, surfaces, scopes, risk class, and export behavior.
3. CI/CD runs tests, security scans, privacy checks, and conformance checks.
4. Signed artifact, SBOM, and `ExtensionBuildAttestation` are created.
5. Artifact is uploaded to certified Extension Artifact Host through `ExtensionArtifactAPI`.
6. Developer submits extension.
7. Certification system validates artifact signature, manifest-version match, risk tier, and conformance results.
8. `CertificationScopeRecord` records certified version, risk tier, restrictions, and expiration.
9. Governance reviews higher-risk extensions.
10. Extension Registry publishes listing.

### Workflow 2: Creator installs extension

Actors:

- Creator
- Creator Studio
- Extension Registry
- Extension Artifact Host
- Extension Runtime Gateway
- Creator Metadata Host

Steps:

1. Creator browses extension marketplace.
2. Creator opens extension details, permissions, risk level, pricing, and reviews.
3. Creator installs extension through `ExtensionInstallAPI`.
4. Creator grants scoped `ExtensionPermissionGrant`.
5. `ExtensionInstallRecord` stores manifest id/version, artifact signature, certification status, permissions, config, and export support.
6. Extension Runtime Gateway retrieves signed bundle through `ExtensionArtifactAPI`.
7. Fan apps verify artifact signature and manifest-version match before rendering.
8. Runtime fails closed if artifact, certification, or key status is invalid.
9. Fan apps can render extension surface.

### Workflow 3: Fan participates in campaign extension

Actors:

- Fan
- Fan App
- Extension Runtime
- Campaign Ledger
- Reward Ledger
- ConsentGrantAPI
- Audience Data Firewall
- Creator Audience Vault
- Private Event Vault

Steps:

1. Fan opens creator campaign.
2. Extension displays rules, rewards, sponsor disclosure, and data request.
3. Extension checks `CampaignDataGrant` requirements and any broader `DataUseGrant`.
4. Fan grants permission or selects alternate entry.
5. `DataAccessReceipt` records actual sensitive data access.
6. Campaign Ledger records entry.
7. Creator Audience Vault receives only allowed creator-scoped state.
8. Raw Private Event Vault data is not exported to the extension, creator, or sponsor.
9. Extension evaluates eligibility.
10. Reward Ledger records reward or winner state.
11. Fan sees entry and reward status.

### Workflow 3A: CRM or direct-contact extension access

Actors:

- Creator
- Fan
- Creator Studio
- Extension Runtime Gateway
- Creator Audience Vault
- Audience Data Firewall
- Fan App

Steps:

1. Creator installs a CRM, newsletter, community, or direct-contact extension.
2. `ExtensionManifest` declares contact scopes, destinations, retention, export behavior, sponsor sharing, and risk tier.
3. Creator grants only creator-side scopes through `ExtensionPermissionGrant`.
4. Fan-facing contact collection or sync requires valid `DirectContactGrant`; the extension cannot infer contact permission from follow or membership alone.
5. `AudienceDataFirewallPolicy` checks `FollowVisibilityPolicy`, `CreatorAudienceExportPolicy`, block state, revocation state, and `CreatorScopedTombstoneRecord`.
6. Extension receives only eligible creator-scoped fields through `ExtensionRuntimeGateway`.
7. `DataAccessReceipt` records sensitive or grant-protected access.
8. Fan revocation, block, or deletion request disables future extension access and prevents rehydration from extension state.

### Workflow 4: Sponsor campaign execution

Actors:

- Sponsor
- Creator
- Sponsor Dashboard
- Creator Studio
- Campaign Extension
- Settlement Engine

Steps:

1. Sponsor proposes campaign terms.
2. `SponsorCampaignAPI` creates offer, product cards, promo codes, conversion goals, and reporting needs.
3. Creator reviews and accepts campaign.
4. Extension configures `CampaignManifest`, `CampaignComplianceManifest`, and `SponsorDisclosurePolicy`.
5. Fans participate.
6. `SponsorDeliveryReceipt`, `CampaignEntryReceipt`, `RewardReceipt`, `ConversionReceipt`, and `ExtensionUsageReceipt` are generated where relevant.
7. Sponsor receives permitted aggregate or permissioned reporting.
8. `ReceiptIngestAPI` sends receipts to `ReceiptLedger`.
9. `SettlementEngineAPI` applies `SettlementManifest` and allocates funds to creator, extension developer, providers, and utilities.

### Workflow 5: Extension suspension

Actors:

- Governance Admin
- Extension Registry
- Creator
- Fan App
- Developer

Steps:

1. Security, privacy, fraud, or compliance issue is detected.
2. Governance changes certification state to `Limited`, `Suspended`, or `Revoked`.
3. Extension Registry updates listing.
4. Signing keys are rotated or revoked where needed.
5. Creator Studio shows affected installs.
6. Fan apps disable or restrict extension runtime and fail closed for revoked artifacts.
7. Developer receives remediation path.
8. Export and data deletion obligations are enforced.

### Workflow 6: Extension state export

Actors:

- Creator
- Creator Metadata Host
- Extension Registry
- Migration System
- Destination Provider

Steps:

1. Creator requests export or migration.
2. `MigrationPlanAPI` reads `MigrationManifest`, extension install records, and destination runtime support.
3. Extension config, campaign state, reward state, extension-backend state, and non-portable runtime state are classified by portability class.
4. `ExtensionStateExportAPI` exports portable extension config, campaign state, and reward state.
5. `ReceiptExportAPI` exports relevant campaign, reward, conversion, and extension usage receipts.
6. Destination validates compatible extension runtime and certified artifact versions.
7. Creator confirms migration.
8. `MigrationReceipt` records export and cutover.

## 7. Cross-Area Interactions

- Creator Experience: Creator Studio exposes `ExtensionManifest`, `ExtensionInstallRecord`, extension permissions, and campaign management.
- Fan Experience: Fan Apps render extension surfaces through `ExtensionRuntimeGateway` and app sandbox controls.
- Developer Ecosystem and DevOps Supply Chain: developers build, test, sign, and publish through `ExtensionArtifactAPI`, `ExtensionBuildAttestation`, `SoftwareBillOfMaterials`, and `ExtensionRegistryAPI`.
- Audience Data Firewall and Data Rights: `ExtensionPermissionGrant`, `CampaignDataGrant`, `DataUseGrant`, `FollowVisibilityPolicy`, `DirectContactGrant`, and `DataAccessReceipt` govern data access.
- Brand/Sponsor/Advertiser Tools: sponsor campaigns use `SponsorCampaignAPI`, `SponsorDisclosurePolicy`, `SponsorDeliveryReceipt`, and campaign receipts.
- Revenue, Receipts, Ledgers, and Settlement: extension activity can generate `ExtensionUsageReceipt`, campaign receipts, and settlement fees.
- Trust, Safety, Fraud, and Compliance: `CertificationScopeRecord`, sandboxing, `ExtensionArtifactAPI`, abuse reports, and suspension state enforce safety.
- Migration Strategy from Existing Platforms: `ExtensionStateExportAPI`, `MigrationManifest`, and campaign state exports preserve portable extension state where promised.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Extension registry and marketplace

- `ExtensionRegistryAPI`: publish, search, install, update, suspend, and revoke extensions.
- `ExtensionManifest`: surfaces, scopes, data use, risk level, pricing, export behavior, and runtime requirements.
- `ExtensionArtifactAPI`: signed bundle storage and retrieval from certified Extension Artifact Host.
- Extension Marketplace Listing: description, screenshots, creator use cases, pricing, certification status, risk class, and support.
- `ExtensionInstallAPI`: creator install, configuration, permissions, and lifecycle.

#### Runtime and permission systems

- `ExtensionRuntimeGateway`: mediates extension calls into platform APIs.
- Sandboxed Fan-App Runtime: safe rendering, isolation, permission enforcement, and failure handling.
- `ExtensionPermissionGrant`: creator and fan permission scopes.
- `FollowVisibilityPolicy`: relationship visibility limit that extensions must honor before exposing fan relationship state.
- `DirectContactGrant`: required fan permission before CRM or direct-contact extensions can export or use contact data.
- `CreatorScopedTombstoneRecord`: deletion/remediation marker that extensions must respect when storing or rehydrating creator-scoped state.
- `CreatorAudienceExportPolicy`: field, destination, retention, no-resale, watermarking, revocation, and breach-notice constraints for extension-mediated audience export.
- `ConsentGrantAPI`, `CampaignDataGrant`, `DataUseGrant`, and `DataAccessReceipt`: fan-level grants, revocations, purpose-bound access, and audit records.
- Audience Data Firewall Integration: data boundaries and policy enforcement.

#### Campaign and reward systems

- `CampaignManifest`: rules, dates, eligibility, sponsor disclosures, rewards, legal terms, and data needs.
- `CampaignLedgerAPI`: campaign entries, state, eligibility, compliance, and audit.
- `RewardLedgerAPI`: points, badges, rewards, issuance, redemption, and export.
- `AlternateEntryMethodPolicy`: compliance path for giveaways and promotions.
- `CampaignComplianceManifest`: legal, regional, age, and sponsor requirements.
- `SponsorCampaignAPI`, `SponsorDisclosurePolicy`, product cards, promo codes, `SponsorDeliveryReceipt`, and `ConversionReceipt`: sponsor activation support.

#### Developer and supply chain systems

- SDK Templates: extension project scaffolds.
- CI/CD Templates: GitHub Actions, GitLab, or self-hosted CI.
- `ExtensionBuildAttestation`: provenance for signed artifacts.
- Software Bill of Materials: dependency transparency.
- Security and Privacy Scans: automated checks.
- `ExtensionConformanceTestSuite`: API, permission, runtime, and export tests.

#### Revenue and analytics systems

- `ExtensionUsageReceipt`: usage or billing basis.
- `CampaignEntryReceipt`: participation event.
- `RewardReceipt`: issued/redeemed reward.
- `ConversionReceipt`: sponsor or commerce conversion where permitted.
- `ReceiptIngestAPI` and `ReceiptLedger`: economic and audit receipt ingestion.
- `SettlementManifest` and `SettlementEngineAPI`: extension fees, sponsor campaign fees, developer/provider allocation, and payout statements.
- `ExtensionAnalyticsAPI`: creator and developer reporting.

#### Governance and safety systems

- Extension Certification Workflow: risk-based review.
- `CertificationScopeRecord`: extension version, risk tier, certification state, restrictions, and expiration.
- Extension Incident Report: vulnerabilities, abuse, fraud, privacy violations, or outages.
- Extension Suspension and Revocation: capability restrictions and runtime blocking.
- Signing Key Revocation: compromised extension/developer keys.
- Runtime Blocking Rules: fail-closed behavior for revoked artifacts, invalid signatures, or manifest mismatch.
- Data Deletion and Export Compliance: required cleanup and portability behavior.
