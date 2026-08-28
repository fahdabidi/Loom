# Chess Club Product Experience

> **Correction, 2026-08-10 (Community JSON Migration effort, `docs/Build Plan V2/Community JSON Migration
> Tracker.md` §3):** every row below naming `chess-local-install-open` or `chess-route-home` describes a
> generic "package installed / home route opened" concept that was **never actually implemented as a real
> workflow** — confirmed by direct source read: no `LoomWorkflowDefinition` anywhere in the codebase (not
> Chess Club's own JSON, not any other community's) is ever constructed with either id; the two `case`
> branches referencing them (`_displayTitleFor` in `part08_garden_and_helpers.dart:582`, `_chessPolicy` in
> `part15_evidence_catalog.dart:1658-1659`) are unreachable dead code. **Do not author engine-native JSON for
> either of these** — there is no behavior to migrate. Left in place below per this tracker's standing
> "expand-only, never remove" rule, but should be read as historical/aspirational, not a real workflow
> requirement. Chess Club's real, implemented workflow count is **8**: the 2 this doc already covers below
> (`chess-match-meetup`, `chess-match-result`) plus 6 more this doc never documented at all
> (`chess-club-night`, `chess-discussion-thread`, `chess-export-package`, `chess-pairing-queue`,
> `chess-rankings-table`, `chess-rules-documents` — all confirmed real, with real `states`/`transitions`, in
> `part02_tab_shell.dart:10840-11823`). Add these 6 as real workflow rows to every table below before this
> doc is used as an authoring source, following the existing row format exactly.
>
> **Two real bugs found in the current implementation, confirmed by direct source read — do not carry
> either forward when authoring JSON (do not fix the Dart source as part of this note, just don't repeat the
> mistake in the new JSON):**
> - `chess-export-package`'s `generate-export` effect hardcodes `"checksum": "sha256-chess-2026"`
>   (`part02_tab_shell.dart:11547-11550`) — a fabricated, non-computed value. Checksum/hash generation is a
>   `❌ Not implemented` platform service per `docs/references/reference/platform-services.md` — this is the
>   same AP-6 violation already found and fixed in Cedar Commons HOA's `hoa-export-evidence` workflow. Do not
>   fabricate a checksum field in the new JSON.
> - `chess-match-result`'s `submit-result`/`correct-result` transitions (`part02_tab_shell.dart:11130-11168`)
>   set a `rankingRows` field to a hardcoded literal string (`"Maya Patel:1496:+16"`), disconnected from the
>   actually-submitted score and never actually written to `chess-rankings-table`. Do not carry this fake
>   ranking-delta value forward.
>
> **Two more structural gaps, confirmed by direct source read of the same 6 workflows
> (`part02_tab_shell.dart:11362-11823`), to resolve at JSON-authoring time, not silently carried forward:**
> **BOTH GAPS BELOW WERE RESOLVED BY LATER PLATFORM WORK. Corrected 2026-08-27 — the original text
> is kept struck through because it was accurate when written and the reasoning still explains why the
> legacy bindings looked wrong.**
>
> - ~~The legacy implementation binds these workflows to `tabId` values that do not exist in the real,
>   closed enum — `"matches"`, `"rankings"`, `"documents"` are not real tabs and must be remapped onto
>   `home`.~~ **No longer true.** `tabId` is explicitly **not** a closed enum
>   (`docs/references/reference/render-bindings.md` line 450: "Exactly two ids are structural" — `home`
>   and `messages`); every other id is declared by the community in `appShell.tabs[]`. Six shipping
>   communities already use nine ids outside the old list — Book Club `books`/`discussions`, Garden
>   `care`/`organize`, Camera `critique`, Cedar `requests`, Mosque `resources`, Youth Soccer `team`, and
>   `documents` in four of them. So `matches`, `rankings` and `documents` are correct declared tabs for
>   Chess, and §3.1's persona tab lists are authoritative. Remapping them onto `home` would now be the
>   error.
> - ~~The legacy implementation also uses `cardSurfaceFamily` values that are not among the 9 real
>   archetypes — `"table"`, `"exportWizard"`, `"documentLibrary"` are fabricated, never-implemented
>   families.~~ **No longer true for three of the five.** `table`, `documentLibrary`, `searchAiAnswer`
>   and `exportWizard` were promoted on 2026-08-11 and are real, registered and validator-enforced
>   (`docs/references/archetypes/README.md`: 13 archetypes, not 9). `chess-export-package` correctly
>   uses `exportWizard`, which is backed by a real export-bundle and checksum service as of 2026-08-27.
>   `"dashboard"` and `"calendarAgenda"` remain fabricated — pick real replacements for those two per the
>   row notes below.
>
> **Why this correction exists.** A regeneration on 2026-08-27 declared `matches`, `rankings` and
> `documents` as tabs, which read as scope creep against this note and was very nearly rejected as
> such. The note was the thing that was wrong. A product doc that carries a stale platform constraint
> does not merely fail to help — it argues against the correct answer, and it argues from authority.

