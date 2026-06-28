# Phase B17 - API Review

## Scope

Reviewed the Demo App persona/workflow API surface needed to model test personas without introducing
production identity behavior.

## Decisions

- Persona inventory is represented by `LoomPersonaDefinition` and exposed through
  `personasForExtensionId`.
- Workflow capability policy is centralized in `personaPolicyForWorkflow`, with actor, receiver,
  read-only, disabled, and prerequisite fields.
- Matrix and dependency audits use `personaWorkflowMatrixForExtensionId` and
  `workflowDependenciesForExtensionId` so tests and evidence use the same source of truth.
- Receipt state is keyed by workflow and persona so multiple receiving personas can be tested
  independently.

## Evidence

- `wf_persona-role-inventory-capability-matrix`
- `docs/Build Plan V2/Evidence/B17/workflow-ui-evidence.json`
