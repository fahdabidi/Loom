# Loom Architecture 02: Workflow Inventory And Function Map

Status: Draft for review  
Source: all markdown files in `docs/Product Docs`

## 1. Purpose

This document enumerates the workflows defined across the product definition set and organizes them into the architecture document set that will define transaction packet models.

Workflow references use this format:

`PP/WN`: product document number `PP`, workflow `WN`.

Example: `05/W2` means Product Definition 05, Workflow 2.

## 2. Architecture Document Set

| Architecture doc | Major function | Packet-model status |
| --- | --- | --- |
| `01-overall-system-architecture.md` | Overall system architecture and Core Thesis workflows | Complete draft |
| `03-identity-fan-data-wallets-and-fan-app-shell.md` | Identity, Fan Passport, follows, vaults, grants, wallet, data rights, and fan app shell flows | Complete draft |
| `04-creator-tools-and-channel-metadata.md` | Creator Studio, creator channel identity, metadata, manifests, publishing, creator audience tools, and creator business controls | Complete draft |
| `05-content-hosting-playback-monetization-and-settlement.md` | Hosting, playback, ad/no-ad, monetization, receipts, settlement, payments, entitlements, and economic statements | Complete draft |
| `06-provider-certification-governance-and-developer-supply-chain.md` | Provider marketplace, certification, app/extension/provider governance, developer tools, conformance, API versioning, keys, and audits | Complete draft |
| `07-search-recommendations-and-ai.md` | Neutral search, creator-led recommendations, fan-scoped ranking, AI archive Q&A, AI tools, source attribution, and AI provider certification | Complete draft |
| `08-extensions-campaigns-and-sponsor-tools.md` | Extensions, campaigns, brand/sponsor tools, reward flows, sponsor reporting, and sponsor data boundaries | Complete draft |
| `09-trust-safety-fraud-and-compliance.md` | Abuse reports, invalid traffic, takedowns, campaign compliance, privacy misuse, incidents, fraud, and enforcement | Complete draft |
| `10-migration-export-and-portability.md` | Creator/fan/provider migration, exports, imports, external platform migration, metadata host migration, media export, and extension state export | Complete draft |
| `11-business-model-and-incentive-architecture.md` | Utility funding, platform economics, provider economics, developer revenue, sponsor economics, referral economics, and liability | Complete draft |
| `12-mvp-prototype-transaction-slices.md` | Prototype slice workflows and implementation order | Complete draft |

## 3. Functional Workflow Map

### 3.1 Overall System Architecture

Implemented in `01-overall-system-architecture.md`.

- `01/W1`: Creator onboarding and first publish.
- `01/W2`: Fan onboarding, follow, and cross-app portability.
- `01/W3`: Provider certification and marketplace listing.
- `01/W4`: Monetized playback and settlement.
- `01/W5`: Creator-led recommendation and referral settlement.
- `01/W6`: Extension-powered sponsor campaign with data grant.
- `01/W7`: Fan search and AI-assisted discovery.
- `01/W8`: Creator migration to a new provider.

### 3.2 Identity, Fan Data, Wallets, And Fan App Shell

Primary packet doc: `03-identity-fan-data-wallets-and-fan-app-shell.md`.

- `03/W1`: Fan onboarding and first follow.
- `03/W1A`: Fan revokes or limits creator relationship data.
- `03/W4`: Membership purchase and access.
- `03/W7`: Fan revokes app or campaign access.
- `03/W8`: Cross-app switch.
- `03/W10`: Premium private data mode.
- `03/W12`: Multi-format creator engagement.
- `03/W13`: Wallet support allocation and boosts.
- `05/W1`: Fan Passport creation.
- `05/W2`: Follow creator with pairwise identity.
- `05/W3`: Wallet purchase and entitlement.
- `05/W4`: App permission grant and revoke.
- `05/W5`: Private event storage and AI memory.
- `05/W6`: Campaign data grant.
- `05/W7`: Fan export or migration.
- `14/W1`: App data grant.
- `14/W2`: Creator analytics.
- `14/W2A`: Creator relationship visibility and revocation.
- `14/W2B`: Creator CRM export and direct-contact gating.
- `14/W3`: Campaign data grant.
- `14/W4`: Data mode selection and premium private mode.
- `14/W5`: Data export/delete.
- `15/W1`: App login and permission grant.
- `15/W1A`: Certified app relationship controls.
- `15/W2`: Content rendering and playback.
- `15/W3`: App search and recommendation.
- `15/W4`: Extension rendering.

