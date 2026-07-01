# Garden Club Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Garden Club |
| Community type | Neighborhood garden club |
| Product promise | Help members RSVP to garden events, share plants, coordinate care/volunteer work, and export club records. |
| Brand cues | Green palette, garden/leaf iconography, seasonal event language, warm practical tone. |
| What this must not feel like | A generic workflow list with event and form labels. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Member | RSVP, submit plant exchange, view exports read-only | Find current garden activities and act quickly. | Contact details and private requests should not be overexposed. | RSVP/submission status is visible with next steps. |
| Coordinator | Organizes events and exports records | Confirm attendance and keep club data portable. | Export evidence needs checksum/redaction context. | Event participation and exports are auditable. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Garden home | Current garden activity. | Member | upcoming event, plant exchange, care/volunteer section, data/export section. | RSVP / submit entry |
| Garden calendar | RSVP to workshops and discover seasonal work days. | Member | title, date, place, capacity, recurrence/reminder, attendance state. | RSVP / add reminder |
| Plant exchange form | Share plant offer/request. | Member | labeled fields, privacy, reviewer handoff. | Submit entry |
| Tool and giveaway marketplace | Discover, list, borrow, queue for, track, or give away shared garden items. | Member | item, loan/giveaway mode, owner/current holder, queue, pickup window, availability, borrower/claim state. | Browse / list / claim |
| Export evidence | Review portability state. | Coordinator | redacted copy, checksum, exportable data. | Review export |

## 3.1 Persona Tabs, Pins, And Customization

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| Member | Home, Calendar, Marketplace, Care, Messages | Spring workshop, available plant/tool exchange items | Green seasonal palette, plant/event iconography, readable item and event labels. |
| Coordinator | Home, Calendar, Marketplace, Documents, Organize, Messages | attendee count, exchange review queue, export package | Coordinator tabs may expose reviewer/export surfaces hidden from members. |

## 4. Home Screen Requirements

The home must prioritize garden activity, not workflow categories. It should show what is happening
this week, what help or exchange is needed, and what records are available.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Calendar/Event RSVP | event title, date, location, capacity, recurrence/reminder, member state | open/RSVPed/full/cancelled | RSVP, change RSVP, add reminder | checklist modal |
| Plant exchange | item/request, notes, privacy, review state | draft/submitted/reviewed | submit, edit | generic form workflow card |
| Tool/giveaway marketplace | tool/item, availability, owner, current holder, queue, loan/giveaway mode, pickup/return or transfer state | available/queued/reserved/loaned/overdue/given/returned/lost | browse, list item, edit/delist, join queue, request loan, claim giveaway, return, report issue | single generic request |
| Export | data scope, redaction, checksum | ready/exported/error | export, verify | abstract export chip |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| garden-event-rsvp | member | Garden calendar event detail | date/location/capacity, recurrence/reminder, RSVP result and change path | Calendar/events, notifications, audit | B13/B25 |
| plant-exchange-submission | member | Plant exchange form | labeled details, privacy, reviewer state | Forms, vault/consent, events | B13/B25 |
| garden-tool-loan-giveaway | member | Tool and giveaway marketplace | browse available tools/items, list/edit/delist a tool, choose loan or giveaway, queue/current-holder state, pickup/return or ownership transfer state | Shared item marketplace/loan/giveaway, notifications, audit | B25 |
| garden-export-custom-schemas | owner | Export package review | selected garden_event and plant_exchange schemas, redaction preview, checksum, destination, change-scope path, download/export status | Export, documents, audit | B13/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| garden-event-rsvp | member chooses going/maybe/not attending for the Spring Workshop | coordinator sees attendee count and waitlist | non-attendee can view event date/location/capacity | RSVP disabled when full or closed | non-members cannot RSVP and see public event summary only |
| plant-exchange-submission | member submits plant offer/request with variety and pickup window | coordinator reviews public summary and protected contact handoff | other members see availability and safe pickup details | submit disabled if labeled fields or privacy check are missing | private contact details hidden until approved handoff |
| garden-tool-loan-giveaway | member lists, edits, delists, loans, queues for, borrows, or gives away a garden tool/item | owner/coordinator sees borrower, queue, current-holder/custody, claimant, pickup/return, condition, and due state | members can browse availability, queue position, current-holder privacy-safe state, and item condition | loan disabled when unavailable; queue shown when waitlisted; giveaway claim disabled after transfer | private owner/current-holder contact remains protected until approved handoff |
| garden-export-custom-schemas | owner selects garden_event and plant_exchange schemas for export | provider/import reviewer sees checksum and redaction status | members see export status without protected fields | export disabled until redaction preview and checksum pass | non-owners cannot generate or transfer the export |

