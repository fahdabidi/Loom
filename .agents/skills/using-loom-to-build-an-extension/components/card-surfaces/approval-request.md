# Approval and Request Surface

## Supported Interactions

- Submit request, assign reviewer, approve, reject, request changes, comment, show status history,
  reopen, appeal, and notify requester.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Requester | `community.surface.approval.submit` | Submit, edit while draft, respond to requested changes, appeal. |
| Reviewer/committee | `community.surface.approval.review` | Approve, reject, request changes, comment. |
| Admin | `community.surface.approval.admin` | Assign reviewers, reopen, audit. |

## Custom Experience Guidance

Customize request type, evidence fields, committee flow, SLA, decision labels, appeal policy, and
notification copy. Use for HOA architectural requests, join approvals, gear approvals, and committee
decisions.

## API Support

Requires `CommunityApprovalApi`: `submitRequest`, `assignReviewer`, `approve`, `reject`,
`requestChanges`, `comment`, `statusHistory`, `reopen`, `appeal`, `notifyRequester`.
