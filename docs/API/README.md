# Loom API Specifications

Status: Draft for review

This folder contains Loom's API contract documents. The product docs define desired behavior, the architecture docs define packet flows, and this folder defines executable API boundaries.

## Organization

OpenAPI specifications are organized by independently owned API surface, not by workflow. A workflow can call many APIs, but each API owner publishes one contract for its own endpoints, schemas, auth scopes, error behavior, idempotency behavior, and downstream dependencies.

```text
docs/API/
  00-api-standards-and-versioning.md
  OpenAPI/
    _shared/
    identity/
    creator/
    content/
    monetization/
    discovery/
    ecosystem/
    campaigns/
    safety/
    portability/
    governance/
  Bundles/
  Examples/
```

## Dependency Convention

Each OpenAPI document uses `x-loom-api-owner` and `x-loom-downstream-apis` to declare ownership and dependency boundaries. Downstream APIs are referenced by file path so packet flows can be checked against real contracts.

Shared schemas live in `OpenAPI/_shared/`. API specs should reference shared schemas rather than redefining identifiers, receipts, errors, pagination, principals, or security schemes.

## Initial Spec Set

The initial spec set mirrors the system components named by the architecture docs:

- Identity: Fan Passport, Fan Vault, Fan Wallet.
- Creator: Creator Channel Registry, Creator Metadata, Creator Audience.
- Content: Content Host, Playback Authorization.
- Monetization: Entitlement Ledger, Receipt Ledger, Settlement Engine.
- Discovery: Search, Recommendation/Referral, AI Gateway.
- Ecosystem: Provider Registry, Certification, Extension Registry, Extension Runtime.
- Campaigns: Campaign API, Sponsor Campaign API.
- Safety: Trust and Safety, Fraud.
- Portability: Migration/Export, Provider Exit.
- Governance: Governance, Audit.

