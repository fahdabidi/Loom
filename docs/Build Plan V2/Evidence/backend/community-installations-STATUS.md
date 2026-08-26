# App Access community-installations status

## Result

`loom_app_access_provisioning` now builds and posts one
`InstallCommunityPackageRequest` per community to
`POST /v1/apps/{appId}/community-installations`.

- The plan is schema version 3 and contains only a local `communityId` plus
  the exact installation request. It has no group id, role permissions,
  permission catalog entries, permission prefix, or client-side creation
  classification.
- The deriver retains the JSONC loader and existing `ArchetypeResolver`. It
  extracts role IDs and labels verbatim; `createRoleIds` is the sorted union
  of every render-binding `create` action's `byRoleIds`; transitions carry the
  declared action only when it exists, their tone, terminal state, and
  `guard.allowedRoleIds` (or an empty list for an instance-gated transition).
- The applier makes only installation POSTs. It has no catalog, group, role,
  or role-permission write path. A 200 records the server-returned `groupId`
  under the local community ID; its resulting `communityGroupIds` object is
  the sole value to use for `LOOM_COMMUNITY_GROUP_IDS` after a fully successful
  apply.
- A 422 remains a failed community. Every finding is retained and printed as
  its full JSON object, while the applier continues with the remaining
  community requests. `rolesWithNoPermissions` is emitted as a warning on a
  successful response. Non-422 errors retain the response body in the thrown
  error. No client secret is printed or persisted.
- `--dry-run` remains the default. It makes 0 network calls and prints the
  request that would be POSTed for each community.

No live service, Keycloak, or cluster endpoint was called. The applier tests
use an in-process HTTP server only.

## Corpus results

| Measure | Verified result |
| --- | --- |
| Packages that build an installation request | **11/11** |
| Workflows represented | **95/95** |
| Transitions represented | **611/611** |
| Transitions with an absent (not empty) `action` | **274/611** |
| Generated requests with a `permissionIds` field | **0/11** |
| Cedar facility-reservation `createRoleIds` | **2/2**: `hoa-board`, `hoa-member` |
| Fake 200 results that recorded a returned group ID | **1/1** |
| Fake 422 findings surfaced by the CLI | **2/2** |

The test suite includes an inverted Cedar assertion: `hoa-member` and
`hoa-board` are present, while `cedar_commons_hoa_admin` is absent from the
whole generated plan.

## Cedar Commons HOA generated request (verbatim)

```json
{"communityHandle":"cedar-commons-hoa","displayName":"Cedar Commons HOA","grammarVersion":4,"roles":[{"roleId":"hoa-member","label":"Homeowner"},{"roleId":"hoa-board","label":"Board"}],"workflows":[{"workflowType":"hoa-architectural-request","cardSurfaceFamily":"formEntry","createRoleIds":["hoa-member"],"transitions":[{"transitionId":"submit-request","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"withdraw-draft","tone":"destructive","isTerminal":true,"allowedRoleIds":["hoa-member"]},{"transitionId":"attach-request-document","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"begin-review","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"request-changes-case","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"approve-case","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"deny-case","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"reopen-case","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"resubmit-request","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"withdraw-request","tone":"destructive","isTerminal":true,"allowedRoleIds":["hoa-member"]}]},{"workflowType":"hoa-committee-decision","cardSurfaceFamily":"approvalQueueItem","createRoleIds":[],"transitions":[{"transitionId":"begin-committee-review","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"approve-request","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"request-owner-changes","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"deny-request","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"reopen-decision","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"resume-review","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"owner-resubmitted","tone":"secondary","isTerminal":true,"allowedRoleIds":["hoa-member"]},{"transitionId":"owner-withdraw","tone":"destructive","isTerminal":true,"allowedRoleIds":["hoa-member"]}]},{"workflowType":"hoa-dues-payment","cardSurfaceFamily":"paymentCheckout","createRoleIds":["hoa-board"],"transitions":[{"transitionId":"start-checkout","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"record-offline-payment","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"record-payment-failure","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"retry-payment","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"cancel-checkout","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"change-payment-amount","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"edit-payment-method","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"enable-autopay","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"disable-autopay","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"request-refund","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"record-offline-refund","tone":"primary","isTerminal":true,"allowedRoleIds":["hoa-board"]},{"transitionId":"decline-refund","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]}]},{"workflowType":"hoa-member-document","cardSurfaceFamily":"documentLibrary","createRoleIds":["hoa-board"],"transitions":[{"transitionId":"record-document-edit","action":"edit","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"publish-document","action":"publish","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"delete-document","action":"delete","tone":"destructive","isTerminal":true,"allowedRoleIds":["hoa-board"]},{"transitionId":"archive-document","action":"archive","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"restore-document","action":"restore","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"record-open","action":"open","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member","hoa-board"]},{"transitionId":"confirm-document-download","action":"download","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member","hoa-board"]},{"transitionId":"acknowledge-document","action":"acknowledge","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"mark-document-unread","action":"mark_unread","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"save-document","action":"save","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"remove-saved-document","action":"unsave","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"request-document-access","action":"request_access","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"withdraw-access-request","action":"withdraw_access_request","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"share-document","action":"share","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member","hoa-board"]}]},{"workflowType":"hoa-facility-reservation","cardSurfaceFamily":"event-rsvp","createRoleIds":["hoa-board","hoa-member"],"transitions":[{"transitionId":"reserve-facility","action":"create","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"board-reserve-facility","action":"create","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"flag-reservation-conflict","action":"record_outcome","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"revise-conflicted-reservation","action":"edit","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"board-revise-conflicted-reservation","action":"edit","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"change-reservation","action":"edit","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"board-change-reservation","action":"edit","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"cancel-reservation","action":"cancel","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"board-cancel-reservation","action":"cancel","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"reopen-reservation","action":"reopen","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"board-reopen-reservation","action":"reopen","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"enable-reservation-reminder","action":"set_reminder","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"disable-reservation-reminder","action":"set_reminder","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]}]},{"workflowType":"hoa-owner-notification","cardSurfaceFamily":"notificationInbox","createRoleIds":["hoa-board"],"transitions":[{"transitionId":"mark-notification-read","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"mark-notification-unread","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-member"]},{"transitionId":"withdraw-notification","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"resend-notification","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]}]},{"workflowType":"hoa-export-evidence","cardSurfaceFamily":"exportWizard","createRoleIds":["hoa-board"],"transitions":[{"transitionId":"preview-export","action":"preview","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"approve-redaction","action":"approve_redaction","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"change-export-scope","action":"configure_scope","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"generate-export","action":"run","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"complete-export-generation","action":"record_outcome","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"record-export-failure","action":"record_outcome","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"retry-export","action":"retry","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"request-export-download","action":"download","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"start-export-transfer","action":"run","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"record-transfer-complete","action":"record_outcome","tone":"primary","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"rollback-transfer","action":"rollback","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"cancel-export","action":"cancel","tone":"destructive","isTerminal":false,"allowedRoleIds":["hoa-board"]},{"transitionId":"reopen-export","action":"retry","tone":"secondary","isTerminal":false,"allowedRoleIds":["hoa-board"]}]}]}
```

