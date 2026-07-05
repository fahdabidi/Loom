# Archetype Catalog — cross-reference + per-community JSON field reference

Living design doc (not implemented). Two parts:
1. **Master cross-reference table** — every archetype × community × workflow, with community
   customization and per-persona features.
2. **Per-archetype JSON** — for each archetype: an annotated **customization-field schema** (the full
   set of fields the archetype exposes for community customization), then **per-community instances**
   showing how those fields are set differently. Inspect part 2 to understand exactly which fields
   drive each community's look/behavior.

All 15 primary archetypes + `table`/`singleItem`/`list` follow one base shape:
```jsonc
{
  "cardSurfaceFamily": "<unique-key>",   // referenced by a workflow's renderBindings[].cardSurfaceFamily
  "archetype": "<containerType>",         // one of the 15 (+3) container types
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },  // community brand tokens
  "workflowType": "<id>",                 // links to states/transitions/instanceDataSchema (§3, §9a)
  "<archetype>": { /* archetype-specific config — the customizable fields, below */ }
}
```
Per-persona differences are expressed either as guard-filtered transitions (same surface, different
buttons) or as separate role-keyed `renderBindings` (different surface per role) — see §3a. Only
`guidedProcess`↔`statusTimeline` and `protectedDetail` change the *surface* per persona; everything
else changes only *which actions are enabled*.

---

## Part 1 — Master cross-reference table

### calendarAgenda — universal (all 8)
| Community    | Workflow / card                         | Customization                             | Per-persona features                                    |
| ------------ | --------------------------------------- | ----------------------------------------- | ------------------------------------------------------- |
| Tabletop     | Game-night/tournament RSVP              | date/time/location; capacity              | member: RSVP/change · organizer: create, capacity       |
| HOA          | Facility reservation; board meetings    | inline conflict detection                 | homeowner: reserve/reschedule · board: see-all/override |
| Mosque       | Prayer/class/iftar                      | daily-prayer recurrence; green palette    | member: RSVP/waitlist · admin: create, counts           |
| Book Club    | Meeting RSVP                            | physical or virtual link; reading-cycle   | member: RSVP/link · host: schedule/attendance           |
| Youth Soccer | Practice/game schedule                  | schedule-first; field/opponent; sync      | guardian: RSVP/reminders · coach: create/attendance     |
| Garden Club  | Garden event RSVP                       | seasonal accents; full/cancelled/waitlist | member: RSVP/waitlist · coordinator: create/counts      |
| Camera Club  | Photo-walk RSVP                         | visual-first; route/location              | member: RSVP/change · organizer: create/capacity        |
| Chess Club   | Club night/tournament + confirmed match | opponent/pairing; tournament flavor       | player: schedule/reminders · organizer: create/pairings |

### stateMachineGrid — 5×
| Community    | Workflow / card                    | Customization                               | Per-persona features                                          |
| ------------ | ---------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| Tabletop     | Equipment loan + giveaway          | icon tiles; available/onLoan; queue+custody | member: borrow/queue/claim/return · organizer: return/custody |
| Book Club    | Shared lending library             | cover-art template; book/DVD/game           | member: browse/borrow/queue · host: list/delist/custody       |
| Garden Club  | Tool loan/giveaway; plant exchange | 8-state custody; classifieds-lite           | member: browse/borrow/claim/damage · coordinator: moderate    |
| Camera Club  | Gear loan + photo-submission grid  | photo-thumbnail template                    | member: browse/borrow/queue · organizer: custody              |
| Youth Soccer | Team roster (adjacent)             | minor-data redaction on tiles               | guardian: read-only child · coach: edit/redact                |

### formEntry (NEW #14) — 2nd broadest
| Community        | Workflow / card                    | Customization                               | Per-persona features                     |
| ---------------- | ---------------------------------- | ------------------------------------------- | ---------------------------------------- |
| Book Club        | Book nomination                    | title/author/reason/cover-image             | member: nominate/edit/withdraw · host: — |
| Mosque           | Care request; announcement compose | per-field public/private; audience selector | member: submit care · admin: compose     |
| Youth Soccer     | Registration fields; roster edit   | validation gates; minor-data fields         | guardian: fill · coach: edit/redact      |
| Garden Club      | Plant-exchange + list-your-item    | plant OR tool schema                        | member: list item · coordinator: —       |
| Camera Club      | Critique submit; list-gear         | image-upload; prompt/consent                | member: submit · organizer: —            |
| HOA              | Architectural-request submit       | project/address/attachments; validation     | homeowner: submit/revise · board: —      |
| Chess Club       | Propose-match; report-result       | opponent/board; score→rankings              | player: propose/report · organizer: —    |
| all marketplaces | "List your own item"               | per-community item schema                   | member/owner: create listing             |

