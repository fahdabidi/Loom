# Loom Product Definition 05: Fan Passport, Wallet, Vaults, and Identity Architecture

Status: Draft for review  
Product area: 5 of 22  
Depends on: 01 Core Thesis and Platform Principles; 03 Fan Experience

## 1. Product Definition

The Fan Passport, Wallet, Vaults, and Identity Architecture defines fan portability and fan data control. It lets fans carry identity, follows, personas, app permissions, entitlements, wallet state, preferences, and selected private state across certified apps without giving every app, provider, creator, or sponsor unrestricted access to fan behavior.

The fan should not need to pay separately for abstract identity hosting. Baseline identity and core vault infrastructure should be funded as shared utility infrastructure. Fans may pay for premium modes, no-ad access, private data modes, AI features, creator memberships, events, and paid content.

## 2. Scope

This product area covers:

- Fan Passport identity.
- `FanPassportClaim`.
- Fan personas and display identities.
- Follow relationships.
- Follow visibility and relationship lifecycle controls.
- App permission grants.
- Consent grants and revocation.
- Fan Wallet and entitlements.
- Core Fan Vault.
- Private Event Vault.
- Fan Interest Profile.
- Disliked interests and disliked creators.
- Fan feedback signals.
- Creator Audience Vault interaction.
- Pairwise creator relationship IDs.
- Export, delete, migration, and privacy controls.

It does not define complete Fan App UX, but it powers the Fan Experience across apps.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Fan Passport | Portable fan identity across certified apps. | Fans do not get locked into one app account. | Fan Experience; Fan Apps and App Ecosystem |
| `FanPassportClaim` | Signed root fan identity claim with public keys and account/vault pointers. | Apps and providers can verify identity without owning it. | Governance, Certification, and Foundation Model |
| Fan personas | Fan can maintain different display identities or contexts. | Supports privacy and community-specific expression. | Audience Data Firewall and Data Rights |
| Pairwise creator IDs | Creator-scoped fan identifiers limit cross-creator tracking. | Creators get audience tools without broad surveillance. | Creator Experience; Audience Data Firewall and Data Rights |
| Relationship visibility controls | Fan can set public, creator-visible, private, or pseudonymous/anonymous creator relationship visibility where supported. | Protects fans while still allowing creators legitimate audience visibility. | Fan Experience; Audience Data Firewall and Data Rights |
| Fan Wallet | Wallet for memberships, subscriptions, premium, AI credits, tips, events, and paid content. | One payment and entitlement model across apps. | Monetization Models; Revenue, Receipts, Ledgers, and Settlement |
| Core Fan Vault | Lightweight portable fan-owned state. | Saves preferences, bookmarks, and settings across apps. | Fan Apps and App Ecosystem |
| Private Event Vault | Richer behavior stored under purpose-bound controls. | Enables personalization and AI without exporting raw behavior broadly. | Audience Data Firewall and Data Rights; AI Layer |
| Fan Interest Profile | Fan-owned interest tokens, disliked interests, liked/disliked creators, muted providers, and confidence/source metadata. | Lets recommendations personalize around fan-controlled interests instead of app-owned profiles. | Creator-Led Recommendation Economy; Fan Apps and App Ecosystem |
| Explicit dislike controls | Fan can dislike content, interests, creators, and recommendation providers. | Gives fans a direct way to suppress topics and creators, and gives ranking a strong negative signal. | Fan Experience; Trust, Safety, Fraud, and Compliance |
| Creator interest-data grants | Fan can approve, narrow, deny, or revoke creator access to interests, likes, dislikes, ad preferences, and creator preference records on a per-creator or creator-category basis. | Lets fans trade data for better creator offers without making interest data platform-owned or creator-owned by default. | Audience Data Firewall and Data Rights; Brand/Sponsor/Advertiser Tools |
| Consent grants | Explicit fan permissions for apps, campaigns, AI, and providers. | Data use becomes visible and revocable. | Brand/Sponsor/Advertiser Tools; Creator Plugins / Extensions / Campaign Layer |
| Entitlement portability | Purchases and access rights work across certified apps. | Fans can change apps without losing paid access. | Provider Marketplace and Certified APIs |
| Export/delete/migration | Fan can export, delete, revoke, or move identity and vault state. | Data rights become operational. | Migration Strategy from Existing Platforms |

