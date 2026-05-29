# Loom API Standards And Versioning

Status: Draft for review

## 1. API Boundary Rule

One OpenAPI document represents one independently owned API surface. A workflow-oriented architecture doc can reference multiple APIs, but it does not own their contracts.

## 2. Versioning

- Public API paths include a major version: `/v1/...`.
- Breaking changes require a new major path.
- Non-breaking field additions are allowed when clients must ignore unknown response fields.
- Manifest and receipt schemas carry explicit `schemaVersion` fields independent from API path version.
- Every mutating request should accept `Idempotency-Key`.

## 3. Identity And Auth

- User and service auth schemes are declared in `OpenAPI/_shared/security-schemes.yaml`.
- Actor identity is represented with shared `ActorPrincipal`.
- Service-to-service calls must include `X-Loom-Correlation-Id`.
- Fan-facing APIs must support pairwise or scoped identifiers when the workflow does not need a global fan id.

## 4. Common Headers

| Header | Required | Purpose |
| --- | --- | --- |
| `X-Loom-Correlation-Id` | Required for mutating calls | Trace a packet across APIs. |
| `Idempotency-Key` | Required for mutating calls | Prevent duplicate writes. |
| `X-Loom-Actor` | Optional when auth token is not enough | Signed actor context for service calls. |
| `X-Loom-Manifest-Version` | Optional | Pin request to a known manifest version. |

## 5. Error Model

All APIs use the shared `ApiError` schema. Error responses should include:

- `code`: stable machine-readable error code.
- `message`: safe human-readable summary.
- `correlationId`: packet trace id.
- `details`: field-level or policy-level remediation details when safe.

## 6. Cross-API Dependencies

Each spec declares downstream dependencies through `x-loom-downstream-apis`. A dependency means the API may call or require contract compatibility with that downstream API while completing a workflow packet.

## 7. Receipts

Economic, audit, data-access, and migration events should write signed receipts. Receipt schemas live in `OpenAPI/_shared/receipts.yaml` and should be referenced directly.

