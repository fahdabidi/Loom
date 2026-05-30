# Loom Architecture 08: Extensions, Campaigns, And Sponsor Tools

Status: Draft for review  
Source workflow map: `docs/Architecture/02-workflow-inventory-and-function-map.md`

## 1. Purpose

This document defines transaction packet models for the extension platform, campaign runtime, sponsor campaign setup, data grants, CRM/direct-contact extension access, fan participation, reward settlement, extension suspension, extension state export, sponsor reporting, and sponsor-free premium variants.

## 2. Functional System Diagram

```mermaid
flowchart TB
  Developer[Developer]
  Creator[Creator]
  Sponsor[Sponsor]
  Fan[Fan]
  DevConsole[Developer Console]
  CreatorStudio[Creator Studio]
  SponsorConsole[Sponsor Console]
  FanApp[Fan App]
  ExtRegistry[Extension Registry]
  ExtRuntime[Extension Runtime]
  CampaignAPI[Campaign API]
  SponsorAPI[Sponsor Campaign API]
  ADF[Audience Data Firewall]
  FanVault[Fan Vault]
  CRM[Creator CRM Export API]
  CMH[Creator Metadata Host]
  ReceiptLedger[Receipt Ledger]
  Settlement[Settlement Engine]
  TrustSafety[Trust And Safety]
  ProviderRegistry[Provider Capability Registry]

  Developer --> DevConsole
  Creator --> CreatorStudio
  Sponsor --> SponsorConsole
  Fan --> FanApp
  DevConsole --> ExtRegistry
  CreatorStudio --> ExtRegistry
  CreatorStudio --> CampaignAPI
  SponsorConsole --> SponsorAPI
  SponsorAPI --> CampaignAPI
  CampaignAPI --> ExtRuntime
  FanApp --> ExtRuntime
  ExtRuntime --> ADF
  ADF --> FanVault
  ADF --> CRM
  CampaignAPI --> CMH
  CampaignAPI --> ReceiptLedger
  ReceiptLedger --> Settlement
  SponsorAPI --> ReceiptLedger
  TrustSafety --> CampaignAPI
  TrustSafety --> ExtRegistry
  ProviderRegistry --> ExtRuntime
```

## 3. Packet Envelope

| Field | Meaning |
| --- | --- |
| `extensionContext` | Extension id, developer id, manifest version, artifact version, permissions, surfaces, risk tier, and suspension state. |
| `campaignContext` | Campaign id, creator id, sponsor id, objective, audience, budget, schedule, reward rules, and compliance state. |
| `fanGrantContext` | Fan identity, pairwise creator identity, requested fields, creator interest-data fields, purpose, retention, revocation, ad-use flag, offer context, category defaults, and private-mode state. |
| `sponsorContext` | Sponsor account, brand safety constraints, accepted session intent ad contexts, requested fan-interest fields, reporting scope, invoicing, allowed metrics, and denied data fields. |
| `runtimeContext` | App surface, extension runtime session, sandbox permissions, event id, idempotency key, and provider version. |
| `receiptContext` | Participation, reward, conversion, sponsor spend, developer fee, and settlement receipts. |
| `auditContext` | Artifact attestation, permission grant, data-access receipt, compliance review, suspension, and export evidence. |

## 4. Interfaces And Contracts

