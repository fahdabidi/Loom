# Loom Product Definition 12: Creator-Led Recommendation Economy

Status: Draft for review  
Product area: 12 of 22  
Depends on: 01 Core Thesis and Platform Principles; 02 Creator Experience; 03 Fan Experience; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 11 AI Layer; 14 Audience Data Firewall and Data Rights; 17 Trust, Safety, Fraud, and Compliance

## 1. Product Definition

The Creator-Led Recommendation Economy makes creator trust a first-class discovery system. Instead of relying only on opaque engagement-maximizing feeds, creators can publish portable `RecommendationManifest` records that fan apps rank according to fan preferences. Destination creators can publish referral terms, and qualified engagement can generate referral revenue.

The goal is not to remove algorithmic ranking. The goal is to make the source of recommendation candidates more accountable, portable, and economically transparent.

Recommendation providers and fan apps can rank eligible candidates, but they cannot become owners of the discovery graph, broad autonomous crawlers, undisclosed paid-ranking feeds, or substitutes for neutral public search.

## 2. Scope

This product area covers:

- Creator Discovery Exchange.
- Creator Recommendation Graph.
- Recommendation Workbench.
- `RecommendationManifest`.
- `ReferralTermsManifest`.
- Fan Scoped Recommendation Engine.
- Community Recommendation Feed Provider.
- Trusted recommendation candidate boundaries.
- Private ranking and data-rights gates.
- Recommendation disclosures.
- Creator recommendation reputation.
- Referral attribution windows and caps.
- Discovery and referral receipts.
- Anti-clickbait and recommendation abuse controls.

It does not define neutral public search. Search is separate and non-monetized.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Creator-authored recommendations | Creators publish `RecommendationManifest` records. | Discovery begins with trust and editorial accountability. | Creator Experience |
| Creator Discovery Exchange | Tools for creators to find creators, content, promotions, referral terms, and reputation signals. | Creators can recommend beyond their existing knowledge. | AI Layer |
| Referral terms | Destination creators define terms for referral payouts. | Referral economics are explicit. | Revenue, Receipts, Ledgers, and Settlement |
| Fan scoped ranking | Fan apps rank trusted recommendation candidates based on fan settings. | Fans keep control over recommendation experience. | Fan Experience |
| Disclosures | Editorial, paid, affiliate, sponsored, or referral labels are visible. | Fans understand why recommendations appear. | Trust, Safety, Fraud, and Compliance |
| Creator reputation | Recommendation quality and abuse signals affect creator reputation. | Reduces spam and clickbait. | Governance, Certification, and Foundation Model |
| Discovery receipts | Qualified discovery events are auditable. | Enables referral settlement and abuse detection. | Revenue, Receipts, Ledgers, and Settlement |
| Community feeds | Optional curated feeds can supplement creator recommendations. | Supports topics and communities without replacing creator trust. | Fan Apps and App Ecosystem |
| AI-assisted drafting | AI can help creators find and draft recommendations, but creators publish them. | Improves workflow without autonomous hidden ranking. | AI Layer |

## 4. Product Experience Requirements

### 4.1 Creator Experience

Creators should be able to:

- Discover relevant creators and content.
- Review reputation, public metrics, topic fit, and referral terms.
- Draft recommendations with required disclosures.
- Publish, update, pause, or remove recommendations.
- See recommendation performance and referral revenue.
- Understand reputation effects.

### 4.2 Fan Experience

Fans should be able to:

- See recommendations from creators they trust.
- Understand why a recommendation is shown.
- Filter or mute recommendation sources.
- Add optional community feeds.
- Provide feedback.
- Avoid paid ranking disguised as search.

### 4.3 Destination Creator Experience

Destination creators should be able to:

- Publish referral terms.
- Limit eligibility, payout windows, caps, and abuse rules.
- See inbound recommendation performance.
- Dispute invalid referrals.

## 5. User Stories

### Story 1: Creator recommends trusted creator

As a creator, I want to recommend another creator I trust so my fans can discover relevant work.

End state:

- `RecommendationManifest` is published.
- Fan apps can show recommendation.
- Disclosure is visible.

### Story 2: Creator earns referral revenue

As a creator, I want referral revenue when my recommendation drives qualified engagement.

End state:

- Destination creator has referral terms.
- Qualified action creates receipt.
- Settlement allocates referral revenue.

### Story 3: Fan controls recommendation sources

As a fan, I want to choose which creator recommendations influence my feed.

End state:

- Fan settings control sources.
- Fan app ranks candidates.
- Feedback affects future ranking.

### Story 4: Destination creator sets terms

As a destination creator, I want to define referral payout terms so discovery economics are predictable.

End state:

- `ReferralTermsManifest` is published.
- Terms include action types, windows, caps, and exclusions.

### Story 5: Governance handles recommendation abuse

As governance, I want to detect clickbait and fake referral loops.

End state:

- Abuse signals are recorded.
- Recommendation reputation updates.
- Settlement can apply fraud adjustments.

