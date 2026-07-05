# Cedar Commons HOA — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`. This doc
re-derives the target UI from the product spec's actual workflows, not from the current
implementation — per the anti-pattern the source doc names: must not feel like "a generic admin
task list with dues and document chips."

## Personas
| Persona          | Role                                                      | Key constraint                                                    |
| ---------------- | --------------------------------------------------------- | ----------------------------------------------------------------- |
| Homeowner/Member | actor on dues/documents/facilities/requests               | non-member denied/hidden everywhere                               |
| HOA Board        | receiver on requests, actor on document management/export | decisions require audit trail; non-board denied on review actions |

## Tabs → Cards → Archetype → Actions

### Home (both personas) — `dashboard`
Aggregates mini-cards from every tab below at `minimized`/`medium`/`expanded` density, tap-to-expand.
Pinned (homeowner): dues receipt, active request status, governing docs. Pinned (board):
architectural decision queue, owner notifications, facility requests.

### Documents (both) — `documentLibrary`
- **Governing docs library card**: categorized (bylaws, covenants, meeting minutes). Actions: browse
  by category, open embedded, open external, download.
- **Document detail card**: title/version/date, access state. Actions: open embedded, open external,
  acknowledge, request access. States: available / read / acknowledged / access-requested.

### Payments (homeowner) — `paymentCheckout`
- **Dues card**: amount, due date, payer. Actions: pay, view receipt. Alternates: change amount, edit
  payment, manage/cancel subscription, refund, retry. States: due / paid / failed (retry shown only
  on failure; pay disabled after paid).

### Requests (homeowner) — `formEntry` (submit) + `statusTimeline` (track)
- **Architectural request form** (`formEntry`, `role: actor`): typed fields — project description,
  property address, attachments, requested-completion date. Draft/submit + revise on changes-needed.
  This is the *entry* side, split out from the timeline per §3b (Redwood gap #2).
- **Architectural request status card** (`statusTimeline`, same instance, tracking view): current
  step of submitted → under-review → changes-needed → approved/denied → reopened, with reviewer,
  requested-changes path, document/payment checkpoints, comments, audit/status history. Actions
  (homeowner): withdraw, reopen, appeal. Both cards are two `renderBindings` on one workflow instance.

### Board (board persona only) — `statusTimeline` (reviewer-facing) + `dashboard` (queue)
- **Decision queue card** (`dashboard`-style list of `statusTimeline` summaries): requester, current
  step, age. Tapping opens the full timeline.
- **Committee decision card** (`statusTimeline`, reviewer view of the same instance homeowners see):
  requester, decision actions (approve/reject/request changes), comments, status history, and the
  owner-notification receiver state this decision produces.

### Messages (both) — `notificationInbox` + `discussionThread`
- **Owner notification card** (`notificationInbox`): sender/audience/body/timing/sent-read state —
  fed by Board decisions and by facility-reservation conflict alerts.
- **Direct/thread messages** (`discussionThread`): standard inbox/thread/composer, same as every
  other community's Messages tab.

### Facilities (implicit under Home/Requests, `calendarAgenda`)
- **Facility reservation card**: facility/date/time, conflict/status, reminder. Actions: reserve,
  cancel, change, reschedule. Conflict detection surfaces inline in the event-detail panel, not a
  separate dialog.

## Community-specific customizations (per archetype, per persona)

| Archetype                     | Community customization (theme/fields/states/copy)                                           | Homeowner needs                              | Board needs                                             |
| ----------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------- |
| `paymentCheckout`             | Civic palette; fields = dues amount/period/property; states due/paid/failed; copy "Pay dues" | pay, view receipt, manage autopay            | read-only ledger view of who's paid (audit)             |
| `documentLibrary`             | Categories = bylaws/covenants/minutes; acknowledgement required on governing docs            | open/download/acknowledge, request access    | upload/version/retire docs, see who acknowledged        |
| `formEntry` (request)         | Fields = project desc/address/attachments/date; validation on required attachments           | submit, edit draft, revise on changes-needed | — (board doesn't submit requests)                       |
| `statusTimeline` (request)    | Steps submitted→review→changes→approved/denied→reopened; audit-trail emphasis                | watch status, withdraw, reopen, appeal       | approve/reject/request-changes, comment, decision audit |
| `calendarAgenda` (facilities) | Conflict-detection inline; fields = facility/date/time                                       | reserve/cancel/reschedule, see conflicts     | see all reservations, override/block                    |
| `notificationInbox`           | Sender = Board; audience = homeowners; civic tone                                            | receive owner notifications, mark read       | compose/schedule owner notifications, delivery receipts |
| `dashboard` (Home)            | Pins: dues receipt, active request, governing docs                                           | homeowner-priority pins                      | board-priority pins: decision queue, facility requests  |
| `discussionThread`            | Standard                                                                                     | member↔member, member↔board                  | board broadcast + moderation                            |

## Cross-cutting notes
- Every workflow above has an explicit actor-state **and** receiver-state requirement (e.g. board
  decision → homeowner sees approved/rejected/changes-needed) — this is `renderBindings`' `role`
  field doing its job: the Board's decision queue and the homeowner's request-status card are two
  `renderBindings` on the *same* `statusTimeline` workflow instance, not two separate workflows.
- Anti-patterns explicitly named in the source doc to avoid regressing into: "generic payment chip,"
  "metadata card only," "checklist modal," "single rigid approval card."