## 4. Product Experience Requirements

### 4.1 Identity Model

Fan identity should support:

- Stable Fan Passport ID.
- Public keys and verification.
- One or more personas.
- Pairwise IDs for creator-scoped relationships.
- Account recovery.
- App permission grants.
- Migration records.
- Revocation records.

### 4.2 Vault Model

Fan data should be separated by sensitivity and purpose:

- Fan Passport Ledger: identity, follows, personas, permissions, entitlements references, and migration records.
- Core Fan Vault: saved content, playlists, bookmarks, notification preferences, app settings, explicit interests, disliked interests, liked/disliked creators, muted providers, blocked creators/topics, display preferences, lightweight AI preferences, and reward state.
- Private Event Vault: watch/read/search history, AI memory, recommendation feedback, derived interest confidence, private interest signals, and private ranking state.
- Creator Audience Vault: creator-scoped audience records, membership state, campaign participation, and permissioned direct contact.

### 4.3 Wallet Model

Fan Wallet should support:

- Creator memberships.
- Global no-ad premium.
- Premium delivery or quality plans.
- AI credits or subscriptions.
- Tips and boosts.
- Paid events.
- Paid content or pay-per-view.
- Courses.
- Refunds and chargebacks.
- Payment receipt references.
- Fan-facing allocation statements.

### 4.4 Privacy and Permission Model

Fans should be able to:

- See who has access to what.
- Revoke app permissions.
- Revoke campaign or sponsor data grants.
- Approve or deny creator requests for interest, like, dislike, and ad-preference access per creator.
- Set broad creator-category defaults, such as always ask, auto-deny, or auto-approve limited fields for creator categories the fan trusts.
- Choose AI memory settings.
- Choose data modes.
- View, edit, export, or delete interest and dislike profiles.
- View and edit ad preferences, data-for-value offers, active creator data grants, and disliked/blocked creators from Fan App settings.
- Like, dislike, flag, save, follow, unfollow, mute, or block content and creators.
- Export data.
- Delete selected data.
- Migrate identity and vault state.

## 5. User Stories

### Story 1: Fan creates a portable identity

As a fan, I want one identity across Loom apps so I can follow creators and manage purchases without separate accounts everywhere.

End state:

- Fan Passport exists.
- `FanPassportClaim` is signed.
- Core Fan Vault is provisioned.
- Default privacy and app permissions are established.

### Story 2: Fan uses personas

As a fan, I want to use different display personas so I can participate in different creator communities with appropriate context.

End state:

- Persona records exist.
- App and creator surfaces see only the active permitted persona.
- Pairwise identifiers prevent unnecessary cross-context tracking.

### Story 2A: Fan controls creator relationship visibility

As a fan, I want to follow a creator while controlling whether the relationship is public, creator-visible, private, or pseudonymous.

End state:

- `FollowVisibilityPolicy` is recorded with the follow.
- Creator receives only allowed creator-scoped state.
- Fan can unfollow, block, revoke direct contact, or request creator-scoped deletion/tombstoning later.

### Story 3: Fan buys membership

As a fan, I want one wallet to manage creator memberships and access rights.

End state:

- Fan Wallet records payment.
- Entitlement Ledger records membership.
- Certified apps can authorize access.
- Creator receives member signal without payment details.

### Story 4: Fan saves content across apps

As a fan, I want saved content and preferences to follow me across certified apps.

End state:

- Core Fan Vault stores saved references and preferences.
- App-specific preferences remain separate where appropriate.
- Fan can revoke an app without losing portable saved state.

### Story 5: Fan enables private recommendations

As a fan, I want better recommendations without exposing my raw behavior to every provider.

End state:

- Private Event Vault stores behavior.
- PrivateRankingAPI ranks inside the vault where required.
- Apps receive ranked outputs or derived signals, not unrestricted history.

### Story 5A: Fan manages interests and dislikes

As a fan, I want to see and correct the interests and dislikes Loom uses for recommendations.

