# Riverside Youth Soccer Product Experience

## 1. Community Identity And Promise

| Field | Value |
| --- | --- |
| Community name | Riverside Youth Soccer |
| Community type | Youth sports team/league |
| Product promise | Help guardians and coaches manage roster, registration, schedule, reminders, and protected minor data. |
| Brand cues | Team/schedule/field cues, confident family-friendly tone, privacy-forward labels. |
| What this must not feel like | Generic payment/form/notification workflow tiles. |

## 2. Personas, Roles, And Jobs

| Persona | Role/capabilities | Primary jobs-to-be-done | Sensitive constraints | Success state |
| --- | --- | --- | --- | --- |
| Guardian | Join approval, register/pay, view schedule/reminders | Keep child registered and know practice/game logistics. | Minor data must be redacted and consented. | Guardian sees registration, payment receipt, and next schedule. |
| Coach | Manage roster and schedule | Know who is registered and communicate reminders. | Coach sees only appropriate minor info. | Roster/schedule/reminder state is current. |
| Owner | Export metadata | Keep league data portable. | Export must respect minor redaction. | Export evidence is redacted and verifiable. |

## 3. Information Architecture

| Surface | Purpose | Primary persona | Required content | Primary action |
| --- | --- | --- | --- | --- |
| Team home | Current team status. | Guardian/coach | next practice, roster status, registration/payment, reminders. | Register / view roster |
| Registration/payment | Register player and pay. | Guardian | player summary, fee, consent, receipt. | Pay registration |
| Roster | View team membership. | Coach | player names or redacted minors, roles, approval state. | Review roster |
| Schedule/reminders | Practice/game logistics. | Guardian/coach | date, time, location, reminder channel. | Confirm / send reminder |

## 4. Home Screen Requirements

The home must answer what is next for the team, whether the child is registered, and what action the
guardian or coach needs to take.

## 5. Domain-Native Product Surfaces

| Surface | Required visible content | Required states | Natural actions | Anti-patterns |
| --- | --- | --- | --- | --- |
| Registration/payment | fee, player context, consent, receipt | unpaid/paid/failed | pay, retry, view receipt | abstract payment row |
| Roster | player/guardian/coach state, redaction | pending/approved/redacted | approve, view | exposed minor details |
| Schedule | event title, date, location, reminder | upcoming/sent/cancelled | remind, RSVP | generic notification card |

## 6. Workflow-To-Surface Mapping

| Workflow | Persona | Product surface | Required visible proof | Loom APIs/rules/events | Test/evidence IDs |
| --- | --- | --- | --- | --- | --- |
| soccer-guardian-join-approval | guardian | Join approval | guardian request and approval state | Membership/roles/events | B14/B25 |
| soccer-team-roster | coach | Roster | team list and approved/redacted state | Membership/vault | B14/B25 |
| soccer-minor-redaction | guardian | Protected profile | redacted minor fields | Vault/consent/audit | B14/B25 |
| soccer-registration-payment | guardian | Payment surface | amount, receipt, status | Wallet/receipts/settlement | B14/B25 |
| soccer-practice-schedule | guardian | Schedule detail | date/time/location | Events/notifications | B14/B25 |
| soccer-reminder-notification | guardian | Reminder center | audience/channel/sent state | Notifications/events | B14/B25 |
| soccer-export-metadata | owner | Export status | redaction/checksum/scope | Export/documents | B14/B25 |

## 7. Persona And State Matrix

| Workflow | Actor state | Receiver state | Read-only state | Disabled/hidden state | Unauthorized behavior |
| --- | --- | --- | --- | --- | --- |
| registration payment | guardian pays | coach sees registered state | guardian can view receipt | pay disabled after paid | non-guardian hidden |
| roster | coach manages | guardian sees child status | member reads schedule | roster admin hidden | minors redacted |

## 8. Content And Seed Data Requirements

Use team names, practice dates, field locations, registration fees, receipts, guardian/player labels,
redaction markers, and reminder channels.

## 9. Visual And Interaction Standard

Use schedule-first mobile hierarchy, strong privacy/receipt indicators, and role-specific coach vs
guardian surfaces. Avoid repeated cards that hide team logistics.

## 10. Review And Remediation Log

| Review run | Product-spec gap? | Implementation gap? | Product doc changes | UI changes required | Status |
| --- | --- | --- | --- | --- | --- |
| B25 next pass | no | pending review | Created canonical Youth Soccer product experience. | Judge current screenshots against team/schedule/payment surfaces. | open |
