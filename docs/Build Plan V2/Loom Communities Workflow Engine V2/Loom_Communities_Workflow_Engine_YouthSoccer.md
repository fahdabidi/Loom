# Riverside Youth Soccer — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/riverside-youth-soccer-product-experience.md`.
Anti-pattern to avoid: "generic payment/form/notification workflow tiles."

## Personas
| Persona  | Role                                                                        | Key constraint                                                   |
| -------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Guardian | actor on join-approval/registration/payment, receiver on schedule/reminders | cannot see un-redacted minor data beyond consent scope           |
| Coach    | actor on roster/schedule/reminders                                          | sees only role-appropriate minor info; protected fields redacted |
| Owner    | actor on export                                                             | export must respect minor redaction                              |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Schedule-first hierarchy (source doc is explicit about this ordering). Must show strong
privacy/receipt indicators, not abstract payment rows.

### Registration (guardian: actor; coach/owner: receiver) — `guidedProcess` + `statusTimeline`
**The canonical `guidedProcess` case.** Guardian join-approval is a genuine multi-step wizard, not a
flat status card:
- **Registration wizard** (`guidedProcess`, `role: actor`): sequential steps with a visible position
  indicator — join request → waiver acknowledgement → registration payment → roster confirmation,
  each with per-step validation (can't reach payment before the waiver is signed). The guardian steps
  *through* this.
- **Registration status card** (`statusTimeline`, same instance, `role: receiver`): the club
  reviewer/coach *watches* the same instance (current step, missing items, approve/reject). Same
  workflow, two role-keyed `renderBindings` — the exact split §3b (Redwood gap #2) introduced.

### Schedule (both) — `calendarAgenda`
- **Practice/game card**: date/time/location/field/opponent, reminder, calendar-sync state, RSVP
  (going/maybe/not-going), change/cancel, capacity/attendance visible to coach.

### Team — two role-keyed bindings, same instances, two archetypes (§4b's "same data, two views" pattern)
- **Guardian's roster card** (`stateMachineGrid`, `role: guardian`, `tabId: team`): one card, their own
  child only — player/waiver state, protected fields per `protectedDetail`'s masking rules.
- **Coach's roster table** (`table`, `role: coach`, `tabId: team`): the *entire* roster, sortable by
  `playerName`/`ageGroup`/`waiverStatus` (columns reference `soccer-team-roster`'s
  `instanceDataSchema` keys, each marked `sortable: true`). Actions: edit player, request update,
  redact field, undo. Same `workflowType`, same instances as the guardian's cards — only the
  `cardSurfaceFamily` differs, exactly like Chess Club's standings table references `chess-match-result`.
- **Minor-data detail card** (`protectedDetail`, reachable from either binding): shows which fields
  are redacted and why, consent state; unauthorized roles see the hidden/redacted version, not an
  error.

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

## Community-specific customizations (per archetype, per persona)

| Archetype                                                       | Community customization (theme/fields/states/copy)                              | Guardian needs                               | Coach needs                                                | Owner needs                     |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------------- | ------------------------------- |
| `guidedProcess` (registration)                                  | Steps join→waiver→payment→roster; per-step gate                                 | step through wizard, resume draft            | —                                                          | —                               |
| `statusTimeline` (registration)                                 | Reviewer view of the same wizard; missing-items list                            | watch own status                             | approve/reject, request changes                            | —                               |
| `calendarAgenda` (schedule)                                     | Schedule-first; fields date/time/field/opponent; calendar-sync                  | RSVP, get reminders                          | create/edit practices+games, see attendance                | —                               |
| `paymentCheckout`                                               | Fee/receipt; unpaid/paid/failed                                                 | pay, retry, refund, manage                   | —                                                          | ledger view                     |
| `stateMachineGrid` (roster, guardian) + `table` (roster, coach) | Same instances, two archetypes; table columns sortable by name/age-group/waiver | read-only own child card                     | sortable roster table: edit player, request update, redact | —                               |
| `protectedDetail` (minor data)                                  | Shared redaction/consent rules (with Mosque); shows why-redacted                | see own child full                           | see role-appropriate fields only                           | —                               |
| `documentLibrary` (waivers)                                     | Version/acknowledgement; embedded-vs-external                                   | open/acknowledge waiver                      | manage docs                                                | —                               |
| `notificationInbox` (reminders)                                 | Sender=coach; audience=team; delivery receipts                                  | receive reminders, mark read                 | compose/schedule reminders                                 | —                               |
| `exportWizard`                                                  | Minor-redaction preview mandatory; checksum                                     | —                                            | —                                                          | run export respecting redaction |
| `dashboard` (Home)                                              | Schedule-first; privacy/receipt indicators                                      | guardian pins: next game, payment, reminders | coach pins: roster, schedule                               | —                               |

## Cross-cutting notes
- The **guardian registration flow** is now the clearest data point for the `guidedProcess`/
  `statusTimeline` split (Redwood gap #2): the guardian *completes* a stepped wizard while the
  reviewer *watches* a status timeline — same instance, two role-keyed bindings. This is a better
  model than the earlier "it's all statusTimeline" framing, which conflated doing with watching.
- Protected-minor-data handling here is a second, independent confirmation of `protectedDetail` as
  its own archetype (alongside Mosque's care-request) — worth treating the redaction/consent
  rendering rules as shared logic across both communities' `protectedDetail` instances, not
  reinvented per community.
