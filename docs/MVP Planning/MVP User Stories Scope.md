# Loom MVP — User Stories and Workflows Scope

## Purpose

This document assembles the user stories and end-to-end workflows from the existing product definition docs that are **required to deliver the MVP executive pitch**. Stories and workflows are copied from source docs; the source reference is noted beside each. Where a story or workflow is needed by the MVP but does not yet exist in the product docs, it is flagged as **MISSING** at the end of this document.

**MVP pitch reference:** [Loom Product Pitch.md](./Loom%20Product%20Pitch.md)

**The six-step "wow" demo this scope must support:**
1. Creator imports a back-catalog, publishes with a required content summary, enables archive Q&A, sets an ad policy.
2. Fan onboards, picks interests, selects a tile → sees a purposeful, transparent feed; dislikes an item and watches ranking change.
3. Fan toggles "rank by summary, ignore clickbait" via an AI agent → order changes with a why-shown explanation.
4. Fan asks the creator's entire archive a question → cited answer → source-royalty receipt generated.
5. Fan sees a creator-aligned contextual ad or buys the no-ad pass; accepts a data-for-value offer for a better giveaway.
6. Settlement simulator shows revenue split by source and by intent; creator clicks Export and walks away with everything.

---

## Scope legend

Each item is tagged:

- **IN** — required for MVP
- **IN (simulated)** — required for MVP, payment or settlement is simulated, not real money
- **PARTIAL** — a simplified or reduced version of the story is needed; the full version is deferred
- **DEFERRED** — out of scope for MVP

---

## Part A — Creator User Stories

**Source: [02-creator-experience.md](../Product%20Docs/02-creator-experience.md) §5**

---

### CE-S1: New creator creates a channel **[IN]**

As a new creator, I want to create a channel quickly so I can publish today while still owning my channel identity and export rights.

End state:
- Creator Channel exists in the Creator Channel Registry.
- `CreatorChannelManifest` is created.
- Creator Metadata Host stores channel state.
- Default hosting and settlement providers are attached through manifests.

---

### CE-S2: Creator publishes multi-format content **[IN]**

As a creator, I want to publish videos, posts, and events from one place so my fans can follow all of my work through one channel.

End state:
- Content appears in the creator's public catalog.
- Fan apps can render the content according to its content type and access mode.
- Search, AI, monetization, and playback rules are stored in manifests.

> **MVP note:** For MVP, scope to video and posts. Live events and courses are deferred.

---

### CE-S3: Creator launches memberships **[IN (simulated)]**

As a creator, I want to define membership tiers and member-only content so I can monetize recurring fan support without sending fans to another platform.

End state:
- Membership tiers are stored in channel metadata.
- Fan Wallet can sell and renew memberships.
- Entitlement Ledger can authorize member content.
- Revenue receipts feed settlement and creator payout statements.

---

### CE-S3A: Creator uses permissioned audience relationship data **[PARTIAL]**

As a creator, I want to understand, segment, and contact my audience where fans have allowed it so I can build a business without depending on platform-owned ad data.

End state:
- Creator sees creator-scoped follower and member state permitted by `FollowVisibilityPolicy`.
- Direct-contact and CRM exports require valid `DirectContactGrant`.
- `CreatorAudienceExportPolicy` limits fields, destination, retention, resale, and breach obligations.
- Fans who unfollow, block, revoke contact, or request deletion are removed from future eligible exports.

> **MVP note:** For MVP, scope to basic follower/member counts and aggregate insights. CRM export is deferred.

---

### CE-S4: Creator installs a giveaway extension **[PARTIAL]**

As a creator, I want to install a certified giveaway extension so I can run fan engagement campaigns without custom engineering.

End state:
- Creator reviews extension permissions.
- Extension install state is stored in channel metadata.
- Campaign entries and reward events create receipts.
- Fan data access uses explicit campaign data grants.

> **MVP note:** Deliver one built-in simple campaign (giveaway or poll). Full extension marketplace is deferred.

---

### CE-S5: Creator recommends another creator **[IN]**

As a creator, I want to recommend another creator to my audience and earn referral revenue when the recommendation produces qualified engagement.

End state:
- Creator uses discovery tools to evaluate destination creator and referral terms.
- `RecommendationManifest` is published.
- Fan apps show disclosures.
- Qualified referral events generate receipts and settlement entries.

---

### CE-S6: Creator reviews revenue and provider costs **[IN]**

As a creator, I want to understand why I was paid so I can trust the platform and optimize my business.

End state:
- Creator sees gross revenue by source.
- Provider costs, utility fees, adjustments, and net payout are visible.
- Playback, ad, premium no-ad, AI, referral, campaign, and membership receipts are traceable.

> **MVP note:** Revenue must be breakable by session intent (Trending vs. Creator Updates vs. Learn) per the pitch.

---

### CE-S7: Creator upgrades hosting control **[DEFERRED]**

Full provider comparison and unbundling. Single managed backend at MVP.

---

### CE-S8: Creator exports or migrates **[IN]**

As a creator, I want an exit button so I can move providers if terms, cost, reliability, or trust becomes unacceptable.

End state:
- Migration plan is generated.
- Portable channel state and required export state are available.
- Registry pointers can be updated.
- Final settlement and disputes remain auditable.

> **MVP note:** The "export everything" one-click path is a core pitch differentiator. Deliver metadata + content catalog + receipt export. Full provider migration routing is deferred.

---

### CE-S9: Creator enables AI archive Q&A **[IN]**

*(Not a standalone story in Doc 02 §5; covered by Workflow 7 — see CE-W7 below.)*

See also: **MISSING-S1** below.

---

## Part B — Creator Workflows

**Source: [02-creator-experience.md](../Product%20Docs/02-creator-experience.md) §6**

---

### CE-W1: Creator onboarding to first publish **[IN]**

Actors: Creator, Creator Studio, Creator Channel Registry, Creator Metadata Host, Provider Capability Registry, Payment/Payout Provider, Content Host, Fan App

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

---

### CE-W1A: Free managed hosting setup **[IN]**

