**Workflow:** `book-export-metadata` in Neighborhood Book Club
**Outcome:** Both halves of the proof standard were met — signed in as `fan-book-organizer-1`, a new export record was created through the real UI and driven `draft → redaction-previewed → ready → transferring → transferred`, with every step independently confirmed in Postgres.

**Package identity:** `Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 = 71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`
- `cmp`-identical to the locked reference copy `docs/references/communities/Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc`

**Date:** 2026-09-20 (device 01:07–01:12 PDT = 08:09–08:12 UTC)

---

## Identity

| | |
|---|---|
| Keycloak account | `loom-book-organizer-1` |
| Fan id | `fan-book-organizer-1` |
| Role | `book-organizer` (Organizer) |

Established three independent ways rather than assumed:

1. **The app's own "Account role and permissions" sheet** read *"Signed in as Book Organizer 1 … ID: fan-book-organizer-1"*, with **Organizer** selected — the role whose description is literally *"Curates the ballot, publishes the selection, manages meetings, and exports club metadata."*
2. **A password-grant token request** against `loom-test-client` returned **HTTP 200** with `preferred_username=loom-book-organizer-1`, `fanId=fan-book-organizer-1`. The password `LoomTest123!` worked exactly as documented — no shell-escaping artifact.
3. **The row itself** carries `created_by_fan_id = fan-book-organizer-1`, which is the authoritative record of whose token wrote it.

A fourth, weaker corroboration falls out of the package: `scopeDisplay` is
`if($viewer == ownerFanId, scope, 'Protected export scope')`, and the card rendered the **real**
scope rather than the protected placeholder — so the viewer was the owner.

The app already held a session for this identity, so no Keycloak form appeared and **no credential
was created or reset**. Because a stored session is not by itself proof of identity, the three
checks above were run instead of trusting the green state. No identity switch was needed, so
Chrome/app data were deliberately **not** cleared.

The token in (2) was used **only** to verify identity. Every transition below was fired by tapping
the real UI; nothing was driven through the API.

## Baseline — measured, not trusted

Queried before touching the device:

- `book-export-metadata` rows: **0**.
- **Control**, so an empty result means absent rather than a broken query: six sibling `book-*` types
  were present (`book-discussion-message`, `book-meeting-rsvp`, `book-meeting-rsvp-response`,
  `book-nomination`, `book-selection-publish`, `book-vote` — 1 row each).
- Whole table: **97** instances (→ **98** after this run).
- `book-export-metadata` is **published at `version 4`**, so `createInstance` could not silently no-op.

The brief's hint of "about 0 rows" was right for this type. The row is distinguished by its own
instance id and `created_at`, not by the count moving.

## What was driven, in order

All on the **Admin** tab (`tabId: "admin"`, `cardSurfaceFamily: "exportWizard"`), as Organizer.

| # | UI action | State after | Evidence |
|---|---|---|---|
| 0 | FAB → **New export**, `scope` + `redactionNotes` entered, **Create** | `draft` | card rendered with `Preview redaction` |
| 1 | **Preview redaction**, `redactionStatus` chip = `passed` | `redaction-previewed` | `Redaction: Passed`, `previewedAt 08:10:03.492311Z` |
| 2 | **Confirm export ready** | `ready` | `Export ready; checksum pending platform service`, `readyAt 08:10:44.695887Z` |
| 3 | **Download export** | `ready` (unchanged) | refused with an explicit message — see "Observation" below |
| 4 | **Start transfer** | `transferring` | `Organizer confirmed transfer start`, `transferStartedAt 08:11:49.617277Z` |
| 5 | **Confirm transferred** | **`transferred`** | `Transfer confirmed; platform identifiers pending`, `transferredAt 08:12:06.525882Z` |

Final UI state: a green **`Transferred`** badge, with only the destructive `Rollback transfer`
remaining. **Neither destructive exit was taken** — `cancel-export` and `cancel-reviewed-export`
were never tapped, and `Rollback transfer` was left alone.

### `redactionStatus` renders as a chip, not a text field

The brief's main warning was that `redactionStatus` is a `required` form input that must read
exactly `passed`, and that `adb shell input text` truncates silently. **On this surface the input
renders as two selectable chips (`passed` / `needs-changes`), so the value was selected, not
typed**, and the truncation hazard does not arise for this field at all. It was verified against the
stored row regardless: `redactionStatus = 'passed'`, `length = 6`.

That matters beyond this row: every forward transition here is guarded
`formula: "redactionStatus == 'passed'"`, and all three of them (`confirm-export-ready`,
`start-transfer`, `confirm-transfer`) became available exactly when that field was set — so the
guard was observed working in the permitting direction.

### Free-text fields were verified against the row, not the screen

