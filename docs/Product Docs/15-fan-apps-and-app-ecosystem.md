# Loom Product Definition 15: Fan Apps and App Ecosystem

Status: Draft for review  
Product area: 15 of 22  
Depends on: 03 Fan Experience; 04 Creator Channel and Metadata Architecture; 05 Fan Passport, Wallet, Vaults, and Identity Architecture; 07 Provider Marketplace and Certified APIs; 08 Revenue, Receipts, Ledgers, and Settlement; 10 Creator Plugins / Extensions / Campaign Layer; 12 Creator-Led Recommendation Economy; 13 Neutral Public Search Utility; 14 Audience Data Firewall and Data Rights

## 1. Product Definition

Loom should support many fan apps, not just one official app. Apps can specialize in video, shorts, newsletters, communities, education, privacy, family-safe experiences, AI, verticals, devices, or accessibility. Apps display and enhance the network, but they do not own the creator/fan relationship.

Certified apps must respect Fan Passport identity, wallet entitlements, creator manifests, search neutrality, recommendation disclosures, receipts, extension sandboxing, and data permissions.

## 2. Scope

This product area covers:

- Official and third-party Fan Apps.
- Certified app program.
- App permission grants.
- Fan Passport login.
- Fan Wallet and entitlement integration.
- Content playback and rendering.
- Public search integration.
- Creator-led recommendation integration.
- Extension runtime support.
- Usage receipt generation.
- Data mode settings.
- App-specific premium features.
- App audits and certification.

## 3. Key Features and Differentiators

| Feature / differentiator | Definition | Product value | Interacting product areas |
| --- | --- | --- | --- |
| Multiple certified apps | Fans can choose apps without losing identity or entitlements. | Competition on UX instead of lock-in. | Fan Passport, Wallet, Vaults, and Identity Architecture |
| App permission grants | Apps request scoped access. | Fans control app data access. | Audience Data Firewall and Data Rights |
| Relationship privacy controls | Apps must expose follow visibility, direct-contact revocation, unfollow, block, and creator-scoped deletion controls. | Fans can use any certified app without losing privacy protections. | Fan Experience; Fan Passport, Wallet, Vaults, and Identity Architecture |
| Manifest enforcement | Apps enforce content, monetization, search, AI, and extension rules. | Creator rules travel across apps. | Creator Channel and Metadata Architecture |
| Receipt generation | Apps generate usage and interaction receipts where required. | Settlement and audit remain consistent. | Revenue, Receipts, Ledgers, and Settlement |
| Extension rendering | Apps safely render certified creator extensions. | Creator customization works across apps. | Creator Plugins / Extensions / Campaign Layer |
| App specialization | Apps compete on privacy, verticals, AI, devices, accessibility, and feed design. | Fans get better experiences. | Business Model and Incentive Design |
| Certified app audits | Apps are tested for API, privacy, entitlement, and receipt behavior. | Prevents app-level lock-in or data abuse. | Governance, Certification, and Foundation Model |

## 4. Product Experience Requirements

Fans should:

- Sign in with Fan Passport.
- Grant only needed app permissions.
- See followed creators and entitlements.
- Set follow visibility and revoke creator direct-contact permission.
- Unfollow, block, or request creator-scoped tombstoning without changing apps.
- Search and receive recommendations according to Loom rules.
- Manage wallet and privacy.
- Revoke an app without losing portable state.

Creators should:

- Trust certified apps to respect channel manifests.
- See app-generated usage receipts.
- Know which apps support their content types and extensions.

App developers should:

- Build with SDKs and conformance tests.
- Request permissions clearly.
- Access standard APIs.
- Submit for certification.
- Monetize app-specific features without capturing creator/fan identity.

## 5. User Stories

### Story 1: Fan switches apps

As a fan, I want to use a different app while keeping follows, memberships, and saves.

End state:

- Fan signs in with Fan Passport.
- App receives scoped grant.
- Portable state appears.

### Story 2: App renders creator channel

As an app developer, I want to render creator channels using standard manifests.