Actors: Creator, Creator Studio, Provider Marketplace, Free Managed Host, Creator Metadata Host, Settlement Engine

Steps:
1. Creator selects free managed hosting during onboarding or from provider controls.
2. Creator Studio fetches certified host terms through `ProviderPricingAPI` and provider manifests.
3. Creator reviews host ad control, revenue share, no-ad replacement behavior, storage limits, retention and age-out rules, export rights, and support.
4. Creator accepts terms.
5. Creator Metadata Host stores `HostingContractManifest`, `MonetizationManifest`, `SettlementManifest`, and lifecycle settings.
6. `LifecyclePolicyAPI` controls retention, archival, and age-out behavior.
7. Playback and ad/no-ad rules use the managed hosting terms.
8. Creator Dashboard shows managed hosting economics and upgrade paths.

---

### CE-W2: Membership launch **[IN (simulated)]**

Actors: Creator, Creator Studio, Fan, Fan App, Fan Wallet, Entitlement Ledger, Receipt Ledger, Settlement Engine

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

---

### CE-W2A: Creator audience export and direct contact **[PARTIAL]**

Scope to basic aggregate audience insights and follower counts. CRM export deferred.

---

### CE-W3: Extension-powered campaign **[PARTIAL]**

Deliver one built-in simple giveaway/poll. Full extension runtime with arbitrary third-party plugins is deferred. See also CE-S4.

---

### CE-W4: Recommendation and referral **[IN]**

Actors: Creator, Creator Discovery Exchange, Recommendation Workbench, Destination Creator, Fan App, Receipt Ledger, Settlement Engine

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

---

### CE-W5: Provider upgrade or unbundling **[DEFERRED]**

---

### CE-W6: Creator export and migration **[IN]**

Actors: Creator, Migration System, Creator Metadata Host, Current Provider, Destination Provider, Governance Admin

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

> **MVP note:** For MVP, deliver export of metadata, content catalog, and receipts. Full provider migration routing deferred.

---

### CE-W7: Creator enables AI archive Q&A **[IN]**

Actors: Creator, Creator Studio, Creator Metadata Host, AI Gateway, AI Provider, Fan App, Receipt Ledger, Settlement Engine

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

---

## Part C — Fan User Stories

**Source: [03-fan-experience.md](../Product%20Docs/03-fan-experience.md) §5**

---

### FE-S1: Fan follows a creator once **[IN]**

As a fan, I want to follow a creator once so that I can see that creator across compatible apps.

End state:
- FollowRelationshipAPI records the follow.
- `FollowVisibilityPolicy` records fan-selected visibility.
- Creator gets creator-scoped audience signal.
- Other certified apps can show the follow when the fan grants access.
- Creator receives only the audience state allowed by the fan's relationship visibility and grants.

---

### FE-S1A: Fan changes relationship visibility **[PARTIAL]**

As a fan, I want to change how visible my creator relationship is so I can follow creators without exposing unnecessary identity.

End state:
- `FollowVisibilityPolicy` updates relationship visibility.
- Creator Audience Vault updates active creator-facing state.
- Previous required receipts and audit records remain preserved.
- Future direct contact, targeting, campaign eligibility, and exports follow the new setting.

> **MVP note:** Deliver basic public/private follow visibility. Pseudonymous/anonymous and full audit trail deferred.

---

### FE-S1B: Fan unfollows, blocks, or revokes creator access **[IN]**

As a fan, I want the same level of control Facebook exposes through unfollow/block, but with clearer data rights around creator-visible audience data.

End state:
- Fan can unfollow while keeping past purchases and required receipts intact.
- Fan can block a creator and stop future creator-initiated contact or community interactions.
- Fan can revoke `DirectContactGrant` without necessarily unfollowing.
- Fan can request creator-scoped tombstoning so future exports, plugins, sponsor tools, and apps cannot rehydrate deleted relationship state.

---

### FE-S2: Fan watches ad-supported content **[IN]**

As a free fan, I want to watch creator content without paying so I can try Loom and still support creators through ads.

End state:
- Playback is authorized.
- Ad decision is made according to content and fan data mode.
- Playback and ad receipts are generated.
- Creator settlement can include ad revenue.

---

### FE-S3: Fan buys global no-ad **[IN (simulated)]**

As a fan, I want one no-ad plan so I can avoid ads across participating content while still supporting the creators I watch.

End state:
- Fan Wallet records premium no-ad entitlement.
- Playback skips ads.
- PremiumNoAdReceipt records qualifying sessions.
- Settlement allocates subscription value.

---

### FE-S4: Fan joins a creator membership **[IN (simulated)]**

As a fan, I want to join a creator membership so I can access member content and support the creator directly.

End state:
- Payment or simulated payment succeeds.
- Membership entitlement is recorded.
- Member surfaces unlock across certified apps.
- Creator sees member growth and revenue.

---

### FE-S5: Fan searches intentionally **[IN]**

As a fan, I want to search public content without paid ranking so I can find creators and topics outside my follow graph.

End state:
- Search runs against certified public search APIs.
- Results are merged neutrally.
- SearchReceipt supports audit and utility funding only.

---

### FE-S6: Fan participates in a giveaway **[PARTIAL]**

As a fan, I want to join a creator giveaway while knowing exactly what data I am granting.

End state:
- Campaign terms and data grant are shown.
- Fan grants or declines permission.
- CampaignEntryReceipt and RewardReceipt record actions.
- Fan can revoke future access where applicable.

> **MVP note:** Deliver one built-in simple giveaway alongside CE-S4/CE-W3.

---

### FE-S6A: Fan trades interest data for a creator offer **[IN]**

As a fan, I want to decide whether a creator can use my interests, likes, dislikes, and ad preferences in exchange for better giveaways, promotions, or creator-approved ad relevance.

End state:
- Fan sees requested fields, purpose, retention, ad-use flag, sponsor context, offer value, and alternate path where applicable.
- Fan can approve, deny, narrow fields, or apply a default to a creator category.
- `ConsentGrantAPI` records a `creator_interest_data` grant or denial.
- Fan App settings show active grants, pending requests, category defaults, ad preferences, interests/dislikes, disliked creators, and revocation controls.
- Creator receives only approved creator-scoped fields or aggregate counts through the Audience Data Firewall.

