# Phase B17 - Persona Role Inventory and Capability Matrix

## Achieves

Define the personas, user roles, permissions, workflow ownership, and receiving states for every
example community before implementing persona-aware UI.

## Deliverables

- Persona inventory for every B13-B16 example and test app.
- Workflow-to-persona capability matrix.
- Workflow dependency graph covering prerequisite persona actions and generated records.
- Hidden, disabled, read-only, and receiving-state UX policy.
- Unauthorized-action matrix with backend permission expectations.
- Per-persona workflow test matrix with one row for every persona/workflow combination.
- Multi-persona workflow list and screenshot evidence IDs.
- B17 API Review and B17 UX Decisions.

## Completed When

Every workflow has an explicit initiating persona, receiving persona, required permission/role grant,
UX state for unauthorized personas, prerequisite persona actions, and expected generated records.
Masjid Nur must explicitly model admin announcement publishing as the prerequisite for member
announcement receipt/search. Every persona/workflow row must be testable or marked not applicable with
rationale.

## Evidence To Record

Matrix path, dependency graph path, source review notes, per-persona workflow matrix, manifest rows,
phase gate, analyzer, boundary lint, diff check, and commit SHA.

## Execution Evidence - 2026-06-27

- Persona and workflow policy helpers implemented in `app/apps/loom_communities_demo/lib/main.dart`.
- `wf_persona-role-inventory-capability-matrix` passed.
- Android evidence: `docs/Build Plan V2/Evidence/B17/workflow-ui-evidence.json`.
