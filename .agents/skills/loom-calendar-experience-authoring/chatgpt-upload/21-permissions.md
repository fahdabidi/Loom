---
spec: 4
doc_version: 1.6.0
status: current
last_verified: 2026-08-20
audience: llm-agent
derived_from:
  - docs/API/OpenAPI/identity/app-access-api.openapi.yaml
  - docs/references/archetypes/README.md
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part32_engine_native_list_surface.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part12_persona_and_tabs.dart
---

# Permissions — derived, never authored

**Status: CURRENT.** Ratified 2026-08-17: §6's derivation algorithm was reviewed line-by-line against
the real, deployed `CommunityPermissionDeriver` (`services/app-access/.../CommunityPermissionDeriver.java`)
and matches it — group creation, role registration, archetype resolution, transition-to-permission
mapping, and the reduced `POST /v1/apps/{appId}/community-installations` payload shape are all real and
working, not merely proposed. This defines how a community's roles and permissions are derived from its
JSON, so that community JSON never contains a permission and never contains user management.

## 1. The rule

> A community's JSON says **which role performs which action**. That statement, and nothing else, is
> what grants a permission.

Community authors never write a permission, a permission id, a role-to-permission mapping, or a user.
They write what they already write today — "the organizer may cancel the event" — and the platform
derives the rest.

Concretely, at community install time:

```
roles[]                          ->  roles registered in App Access
guard.allowedRoleIds on T        ->  those roles may perform T
T.action + workflow archetype    ->  the permission T requires
                                 ->  grant that permission to those roles
```

## 2. Two layers, and only one of them is derivable

Not all access control in a community's JSON is role-based, and only role-based access can be
pre-granted as a permission. Measured across the eleven real fixtures:

| Kind | Occurrences | Resolved by |
|---|---|---|
| `allowedRoleIds` (transition guards, 582), `byRoleIds` (create actions, 70) | **652** | **App Access** — pre-granted permissions |
| `actorEqualsField` (190), `actorInList` (53) | **243** | **Workflow engine** — per-instance, at runtime |

**A note on naming.** These keys were `allowedPersonaIds` and `byPersonaIds` before **specVersion 4**, and are
`allowedRoleIds` / `byRoleIds` from 4 onward. This document describes 4; see
[`identity-types.md`](./identity-types.md) for the full migration.

The rename is worth a sentence of history, because getting it wrong once already cost something. An
earlier draft of this document wrote `allowedRoleIds` while every fixture still used the old keys — so the keys it
named appeared **zero** times in any package, and a derivation built literally from that text would have
found no guards at all, in any community, and silently derived nothing. It was corrected to match the
fixtures, and specVersion 4 has now moved the fixtures instead. The lesson is the same either way: this document
and the packages must name the same key, and the spec-sync test exists so they cannot drift apart
unnoticed.

The two words are not synonyms by accident. The JSON's `roleId` and App Access's role are the same
thing across a translation that happens at install time, when §6 step 2 registers each entry of
`roles[]` as a group-scoped role. Fan Passport's `Persona` is a **different** concept — a pseudonymity
facet of one human — which is precisely why the grammar stopped calling its role types "personas".

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

### What is normative here, and what is not

**The action list is normative. The "Observed transitions" column is not.**

The validator enforces one thing: that a bespoke transition's `action` is a member of its family's
list. It cannot enforce *which* member, because the id does not determine the answer — that is the
whole reason §3 exists.

The "Observed transitions" column is a lookup aid built from the eleven fixtures. It resolves the
corpus completely and is right the overwhelming majority of the time, so start there. Entries ending
in `*` are prefix patterns; a literal id beats a pattern, and a longer pattern beats a shorter one, so
`start-preview-*` beats `start-*`.

But when the column disagrees with what the transition actually does, **the transition wins**. Its
`guard`, its `from`/`to` states, and its `effects` are the evidence; the column is a guess based on a
name.

`cancel-loan` is the proof that this caveat is load-bearing, not boilerplate:

| Community | Guard | State | What it really is |
|---|---|---|---|
| Garden Club | `actorEqualsField: borrowerFanId` | `reserved` | withdrawing a reservation → `withdraw_request` |
| Book Club | `actorEqualsField: currentHolderFanId` | `borrowed` | ending an active loan → `return` |

