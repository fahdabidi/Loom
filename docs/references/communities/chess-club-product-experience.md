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
| Organizer | Loads package and reviews home | Confirm arbitrary package content renders as a product. | Local package data must remain deterministic. | Chess Club card and home use parsed package identity/content. |
| Player | Opens club home | See match/event context and next action. | No sensitive data expected. | Player sees club activity rather than metadata. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Chess home | Demonstrate arbitrary package rendering. | Organizer/player | club name, chess identity, match/event summary, member action. | Open home / join activity |
| Match meetup scheduler | Let members schedule ladder games or casual matches. | Player | opponent, proposed time/place/board, response state, calendar reminder. | Propose match / accept |
| Match calendar | Show club nights, tournaments, and scheduled member matches. | Player/organizer | event title, date/time, location, opponent/pairing, reminder state. | RSVP / add reminder |

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

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | member | Installed card/open route | parsed Chess Club identity, card, local route, and open state | Local backend/App Shell | B9/B25 |
| chess-route-home | member | Chess home | chess content, route state, next match or result action | Runtime bridge | B9/B25 |
| chess-match-meetup | member | Match meetup scheduler | opponent, proposed time/place/board, accept/decline/reschedule state | Member meetup/calendar/events | B25 |
| chess-match-result | member | Match result surface | players, round, result, next action, correction path | Runtime bridge/events | B9/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | tester installs local Chess Club package and opens the community card | member sees branded chess home after install | installed card identity and route are readable | invalid package pair blocked with error | invalid files are not installed |
| chess-route-home | member opens the local chess route/home | player sees tonight ladder, pairings, and standings | non-active player can read public club home | action disabled when no match is scheduled | non-members see public club summary only |
| chess-match-meetup | member proposes or accepts a match with opponent/time/place | opponent receives invite and response state | club members can see accepted public match slot where policy allows | accept disabled after expiry or conflict | non-members cannot schedule private member matches |
| chess-match-result | member records match result with players, round, score, and correction path | opponent/standings view receives updated result | members can read saved result and standings impact | save disabled without opponent/score/result | non-members cannot record match result |

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


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `chess-local-install-open` | [custom-form-submission](../../CardSurfaces/custom-form-submission.md) | `CommunityFormSurfaceApi` | local package import/open, route state, installed card status | Demo renderer must show parsed Chess Club identity, local route, installed card, and open state. |
| `chess-route-home` | [calendar](../../CardSurfaces/calendar.md) | `CommunityCalendarSurfaceApi` | scheduled match/session, club night/tournament, player context, route/open state, reminder | Demo renderer must show chess home, next match/session, players, date/time/location, and primary action. |
| `chess-match-meetup` | [member-meetup](../../CardSurfaces/member-meetup-scheduling.md) and [calendar](../../CardSurfaces/calendar.md) | `CommunityMeetupApi` / `CommunityCalendarSurfaceApi` | propose/accept/decline/reschedule/cancel, availability, reminder, receiver state | Demo renderer must show opponent, proposed slot/location/board, invite response, reschedule/cancel, and calendar state. |
| `chess-match-result` | [approval-request](../../CardSurfaces/approval-request.md) | `CommunityRequestSurfaceApi` | submit/edit result, status, correction path, notification | Demo renderer must show players, round, outcome, correction path, and next action. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