---

### FE-S7: Fan uses AI to understand a creator archive **[IN]**

As a fan, I want to ask questions about a creator's archive so I can find relevant answers quickly.

End state:
- AI request respects creator AI policy and fan memory policy.
- Source attribution receipts are generated.
- Creator can receive AI source royalties where enabled.

---

### FE-S8: Fan switches apps **[DEFERRED]**

Single app for MVP. Fan Passport architecture supports it when ready.

---

### FE-S9: Fan receives creator-led recommendations **[IN]**

As a fan, I want recommendations from creators I trust and session intents I intentionally choose so discovery feels accountable and relevant.

End state:
- Fan sees and can switch or clear the current `SessionIntent`.
- Fan App fetches `RecommendationManifest` records from followed or trusted creators.
- `FanScopedRecommendationAPI` ranks candidates using session intent policy and fan settings.
- Disclosures are visible.
- Feedback, `DiscoveryReceipt`, and possible `CreatorReferralReceipt` are recorded.

---

### FE-S9A: Fan starts from content tiles **[IN]**

As a fan, I want Loom to show tiles that combine what I am here to do with what I care about, so I can choose Learning: Tennis, Reviews: Video Games, Entertainment: Comedy, Creator Updates, or Friends and Family without tuning an algorithm.

End state:
- App launch shows content tiles with disclosed tradeoffs.
- `SessionIntent` sets platform intent, active interest tokens, dislike filters, creator/provider blend, data posture, ad posture, and session shape.
- Search intent uses neutral public search and shows no ads in results.
- Friends and Family intent shows only direct connections and applies strict age/family-safe defaults unless the fan expands scope.
- Fan can switch, save, mute, dislike, or clear session intent mid-session.

---

### FE-S9B: Fan corrects interests and disliked content **[IN]**

As a fan, I want like/dislike/flag/follow/unfollow controls so I can shape my interests and dislikes directly.

End state:
- Like/save/follow increase relevant interest and creator affinity.
- Dislike/not interested lowers interest affinity or adds a disliked interest.
- Dislike creator, mute, unfollow, or block suppresses creator candidates according to severity.
- Flag content routes to Trust and Safety.
- Fan Vault exposes interest and dislike controls in settings.

---

### FE-S10: Fan chooses premium private data mode **[DEFERRED]**

---

### FE-S11: Fan manages broader wallet support **[PARTIAL]**

Deliver memberships, no-ad premium, and tips. Boosts, gifts, bundles, and premium delivery deferred.

---

### FE-S12: Fan consumes multiple content formats **[PARTIAL]**

Deliver videos and posts (written content) from one creator home. Livestreams, events, courses, and community surfaces deferred.

---

## Part D — Fan Workflows

**Source: [03-fan-experience.md](../Product%20Docs/03-fan-experience.md) §6**

---

### FE-W1: Fan onboarding and first follow **[IN]**

Actors: Fan, Fan App, Fan Passport Ledger, Core Fan Vault, Creator Audience Vault, Creator Metadata Host

Steps:
1. Fan opens a certified Fan App.
2. Fan creates or resolves a Fan Passport.
3. Fan chooses display persona and basic privacy mode.
4. Fan finds a creator through link, search, recommendation, or import flow.
5. App explains portable follow, creator visibility, direct-contact options, and unfollow/block controls.
6. Fan selects `FollowVisibilityPolicy`.
7. Fan follows creator.
8. Follow relationship is written to Fan Passport Ledger through `FollowRelationshipAPI`.
9. Creator Audience Vault receives only allowed creator-scoped audience state.
10. `PairwiseIdentityAPI` provides creator-scoped identity rather than a universal fan id.
11. Core Fan Vault stores notification and app preference defaults.
12. Later unfollow, block, visibility change, or direct-contact revocation creates `CreatorRelationshipActionRecord`.
13. Fan App shows creator home and available content.

---

### FE-W1A: Fan revokes or limits creator relationship data **[IN]**

Actors: Fan, Fan App, Core Fan Vault, Creator Audience Vault, Audience Data Firewall, Creator Studio

Steps:
1. Fan opens relationship settings from a creator page, privacy dashboard, notification surface, or app account settings.
2. Fan chooses one or more actions: change `FollowVisibilityPolicy`, revoke `DirectContactGrant`, unfollow, block, or request creator-scoped deletion.
3. Fan App calls `FollowRelationshipAPI`; grant changes also update `ConsentGrantAPI` where consent records are involved.
4. `CreatorRelationshipActionRecord` records the lifecycle event.
5. `AudienceDataFirewallPolicy` recalculates creator, sponsor, app, extension, analytics, and export eligibility.
6. `CreatorAudienceAPI` updates Creator Audience Vault and Creator Studio state without exposing restricted fan data.
7. `CreatorCRMExportAPI` and `CreatorAudienceExportPolicy` exclude the fan from future direct-contact exports where grants or visibility no longer allow access.
8. If deletion is requested, `CreatorScopedTombstoneRecord` prevents creator-scoped relationship rehydration while required audit, safety, settlement, and legal records remain retained.
9. Fan Data Dashboard shows updated relationship state, access/export history, and dispute/report controls.

---

### FE-W2: Free ad-supported playback **[IN]**

Actors: Fan, Fan App, Playback Authorization Service, Content Host, Ad Decision Service, Receipt Ledger, Settlement Engine

Steps:
1. Fan selects free content.
2. Fan App requests playback authorization.
3. Authorization checks content access mode and fan entitlements.
4. Ad Decision Service determines eligible ads based on `CreatorAdPolicy` and session intent ad posture; no behavioral targeting.
5. Content Host serves content.
6. `PlaybackReceipt`, `AdImpressionReceipt`, and delivery receipts are generated.
7. Fraud signals attach confidence scores.
8. Settlement Engine allocates ad revenue to creator and providers.

---

