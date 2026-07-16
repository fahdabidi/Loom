# Ticket status: A.11e selectedGame / generic fallback fix

## Fix applied

Status: done

`_EventRsvpDetailCard` now builds a schema-driven fallback fact section for
fields not already represented by its RSVP/capacity UI. It reuses
`WorkflowFactPillRow` and the shared `_isCalendarDetailField` helper, which
honors explicit `detail` contexts or declarative label/icon fields with no
contexts. RSVP counts, capacity/quorum state, and persona response/waitlist
collections remain excluded because the bespoke surface already represents
them. This renders `selectedGame`, `host`, `location`, and later compatible
schema fields without special-casing any one field.

## Verification

dart analyze: not clean; blocked before analysis by `/home/fahd_/flutter/bin/internal/update_engine_version.sh: line 64: /home/fahd_/flutter/bin/cache/engine.stamp: Read-only file system`.

Full `v3_milestone_a8_calendar_end_to_end_test.dart` run: blocked before test discovery by the same read-only Flutter SDK cache error; no pass/fail count was produced.

Full app-shell suite: blocked before test discovery by the same read-only Flutter SDK cache error; no pass/fail count was produced.

Manual verification: the frozen tournament-event schema declares
`selectedGame` with `labelTemplate: "Selected game: {value}"` and
`displayContexts: ["tile", "detail"]`. The new generic fallback includes it
and delegates rendering to `WorkflowFactPillRow`, producing `Selected game:
TBD` for the seeded event.

## Commit

staged, not committed — required Dart/Flutter verification is blocked by the
read-only Flutter SDK cache error above.
