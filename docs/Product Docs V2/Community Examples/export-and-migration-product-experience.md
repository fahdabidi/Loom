# Export And Migration Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Export and Migration |
| Evidence community name | Data Portability Community |
| Community type | Portability / provider transfer test app |
| Product promise | Help owners export, verify, migrate, roll back, and understand redaction/portability status. |
| Brand cues | Operational trust, clear status/progress, checksum/redaction/rollback clarity. |
| What this must not feel like | Technical export rows without user-understandable migration state. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Owner/admin | Export, verify, transfer, rollback | Move or back up community data safely. | Redaction and protected data must be explicit. | Export has scope, checksum, verification, and rollback status. |
| Member | Understand data portability where relevant | Know what is exported/redacted. | Member-sensitive data must not leak. | Member sees appropriate notices or read-only export status. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Export scope | Select/review exported data. | Owner/admin | included components, redactions, protected-data policy. | Start export |
| Verification | Confirm integrity. | Owner/admin | checksum, file count, result. | Verify |
| Migration/rollback | Track provider transfer. | Owner/admin | source/destination, status, rollback option. | Transfer / rollback |

## 4. Home Screen Requirements

The user must see a migration dashboard with scope, redaction, verification, and rollback state, not a
generic export workflow list.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Export wizard | scope, components, redaction, destination | draft/running/complete/error | export, cancel | technical row only |
| Verification | checksum, counts, pass/fail | pending/verified/failed | verify, retry | hidden checksum |
| Rollback | source, destination, reason, status | available/running/complete | rollback | unlabelled transfer task |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| export-migration | owner/admin | Export wizard and transfer status | scope/redaction/checksum/rollback state | Export/provider transfer/audit | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| export/migration | owner starts/verifies | members see applicable notice | verified package read-only | rollback disabled when unavailable | non-owner hidden |

## 8. Content And Seed Data Requirements

Use component lists, redaction summaries, checksums, source/destination provider names, transfer IDs,
rollback reason/status, and error examples.

## 9. Visual And Interaction Standard

Use a stepper/status-dashboard feel with readable trust indicators. Avoid rows that expose backend
terms without explaining what the owner should decide.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Export/Migration product experience. | Judge current screenshots against migration/status surfaces. | open |
