# Workflow Status And Case Surface

## Supported Interactions

- Create a workflow/case instance, show all steps, expose current status, and route persona-specific
  next actions.
- Support arbitrary multi-step community processes such as submitted -> under review -> feedback
  needed -> approved/rejected -> payment needed -> scheduled -> completed.
- Add comments, attach documents, request changes, approve/reject, reopen, cancel, assign reviewers,
  notify participants, and show audit/history.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Requester | `community.surface.workflow.request` | Start workflow, edit draft, respond to feedback, cancel/reopen where allowed. |
| Reviewer | `community.surface.workflow.review` | Review step, approve/reject/request changes, comment, assign, escalate. |
| Receiver/viewer | `community.surface.workflow.read` | See current status, required next step, receiver notification, and history. |
| Workflow admin | `community.surface.workflow.admin` | Configure step templates, deadlines, automations, and audit/export rules. |

## Custom Experience Guidance

Use this surface when the process is not a fixed approval card. Configure step names, allowed
transitions, required data, SLAs, documents, payment checkpoints, notification copy, and receiver
states. An HOA architectural request can include property details, document attachments, board review,
neighbor comment, changes requested, approval, payment, and final audit. A care workflow can keep
public and protected data split while still showing neutral member-facing progress.

## API Support

Requires `CommunityWorkflowStatusApi`: `createWorkflowInstance`, `getWorkflowStatus`,
`listWorkflowSteps`, `transitionWorkflowStep`, `assignWorkflowReviewer`, `requestWorkflowChanges`,
`approveWorkflowStep`, `rejectWorkflowStep`, `addWorkflowComment`, `attachWorkflowDocument`,
`recordWorkflowPaymentNeeded`, `notifyWorkflowParticipants`, `reopenWorkflow`, `cancelWorkflow`,
`workflowAuditTrail`.