Chess Club's real, implemented workflow count is **8**. The 2 this doc already covered before this
correction (`chess-match-meetup`, `chess-match-result`) are documented in the tables below; the 6 more this
doc never documented at all follow immediately after them in every table (`chess-club-night`,
`chess-discussion-thread`, `chess-export-package`, `chess-pairing-queue`, `chess-rankings-table`,
`chess-rules-documents`).

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Chess Club |
| Community type | Arbitrary local package example |
| Product promise | Prove an arbitrary generated package can open into a recognizable club home with meaningful activities. |
| Brand cues | Chess-piece iconography, match/night language, compact club-home layout. |
| What this must not feel like | Proof-only arbitrary package metadata. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Owner | Sets up the community and owns export custody. | Confirm the community is configured and generate, download, roll back, retry, or cancel club-data exports. | Admission authority is App Access-only and must never be encoded as a workflow, permission, user, or membership in package JSON. | The owner can manage export scope and lifecycle without fabricated checksum data. |
| Organizer | Runs club operations. | Schedule club nights, send reminders, resolve result disputes, assign pairings, publish rankings, and maintain rules. | Operational authority does not include package-authored membership admission. | Club nights, pairings, standings, disputes, and rules remain current and visible to players. |
| Player | Participates in chess activity. | Schedule matches, respond to opponents, record/correct/dispute results, RSVP, discuss games, and read rules. | Private match and discussion data remains member-only; public standings remain readable. | The player sees concrete club activity and can complete or reverse every supported interaction. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Chess home | Demonstrate arbitrary package rendering. | Organizer/player | club name, chess identity, match/event summary, member action. | Open home / join activity |
| Match meetup scheduler | Let members schedule ladder games or casual matches. | Player | opponent, proposed time/place/board, response state, calendar reminder. | Propose match / accept |
| Match calendar | Show club nights, tournaments, and scheduled member matches. | Player/organizer | event title, date/time, location, opponent/pairing, reminder state. | RSVP / add reminder |
| Club night reminder | Notify players of a scheduled club night. | Organizer | event title, time, location, pairing note, reminder-sent state. | Send reminder |
| Pairing queue | Assign board pairings from a waiting list. | Organizer | queue title, waiting players, assignment history. | Assign pairing |
| Rankings table | Show current ladder standings. | Player/organizer | rank, player, score, delta, last-updated. | Publish rankings |
| Rules documents | Read, open externally, or download club rules. | Player/organizer | document title, embedded/external open choice, download state. | Open rules |
| Export package | Export club match/ranking data. | Owner | export scope, checksum gap, status, download history, rollback/retry/cancel paths | Generate export / download / rollback |
| Club discussion | Member conversation about matches and club nights. | Player | thread title, message history, archive state. | Reply |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Player | Home, Matches, Calendar, Rankings, Messages | next match, open challenge, latest result | Board/tournament visual language, rank/status clarity, quick match reporting. |
| Organizer | Home, Matches, Calendar, Admin, Documents, Messages | pairing queue, result disputes, export package | Organizer tabs expose schedule, dispute, and export controls. |

## 4. Home Screen Requirements

