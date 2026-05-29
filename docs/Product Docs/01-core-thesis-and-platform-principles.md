# Loom Product Definition 01: Core Thesis and Platform Principles

Status: Draft for review  
Product area: 1 of 22  
Source inputs: `chatgpt session/Loom High Level.docx`, `chatgpt session/Loom Product Thesis per Area.docx`, `chatgpt session/Loom Architecture Components.docx`

## 1. Product Definition

Loom is an open creator/fan network where creators own their channels, fans own their identity and data controls, and major platform services are provided through certified, swappable APIs.

The product is not only an open-source social app. It is an open creator economy protocol with user-facing apps, hosting providers, metadata providers, vault providers, AI providers, ad providers, search/index providers, recommendation systems, extension developers, payment providers, settlement providers, moderation/trust providers, analytics providers, sponsors, and governance bodies operating inside common rules.

The core promise to creators is:

Creators can start easily, grow into more control, and switch or unbundle providers without losing their identity, audience, content catalog, revenue history, recommendation metadata, extension settings, campaign data, or fan relationships.

The core promise to fans is:

Fans get one portable identity, one wallet, one way to follow creators, better privacy controls, better search, creator-trust-based recommendations, and richer engagement with the creators they care about across compatible apps.

The core promise to providers and developers is:

Infrastructure providers, app developers, AI providers, payment companies, extension developers, search providers, metadata providers, vault providers, moderation/trust providers, analytics providers, and settlement providers can compete in an open marketplace by implementing certified interfaces instead of needing to own the entire social network.

## 2. Scope

This product area defines the foundational rules that every other Loom product area must respect.

It covers:

- The platform thesis.
- The product principles.
- The ownership model.
- The portability model.
- The provider competition model.
- The role of manifests, receipts, APIs, and certification.
- The basic trust relationship among creators, fans, providers, apps, developers, sponsors, and governance.
- The baseline user experiences that make these principles visible without forcing users to understand protocol details.

It does not define the complete feature set for every downstream area. Those details belong in the area-specific product definitions listed in the product area registry below.

## 2.1 Product Area Registry

Future product-definition docs should use these canonical area names when referring across docs. Short labels are acceptable inside tables only when the canonical area has already been introduced.

| # | Canonical product area | Slug | Accepted short label |
| --- | --- | --- | --- |
| 01 | Core Thesis and Platform Principles | `core-thesis-and-platform-principles` | Core Thesis |
| 02 | Creator Experience | `creator-experience` | Creator Experience |
| 03 | Fan Experience | `fan-experience` | Fan Experience |
| 04 | Creator Channel and Metadata Architecture | `creator-channel-and-metadata-architecture` | Creator Metadata |
| 05 | Fan Passport, Wallet, Vaults, and Identity Architecture | `fan-passport-wallet-vaults-and-identity-architecture` | Fan Identity |
| 06 | Hosting Provider Lifecycle and Progressive Unbundling | `hosting-provider-lifecycle-and-progressive-unbundling` | Hosting Lifecycle |
| 07 | Provider Marketplace and Certified APIs | `provider-marketplace-and-certified-apis` | Provider Marketplace |
| 08 | Revenue, Receipts, Ledgers, and Settlement | `revenue-receipts-ledgers-and-settlement` | Revenue Settlement |
| 09 | Monetization Models | `monetization-models` | Monetization |
| 10 | Creator Plugins / Extensions / Campaign Layer | `creator-plugins-extensions-campaign-layer` | Extensions |
| 11 | AI Layer | `ai-layer` | AI |
| 12 | Creator-Led Recommendation Economy | `creator-led-recommendation-economy` | Recommendations |
| 13 | Neutral Public Search Utility | `neutral-public-search-utility` | Search |
| 14 | Audience Data Firewall and Data Rights | `audience-data-firewall-and-data-rights` | Data Rights |
| 15 | Fan Apps and App Ecosystem | `fan-apps-and-app-ecosystem` | Fan Apps |
| 16 | Developer Ecosystem and DevOps Supply Chain | `developer-ecosystem-and-devops-supply-chain` | Developer Ecosystem |
| 17 | Trust, Safety, Fraud, and Compliance | `trust-safety-fraud-and-compliance` | Trust/Safety |
| 18 | Brand/Sponsor/Advertiser Tools | `brand-sponsor-advertiser-tools` | Sponsor Tools |
| 19 | Governance, Certification, and Foundation Model | `governance-certification-and-foundation-model` | Governance |
| 20 | MVP / Prototype Roadmap | `mvp-prototype-roadmap` | MVP |
| 21 | Migration Strategy from Existing Platforms | `migration-strategy-from-existing-platforms` | Migration |
| 22 | Business Model and Incentive Design | `business-model-and-incentive-design` | Business Model |

## 2.2 Baseline Terminology and Conventions

Future docs should preserve these conventions unless a later governance decision changes them.

### Naming conventions

- User-facing concepts may use spaced names, such as "Recommendation Manifest".
- Machine-readable contracts use PascalCase, such as `RecommendationManifest`.
- APIs end in `API`, such as `CreatorDiscoveryAPI`.
- Persistent ledgers end in `Ledger`, such as `ReceiptLedger`.
- Registries end in `Registry`, such as `ProviderCapabilityRegistry`.
- Policies end in `Policy`, such as `AIContentPolicy`.
- Schemas end in `Schema`, such as `PublicSearchResultSchema`.
- Receipts end in `Receipt`, such as `PlaybackReceipt`.

### Receipt classes

