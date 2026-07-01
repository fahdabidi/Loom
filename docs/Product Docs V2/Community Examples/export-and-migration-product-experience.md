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
| export-import-preview | owner | Export/import preview | selected scope, redaction preview, destination, change-scope path | Export/provider transfer/audit | B16/B25 |
| export-import-replay | owner | Import replay | replay source, validation status, retry/cancel, receiver state | Import/provider transfer/audit | B16/B25 |
| export-protected-redaction | owner | Protected redaction review | protected fields, redaction choices, preview, audit state | Export/vault/audit | B16/B25 |
| export-schema-listing | owner | Schema listing | schema names, included/excluded components, protected-data labels | Export/schema registry | B16/B25 |
| export-full-bundle | owner | Full bundle generation | scope, file count, checksum, download state | Export/documents/audit | B16/B25 |
| export-redacted-bundle | owner | Redacted bundle generation | redaction summary, checksum, download state | Export/vault/audit | B16/B25 |
| export-checksum-evidence | owner | Checksum verification | checksum, verification result, retry path | Export/audit | B16/B25 |
| export-transfer-verification | owner | Provider transfer verification | source/destination, transfer ID, status, retry/cancel path | Provider transfer/audit | B16/B25 |
| export-transfer-rollback | owner | Transfer rollback | rollback reason, source/destination, rollback availability, completed state | Provider transfer/audit | B16/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| export-import-preview | owner reviews scope before export | members see only applicable notice | preview is readable before run | export disabled until required scope is selected | non-owner hidden |
| export-import-replay | owner replays import | affected members see migration notice if relevant | replay log readable | replay disabled after final verification | non-owner hidden |
| export-protected-redaction | owner reviews protected-data redaction | protected members see safe notice only | redaction preview readable | export disabled until protected choice confirmed | non-owner hidden |
| export-schema-listing | owner reviews included schemas | no member receiver state unless notified | schema list readable | edit disabled after package generation | non-owner hidden |
| export-full-bundle | owner generates full bundle | members see applicable notice | generated bundle metadata readable | download disabled until checksum passes | non-owner hidden |
| export-redacted-bundle | owner generates redacted bundle | members see protected-data notice | redaction summary readable | download disabled until redaction passes | non-owner hidden |
| export-checksum-evidence | owner verifies checksum | audit records verification | checksum readable/exportable | transfer disabled until checksum passes | non-owner hidden |
| export-transfer-verification | owner verifies provider transfer | destination provider receives transfer state | verification record readable | rollback disabled until transfer starts | non-owner hidden |
| export-transfer-rollback | owner rolls back transfer | destination/source show restored state | rollback audit readable | rollback disabled when unavailable | non-owner hidden |

## 8. Content And Seed Data Requirements

Use component lists, redaction summaries, checksums, source/destination provider names, transfer IDs,
rollback reason/status, and error examples.

## 9. Visual And Interaction Standard

Use a stepper/status-dashboard feel with readable trust indicators. Avoid rows that expose backend
terms without explaining what the owner should decide.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| export-import-preview | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-import-replay | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-protected-redaction | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-schema-listing | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-full-bundle | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-redacted-bundle | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-checksum-evidence | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-transfer-verification | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| export-transfer-rollback | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `export-import-preview` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must show scope, redaction preview, destination, change-scope, and run state. |
| `export-import-replay` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | replay import, validate, retry/cancel, audit | Demo renderer must show replay source, validation result, retry/cancel, and receiver state. |
| `export-protected-redaction` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | protected redaction preview, confirm, audit | Demo renderer must show protected fields, redaction choices, preview, and audit state. |
| `export-schema-listing` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | schema listing, included/excluded scope, labels | Demo renderer must show schema names, protected labels, included/excluded components, and next step. |
| `export-full-bundle` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | generate/download/checksum full bundle | Demo renderer must show full bundle scope, file count, checksum, download, and cancel/change path. |
| `export-redacted-bundle` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | redacted bundle, redaction summary, checksum | Demo renderer must show redaction summary, checksum, download, and rollback/change path. |
| `export-checksum-evidence` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | checksum verify/retry/audit | Demo renderer must show checksum, verification result, retry, and audit state. |
| `export-transfer-verification` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | provider transfer verify/retry/cancel | Demo renderer must show source, destination, transfer ID, status, retry, and cancel. |
| `export-transfer-rollback` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | rollback request/confirm/result/audit | Demo renderer must show rollback reason, source/destination, availability, confirm, and completed state. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
