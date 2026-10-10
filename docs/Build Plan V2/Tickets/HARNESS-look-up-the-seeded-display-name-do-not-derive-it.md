# HARNESS — look up the seeded fan's display name, do not derive it from the slug

**Status:** written 2026-10-05. **DISPATCHED AND SHIPPED as `e2c63f0d`** -- verified by my own five-suite run and A/B, not on the agent's word. Device-measured effect: stalls 11 to 1; zero waits remain on a derived name. Kept for its reasoning; do NOT re-dispatch.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Evidence:** Garden/Book precheck at `6097767f`, scratch evidence root. `exit=0`, `workflows=17`,
`b25Proven=0/16`, `b25RowExecutionFailed=3`, 11 × `row_stalled_inconclusive`, `screenshots=15/15`,
zero `found modal-barrier`, canonical `Evidence/` untouched.

## First, what `d4430982`'s beats fixed — confirmed on device, do not redo

**Reach went 2 → 17 workflows and the run now completes (`exit=0`).** More decisively: **not one stall
is a watchdog expiry any more.** Every stall is the *inner* 2m45s budget —

    10 × bounded wait (2m 53s elapsed, limit 2m 45s)
     1 × bounded wait (2m 45s elapsed, limit 2m 45s)

— against the previous run where the limiter was `3m 0s / limit 3m 0s`. That class is closed, and the
cascade stays closed too (zero modal-barrier leaks).

## The defect: 10 of the 11 stalls are one cause

Every one of those 10 waits for a **second-holder** account row that cannot exist as named:

    6 × Waiting for: widgets with type "ListTile" ancestor of text "Book Member 2"
    2 × Waiting for: widgets with type "ListTile" ancestor of text "Garden Member 2"
    2 × Waiting for: widgets with type "ListTile" ancestor of text "Book Organizer 1"

The harness **derives** that text by title-casing the slug — `_seededEvidenceFanDisplayName(slug)`,
used as finder text at `test/workflow_ui_test_harness.dart:2321, :2325, :2333`. The stored names
disagree, and I read them from `loom_fan_passport` rather than off the screen:

| fan_id | stored `display_name` | harness expects |
|---|---|---|
| `fan-garden-member-1` | `Garden Member 1` | Garden Member 1 ✅ |
| `fan-garden-member-2` | **`Test garden-member-2`** | Garden Member 2 ❌ |
| `fan-book-member-2` | **`Test book-member-2`** | Book Member 2 ❌ |
| `fan-book-organizer-2` | **`Test book-organizer-2`** | Book Organizer 2 ❌ |
| `fan-garden-coordinator-2` | **`Test garden-coordinator-2`** | Garden Coordinator 2 ❌ |

So the **first** holders were seeded title-cased and the **second** holders were seeded as
`Test <slug>`. Identity 1 resolves; identity 2 waits out its full 2m45s for a row that reads
something else. This only began to bite now because two-identity arrangement is the first thing that
ever needed a *second* holder.

**This is the "a derived identifier looks like its source and is not it" class.** The harness owns the
slug; the **backend owns the display name**, and deriving one from the other is an assumption about
data this code does not control.

## The change

**Look the name up instead of deriving it — and look it up from the list the chooser itself renders.**

Use **`authApi.listAccounts(...)`**, not `listCommunityMembers`. That matters: `listAccounts` is the
*writer* of the rows being searched (`_showActorIdentityPicker` awaits it before `showDialog`), and
`LoomAccount` already carries both halves of the join —

    class LoomAccount { final String accountId; final String displayName;
                        final String roleId; final MembershipStatus status; }

— so match `accountId` against the row's fan id and use that entry's `displayName` as the finder
text. `listCommunityMembers` is a *parallel* directory; joining against it would re-introduce the
same hazard one layer over, because nothing guarantees the two sources render the same string. Find
the writer, read what it puts there, then join.

**The handle already exists:** `screen.authApi` (`test/workflow_ui_test_harness.dart:2372, :2646`).
Note `:2372-2379` is the **local** path and deliberately throws unless the api `is LocalAuthApi`, so
the remote path needs its own access rather than reusing that block.

- **Keep the slug as the identity key.** Only the *display* string comes from the directory; the fan
  id stays authoritative for who is acting, and the existing `signIn` accountId-vs-token-`fanId`
  check stays untouched.
- **Fail loudly and immediately if the lookup finds no such fan**, naming the fan id. That is a
  seeding gap, and it must not look like a 2m45s UI stall — the whole cost of this defect was that a
  data mismatch presented as a timeout.
- **Do not keep the derivation as a fallback.** A fallback here would silently restore the exact bug
  for any fan whose stored name differs, which is the "fallback path is where a capability silently
  fails to exist" shape.

## The alternative I am NOT choosing, and why it needs your call

The other fix is to normalise the five seeded `display_name` rows to title case. It is a smaller
change and would unblock these rows immediately — but it **edits seeded identity data**, which is
explicitly the user's domain ("seed them in the back end"), and it leaves the harness still asserting
a name it guessed, so the next fan seeded under any other convention breaks it again. **Surfacing
rather than deciding:** if you would rather normalise the data than change the harness, say so — the
two are not mutually exclusive, but only the lookup makes the harness robust.

## Also open from this run, deliberately not bundled

- **3 × `row_execution_failed`, all Garden, all reason `No element`** —
  `garden-event-rsvp`, `garden-volunteer-shift`, `plant-exchange-submission`. A finder matched nothing
  where the code expected one element. Diagnose separately; do not assume it is the same cause as the
  display-name mismatch.
- **1 stall waiting on `actor-identity-picker-button`** rather than an account row — a different wait
  site, one occurrence, needs its own look.
- `b25Proven` is **0/16**. Nothing is proven yet and this ticket does not claim otherwise.

## Verification

- A test that **fails before and passes after**: a fan whose stored display name differs from its
  title-cased slug must still be found; and a fan absent from the directory must fail immediately
  with its fan id named, not time out.
- All five suites, skip counts before pass counts: demo **297** (0 failed, 0 skipped), app shell
  **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential sets), service **168**
  (+1, the one skip being App Access and **not** PostgreSQL). Run them **sequentially** — judges
  beside engine gives a false timeout. `b25_capture_prebuilt_binary_test.dart` is known flaky about
  1 run in 3; confirm a `TimeoutException` and that the file passes isolated before believing it.
- `flutter analyze` on the demo app: **3** pre-existing issues, from flutter's own `N issues found`.
- **Success criterion in the run's own units:** the 10 display-name stalls disappear. Reach should
  hold at 17+ and `found modal-barrier` stay 0.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher now refuses a reply without it and exits 2 —
  `NOT_RUN(reason)` is a correct entry for anything you genuinely could not run.
