# SKILL — Book Club regeneration: release the hold, restore access lists, add create-time identity

**Status:** written 2026-09-25, **NOT dispatched** (user-directed: write and slot, do not dispatch).
**Route:** the Skill only, via `data/call_skill_authoring_agent.sh <target-doc> bookclub-release`.
Community JSON is never hand-authored; copy the Skill's output byte-identically.
**Supersedes the hold in** `TODO-open-detail.md` row-247.

## Why the hold is released — the condition it waited for is met

Row-247 held this regeneration *"until the listing/loan backend exists so the community is regenerated
ONCE against the new API."* **That backend exists and the shell uses it.** Verified 2026-09-25:

- All **four** paths in `listing-loan-api.openapi.yaml` are served by the workflow service —
  `_matchesItemQueue`, `_matchesItemQueueMember`, `_matchesItemQueueAdvance`,
  `_matchesQueueMemberships` — with `item_queue_repository.dart` behind them, Postgres-backed, covered
  by the RLS integration tests. Live on `workflow-service:1.0.9`.
- The client exists: `LoomItemQueueClient` (`part46_item_queue_client.dart`), calling
  `v1/communities/{id}/instances/{id}/queue`.
- The shell wires the archetype to it by **action verb**:
  `_usesServiceItemQueue = _remoteEngine != null && _declaresItemQueue`, where `_declaresItemQueue`
  is any transition with `action == 'join_queue' || 'leave_queue'`
  (`part36_engine_native_marketplace_surface.dart:543-551`), and `_applyTransition:838` routes such a
  transition to the client instead of the engine.

So regenerating **now** *is* regenerating against the new API. Waiting no longer buys what the hold
was for.

## What NOT to restore — and this is the part most likely to be got wrong

**Do not restore `queuedFanIds`, `queueLength`, or `myQueuePosition`.** The shell explicitly
classifies these as legacy:

```dart
bool _isLegacyQueueField(String key) =>
    key == 'queuedFanIds' || key == 'queueLength' || key == 'myQueuePosition';
```

The service owns queue state now; these fields are the superseded in-instance representation.
Restoring them would re-add the old mechanism alongside the new one.

**Corollary that resolves a stale claim:** `join-queue` / `leave-queue` carrying **zero effects is
correct by design**, not the "six dead buttons" defect the listing-loan spec describes. There is
nothing for an effect to write, because the queue is no longer in instance data. **Book Club already
declares both transitions** (verified: 2 occurrences) and **`c0e0355b` never removed them** — the diff
contains no `join_queue`/`leave_queue` lines at all.

**Do not restore the reminder formula machinery** — `reminderAt` (formula), the `send-reminder`
transition with `action: "deliver_reminder"`, or `reminderSentAt`. Their removal was `c0e0355b`'s
entire purpose ("the meeting reminder is declared, not computed") and is correct: the declarative
`reminder` block replaced them, and this repo's own rule is that a thing the platform can compute
belongs to the platform rather than to a formula. The `reminder` block currently on
`book-meeting-rsvp` stays as it is.

## What TO restore

**The reading-material access lists**, which are the genuine remaining loss from `c0e0355b`:
`accessRequestedFanIds` and `approvedFanIds` on `book-reading-material`, plus the seeded instances'
values for them. These have **no dependency on the listing-loan API** and were collateral to a
reminder change.

## What TO add — the create-time identity fix

Scoped 2026-09-08 by the root cause agent (session key `draft-binding-invisibility`) and
**independently confirmed on a device 2026-09-20**: the demo-app harness names all four affected
workflows with the exact mechanism, e.g. *"actorEqualsField nominatorFanId is absent from the instance
data. deriveInstanceRoles did not resolve an actor audience."*

**The obvious fix is wrong and must not be used.** Falling back to `createdByFanId` when the actor
field is null would break an intentional design: the docs deliberately give the **business party
precedence over the creator** (`render-bindings.md`, `guards.md:392`), justified by a charge a board
member creates for another payer. Verified in `role_resolver.dart:22-31`: the loop takes the **first**
`actorEqualsField` guard and `break`s, and `createdByFanId` is used **only when no such guard exists
at all**. So a null field yields no actor and nobody matches — including the author.

**The fix is create-time identity in the PACKAGE.** For `book-nomination`:

1. Add `"prefill": { "nominatorFanId": "$actor" }` to the "Nominate a book" create action.
2. Change `nominatorFanId` to `"writableBy": "platform"` and required.
3. **Remove** the `nominatorFanId = $actor` effect from `submit-nomination` — ownership must survive
   submission and revision — while **keeping** its timestamp effect.