The home must prove arbitrary package data drives visible identity and content, not a hardcoded fixture
or metadata-only route.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Club home | chess identity, match/event context, member action | loaded/opened | open, join, view | package proof card only |
| Match meetup | opponent, proposed slot, location/board, accept/decline, reschedule | proposed/accepted/declined/rescheduled/completed | propose, accept, decline, reschedule, record result | generic request without opponent/time |
| Calendar | club night/tournament/match, date/time/location, reminder | upcoming/RSVPed/cancelled | RSVP, add reminder, open match | raw event row |
| Club night | event title, time, location, pairing note, reminder status | scheduled/reminded | send reminder | raw event row without reminder state |
| Pairing queue | queue title, waiting players, assignment history | open/assigned | assign pairing | single request without queue context |
| Rankings table | rank, player, score, delta, last-updated | current | publish rankings | flat numeric list with no rank/delta context |
| Rules documents | document title, open history | available/embedded-opened/external-opened/downloaded | open embedded, open external, download | raw external URL only |
| Export package | export scope, checksum, status | ready/generated/rolled back | generate export, rollback | fabricated checksum |
| Club discussion | thread title, messages, archive state | open/replied/archived | reply, archive | generic message workflow |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | member | Installed card/open route | parsed Chess Club identity, card, local route, and open state | Local backend/App Shell | B9/B25 |
| chess-route-home | member | Chess home | chess content, route state, next match or result action | Runtime bridge | B9/B25 |
| chess-match-meetup | member | Match meetup scheduler | opponent, proposed time/place/board, accept/decline/reschedule state | Member meetup/calendar/events | B25 |
| chess-match-result | member | Match result surface | players, round, result, next action, correction path | Runtime bridge/events | B9/B25 |
| chess-club-night | organizer | Club night reminder | event title/time/location/pairing, reminder-sent state | Calendar/notifications | B25 |
| chess-discussion-thread | member | Club discussion thread | thread title, message history, archive state | Messaging/events | B25 |
| `chess-export-package` | owner | Export package review | export scope, checksum gap, status, download history, rollback/retry/cancel paths | Export/audit state machine; checksum generation remains a platform-service gap | B25 |
| `chess-pairing-queue` | organizer | Pairing queue | ordered waiting players, queue length, assignment history, close path | Roster/assignment/audit | B25 |
| `chess-rankings-table` | organizer | Rankings table | rank, player, score, delta, evidence, last-updated, revise/retire paths | Standings/events | B25 |
| chess-rules-documents | member | Rules documents | document title, embedded/external open choice, download state | Documents/external documents/audit | B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | tester installs local Chess Club package and opens the community card | member sees branded chess home after install | installed card identity and route are readable | invalid package pair blocked with error | invalid files are not installed |
| chess-route-home | member opens the local chess route/home | player sees tonight ladder, pairings, and standings | non-active player can read public club home | action disabled when no match is scheduled | non-members see public club summary only |
| chess-match-meetup | member proposes or accepts a match with opponent/time/place | opponent receives invite and response state | club members can see accepted public match slot where policy allows | accept disabled after expiry or conflict | non-members cannot schedule private member matches |
| chess-match-result | member records match result with players, round, score, and correction path | opponent/standings view receives updated result | members can read saved result and standings impact | save disabled without opponent/score/result | non-members cannot record match result |
| chess-club-night | organizer schedules club night and sends a reminder | players receive reminder notification | non-actor players can read event title/time/location | reminder disabled once already sent | non-members cannot see private club-night details |
| chess-discussion-thread | player or organizer posts/replies in club discussion | members see message history and archive state | organizer can archive/moderate thread | reply disabled once archived | non-members cannot post or read private discussion |
| `chess-export-package` | owner creates an export, changes its scope, generates it, downloads it, rolls it back, retries it, or cancels it | players may read the guarded status summary while the owner retains export controls | players see export status without protected platform-generated values | rollback and download are unavailable until generated; retry is available after rollback | non-owners cannot create, configure, generate, download, roll back, retry, or cancel exports; membership admission is not a workflow |
| `chess-pairing-queue` | organizer assigns a board pairing from the ordered waiting queue | waiting players see their order and assignment history | members can read the open queue and current waiting list | assign is disabled until at least two waiting names exist | non-organizers cannot assign pairings or close the queue |
| `chess-rankings-table` | organizer publishes an evidence-backed ladder row | players see rank, score, delta, evidence, and last update | non-members can read public current standings | publish is disabled until a real rank change is confirmed | non-organizers cannot publish, revise, or retire ranking rows |
| chess-rules-documents | member opens or downloads club rules | organizer can see which materials were opened, if tracked | source/version readable by all members | download disabled while offline (not modeled) | non-members cannot open private club-only rules variants |

## 8. Content And Seed Data Requirements

Use club name, chess icon/identity, match/night copy, opponent names, proposed match slots, board/table
labels, and at least one realistic club action.

## 9. Visual And Interaction Standard