- `EconomicReceipt`: a receipt that may affect revenue allocation, provider payment, creator payout, refund, chargeback, or subscription allocation.
- `AuditReceipt`: a receipt used for transparency, compliance, dispute resolution, safety review, or system integrity.
- `UtilityFundingReceipt`: a receipt used to measure shared utility usage for funding infrastructure such as identity, vaults, search, or settlement.

`SearchReceipt` is an audit and utility-funding receipt. It must not create paid ranking, search ads, per-click search monetization, or any search result ordering advantage.

### System and data taxonomy

- Domain object: the user or business object the product revolves around, such as Creator Channel, Fan Passport, Recommendation Manifest, or Campaign.
- Storage system: a durable system that stores state, such as Creator Metadata Host, Fan Passport Ledger, Core Fan Vault, Private Event Vault, Creator Audience Vault, Entitlement Ledger, or Receipt Ledger.
- API/service: the interface used to read, write, validate, or process state, such as `CreatorMetadataAPI`, `FanPassportAPI`, `PrivateRankingAPI`, or `SettlementEngineAPI`.
- App surface: the product UI used by a person or organization, such as Creator Studio, Fan App, Provider Console, Developer Console, Sponsor Dashboard, or Governance Admin.
- Portable state: state that must move or export across certified providers.
- Provider-local runtime state: operational state a provider needs to run its service but does not own as creator or fan business state.

### Portability classes

- Canonical Portable State: state that defines creator or fan identity and must remain portable, such as Creator Channel identity, `CreatorChannelManifest`, Fan Passport identity, `FanPassportClaim`, follows, entitlements, provider pointers, and signed manifest history.
- Required Export State: state a certified provider must export when relevant, such as content metadata, media export references, receipt history, extension install state, campaign state, settlement statements, and consent records.
- Optional Export State: state that can be exported if supported by the provider contract, such as derived analytics, historical recommendation experiments, or app-specific layout preferences.
- Non-portable Provider Runtime State: provider operational data that is not part of the creator/fan portable business relationship, such as internal cache data, infrastructure logs beyond audit requirements, and proprietary implementation metrics.

### Certification states

- `Draft`: provider, app, or extension is preparing a capability declaration.
- `Submitted`: declaration and evidence have been submitted for review.
- `Certified`: capability passed required conformance and policy checks.
- `Limited`: capability may operate with explicit restrictions or reduced scope.
- `Suspended`: capability is temporarily removed from marketplace operation pending remediation.
- `Revoked`: capability is no longer trusted; keys, listings, or access may be disabled.

Certification applies at the capability level. A provider may be certified for one service role and uncertified or limited for another.

## 3. Product Principles

### 3.1 Creator Ownership

The creator owns the canonical channel relationship. A host may store media, an app may display content, an ad provider may monetize an impression, and a payment provider may process a charge, but none of them should become the owner of the creator's channel identity, audience relationship, or portable business state.

Required product behavior:

- A creator has a canonical Creator Channel ID.
- The Creator Channel points to the current metadata host.
- The channel is represented by a signed `CreatorChannelManifest`.
- The channel includes portable public profile, content catalog, monetization settings, provider contracts, recommendation manifests, extension installs, campaign settings, AI permissions, revenue receipt references, payout and settlement history, provider cost history, and migration state.
- The creator can export and migrate this state.
- Provider changes should not force the creator to rebuild their audience or channel.

### 3.2 Fan Portability

The fan should not be trapped inside one app. A fan should be able to follow creators, manage subscriptions, use a wallet, control privacy, and carry preferences across certified fan apps.

Required product behavior:

- A fan has a portable Fan Passport.
- Fan identity is represented by signed `FanPassportClaim` records.
- Apps use the passport rather than creating isolated user identities.
- Fan entitlements, follows, consent grants, notification settings, wallet state, saved content references, and privacy preferences are portable where the fan allows it.
- Fan identity supports personas and pairwise creator relationship IDs to reduce unnecessary cross-creator tracking.
- The fan can revoke access, export data, and migrate compatible state.

### 3.3 Certified Provider Competition

Loom should not become one bundled platform monopoly. Providers should compete to serve creators, fans, apps, and developers through certified APIs.

Required product behavior:

- Providers declare capabilities in machine-readable provider manifests.
- Certification is by capability, not by brand.
- Providers can bundle multiple services, but each service role must be separately declared.
- Creators can compare provider price, quality, reliability, revenue terms, portability support, data use, and certification scope.
- Apps and providers must pass conformance tests for the APIs they claim to support.

### 3.4 Portability Through Manifests

The platform should use explicit, machine-readable manifests for business rules, rights, permissions, provider contracts, and monetization settings.

Required product behavior:

- Creator Channel state is represented by signed metadata and manifests.
- `CreatorChannelManifest` is the root creator contract for creator identity, metadata host pointers, public keys, and channel state.
- `FanPassportClaim` is the root fan identity claim for portable fan identity, public keys, account pointers, and vault pointers.
- Content, monetization, hosting, recommendation, referral, extension, campaign, AI, search, safety, settlement, and migration rules should be expressible in standard manifest formats.
- Apps and providers should enforce manifests at runtime.
- Manifests should be versioned and auditable.

### 3.5 Transparent Economics Through Receipts

Every meaningful monetized event should create a signed economic receipt. Important non-monetized infrastructure and governance events should create audit or utility-funding receipts where needed. Revenue allocation should be explainable from receipts, manifests, and contracts.

Required product behavior:

- Playback, ad impressions, premium no-ad views, AI usage, source attribution, discovery events, referrals, campaign entries, memberships, tips, sponsor actions, delivery, and settlement should be represented by economic receipts where relevant.
- Search, provider certification, data access, migration, audit probes, and dispute events should be represented by audit or utility-funding receipts where relevant.
- Search receipts must not create paid ranking, search ads, per-click search monetization, or search ordering advantages.
- Creators can understand why they were paid.
- Providers can be compensated for real services.
- Fans can see how subscriptions or premium plans supported creators where applicable.
- Invalid or fraudulent activity can be adjusted through auditable records.

### 3.6 Fan Data Rights and Audience Data Firewall

The product must balance fan privacy with legitimate creator audience rights.

Required product behavior:

- Fan private data, creator-scoped audience data, and provider processing data are separated.
- Providers cannot reuse fan or creator data for unrelated businesses without permission.
- Creators get useful first-party audience tools without unrestricted fan surveillance.
- Fans can see and revoke permissions.
- Data access should be purpose-bound, scoped, and auditable.

### 3.7 Creator-Led Discovery

Loom should reduce dependence on opaque engagement-maximizing feeds by making creator trust a first-class discovery source.

Required product behavior:

- Creators can publish Recommendation Manifests.
- Creators can use a Creator Discovery Exchange to find creators, content, promotions, referral terms, and reputation signals before publishing recommendations.
- Destination creators can publish referral terms.
- Fan apps can rank creator recommendations based on fan preferences.
- Recommendation disclosures should identify editorial, paid, affiliate, sponsored, or referral relationships.
- Referral revenue can be settled through receipts and manifests.
- Recommendation abuse should be detectable and penalized.

### 3.8 Neutral Public Search

Search is the fan's intentional path outside the creator trust graph. It should be broad, neutral, distributed, and non-monetized.

Required product behavior:

- Search is separate from recommendations.
- Search results should not be sold as paid ranking.
- Search should not contain search ads or per-click search monetization.
- Hosts expose certified public search APIs.
- Apps can merge signed search results from multiple hosts.
- Search can be connected to fan-controlled AI tools.
- Search should be funded as shared utility infrastructure rather than per-click extraction.

### 3.9 Progressive Complexity

Creators and fans should not need to understand the whole protocol on day one.

Required product behavior:

- Creators can start with a simple managed path.
- More advanced control becomes available as creators grow.
- Fans get a simple app experience first, with privacy, wallet, and data controls available when needed.
- Provider choice should feel like product control, not infrastructure burden.

### 3.10 Open Governance

The core protocol must be governed so no one provider, app, AI company, hosting company, or payment company can capture the network.

Required product behavior:

- Certification, API versioning, conformance testing, revocation, provider audits, and dispute handling are governed neutrally.
- Open-source reference implementations should exist for core components.
- Commercial providers can compete, but cannot redefine portability rules unilaterally.
- Governance should protect creators, fans, developers, providers, sponsors, and shared utilities.

## 4. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator-owned channel | Canonical creator identity and channel metadata are portable and separate from any host or app. | Creators do not lose their business when switching providers. | Creator Experience, Creator Metadata, Hosting Lifecycle, Migration |
| Fan-owned identity | Fans use a portable Fan Passport and wallet across compatible apps. | Fans do not rebuild follows, payments, privacy settings, and entitlements in every app. | Fan Experience, Fan Passport, Fan Apps, Data Rights |
| Certified provider marketplace | Providers compete through certified APIs and declared capabilities. | The ecosystem gets competition without breaking interoperability. | Provider Marketplace, Governance, Developer Ecosystem |
| Machine-readable manifests | Business rules, permissions, and contracts are encoded in standard signed manifests. | Apps and providers can enforce rights consistently. | Metadata, Monetization, Hosting, AI, Extensions, Search, Settlement |
| Receipt-based settlement | Monetized actions produce signed receipts that feed ledgers and payouts. | Creator and provider payments become auditable and explainable. | Revenue Settlement, Monetization, Trust/Safety, Business Model |
| Progressive unbundling | Creators can start free and gradually take control of hosting, ads, AI, analytics, CDN, and storage. | Loom can serve new creators and mature creators without forcing a platform switch. | Creator Experience, Hosting Lifecycle, Provider Marketplace |
| Audience Data Firewall | Fan data, creator audience data, and provider processing rights are separated. | Fans gain privacy, creators retain legitimate audience tools, and providers are constrained. | Data Rights, Fan Passport, Creator Experience, Sponsors |
| Creator-led recommendations | Creators publish portable recommendation manifests and may earn referral revenue. | Discovery is based on trust and accountability rather than only opaque engagement ranking. | Recommendations, Fan Experience, Revenue Settlement |
| Neutral public search | Search is distributed, fan-initiated, and not pay-to-rank. | Fans can explore broadly without turning search into another ad auction. | Search, Fan Apps, AI, Governance |
| Certified extensions | Creators can install sandboxed plugins with scoped permissions and portable state. | Creator channels become customizable without compromising security or portability. | Extensions, Developer Ecosystem, Campaigns, Trust/Safety |
| Pluggable AI layer | AI services are provider-neutral, permissioned, and receipt-generating. | Creators and fans can use AI without centralizing control over archives or private data. | AI, Data Rights, Search, Recommendations, Revenue Settlement |
| Open governance and certification | Neutral governance enforces certification, conformance, audits, and dispute resolution. | The network remains open, interoperable, and resistant to capture. | Governance, Trust/Safety, Provider Marketplace |

## 5. Primary Actors

### Creator

Publishes content, owns a Creator Channel, manages fans, selects providers, installs extensions, monetizes content, publishes recommendations, and reviews receipts and payouts.

