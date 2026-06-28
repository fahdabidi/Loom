# Phase B12 - UX Decisions

## Reference Sources Reviewed

- Existing B1a-B11 workflow tests and tracker evidence.
- Loom Skill operating rules requiring visible Demo App validation.
- Android emulator screenshot evidence requirements.

## Key Decisions

- Use visible workflow checklist screens as the deterministic UI evidence surface.
- Require three screenshots per workflow: start, critical action, and completion.
- Store evidence by phase under `docs/Build Plan V2/Evidence/`.
- Treat missing screenshots as a failed gate.

## Workflow Walkthrough

The harness opens the Demo App, captures empty-state/dialog/complete harness screenshots, installs
local packages, opens community cards, completes workflows, and writes phase evidence manifests.
