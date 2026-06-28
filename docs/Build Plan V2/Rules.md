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
- For any local validation phase, Skill prereq setup passes and the validation environment lock is
  current.
- API/OpenAPI specs owned or changed by the phase exist, validate, and are linked from the API Review.
- Skill contribution is complete.
- API Review is filed.
- UX Decisions is filed where UI or workflow UX changed.
- Phase changes are committed to git.
- Build Tracker records status, gate evidence, component versions, and the exact commit SHA.

No next phase may start from uncommitted prior-phase changes. If a fix-up is needed after the commit,
make a follow-up commit and update the tracker to the latest applicable SHA before advancing.

For B25 specifically, every independent UX review/remediation iteration has the same commit boundary as
a phase. Do not start the next UX feedback loop or correction batch until the current B25 iteration's
review evidence, fixes, refreshed screenshots or screenshot references, tests, remaining findings, and
tracker updates are committed and the remediation loop log records that commit SHA.

## R13 Reuse the V1 harness

Use `loom_api_contracts`, `loom_fake_backend`, `loom_local_store`, `loom_seed_data`,
`loom_lints`, the Loom Communities Demo App, `loom_skill_prereq_setup`, melos scripts, and Flutter
integration tests. Run all harness commands through WSL Ubuntu from `app/`; `dart`, `flutter`, and
`melos` must resolve inside Ubuntu, not from Windows-native shells. Do not create a parallel test
harness unless the phase explicitly records why the existing harness cannot support the component.

## R14 A4 service split

The Service layer is pre-split to avoid an overloaded component phase:

- **A4a**: ops/community services: case/task, documents, facilities, import/export, provider transfer,
  trust/safety case intake, moderation, incident/dispute scaffolds.
- **A4b**: economic/search/ad services: wallet, ads/ad decision, ad campaign, receipt-adjacent
  integrations, settlement, utility funding, search, indexing, AI gateway, digest, fraud signal.

Do not merge A4a and A4b during execution. If either still exceeds clean parallel review capacity,
split further only by adding a new phase and updating the manifest first.

## R15 Local-first extension delivery gate

Before any hosted publish/certify workflow is required, B1a must prove the local preliminary product:

- The Loom Communities Demo App starts with zero communities.
- The App Shell shows an empty-state community card area and an `Add Community` action.
- The user can choose a local extension package from the emulator file system.
- The app validates the package, imports its initialization package into the fake in-app backend, and
  persists records in the local DB.
- The installed community appears as a card and opens in the App Shell using the latest local package.

Hosted publish, QR, and marketplace behaviors cannot substitute for this local sideload gate.

## R16 Skill debug loop

The Skill must be testable like product code. Each phase that changes the Skill updates:

- Prompt fixtures and expected package outputs.
- Golden extension and initialization packages.
- Validator diagnostics and remediation examples.
- Transcript capture/replay notes for failed Skill runs.

B1a cannot complete until the Skill can generate a downloadable extension package and initialization
package from at least one golden prompt and the Demo App can load both.

## R17 Skill modes and workflow validation target

The Skill supports exactly two delivery modes:

- `local-demo`: build a downloadable extension package and initialization package for the Demo Loom
  Communities App with the Local Backend.
- `real-backend-publish`: build the package and backend initialization payloads needed for a real Loom
  Communities backend publish flow.

All Set B validation workflow tests run against the Demo Loom Communities App with the Local Backend.
Real-backend publishing behavior is validated through local backend stubs, contract fakes, and
conformance tests first. A phase may document a later hosted smoke test, but the phase gate cannot
depend on an external backend.

## R18 Execution environment bootstrap

The first supported Skill execution targets are Codex and Claude Code. Online-only ChatGPT, Claude.ai,
and Gemini.com support is deferred until Loom has a hosted build and validation backend.

Before any local workflow validation runs, the Skill prereq setup component must:

- Verify WSL Ubuntu is the active tooling environment.
- Load `Skill/setup/prereq-manifest.json`.
- Detect the host, shell, repo path, and execution target.
- Produce an install/configuration plan before changing the environment.
- Install or configure approved missing tools.
- Verify required tool commands and versions.
- Write `Skill/setup/validation-environment.lock.json`.
- Pass the Demo App local validation smoke check.

The phase gate must fail if `validationReady` is false, if the environment lock is stale, if WSL Ubuntu
tooling is not active, or if the selected execution target is unsupported.

## R19 Locked package and branding format

Extension artifacts use two locked downloadable formats:

- `<extension-id>.loom-extension.zip` contains `loom.extension.json`, UI, bundled assets, schemas,
  rules, workflows, jobs, optional functions, fixtures, tests, docs, and signatures.
- `<extension-id>.loom-init.zip` contains `loom.initialization.json`, seed assets, fixtures, and an
  import plan.

All local-demo assets must be bundled locally, declared in the manifest, hashed, size-limited,
format-limited, dimension-validated, and labeled with alt text or decorative metadata. The App Shell
owns community-card rendering. Card image priority is community card image -> community logo ->
extension default card image -> generated initials/category/accent-color fallback.

## R20 UX research and decision gate

Any phase with UI, interaction, user-visible workflow state, or user-facing copy must complete its
sibling `Phase X - UX Decisions.md` before implementation. The UX Decisions file must include:

- Reference sources reviewed: several reference implementations, the surfaces/flows reviewed, why each
  applies, observed patterns, applicability/gaps, and review date.
- UX patterns extracted: concrete patterns learned from the references, including task flow, states,
  trust/privacy/payment cues, layout density, accessibility, and recovery behavior.
- Key UX decisions: Loom-specific decisions with rationale, affected surfaces, and acceptance signals.
- Key implementation decisions: choices that materially alter UX, including component ownership, state
  model, validation behavior, layout behavior, copy source, and tests.
- Workflow walkthrough: step-by-step user actions mapped to screens/states, owning components, UX
  decisions, and covering tests.
- Open questions / tradeoffs: unresolved options, recommendation, owner, and resolution deadline.

A phase cannot complete with a UX Decisions file that only contains generic notes or unreviewed
placeholders.

## R21 Independent UX judge tools

UX pass/fail gates must separate implementation from judgment. The Worker Agent implements fixes, the
Evidence Collector Tool captures artifacts, the Judge Agent scores only supplied evidence, and the
Remediation Planner converts judge failures into the next fix batch.

The required judge tools are:

- B11 `workflow_completeness_judge.dart`
- B21 `ux_contract_judge.dart`
- B22 `domain_surface_classifier.dart`
- B23 `persona_ux_judge.dart`
- B24 `evidence_integrity_auditor.dart`
- B25 `production_ux_judge.dart`

Judge agents and judge tools may receive only artifacts, screenshots, blueprint/contracts, pass
criteria, evidence metadata, and remediation logs. They must not receive worker implementation notes,
intended behavior summaries, or optimistic completion claims. If the artifact does not prove a
criterion, the criterion fails.

B25 must express production UX pass criteria as direct questions, not only as abstract checklist
statements. The Production UX Judge must run one holistic product UX pass and one workflow/persona pass
for every reviewed workflow/persona pair. Both passes must be green before B25 can close. A holistic
pass cannot hide a weak workflow, and passing workflow/persona rows cannot hide an incoherent,
non-modern, or non-production overall UI.

A phase cannot complete when its required judge scorecard has a blocking criterion failure.

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
