# Ticket status: CALR.3h1b

## Fix applied
done

## Verification
dart analyze: not clean (blocked before analysis: `/home/fahd_/flutter/bin/internal/update_engine_version.sh` could not write `/home/fahd_/flutter/bin/cache/engine.stamp`: Read-only file system).
Single-file test run (short timeout): blocked: Flutter could not update the read-only SDK engine stamp before the test command started.

## Commit
staged, not committed: the target test file already has a pre-existing staged CALR.3h1 diff (114 added lines), and the index also contains staged production and unrelated changes. Committing this path would include that pre-existing work, so it was preserved rather than committed.