### Story 6: Creator uses AI workbench

As a creator, I want AI help finding creators to recommend, but I want final editorial control.

End state:

- AI drafts candidates using bounded tools.
- Creator reviews disclosures.
- Creator publishes recommendation.

## 6. End-to-End Workflows

### Workflow 1: Destination creator publishes referral terms

Actors:

- Destination Creator
- Creator Studio
- Creator Metadata Host
- Settlement Engine

Steps:

1. Destination creator opens referral settings.
2. Creator defines eligible actions, payout amount or percentage, attribution window, caps, exclusions, and fraud rules.
3. Creator Studio validates terms.
4. `ReferralTermsManifest` is stored in channel metadata.
5. Creator Discovery Exchange can surface terms.

### Workflow 2: Source creator publishes recommendation

Actors:

- Source Creator
- Creator Discovery Exchange
- Recommendation Workbench
- AI Gateway
- Creator Metadata Host

Steps:

1. Source creator searches for creators, content, promotions, and referral terms.
2. Creator reviews reputation and fit.
3. Creator optionally grants `CreatorAgentDelegationToken` access to `RecommendationWorkbenchMCPServer` with bounded research and draft scopes.
4. AI-assisted draft records candidate provenance, sources, referral terms reviewed, and tool-call audit records.
5. Recommendation Workbench validates disclosure requirements, relationship labels, and referral-term compatibility.
6. Creator publishes `RecommendationManifest` through `RecommendationManifestAPI`.
7. Manifest becomes available to fan apps without transferring graph ownership to an app or provider.

### Workflow 3: Fan receives trusted recommendation

Actors:

- Fan
- Fan App
- Fan Scoped Recommendation Engine
- Creator Recommendation Graph
- Private Event Vault

Steps:

1. Fan App fetches recommendations from creators the fan follows or trusts.
2. App optionally adds enabled `CommunityFeedAPI` candidates and fan-initiated search-result candidates.
3. `FanScopedRecommendationAPI` applies `FanRecommendationSettings`, source filters, disclosure preferences, and trusted-candidate rules.
4. If private behavior influences ranking, `PrivateRankingAPI` runs in the Private Event Vault after a purpose-bound `DataUseGrant`; no raw private event data leaves the vault.
5. `DataAccessReceipt` records grant-protected private ranking access.
6. App displays recommendation with source, disclosure, funding/referral label, and why-shown context.
7. Fan follows, watches, joins, buys, saves, or dismisses.
8. `RecommendationFeedbackAPI` updates fan settings and future ranking.
9. Qualified discovery generates `DiscoveryReceipt`; eligible conversion may later generate `CreatorReferralReceipt`.

### Workflow 4: Referral settlement

Actors:

- Fan
- Source Creator
- Destination Creator
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan engages with destination creator after recommendation.
2. Attribution rules evaluate eligibility against the effective `RecommendationManifest`, `ReferralTermsManifest`, attribution window, fan privacy mode, and `SettlementManifest`.
3. `DiscoveryReceipt` or `CreatorReferralReceipt` is signed by the responsible app/provider and submitted through `ReceiptIngestAPI`.
4. `ReceiptLedger` stores immutable receipt evidence and manifest-version bindings.
5. Fraud signals attach confidence scores, invalid-referral flags, or `FraudAdjustmentRecord` entries.
6. `SettlementEngineAPI` applies referral terms, caps, reserves, chargebacks, and dispute adjustments.
7. `SettlementRunRecord` and `CreatorPayoutStatement` show source creator revenue, destination creator cost, and provider adjustments.

### Workflow 5: Community feed subscription

Actors:

- Fan
- Fan App
- Community Recommendation Feed Provider
- Governance System

Steps:

1. Fan browses available community feeds.
2. App shows feed topic, `CommunityRecommendationProviderManifest`, curation policy, funding model, ranking policy, certification state, and governance information.
3. Fan subscribes to feed.
4. `CommunityFeedAPI` provides recommendation candidates only from declared eligible sources.
5. Fan Scoped Recommendation Engine ranks them with fan settings and disclosure constraints.
6. `CommunityFeedAuditAPI` records feed delivery, funding disclosure, and ranking-policy compliance.
7. Community feed providers cannot sell paid-search placement or per-click ranking by default.
8. Fan can unsubscribe.

### Workflow 6: Recommendation abuse review

Actors:

- Fan
- Creator
- Fraud Signal Service
- Governance Admin
- Settlement Engine

Steps:

1. Abuse signals identify suspicious recommendations.
2. Signals may include clickbait, undisclosed paid relationships, referral loops, fake engagement, or high bounce.
3. Governance reviews evidence.
4. Recommendation reputation is adjusted.
5. Referral settlement may be held or adjusted.
6. Repeat abuse can affect creator or provider trust status.

## 7. Cross-Area Interactions

