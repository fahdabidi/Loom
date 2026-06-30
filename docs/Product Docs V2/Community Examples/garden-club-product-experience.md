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
| Event detail | RSVP to workshop. | Member | title, date, place, capacity, attendance state. | RSVP to event |
| Plant exchange form | Share plant offer/request. | Member | labeled fields, privacy, reviewer handoff. | Submit entry |
| Export evidence | Review portability state. | Coordinator | redacted copy, checksum, exportable data. | Review export |

## 4. Home Screen Requirements

The home must prioritize garden activity, not workflow categories. It should show what is happening
this week, what help or exchange is needed, and what records are available.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Event/RSVP | event title, date, location, capacity, member state | open/RSVPed/full | RSVP, change RSVP | checklist modal |
| Plant exchange | item/request, notes, privacy, review state | draft/submitted/reviewed | submit, edit | generic form workflow card |
| Export | data scope, redaction, checksum | ready/exported/error | export, verify | abstract export chip |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| garden-event-rsvp | member | Event detail | date/location/capacity plus RSVP result | Events, notifications, audit | B13/B25 |
| plant-exchange-submission | member | Plant exchange form | labeled details, privacy, reviewer state | Forms, vault/consent, events | B13/B25 |
| garden-export-custom-schemas | owner | Export package review | selected garden_event and plant_exchange schemas, redaction preview, checksum, destination, change-scope path, download/export status | Export, documents, audit | B13/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| event RSVP | member acts | coordinator sees attendance | non-attendee can view event | RSVP disabled when full | non-members hidden |
| plant exchange | member submits | coordinator reviews | other members see public summary | submit disabled if missing fields | private details hidden |

## 8. Content And Seed Data Requirements

Use real event names, dates, capacity, plant names, privacy labels, reviewer names, redaction/checksum
values, and before/after RSVP/submission states.

## 9. Visual And Interaction Standard

Use garden-specific hierarchy, seasonal accents, readable event/detail surfaces, and form sections with
clear labels. Avoid repeated same-shape cards as the whole experience.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| garden-event-rsvp | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| plant-exchange-submission | member | Member evaluates a concrete plant exchange item with owner, pickup details, availability, and claim/cancel paths. | claim plant, request plant, offer plant, reserve plant | cancel claim, edit offer, mark claimed, mark unavailable | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| garden-export-custom-schemas | owner | Admin selects export/import/transfer scope, reviews redaction/checksum/status, and can cancel, retry, or roll back. | export, download export, start transfer, import data | change scope, cancel transfer, rollback, retry, redaction preview | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
| B25 pass 17 | yes | yes | Tightened Garden export from generic evidence to a package-review surface with scope, redaction, checksum, destination, rollback/change-scope, and download status. | Render export review tile/action surface and recapture full B25 evidence. | in progress |