| Interface or contract | Packet responsibility |
| --- | --- |
| `ExtensionManifest` | Declares surfaces, requested permissions, data scopes, risk tier, pricing, export behavior, and runtime needs. |
| `ExtensionArtifactAPI` | Stores signed extension bundles, versions, attestations, and rollback targets. |
| `ExtensionInstallGrant` | Creator approval for extension install, surfaces, permissions, and campaign use. |
| `ExtensionRuntimeAPI` | Sandboxed runtime calls between fan apps, extensions, campaign services, and platform APIs. |
| `CampaignManifest` | Creator/sponsor campaign objective, eligibility, data grants, reward rules, schedule, and settlement rules. |
| `SponsorCampaignAPI` | Sponsor setup, approvals, budget, reporting, invoicing, and sponsor-safe metrics. |
| `SessionIntentAdContext` | Platform-intent ad posture, contextual category, creator-approved-only flag, and ad-load/breadth boundary from the current fan session intent; never raw private behavior, raw interest tokens, or dislike records. |
| `AudienceDataFirewallPolicy` | Data minimization, field gating, aggregation thresholds, denial reasons, retention, and revocation. |
| `CampaignDataGrant` | Fan-granted campaign data scope, purpose, expiration, and revocation state. |
| `FanDataGrantOffer` | Data-for-value offer terms, requested fan interest/ad-preference fields, reward/promo value, retention, ad-use flag, and alternate path. |
| `CreatorInterestDataGrant` | Fan-approved creator-scoped grant for interests, likes, dislikes, creator dislikes, muted providers, and ad preferences. |
| `CreatorCategoryPermissionPolicy` | Fan defaults for broad creator categories that campaign and sponsor tools must honor. |
| `FanAdPreferencesAPI` | Fan ad preference settings available to campaign/ad tools only through explicit grants. |
| `PermissionedAudienceInterestDataAPI` | Creator-side query path for approved creator-scoped fan interest/ad-preference fields or aggregate counts. |
| `CreatorCRMExportAPI` | Direct-contact and CRM export path for permissioned audience data. |
| `CampaignParticipationReceipt` | Signed participation, reward, conversion, and spend events. |
| `SponsorReport` | Aggregated campaign performance report with privacy thresholds and settlement reconciliation. |
| `ExtensionSuspensionRecord` | Suspension reason, affected versions, blocked permissions, remediation, and export window. |
| `ExtensionStateExport` | Portable extension state owned by creator/fan and constrained by export policy. |

## 5. Workflow Transaction Packet Models

| Ref | Trigger | Primary packet path | Durable writes / receipts | Completion response |
| --- | --- | --- | --- | --- |
| `02/W3` | Creator launches extension-powered campaign. | Creator Studio -> Extension Registry -> Campaign API -> Fan App runtime. | Install grant, campaign manifest, runtime config. | Campaign is available to fans. |
| `03/W6` | Fan participates in campaign and earns reward. | Fan App -> Extension Runtime -> Campaign API -> Receipt Ledger. | Participation grant, reward receipt. | Fan receives reward or ineligible reason. |
| `10/W1` | Developer publishes extension. | Developer Console -> Extension Registry -> Certification. | Manifest, signed artifact, attestation, listing. | Extension listed or remediation returned. |
| `10/W2` | Creator installs extension. | Creator Studio -> Extension Registry -> permission review -> Metadata Host. | `ExtensionInstallGrant`. | Extension becomes active on approved surfaces. |
| `10/W3` | Fan participates in campaign extension. | Fan App -> Extension Runtime -> Data Firewall -> Campaign API. | Campaign grant, optional creator interest-data grant, participation receipt. | Fan completes campaign step and sees data-use status. |
| `10/W3A` | Extension requests CRM or direct-contact access. | Extension Runtime -> CreatorCRMExportAPI -> Audience Data Firewall. | Data-access receipt or denial. | Access is granted, narrowed, or denied. |
| `10/W4` | Sponsor campaign executes. | Sponsor Console -> SponsorCampaignAPI -> Campaign API -> Fan App. | Sponsor budget, delivery, participation, spend receipts. | Campaign runs and reports aggregate performance. |
| `10/W5` | Extension is suspended. | Trust/Safety -> Extension Registry -> Runtime blocklist. | Suspension record and remediation state. | Extension runtime calls are blocked or limited. |
| `10/W6` | Extension state is exported. | Creator/Fan -> Extension Registry -> Extension Runtime -> export package. | Export receipt and package manifest. | Portable extension state is delivered. |
| `18/W1` | Sponsor sets up campaign. | Sponsor Console -> SponsorCampaignAPI -> Creator approval -> Campaign API. | Campaign proposal, approvals, budget reservation. | Campaign ready for creator or platform approval. |
| `18/W2` | Fan participates in sponsor campaign. | Fan App -> Extension Runtime -> Data Firewall -> Campaign API. | Campaign grant, optional creator interest-data grant, participation, reward receipt. | Fan sees reward and data-use status. |
| `18/W2B` | Fan grants sponsor-linked creator interest data. | Fan App -> `ConsentGrantAPI` -> Audience Data Firewall -> `PermissionedAudienceInterestDataAPI`. | `CreatorInterestDataGrant`, data-access receipt, category policy update if selected. | Creator/sponsor tooling receives approved fields, aggregate counts, or denial. |
| `18/W2A` | Sponsor asks for too much audience data. | SponsorCampaignAPI -> Audience Data Firewall -> Creator/Sponsor response. | Denial or narrowed scope record. | Sponsor receives approved aggregate or denial reason. |
| `18/W3` | Sponsor reporting and settlement. | SponsorCampaignAPI -> Receipt Ledger -> Settlement Engine. | Spend, reward, developer, creator, and sponsor reports. | Statements and invoices are produced. |
| `18/W4` | Fan chooses sponsor-free premium variant. | Fan App -> Fan Wallet -> Campaign API/ad decision. | Premium entitlement and no-sponsor delivery state. | Sponsor campaign is suppressed for that fan. |

