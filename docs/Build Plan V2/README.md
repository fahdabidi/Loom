# Loom Communities V2 Build Plan

Status: Draft for execution review
Source architecture: [Architecture V2/00 - System Design Tenets](../Architecture%20V2/00-system-design-tenets.md) and [Architecture V2/01 - Overall System Architecture](../Architecture%20V2/01-overall-system-architecture.md)
Source product docs: [Product Docs V2 registry](../Product%20Docs%20V2/01-core-thesis-and-platform-principles.md#21-product-area-registry)

This folder defines the phased implementation system for Loom Communities V2. It does not execute the
build. The plan adapts the V1 phase convention from `data/MVP Planning/Phases`: every phase is
self-contained, has gates, integration tests, API review, UX decisions where UI exists, tracker updates,
and a clear next phase.

V2 changes the ordering. It is component-first, then workflow-first:

1. **Phase 0** initializes rules, manifest, gates, workspace scaffolds, tracker, and the Skill.
2. **Set A** builds micro-components bottom-up by Architecture V2 layer.
3. **Set B** runs end-to-end workflows against the Demo Loom Communities App with the Local Backend and
   fixes issues by routing each fix to the owning component. The first workflow is local-only:
   generate a downloadable extension and initialization package, load it into the Demo App from the
   emulator file system, seed the fake backend, and run without a hosted backend. The real-backend
   publishing mode is also validated through local backend stubs/contracts before any external backend
   is required.

## Control Artifacts

| Artifact | Purpose |
| --- | --- |
| [Rules.md](./Rules.md) | Constitution every phase must follow. |
| [test-manifest.json](./test-manifest.json) | Machine source of truth for components, tests, phases, status, versions, and staleness. |
| [Test Manifest.md](./Test%20Manifest.md) | Human view of the machine manifest, grouped by phase. |
| [Build Tracker.md](./Build%20Tracker.md) | Phase status, gate evidence, component versions, and commit SHAs. |
| [Skill/SKILL.md](./Skill/SKILL.md) | Provider-neutral Loom extension-building Skill wrapper. |
| [Skill/using-loom-to-build-an-extension.md](./Skill/using-loom-to-build-an-extension.md) | Master walkthrough the Skill follows. |
| [Skill/setup/system-prereqs.md](./Skill/setup/system-prereqs.md) | Local setup and validation-ready contract for Codex and Claude Code execution targets. |
| [Skill/setup/prereq-manifest.json](./Skill/setup/prereq-manifest.json) | Machine-readable setup manifest for required validation tools. |

## Phase Index

| Phase | Doc | Set | Gate |
| --- | --- | --- | --- |
| 0 | [Phase 0 - Initialize Build.md](./Phases/Phase%200%20-%20Initialize%20Build.md) | Init | Manifest, rules, Skill, workspace gates, tracker exist. |
| A1 | [Phase A1 - Foundation Components.md](./Phases/Phase%20A1%20-%20Foundation%20Components.md) | Components | Foundation validation and available contract tests pass. |
| A2 | [Phase A2 - Registry and Control-Plane Components.md](./Phases/Phase%20A2%20-%20Registry%20and%20Control-Plane%20Components.md) | Components | Registry/control-plane tests to/from built providers pass. |
| A3 | [Phase A3 - Service Components I (Experience Core).md](./Phases/Phase%20A3%20-%20Service%20Components%20I%20%28Experience%20Core%29.md) | Components | Experience-service tests to/from built providers pass. |
| A4a | [Phase A4a - Service Components II (Ops and Community).md](./Phases/Phase%20A4a%20-%20Service%20Components%20II%20%28Ops%20and%20Community%29.md) | Components | Ops/community-service tests to/from built providers pass. |
| A4b | [Phase A4b - Service Components III (Economic Search and Ads).md](./Phases/Phase%20A4b%20-%20Service%20Components%20III%20%28Economic%20Search%20and%20Ads%29.md) | Components | Economic/search/ad-service tests to/from built providers pass. |
| A5 | [Phase A5 - Extension Engine Components.md](./Phases/Phase%20A5%20-%20Extension%20Engine%20Components.md) | Components | Engine tests and provider/consumer contract tests pass. |
| A6 | [Phase A6 - UX Components.md](./Phases/Phase%20A6%20-%20UX%20Components.md) | Components | UX micro-component, visual, invariant, and contract tests pass. |
| B1a | [Phase B1a - Local Build Download Sideload Install.md](./Phases/Phase%20B1a%20-%20Local%20Build%20Download%20Sideload%20Install.md) | Workflows | Skill prereq setup, local package, init package, fake backend import, and app sideload pass. |
| B1b | [Phase B1b - Publish Discover Certify Install.md](./Phases/Phase%20B1b%20-%20Publish%20Discover%20Certify%20Install.md) | Workflows | Hosted publish/certify/discover/install workflow and regressions pass. |
| B2 | [Phase B2 - Book Club Headline Flow.md](./Phases/Phase%20B2%20-%20Book%20Club%20Headline%20Flow.md) | Workflows | Book club workflow and regressions pass. |
| B3 | [Phase B3 - Youth Soccer Headline Flow.md](./Phases/Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md) | Workflows | Youth soccer workflow and regressions pass. |
| B4 | [Phase B4 - HOA Headline Flow.md](./Phases/Phase%20B4%20-%20HOA%20Headline%20Flow.md) | Workflows | HOA workflow and regressions pass. |
| B5 | [Phase B5 - Mosque Headline Flow.md](./Phases/Phase%20B5%20-%20Mosque%20Headline%20Flow.md) | Workflows | Mosque workflow and regressions pass. |
| B6 | [Phase B6 - Messaging In-Stream Ads and Connections.md](./Phases/Phase%20B6%20-%20Messaging%20In-Stream%20Ads%20and%20Connections.md) | Workflows | Required shell surfaces, messages, ads, and connections pass. |
| B7 | [Phase B7 - Ad-Off.md](./Phases/Phase%20B7%20-%20Ad-Off.md) | Workflows | Ad-off workflow and economic regressions pass. |
| B8 | [Phase B8 - Export and Migration.md](./Phases/Phase%20B8%20-%20Export%20and%20Migration.md) | Workflows | Export/migration and redaction regressions pass. |
| B9 | [Phase B9 - Arbitrary Local Package Ingestion.md](./Phases/Phase%20B9%20-%20Arbitrary%20Local%20Package%20Ingestion.md) | Workflows | Arbitrary local package contents are parsed, imported, rendered, and opened without fixture substitution. |
| B10 | [Phase B10 - Skill Arbitrary Extension Test Run.md](./Phases/Phase%20B10%20-%20Skill%20Arbitrary%20Extension%20Test%20Run.md) | Workflows | Arbitrary Skill-generated artifacts replay through the Demo App Local Backend and open locally. |
| B11 | [Phase B11 - Skill Prompt Build Validate Complete.md](./Phases/Phase%20B11%20-%20Skill%20Prompt%20Build%20Validate%20Complete.md) | Workflows | Owner prompt produces docs, packages, local install/open, workflow validation, and a complete report. |
| B12 | [Phase B12 - Skill Reference Methodology.md](./Phases/Phase%20B12%20-%20Skill%20Reference%20Methodology.md) | Workflows | The Skill uses Loom reference implementations, UX methodology, API maps, and phase templates before execution. |
| B13 | [Phase B13 - Skill Multi Prompt Validation.md](./Phases/Phase%20B13%20-%20Skill%20Multi%20Prompt%20Validation.md) | Workflows | Multiple arbitrary community prompts generate packages that pass local Demo App workflow validation. |

## Shared Execution Convention

All phase implementation happens from `app/` in the melos monorepo through WSL Ubuntu. Do not run
Dart, Flutter, Melos, package validators, manifest gates, phase gates, or workflow tests from
Windows-native PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Commands are
expected to use the same harness as V1: `loom_api_contracts`, `loom_fake_backend`, `loom_local_store`,
`loom_seed_data`, `loom_lints`, and Flutter integration tests under the demo app.

Baseline commands:

| Purpose | Command |
| --- | --- |
| Bootstrap | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos bootstrap'` |
| Skill prereq setup | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/skill_prereq_setup.dart --target codex --mode local-demo'` |
| Skill prereq check | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/skill_prereq_check.dart --mode local-demo'` |
| Analyze | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run analyze'` |
| Boundary lints | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run lint:boundaries'` |
| Unit tests | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run test'` |
| Integration tests | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run test:integration'` |
| Extension package validation | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run validate:extension'` |
| Extension asset validation | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run validate:extension-assets'` |
| Initialization package validation | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run validate:initialization'` |
| Local demo sideload workflow | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run test:demo-local'` |
| Local validation-ready workflow | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run test:demo-local-prereq'` |
| Workflow validation target | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && melos run test:workflows:demo-local'` |
| Manifest gate | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/manifest_gate.dart --manifest ../docs/Build\\ Plan\\ V2/test-manifest.json'` |
| Phase gate | `wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && dart run packages/tooling/phase_gate.dart --phase <phase>'` |

## Required Sibling Docs

Every phase creates or updates:

- `Phase X - API Review.md`: API conformance, OpenAPI gaps, payload/idempotency/pagination notes.
- `Phase X - UX Decisions.md`: required where the phase changes UI or workflow UX; optional but allowed
  for component-only phases. When required, it must be completed before implementation and follow the
  R20 structure: reference sources reviewed, UX patterns extracted, key UX decisions, key
  implementation decisions, workflow walkthrough, and open questions / tradeoffs.

## Completion Rule

A phase is complete only when [Rules.md](./Rules.md) R12 and R20 are satisfied: tests green, manifest
current, staleness gate green, Skill updated, API Review filed, UX Decisions completed where
applicable, Build Tracker updated, phase changes committed, and commit SHA recorded. Do not start the
next phase until the prior phase commit exists and is recorded in the tracker.
