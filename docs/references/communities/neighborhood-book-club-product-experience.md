# Neighborhood Book Club Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Neighborhood Book Club |
| Community type | Reading group |
| Product promise | Help members nominate, vote, discuss, RSVP, and discover reading context without leaving the club space. |
| Brand cues | Book, discussion, calendar, and reading-list cues; editorial but utilitarian tone. |
| What this must not feel like | A list of book workflows with generic completion buttons. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Member | Nominate, vote, RSVP, discuss, search/digest | Participate in the reading cycle and know what to read next. | Discussion messages and preferences stay within club context. | Member sees selected book, meeting details, vote/discussion state. |
| Organizer | Publish selection and export metadata | Curate reading cycle and keep data portable. | Export must show scope and checksum. | Selection published and members have clear next step. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Book club home | Current book cycle. | Member | current/next book, nominations, vote status, meeting, discussion prompt. | Vote / RSVP / discuss |
| Nomination/detail | Submit or inspect nomination. | Member | title, author, reason, nominator. | Nominate book |
| Vote surface | Pick/read vote state. | Member | candidates, current totals/status, deadline. | Cast vote |
| Reading calendar | Track meetings, reading deadlines, and reminders. | Member/organizer | meeting title, date/time, location/link, recurrence, RSVP/reminder state. | RSVP / add reminder |
| Reading materials | Open book guides, author links, excerpts, or external notes. | Member | document/link title, source, access, embedded/external open choice. | Open material |
| Shared library | Borrow or give away books, DVDs, audiobooks, or board games. | Member | item title/format, owner/current holder, due date, queue, loan/giveaway state. | Browse library / join queue |
| Discussion | Member conversation. | Member | prompt, latest messages, author. | Send message |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Member | Home, Books, Calendar, Discussions, Messages | current selection, open ballot, next meeting | Book-forward typography, cover art where available, reading-progress and vote state. |
| Host | Home, Books, Calendar, Admin, Documents, Messages | nomination queue, ballot results, selected-book publish action | Host tabs expose publish and export surfaces that members see as read-only or hidden. |

## 4. Home Screen Requirements

The home must make the current reading cycle obvious: what book is being chosen or read, when the group
meets, and how the member participates next.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Nomination | title, author, reason, nominator | draft/submitted/selected | nominate, edit | workflow card only |
| Vote | candidates, deadline, vote status | open/voted/closed | vote, change vote | abstract poll chip |
| Calendar meeting RSVP | meeting title, date, location/link, recurrence/reminder, attendance | open/RSVPed/full/cancelled | RSVP, change RSVP, add reminder | checklist dialog |
| Reading materials | title, author/source, version/date, access, open mode | available/read/acknowledged/access-requested | open embedded, launch external, save, acknowledge | raw external URL |
| Shared library | book/DVD/game title, format, owner/current holder, due date, queue position, condition | available/queued/borrowed/overdue/given/returned/lost | browse, list item, request loan, join queue, return, claim giveaway | generic equipment wording or no current-holder state |
| Discussion | prompt, message body, sender | empty/unread/sent | reply | generic message workflow |

