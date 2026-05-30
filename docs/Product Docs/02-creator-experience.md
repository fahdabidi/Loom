# Loom Product Definition 02: Creator Experience

Status: Draft for review  
Product area: 2 of 22  
Depends on: 01 Core Thesis and Platform Principles

## 1. Product Definition

The Creator Experience is the supply-side wedge for Loom. It should feel like a single operating system for a creator's media business: publish content, understand fans, monetize, install extensions, run sponsor campaigns, build recommendations, use AI, compare providers, and migrate without losing the channel.

The creator should not experience Loom as "yet another posting app." Loom should become the creator-owned hub that can eventually replace the fragmented stack of YouTube, TikTok, Instagram, X, Patreon, Substack, Discord, email, sponsor tools, giveaway tools, and AI tools.

The Creator Experience must make the protocol visible only when it gives the creator leverage: ownership, provider choice, revenue transparency, audience portability, extension customization, and migration rights.

## 2. Scope

This product area covers the creator-facing product experience, mainly through Creator Studio and related surfaces.

It includes:

- Creator onboarding and Creator Channel setup.
- Channel profile, branding, domain, and public presence.
- Content creation, upload, publishing, scheduling, and catalog management.
- Multi-format publishing: videos, shorts, posts, newsletters, events, livestreams, courses, and community updates.
- Membership, paywall, tips, paid events, and premium content controls.
- Sponsor, ad, campaign, giveaway, reward, and extension management.
- Creator-led recommendations and referral revenue setup.
- AI archive, creator assistant, summaries, Q&A, and translation/dubbing configuration.
- Audience insights through the Audience Data Firewall.
- Revenue, cost, receipt, and settlement dashboards.
- Provider comparison, provider upgrades, progressive unbundling, export, and migration controls.

It does not define the full internals of fan identity, settlement, AI, plugins, search, or governance. Those are defined in their own product areas, but the Creator Experience must expose them coherently.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator-owned channel dashboard | Creator Studio manages a portable Creator Channel rather than an app-owned account. | Creators understand that the business relationship belongs to them. | Core Thesis and Platform Principles; Creator Channel and Metadata Architecture |
| Unified publishing | One place to publish videos, shorts, posts, newsletters, events, courses, livestreams, and community updates. | Reduces the need for separate platform workflows. | Creator Channel and Metadata Architecture; Hosting Provider Lifecycle and Progressive Unbundling |
| Provider-aware setup | Creators start with managed defaults but can see which providers power hosting, ads, AI, payments, search, analytics, and settlement. | Provider choice is discoverable without blocking onboarding. | Provider Marketplace and Certified APIs; Hosting Provider Lifecycle and Progressive Unbundling |
| Progressive control | The creator can move from free managed hosting to direct paid or modular provider control. | Loom works for both new and mature creators. | Hosting Provider Lifecycle and Progressive Unbundling; Business Model and Incentive Design |
| Audience visibility with limits | Creators get followers, members, notification opt-ins, creator-scoped activity, campaign participation, and aggregate insights without unrestricted fan surveillance. | Balances creator business needs with fan data rights. | Audience Data Firewall and Data Rights; Fan Passport, Wallet, Vaults, and Identity Architecture |
| Relationship privacy lifecycle | Creators can see the audience relationship they earned, but fan visibility, direct contact, export, block, and deletion/tombstone controls bound what is exposed. | Gives creators real first-party audience value without turning follows into unrestricted surveillance. | Audience Data Firewall and Data Rights; Fan Passport, Wallet, Vaults, and Identity Architecture |
| Revenue transparency | Creator sees gross revenue, provider costs, referral income, AI royalties, sponsor revenue, adjustments, and expected payouts. | Makes Loom materially better than opaque platform payouts. | Revenue, Receipts, Ledgers, and Settlement; Monetization Models |
| Extension-based customization | Creator installs certified extensions for polls, giveaways, rewards, sponsor campaigns, courses, games, and live tools. | Channels become customizable without waiting for core platform features. | Creator Plugins / Extensions / Campaign Layer; Developer Ecosystem and DevOps Supply Chain |
| Campaign and sponsor operating surface | Creator can configure sponsor campaigns, product cards, giveaways, disclosures, rewards, and reporting. | Turns brand deals into structured, measurable, consented workflows. | Brand/Sponsor/Advertiser Tools; Audience Data Firewall and Data Rights |
| Recommendation workbench | Creator publishes `RecommendationManifest` and optional referral relationships. | Discovery starts from creator trust and can generate referral revenue. | Creator-Led Recommendation Economy; Revenue, Receipts, Ledgers, and Settlement |
| Creator AI tools | Creator can approve AI summaries, archive Q&A, translation/dubbing, assistant behavior, and source royalties. | Creator archives become searchable and monetizable knowledge products. | AI Layer; Audience Data Firewall and Data Rights |
| Export and migration controls | Creator can inspect portable state, export metadata, and plan provider migration. | Portability becomes a real product behavior. | Migration Strategy from Existing Platforms; Provider Marketplace and Certified APIs |

