# Loom Architecture 10: Migration, Export, And Portability

Status: Draft for review  
Source workflow map: `docs/Architecture/02-workflow-inventory-and-function-map.md`

## 1. Purpose

This document defines transaction packet models for creator export and migration, metadata host migration, fan export and migration, media host migration, extension state export, data export/delete, existing-platform migration, public metadata import, membership migration, cross-post/exclusive migration, and provider exit-button flows.

## 2. Functional System Diagram

```mermaid
flowchart TB
  Creator[Creator]
  Fan[Fan]
  ExistingPlatform[Existing Platform]
  CreatorStudio[Creator Studio]
  FanApp[Fan App]
  Migration[Migration Orchestrator]
  Export[Export Service]
  Import[Import Service]
  CCR[Creator Channel Registry]
  CMH[Creator Metadata Host]
  NewCMH[New Metadata Host]
  ContentHost[Content Host]
  NewHost[New Content Host]
  FanVault[Fan Vault]
  Wallet[Fan Wallet]
  Entitlements[Entitlement Ledger]
  ExtensionRegistry[Extension Registry]
  ExtensionRuntime[Extension Runtime]
  ProviderRegistry[Provider Capability Registry]
  SearchIndex[Search Index]
  ReceiptLedger[Receipt Ledger]
  Notify[Notification Service]

  Creator --> CreatorStudio
  Fan --> FanApp
  ExistingPlatform --> Import
  CreatorStudio --> Migration
  FanApp --> Migration
  Migration --> Export
  Migration --> Import
  Migration --> CCR
  Migration --> CMH
  Migration --> NewCMH
  Migration --> ContentHost
  Migration --> NewHost
  Migration --> FanVault
  Migration --> Wallet
  Migration --> Entitlements
  Migration --> ExtensionRegistry
  ExtensionRegistry --> ExtensionRuntime
  Migration --> ProviderRegistry
  Migration --> SearchIndex
  Export --> ReceiptLedger
  Import --> ReceiptLedger
  Migration --> Notify
```

## 3. Packet Envelope

| Field | Meaning |
| --- | --- |
| `ownerContext` | Creator, fan, channel, wallet, vault, app, provider, or extension owner and authorization proof. |
| `sourceContext` | Source provider, source platform, source host, export endpoint, object ids, schema version, and integrity hashes. |
| `targetContext` | Target provider, target host, import endpoint, schema version, key scope, and activation plan. |
| `assetContext` | Metadata, media, transcripts, manifests, entitlements, memberships, wallet state, fan vault data, or extension state. |
| `policyContext` | Export rights, privacy mode, fan grants, creator policy, retention, deletion, and provider exit obligations. |
| `verificationContext` | Checksum, manifest signature, sample playback, entitlement reconciliation, and index verification. |
| `cutoverContext` | Freeze window, pointer update, routing state, rollback plan, notification plan, and completion marker. |
| `auditContext` | Export receipt, import receipt, deletion receipt, migration job id, actor signature, and timestamp. |

## 4. Interfaces And Contracts

| Interface or contract | Packet responsibility |
| --- | --- |
| `CreatorExportBundle` | Portable channel metadata, manifests, provider roles, catalog, business rules, and audit receipts. |
| `FanExportBundle` | Fan passport, follows, grants, wallet references, vault export, preferences, and deletion markers. |
| `MediaExportManifest` | Media objects, renditions, transcripts, captions, checksums, rights, and playback verification. |
| `MetadataHostMigrationAPI` | Moves creator metadata host pointer and verifies target host readiness. |
| `ContentHostMigrationAPI` | Copies media, verifies playback, and updates content host pointers. |
| `ProviderExitAPI` | One-click export, transfer, revocation, and cutover contract exposed by certified providers. |
| `ImportValidationAPI` | Schema validation, duplicate detection, identity matching, and remediation response. |
| `MembershipMigrationMap` | Mapping between external members, Loom fan identities, entitlements, and opt-in state. |
| `CrossPostPolicy` | Rules for mirrored, exclusive, and staged content migration. |
| `DataDeletionReceipt` | Durable proof that deleted or revoked data was removed or tombstoned. |
| `ExtensionStateExport` | Portable creator/fan-owned extension state and schema version. |
| `MigrationAuditReceipt` | Signed export/import/cutover evidence for portability and disputes. |

## 5. Workflow Transaction Packet Models