`scope` and `redactionNotes` **were** typed, and the soft keyboard did collapse the creation
dialog's fields to zero height (the documented IME trap); the keyboard was dismissed with the IME
chevron rather than `keyevent 111`, which can close the whole dialog. Both fields then displayed
horizontally scrolled, showing only a plausible tail — the exact shape that has hidden a truncated
value before. Both were therefore settled against the database, and both stored in full:

- `scope` = `B25-Sep20-nominations-and-vote-history`
- `redactionNotes` = `Exclude-member-emails-and-addresses`

## The database half

```
instance_id       community_neighborhood_book_club_book-export-metadata_tz2dk7ife3hi
community_id      community_neighborhood_book_club
workflow_type     book-export-metadata
created_by_fan_id fan-book-organizer-1
current_state     transferred
created_at        1789891745035  (2026-09-20 08:09:05 UTC)
```

Full `instance_data` as stored:

```json
{
    "scope": "B25-Sep20-nominations-and-vote-history",
    "readyAt": "2026-09-20T08:10:44.695887Z",
    "ownerFanId": "fan-book-organizer-1",
    "transferId": "bdddb782-c293-4b15-9bc1-533fa7079753",
    "previewedAt": "2026-09-20T08:10:03.492311Z",
    "statusMessage": "Transfer confirmed; platform identifiers pending",
    "transferredAt": "2026-09-20T08:12:06.525882Z",
    "redactionNotes": "Exclude-member-emails-and-addresses",
    "redactionStatus": "passed",
    "transferStartedAt": "2026-09-20T08:11:49.617277Z"
}
```

**Do the two halves agree? Yes, exactly.** The terminal state the device showed (`Transferred`) is
the `current_state` in the row; `created_by_fan_id` is the identity that was authenticated and
driven; and all four timestamps rendered on the card are byte-identical to the stored values. The
`ownerFanId` confirms the binding's `prefill: { ownerFanId: "$actor" }` resolved to the real
authenticated fan, not a role-id-shaped string.

## The `audience: "actor"` binding renders — the regression this row was watching for

`draft` and `redaction-previewed` bind `audience: "actor"` only. Before `8d33a8af` the remote
instance projection omitted creator identity, so those cards rendered for **nobody, including their
own creator**, and the sibling `book-selection-publish` row was correctly recorded as not proven.

**No such regression here.** The `draft` card rendered immediately on creation with its
`Preview redaction` action present and tappable, and the `redaction-previewed` card rendered in
full. Taking the four facts the brief asked to be kept distinct: the card was **present**, the
action was **present**, the action was **enabled**, and the state **persisted**. All four held at
every step.

## Observation — `download-export` refuses, loudly and honestly (not a defect, not a blocker)

Step 3 above. Tapping **Download export** did not advance anything; the card displayed:

> Export download is unavailable until this app session generates a bundle.

Verified against the database rather than inferred from the screen: `downloadedAt` stayed **NULL**
and `statusMessage` was **unchanged**, so the transition genuinely did not fire. State remained
`ready`.

The mechanism, read rather than assumed —
`part36_engine_native_marketplace_surface.dart:2154` catches a named
`_ExportBundleHandleUnavailable` and routes it to `_finishAfterExportFailure` with that message.
This is a **deliberate, named, loud refusal**, not a silent fallback and not a swallowed exception.

Recording it as an observation rather than a finding, for three reasons:

1. `download-export` declares `"to": null` — it stamps `downloadedAt` in place and **gates nothing**.
   The path to `transferred` runs through `start-transfer`, which was unaffected.
2. The unwritten `checksum` field is `writableBy: "platform"` with `platformSource: "checksum"`, and
   the workflow's own authored `statusMessage` says *"checksum pending platform service"*. The
   checksum service is one of the four known-missing platform services, so this is the documented
   boundary being honest about itself — the field is visibly unwritten rather than filled with a
   placeholder.
3. Nothing here contradicts the package or the product doc.

Worth a line in a future sweep only as: *the one organizer-visible action on this workflow that
cannot complete today is `download-export`, and it says so plainly.*

## Environment

- `loom-workflow-service:1.0.9`, `loom/app-access:0.3.11`; all six `loom` pods `1/1 Running`.
- No `403`, no `unknown_permission_id`, no error toast at any step.
- No crash or ANR during the run: focus stayed on `com.example.loom_communities_demo/.MainActivity`
  throughout, `FATAL EXCEPTION`/`ANR in` count was **0** over the run's logcat window, and the only
  ANR traces on disk are from 2026-09-11 and 2026-09-12 — days old and unrelated.
- No application code, community JSON, or tracker was modified. This manifest is the only file added.

## Scope note

Book Club's regeneration is held by user decision (row-247). Nothing here proposes a package change;
no defect was found that would need one.
