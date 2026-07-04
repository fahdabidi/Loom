# Masjid Nur — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md`. Anti-pattern to
avoid: "a list of publish/receive workflows with generic cards and confirmation checklists."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Masjid Admin | actor on announcements/events/volunteer coordination, receiver on care review | care/donation privacy must be respected |
| Community Member | receiver on announcements, actor on RSVP/donate/volunteer/care-request | cannot publish; cannot see others' protected care fields or unauthorized donor identity |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Pinned (member): Friday service/iftar, donation receipt, care request status. Pinned (admin):
announcement composer, volunteer roster, donation status, care review. Must read as a community hub
(announcements + events + giving + volunteer needs + care), never a global workflow list.

### Calendar (both) — `calendarAgenda`
- **Service/class/iftar event card**: title, date/time, location, recurrence, capacity, reminder.
  Actions: RSVP going/maybe/not-going, change/cancel; waitlist appears automatically when at capacity
  — this is the RSVP sub-pattern built into `calendarAgenda`, not a separate surface.

### Giving (both) — `paymentCheckout` + `singleItem` (preference)
- **Donation card** (`paymentCheckout`): amount, fund, privacy indicator, receipt. Actions: pay,
  retry, manage/cancel recurring plan, open receipt.
- **Donor visibility preference card** (`singleItem`, settings sub-pattern): public/anonymous/
  restricted choice, shown alongside the live amount/fund/receipt-visibility context it affects.
  Actions: change visibility. This is layered on top of the donation card, not merged into it — the
  preference outlives any single donation.

### Care (member: actor; admin: receiver) — `protectedDetail`
- **Care request card**: public summary visible to admins generally; private fields visible only to
  the assigned recipient/reviewer. States: draft / submitted / assigned / resolved. Actions: submit,
  edit (draft only), withdraw; admin: assign, respond, close. The public/private split is a rendering
  property of this one card, not two separate cards.

### Admin (admin only) — `notificationInbox` (composer) + `volunteerRoster`
- **Announcement composer card** (`notificationInbox`): draft → preview → schedule/publish →
  sent/read. Actions: publish, edit, preview, save draft, schedule, change audience.
- **Volunteer shift card** (`volunteerRoster`): role/time, open-spots-vs-filled counter, signed-up
  roster. Actions (admin): open/close shift, view roster, follow up with a volunteer (protected
  contact, gated). Actions (member, surfaced on member's own Care/Home pin, not Admin): sign up, edit,
  cancel/withdraw.

### Messages (both) — `discussionThread` + `notificationInbox`
- Standard thread inbox/detail/composer, plus a **neutral notification card**
  (`notificationInbox`) for privacy-safe system notices (e.g. "your care request was received") that
  must never leak protected details — a stricter content policy on the same archetype as the
  announcement composer above, not a different archetype.

### Search (both) — `searchAiAnswer`
- **AI answer card**: query, generated answer, cited/permission-guarded sources. Actions: refine
  query, hide source, report stale citation.

## Cross-cutting notes
- This community is the strongest evidence for `protectedDetail` as its own archetype (not just a
  disabled button) — the care-request card's public/private split renders *different fields* to
  different viewers of the *same* object.
- Persona-picker/persona-aware-UX workflows in the source doc require every card above to prove
  actor/receiver/disabled-with-reason rendering explicitly, not just hide/show — confirms §3b's
  cross-cutting rendering concern is load-bearing here, not decorative.
- The source doc's own remediation log flags announcement, iftar RSVP, and volunteer-signup surfaces
  as having had real implementation gaps ("in progress" as of last review) — i.e., this is not a
  hypothetical risk, it already happened once under the narrower archetype set.
