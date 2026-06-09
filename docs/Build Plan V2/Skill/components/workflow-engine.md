# Workflow Engine

Use `CommunityWorkflowApi` for stateful approval, onboarding, registration, and operational flows.

## Extension Use

- Model each workflow with clear states and terminal end states.
- Use case/task service for human review steps.
- Keep workflow transitions idempotent.

## Validation

- `vt_workflow-engine_start` and `vt_workflow-engine_transition` prove workflow state changes.
- `ct_workflow-engine__case-task_transition` proves case/task handoff.
