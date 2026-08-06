Ticket AuthZ.P6 fix1 — 23 test failures after the entry gate landed (3 in the gate's own new test file)

## Context

AuthZ.P6 (commit `94de7da2`) added the community-open entry gate and reported updating 20 existing test
files plus a new `authz_p6_entry_gate_test.dart` to work with it, claiming a clean bill of health. Its own
sandbox could not run `flutter test` at all (denied loopback socket), so none of this was actually verified
before commit. I independently ran the full `loom_communities_app_shell` suite outside that sandbox and
found **23 real failures** (180 passing / 23 failing), including **3 of the 4 tests in the ticket's own new
`authz_p6_entry_gate_test.dart`** -- the dedicated test file for this exact feature does not pass.

Full list of the 23 failing tests:

```
test/authz_p6_entry_gate_test.dart: open-only community gates entry, then renders content after signup
test/authz_p6_entry_gate_test.dart: requiresApproval community stays at the gate with pending membership state
test/authz_p6_entry_gate_test.dart: requiresInvite community exposes invite redemption at the entry gate
test/notification_fab_test.dart: FAB notification style is global, scoped, and marks unread rows read
test/notification_fixed_card_test.dart: fixed card is home-scoped, persona-scoped, and marks unread through the engine
test/v3_calnotify2_7_bell_activation_test.dart: real Tabletop Club fixture activates only the bell notification presentation
test/v3_calr4g_marketplace_transition_action_test.dart: Marketplace presents borrow as a guarded FAB and keeps other transitions in the automatic row
test/v3_calr4g_marketplace_transition_action_test.dart: Marketplace hides the contextual FAB when borrow is disallowed
test/v3_milestone_b1_home_engine_native_test.dart: Home renders only its JSON-declared bindings through the generic engine-native pipeline, not the legacy blanket workflow dump
test/v3_milestone_b1_home_engine_native_test.dart: publishing the seeded announcement makes its title and body appear on Home
test/v3_milestone_phaseb_votepoll_archetype_test.dart: real frozen ballot renders persona-aware votePoll behavior and casts a row
test/v3_milestone_phaseb_votepoll_archetype_test.dart: real close-vote writes the clear winner to the related tournament event
test/v3_milestone_phasee_purchase_proposal_test.dart: member proposals flow from Home creation through the live Admin queue, decisions, and revision
test/v3_milestone_gp2_giving_end_to_end_test.dart: Giving projects the frozen dues instance through the generic engine-native list
test/v3_milestone_phasec_marketplace_archetype_test.dart: claimed equipment giveaway leaves the real Marketplace grid
test/v3_milestone_phasef_messages_test.dart: engine-native Messages renders seeded threads and completes the full thread lifecycle
test/v3_milestone_phaseb_votepoll_archetype_test.dart: real close-vote creates a runoff ballot for a queried three-way tie
test/v3_milestone_gp2_giving_end_to_end_test.dart: Giving pay unlocks Marketplace borrow through the shared engine UI
test/v3_milestone_phasec_marketplace_archetype_test.dart: real seeded Marketplace listings render through the shared engine grid, search, category filters, and detail
test/v3_milestone_phasec_marketplace_archetype_test.dart: paid-up members see Request loan from the real borrow guard while organizers and unpaid members do not
test/v3_milestone_phasec_marketplace_archetype_test.dart: an unpaid member cannot see the guarded borrow action
test/v3_milestone_a11_event_rsvp_archetype_test.dart: organizer creates an event and one pending response per member
test/v3_milestone_a11_event_rsvp_archetype_test.dart: new event control is hidden from a non-creatable persona
```

Note: `organizer creates an event and one pending response per member` was already the one known
pre-existing flake before AuthZ.P6 -- keep it in mind while triaging, but do not assume it's still "the same"
flake without checking; AuthZ.P6 could plausibly have changed its failure mode too, or it could genuinely be
unrelated and still just flaky. Note also `notification_fixed_card_test.dart`'s SECOND previously-fixed test
("fixed card collapses when the viewing persona has no notifications", fixed in AuthZ.P4b fix1) is NOT in
this new failure list -- so that specific fix is holding; only the OTHER test in that file broke again.

I traced two representative failures myself (do not re-derive these two, but do trace the rest -- the pattern
may not be identical everywhere):

1. **`authz_p6_entry_gate_test.dart`'s "open-only" and "requiresInvite" tests both throw the identical
   error**, before any UI assertion even runs:
   ```
   Bad state: Engine-native seed entry-content-1 is missing createdByPersonaId
     at _EngineNativeCommunityStore._initialize (part25_engine_native_community_store.dart:166)
     at workflowEngineForExtensionId (part25_engine_native_community_store.dart:264)
     at _LocalExtensionScreenState._syncEnginePersonaTypes (part01_local_extension_screen.dart:511)
   ```
   This is a fixture bug in the new test file's own seed data -- some workflow-instance seed(s) it constructs
   omit `createdByPersonaId`, which the engine now requires at initialization. Find the seed-construction
   helper this new test file uses and add the missing field.

2. **`notification_fab_test.dart`'s failure is different**: it times out waiting for the unread-count badge
   text to ever appear, which strongly suggests the test's widget tree never gets past the new entry gate at
   all in this case (content that depends on a signed-in, active persona never renders, so nothing downstream
   -- including notification badges -- ever shows). This file WAS on AuthZ.P6's own "updated" list, so
   whatever update was made there is evidently incomplete -- trace exactly what state the test harness is in
   when the timeout occurs (is `_communityEntryAllowed` still `null`/`false`? Is the account it signs in with
   actually being recognized as active for this specific community extension id?).

**Given the volume and spread of these 23 failures across many unrelated content surfaces (marketplace,
votepoll, giving, messages, home, purchase-proposal, a11, notifications), suspect there is a small number of
shared root causes, not 23 independent ones** -- e.g. a shared test-helper function
(`authz_p6_test_helpers.dart`, mentioned in AuthZ.P6's own STATUS) that has a bug affecting every test that
uses it, or a systematic gap in how "updated" tests establish their active session before the gate's async
`_refreshCommunityEntryGate()` check resolves (a timing/race issue would explain intermittent-looking
failures across many otherwise-unrelated files). Look for the shared mechanism before treating each failure
as a one-off.

## Scope

1. Fix the `createdByPersonaId` fixture bug in `authz_p6_entry_gate_test.dart`'s own seed data.
2. Systematically trace and fix the remaining 21 failures. Start from whatever shared helper/pattern you find
   per the hypothesis above -- fixing the shared root cause may resolve most of the list at once. For any
   failure that turns out to be genuinely independent, fix it individually and say so.
3. Re-examine whether `organizer creates an event and one pending response per member` is still the exact
   same pre-existing flake or a new failure mode -- state clearly which it is.
4. If, in the course of fixing these, you find the entry gate's own production logic (not just test setup)
   has a real bug, fix that too -- do not force test-side workarounds for a genuine production defect. Say
   explicitly which category each fix falls into (test fixture bug vs. production bug).

## Do not do

- Do not weaken, skip, or delete any of the 23 failing tests, or any other currently-passing test, to make
  numbers look better.
- Do not touch AuthZ.P1-P5 code unless a genuine bug there blocks this ticket (say so explicitly if so).
- Do not add or change any JSON grammar.
- Do not disable or bypass the entry gate for any community to make tests pass more easily.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. Full test suite -- must return to 199+ passing (185 original baseline + 6 P4b + 7 P5 + 4 P6-new = 202
   total test count expected, recompute the exact expected total yourself from the actual current suite
   rather than trusting this arithmetic blindly) with only ONE failure, and that failure must be confirmed as
   the genuinely pre-existing "organizer creates an event and one pending response per member" flake (or, if
   your investigation in point 3 above finds it's now a different failure mode, say so plainly rather than
   silently accepting a changed failure as "the same known flake").
3. Run `test/authz_p6_entry_gate_test.dart` individually and confirm all 4 tests pass.
4. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless (this is what caught all 23 failures, since AuthZ.P6 itself
   could not verify anything before committing).

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `fix: resolve the 23 test failures introduced by the AuthZ.P6 entry gate (AuthZ.P6
fix1)`.

## Required response format (write to `data/v3_ticket_authz_p6_fix1_STATUS.md`)

```
# Ticket status: AuthZ.P6 fix1

## Root cause(s) found
The shared mechanism(s), if any, plus any genuinely independent failures, each with evidence.

## Change applied
Status: done | blocked
For each fix, state: test fixture bug vs. production bug, and exactly what changed.

## Verification
flutter analyze: clean/not clean.
Test suite: exact pass count out of the exact total test count in the suite (compute both yourself, don't
assume). Confirm all 4 authz_p6_entry_gate_test.dart tests pass. State plainly whether the one remaining
failure (if any) is confirmed to be the original pre-existing a11 flake or something else.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