## 8. Content And Seed Data Requirements

Use real event names, dates, capacity, plant names, privacy labels, reviewer names, redaction/checksum
values, tool/item names, pickup windows, loan/giveaway mode, and before/after RSVP/submission states.

## 9. Visual And Interaction Standard

Use garden-specific hierarchy, seasonal accents, readable event/detail surfaces, and form sections with
clear labels. Avoid repeated same-shape cards as the whole experience.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| garden-event-rsvp | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| plant-exchange-submission | member | Member evaluates a concrete plant exchange item with owner, pickup details, availability, and claim/cancel paths. | claim plant, request plant, offer plant, reserve plant | cancel claim, edit offer, mark claimed, mark unavailable | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| garden-tool-loan-giveaway | member | Member browses available garden tools/items, chooses loan or giveaway, sees current holder/queue, reviews owner/pickup/return or transfer terms, and can list/edit/delist their own item. | browse items, list item, request loan, join waitlist, claim giveaway, schedule pickup | leave queue, cancel loan, edit listing, pause/delist listing, mark damaged/lost, return item | Fresh screenshots must show browse/list views, loan/giveaway mode, owner/current-holder privacy, queue position, custody/condition state, borrower/claim state, pickup/return or ownership-transfer result. |
| garden-export-custom-schemas | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `garden-event-rsvp` | [calendar](../../CardSurfaces/calendar.md) and [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityCalendarSurfaceApi` / `CommunityEventRsvpApi` | named event detail, recurrence/reminder, going/maybe/not-going, change/cancel RSVP, capacity/attendee state | Demo renderer must show a garden calendar/event surface with date/location/capacity, reminder, RSVP result, and change path. |
| `plant-exchange-submission` | [exchange](../../CardSurfaces/plant-exchange.md) | `CommunityExchangeApi` | offer/request, claim/cancel claim, pickup coordination, privacy-safe contact | Demo renderer must select a domain-native surface for `exchange` and LocalInAppBackend must expose/import the state for these interactions. |
| `garden-tool-loan-giveaway` | [equipment-loan](../../CardSurfaces/equipment-loan.md) | `CommunityEquipmentLoanApi` | browse/search tools, list/edit/pause/delist personal tool, choose loan vs giveaway, request/reserve/approve, join/leave/advance queue, show current holder/custody history, claim giveaway, pickup/return or transfer | Demo renderer must show available item browsing, owner/listing details, current holder or privacy-safe hold state, queue position, loan/giveaway mode, borrower/claim state, pickup/return, condition, and transfer state. |
| `garden-export-custom-schemas` | [portability](../../CardSurfaces/export-import-transfer.md) | `CommunityPortabilitySurfaceApi` | scope/redaction preview, generate/download/checksum, transfer/rollback, audit trail | Demo renderer must select a domain-native surface for `portability` and LocalInAppBackend must expose/import the state for these interactions. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| B25 pass 17 | yes | yes | Tightened Garden export from generic evidence to a package-review surface with scope, redaction, checksum, destination, rollback/change-scope, and download status. | Render export review tile/action surface and recapture full B25 evidence. | in progress |
