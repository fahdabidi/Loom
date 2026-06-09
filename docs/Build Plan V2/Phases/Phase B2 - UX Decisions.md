# Phase B2 - UX Decisions

Status: Complete - R20 second-pass UX decisions applied

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow walkthrough, and open tradeoffs for book club nomination, poll/vote, meeting event, RSVP, discussion thread, search, AI digest, citations, and local card/open flow. This file is a phase gate artifact, not a placeholder.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Bookclubs](https://bookclubs.com/) | Book club home, polls, meetings, member management, chat. | B2's vertical is an organized reading group. | The product separates book selection, meeting scheduling, membership, and chat into clear tasks. | Loom uses extension workflows and shared services instead of a single-purpose app. | 2026-06-09 |
| [Bookclubs poll tutorial](https://bookclubs.com/blog/tutorial-three-how-to-create-a-poll) | Poll creation/voting for book and meeting choices. | B2 needs nomination and voting states. | Polls can be tied to book metadata, vote limits, options, and meeting-time decisions. | Loom's B2 test starts with a simple form and vote; ranked/advanced polls are later. | 2026-06-09 |
| [Goodreads Groups](https://www.goodreads.com/group) | Reader groups, discovery, discussion posts. | Book clubs need open-ended discussion and searchable group knowledge. | Groups emphasize topic discovery, threads, and ongoing discussion archives. | Goodreads is public/social; Loom must keep community permission boundaries. | 2026-06-09 |
| [Slack polls](https://slack.com/help/articles/229002507-Conversations--Create-a-poll-in-Slack) and [Slack threads](https://slack.com/help/articles/115000769927-Use-threads-to-organize-discussions) | Lightweight vote collection and thread organization. | B2 uses quick poll/vote plus discussion thread behavior. | Polls gather member input quickly; threads prevent clutter and keep context. | Loom uses Forms/Voting and Messaging/Publishing services rather than Slack apps. | 2026-06-09 |
| [Google Calendar create events](https://developers.google.com/workspace/calendar/api/guides/create-events) and [Google Calendar invite guests](https://support.google.com/calendar/answer/37161) | Event details, guests, RSVP state. | Book clubs need meeting creation and attendance signal. | Event UX needs clear time/details and RSVP response state. | B2 validates event + RSVP contract, not full calendar sync UI. | 2026-06-09 |
| [Bookclubs discussion questions](https://bookclubs.com/blog/ultimate-list-of-book-club-discussion-questions) | Guided discussion prompts and recaps. | B2's AI digest should summarize discussion with citations. | Helpful discussion surfaces provide prompts, questions, and meeting support. | Loom's digest must cite permitted indexed records and avoid inventing content. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Separate nominate -> vote -> selection states | Bookclubs poll tutorial | Members need to understand whether they are suggesting, voting, or seeing the winner. | Forms/Voting uses separate form and poll IDs; publishing announces selected book. | Advanced poll types are deferred. |
| Meeting event follows the winning selection | Bookclubs, Google Calendar | A book choice should lead directly into a scheduled discussion. | Events service creates the meeting after voting. | Date/time UI is not built in B2. |
| RSVP is a simple attendance state | Google Calendar | Hosts need expected attendance. | Event RSVP stores a going state and ticket code. | Waitlist/capacity UX comes later. |
| Discussion stays attached to the book/event | Goodreads, Slack threads | Members need organized conversation without losing context. | Publishing and messaging use a discussion thread tied to the book selection. | Spoiler controls are not in B2. |
| Digest must cite indexed permitted content | Bookclubs discussion prompts, Goodreads archives | AI summaries need trust and traceability. | Digest returns citation record IDs from indexed published content. | AI must respect permission-aware search boundaries. |

## Key UX Decisions

List the UX decisions that must be reflected in implementation. Each decision must trace to either a reference pattern, a Loom platform invariant, or a workflow requirement.

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Model nomination and vote as separate workflow steps. | Prevents users from confusing suggestions with final selection. | Forms/Voting, Skill book-club guide. | `wf_book-club-headline`, `vt_forms-voting_submit`, `vt_forms-voting_poll-results` |
| Publish the selected book before event/discussion activity. | The selected book becomes the shared context for RSVP and discussion. | Publishing, Events, Messaging. | `wf_book-club-headline` |
| RSVP state is lightweight in B2. | Headline flow needs attendance proof without full event management UI. | Events Service. | `vt_events_rsvp`, `wf_book-club-headline` |
| Discussion and digest use permission-aware indexed records. | AI recap must not summarize content outside the member's allowed scope. | Search Service, AI Gateway, Digest Service. | `vt_search_permission-aware`, `vt_ai-gateway_answer`, `vt_digest_on-demand`, `wf_book-club-headline` |
| Local card/open remains the same Demo App shell contract. | Vertical workflows should prove extension behavior without changing shell invariants. | Demo App, App Shell Runtime, Community Card. | `vt_demo-app_open-local-extension`, `wf_book-club-headline` |

## Key Implementation Decisions

Record implementation decisions that materially alter the UX, including component ownership, state model, copy source, layout behavior, validation behavior, and test coverage.

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Keep B2 as a workflow contract over existing services, not a new visual book-club screen. | Validates service composition first; UI can be layered onto stable contracts. | Workflow Validation Harness. | `wf_book-club-headline` |
| Use explicit IDs for nomination form, vote poll, event, discussion, and digest. | Makes each workflow state inspectable and testable. | Forms/Voting, Events, Publishing, Digest. | `wf_book-club-headline` |
| Digest citations use indexed record IDs. | Users and tests can trace AI output back to permitted source content. | Indexing/Search, AI Gateway, Digest. | `wf_book-club-headline` |
| Keep Skill example artifacts under the book-club example path. | The Skill can reuse the same local and publish package context as B1a/B1b. | Skill workflow guide. | Skill example review, B2 workflow guide |

## Workflow Walkthrough

Workflow under review: `wf_book-club-headline`. Walk through the experience step by step after the UX decisions are made. Include the screen or state shown, the user action, the owning component, and the covering test.

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Nominate a book. | Nomination form captures member's proposed book. | Forms/Voting, Data Schema Store. | Separate nominate state. | `wf_book-club-headline` |
| 2 | Vote in the monthly poll. | Poll records member vote and result count. | Forms/Voting. | Separate vote state. | `wf_book-club-headline` |
| 3 | Publish selected book. | Selection post announces the winner. | Publishing Service. | Selected book before event/discussion. | `wf_book-club-headline` |
| 4 | Create discussion event. | Meeting event is created for the selected book. | Events Service. | Meeting follows winning selection. | `wf_book-club-headline` |
| 5 | RSVP. | Member marks going and receives attendance proof. | Events Service. | Lightweight RSVP. | `wf_book-club-headline` |
| 6 | Post in discussion. | Member contributes discussion message. | Messaging/Publishing. | Discussion attached to book/event. | `wf_book-club-headline` |
| 7 | Index content. | Published selection is indexed with visibility metadata. | Indexing/Search Service. | Permission-aware source record. | `wf_book-club-headline` |
| 8 | Generate cited digest. | AI answer and digest cite indexed record IDs. | AI Gateway, Digest Service. | Cited digest. | `wf_book-club-headline` |

## Open Questions / Tradeoffs

Capture unresolved UX questions and tradeoffs before implementation starts. A phase can proceed only when blockers are resolved or explicitly accepted.

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should B2 include a full visual book-club screen? | Build UI now, validate workflow contracts now. | Keep B2 contract-first; add polished vertical UI when UX shell patterns stabilize. | App Shell / Extension Runtime. | Vertical UI polish |
| Should book voting support ranked choice immediately? | Single vote now, ranked-choice now. | Single vote for headline flow; advanced poll options later. | Forms/Voting Service. | Advanced voting backlog |
| Should digest summarize private messages? | Public published content only, permission-aware private content. | Use permitted indexed records only; private message digest requires explicit consent. | AI Gateway / Search. | Sensitive-data workflow |
| Should event capacity/waitlist be part of B2? | Capacity only, waitlist now. | Validate RSVP and capacity basics now; waitlist belongs to facilities/events enhancement. | Events Service. | Future event polish |

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