### guidedProcess (NEW #15)
| Community    | Workflow / card                              | Customization                     | Per-persona features                                        |
| ------------ | -------------------------------------------- | --------------------------------- | ----------------------------------------------------------- |
| Youth Soccer | Registration wizard (join→waiver→pay→roster) | per-step gate; position indicator | guardian: step through · (coach watches via statusTimeline) |
| Chess Club   | Match propose→confirm (actor side)           | propose→respond→confirm           | proposer: drive to confirm                                  |

### statusTimeline (narrowed — passive dual-viewer)
| Community    | Workflow / card                            | Customization       | Per-persona features                                             |
| ------------ | ------------------------------------------ | ------------------- | ---------------------------------------------------------------- |
| HOA          | Architectural request + committee decision | audit-trail; 5-step | homeowner: watch/withdraw/appeal · board: approve/reject/comment |
| Youth Soccer | Registration status (reviewer side)        | missing-items list  | guardian: watch · coach: approve/request-changes                 |
| Camera Club  | Critique draft→submitted→reviewed          | lightweight         | member: watch · organizer: reviewer-queue                        |
| Chess Club   | Match negotiation; result dispute          | two-party           | both: negotiate/dispute                                          |

### paymentCheckout — 4×
| Community    | Workflow / card      | Customization                    | Per-persona features                           |
| ------------ | -------------------- | -------------------------------- | ---------------------------------------------- |
| Tabletop     | Dues (Giving)        | amount/period                    | member: pay/receipt                            |
| HOA          | Dues payment         | property/period; autopay         | homeowner: pay/manage · board: ledger          |
| Mosque       | Donation             | masked per donor pref; recurring | member: donate/recurring · admin: gated totals |
| Youth Soccer | Registration payment | fee/receipt                      | guardian: pay/retry · owner: ledger            |

### documentLibrary — 5×
| Community    | Workflow / card        | Customization                            | Per-persona features                        |
| ------------ | ---------------------- | ---------------------------------------- | ------------------------------------------- |
| HOA          | Governing docs         | categories bylaws/covenants/minutes; ack | homeowner: open/ack · board: upload/version |
| Mosque       | Khutbah/forms/policies | ack on policies                          | member: open · admin: manage                |
| Book Club    | Reading materials      | reading-cycle tie-in                     | member: open/download · host: curate        |
| Youth Soccer | Waivers                | version/ack                              | guardian: acknowledge · coach: manage       |
| Chess Club   | Club rules             | standard                                 | player: read · organizer: manage            |

### notificationInbox — 4×
| Community    | Workflow / card                      | Customization                   | Per-persona features                              |
| ------------ | ------------------------------------ | ------------------------------- | ------------------------------------------------- |
| HOA          | Owner notifications                  | civic; Board sender             | homeowner: receive/read · board: compose/receipts |
| Mosque       | Announcements + neutral care notices | audience selector; privacy-safe | member: receive · admin: compose/schedule         |
| Book Club    | Selection-publish                    | winning-book announce           | member: receive · host: publish                   |
| Youth Soccer | Reminders                            | coach sender; team audience     | guardian: receive · coach: compose/schedule       |

### protectedDetail — 4× (2 solid, 2 lighter)
| Community    | Workflow / card             | Customization                        | Per-persona features                                  |
| ------------ | --------------------------- | ------------------------------------ | ----------------------------------------------------- |
| Mosque       | Care request public/private | field-masking by identity            | member: own full · admin: public-only unless assigned |
| Youth Soccer | Minor-data redaction        | shared redaction rules; why-redacted | guardian: own child · coach: role-appropriate         |
| Garden Club  | Holder labels (lighter)     | mask until claim                     | member: safe label · coordinator: full                |
| Book Club    | Holder labels (lighter)     | mask until handoff                   | member: safe label · host: full                       |