### Fan

Follows creators, consumes content, manages identity and wallet, joins memberships, participates in campaigns, uses search and AI, controls privacy, and carries state across apps.

### Fan App

Displays content, search, feeds, recommendations, wallet surfaces, extension surfaces, privacy settings, and campaign experiences while respecting manifests and permissions.

### Hosting Provider

Stores media, serves playback, exposes public catalog/search APIs, generates delivery receipts, supports export, and may offer managed monetization services.

### Service Provider

Provides ads, payments, settlement, AI, analytics, moderation, search, recommendations, vaults, or other specialized services through certified APIs.

### Extension Developer

Builds plugins or campaign modules that creators can install into channels and fan apps can render safely.

### Sponsor / Brand

Works with creators through permissioned campaigns, sponsor placements, product cards, giveaways, and measurable conversions.

### Governance / Foundation

Maintains protocol standards, certification, conformance tests, registries, dispute processes, revocation, public incident reporting, and open-source reference implementations.

## 6. Product Experience Requirements

### 6.1 Creator Experience

The creator should experience Loom as a single operating system for their media business, not as a pile of infrastructure choices.

Required experience:

- Start a channel quickly with sensible defaults.
- Understand that the channel belongs to the creator.
- Publish content without choosing every provider manually.
- See when the creator is using a managed provider versus a modular provider.
- Compare provider alternatives when they are ready.
- See revenue and cost transparency.
- Export or migrate channel state without needing support tickets.
- Install extensions with clear permissions and reversible access.

### 6.2 Fan Experience

The fan should experience Loom as a better way to follow creators, not as a protocol.

Required experience:

- Sign in once with a Fan Passport.
- Follow a creator once and see that relationship in compatible apps.
- Use one wallet for memberships, premium, AI credits, tips, paid events, and paid content.
- Understand privacy modes in plain language.
- Revoke app or campaign permissions.
- Search broadly when they intend to search.
- Receive recommendations that disclose why something is shown.
- Join campaigns without unknowingly giving away broad data rights.

### 6.3 Provider Experience

The provider should experience Loom as a market with clear rules and real commercial opportunity.

Required experience:

- Register as a provider.
- Declare capabilities.
- Run conformance tests.
- Publish terms and pricing.
- Receive signed receipts for services rendered.
- Get paid through settlement.
- Support export, audit, and dispute workflows.

### 6.4 Developer Experience

The developer should be able to build apps, extensions, tools, and providers without private platform access.

Required experience:

- Use SDKs and local emulators.
- Generate and validate manifests.
- Run conformance tests locally and in CI.
- Submit signed artifacts.
- Receive clear certification results.
- Access sandbox data.
- Understand permission scopes and risk classes.

### 6.5 Governance Experience

Governance should make trust and interoperability operational, not symbolic.

Required experience:

- Review provider capability claims.
- Run automated and manual audits.
- Revoke keys or suspend marketplace listings.
- Resolve disputes.
- Publish certification scope and incident records.
- Version APIs and manifests without breaking the network unexpectedly.

## 7. User Stories

### Story 1: Creator starts with a portable channel

As a new creator, I want to create a Loom channel with managed defaults so I can publish immediately while still owning my channel identity and future migration rights.

End state:

- A Creator Channel exists in the registry.
- A Creator Metadata Host stores the creator's portable channel state.
- A default hosting provider is attached through a Hosting Contract Manifest.
- The creator can publish content and later change providers.

Interacting areas:

- Creator Experience
- Creator Channel and Metadata Architecture
- Hosting Provider Lifecycle
- Provider Marketplace
- Migration Strategy

### Story 2: Creator grows and unbundles providers

As a growing creator, I want to compare hosting, ad, analytics, AI, and payment providers so I can improve economics and control without rebuilding my channel.

End state:

- Provider alternatives are visible in Creator Studio.
- Cost and revenue simulations show the effect of switching or unbundling.
- The creator updates provider contracts.
- Receipts and settlement rules continue without losing history.

Interacting areas:

- Creator Experience
- Hosting Lifecycle
- Provider Marketplace
- Revenue Settlement
- Business Model

### Story 3: Fan follows a creator across apps

As a fan, I want to follow a creator once and carry that relationship across compatible apps so I do not need separate accounts and subscriptions everywhere.

End state:

- Fan Passport records the follow relationship.
- Fan app permissions are scoped.
- The creator sees a creator-scoped audience relationship, not the fan's entire cross-network identity.
- The fan can use another certified app and keep the follow.

Interacting areas:

- Fan Experience
- Fan Passport
- Fan Apps
- Audience Data Firewall
- Creator Experience

### Story 4: Fan pays for premium without breaking creator economics

As a fan, I want to pay for a global no-ad experience so I can avoid ads while still supporting the creators I watch.

End state:

- Fan Wallet records the premium entitlement.
- Playback service recognizes no-ad mode.
- PremiumNoAdReceipt records qualifying consumption.
- Settlement allocates subscription value to creators and providers.

Interacting areas:

- Fan Experience
- Fan Wallet
- Monetization Models
- Revenue Settlement
- Business Model

### Story 5: Creator recommends another creator

As a creator, I want to recommend trusted creators to my fans and earn referral revenue when my recommendation leads to qualified engagement.

End state:

- Creator publishes a Recommendation Manifest.
- Destination creator has Referral Terms Manifest if referral revenue is enabled.
- Fan app shows the recommendation with clear disclosure.
- Qualified discovery events produce receipts.
- Settlement distributes referral revenue according to terms.