Same id, two different capabilities, two different permissions. Treating the column as authoritative
would have collapsed them and granted Book Club's holders the wrong one — reintroducing exactly the
ambiguity the `action` field was introduced to remove.

So: consult the column, then confirm it against the transition. Where a community's usage diverges,
author the action the transition actually performs and say so.

### `event-rsvp`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `event_rsvp.view` | read-only bindings |
| `create` | `event_rsvp.create` | `publish-event`, `save-event-draft`, `reserve-facility`, `board-reserve-facility` |
| `edit` | `event_rsvp.edit` | `change-reservation`, `board-change-reservation`, `revise-conflicted-reservation`, `board-revise-conflicted-reservation`, `save-schedule-update`, `reschedule-match`, `make-recurring`, `mark-rescheduled` |
| `cancel` | `event_rsvp.cancel` | `cancel-*` — `cancel-event`, `cancel-meeting`, `cancel-walk`, `cancel-meetup`, `cancel-practice`, `cancel-reservation`, `cancel-tournament`, `board-cancel-reservation` |
| `reopen` | `event_rsvp.reopen` | `reopen-reservation`, `board-reopen-reservation` |
| `respond` | `event_rsvp.respond` | `rsvp-going`, `rsvp-maybe`, `rsvp-not-going`, `respond-going`, `respond-maybe`, `respond-declined`, `accept-match`, `decline-match` |
| `withdraw_response` | `event_rsvp.withdraw_response` | `rsvp-withdraw`, `cancel-rsvp` |
| `join_waitlist` | `event_rsvp.join_waitlist` | `join-event-waitlist`, `respond-waitlist` |
| `set_reminder` | `event_rsvp.set_reminder` | `add-reminder`, `add-event-reminder`, `set-reminder`, `enable-reservation-reminder`, `disable-reservation-reminder`, `request-calendar-sync` — a member asking to be reminded, about their own row. |
| `send_reminder` | `event_rsvp.send_reminder` | `send-reminder`, `send-next-reminder` — **a human sending one now, on purpose.** An organiser or coach taps it; it is guarded by `allowedRoleIds` and **renders as a button**, like any other role-gated action. Distinct from `deliver_reminder` below: same outcome for the recipient, different actor. |
| `deliver_reminder` | `event_rsvp.deliver_reminder` | **No transition — you do not write one.** Platform-applied, never user-tapped: driven by the workflow's declarative `reminder` block and swept by `LoomReminderSweeper` through `dueNotifications({asOf})`. **No role is granted it**, so it renders as no button anywhere, by the ordinary derivation in §1 rather than any special case. Measured 2026-09-04: **zero of the eleven shipped packages declare a `deliver-reminder` transition**, and none should — the reserved id exists so that a package which ever did declare one resolves to this action instead of `send_reminder`. |
| `propose_change` | `event_rsvp.propose_change` | `suggest-new-time` |
| `record_outcome` | `event_rsvp.record_outcome` | `record-result`, `flag-reservation-conflict` |


**Three reminder actions, and they are genuinely different things.** `set_reminder` is a member asking
to be reminded, about their own row — Garden Club's doc lists "RSVP / **add reminder**" beside RSVP
itself. `send_reminder` is an organiser or coach deciding to send one **now**: a deliberate human act,
role-guarded, and a button like any other. `deliver_reminder` is the platform sending the reminder it
was already asked for, on the schedule the workflow declared.

Both delivery paths are supported on purpose, and a community may use either or both. The automatic
one is configured declaratively:

```jsonc
"reminder": { "anchorDateField": "eventDate", "anchorTimeField": "eventTime", "leadHours": 24 }
```

and swept by `dueNotifications({asOf})`. The manual one is an ordinary role-gated transition. The
recipient sees the same notification either way; what differs is who caused it, and that is exactly
what the permission has to capture.

#### Which one do I write? — the authoring rule

Ask **who decides that this reminder goes out now.** If the answer is a clock, it is automatic. If the
answer is a person, it is manual. A community may declare either, both, or neither, and the two never
substitute for one another.