### exportWizard · searchAiAnswer · votePoll · volunteerRoster · table · singleItem
| Archetype            | Community                        | Workflow                | Customization                                           | Per-persona features                                 |
| -------------------- | -------------------------------- | ----------------------- | ------------------------------------------------------- | ---------------------------------------------------- |
| exportWizard         | HOA/Garden/BookClub/Soccer/Chess | Records export          | per-schema; redaction/checksum (minor-mandatory Soccer) | member: read-only · owner: run/rollback              |
| searchAiAnswer       | Mosque, Book Club                | AI answer w/ citations  | permission-guarded sources                              | member: permitted · admin: all                       |
| votePoll             | Book Club                        | Selection ballot        | candidates=nominations; deadline; winning/tie           | member: cast/change · host: aggregate/close/tiebreak |
| volunteerRoster      | Mosque, Garden (adj)             | Shift signup            | open-spots meter; protected contact                     | member: signup/cancel · admin: open-close/roster     |
| table (+rankingMode) | Chess Club                       | Rankings                | rank/score/delta; live-update                           | player: view · organizer: recompute                  |
| singleItem           | Mosque                           | Donor-visibility toggle | public/anon/restricted + context                        | member: set pref                                     |

### dashboard (meta) — universal (all 8)
Home composites mini-cards at `minimized`/`medium`/`expanded` density; per-persona = **different pins**
(e.g. Chess player: next-match/challenge/result · organizer: pairing-queue/disputes/export).

---

## Part 2 — Per-archetype JSON (field schema + per-community instances)

### 2.1 `calendarAgenda`

**Customization-field schema (every field this archetype exposes):**
```jsonc
{
  "cardSurfaceFamily": "<key>",
  "archetype": "calendarAgenda",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },
  "workflowType": "<event-workflow-id>",
  "calendarAgenda": {
    "groupBy": "date",                 // date-grouped agenda (the M4 grouping)
    "dateStrip": true,                 // horizontal quick-jump strip (deduped by date)
    "views": ["agenda", "month"],      // available view modes; "month" optional
    "eventFields": ["dateTime","location","host","capacityLabel"], // pulled from instanceDataSchema
    "rsvp": {
      "enabled": true,
      "choices": ["going","maybe","not-going"],
      "waitlistWhenFull": true,        // capacity → waitlist behavior
      "showAttendeeCount": true        // organizer sees counts
    },
    "reminders": true,
    "conflictDetection": false,        // true only where double-booking matters (HOA facilities)
    "recurrence": "none",              // "none" | "weekly" | "daily" (Mosque prayers) | "custom"
    // Audience/distribution (§3c). Set audienceMemberField when an event is created for a chosen
    // set of people rather than "all of a role" — the receive-side (role:receiver) binding then
    // resolves visibility from this instance's invitedPersonaIds, not the static receiverPersonaIds.
    "audienceMemberField": null,       // e.g. "invitedPersonaIds"; null = 1-to-all-of-role only
    // rsvp responses persist per-member in instanceData.rsvpByPersona (same shape as queuedPersonaIds)
    "dateWindow": { "paging": "range" } // §4b: calendarAgenda pages by date-range window, not cursor
  }
}
// The corresponding event workflowType carries the audience in instanceData:
//   "instanceData": { "audienceScope": "selected", "invitedPersonaIds": ["fatima","yusuf"],
//                     "rsvpByPersona": { "fatima": "going" } }
```

**Per-community instances (only fields that differ from the schema defaults shown):**
```jsonc
// Mosque — daily prayer recurrence, green palette
{ "cardSurfaceFamily": "mosque-events", "archetype": "calendarAgenda",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" },
  "workflowType": "mosque-event-rsvp",
  "calendarAgenda": { "recurrence": "daily", "views": ["agenda"],
    "eventFields": ["dateTime","location","capacityLabel"],
    "rsvp": { "enabled": true, "choices": ["going","maybe","not-going"], "waitlistWhenFull": true, "showAttendeeCount": true } } }

// HOA — facility reservation needs conflict detection
{ "cardSurfaceFamily": "hoa-facilities", "archetype": "calendarAgenda",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "workflowType": "hoa-facility-reservation",
  "calendarAgenda": { "conflictDetection": true, "eventFields": ["facility","dateTime","location"] } }

// Book Club — physical OR virtual meeting link
{ "cardSurfaceFamily": "bookclub-meetings", "archetype": "calendarAgenda",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" },
  "workflowType": "book-meeting-rsvp",
  "calendarAgenda": { "eventFields": ["dateTime","locationOrLink","host"] } }

// Chess Club — opponent/pairing on the event
{ "cardSurfaceFamily": "chess-matches", "archetype": "calendarAgenda",
  "theme": { "accent": "#2E2E2E", "palette": "board-tournament" },
  "workflowType": "chess-match-meetup",
  "calendarAgenda": { "eventFields": ["dateTime","location","opponent","board"] } }
// Tabletop / Youth Soccer / Garden / Camera follow the same shape, differing only in
// theme + eventFields (Soccer adds "field"/"opponent"; Garden adds seasonal palette).
```

