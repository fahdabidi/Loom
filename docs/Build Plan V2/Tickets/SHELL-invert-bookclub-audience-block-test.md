# SHELL — invert the Book Club audience-block test, which now asserts a defect that is fixed

**Status:** written 2026-09-25, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh` (Claude CLI, sonnet, xhigh). Dart test only.
**Size:** one test case in one file. No product code.

## Why this exists

The Book Club regeneration (`d87f9875`) added create-time identity to four workflows —
`book-nomination`, `book-vote-response`, `book-shared-library-item`, `book-search-ai-digest` — so each
seed now carries its `actorEqualsField` value and an `audience: "actor"` binding resolves for its own
author. That is the fix working.

**One test was written to assert the defect still existed**, and it now fails *because the defect is
gone*:

    app/apps/loom_communities_demo/test/b25_actor_audience_resolution_test.dart:217
    'the held Book Club package records all four audience blocks'

    Expected: an object with length of <4>
      Actual: WhereIterable<B25ActorAudienceRowSelection<String>>:[]

It reads the **shipped** package via `readShippedEvidencePackage`, builds a selection per expected row,
and asserts `selections.where((s) => s.isBlockedByAudience)` has length 4. `selections` is still 4 —
all four rows resolve. The filtered list is now **empty**, because none of them is blocked any more.
Its own name says `the held Book Club package`; the hold was released the same day.

**This is a green signal wearing a red X**, and it is stronger evidence than the suite's previous
known failure was: `b43_book_engine_migration_test.dart`'s owner-visibility check proved the fix for
`book-nomination` alone, while this test proves it for **all four** workflows at once.

## What to build

**Invert this one test case to assert the repaired state, and keep it reading the shipped package.**
Do not delete it — it is the only check that covers all four workflows' create-time identity against
the real asset, and deleting it would leave that population unguarded.

The inverted assertions, for the same four `expectedRows`:

- `selections` still has length 4 (unchanged).
- **none** is blocked: `selections.where((s) => s.isBlockedByAudience)` is empty.
- each selection's `selector` is non-null — the renderer-approved actor resolved.
- each row's identity field is present in the instance data and equals the `book-member` candidate's
  fan id, keyed per row from the existing `expectedRows` table
  (`nominatorFanId`, `voterFanId`, `ownerFanId`, `submitterFanId`).

Rename the case to say what it now proves, e.g. *"the Book Club package resolves all four actor
audiences after create-time identity"*. **The name is load-bearing** — "the held Book Club package"
will read as stale the moment anyone greps for the hold.

## Do NOT touch the other six cases in this file

Lines 11, 68, 100, 115, 156 and 186 build **synthetic** instances and machines via the local `_instance()`
/ `_machine()` helpers. They prove the blocking *mechanism* — that an absent `actorEqualsField` is
blocked with its reason, carries the right cause, and lets the next row run — and that mechanism is
still correct and still needed. They pass today and must keep passing unchanged.

The distinction: those six test **the guard**; the one at :217 tested **the package's state**. Only
the second went stale.

## A consequence to verify, not to change

`requireB25ActorBindingAudience` / `selectB25ActorAudienceRow` are also consumed by
`integration_test/workflow_ui_evidence_test.dart` — the capture harness. With the four seeds repaired,
rows that previously recorded an audience block should now proceed. **Do not modify the harness.**
Just confirm it still compiles against the helper and report whether any of its expectations encode the
blocked outcome for these four; if one does, report it rather than editing it — that is a separate
ticket and it bears on the capture campaign.

## Out of scope

No product code. No package edits — community JSON is Skill-authored only. Do not weaken, delete or
renumber any other assertion, and do not change `b25_actor_audience_resolution.dart` (the helper).

## Verification

- The demo app suite reaches **262 passed, 0 failed, 0 skipped** — this file's seven cases all green.
  That is the first fully green demo-app run this project has had; the previous baseline carried one
  known failure deliberately.
- `flutter analyze` clean on `app/apps/loom_communities_demo`.
- Grep the diff for weakened assertions: the inverted case must gain a positive claim per row, not
  merely drop the negative one. An assertion that only deletes `isBlockedByAudience` proves nothing.
