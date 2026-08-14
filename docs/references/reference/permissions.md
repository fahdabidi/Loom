---
spec: { envelope: 1, experience: 2, grammar: 2 }
doc_version: 1.1.0
status: proposed
last_verified: 2026-08-13
audience: llm-agent
derived_from:
  - docs/API/OpenAPI/identity/app-access-api.openapi.yaml
  - docs/references/archetypes/README.md
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part32_engine_native_list_surface.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart
---

# Permissions — derived, never authored

**Status: PROPOSED.** Nothing here is implemented yet. This defines how a community's roles and
permissions are derived from its JSON, so that community JSON never contains a permission and never
contains user management.

## 1. The rule

> A community's JSON says **which role performs which action**. That statement, and nothing else, is
> what grants a permission.

Community authors never write a permission, a permission id, a role-to-permission mapping, or a user.
They write what they already write today — "the organizer may cancel the event" — and the platform
derives the rest.

Concretely, at community install time:

```
personas[]                     ->  roles registered in App Access
guard.allowedRoleIds on T      ->  that role may perform T
T.action + workflow archetype  ->  the permission T requires
                               ->  grant that permission to that role
```

## 2. Two layers, and only one of them is derivable

Not all access control in a community's JSON is role-based, and only role-based access can be
pre-granted as a permission. Measured across the eleven real fixtures:

| Kind | Occurrences | Resolved by |
|---|---|---|
| `allowedRoleIds` (transition guards), `byRoleIds` (create actions) | **653** | **App Access** — pre-granted permissions |
| `actorEqualsField`, `actorInList` | **243** | **Workflow engine** — per-instance, at runtime |

App Access answers *may this role do this kind of thing in this community*. The workflow engine still
answers *is this specific person the actor, recipient, or queue member of this specific row*. Both are
required, and the second must never be pushed into App Access: "only the recipient may dismiss their
own notification" is a fact about one row, not a role.

A permission check therefore gates whether an action is **offered**; the engine guard still decides
whether it **succeeds**.

## 3. The `action` field

A transition declares which archetype action it is:

```jsonc
{
  "id": "acknowledge-latest-version",
  "action": "acknowledge",
  "label": "Acknowledge",
  "guard": { "allowedRoleIds": ["hoa-member"] }
}
```

This field exists because a transition's `id` cannot identify its action. Real communities name the
same semantic action many ways — `documentLibrary` alone carries `acknowledge-document`,
`acknowledge-latest-version`, `acknowledge-material`, and `acknowledge-resource`. Inferring from the id
would be guesswork, and a wrong guess grants a wrong permission silently.

**`action` is required on transitions of bespoke-archetype workflows, and absent on generic ones.**
See §4 and §5.

## 4. Bespoke archetypes — closed vocabularies

Six families have a dedicated widget that already assumes specific semantics
(`part27_engine_native_binding_dispatcher.dart` switches on them by name, and those widgets look
transitions up by id — `_action('borrow')`, `_action('join-queue')`, `_action('return-game')`). A
widget that hard-codes ids has already fixed the vocabulary; writing it down only makes it checkable.
So for these the action vocabulary is **closed**: the validator rejects an `action` outside the list.

Permission ids are `<archetype_snake_case>.<action>`.

The "Observed transitions" column is the authoritative mapping table, not an illustration — every
bespoke transition in the eleven fixtures resolves through it. Entries ending in `*` are prefix
patterns; a literal id always wins over a pattern, and a longer pattern wins over a shorter one, so
`start-preview-*` beats `start-*`.

### `event-rsvp`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `event_rsvp.view` | read-only bindings |
| `create` | `event_rsvp.create` | `publish-event`, `save-event-draft`, `reserve-facility`, `board-reserve-facility` |
| `edit` | `event_rsvp.edit` | `change-reservation`, `board-change-reservation`, `revise-conflicted-reservation`, `board-revise-conflicted-reservation`, `save-schedule-update`, `reschedule-match`, `make-recurring`, `mark-rescheduled` |
| `cancel` | `event_rsvp.cancel` | `cancel-*` — `cancel-event`, `cancel-meeting`, `cancel-walk`, `cancel-meetup`, `cancel-practice`, `cancel-reservation`, `cancel-tournament`, `board-cancel-reservation` |
| `reopen` | `event_rsvp.reopen` | `reopen-reservation`, `board-reopen-reservation` |
| `respond` | `event_rsvp.respond` | `rsvp-going`, `rsvp-maybe`, `rsvp-not-going`, `accept-match`, `decline-match` |
| `withdraw_response` | `event_rsvp.withdraw_response` | `rsvp-withdraw`, `cancel-rsvp` |
| `join_waitlist` | `event_rsvp.join_waitlist` | `join-event-waitlist` |
| `set_reminder` | `event_rsvp.set_reminder` | `add-reminder`, `add-event-reminder`, `enable-reservation-reminder`, `disable-reservation-reminder`, `send-next-reminder`, `request-calendar-sync` |
| `propose_change` | `event_rsvp.propose_change` | `suggest-new-time` |
| `record_outcome` | `event_rsvp.record_outcome` | `record-result`, `flag-reservation-conflict` |

