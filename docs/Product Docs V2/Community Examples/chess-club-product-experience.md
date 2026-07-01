# Chess Club Product Experience

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

## 4. Home Screen Requirements

The home must prove arbitrary package data drives visible identity and content, not a hardcoded fixture
or metadata-only route.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Club home | chess identity, match/event context, member action | loaded/opened | open, join, view | package proof card only |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | member | Installed card/open route | parsed Chess Club identity, card, local route, and open state | Local backend/App Shell | B9/B25 |
| chess-route-home | member | Chess home | chess content, route state, next match or result action | Runtime bridge | B9/B25 |
| chess-match-result | member | Match result surface | players, round, result, next action, correction path | Runtime bridge/events | B9/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| package open | organizer opens | player sees same home | card identity readable | invalid package blocked | invalid files not installed |

## 8. Content And Seed Data Requirements

Use club name, chess icon/identity, match/night copy, and at least one realistic club action.

## 9. Visual And Interaction Standard

The arbitrary example should be simple but product-like: recognizable chess identity, no raw package
debug labels, and no generic workflow proof screen.

### B25 Semantic Interaction Models

This B25 addendum defines the production interaction model the UI must prove from fresh after-screenshot evidence. A workflow cannot pass with only a happy-path action; it must show the expected decision, required primary action, alternate/change/reject path, durable result state, and receiver or continuation state.

| Workflow | Persona | Expected decision | Required primary actions | Required alternate/change/reject actions | Result and receiver state |
| --- | --- | --- | --- | --- | --- |
| chess-local-install-open | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-route-home | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |
| chess-match-result | member | Participant records or reviews a concrete match with opponent, score/result, and correction/dispute paths. | record match, submit score, save result | edit score, undo result, correct result, dispute result | Fresh screenshots must show status, receipt/history/confirmation, and any receiver or continuation state for this persona. |


### B25 Card Surface Registry Mapping

This B25 advisory registry maps each documented community workflow to the canonical card surface family, OpenAPI contract, required interactions/actions, and Demo App renderer/fake-backend support expected by remediation. It is used as implementation context only; B25 does not yet enforce this as a standalone card-surface/API coverage gate.

| Workflow | Card surface family | API contract | Required interactions/actions | Renderer/fake-backend support |
| --- | --- | --- | --- | --- |
| `chess-local-install-open` | [custom-form-submission](../../CardSurfaces/custom-form-submission.md) | `CommunityFormSurfaceApi` | local package import/open, route state, installed card status | Demo renderer must show parsed Chess Club identity, local route, installed card, and open state. |
| `chess-route-home` | [event-rsvp](../../CardSurfaces/event-rsvp.md) | `CommunityEventRsvpApi` | scheduled match/session, player context, route/open state | Demo renderer must show chess home, next match/session, players, and primary action. |
| `chess-match-result` | [approval-request](../../CardSurfaces/approval-request.md) | `CommunityRequestSurfaceApi` | submit/edit result, status, correction path, notification | Demo renderer must show players, round, outcome, correction path, and next action. |

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Added semantic interaction model addendum. | Use documented primary and alternate actions in the UI, then recapture screenshots. | open |