End state:

- `FanInterestProfile` shows explicit interests, inferred interests, disliked interests, liked/disliked creators, muted providers, and source/confidence.
- Fan can add, remove, mute, dislike, export, or delete interest records.
- Raw private behavior remains in Private Event Vault unless the fan grants access.
- Startup tiles and recommendation scoring honor dislikes and muted creators/providers.

### Story 6: Fan revokes campaign data access

As a fan, I want to revoke a campaign data grant after participating.

End state:

- ConsentGrantAPI revokes future access.
- Data access records remain auditable.
- Campaign keeps valid historical receipts but loses future access where applicable.

### Story 6A: Fan grants creator interest data for better offers

As a fan, I want to approve, narrow, or deny a creator's request to use my interests, likes, dislikes, and ad preferences for creator-approved ads, giveaways, or promotions.

End state:

- Creator request shows purpose, requested fields, retention, ad-use flag, and offer value.
- Fan can approve for one creator, deny, narrow fields, or save a creator-category default.
- `ConsentGrantAPI` stores `creator_interest_data` grants and revocations.
- Creator Audience APIs expose only approved creator-scoped fields and create `DataAccessReceipt` on access.

### Story 7: Fan migrates to another vault provider

As a fan, I want to move my identity or vault provider without losing follows and entitlements.

End state:

- Fan migration plan is generated.
- Export package is produced.
- New vault validates import.
- App permissions and entitlements remain usable.

## 6. End-to-End Workflows

### Workflow 1: Fan Passport creation

Actors:

- Fan
- Fan App
- Fan Passport Ledger
- Core Fan Vault
- Entitlement Ledger

Steps:

1. Fan opens a certified Fan App.
2. Fan creates identity or signs in with an existing one.
3. Fan Passport Ledger creates `FanPassportClaim`.
4. Fan chooses initial persona.
5. Core Fan Vault is provisioned.
6. Default app permission grant is created.
7. Entitlement Ledger is linked for future access rights.
8. Fan can follow creators and use wallet features.

### Workflow 2: Follow creator with pairwise identity

Actors:

- Fan
- Fan App
- Fan Passport Ledger
- Pairwise Identity API
- Creator Audience Vault

Steps:

1. Fan taps follow.
2. Fan selects `FollowVisibilityPolicy`: public, creator-visible, private, or pseudonymous/anonymous where supported.
3. `SensitiveRelationshipDefaultPolicy` can require stricter defaults for minors, vulnerable users, sensitive creator categories, private mode, or regulated regions.
4. `FollowRelationshipAPI` records follow relationship.
5. `PairwiseIdentityAPI` creates creator-scoped fan identifier.
6. Creator Audience Vault receives only allowed creator-scoped audience state.
7. Creator sees follower/member status according to `FollowVisibilityPolicy`, not full cross-network identity.
8. Fan can unfollow, block, revoke `DirectContactGrant`, change notification permissions, or request creator-scoped deletion/tombstoning.
9. Lifecycle changes create `CreatorRelationshipActionRecord`; tombstoning creates `CreatorScopedTombstoneRecord` while required audit, settlement, safety, and legal records remain retained.

### Workflow 3: Wallet purchase and entitlement

Actors:

- Fan
- Fan Wallet
- Payment Provider
- Entitlement Ledger
- Fan App
- Creator Studio
- Receipt Ledger

Steps:

1. Fan selects membership, premium plan, AI credits, or paid content.
2. Fan Wallet starts purchase.
3. Payment Provider charges or prototype simulates charge.
4. PaymentReceipt is generated.
5. `EntitlementClaimAPI` records access claim in the Entitlement Ledger.
6. Fan App unlocks access.
7. Creator Studio receives creator-scoped member or purchase signal.
8. Receipt Ledger sends records to settlement.

### Workflow 4: App permission grant and revoke

Actors:

- Fan
- Fan App
- Consent Grant API
- Core Fan Vault
- Private Event Vault

Steps:

1. Fan signs into a certified app.
2. App requests scopes.
3. Fan reviews requested identity, vault, wallet, and activity access.
4. ConsentGrantAPI records grant.
5. App reads permitted state.
6. Fan later revokes access.
7. App loses future access.
8. Revocation record is stored for audit.

### Workflow 5: Private event storage and AI memory

Actors:

- Fan
- Fan App
- Private Event Vault
- AI Gateway
- Fan AI Assistant
- `DataUseGrant`

Steps:

1. Fan enables AI memory or private recommendations.
2. Fan App records eligible behavior to Private Event Vault.
3. Fan AI Assistant requests permitted memory context for a specific purpose.
4. `DataUseGrant` is created or checked before memory access.
5. AI Gateway applies fan memory policy.
6. `DataAccessReceipt` records actual access.
7. AI response is returned.
8. Fan can clear memory, change retention, or revoke access.

### Workflow 5A: Interest and dislike update

Actors:

- Fan
- Fan App
- Core Fan Vault
- Private Event Vault
- Fan Scoped Recommendation Engine
- Trust and Safety

Steps:

1. Fan selects a startup tile, likes content, dislikes content, says not interested, saves content, follows or unfollows a creator, dislikes a creator, mutes a provider, blocks a creator, or flags content.
2. Fan App sends `FanInterestSignal` to `FanInterestProfileAPI`.
3. Core Fan Vault updates explicit interests, disliked interests, liked/disliked creators, muted providers, and blocked creators where the signal is portable.
4. Private Event Vault stores private behavioral evidence, confidence, and recency where fan policy allows.
5. Flag actions route to Trust and Safety while still creating a dislike/suppression signal for the fan.
6. Fan Scoped Recommendation Engine receives only allowed interest tokens, dislike filters, and derived private summaries.
7. Fan can later edit, export, or delete interest/dislike records from the Data Dashboard.

### Workflow 6: Campaign data grant

Actors:

- Fan
- Fan App
- Campaign Extension
- Consent Grant API
- Campaign Ledger
- Creator Audience Vault

Steps:

1. Fan enters a creator campaign.
2. Campaign extension shows required data and value exchange.
3. Fan accepts or uses alternate entry where required.
4. Campaign Data Grant is recorded.
5. Campaign Ledger records entry.
6. Creator Audience Vault records campaign participation.
7. Fan can later revoke future access.

### Workflow 6A: Creator interest-data grant request

Actors:

- Creator
- Creator Studio
- Fan
- Fan App Settings
- Consent Grant API
- Fan Interest Profile API
- Creator Audience API
- Audience Data Firewall

Steps:

1. Creator creates an `AudienceDataGrantRequest` with purpose, requested fields, creator categories, retention, ad-use flag, and optional giveaway/promotion value.
2. Fan App shows the request in settings and, where appropriate, at campaign or creator surfaces.
3. Fan approves, denies, narrows fields, or applies a creator-category default.
4. `ConsentGrantAPI` records a `creator_interest_data` grant with `granteeType` set to creator channel or creator category.
5. `FanInterestProfileAPI` and `FanAdPreferencesAPI` expose only approved fields through Audience Data Firewall.
6. `CreatorAudienceAPI` returns creator-scoped interest/ad-preference fields or aggregate counts according to the grant.
7. Every access creates `DataAccessReceipt`; revocation blocks future access while preserving required receipts.

### Workflow 7: Fan export or migration

Actors:

- Fan
- Fan Export API
- Fan Passport Ledger
- Core Fan Vault
- Private Event Vault
- Entitlement Ledger
- Destination Provider

Steps:

1. Fan requests export or migration.
2. `MigrationPlanAPI` reads `MigrationManifest`, source provider capabilities, destination provider capabilities, and portability classes.
3. System shows included state by portability class.
4. Fan confirms destination and privacy settings.
5. `FanExportAPI` exports identity, follows, permissions, vault state, and entitlement references.
6. Destination provider validates import.
7. `MigrationReceipt` and `FanMigrationRecord` record execution and cutover state.
8. Apps resolve updated account/vault pointers.

## 7. Cross-Area Interactions

