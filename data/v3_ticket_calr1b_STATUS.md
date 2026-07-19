# Ticket status: CALR.1b engine fixes

## Fixes applied

Status: done

- Hydrated query-backed rows expose their own `instanceId` at the reserved `$id` key, and persisted `$id`/`$state` collisions are rejected.
- Related-aggregate guards fail closed when an aggregate or comparison target cannot be resolved. Async transition resolution defers that guard only until the aggregate is computed.

## Verification

dart analyze: not clean. The full package analysis reports 21 pre-existing `prefer_const_constructors` infos in `test/v3_milestone_aprime_grammar_extensions_test.dart`; analysis of `lib` and `test/calr1_engine_test.dart` is clean.

Test suite: pass count (138/138). New coverage: hydrated query-backed rows include `$id`; an `avg` relatedAggregate over an empty matching set denies the transition.

## Commit

staged, not committed — `fatal: Unable to create '/mnt/c/Users/fahd_/OneDrive/Documents/Loom/.git/index.lock': File exists.` The prescribed single retry did not produce a commit; no further git recovery was attempted.
