# Phase 0 - Initialize Build

Surface: tooling/docs/workspace
UX gate: low
On green: proceed to A1
Rules: [Rules.md](../Rules.md)

## 0. Prerequisite Gate

No prior phase. Verify local execution environment only:

- `app/` exists or is created as the V2 melos workspace root.
- Flutter/Dart/melos/tooling prerequisites are documented.
- Git worktree status is recorded before generation begins.

## 1. Build the Test Manifest

Create and validate:

- [../test-manifest.json](../test-manifest.json)
- [../Test Manifest.md](../Test%20Manifest.md)

The manifest must enumerate:

- Every planned validation test `vt_<component>_<capability>` for Set A.
- Every planned consumer-contract test `ct_<provider>__<consumer>_<scenario>`.
- Every planned workflow test `wf_<workflow-id>` for Set B.
- Owning component, covered components, dependents, first implementation phase, status, component
  version stamps, and `testHash`.

Initial statuses:

- `planned` for tests with no built component yet.
- `pending-counterpart` for consumer-contract tests whose counterpart is not built.

## 2. Establish the Rules

Publish:

- [../Rules.md](../Rules.md)
- [../README.md](../README.md)

Rules R1-R14 are binding. Phase docs may add checks but cannot weaken the rules.

## 3. Scaffold the Skill

Create:

- [../Skill/SKILL.md](../Skill/SKILL.md)
- [../Skill/using-loom-to-build-an-extension.md](../Skill/using-loom-to-build-an-extension.md)
- `Skill/components/`
- `Skill/workflows/`
- `Skill/examples/book-club/`
- `Skill/examples/youth-soccer/`
- `Skill/examples/hoa/`
- `Skill/examples/mosque/`

The initial Skill must explain the Loom trust boundary, required App Shell structure, permission model,
extension package shape, validation loop, certification path, and publish -> QR/handle -> install ->
latest loop.

## 4. Scaffold the V2 Workspace

Create or confirm package namespaces for:

- `loom_api_contracts`
- `loom_fake_backend`
- `loom_local_store`
- `loom_seed_data`
- `loom_app_shell`
- `loom_design_system`
- `loom_lints`
- `packages/tooling/manifest_gate.dart`
- `packages/tooling/phase_gate.dart`

No domain implementation is required in Phase 0 beyond enough scaffolding for the gates to exist.

## 5. Build Tracker

Create and initialize [../Build Tracker.md](../Build%20Tracker.md).

The tracker must have all phases from 0 through B8, including the pre-split A4a/A4b service phases.

## 6. API Review

Create `Phase 0 - API Review.md`.

Record:

- Which Architecture V2 components imply OpenAPI specs.
- Which V1 specs can be reused or renamed.
- Which V2 contracts are new.
- Which specs are deferred to component phases.

## 7. Definition of Done

Phase 0 is complete when:

- Manifest parses as valid JSON.
- Manifest gate can run and report expected `planned` / `pending-counterpart` states.
- Rules, README, tracker, and Skill skeleton exist.
- Workspace scaffold and gate script placeholders exist.
- API Review filed.
- Build Tracker records Phase 0 gate evidence and commit SHA.

## 8. Next Phase

Proceed to [Phase A1 - Foundation Components.md](./Phase%20A1%20-%20Foundation%20Components.md).