`cancel-rsvp` and `cancel-tournament` read alike and mean opposite things — withdrawing your own
attendance versus calling off the event for everyone. The literal `cancel-rsvp` entry under
`withdraw_response` is what keeps the `cancel-*` pattern from swallowing it.

`propose_change` exists because `suggest-new-time` is offered to members who cannot `edit`. Mapping it
to `edit` would grant every suggester the power to actually move the event.

### `equipment-loan`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `equipment_loan.view` | read-only bindings |
| `list_item` | `equipment_loan.list_item` | `publish-listing`, `resume-listing`, `resume-giveaway` |
| `pause_listing` | `equipment_loan.pause_listing` | `pause-listing`, `pause-giveaway` |
| `delist` | `equipment_loan.delist` | `delist`, `delist-item`, `delist-giveaway`, `retire-lost-item` |
| `request` | `equipment_loan.request` | `request-loan`, `request-borrow`, `borrow` |
| `decide_request` | `equipment_loan.decide_request` | `approve-loan`, `approve-request`, `decline-loan`, `decline-request` |
| `withdraw_request` | `equipment_loan.withdraw_request` | `cancel-loan-request`, `cancel-request`, `cancel-loan` |
| `claim` | `equipment_loan.claim` | `claim`, `claim-giveaway` |
| `join_queue` | `equipment_loan.join_queue` | `join-queue` |
| `leave_queue` | `equipment_loan.leave_queue` | `leave-queue` |
| `take_custody` | `equipment_loan.take_custody` | `confirm-pickup`, `mark-picked-up` |
| `return` | `equipment_loan.return` | `return`, `return-item`, `return-game`, `return-gear-holder`, `return-gear-owner` |
| `renew` | `equipment_loan.renew` | `renew`, `renew-loan` |
| `report_issue` | `equipment_loan.report_issue` | `report-issue`, `report-lost`, `mark-damaged` |

### `documentLibrary`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `document_library.view` | read-only bindings |
| `upload` | `document_library.upload` | creation actions, `prepare-new-document-version` |
| `archive` | `document_library.archive` | `archive-document`, `archive-material`, `archive-resource` |
| `restore` | `document_library.restore` | `restore-document` |
| `acknowledge` | `document_library.acknowledge` | `acknowledge-document`, `acknowledge-latest-version`, `acknowledge-material`, `acknowledge-resource` |
| `open` | `document_library.open` | `record-open`, `record-embedded-open`, `record-external-open`, `record-resource-open` |
| `download` | `document_library.download` | `record-download`, `record-resource-download`, `confirm-document-download` |
| `mark_read` | `document_library.mark_read` | `mark-document-read` |
| `mark_unread` | `document_library.mark_unread` | `mark-document-unread`, `mark-resource-unread`, `mark-unread` |
| `save` | `document_library.save` | `save-document`, `save-material`, `save-resource` |
| `unsave` | `document_library.unsave` | `remove-saved-document` |
| `request_access` | `document_library.request_access` | `request-access`, `request-document-access`, `request-resource-access` |
| `withdraw_access_request` | `document_library.withdraw_access_request` | `withdraw-access-request` |
| `grant_access` | `document_library.grant_access` | `approve-access`, `grant-document-access` |
| `share` | `document_library.share` | `share-within-club` |
| `request_follow_up` | `document_library.request_follow_up` | `ask-coach-about-document`, `request-resource-follow-up` |

### `exportWizard`

