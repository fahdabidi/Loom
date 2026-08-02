# Ticket status: CAL.Notify2.9 fix7

## Change applied
Status: done

## Design notes

1. `Calendar event detail editors are organizer-only and persist through the engine` had an
   optimistic rendered-title assertion immediately after the Save tap. The engine write and the
   Calendar follow-up query could still be in flight, so the card still showed `Friday game night`.
   The test now uses the bounded real-async/pump poll to require both the rendered title text and the
   persisted instance title to equal `Friday game night updated` before asserting the result and
   organizer-only behavior.

2. `organizer creates an event and one pending response per member` tapped the date-picker day after
   a single `pumpAndSettle`; the `15` finder could still be empty, producing `StateError: Bad state:
   No element`. The creation flow now polls for the actual `15` widget before tapping it, polls for
   the date/time dialog's `OK` action before confirming, and waits for the calendar tab/editor states
   at the preceding navigation steps. The created-event engine poll remains in place before response
   rows are queried.

3. `recurring edit scope saves every occurrence in the series` previously settled only the anchor
   occurrence. The scope helper now accepts the exact occurrence IDs asserted by each scope and polls
   all three series members for the new location in the `all` case, so the assertion cannot read the
   earlier or later member while its bulk write is still pending.

4. `recurring delete scope cancels this and following occurrences` had the same anchor-only settle
   gap after the scope-picker confirmation. Its helper now polls both the anchor and the following
   occurrence until each persisted `currentState` is `cancelled`.

5. `recurring delete scope cancels every occurrence` now passes all three asserted series-member IDs
   to the same condition-based cancellation poll, requiring every persisted state to be `cancelled`
   before the loop of assertions runs.

Additional full-pass hardening: both `_selectAgenda` helpers now wait for the selected-detail widget
   after the row tap; both RSVP action helpers wait for the required `respond-going` input dialog,
   party-size field, and confirm control before interacting; the Calendar tab helpers wait for the
   tab surface; the App Shell persona-visibility test polls for both creation controls to disappear;
   and the lower-event scroll action uses `_pumpUntil` for the row instead of a standalone
   `pumpAndSettle`. The audit found no remaining fixed-iteration mutation-settling tail in either
   requested file; remaining bounded loops are the shared condition pollers or ordinary collection
   iteration.

## Verification

Full a8 test file: blocked before test discovery; pass count unavailable. Flutter could not bootstrap
because `/home/fahd_/flutter/bin/cache/engine.stamp` is read-only (`Read-only file system`).

Full a11 test file: blocked before test discovery; pass count unavailable. Same Flutter SDK bootstrap
error; no test body ran.

Full loom_communities_app_shell suite: blocked before test discovery; pass count unavailable (target
167/167). Same read-only Flutter `engine.stamp` error; no test body ran.

Full loom_workflow_engine suite: 192/192 passed via the direct Dart test runner; unaffected.

flutter analyze (both packages): Flutter wrapper blocked before analysis by the same read-only
`engine.stamp` error. Direct analyzer fallback reported `loom_communities_app_shell`: No issues found;
`loom_workflow_engine`: no errors, with its 21 pre-existing informational `prefer_const_constructors`
hints.

## Commit

staged, not committed + the requested single commit is pending; its SHA cannot be recorded in this
file until Git creates that commit. The exact commit hash will be reported in the final response.
