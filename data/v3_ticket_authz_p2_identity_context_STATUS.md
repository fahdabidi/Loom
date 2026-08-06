# Ticket status: AuthZ.P2

## Change applied
Status: done (required one follow-up fix round, AuthZ.P2 fix1, see below)

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

Sandbox flutter analyze: clean (see original note on the workaround required to get there).
Sandbox test suite: blocked by the sandbox's denied Flutter tester loopback socket, as originally
reported.

**Independent verification (verification agent, outside the sandbox):** first run found a real
regression -- 2 new failures beyond the known a11 flake, both attendee-name resolution in
`v3_milestone_a11_event_rsvp_archetype_test.dart` ("resolve frozen-fixture names by response
state" and "resolve tournament names and retain unknown ids"), root-caused and fixed in a
follow-up ticket (AuthZ.P2 fix1, `data/v3_ticket_authz_p2_fix1_STATUS.md`): an inherited-widget
lookup (`ActiveIdentityScope.of(context)`) was called from `initState()`, which Flutter rejects;
the resulting error was silently swallowed by existing graceful-degradation handling. Moved to
`didChangeDependencies()`. After that fix, independently verified: `flutter analyze` clean, full
`loom_communities_app_shell` suite 182/183 passing (only the known pre-existing a11 flake), both
previously-failing tests confirmed passing individually.

## Commit

This ticket's own code landed in commit `74715e6e` (bundled together with the fix1
ticket-authoring commit, since both were already staged at commit time -- see that commit's
message), and the regression fix landed separately in `eeb95b48`.