## Tests deleted because they asserted the removed client-side derivation

1. `plan permissions exactly equal every role grant and include creation` —
   the plan now intentionally has no permission set or role grants.
2. `community-group mapping covers every community and parses in service` —
   group IDs must come from installation responses, not a client-side naming
   rule.
3. `creation classification keeps the exact provisional stopgap set` — the
   incorrect initial-state/system-created/unstated inference was removed;
   creation authority now comes only from create actions' `byRoleIds`.
4. `applier reconciles once, then reruns as a no-op` — it asserted direct
   group and role writes, which no longer exist in the applier.
5. `applier posts only missing permissions and never replaces catalog` — the
   client must not read or write the permission catalog.
6. `applier posts permissions before any role post` — both client-side write
   phases were removed in favour of one installation POST.

The retained tests were adapted to the new contract rather than weakened:
dry-run remains zero-network, response bodies remain observable on unexpected
HTTP failures, Cedar retains its exact package role IDs, and all 11 packages
still build successfully.

## Verification

| Command | Exact final total |
| --- | --- |
| `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **11 passed** |
| `cd app/packages/core/loom_communities_app_shell && flutter test` | **273 passed** |
| `cd app/packages/core/loom_workflow_engine && flutter test` | **284 passed, 3 skipped** |
| `cd app/packages/tooling/loom_ux_judges && flutter test` | **432 passed** |
| `cd app/apps/loom_communities_demo && flutter test` | **160 passed** |
| `cd app/packages/tooling/loom_app_access_provisioning && flutter analyze` | **No issues found** |

The provisioning total decreased from **12 to 11**. That is expected and is
fully accounted for by removing the six obsolete client-derivation tests above
and retaining or adding the applicable request/applier contract tests; the
resulting suite has one fewer test. No remaining applicable test was deleted.
The four required repository-suite totals did not move down.

## Contradiction found

The read-only current corpus contradicts the ticket's stated create-action
count. A direct scan of `docs/references/communities/*.jsonc` finds **75**
`"kind": "create"` actions, not 70: Ad-Free 2, Camera 4, Cedar 6, Chess 8,
Data Portability 10, Garden 6, Masjid 8, Member Social Space 6, Neighborhood
Book Club 10, Tabletop 10, and Riverside Youth Soccer 5. The observed range is
therefore **2–10**, not 2–11. No community JSON or reference documentation was
modified. This does not prevent request construction; all **11/11** packages
build successfully.
