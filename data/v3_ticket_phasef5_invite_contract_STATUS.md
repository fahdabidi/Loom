# Ticket status: Phase F.5

## Change applied
Status: blocked

## What you found
The Messages renderer contract in `part11_shell_models.dart` was the only contract registry entry carrying the false invite anatomy, interactions, pending state, label wording, and evidence requirement. Those claims are now removed; the real thread interactions and non-invite states remain unchanged. The fallback policy now names the intended `EngineNativeListSurface`/`GenericWorkflowInstanceCard` pipeline. `rendererId: 'MessagesTabSurface'` remains unchanged because the shell uses it as the shared legacy/engine-native dispatch identifier and the judge tooling uses it as renderer metadata.

The test directory has no references to the removed invite claims, and no judge code consumes the Messages contract's removed fields. Separate social-surface catalogs in `part13_workflow_copy_catalog.dart` and `loom_ux_judges.dart`, plus historical/API/skill documentation, B25 evidence, the Phase F plan, and the frozen example's explanatory comment still contain invite terminology; those describe the separate `CommunitySocialSurfaceApi`/social workflow contract or historical evidence and were left untouched as required.

## Verification
flutter analyze: clean (`No issues found!`).
Test suite: 0/50 test files loaded. The full package run was blocked before assertions by the sandbox's Flutter tester socket error: `Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`. Therefore the known a11 flake could not be isolated from the sandbox run; external verification is required.

## Commit
Commit hash: `a8c8c92c2baaed993dd861908852d0bfa753ac64`.
