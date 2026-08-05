# Ticket status: Phase B.6 engine hydration bug

## Change applied
Status: done

## Root cause confirmation
Confirmed against `LocalWorkflowEngineApi._applyExtendedEffects`: each effect was
being evaluated by `_withComputedFields` from the raw stored instance data, without
calling `_hydrateSourceFields` first. A ballot's query-backed `ballots` field was
therefore absent during `close-vote`, so the formula chain could not produce a real
boolean for the `isTie` branch condition. The fix hydrates a fresh evaluation map
once per effect iteration while leaving the persisted `data` map unchanged.

## Verification
dart analyze (loom_workflow_engine): clean with the direct Flutter Dart SDK
analyzer (no errors; 21 pre-existing style infos in the existing grammar-extension
test). The repository `dart` wrapper itself was blocked by the known WSL vsock
startup error.
loom_workflow_engine test suite: 195/195 passed, including the two new regression
cases. The focused test passed 2/2 in 2.46 seconds.
app-shell votePoll tests: not run; Flutter exited before test startup with
`WSL ... UtilBindVsockAnyPort:309: socket failed 1` (exit 1). Independent
verification is required for those two widget tests.

## Commit
pending until the controlled commit completes.
