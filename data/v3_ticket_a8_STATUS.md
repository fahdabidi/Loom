# A.8 Calendar interaction remediation 3b

Implementation commit: `98c3a983d52f3b1fd60a5c084269dbca1388faa4`

This final bounded A.8 evidence pass strengthens the real installed-community
Calendar route without changing production code. The eight focused cases now
prove exact engine-native month/agenda structure and order, continuous
same-persona formula refresh after RSVP changes, the persisted waitlist
transition, both directions of the tournament actor guard, and automatic
selection reconciliation after organizer cancellation.

Validated from `app/packages/core/loom_communities_app_shell`:

- `dart format --output=none --set-exit-if-changed` on the changed A.8 test
  file — pass (unchanged).
- `flutter analyze packages/core/loom_communities_app_shell` — pass (no
  issues).
- A.6 focused suite — 11 passing tests.
- A.7 focused suite — 8 passing tests.
- A.8 focused suite — 8 passing tests.
- Milestone 1.5 focused suite — 3 passing tests.
- Full app-shell `flutter test packages/core/loom_communities_app_shell/test`
  — 68 passing tests.

The frozen Tabletop JSONC SHA-256 is
`822a776f997f6c627c1bc42fb77dd227933630795e27d3d4becce94ad7cc1813`.
Windows Git's baseline-diff check for that fixture against
`c5eb7aa6438f4679e08309f49ad568a985c99b75` exits zero.

Demo b27/b29/b36 remain pre-existing shallow-legacy Calendar debt: when run
independently they are 3 pass / 14 fail. They are outside the engine-native
A.8 route and are not claimed as passing here.

Independent validation retains ownership of A.8 closure.
