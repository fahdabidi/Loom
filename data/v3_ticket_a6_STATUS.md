# A.6 generic engine-native instance card — evidence

Implementation commit: `9fe6d4811e73a95326bb2f2622dc2dd643ba8836`

Changed production and test files:

- `app/packages/core/loom_communities_app_shell/lib/loom_communities_app_shell.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart`
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a6_generic_instance_card_test.dart`

Verification from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test` — exit 0; 49 files formatted.
- `dart format --output=none --set-exit-if-changed lib test` — exit 0; 49 files checked, 0 changed.
- `flutter analyze` — exit 0; `No issues found!`.
- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart` — exit 0; 3 tests passed.
- `flutter test` — exit 0; 44 tests passed.

Acceptance assertions:

- The isolated card maps every display schema entry into the shared fact-pill renderer, including icon, `{value}`, `{value.length}`, empty filtering, and tile/detail contexts.
- Editable controls are schema-dispatched for text, textarea, date, time, bool, and number; valid updates use `updateInstanceFields`, and invalid numbers do not write.
- Actions are obtained only through `availableTransitionsAsync`; the permanent test proves a JSON related-instance list guard hides/shows a transition and that transition state/effects persist through the real local engine.
- The widget uses mounted/request-token safety, one in-flight mutation, deterministic semantic keys, progress state, and retryable errors.

Frozen Tabletop fixture:

- SHA-256: `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
- `git.exe diff --exit-code c5eb7aa6438f4679e08309f49ad568a985c99b75 -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` — exit 0.

No tab was wired. No A.7 or A.8 work was performed.