### 3.3 Creator Tools And Channel Metadata

Primary packet doc: `04-creator-tools-and-channel-metadata.md`.

- `02/W1`: Creator onboarding to first publish.
- `02/W2`: Membership launch.
- `02/W2A`: Creator audience export and direct contact.
- `02/W7`: Creator enables AI archive Q&A.
- `04/W1`: Channel creation.
- `04/W2`: Publish content metadata.
- `04/W3`: Update channel business rules.
- `04/W4`: Multi-provider channel operation.
- `04/W6`: Manifest conflict or invalid update.
- `04/W7`: Metadata host key rotation or recovery.

### 3.4 Content Hosting, Playback, Monetization, Receipts, And Settlement

Primary packet doc: `05-content-hosting-playback-monetization-and-settlement.md`.

- `02/W1A`: Free managed hosting setup.
- `02/W5`: Provider upgrade or unbundling.
- `03/W2`: Free ad-supported playback.
- `03/W3`: Premium no-ad playback.
- `06/W1`: Free managed hosting onboarding.
- `06/W2`: Hosting upgrade simulation.
- `06/W3`: Upgrade from free managed to direct paid.
- `06/W4`: Unbundle ad provider.
- `06/W6`: Self-host certification.
- `06/W7`: Hosting downgrade or rollback.
- `08/W1`: Receipt generation and ingestion.
- `08/W2`: Monthly creator settlement.
- `08/W3`: Premium no-ad allocation.
- `08/W3A`: Payment, entitlement, refund, and chargeback.
- `08/W4`: AI source royalty settlement.
- `08/W5`: Campaign settlement.
- `08/W6`: Dispute and adjustment.
- `09/W1`: Configure monetization for content.
- `09/W2`: Free ad-supported revenue.
- `09/W3`: Membership monetization.
- `09/W3A`: Global no-ad premium.
- `09/W3B`: Paid private mode.
- `09/W3C`: Paid content, events, courses, bundles, gifts, and commerce.
- `09/W4`: AI source royalty.
- `09/W5`: Sponsor campaign monetization.
- `09/W6`: Referral monetization.

### 3.5 Provider Certification, Governance, And Developer Supply Chain

Primary packet doc: `06-provider-certification-governance-and-developer-supply-chain.md`.

- `07/W1`: Provider registration and certification.
- `07/W2`: Creator selects a provider.
- `07/W3`: App discovers provider capabilities.
- `07/W4`: Continuous provider audit.
- `07/W5`: Provider version migration.
- `15/W5`: App certification.
- `16/W1`: Extension development.
- `16/W2`: Provider certification.
- `16/W3`: Fan app development.
- `16/W4`: API version upgrade.
- `16/W5`: Supply chain incident.
- `19/W1`: Capability certification.
- `19/W2`: Continuous audit.
- `19/W3`: Dispute resolution.
- `19/W4`: API version governance.
- `19/W5`: Key revocation.
- `19/W6`: Privacy and data-rights governance.
- `19/W7`: Utility fee governance.

### 3.6 Search, Recommendations, And AI

Primary packet doc: `07-search-recommendations-and-ai.md`.

