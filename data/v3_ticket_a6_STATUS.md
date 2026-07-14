# A.6 generic engine-native instance card — evidence

Original implementation commit: `9fe6d4811e73a95326bb2f2622dc2dd643ba8836`

Lifecycle remediation implementation commit: `854b1ec62fe7d6c9374625aa18730884eabddbfc`

Changed production and test files:

- `app/packages/core/loom_communities_app_shell/lib/loom_communities_app_shell.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart`
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a6_generic_instance_card_test.dart`

Verification from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test` — exit 0; 49 files formatted.
- `dart format --output=none --set-exit-if-changed lib test` — exit 0; 49 files checked, 0 changed.
- `flutter analyze` — exit 0; `No issues found!`.
- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart` — exit 0; 4 tests passed.
- `flutter test` — exit 0; 45 tests passed.

Acceptance assertions:

- The display test proves the declared icon, `{value}`, `{value.length}`, tile/detail filtering, absent keyed subtrees for null/blank/empty-list/empty-map `hideWhenEmpty` values, and retained `false`/zero pills.
- The editing tests prove a text-only edit enables Save and persists through the real local engine, textarea/bool/number persistence, invalid-number rejection without an engine write, and transition-effect controller resynchronization for editable text and number fields.
- The guarded-action test uses real JSON definitions and the local engine to prove the related-instance-list persona guard hides/shows the action and that its state/effects persist.
- Production code now uses one input generation across action loads, mutations, and pickers; stale completions are suppressed, refresh clears old actions before loading/failure, progress/error keys are instance-qualified, and successful engine results rebuild text controllers.

Frozen Tabletop fixture:

- SHA-256: `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
- `git.exe diff --exit-code c5eb7aa6438f4679e08309f49ad568a985c99b75 -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` — exit 0.

No tab was wired. No A.7 or A.8 work was performed.
