# Loom Product Definition 03: Fan Experience

Status: Draft for review  
Product area: 3 of 22  
Depends on: 01 Core Thesis and Platform Principles; 02 Creator Experience

## 1. Product Definition

The Fan Experience is the demand-side product that makes Loom useful to ordinary users without making them understand the underlying protocol. Fans should experience one portable identity, one wallet, one way to follow creators, clear privacy controls, better search, creator-trust-based recommendations, AI help, and richer engagement across compatible apps.

The fan should not feel locked into a single app. A certified Fan App can compete on UX, privacy, device support, feed design, AI features, or vertical focus, but it should not own the fan's creator relationships, entitlements, or portable preferences.

## 2. Scope

This product area covers fan-facing product behavior across official and certified fan apps.

It includes:

- Fan onboarding and Fan Passport sign-in.
- Follow relationships across apps.
- Content consumption: video, shorts, posts, newsletters, livestreams, events, courses, and community surfaces.
- Wallet, memberships, premium no-ad, tips, paid events, AI credits, and paid content.
- Notifications, saves, playlists, bookmarks, and app preferences.
- Search and creator-led recommendations.
- Campaigns, giveaways, polls, quizzes, rewards, and loyalty.
- AI summaries, archive Q&A, digests, search, and recommendation filtering.
- Privacy mode selection, consent grants, app permissions, data export, delete, and revoke controls.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Fan Passport | Portable identity used across certified apps. | Fans do not rebuild accounts and follows in every app. | Fan Passport, Wallet, Vaults, and Identity Architecture; Fan Apps and App Ecosystem |
| One follow graph | Follow a creator once and carry that relationship across compatible apps. | Creator relationships become fan-owned. | Creator Experience; Audience Data Firewall and Data Rights |
| Follow visibility controls | Fan can choose public, creator-visible, private, or pseudonymous/anonymous follow modes where supported. | Fans can follow without exposing more identity than the relationship requires. | Fan Passport, Wallet, Vaults, and Identity Architecture; Audience Data Firewall and Data Rights |
| Fan Wallet | One wallet for memberships, tips, premium, events, AI credits, and paid content. | Simplifies payment and entitlements. | Monetization Models; Revenue, Receipts, Ledgers, and Settlement |
| Cross-app entitlements | Purchases and access rights work across certified apps. | Fans can choose better apps without losing access. | Fan Apps and App Ecosystem; Provider Marketplace and Certified APIs |
| Creator-trust recommendations | Fan sees recommendations rooted in creators they trust, with disclosures. | Healthier discovery than opaque engagement-only feeds. | Creator-Led Recommendation Economy |
| Startup content tiles | App launch shows tiles generated from platform-defined intents and the fan's interests/dislikes, such as Learn: Tennis, Reviews: Video Games, Entertainment: Comedy, Creator Updates, or Friends and Family. | Fans choose why they are here and what topic they want without being dropped into an opaque feed. | Creator-Led Recommendation Economy; Fan Apps and App Ecosystem |
| Fan interests and dislikes | Fan Vault stores interest tokens, disliked interests, liked/disliked creators, muted creators, and feedback-derived signals. | Personalization follows the fan across apps and can be corrected directly. | Fan Passport, Wallet, Vaults, and Identity Architecture; Audience Data Firewall and Data Rights |
| Standard fan feedback | Fans can like, dislike, save, flag, follow, unfollow, mute, block, and say not interested. | Loom gets explicit preference signals and gives fans quick controls against unwanted content or creators. | Trust, Safety, Fraud, and Compliance; Creator-Led Recommendation Economy |
| Neutral public search | Fan can intentionally search beyond their graph without paid ranking. | Broad discovery without search ads. | Neutral Public Search Utility |
| Privacy modes | Fan can choose free personalized, no-ad premium, or stronger private modes where available. | Privacy becomes understandable and actionable. | Audience Data Firewall and Data Rights; Business Model and Incentive Design |
| Data permission dashboard | Fan can see creator data requests, creator/category grants, app grants, campaign grants, AI grants, provider grants, ad preferences, interests/dislikes, disliked creators, and access history. | Gives fans real control over data use and lets them decide when data-for-value offers are worth accepting. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Campaign participation | Fans join giveaways, quizzes, rewards, sponsor campaigns, and community events with explicit terms. | Engagement becomes richer and safer. | Creator Plugins / Extensions / Campaign Layer; Brand/Sponsor/Advertiser Tools |
| Fan AI | Fan gets summaries, archive Q&A, search help, digests, and trusted recommendation filtering. | Content becomes easier to understand and navigate. | AI Layer |