**Automatic — the platform sends it on schedule.** Declare a `reminder` block on the workflow and
**declare no transition at all**. There is nothing to guard, nothing to grant, and no button appears.

```jsonc
// on the workflow, beside "states" / "transitions"
"reminder": { "anchorDateField": "eventDate", "anchorTimeField": "eventTime", "leadHours": 24 }
```

Optionally add `"enabledField": "reminderEnabled"` to let a member mute their own row — that toggle is
a `set_reminder` action, not this one.

**Manual — a named role sends it deliberately.** Declare an ordinary transition whose id is
`send-reminder` (or `send-next-reminder`) and guard it with `allowedRoleIds` naming the role allowed to
send. It renders as a button for exactly that role, like any other role-gated action.

```jsonc
{
  "id": "send-reminder",
  "label": "Send reminder",
  "from": ["scheduled"], "to": "scheduled",
  "guard": { "allowedRoleIds": ["chess-organizer"] }
}
```

**Do not** reach for `deliver-reminder` as a transition id to mean "send it now" — that id is reserved
for the platform path and grants nobody, so the button you wrote would render for no one. Equally, do
not omit `allowedRoleIds` from a `send-reminder` transition in the hope the platform will fire it: the
sweeper reads the `reminder` block and never a transition, so an unguarded `send-reminder` is simply a
manual button offered to every role.

Both paths in one workflow is a normal, supported combination: the `reminder` block covers the routine
24-hours-before nudge, and a `send-reminder` transition lets the organiser send an extra one when the
venue changes.

**The ids are what separate them, and nothing else does.** `send-reminder` and `deliver-reminder`
differ by one word and are opposite in every way that matters. Guard shape *correlates* — a manual
send carries `allowedRoleIds`, a delivered one does not — but it is a correlation and was never the
rule: it got 8 of the corpus's 10 reminder transitions right and broke on the other two. Chess Club's
`send-reminder` (`chess-organizer`) and Youth Soccer's (`soccer-coach`) are those two, and under the
earlier mapping they would have resolved to `deliver_reminder`, been granted to nobody, and **lost a
primary button an organiser legitimately taps.**

A `deliver_reminder` transition names no role, so §1's derivation grants it to nobody, so it renders
as no button — no special case required. Until 2026-08-20 the app shell instead kept a hardcoded list
of transition **ids** to hide, which silently hid nothing in the eight communities that spell theirs
differently.
`cancel-rsvp` and `cancel-tournament` read alike and mean opposite things — withdrawing your own
attendance versus calling off the event for everyone. The literal `cancel-rsvp` entry under
`withdraw_response` is what keeps the `cancel-*` pattern from swallowing it.

`propose_change` exists because `suggest-new-time` is offered to members who cannot `edit`. Mapping it
to `edit` would grant every suggester the power to actually move the event.

### `calendar`

A dated item on a schedule that nobody RSVPs to: a prayer time, a fixture, a bin collection, a
volunteer shift. It is `event-rsvp` with the attendance removed, and the overlap is not accidental —
the two share every action except the three that exist to record who is coming.

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `view` | `calendar.view` | read-only bindings |
| `create` | `calendar.create` | scheduling the item — `add-prayer-time`, `schedule-shift`, `publish-fixture` |
| `edit` | `calendar.edit` | correcting a detail without moving it |
| `cancel` | `calendar.cancel` | calling the item off; the date stays visible as cancelled |
| `reopen` | `calendar.reopen` | reversing a cancellation |
| `set_reminder` | `calendar.set_reminder` | a member asking to be reminded |
| `deliver_reminder` | `calendar.deliver_reminder` | **platform-applied, never user-tapped** — the same rule as `event_rsvp.deliver_reminder`: no role is granted it, so it renders as no button by §1's ordinary derivation |
| `propose_change` | `calendar.propose_change` | suggesting a new time without the power to move it |
| `record_outcome` | `calendar.record_outcome` | what happened — attendance counts, a result, a note |

**Why this is a separate family and not an `event-rsvp` with unused actions.** A closed vocabulary is
a statement about what a workflow *can* do, and the derivation in §1 reads it literally. Modelling a
prayer time as `event-rsvp` would make `respond`, `withdraw_response` and `join_waitlist` legal
actions for it — a community could grant `event_rsvp.respond` on a prayer time and the grammar would
allow it. The absence of those three is the whole content of this family.

