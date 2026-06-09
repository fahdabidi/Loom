# Phase B8 - UX Decisions

Status: Second-pass UX research required before phase execution

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for export, migration, redaction explanation, checksums, provider transfer, rollback, retained-record disclosure, full regression summary, and final readiness UX. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

Before implementing this phase, find several reference implementations of export, migration, redaction explanation, checksums, provider transfer, rollback, retained-record disclosure, full regression summary, and final readiness UX. Record enough detail that another agent can understand what was reviewed and why it applies. Use current references available at execution time, and prefer mature production products over generic inspiration.

Research focus:

- Find several reference implementations of export/download, migration wizard, import preview, redaction explanation, checksum/verification, provider transfer, rollback, and retained-record disclosure UX.
- Extract patterns for confidence-building, progress, resumability, irreversible actions, verification, failure recovery, and privacy explanation.
- Review how references communicate what data is omitted, redacted, retained, or protected during export/migration.

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD | TBD | TBD |

## UX Patterns Extracted

Learn from the reference implementations before making Loom-specific decisions. Extract concrete patterns, not general preferences.

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD | TBD |

Required pattern categories:

- Primary task flow and entry points.
- Empty, loading, success, failure, retry, and duplicate-action states.
- Permission, privacy, trust, payment, certification, or sensitive-data cues where applicable.
- Mobile and desktop layout density, hierarchy, and navigation.
- Accessibility, labels, tap targets, keyboard/focus behavior, and reduced-motion expectations.
- Error prevention and recovery copy.

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD |
| TBD | TBD | TBD | TBD |

## Workflow Walkthrough

Workflow under review: `wf_export-migration`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Start export | TBD | TBD | TBD | TBD |
| 2 | Preview included components | TBD | TBD | TBD | TBD |
| 3 | Explain protected-data redaction | TBD | TBD | TBD | TBD |
| 4 | Generate checksum | TBD | TBD | TBD | TBD |
| 5 | Transfer provider package | TBD | TBD | TBD | TBD |
| 6 | Verify target state | TBD | TBD | TBD | TBD |
| 7 | Handle rollback | TBD | TBD | TBD | TBD |
| 8 | Display final readiness/regression summary | TBD | TBD | TBD | TBD |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| TBD | TBD | TBD | TBD | Phase implementation |
| TBD | TBD | TBD | TBD | Phase implementation |

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
