# Phase B18 - API Review

## Scope

Reviewed the Demo App state needed for a test-only persona picker behind the people icon.

## Decisions

- Active persona state is local to `_LocalExtensionScreenState`; production identity remains out of
  scope.
- Picker options come from `personasForExtensionId`, so examples cannot drift from the B17 matrix.
- The selected persona is passed into `personaWorkflowViewFor` for all workflow rendering.

## Evidence

- `wf_demo-app-persona-picker`
- `docs/Build Plan V2/Evidence/B18/workflow-ui-evidence.json`
