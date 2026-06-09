# Phase A4a - Service Components II (Ops and Community)

Layer: service
Components: Case/Task Service, Documents Service, Facilities Service, Import Service, Export Service,
Provider Transfer Service, Abuse Report Service, Moderation Case Service, Incident Service, Dispute
Resolution scaffold.
Depends on: A3
Parallelism: one agent per component
Gate: ops/community-service validation and contract tests pass

## 0. Prerequisite Gate

- A3 complete and committed.
- A1-A3 manifest has no stale required tests.
- Provider fakes for foundation/registry/experience services are available.

## 1. Components in This Phase

| Component | Architecture source | Contract |
| --- | --- | --- |
| case-task-service | [Arch 12](../../Architecture%20V2/12-mvp-prototype-transaction-slices.md) | `CommunityCaseTaskApi` |
| documents-service | [Arch 12](../../Architecture%20V2/12-mvp-prototype-transaction-slices.md) | `CommunityDocumentsApi` |
| facilities-service | [Arch 12](../../Architecture%20V2/12-mvp-prototype-transaction-slices.md) | `CommunityFacilitiesApi` |
| import-service | [Arch 10](../../Architecture%20V2/10-migration-export-and-portability.md) | `CommunityImportApi` |
| export-service | [Arch 10](../../Architecture%20V2/10-migration-export-and-portability.md) | `CommunityExportApi` |
| provider-transfer-service | [Arch 10](../../Architecture%20V2/10-migration-export-and-portability.md) | `CommunityProviderTransferApi` |
| abuse-report-service | [Arch 09](../../Architecture%20V2/09-trust-safety-moderation-and-compliance.md) | `CommunityAbuseReportApi` |
| moderation-case-service | [Arch 09](../../Architecture%20V2/09-trust-safety-moderation-and-compliance.md) | `CommunityModerationApi` |
| incident-service | [Arch 09](../../Architecture%20V2/09-trust-safety-moderation-and-compliance.md) | `CommunityIncidentApi` |
| dispute-resolution | [Arch 09](../../Architecture%20V2/09-trust-safety-moderation-and-compliance.md) | `CommunityDisputeApi` |

## 2. Agent Assignment and Parallelism

Run one agent per component. Merge order:

1. Case/Task, Documents, Facilities.
2. Import/Export.
3. Provider Transfer.
4. Abuse Report, Moderation, Incident, Dispute.

## 3. Per-Component Build Spec

Ops/community services must consume lower-layer contracts and A3 service provider tests only through
fakes. Export/import must call component contracts instead of reading store tables directly.

## 4. Basic Validation Tests

Required:

- `vt_case-task_transition`
- `vt_documents_permissions`
- `vt_facilities_reservation`
- `vt_import_dry-run`
- `vt_import_commit`
- `vt_export_assemble`
- `vt_export_redaction`
- `vt_provider-transfer_execute-verify`
- `vt_abuse-report_submit`
- `vt_moderation_case-lifecycle`
- `vt_incident_create`
- `vt_dispute_open-case`

## 5. Consumer-Contract Tests Authored for Dependents

Author and register:

- `ct_documents__search_index-visible-documents`
- `ct_documents__export_include-documents`
- `ct_facilities__wallet_reservation-payment`
- `ct_case-task__workflow-engine_transition`
- `ct_import__protected-vault_write`
- `ct_export__components_enumerate`
- `ct_protected-vault__import-export_redaction`
- `ct_incident__certification_revoke`
- `ct_fraud__dispute_resolution-path`

Tests with A4b/A5 consumers remain pending until those phases.

## 6. Cross-Component Test Gate

Run A4a validation tests plus all contract tests to/from built A1-A3 providers. Rerun affected earlier
tests for protected vault, role policy, documents, events, and receipts if any contracts changed.

## 7. Tenet-Adherence Checks

Verify import/export orchestration does not violate owned-data boundaries. Safety services must append
records and emit events rather than rewriting source content or receipts directly.

## 8. Skill Contribution

Add component guides for case/task, documents, facilities, import, export, provider transfer, abuse
report, moderation, incident, and dispute. Guides must include extension recipes for approval queues,
document libraries, reservations, import/export, and moderation escalation.

## 9. Manifest Update

Stamp A4a tests and resolve pending counterparts unblocked by ops/community services.

## 10. API Review

Create `Phase A4a - API Review.md`. Record specs for operational, portability, and trust/safety
service APIs.

## 11. Definition of Done

A4a tests, regressions, manifest, Skill guides, API Review, tracker, and commit SHA complete.

## 12. Next Phase

Proceed to [Phase A4b - Service Components III (Economic Search and Ads).md](./Phase%20A4b%20-%20Service%20Components%20III%20%28Economic%20Search%20and%20Ads%29.md).
