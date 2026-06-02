# Loom Product Definition 14: Audience Data Firewall and Data Rights

Status: Draft for review  
Product area: 14 of 22  
Depends on: 01 Core Thesis and Platform Principles; 03 Fan Experience; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 08 Revenue, Receipts, Ledgers, and Settlement; 09 Monetization Models; 10 Creator Plugins / Extensions / Campaign Layer; 11 AI Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 17 Trust, Safety, Fraud, and Compliance; 18 Brand/Sponsor/Advertiser Tools

## 1. Product Definition

The Audience Data Firewall and Data Rights architecture balances fan privacy, creator audience rights, and provider processing needs. The goal is not to block all data use. The goal is to make data use explicit, scoped, auditable, revocable, and aligned with fan and creator interests.

Fan private data, creator-scoped audience data, and provider-local runtime data must remain distinct. Providers should not mine creator/fan data for unrelated businesses without permission. Creators should receive useful first-party audience tools without unrestricted fan surveillance.

> **Phases 21–26 — AI search agent connection (query egress):** connecting a fan AI search agent means the fan's **search queries (and only permitted context) are sent to the fan's chosen AI provider** (Claude/OpenAI/Gemini). This is fan-initiated data egress and requires **explicit, revocable consent + clear disclosure** in Settings (`FanSearchAgentConfig.queryEgressAcknowledged`), consistent with the firewall and neutral-search rules. The agent receives only what the fan permits and does not expand creator-scoped or private-vault access. See story FE-S16.

## 2. Scope

This product area covers:

- Audience Data Firewall policy.
- `DataUseGrant`.
- `CampaignDataGrant`.
- `DataAccessReceipt`.
- Core Fan Vault, Private Event Vault, and Creator Audience Vault boundaries.
- Pairwise creator relationship IDs.
- Creator relationship visibility and direct-contact controls.
- Derived interest tokens.
- Clean-room campaign measurement.
- Creator-scoped analytics.
- Premium private mode.
- Free personalized mode.
- No-ad premium mode.
- Platform intent, interest, and dislike data posture.
- Revoke, export, delete, and dispute controls.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Data boundary model | Separates fan private data, creator audience data, and provider runtime data. | Prevents hidden data ownership grabs. | Core Thesis and Platform Principles |
| Purpose-bound grants | `DataUseGrant` defines who can use what data, for what purpose, and for how long. | Data use becomes explicit and auditable. | Fan Experience |
| Campaign data grants | Fans can exchange limited data for campaign participation or rewards. | Supports sponsor/creator campaigns without broad surveillance. | Brand/Sponsor/Advertiser Tools |
| Pairwise identity | Creators see creator-scoped identifiers, not universal fan tracking. | Limits cross-creator tracking. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| Creator relationship privacy | Fans control whether each creator relationship is public, creator-visible, private, or pseudonymous/anonymous where supported. | Lets creators build direct audience relationships without exposing fans to unrestricted visibility or contact. | Creator Experience; Fan Experience |
| Permissioned audience export | Creator audience exports are field-limited, destination-bound, auditable, revocable for future use, and subject to breach duties. | Gives creators useful audience ownership without making every follower list an unmanaged data leak. | Trust, Safety, Fraud, and Compliance |
| Private Event Vault | Rich behavior stays inside stricter access controls. | Enables personalization and AI while protecting raw history. | AI Layer |
| Creator Audience Vault | Creator gets legitimate first-party audience state. | Preserves creator business relationship. | Creator Experience |
| Data access receipts | Access to sensitive data creates audit records. | Supports fan trust, dispute handling, and compliance. | Revenue, Receipts, Ledgers, and Settlement |
| Premium private mode | Fans can pay for stronger privacy and reduced data use. | Gives privacy a product and business model. | Business Model and Incentive Design |
| Clean-room measurement | Sponsors and creators measure campaigns without raw fan data export. | Enables brand revenue with privacy. | Brand/Sponsor/Advertiser Tools |
| Platform intent and interest data posture | Each `SessionIntent` resolves a platform intent plus scoped fan interests/dislikes and declares which vault, public, aggregate, direct-connection, or provider signals ranking may use. | Fans can understand intent and interest tradeoffs without confusing a session choice with broad consent. | Creator-Led Recommendation Economy; Fan Apps and App Ecosystem |
| Fan-controlled dislikes | Disliked interests, disliked creators, muted providers, and blocked creators are explicit suppression signals in the Fan Vault. | Data rights include the right to tell the system what not to recommend. | Fan Passport, Wallet, Vaults, and Identity Architecture; Fan Experience |