Interacting areas:

- Creator-Led Recommendation Economy
- Fan Experience
- Revenue Settlement
- Trust/Safety
- Governance

### Story 6: Creator installs a campaign extension

As a creator, I want to install a certified giveaway extension so I can engage fans and sponsors without exposing more fan data than needed.

End state:

- Extension manifest is reviewed before install.
- Creator grants scoped permissions.
- Fans see campaign terms and data grants.
- Campaign entries and reward events create receipts.
- Campaign state is portable and exportable.

Interacting areas:

- Extensions
- Developer Ecosystem
- Audience Data Firewall
- Sponsor Tools
- Revenue Settlement
- Trust/Safety

### Story 7: AI provider powers creator archive Q&A

As a creator, I want fans to ask questions over my archive through approved AI providers so fans get value and my content receives source attribution and royalties.

End state:

- Creator AI permissions are declared in AIContentPolicy.
- Fan AI request uses permitted content access.
- AI usage and source attribution receipts are generated.
- Fan memory and privacy settings are respected.
- Settlement can allocate AI royalties.

Interacting areas:

- AI Layer
- Creator Metadata
- Fan Passport
- Revenue Settlement
- Data Rights

### Story 8: Provider becomes certified

As a provider, I want to certify my API implementation so creators and apps can trust my service and I can participate in the marketplace.

End state:

- Provider publishes a Provider Capability Manifest.
- Conformance tests run against declared APIs.
- Governance records certification scope.
- Provider listing appears in the marketplace.
- Service usage creates receipts for settlement.

Interacting areas:

- Provider Marketplace
- Developer Ecosystem
- Governance
- Revenue Settlement
- Trust/Safety

### Story 9: Fan searches across the network

As a fan, I want to search public creator content across Loom without paid ranking so I can intentionally find content beyond my follow graph.

End state:

- Fan app sends query to Search Directory or host search APIs.
- Hosts return signed public results.
- App merges results neutrally.
- Search receipts support audit and utility funding.
- Fan may optionally use an AI search assistant with permissioned access.

Interacting areas:

- Neutral Public Search
- Fan Apps
- AI Layer
- Governance
- Business Model

### Story 10: Creator exits a provider

As a creator, I want an exit path from any provider so I can move my channel, content metadata, receipts, extension state, and provider contracts to another certified provider.

End state:

- Migration plan is generated.
- Metadata, media, receipts, and extension state are exported as supported.
- Registry pointer updates to the new metadata host.
- Fans keep follows and entitlements.
- Settlement and dispute records remain auditable.

Interacting areas:

- Migration Strategy
- Creator Metadata
- Provider Marketplace
- Fan Passport
- Revenue Settlement
- Governance

## 8. End-to-End Workflows

### Workflow 1: Creator onboarding and first publish

Goal: Let a creator start quickly while proving that channel identity and metadata are portable from day one.

Actors:

- Creator
- Creator Studio
- Creator Channel Registry
- Creator Metadata Host
- Default Content Host
- Provider Capability Registry

Steps:

1. Creator signs up in Creator Studio.
2. Creator creates a channel name, handle, profile, and optional domain binding.
3. Creator Channel Registry creates canonical channel identity, public key records, and root `CreatorChannelManifest`.
4. Creator Studio provisions a default Creator Metadata Host.
5. Creator chooses default managed hosting or accepts a recommended free managed host.
6. Hosting Contract Manifest is attached to the channel.
7. Creator uploads first content.
8. Content Host returns content metadata and playback references.
9. Creator Metadata Host stores Content Manifest and updates public catalog.
10. Fan app can discover and play the content through standard APIs.

Product principles proven:

- Creator-owned channel.
- Metadata separate from media hosting.
- Certified provider default path.
- Future migration support.

### Workflow 2: Fan onboarding, follow, and cross-app portability

Goal: Let a fan follow a creator and carry the relationship across apps.

Actors:

- Fan
- Fan App A
- Fan App B
- Fan Passport Ledger
- Core Fan Vault
- Creator Audience Vault

Steps:

1. Fan creates or signs into a Fan Passport in Fan App A.
2. Fan Passport Ledger creates or resolves the fan's `FanPassportClaim`.
3. Fan follows a creator.
4. `FollowRelationshipAPI` records the relationship.
5. Fan App A receives only the app permissions the fan grants.
6. Creator Audience Vault receives creator-scoped audience state.
7. Fan saves content and notification preferences in the Core Fan Vault.
8. Fan signs into Fan App B with the same Fan Passport.
9. Fan App B requests scoped access.
10. Fan sees the same followed creator, saved references, and valid entitlements where permissions allow.
11. Fan can revoke either app independently.

Product principles proven:

- Fan portability.
- Pairwise and scoped identity.
- Apps do not own the fan relationship.
- Creator gets legitimate audience signal without unrestricted surveillance.

### Workflow 3: Provider certification and marketplace listing

Goal: Let a provider join Loom through verified capability claims.

Actors:

- Provider
- Developer Console
- Provider Certification System
- Governance Admin
- Marketplace Listing API
- Conformance Test Suite

Steps:

1. Provider creates a provider account.
2. Provider publishes a Provider Capability Manifest.
3. Provider accepts `ProviderParticipationTerms`.
4. Provider declares supported API versions, pricing, data use, export support, uptime targets, and public keys.
5. Provider runs local conformance tests.
6. Provider submits certification request through `ProviderCertificationAPI`.
7. Certification system runs automated tests and may request manual review.
8. Governance records `CertificationScopeRecord` and signing-key status.
9. Marketplace publishes provider listing.
10. Creator Studio and apps can compare the provider against alternatives.
11. Provider receives receipts and payouts only for certified service roles.