## 4. Product Experience Requirements

### 4.1 Fan App Home

The fan home experience should prioritize:

- Followed creators.
- New content and live events from followed creators.
- Membership and paid content access.
- Startup tiles organized by platform intent and fan interests/dislikes.
- Creator-led recommendations with clear source and disclosure.
- Current `SessionIntent` with visible platform intent, active interests, dislike filters, creator/provider blend, ad posture, and session shape.
- Campaigns and rewards the fan is eligible for.
- Search entry point.
- Wallet and privacy status.

### 4.2 Identity and Privacy Experience

Fans should understand:

- Which identity or persona is active.
- Which apps have access.
- Which creators they follow.
- How visible each creator relationship is.
- Which campaigns they joined.
- Which creators requested or received access to interests, likes, dislikes, ad preferences, or direct-contact data.
- Which broad creator-category defaults apply to future creator data requests.
- Which AI memory or data mode is active.
- Which entitlements are active.
- How to revoke, export, or delete data.
- How to unfollow, block a creator, revoke direct-contact permission, or request creator-scoped deletion/tombstoning.
- How to approve, deny, narrow, or revoke creator interest-data grants and data-for-value promotion offers.

The interface should avoid protocol language unless the fan asks for details.

### 4.3 Wallet Experience

Fan Wallet should show:

- Active creator memberships.
- Global no-ad or premium plans.
- AI credits or subscriptions.
- Tips and boosts.
- Paid event tickets.
- Paid content purchases.
- Premium bandwidth, premium resolution, or premium delivery plans.
- Creator boosts, gifts, bundles, sponsor-free access, paid courses, and gifted memberships.
- Refunds, failed payments, and chargebacks.
- How premium subscription value supported creators where applicable.

### 4.4 Search and Recommendation Experience

Search and recommendations must feel distinct:

- Search is fan-initiated, neutral, and broad.
- Search can appear as a startup tile, but it remains governed by neutral public search rules and has no ads in search results.
- Recommendations come from trusted creator candidates, enabled community feeds, fan settings, fan interest/dislike profile, and platform-intent-eligible signals. App ranking can personalize eligible candidates, but apps should not become broad autonomous crawlers, paid-ranking feeds, or opaque owner of the discovery graph.
- Fan-selected `SessionIntent` controls platform intent, creator/provider blend, data posture, ad posture, score weights, and session shape through `RecommendationModePolicy`.
- Session intent disclosure must be visible before or during ranking, and fans can switch or clear intent mid-session.
- Paid, sponsored, affiliate, and referral relationships are disclosed.
- Fans can tune recommendation sources, interests, disliked interests, disliked creators, muted providers, and feedback.

## 5. User Stories

### Story 1: Fan follows a creator once

As a fan, I want to follow a creator once so that I can see that creator across compatible apps.

End state:

- FollowRelationshipAPI records the follow.
- `FollowVisibilityPolicy` records fan-selected visibility.
- Creator gets creator-scoped audience signal.
- Other certified apps can show the follow when the fan grants access.
- Creator receives only the audience state allowed by the fan's relationship visibility and grants.

### Story 1A: Fan changes relationship visibility

As a fan, I want to change how visible my creator relationship is so I can follow creators without exposing unnecessary identity.

End state:

- `FollowVisibilityPolicy` updates relationship visibility.
- Creator Audience Vault updates active creator-facing state.
- Previous required receipts and audit records remain preserved.
- Future direct contact, targeting, campaign eligibility, and exports follow the new setting.

### Story 1B: Fan unfollows, blocks, or revokes creator access

As a fan, I want the same level of control Facebook exposes through unfollow/block, but with clearer data rights around creator-visible audience data.

End state:

- Fan can unfollow while keeping past purchases and required receipts intact.
- Fan can block a creator and stop future creator-initiated contact or community interactions.
- Fan can revoke `DirectContactGrant` without necessarily unfollowing.
- Fan can request creator-scoped tombstoning so future exports, plugins, sponsor tools, and apps cannot rehydrate deleted relationship state.

### Story 2: Fan watches ad-supported content

As a free fan, I want to watch creator content without paying so I can try Loom and still support creators through ads.

End state:

- Playback is authorized.
- Ad decision is made according to content and fan data mode.
- Playback and ad receipts are generated.
- Creator settlement can include ad revenue.

### Story 3: Fan buys global no-ad