### FE-W3: Premium no-ad playback **[IN (simulated)]**

Actors: Fan, Fan Wallet, Fan App, Playback Authorization Service, Content Host, Receipt Ledger, Settlement Engine

Steps:
1. Fan buys or already has global no-ad entitlement.
2. Fan selects eligible content.
3. Playback authorization checks PremiumNoAdEntitlement.
4. Fan App plays content without ads.
5. `PremiumNoAdReceipt` records qualified consumption.
6. Settlement Engine allocates subscription pool to creators and providers.
7. Fan can view allocation summary where applicable.

---

### FE-W4: Membership purchase and access **[IN (simulated)]**

Actors: Fan, Fan App, Fan Wallet, Payment Provider, Entitlement Ledger, Creator Studio, Receipt Ledger

Steps:
1. Fan views membership tiers.
2. Fan selects a tier.
3. Payment Provider processes subscription or prototype simulation.
4. Entitlement Ledger records access.
5. Fan App unlocks member content and community surfaces.
6. MembershipReceipt and payment receipt are generated.
7. Creator Studio shows member conversion and expected payout.

---

### FE-W5: Search and AI-assisted discovery **[IN]**

Actors: Fan, Fan App, Search Directory, Host Public Search APIs, Fan AI Assistant, Private Event Vault

Steps:
1. Fan enters a search query.
2. Fan App sends query to Search Directory or host search APIs.
3. Certified hosts return signed results using `PublicSearchResultSchema` and `OpenSearchKernel` behavior.
4. Fan App merges results neutrally.
5. Fan optionally asks AI to summarize or refine results.
6. AI uses permitted public search tools and fan memory settings.
7. `SearchReceipt` records query routing and result source for audit and utility funding only.
8. Private Event Vault stores richer behavior only if fan data mode allows.
9. Fan opens content, follows a creator, or saves a result.

---

### FE-W6: Campaign participation and reward **[PARTIAL]**

One built-in simple giveaway campaign only. Full campaign extension runtime deferred.

---

### FE-W6A: Creator interest-data permission request **[IN]**

Actors: Creator, Creator Studio, Fan, Fan App Settings, Consent Grant API, Core Fan Vault, Audience Data Firewall, Creator Audience API

Steps:
1. Creator creates a data-for-value request for interests, liked/disliked content, liked/disliked creators, muted providers, or ad preferences.
2. Creator declares field list, purpose, retention, whether data may be used for creator-approved ads, creator category, sponsor context, and offer terms.
3. Fan App shows the request in settings and on relevant campaign/promotion surfaces with approve, deny, narrow, and apply-to-category controls.
4. Fan decision creates, updates, or denies a `creator_interest_data` grant in `ConsentGrantAPI`.
5. Core Fan Vault stores grant state, category defaults, ad preferences, interests/dislikes, disliked creators, and access history.
6. Audience Data Firewall enforces the stricter of fan privacy mode, age/region policy, creator relationship state, block/dislike state, category defaults, and grant scope.
7. Creator Audience API returns only approved creator-scoped fields or aggregate counts for promotions, creator-sold ads, or sponsor reporting.
8. `DataAccessReceipt` records actual grant-protected access, and Fan App settings lets the fan revoke future access.

---

### FE-W7: Fan revokes app or campaign access **[IN]**

Actors: Fan, Fan App, Consent Grant API, Core Fan Vault, Private Event Vault, Creator Audience Vault

Steps:
1. Fan opens data permissions.
2. Fan selects an app, campaign, AI memory setting, creator interest-data grant, creator-category default, direct-contact grant, sponsor-linked grant, or provider permission.
3. Fan reviews consequences of revocation.
4. ConsentGrantAPI revokes future access.
5. A DataAccessReceipt or revocation record is created.
6. Affected app or provider loses access.
7. Portable fan state remains intact unless fan requests deletion.

---

### FE-W8: Cross-app switch **[DEFERRED]**

---

### FE-W9: Fan receives creator-led recommendations **[IN]**

Actors: Fan, Fan App, Creator Recommendation Graph, Fan Scoped Recommendation Engine, Community Recommendation Feed Provider, Fan AI Assistant, Receipt Ledger

Steps:
1. Fan App fetches recommendations from creators the fan follows or trusts through `RecommendationManifestAPI`.
2. Fan App also fetches optional candidates from enabled community feeds through `CommunityFeedAPI`.
3. App creates a `SessionIntent` from the fan's selected tile: platform intent plus active interest tokens and dislike filters.
4. `FanScopedRecommendationAPI` ranks eligible candidates using `FanRecommendationSettings`, `FanInterestProfile`, session intent policy, `ContentManifest.summary`, host content performance metadata, creator reputation, and source quotas.
5. Fan AI Assistant may filter or explain candidates if the fan enabled it; if the fan asks to ignore clickbait/ragebait titles, the assistant can deemphasize title wording and use creator-approved summaries without expanding candidate sources.
6. Fan App displays recommendation source, title, summary where appropriate, reason, content score explanation, and paid/affiliate/sponsored/referral disclosures.
7. Fan follows, unfollows, likes, dislikes, flags, watches, joins, buys, saves, dismisses, mutes, or blocks.
8. `DiscoveryReceipt` and possible `CreatorReferralReceipt` are generated for qualified events.
9. `FanContentFeedbackAPI` updates future ranking and Fan Vault interest/dislike state.

---

### FE-W10: Premium private data mode **[DEFERRED]**

---

### FE-W11: Fan AI archive Q&A **[IN]**

Actors: Fan, Fan App, AI Gateway, AI Provider, Creator Metadata Host, Content Host / Transcript Store, Entitlement Ledger, Receipt Ledger, Settlement Engine

Steps:
1. Fan asks a question about a creator archive.
2. AI Gateway checks `AIContentPolicy`, fan memory policy, and any required `AICreditEntitlement`.
3. AI Gateway retrieves approved source metadata, transcripts, or content references.
4. AI Provider generates answer with source references.
5. `AIUsageReceipt` and `SourceAttributionReceipt` are generated.
6. Fan sees answer and source links.
7. Settlement Engine allocates AI provider costs and creator source royalties where enabled.