## 6. Step-By-Step Life Of A Packet Overlays

### 6.1 `02/W3`: Extension-Powered Campaign

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Registry as Extension Registry
  participant Campaign as Campaign API
  participant CMH as Metadata Host
  participant Runtime as Extension Runtime

  Creator->>Studio: Configure campaign with extension
  Studio->>Registry: Verify extension version and permissions
  Registry-->>Studio: Certified manifest and risk tier
  Studio->>Campaign: Create CampaignManifest
  Campaign->>CMH: Publish campaign metadata
  Campaign->>Runtime: Activate runtime config
  Studio-->>Creator: Campaign ready
```

1. Creator Studio composes the campaign objective, surfaces, schedule, reward rules, and extension version.
2. `ExtensionRegistry` validates certification, suspension state, permission scopes, and risk tier.
3. `CampaignAPI` writes the campaign manifest and connects it to creator metadata.
4. `ExtensionRuntimeAPI` receives sandbox configuration for the approved app surfaces.
5. Fan apps discover the campaign through channel metadata and render the extension surface.

### 6.2 `03/W6`: Campaign Participation And Reward

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Runtime as Extension Runtime
  participant ADF as Audience Data Firewall
  participant Campaign as Campaign API
  participant Ledger as Receipt Ledger

  Fan->>App: Start campaign action
  App->>Runtime: Runtime event packet
  Runtime->>ADF: Request required fan grant
  ADF-->>Runtime: Grant, narrowed grant, or denial
  Runtime->>Campaign: Submit participation
  Campaign->>Ledger: Participation and reward receipt
  Campaign-->>App: Reward or ineligible reason
```

1. The fan app launches the certified extension in the approved surface.
2. The extension requests only the fields declared in the campaign manifest.
3. `AudienceDataFirewallPolicy` applies fan privacy mode, minimization, and revocation state.
4. `CampaignAPI` validates eligibility and writes the participation receipt.
5. The fan receives a reward, pending state, or precise ineligible reason.

### 6.3 `10/W1`: Developer Publishes Extension

```mermaid
sequenceDiagram
  actor Developer
  participant Console as Developer Console
  participant Registry as Extension Registry
  participant Cert as Certification System
  participant Artifacts as ExtensionArtifactAPI
  participant Market as Marketplace Listing

  Developer->>Console: Submit manifest and artifact
  Console->>Artifacts: Store signed bundle and attestation
  Console->>Cert: Run extension certification
  Cert-->>Registry: Certification outcome
  Registry->>Market: Publish listing if approved
  Console-->>Developer: Approved, limited, or rejected
```

1. The developer submits `ExtensionManifest`, signed artifact, build attestation, pricing, and export behavior.
2. `ExtensionArtifactAPI` stores immutable artifact versions.
3. Certification checks permissions, sandbox behavior, receipts, privacy, and supply-chain evidence.
4. Approved versions are listed with explicit risk tier and data scopes.
5. Rejected versions return remediation without becoming installable.

### 6.4 `10/W2`: Creator Installs Extension

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Registry as Extension Registry
  participant Permissions as Permission Review
  participant CMH as Metadata Host

  Creator->>Studio: Install extension
  Studio->>Registry: Fetch manifest and certification
  Registry-->>Studio: Permissions, surfaces, risk tier
  Studio->>Permissions: Creator approves scopes
  Permissions->>CMH: Store ExtensionInstallGrant
  Studio-->>Creator: Extension active
```

1. Creator Studio presents requested surfaces, data scopes, sponsor access, fees, and risk tier.
2. The creator approves, narrows, or rejects extension permissions.
3. `ExtensionInstallGrant` is stored as creator metadata and can be revoked later.
4. The extension runtime activates only on approved surfaces.
5. Existing campaigns must revalidate if install permissions change.

### 6.5 `10/W3`: Fan Participates In Campaign Extension

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Runtime as Extension Runtime
  participant ADF as Audience Data Firewall
  participant Campaign as Campaign API
  participant Ledger as Receipt Ledger

  Fan->>App: Open extension campaign
  App->>Runtime: Start extension session
  Runtime->>ADF: Check campaign and creator-interest grants
  ADF-->>Fan: Grant prompt, category default, or denial
  Fan-->>ADF: Approve, narrow, or deny
  Runtime->>Campaign: Complete campaign action
  Campaign->>Ledger: CampaignParticipationReceipt
```