As a fan, I want one no-ad plan so I can avoid ads across participating content while still supporting the creators I watch.

End state:

- Fan Wallet records premium no-ad entitlement.
- Playback skips ads.
- PremiumNoAdReceipt records qualifying sessions.
- Settlement allocates subscription value.

### Story 4: Fan joins a creator membership

As a fan, I want to join a creator membership so I can access member content and support the creator directly.

End state:

- Payment or simulated payment succeeds.
- Membership entitlement is recorded.
- Member surfaces unlock across certified apps.
- Creator sees member growth and revenue.

### Story 5: Fan searches intentionally

As a fan, I want to search public content without paid ranking so I can find creators and topics outside my follow graph.

End state:

- Search runs against certified public search APIs.
- Results are merged neutrally.
- SearchReceipt supports audit and utility funding only.

### Story 6: Fan participates in a giveaway

As a fan, I want to join a creator giveaway while knowing exactly what data I am granting.

End state:

- Campaign terms and data grant are shown.
- Fan grants or declines permission.
- CampaignEntryReceipt and RewardReceipt record actions.
- Fan can revoke future access where applicable.

### Story 6A: Fan trades interest data for a creator offer

As a fan, I want to decide whether a creator can use my interests, likes, dislikes, and ad preferences in exchange for better giveaways, promotions, or creator-approved ad relevance.

End state:

- Fan sees requested fields, purpose, retention, ad-use flag, sponsor context, offer value, and alternate path where applicable.
- Fan can approve, deny, narrow fields, or apply a default to a creator category.
- `ConsentGrantAPI` records a `creator_interest_data` grant or denial.
- Fan App settings show active grants, pending requests, category defaults, ad preferences, interests/dislikes, disliked creators, and revocation controls.
- Creator receives only approved creator-scoped fields or aggregate counts through the Audience Data Firewall.

### Story 7: Fan uses AI to understand a creator archive

As a fan, I want to ask questions about a creator's archive so I can find relevant answers quickly.

End state:

- AI request respects creator AI policy and fan memory policy.
- Source attribution receipts are generated.
- Creator can receive AI source royalties where enabled.

### Story 8: Fan switches apps

As a fan, I want to try a different fan app without losing my follows, memberships, or saved state.

End state:

- Fan signs in with Fan Passport.
- App requests scoped permissions.
- Follows and entitlements are available.
- App-specific preferences remain separate from portable fan state.

### Story 9: Fan receives creator-led recommendations

As a fan, I want recommendations from creators I trust and session intents I intentionally choose so discovery feels accountable and relevant.

End state:

- Fan sees and can switch or clear the current `SessionIntent`.
- Fan App fetches `RecommendationManifest` records from followed or trusted creators.
- `FanScopedRecommendationAPI` ranks candidates using session intent policy and fan settings.
- Disclosures are visible.
- Feedback, `DiscoveryReceipt`, and possible `CreatorReferralReceipt` are recorded.

### Story 9A: Fan starts from content tiles

As a fan, I want Loom to show tiles that combine what I am here to do with what I care about, so I can choose Learning: Tennis, Reviews: Video Games, Entertainment: Comedy, Creator Updates, or Friends and Family without tuning an algorithm.

End state:

- App launch shows content tiles with disclosed tradeoffs.
- `SessionIntent` sets platform intent, active interest tokens, dislike filters, creator/provider blend, data posture, ad posture, and session shape.
- Search intent uses neutral public search and shows no ads in results.
- Friends and Family intent shows only direct connections and applies strict age/family-safe defaults unless the fan expands scope.
- Fan can switch, save, mute, dislike, or clear session intent mid-session.

### Story 9B: Fan corrects interests and disliked content

As a fan, I want like/dislike/flag/follow/unfollow controls so I can shape my interests and dislikes directly.

End state:

- Like/save/follow increase relevant interest and creator affinity.
- Dislike/not interested lowers interest affinity or adds a disliked interest.
- Dislike creator, mute, unfollow, or block suppresses creator candidates according to severity.
- Flag content routes to Trust and Safety.
- Fan Vault exposes interest and dislike controls in settings.

### Story 10: Fan chooses premium private data mode

As a fan, I want a paid private mode so I can reduce data use, avoid ad targeting, and keep recommendations or AI memory inside stronger privacy boundaries.

End state:

- Fan Wallet records private mode entitlement.
- Private Event Vault and Core Fan Vault enforce stronger access rules.
- Raw behavior is not exported for external ad targeting or broad recommendation providers.
- AI memory and training are disabled or tightly scoped according to fan policy.