**It carries no attendance bookkeeping.** `event-rsvp` owns `goingFanIds`, `maybeFanIds`,
`notGoingFanIds` and `waitlistFanIds`; `calendar` owns only `reminderFanIds`. A community that finds
itself wanting an attendance list on a `calendar` item has chosen the wrong family, and the fix is to
change the family rather than to declare the arrays by hand.

**`eventDate` and `eventTime` are part of the contract, not a convention.** A calendar item declares
both, spelled exactly that way, because the app shell's calendar surface reads those two keys to
place an item on a grid. This was true before this family existed and was undeclared: Masjid Nur's
volunteer shift used `shiftDate`/`shiftTime`, bound to a calendar-rendered tab, and silently lost its
month grid because nothing said the names were load-bearing. Declaring them here is what makes that
checkable instead of folklore.

### `equipment-loan`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `create` | `equipment_loan.create` | listing an item for loan or giveaway. Declared by a `kind: "create"` render-binding action; `list_item` below publishes an existing listing and is not the same act. |
| `view` | `equipment_loan.view` | read-only bindings |
| `list_item` | `equipment_loan.list_item` | `publish-listing`, `resume-listing`, `resume-giveaway` |
| `pause_listing` | `equipment_loan.pause_listing` | `pause-listing`, `pause-giveaway` |
| `delist` | `equipment_loan.delist` | `delist`, `delist-item`, `delist-giveaway`, `retire-lost-item` |
| `request` | `equipment_loan.request` | `request-loan`, `request-borrow`, `borrow` |
| `decide_request` | `equipment_loan.decide_request` | `approve-loan`, `approve-request`, `decline-loan`, `decline-request` |
| `withdraw_request` | `equipment_loan.withdraw_request` | `cancel-loan-request`, `cancel-request`, `cancel-loan` (community-dependent — see the caveat in §4's preamble) |
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
| `create` | `document_library.create` | adding a document. Declared by a `kind: "create"` render-binding action; `upload` below is the *content* step and is a different capability. |
| `view` | `document_library.view` | read-only bindings |
| `upload` | `document_library.upload` | creation actions, `prepare-new-document-version` |
| `edit` | `document_library.edit` | revising a document's own content or metadata |
| `publish` | `document_library.publish` | moving a document out of an unpublished state |
| `delete` | `document_library.delete` | removing a document outright, as distinct from `archive` |
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
| `create` | `export_wizard.create` | starting a new export. Declared by a `kind: "create"` render-binding action rather than by a transition — the wizard's own steps are the transitions below. |
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
| `close` | `vote_poll.close` | `close-vote`, `cancel-vote` |
| `publish_result` | `vote_poll.publish_result` | result publication |

An earlier draft added a `withdraw_vote` action for `cancel-vote`, on the reasoning that it withdraws
one ballot rather than closing the poll. That reasoning was wrong, and checking the only fixture that
carries the id disproves it: Book Club's `cancel-vote` sits on the ballot workflow itself, is
`allowedRoleIds: ["book-organizer"]`, is `tone: "destructive"`, and moves `open → cancelled` —
directly alongside `close-vote`, which moves `open → closed`. It calls the poll off for everyone.

Both are the organizer ending the poll, differing only in whether a result stands. Per §5's
accepted-limit reasoning, an organizer who may close may realistically cancel, so they share `close`
and `withdraw_vote` is removed.

The genuine member-level withdrawal does exist — Book Club's `clear-vote` — but it lives on the
`book-vote-response` workflow, which is `formEntry`, so it derives structurally and never needed a
`votePoll` action at all.

### `searchAiAnswer`

| Action | Grants | Observed transitions it covers |
|---|---|---|
| `create` | `search_ai_answer.create` | opening a new question surface. Declared by a `kind: "create"` render-binding action rather than by a transition, which is why the column below lists none — §1's derivation grants it from the action's `byRoleIds`. |
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
2. **Register the roles.** Each entry in `roles[]` becomes a group-scoped role.
3. **For each workflow**, resolve its archetype:
   a. If any `renderBindings[].cardSurfaceFamily` is a bespoke family, that is the archetype. A
      workflow may also carry generic bindings; they do not compete (see §8).
   b. Otherwise, if the workflow is named by some binding's `responseTable.workflowType`, it
      **inherits that binding's archetype**.
   c. Otherwise it is generic, and §5's structural rule applies.
   d. A workflow with no bindings and no `responseTable` owner derives nothing at all.
4. **For each transition**, resolve its action — the declared `action` for a bespoke archetype, or the
   structural rule for a generic one — and map to the permission id.
5. **For each role in that transition's `guard.allowedRoleIds`** — registered in step 2 — add the
   permission to that role.
6. **For each `create` action's `byRoleIds`**, add the archetype's `create` permission.
7. **Union per role**, then `setRolePermissions` once per role.

Idempotent: re-installing the same package produces the same grants.

### Where this runs

In the **App Access service**, via `POST /v1/apps/{appId}/community-installations`
(`app-access-api.openapi.yaml`). Not in the client, and not in the authoring toolchain.

The caller submits only the derivation inputs — roles, and per workflow the resolved archetype plus each
transition's `action`, `tone`, `isTerminal` and `allowedRoleIds`. It does not submit the whole package:
App Access has no business parsing render bindings, theming, or seed data, and accepting them would make
it a second consumer of the full grammar.

The rules themselves — archetype resolution, the closed vocabularies, §5's structural rule — are shared
with the community-package validator as a generated vocabulary artifact rather than implemented twice.
That matters more than it sounds: this repo has twice been broken by the same rules living in two places
and drifting, and a derivation that disagreed with the validator would grant permissions for a package
the validator had already passed.

Reconciliation is by replacement, not by append. A role that disappears from a package has its grants
withdrawn and is reported in `removedRoleIds`, because a retired role left holding live permissions is
exactly how stale access accumulates unnoticed.

### Why step 3b exists

Without it, responding to an event derives no permission in five of the eleven communities.

Those five put per-member responses in a separate `*-response` workflow with `"renderBindings": []`,
reachable only as the parent `event-rsvp` binding's `responseTable` target. An earlier draft read the
archetype off `renderBindings` alone, so those workflows had no archetype, were neither bespoke nor
generic, and fell through every rule — leaving **26 transitions ungated**, among them `respond-going`,
the single most common member action in the product.

The same capability *does* derive `event_rsvp.respond` in Masjid Nur and Tabletop Club, where
`rsvp-going` sits on the bespoke workflow directly. Tabletop carries both shapes at once. Identical
member capabilities must not be gated in one community and ungated in another because of an authoring
choice about where the rows live, and `responseTable.workflowType` names the link explicitly, so the
inheritance is derivable rather than guessed.

Step 3d is deliberate and distinct: the three `mark-read` notification workflows have no bindings and
no `responseTable` owner. They are driven by effects from other workflows, are never rendered as an
invocable surface, and correctly derive nothing.

## 7. The `admin` role — a system-created default per community

`admin` is **not declared in community JSON**, and the Skill never authors it. It is a **system
default**: when a community is created — i.e. when its package is installed — the platform
automatically creates the community's admin role, scoped to that community's group. It is the seed
root the community needs to start operating, and every community gets exactly one.

Its id is derived from the community, as `<communityHandle>-admin` (the group is
`loom_communities_<communityHandle>`, so Garden Club's is `garden-club-admin`). Nothing in the package
names it; the identifier is a deterministic function of the community, so the same community always
resolves to the same admin role.

It holds the `community.*` governance permissions, and only the admin role holds them:

| Permission | Capability |
|---|---|
| `community.view` | open the community |
| `community.manage_members` | add and remove members |
| `community.manage_roles` | assign roles to a member |
| `community.invite` | add a member by Fan Passport id |
| `community.manage_settings` | community configuration |

**Governance is generated data, owned by community creation — not archetype-derived and not
hand-granted.** `community.*` is emitted into the permissions vocabulary as its own family (it is not
tied to any workflow archetype), and the create-a-community step both **creates** the `<handle>-admin`
role and **grants** it those five. Because creation owns this role, re-running it is safe: it re-creates
or preserves the admin role rather than treating it as undeclared, and it grants `community.*` rather
than stripping them. This is the mechanism that lets the provisioning tooling reproduce the full
authorization state without a manual step.

`admin` coexists with the domain roles a package does declare: a real person may hold
`[garden-club-admin, garden-coordinator]`. It is additive — a package's own `roles[]` is unchanged by
its existence.

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
| a workflow's `renderBindings` mix one bespoke family with generic ones | allowed — the bespoke family is the archetype |
| two or more bespoke families, and the declared actions fit only one of them | allowed — that family is the archetype |
| two or more bespoke families, and the declared actions fit none or several | error — the archetype is genuinely undecidable |
| a role ends up with zero permissions | warning — probably a role nothing can do |

An unmapped transition is an **error, not a warning**: it would leave a permission ungranted, and the
action would then fail at runtime for reasons no author could see.

### Why the family rule is split in two

An earlier draft made *any* disagreement among a workflow's `renderBindings` an error. Measured against
the corpus, that rule rejects **27 of the fixtures' workflows** — and 26 of those rejections are wrong.

Mixing families is the normal, correct shape: a workflow renders its primary surface on one tab and a
summary on another. Data Portability alone has eight workflows that pair `exportWizard` with a
`statusTimeline` home-tab summary. Nothing about that is ambiguous — only one family is bespoke, and it
is the archetype.

Exactly **one** workflow in the corpus names two bespoke families: Tabletop Club's `tournament-event`
(`event-rsvp` plus a `votePoll` attendance/quorum summary).

An earlier draft of this rule made that an error too, on the reasoning that two bespoke families are
inherently ambiguous. Implementing the rule disproved it. `tournament-event`'s three transitions
declare `respond`, `withdraw_response` and `cancel` — **none of which exists in `votePoll`'s
vocabulary** — so the archetype is decidable, and the dispatcher not only tolerates this shape but
special-cases this very workflow by name. Flagging it would have condemned a supported pattern.

So the test is not "how many bespoke families are named" but "can the declared actions belong to more
than one of them". Resolve by finding the family whose vocabulary accounts for every action the
workflow declares: exactly one such family means the archetype is determined; none or several means it
genuinely is not, and the workflow should be rewritten rather than guessed at. A workflow that declares
no actions yet is also undecidable, which is the correct answer — it is unauthored.

This matches the dispatcher, which switches on `resolved.binding.cardSurfaceFamily` — **per binding**,
not per workflow. Archetype is a property of a binding; a workflow has an archetype only insofar as its
bespoke binding gives it one.

## 9. What community JSON must never contain

- a permission or permission id
- a role-to-permission mapping
- a user, account, or Fan Passport id
- a membership or join-approval workflow — that is App Shell plus App Access
- an `admin` role — it is provided by the platform

Roles are declared. Everything else is derived.

### The membership rule is already structurally satisfied — judge it by mechanism, not by name

No fixture grants membership, and none can. The workflow grammar has no effect op that could: the
complete set in use is `set`, `append`, `appendUnique`, `removeValue`, `createInstance`,
`transitionRelated`, `branch`, `generateRecurringInstances`, `removeFromTileGrid`. Of the 74 effects
that assign an identity-shaped key, every one writes a `fanId` into a **field on an instance** — who
reserved the room, who is holding the tool, who reviewed the request. That records a fact about a row;
it grants nothing.

Scanning workflow *names* for `join`, `signup` or `membership` finds only false positives, and it has
already produced two:

- **`soccer-guardian-join-approval`** is player registration, not community joining. Its opening
  transition is guarded `allowedRoleIds: ["soccer-guardian"]`, so the actor must already be a
  guardian in the community before they can start it. `approve-request` is gated on a formula requiring
  the waiver acknowledged and the fee paid, and its effects create a roster row and a redaction row.
  Waiver, payment, coach review, roster — a domain process end to end, and exactly the kind this
  document means to keep as a workflow.
- **`mosque-volunteer-signup`** is signing up for volunteer shifts. Fully generic, grants nothing.

Both must stay. The rule to apply is: *does any effect grant a role, a membership, or app access?*
Today nothing can, so the answer is structurally no — and if a future effect op could, that op is what
needs gating, not the workflow's name.