- Creator Experience: creators build and manage `RecommendationManifest`, `ReferralTermsManifest`, disclosures, and performance reporting.
- Fan Experience: fans consume and control recommendations through `FanRecommendationSettings`, `FanScopedRecommendationAPI`, and `RecommendationFeedbackAPI`.
- Fan Passport, Wallet, Vaults, and Identity Architecture: fan settings, `DataUseGrant`, and `PrivateRankingAPI` are enforced through vaults.
- Provider Marketplace and Certified APIs: community feed and recommendation providers require `ProviderCertificationAPI` and `CertificationScopeRecord`.
- Neutral Public Search Utility: `SearchReceipt`, `SearchDirectoryAPI`, and `NeutralSearchMergePolicy` remain separate from recommendations.
- Revenue, Receipts, Ledgers, and Settlement: `DiscoveryReceipt`, `CreatorReferralReceipt`, and `SettlementManifest` drive referral payouts.
- AI Layer: `RecommendationWorkbenchMCPServer`, `CreatorAgentDelegationToken`, and audit logs support recommendation drafting.
- Audience Data Firewall and Data Rights: private ranking requires `DataUseGrant`, `PrivateRankingAPI`, and `DataAccessReceipt`.
- Trust, Safety, Fraud, and Compliance: `RecommendationAbuseAPI`, disclosure audits, and `FraudAdjustmentRecord` enforce recommendation trust.
- Governance, Certification, and Foundation Model: `CertificationScopeRecord`, `DisputeResolutionAPI`, and reputation policy govern enforcement.
- Business Model and Incentive Design: `ReferralTermsManifest`, caps, reserves, and incentive audits avoid predatory engagement loops.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Creator discovery systems

- `CreatorDiscoveryAPI`: broad discovery for creators, content, events, promotions, and public profiles.
- `PromotionDiscoveryAPI`: campaigns, giveaways, events, launches, and offers.
- `ReferralTermsDiscoveryAPI`: creators with active referral terms.
- `CreatorReputationAPI`: quality, trust, recommendation reputation, abuse signals, and public metrics.
- `CreatorAgentDelegationToken`: bounded AI access for creator recommendation research.
- `RecommendationWorkbenchMCPServer`: scoped AI tool surface for recommendation research and draft generation.

#### Recommendation authoring systems

- `RecommendationWorkbenchAPI`: draft, validate, label, publish, update, pause, and delete recommendations.
- `RecommendationManifestAPI`: publishing and lifecycle API for creator recommendations.
- `RecommendationManifest`: source creator, destination creator/content, reason, disclosure, ranking hints, expiration, and labels.
- `RecommendationDisclosurePolicy`: editorial, paid, affiliate, sponsored, referral, or other relationship labels.
- `RecommendationWorkbenchAuditLog`: candidate source provenance, tool calls, disclosure checks, and publishing events.

#### Fan recommendation systems

- `FanScopedRecommendationAPI`: trusted candidate set, fan preferences, source filters, and feedback.
- `FanRecommendationSettings`: source controls, topic preferences, muted creators, community feeds, privacy mode, and disclosure preferences.
- `PrivateRankingAPI`: in-vault ranking where privacy mode or private behavior requires it.
- `DataUseGrant`: purpose-bound authorization for private ranking.
- `DataAccessReceipt`: audit record for grant-protected private ranking access.
- `RecommendationFeedbackAPI`: fan feedback, dismissals, source mutes, and preference updates.
- `CommunityFeedSubscriptionAPI`: opt in/out of community recommendation feeds.
- `CommunityFeedAPI`: curated feed candidate delivery from declared eligible sources.
- `CommunityRecommendationProviderManifest`: topic, funding, ranking, data-use, and governance policy for community feeds.
- `CommunityFeedAuditAPI`: delivery, funding disclosure, ranking-policy, and abuse audit records.

#### Referral and settlement systems

- `ReferralTermsManifest`: payout terms, eligible actions, attribution windows, caps, fraud rules, and exclusions.
- `CreatorReferralReceipt`: qualified referral event.
- `DiscoveryReceipt`: recommendation-driven discovery event.
- `ReceiptIngestAPI`: receipt validation and ledger submission.
- `ReceiptLedger`: immutable receipt store with manifest-version bindings.
- `SettlementManifest`: economic routing and settlement policy.
- `SettlementEngineAPI`: applies referral terms to settlement.
- `SettlementRunRecord`: settlement run output with referral allocations and adjustments.
- `CreatorPayoutStatement`: creator-facing statement for referral revenue or costs.
- `FraudAdjustmentRecord`: invalid referral or fake engagement adjustments.

#### Trust and governance systems

- `RecommendationReputationAPI`: source quality, fan feedback, clickbait signals, conversion quality, and abuse history.
- `RecommendationAbuseAPI`: reports and signals for spam, undisclosed paid placement, fake referrals, and manipulation.
- `DisclosureAuditAPI`: checks labels and paid relationships.
- `DisputeResolutionAPI`: referral and recommendation disputes.
- `CertificationScopeRecord`: provider/app/community-feed certification boundary.