1. The fan app creates a runtime session tied to extension version, campaign id, and app surface.
2. The firewall evaluates requested fan data against campaign purpose, creator interest-data purpose, creator category defaults, fan ad preferences, and fan privacy mode.
3. The fan can approve, narrow, deny, apply a creator-category default, or choose alternate entry before participation continues.
4. `ConsentGrantAPI` records purpose, fields, retention, ad-use flag, offer context, and revocation behavior for grant-backed access.
5. The extension submits the completed action to `CampaignAPI`.
6. The receipt ledger stores data-access, participation, and reward evidence for reporting and settlement.

### 6.6 `10/W3A`: CRM Or Direct-Contact Extension Access

```mermaid
sequenceDiagram
  participant Runtime as Extension Runtime
  participant CRM as CreatorCRMExportAPI
  participant ADF as Audience Data Firewall
  participant CAV as Creator Audience Vault
  participant Ledger as Receipt Ledger

  Runtime->>CRM: Request direct-contact data
  CRM->>ADF: Evaluate field, purpose, destination
  ADF->>CAV: Fetch eligible audience records
  CAV-->>ADF: Permissioned fields only
  ADF->>Ledger: DataAccessReceipt
  ADF-->>CRM: Grant, narrowed dataset, or denial
```

1. The extension declares fields, destination, retention, sponsor involvement, and contact purpose.
2. `CreatorCRMExportAPI` routes all direct-contact requests through the Audience Data Firewall.
3. The firewall removes fans who revoked visibility, blocked export, are in private mode, or lack direct-contact grants.
4. Every granted or denied access writes a `DataAccessReceipt`.
5. The extension receives only the narrowed dataset or a machine-readable denial reason.

### 6.7 `10/W4`: Sponsor Campaign Execution

```mermaid
sequenceDiagram
  actor Sponsor
  participant SponsorAPI as SponsorCampaignAPI
  participant Campaign as Campaign API
  participant Creator as Creator Studio
  participant Runtime as Extension Runtime
  participant Ledger as Receipt Ledger

  Sponsor->>SponsorAPI: Submit campaign budget and objective
  SponsorAPI->>Creator: Request creator approval
  Creator-->>SponsorAPI: Approve or reject
  SponsorAPI->>Campaign: Activate sponsor campaign
  Campaign->>Runtime: Deliver campaign config
  Runtime->>Ledger: Delivery and participation receipts
  SponsorAPI-->>Sponsor: Live campaign status
```

1. Sponsor setup includes objective, budget, brand constraints, accepted session intent ad contexts, reward rules, reporting scope, and requested data.
2. Creator approval is required before campaign delivery on creator-controlled surfaces.
3. `CampaignAPI` activates the campaign only after budget and compliance checks pass.
4. Runtime delivery and participation events write signed receipts.
5. Sponsor reporting is built from approved aggregate metrics and settlement receipts.

### 6.8 `10/W5`: Extension Suspension

```mermaid
sequenceDiagram
  actor Reviewer
  participant Safety as Trust And Safety
  participant Registry as Extension Registry
  participant Runtime as Extension Runtime
  participant Studio as Creator Studio
  participant Apps as Fan Apps

  Reviewer->>Safety: Open suspension case
  Safety->>Registry: Set suspension state
  Registry->>Runtime: Push blocklist update
  Runtime-->>Apps: Block or limit extension calls
  Registry-->>Studio: Notify affected creators
  Safety-->>Reviewer: Remediation state
```

1. Trust and Safety opens a case tied to extension id, version, artifact hash, and reason.
2. The registry marks affected versions as limited, suspended, or revoked.
3. Runtime blocklists prevent new sessions and can terminate active sessions.
4. Creators and fans receive product-safe messaging and export/remediation options.
5. Reinstatement requires new evidence or a certified replacement version.

### 6.9 `10/W6`: Extension State Export