### Story 11: Fan manages broader wallet support

As a fan, I want one place to manage memberships, boosts, gifts, bundles, premium delivery, sponsor-free access, paid courses, and gifted memberships.

End state:

- Fan Wallet records purchases and support allocation.
- Entitlement Ledger records access rights.
- Creator receives creator-scoped support signals.

### Story 12: Fan consumes multiple content formats

As a fan, I want one creator home for videos, posts, newsletters, livestreams, events, courses, and community updates.

End state:

- Fan App renders content according to `ContentManifest`.
- Entitlement checks work across content types.
- Saves, reminders, and read/watch state are stored according to fan settings.

### Story 13: Fan joins via a one-tap starter pack

As a fan arriving through a creator's link, I want to follow that creator and their recommended creators in one tap and land on a populated feed, so my first session is valuable instead of empty.

End state:

- Opening a creator capture link offers a starter pack: the source creator plus recommended creators, defaulted on and individually toggleable.
- `StarterPackAPI` resolves the pack from creator-led recommendations; a single confirm performs an idempotent bulk follow.
- The fan lands on a non-empty feed seeded by the new follows and interest profile.
- `FollowVisibilityPolicy` and pairwise creator identity apply to the new follows.

> Identified in the [GTM Launch Gap Analysis](../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) §A(c) (MVP scope id **FE-S13**); launch scope, implemented in Phase 12. Also addresses UX item U4 ("suggested creators", plural).

### Story 14: Fan experiences a creator-customized channel

As a fan, I want each creator's channel to feel like their own world — their theme, layout, interactive modules, and AI persona — while I keep one Loom passport, wallet, and follow graph across all of them.

End state:

- Opening a creator channel renders that creator's theme, banner, ordered modules, AI persona, and ad posture from `CreatorExperienceConfig`.
- Different creators render as distinct experiences through one generic renderer; identity, wallet, and follows are unchanged across them.
- Customization is per-creator; the fan's portable identity is not.

> Launch/showcase scope (MVP scope id **FE-S14**); implemented in Phase 16. See the gaming showcase in [Phase 15+](../MVP%20Planning/Phases/Phase%2015%20-%20Extensions%20Platform%20and%20Customization%20Foundation.md).

### Story 15: Fan participates in a creator's extension

As a fan, I want to take part in a creator's interactive extension (submit a clip, make a prediction, send hype, complete a quest, submit a build, contribute to a guild goal) and earn rewards or badges.

End state:

- Participation runs through an Extension Runtime session scoped to the install's approved permissions and surfaces.
- Events are idempotent; rewards/badges issue through the existing reward + receipt path; tip/hype uses the Fan Wallet (simulated).
- The same extension behaves differently per creator according to its install config.

> Launch/showcase scope (MVP scope id **FE-S15**); implemented in Phases 17–18. See [10 Extensions](./10-creator-plugins-extensions-campaign-layer.md).

### Story 16: Fan connects an AI search agent and external sources

As a fan, I want to connect my own AI agent (Claude/OpenAI/Gemini via MCP) and enable external sources in Settings, so my search is ranked by my agent and can reach beyond Loom.

End state:

- Fan sets a provider + MCP connection (`FanSearchAgentConfig`), toggles external sources, and sets a "prefer creator content" default.
- A disclosure makes clear that search queries are sent to the fan's chosen AI provider (data egress); the connection is reversible.

> Launch/showcase scope (MVP scope id **FE-S16**); implemented in Phases 21–22. Extends the Phase-5 bring-your-own-AI model from recommendations to search. See [11 AI Layer](./11-ai-layer.md) and [14 Data Rights](./14-audience-data-firewall-and-data-rights.md).

### Story 17: Fan AI search merges creator and external content

As a fan with a connected agent, I want one ranked list that merges creator content (preferred on match) with external results (e.g., YouTube), with ragebait tamed without misrepresenting third-party content.

End state:

- The agent determines final ranking (disclosed); creator content is preferred on match; there is **no paid placement** (neutral search preserved).
- Creator tiles show summary over clickbait; **external tiles keep the unaltered original title + thumbnail**, lead with an **additive AI accurate-match label**, and show a **source-attribution chip**.
- With no agent connected, search falls back to the existing neutral path (Story 5).

> Launch/showcase scope (MVP scope id **FE-S17**); implemented in Phase 23. See [11 AI Layer](./11-ai-layer.md) and [13 Neutral Public Search](./13-neutral-public-search-utility.md).

