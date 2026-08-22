# Shared Item Marketplace, Loan, And Giveaway Surface

Surface family id: `equipment-loan`

The family id is retained for compatibility with existing Demo App and API mappings, but the product
surface is generic: it covers any community-owned or member-owned item that can be discovered,
borrowed, queued for, tracked, returned, or permanently given away.

## Supported Interactions

- Browse and search available items, filter by category/availability/location/condition/owner/use
  policy, inspect item details, and discover what can be borrowed, reserved, queued for, claimed, or
  taken as a giveaway.
- Member lists personal equipment, community steward lists shared inventory, lender approves/declines
  loans, borrower requests/reserves, joins/leaves a queue, schedules pickup, checks item out, extends
  loan, returns item, marks damaged/lost/overdue, cancels, and sees availability.
- Listing owner can create, modify, pause, reactivate, or delist an item, update availability windows,
  photos, condition, pickup policy, deposit/fee, and loan/giveaway mode.
- Track the current holder, borrower/claim queue, custody history, condition checks at checkout/return,
  return reminders, overdue state, dispute/loss/damage resolution, and privacy-scoped contact handoff.
- Support personally owned items, community-owned inventory, short-term loans, deposits/fees, and
  giveaway/free-item flows where an owner is giving an item away permanently.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Browser/borrower/recipient | `community.surface.equipment.browse` | Search listings, inspect details, request loan, reserve, join queue, claim giveaway, view own holder/return status. |
| Lender/listing owner | `community.surface.equipment.list` | List personal item, edit/pause/reactivate/delist listing, approve/decline, schedule pickup, see queue, mark returned/damaged/lost. |
| Item steward/librarian | `community.surface.equipment.admin` | Moderate inventory, queues, custody, visibility, disputes, deposits, categories, and giveaway rules. |

## Custom Experience Guidance

Customize item category, condition, photos, deposit/fee, pickup windows, loan duration, queue policy,
renewal rules, privacy-safe contact, care instructions, return checklist, giveaway eligibility, and
discovery filters.

Examples:

- A tennis, pickleball, or soccer community can let members browse racquets, balls, pinnies, cones,
  or goals by size/condition, join a queue, see who currently has an item when policy allows, and
  reserve the next available slot.
- A camera club can browse lenses, tripods, lights, and backdrops by mount/brand/condition; list
  personal gear; approve a borrower; track checkout, return, and damage.
- A neighborhood book, DVD, board-game, or toy library can show title, format, owner/library shelf,
  current holder, due date, queue position, renew/return actions, and replacement/lost status.
- A community group can list party supplies, folding tables, chairs, camping gear, tools, or an old set
  of wine glasses as a giveaway with pickup instructions, claim/transfer state, and closed listing.
- A mosque, HOA, school, or club can manage shared projectors, microphones, sports kits, keys, tables,
  or facility equipment with steward approval, custody history, and return reminders.

Use domain labels in the UI. A book-share extension should say "Browse library", "Join waitlist",
"Return book", and "Currently borrowed by..." rather than exposing "equipment" copy.

## API Support

Requires `CommunityEquipmentLoanApi`: `browseEquipment`, `searchEquipment`, `getEquipmentDetail`,
`listEquipmentListing`, `createEquipmentListing`, `updateEquipmentListing`, `removeEquipmentListing`,
`pauseEquipmentListing`, `reactivateEquipmentListing`, `updateAvailability`, `offerEquipment`,
`offerGiveaway`, `claimGiveaway`, `requestLoan`, `reserveLoan`, `approveLoan`, `declineLoan`,
`joinLoanQueue`, `leaveLoanQueue`, `listLoanQueue`, `advanceLoanQueue`, `schedulePickup`, `checkOut`,
`getCurrentHolder`, `transferCustody`, `listCustodyHistory`, `recordConditionCheck`, `extendLoan`,
`returnItem`, `sendReturnReminder`, `reportOverdue`, `markDamaged`, `reportLostItem`,
`resolveLoanDispute`, `cancelLoan`, `listAvailability`, `listBorrowers`, `privacyScopedContact`,
    `transferGiveawayOwnership`.

## Marketplace State Machine Model

Listing interactions (loan, sale, trade, giveaway) are powered by a community-declared **per-listing
state machine**, not hardcoded framework logic. The App Shell ships a generic, mode-agnostic engine;
each community declares its own states, transitions, persona permissions, and effect flags in the
`experience.marketplace` block.

### Declaring a template (community-level)

A community may declare **templates** under `marketplace.templates` and reference them from listings
via the `template` key, or inline a custom `stateMachine` per listing. A template is a named set of
states and transitions shared by multiple listings:

```json
"marketplace": {
  "templates": {
    "loan": {
      "initialState": "available",
      "states": {
        "available": { "label": "Available", "tone": "positive" },
        "onLoan":    { "label": "On loan",   "tone": "warning", "showsHolder": true, "showsDue": true },
        "queued":    { "label": "Queue open", "tone": "info",    "showsQueue": true }
      },
      "transitions": [
        { "id": "borrow",     "label": "Request loan", "fromStates": ["available"], "to": "onLoan",
          "allowedRoleIds": ["tabletop-member"], "linkedWorkflowId": "tabletop-game-loan",
          "setsHolderToActor": true },
        { "id": "join-queue", "label": "Join queue",   "fromStates": ["onLoan", "queued"],
          "allowedRoleIds": ["tabletop-member"], "addsActorToQueue": true, "requiresActorNotInQueue": true },
        { "id": "leave-queue", "label": "Leave queue",   "fromStates": ["queued"],
          "allowedRoleIds": ["tabletop-member"], "requiresActorInQueue": true, "removesActorFromQueue": true },
        { "id": "return",     "label": "Return",       "fromStates": ["onLoan"],    "to": "available",
          "allowedRoleIds": ["tabletop-member","tabletop-organizer"], "clearsHolder": true }
      ]
    }
  }
}
```

### Listing model

Each listing under `experience.marketplaceListings` may optionally carry:

| Field | Type | Required | Purpose |
| --- | --- | --- | --- |
| `template` | String? | No | Ref to a `marketplace.templates` key. |
| `stateMachine` | Object? | No | Inline `LoomListingStateMachine` overriding the template. |
| `state` | String? | No | Runtime state override (defaults to `initialState`). |

Resolution: `listing.stateMachine ?? community.marketplaceTemplate` (template resolved by name
via `marketplaceTemplateMap[templateName]`). A listing without any machine renders with no actions.

### State fields

| Field | Type | Notes |
| --- | --- | --- |
| `label` | String | Display label for the state (e.g. "Available"). |
| `tone` | String? | `positive`, `warning`, `info`, or `error` — maps to color treatment. |
| `showsHolder` | bool = false | Surfaces `currentHolderLabel` in the detail card. |
| `showsDue` | bool = false | Surfaces `dueLabel`. |
| `showsQueue` | bool = false | Surfaces `queueLength`. |

### Transition fields

| Field | Type | Notes |
| --- | --- | --- |
| `id` | String | Stable key; renders as `marketplace-action-<id>`. |
| `label` | String | Button label. |
| `fromStates` | String[] | States this transition is valid from. |
| `to` | String? | Target state after applying (null = self-transition). |
| `allowedRoleIds` | String[]? | Role IDs permitted to invoke this transition (empty/null = all). |
| `linkedWorkflowId` | String? | Real workflow fired via `onConfirmWorkflow` (resolved from `experience.workflows`). |
| `setsHolderToActor` | bool = false | On apply: sets `currentHolderLabel` to the actor's display name. |
| `clearsHolder` | bool = false | On apply: clears `currentHolderLabel`. |
| `incrementsQueue` | bool = false | On apply: increments `queueLength`. |
| `decrementsQueue` | bool = false | On apply: decrements `queueLength` (floor 0). |
| `removesFromList` | bool = false | On apply: removes the listing from the local grid (used by buy/claim). |

### Action derivation (per persona)

`availableActions(stateId, personaId)` returns all transitions where:
- `stateId ∈ fromStates`
- `roleFor(personaId) ∈ allowedRoleIds` (if `allowedRoleIds` is `null`, all personas pass)

Example: a `borrow` transition gated to `["tabletop-member"]` is *hidden* from organizers when they
view the same listing, even though they share the `return` transition.

### Mode-agnostic: loan / sale / trade / giveaway

All four canonical marketplace modes are **expressible as declared machines** without framework
built-ins:

- **Loan** (Tabletop Club): `available → onLoan → available` with queue, holder, and return.
- **Sale**: `available → purchased` with `removesFromList: true` and a `linkedWorkflowId` for checkout.
- **Trade**: `offered → pending → traded` with different personas permitted at each step.
- **Giveaway**: `available → claimed` with `removesFromList: true`.

Each mode is a community-authored template, not a Dart `enum`. The engine derives actions, applies
effect flags, and resolves linked workflows generically.

### API operations

| Operation | Purpose |
| --- | --- |
| `listListings` | List marketplace listings with current state, persona-filtered. |
| `getListing` | Get a single listing detail. |
| `listTransitions` | List available transitions for a listing from the current persona context. |
| `applyTransition` | Apply a transition, returning the updated listing state. |
| `listCustodyHistory` | List custody/claim history for a listing (existing). |