The arbitrary example should be simple but product-like: recognizable chess identity, no raw package
debug labels, and no generic workflow proof screen.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-route-home | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-match-meetup | member | Member schedules a match with a concrete opponent after seeing available times, location/board, response state, and reschedule path. | propose meetup, accept match, add reminder | decline, reschedule, cancel meetup, suggest new time | Fresh screenshots must show opponent, time/location/board, invite/response state, calendar/reminder, and reschedule/cancel path. |
| chess-match-result | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-club-night | organizer | Organizer schedules a concrete club night and reminds players; a player who can no longer attend withdraws, and the organizer can call the whole night off. | rsvp, add reminder, send reminder | withdraw rsvp, cancel club night | Fresh screenshots must show event details, reminder-sent state, the withdrawn-RSVP state, and the cancelled-night state players receive. |
| chess-discussion-thread | member | Member evaluates a concrete discussion thread with sender/message context and reply/archive paths. | reply, send message | archive, mute | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-export-package | owner | Owner selects a concrete export scope and decides whether to generate and download the package. | generate export, download export | change scope, rollback, generate again, cancel export | Fresh screenshots must show selected scope, generated/downloaded status or rollback/cancel status, and that checksum remains pending rather than fabricated. |
| chess-pairing-queue | organizer | Organizer reviews an ordered waiting list, assigns a concrete board pairing, and decides when to close the queue. | assign pairing | close queue | Fresh screenshots must show queue order, assignment history, the assigned state, the closed-queue state, and the waiting-player receiver view. |
| chess-rankings-table | organizer | Organizer reviews evidence for a real ladder change and decides whether to publish it. | publish rankings | revise ranking, retire ranking row | Fresh screenshots must show rank, player, score, delta, evidence, last-updated state, and the revised or retired row players then see. |
| chess-rules-documents | member | Member opens a concrete rules document, chooses embedded or external, downloads it, and the organizer archives a superseded version. | open document, download | launch external, archive document | Fresh screenshots must show title, open history, download state, and the archived-document state. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `chess-local-install-open` | [custom-form-submission](../../CardSurfaces/custom-form-submission.md) | `CommunityFormSurfaceApi` | local package import/open, route state, installed card status | Demo renderer must show parsed Chess Club identity, local route, installed card, and open state. |
| `chess-route-home` | [calendar](../../CardSurfaces/calendar.md) | `CommunityCalendarSurfaceApi` | scheduled match/session, club night/tournament, player context, route/open state, reminder | Demo renderer must show chess home, next match/session, players, date/time/location, and primary action. |
| `chess-match-meetup` | [member-meetup](../../CardSurfaces/member-meetup-scheduling.md) and [calendar](../../CardSurfaces/calendar.md) | `CommunityMeetupApi` / `CommunityCalendarSurfaceApi` | propose/accept/decline/reschedule/cancel, availability, reminder, receiver state | Demo renderer must show opponent, proposed slot/location/board, invite response, reschedule/cancel, and calendar state. |
| `chess-match-result` | [approval-request](../../CardSurfaces/approval-request.md) | `CommunityRequestSurfaceApi` | submit/edit result, status, correction path, notification | Demo renderer must show players, round, outcome, correction path, and next action. |
| `chess-club-night` | *(none real — legacy uses `calendarAgenda`, not a real archetype)* | — | send reminder, event detail | Pick a real archetype at authoring time — closest fit is `statusTimeline` (scheduled → reminded is a simple timestamped progression). |
| `chess-discussion-thread` | [thread](../../CardSurfaces/discussion-message.md) *(stale registry — real fit is `discussionThread`, one of the 13 real archetypes (9 original + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`, promoted 2026-08-11))* | `CommunityThreadApi` | reply, archive, read/unread | `discussionThread` is real and already correctly used by the legacy implementation's `tabId: "messages"` binding — keep using it. |
| `chess-export-package` | *(none real — legacy uses `exportWizard`, not a real archetype)* | — | generate export, rollback, scope/status | Pick a real archetype at authoring time — closest fit is `formEntry` or `statusTimeline` (ready → generated → rolled back). Never fabricate `checksum` — see the correction note at the top of this doc. |
| `chess-pairing-queue` | *(none real — legacy uses `dashboard`, not a real archetype)* | — | assign pairing, waiting list | Pick a real archetype at authoring time — closest fit is `approvalQueueItem` ("a live queue of items awaiting decision" — matches exactly). |
| `chess-rankings-table` | [table](../../archetypes/table.md) *(promoted to a real archetype 2026-08-11; `rankingMode` is not real)* | — | publish rankings, rank/score/delta | None of the 13 real archetypes (9 original + `table`/`documentLibrary`/`searchAiAnswer`/`exportWizard`, promoted 2026-08-11) natively models a sortable leaderboard. Report this as an honest gap at authoring time (AP-11) rather than force-fitting — closest approximation is `statusTimeline` for the publish/last-updated state, with rank rows carried as plain list data. |
| `chess-rules-documents` | *(none real — legacy uses `documentLibrary`, not a real archetype)* | — | open embedded, open external, download | Pick a real archetype at authoring time — closest fit is `statusTimeline` (available → embedded-opened → external-opened → downloaded), using the `type: "url"` field grammar (CJM.2) for the external-open link. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| Skill-authoring judge pass 1 (2026-08-10) | no | yes | None. | `chess-pairing-queue` silently dropped "waiting players see queue position" (§7/§9) — the first authoring attempt modeled each waiting player as a separate instance, making position uncomputable, then justified the drop with a false claim that Player has no admin-tab access. Fixed by redesigning to one shared queue-container instance with an ordered `waitingPlayerNames` list, where each player's list index is their real, visible queue position. | fixed |