### 2.2 `stateMachineGrid`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>",
  "archetype": "stateMachineGrid",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },
  "workflowType": "<listing-workflow-id>",   // supplies states/transitions/instanceDataSchema
  "stateMachineGrid": {
    "columns": { "minimized": 2, "medium": 2, "expanded": 3 },
    "itemTemplate": "iconTile",              // "iconTile" | "coverArt" | "photoThumbnail"
    "search": { "enabled": true, "searchableFields": ["title","description"], "placeholder": "Search…" },
    "filters": { "field": "category", "mode": "chips" }, // auto-derives chip values from data
    "queue": { "enabled": true, "showPosition": true },
    "custody": { "enabled": true, "showHolder": true, "redactHolderUntil": "claimed" },
    "detailFields": ["condition","holderPersonaId","queuedPersonaIds","dueDate"]
  }
}
```

**Per-community instances:**
```jsonc
// Book Club — cover-art tiles for a lending library
{ "cardSurfaceFamily": "bookclub-library", "archetype": "stateMachineGrid",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" },
  "workflowType": "book-shared-library",
  "stateMachineGrid": { "itemTemplate": "coverArt",
    "search": { "enabled": true, "searchableFields": ["title","author"], "placeholder": "Search library" },
    "filters": { "field": "format", "mode": "chips" },
    "queue": { "enabled": true, "showPosition": true },
    "custody": { "enabled": true, "showHolder": true, "redactHolderUntil": "borrowed" },
    "detailFields": ["format","condition","holderPersonaId","queuedPersonaIds","dueDate"] } }

// Camera Club — photo-thumbnail tiles for gear
{ "cardSurfaceFamily": "camera-gear", "archetype": "stateMachineGrid",
  "theme": { "accent": "#22303A", "palette": "photo-visual" },
  "workflowType": "gear-loan-request",
  "stateMachineGrid": { "itemTemplate": "photoThumbnail",
    "filters": { "field": "gearType", "mode": "chips" } } }

// Garden Club — 8-state tool loan/giveaway
{ "cardSurfaceFamily": "garden-tools", "archetype": "stateMachineGrid",
  "theme": { "accent": "#3F7A44", "palette": "seasonal" },
  "workflowType": "garden-tool-loan-giveaway",
  "stateMachineGrid": { "filters": { "field": "category", "mode": "chips" },
    "custody": { "enabled": true, "showHolder": true, "redactHolderUntil": "reserved" },
    "detailFields": ["condition","holderPersonaId","queuedPersonaIds","dueDate","damageReport"] } }
// Tabletop matches the marketplace .jsonc example (iconTile). The states/transitions themselves
// live in workflowType, not here — this block only styles the grid + declares which data shows.
```

### 2.3 `formEntry` (NEW)

**Customization-field schema — revised 2026-07-04.** Fields are no longer redeclared here at all.
`instanceDataSchema` (§9a) is the single source of truth for a field's type/required/storage; the
current workflow **state**'s `editableFields` (§9a-i) says which subset is editable right now. A
`formEntry` binding only configures genuinely presentational concerns:
```jsonc
{
  "cardSurfaceFamily": "<key>",
  "archetype": "formEntry",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },
  "workflowType": "<workflow-id>",     // supplies instanceDataSchema + the current state's editableFields
  "formEntry": {
    // NO "fields[]" here — derived from currentState.editableFields, in instanceDataSchema's own
    // declared order. This section only arranges what's already been declared elsewhere.
    "sections": [
      { "label": "Photos", "fieldKeys": ["photo"] },
      { "label": "Details", "fieldKeys": ["title","category","condition","description"] }
    ],
    "masterDetail": null,              // OR { "childCollectionKey": "options", "childFields": [ ... ] }
    "perFieldPrivacy": false,          // true → editable fields ALSO get a public/private toggle (Mosque care)
    "submitLabel": "Submit",
    "draftable": true                  // save-draft before submit
  }
}
```
`instanceDataSchema.<field>.type` now includes `audienceSelector` (§3c) alongside
`text|textarea|number|date|image|select|personaId|money|boolean` — a field that sets the created
instance's audience (`all`/`selected-many`/`individual` → `audienceScope`/`invitedPersonaIds`), the
mechanism that makes 1-to-all/1-to-selected/1-to-1 distribution one workflow instead of three.

**Per-community instances — now just `theme` + `workflowType` + presentational grouping, since the
field list itself lives in each `workflowType`'s `instanceDataSchema`/`states.<state>.editableFields`:**
```jsonc
// Book Club — nomination (fields declared once in book-nomination's instanceDataSchema; this form
// just says how to group them)
{ "cardSurfaceFamily": "bookclub-nominate", "archetype": "formEntry",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" },
  "workflowType": "book-nomination",
  "formEntry": { "submitLabel": "Nominate" } }

