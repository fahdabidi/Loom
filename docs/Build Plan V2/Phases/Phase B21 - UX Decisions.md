# Phase B21 - UX Decisions

## Decisions

- Treat every workflow/persona row as a production UX contract with category, action label, inputs,
  validation, result, receiver surface, and persona state.
- Reject generic checklist, metadata-only, and completion-dialog UX as production workflow UX.
- Use the existing example workflow copy as domain input, but replace generic action labels with
  semantic user actions.
- Keep existing test keys stable so B12-B20 evidence can be refreshed without rewriting all harnesses.

## Evidence

- `wf_production-workflow-ux-contract-matrix` validates all production workflow contracts.
- The generic-copy gate reports no user-facing production UX violations.