```mermaid
sequenceDiagram
  actor Owner as Creator Or Fan
  participant App as App Or Studio
  participant Registry as Extension Registry
  participant Runtime as Extension Runtime
  participant Export as Export Service
  participant Ledger as Audit Ledger

  Owner->>App: Request extension state export
  App->>Registry: Resolve export contract
  Registry->>Runtime: Fetch exportable state
  Runtime->>Export: Build package
  Export->>Ledger: Export receipt
  Export-->>App: Downloadable export package
```

1. The owner requests export from the creator studio, fan app, or provider exit flow.
2. `ExtensionManifest` defines what state is creator-owned, fan-owned, sponsor-owned, or non-exportable.
3. The runtime returns exportable state using the manifest's schema and version.
4. The export service creates a signed package with schema, owner, timestamp, and integrity hash.
5. The audit ledger records the export for portability and compliance.

### 6.10 `18/W1`: Sponsor Campaign Setup

```mermaid
sequenceDiagram
  actor Sponsor
  participant Console as Sponsor Console
  participant SponsorAPI as SponsorCampaignAPI
  participant ADF as Audience Data Firewall
  participant Creator as Creator Studio
  participant Campaign as Campaign API

  Sponsor->>Console: Configure campaign
  Console->>SponsorAPI: Campaign proposal packet
  SponsorAPI->>ADF: Preflight data scope and thresholds
  ADF-->>SponsorAPI: Approved, narrowed, or denied scopes
  SponsorAPI->>Creator: Send creator approval request
  Creator-->>Campaign: Approve campaign manifest
  SponsorAPI-->>Sponsor: Setup status
```

1. Sponsor Console captures objective, contextual session intent categories, target constraints, budget, reward, requested fan interest/ad-preference fields, data needs, and reporting needs.
2. `AudienceDataFirewallPolicy` preflights whether requested fields require explicit fan grants, must be aggregated, or must be denied.
3. Creator Studio receives a campaign proposal with the narrowed data scope and brand terms.
4. Campaign activation requires creator approval, budget reservation, and `FanDataGrantOffer` terms when the campaign asks fans to share interest/ad-preference data.
5. Denied scopes are returned with specific policy reasons.

### 6.11 `18/W2`: Fan Campaign Participation

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Runtime as Extension Runtime
  participant ADF as Audience Data Firewall
  participant Campaign as Campaign API
  participant Wallet as Fan Wallet

  Fan->>App: Join sponsor campaign
  App->>Runtime: Start sponsor extension
  Runtime->>ADF: Request campaign and creator-interest grants
  ADF-->>Runtime: Scoped grants, prompt, or denial
  Runtime->>Campaign: Submit participation proof
  Campaign->>Wallet: Issue reward or credit
  Campaign-->>App: Participation result
```

1. The fan joins from a clearly labeled sponsor campaign surface.
2. The extension requests only data allowed by campaign scope, `FanDataGrantOffer`, creator category defaults, and fan choice.
3. Fan can approve, narrow, deny, or use alternate entry before grant-protected data is accessed.
4. `CampaignAPI` validates the participation proof and anti-fraud constraints.
5. Rewards are issued to the fan wallet or marked pending.
6. The fan can inspect, revoke, or export the campaign grant and creator interest-data grant later.

### 6.12 `18/W2B`: Sponsor-Linked Creator Interest-Data Grant

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App Settings
  participant Runtime as Campaign Extension
  participant CG as ConsentGrantAPI
  participant ADF as Audience Data Firewall
  participant Interest as PermissionedAudienceInterestDataAPI
  participant Report as Sponsor Reporting
  participant Ledger as Receipt Ledger

  Fan->>App: Review data-for-value offer
  App->>Runtime: Fan decision packet
  Runtime->>CG: Create/narrow/deny creator_interest_data grant
  CG->>ADF: Publish grant and category policy state
  Interest->>ADF: Query approved fields or counts
  ADF-->>Interest: Approved creator-scoped fields, aggregates, or denial
  Interest->>Ledger: DataAccessReceipt
  Interest->>Report: Aggregate or permitted grant-backed metrics
  App-->>Fan: Active grant, ad preferences, access history
```

