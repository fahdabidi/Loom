# Loom API Surface Inventory

Status: Draft for review

This inventory lists the independently owned OpenAPI surfaces created for the initial Loom API specification set. Workflow packet docs should reference these API contracts rather than defining endpoint contracts inline.

## 1. Identity

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Fan Passport API | `OpenAPI/identity/fan-passport-api.openapi.yaml` | Fan identity, follows, pairwise creator identity, consent grants, creator interest-data grant requests, creator-category permission policies, relationship visibility. | Creator Audience, Creator Metadata, Receipt Ledger |
| Fan Vault API | `OpenAPI/identity/fan-vault-api.openapi.yaml` | Fan-owned vault records, explicit interests, disliked interests, liked/disliked creators, muted providers, ad preferences, private events, memory bundles, vault export. | Fan Passport, Receipt Ledger, AI Gateway, Recommendation and Referral |
| Fan Wallet API | `OpenAPI/identity/fan-wallet-api.openapi.yaml` | Wallet state, payment intents, subscriptions, boosts, refunds. | Fan Passport, Entitlement Ledger, Receipt Ledger, Settlement Engine |

## 2. Creator

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Creator Channel Registry API | `OpenAPI/creator/creator-channel-registry-api.openapi.yaml` | Canonical channel ids, handles, keys, metadata host pointer, provider role grants. | Creator Metadata, Provider Registry, Audit |
| Creator Metadata API | `OpenAPI/creator/creator-metadata-api.openapi.yaml` | Profiles, content manifests with required summaries, business manifests, public catalog projection. | Channel Registry, Content Host, Search, AI Gateway, Settlement |
| Creator Audience API | `OpenAPI/creator/creator-audience-api.openapi.yaml` | Creator-visible audience, segments, analytics, permissioned export/direct contact, creator interest-data grant requests, permissioned audience interest-data queries. | Fan Passport, Fan Vault, Receipt Ledger, Trust and Safety |

## 3. Content And Monetization

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Content Host API | `OpenAPI/content/content-host-api.openapi.yaml` | Media upload, renditions, playback assets, media export, aggregate public content performance metadata. | Creator Metadata, Receipt Ledger, Migration/Export |
| Playback Authorization API | `OpenAPI/content/playback-authorization-api.openapi.yaml` | Playback access decision, playback tokens, ad/no-ad route, completion trigger. | Content Host, Creator Metadata, Entitlement Ledger, Receipt Ledger, Fraud |
| Entitlement Ledger API | `OpenAPI/monetization/entitlement-ledger-api.openapi.yaml` | Signed access rights and entitlement verification. | Fan Wallet, Receipt Ledger |
| Receipt Ledger API | `OpenAPI/monetization/receipt-ledger-api.openapi.yaml` | Immutable receipt ingestion/query and adjustment receipt chain. | Fraud, Settlement Engine |
| Settlement Engine API | `OpenAPI/monetization/settlement-engine-api.openapi.yaml` | Settlement runs, payout statements, disputes, allocation calculations. | Receipt Ledger, Entitlement Ledger, Creator Metadata, Fraud |

## 4. Discovery And AI

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Search API | `OpenAPI/discovery/search-api.openapi.yaml` | Public search, index updates, search audit probes. | Creator Metadata, Content Host, Provider Registry, Audit |
| Recommendation And Referral API | `OpenAPI/discovery/recommendation-referral-api.openapi.yaml` | Startup content tiles, platform intents, session intents, content scoring explanations, fan content feedback, recommendation mode compatibility, referral terms, creator-led recommendations, recommendation feed, attribution. | Creator Metadata, Content Host, External Recommendation Provider, Fan Passport, Fan Vault, Receipt Ledger, Settlement, Trust and Safety |
| External Recommendation Provider API | `OpenAPI/discovery/external-recommendation-provider-api.openapi.yaml` | Certified provider candidate retrieval under platform intent, fan interest, dislike, quota, and privacy boundaries. | Provider Registry, Content Host, Trust and Safety |
| AI Gateway API | `OpenAPI/discovery/ai-gateway-api.openapi.yaml` | Archive Q&A, AI search assistant, **fan AI search (`runAiSearch`) merging creator + external with agent ranking**, creator copilot, AI indexing jobs. | Creator Metadata, Content Host, Fan Vault, Receipt Ledger, Provider Registry, Trust and Safety, Search, External Content Source |
| External Content Source API | `OpenAPI/discovery/external-content-source-api.openapi.yaml` | Generic external content retrieval (YouTube now; twitch/discord/blog/webpage modeled) + compliant embed descriptors; original title/thumbnail unaltered, additive accurate-match label, source attribution. | Trust and Safety, Receipt Ledger |

## 5. Extensions And Campaigns

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Extension Registry API | `OpenAPI/ecosystem/extension-registry-api.openapi.yaml` | Extension manifests, artifacts, install grants, suspension state. | Certification, Creator Metadata, Audit |
| Extension Runtime API | `OpenAPI/ecosystem/extension-runtime-api.openapi.yaml` | Runtime sessions, extension events, extension state export. | Extension Registry, Fan Passport, Fan Vault, Campaign, Creator Audience, Receipt Ledger |
| Campaign API | `OpenAPI/campaigns/campaign-api.openapi.yaml` | Campaign manifests, participation, rewards, compliance state, fan data grant offers. | Extension Runtime, Fan Passport, Creator Audience, Receipt Ledger, Trust and Safety |
| Sponsor Campaign API | `OpenAPI/campaigns/sponsor-campaign-api.openapi.yaml` | Sponsor proposals, fan-interest field requests, data request narrowing, sponsor reporting. | Campaign, Creator Audience, Fan Passport, Receipt Ledger, Settlement |

