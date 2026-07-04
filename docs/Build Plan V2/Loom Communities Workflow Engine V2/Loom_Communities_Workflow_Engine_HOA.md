# Cedar Commons HOA — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/cedar-commons-hoa-product-experience.md`. This doc
re-derives the target UI from the product spec's actual workflows, not from the current
implementation — per the anti-pattern the source doc names: must not feel like "a generic admin
task list with dues and document chips."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Homeowner/Member | actor on dues/documents/facilities/requests | non-member denied/hidden everywhere |
| HOA Board | receiver on requests, actor on document management/export | decisions require audit trail; non-board denied on review actions |

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

### Requests (homeowner) — `statusTimeline`
- **Architectural request card**: current step of submitted → under-review → changes-needed →
  approved/denied → reopened, with reviewer, requested-changes path, document/payment checkpoints,
  comments, audit/status history. Actions: submit, edit, withdraw, revise (on changes-needed), reopen,
  appeal.

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

## Cross-cutting notes
- Every workflow above has an explicit actor-state **and** receiver-state requirement (e.g. board
  decision → homeowner sees approved/rejected/changes-needed) — this is `renderBindings`' `role`
  field doing its job: the Board's decision queue and the homeowner's request-status card are two
  `renderBindings` on the *same* `statusTimeline` workflow instance, not two separate workflows.
- Anti-patterns explicitly named in the source doc to avoid regressing into: "generic payment chip,"
  "metadata card only," "checklist modal," "single rigid approval card."
