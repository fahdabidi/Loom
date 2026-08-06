# Ticket status: AuthZ.P1

## Root cause confirmed

Confirmed. `LoomAuthScreen` did not receive the currently open `LoomExperienceDefinition`,
so `_AccountList._personaLabelFor` and `_SignUpFormState._availableTypes` in
`part31_auth_screens.dart` used the copy-pasted hardcoded `tabletop-member` and
`tabletop-organizer` IDs. The picker therefore ignored the open community's declared
personas, while the existing transition guards continued to reject those undeclared
persona types.

## Change applied

Status: done

- `part01_local_extension_screen.dart`: passes the current `experience` into
  `LoomAuthScreen` and constructs the production `LocalAuthApi` with an independently
  wired resolver that resolves the current community's experience and calls
  `personasForExtensionId`.
- `part31_auth_screens.dart`: threads `experience` through `LoomAuthScreen`, `_AccountList`,
  and `_SignUpForm`; resolves account labels from declared persona `label`/`roleLabel`;
  derives signup IDs and initial selection from the open community's personas; and renders
  persona labels in the dropdown.
- `part30_local_auth_api.dart`: adds the optional `personaResolver` constructor injection;
  when supplied, `signUp` rejects a persona ID absent from that community's resolved list
  with an `ArgumentError` naming both the invalid ID and community. The default null path
  remains unchecked and preserves the existing bare `LocalAuthApi()` behavior.

Regression coverage was added for the non-Tabletop community picker, resolver rejection,
and the null-resolver legacy signup path.

## Verification

flutter analyze: not run in this sandbox. The exact command exited before analysis with:
`/home/fahd_/flutter/bin/internal/update_engine_version.sh: line 64: /home/fahd_/flutter/bin/cache/engine.stamp: Read-only file system`.
The direct Dart analyzer substitute reported `No issues found!`; its process then exited
nonzero because it could not write `/home/fahd_/.dart-tool/dart-flutter-telemetry-session.json`.

Test suite: 0/unknown executed. The exact full-suite command stopped before test discovery
with the same read-only `engine.stamp` error, so the new tests could not be locally confirmed
as passing. The added regression tests are `sign-up persona options come from the open
community declaration`, `persona resolver rejects an undeclared persona type`, and `null
persona resolver preserves unchecked sign-up behavior`; independent verification is required.

## Commit

staged, not committed + required Flutter analyzer/test verification is blocked by the
sandbox's read-only Flutter SDK (`engine.stamp` cannot be written)
