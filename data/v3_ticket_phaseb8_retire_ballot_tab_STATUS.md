# Ticket status: Phase B.8 retire legacy bespoke ballot tab

## Change applied
Status: blocked

The legacy bespoke ballot tab and its disconnected in-memory engine were removed. The source-level
cleanup is complete, but the required Flutter analyzer/suite execution is blocked by this sandbox's
WSL/vsock and read-only Flutter SDK cache limitations.

## What was removed

The following references were searched across the app-shell package before deletion and had no live
usages outside the legacy path:

- `_TournamentBallotTabSurface`, `_TournamentBallotTabSurfaceState`, and
  `_TournamentBallotEngineStore`, including their private `ballot`-tab render bindings, queries,
  copied seed data, and old `pendingChoice` mutation flow, from `part02_tab_shell.dart`.
- The `TournamentBallotTabSurface` renderer-switch case from `part02_tab_shell.dart`.
- `LoomTournamentCandidate` and `LoomTournamentBallotSeed` from `part11_shell_models.dart`.
- The `'tournament-ballot'` legacy `LoomTabRendererContract` entry from `part11_shell_models.dart`.
- The `LoomExperienceDefinition.tournamentBallot` constructor parameter and field.
- The conditional `tabId: 'ballot'` tab specification from `part12_persona_and_tabs.dart`.
- The `_parseTournamentBallotSeed` call and parser from `part15_evidence_catalog.dart`.
- `test/v3_milestone_1_18_stage2b_ballot_ui_test.dart`, the five-test suite dedicated exclusively to
  the deleted widget.

The exact JSON key `"tournamentBallot"` is absent from all community fixtures, including the current
Tabletop Club fixture and the Garden, Camera, Chess, Book, Youth Soccer, Mosque, and HOA examples.

## Anything NOT removed, and why

The real JSON-driven `tournament-ballot`/`tournament-event` workflow definitions, Home render bindings,
`VotePollArchetypeCard`, engine-native dispatch, and all Phase B replacement tests were preserved.
They are the live replacement for the deleted tab. The frozen Tabletop reference's historical comment
mentioning the old `tournamentBallot` block was left untouched because the fixture has no such active
key and the frozen JSON must not be edited. `_reminderOffsets` was also preserved because it remains
used by the live form-entry controls.

No other community, production file, or test was found to depend on the removed legacy symbols.

## Verification

flutter analyze: blocked before diagnostics by `UtilBindVsockAnyPort:309: socket failed 1`. The direct
cached Dart analyzer completed with `No issues found!`; invoking Flutter's tool directly was then
blocked by the read-only SDK cache lockfile. The changed Dart files are formatted and `git diff --check`
is clean.

Test suite: before count 172/173 (the one known pre-existing a11 date-picker flake); after count
expected 167/168 after deleting the five-test legacy file. `flutter test` could not execute because of
the same WSL/vsock error, so no post-change pass/fail result is claimed here.

## Commit

staged, not committed — verification execution is blocked by the sandbox limitations above; the final
commit hash will be recorded after the controlled commit.
