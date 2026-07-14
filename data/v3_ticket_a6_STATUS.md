# A.6 generic engine-native instance card — evidence

Original implementation commit: `9fe6d4811e73a95326bb2f2622dc2dd643ba8836`

Lifecycle remediation implementation commit: `854b1ec62fe7d6c9374625aa18730884eabddbfc`

Lifecycle acceptance completion commit: `5522189c4557ef393bafd50aa272b23fe762da53`

Changed production and test files:

- `app/packages/core/loom_communities_app_shell/lib/loom_communities_app_shell.dart`
- `app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart`
- `app/packages/core/loom_communities_app_shell/test/v3_milestone_a6_generic_instance_card_test.dart`

Verification from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test` — exit 0; 49 files formatted.
- `dart format --output=none --set-exit-if-changed lib test` — exit 0; 49 files checked, 0 changed.
- `flutter analyze` — exit 0; `No issues found!`.
- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart` — exit 0; 10 tests passed.
- `flutter test` — exit 0; 51 tests passed.

Acceptance assertions:

- The display test proves the declared icon, `{value}`, `{value.length}`, tile/detail filtering, absent keyed subtrees for null/blank/empty-list/empty-map `hideWhenEmpty` values, and retained `false`/zero pills.
- The real typed-control test opens and confirms the Material date and time dialogs, saves their stable `yyyy-MM-dd`/24-hour `HH:mm` values with textarea, bool, and number edits, and queries `LocalWorkflowEngineApi` for the exact stored results.
- The fresh malformed-number test changes only the number, shows the validation error, and proves the real engine retains its original value.
- Computed and `writableBy: effect` fields accidentally listed as editable have no editor; the picker label from `Date: {value}` is exactly `Date`, while bare `{value}` still uses the generic field-key fallback.
- The text-only Save test and transition-effect controller-resynchronization test remain permanent acceptance coverage.
- The guarded-action test uses real JSON definitions and the local engine to prove the related-instance-list persona guard hides/shows the action and that its state/effects persist.
- Initial unresolved action loading shows the instance-qualified progress key. A controlled engine proves replacing A's instance/persona while its action load is pending rejects A's actions and publishes only B's actions.
- A held A update followed by B replacement proves B is immediately released from mutation progress, can start exactly one current write despite duplicate taps, retains its card, and never receives A's callback/completion.
- A failed post-mutation action refresh shows the instance-qualified error/retry UI with no old action button; retry publishes only the fresh action set.
- A real date dialog opened for A and resolved after replacement cannot edit B, enable B Save, alter B's state, or cause an engine write. The card's shared generation check is used by both date and time picker paths.
- Production code now resets mutation state for a new input generation, uses generation guards across action loads, mutations, and pickers, clears old actions before refresh/failure, keeps progress/error keys instance-qualified, and rebuilds text controllers after successful current-generation engine results.

Frozen Tabletop fixture:

- SHA-256: `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
- `git.exe diff --exit-code c5eb7aa6438f4679e08309f49ad568a985c99b75 -- docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc` — exit 0.

No tab was wired. No A.7 or A.8 work was performed.