## 4. Product Experience Requirements

Fans should be able to:

- See data modes.
- Understand app, campaign, AI, creator, sponsor, and provider access.
- Grant, revoke, export, and delete data.
- Set follow visibility, revoke creator direct-contact permission, unfollow, block, and request creator-scoped tombstoning.
- Choose free personalized, no-ad premium, or premium private mode where available.
- See and change platform intent, interest, and dislike data posture, bounded by privacy mode and grants.
- View, export, edit, or delete explicit interest/dislike records.
- See data access history.

Creators should be able to:

- See followers, members, notification opt-ins, campaign participation, reward state, and creator-scoped activity subject to `FollowVisibilityPolicy`.
- Build permitted segments.
- Export permissioned CRM data only where `DirectContactGrant`, revocation state, and retention policy allow it.
- Access aggregate analytics.
- Avoid receiving restricted fan private data by default.

Sponsors/providers should:

- Use only scoped permissions.
- Receive aggregate or clean-room reporting unless explicit grants allow more.
- Generate access receipts.
- Respect revocation and deletion.

### 4.1 Privacy Mode Matrix

| Mode | Default data use | Ads and monetization | AI and recommendations | Required contracts |
| --- | --- | --- | --- | --- |
| Free personalized | Uses permitted app, creator, recommendation, and campaign signals. | Ads or sponsor campaigns may use allowed context and disclosures. | `FanScopedRecommendationAPI` can use permitted preferences; private data requires grant. | `DataUseGrant`, `DataAccessReceipt`, `AdImpressionReceipt`, `CampaignDataGrant` |
| No-ad premium | No ad targeting or ad delivery for premium surfaces. | `PaymentReceipt` activates entitlement; `UtilityFeePolicy` can fund shared infrastructure. | Recommendations remain available but cannot use ad targeting logic. | `EntitlementLedgerAPI`, `PremiumNoAdReceipt`, `UtilityFeePolicy` |
| Premium private | Minimal external data use, no raw external recommendation data, no-training defaults, and stricter vault boundaries. | `PaymentReceipt` activates `PrivateVaultEntitlement`; vault service costs can create `VaultServiceReceipt`. | `PrivateRankingAPI` runs in-vault; `FanAIMemoryPolicy` and `AIConversationPolicy` default to limited memory and no training. | `PrivateVaultEntitlement`, `PrivateRankingAPI`, `FanAIMemoryPolicy`, `AIConversationPolicy`, `VaultServiceReceipt` |

### 4.2 Platform Intent, Interest, And Dislike Data Posture

Session intents are not the same thing as paid privacy modes. A `SessionIntent` can request use of a platform intent, explicit interests, inferred interests, dislike filters, host performance metadata, and provider candidates, but the Audience Data Firewall enforces the stricter of the fan's privacy mode, grants, age/region policy, vault policy, and platform intent policy.

| Data class | Default posture |
| --- | --- |
| Platform intent | Session-scoped, platform-defined, visible to the fan, and safe to pass to ranking/ad systems as a policy constraint. |
| Explicit interests | Core Fan Vault state that may be used for startup tiles and ranking when app grant and privacy mode allow. |
| Inferred interests | Stored as derived tokens; raw behavior remains in Private Event Vault unless explicit access is granted. |
| Disliked interests | Strong suppression signal in Core Fan Vault; ranking should honor it before engagement or provider scores. |
| Disliked creators / muted creators | Creator-level suppression signal distinct from unfollow and block; apps must make it easy to change. |
| External provider candidates | Allowed only up to the platform intent's provider quota and certification scope. |
| Host content performance metadata | Public/aggregate fields such as trending, being watched now, fresh, total view count, velocity, and completion can be used where content is eligible. |
| Raw private behavior | Never exported to external recommendation providers; in-vault ranking or derived summaries require grants and receipts. |