End state:

- App reads public catalog and content manifests.
- Entitlements and access rules are enforced.

### Story 3: App supports privacy-first mode

As a fan, I want a privacy-focused app that uses private ranking and minimal data access.

End state:

- App requests minimal scopes.
- Private Event Vault and `PrivateRankingAPI` are used.

### Story 4: App loads certified extension

As a fan app, I want to render creator extensions safely.

End state:

- Extension artifact and certification are verified.
- Runtime enforces scopes.

### Story 5: App fails certification

As governance, I want to limit apps that misuse data or ignore manifests.

End state:

- App certification state changes.
- Fan access is limited or revoked where needed.
- Users are notified.

## 6. End-to-End Workflows

### Workflow 1: App login and permission grant

Actors:

- Fan
- Fan App
- Fan Passport Ledger
- Core Fan Vault
- ConsentGrantAPI

Steps:

1. Fan opens app.
2. App requests Fan Passport login.
3. App declares requested scopes.
4. Fan reviews and approves.
5. `ConsentGrantAPI` records app grant and `DataUseGrant` records purpose, duration, vault scopes, destination, and revocation behavior.
6. App reads permitted follows, preferences, and entitlements from `CoreFanVaultAPI`, applying `FollowVisibilityPolicy` and `SensitiveRelationshipDefaultPolicy`.
7. Any Private Event Vault access requires explicit scope through `PrivateEventVaultAPI`.
8. `DataAccessReceipt` records grant-protected private data access.
9. App surfaces system controls for changing follow visibility, unfollowing, blocking, revoking `DirectContactGrant`, and requesting creator-scoped tombstoning.
10. Fan can revoke future app access without losing portable state.

### Workflow 1A: Certified app relationship controls

Actors:

- Fan
- Fan App
- Fan Passport Ledger
- Core Fan Vault
- Creator Audience Vault
- Audience Data Firewall

Steps:

1. Fan opens relationship settings in any certified app.
2. App renders current follow state, `FollowVisibilityPolicy`, notification preferences, `DirectContactGrant`, and block/tombstone status.
3. Fan changes visibility, revokes direct contact, unfollows, blocks, or requests creator-scoped deletion.
4. App writes relationship changes through `FollowRelationshipAPI` and grant changes through `ConsentGrantAPI`.
5. `CreatorRelationshipActionRecord` records the lifecycle event.
6. `AudienceDataFirewallPolicy` recalculates app, creator, sponsor, extension, and export access.
7. `CreatorAudienceAPI`, `CreatorCRMExportAPI`, and `CreatorAudienceExportPolicy` prevent restricted relationship state from reappearing through other apps or exports.
8. App updates local UI and portable state without keeping an app-owned shadow relationship graph.

### Workflow 2: Content rendering and playback

Actors:

- Fan App
- Creator Metadata Host
- Content Host
- Entitlement Ledger
- Receipt Ledger

Steps:

1. App resolves creator channel.
2. App reads public catalog and enforces `CreatorChannelManifest`, `ContentManifest`, `MonetizationManifest`, `HostingContractManifest`, `SearchAccessPolicy`, `AIContentPolicy`, `SettlementManifest`, `SafetyPolicyManifest`, and extension install records.
3. App validates manifest versions, signatures, provider keys, and conflict rules.
4. App checks entitlements for restricted content through `EntitlementLedgerAPI`.
5. Missing or invalid required manifests fail closed.
6. App requests playback or content body.
7. App renders content.
8. Typed signed receipts are generated by the responsible app/provider and submitted through `ReceiptIngestAPI` to `ReceiptLedger`.
9. Receipt types include `PlaybackReceipt`, `AdImpressionReceipt`, `PremiumNoAdReceipt`, `DataAccessReceipt`, and extension/campaign receipts where relevant.

### Workflow 3: App search and recommendation

Actors:

- Fan App
- Search Utility
- Fan Scoped Recommendation Engine
- Fan

Steps:

1. App exposes search and recommendation surfaces.
2. Search uses `SearchDirectory`, `HostPublicSearchAPI`, `PublicSearchResultSchema`, `OpenSearchKernel`, and `OpenSearchKernelConformance`.
3. App applies `NeutralSearchMergePolicy`; app premium features cannot influence neutral public search ordering.
4. Search creates `SearchReceipt` for audit/utility funding only and never paid ranking, search ads, per-click monetization, or ordering advantage.
5. Recommendations fetch `RecommendationManifestAPI` records from followed/trusted creators, optional `CommunityFeedAPI` candidates, and fan-initiated search-result candidates.
6. `FanScopedRecommendationAPI` applies `FanRecommendationSettings`, privacy mode, and trusted-candidate boundaries.
7. App displays disclosures, source, funding/referral labels, and why-shown context.
8. Fan feedback updates settings through `RecommendationFeedbackAPI`.
9. Qualified discovery or conversion can create `DiscoveryReceipt` or `CreatorReferralReceipt`.

### Workflow 4: Extension rendering

Actors:

- Fan App
- Extension Runtime
- Extension Registry
- Creator Metadata Host
- Fan

Steps:

1. App reads creator extension install record.
2. App resolves `ExtensionManifest` and artifact through `ExtensionArtifactAPI` from a certified Extension Artifact Host.
3. App verifies artifact signature, manifest-version match, certification scope, and revocation status.
4. `ExtensionRuntimeGateway` fails closed when artifact, certification, manifest, or signature checks fail.
5. Runtime enforces `ExtensionPermissionGrant`, `CampaignDataGrant`, `DataUseGrant`, and sandbox limits.
6. Fan interacts with extension.
7. `DataAccessReceipt`, campaign receipts, reward receipts, and sponsor receipts are generated where relevant.

### Workflow 5: App certification

Actors:

- App Developer
- Developer Console
- App Certification System
- Governance Admin

Steps:

1. Developer submits `AppCapabilityManifest` with supported surfaces, API versions, data use, devices, extension runtime, and receipt behavior.
2. `AppCertificationAPI` runs `AppConformanceTestSuite` for login, `AppPermissionGrant`, data grants, entitlement checks, manifest enforcement, receipt generation, search neutrality, recommendation boundaries, and extension sandboxing.
3. App signing keys and API-version scope are validated.
4. Governance reviews higher-risk data access.
5. `CertificationScopeRecord` is recorded with certification state and approved capabilities.
6. `AppMarketplaceListing` appears.
7. `AppAuditAPI` and continuous probes monitor behavior.
8. Suspension or revocation triggers app key changes, notices, and `AppRevocationWorkflow`.

## 7. Cross-Area Interactions

- Fan Experience: apps are the main fan surface for `FollowRelationshipAPI`, `PlaybackReceipt`, wallet, privacy, search, recommendations, campaigns, and AI.
- Fan Passport, Wallet, Vaults, and Identity Architecture: apps authenticate with `FanAppLoginSDK` and request access through `AppPermissionGrant`.
- Creator Channel and Metadata Architecture: apps read and enforce `CreatorChannelManifest`, `ContentManifest`, `MonetizationManifest`, and policy manifests.
- Provider Marketplace and Certified APIs: apps rely on certified providers plus `AppCertificationAPI`, `AppCapabilityManifest`, and `CertificationScopeRecord`.
- Revenue, Receipts, Ledgers, and Settlement: typed `PlaybackReceipt`, `SearchReceipt`, `DiscoveryReceipt`, `DataAccessReceipt`, and campaign receipts feed settlement and audits.
- Neutral Public Search Utility: apps must apply `NeutralSearchMergePolicy`, use `PublicSearchResultSchema`, and generate audit-only `SearchReceipt`.
- Creator-Led Recommendation Economy: apps rank `RecommendationManifest` and `CommunityFeedAPI` candidates through `FanScopedRecommendationAPI`.
- Creator Plugins / Extensions / Campaign Layer: apps render extensions through `ExtensionRuntimeGateway` and `ExtensionArtifactAPI`.
- Audience Data Firewall and Data Rights: app data access requires `DataUseGrant`, `AppPermissionGrant`, `FollowVisibilityPolicy`, and `DataAccessReceipt`.
- Trust, Safety, Fraud, and Compliance: `AppAuditAPI`, `AbuseReportAPI`, and `AppRevocationWorkflow` enforce app behavior.

