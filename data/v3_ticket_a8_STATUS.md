# A.8 Calendar validation remediation 2

Implementation commit: `485e54ebd64652496c02f2557b4a299678322161`

Validated from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test` — pass (53 files unchanged).
- `dart format --output=none --set-exit-if-changed lib test` — pass (53 files).
- `flutter analyze` — pass.
- A.6 focused suite — 11 passing tests.
- A.7 focused suite — 8 passing tests.
- A.8 focused suite — 5 passing tests.
- Milestone 1.5 Calendar grid — 3 passing tests.
- Full app-shell `flutter test` — 65 passing tests.

The frozen Tabletop JSONC SHA-256 is
`822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
The baseline-diff check for that fixture against
`754f70863cc4bba3404866096f35d6dd30547d74` exits zero.

The historical demo tests `b27_calendar_tab_real_data_test.dart`,
`b29_calendar_complete_interactions_test.dart`, and
`b36_calendar_engine_rsvp_test.dart` remain pre-existing legacy Calendar debt:
they build shallow `experience.workflows` without `workflowDefinitions`, so
`_hasEngineNativeCalendarBinding` is false and they do not enter A.8's route.
Their expectations predate Milestone 1.5 commit `68dd0b0`; this A.8 diff does
not alter legacy fallback behavior. They are not claimed as passing evidence.

Residual review risk: independent validation should retain ownership of the
historical-demo classification and A.8 closure.
