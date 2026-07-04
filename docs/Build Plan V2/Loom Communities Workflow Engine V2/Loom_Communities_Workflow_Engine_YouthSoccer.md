# Riverside Youth Soccer — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`.
Anti-pattern to avoid: "generic payment/form/notification workflow tiles."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Guardian | actor on join-approval/registration/payment, receiver on schedule/reminders | cannot see un-redacted minor data beyond consent scope |
| Coach | actor on roster/schedule/reminders | sees only role-appropriate minor info; protected fields redacted |
| Owner | actor on export | export must respect minor redaction |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Schedule-first hierarchy (source doc is explicit about this ordering). Must show strong
privacy/receipt indicators, not abstract payment rows.

### Schedule (both) — `calendarAgenda`
- **Practice/game card**: date/time/location/field/opponent, reminder, calendar-sync state, RSVP
  (going/maybe/not-going), change/cancel, capacity/attendance visible to coach.

### Team (both) — `stateMachineGrid`-adjacent roster + `protectedDetail`
- **Roster card** (coach: actor; guardian: read-only on own child): player/guardian state, waiver
  status. Actions (coach): edit player, request update, redact field, undo.
- **Minor-data detail card** (`protectedDetail`): shows which fields are redacted and why, consent
  state; unauthorized roles see the hidden/redacted version, not an error.

### Payments (guardian) — `paymentCheckout`
- **Registration payment card**: fee, receipt. States: unpaid / paid / failed. Actions: pay, retry,
  refund, manage subscription.

### Documents (coach; guardian via Team) — `documentLibrary`
- **Waiver/document card**: title/version/source, embedded-vs-external open, acknowledgement state,
  access-request gating, audit trail.

### Coach (coach only) — `dashboard` (roster + schedule composited) + `notificationInbox`
- **Reminder/announcement card** (`notificationInbox`): sender/audience/channel/timestamp, read/unread,
  draft/schedule/publish/cancel, delivery/read receipts.

### Messages (both) — `discussionThread`

### Admin/Export (owner) — `exportWizard`
- **Export card**: scope selection, redaction preview (minor data specifically flagged), checksum,
  transfer/rollback/retry.

## Cross-cutting notes
- The **guardian join-approval flow** (registration → waiver → payment → roster) is the clearest
  second data point (after HOA) for `statusTimeline`: current step, missing items, reviewer,
  checkpoints, history — this is a case/status pattern, not a single card, and the source doc is
  explicit that it must show the full step sequence, not a collapsed approve/reject button.
- Protected-minor-data handling here is a second, independent confirmation of `protectedDetail` as
  its own archetype (alongside Mosque's care-request) — worth treating the redaction/consent
  rendering rules as shared logic across both communities' `protectedDetail` instances, not
  reinvented per community.