> **Reconciliation note — 2026-08-10** (Community JSON Migration effort,
> `docs/Build Plan V2/Community JSON Migration Tracker.md` §3): the doc's `book-shared-library` and the real
> implementation's `book-library-item` (`part02_tab_shell.dart:12852-12875`) are reconciled as **one**
> workflow, `book-shared-library-item` (a name preserving both), expanded to deliver this doc's full
> richness. Concrete gaps found in the current implementation that the engine-native JSON must close:
> - No `ownerPersonaId` field distinct from `currentHolder` — the doc's §7 explicitly separates
>   "owner/steward" from "current holder" (owner lists the item; holder is whoever has it right now).
>   Add both.
> - No `dueDate` field at all, despite §5/§6 explicitly requiring it. Add it (set on loan-approval, cleared
>   on return, following the same shape Garden Club's `garden-tool-loan-giveaway` and Camera Club's
>   `gear-loan-request` already use for `pickupBy`/`dueDate`).
> - No `overdue` state, despite §5 listing it as a required state. Per `04-antipatterns.md` AP-1 (don't
>   model an orthogonal/derivable condition as an FSM state), realize this as a computed
>   `isOverdue: isPast(dueDate)` formula-driven indicator on the `borrowed`/`queued`-equivalent state, not
>   a separate terminal FSM state — mirrors how every other derived status in this codebase's fixtures is
>   handled (e.g. Camera Club's `isAvailable`/`isFull`).
> - `offer-giveaway` is only reachable from `returned` in the current implementation — a loan-only item
>   must complete one full borrow/return cycle before it can ever be offered as a giveaway. The doc's §5/§9
>   describe loan-vs-giveaway as a mode the lister **chooses up front** (matching Garden Club's
>   `garden-tool-loan-giveaway` and Camera Club's `gear-loan-request` patterns) — fix so a member can list
>   an item as a giveaway from the start. Whether to split into two workflow types (Garden Club's approach)
>   or one type with a `listingMode` field (Camera Club's approach) is left to the authoring Skill, matching
>   whichever precedent it finds cleaner — either is acceptable, just don't gate giveaway behind a prior
>   loan cycle.
> - The current implementation binds this workflow to `tabId: "library"` with
>   `cardSurfaceFamily: "stateMachineGrid"` — **neither is real.** The closed `tabId` enum
>   (`docs/references/reference/render-bindings.md`) has no `library` value, and `stateMachineGrid` is not
>   one of the 13 real archetypes (9 original + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`, promoted 2026-08-11) (`docs/references/archetypes/README.md`). The engine-native JSON must bind
>   to the real `marketplace` tab with `cardSurfaceFamily: "equipment-loan"`, the same real archetype every
>   other community's shared-item marketplace already uses.
> - Queue position (`indexOf(queuePersonaIds, $viewer)`) is a real formula gap the doc's §5/§6 requires
>   ("queue position") but the current implementation only exposes the raw list, not a computed position.
>
> `book-search-ai-digest` also needs the citation-list extension (§1.2 / CJM.3, now landed and available).

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| book-nomination | member | Nomination form/detail | book title/author/reason and submitted state | Publishing/forms/events | B14/B25 |
| book-vote | member | Vote surface | candidates and voted result | Voting/events/audit | B14/B25 |
| book-meeting-rsvp | member | Reading calendar meeting detail | meeting title, date/time, location/link, recurrence/reminder, attendance | Calendar/events/notifications | B14/B25 |
| book-reading-material | member | Reading materials detail | document/link title, source, embedded/external open option, access/acknowledgement state | Documents/external documents/audit | B14/B25 |
| book-shared-library-item | member | Shared library item detail | searchable book/DVD/game listing, owner/current holder, queue position, due date, loan/giveaway mode, return or transfer state | Shared item marketplace/loan/giveaway, notifications, audit | B25 |
| book-discussion-message | member | Discussion thread | prompt/message/sender | Messaging/events | B14/B25 |
| book-selection-publish | owner | Admin publish | selected book/audience/timing | Publishing/notifications | B14/B25 |
| book-search-ai-digest | member | Search/digest | query/citations/summary | Search/AI/digest | B14/B25 |
| book-export-metadata | owner | Export status | scope/checksum/redaction | Export/documents | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| book-nomination | member submits a concrete book nomination with title/author/rationale | organizer sees nomination in ballot-prep queue | members can read submitted nomination and rationale | submit disabled without title, author, and rationale | non-members cannot nominate and see public reading list only |
| book-vote | member casts or changes vote on open ballot | organizer sees aggregate vote status/results | members can read ballot and their selected state | voting disabled after close or without eligibility | guests cannot vote and see public meeting summary only |
| book-meeting-rsvp | member chooses going/maybe/not attending for the named meeting | organizer sees attendee count and waitlist | non-attendees can view meeting details | RSVP disabled when closed or full | non-members cannot RSVP |
| book-reading-material | member opens a reading guide, external note, or excerpt | organizer sees access/acknowledgement where required | source/version readable | request access shown for private materials | non-members cannot open private club materials |
| book-shared-library-item | member borrows, queues for, lists, or gives away a club item | owner/steward sees borrower, queue, current-holder/custody, due, and return state | members can see availability and queue position with privacy-safe holder labels | loan disabled when unavailable; queue shown when waitlisted | private owner/current-holder contact hidden until approved handoff |
| book-discussion-message | member posts/replies in discussion thread | members see sender, body, timestamp, and read/unread state | organizer can moderate/read thread | send disabled without message body | non-members cannot post or read private discussion |
| book-selection-publish | owner publishes selected book announcement to members | members receive selected book and meeting update | guests can read public meeting summary | publish hidden for members | non-owners cannot publish |
| book-search-ai-digest | member asks for cited club digest/search result | members receive answer with citations and source visibility | organizer can read saved digest | answer disabled without query/source context | non-members cannot query private club data |
| book-export-metadata | owner exports book club metadata with redaction/checksum | provider/import reviewer sees verified export status | members see export status without protected fields | export disabled until checksum and redaction preview pass | non-owners cannot export or transfer |

## 8. Content And Seed Data Requirements

Use real book titles/authors, meeting dates/locations/links, reading material titles/sources,
shared-library item formats, current-holder/queue/due-date examples, discussion prompts, vote
candidates, digest citations, sender names, and export metadata.

## 9. Visual And Interaction Standard

Use readable book-cycle sections, clear editorial hierarchy, discussion thread affordances, and compact
meeting/vote cards. Avoid generic workflow-card repetition.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| book-nomination | member | Member decides whether a concrete title belongs on the ballot after reviewing title, author, rationale, genre, nominator, and meeting cycle. | submit nomination, nominate book, save nomination | edit nomination, withdraw nomination, change title | Fresh screenshots must show title/author/rationale, ballot state, edit path, submitted result, and member receiver state for this persona. |
| book-vote | member | Member chooses one nominated book after comparing candidates, vote deadline, current count, selected state, and meeting context. | record vote, vote, select book | change vote, clear vote, choose another book | Fresh screenshots must show nominated books, selected/winning state, change-vote path, recorded result, and member receiver state for this persona. |
| book-meeting-rsvp | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| book-reading-material | member | Member opens a concrete reading material with title/source/access, chooses embedded or external open, and can save or acknowledge it. | open document, launch external, save material, acknowledge | request access, mark unread, share within club | Fresh screenshots must show title/source/version, embedded/external open choices, access/acknowledgement state, and reading-cycle linkage. |
| book-shared-library-item | member | Member browses books, DVDs, or games, checks current holder/queue/due date, requests a loan or giveaway, and can list/edit/delist their own item. | browse library, list item, request loan, join waitlist, claim giveaway, return item | leave queue, edit listing, delist, report lost, renew/extend, cancel loan | Fresh screenshots must show item title/format, owner/current-holder privacy, queue position, custody/due/condition state, and return or ownership-transfer result. |
| book-discussion-message | member | Member evaluates a concrete message, connection, or invite with sender/recipient context and accept/decline/block paths. | send message, reply, send invite, accept invite, connect | decline, block, mute, archive, cancel invite | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| book-selection-publish | owner | Admin decides whether a concrete announcement is ready for a named audience and delivery timing; members can later read the delivered update. | publish announcement, send announcement, post announcement, schedule announcement | edit announcement, preview announcement, save draft, schedule later, change audience | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| book-search-ai-digest | member | User decides a concrete community task with enough context, a semantic primary action, a meaningful alternative, and a durable result. | submit, save, send | edit, change, undo, reject, withdraw | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| book-export-metadata | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `book-nomination` | [nomination](../../CardSurfaces/book-nomination.md) | `CommunityNominationApi` | create/edit/withdraw nomination, duplicate/eligibility checks, ballot linkage, status | Demo renderer must select a domain-native surface for `nomination` and LocalInAppBackend must expose/import the state for these interactions. |
| `book-vote` | [vote](../../CardSurfaces/vote-poll.md) | `CommunityVoteApi` | open/close ballot, cast/change/clear vote, results/tie handling, selection publish | Demo renderer must select a domain-native surface for `vote` and LocalInAppBackend must expose/import the state for these interactions. |
| `book-meeting-rsvp` | [calendar](../../CardSurfaces/calendar.md) and [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityCalendarSurfaceApi` / `CommunityEventRsvpApi` | named meeting detail, recurrence/reminder, going/maybe/not-going, change/cancel RSVP, capacity/attendee state | Demo renderer must show meeting title/date/location/link, reminder, RSVP result, and change path. |
| `book-reading-material` | [documents](../../CardSurfaces/documents.md) and [external-document-link](../../CardSurfaces/external-document-link.md) | `CommunityDocumentSurfaceApi` / `CommunityExternalDocumentApi` | list/open/download/acknowledge/request access, embedded browser open, external app launch, version/audit trail | Demo renderer must show reading material title/source/version, embedded/external open choices, acknowledgement/access state, and reading-cycle context. |
| `book-shared-library-item` | [equipment-loan](../../CardSurfaces/equipment-loan.md) | `CommunityEquipmentLoanApi` | browse/search items, list/edit/pause/delist personal item, request/reserve/approve, join/leave/advance queue, show current holder/custody history, claim giveaway, pickup/return or transfer | Demo renderer must show item title/format, owner/current holder or privacy-safe hold state, queue/due date, condition, loan/giveaway mode, borrower/claim state, and return/transfer state. |
| `book-discussion-message` | [thread](../../CardSurfaces/discussion-message.md) | `CommunityThreadApi` | reply/edit/delete, read/unread, moderate/mute/archive, attachments/mentions | Demo renderer must select a domain-native surface for `thread` and LocalInAppBackend must expose/import the state for these interactions. |
| `book-selection-publish` | [announcement](../../CardSurfaces/announcement-publish.md) | `CommunityAnnouncementApi` | draft/edit/preview, schedule/publish/cancel, delivery/read receipts/revisions | Demo renderer must select a domain-native surface for `announcement` and LocalInAppBackend must expose/import the state for these interactions. |
| `book-search-ai-digest` | [knowledge](../../CardSurfaces/search-ai-digest.md) | `CommunityKnowledgeSurfaceApi` | query/citations, save/share digest, source visibility, stale citation handling | Demo renderer must select a domain-native surface for `knowledge` and LocalInAppBackend must expose/import the state for these interactions. |
| `book-export-metadata` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| Skill-authoring judge pass 1 (2026-08-10) | no | yes | None. | Fixed an isTerminal contract violation (`book-export-metadata`'s `cancelled` state had a real retry transition leaving it) and replaced `book-vote-response`'s inert `scope:"instance"` create action (not yet App-Shell-implemented) with a real, working `scope:"tab"` create action, also fixing a dependent `role:"actor"` correctness issue. This session's first real use of the Hard Rule 11 requirement traceability table — it caught most gaps honestly but missed the isTerminal self-contradiction and didn't flag that the "Cast a vote" fix rested on a not-yet-implemented engine surface. | fixed |
| B25 pass 17 | yes | yes | Tightened Book Club nomination, vote, RSVP, discussion, and selection publish surfaces with title/author/rationale, ballot state, concrete meeting details, thread copy, sender, audience, and delivery timing. | Render Book Club-specific tiles/action surfaces and recapture full B25 evidence. | in progress |
