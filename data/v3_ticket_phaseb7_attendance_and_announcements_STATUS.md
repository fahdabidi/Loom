# Ticket status: Phase B.7 attendance card + announcements

## Change applied
Status: blocked

## Attendance field used
The attendance card reads the existing computed `accepted` field, whose frozen
schema formula is `size(goingPersonaIds)`, and the existing computed `quorumMet`
field, whose formula is `size(goingPersonaIds) >= minimumAttendance`. It reads
the stored `minimumAttendance` field for the denominator. No Dart-side
attendance formula or duplicate list count was introduced.

## Verification
flutter analyze: clean via the direct Flutter Dart SDK analyzer (`No issues
found!`). The Flutter wrapper itself exits before analysis with the known WSL
vsock error: `UtilBindVsockAnyPort:309: socket failed 1`.
Test suite: unavailable (0/0 executed). The focused B.1/Phase B.7 test and the
full `loom_communities_app_shell` suite both exit before test discovery with
that same WSL vsock error. Independent Flutter verification is required.

## Commit
pending until the controlled commit completes.