---

### FE-W12: Multi-format creator engagement **[PARTIAL]**

Deliver video and post formats. Livestreams, events, courses, and community surfaces deferred.

---

### FE-W13: Wallet support allocation **[PARTIAL]**

Deliver memberships and no-ad premium. Boosts, gifts, bundles, and premium delivery deferred.

---

## Part E — Recommendation Economy User Stories

**Source: [12-creator-led-recommendation-economy.md](../Product%20Docs/12-creator-led-recommendation-economy.md) §5**

---

### RE-S1: Creator recommends trusted creator **[IN]**

As a creator, I want to recommend another creator I trust so my fans can discover relevant work.

End state:
- `RecommendationManifest` is published.
- Fan apps can show recommendation.
- Disclosure is visible.

---

### RE-S2: Creator earns referral revenue **[IN (simulated)]**

As a creator, I want referral revenue when my recommendation drives qualified engagement.

End state:
- Destination creator has referral terms.
- Qualified action creates receipt.
- Settlement allocates referral revenue.

---

### RE-S3: Fan controls recommendation sources **[IN]**

As a fan, I want to choose which creator recommendations influence my feed.

End state:
- Fan settings control sources.
- Fan app ranks candidates.
- Feedback affects future ranking.

---

### RE-S3A: Fan chooses platform intent and interest from startup tiles **[IN]**

As a fan, I want Loom to show content tiles based on platform-defined intents and my interests/dislikes so I can choose why I am here and what I want to see without being dropped into an engagement-max feed.

End state:
- Fan selects a `ContentTile` that has a `PlatformIntent` and scoped interest/dislike tokens.
- `SessionIntentDisclosure` shows purpose, creator/provider blend, data posture, ad posture, algorithmic breadth, and session shape.
- `RecommendationModePolicy` constrains ranking, data access, ads, external recommendation providers, and session defaults.
- Interest/dislike updates are stored in Fan Vault only according to fan policy.

---

### RE-S4: Destination creator sets referral terms **[IN]**

As a destination creator, I want to define referral payout terms so discovery economics are predictable.

End state:
- `ReferralTermsManifest` is published.
- Terms include action types, windows, caps, and exclusions.

---

### RE-S5: Governance handles recommendation abuse **[DEFERRED]**

---

### RE-S6: Creator uses AI workbench **[DEFERRED]**

---

### RE-S7: Host contributes trending statistics **[IN]**

As a hosting provider, I want to publish aggregate trending statistics for eligible public content so Trending and Entertainment session intents can reflect real momentum without exposing raw fan behavior.

End state:
- `HostingTrendingStatsAPI` publishes aggregate velocity, novelty, geography/locale buckets where allowed, and eligibility metadata.
- `TrendingSignalReceipt` or audit log records source host, time window, and policy version.
- Ranking services can use the signal only for session intents that allow aggregate trending inputs.

---

### RE-S8: Fan likes, dislikes, flags, follows, or unfollows **[IN]**

As a fan, I want normal controls like like, dislike, flag, not interested, follow, and unfollow so Loom can learn my interests and dislikes while still letting me correct the system.

End state:
- `FanContentFeedbackAPI` records the action.
- Fan Vault updates interest, disliked interest, liked creator, disliked creator, mute, or block state where appropriate.
- Trust and Safety receives flag actions.
- Future feed scoring suppresses disliked interests and creators and explains major preference effects.

---

### RE-S9: Fan agent ignores clickbait titles **[IN]**

As a fan, I want my personal Claude, ChatGPT, Gemini, or other MCP-based recommendation agent to ignore clickbait or ragebait title wording and use creator-approved summaries to find relevant content.

End state:
- Agent receives only eligible followed-creator and creator-recommendation candidates allowed by the current Fan Recommendation AI definition.
- Candidate metadata includes title, `ContentManifest.summary`, creator, recommendation source, and disclosure state.
- Scoring can mark title wording as deemphasized and summary relevance as used.
- Fan sees normal titles and disclosures in the UI, plus a why-shown explanation if summary-first ranking changed the order.

---

## Part F — Recommendation Economy Workflows

**Source: [12-creator-led-recommendation-economy.md](../Product%20Docs/12-creator-led-recommendation-economy.md) §6**

---

### RE-W1: Destination creator publishes referral terms **[IN]**

Actors: Destination Creator, Creator Studio, Creator Metadata Host, Settlement Engine

Steps:
1. Destination creator opens referral settings.
2. Creator defines eligible actions, payout amount or percentage, attribution window, caps, exclusions, and fraud rules.
3. Creator Studio validates terms.
4. `ReferralTermsManifest` is stored in channel metadata.
5. Creator Discovery Exchange can surface terms.

---

### RE-W2: Source creator publishes recommendation **[IN]**

Actors: Source Creator, Creator Discovery Exchange, Recommendation Workbench, AI Gateway, Creator Metadata Host

Steps:
1. Source creator searches for creators, content, promotions, and referral terms.
2. Creator reviews reputation and fit.
3. Creator optionally grants `CreatorAgentDelegationToken` access to `RecommendationWorkbenchMCPServer` with bounded research and draft scopes.
4. AI-assisted draft records candidate provenance, sources, referral terms reviewed, and tool-call audit records.
5. Recommendation Workbench validates disclosure requirements, relationship labels, and referral-term compatibility.
6. Creator publishes `RecommendationManifest` through `RecommendationManifestAPI`.
7. Manifest becomes available to fan apps without transferring graph ownership to an app or provider.

---

### RE-W3: Fan receives trusted recommendation **[IN]**

Actors: Fan, Fan App, Fan Scoped Recommendation Engine, Creator Recommendation Graph, Private Event Vault