// Mosque — care request WITH per-field privacy
{ "cardSurfaceFamily": "mosque-care-submit", "archetype": "formEntry",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" },
  "workflowType": "mosque-care-request",
  "formEntry": { "submitLabel": "Submit request", "perFieldPrivacy": true } }

// Youth Soccer — registration, one binding per guidedProcess step (each step is a state with its
// own editableFields — see §9a-i and the guidedProcess entry below)
{ "cardSurfaceFamily": "soccer-registration-form", "archetype": "formEntry",
  "theme": { "accent": "#2F7D32", "palette": "team" },
  "workflowType": "soccer-guardian-join-approval",
  "formEntry": { "submitLabel": "Continue" } }

// Camera Club — image-first critique submission
{ "cardSurfaceFamily": "camera-critique-submit", "archetype": "formEntry",
  "theme": { "accent": "#22303A", "palette": "photo-visual" },
  "workflowType": "critique-submission",
  "formEntry": { "submitLabel": "Submit for critique",
    "sections": [ { "label": "Photo", "fieldKeys": ["photo"] },
                  { "label": "Details", "fieldKeys": ["title","prompt","consent"] } ] } }
// HOA arch-request, Garden plant/tool listing, Chess propose-match all follow the same shape —
// their fields live in their own workflowType's instanceDataSchema, not redeclared here. "List your
// own item" marketplace sub-flows are formEntry producing a stateMachineGrid instance, per §3d.
```

### 2.4 `guidedProcess` (NEW)

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>",
  "archetype": "guidedProcess",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },
  "workflowType": "<workflow-id>",
  "guidedProcess": {
    "positionIndicator": true,
    "steps": [
      { "id": "join",    "label": "Join request", "surface": "soccer-registration-form" },
      { "id": "waiver",  "label": "Sign waiver",   "gate": "documentAcknowledged:soccer-waiver" },
      { "id": "payment", "label": "Pay fee",       "gate": "paymentComplete:soccer-registration-payment" },
      { "id": "roster",  "label": "Confirm roster","gate": "reviewerApproved" }
    ],
    "resumeDraft": true                // can leave and resume mid-wizard
  }
}
```
`gate` per step is the enforcement — a step can't be reached until its predecessor's gate passes
(this is what makes "can't pay before signing the waiver" declarative, not hand-coded). Each step
either references a `formEntry` surface or a `gate` condition.

**Per-community instances:**
```jsonc
// Youth Soccer — the canonical registration wizard
{ "cardSurfaceFamily": "soccer-registration", "archetype": "guidedProcess",
  "theme": { "accent": "#2F7D32", "palette": "team" },
  "workflowType": "soccer-guardian-join-approval",
  "guidedProcess": { "positionIndicator": true, "resumeDraft": true, "steps": [
    { "id": "join", "label": "Join request", "surface": "soccer-registration-form" },
    { "id": "waiver", "label": "Sign waiver", "gate": "documentAcknowledged:soccer-waiver" },
    { "id": "payment", "label": "Pay fee", "gate": "paymentComplete:soccer-registration-payment" },
    { "id": "roster", "label": "Confirm roster", "gate": "reviewerApproved" } ] } }

// Chess Club — propose→confirm as the proposer experiences it
{ "cardSurfaceFamily": "chess-propose", "archetype": "guidedProcess",
  "theme": { "accent": "#2E2E2E", "palette": "board-tournament" },
  "workflowType": "chess-match-meetup",
  "guidedProcess": { "positionIndicator": true, "steps": [
    { "id": "propose", "label": "Propose match", "surface": "chess-propose-form" },
    { "id": "await", "label": "Await response", "gate": "opponentResponded" },
    { "id": "confirm", "label": "Confirm", "gate": "bothAccepted" } ] } }
```

