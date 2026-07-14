# Ticket status: candidate popup test regression fix

## Item 1 of 1: fix store-sharing contamination + missing pump
Status: blocked
If blocked: `flutter test test/v3_milestone_1_18_stage2b_ballot_ui_test.dart` could not start because `/home/fahd_/flutter/bin/internal/update_engine_version.sh` attempted to write `/home/fahd_/flutter/bin/cache/engine.stamp` and the SDK cache is read-only. `dart analyze` completed with `No issues found!`; no `+N -0` test summary was produced.
