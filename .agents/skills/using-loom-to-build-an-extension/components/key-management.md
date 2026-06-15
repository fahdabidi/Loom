# Key Management

Use `CommunityKeyManagementApi` to request signing keys scoped to a builder, extension, or package
operation. Extensions never generate signing authority outside Loom's key-management boundary.

## Extension Use

- Request a key for one explicit scope.
- Verify scope before attaching signatures to extension or initialization packages.
- Rotate by requesting a new key version rather than widening a previous scope.

## Validation

- `vt_builder-app-id_signing-scope` covers key issuance through the builder App ID flow.
