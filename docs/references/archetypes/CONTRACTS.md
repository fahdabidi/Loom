---
spec: 4
doc_version: 1.3.0
status: proposed
last_verified: 2026-08-14
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part36_engine_native_marketplace_surface.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart
  - app/packages/core/loom_workflow_engine/lib/src/api/local_workflow_engine_api.dart
  - docs/references/reference/permissions.md
---

# Archetype contracts

**Status: PROPOSED.** Normative once approved. Defines, for all 13 archetypes, what the archetype
itself owns and what a community declares.

The per-archetype narrative docs (`equipment-loan.md`, `vote-poll.md`, …) describe *how to author*
each one. This file defines *what each one guarantees*, and is the source both the validator and the
install-time derivation read.

## 1. The rule

> A transition that declares an `action` gets that archetype's semantics.
> A transition that declares none is a community-defined action, and derives structurally.

Both are first-class. This is not a closed system with an escape hatch — **most of the corpus is the
second kind**: 201 of the ~450 transitions declare no `action`, including 74 in `approvalQueueItem`
and 43 in `formEntry`.

### Why the vocabulary exists at all

An earlier draft of `permissions.md` justified the closed vocabularies by saying the archetype widgets
"look transitions up by id". Checking the code, that is true of **six ids in one archetype** —
`equipment-loan`'s `borrow`, `claim`, `join-queue`, `leave-queue`, `return`, `return-game` — and those
lookups only control *placement*, not legality. Every other button on every archetype comes from
`availableTransitionsAsync`, as `EquipmentLoanArchetypeCard`'s own comment states.

So the vocabulary is not a rendering constraint. It exists because a named action carries **semantics
the archetype implements for you**: idempotence, per-person bookkeeping, derived read-state, and a
stable permission id. `open` means "record that this person opened it, once" — and the archetype knows
that without the author writing it.

## 2. What an archetype contract specifies

| Clause | Meaning |
|---|---|
| **Actions** | The named vocabulary. Each maps to permission `<archetype_snake_case>.<action>`. |
| **Bookkeeping** | Per-person state the archetype maintains itself. The author never declares these fields, and never writes idempotence guards against them. |
| **Visibility** | Which read model the archetype supports, beyond the community's own `visibleTo`. |
| **Placement** | Any action given a position other than the generic button row. |
| **Custom actions** | Always permitted. Derive structurally; render in the generic row. |

### Structural derivation, for any transition without an `action`

| Structure already on the transition | Derived action |
|---|---|
| a `create` action on a renderBinding | `create` |
| `tone: "destructive"`, or `to` is an `isTerminal` state | `terminate` |
| any other state-changing transition | `advance` |
| read-only binding, no transition | `view` |

## 3. Visibility models

Replaces hand-written `readGuard` formulas. A community declares `visibleTo` per state; the archetype
supplies anything richer.

| Model | Rule | Archetypes |
|---|---|---|
| `roles` | visible to the roles listed in the state's `visibleTo` | all |
| `owner` | plus: whoever created the instance | all |
| `owner_and_shared` | plus: anyone the instance was explicitly shared with | `documentLibrary` |
| `participants` | plus: anyone in the instance's participant set | `discussionThread` |
| `parties` | plus: the two named sides of a request | `approvalQueueItem`, `paymentCheckout` |
| `recipient` | plus: the addressee only | `notificationInbox` |

**All models fail closed.** An identity field that is unset matches nobody. An instance belonging to
no one is visible to no one — which is correct, and is why seed data carrying no identity renders
nothing rather than leaking.

---

## 4. The contracts

### `documentLibrary` — bespoke

Used by 5 communities. All declare `visibility: membersOnly` today.

**Actions (19).** The 16 current, plus three this contract adds because a realistic document lifecycle
cannot be expressed without them:

`view` · `upload` · **`edit`** · **`publish`** · **`delete`** · `archive` · `restore` · `acknowledge` ·
`open` · `download` · `mark_read` · `mark_unread` · `save` · `unsave` · `request_access` ·
`withdraw_access_request` · `grant_access` · `share` · `request_follow_up`

> `edit`, `publish` and `delete` are new. Writing out a normal HOA policy — *"only the Board may
> edit/delete/publish; unpublished documents are Board-only; published ones are readable by all
> members"* — is impossible with the current 16, because documents have no unpublished state and no
> way to leave one.

**Bookkeeping (archetype-owned).** `openedFanIds`, `acknowledgedFanIds`, `savedFanIds`,
`downloadedFanIds`, `accessRequestedFanIds`, `sharedWithFanIds`. The corpus declares all of these by
hand today, plus `memberAccessState` and `downloadState` formulas derived from them. All become
archetype-supplied.

**Visibility:** `owner_and_shared`. Sharing is the archetype's own mechanism — `share` and
`grant_access` populate `sharedWithFanIds`, and the read model honours it. A community that wants
sharing declares `sharing: { enabled: true, grantable: [...] }` and writes no guard.

