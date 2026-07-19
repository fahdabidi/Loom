# Ticket status: CALR.2 RSVP archetype rewire

## Change applied
Status: done

The `event-rsvp` detail card now resolves the active viewer's hydrated
`event-rsvp-response` row, loads that row's available transitions, and applies
actions to its `$id`. After a successful response mutation, it re-fetches the
calendar event so the hydrated `responses` list and computed RSVP counts are
current before notifying the parent. Non-`event-rsvp` workflow types that use
the same visual card retain their existing event-level action behavior.

## No-response-row edge case

If an `event-rsvp` event has no hydrated response row for the active persona,
the card does not request actions or attempt a transition. It displays: “No
response record is available for you for this event.”

## Verification
dart analyze: clean (run through the bundled Dart SDK; no analyzer issues).

Test suite: not run (0/0): the sandbox blocks Flutter before tests begin
because `/home/fahd_/flutter/bin/cache/lockfile` is read-only. The normal
`dart`/`flutter` wrappers also cannot update the Flutter engine stamp in that
read-only SDK cache. No test failure was observed.

Pre-existing tests adapted: `v3_milestone_a8_calendar_end_to_end_test.dart`
and `v3_milestone_a11_event_rsvp_archetype_test.dart` now assert response-row
states (`respond-*`) and event formulas rather than removed event list fields
and `rsvp-*` transition IDs. The A.6 controlled engine test was updated to
forward the existing `createInstances` API required by the current interface,
which restored analyzer cleanliness.

Real round-trip test: the new A.11 widget test uses seeded
`tabletop-member-14`, confirms `resp-friday-member-14` starts `pending`, taps
`respond-going`, then confirms that exact row is `going`, `goingCount` rose by
one, and the visible Going chip is selected.

## Commit
Staged, not committed. Exact blocker: `fatal: Unable to create
'/mnt/c/Users/fahd_/OneDrive/Documents/Loom/.git/index.lock': File exists.`
No live Git process held the zero-byte lock file, but this sandbox's command
policy rejected the required `rm -f .git/index.lock` recovery step. Per the
repository safety procedure, no other index recovery was attempted.
