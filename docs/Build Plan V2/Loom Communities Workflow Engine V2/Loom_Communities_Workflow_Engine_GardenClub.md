# Garden Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/garden-club-product-experience.md`. Anti-pattern to
avoid: "a generic workflow list with event and form labels."

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Member | actor on RSVP/plant-exchange/tool-loan | contact details/private requests must not be overexposed |
| Coordinator | actor on event organizing/export | export needs checksum/redaction context |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Explicit requirement: prioritize garden *activity* — "what is happening this week, what help or
exchange is needed, what records are available" — a composite of calendar + marketplace + export
mini-cards, not workflow categories.

### Calendar (both) — `calendarAgenda`
- **Event card**: title, date, location, capacity, recurrence/reminder. States: open / RSVPed / full
  / cancelled. Actions: RSVP, cancel, join waitlist when full. Attendee count visible to coordinator.

### Marketplace (both) — `stateMachineGrid` (two workflow types sharing the tab, per §3a's
many-to-many model)
- **Tool loan/giveaway card**: states available/queued/reserved/loaned/overdue/given/returned/lost.
  Actions: browse, list your own item, choose loan-vs-giveaway mode, join/leave waitlist, view
  current-holder/custody (privacy-redacted), confirm pickup/return or ownership transfer, report
  condition/damage. Source doc explicitly flags "single generic request" as the anti-pattern — this
  card needs the full browse+queue+custody treatment, matching Book Club's shared-library and
  Tabletop's equipment-loan almost exactly (third independent confirmation of `stateMachineGrid`).
- **Plant exchange card** (a lighter `stateMachineGrid` instance, closer to classifieds): draft /
  submitted / reviewed states, privacy-gated contact handoff on claim. Actions: submit listing, edit,
  withdraw, claim, cancel-claim.

### Care (member) — `volunteerRoster`-adjacent
- Care/volunteer coordination for garden maintenance shifts — same shape as Mosque's volunteer
  roster (role/time/open-spots/signed-up roster), reused rather than reinvented per community.

### Documents/Organize (coordinator) — `exportWizard`
- **Export card**: schema selection (garden_event, plant_exchange), redaction preview, checksum,
  destination, change-scope, download status. The source doc's own remediation log records this
  surface being explicitly tightened from "generic evidence" to this full review-and-confirm shape —
  direct evidence a plain `singleItem`/`list` was insufficient here.

### Messages (both) — `discussionThread`

## Cross-cutting notes
- Garden Club is the *second* independent confirmation (after Tabletop) that `stateMachineGrid` needs
  built-in queue/custody state, not a plain grid — and the *third* overall once Book Club's shared
  library and Camera Club's gear loan are counted.
- `exportWizard`'s remediation history here is worth treating as a cautionary, reusable case study
  when Phase 5 (automated migration, per the main tracker's §7) gets designed — a generic evidence
  card silently regressing into "good enough" is exactly the failure mode automation needs to guard
  against.
