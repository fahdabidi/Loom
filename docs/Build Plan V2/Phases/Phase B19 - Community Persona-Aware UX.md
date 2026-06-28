# Phase B19 - Community Persona-Aware UX

## Achieves

Make every example community adjust visible workflows and capabilities to the selected test persona.

## Deliverables

- Role-aware workflow rendering for every example/test app.
- Hidden, disabled, read-only, and receiving-state behavior.
- Disabled-state reason copy where workflows remain visible for explanation.
- Persona-specific receiving surfaces for workflows created by another persona.
- Backend permission parity checks.
- Updated example docs and screenshot evidence.
- B19 API Review and B19 UX Decisions.

## Completed When

Capabilities shown in the community experience match the selected persona. Admin-only workflows are not
generally executable by member personas, member personas get receiving/read-only workflows where
appropriate, and every persona/workflow row from B17 has an implemented UI state.

## Evidence To Record

Authorized, unauthorized, read-only, and receiving-state screenshots for all examples, backend denial
assertions, per-persona workflow matrix audit, test output, manifest rows, phase gate, analyzer,
boundary lint, diff check, and commit SHA.

## Execution Evidence - 2026-06-27

- Workflow tiles render actor, receiver, read-only, waiting, and disabled states from the selected
  persona.
- `wf_community-persona-aware-ux` passed.
- Android evidence: `docs/Build Plan V2/Evidence/B19/workflow-ui-evidence.json`.
