# Masjid Nur Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Masjid Nur |
| Community type | Mosque community |
| Product promise | Help admins and members coordinate announcements, events, donations, volunteers, and protected care requests. |
| Brand cues | Respectful mosque/community-care tone, green palette, giving/care/announcement cues. |
| What this must not feel like | A list of publish/receive workflows with generic cards and confirmation checklists. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Masjid Admin | Publish announcements, coordinate events/volunteers, review care | Send trustworthy community updates and manage support. | Care requests and donations need privacy controls. | Update is sent; care/volunteer/donation state is accountable. |
| Community Member | Receive announcements, RSVP, donate, volunteer, request care | Know what is happening and participate safely. | Protected care details should be visible only to approved recipients. | Member sees relevant update, receipt, signup, or care status. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Masjid home | Current community life. | Member/admin | announcements, upcoming events/prayer/community updates, giving, volunteers, care. | Read update / donate / volunteer |
| Announcement compose/feed | Publish and receive updates. | Admin/member | body, sender, audience, timing, delivery/read state. | Publish / read |
| Donation | Give with visibility controls. | Member | amount, fund, privacy, receipt. | Donate |
| Care request | Protected support request. | Member/admin | public summary, private fields, recipient state. | Submit / review |
| Volunteer signup | Coordinate help. | Member/admin | need, shift, capacity, signup state. | Volunteer |

## 4. Home Screen Requirements

The first Masjid screen must feel like a community hub with announcements, events/updates, giving,
volunteer needs, and care. It must not be a global workflow list or generic repeated cards.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Announcement/feed | title/body, sender, audience, timing, channel, read state | draft/sent/read | publish, read | publish workflow card |
| Donation | amount, fund/purpose, privacy, receipt | pending/paid/failed | donate, view receipt | abstract payment chip |
| Care request | public summary, private details, recipient, privacy label | draft/submitted/assigned | submit, review | exposing protected details |
| Volunteer | role, shift, capacity, signup status | open/full/signed-up | volunteer, cancel | generic task card |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| mosque-announcement-publish | admin | Announcement compose/feed | sender, audience, body, timing, sent state | Publishing/notifications/events | B14/B20/B25 |
| mosque-announcement-receive | member | Announcement feed/inbox | body, sender, read/received state | Messaging/notifications | B14/B20/B25 |
| mosque-donation | member | Donation/payment | amount, privacy, receipt | Wallet/receipts | B14/B25 |
| mosque-care-request | member/admin | Protected care form/review | private/public split, recipient state | Vault/cases/audit | B14/B25 |
| mosque-volunteer-signup | member | Volunteer detail | shift/capacity/signup state | Forms/events | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| announcement | admin composes/sends | member reads inbox/feed | other members read sent item | publish hidden for member | non-admin cannot send |
| care request | member submits | admin/support receives | member sees status | protected fields hidden broadly | unauthorized personas denied |

## 8. Content And Seed Data Requirements

Use realistic announcement body, sender/role, audience, delivery timing, donation amount/fund,
receipt, volunteer shift/capacity, care privacy indicators, and receiver state.

## 9. Visual And Interaction Standard

Use a respectful community hub with strong content hierarchy, clear privacy/giving treatment, and
domain surfaces for announcements/donations/care. Avoid checklist modals and repeated task cards.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Masjid Nur product experience. | Judge current screenshots against announcement/giving/care surfaces. | open |