Product principles proven:

- Provider competition by capability.
- Claims are tested, not merely marketed.
- Marketplace trust is tied to certification.

### Workflow 4: Monetized playback and settlement

Goal: Turn a fan content session into auditable economic records.

Actors:

- Fan
- Fan App
- Content Host
- Playback Authorization Service
- Ad Decision Service or Premium No-Ad Service
- Receipt Ledger
- Settlement Engine
- Creator Dashboard
- Provider Console

Steps:

1. Fan selects content.
2. Fan App requests playback authorization.
3. Authorization checks Content Manifest, Monetization Manifest, and fan entitlements.
4. If fan is ad-supported, Ad Decision Service selects eligible ads.
5. If fan is premium no-ad, playback skips ads and records premium mode.
6. Content Host serves playback.
7. Playback, ad, delivery, or no-ad receipts are generated.
8. Receipt Ledger ingests signed receipts.
9. Settlement Engine applies Settlement Manifest and provider contracts.
10. Creator receives a CreatorPayoutStatement with gross revenue, provider costs, adjustments, and payout estimates.
11. Providers receive ProviderPayoutStatements for service-level receipts and settlement records.
12. Premium fan allocation can be shown in a FanSubscriptionAllocationStatement where applicable.

Product principles proven:

- Transparent economics.
- No receipt, no payout.
- Fan premium behavior can still support creators.
- Provider compensation is auditable.

### Workflow 5: Creator-led recommendation and referral settlement

Goal: Show how discovery can flow through creator trust instead of black-box ranking alone.

Actors:

- Source Creator
- Destination Creator
- Creator Studio
- Creator Discovery Exchange
- Recommendation Workbench
- Fan Scoped Recommendation Engine
- Fan App
- Fan
- Receipt Ledger
- Settlement Engine

Steps:

1. Destination creator publishes optional Referral Terms Manifest.
2. Source creator uses Creator Discovery Exchange to find relevant creators, public content, promotions, referral terms, and reputation signals.
3. Source creator may delegate bounded AI assistance through `CreatorAgentDelegationToken` to draft recommendations.
4. Source creator uses Recommendation Workbench to publish a Recommendation Manifest.
5. Source creator labels the recommendation as editorial, affiliate, sponsored, or paid where applicable.
6. Fan App fetches candidate recommendations from creators the fan trusts.
7. Fan Scoped Recommendation Engine ranks trusted candidates using fan settings and eligible community feeds. It does not become a broad autonomous crawler.
8. Fan sees why the recommendation appears.
9. Fan follows, watches, joins, or buys from destination creator.
10. `DiscoveryReceipt` or `CreatorReferralReceipt` records qualified event.
11. Settlement Engine applies referral terms and caps.
12. Creator recommendation reputation updates over time.

Product principles proven:

- Creator trust graph.
- Disclosure.
- Referral economics.
- Recommendation accountability.

### Workflow 6: Extension-powered sponsor campaign with data grant

Goal: Let a creator run a sponsor campaign while keeping fan permissions explicit.

Actors:

- Creator
- Sponsor
- Extension Developer
- Extension Registry
- Fan App
- Fan
- Campaign Ledger
- Reward Ledger
- Audience Data Firewall
- Settlement Engine

Steps:

1. Extension developer publishes a certified campaign extension.
2. Sponsor proposes campaign terms.
3. Creator installs the extension and configures campaign rules.
4. CampaignManifest defines eligibility, dates, rewards, sponsor disclosures, data needs, and alternate entry rules.
5. Fan App renders campaign experience.
6. Fan reviews campaign terms and grants only the required Campaign Data Grant.
7. Campaign entry is recorded.
8. RewardReceipt records reward issuance or redemption.
9. Sponsor receives aggregate reporting or permissioned conversion data.
10. Settlement Engine allocates campaign fees according to manifest.

Product principles proven:

- Extensible creator channels.
- Fan consent.
- Sponsor transparency.
- Campaign economics with receipts.

### Workflow 7: Fan search and AI-assisted discovery

Goal: Let a fan intentionally search beyond their graph while preserving neutral search principles.

Actors:

- Fan
- Fan App
- Search Directory
- Host Public Search APIs
- Optional Fan AI Assistant
- Search Receipt Ledger

Steps:

1. Fan enters a search query.
2. Fan App sends query to Search Directory or relevant host search APIs.
3. Hosts return signed results using PublicSearchResultSchema.
4. Fan App merges results neutrally using certified behavior.
5. Fan filters by creator, content type, freshness, duration, language, topic, or transcript availability.
6. `SearchReceipt` records query routing and result source for audit and utility funding only.
7. If fan uses AI search, the assistant uses permitted search tools and fan privacy settings.
8. Fan opens content, triggering normal playback or content access workflows.

Product principles proven:

- Search is not recommendations.
- No paid ranking.
- No search ads or per-click search monetization.
- Distributed indexing.
- Fan-initiated discovery.

### Workflow 8: Creator migration to a new provider

Goal: Make provider switching real, not theoretical.

Actors:

- Creator
- Current Provider
- New Provider
- Creator Channel Registry
- Creator Metadata Host
- Media Export API
- Receipt Export API
- Extension State Export API
- Migration System
- Migration Plan API
- Migration Receipt
- Governance / Dispute System

Steps:

