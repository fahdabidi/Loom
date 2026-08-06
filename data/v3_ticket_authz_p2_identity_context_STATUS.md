# Ticket status: AuthZ.P2

## Change applied
Status: blocked

Added the immutable `ActiveIdentityContext` (`part25_engine_native_community_store.dart:9-34`)
with `accountId`, `authApi`, and `personaId`, plus the stateful `ActiveIdentityScope`
(`part25_engine_native_community_store.dart:38-120`). Its static `of(BuildContext)` accessor is
at line 50; the scope state exposes instance `resolveEnginePersonaId` at lines 74-76 and
`setCurrentActiveAccountId` at lines 78-87, and publishes changes through the private
`InheritedNotifier` at lines 111-120.

Production call sites converted:

- `part01_local_extension_screen.dart:916-923` wraps the `LocalExtensionScreen` subtree in the
  scope. The build-time identity synchronization is now the scoped call at line 933; the two
  action/focus paths use scoped calls at lines 522-524 and 672-674. The identity `BuildContext`
  is threaded through the workflow presenter and action callbacks at lines 848-913 and
  1291-1303.
- `part28_engine_native_calendar_surface.dart:190-207` resolves the dispatcher/content actor
  from `ActiveIdentityScope.of(context)`. Account-name lookup uses the scoped `authApi` at
  lines 1644-1646 and 1918-1921.
- `part32_engine_native_list_surface.dart:89-91` resolves the list actor through the scope.
- `part36_engine_native_marketplace_surface.dart:105-107` resolves the marketplace actor
  through the scope.
- `part25_engine_native_community_store.dart:9-120` contains the context/scope implementation;
  the former module-level `_globalAuthApi`, `_currentActiveAccountId`,
  `setGlobalAuthApi`, `setCurrentActiveAccountId`, and `resolveEnginePersonaId` free functions
  are gone.

Standalone surface test harnesses now provide explicit scopes at
`v3_calnotify2_9_calendar_reminder_test.dart:439-465`,
`v3_milestone_a11_event_rsvp_archetype_test.dart:101-126`,
`v3_milestone_a8_calendar_end_to_end_test.dart:112-139` and its direct surface case at
lines 2691-2709, `v3_milestone_a9_calendar_theming_test.dart:92-115`, and
`v3_milestone_phasec_marketplace_archetype_test.dart:850-872`. A11's seeded account-name
tests pass their auth instance explicitly at lines 497-501 and 538-542; account-specific
calendar identities are explicit at lines 580-585, 658-663, 735-740, and the corresponding
A8/cancellation cases at lines 3014-3020, 3067-3073, 3388-3393, and 3412-3417.
`v3_multiuser_login_test.dart` no longer calls the removed global setters (the former calls
were at lines 200, 228, and 278); its direct engine assertions already pass explicit account
IDs.

The repo-wide search found no remaining read or write of either former global. The
`_EngineNativeCommunityStore._stores` per-community cache at
`part25_engine_native_community_store.dart:122-143` was deliberately left untouched; it remains
the singleton keyed by `extensionId`. No AuthZ.P1 persona-picker or sign-up validation code was
changed, and no access/visibility/membership/invite concept was added.

## Verification

flutter analyze: clean. Using a writable temporary Flutter SDK and the existing package
configuration, `flutter analyze --no-pub packages/core/loom_communities_app_shell` reported
`No issues found!`. The normal sandbox Flutter bootstrap cannot write its read-only
`/home/fahd_/flutter/bin/cache/engine.stamp`; pub-enabled startup was also blocked by the
sandbox's restricted network, so `--no-pub` was required for the clean analyzer run.

Test suite: pass count unavailable (0/183 test cases executed). The full app-shell suite reached
the loader with the writable SDK but every test file failed before discovery because Flutter
could not bind its tester VM socket: `Failed to create server socket (OS Error: Operation not
permitted, errno = 1), address = 127.0.0.1, port = 0` (`+0 -50: Some tests failed`). No test body
ran, so the required 182/183 outcome and the exact single pre-existing
`organizer creates an event and one pending response per member` A11 failure cannot be confirmed
in this sandbox. This is an environment block, not a different observed test result;
independent verification outside the sandbox is required.

## Commit

staged, not committed + required full-suite verification is blocked by the sandbox's denied
Flutter tester loopback socket (`Operation not permitted` on `127.0.0.1:0`).