**Custom actions:** permitted.

---

### `equipment-loan` — bespoke

Used by 4 communities.

**Actions (14):** `view` · `list_item` · `pause_listing` · `delist` · `request` · `decide_request` ·
`withdraw_request` · `claim` · `join_queue` · `leave_queue` · `take_custody` · `return` · `renew` ·
`report_issue`

**Bookkeeping:** `queuedFanIds`, and the current holder. Queue position is derived, not stored.

**Visibility:** `roles` + `owner`.

**Placement — the only archetype with any.** `borrow`/`request` renders contextually; `join-queue` and
`leave-queue` render as one toggle; `return` renders as a distinguished action. Six transition ids are
matched by name in `part36`. Everything else falls to the generic row.

**Custom actions:** permitted, and already relied upon.

---

### `event-rsvp` — bespoke

Used by 8 communities — the most widely used archetype.

**Actions (11):** `view` · `create` · `edit` · `cancel` · `reopen` · `respond` · `withdraw_response` ·
`join_waitlist` · `set_reminder` · `propose_change` · `record_outcome`

**Bookkeeping:** the **response row** — one instance per member per event, whose state is the answer.
`respond` moves that row between response states, so exclusivity is inherent rather than enforced.
Plus `reminderFanIds` on the event, which is genuinely a set and unambiguous.

**Provisioning is archetype-owned, and is a built-in action.** A transition declaring `action: "create"`
on an `event-rsvp` workflow fans out one response row per member, in the response workflow's declared
initial state. The author declares nothing — no effect, no create action on the response type, no member
list.

> This is a deliberate choice between two workable designs, recorded because the rejected one is not
> obviously wrong. The effect grammar *could* have carried a general per-member fan-out op, shaped
> exactly like `generateRecurringInstances` — which already fans out over N dates without naming a single
> date, proving an engine-resolved iteration domain needs no identity values in JSON. That was rejected in
> favour of archetype ownership: a general op would let any community hand-roll per-member creation, which
> is precisely the duplication the archetype exists to absorb. **The identity rule (§9) was never the
> obstacle** — an earlier draft of this contract claimed it was, and that claim was false.

Because provisioning is archetype-owned, `no_creation_path_for_editable_type` does not apply to a
workflow reached through `responseTable.workflowType` — there is deliberately no authored creation path,
for the same reason there is no authored `reminderFanIds`.

> **Corrected 2026-08-14.** An earlier draft listed five per-person arrays here and claimed nothing
> enforced exclusivity. Measuring the corpus disproved it: six of eight communities already use response
> rows (inherent), Masjid Nur's arrays are hand-written correctly, and only Tabletop's `tournament-event`
> genuinely lacks it. The real blocker is different — `respond` maps to three different arrays depending
> on the transition, so the archetype cannot tell which set to fill from the action alone. Rows remove
> that ambiguity instead of encoding it. See [`event-rsvp.md`](./event-rsvp.md) §2.

**Visibility:** `roles` + `owner`.

**Custom actions:** permitted.

> **Response rows.** Per-member responses live in a separate workflow named by
> `responseTable.workflowType`, which inherits this archetype (`permissions.md` §6 step 3b). This shape
> is **required**, not optional — it is what resolves the ambiguity described above, which the archetype
> cannot resolve from the action alone. Six communities already model it, and all six happen to use
> `pending · going · maybe · declined · waitlisted` — a convention, not a requirement. The archetype does
> not fix the state set; communities declare their own.
>
> The engine creates rows eagerly at event creation — one per member, in the response workflow's declared
> initial state. Which states mean "hasn't answered" is the community's choice, declared as
> `responseTable.pendingStates` (a list). `withdraw_response` may target any state that is not already
> the target of a `respond` transition offered from the same source. See
> [`event-rsvp.md`](./event-rsvp.md) §4.

---

### `exportWizard` — bespoke

Used by 6 communities. **All 14 workflows declare `visibility: guarded`** — the only archetype with a
uniform guarded default, which fits: an export contains whatever the exporter could read.

**Actions (11):** `view` · `configure_scope` · `preview` · `approve_redaction` · `run` · `download` ·
`rollback` · `retry` · `cancel` · `record_outcome` · `decide_transfer`

**Bookkeeping:** none per-person. Export state is per-instance, not per-viewer.

**Visibility:** `roles` + `owner`. An export is owned by whoever ran it.

**Custom actions:** permitted.

---

### `searchAiAnswer` — bespoke

Used by 2 communities.

**Actions (7):** `view` · `ask` · `withdraw_query` · `curate` · `add_citation` · `report` · `moderate`

**Bookkeeping:** `savedFanIds`.

**Visibility:** `roles` + `owner` — the asker always reads their own query.

**Custom actions:** permitted.

---

### `votePoll` — bespoke

Used by 2 communities.

**Actions (6):** `view` · `create` · `vote` · `change_vote` · `close` · `publish_result`

**Bookkeeping:** the ballot set, and **who has voted** — but never *how* they voted, which is the one
piece of per-person state this archetype must not expose. Tallies are derived.