- Fan Experience: fan-facing behavior depends on `FanPassportClaim`, `CoreFanVaultAPI`, `PrivateEventVaultAPI`, `FanWalletAPI`, and `ConsentGrantAPI`.
- Creator-Led Recommendation Economy: `FanInterestProfile`, dislike filters, and feedback signals shape startup tiles and content scoring.
- Creator Experience: creators receive creator-scoped audience data through `CreatorAudienceAPI`, `PairwiseIdentityAPI`, `AudienceAnalyticsAPI`, and permissioned interest-data grants.
- Revenue, Receipts, Ledgers, and Settlement: wallet payments and usage entitlements generate `PaymentReceipt`, `MembershipReceipt`, `PremiumNoAdReceipt`, and entitlement claims.
- Audience Data Firewall and Data Rights: this architecture enforces `DataUseGrant`, `CampaignDataGrant`, `DataAccessReceipt`, and `AudienceDataFirewallPolicy`.
- Fan Apps and App Ecosystem: apps authenticate through `FanAppLoginSDK` and request scoped access through `AppPermissionGrant`.
- AI Layer: `FanAIMemoryPolicy`, `AIConversationPolicy`, and `PrivateEventVaultAPI` govern assistant behavior.
- Creator Plugins / Extensions / Campaign Layer: campaigns request `CampaignDataGrant` and store rewards through `CoreFanVaultAPI` and campaign receipts.
- Migration Strategy from Existing Platforms: `FanExportAPI`, `VaultExportAPI`, `MigrationReceipt`, and `FanMigrationRecord` support export and migration.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

#### Identity systems

- `FanPassportClaim`: signed root fan identity claim with public keys, account pointers, vault pointers, personas, and revocation state.
- `FanPassportAPI`: create, resolve, update, and migrate fan identity.
- `FanPersonaAPI`: manage display identities and persona-specific preferences.
- `FollowRelationshipAPI`: follow/unfollow creators and manage notification relationship state.
- `FollowVisibilityPolicy`: fan-selected creator relationship visibility state: public, creator-visible, private, or pseudonymous/anonymous where supported.
- `DirectContactGrant`: explicit fan permission for creator direct-contact use, including purpose, destination, retention, revocation, and export eligibility.
- `CreatorRelationshipActionRecord`: audit record for follow visibility changes, unfollows, blocks, direct-contact revocations, and creator-scoped deletion requests.
- `CreatorScopedTombstoneRecord`: minimal retained marker that prevents creator rehydration of deleted relationship data while preserving required audit, safety, settlement, and legal exceptions.
- `SensitiveRelationshipDefaultPolicy`: stricter relationship visibility and direct-contact defaults for minors, vulnerable users, sensitive creator categories, private-mode users, and regulated regions.
- `CreatorAudienceExportPolicy`: field, destination, retention, watermarking, no-resale, revocation, and breach-notice rules for creator audience exports.
- `ConsentGrantAPI`: app, provider, campaign, AI, creator interest-data, creator-category default, and direct-contact permission grants and revocations.
- `CreatorDataGrantRequest`: creator request for fan interests, likes, dislikes, ad preferences, and creator preference records, including purpose, retention, ad-use flag, and offer value.
- `CreatorCategoryPermissionPolicy`: fan default for creator categories, such as ask every time, auto-deny, or auto-approve limited fields.
- `EntitlementClaimAPI`: signed entitlement references linked to fan identity.
- `PairwiseIdentityAPI`: creator-scoped identifiers and anti-correlation controls.
- `FanMigrationRecord`: identity and vault migration history.
- Account Recovery System: recovery keys, trusted devices, or recovery providers.

#### Wallet and entitlement systems

- `FanWalletAPI`: memberships, subscriptions, tips, paid content, paid events, AI credits, private mode, premium delivery, and premium plans.
- `EntitlementLedgerAPI`: signed access claims for creator memberships, global no-ad, private vault mode, AI credits, events, courses, premium delivery, and paid content.
- `SubscriptionRecord`: active recurring paid plan.
- `MembershipEntitlement`: creator-specific membership access.
- `PremiumNoAdEntitlement`: no-ad access proof.
- `PrivateVaultEntitlement`: stronger paid privacy mode.
- `AICreditEntitlement`: AI access and credit balance.
- `PaymentReceipt`: proof of payment.
- `RefundChargebackRecord`: downstream payment and settlement adjustments.
- `PaymentProviderAPI`: charges, refunds, subscriptions, cancellations, receipts, and chargebacks.
- `MerchantOfRecordContract`: defines payment/legal responsibility.
- `FanSubscriptionAllocationStatement`: fan-visible support allocation where applicable.

