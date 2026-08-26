# App Access provisioning deriver status

## Result

Implemented `loom_app_access_provisioning` under `app/packages/tooling/`.

- The pure deriver reuses the existing JSONC/package parser and
  `ArchetypeResolver`; it produces a deterministic JSON plan for all shipped
  packages.
- The plan has 11 communities, 25 globally unique role ids, 95 workflows, and
  a `communityGroupIds` object proven by
  `MapCommunityGroupIdResolver.fromJson`.
- The HTTP applier is separate from the deriver. It defaults to dry-run with
  zero HTTP calls, requires `--apply` to mutate, uses App Access `GET` list,
  `POST` group/role, and `PUT` role-permissions operations, sends a fresh UUID
  correlation id on every HTTP request, and never has a delete operation.
- Apply-mode configuration is environment-only:
  `LOOM_APP_ACCESS_BASE_URL`, `LOOM_KEYCLOAK_TOKEN_URL`,
  `LOOM_APP_ACCESS_CLIENT_ID`, `LOOM_APP_ACCESS_CLIENT_SECRET`, and
  `LOOM_APP_ID`. The client secret is neither logged nor written into plans or
  reports.

The derive CLI is:

```sh
cd app
dart run packages/tooling/loom_app_access_provisioning/bin/derive_app_access_provisioning_plan.dart \
  ../docs/references/communities
```

The applier receives that JSON file as its only positional argument. Without
`--apply`, it enumerates every group and role it would ensure and makes zero
calls. Apply mode compares the remote lists before mutating, so a second run is
a no-op. Existing unmatched groups and roles are returned as extras; none are
deleted. A mismatched existing group display name, role group id, or role
display name fails loudly because the documented API provides no update
operation for those fields.

## Corpus derivation

| Measure | Result |
| --- | --- |
| Communities / packages | 11 / 11 |
| Workflows | 95 / 95 |
| Initial-state guarded creation | 84 / 95 |
| System-created creation | 7 / 95 |
| Provisional unstated creation | 4 / 95 |
| Globally unique declared role ids | 25 / 25 |
| Community-group map coverage | 11 / 11 |

No package failed derivation.

The existing resolver intentionally has no family for the two unrendered,
system-created Tabletop workflows `tournament-vote` and `notification`. Their
plan entries contain `family: null`, `permissionPrefix: null`, no create roles,
and no App Access grant. This is the resolver's documented “derives nothing”
result for a workflow with no render binding/response-table owner; assigning a
family by workflow type here would reimplement resolver behavior and invent a
permission. The other five system-created workflows resolve normally but still
grant `.create` to nobody.

The corpus-wide inference matches the ticket's stated classification. The only
creation-authority uncertainty is the deliberately provisional case below; no
additional package looked suspicious enough to justify changing the prescribed
three-case rule.

### Provisional create-permission fallback

These are the only workflows marked `creationAuthority: "unstated"`; all
declared roles in their package receive the family `.create` permission pending
a specification decision.

1. Camera Club — `critique-submission`
2. Garden Club — `plant-exchange-submission`
3. Masjid Nur — `mosque-donation-payment`
4. Masjid Nur — `mosque-care-request`

## Cedar Commons HOA plan (verbatim)

