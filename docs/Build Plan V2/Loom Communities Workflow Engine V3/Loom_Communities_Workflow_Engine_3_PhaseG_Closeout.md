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

✅ **Closed (2026-08-05).** Full sweep run across all four packages via WSL, independent of any
implementation-agent report. Exact counts:

- **`loom_workflow_engine`**: 195/195 passing. `flutter analyze`: clean except 21 pre-existing
  info-level lints in a file that predates Phase B by weeks — unrelated to this session.
- **`loom_communities_app_shell`**: 178/179 passing (the one failure is the already-known `a11`
  flake, pre-existing and unrelated to Phases B-G). `flutter analyze` clean.
- **`loom_communities_demo`** (the package holding the seven-other-communities regression guards):
  `b26_package_driven_experience_test.dart`, `b28_response_choice_interactions_test.dart`, and
  `b34_marketplace_browse_test.dart` — the files this milestone's own checklist names — all pass
  **unmodified**. `b20_multi_persona_workflow_evidence_test.dart`,
  `b27_calendar_tab_real_data_test.dart`, `b29_calendar_complete_interactions_test.dart`, and
  `b33_messages_thread_test.dart` have 24 failures total. These were **not** assumed pre-existing —
  proven so: `git worktree add --detach <tmp> c71c6596` (the commit immediately before Phase G.2,
  i.e. before any theming fix this session touched) reproduced the exact same failures for all four
  files, in complete isolation from the current working tree, across two separate worktree checks.
  Confirmed pre-existing baseline debt, unrelated to any Phase B-G work, therefore correctly out of
  scope for this milestone and left unfixed.
- **`loom_ux_judges`**: `flutter analyze` clean (2 pre-existing info-level warnings, unrelated to
  this session). `flutter test` could not complete — a reproducible Dart compiler crash
  ("Null check operator used on a null value" in `test_compiler.dart`) on 3/3 attempts. Traced to
  this package's own unrelated, pre-existing uncommitted work-in-progress (a different session's
  validator-server/skill-authoring changes, never touched by this session) — not a WSL-wide issue
  (confirmed WSL itself was responsive) and not a syntax error in any new file (`dart analyze` on it
  alone was clean). Root cause undetermined beyond that; `flutter analyze` is the best independent
  verification available for this package this pass, and that is clean.

All seven other communities: confirmed via G.1's investigation that none of them are engine-native
(their bundled JSONC fixtures are inert, unwired constants) and via this sweep that their own
regression-guard tests (`b26`/`b28`/`b34`) pass unmodified — behavior is unchanged.

## G.4 — Documentation reconciliation

- [ ] [Archetype Implementation Standard](./Loom_Communities_Workflow_Engine_Archetype_Implementation_Standard.md)
      updated: each archetype's row now cites the **JSON-declared** implementation, not a bespoke widget.
- [ ] [JSON_Schema_Versions.md](./Loom_Communities_Workflow_Engine_JSON_Schema_Versions.md) updated with
      any grammar changes made along the way (e.g. Phase E's instance-creation addition, any string-literal
      formula finding from A.3). **Bump `workflowGrammarVersion` if any change was breaking.**
- [ ] The Tabletop Club JSON is the **authoritative, validated** community definition — and the reference
      the Skill (Phase 3) will be grounded in.
- [ ] Known gaps recorded honestly, not silently dropped (invites, receipt-id platform service, anything
      deferred).

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
