# Ticket status: CALR.2e final fixes

## Fix 1 (cancel-event unreachable)
Status: done
`_loadActions()` now loads the event instance transitions and, when the viewer
has an RSVP response row, that row's transitions, then merges both lists. It
records the IDs returned by the event request. On tap, `_applyTransition()`
routes a transition whose ID is in that event-ID set to the event instance;
all other response-row transitions route to the viewer response row and then
rehydrate the event. This does not special-case `cancel-event`.

## Fix 2 (InputChip cast)
Status: done

## Fix 3 (stale waitlist chip)
Status: done
The synthesized waitlisted chip is omitted when the real action list includes
`respond-going`.

## Verification
dart analyze: clean.
Test suite: blocked before a pass count could be produced. `flutter test`
could not resolve the Flutter SDK's GitHub remote (`Could not resolve host:
github.com`) and then attempted to download packages; no test ran.

## Commit
staged, not committed — full-suite verification is blocked by unavailable
network dependency resolution.
