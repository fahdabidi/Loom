# Ticket status: CALR.3b-fix

## Fix applied
done

## Verification
dart analyze: not clean (blocked: WSL `UtilBindVsockAnyPort:307: socket failed 1`).
Test: blocked: WSL `UtilBindVsockAnyPort:307: socket failed 1`.
Full suite: not attempted (the targeted test could not start because of the same WSL vsock error).

## Commit
staged, not committed: blocked because the required `git ls-files | wc -l` sanity check emitted WSL `UtilBindVsockAnyPort:307: socket failed 1` and returned `0`, not the expected thousands of tracked files.
