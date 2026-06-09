# Phase B2 - Book Club Headline Flow

Workflow bundle: nominate book, vote, schedule meeting, discuss, digest/search.
Components involved: Community Registry, Membership, Events, Forms/Voting, Publishing, Search, AI
Gateway, App Shell, Extension Runtime, Data Schema Store.
UX gate: high
Gate: `wf_book-club-headline` plus affected component regressions pass.

## 0. Prerequisite Gate

- B1 complete and committed.
- Manifest current for all components in the workflow.
- Book club example package from B1 is available.

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

Create `Phase B2 - UX Decisions.md`. Review book club, polling, event, and discussion patterns. Record
mobile layout for nominations, voting, event state, discussion, and digest.

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

## 10. Next Phase

Proceed to [Phase B3 - Youth Soccer Headline Flow.md](./Phase%20B3%20-%20Youth%20Soccer%20Headline%20Flow.md).
