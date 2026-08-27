---
spec: 4
doc_version: 1.0.0
status: implemented
last_verified: 2026-08-27
audience: llm-agent
derived_from:
  - docs/references/archetypes/CONTRACTS.md
  - docs/references/reference/permissions.md
  - app/packages/core/loom_workflow_engine/lib/src/archetypes/archetype_resolver.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part28_engine_native_calendar_surface.dart
---

# `calendar`

A dated item on a schedule that nobody RSVPs to: a prayer time, a fixture, a bin collection, a
volunteer shift, a rehearsal.

Contract summary: [`CONTRACTS.md`](./CONTRACTS.md). Permission derivation:
[`../reference/permissions.md`](../reference/permissions.md) §4.

## 1. What it is, and what `event-rsvp` is

The two are the same archetype with one difference: `event-rsvp` records who is coming, and
`calendar` does not.

| | `calendar` | `event-rsvp` |
|---|---|---|
| Actions | `view` `create` `edit` `cancel` `reopen` `set_reminder` `deliver_reminder` `propose_change` `record_outcome` | the same nine, **plus** `respond` `withdraw_response` `join_waitlist` |
| Bookkeeping | `reminderFanIds` | `reminderFanIds`, `goingFanIds`, `maybeFanIds`, `notGoingFanIds`, `waitlistFanIds` |
| Renders as | the calendar surface | the calendar surface |

**Choose by whether attendance is recorded, not by whether the thing is an "event".** A Friday prayer
is an event in every ordinary sense and takes no RSVPs, so it is a `calendar`. A book club meeting
with eight seats is an `event-rsvp`.

**The absence of the three RSVP actions is the whole content of this family.** A closed vocabulary is
a statement about what a workflow *can* do, read literally by permission derivation. Modelling a
prayer time as `event-rsvp` would make `event_rsvp.respond` a grantable permission on it — legal, and
meaningless.

## 2. Placement

**A `calendar` workflow can live in any tab.** The tab id is only the join key between a tab and its
bindings; the bound archetype decides the renderer. A community may call the tab `prayer-times`,
`fixtures`, `bin-collection` or anything else, and it renders a month grid and agenda.

Two consequences worth stating, because both have caught people:

- **A tab called `calendar` is not automatically a calendar.** If its bindings are `formEntry`, it
  renders a list. The name has never been what decides.
- **A tab must bind exactly one tab-native archetype to get that archetype's surface.** A tab mixing
  `calendar` and `formEntry` bindings falls back to the generic list for *all* of them — the whole
  tab, not just the odd one out. Masjid Nur lost its month grid this way for a long time, silently,
  because one volunteer-shift workflow shared the tab. If a community needs both, give them separate
  tabs.

`home` and `messages` are the only tab ids the app shell reserves. Everything else is the
community's.

## 3. Required fields

A `calendar` item **must** declare these two, spelled exactly so:

```jsonc
"instanceDataSchema": {
  "eventDate": { "type": "date", "required": true, "writableBy": "formEntry" },
  "eventTime": { "type": "text", "writableBy": "formEntry" }
}
```

The calendar surface reads those two keys to place an item on the grid. This is a contract, not a
convention: a workflow that calls its date `shiftDate` is not placeable, and the failure is silent —
the item either vanishes from the schedule or takes the whole tab down to a list.

Optional, and read when present:

| Field | Meaning |
|---|---|
| `eventEndDate` | A multi-day item occupies every date from `eventDate` through this one |
| `allDay` | `true` suppresses the time requirement; without it a malformed `eventTime` is an error |

## 4. Bookkeeping the archetype owns

| Field | Maintained by |
|---|---|
| `reminderFanIds` | `set_reminder` |

A community declares none of it and writes no idempotence guard against it.

**No attendance arrays.** A community finding itself wanting `goingFanIds` on a `calendar` item has
chosen the wrong family; the fix is to change the family, not to declare the array by hand.

## 5. `set_reminder` versus `deliver_reminder`

Identical to `event-rsvp`'s, and for the same reason. `set_reminder` is a member asking to be
reminded. `deliver_reminder` is the platform sending it, applied through the `dueNotifications({asOf})`
sweep, and **no role is ever granted it** — so it renders as no button anywhere, by §1's ordinary
derivation rather than any special case.

## 6. Worked example — a prayer time

```jsonc
"masjid-prayer-time": {
  "initialState": "scheduled",
  "visibility": { "default": "membersOnly" },
  "states": {
    "scheduled": { "label": "Scheduled" },
    "cancelled":  { "label": "Cancelled", "isTerminal": false }
  },
  "renderBindings": [
    { "states": ["scheduled", "cancelled"], "audience": "any",
      "tabId": "prayer-times", "cardSurfaceFamily": "calendar",
      "bindingKind": "primary",
      "actions": [
        { "kind": "create", "label": "Add prayer time", "byRoleIds": ["masjid-admin"],
          "scope": "tab", "presentation": "fab" }
      ] }
  ],
  "transitions": [
    { "id": "correct-prayer-time", "action": "edit", "from": ["scheduled"], "to": null,
      "guard": { "allowedRoleIds": ["masjid-admin"] } },
    { "id": "cancel-prayer-time", "action": "cancel", "from": ["scheduled"], "to": "cancelled",
      "guard": { "allowedRoleIds": ["masjid-admin"] } },
    { "id": "restore-prayer-time", "action": "reopen", "from": ["cancelled"], "to": "scheduled",
      "guard": { "allowedRoleIds": ["masjid-admin"] } },
    { "id": "remind-me", "action": "set_reminder", "from": ["scheduled"], "to": null,
      "guard": { "allowedRoleIds": ["community-member"] } }
  ],
  "instanceDataSchema": {
    "title":     { "type": "text", "required": true, "writableBy": "formEntry" },
    "eventDate": { "type": "date", "required": true, "writableBy": "formEntry" },
    "eventTime": { "type": "text", "writableBy": "formEntry" }
  }
}
```

### Permissions this derives

| Role | Permissions |
|---|---|
| `masjid-admin` | `calendar.edit`, `calendar.cancel`, `calendar.reopen` |
| `community-member` | `calendar.set_reminder` |

Nothing above names a permission. Every one derives from `action` + `allowedRoleIds`.

## 7. Open

- **Mixed-archetype tabs still degrade wholesale.** A tab binding `calendar` alongside anything
  tab-native falls back to the generic list for the entire tab. Separate tabs are the workaround, and
  a per-binding surface selection would be the fix.
- **`record_outcome` has no shipped use yet.** It is in the vocabulary because a schedule that cannot
  record what happened is half a record, but no community declares it, so its bookkeeping is
  unspecified.
