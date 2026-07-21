# Ticket status: CALR.3g5 diagnostics

## Instrumentation added
done

## Ran it myself?
no, sandbox blocked: `/home/fahd_/flutter/bin/internal/update_engine_version.sh: line 64: /home/fahd_/flutter/bin/cache/engine.stamp: Read-only file system`

## Diagnostic output (if you ran it)
The test did not start, so no `CALR3G5_DIAG:` or render-tree output was produced.

## Commit
not committed — staging the instrumented test failed with `fatal: Unable to create '/mnt/c/Users/fahd_/OneDrive/Documents/Loom/.git/index.lock': File exists.` A zero-byte `.git/index.lock` existed and `ps` showed no live Git process. The prescribed `rm -f .git/index.lock`, two-second wait, and one retry could not be performed because the sandbox rejected that command: `CreateProcess { message: "Rejected(\"... blocked by policy\")" }`. No other Git recovery was attempted.