## 4. Product Experience Requirements

### 4.1 Creator Studio Home

Creator Studio should show the creator's business at a glance:

- Channel status and provider stack.
- Recent content performance.
- Revenue and payout estimates.
- Fan growth, members, and notification opt-ins.
- Active campaigns, sponsor deals, and extensions.
- Open issues: failed receipts, provider incidents, takedowns, export warnings, or certification warnings.
- Recommended next actions based on channel maturity.

### 4.2 Publishing Experience

Publishing should default to simple choices while writing standard manifests behind the scenes.

Required behavior:

- Upload or compose content.
- Select content type, visibility, access mode, monetization mode, AI policy, search policy, and schedule.
- Preview how the content appears in certified fan apps.
- Generate or update `ContentManifest`, `MonetizationManifest`, `SearchAccessPolicy`, and `AIContentPolicy`.
- Publish to the chosen content host and public catalog.

### 4.3 Audience Experience

Creators should see useful audience state, but the interface must make data boundaries clear.

Allowed creator-facing data examples:

- Followers and members.
- Notification opt-ins.
- Creator-scoped watch/read activity.
- Campaign participants.
- Loyalty or reward state.
- Sponsor offer engagement.
- Aggregate audience insights.
- Permissioned direct contact channels.
- Follow visibility state: public, creator-visible, private, or pseudonymous/anonymous where supported.
- Direct-contact grant state and revocation status.
- Whether a fan has unfollowed, blocked the creator, or requested creator-scoped deletion/tombstoning where audit-safe context is still needed.

Restricted by default:

- Full cross-creator watch history.
- Private fan messages.
- Payment details.
- Full AI conversations.
- Unrelated follows or memberships.
- Sensitive personal data.
- Precise location unless specifically granted for a permitted purpose.
- Direct email, phone, or off-platform contact information without `DirectContactGrant`.
- A universal fan identifier that can be correlated across unrelated creators.

### 4.4 Provider Control Experience

Provider controls should be staged by maturity:

- New creator: managed defaults and simple explanations.
- Growing creator: upgrade prompts, provider comparisons, revenue simulations, and cost visibility.
- Mature creator: modular controls for hosting, CDN, storage, ads, payments, AI, analytics, moderation, search, recommendation, and settlement providers.
- Advanced creator: metadata host, backup provider, payout provider, and audience/vault-related provider roles become visible where the creator has control or dependency.
- Enterprise creator: self-hosting, custom contracts, backup providers, and advanced governance support.

## 5. User Stories

### Story 1: New creator creates a channel

As a new creator, I want to create a channel quickly so I can publish today while still owning my channel identity and export rights.

End state:

- Creator Channel exists in the Creator Channel Registry.
- `CreatorChannelManifest` is created.
- Creator Metadata Host stores channel state.
- Default hosting and settlement providers are attached through manifests.

### Story 2: Creator publishes multi-format content

As a creator, I want to publish videos, posts, and events from one place so my fans can follow all of my work through one channel.

End state:

- Content appears in the creator's public catalog.
- Fan apps can render the content according to its content type and access mode.
- Search, AI, monetization, and playback rules are stored in manifests.

### Story 3: Creator launches memberships

As a creator, I want to define membership tiers and member-only content so I can monetize recurring fan support without sending fans to another platform.

End state:

- Membership tiers are stored in channel metadata.
- Fan Wallet can sell and renew memberships.
- Entitlement Ledger can authorize member content.
- Revenue receipts feed settlement and creator payout statements.

### Story 3A: Creator uses permissioned audience relationship data

As a creator, I want to understand, segment, and contact my audience where fans have allowed it so I can build a business without depending on platform-owned ad data.

End state:

- Creator sees creator-scoped follower and member state permitted by `FollowVisibilityPolicy`.
- Direct-contact and CRM exports require valid `DirectContactGrant`.
- `CreatorAudienceExportPolicy` limits fields, destination, retention, resale, and breach obligations.
- Fans who unfollow, block, revoke contact, or request deletion are removed from future eligible exports.

### Story 4: Creator installs a giveaway extension

As a creator, I want to install a certified giveaway extension so I can run fan engagement campaigns without custom engineering.

End state:

- Creator reviews extension permissions.
- Extension install state is stored in channel metadata.
- Campaign entries and reward events create receipts.
- Fan data access uses explicit campaign data grants.

### Story 5: Creator recommends another creator

As a creator, I want to recommend another creator to my audience and earn referral revenue when the recommendation produces qualified engagement.

End state:

- Creator uses discovery tools to evaluate destination creator and referral terms.
- `RecommendationManifest` is published.
- Fan apps show disclosures.
- Qualified referral events generate receipts and settlement entries.

### Story 6: Creator reviews revenue and provider costs

As a creator, I want to understand why I was paid so I can trust the platform and optimize my business.

End state:

- Creator sees gross revenue by source.
- Provider costs, utility fees, adjustments, and net payout are visible.
- Playback, ad, premium no-ad, AI, referral, campaign, and membership receipts are traceable.

### Story 7: Creator upgrades hosting control

As a growing creator, I want to compare hosting and ad provider options so I can improve margins without losing my channel.

End state:

- Creator compares certified providers.
- Cost and revenue simulation is shown.
- Hosting contract changes are recorded.
- Existing fans, metadata, content catalog, receipts, and entitlements continue.

### Story 8: Creator exports or migrates

As a creator, I want an exit button so I can move providers if terms, cost, reliability, or trust becomes unacceptable.

End state:

- Migration plan is generated.
- Portable channel state and required export state are available.
- Registry pointers can be updated.
- Final settlement and disputes remain auditable.

## 6. End-to-End Workflows

### Workflow 1: Creator onboarding to first publish

Actors:

- Creator
- Creator Studio
- Creator Channel Registry
- Creator Metadata Host
- Provider Capability Registry
- Payment/Payout Provider
- Content Host
- Fan App

Steps:

1. Creator signs up and creates a channel.
2. Creator Studio creates the `CreatorChannelManifest`.
3. Default providers are selected based on creator region, content type, and managed hosting availability.
4. Creator selects or accepts a payout provider path; prototype builds may use simulated payouts.
5. Creator enters payout instructions and tax/payment readiness information where required.
6. Creator configures profile, handle, categories, and optional domain.
7. Creator uploads first content.
8. Creator sets visibility, access, monetization, AI, and search options.
9. Creator Studio writes content and business manifests to Creator Metadata Host.
10. Content Host ingests media and returns playback references.
11. Public catalog updates.
12. Fan App can discover, follow, and consume the content.

### Workflow 1A: Free managed hosting setup

Actors:

- Creator
- Creator Studio
- Provider Marketplace
- Free Managed Host
- Creator Metadata Host
- Settlement Engine

Steps:

1. Creator selects free managed hosting during onboarding or from provider controls.
2. Creator Studio fetches certified host terms through `ProviderPricingAPI` and provider manifests.
3. Creator reviews host ad control, revenue share, no-ad replacement behavior, storage limits, retention and age-out rules, export rights, and support.
4. Creator accepts terms.
5. Creator Metadata Host stores `HostingContractManifest`, `MonetizationManifest`, `SettlementManifest`, and lifecycle settings.
6. `LifecyclePolicyAPI` controls retention, archival, and age-out behavior.
7. Playback and ad/no-ad rules use the managed hosting terms.
8. Creator Dashboard shows managed hosting economics and upgrade paths.

### Workflow 2: Membership launch

Actors:

- Creator
- Creator Studio
- Fan
- Fan App
- Fan Wallet
- Entitlement Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator defines membership tiers, benefits, price, region rules, and renewal terms.
2. Creator marks selected content or community surfaces as member-only.
3. Fan views membership offer in a Fan App.
4. Fan Wallet processes purchase or simulated purchase.
5. Entitlement Ledger records member access.
6. Fan accesses member content.
7. MembershipReceipt and playback/read receipts are ingested.
8. Settlement Engine allocates creator revenue, provider costs, and platform utility fees.
9. Creator sees membership conversion, churn, revenue, and content engagement.

### Workflow 2A: Creator audience export and direct contact

Actors:

- Creator
- Creator Studio
- Creator Audience Vault
- Audience Data Firewall
- CreatorCRMExportAPI
- Receipt Ledger
- Fan Data Dashboard

Steps:

1. Creator opens audience manager and selects an audience segment, direct-message action, or CRM export.
2. Creator declares purpose, destination, retention period, and whether direct contact is required.
3. Creator Studio calls `CreatorAudienceAPI` and `CreatorCRMExportAPI` with the declared purpose and destination.
4. `AudienceDataFirewallPolicy` evaluates `FollowVisibilityPolicy`, `DirectContactGrant`, `SensitiveRelationshipDefaultPolicy`, block state, revocation state, and `CreatorScopedTombstoneRecord`.
5. `CreatorAudienceExportPolicy` limits eligible fields, export format, destination, retention, watermarking, no-resale obligations, and breach-notice duties.
6. Export returns only eligible creator-scoped fields and pairwise identifiers; universal fan identifiers, ungranted contact details, private follows, and deleted/tombstoned relationships are excluded.
7. `DataAccessReceipt` records the allowed access or export and is submitted to `ReceiptLedger`.
8. Fan Data Dashboard shows export/access history and revocation controls where disclosure is required.
9. Later unfollow, block, visibility change, direct-contact revocation, or deletion request updates future eligibility through `CreatorRelationshipActionRecord`.

### Workflow 3: Extension-powered campaign

Actors:

- Creator
- Extension Registry
- Extension Runtime
- Sponsor
- Fan
- Campaign Ledger
- Reward Ledger
- Audience Data Firewall

Steps:

1. Creator browses certified campaign extensions.
2. Creator selects an extension and reviews `ExtensionManifest`, risk class, permissions, artifact signature, and export support.
3. Creator Studio verifies signed artifact metadata through `ExtensionArtifactAPI`.
4. Creator installs the extension through `ExtensionInstallAPI`.
5. `ExtensionPermissionGrant` records scoped creator permissions.
6. Fan App loads only verified signed artifacts and enforces runtime signature checks.
7. Creator configures campaign terms, sponsor disclosures, eligibility, rewards, and data grants.
8. Fan App renders the campaign extension.
9. Fan grants campaign-specific permission or uses alternate entry where required.
10. Campaign entry and reward actions generate receipts.
11. Creator and sponsor receive aggregate reporting.
12. Extension state remains exportable with the channel.

### Workflow 4: Recommendation and referral

Actors:

- Creator
- Creator Discovery Exchange
- Recommendation Workbench
- Destination Creator
- Fan App
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator searches for creators, content, events, promotions, and referral terms.
2. Creator evaluates reputation, topic fit, and disclosure requirements.
3. Creator drafts a recommendation with optional AI assistance.
4. Creator publishes `RecommendationManifest`.
5. Fan App ranks the recommendation for fans who trust the source creator.
6. Fan engages with destination creator.
7. `DiscoveryReceipt` or `CreatorReferralReceipt` is generated.
8. Settlement Engine applies referral terms, caps, and fraud checks.
9. Creator recommendation reputation updates.

### Workflow 5: Provider upgrade or unbundling

Actors:

- Creator
- Creator Studio
- Provider Marketplace
- Current Provider
- New Provider
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator opens provider control panel.
2. Creator sees current stack, costs, revenue split, reliability, and portability status.
3. Creator compares certified alternatives.
4. Creator runs upgrade or unbundling simulation.
5. Creator selects new provider or modular role.
6. Provider contract manifest updates.
7. New provider receives required metadata and configuration.
8. Receipts continue flowing into the same settlement process.
9. Creator monitors cost and revenue impact.

### Workflow 6: Creator export and migration

Actors:

- Creator
- Migration System
- Creator Metadata Host
- Current Provider
- Destination Provider
- Governance Admin

Steps:

1. Creator requests a migration plan.
2. Migration System reads `MigrationManifest`, provider contract, export rights, and destination capabilities.
3. Creator reviews what is canonical portable state, required export state, optional export state, and provider-local runtime state.
4. Export package is prepared.
5. Destination provider validates import.
6. Creator confirms cutover.
7. Creator Channel Registry updates pointers.
8. Old provider generates final settlement records.
9. Disputes or failures are routed to governance.

### Workflow 7: Creator enables AI archive Q&A

Actors:

- Creator
- Creator Studio
- Creator Metadata Host
- AI Gateway
- AI Provider
- Fan App
- Receipt Ledger
- Settlement Engine

Steps:

