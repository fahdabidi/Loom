# Ticket status: login test setup fix

## Fix applied
Status: done

Added missing `experienceForExtensionId(...)` call in `v3_multiuser_login_test.dart`'s `setUp`,
between `final community = result.community;` and `workflowEngineForExtensionId(...)`, matching
the a5 test's pattern. This is the function that registers the engine-native store, without which
`workflowEngineForExtensionId` throws `StateError`.

## Verification
dart analyze: **clean** ("No issues found!").
flutter test: **blocked** — sandbox denies server-socket creation (same restriction as all prior rounds).

## Commit
Commit hash: e8396e8