### 2.5 `statusTimeline` (narrowed)

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "statusTimeline",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" }, "workflowType": "<workflow-id>",
  "statusTimeline": {
    "steps": ["submitted","under-review","changes-needed","approved","denied","reopened"],
    "showAuditTrail": true,
    "comments": true,
    "checkpoints": ["document","payment"],     // milestones shown inline on the timeline
    "reviewerActions": ["approve","reject","request-changes"], // role: receiver
    "requesterActions": ["withdraw","reopen","appeal"]         // role: actor
  }
}
```

**Per-community instances:**
```jsonc
// HOA — architectural request (dual requester/reviewer, full audit)
{ "cardSurfaceFamily": "hoa-request-status", "archetype": "statusTimeline",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "workflowType": "hoa-architectural-request",
  "statusTimeline": { "showAuditTrail": true, "comments": true,
    "checkpoints": ["document","payment"],
    "reviewerActions": ["approve","reject","request-changes"],
    "requesterActions": ["withdraw","reopen","appeal"] } }

// Chess Club — two-party match negotiation (both sides watch)
{ "cardSurfaceFamily": "chess-negotiation", "archetype": "statusTimeline",
  "theme": { "accent": "#2E2E2E", "palette": "board-tournament" },
  "workflowType": "chess-match-meetup",
  "statusTimeline": { "steps": ["proposed","countered","accepted","declined"],
    "reviewerActions": ["accept","decline","suggest-new-time"],
    "requesterActions": ["cancel","reschedule"] } }
// Youth Soccer registration-status = reviewer side of the guidedProcess above (missing-items list);
// Camera Club critique = lightweight draft/submitted/reviewed.
```

### 2.6 `paymentCheckout`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "paymentCheckout",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" }, "workflowType": "<payment-workflow-id>",
  "paymentCheckout": {
    "amountField": "amountLabel", "purposeField": "purpose",
    "states": ["due","paid","failed"],
    "recurring": false,               // subscription/recurring plan support
    "receipt": true,
    "alternateActions": ["retry","refund","manage-subscription"],
    "privacyAware": false             // Mosque donation → true (amount masked per donor pref)
  }
}
```

**Per-community instances:**
```jsonc
// Mosque — privacy-aware recurring donation
{ "cardSurfaceFamily": "mosque-donation", "archetype": "paymentCheckout",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" },
  "workflowType": "mosque-donation-payment",
  "paymentCheckout": { "amountField": "amountLabel", "purposeField": "fund",
    "recurring": true, "privacyAware": true,
    "alternateActions": ["retry","manage-subscription","open-receipt"] } }

// HOA — dues with autopay
{ "cardSurfaceFamily": "hoa-dues", "archetype": "paymentCheckout",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "workflowType": "hoa-dues-payment",
  "paymentCheckout": { "recurring": true, "alternateActions": ["retry","refund","manage-subscription"] } }
// Tabletop dues + Youth Soccer registration = same shape, recurring:false, privacyAware:false.
```

### 2.7 `documentLibrary`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "documentLibrary",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" }, "workflowType": "<document-workflow-id>",
  "documentLibrary": {
    "categories": ["<folder1>","<folder2>"],   // library folder structure
    "openModes": ["embedded","external"],       // embedded viewer + external app open
    "acknowledgement": true,                     // require read-acknowledgement
    "versioning": true,
    "accessRequest": true,                       // gated docs → request-access flow
    "detailFields": ["version","date","source"]
  }
}
```

**Per-community instances:**
```jsonc
// HOA — governing docs, acknowledgement required
{ "cardSurfaceFamily": "hoa-governing-docs", "archetype": "documentLibrary",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "workflowType": "hoa-member-document",
  "documentLibrary": { "categories": ["Bylaws","Covenants","Meeting minutes"],
    "acknowledgement": true, "accessRequest": true } }

// Book Club — reading materials tied to current cycle
{ "cardSurfaceFamily": "bookclub-reading", "archetype": "documentLibrary",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" },
  "workflowType": "book-reading-material",
  "documentLibrary": { "categories": ["Guides","Author links","Excerpts"], "acknowledgement": false } }
// Mosque (khutbah/forms/policies), Youth Soccer (waivers, ack:true), Chess (rules) follow the same
// shape, differing only in categories[] + whether acknowledgement is required.
```

### 2.8 `notificationInbox`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "notificationInbox",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" }, "workflowType": "<announce-workflow-id>",
  "notificationInbox": {
    "composer": { "enabled": true, "audienceOptions": ["all","members"], "schedulable": true },
    "readState": true, "deliveryReceipts": true,
    "senderLabel": "<who>",
    "privacySafe": false               // Mosque neutral care notices → true (never leak protected)
  }
}
```

