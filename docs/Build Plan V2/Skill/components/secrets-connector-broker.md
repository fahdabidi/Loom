# Secrets Connector Broker

Use `CommunitySecretsConnectorApi` for scoped connector secrets.

## Extension Use

- Store secrets by extension and connector scope.
- Never put secret values in extension or initialization packages.
- Display only redacted values in debug output.

## Validation

- `vt_secrets-connector_scoped-secret` proves scoped redaction behavior.