### Story 18: Fan plays external video in-app with AI-driven next

As a fan, I want to play a YouTube result inside Loom and have the next recommendation come from my AI search, not the platform's.

End state:

- Tapping a YouTube item opens the **official in-app embedded player**, unobscured; the original title + source attribution stay visible.
- A "Next from your AI search" rail (creator-preferred) surrounds the player; non-YouTube sources open externally; no Loom ads over the embed.

> Launch/showcase scope (MVP scope id **FE-S18**); implemented in Phase 24. Compliance (official player, unaltered metadata, attribution) is defined in [17 Trust, Safety, Fraud, and Compliance](./17-trust-safety-fraud-and-compliance.md).

## 6. End-to-End Workflows

### Workflow 1: Fan onboarding and first follow

Actors:

- Fan
- Fan App
- Fan Passport Ledger
- Core Fan Vault
- Creator Audience Vault
- Creator Metadata Host

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

### Workflow 1A: Fan revokes or limits creator relationship data

Actors:

- Fan
- Fan App
- Core Fan Vault
- Creator Audience Vault
- Audience Data Firewall
- Creator Studio

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

### Workflow 2: Free ad-supported playback

Actors:

- Fan
- Fan App
- Playback Authorization Service
- Content Host
- Ad Decision Service
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan selects free content.
2. Fan App requests playback authorization.
3. Authorization checks content access mode and fan entitlements.
4. Ad Decision Service determines eligible ads.
5. Content Host serves content.
6. `PlaybackReceipt`, `AdImpressionReceipt`, and delivery receipts are generated.
7. Fraud signals attach confidence scores.
8. Settlement Engine allocates ad revenue to creator and providers.

### Workflow 3: Premium no-ad playback

Actors:

- Fan
- Fan Wallet
- Fan App
- Playback Authorization Service
- Content Host
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan buys or already has global no-ad entitlement.
2. Fan selects eligible content.
3. Playback authorization checks PremiumNoAdEntitlement.
4. Fan App plays content without ads.
5. `PremiumNoAdReceipt` records qualified consumption.
6. Settlement Engine allocates subscription pool to creators and providers.
7. Fan can view allocation summary where applicable.

### Workflow 4: Membership purchase and access

Actors:

- Fan
- Fan App
- Fan Wallet
- Payment Provider
- Entitlement Ledger
- Creator Studio
- Receipt Ledger

Steps:

1. Fan views membership tiers.
2. Fan selects a tier.
3. Payment Provider processes subscription or prototype simulation.
4. Entitlement Ledger records access.
5. Fan App unlocks member content and community surfaces.
6. MembershipReceipt and payment receipt are generated.
7. Creator Studio shows member conversion and expected payout.

### Workflow 5: Search and AI-assisted discovery

Actors:

- Fan
- Fan App
- Search Directory
- Host Public Search APIs
- Fan AI Assistant
- Private Event Vault

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

### Workflow 6: Campaign participation and reward

Actors:

- Fan
- Fan App
- Extension Runtime
- Campaign Ledger
- Reward Ledger
- Audience Data Firewall
- Sponsor Dashboard

Steps:

1. Fan sees a creator campaign.
2. Fan opens campaign terms.
3. Fan reviews eligibility, sponsor disclosure, reward terms, and data grant.
4. Fan grants required permission or uses alternate entry if available.
5. Campaign Ledger records entry.
6. Reward Ledger issues or tracks reward.
7. Sponsor receives permitted aggregate or conversion reporting.
8. Fan can view and revoke related permissions.

### Workflow 6A: Creator interest-data permission request

Actors:

- Creator
- Creator Studio
- Fan
- Fan App Settings
- Consent Grant API
- Core Fan Vault
- Audience Data Firewall
- Creator Audience API

Steps:

1. Creator creates a data-for-value request for interests, liked/disliked content, liked/disliked creators, muted providers, or ad preferences.
2. Creator declares field list, purpose, retention, whether data may be used for creator-approved ads, creator category, sponsor context, and offer terms.
3. Fan App shows the request in settings and on relevant campaign/promotion surfaces with approve, deny, narrow, and apply-to-category controls.
4. Fan decision creates, updates, or denies a `creator_interest_data` grant in `ConsentGrantAPI`.
5. Core Fan Vault stores grant state, category defaults, ad preferences, interests/dislikes, disliked creators, and access history.
6. Audience Data Firewall enforces the stricter of fan privacy mode, age/region policy, creator relationship state, block/dislike state, category defaults, and grant scope.
7. Creator Audience API returns only approved creator-scoped fields or aggregate counts for promotions, creator-sold ads, or sponsor reporting.
8. `DataAccessReceipt` records actual grant-protected access, and Fan App settings lets the fan revoke future access.

