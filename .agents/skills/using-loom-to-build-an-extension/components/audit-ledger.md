# Audit Ledger

Use `CommunityAuditApi` indirectly through Loom components or directly for extension actions that need
operator-visible traceability. Sensitive actions must write redacted audit entries.

## Extension Use

- Include actor, component, action, and idempotency key in audit-worthy operations.
- Set `redacted=true` when data class or policy requires it.
- Link extension errors to audit IDs when presenting admin diagnostics.

## Validation

- A1 component tests assert audit IDs on passport, protected-vault, connection, and builder-app actions.
