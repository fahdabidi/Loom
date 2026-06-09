# Loom Communities V2 Build Rules

Status: Draft for execution review

These rules are the constitution for every phase under [Phases](./Phases). A phase may add
phase-specific checks, but it may not weaken these rules.

## R1 Bottom-up layering

Build Foundation -> Registry/control-plane -> Service -> Extension engine -> UX. Synchronous calls
must not depend upward. Upward effects are allowed only through typed events on the Event Bus.

## R2 One agent per component, parallel

Component phases run one worktree-isolated background agent per component where practical. Each agent
owns one Component Contract Card and its acceptance suite. Merges are serialized after tests pass to
avoid cross-agent races.

## R3 Contract-first implementation

Every component exposes a typed `Community*Api` contract in `loom_api_contracts`. Consumers depend on
contracts and fakes, not concrete implementations or storage.

## R4 Provider-authored consumer-contract tests

Each provider component ships the `ct_<provider>__<consumer>_<scenario>` tests its dependents must run.
If the dependent does not exist yet, the test is authored and registered as `pending-counterpart`.

## R5 Component-phase gate

A component phase is done only when all required tests touching each phase component pass:

- All owned validation tests `vt_<component>_<capability>`.
- All provider-side contract tests where the component is provider.
- All consumer-side contract tests where the component consumes already-built providers.
- All altered integration tests touching the component.

Skip only tests whose counterpart component does not exist yet, and record that as
`pending-counterpart` in the manifest.

## R6 Workflow fix loop

Workflow phases use the red-bar-first loop:

1. Add or strengthen the validation/contract test in the owning component that catches the issue.
2. Route the fix to the owning component agent.
3. Update downstream validation or contract tests affected by the fix.
4. Rerun the workflow and all affected component regressions.

## R7 Manifest is source of truth

Every validation, contract, and workflow test must be registered in `test-manifest.json` with owner,
covered components, phase first implemented, status, test hash, and last-run component versions.

## R8 Staleness gate

A test is stale if the current version hash of any component it covers differs from the version stamped
in `lastRunComponentVersions`, or if the test file hash differs from `testHash`. No phase can complete
with stale required tests.

## R9 Idempotency, versioning, and audit

Every mutation is idempotent, versioned, and audited. Sensitive operations use redacted audit and route
through protected-vault policy.

## R10 Platform invariants

The App Shell top ad banner and in-stream ad items are not suppressible by extensions. The nav panel
always exposes Messages and Connections. The payment surface is Loom-owned. Certification lint enforces
these invariants.

## R11 Every phase updates the Skill

Set A phases add or refresh `Skill/components/<component>.md`. Set B phases add or refresh
`Skill/workflows/<workflow>.md` and grow examples under `Skill/examples/<vertical>/`.

## R12 Definition of done

A phase is done only when:

- Required tests pass.
- Manifest and staleness gates pass.
- Skill contribution is complete.
- API Review is filed.
- UX Decisions is filed where UI or workflow UX changed.
- Build Tracker records status, gate evidence, component versions, and commit SHA.

## R13 Reuse the V1 harness

Use `loom_api_contracts`, `loom_fake_backend`, `loom_local_store`, `loom_seed_data`,
`loom_lints`, melos scripts, and Flutter integration tests. Do not create a parallel test harness unless
the phase explicitly records why the existing harness cannot support the component.

## R14 A4 service split

The Service layer is pre-split to avoid an overloaded component phase:

- **A4a**: ops/community services: case/task, documents, facilities, import/export, provider transfer,
  trust/safety case intake, moderation, incident/dispute scaffolds.
- **A4b**: economic/search/ad services: wallet, ads/ad decision, ad campaign, receipt-adjacent
  integrations, settlement, utility funding, search, indexing, AI gateway, digest, fraud signal.

Do not merge A4a and A4b during execution. If either still exceeds clean parallel review capacity,
split further only by adding a new phase and updating the manifest first.

## Test Naming

| Type | Pattern | Example |
| --- | --- | --- |
| Validation | `vt_<component>_<capability>` | `vt_community-registry_discovery` |
| Contract | `ct_<provider>__<consumer>_<scenario>` | `ct_community-registry__app-shell_resolve-by-qr` |
| Workflow | `wf_<workflow-id>` | `wf_build-publish-discover-install` |
| Legacy V1 compatibility | `it_p<N>_<id>` | Keep only for migrated V1 demo tests. |

## Status Values

Use these machine status values in the manifest:

- `planned`
- `pending-counterpart`
- `ready`
- `pass`
- `fail`
- `stale`
- `blocked`