| Ref | Trigger | Primary packet path | Durable writes / receipts | Completion response |
| --- | --- | --- | --- | --- |
| `02/W6` | Creator exports and migrates. | Creator Studio -> Migration Orchestrator -> Export/Import -> Registry. | Creator export bundle, import receipt, pointer update. | Channel runs from new provider. |
| `04/W5` | Metadata host migration. | Creator Studio -> MetadataHostMigrationAPI -> Registry -> Search Index. | Host pointer update and verification receipt. | Metadata reads route to new host. |
| `05/W7` | Fan export or migration. | Fan App -> Export Service -> Fan Vault/Wallet/Passport. | Fan export bundle and optional deletion receipt. | Fan receives portable data or migrated account state. |
| `06/W5` | Media export and host migration. | Creator Studio -> ContentHostMigrationAPI -> source/target hosts. | Media manifest, checksums, playback verification. | Playback routes to target host. |
| `10/W6` | Extension state export. | Owner -> Extension Registry -> Runtime -> Export Service. | Extension export package and receipt. | Portable extension state delivered. |
| `14/W5` | Data export/delete. | Fan/App -> Data Rights API -> vault/wallet/grants/services. | Export bundle, deletion/tombstone receipts. | Fan receives export or deletion confirmation. |
| `21/W1` | Existing creator starts owned hub. | Creator Studio -> Import Service -> Registry/Metadata Host. | Channel manifest, imported profile/catalog. | Creator hub is live with imported public metadata. |
| `21/W2` | Public metadata import. | Import Service -> Existing Platform -> Metadata Host. | Import manifest, source links, validation results. | Public profile/content metadata appears in Loom. |
| `21/W3` | Membership migration. | Creator Studio -> Import Service -> Fan opt-in -> Entitlement Ledger. | Membership map, opt-in grants, entitlements. | Members gain Loom access after opt-in. |
| `21/W4` | Cross-post and exclusive migration. | Creator Studio -> CrossPostPolicy -> Content/Metadata hosts. | Cross-post rules, exclusive schedule, content refs. | Content moves in stages without confusing fans. |
| `21/W5` | Provider exit button. | Creator/Fan -> ProviderExitAPI -> Migration Orchestrator. | Export, revocation, cutover, and deletion receipts. | Owner exits provider with portable state. |

## 6. Step-By-Step Life Of A Packet Overlays

### 6.1 `02/W6`: Creator Export And Migration

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Migration as Migration Orchestrator
  participant Export as Export Service
  participant Import as Import Service
  participant Registry as Creator Channel Registry

  Creator->>Studio: Request creator migration
  Studio->>Migration: Migration packet with target provider
  Migration->>Export: Build CreatorExportBundle
  Migration->>Import: Validate and import bundle
  Import-->>Migration: Import receipt and readiness
  Migration->>Registry: Update provider pointers
  Studio-->>Creator: Migration complete or pending cutover
```

1. Creator Studio collects target provider, assets, cutover timing, and rollback preference.
2. The export service builds a signed bundle of channel metadata, manifests, catalog, business rules, and receipts.
3. The target import service validates schema, keys, provider capability, and duplicate records.
4. The registry updates provider pointers only after target readiness checks pass.
5. The creator receives completion status, propagation state, and rollback window.

### 6.2 `04/W5`: Metadata Host Migration

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Old as Current Metadata Host
  participant New as New Metadata Host
  participant Registry as Creator Channel Registry
  participant Search as Search Index

  Creator->>Studio: Move metadata host
  Studio->>Old: Export metadata snapshot
  Studio->>New: Import and verify snapshot
  New-->>Studio: Readiness and signature proof
  Studio->>Registry: Update metadata host pointer
  Registry->>Search: Emit reindex event
  Studio-->>Creator: New metadata host active
```

1. The current host exports the latest channel manifest, catalog, policies, and version history.
2. The new host imports the snapshot and proves it can serve required certified APIs.
3. Creator Channel Registry updates the canonical metadata host pointer.
4. Search and fan apps receive reindex/routing events with the new pointer.
5. The old host remains read-only during the rollback window if policy allows it.

### 6.3 `05/W7`: Fan Export Or Migration

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Export as Export Service
  participant Vault as Fan Vault
  participant Wallet as Fan Wallet
  participant Passport as Fan Passport
  participant Ledger as Audit Ledger

  Fan->>App: Request export or migration
  App->>Export: Fan export packet
  Export->>Passport: Fetch identity and follows
  Export->>Vault: Fetch private vault data
  Export->>Wallet: Fetch wallet references and entitlements
  Export->>Ledger: Export receipt
  Export-->>App: FanExportBundle
