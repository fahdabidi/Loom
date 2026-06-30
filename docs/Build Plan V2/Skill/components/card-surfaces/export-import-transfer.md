# Export, Import, and Transfer Surface

## Supported Interactions

- Create export plan, select scope, preview redaction, generate export, download, verify checksum,
  cancel/retry, start provider transfer, verify transfer, rollback, and inspect audit trail.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Owner | `community.surface.portability.export`, `community.surface.portability.transfer` | Export, transfer, rollback, inspect audit. |
| Data reviewer | `community.surface.portability.review` | Preview redaction and validate scope. |
| Member | `community.surface.portability.own.read` | Export own data where policy allows. |

## Custom Experience Guidance

Customize export scopes, redaction explanations, provider labels, checksum display, rollback warnings,
and transfer status. Always show protected-data handling and audit receipt.

## API Support

Requires `CommunityPortabilitySurfaceApi`: `createExportPlan`, `previewRedaction`, `generateExport`,
`downloadExport`, `verifyChecksum`, `cancelExport`, `retryExport`, `startTransfer`,
`verifyTransfer`, `rollbackTransfer`, `auditTrail`.
