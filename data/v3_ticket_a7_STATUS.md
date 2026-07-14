# A.7 Calendar-only render-binding dispatch evidence

## Commits

- Initial production/test: `9cd1ebb8830d4f1af41ec4a1f4a27bca5ab4544a`
- Initial typing follow-up: `64e2eec1d96574728402b6d8da241bcc44fc8047`
- A.7 acceptance remediation: `6dcc6bb0ad1866872c1b64f484969cc2889d5344`
- This evidence update is committed separately after the verification below.

The remediation adds the permanent eight-test A.7 acceptance matrix and one
bounded production fix: a generation check immediately after every awaited
page. A stale completed page therefore cannot issue another pagination query.
The dispatcher remains headless, Calendar-only, and delegates successful
layout entirely to its supplied builder.

## Permanent acceptance coverage

`test/v3_milestone_a7_binding_dispatch_test.dart` contains eight tests that
cover all A.7 requirements:

1. Real local-engine, parsed Calendar and Home-only definitions; three
   Calendar instances over `pageSize: 1` pages, exact four-query pagination,
   exact instance IDs/binding indices/identities, uniqueness, Home exclusion,
   default empty roles with a `role: any` Calendar binding, and an
   unmodifiable builder list.
2. Real parsed state/role resolution: wrong-state and unavailable-role
   bindings are excluded, while two resolver-provided roles retain every
   matching Calendar binding in definition order with exact distinct
   indices/identities.
3. Real parsed dynamic `receiver` audience resolution forwards instance data
   and persona identity: an invited persona sees the selected-audience row and
   an uninvited persona does not, with no injected roles.
4. Each disabled tab (`home`, `marketplace`, `giving`, `admin`, `messages`)
   has a keyed empty successful builder result and exactly zero engine queries.
5. Controlled-page hard failures: a missing workflow definition gives the
   keyed error naming workflow type and instance ID without success publication;
   blank/null-style and repeated cursors give keyed finite pagination errors
   after one and two calls respectively.
6. Retry starts from a first controlled query failure, verifies root/error/
   retry keys and zero successful builders, then retries into a real local
   engine and publishes only its fresh resolved row after exactly two queries.
7. Separate pending engines/personas prove stale A cannot publish or paginate
   after B replaces it; a Calendar request invalidated by Home publishes Home
   empty without another query, and its completed Calendar future cannot return.
8. A real `open -> done` transition proves the builder callback causes an
   authoritative re-query, ignores its deliberately wrong payload, removes the
   now-Home-only row from Calendar, and rejects an old callback after inputs
   advance to a new generation.

The real cases exercise `resolveBindings(machine, state, roles,
instanceData: ..., personaId: ...)`; they verify all matches in query then
definition order. Controlled engines are used only for deterministic error,
cursor, retry, and timing behavior.

## Verification

Run from `app/packages/core/loom_communities_app_shell`:

- `dart format lib test` — exit 0 (51 files; 0 changed).
- `dart format --output=none --set-exit-if-changed lib test` — exit 0 (51
  files; 0 changed).
- `flutter analyze` — exit 0 (`No issues found!`).
- `flutter test test/v3_milestone_a7_binding_dispatch_test.dart` — exit 0,
  exactly 8 tests.
- `flutter test` — exit 0, exactly 60 tests.

Frozen fixture re-proof:

- Windows `certutil.exe -hashfile ... SHA256` reported exactly
  `822A776F997F6C627C1BC42FB77DD227933630795E27D3D4BECCE94AD7CC1813`.
- Windows `git.exe diff --exit-code
  c5eb7aa6438f4679e08309f49ad568a985c99b75 -- "docs/Build Plan V2/Loom
  Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc"`
  — exit 0.
