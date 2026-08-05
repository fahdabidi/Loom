# Ticket status: Phase B.6 close-vote runoff/winner-write

## Change applied
Status: blocked

## Scenarios covered
Added two fresh-install widget scenarios to
`app/packages/core/loom_communities_app_shell/test/v3_milestone_phaseb_votepoll_archetype_test.dart`.
The clear-winner scenario leaves the seeded tally queried as Catan 2,
Wingspan 1, Azul 1, taps the real organizer `Close vote` button, and checks
that the ballot closes with `outcome == 'decided'` while the related
`event-summer-tournament.selectedGame` becomes `catan`. The tie scenario casts
real `cast-vote` transitions for `tabletop-member-07` → `wingspan` and
`tabletop-member-08` → `azul`, then queries the resulting Catan 2 / Wingspan
2 / Azul 2 three-way tie before tapping the same real button. It checks the
original ballot's `runoff` outcome, a new runoff ballot with exactly the
queried tied candidate IDs and the linked event ID, and that the event winner
remains `TBD`.

## Verification
flutter analyze: clean via the underlying Dart analyzer (`No issues found!`).
The standard Flutter launcher is unavailable in this sandbox because it exits
with `WSL ... UtilBindVsockAnyPort:309: socket failed 1`.
Test suite: pass count unavailable. The direct targeted and full `flutter test`
runs exited before test loading with the same WSL vsock error. A direct Dart
test-runner attempt is not a valid Flutter widget run and failed while loading
Flutter's `dart:ui`; no widget assertions ran. The known pre-existing A.11
date-picker flake was not reached, so no new-regression count could be measured.

## Commit
Commit hash: pending until the controlled commit completes.
