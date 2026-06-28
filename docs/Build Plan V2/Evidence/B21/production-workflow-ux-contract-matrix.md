# B21 Production Workflow UX Contract Matrix

## Status

Pass.

## Coverage

- Communities/test apps: 10
- Workflow definitions covered by production contracts: 66
- Persona/workflow matrix rows covered: more than 100, across actor, receiver, read-only, and disabled
  states.
- Source of truth: `LoomProductionWorkflowContract`, `personaWorkflowMatrixForExtensionId`, and
  `productionUxGenericCopyViolations` in `app/apps/loom_communities_demo/lib/main.dart`.

## Contract Fields

Each workflow/persona row is validated for:

- community/test app and workflow ID
- workflow category
- real user goal
- production surface label
- semantic primary action label
- required inputs
- validation/trust summary
- result and success state
- receiver surface
- persona state and rationale

## Generic Copy Audit

The B21/B24 gate rejects user-facing production workflow copy containing:

- `Complete workflow`
- `Can perform this workflow`
- `workflow evidence`
- `Workflow checklist`
- `local route`

Audit result: pass, no violations.
