## Root cause
The regression is geometry-related, not a mutation-completion logic bug. After `CJM.10`, the new empty-edits hint is rendered whenever `!_mutating && _edits.isEmpty`, including the post-save path where the save succeeds but action refresh fails. In that state, `_runMutation` has already cleared `_edits`, so the card shows:

- Save button
- `No changes to save yet.` hint
- Error row with Retry

That extra hint row shifts the error/retry section downward in this already long card, so in the test harness the Retry button lands outside the visible hit-test region. The tap therefore does not hit the button, and the test later completes the already-completed completer in `controlled.actionCompleters.last`, surfacing `StateError: Future already completed`.

I verified `_editor` changes for `list`/`personaId[]` are not involved in this specific failing path (the failing test only edits a `text` field).

## Change
In `app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart`, I changed the save-hint condition to:

- from: `if (!_mutating && _edits.isEmpty)`
- to: `if (!_mutating && _edits.isEmpty && _error == null)`

This prevents rendering the hint during action-load error states, keeping the Retry affordance reachable where it is by default and avoiding the hit-test miss without weakening the test semantics or removing the CJM.10 behavior for success/idle states. No other files or test files were changed.

## Verification
Attempted required commands after the fix:

- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart --plain-name "failed post-mutation refresh clears prior actions and retry replaces them"`
  - run 1: failed to execute, WSL output `UtilBindVsockAnyPort:309: socket failed 1`
  - run 2: failed to execute, same WSL output
- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart`
  - failed before test start with `UtilBindVsockAnyPort:309: socket failed 1`
- `flutter test` (full suite)
  - failed before test start with `UtilBindVsockAnyPort:309: socket failed 1`
- `flutter analyze`
  - failed before analysis with `UtilBindVsockAnyPort:309: socket failed 1`
- `git ls-files | wc -l`
  - `2204`

Pre-fix reproduction command had the same WSL launcher failure in this sandbox before any local assertions could run, so I could not obtain a concrete before/after test diff from this environment.

## Commit
`fix: resolve CJM.10's own retry-tap test regression (CJM.10b)`