**Visibility:** `roles`.

**Custom actions:** permitted.

> `withdraw_vote` was briefly added and removed. Book Club's `cancel-vote` is organizer-only,
> destructive, and moves `open → cancelled` — it calls the poll off for everyone, so it is `close`.

---

### `approvalQueueItem` — generic

Used by 9 communities, with **74 community-defined transitions** — the most customised archetype in the
corpus, and the clearest evidence that a closed vocabulary would be wrong here.

**Actions:** none named. All derive structurally.

**Bookkeeping:** none.

**Visibility:** `parties` — requester and reviewer. This is the archetype behind most of the 18
identity-dependent read guards.

**Custom actions:** the norm. `approve`, `reject`, `assign-pairing`, `approve-and-assign-care-request`
are all community vocabulary.

> **The accepted limit** (`permissions.md` §5): structural derivation cannot separate `approve` from
> `reject` — both are `advance`. A community needing asymmetric decision rights is the signal to
> promote a bespoke archetype, not to complicate the generic path.

---

### `formEntry` — generic

Used by 7 communities, 43 community-defined transitions.

**Actions:** none named.

**Bookkeeping:** `readFanIds`, `signedUpFanIds`, `contactSharingFanIds` appear in the corpus but are
community-declared, and stay that way — a form's fields are its own.

**Visibility:** `roles` + `owner`.

**Custom actions:** the norm.

---

### `discussionThread` — generic

Used by 6 communities, 17 community-defined transitions.

**Actions:** none named.

**Bookkeeping:** `readByFanIds`, `mutedByFanIds` — declared inconsistently today (`readPersonaIds` vs
`readByPersonaIds`, `mutedPersonaIds` vs `mutedByPersonaIds`). Worth standardising into the archetype.

**Visibility:** `participants`. This is Member Social Space's model: a thread is readable by its
participants and nobody else.

**Custom actions:** the norm.

---

### `notificationInbox` — generic

Used by 5 communities, 25 community-defined transitions.

**Actions:** none named.

**Bookkeeping:** `dismissedByFanIds`, `clickedByFanIds`, `impressionedByFanIds`,
`acknowledgedByFanIds` — genuinely per-person and a good candidate for archetype ownership.

**Visibility:** `recipient`. "Only the addressee may dismiss their own notification" is
`permissions.md` §2's canonical example of a per-instance rule that must never become a role permission.

**Custom actions:** the norm.

---

### `paymentCheckout` — generic

Used by 4 communities, 29 community-defined transitions.

**Actions:** none named.

**Bookkeeping:** none per-person.

**Visibility:** `parties` — payer and the collecting party.

**Custom actions:** the norm.

---

### `statusTimeline` — generic

Used by 2 communities, 4 community-defined transitions. Most often a *secondary* binding: a summary
surface beside a bespoke primary one (8 of Data Portability's 9 workflows pair it with `exportWizard`).

**Actions:** none named.

**Bookkeeping:** none.

**Visibility:** inherits its workflow's model.

**Custom actions:** the norm.

---

### `table` — generic

Used by 1 community directly (Riverside's roster), 9 community-defined transitions. Chess Club's
rankings pair it with `formEntry`.

**Actions:** none named. `table` renders as a grid, which reads bespoke, but it has **no dispatcher
case** — its only special treatment is list *layout* (`part32` groups sibling bindings into one
`WorkflowTableArchetypeCard`). Layout is not a semantic contract.

**Bookkeeping:** none.

**Visibility:** `roles` + `owner`. Riverside's roster rows are guardian-scoped, which its
`actorEqualsField` guards express today.

**Custom actions:** the norm — consent application, field redaction, row archival.

---

## 5. What this changes

| Change | Consequence |
|---|---|
| A bespoke transition may omit `action` | Reverses `missing_transition_action` as an error. It becomes a community-defined action. |
| Three new `documentLibrary` actions | `edit`, `publish`, `delete`. |
| Archetype-owned bookkeeping | Removes ~20 hand-declared `*FanIds` arrays and every `actorInList` idempotence guard written against them. |
| `visibleTo` per state | Replaces 40 hand-written `readGuard` formulas, 7 of which are provably broken. |
| Engine enforcement | The archetype applies its own bookkeeping and visibility, instead of each community re-expressing them. |

## 6. Open, and deliberately not decided here

- **Which of the 40 existing read guards fit `visibleTo` versus needing a richer model.** Requires the
  guard-by-guard survey; inventing the model list without it is how the action vocabularies went wrong
  the first time.
- **Migration order.** Bookkeeping ownership and `visibleTo` are separable changes; doing both at once
  touches every workflow in the corpus.
- **The narrative per-archetype docs.** Seven do not exist (`documentLibrary`, `searchAiAnswer`,
  `exportWizard`, `table`, `formEntry`, `statusTimeline`, `notificationInbox`). This file is the
  contract they will describe, not a replacement for them.