**Per-community instances:**
```jsonc
// Mosque — audience selector + privacy-safe neutral notices
{ "cardSurfaceFamily": "mosque-announce", "archetype": "notificationInbox",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" },
  "workflowType": "mosque-announcement",
  "notificationInbox": { "composer": { "enabled": true, "audienceOptions": ["all","members","volunteers"], "schedulable": true },
    "senderLabel": "Masjid Admin", "privacySafe": true } }

// HOA — board → homeowners
{ "cardSurfaceFamily": "hoa-owner-notices", "archetype": "notificationInbox",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "workflowType": "hoa-owner-notification",
  "notificationInbox": { "composer": { "enabled": true, "audienceOptions": ["all-homeowners"], "schedulable": true }, "senderLabel": "HOA Board" } }
// Book Club selection-publish + Youth Soccer reminders = same shape, different sender/audience.
```

### 2.9 `protectedDetail`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "protectedDetail",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" }, "workflowType": "<workflow-id>",
  "protectedDetail": {
    "publicFields": ["summary","urgency"],       // visible to any authorized viewer
    "privateFields": ["contact","details"],      // visible only per visibleTo rule
    "visibleTo": "assignedRecipient",            // "assignedRecipient" | "owner" | "consentedRoles"
    "showRedactionReason": true,                 // show WHY a field is hidden, not just blank
    "consentModel": null                         // Youth Soccer minor data → consent-scope object
  }
}
```

**Per-community instances:**
```jsonc
// Mosque — care request public/private split
{ "cardSurfaceFamily": "mosque-care-detail", "archetype": "protectedDetail",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" },
  "workflowType": "mosque-care-request",
  "protectedDetail": { "publicFields": ["summary","urgency"], "privateFields": ["need","contact"],
    "visibleTo": "assignedRecipient", "showRedactionReason": true } }

// Youth Soccer — minor-data redaction with consent scope
{ "cardSurfaceFamily": "soccer-minor-detail", "archetype": "protectedDetail",
  "theme": { "accent": "#2F7D32", "palette": "team" },
  "workflowType": "soccer-minor-redaction",
  "protectedDetail": { "publicFields": ["playerName","team"], "privateFields": ["dob","medicalNotes","guardianContact"],
    "visibleTo": "consentedRoles", "showRedactionReason": true,
    "consentModel": { "scope": ["coach"], "excludes": ["medicalNotes"] } } }
// Garden/Book Club use the lighter form: privateFields:["holder"], visibleTo:"owner", masked until claim/handoff.
```

### 2.10 `dashboard`

**Customization-field schema:**
```jsonc
{
  "cardSurfaceFamily": "<key>", "archetype": "dashboard",
  "theme": { "accent": "#RRGGBB", "palette": "<name>" },
  "dashboard": {
    "density": "medium",               // default card density: minimized | medium | expanded
    "tapToExpand": true,
    "pinsByPersona": {                 // THE per-persona field — different pins per role
      "<persona-a>": ["<surfaceKey1>","<surfaceKey2>"],
      "<persona-b>": ["<surfaceKey3>","<surfaceKey4>"]
    }
  }
}
```

**Per-community instances:**
```jsonc
// HOA
{ "cardSurfaceFamily": "hoa-home", "archetype": "dashboard",
  "theme": { "accent": "#3A5A78", "palette": "civic" },
  "dashboard": { "density": "medium", "tapToExpand": true, "pinsByPersona": {
    "homeowner": ["hoa-dues","hoa-request-status","hoa-governing-docs"],
    "board": ["hoa-decision-queue","hoa-owner-notices","hoa-facilities"] } } }

// Chess Club — the 3-composited-types Home
{ "cardSurfaceFamily": "chess-home", "archetype": "dashboard",
  "theme": { "accent": "#2E2E2E", "palette": "board-tournament" },
  "dashboard": { "pinsByPersona": {
    "player": ["chess-matches","chess-open-challenge","chess-standings"],
    "organizer": ["chess-pairing-queue","chess-disputes","chess-export"] } } }
```

### 2.11 Thin/specialized archetypes (schema + the one/two communities that use them)

```jsonc
// votePoll — Book Club only
{ "cardSurfaceFamily": "bookclub-ballot", "archetype": "votePoll",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" }, "workflowType": "book-vote",
  "votePoll": { "candidateSource": "book-nomination", "deadline": true, "liveResults": true,
    "winningState": true, "tieHandling": "runoff", "voteActions": ["cast","change","clear"] } }

