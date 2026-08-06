Ticket AuthZ.P5 fix1 — "admin can issue an invite" test finds two different invite codes in the tree

## Context

AuthZ.P5 (commit `004b200f`) added the `_PendingAndInvitesSurface` (issue invite / approve pending account
UI) and its own new test file, `test/authz_p5_membership_flows_test.dart`. I independently re-ran that test
file outside the Implementation Agent's own sandbox (which could not run `flutter test` at all) and found one
of the 7 new tests genuinely fails: `admin can issue an invite from the visible surface`.

The failure is specific and worth reading carefully before guessing at a fix:

```dart
await tester.tap(find.byKey(const ValueKey('issue-invite-button')));
await tester.pumpAndSettle();

expect(find.byKey(const ValueKey('issued-invite-code')), findsOneWidget);  // PASSES
expect(find.textContaining('LOOM-'), findsOneWidget);                      // FAILS
```

The second assertion fails with **two** matches, and critically, they are **different codes** -- an
`EditableText` showing `LOOM-AADBXA` and a separate `Text` showing `LOOM-ABC234`. The first assertion (the
specifically-keyed `issued-invite-code` widget) passes and finds exactly one widget, so the intended
"just-issued code" display is working -- the second, broader assertion is what's catching an extra,
unexpected second code somewhere else in the tree.

**Two plausible explanations, not yet distinguished -- trace the actual widget tree and `issueInvite` call
count, don't guess:**
1. The "Issue invite" button's tap handler fires `issueInvite` more than once per tap (e.g. a double-registered
   `onPressed`, or `ensureVisible` + `tap` somehow triggering two gestures) -- two different invites really
   were created, and both surface somewhere in the widget tree.
2. `_PendingAndInvitesSurface` intentionally shows more than just the single most-recently-issued code (e.g.
   a running list of all currently-pending, unclaimed invites for this community) -- in which case only ONE
   invite was actually created, but the test's own second assertion (`find.textContaining('LOOM-')`, with no
   scoping) is simply too broad for a screen that's allowed to show more than one code, and the fix belongs in
   the test, not production code. Check whether a fresh admin session issuing its very first invite in an
   otherwise-empty community should legitimately have only one `LOOM-`-prefixed string on screen, or whether
   the surface's design always includes a static placeholder/example, a previous invite from network/DB seed
   data, or similar.

## Scope

1. Determine, with actual evidence (not a guess), which of the two explanations above (or a third one you
   find) is correct.
2. If `issueInvite` is genuinely being called twice per tap: find and fix the actual double-firing mechanism
   in the button wiring (production code fix).
3. If the surface legitimately can show more than one invite/code at once by design: fix the *test's* second
   assertion to be properly scoped (e.g. assert on `find.descendant(of: find.byKey(const
   ValueKey('issued-invite-code')), matching: find.textContaining('LOOM-'))`, or drop the redundant broad
   assertion now that the specifically-keyed one already proves the code rendered) -- do not weaken what the
   test actually verifies, just make the assertion specific to the thing it's meant to check.
4. Either way, state your finding plainly in the STATUS response with the actual evidence (e.g. add a
   temporary print/log of `issueInvite` call count while diagnosing, if useful, but remove any temporary
   diagnostics before your final commit).

## Do not do

- Do not touch AuthZ.P1-P4b code.
- Do not weaken or delete the first assertion (`issued-invite-code` findsOneWidget) or any of the other 6
  passing tests in this file.
- Do not add or change any JSON grammar.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. `flutter test test/authz_p5_membership_flows_test.dart` -- all 7 tests pass, including `admin can issue an
   invite from the visible surface`.
3. Full test suite -- baseline 191 passing / 1 known a11 flake, plus all 7 AuthZ.P5 tests now passing (198
   total passing / 1 known failing).
4. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless.

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `fix: resolve the AuthZ.P5 issue-invite test's double-code-match failure (AuthZ.P5
fix1)`.

## Required response format (write to `data/v3_ticket_authz_p5_fix1_STATUS.md`)

```
# Ticket status: AuthZ.P5 fix1

## Root cause found
Which of the two explanations (or a third) was correct, with actual evidence.

## Change applied
Status: done | blocked
Whether the fix was in production code or the test, and exactly what changed.

## Verification
flutter analyze: clean/not clean.
Test suite: pass count. Confirm all 7 authz_p5 tests pass and the full suite is 198/199 (only the known a11
flake).

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
