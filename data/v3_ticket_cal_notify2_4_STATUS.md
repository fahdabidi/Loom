# Ticket status: CAL.Notify2.4

## Change applied
Status: done

## Verification
flutter analyze: not clean — the command exited before Flutter startup with the exact environment error `<3>WSL (169 - ) ERROR: UtilBindVsockAnyPort:307: socket failed 1` and `<3>WSL (174 - ) ERROR: UtilBindVsockAnyPort:307: socket failed 1`; exact analyzer issue count unavailable. Direct Dart analysis completed cleanly with `No issues found!`.
Test suite: 148/148 before (ticket baseline); after count unavailable because `flutter test packages/core/loom_communities_app_shell` exited before test discovery with the same WSL vsock error. Two dedicated-tab widget tests were added and require independent verification.

## Commit
Commit hash pending; the requested commit will include only this ticket's scoped changes.