### Workflow 7: Fan revokes app or campaign access

Actors:

- Fan
- Fan App
- Consent Grant API
- Core Fan Vault
- Private Event Vault
- Creator Audience Vault

Steps:

1. Fan opens data permissions.
2. Fan selects an app, campaign, AI memory setting, creator interest-data grant, creator-category default, direct-contact grant, sponsor-linked grant, or provider permission.
3. Fan reviews consequences of revocation.
4. ConsentGrantAPI revokes future access.
5. A DataAccessReceipt or revocation record is created.
6. Affected app or provider loses access.
7. Portable fan state remains intact unless fan requests deletion.

### Workflow 8: Cross-app switch

Actors:

- Fan
- Fan App A
- Fan App B
- Fan Passport Ledger
- Core Fan Vault
- Entitlement Ledger

Steps:

1. Fan uses Fan App A with follows, saves, and memberships.
2. Fan installs or opens Fan App B.
3. Fan signs in with Fan Passport.
4. Fan App B requests app permission grant.
5. Fan approves scoped access.
6. Fan App B reads follows, entitlements, and portable preferences.
7. App-specific settings are stored separately.
8. Fan can revoke either app independently.

### Workflow 9: Fan receives creator-led recommendations

Actors:

- Fan
- Fan App
- Creator Recommendation Graph
- Fan Scoped Recommendation Engine
- Community Recommendation Feed Provider
- Fan AI Assistant
- Receipt Ledger

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

### Workflow 10: Premium private data mode

Actors:

- Fan
- Fan App
- Fan Wallet
- Core Fan Vault
- Private Event Vault
- AI Gateway
- Fan Scoped Recommendation Engine
- Settlement Engine

Steps:

1. Fan selects premium private data mode.
2. `FanWalletAPI` processes payment or prototype simulation.
3. Entitlement Ledger records `PrivateVaultEntitlement`.
4. Fan App explains that raw behavior will not be used for external ad targeting, broad external recommendation export, or AI training.
5. `DataUseGrant` rules are narrowed or revoked.
6. Core Fan Vault stores private mode settings.
7. Private Event Vault keeps behavior inside purpose-bound access controls.
8. Private in-vault recommendations use `PrivateRankingAPI`.
9. AI Gateway follows no-training and no-memory defaults unless the fan explicitly changes them.
10. Settlement Engine applies private mode subscription and utility-fee allocation.

### Workflow 11: Fan AI archive Q&A

Actors:

- Fan
- Fan App
- AI Gateway
- AI Provider
- Creator Metadata Host
- Content Host / Transcript Store
- Entitlement Ledger
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan asks a question about a creator archive.
2. AI Gateway checks `AIContentPolicy`, fan memory policy, and any required `AICreditEntitlement`.
3. AI Gateway retrieves approved source metadata, transcripts, or content references.
4. AI Provider generates answer with source references.
5. `AIUsageReceipt` and `SourceAttributionReceipt` are generated.
6. Fan sees answer and source links.
7. Settlement Engine allocates AI provider costs and creator source royalties where enabled.

### Workflow 12: Multi-format creator engagement

Actors:

- Fan
- Fan App
- Creator Metadata Host
- Content Host
- Entitlement Ledger
- Core Fan Vault

Steps:

1. Fan opens a creator channel.
2. Fan sees videos, shorts, posts, newsletters, livestreams, events, courses, and community updates from one channel catalog.
3. Fan opens a post/newsletter, saves a course, joins a livestream reminder, or enters a member community.
4. Fan App checks `ContentManifest` and Entitlement Ledger for each content type.
5. Core Fan Vault stores saves, reminders, bookmarks, and preferences.
6. Read/watch/join receipts are generated where relevant.

### Workflow 13: Wallet support allocation and boosts

Actors:

- Fan
- Fan Wallet
- Entitlement Ledger
- Creator Studio
- Receipt Ledger
- Settlement Engine

Steps:

1. Fan opens wallet support controls.
2. Fan manages memberships, boosts, gifts, bundles, premium delivery, sponsor-free access, paid courses, or gifted memberships.
3. Fan Wallet processes payment or updates allocation.
4. Entitlement Ledger records access rights.
5. Receipt Ledger records purchase, boost, gift, or allocation receipts.
6. Creator Studio receives creator-scoped support signals.
7. Settlement Engine allocates revenue and fees.

## 7. Cross-Area Interactions

- Creator Experience: fan actions update `CreatorAudienceAPI`, `MembershipEntitlement`, `CampaignEntryReceipt`, `RecommendationFeedbackAPI`, and creator dashboards.
- Fan Passport, Wallet, Vaults, and Identity Architecture: `FanPassportClaim`, `FanWalletAPI`, `CoreFanVaultAPI`, `PrivateEventVaultAPI`, `EntitlementLedgerAPI`, and `ConsentGrantAPI` power the experience.
- Revenue, Receipts, Ledgers, and Settlement: fan activity produces `PlaybackReceipt`, `PremiumNoAdReceipt`, `PaymentReceipt`, `CampaignEntryReceipt`, and `FanSubscriptionAllocationStatement`.
- Monetization Models: fan payments and free usage map to `MonetizationManifest`, `PaymentReceipt`, typed entitlements, and no-ad/ad-supported rules.
- Creator-Led Recommendation Economy: recommendations come from `RecommendationManifest`, `FanRecommendationSettings`, `FanScopedRecommendationAPI`, and `DiscoveryReceipt`.
- Neutral Public Search Utility: search uses `SearchDirectoryAPI`, `HostPublicSearchAPI`, `NeutralSearchMergePolicy`, and audit-only `SearchReceipt`.
- Audience Data Firewall and Data Rights: privacy controls use `DataUseGrant`, `CampaignDataGrant`, creator interest-data grants, category defaults, `DataAccessReceipt`, and `AudienceDataFirewallPolicy`.
- Fan Apps and App Ecosystem: certified apps use `AppPermissionGrant`, `AppCapabilityManifest`, `AppCertificationAPI`, and `AppAuditAPI`.
- AI Layer: AI features respect `AIContentPolicy`, `FanAIMemoryPolicy`, `AIConversationPolicy`, `AIUsageReceipt`, and `SourceAttributionReceipt`.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Fan-facing apps and surfaces

- Fan App: onboarding, feed, creator pages, playback, reading, search, recommendations, wallet, campaigns, AI tools, settings, and privacy controls.
- Fan Identity Settings: persona selection, app grants, creator data requests, creator/category data grants, data modes, export, delete, and revocation.
- Fan Data and Ads Settings: active creator grants, pending requests, creator-category defaults, ad preferences, interests, disliked interests, liked/disliked creators, muted providers, disliked creators, blocked creators, and access receipts.
- Fan Wallet UI: memberships, premium no-ad, tips, boosts, gifts, bundles, premium delivery, sponsor-free access, paid courses, gifted memberships, paid events, AI credits, payment history, and subscription allocation.
- Notification Center: creator updates, membership reminders, campaign status, rewards, live events, and provider/account alerts.

#### Identity, wallet, and vault systems

- Fan Passport Ledger: `FanPassportClaim`, personas, follows, app permission grants, migration records, and revocations.
- Core Fan Vault: saved content, playlists, bookmarks, notification preferences, app preferences, explicit interests, disliked interests, liked/disliked creators, blocked creators/topics, wallet display preferences, lightweight AI settings, and reward state.
- Private Event Vault: watch/read history, search history, AI interaction memory, recommendation feedback, derived interests, private interest confidence, and private ranking state under purpose-bound access.
- Creator Audience Vault: creator-scoped fan records, membership state, campaign participation, direct contact grants, and creator analytics.
- Pairwise Identity API: creator-scoped fan identifiers that limit cross-creator tracking.
- `FollowRelationshipAPI`: portable follow/unfollow state.
- `FollowVisibilityPolicy`: public, creator-visible, private, or pseudonymous/anonymous follow visibility.
- `DirectContactGrant`: explicit permission for creator direct contact or CRM export.
- `CreatorRelationshipActionRecord`: follow, unfollow, block, visibility change, direct-contact revocation, and deletion/tombstone lifecycle evidence.
- `CreatorScopedTombstoneRecord`: minimal retained marker that prevents creator rehydration of deleted relationship data while preserving required audit, safety, settlement, and legal exceptions.
- `SensitiveRelationshipDefaultPolicy`: stricter relationship visibility and direct-contact defaults for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
- `CreatorAudienceExportPolicy`: field, destination, retention, watermarking, no-resale, revocation, and breach-notice rules for creator audience exports.
- `CreatorDataGrantRequestAPI`: creator-originated requests for interests, likes, dislikes, creator dislikes, muted providers, and ad preferences.
- `CreatorCategoryPermissionPolicy`: fan defaults for broad creator categories, including deny-by-default, ask-each-time, or allow selected fields.
- `FanAdPreferencesAPI`: fan-owned ad preference settings and creator-approved ad-use posture.
- `PermissionedAudienceInterestDataAPI`: creator-side query surface that returns only approved creator-scoped fields or aggregate counts.