Steps:
1. Fan App shows startup tiles generated from platform intents and the fan's `FanInterestProfile`.
2. Fan selects a tile; `SessionIntentAPI` creates a `SessionIntent` with `platformIntentId`, active interest tokens, dislike filters, creator/provider blend, and ad posture.
3. `SessionIntentDisclosure` shows ranking purpose, data posture, creator/provider blend, ad posture, and session shape.
4. Fan App fetches eligible candidates from followed creators, creator recommendations, direct connections, community feeds, fan-initiated search results, and `HostingTrendingStatsAPI` only as allowed by the platform intent.
5. `FanScopedRecommendationAPI` applies intent weights, `FanInterestProfile`, source filters, disclosure preferences, disliked interests, disliked creators, and trusted-candidate rules.
6. If private behavior influences ranking, `PrivateRankingAPI` runs in the Private Event Vault after a purpose-bound `DataUseGrant`; no raw private event data leaves the vault.
7. `DataAccessReceipt` records grant-protected private ranking access.
8. `ContentScoringService` scores candidates using followed-creator affinity, creator recommendations, host content performance metadata, `ContentManifest.summary` relevance, title-risk/title-summary mismatch penalties, creator reputation, interest relevance, dislike penalties, safety labels, freshness, and trending momentum.
9. `SessionIntentAdContext` sets ad posture and creator/provider breadth; `CreatorAdPolicy` and sponsor policy decide which ads can actually appear.
10. App displays content tile/feed item with title, summary where appropriate, intent label, source, disclosure, score explanation, funding/referral label, and why-shown context.
11. Fan likes, dislikes, flags, follows, unfollows, saves, dismisses, mutes, blocks, clears intent, or switches intent.
12. `FanContentFeedbackAPI` updates Fan Vault interest/dislike state and future ranking.
13. Qualified discovery generates `DiscoveryReceipt`; eligible conversion may later generate `CreatorReferralReceipt`.

---

### RE-W3A: Startup tile selection and mid-session switch **[IN]**

Actors: Fan, Fan App, Fan Scoped Recommendation Engine, Audience Data Firewall, Ad Decision System

Steps:
1. Fan opens app.
2. `StartupTileSurfaceAPI` reads platform-defined intents and the fan's allowed `FanInterestProfile`.
3. App displays tiles such as Learn: Tennis, Reviews: Video Games, Entertainment: Comedy, Creator Updates, or Friends and Family.
4. Fan selects a tile, searches for a topic, mutes an interest, or starts from Creator Updates.
5. `SessionIntentAPI` sends `platformIntentId`, active interest tokens, dislike filters, creator/provider blend, ad posture, and storage preference to `FanScopedRecommendationAPI`.
6. `AudienceDataFirewallPolicy` checks whether the session's requested interest/dislike posture is allowed by privacy mode, grants, age rules, and vault policy.
7. `SessionIntentAdContext` sends intent-level ad posture, load, creator/provider breadth, and creator-approved-only constraints to the ad decision boundary.
8. Ranking begins with intent-specific objective, candidate quotas, and score weights.
9. If the fan switches intent mid-session, the engine re-ranks from the new policy and records a new session intent context for future receipts.
10. Fan can save the preference, use it for this session only, dislike the interest, dislike the creator, mute the provider, or clear the intent.

---

### RE-W4: Referral settlement **[IN (simulated)]**

Actors: Fan, Source Creator, Destination Creator, Receipt Ledger, Settlement Engine

Steps:
1. Fan engages with destination creator after recommendation.
2. Attribution rules evaluate eligibility against the effective `RecommendationManifest`, `ReferralTermsManifest`, attribution window, fan privacy mode, and `SettlementManifest`.
3. `DiscoveryReceipt` or `CreatorReferralReceipt` is signed by the responsible app/provider and submitted through `ReceiptIngestAPI`.
4. `ReceiptLedger` stores immutable receipt evidence and manifest-version bindings.
5. Fraud signals attach confidence scores, invalid-referral flags, or `FraudAdjustmentRecord` entries.
6. `SettlementEngineAPI` applies referral terms, caps, reserves, chargebacks, and dispute adjustments.
7. `SettlementRunRecord` and `CreatorPayoutStatement` show source creator revenue, destination creator cost, and provider adjustments.

---

### RE-W5: Community feed subscription **[DEFERRED]**

---

### RE-W6: Recommendation abuse review **[DEFERRED]**

---

### RE-W7: Hosting trending statistics ingestion **[IN]**

Actors: Hosting Provider, Content Host, Fan Scoped Recommendation Engine, Governance/Audit System

Steps:
1. Certified hosting provider aggregates eligible public content velocity, novelty, completion, freshness, being-watched-now state, total view count, and safety-filtered momentum over a declared time window.
2. Host excludes private-mode fan behavior, non-consented private vault signals, minors' restricted signals, and content not eligible for trending exposure.
3. Host signs a `HostingTrendingStatsBatch` with provider id, API version, time window, aggregation thresholds, content references, and public content performance fields.
4. `HostingTrendingStatsAPI` publishes the batch to recommendation services.
5. Recommendation services use the batch only for session intents whose `RecommendationModePolicy` permits aggregate public content performance signals.
6. Governance can audit host trending claims through `TrendingSignalAuditAPI`, receipt samples, and replayable aggregation evidence.

---

## Part G — Monetization and Ads User Stories

**Source: [09-monetization-models.md](../Product%20Docs/09-monetization-models.md) §5 and [18-brand-sponsor-advertiser-tools.md](../Product%20Docs/18-brand-sponsor-advertiser-tools.md) §5**

---

### MN-S1: Creator monetizes free fans **[IN]**

As a creator, I want free fans to generate revenue so my public content can grow reach.

End state:
- Content is ad eligible.
- Ad receipts and playback receipts are generated.
- Creator payout includes ad revenue.

---

### MN-S2: Fan pays for no-ad premium **[IN (simulated)]**

As a fan, I want no-ad access across eligible creators so I can improve my experience while supporting creators.

End state:
- Premium entitlement exists.
- No-ad playback receipts allocate value.
- Fan can see subscription status.

---

### MN-S3: Creator launches membership tiers **[IN (simulated)]**

As a creator, I want paid tiers so fans can support me directly.

End state:
- Membership tiers are published.
- Fan Wallet sells memberships.
- Entitlement Ledger gates member benefits.

---