#### Vault systems

- `CoreFanVaultAPI`: encrypted portable state for saves, preferences, app settings, notifications, blocks, wallet display preferences, and rewards.
- `PrivateEventVaultAPI`: richer private behavior under purpose-bound access controls.
- `FanInterestProfileAPI`: read/update explicit interests, inferred interests, disliked interests, liked/disliked creators, muted providers, source, confidence, and recency.
- `FanAdPreferencesAPI`: fan-owned ad preference settings, blocked ad categories, blocked sponsors, and default creator data-sharing stance.
- `FanInterestSignal`: like, dislike, not interested, flag, save, tile selected, follow, unfollow, mute creator, block creator, and mute provider event.
- `InterestToken`: normalized topic, creator, format, product, sport, genre, or community token used for ranking.
- `DislikedInterestToken`: strong negative signal that suppresses matching candidates unless the fan temporarily overrides it.
- `DislikedCreatorRecord`: creator-level suppression signal distinct from unfollow, mute, and block.
- `MutedRecommendationProviderRecord`: fan-owned suppression of external recommendation providers.
- `VaultAccessGrant`: app/provider permission to access specific vault scopes.
- `VaultExportAPI`: export portable vault state.
- `VaultDeleteAPI`: delete or revoke fan state.
- `VaultServiceReceipt`: utility-funding receipt for vault operation.

#### Creator audience vault systems

- `CreatorAudienceAPI`: creator-scoped audience records, member/follower state, follow visibility state, direct contact grants, block state, tombstone status, and campaign participation.
- `AudienceDataGrantRequestAPI`: creator-side request lifecycle for interest, like, dislike, and ad-preference access.
- `PermissionedAudienceInterestDataAPI`: creator-side query path for granted interest/ad-preference fields and aggregate counts.
- `AudienceSegmentAPI`: creator-controlled segments for campaigns and communication.
- `CampaignDataGrant`: fan-granted data for a specific creator campaign.
- `CreatorCRMExportAPI`: export only permissioned creator audience data where `DirectContactGrant`, `FollowVisibilityPolicy`, `CreatorAudienceExportPolicy`, access history, revocation state, and retention rules allow it.
- `AudienceAnalyticsAPI`: aggregate audience insights and creator-scoped activity.
- `AudienceDataFirewallPolicy`: boundaries among fan private data, creator-scoped audience data, and provider processing rights.

#### Consent and data systems

- `DataUseGrant`: purpose-bound data access.
- `DataAccessReceipt`: audit record of data access.
- `CampaignDataGrant`: data-for-value campaign permission.
- `DerivedInterestTokenAPI`: privacy-preserving ad or recommendation signals.
- `PrivateRankingAPI`: in-vault recommendation ranking.
- `FanAIMemoryPolicy`: memory, retention, training, ad-use, and delete rules.

#### App and provider integration

- `FanAppLoginSDK`: Fan Passport authentication and permission requests.
- `EntitlementCheckSDK`: app-side access enforcement.
- `ProviderCapabilityRegistry`: identity, wallet, vault, and app provider certifications.
- `AppAuditAPI`: verifies app permission behavior and data handling.

#### Migration and governance systems

- `FanExportAPI`: identity, vault, permission, and entitlement export.
- `MigrationManifest`: export, migration, rehydration, backup, and privacy terms.
- `MigrationPlanAPI`: planned fan provider or vault switch.
- `MigrationReceipt`: migration execution, failures, cutover, and dispute evidence.
- `FanMigrationRecord`: source, destination, exported scopes, and cutover status.
- Key Revocation: invalidates compromised providers, apps, or devices.
- Dispute Resolution API: identity, payment, entitlement, privacy, export, and revocation disputes.