> **Wired into the demo for the customization showcase (Phases 15–20):** the existing **Extension Registry API** and **Extension Runtime API** (above) now back creator-customized fan experiences — five gaming creators composing different experiences from six certified extensions (one shared `ExtensionManifest` primitive). No new specs are required; a `CreatorExperienceConfig` (theme, banner, ordered surface modules, installed extensions) is owned by the Creator Metadata API. See [MVP User Stories Scope](../MVP%20Planning/MVP%20User%20Stories%20Scope.md) Part K (CE-S12/CE-S13/FE-S14/FE-S15).

## 6. Ecosystem, Safety, Portability, And Governance

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Provider Registry API | `OpenAPI/ecosystem/provider-registry-api.openapi.yaml` | Provider manifests, certified scopes, capability endpoint discovery, incidents. | Certification, Audit, Governance |
| Certification API | `OpenAPI/ecosystem/certification-api.openapi.yaml` | Certification requests, conformance runs, certification decisions. | Provider Registry, Extension Registry, Audit, Governance |
| Trust And Safety API | `OpenAPI/safety/trust-safety-api.openapi.yaml` | Safety reports, cases, enforcement actions, appeals. | Creator Metadata, Creator Audience, Campaign, AI Gateway, Provider Registry, Receipt Ledger |
| Fraud API | `OpenAPI/safety/fraud-api.openapi.yaml` | Fraud signals, fraud cases, invalid traffic adjustments. | Receipt Ledger, Settlement, Trust and Safety |
| Migration And Export API | `OpenAPI/portability/migration-export-api.openapi.yaml` | Export jobs, import jobs, migration jobs, data deletion jobs. | Channel Registry, Creator Metadata, Content Host, Fan Passport, Fan Vault, Fan Wallet, Extension Runtime, Receipt Ledger |
| Provider Exit API | `OpenAPI/portability/provider-exit-api.openapi.yaml` | Provider exit requests, exit status, blockers. | Migration/Export, Provider Registry, Receipt Ledger |
| Governance API | `OpenAPI/governance/governance-api.openapi.yaml` | API versions, utility fee policy, governance disputes. | Audit, Provider Registry, Certification |
| Audit API | `OpenAPI/governance/audit-api.openapi.yaml` | Audit probes, evidence bundles, remediation plans. | Receipt Ledger, Provider Registry |

## 7. Launch & Growth

Added from the [GTM Launch Gap Analysis](../Go-To-Market/MVP%20Gap%20Analysis%20—%20Launch%20Scope.md) §B to support launch scope (creator audience re-acquisition, one-tap onboarding, conversion analytics). Implemented across [Phase 10](../MVP%20Planning/Phases/Phase%2010%20-%20Launch%20Contracts%20Store%20and%20Fakes.md) through [Phase 14](../MVP%20Planning/Phases/Phase%2014%20-%20UX%20Hardening%20and%20Physical%20Phone%20Validation.md).

| API surface | Spec | Owns | Key downstream APIs |
| --- | --- | --- | --- |
| Creator Announcement API | `OpenAPI/creator/creator-announcement-api.openapi.yaml` | Announcement templates, rendered launch announcements, link-in-bio page (re-acquisition messaging assets). | Fan Follow Capture, Creator Metadata |
| Fan Follow Capture API | `OpenAPI/creator/fan-follow-capture-api.openapi.yaml` | Creator capture links, follow-capture landing, manual re-follow recording (audit-class; no follower import). | Fan Passport, Creator Audience, Audit |
| Starter Pack API | `OpenAPI/discovery/starter-pack-api.openapi.yaml` | One-tap starter packs (source creator + recommended creators) and idempotent bulk follow for onboarding. | Recommendation And Referral, Fan Passport, Creator Metadata |
| Audience Analytics API | `OpenAPI/creator/audience-analytics-api.openapi.yaml` | Aggregate-only conversion (re-acquisition) funnel: reached → re-followed → member → premium. | Fan Passport, Entitlement Ledger, Fan Follow Capture, Creator Audience |
| External Account Link API | `OpenAPI/creator/external-account-link-api.openapi.yaml` | Link/verify/unlink a creator's external platform accounts (provenance for import, cross-post, verified links — not follower import). | Creator Metadata, Import Public Metadata |
| Import Public Metadata API | `OpenAPI/creator/import-public-metadata-api.openapi.yaml` | Async import of public catalog metadata into external content references with rights provenance. | External Account Link, Creator Metadata |
| Cross-Posting API | `OpenAPI/creator/cross-posting-api.openapi.yaml` | Publish announcements/links to linked external platforms with per-target delivery status. | External Account Link, Creator Announcement |
| Premium No-Ad API | `OpenAPI/monetization/premium-no-ad-api.openapi.yaml` | Global no-ad entitlement status + recording qualifying no-ad consumption (economic receipt for settlement). | Entitlement Ledger, Receipt Ledger, Fan Wallet |
| Ad Decision API | `OpenAPI/content/ad-decision-api.openapi.yaml` | Contextual, creator-policy ad selection + impression recording. No behavioral targeting. | Creator Metadata, Receipt Ledger, Fraud |

> **Relationship to Playback Authorization:** Premium No-Ad and Ad Decision formalize the ad/no-ad
> route that Playback Authorization previously owned inline; Playback Authorization delegates to them.
> **CreatorAdPolicy authoring** remains owned by the Creator Metadata API (business manifests); Ad
> Decision only *consumes* the policy at selection time.