```json
{
  "communityId": "community_cedar_commons_hoa",
  "groupId": "loom_communities_cedar_commons_hoa",
  "displayName": "Cedar Commons HOA",
  "roles": [
    {
      "roleId": "hoa-member",
      "displayName": "Homeowner",
      "permissionIds": [
        "approval_queue_item.create",
        "document_library.acknowledge",
        "document_library.download",
        "document_library.mark_unread",
        "document_library.open",
        "document_library.request_access",
        "document_library.save",
        "document_library.share",
        "document_library.unsave",
        "document_library.withdraw_access_request",
        "event_rsvp.cancel",
        "event_rsvp.create",
        "event_rsvp.edit",
        "event_rsvp.reopen",
        "event_rsvp.set_reminder",
        "form_entry.create",
        "notification_inbox.create",
        "payment_checkout.create"
      ]
    },
    {
      "roleId": "hoa-board",
      "displayName": "Board",
      "permissionIds": [
        "approval_queue_item.create",
        "document_library.archive",
        "document_library.create",
        "document_library.delete",
        "document_library.download",
        "document_library.edit",
        "document_library.open",
        "document_library.publish",
        "document_library.restore",
        "document_library.share",
        "event_rsvp.cancel",
        "event_rsvp.create",
        "event_rsvp.edit",
        "event_rsvp.record_outcome",
        "event_rsvp.reopen",
        "export_wizard.approve_redaction",
        "export_wizard.cancel",
        "export_wizard.configure_scope",
        "export_wizard.create",
        "export_wizard.download",
        "export_wizard.preview",
        "export_wizard.record_outcome",
        "export_wizard.retry",
        "export_wizard.rollback",
        "export_wizard.run",
        "notification_inbox.create",
        "payment_checkout.create"
      ]
    }
  ],
  "workflows": [
    {
      "workflowType": "hoa-architectural-request",
      "family": "formEntry",
      "permissionPrefix": "form_entry",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-member"
      ]
    },
    {
      "workflowType": "hoa-committee-decision",
      "family": "approvalQueueItem",
      "permissionPrefix": "approval_queue_item",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board",
        "hoa-member"
      ]
    },
    {
      "workflowType": "hoa-dues-payment",
      "family": "paymentCheckout",
      "permissionPrefix": "payment_checkout",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board",
        "hoa-member"
      ]
    },
    {
      "workflowType": "hoa-member-document",
      "family": "documentLibrary",
      "permissionPrefix": "document_library",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board"
      ]
    },
    {
      "workflowType": "hoa-facility-reservation",
      "family": "event-rsvp",
      "permissionPrefix": "event_rsvp",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board",
        "hoa-member"
      ]
    },
    {
      "workflowType": "hoa-owner-notification",
      "family": "notificationInbox",
      "permissionPrefix": "notification_inbox",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board",
        "hoa-member"
      ]
    },
    {
      "workflowType": "hoa-export-evidence",
      "family": "exportWizard",
      "permissionPrefix": "export_wizard",
      "creationAuthority": "initial-state-transition",
      "createRoleIds": [
        "hoa-board"
      ]
    }
  ]
}
```

`hoa-member` and `hoa-board` are exact package ids. The old
`cedar_commons_hoa_admin` string appears nowhere in the derived plan; a
dedicated inverted regression assertion verifies that condition.

## Verification output

```text
$ cd app/packages/tooling/loom_app_access_provisioning && flutter test
00:00 +8: All tests passed!

$ cd app/packages/core/loom_communities_app_shell && flutter test
03:53 +273: All tests passed!

$ cd app/packages/core/loom_workflow_engine && flutter test
00:24 +284 ~3: All tests passed!

$ cd app/packages/tooling/loom_ux_judges && flutter test
00:22 +432: All tests passed!

$ cd app/apps/loom_communities_demo && flutter test
02:52 +160: All tests passed!
```

The engine's current total is **284 passed + 3 skipped**, rather than the
ticket baseline of **281 passed + 3 skipped**. That is an increase of three
tests, not a decrease; this ticket did not edit the engine suite. No test total
moved down.

The provisioning package's eight tests cover Cedar's exact ids and stale-admin
absence; all packages/roles; global role uniqueness; service-compatible group
map parsing; Cedar `event_rsvp.create`; the exact four fallback workflows and
84/7 creation counts; dry-run-by-default with zero calls; and applier
idempotency against a fake HTTP server, including UUID correlation and no
delete request checks.

`melos run analyze` was also run from `app`. The new
`loom_app_access_provisioning` package analyzed cleanly, but the workspace run
stopped at the pre-existing `loom_communities_app_shell` analyzer findings
below, so the workspace-wide clean-analyze constraint could not be verified:

```text
10 issues found in loom_communities_app_shell (all info diagnostics):
- 3 × unawaited_futures in lib/src/part18_marketplace_rendering.dart:856-858
- 7 × prefer_const_constructors in existing app-shell test files
```

Those files are outside this provisioning change. They were not modified to
make the workspace analyzer green.

## Not performed

No live App Access, Keycloak, workflow service, or other cluster endpoint was
called. The only network-shaped verification used an in-process fake HTTP
server. The two known stale Cedar role ids and the two `b3-e2e-*` test groups
were not deleted or otherwise changed.