## 5. User Stories

### Story 1: Fan reviews data access

As a fan, I want to see which apps, creators, campaigns, AI tools, and providers can access my data.

End state:

- Data dashboard lists grants and history.
- Fan can revoke future access.

### Story 2: Creator views audience insights

As a creator, I want useful audience insights without receiving unrelated fan history.

End state:

- Creator sees creator-scoped analytics and segments.
- Private cross-creator history remains protected.

### Story 3: Fan joins campaign with data grant

As a fan, I want to join a giveaway while understanding the data exchange.

End state:

- `CampaignDataGrant` records consent.
- Campaign entry is valid.
- Fan can revoke future access.

### Story 4: Fan chooses premium private mode

As a fan, I want stronger privacy controls, fewer tracking uses, and no AI training by default.

End state:

- `PrivateVaultEntitlement` is active.
- Private Event Vault enforces restricted processing.
- Utility fees support privacy infrastructure.

### Story 5: Sponsor measures campaign cleanly

As a sponsor, I want campaign reporting without raw fan data export.

End state:

- Clean-room reporting returns permitted aggregate metrics.
- `DataAccessReceipt` records access.

### Story 5A: Fan reviews session intent data posture

As a fan, I want to know what data a selected session intent can use before ranking starts.

End state:

- `SessionIntentDisclosure` shows platform intent, active interests, dislike filters, creator/provider blend, and allowed data classes.
- Audience Data Firewall blocks data classes not allowed by privacy mode or grants.
- Private vault ranking uses `PrivateRankingAPI` and creates `DataAccessReceipt` where required.

### Story 5B: Fan controls interest and dislike data

As a fan, I want to see and edit interests, disliked topics, disliked creators, and muted recommendation providers.

End state:

- Fan Vault exposes interest and dislike records.
- Startup tiles and feed ranking honor fan edits.
- Raw behavior evidence can stay private while derived interest tokens remain portable.
- Fan can export or delete interest/dislike records.

### Story 5C: Fan grants creator interest data selectively

As a fan, I want to decide which creators or creator categories can use my interests, likes, dislikes, and ad preferences for creator-approved ads, giveaways, and promotions.

End state:

- Creator requests show requested fields, purpose, retention, ad-use flag, sponsor/offer context, and alternate path where required.
- Fan can approve, deny, narrow, revoke, or set creator-category defaults.
- Audience Data Firewall exposes only creator-scoped approved fields and creates `DataAccessReceipt`.
- Creator and sponsor tools cannot use interests/dislikes unless the fan grant allows that purpose.

### Story 6: Fan limits creator relationship visibility

As a fan, I want to control what a creator can see about my follow relationship and whether they can contact me directly.

End state:

- `FollowVisibilityPolicy` governs creator visibility.
- `DirectContactGrant` can be denied or revoked independently from the follow.
- Creator Audience Vault applies block, unfollow, and creator-scoped tombstone state.

### Story 7: Creator exports only permissioned audience data

As a creator, I want to export or contact the fans who have granted permission without receiving private followers, blocked fans, or universal identifiers.

End state:

- `CreatorCRMExportAPI` returns only eligible audience fields.
- `CreatorAudienceExportPolicy` defines allowed fields, destination, retention, watermarking, resale limits, and breach duties.
- `DataAccessReceipt` records export/access history for audit, fan visibility, and disputes.

## 6. End-to-End Workflows

### Workflow 1: App data grant

Actors:

- Fan
- Fan App
- ConsentGrantAPI
- Core Fan Vault
- Private Event Vault