```

1. The fan chooses export, migration to another app/provider, or deletion after export.
2. Export scopes include passport, follows, grants, preferences, vault data, wallet references, and entitlements as allowed.
3. Private vault exports use fan authorization and may require local encryption.
4. Wallet export references avoid exposing payment credentials.
5. The fan receives a signed bundle and audit receipt.

### 6.4 `06/W5`: Media Export And Host Migration

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Source as Source Content Host
  participant Target as Target Content Host
  participant Migration as ContentHostMigrationAPI
  participant CMH as Metadata Host

  Creator->>Studio: Move media host
  Studio->>Migration: Media migration packet
  Migration->>Source: Export MediaExportManifest and objects
  Migration->>Target: Import media and verify checksums
  Target-->>Migration: Playback verification
  Migration->>CMH: Update content host pointers
  Studio-->>Creator: Media migration status
```

1. The migration packet names content ids, target host, renditions, transcript/caption scope, and cutover plan.
2. Source host exports media objects and checksums through the certified export API.
3. Target host imports objects, verifies checksums, and proves playback for required renditions.
4. Metadata host updates content pointers after verification.
5. Fan apps continue using old URLs until the new pointers are active.

### 6.5 `10/W6`: Extension State Export

```mermaid
sequenceDiagram
  actor Owner as Creator Or Fan
  participant App as App Or Studio
  participant Registry as Extension Registry
  participant Runtime as Extension Runtime
  participant Export as Export Service

  Owner->>App: Request extension state export
  App->>Registry: Resolve extension export contract
  Registry-->>App: Exportable schema and owner scope
  App->>Runtime: Request state snapshot
  Runtime->>Export: Package state
  Export-->>App: ExtensionStateExport
```

1. The owner initiates export for a specific extension, campaign, or provider exit flow.
2. `ExtensionManifest` determines which state is creator-owned, fan-owned, sponsor-owned, or excluded.
3. Runtime returns state using the declared export schema.
4. Export service signs the package and records schema version.
5. The owner can import the package into a compatible certified extension or archive it.

### 6.6 `14/W5`: Data Export/Delete

```mermaid
sequenceDiagram
  actor Fan
  participant App as Fan App
  participant Rights as Data Rights API
  participant Vault as Fan Vault
  participant ADF as Audience Data Firewall
  participant Services as Downstream Services
  participant Ledger as Audit Ledger

  Fan->>App: Request export or delete
  App->>Rights: Data rights packet
  Rights->>Vault: Export or delete private data
  Rights->>ADF: Revoke grants and visibility
  Rights->>Services: Propagate deletion/tombstone request
  Rights->>Ledger: DataDeletionReceipt or export receipt
  Rights-->>App: Completion status
```

1. The fan chooses export, delete, revoke grants, or a combined action.
2. `Data Rights API` coordinates fan vault, grants, app permissions, campaign data, and downstream service records.
3. Deletion uses tombstones where legal, security, or financial audit records must remain.
4. Grant revocation propagates to apps, creators, sponsors, and extensions.
5. The fan receives status for completed, pending, and exempt records.

### 6.7 `21/W1`: Existing Creator Starts Owned Hub

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Import as Import Service
  participant External as Existing Platform
  participant Registry as Creator Registry
  participant CMH as Metadata Host

  Creator->>Studio: Start owned hub
  Studio->>Import: Import public profile/catalog
  Import->>External: Fetch public metadata
  External-->>Import: Public data snapshot
  Import->>Registry: Create channel identity
  Import->>CMH: Store imported metadata
  Studio-->>Creator: Owned hub ready for review
```

1. The creator proves control of the existing public profile where possible.
2. Import service fetches only public metadata unless the creator provides additional authorized export data.
3. Loom creates a portable creator channel and stores imported metadata as reviewable draft or live records.
4. Source links and import provenance remain attached for transparency.
5. The creator can edit the hub before promoting it to fans.

### 6.8 `21/W2`: Public Metadata Import

```mermaid
sequenceDiagram
  participant Import as Import Service
  participant External as Existing Platform
  participant Validate as ImportValidationAPI
  participant CMH as Metadata Host
  participant Search as Search Index

  Import->>External: Request public metadata snapshot
  External-->>Import: Profile, posts, links, public catalog
  Import->>Validate: Validate schema and ownership evidence
  Validate-->>Import: Accepted records and conflicts
  Import->>CMH: Store accepted metadata
  CMH->>Search: Index eligible imported records
