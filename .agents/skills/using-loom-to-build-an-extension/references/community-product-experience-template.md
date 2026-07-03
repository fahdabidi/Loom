# Community Product Experience Template

Use this template before building or remediating a Loom Communities extension. It defines the product
experience the UI must implement. Workflows and APIs are implementation details under this product
surface contract; they are not the product experience by themselves.

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | `<name>` |
| Community type | `<book-club / mosque / HOA / soccer / etc.>` |
| Product promise | `<what this community app helps members/admins do better>` |
| Brand cues | `<logo, icon, imagery, color, tone, language>` |
| What this must not feel like | `<generic workflow list, metadata page, test harness, etc.>` |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| `<persona>` | `<role>` | `<jobs>` | `<privacy/payment/role constraints>` | `<what success looks like>` |

## 3. Information Architecture

Define the community's real product structure, not workflow categories.

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Home | `<what the home prioritizes>` | `<persona>` | `<current activity, alerts, sections>` | `<main next action>` |
| `<domain surface>` | `<purpose>` | `<persona>` | `<content>` | `<action>` |

## 3.1 Persona Tabs, Pins, And Customization

Define the App Shell navigation model and customization knobs. Home and Messages/Communication are
always required, but every persona can receive different tabs, pinned surfaces, labels, icons, order,
and hidden/disabled states.

| Persona | Required tabs | Pinned surfaces | Customization notes |
| --- | --- | --- | --- |
| `<persona>` | `Home, <domain tab>, Messages` | `<surface or workflow>` | `<theme, typography, density, icon, color, card, tab, or surface presentation choices>` |

## 4. Home Screen Requirements

The first screen after opening the community must show:

- recognizable community identity and useful status
- domain-native sections for current content and jobs-to-be-done
- role/persona-specific next actions
- required App Shell access to Messages and Connections
- no global workflow list, test taxonomy, metadata-only screen, or implementation rationale

## 5. Domain-Native Product Surfaces

For each product surface, define what a real user must see.

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Announcement/feed | audience, sender/author, body, timing, channel, read/receiver state | draft/scheduled/sent/read | publish, send, read, search | generic "publish workflow" card |
| Event/RSVP | title, date, time, location, capacity/attendance, attendee state | open/full/cancelled/RSVPed | RSVP, change, cancel | checklist modal |
| Payment/donation/dues | amount, payer context, fund/purpose, privacy choice, receipt, status | pending/paid/failed/refunded | pay, donate, retry, view receipt | abstract payment chip |
| Protected form/care request | public summary, private fields, recipient role, privacy indicator, status | draft/submitted/assigned/closed | submit, update, receive | exposing sensitive details broadly |
| Admin review | requester, submitted data, decision options, comments, audit state | pending/approved/denied | approve, reject, comment | unlabeled approval task |
| Search/AI/export | scope, source/citation/checksum/redaction/result | loading/result/error/rollback | search, export, verify, rollback | technical export-only row |

Add more rows for the community type.

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| `<workflow-id>` | `<persona>` | `<surface>` | `<visible proof>` | `<APIs/events/rules>` | `<tests/screenshots>` |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| `<workflow-id>` | `<actor UI>` | `<receiver UI>` | `<read-only UI>` | `<disabled/hidden UI>` | `<denial/hide rationale>` |

## 8. Content And Seed Data Requirements

List the realistic seed data needed so screenshots can prove a production product surface.

- names, roles, audiences, times, locations, amounts, messages, receipts, attachments, privacy labels
- realistic empty/loading/error/success states
- before/after records for multi-persona handoffs

## 9. Visual And Interaction Standard

Define how this community should feel visually:

- layout density and hierarchy
- card/list/feed/detail/form usage
- iconography and imagery expectations
- typography and spacing expectations
- mobile navigation and action placement
- accessibility and readability constraints

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| `<run-id>` | `<yes/no>` | `<yes/no>` | `<summary>` | `<summary>` | `<open/closed>` |

When a UX review finds that this document lacks the detail needed to judge a screen, update this
product doc first. Then update the UI, recapture evidence, and rerun the judge.