## 8. FAQ

### What key systems and/or capabilities need to be created/implemented or modified to implement the key features, user stories, and end-to-end workflows?

- `FanAppSDK`: identity, wallet, content, search, recommendation, extension, and receipt APIs.
- `AppPermissionGrant`: scoped app access.
- `FollowVisibilityPolicy`: app-rendered creator relationship visibility state that apps must preserve when showing follows, members, recommendations, search context, and creator community surfaces.
- `DirectContactGrant`: fan permission for creator direct-contact use that apps must display, revoke, and honor before enabling CRM export or off-platform contact flows.
- `CreatorRelationshipActionRecord`: lifecycle event generated or surfaced by apps for visibility changes, unfollows, blocks, direct-contact revocations, and creator-scoped deletion requests.
- `CreatorScopedTombstoneRecord`: creator-scoped deletion marker that apps must respect by preventing restricted relationship data rehydration.
- `SensitiveRelationshipDefaultPolicy`: stricter defaults that apps must apply before allowing broad creator visibility or direct-contact grants.
- `CreatorAudienceExportPolicy`: export and destination constraints that apps must honor before enabling creator CRM export, extension sync, or sponsor-linked contact flows.
- `DataUseGrant`: app purpose, duration, vault scope, and destination permission.
- `DataAccessReceipt`: audit record for grant-protected private data access.
- `CoreFanVaultAPI`: portable follows, preferences, saves, and lightweight fan state.
- `PrivateEventVaultAPI`: private behavior access under strict scopes.
- `AppCapabilityManifest`: supported surfaces, data use, devices, extension runtime, and API versions.
- `AppCertificationAPI`: certification submission and status.
- `CertificationScopeRecord`: certified app capabilities, API versions, signing keys, and lifecycle state.
- `AppConformanceTestSuite`: login, permissions, entitlement checks, manifest enforcement, receipt generation, search neutrality, recommendation boundaries, and extension sandboxing.
- `FanPassportLoginSDK`: authentication and persona support.
- `EntitlementCheckSDK`: wallet/ledger access enforcement.
- `EntitlementLedgerAPI`: membership, purchase, premium, and content access checks.
- `ReceiptIngestAPI`: receipt validation and ledger submission.
- `ReceiptLedger`: immutable store for app/provider generated receipts.
- `SearchDirectory`: certified search routing.
- `HostPublicSearchAPI`: host-local search.
- `PublicSearchResultSchema`: standard signed search result.
- `OpenSearchKernel`: reference neutral host search.
- `OpenSearchKernelConformance`: neutral search test suite.
- `SearchReceipt`: audit/utility funding receipt, never paid-ranking input.
- `RecommendationManifestAPI`: creator-authored recommendation source.
- `CommunityFeedAPI`: optional community recommendation candidates.
- `FanScopedRecommendationAPI`: fan-scoped ranking over trusted candidates.
- `FanRecommendationSettings`: fan recommendation controls.
- `DiscoveryReceipt`: recommendation-driven discovery evidence.
- `CreatorReferralReceipt`: eligible referral event.
- `ExtensionManifest`: extension metadata and permissions.
- `ExtensionArtifactAPI`: certified extension artifact retrieval.
- `ExtensionRuntimeGateway`: fail-closed extension runtime enforcement.
- `ExtensionPermissionGrant`: extension permission grant.
- `CampaignDataGrant`: campaign-specific data grant.
- `ExtensionRuntimeSDK`: safe extension rendering.
- `AppAuditAPI`: privacy, data access, receipt, manifest, search, recommendation, and extension behavior checks.
- `AppMarketplaceListing`: certified apps and specialization.
- `AppRevocationWorkflow`: fan and governance revocation of app access.