1. Creator opens AI settings.
2. Creator selects archive Q&A, summaries, translation, or other AI features.
3. Creator chooses certified AI provider and reviews cost, data use, source attribution, and royalty support.
4. Creator Studio writes `AIContentPolicy` to Creator Metadata Host.
5. AI Gateway uses `AIContentAccessAPI` to access only approved source material.
6. Fan App exposes AI features where content and entitlements allow.
7. AI interactions generate `AIUsageReceipt` and `SourceAttributionReceipt`.
8. Creator can pause, revoke, or change AI permissions.
9. Settlement Engine allocates AI provider costs and creator source royalties.

## 7. Cross-Area Interactions

- Creator Channel and Metadata Architecture: Creator Studio writes `CreatorChannelManifest`, `ContentManifest`, `MonetizationManifest`, `HostingContractManifest`, and provider pointers.
- Fan Passport, Wallet, Vaults, and Identity Architecture: Creator workflows depend on `FollowRelationshipAPI`, `MembershipEntitlement`, `EntitlementLedgerAPI`, `ConsentGrantAPI`, and `CreatorAudienceAPI`.
- Hosting Provider Lifecycle and Progressive Unbundling: Creator Studio exposes `HostingContractManifest`, `ProviderRoleGrant`, `MigrationPlanAPI`, and hosting-tier controls.
- Revenue, Receipts, Ledgers, and Settlement: Creator dashboards consume `ReceiptLedger`, `SettlementRunRecord`, `CreatorPayoutStatement`, and `ProviderPayoutStatement`.
- Creator Plugins / Extensions / Campaign Layer: Creator installs `ExtensionManifest` records and manages `ExtensionInstallRecord`, `CampaignManifest`, and extension state.
- AI Layer: Creator controls `AIContentPolicy`, `AIIndexingAPI`, `AIUsageReceipt`, and `SourceAttributionReceipt`.
- Creator-Led Recommendation Economy: Creator builds and publishes `RecommendationManifest` and `ReferralTermsManifest` records.
- Audience Data Firewall and Data Rights: Creator audience tools must respect `AudienceDataFirewallPolicy`, `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, `DataUseGrant`, `CampaignDataGrant`, and `DataAccessReceipt`.
- Governance, Certification, and Foundation Model: Creator trust depends on `CertificationScopeRecord`, `ProviderAuditAPI`, `DisputeResolutionAPI`, and key revocation state.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Creator-facing apps and surfaces

- Creator Studio: onboarding, profile, publishing, content catalog, membership setup, sponsor management, extension install, recommendation builder, provider controls, analytics, revenue dashboard, export, and migration.
- Creator Dashboard Home: channel health, active campaigns, provider incidents, pending payouts, growth signals, and recommended actions.
- Creator Provider Control Panel: current stack, provider roles, contract terms, costs, certification status, portability status, metadata host, payout provider, backup provider, audience/vault dependencies, and upgrade simulations.
- Creator Revenue Dashboard: gross revenue, provider costs, utility fees, adjustments, referrals, AI royalties, sponsor revenue, and net payout.

#### Control-plane systems

- Creator Channel Registry: canonical creator identity, public keys, handle/domain binding, metadata host pointer, provider pointers, and migration state.
- Creator Metadata Host: channel profile, content catalog, manifests, extension installs, campaign config, membership tiers, AI permissions, recommendation manifests, provider settings, and export state.
- Provider Capability Registry: certified providers available for metadata hosting, content hosting, ads, payments, payout, analytics, AI, search, settlement, moderation, backup, audience/vault-related services, and extensions.
- `MigrationPlanAPI`: creator-facing provider switch plans and export readiness checks.

#### Content and publishing systems

- `ContentIngestAPI`: upload and content creation.
- `ContentCatalogAPI`: public and private content metadata.
- `ContentManifest`: title, required creator-approved summary, content type, access mode, media references, searchability, AI policy, and lifecycle metadata.
- `HostingContractManifest`: current hosting tier, provider role, ad control, revenue split, export support, and lifecycle policy.
- `PublicCatalogAPI`: exposes published content to apps and search.

#### Monetization and settlement systems

- `MonetizationManifest`: ads, memberships, tips, pay-per-view, premium no-ad eligibility, sponsor rules, and AI royalty rules.
- `SettlementManifest`: allocation rules for hosting tiers, managed ad/no-ad modes, provider costs, utility fees, and creator payouts.
- `EntitlementLedger`: member access, paid content, events, premium no-ad, AI credits, and creator bundle entitlements.
- `ReceiptLedger`: playback, ad, membership, tip, campaign, AI, referral, delivery, and settlement receipts.
- `SettlementEngineAPI`: payout calculations and creator/provider allocation.
- `PayoutProviderAPI` / `PayoutAPI`: payout instructions, simulated prototype payouts, real payout execution, tax/payment readiness, and payout status.
- `CreatorPayoutStatement`: creator-facing explanation of revenue, costs, adjustments, and payouts.

#### Audience and data systems

- Creator Audience Vault: creator-scoped audience state, segments, campaign participation, reward state, and permissioned CRM export.
- `PrivateEventVault`: private fan behavioral data that can inform creator analytics only through scoped, auditable, purpose-bound access.
- `AudienceAnalyticsAPI`: aggregate fan insights and creator-scoped activity.
- Audience Data Firewall Policy Engine: enforces boundaries between fan private data, creator audience data, and provider processing data.
- `PairwiseIdentityAPI`: creator-scoped fan identifiers that limit cross-creator tracking.
- `FollowVisibilityPolicy`: fan-selected creator relationship visibility for public, creator-visible, private, or pseudonymous/anonymous follows.
- `DirectContactGrant`: explicit permission for creator email, CRM, off-platform contact, or other direct-contact export.
- `CreatorRelationshipActionRecord`: follow, unfollow, block, visibility change, direct-contact revocation, and deletion/tombstone lifecycle evidence.
- `CreatorScopedTombstoneRecord`: minimal retained marker that prevents creator rehydration of deleted relationship data while preserving required audit, safety, settlement, and legal exceptions.
- `SensitiveRelationshipDefaultPolicy`: stricter relationship visibility and direct-contact defaults for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
- `CreatorAudienceExportPolicy`: field-level export, destination, retention, watermarking, no-resale, revocation, and breach-notice rules for creator audience exports.
- `DataUseGrant`, `DataAccessReceipt`, `ConsentGrantAPI`, and `CampaignDataGrant`: explicit fan permissions and audit records for campaigns, direct contact, creator analytics, and data-for-value exchanges.

#### Extension and campaign systems

- `ExtensionRegistryAPI`: browsing, install, certification status, manifests, and signed artifacts.
- `ExtensionArtifactAPI`: signed extension bundle storage and artifact retrieval.
- `ExtensionInstallAPI`: creator install and configuration.
- `ExtensionPermissionGrant`: scoped creator/fan permissions for extension access.
- `ExtensionBuildAttestation`: CI/CD provenance for signed artifacts.
- `ExtensionConformanceTestSuite`: certification tests for APIs, permissions, runtime behavior, and export support.
- `ExtensionRuntimeGateway`: safe runtime calls into platform APIs.
- Campaign Ledger: campaign configuration, entries, eligibility, and compliance state.
- Reward Ledger: loyalty, points, badges, rewards, issuance, redemption, and export state.

#### Recommendation and discovery systems

- Creator Discovery Exchange: creator search, promotion discovery, referral-term discovery, and reputation lookup.
- `CreatorDiscoveryAPI`: broad creator/content/event discovery for recommendation drafting.
- `CreatorAgentDelegationToken`: bounded AI access for creator recommendation work.
- `RecommendationManifestAPI`: read/write published recommendations.
- `RecommendationWorkbenchAPI`: draft, validate, label, and publish `RecommendationManifest`.
- `ReferralTermsManifest`: destination creator referral payout terms.
- `FanScopedRecommendationAPI`: fan-side trusted candidate ranking.
- `CommunityFeedAPI`: optional community feed candidate source.
- Creator Recommendation Graph and Referral Engine: recommendation relationships, referral attribution, receipts, and reputation.

#### AI systems

- AI Gateway: approved AI provider calls.
- `AIContentAccessAPI`: source access according to creator policy.
- `AIContentPolicy`: summaries, archive Q&A, translation/dubbing, training, no-training defaults, and royalties.
- `AIUsageReceipt` and `SourceAttributionReceipt`: audit and settlement records for AI interactions.

#### Trust, safety, and governance systems

- Provider Certification API: confirms provider capability claims surfaced to creators.
- Abuse Report API and Takedown API: creator-facing safety workflows.
- Dispute Resolution API: payout, provider, takedown, migration, campaign, and receipt disputes.
- Provider Incident Report: reliability, data, export, or certification incidents shown in Creator Studio.