### MN-S4: Sponsor funds a campaign **[PARTIAL]**

One built-in simple campaign. Full sponsor campaign marketplace deferred.

---

### MN-S5: Creator earns AI royalties **[IN]**

As a creator, I want to earn when AI uses my content as a source.

End state:
- AI policy allows usage.
- Source attribution receipts are generated.
- Settlement allocates AI royalties.

---

### MN-S6: Creator earns referral revenue **[IN (simulated)]**

As a creator, I want to earn from trusted recommendations when they drive qualified engagement.

End state:
- Recommendation and referral terms are published.
- Discovery receipts are generated.
- Referral settlement occurs.

---

### MN-S7: Fan pays for private data mode **[DEFERRED]**

---

### MN-S8: Creator sells paid event, course, bundle **[DEFERRED]**

---

### AD-S1: Sponsor proposes campaign to creator **[PARTIAL]**

As a sponsor, I want to propose a campaign to a creator so I can reach that creator's audience.

End state:
- Sponsor campaign proposal is created.
- Creator reviews terms and disclosure.
- Accepted campaign becomes a `CampaignManifest`.

> **MVP note:** Deliver for the built-in simple giveaway only.

---

### AD-S3A: Fan grants sponsor-linked creator ad relevance **[IN]**

As a fan, I want to choose whether a creator can use my interests, likes, dislikes, and ad preferences for a sponsor promotion in exchange for a better offer.

End state:
- Campaign terms show the creator, sponsor, requested fields, ad-use purpose, retention, offer value, and alternate entry where required.
- Fan can approve, deny, narrow, or rely on a creator-category default.
- Sponsor receives aggregate or clean-room reporting unless the explicit fan grant permits more.
- Creator Audience API and Audience Data Firewall prevent sponsor or creator access after revocation.

---

### AD-S5: Creator offers sponsor-free version **[DEFERRED]**

---

## Part H — Monetization and Ads Workflows

---

### MN-W1: Configure monetization for content **[IN]**

Actors: Creator, Creator Studio, Creator Metadata Host, Fan App, Playback Service, Settlement Engine

Steps:
1. Creator selects content monetization mode.
2. Creator Studio validates ad, membership, premium, sponsor, AI, and paid access rules.
3. `MonetizationManifest` is updated.
4. Fan App displays access and payment options.
5. Playback or content access service enforces rules.
6. Receipts are generated.
7. Settlement applies manifest version.

---

### MN-W2: Free ad-supported revenue **[IN]**

*(See FE-W2 — same workflow, covers ad-receipt generation and settlement.)*

---

### AD-W1: Sponsor campaign setup **[PARTIAL]**

Actors: Sponsor, Sponsor Dashboard, Creator, Creator Studio, Campaign System

Steps (MVP scope):
1. Creator defines `CreatorAdPolicy` — allowed and blocked ad categories and brands.
2. Sponsor proposes a campaign aligned with the creator's policy.
3. Creator reviews terms and disclosure.
4. `CampaignManifest` and `SponsorDisclosurePolicy` are stored.
5. Campaign becomes active for the creator's audience.

> **MVP note:** Deliver the `CreatorAdPolicy` setup and a single campaign flow. Full certification-scope checks, compliance manifests, and clean-room measurement deferred.

---

### AD-W2: Fan campaign participation **[PARTIAL]**

*(See FE-W6 — one built-in campaign. Full extension runtime deferred.)*

---

### AD-W2B: Sponsor-linked creator interest-data offer **[IN]**

Actors: Sponsor, Creator, Fan, Fan App, Creator Studio, Audience Data Firewall, Sponsor Dashboard

Steps:
1. Sponsor proposes a promotion that asks for fan interests, likes, dislikes, disliked creators, muted providers, or ad preferences.
2. Creator reviews sponsor terms, data fields, ad-use purpose, retention, and offer value before approving the request.
3. Fan App shows the data-for-value offer with requested fields, sponsor context, creator category, ad-use flag, retention, and alternate entry where required.
4. Fan approves, denies, narrows fields, revokes an existing grant, or applies a creator-category default.
5. `ConsentGrantAPI` records a `creator_interest_data` grant or denial.
6. `AudienceDataFirewallPolicy` exposes only approved creator-scoped fields or aggregate counts through `PermissionedAudienceInterestDataAPI`.
7. Sponsor Dashboard receives only aggregate, clean-room, or explicitly grant-backed metrics, and `DataAccessReceipt` records actual grant-protected access.

---

## Part I — Missing Stories (to be defined)

The following stories are required by the MVP pitch but do not yet exist in the product docs. They should be defined and added to the relevant area docs before implementation begins.

---

### MISSING-S1: Creator sets content ad policy *(✅ now defined — `02 Creator Experience` Story 3B; `18 Brand/Sponsor/Advertiser Tools` Story 2A)*

**Needed by:** "Your ad environment is yours" (pitch) and CE-W1 / AD-W1.

**Gap:** There is no user story that specifically covers a creator defining their `CreatorAdPolicy` — the allow/block list of ad categories and brands for their channel and content. The `CreatorAdPolicy` object appears in the architecture and ad workflows but is not represented as a named creator user story.

**Suggested framing:** As a creator, I want to define which ad categories and brands are allowed on my channel and content so that fans only see ads that align with my values, and I remain in control of my monetization environment.

---

### MISSING-S2: Fan interest onboarding (cold-start)

**Needed by:** "Fan onboards, picks interests" (demo step 2) and FE-W1.

**Gap:** There is no user story covering the first-launch experience for a brand-new fan who has zero follows. The startup tile mechanism presupposes a `FanInterestProfile`, but there is no story for the initial interest and category selection that seeds that profile on day one before any follows exist.

**Suggested framing:** As a new fan with no follows, I want to pick interests and topics on first launch so that Loom can show me relevant startup tiles immediately, without requiring me to already follow creators.

---

### MISSING-S3: Creator publishes content with required AI-ready summary *(✅ now defined — `02 Creator Experience` Story 2A; `04 Creator Channel and Metadata Architecture` documents the required `ContentManifest.summary`)*

