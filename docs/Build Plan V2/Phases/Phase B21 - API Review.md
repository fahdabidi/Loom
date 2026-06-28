# Phase B21 - API Review

## Scope

B21 adds a production UX contract matrix over the existing Demo App workflow/persona model. It does
not add backend APIs or change Loom-owned service contracts.

## Decision

- Use the existing `LoomWorkflowDefinition`, persona policy, and evidence target data as the source of
  truth.
- Add `LoomProductionWorkflowContract` in the Demo App as UI/test metadata only.
- Keep workflow IDs, route IDs, package schema, initialization schema, persona IDs, and screenshot
  evidence IDs stable.

## Result

No API contract changes are required for B21. The matrix is validated by
`wf_production-workflow-ux-contract-matrix`.
