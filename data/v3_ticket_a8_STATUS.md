# A.8 Calendar integration remediation 3a

Implementation commit: `b652f1b4e14b0f0831af91f1cf2895f104b37108`

This bounded follow-up retains the real installed community for the production
App Shell route proof, includes the A.8 projection-error repair/Retry proof,
and proves the real empty-engine state. It also retains declarative scalar
detail facts written by effects and reconciles a selected binding whose
authoritative projected date changes.

Validated from `app/packages/core/loom_communities_app_shell`:

- `dart format --output=none --set-exit-if-changed` on the two changed A.8
  files — pass (2 files unchanged).
- `flutter analyze packages/core/loom_communities_app_shell` — pass (no
  issues).
- A.8 focused suite — 8 passing tests.
- Full app-shell `flutter test packages/core/loom_communities_app_shell/test`
  — 68 passing tests.

The frozen Tabletop JSONC SHA-256 is
`822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
Windows Git's baseline-diff check for that fixture against
`c5eb7aa6438f4679e08309f49ad568a985c99b75` exits zero.

Independent validation retains ownership of A.8 closure.