**Needed by:** "Publish with AI-ready summaries" (pitch) and RE-W3 / RE-S9 (summary-first ranking).

**Gap:** The product docs reference `ContentManifest.summary` as required for recommendation relevance, fan agent ranking, and clickbait/ragebait defense. However, there is no creator user story that covers the act of writing or generating this summary during publishing. Story CE-S2 covers publishing but does not mention the summary requirement.

**Suggested framing:** As a creator, I want to add or generate a required content summary when I publish so that fans and AI agents can evaluate my content by its substance, not just its title, and my content ranks better for the fans who care about it.

---

### MISSING-S4: Creator views revenue split by session intent *(✅ now defined — `02 Creator Experience` Story 6A; `09 Monetization Models` `CreatorPayoutStatement`)*

**Needed by:** Demo step 6 ("Settlement simulator shows the creator's revenue split by source and by intent") and CE-S6.

**Gap:** CE-S6 covers revenue transparency by source (ad, membership, AI, referral) but does not cover the per-intent split that the MVP pitch specifically calls out. There is no story that shows a creator how much of their ad revenue came from fans in Creator Updates mode vs. Entertainment/Trending mode.

**Suggested framing:** As a creator, I want to see my revenue broken down by session intent (Creator Updates, Entertainment, Learn, Search) so I can understand which audience contexts generate most of my income and optimize my content accordingly.

---

### MISSING-S5: Creator imports existing catalog from another platform *(✅ now defined — `02 Creator Experience` Story 2B; `21 Migration Strategy from Existing Platforms` has the detailed workflow)*

**Needed by:** "Creator imports a back-catalog" (demo step 1) and the long-form creator beachhead.

**Gap:** Doc 21 (Migration Strategy) defines import workflows in detail but is not included in the MVP scope docs. The MVP pitch specifically calls out catalog import as day-one magic for long-form creators with existing archives. There is no story in the in-scope docs (02, 03, 09, 12, 18) for this flow.

**Suggested framing:** As a creator, I want to import my existing catalog metadata from YouTube, Spotify, Substack, or another platform so that my back-catalog is immediately searchable and AI-queryable on Loom without re-uploading everything.

---

## Part J — Stories Identified in the GTM Launch Gap Analysis

The following stories were identified by the go-to-market analysis as **missing** but **required to
deliver the launch scope** (creator-led audience re-acquisition, one-tap onboarding, and conversion
visibility). They are tracked for implementation in
**[Phase 10 — Launch: Audience Re-acquisition & Onboarding](./Phases/Phase%2010%20—%20Launch%20Audience%20Re-acquisition%20and%20Onboarding.md)**.

**Source:** [MVP Gap Analysis — Launch Scope](../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) §A · companion to the [Loom Launch Playbook](../Go-To-Market/Loom%20Launch%20Playbook.md).

> Note on scope: these extend the original six-step demo with the launch loop. They are **launch
> scope**, not part of the original Phase 0–9 MVP. The UX-quality gaps from the same analysis (Gap
> Analysis §D, items U1–U7) are tracked as design-hardening work in Phase 10, **not** as user stories.

---

### CE-S10: Creator runs the audience re-acquisition funnel **[IN — launch scope]**

As a creator, I want announcement templates, a link-in-bio page, a QR code, and a shareable
follow-capture landing so I can drive my **existing** audience to re-follow me on Loom — because my
follower graph **cannot be imported** from incumbents and must be rebuilt by fans choosing to follow.

End state:
- Creator picks an announcement template and gets a rendered announcement, a link-in-bio page, and a QR code.
- A shareable capture link resolves to a creator-branded follow-capture landing.
- A fan arriving via the link can re-follow; the re-follow is recorded (idempotent) — there is **no** automatic follower import.
- Capture/re-follow is an audit-class event (no economic receipt tied to a follow); `FollowVisibilityPolicy` applies.

**GTM Gap ref:** §A item (a) — re-acquisition as *manual conversion*. **Target product doc:** `21 Migration Strategy` (refine Stories 1/3 + Workflow 1). **New APIs:** `FanFollowCaptureAPI`, `CreatorAnnouncementTemplatesAPI` (see Gap Analysis §B).

---

### FE-S13: Fan joins via a one-tap starter pack **[IN — launch scope]**

As a fan arriving through a creator's link, I want to follow that creator **and their recommended
creators in one tap** and land on a populated feed, so my first session is immediately valuable
instead of an empty feed.

End state:
- Opening a creator capture link offers a starter pack: the creator + N recommended creators (from the Phase 8 recommendation graph), defaulted on, individually toggleable.
- One-tap confirm performs a bulk follow (idempotent — re-opening does not duplicate follows).
- The fan lands on a **non-empty** discovery feed seeded by those follows + interest profile.
- `FollowVisibilityPolicy` and pairwise identity apply to the new follows.

**GTM Gap ref:** §A item (c) — starter-pack / bulk-follow onboarding (missing entirely; also UX item U4, "suggested creators" plural). **Target product doc:** `03 Fan Experience` (+ surface note in `15 Fan Apps`). **New API:** `StarterPackAPI` / `BulkFollowAPI` (see Gap Analysis §B).

---

### CE-S11: Creator views conversion yield **[IN — launch scope]**

As a creator, I want to see how many of the people I drove to Loom actually re-followed, subscribed,
or went premium — my **conversion yield** — so I can judge whether my launch push is working.

End state:
- A funnel view shows audience reached → re-followed → member → premium, sourced from follow + entitlement + capture state.
- Values are **aggregates only** — never per-fan behavioral rows or universal fan IDs (Audience Data Firewall).
- The view reuses the Studio dashboard pattern and renders as a compact visual (funnel/bars), not row-only (UX item U5).

**GTM Gap ref:** §A item (h) — conversion analytics (Doc 02 covers revenue-by-intent only). **Target product doc:** `02 Creator Experience` (new story alongside CE-S6/CE-S6A). **New API:** `AudienceAnalyticsAPI` (see Gap Analysis §B).

---

*End of MVP User Stories Scope document.*
