# A.8 Calendar evidence

Implementation commit: `d48fb186267ee11100ab1c0c7f65e247d6ed49d2`

Focused A.8 acceptance suite: 5 passing tests.

Passing checks run from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test`
- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test test/v3_milestone_a6_generic_instance_card_test.dart` (11)
- `flutter test test/v3_milestone_a7_binding_dispatch_test.dart` (8)
- `flutter test test/v3_milestone_a8_calendar_end_to_end_test.dart` (5)

Frozen Tabletop fixture SHA-256: `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
The required baseline fixture diff command exited 0 with no output.