112 observed transition ids collapse to ten actions. The `cancel-*` family alone accounts for 22 ids.

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `export_wizard.view` | read-only bindings |
| `configure_scope` | `export_wizard.configure_scope` | `change-*`, `select-export-scope` |
| `preview` | `export_wizard.preview` | `preview-*`, `start-preview-*`, `open-redaction-preview`, `review-redaction-preview` |
| `approve_redaction` | `export_wizard.approve_redaction` | `approve-redaction`, `confirm-protected-redaction`, `approve-manual-export-review` |
| `run` | `export_wizard.run` | `start-*`, `generate-*`, `confirm-transfer`, `confirm-import-replay`, `enable-transfer`, `submit-transfer-for-verification` |
| `download` | `export_wizard.download` | `download-*`, `request-export-download` |
| `rollback` | `export_wizard.rollback` | `rollback-*`, `start-transfer-rollback`, `complete-transfer-rollback` |
| `retry` | `export_wizard.retry` | `retry-*`, `reopen-export` |
| `cancel` | `export_wizard.cancel` | `cancel-*` (22 ids) |
| `record_outcome` | `export_wizard.record_outcome` | `record-*`, `fail-*`, `complete-*`, `mark-*`, `retire-*`, `lock-schema-listing`, `export-checksum-evidence-record`, `confirm-export-ready` |
| `decide_transfer` | `export_wizard.decide_transfer` | `provider-accept-transfer`, `provider-reject-transfer` |

Four pairs here look alike and resolve by the longer-pattern-wins rule, so they are worth stating
outright:

- `start-preview-export` is a `preview`, not a `run` — `start-preview-*` is longer than `start-*`.
- `start-transfer-rollback` is a `rollback`, not a `run` — literal beats pattern.
- `complete-transfer-rollback` is a `rollback`, not `record_outcome` — literal beats `complete-*`.
- `cancel-transfer-rollback` *is* a `cancel`: it calls off the rollback operation.

`confirm-*` deliberately has no pattern; its three occurrences land in three different actions
(`confirm-transfer` runs, `confirm-protected-redaction` approves, `confirm-export-ready` records), so
each is listed literally.

`record_outcome` deliberately covers the state-machine bookkeeping transitions (`fail-*`,
`record-checksum-pass`, `record-transfer-complete`). These are usually platform- or admin-recorded
rather than member-invoked; grouping them keeps the member-facing vocabulary honest.

### `votePoll`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `vote_poll.view` | read-only bindings |
| `create` | `vote_poll.create` | poll creation actions |
| `vote` | `vote_poll.vote` | `cast-vote` |
| `change_vote` | `vote_poll.change_vote` | vote revision |
| `withdraw_vote` | `vote_poll.withdraw_vote` | `cancel-vote` |
| `close` | `vote_poll.close` | `close-vote` |
| `publish_result` | `vote_poll.publish_result` | result publication |

`cancel-vote` withdraws a ballot; it does not close the poll. `withdraw_vote` keeps that separable
from `close`, which ends voting for everyone.

### `searchAiAnswer`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `search_ai_answer.view` | read-only bindings |
| `ask` | `search_ai_answer.ask` | `submit-query`, `refine-search-query` |
| `withdraw_query` | `search_ai_answer.withdraw_query` | `withdraw-query` |
| `curate` | `search_ai_answer.curate` | `provide-curated-answer`, `save-search-answer`, `edit-digest`, `save-digest` |
| `add_citation` | `search_ai_answer.add_citation` | `add-citation` |
| `report` | `search_ai_answer.report` | `report-stale-citation` |
| `moderate` | `search_ai_answer.moderate` | `hide-search-source`, `reopen-reported-question` |

`curate` covers the digest transitions as well as answer curation: a digest is curated output, and the
capability is the same one. `moderate` is separate from `curate` on purpose — hiding a source and
reopening a reported question act on **other members'** contributions, which is a different grant from
writing your own curated answer.

## 5. Generic archetypes — structural derivation, no `action` field

Seven families have **no dispatcher case**. They reach `GenericWorkflowInstanceCard`, which calls
`engine.availableTransitionsAsync(...)` and renders whatever comes back. Rendering *whatever
transitions exist* is what the archetype **is** — so a closed vocabulary is impossible without
destroying it.

Applies to: `paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`,
`statusTimeline`, `notificationInbox`, `table`.

### Why `table` is here and not in §4

