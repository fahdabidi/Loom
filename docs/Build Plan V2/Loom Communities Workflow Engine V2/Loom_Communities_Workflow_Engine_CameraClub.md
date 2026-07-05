# Camera Club — Tabs, Cards, Actions (workflow-engine target design)

Source: `docs/Product Docs V2/Community Examples/camera-club-product-experience.md` (an
arbitrary/prompt-generated example — proves the Skill can produce a real photo-club experience, not
just a validation report).

## Personas
| Persona   | Role                                        | Key constraint                                      |
| --------- | ------------------------------------------- | --------------------------------------------------- |
| Organizer | actor on prompt-build validation            | generated package must not skip requested workflows |
| Member    | actor on photo-walk RSVP/critique/gear-loan | photo submissions may need consent/context          |

## Tabs → Cards → Archetype → Actions

### Home (both) — `dashboard`
Visual-first (explicit requirement: "photo thumbnails, location/time and critique-state clarity").

### Calendar (both) — `calendarAgenda`
- **Photo-walk event card**: named route, date/time/location, capacity, RSVP (going/maybe/not-going),
  change path, confirmed state.

### Critique (both) — `formEntry` (submit) + `stateMachineGrid` (grid) + `discussionThread`
### composed together, per §3b's explicit "don't invent a new archetype for this" guidance
- **Critique submission form** (`formEntry`, image-forward): fields photo-upload/title/prompt/consent
  note. Actions: submit, edit, withdraw. States: draft / submitted / reviewed.
- **Photo submission grid card** (`stateMachineGrid`): thumbnail-forward tile (image-first
  `displayContext`, not the default icon+text tile) showing the submissions produced by the form
  above.
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

## Community-specific customizations (per archetype, per persona)

| Archetype                     | Community customization (theme/fields/states/copy)        | Member needs                                        | Organizer needs                             |
| ----------------------------- | --------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------- |
| `calendarAgenda` (photo-walk) | Visual-first; fields route/location/time; capacity        | RSVP going/maybe/not, change                        | create walks, see capacity                  |
| `formEntry` (critique)        | Image-upload field; prompt/consent fields                 | submit photo + prompt, edit, withdraw               | —                                           |
| `stateMachineGrid` (critique) | Photo-thumbnail item template (image-first)               | browse submissions                                  | manage/curate submissions                   |
| `discussionThread` (critique) | Attached to a submission instance; reviewer-queue framing | comment, receive critique                           | organize reviewer queue                     |
| `formEntry` (gear listing)    | Fields gear-type/condition/loan-vs-giveaway/photo         | list own gear, edit, pause/delist                   | —                                           |
| `stateMachineGrid` (gear)     | Custody+queue; borrower/claim roster                      | browse/search, borrow, join queue, return, transfer | see custody history                         |
| `statusTimeline` (validation) | Admin-only; requested-vs-implemented-vs-validated         | —                                                   | run prompt-build validation, see pass state |
| `dashboard` (Home)            | Photo-thumbnail visual-first                              | member visual pins                                  | organizer admin pins (not member-facing)    |

## Cross-cutting notes
- Camera Club is the concrete proof case for §3b's "compose, don't fragment" restraint principle: the
  photo-critique pattern *looks* like it might need its own archetype, but decomposes cleanly into
  `formEntry` (image submit) + `stateMachineGrid` (image grid) + `discussionThread` (attached), all
  three already justified by other communities independently.