- `02/W4`: Recommendation and referral.
- `03/W5`: Search and AI-assisted discovery.
- `03/W9`: Fan receives creator-led recommendations.
- `03/W11`: Fan AI archive Q&A.
- `11/W1`: Creator enables AI archive Q&A.
- `11/W2`: Fan AI search.
- `11/W3`: Creator AI copilot for publishing.
- `11/W4`: AI recommendation workbench.
- `11/W5`: Private in-vault recommendation assistant.
- `11/W6`: AI provider certification and audit.
- `11/W7`: Creator revokes AI indexing or source access.
- `11/W8`: AI translation, dubbing, or clipping.
- `12/W1`: Destination creator publishes referral terms.
- `12/W2`: Source creator publishes recommendation.
- `12/W3`: Fan receives trusted recommendation.
- `12/W4`: Referral settlement.
- `12/W5`: Community feed subscription.
- `12/W6`: Recommendation abuse review.
- `13/W1`: Public search query.
- `13/W2`: Creator sets search policy.
- `13/W3`: Host search certification.
- `13/W4`: Fan AI search assistant.
- `13/W5`: Search audit probe.

### 3.7 Extensions, Campaigns, And Sponsor Tools

Primary packet doc: `08-extensions-campaigns-and-sponsor-tools.md`.

- `02/W3`: Extension-powered campaign.
- `03/W6`: Campaign participation and reward.
- `10/W1`: Developer publishes extension.
- `10/W2`: Creator installs extension.
- `10/W3`: Fan participates in campaign extension.
- `10/W3A`: CRM or direct-contact extension access.
- `10/W4`: Sponsor campaign execution.
- `10/W5`: Extension suspension.
- `10/W6`: Extension state export.
- `18/W1`: Sponsor campaign setup.
- `18/W2`: Fan campaign participation.
- `18/W2A`: Sponsor request for audience data is narrowed or denied.
- `18/W3`: Sponsor reporting and settlement.
- `18/W4`: Sponsor-free premium variant.

### 3.8 Trust, Safety, Fraud, And Compliance

Primary packet doc: `09-trust-safety-fraud-and-compliance.md`.

- `17/W1`: Abuse report.
- `17/W2`: Invalid traffic adjustment.
- `17/W3`: Takedown and appeal.
- `17/W4`: Provider incident.
- `17/W5`: Campaign compliance enforcement.
- `17/W6`: Privacy and data-misuse enforcement.
- `17/W6A`: Creator audience misuse report.
- `17/W7`: AI safety and source misuse.

### 3.9 Migration, Export, And Portability

Primary packet doc: `10-migration-export-and-portability.md`.

- `02/W6`: Creator export and migration.
- `04/W5`: Metadata host migration.
- `05/W7`: Fan export or migration.
- `06/W5`: Media export and host migration.
- `10/W6`: Extension state export.
- `14/W5`: Data export/delete.
- `21/W1`: Existing creator starts owned hub.
- `21/W2`: Public metadata import.
- `21/W3`: Membership migration.
- `21/W4`: Cross-post and exclusive migration.
- `21/W5`: Provider exit button.

Some migration/export workflows also appear in their domain packet docs. The migration architecture doc defines the cross-cutting cutover, export inventory, receipt, and dispute model.

### 3.10 Business Model And Incentive Architecture

Primary packet doc: `11-business-model-and-incentive-architecture.md`.

- `22/W1`: Free managed hosting revenue share.
- `22/W2`: Direct paid hosting economics.
- `22/W3`: Utility fee allocation.
- `22/W4`: Developer extension revenue.
- `22/W5`: Sponsor campaign economics.
- `22/W6`: Referral economics.
- `22/W7`: Payment and settlement liability.

The business model architecture doc cites settlement, sponsor, provider, and extension packet docs where the operational flow is already covered.

### 3.11 MVP Prototype Transaction Slices

Primary packet doc: `12-mvp-prototype-transaction-slices.md`.

- `20/W1`: Creator onboarding to public content.
- `20/W2`: Fan follow and playback.
- `20/W3`: Search and recommendation.
- `20/W4`: Extension campaign.
- `20/W5`: AI summary.

## 4. Full Workflow Enumeration By Source Product Doc

### 01 Core Thesis And Platform Principles

- `01/W1`: Creator onboarding and first publish.
- `01/W2`: Fan onboarding, follow, and cross-app portability.
- `01/W3`: Provider certification and marketplace listing.
- `01/W4`: Monetized playback and settlement.
- `01/W5`: Creator-led recommendation and referral settlement.
- `01/W6`: Extension-powered sponsor campaign with data grant.
- `01/W7`: Fan search and AI-assisted discovery.
- `01/W8`: Creator migration to a new provider.

