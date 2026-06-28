# Phase B22 - API Review

## Scope

B22 replaces generic Demo App workflow surfaces with domain-specific production surfaces. It does not
change package ingestion, local backend, App Shell, wallet, messages, connections, ads, or export APIs.

## Decision

- Preserve all workflow IDs, persona IDs, screenshot keys, and local backend state.
- Add production UI metadata and rendering only inside the Demo App.
- Continue using Loom-owned surfaces for payment, ads, messages, connections, protected data, and audit
  semantics.

## Result

No API contract changes are required for B22. Existing B12-B20 workflow tests continue to pass.
