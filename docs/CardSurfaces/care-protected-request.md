# Care and Protected Request Surface

## Supported Interactions

- Create/update/withdraw care request, split public summary from protected details, assign care team,
  review, request changes, resolve, send neutral notification, read public summary, read protected
  details where allowed, and audit redacted access.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Requester | `community.surface.care.write` | Submit, edit, withdraw, view own status. |
| Care team | `community.surface.care.review`, `community.surface.care.protected.read` | Review protected details, assign, resolve. |
| General admin | `community.surface.care.read` | See public/redacted summary only. |

## Custom Experience Guidance

Customize request categories, public/private fields, routing, neutral copy, care-team role, follow-up
states, and consent copy. Never expose protected details in generic feeds or audit text.

## API Support

Requires `CommunityCareRequestApi`: `createRequest`, `updateRequest`, `withdrawRequest`,
`assignCareTeam`, `reviewRequest`, `requestChanges`, `resolveRequest`, `neutralNotification`,
`readPublicSummary`, `readProtectedDetails`, `redactedAudit`.
