# Camera Club Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Camera Club |
| Community type | Prompt-generated arbitrary extension example |
| Product promise | Prove a Skill-created arbitrary community can capture workflows, generate packages, install locally, and render real photo-club surfaces. |
| Brand cues | Camera/photo-walk/critique imagery, visual portfolio tone, event and submission cues. |
| What this must not feel like | A validation report route or generated-artifact checklist. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Organizer | Runs prompt-build validation | Confirm generated workflows and packages are complete. | Package generation must not skip requested workflows. | Validation report is complete and community opens. |
| Member | Uses photo club surfaces | See photo walk, critique, and announcement tasks. | Photo submissions may need consent/context. | Member sees photo-specific next actions. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Camera home | Generated club experience. | Member | photo walk, critique submission, announcements, validation status. | RSVP / submit critique |
| Validation report | Prove Skill completion. | Organizer | requested workflows, implemented/validated statuses. | Review completion |

## 4. Home Screen Requirements

The home must make the generated community feel like a photo club, not just a demonstration of prompt
parsing.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Photo walk | title, date, location, attendance | open/RSVPed | RSVP, view details | generic event workflow |
| Critique submission | photo/topic, notes, review state | draft/submitted/reviewed | submit critique | generated checklist |
| Completion report | workflow list, pass state, package paths | pending/complete | review | hidden failed workflow |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| skill-prompt-build-validate-complete | organizer | Validation report and installed community | complete=true plus local open | Skill harness/local backend/App Shell | B11/B25 |
| camera-photo-walk | member | Photo walk | date/location/action | Events | B15/B25 |
| camera-critique-submission | member | Critique form | submission/review state | Forms/events | B15/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| prompt build | organizer validates | member opens generated home | validation report read-only after pass | package paths withheld until complete | incomplete report blocks delivery |
| critique | member submits | organizer reviews | member sees status | submit disabled without required fields | non-member hidden |

## 8. Content And Seed Data Requirements

Use photo walk titles, locations, critique prompts, submitted photo context, organizer/member names,
and validation statuses for every requested prompt workflow.

## 9. Visual And Interaction Standard

Use image/photography cues and clear event/submission surfaces. Avoid generated text that describes the
Skill instead of the photo club task.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| photo-walk-rsvp | member | Member decides attendance for a named dated event with time, location, capacity/status, and a later change path. | rsvp, attend, going, reserve spot, confirm attendance | decline, not attending, maybe, change response, edit response, cancel rsvp | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| critique-submission | member | Participant reviews or submits a concrete critique item with content, author, feedback, and edit/withdraw paths. | submit critique, review critique, comment | edit critique, withdraw critique, request changes, resubmit | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| gear-loan-request | member | Reviewer or requester evaluates a concrete request with requester, details, status, and approve/reject/change paths. | submit request, approve request, send request, review request | reject, request changes, revise, withdraw, edit request | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