#### Entitlement and payment systems

- `FanWalletAPI`: fan-facing subscriptions, memberships, tips, boosts, gifts, bundles, premium delivery, sponsor-free access, AI credits, paid events, paid courses, and paid content.
- `EntitlementLedgerAPI`: access checks for memberships, premium no-ad, private vault mode, premium delivery, AI credits, events, courses, and paid content.
- `PrivateVaultEntitlement`: paid private data mode access.
- `PaymentProviderAPI`: charge, refund, subscribe, cancel, and payment receipt generation.
- Refund and Chargeback Records: downstream settlement adjustments.

#### Content and playback systems

- Playback Authorization API: checks content manifests, access mode, fan entitlements, data mode, and monetization rules.
- Playback Session API: starts content sessions.
- Ad Decision API: ad selection for free fans.
- Premium No-Ad API: no-ad eligibility and replacement settlement.
- Content Host APIs: playback manifests, delivery receipts, and public catalog.

#### Search, recommendation, and AI systems

- Public Search Utility: Search Directory, host public search APIs, `PublicSearchResultSchema`, `OpenSearchKernel`, neutral merge behavior, and `SearchReceipt`.
- `RecommendationManifestAPI`: reads creator-authored recommendations.
- `FanScopedRecommendationAPI`: trusted recommendation candidates, fan settings, community feed subscriptions, and feedback.
- `PlatformIntentRegistry`: platform-defined session motives and policy effects.
- `StartupTileSurfaceAPI`: returns startup and mid-session content tiles from platform intents plus allowed fan interests/dislikes.
- `FanInterestProfileAPI`: reads and updates fan-owned interest tokens, disliked interests, liked/disliked creators, and muted providers.
- `SessionIntentAPI`: creates, switches, clears, and optionally saves the fan's current platform intent plus scoped interest context.
- `SessionIntent`: selected platform intent, active interest tokens, active dislike filters, creator/provider blend, ad posture, ranking weights, and session shape for the current session.
- `CommunityFeedAPI`: optional curated community feed candidates.
- `FanRecommendationSettings`: trusted source, interest, dislike, community feed, provider, and feedback settings.
- `FanContentFeedbackAPI`: like, dislike, not interested, flag, save, follow, unfollow, mute, and block actions.
- `PrivateRankingAPI`: in-vault ranking for privacy-sensitive modes.
- Fan AI Assistant: summaries, Q&A, digests, search refinement, and trusted recommendation filtering.
- `AIUsageReceipt` and `SourceAttributionReceipt`: audit, attribution, and settlement records.

#### Campaign and engagement systems

- Extension Runtime: renders certified creator extensions in fan apps.
- Campaign Ledger: campaign rules, entries, eligibility, sponsor terms, and compliance.
- Reward Ledger: points, badges, rewards, issuance, redemption, and expiration.
- Campaign Data Grant: explicit fan permission for data-for-value campaigns.
- Alternate Entry Method Policy: campaign participation without excessive data disclosure.

#### Data rights and safety systems

- `ConsentGrantAPI`: grants and revokes app, campaign, AI, creator, and provider permissions.
- `CreatorInterestDataGrant`: creator-scoped grant for interests, likes, dislikes, disliked creators, muted providers, and ad preferences with purpose, retention, ad-use flag, offer context, and revocation.
- `DataUseGrant`: general purpose-bound data access.
- `CampaignDataGrant`: campaign-specific data-for-value grant.
- `DataAccessReceipt`: audit record for data access.
- Audience Data Firewall Policy Engine: enforces boundaries among fan private data, creator audience data, sponsor access, and provider processing.
- `DataDashboard`: fan-facing relationship visibility, grant, access history, export, delete, dispute, and report controls.
- Abuse Report API: fan reporting of content, creators, apps, extensions, sponsors, or providers.
- Moderation Label API: labels and restrictions surfaced in the Fan App.
