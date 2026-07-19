# Ticket status: CALR.2h regression test fix

## Fix applied
Status: done

## Verification
dart analyze: not clean (blocked: the Flutter SDK attempted to write `/home/fahd_/flutter/bin/cache/engine.stamp`, but that cache is read-only in this sandbox).
Test suite: blocked: `flutter test` is blocked by the same read-only Flutter SDK cache while updating `engine.stamp`.

## Commit
staged, not committed: pending commit.
