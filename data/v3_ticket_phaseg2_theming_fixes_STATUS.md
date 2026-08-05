# Ticket status: Phase G.2

## Findings per item
1. `_ProtectedDetailTabSurfaceState`: the masked branch used literal
   `Colors.black12` and `Colors.black26`, while `modernTheme` was already
   available on the widget. It now resolves its fill and border from
   `modernTheme.resolvedFill`/`resolvedBorder`, with the resolved accent as
   the legacy fallback. The authorized branch is unchanged.
2. `_WorkflowTile`: Tabletop Club no longer reaches this legacy tile. Its
   engine-native Home binding is intercepted by the
   `EngineNativeListSurface` gate in `_TabNativeRenderer` before the legacy
   `workflowBuilder`/`_workflowPresenterFor` path. The tile remains reachable
   for the non-engine-native bespoke community surfaces, where the bug was
   real: it ignored its already cascade-resolved `fallbackAccent` and used
   `_categoryAccentColor`'s hardcoded palette. It now uses
   `modernTheme.accent` or `fallbackAccent`.
3. Ballot candidate row border: it was not already fixed. `VotePollArchetypeCard`
   rendered each candidate as a bare `Row` with no decoration. Each candidate
   now has a themed `DecoratedBox` using `modernTheme.resolvedBorder` (or the
   resolved accent fallback), and the Phase B widget test reads and asserts
   the actual rendered border and fill.

## Change applied
Status: blocked

## Verification
flutter analyze: clean (`flutter analyze --no-pub packages/core/loom_communities_app_shell`; no issues found).
Test suite: 0/50 test files executed; the focused change tests also stopped at 0/2. Flutter could not start
the test device because the sandbox forbids its localhost server socket:
`Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`.
The known a11 flake could not be isolated; independent runtime verification is required outside this sandbox.
The B26 package-driven theme regression test was left unmodified and was not runnable for the same reason.

## Commit
staged, not committed — runtime widget tests are blocked by the exact localhost server-socket restriction above.
