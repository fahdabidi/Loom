# Case Task Service

Use `CommunityCaseTaskApi` for approval queues, operational follow-up, and workflow-owned tasks.

## Extension Use

- Open cases for reviewable user actions such as facility requests or document approvals.
- Store only task state in this service; source records stay with their owning component.
- Use emitted case events to trigger workflow steps.

## Validation

- `vt_case-task_transition` proves transition state and event emission.
- `ct_case-task__workflow-engine_transition` remains pending until A5.