1. Creator requests migration plan.
2. `MigrationPlanAPI` reads current provider contracts, `MigrationManifest`, and export capabilities.
3. Creator chooses destination provider.
4. System exports creator metadata, content catalog, supported media files, manifests, receipts, extension state, and campaign state.
5. New provider validates import.
6. Creator confirms cutover.
7. Creator Channel Registry updates metadata host pointer or provider relationship pointers.
8. Fan follows and entitlements remain valid.
9. Old provider generates final settlement records.
10. `MigrationReceipt` records the migration steps and cutover state.
11. Disputes, missing exports, or contract violations are routed to governance.

Product principles proven:

- Exit rights.
- Portable channel state.
- Provider accountability.
- Fan continuity.

## 9. Cross-Area Requirements

Every future product definition should answer how it supports these baseline requirements:

- Does it preserve creator ownership of channel identity and business state?
- Does it preserve fan identity portability and data controls?
- Does it use certified APIs instead of private lock-in?
- Does it create or consume machine-readable manifests where rights or business rules are involved?
- Does it generate signed receipts for monetized or auditable actions?
- Does it respect the Audience Data Firewall?
- Does it support export, migration, revocation, or dispute workflows where relevant?
- Does it keep search, recommendations, and ads conceptually separate?
- Does it avoid requiring creators or fans to understand protocol complexity before they receive value?
- Does it expose enough transparency for creators, fans, providers, developers, and governance to trust the system?

## 10. Prototype Implications

The prototype should prove the core thesis in a narrow but end-to-end way.

The first prototype does not need every provider type or complete federation. It should include enough working surfaces to show that:

- A creator can create a portable channel.
- A creator can publish content into a metadata model separate from hosting.
- A fan can create a portable identity and follow the creator.
- A fan can consume free ad-supported or simulated premium no-ad content.
- Basic usage receipts can be generated.
- Settlement can be simulated from receipts and manifests.
- A public search path can return neutral results.
- A creator can publish a recommendation manifest.
- Basic AI summary/search over creator transcripts or content metadata can work where source material is available.
- A simple extension, such as a poll or giveaway, can be installed with scoped permissions.
- A provider capability manifest can be registered.
- A creator metadata export can be produced.

## 11. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

For a prototype, Loom needs minimal but coherent versions of the following systems. These do not need to be production-scale, but they should use the same conceptual boundaries as the final architecture so that the prototype validates the real product thesis.

#### Core control-plane systems

- Creator Channel Registry: creates and resolves canonical creator/channel identity, public keys, metadata host pointers, provider relationships, migration state, and `CreatorChannelManifest`.
- Creator Metadata Host: stores channel profile, content catalog, content manifests, monetization manifests, hosting contracts, recommendation manifests, extension installs, campaign settings, AI permissions, provider settings, and export state.
- `FanPassportAPI`: create, resolve, update, and migrate fan identity records.
- Fan Passport Ledger: creates and resolves fan identity, `FanPassportClaim`, personas, follow relationships, consent grants, app permissions, entitlement references, and migration records.
- Core Fan Vault: stores lightweight fan-owned portable state, including preferences, saved content references, app settings, notification preferences, blocked items, lightweight AI settings, and reward state. It is not the primary store for rich behavioral history.
- Private Event Vault: stores richer fan behavioral data, such as watch, search, AI, recommendation, and interaction history, under purpose-bound access controls.
- Creator Audience Vault: stores creator-scoped audience records, campaign segments, creator analytics, and permissioned CRM export state.
- Entitlement Ledger and Fan Wallet: stores memberships, premium no-ad entitlement, AI credits, tips, paid events, paid content, and payment receipt references.

#### Provider and governance systems

- Provider Capability Registry: stores provider capability manifests, supported API versions, pricing summaries, data-use claims, export support, and provider public keys.
- Provider Participation Terms: records legal, commercial, data-use, export, and marketplace obligations for certified providers.
- Provider Certification API: receives certification submissions and evidence.
- Certification and Conformance System: runs tests that verify provider, app, extension, and API behavior.
- Certification Scope Record: records the precise capability, version, status, restrictions, and expiration for each certified role.
- Provider Audit API: supports continuous certification checks, incident review, and compliance probes.
- Provider Key Management API: issues, rotates, suspends, and revokes provider signing keys.
- Marketplace Listing API: exposes certified providers, apps, extensions, and service roles to creators, fans, and developers.
- Governance Admin: handles certification scope, audits, key revocation, incidents, disputes, and provider suspension.

#### Data-plane systems

- Basic Content Host and Media Pipeline: supports upload, content references, playback authorization, public catalog, media export, and delivery receipts.
- Public Search Utility: supports host public search APIs, public catalog indexing, result schemas, neutral merge behavior, and search receipts.
- Creator Discovery Exchange: supports `CreatorDiscoveryAPI`, reputation lookup, promotion discovery, referral-term discovery, and `CreatorAgentDelegationToken` for bounded AI-assisted recommendation drafting.
- Creator Recommendation Graph and Referral Engine: supports creator-authored `RecommendationManifest`, `ReferralTermsManifest`, recommendation disclosures, `DiscoveryReceipt`, `CreatorReferralReceipt`, and referral settlement inputs.
- Fan Scoped Recommendation Engine: supports `FanScopedRecommendationAPI`, fan settings, trust-graph candidate ranking, private in-vault ranking hooks, and fan feedback.
- Community Recommendation Feed Provider: supports optional curated community feeds through `CommunityFeedAPI` and subscription controls without turning recommendations into paid search.
- Extension Registry and Runtime: supports Extension Manifests, signed artifacts, install records, scoped permissions, sandboxed rendering, campaign ledgers, and exportable extension state.
- AI Gateway: supports AI provider calls, creator AI permissions, fan AI privacy settings, AI usage receipts, source attribution, and optional search/recommendation tools.

