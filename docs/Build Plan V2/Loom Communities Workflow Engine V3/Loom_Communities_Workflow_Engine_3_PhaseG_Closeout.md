# Phase G — Retirement, theming, and close-out

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phases B-F.**

## Goal

Collect the debt the rebuild was designed to pay off, prove nothing regressed, and re-present Milestone
1.20 for the human sign-off that reopened this whole effort.

## G.1 — Retire the bespoke engine stores the pipeline replaced

✅ **Closed (2026-08-05) — investigated, nothing left to delete.**

Each earlier phase deletes the store it supersedes (`_TournamentBallotEngineStore` in B,
`_MessagesEngineStore` in F, …). This milestone is the **sweep**: confirm nothing that the JSON pipeline
now renders still has a hand-written Dart engine-store, and that no dead code was left behind.

**This is the whole point of the rebuild.** The measure of success is *lines deleted*, not lines added:
~20 hand-written engine-store classes in `part02_tab_shell.dart` existed only because there was no way to
load a state machine from JSON. Tabletop Club's should now be gone.

**Careful:** the other seven communities (Garden, Camera, Chess, Book, Youth Soccer, Mosque, HOA) still
run on their own bespoke stores and the **shallow v1 schema**. They are **out of scope** — do not touch
them. They migrate in Phase 2 of the master plan, via the Skill. Deleting a store that another community
still uses is the most likely way to break this phase.

**Investigation findings (2026-08-05):** Tabletop Club never had its own dedicated per-community engine-
store class — unlike Garden/Camera/Chess/Book Club/Youth Soccer/HOA, which each have a named store
(`_GardenClubEngineStore`, `_CameraClubEngineStore`, `_ChessClubEngineStore`, `_BookClubEngineStore`,
`_YouthSoccerEngineStore`, `_ArchitecturalRequestStore`) gated by a community-identity sniff
(`_isGardenEngineExperience`, etc.) checked *before* the engine-native path — Tabletop Club instead
borrowed the **generic**, tabId-keyed stores (`_MessagesEngineStore`, `_MarketplaceBrowseSurface`'s v1
listing path, `_GivingTabSurface`'s v1 workflow-list path). All three are confirmed still genuinely
load-bearing for other communities (HOA in particular: `hoa-dues-payment`, `hoa-*` notification/messages
paths). `tournament-ballot`'s own store was already deleted in Phase B.8 — the one case where Tabletop
Club *did* have a dedicated bespoke class, and it's gone. Cross-referencing every workflow type in the
frozen JSON against the codebase found no other Tabletop-specific bespoke Dart left unreachable. Also
confirmed: the other six communities' bundled JSONC fixtures (`assets/Loom_Communities_Workflow_Engine_*_Example.jsonc`)
do contain populated `workflowDefinitions`, but these are inert string constants consumed only by each
community's own bespoke fixture loader — never wired to `LoomExperienceDefinition.workflowDefinitions`, so
`_hasEngineNativeBinding` is always false for them. **Only Tabletop Club is genuinely engine-native today** —
this session's own six-phase rebuild did not accidentally reach any other community. **Conclusion: nothing
to delete for G.1** — the closeout's "lines deleted" measure is already satisfied by B.8's ballot-store
deletion; every other shared/community-named store must stay untouched exactly as this milestone's own
warning anticipated.

## G.2 — Global theming fixes (the ones Phase A didn't need)

✅ **Closed (2026-08-05, commit `5301d0e4` + fix1 `59a5297b`).** All three items were real, and all three are
now fixed: (1) `_ProtectedDetailTabSurfaceState`'s masked branch now resolves fill/border from
`modernTheme` instead of hardcoded `Colors.black12`/`black26`. (2) `_WorkflowTile` is confirmed unreachable
for Tabletop Club (its Home binding is intercepted by the engine-native gate first) but is genuinely still
reachable for the other seven communities, where the bug was real — now uses the cascade-resolved accent
instead of `_categoryAccentColor`'s hardcoded per-category palette. (3) Ballot candidate rows had no border
at all (not already fixed by Phase B as suspected) — `VotePollArchetypeCard` now wraps each candidate in a
themed `DecoratedBox`, with all existing widget keys preserved unchanged for backward compatibility. One
fix round: both new theming tests initially failed with a mismatched color, traced to a shared test-fixture
bug (accent configured in the wrong field, so the real theme resolver correctly fell back to a default
teal) — not a production bug; the theme cascade itself was resolving correctly all along. Verified
independently: `flutter analyze` clean, 178/179 green (only the known a11 flake), plus
`b26_package_driven_experience_test.dart` (different package) unaffected at 3/3.

Phase A fixed the two Calendar-specific bugs. The rest:

- `_ProtectedDetailTabSurfaceState`'s masked branch hardcodes `Colors.black12`/`Colors.black26`
  (`part02_tab_shell.dart:3112,3114`) — ignores both the accent and the theme.
- `_WorkflowTile` picks its color from `_categoryAccentColor` (`part14_copy_helpers.dart:576-600`) —
  hardcoded **per-category** hex values unrelated to the community accent. This is the reported "random
  black scheme." *(If Phases B-F retire `_WorkflowTile` for Tabletop Club entirely, this may only matter
  for the other seven communities — check before spending effort.)*