4. Add a draft `creationGuard` requiring the member role plus `actorEqualsField: nominatorFanId`, so
   mismatched ownership fails creation including via a direct API call.

**Apply the same shape to the three siblings**, each confirmed by static sweep *and* by the harness:

| Workflow | Field | Create path |
|---|---|---|
| `book-vote-response` | `voterFanId` | `confirm-vote` |
| `book-shared-library-item` | `ownerFanId` | `publish-listing` |
| `book-search-ai-digest` | `submitterFanId` | `submit-query` |

**Audit by workflow/state/creation-path, not mechanically.** An earlier 19-binding count was an
over-count — several candidates already prefill their identity. The raw audience count is not the
defect count.

## Existing identifiers — all must survive verbatim

- `extensionId`: `ext_neighborhood_book_club` · `communityHandle`: `neighborhood-book-club`
- **Roles (2):** `book-member`, `book-organizer` — a `roleId` rename is a migration, not an edit; do
  not rename either.
- **Tabs (7):** `home`, `books`, `calendar`, `discussions`, `documents`, `marketplace`, `admin`
- **Workflows (12):** `book-nomination`, `book-vote`, `book-vote-response`, `book-meeting-rsvp`,
  `book-meeting-rsvp-response`, `book-notification`, `book-reading-material`,
  `book-shared-library-item`, `book-discussion-message`, `book-selection-publish`,
  `book-search-ai-digest`, `book-export-metadata`

## MANDATORY pre-dispatch checks

1. **Read the restore artifact first.** A verified restore sits at
   `~/.codex-skill-authoring-scratch/bookclub-restore-r2/` on the VM. It was built under the **old**
   assumption that queue-in-JSON was the mechanism, so it may re-add the three legacy fields. Read it
   before dispatching and either exclude those fields or do not use it as the basis.
2. **Diff against `c0e0355b^`, not HEAD.** HEAD is the damaged state; a diff against HEAD reports the
   loss as faithfully preserved. This is the single easiest way to verify this work wrongly.
3. **Restart the validator on `:8787`** if it predates the grammar, and confirm
   `curl .../health` is 200 before trusting any validation result.

## Verification — my own oracle, not the agent's report

- `POST /validate` from my own shell: expect `pass`, 0 errors.
- **Field-by-field diff** confirming all 12 workflows, 2 roles and 7 tabs survive as identical sets —
  deletion is invisible in a validator run, so this is the check that catches a silent re-authoring.
- Confirm the three legacy queue fields are **absent** and both `join_queue`/`leave_queue` transitions
  are **present**.
- Confirm `accessRequestedFanIds` / `approvedFanIds` are back on `book-reading-material`.
- **Regeneration is three steps:** regenerate → publish workflow definitions → install the community
  package. Then `check_permission_parity.sh`. Before installing, confirm every live role in the group
  is package-declared or the generated admin (install *deletes* undeclared group-scoped roles) and
  that the admin's `role_kind` is `community_system_admin`.
- **Sync all three copies of the package** — the app-shell asset, the `docs/references/communities`
  twin (**different filename**: `Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc`),
  and the provenance manifest via `tool/update_community_provenance.dart`. Missing any one turns a
  suite red; this cost a cycle on the Youth Soccer repair.
- **All five suites.** The demo app's single expected failure is
  `b43_book_engine_migration_test.dart`, identified by its **failure message**
  `Found 0 widgets with key 'generic-instance-card-nom-draft-1'` — **and this fix is what should make
  it pass.** If it still fails afterwards, the identity fix did not take effect; that is the signal,
  not a nuisance. Two failures, or a differently-named one, is new.

## Expected outcome

Unblocks three bar rows — `book-nomination`, `book-search-ai-digest`, `book-shared-library-item` —
plus `book-vote-response` (a response workflow, not itself a bar row). `book-nomination`'s repair is
also what retires the demo app's one deliberate failure.

## Follow-up, not this ticket

**Existing invisible rows need a separate backfill.** Prefill only affects future creation, so the
verified draft `..._il5zplsant0a` needs `nominatorFanId` backfilled from its `created_by_fan_id`.
Apply that **only** to established self-owned workflow/state cases — creator-to-business-party copying
is not valid generically, which is the same precedence rule that makes the engine fallback wrong.

## Out of scope

The engine, the app shell, `docs/references/**`, the listing-loan service itself, and the queue's
local-engine fallback (on the local path `_usesServiceItemQueue` is false and Book Club has no legacy
fields, so those buttons are inert there — real, but a separate question from this regeneration).