// volunteerRoster — Mosque (Garden reuses the same shape)
{ "cardSurfaceFamily": "mosque-volunteer", "archetype": "volunteerRoster",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" }, "workflowType": "mosque-volunteer-signup",
  "volunteerRoster": { "capacityMeter": true, "rosterVisible": true, "protectedContact": true,
    "shiftFields": ["role","time","openSpots"] } }

// searchAiAnswer — Mosque + Book Club
{ "cardSurfaceFamily": "mosque-search", "archetype": "searchAiAnswer",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" }, "workflowType": "mosque-search-ai-citation",
  "searchAiAnswer": { "citations": true, "permissionGuardedSources": true,
    "actions": ["refine","hide-source","report-stale"] } }

// exportWizard — HOA/Garden/BookClub/Soccer/Chess (Soccer sets redactionMandatory)
{ "cardSurfaceFamily": "soccer-export", "archetype": "exportWizard",
  "theme": { "accent": "#2F7D32", "palette": "team" }, "workflowType": "soccer-export-metadata",
  "exportWizard": { "steps": ["scope","redaction-preview","checksum","download"],
    "schemas": ["roster","registration"], "redactionMandatory": true, "rollback": true } }

// table (+rankingMode) — Chess Club standings. Columns REFERENCE instanceDataSchema keys — they
// don't redeclare type; "sortable" here must match sortable:true on that key in the schema (§9c
// validator), and re-sorting resets queryInstances' pagination cursor (§4b).
{ "cardSurfaceFamily": "chess-standings", "archetype": "table",
  "theme": { "accent": "#2E2E2E", "palette": "board-tournament" }, "workflowType": "chess-match-result",
  "table": { "columns": [
      { "key": "rank", "columnLabel": "#", "sortable": true },
      { "key": "player", "columnLabel": "Player", "sortable": false },
      { "key": "score", "columnLabel": "Score", "sortable": true },
      { "key": "delta", "columnLabel": "±", "sortable": true } ],
    "defaultSort": { "key": "rank", "direction": "asc" },
    "rankingMode": true, "liveUpdate": true } }

// table — Youth Soccer roster, coach's view of the SAME instances a guardian sees as
// stateMachineGrid cards (§4b's "same data, two archetypes for two roles" pattern)
{ "cardSurfaceFamily": "soccer-roster-table", "archetype": "table",
  "theme": { "accent": "#2F7D32", "palette": "team" }, "workflowType": "soccer-team-roster",
  "table": { "columns": [
      { "key": "playerName", "columnLabel": "Player", "sortable": true },
      { "key": "ageGroup", "columnLabel": "Age group", "sortable": true },
      { "key": "waiverStatus", "columnLabel": "Waiver", "sortable": true } ],
    "defaultSort": { "key": "playerName", "direction": "asc" } } }

// singleItem (preference toggle) — Mosque donor visibility
{ "cardSurfaceFamily": "mosque-donor-visibility", "archetype": "singleItem",
  "theme": { "accent": "#1E6E4C", "palette": "mosque-green" }, "workflowType": "mosque-donor-visibility",
  "singleItem": { "mode": "preferenceToggle", "options": ["public","anonymous","restricted"],
    "contextFields": ["amount","fund"] } }

// discussionThread — Book Club (every community's Messages tab uses the default shape)
{ "cardSurfaceFamily": "bookclub-discussion", "archetype": "discussionThread",
  "theme": { "accent": "#7A4B2B", "palette": "book-forward" }, "workflowType": "book-discussion-message",
  "discussionThread": { "composer": true, "readState": true, "moderation": ["mute","archive","block"],
    "attachments": true, "contextBinding": "currentBook" } }
```

---

## How to read this for the field-inventory goal

Every archetype exposes exactly two customization surfaces:
1. **The archetype config block** (`"<archetype>": { ... }`) — layout/behavior fields specific to that
   container (columns, itemTemplate, steps, publicFields, pinsByPersona, …).
2. **`theme` + `workflowType`** — brand tokens, and the pointer to the state machine +
   `instanceDataSchema` (§3/§9a) that supplies the actual data fields, states, transitions, and per-
   field display icons/labels.

Community customization = setting those fields. Persona customization = either guard-filtered
transitions (same block) or `pinsByPersona`/role-keyed `renderBindings` (the two archetypes that
change surface per persona: `dashboard` pins, and the `guidedProcess`↔`statusTimeline`/`protectedDetail`
split). No archetype requires a community to write new widget code — only JSON field values.