Steps:

1. App requests access scopes.
2. Fan reviews data purpose, duration, and destination.
3. `DataUseGrant` is created.
4. App receives only permitted data.
5. `DataAccessReceipt` records grant-protected private or sensitive access and is submitted to `ReceiptLedger`.
6. Fan can revoke future access.

### Workflow 2: Creator analytics

Actors:

- Creator
- Creator Studio
- Creator Audience Vault
- Private Event Vault
- Audience Data Firewall

Steps:

1. Creator opens audience dashboard.
2. Creator requests segment or aggregate insight.
3. `AudienceDataFirewallPolicy` checks creator-scoped data rights, fan privacy mode, and purpose-bound `DataUseGrant`.
4. `PairwiseIdentityAPI` limits identifiers to creator-scoped relationships.
5. Private Event Vault contributes only permitted aggregate or derived signals and never exports raw cross-creator event history.
6. `DataAccessReceipt` records grant-protected private vault access and is submitted to `ReceiptLedger`.
7. Creator sees analytics without raw cross-creator history.

### Workflow 2A: Creator relationship visibility and revocation

Actors:

- Fan
- Fan App
- Creator Audience Vault
- Audience Data Firewall
- Creator Studio

Steps:

1. Fan changes relationship visibility, unfollows, blocks, revokes `DirectContactGrant`, or requests creator-scoped deletion.
2. `FollowRelationshipAPI` updates the relationship state and writes `CreatorRelationshipActionRecord`.
3. `AudienceDataFirewallPolicy` reevaluates what the creator, sponsor tools, apps, and export systems can access.
4. `CreatorAudienceAPI` removes or hides non-required audience state from Creator Studio according to `FollowVisibilityPolicy`, block state, revocation state, and retention policy.
5. If deletion is requested, `CreatorScopedTombstoneRecord` prevents rehydration of creator-visible relationship data while required audit, settlement, legal, and safety records remain retained.
6. Any allowed access or export creates `DataAccessReceipt`; denied access returns a policy-safe denial.
7. Creator Studio updates audience counts, CRM export eligibility, and segment membership without revealing restricted fan private data.

### Workflow 2B: Creator CRM export and direct-contact gating

Actors:

- Creator
- Creator Studio
- Creator Audience Vault
- Audience Data Firewall
- CreatorCRMExportAPI
- Receipt Ledger
- DataDashboard

Steps:

1. Creator selects an audience segment for direct message, CRM sync, or export.
2. Creator declares purpose, destination, contact channel, and retention period.
3. `CreatorCRMExportAPI` requests eligible audience fields from `CreatorAudienceAPI`.
4. `AudienceDataFirewallPolicy` checks `FollowVisibilityPolicy`, `DirectContactGrant`, `SensitiveRelationshipDefaultPolicy`, block state, revocation state, and `CreatorScopedTombstoneRecord`.
5. `CreatorAudienceExportPolicy` enforces field limits, pairwise identifiers, export format, destination class, watermarking, no-resale obligations, and breach-notice duties.
6. Eligible fan records are returned; denied records are omitted or counted only in aggregate.
7. `DataAccessReceipt` records actor, provider key, grant id, purpose, data class, destination, retention policy, and dispute reference.
8. `DataDashboard` shows fan-visible access/export history where disclosure is required.
9. Later revocation, block, or deletion changes future export eligibility and creates `CreatorRelationshipActionRecord`.

### Workflow 2C: Creator interest-data grant for ads and promotions

Actors:

- Creator
- Creator Studio
- Fan
- Fan App Settings
- Fan Interest Profile API
- ConsentGrantAPI
- Creator Audience API
- Audience Data Firewall
- Receipt Ledger

Steps:

1. Creator creates `AudienceDataGrantRequest` for explicit interests, inferred interests, liked/disliked content, liked/disliked creators, muted providers, or ad preferences.
2. Request declares purpose, field list, creator category, retention, ad-use flag, sponsor context, and any giveaway or promotional value.
3. Fan App settings and relevant campaign surfaces show the request with approve, deny, narrow, and category-default actions.
4. Fan decision creates or updates `creator_interest_data` consent grant, or records a denial.
5. `AudienceDataFirewallPolicy` checks fan privacy mode, age/region policy, sensitive creator defaults, relationship state, blocks, category policies, and grant state.
6. `CreatorAudienceAPI` can query only approved creator-scoped fields or aggregate counts; raw Private Event Vault behavior is never exported.
7. If access is allowed, `DataAccessReceipt` records actor, creator, grant id, fields, purpose, ad-use flag, destination, retention, and revocation state.
8. Fan can revoke future access from settings; Creator Audience API omits revoked fields from later ad targeting, promotions, exports, and reports.

### Workflow 3: Campaign data grant

Actors:

- Fan
- Fan App
- Campaign Extension
- Campaign Ledger
- Private Event Vault
- Creator Audience Vault
- Sponsor

Steps:

1. Fan opens campaign.
2. Campaign shows sponsor disclosure, `CampaignComplianceManifest`, eligibility, reward, data use, age/region rules, and alternate entry.
3. `EligibilityAPI` checks campaign rules without exporting raw Private Event Vault data.
4. Fan accepts `CampaignDataGrant` under `AudienceDataFirewallPolicy`.
5. Campaign Ledger records `CampaignEntryReceipt`.
6. Reward fulfillment creates `RewardReceipt` where applicable.
7. Creator Audience Vault records only permitted campaign participation and creator-scoped segment state.
8. Sponsor delivery and conversion events create `SponsorDeliveryReceipt` and `ConversionReceipt` where applicable.
9. Sponsor reporting uses `CleanRoomMeasurementAPI` or aggregate data; any grant-protected access creates `DataAccessReceipt`.

### Workflow 4: Data mode selection and premium private mode

Actors:

- Fan
- Fan Wallet
- Core Fan Vault
- Private Event Vault
- AI Gateway
- Fan Scoped Recommendation Engine
- Receipt Ledger

Steps:

1. Fan selects free personalized, no-ad premium, or premium private mode.
2. Fan may also select a startup content tile; the resulting `SessionIntent` contains platform intent, active interest tokens, and dislike filters that are evaluated separately from privacy mode.
3. If a paid privacy mode is selected, Fan Wallet records `PaymentReceipt` and `EntitlementLedgerAPI` activates `PremiumNoAdEntitlement` or `PrivateVaultEntitlement`.
4. Free personalized mode allows scoped personalization through explicit `DataUseGrant` and required `DataAccessReceipt`.
5. No-ad premium disables ad targeting and ad delivery on premium surfaces while preserving neutral search and fan-controlled recommendations.
6. Premium private mode restricts grant defaults, blocks raw external recommendation data, and keeps behavior inside stricter Private Event Vault boundaries.
7. `RecommendationDataPosturePolicy` declares allowed data classes for the selected platform intent, active interests, dislike filters, and provider candidate sources.
8. `AudienceDataFirewallPolicy` applies the stricter of session intent posture, privacy mode, fan grants, age/region policy, vault policy, and platform intent policy.
9. `FanScopedRecommendationAPI` ranks only eligible/trusted candidates; if private behavior is used, `PrivateRankingAPI` runs in-vault.
10. Search history is stored only if fan policy allows; `SearchReceipt` remains audit/utility funding only and cannot become paid ranking.
11. AI follows `FanAIMemoryPolicy`, `AIConversationPolicy`, no-training defaults, and limited-memory defaults.
12. `VaultServiceReceipt` and utility records support private-mode infrastructure costs where applicable.

### Workflow 5: Data export/delete

Actors:

- Fan
- `FanExportAPI`
- Vault Providers
- App Providers
- Governance Admin

Steps:

1. Fan requests export or delete.
2. System shows affected data by vault and portability class.
3. System shows `MigrationManifest` and `MigrationPlanAPI` options where export supports provider migration.
4. Fan confirms export, migration, or deletion.
5. `FanExportAPI` exports portable Core Fan Vault state, permitted app state, and user-controlled records.
6. `VaultDeleteAPI` deletes or tombstones deletable vault records according to policy.
7. Retained audit, safety, receipt, tax, chargeback, and settlement records are distinguished from exportable or deletable user state.
8. `MigrationReceipt`, export receipts, deletion records, and dispute evidence are created.
9. Disputes or failures route to governance.

## 7. Cross-Area Interactions

- Fan Passport, Wallet, Vaults, and Identity Architecture: `FanPassportClaim`, `CoreFanVaultAPI`, `PrivateEventVaultAPI`, `FanWalletAPI`, and entitlements store identity and access state.
- Creator Experience: creator audience tools depend on `CreatorAudienceAPI`, `AudienceSegmentAPI`, and `AudienceAnalyticsAPI`.
- Fan Experience: data controls surface `DataDashboard`, `ConsentGrantAPI`, grants, revocation, export, and delete history.
- Creator Plugins / Extensions / Campaign Layer: extensions request `ExtensionPermissionGrant`, `CampaignDataGrant`, `DataUseGrant`, and `DataAccessReceipt`.
- Brand/Sponsor/Advertiser Tools: sponsor reporting must use `CampaignDataGrant`, `CleanRoomMeasurementAPI`, `EligibilityAPI`, and sponsor receipts.
- AI Layer: `FanAIMemoryPolicy`, `AIConversationPolicy`, `AIContentPolicy`, and no-training defaults depend on fan and creator policies.
- Creator-Led Recommendation Economy: `PlatformIntent`, `FanInterestProfile`, `SessionIntent`, `RecommendationModePolicy`, `RecommendationDataPosturePolicy`, `AdLoadPolicy`, and `PrivateRankingAPI` require data-rights enforcement.
- Trust, Safety, Fraud, and Compliance: `ProviderAuditAPI`, `AppAuditAPI`, `DisputeResolutionAPI`, and incident workflows enforce data violations.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `AudienceDataFirewallPolicy`: rules for fan private data, creator audience data, provider processing, sponsors, apps, and AI.
- `FollowVisibilityPolicy`: fan-selected creator relationship visibility state: public, creator-visible, private, or pseudonymous/anonymous where supported.
- `DirectContactGrant`: explicit fan permission for creator direct-contact use, including purpose, destination, retention, revocation, and export eligibility.
- `CreatorRelationshipActionRecord`: audit record for follow visibility changes, unfollows, blocks, direct-contact revocations, and creator-scoped deletion requests.
- `CreatorScopedTombstoneRecord`: minimal retained marker that prevents creator rehydration of deleted relationship data while preserving required audit, safety, settlement, and legal exceptions.
- `SensitiveRelationshipDefaultPolicy`: stricter relationship visibility and direct-contact defaults for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
- `CreatorAudienceExportPolicy`: field, destination, retention, watermarking, no-resale, revocation, and breach-notice rules for creator audience exports.
- `ConsentGrantAPI`: grants and revocations.
- `CreatorDataGrantRequestAPI`: creator-originated request lifecycle for fan interests, likes, dislikes, disliked creators, muted providers, and ad preferences.
- `CreatorInterestDataGrant`: creator-scoped grant that records approved fields, purpose, retention, ad-use flag, sponsor/offer context, category policy source, and revocation state.
- `CreatorCategoryPermissionPolicy`: fan defaults that allow, deny, or ask for selected creator categories before creator interest-data requests are shown.
- `FanAdPreferencesAPI`: fan-owned ad preference records used for settings, ad posture, and creator-approved ad relevance when explicitly granted.
- `PermissionedAudienceInterestDataAPI`: creator-side query surface that returns only approved creator-scoped fields or aggregate counts and never exports raw private behavior.
- `DataUseGrant`: purpose-bound access.
- `CampaignDataGrant`: campaign-specific data exchange.
- `DataAccessReceipt`: mandatory signed audit record for actual grant-protected or private data access, including actor, provider key, grant id, purpose, data class, vault, timestamp, certification scope, retention policy, and dispute reference.
- `ReceiptIngestAPI`: validates and submits `DataAccessReceipt` to the ledger.
- `ReceiptLedger`: immutable store for access, campaign, utility, and settlement evidence.
- `CoreFanVaultAPI`: lightweight portable fan state.
- `PrivateEventVaultAPI`: rich fan behavior under strict permissions.
- `CreatorAudienceAPI`: creator-scoped audience records, follow visibility state, member/follower status, direct-contact grants, block state, and tombstone status.
- `AudienceSegmentAPI`: creator campaign and audience segments.
- `CreatorCRMExportAPI`: permissioned creator audience export gated by `FollowVisibilityPolicy`, `DirectContactGrant`, `CreatorAudienceExportPolicy`, access history, revocation state, and retention rules.
- `AudienceAnalyticsAPI`: aggregate insights.
- `PairwiseIdentityAPI`: creator-scoped identifiers.
- `FanInterestProfileAPI`: explicit interests, inferred interest tokens, disliked interests, disliked creators, muted providers, source, confidence, and recency.
- `DerivedInterestTokenAPI`: privacy-preserving signals derived from private behavior.
- `DislikedInterestToken`: fan-owned suppression signal for ranking and startup tiles.
- `DislikedCreatorRecord`: creator-level suppression signal distinct from unfollow, mute, and block.
- `PrivateRankingAPI`: in-vault recommendations.
- `FanScopedRecommendationAPI`: ranks eligible/trusted recommendation candidates while respecting fan settings.
- `CommunityFeedAPI`: optional community candidates that remain subject to fan and data-rights policy.
- `CleanRoomMeasurementAPI`: aggregate campaign reporting.
- `EligibilityAPI`: campaign eligibility checks without raw private export.
- `CampaignComplianceManifest`: campaign rules, disclosures, eligibility, and alternate entry.
- `CampaignEntryReceipt`: campaign entry evidence.
- `RewardReceipt`: reward fulfillment evidence.
- `SponsorDeliveryReceipt`: sponsor delivery evidence.
- `ConversionReceipt`: permitted conversion evidence.
- `PaymentReceipt`: paid privacy or no-ad entitlement payment.
- `EntitlementLedgerAPI`: premium/no-ad/private-mode entitlement state.
- `PrivateVaultEntitlement`: paid private-mode entitlement.
- `FanAIMemoryPolicy`: fan AI memory defaults and retention controls.
- `AIConversationPolicy`: AI conversation retention and training policy.
- `UtilityFeePolicy`: shared utility funding policy.
- `VaultServiceReceipt`: private vault service funding record.
- `FanExportAPI`: fan data export.
- `VaultDeleteAPI`: vault deletion and tombstone requests.
- `MigrationManifest`: portable export/migration package description.
- `MigrationPlanAPI`: provider migration planning.
- `MigrationReceipt`: migration/export completion evidence.
- `DataDashboard`: fan-facing access, revoke, export, and delete controls.
- `StartupTileSurfaceAPI`: returns content tiles using only allowed platform intent, fan interests/dislikes, follows, and public/trending context.
- `SessionIntentAPI`: creates, switches, clears, and optionally saves the fan's current platform intent plus scoped interest context.
- `SessionIntent`: selected platform intent, active interests, dislike filters, and policy envelope for the current session.
- `SessionIntentDisclosure`: fan-facing disclosure of platform intent, interests/dislikes, and data posture before ranking.
- `RecommendationModePolicy`: policy-level data posture and session constraints.
- `RecommendationDataPosturePolicy`: data classes allowed by each session intent policy.
- `ModeDisclosureCard`: compatibility disclosure for apps that expose explicit recommendation modes.
- `ProviderAuditAPI`: detects misuse and verifies deletion/export compliance.
