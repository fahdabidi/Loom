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
| arbitrary-package-open | organizer | Installed card/open route | parsed Chess Club identity | Local backend/App Shell | B9/B25 |
| chess-club-home | player | Chess home | chess content and action | Runtime bridge | B9/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| package open | organizer opens | player sees same home | card identity readable | invalid package blocked | invalid files not installed |

## 8. Content And Seed Data Requirements

Use club name, chess icon/identity, match/night copy, and at least one realistic club action.

## 9. Visual And Interaction Standard

The arbitrary example should be simple but product-like: recognizable chess identity, no raw package
debug labels, and no generic workflow proof screen.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Chess Club product experience. | Judge current arbitrary-package screenshots against product-home bar. | open |