```

1. Import service reads public profile and content metadata from the existing platform.
2. `ImportValidationAPI` checks ownership, duplicates, broken links, unsupported fields, and policy conflicts.
3. Conflicts are returned to Creator Studio for review rather than silently overwritten.
4. Accepted records are stored with source provenance and import timestamp.
5. Search indexes only records that satisfy creator search policy and public eligibility.

### 6.9 `21/W3`: Membership Migration

```mermaid
sequenceDiagram
  actor Creator
  actor Fan
  participant Studio as Creator Studio
  participant Import as Import Service
  participant Map as MembershipMigrationMap
  participant Entitlements as Entitlement Ledger
  participant Notify as Notification Service

  Creator->>Studio: Import member list
  Studio->>Import: Membership migration packet
  Import->>Map: Match external members to Loom identities
  Notify-->>Fan: Invite opt-in to migrated membership
  Fan->>Notify: Accept migration
  Map->>Entitlements: Write migrated entitlement
  Studio-->>Creator: Migration progress
```

1. Creator imports a member list or external platform export under proof of rights.
2. `MembershipMigrationMap` separates matched, unmatched, invited, accepted, declined, and blocked users.
3. Fans must opt in before Loom entitlements or direct relationship state are activated.
4. Accepted fans receive migrated membership access and can review data grants.
5. Creator Studio reports progress without exposing unmatched private user data.

### 6.10 `21/W4`: Cross-Post And Exclusive Migration

```mermaid
sequenceDiagram
  actor Creator
  participant Studio as Creator Studio
  participant Policy as CrossPostPolicy
  participant CMH as Metadata Host
  participant Host as Content Host
  participant Notify as Notification Service

  Creator->>Studio: Configure migration schedule
  Studio->>Policy: Validate mirrored and exclusive rules
  Policy-->>Studio: Approved schedule
  Studio->>CMH: Write cross-post metadata
  Studio->>Host: Stage exclusive media if needed
  Studio->>Notify: Notify fans of availability
```

1. The creator chooses which content is mirrored, delayed, exclusive to Loom, or retired from legacy platforms.
2. `CrossPostPolicy` checks rights, access modes, monetization, and fan messaging requirements.
3. Metadata host stores availability windows and source links.
4. Content host stages exclusive media before fan-facing promotion.
5. Fan notifications distinguish mirrored content from Loom-exclusive releases.

### 6.11 `21/W5`: Provider Exit Button

```mermaid
sequenceDiagram
  actor Owner as Creator Or Fan
  participant UI as App Or Studio
  participant Exit as ProviderExitAPI
  participant Migration as Migration Orchestrator
  participant Source as Source Provider
  participant Target as Target Provider
  participant Ledger as Audit Ledger

  Owner->>UI: Press provider exit button
  UI->>Exit: Exit packet with target and scope
  Exit->>Source: Export, revoke, and freeze request
  Exit->>Migration: Coordinate transfer and validation
  Migration->>Target: Import bundle
  Migration->>Ledger: Export, import, cutover receipts
  UI-->>Owner: Exit complete or action required
```

1. The owner selects target provider, data scope, revocation/deletion options, and cutover timing.
2. `ProviderExitAPI` is a certified provider obligation and must expose export status and blockers.
3. Migration orchestrator validates the transfer before pointers or app routing change.
4. Source provider receives revocation, freeze, or deletion requests based on owner choice.
5. The owner receives a clear completion, pending, or blocked state with receipts.

## 7. Error And Recovery Behavior

| Failure mode | Recovery behavior |
| --- | --- |
| Target provider fails import validation. | Migration remains staged, source stays active, and remediation details return to the owner. |
| Checksums or playback verification fail. | Content host pointers are not updated and failed assets are retried or excluded. |
| External platform import is incomplete. | Imported records are marked partial and creator review is required before publish. |
| Fan declines membership migration. | No Loom entitlement or direct relationship is activated for that fan. |
| Deletion cannot remove financial/audit records. | Data Rights API writes tombstones and explains retained audit categories. |
| Provider exit is blocked by unpaid invoices or legal hold. | Exit packet returns blocker type, affected assets, and available partial export path. |
