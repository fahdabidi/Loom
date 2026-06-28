# Phase B18 - Demo App Persona Picker

## Achieves

Add a test-only persona picker behind the people icon in the Demo Loom Communities App.

## Deliverables

- People-icon picker for the current community.
- Community-scoped persona list with labels and role descriptions.
- Active persona state carried into community screens and workflow rendering.
- Clear local-testing disclaimer because production persona comes from logged-in identity.
- Widget tests and Android screenshot evidence.
- B18 API Review and B18 UX Decisions.

## Completed When

Tapping the people icon opens the picker, selecting a persona updates the active actor without
restarting the app, and the selected persona is visible while testing the community.

## Evidence To Record

Picker screenshots, active persona state assertions, test output, manifest rows, phase gate, analyzer,
boundary lint, diff check, and commit SHA.

## Execution Evidence - 2026-06-27

- People icon opens the `Test persona` picker and active persona updates in-place.
- `wf_demo-app-persona-picker` passed.
- Android evidence: `docs/Build Plan V2/Evidence/B18/workflow-ui-evidence.json`.
