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

The rebuild was **additive** by design — the shallow v1 path and every other community must be
untouched. Prove it, don't assume it:

- [ ] All seven other communities render and behave exactly as before.
- [ ] Every pre-existing test passes **unmodified** — especially `b34_marketplace_browse_test.dart`,
      `b26_package_driven_experience_test.dart`, `b27`/`b28`/`b29`.
- [ ] `flutter analyze` clean across `loom_workflow_engine`, `loom_communities_app_shell`,
      `loom_ux_judges`.
- [ ] Full suite green; exact counts cited.

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
