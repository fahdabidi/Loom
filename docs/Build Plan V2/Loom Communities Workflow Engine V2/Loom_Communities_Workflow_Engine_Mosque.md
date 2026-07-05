# Masjid Nur — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/masjid-nur-product-experience.md`. Anti-pattern to
avoid: "a list of publish/receive workflows with generic cards and confirmation checklists."

## Personas
| Persona          | Role                                                                          | Key constraint                                                                          |
| ---------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Masjid Admin     | actor on announcements/events/volunteer coordination, receiver on care review | care/donation privacy must be respected                                                 |
| Community Member | receiver on announcements, actor on RSVP/donate/volunteer/care-request        | cannot publish; cannot see others' protected care fields or unauthorized donor identity |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Pinned (member): Friday service/iftar, donation receipt, care request status. Pinned (admin):
announcement composer, volunteer roster, donation status, care review. Must read as a community hub
(announcements + events + giving + volunteer needs + care), never a global workflow list.

### Calendar — `formEntry` (create) + `calendarAgenda` (distribute/RSVP), one workflow, role-keyed bindings (§3a/§3c)
- **Event creation form** (`formEntry`, `role: actor`, admin only — guard `allowedPersonaIds:
  ["masjid-admin"]`): title/date/time/location/recurrence/capacity, plus an `audienceSelector` field
  (`all | selected-many | individual`) setting the instance's `audienceScope`/`invitedPersonaIds`.
  Covers all three cardinalities from one form: broadcast Friday prayer to all members
  (`scope:"all"`), invite a specific planning-committee subset (`selected-many`), or invite one
  person to a private consultation (`individual`) — no separate cards per cardinality.
- **Event/RSVP card** (`calendarAgenda`, `role: receiver`, resolved dynamically via
  `audienceMemberField: "invitedPersonaIds"` when `audienceScope != "all"`): title, date/time,
  location, recurrence, capacity, reminder. Actions: RSVP going/maybe/not-going, change/cancel;
  waitlist appears automatically when at capacity — the RSVP sub-pattern built into `calendarAgenda`.
  Only personas in the resolved audience see this binding when scope is `selected`/`individual`;
  everyone with the member role sees it when scope is `all`.
- Same instance, two bindings — admin never sees their own creation form as an "attendee" card, and a
  member never sees the creation form at all (guard denies it), matching persona symmetry from §3a.

### Giving (both) — `paymentCheckout` + `singleItem` (preference)
- **Donation card** (`paymentCheckout`): amount, fund, privacy indicator, receipt. Actions: pay,
  retry, manage/cancel recurring plan, open receipt.
- **Donor visibility preference card** (`singleItem`, settings sub-pattern): public/anonymous/
  restricted choice, shown alongside the live amount/fund/receipt-visibility context it affects.
  Actions: change visibility. This is layered on top of the donation card, not merged into it — the
  preference outlives any single donation.

### Care (member: actor; admin: receiver) — `formEntry` (submit) + `protectedDetail` (view)
- **Care request form** (`formEntry`, `role: actor`): typed fields — need description, urgency,
  contact preference, public-vs-private per-field flags. Draft/submit/edit.
- **Care request detail card** (`protectedDetail`, same instance): public summary visible to admins
  generally; private fields visible only to the assigned recipient/reviewer. States: draft /
  submitted / assigned / resolved. Actions (admin): assign, respond, close. The public/private split
  is a rendering property of the detail card; the entry form is where the member marks which fields
  are private.

### Admin (admin only) — `formEntry`+`notificationInbox` (compose) + `volunteerRoster`
- **Announcement composer card** (`formEntry` for the compose fields — body/audience/schedule-time —
  feeding a `notificationInbox` for the sent/read tracking): draft → preview → schedule/publish →
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

## Community-specific customizations (per archetype, per persona)

| Archetype                                  | Community customization (theme/fields/states/copy)                                                                                      | Member needs                                                       | Admin needs                                                          |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `formEntry`+`calendarAgenda` (event)       | Green/respectful palette; event types prayer/class/iftar; recurrence for daily prayers; audienceSelector (all/selected-many/individual) | RSVP going/maybe/not, join waitlist (only if in resolved audience) | create events + set audience, see attendee counts, manage capacity   |
| `paymentCheckout`                          | Privacy-aware (amount masked per donor pref); fields = amount/fund; recurring donations                                                 | donate, retry, manage recurring, open receipt                      | see donation totals per fund (identity-gated by donor pref)          |
| `singleItem` (donor visibility)            | Toggle public/anonymous/restricted, shown with live fund/amount context                                                                 | set own visibility preference                                      | —                                                                    |
| `formEntry` (care)                         | Per-field public/private flags; urgency levels; contact-pref field                                                                      | submit/edit care request, mark fields private                      | — (admin reviews, doesn't submit)                                    |
| `protectedDetail` (care)                   | Field-level masking by viewer identity, not just role                                                                                   | see own full request                                               | see public summary; private fields only if assigned                  |
| `formEntry`+`notificationInbox` (announce) | Audience selector (all/members/volunteers); schedule-time                                                                               | receive announcements, mark read                                   | compose/preview/schedule/publish, change audience, delivery receipts |
| `volunteerRoster`                          | Open-spots-vs-filled meter; protected contact on roster                                                                                 | sign up, edit, cancel shift                                        | open/close shift, view roster, contact volunteer (gated)             |
| `searchAiAnswer`                           | Citations permission-guarded (some sources members-only)                                                                                | ask, refine, view permitted citations                              | see all citations, report stale                                      |
| `dashboard` (Home)                         | Community-hub layout: announcements + events + giving + volunteer + care                                                                | member pins: Friday service, donation receipt, care status         | admin pins: composer, volunteer roster, donation status, care review |

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