An earlier draft of this document listed `table` as a seventh bespoke family with a two-action
vocabulary, `view` and `publish`. That was wrong, and the corpus is what exposed it: the fixtures
carry **13** `table` transitions — applying consent, redacting fields, archiving roster rows,
requesting guardian updates, revising and discarding ranking drafts — and only `publish-ranking` fits
either action.

The dispatcher settles it. `table` has no `case` and falls through to `GenericWorkflowInstanceCard`,
exactly like the other six. Its only bespoke treatment is **list layout**: `part32` groups sibling
`table` bindings into one `WorkflowTableArchetypeCard` per `(tabId, workflowType)`. That is a
rendering decision about arranging rows, and it makes no assumption whatsoever about what the
transitions mean — the rankings tab even declares the generic
`rendererContractId: 'workflow-status-timeline-actions'`.

A tabular layout is not a semantic contract. `table` derives structurally, and its transitions carry
no `action` field.

For these, **the author writes no `action` field** and the permission is derived from structure the
transition already carries:

| Structure already in the JSON | Derived action |
|---|---|
| a `create` action on a renderBinding | `create` |
| `tone: "destructive"`, or `to` is an `isTerminal` state | `terminate` |
| any other state-changing transition | `advance` |
| read-only binding, no transition | `view` |

Giving four permissions per generic archetype, e.g. `form_entry.create`, `form_entry.advance`,
`form_entry.terminate`, `form_entry.view`.

The signal is already present: the fixtures carry **928** `tone` values and **102** `isTerminal`
declarations. No JSON changes at all.

### The accepted limit

Structural derivation cannot separate `approve` from `reject` — both are `advance`. So
`approvalQueueItem` can express *may decide* but not *may approve but not reject*.

This is accepted deliberately. A reviewer who may approve can realistically reject, and the
alternative is forcing an `action` field onto every generic transition, which would end their
genericity. **If a community genuinely needs asymmetric decision rights, that is the signal to promote
the family to a bespoke archetype** with a closed vocabulary — not a reason to complicate the generic
path.

## 6. Derivation, step by step

Run at community **install** time, not build time, because communities install dynamically.

1. **Create the group.** One App Access group per community: `loom_communities_<communityHandle>`.
2. **Register the roles.** Each entry in `personas[]` becomes a group-scoped role.
3. **For each workflow**, take its archetype from its `renderBindings[].cardSurfaceFamily`.
4. **For each transition**, resolve its action — the declared `action` for a bespoke archetype, or the
   structural rule for a generic one — and map to the permission id.
5. **For each role in that transition's `guard.allowedRoleIds`**, add the permission to that role.
6. **For each `create` action's `byRoleIds`**, add the archetype's `create` permission.
7. **Union per role**, then `setRolePermissions` once per role.

Idempotent: re-installing the same package produces the same grants.

## 7. The platform `admin` role

`admin` is **not declared in community JSON**. It is an app-level template role on
`loom_communities`, assignable in any community's group, and it is the only role present in every
community.

It holds the `community.*` permissions:

| Permission | Capability |
|---|---|
| `community.view` | open the community |
| `community.manage_members` | add and remove members |
| `community.manage_roles` | assign roles to a member |
| `community.invite` | add a member by Fan Passport id |
| `community.manage_settings` | community configuration |

`admin` is a **platform** role and coexists with domain roles: a real person may hold
`[admin, hoa-board]`. No fixture declares a persona named `admin`, so this is purely additive.

User management is an App Shell experience gated on `community.manage_members`, never a workflow.
Adding a member is by **Fan Passport id only** — there is deliberately no user search, so an admin
cannot enumerate or discover users.

## 8. Validator rules

| Rule | Severity |
|---|---|
| `action` present on every transition of a bespoke-archetype workflow | error |
| `action` is in that archetype's closed vocabulary | error |
| `action` present on a generic-archetype transition | error — generic families derive structurally |
| every `allowedRoleIds` / `byRoleIds` entry is a declared role | error |
| a workflow's `renderBindings` disagree on `cardSurfaceFamily` | error — the archetype must be unambiguous |
| a role ends up with zero permissions | warning — probably a role nothing can do |

An unmapped transition is an **error, not a warning**: it would leave a permission ungranted, and the
action would then fail at runtime for reasons no author could see.

## 9. What community JSON must never contain

- a permission or permission id
- a role-to-permission mapping
- a user, account, or Fan Passport id
- a membership or join-approval workflow — that is App Shell plus App Access
- an `admin` persona — it is provided by the platform

Roles are declared. Everything else is derived.
