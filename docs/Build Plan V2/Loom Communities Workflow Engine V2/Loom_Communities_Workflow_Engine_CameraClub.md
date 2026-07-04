# Camera Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/camera-club-product-experience.md` (an
arbitrary/prompt-generated example — proves the Skill can produce a real photo-club experience, not
just a validation report).

## Personas
| Persona | Role | Key constraint |
| --- | --- | --- |
| Organizer | actor on prompt-build validation | generated package must not skip requested workflows |
| Member | actor on photo-walk RSVP/critique/gear-loan | photo submissions may need consent/context |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Visual-first (explicit requirement: "photo thumbnails, location/time and critique-state clarity").

### Calendar (both) — `calendarAgenda`
- **Photo-walk event card**: named route, date/time/location, capacity, RSVP (going/maybe/not-going),
  change path, confirmed state.

### Critique (both) — `stateMachineGrid` (image-forward item template) + `discussionThread`
### composed together, per §3b's explicit "don't invent a new archetype for this" guidance
- **Photo submission grid card**: thumbnail-forward tile (the `stateMachineGrid` item template with
  an image-first `displayContext`, not the default icon+text tile), title, prompt, consent note.
  States: draft / submitted / reviewed. Actions: submit, edit, withdraw.
- **Attached critique thread** (`discussionThread`, bound to the same submission instance): reviewer
  queue, comments. This is the concrete case motivating composition over a new "media gallery +
  critique" archetype — same two existing archetypes, wired to the same workflow instance via two
  `renderBindings` entries (grid card = primary interactive surface, thread = attached detail).

### Gear (both) — `stateMachineGrid`
- **Gear loan card**: browse/search, list/edit/pause/delist personal gear, loan-vs-giveaway mode,
  join/leave/advance queue, current holder/custody history, borrower/claim roster, pickup/return
  timing, condition, ownership transfer. Anti-pattern explicitly named: "single request card without
  browse, queue, listing, or custody" — fourth independent confirmation of `stateMachineGrid`'s
  built-in queue/custody requirement (after Tabletop, Garden Club, Book Club).

### Admin (organizer only) — `statusTimeline` (lightweight)
- **Validation/completion report card**: requested workflows, implemented/validated pass state,
  package paths, pending/complete states. Explicit requirement: must not dominate the member-facing
  product — this card is Admin-tab-only, never a `renderBinding` target on Home or Critique.

### Messages (both) — `discussionThread`

## Cross-cutting notes
- Camera Club is the concrete proof case for §3b's "compose, don't fragment" restraint principle: the
  photo-critique pattern *looks* like it might need its own archetype, but decomposes cleanly into
  `stateMachineGrid` (image item template) + `discussionThread` (attached), both already justified by
  other communities independently.