#### Economic systems

- Receipt Ledger: exposes `ReceiptIngestAPI` and ingests signed playback, ad, no-ad, AI, campaign, referral, search, delivery, membership, migration, data-access, and settlement receipts.
- Settlement Engine or Settlement Simulator: uses `SettlementManifest` and `SettlementEngineAPI` to apply manifests and provider contracts to receipts.
- `PayoutAPI`: routes creator and provider payouts when real payments are enabled.
- `CreatorPayoutStatement`: explains creator gross revenue, costs, adjustments, referrals, AI royalties, and net payout.
- `ProviderPayoutStatement`: explains provider service receipts, adjustments, and net payout.
- `FanSubscriptionAllocationStatement`: explains how premium or no-ad subscription value supported creators where applicable.
- `PaymentProviderAPI`: supports charges, refunds, subscriptions, `PaymentReceipt`, payout instructions, and `RefundChargebackRecord`. The prototype can simulate external money movement.
- `UtilityFeePolicy`: defines how shared infrastructure like identity, vaults, search, and settlement is funded.

#### Trust, safety, and data-rights systems

- `AudienceDataFirewallPolicy`: separates fan private data, creator-scoped audience data, and provider processing rights.
- `FollowVisibilityPolicy`: fan-selected creator relationship visibility that limits public display, creator visibility, exports, and downstream app/plugin use.
- `DirectContactGrant`: explicit fan permission for creator direct-contact and CRM use, with revocation and destination limits.
- `CreatorRelationshipActionRecord`: audit evidence for follow, unfollow, block, visibility change, direct-contact revocation, and creator-scoped deletion requests.
- `CreatorScopedTombstoneRecord`: minimal retained marker that prevents rehydration of deleted creator-scoped relationship data while preserving required audit, safety, settlement, and legal exceptions.
- `CreatorAudienceExportPolicy`: field, destination, retention, watermarking, no-resale, revocation, and breach-notice rules for creator audience exports.
- `ConsentGrantAPI`: supports fan consent, `DataUseGrant`, `CampaignDataGrant`, purpose-bound data access, revocation, export, and delete.
- `DataAccessReceipt`: records approved data access for audit and dispute resolution.
- `DerivedInterestTokenAPI`: allows privacy-preserving ad or recommendation signals without raw data export.
- `PrivateRankingAPI`: ranks recommendations inside the Private Event Vault where fan privacy settings require it.
- `FraudSignalAPI` and `AbuseReportAPI`: attach confidence scores or validity signals to playback, ad, referral, campaign, search, and payment receipts.
- `ModerationLabelAPI` and `TakedownAPI`: support content labels, abuse reports, legal takedowns, disputes, and provider incidents.

#### Migration, export, and backup systems

- `MigrationManifest`: declares export, import, rehydration, backup, and provider-exit terms.
- `MigrationPlanAPI`: builds a step-by-step provider switch plan from current contracts and destination capabilities.
- `MigrationReceipt`: records migration execution, cutover state, failures, and dispute-relevant evidence.
- `CreatorExportAPI`: exports creator metadata, manifests, content catalog, provider settings, receipt references, extension state, and campaign state.
- `FanExportAPI`: exports fan identity, vault state, consent records, entitlements, and app permissions within fan privacy settings.
- `MediaExportAPI`: exports originals, renditions, or references where rights and provider contracts allow.
- `ReceiptExportAPI`: exports revenue, usage, settlement, and audit history.
- `ExtensionStateExportAPI`: exports installed extension configuration, portable campaign state, and reward state.
- `BackupProviderAPI`: supports backup/archive storage for creators, fans, and governance-required evidence.

#### Experience surfaces

- Creator Studio: channel setup, publishing, provider selection, extension install, campaign setup, recommendation builder, revenue dashboard, export/migration controls.
- Fan App: sign-in, follow, watch/read, wallet, search, recommendations, campaigns, privacy controls, app permissions, AI tools.
- Provider Console: capability registration, conformance results, service metrics, receipts, payouts, certification status.
- Developer Console: SDKs, manifest validation, extension submission, provider tests, sandbox access, signed artifact workflow.
- Sponsor Dashboard: campaign setup, sponsor disclosures, aggregate reporting, conversion receipts, and compliance status.
- Governance Admin: certification, audits, disputes, incidents, revocation, and public status records.

#### Capabilities to modify as the prototype matures

- Replace simulated payments with real payment provider integrations.
- Replace settlement simulation with real payout workflows.
- Replace single-host search with distributed host search and neutral merge.
- Replace local manifests with signed versioned manifests and public keys.
- Replace mock certification with automated conformance tests.
- Replace simple extension sandbox with certified runtime isolation.
- Replace simple fan identity with pairwise IDs, personas, and full vault controls.
- Replace basic export with full migration planning and rehydration.

## 12. Open Questions

- What is the first creator vertical for the prototype: video creators, educators, podcasters, newsletter writers, livestreamers, or a mixed creator profile?
- Should the prototype prioritize creator-owned channel portability or fan passport portability first if timeline forces a tradeoff?
- What level of payment simulation is acceptable before integrating real payment providers?
- Should the first extension prove engagement, such as polls or quizzes, or monetization, such as sponsored giveaways?
- Should the first AI feature be creator archive Q&A, content summaries, or recommendation drafting?
- What is the minimum governance surface needed for the prototype: provider registry only, or registry plus automated conformance checks?