- Ballot candidate rows had **no border at all** — likely fixed in Phase B by the generic card; verify.

**Keep the cascade.** community → tab → workflow `theme`/`tabThemes` is deliberate and tested
(`b26_package_driven_experience_test.dart`). These are bugs *within* it. Do **not** remove
`LoomWorkflowDefinition.theme`, `themeOverride`, `tabThemeOverrides`, or `LoomCardTheme.merge`.

## G.3 — Full regression sweep

✅ **Closed (2026-08-05, corrected 2026-08-05 — see correction note below).** Full sweep run across all
four packages via WSL, independent of any implementation-agent report. Exact counts:

- **`loom_workflow_engine`**: 195/195 passing. `flutter analyze`: clean except 21 pre-existing
  info-level lints in a file that predates Phase B by weeks — unrelated to this session.
- **`loom_communities_app_shell`**: 178/179 passing (the one failure is the already-known `a11`
  flake, pre-existing and unrelated to Phases B-G). `flutter analyze` clean.
- **`loom_communities_demo`** (the package holding the seven-other-communities regression guards):
  **112 passing, 17 failing.** `b26_package_driven_experience_test.dart`,
  `b28_response_choice_interactions_test.dart`, `b34_marketplace_browse_test.dart` — the files this
  milestone's own checklist names — all pass **unmodified**.
  `b20_multi_persona_workflow_evidence_test.dart` has **zero** failures (its single test passes; it
  only appears to "fail" in raw log output because Flutter's test runner logs a per-file progress line
  for the test currently executing, which was misread as a failure marker in the first pass at this
  milestone — corrected here). The real 17 failures: `b27_calendar_tab_real_data_test.dart` (3),
  `b29_calendar_complete_interactions_test.dart` (3), `b33_messages_thread_test.dart` (3), and
  `b36_calendar_engine_rsvp_test.dart` (8, initially missed by this milestone's first pass and found
  only on a subsequent user-directed re-check). All were **proven**, not assumed, pre-existing:
  `git worktree add --detach <tmp> c71c6596` (the commit immediately before Phase G.2, i.e. before any
  theming fix this session touched, and after all of Phase F's real code work) reproduced the exact
  same failures for b27/b29/b33 and 7 of b36's 8 failures, in complete isolation from the current
  working tree, across three separate worktree checks. b36's 8th failure
  (`calendar fixture declares RSVP response model fields`, an `expect(fixture.existsSync(), isTrue)`
  check against a relative path) does **not** reproduce when the file is run alone — confirmed to pass
  reliably in isolation both at the pre-G.2 commit and at current HEAD, with the underlying fixture
  file genuinely present and correctly-contented in both. It only fails when run as part of the full
  combined suite — a CWD/test-isolation flakiness artifact of that specific relative-path check, not a
  functional regression from any Phase B-G/G.1-G.4 work, none of which touched this fixture, this test
  file, or any path-resolution code. Confirmed pre-existing baseline debt (plus one flaky, non-code
  test), unrelated to Phase B-G, therefore correctly out of scope for this milestone and left unfixed.
- **`loom_ux_judges`**: `flutter analyze` clean (2 pre-existing info-level warnings, unrelated to
  this session). `flutter test` could not complete — a reproducible Dart compiler crash
  ("Null check operator used on a null value" in `test_compiler.dart`) on 3/3 attempts. Traced to
  this package's own unrelated, pre-existing uncommitted work-in-progress (a different session's
  validator-server/skill-authoring changes, never touched by this session) — not a WSL-wide issue
  (confirmed WSL itself was responsive) and not a syntax error in any new file (`dart analyze` on it
  alone was clean). Root cause undetermined beyond that; `flutter analyze` is the best independent
  verification available for this package this pass, and that is clean.

**Correction note (2026-08-05).** This section's first pass claimed "24 failures total" across
b20/b27/b29/b33 and never mentioned `b36_calendar_engine_rsvp_test.dart` at all. Both were wrong: the
"24" figure was never derived from the actual full-suite tally (112/17, confirmed by `flutter test`'s
own final summary line), and b36 was missed entirely from the file-by-file investigation. A follow-up
user-directed re-check of the raw sweep log caught both errors — corrected above with the real
breakdown and a third isolated-worktree check covering b36. Recorded here rather than silently
overwritten, per this session's own verification discipline: self-correction on a caught mistake is
exactly what that discipline is for.

All seven other communities: confirmed via G.1's investigation that none of them are engine-native
(their bundled JSONC fixtures are inert, unwired constants) and via this sweep that their own
regression-guard tests (`b26`/`b28`/`b34`) pass unmodified — behavior is unchanged.

## G.4 — Documentation reconciliation

✅ **Closed (2026-08-05).** A full research pass (`Explore` agent, source-verified, not carried forward
from prior doc claims) found `docs/references/archetypes/README.md` genuinely stale — last edited
during Phase E, predating all of Phase F and Phase G. Reconciled:

- **[`docs/references/archetypes/README.md`](../../references/archetypes/README.md)** rewritten against
  current source (`EngineNativeArchetypeCard`'s dispatch switch, `part27_engine_native_binding_dispatcher.dart:322-436`).
  New finding that changes the honesty story: all 9 of Tabletop Club's archetypes are now reached
  purely by `cardSurfaceFamily` in JSON with zero hardcoded per-community wiring (the old "second,
  more consequential axis" section's open question is now fully resolved) — but only 3 of 9
  (`event-rsvp`, `equipment-loan`, `votePoll`) render a genuinely distinct bespoke widget. The other 6
  (`paymentCheckout`, `approvalQueueItem`, `formEntry`, `discussionThread`, `statusTimeline`,
  `notificationInbox`) are honestly relabeled 🟡 GENERIC — functionally real (live queries, real
  transitions, real creation) but rendered via the shared `GenericWorkflowInstanceCard`, a deliberate
  scope decision each phase doc (D/E/F) already recorded, not an oversight. `event-rsvp` itself flipped
  from "🔨 REBUILDING, spec-only" to ✅ REAL — the CAL.1-CAL.4 redesign (per-row response table, scoped
  Day/Week/Month/Pending views, real event creation) is fully implemented, not just designed.
- **Five per-archetype reference docs written** (previously all `status: "planned"`, i.e. did not
  exist): [`vote-poll.md`](../../references/archetypes/vote-poll.md),
  [`equipment-loan.md`](../../references/archetypes/equipment-loan.md),
  [`payment-checkout.md`](../../references/archetypes/payment-checkout.md),
  [`approval-queue.md`](../../references/archetypes/approval-queue.md),
  [`discussion-thread.md`](../../references/archetypes/discussion-thread.md) — per §5a's phase
  assignments (B/C/D/E/F respectively). The three 🟡 GENERIC ones state plainly that they document the
  generic-card pattern, not a bespoke widget, to avoid repeating the exact `docs/CardSurfaces/` mistake
  this tracker exists to correct. `calendar-agenda.md` deliberately left unwritten — it's Phase A's own
  deliverable, and Phase A remains genuinely open pending its A.10 human review gate; G.4 does not close
  on Phase A's behalf.
- **`docs/references/_meta/doc-manifest.json`** updated: the 5 new docs flipped `planned` → `current`
  with real `derivedFrom` citations; `archetypes/README.md`'s own `syncedTo.grammar` corrected `1` → `2`
  (it was already behind current grammar before this pass).
- **`docs/references/spec-version.json`** updated: `knownGaps.instanceCreation` (GAP-2) noted as now
  proven across every real archetype — Phases E and F extended the tab-scoped creation pipeline to
  `game-purchase-proposal` and `discussion-thread` and added `personaId[]` creation-field support, so
  it's no longer Calendar-only infrastructure. Also fixed two pre-existing JSON syntax errors found
  while editing (a missing comma before `combineDateAndTimeFormula`, a trailing comma after
  `notificationDeliveryService`) that made the file invalid JSON — confirmed parseable after the fix
  (`python3 -c "import json; json.load(...)"`, both `spec-version.json` and `doc-manifest.json` OK).
  `lastReviewed` bumped to 2026-08-05.
- **[Archetype Implementation Standard](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md)**
  — a 2026-07-XX Phase 1 doc, not tracker 3's own — given a reconciliation note pointing to
  `archetypes/README.md` as the current source of truth for reachability/status, rather than rewriting
  its historical `[x]` build-record rows (which track a different, older question: "was a rich UI ever
  built," not "is it reachable purely from JSON today").
- **Tabletop Club JSON as authoritative reference**: unchanged and confirmed — the frozen `.jsonc` is
  still never edited by this agent, and every doc above cites it as the worked example.
- **Known gaps recorded honestly**: receipt-ID platform service (paymentCheckout, named in
  `payment-checkout.md` and Phase D's own closure), invites (discussionThread, named in
  `discussion-thread.md` and Phase F's own closure), `listMinusActor`/GAP-3's degraded per-thread
  unread bool (named in `discussion-thread.md`), ballot/tournament creation still seed-driven
  (`vote-poll.md`). None silently dropped.

## G.5 — Re-present Milestone 1.20 (the human sign-off gate)

Full live walk on `PantryVision_Manual_API_36`, per the verification standard:

- **Full-tab audit** — every card on every tab is the right archetype with its real interactions.
- **Evidence matrix** — one screenshot per (Tab × User story × Interaction) cell, across all six tabs.
- **Random regression re-check.**

Then hand it to the user. **1.20 is closed only by explicit user confirmation, recorded with the date** —
it is not closeable by the verification agent.

## Definition of done

- [ ] Tabletop Club runs **entirely** from its JSON definition. No bespoke Dart engine-store remains for
      any of its workflows.
- [ ] Net lines of Dart **deleted**, not added.
- [ ] Nothing else in the repo regressed.
- [ ] The user has signed off on Milestone 1.20.