### 02 Creator Experience

- `02/W1`: Creator onboarding to first publish.
- `02/W1A`: Free managed hosting setup.
- `02/W2`: Membership launch.
- `02/W2A`: Creator audience export and direct contact.
- `02/W3`: Extension-powered campaign.
- `02/W4`: Recommendation and referral.
- `02/W5`: Provider upgrade or unbundling.
- `02/W6`: Creator export and migration.
- `02/W7`: Creator enables AI archive Q&A.

### 03 Fan Experience

- `03/W1`: Fan onboarding and first follow.
- `03/W1A`: Fan revokes or limits creator relationship data.
- `03/W2`: Free ad-supported playback.
- `03/W3`: Premium no-ad playback.
- `03/W4`: Membership purchase and access.
- `03/W5`: Search and AI-assisted discovery.
- `03/W6`: Campaign participation and reward.
- `03/W7`: Fan revokes app or campaign access.
- `03/W8`: Cross-app switch.
- `03/W9`: Fan receives creator-led recommendations.
- `03/W10`: Premium private data mode.
- `03/W11`: Fan AI archive Q&A.
- `03/W12`: Multi-format creator engagement.
- `03/W13`: Wallet support allocation and boosts.

### 04 Creator Channel And Metadata Architecture

- `04/W1`: Channel creation.
- `04/W2`: Publish content metadata.
- `04/W3`: Update channel business rules.
- `04/W4`: Multi-provider channel operation.
- `04/W5`: Metadata host migration.
- `04/W6`: Manifest conflict or invalid update.
- `04/W7`: Metadata host key rotation or recovery.

### 05 Fan Passport, Wallet, Vaults, And Identity Architecture

- `05/W1`: Fan Passport creation.
- `05/W2`: Follow creator with pairwise identity.
- `05/W3`: Wallet purchase and entitlement.
- `05/W4`: App permission grant and revoke.
- `05/W5`: Private event storage and AI memory.
- `05/W6`: Campaign data grant.
- `05/W7`: Fan export or migration.

### 06 Hosting Provider Lifecycle And Progressive Unbundling

- `06/W1`: Free managed hosting onboarding.
- `06/W2`: Hosting upgrade simulation.
- `06/W3`: Upgrade from free managed to direct paid.
- `06/W4`: Unbundle ad provider.
- `06/W5`: Media export and host migration.
- `06/W6`: Self-host certification.
- `06/W7`: Hosting downgrade or rollback.

### 07 Provider Marketplace And Certified APIs

- `07/W1`: Provider registration and certification.
- `07/W2`: Creator selects a provider.
- `07/W3`: App discovers provider capabilities.
- `07/W4`: Continuous provider audit.
- `07/W5`: Provider version migration.

### 08 Revenue, Receipts, Ledgers, And Settlement

- `08/W1`: Receipt generation and ingestion.
- `08/W2`: Monthly creator settlement.
- `08/W3`: Premium no-ad allocation.
- `08/W3A`: Payment, entitlement, refund, and chargeback.
- `08/W4`: AI source royalty settlement.
- `08/W5`: Campaign settlement.
- `08/W6`: Dispute and adjustment.

### 09 Monetization Models

- `09/W1`: Configure monetization for content.
- `09/W2`: Free ad-supported revenue.
- `09/W3`: Membership monetization.
- `09/W3A`: Global no-ad premium.
- `09/W3B`: Paid private mode.
- `09/W3C`: Paid content, events, courses, bundles, gifts, and commerce.
- `09/W4`: AI source royalty.
- `09/W5`: Sponsor campaign monetization.
- `09/W6`: Referral monetization.

### 10 Creator Plugins / Extensions / Campaign Layer

- `10/W1`: Developer publishes extension.
- `10/W2`: Creator installs extension.
- `10/W3`: Fan participates in campaign extension.
- `10/W3A`: CRM or direct-contact extension access.
- `10/W4`: Sponsor campaign execution.
- `10/W5`: Extension suspension.
- `10/W6`: Extension state export.