1. Fan opens the campaign or Fan App settings request for a sponsor-linked creator offer.
2. The offer names the creator, sponsor, requested interests/likes/dislikes/ad preferences, purpose, retention, ad-use flag, reward value, and alternate path.
3. Fan approves, denies, narrows fields, revokes an existing grant, or applies a creator-category default.
4. `ConsentGrantAPI` records the `creator_interest_data` grant or denial.
5. Audience Data Firewall applies privacy mode, relationship state, block/dislike state, age/region rules, category policy, purpose, retention, and ad-use limits.
6. `PermissionedAudienceInterestDataAPI` returns only approved creator-scoped fields or aggregate counts.
7. Sponsor reporting receives aggregate, clean-room, or explicitly grant-backed metrics according to the campaign contract.
8. `DataAccessReceipt` and Fan App settings expose actual access and revocation state.

### 6.13 `18/W2A`: Sponsor Request For Audience Data Is Narrowed Or Denied

```mermaid
sequenceDiagram
  actor Sponsor
  participant SponsorAPI as SponsorCampaignAPI
  participant ADF as Audience Data Firewall
  participant Policy as Privacy Policy Engine
  participant Report as Sponsor Reporting

  Sponsor->>SponsorAPI: Request audience fields
  SponsorAPI->>ADF: Evaluate request
  ADF->>Policy: Check minimization, consent, thresholds
  Policy-->>ADF: Allow, narrow, aggregate, or deny
  ADF->>Report: Build permitted response
  Report-->>Sponsor: Narrowed data or denial reason
```

1. Sponsor requests are evaluated by field, purpose, audience size, retention, and destination.
2. The firewall applies fan grants, creator interest-data grants, creator category defaults, creator policy, private mode, minor/vulnerable-user rules, and aggregation thresholds.
3. Direct identifiers, interest records, ad preferences, and disliked-creator data are denied unless explicit grants and creator policy allow the requested purpose.
4. Sponsor receives aggregate metrics, a narrowed dataset, or a structured denial reason.
5. The decision is logged for privacy audit and later campaign disputes.

### 6.14 `18/W3`: Sponsor Reporting And Settlement

```mermaid
sequenceDiagram
  participant Campaign as Campaign API
  participant Ledger as Receipt Ledger
  participant Settlement as Settlement Engine
  participant SponsorReport as Sponsor Reporting
  participant Sponsor as Sponsor Console

  Campaign->>Ledger: Delivery, participation, reward, spend receipts
  Settlement->>Ledger: Pull campaign receipts
  Settlement->>Settlement: Allocate creator, developer, platform, fan rewards
  Settlement->>SponsorReport: Build aggregate report
  SponsorReport-->>Sponsor: Report, invoice, reconciliation
```

1. Campaign runtime writes delivery, participation, reward, and sponsor-spend receipts.
2. Settlement validates budget caps, fraud adjustments, reward eligibility, and developer fees.
3. Sponsor reports use aggregated metrics and privacy thresholds, not raw fan exports.
4. Creator, developer, fan reward, and platform utility allocations are reconciled.
5. The sponsor receives an invoice and a report linked to the receipt set.

### 6.15 `18/W4`: Sponsor-Free Premium Variant

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Wallet as Fan Wallet
  participant Entitlements as Entitlement Ledger
  participant Campaign as Campaign API
  participant Runtime as Extension Runtime

  Fan->>App: Enable sponsor-free premium
  App->>Wallet: Purchase or verify premium mode
  Wallet->>Entitlements: Write premium entitlement
  App->>Campaign: Request campaign suppression state
  Campaign->>Runtime: Suppress sponsor surfaces for fan
  App-->>Fan: Sponsor-free experience active
```

1. The fan buys or activates a premium variant that suppresses sponsor campaign surfaces.
2. The entitlement ledger records sponsor-free status and expiration.
3. Campaign delivery checks entitlement state before rendering sponsor extensions.
4. Suppression affects ads/sponsor surfaces but does not delete prior campaign receipts.
5. Creator and sponsor reporting excludes future sponsor-free impressions for that fan.

## 7. Error And Recovery Behavior

| Failure mode | Recovery behavior |
| --- | --- |
| Extension manifest requests unapproved data. | Install or runtime grant is denied with required scope reduction. |
| Fan denies campaign grant. | Campaign returns an ineligible or limited participation result without exposing denied fields. |
| Sponsor asks for identifying audience data without grants. | Audience Data Firewall returns aggregate-only response or denial. |
| Extension artifact is suspended. | Runtime blocklist stops sessions and Creator Studio exposes replacement/export options. |
| Campaign receipts conflict with budget or fraud rules. | Settlement places affected rewards or payouts in pending adjustment state. |
| Premium sponsor-free entitlement is active. | Campaign API suppresses sponsor surfaces and reports non-delivery reason. |
