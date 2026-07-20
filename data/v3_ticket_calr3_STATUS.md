# Ticket status: CALR.3 new event creation

## Button/dialog
Status: done
Placed a single `New event` button above the calendar month navigation. It is shown only for an `event-rsvp` resolved binding whose `creatable.byPersonaIds` includes the viewer's persona type, and opens a separate schema-driven creation dialog.

## Creation flow (createInstance + createInstances)
Status: done
The dialog creates the event first, then creates one `event-rsvp-response` row per account returned for the installed community extension ID. A partial response-row failure is shown explicitly in the dialog, and successful creation reloads through the existing binding dispatcher callback.

## New test
Status: done
Extended `v3_milestone_a11_event_rsvp_archetype_test.dart` with organizer creation/persisted-response assertions and non-creatable-persona visibility coverage.

## Verification
dart analyze: clean (using the SDK Dart binary; it also emitted a non-fatal telemetry-cache read-only warning after reporting no issues).
Test suite: blocked: `flutter test` cannot start because `/home/fahd_/flutter/bin/cache/engine.stamp` is read-only.

## Commit
Pending git staging and commit.