### 11 AI Layer

- `11/W1`: Creator enables AI archive Q&A.
- `11/W2`: Fan AI search.
- `11/W3`: Creator AI copilot for publishing.
- `11/W4`: AI recommendation workbench.
- `11/W5`: Private in-vault recommendation assistant.
- `11/W6`: AI provider certification and audit.
- `11/W7`: Creator revokes AI indexing or source access.
- `11/W8`: AI translation, dubbing, or clipping.

### 12 Creator-Led Recommendation Economy

- `12/W1`: Destination creator publishes referral terms.
- `12/W2`: Source creator publishes recommendation.
- `12/W3`: Fan receives trusted recommendation.
- `12/W4`: Referral settlement.
- `12/W5`: Community feed subscription.
- `12/W6`: Recommendation abuse review.

### 13 Neutral Public Search Utility

- `13/W1`: Public search query.
- `13/W2`: Creator sets search policy.
- `13/W3`: Host search certification.
- `13/W4`: Fan AI search assistant.
- `13/W5`: Search audit probe.

### 14 Audience Data Firewall And Data Rights

- `14/W1`: App data grant.
- `14/W2`: Creator analytics.
- `14/W2A`: Creator relationship visibility and revocation.
- `14/W2B`: Creator CRM export and direct-contact gating.
- `14/W3`: Campaign data grant.
- `14/W4`: Data mode selection and premium private mode.
- `14/W5`: Data export/delete.

### 15 Fan Apps And App Ecosystem

- `15/W1`: App login and permission grant.
- `15/W1A`: Certified app relationship controls.
- `15/W2`: Content rendering and playback.
- `15/W3`: App search and recommendation.
- `15/W4`: Extension rendering.
- `15/W5`: App certification.

### 16 Developer Ecosystem And DevOps Supply Chain

- `16/W1`: Extension development.
- `16/W2`: Provider certification.
- `16/W3`: Fan app development.
- `16/W4`: API version upgrade.
- `16/W5`: Supply chain incident.

### 17 Trust, Safety, Fraud, And Compliance

- `17/W1`: Abuse report.
- `17/W2`: Invalid traffic adjustment.
- `17/W3`: Takedown and appeal.
- `17/W4`: Provider incident.
- `17/W5`: Campaign compliance enforcement.
- `17/W6`: Privacy and data-misuse enforcement.
- `17/W6A`: Creator audience misuse report.
- `17/W7`: AI safety and source misuse.

### 18 Brand/Sponsor/Advertiser Tools

- `18/W1`: Sponsor campaign setup.
- `18/W2`: Fan campaign participation.
- `18/W2A`: Sponsor request for audience data is narrowed or denied.
- `18/W3`: Sponsor reporting and settlement.
- `18/W4`: Sponsor-free premium variant.

### 19 Governance, Certification, And Foundation Model

- `19/W1`: Capability certification.
- `19/W2`: Continuous audit.
- `19/W3`: Dispute resolution.
- `19/W4`: API version governance.
- `19/W5`: Key revocation.
- `19/W6`: Privacy and data-rights governance.
- `19/W7`: Utility fee governance.

### 20 MVP / Prototype Roadmap

- `20/W1`: Creator onboarding to public content.
- `20/W2`: Fan follow and playback.
- `20/W3`: Search and recommendation.
- `20/W4`: Extension campaign.
- `20/W5`: AI summary.

### 21 Migration Strategy From Existing Platforms

- `21/W1`: Existing creator starts owned hub.
- `21/W2`: Public metadata import.
- `21/W3`: Membership migration.
- `21/W4`: Cross-post and exclusive migration.
- `21/W5`: Provider exit button.

### 22 Business Model And Incentive Design

- `22/W1`: Free managed hosting revenue share.
- `22/W2`: Direct paid hosting economics.
- `22/W3`: Utility fee allocation.
- `22/W4`: Developer extension revenue.
- `22/W5`: Sponsor campaign economics.
- `22/W6`: Referral economics.
- `22/W7`: Payment and settlement liability.
