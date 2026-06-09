# Phase B2 - Book Club Headline Flow

Workflow bundle: nominate book, vote, schedule meeting, discuss, digest/search.
Components involved: Community Registry, Membership, Events, Forms/Voting, Publishing, Search, AI
Gateway, App Shell, Extension Runtime, Data Schema Store.
UX gate: high
Gate: `wf_book-club-headline` plus affected component regressions pass.

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## 0. Prerequisite Gate

- B1b complete and committed.
- Manifest current for all components in the workflow.
- Book club local and hosted package fragments from B1a/B1b are available.
- Workflow validation target is the Demo Loom Communities App with the Local Backend.

## 1. Workflows and End States

| Workflow | End state |
| --- | --- |
| `wf_book-club-headline` | Members nominate books, vote on selection, meeting event is created, discussion thread exists, and AI/search can summarize permitted discussion. |

## 2. Workflow Tests Mapped to Owning Components

| Step | Owning component | Supporting tests |
| --- | --- | --- |
| Create book club community/space | community-registry, spaces-service | `vt_community-registry_discovery`, `vt_spaces_nesting` |
| Nominate books | data-schema-store, forms-voting-service | `vt_data-schema_register`, `vt_forms-voting_submit` |
| Vote and close poll | forms-voting-service | `vt_forms-voting_poll-results` |
| Schedule meeting | events-service | `vt_events_rsvp` |
| Open discussion | publishing-service | `vt_publishing_publish` |
| Search/digest discussion | search-service, ai-gateway, digest-service | `vt_search_permission-aware`, `vt_ai-gateway_answer`, `vt_digest_on-demand` |

## 3. UX Research and Decisions

Complete `Phase B2 - UX Decisions.md` before implementation work that affects UI, interaction, user-visible state, or workflow copy. The UX Decisions file is a gate artifact and must follow this required format:

1. **Reference Sources Reviewed** - find several reference implementations of book club nomination, poll/vote, meeting event, RSVP, discussion thread, search, AI digest, citations, and local card/open flow; record each source, surface/flow reviewed, why it applies, patterns observed, applicability/gaps, and review date.
2. **UX Patterns Extracted** - learn from the reference implementations and extract concrete patterns for task flow, entry points, state handling, trust/privacy/payment cues, layout density, accessibility, and error recovery.
3. **Key UX Decisions** - list the UX decisions made for Loom, with rationale, affected surfaces, and the acceptance signal or covering test.
4. **Key Implementation Decisions** - record implementation choices that materially alter UX, including component ownership, state model, layout behavior, validation behavior, copy source, and test coverage.
5. **Workflow Walkthrough** - walk through the workflow step by step, mapping each user goal/action to the screen or state, owning component, UX decision applied, and covering test.
6. **Open Questions / Tradeoffs** - capture unresolved questions, options considered, recommendation, owner, and when resolution is required.

The phase cannot be marked done if the UX Decisions file only contains generic notes or unreviewed placeholders. If no external references are available, record the internal reference surfaces reviewed and the reason external reference research was not possible.

## 4. Execution and Issue-Triage Loop

Run `wf_book-club-headline`. Fix failures by strengthening the owning component test first, then
routing the fix to that component agent and rerunning downstream tests.

## 5. Per-Component Regression Gate

Run all tests for any altered component and all workflows involving those components.

## 6. Skill Contribution

Add:

- `Skill/workflows/book-club-headline.md`
- Worked book club extension artifacts under `Skill/examples/book-club/`

Update component usage notes for forms/voting, events, publishing, search, and AI if the workflow
reveals practical gotchas.

## 7. Manifest Update

Stamp `wf_book-club-headline`, affected validation tests, and changed contract tests.

## 8. API Review

Create `Phase B2 - API Review.md`. Record schema, forms/voting, events, publishing, search, and AI
contract gaps.

## 9. Definition of Done

Book club workflow passes, regressions pass, Skill/example updated, manifest current, UX/API docs
filed, tracker and commit SHA recorded.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.

## 10. Next Phase

Proceed to [Phase B3 - Youth Soccer Headline Flow.md](./Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md).
