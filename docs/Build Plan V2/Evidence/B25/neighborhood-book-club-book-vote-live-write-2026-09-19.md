# B25 live walkthrough — Neighborhood Book Club, `book-vote`

**Workflow:** `book-vote` in Neighborhood Book Club
**Outcome:** Both halves of the proof standard were met — acting as `loom-book-organizer-1`, created a ballot through the Books tab "New ballot" FAB and fired `close-vote` into the terminal state `closed`, confirming the instance id, every stored field, `created_by_fan_id` and the state change directly in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Community:** Neighborhood Book Club (`community_neighborhood_book_club`)
**Date:** 2026-09-19 local / 2026-09-20 UTC
**Device:** `emulator-5554` (Windows-hosted AVD reached over the ssh reverse tunnel to `:5037`)
**Backend:** workflow-service `http://192.168.56.10:30083`, Keycloak `:30082`, app-access `:30080`,
fan-passport `:30081`; all six pods `1/1 Running` throughout.

## Package identity

`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_BookClub_Example.jsonc`

- `specVersion`: `4`
- `skillVersion`: `3.6.0`
- `sha256`: `71e1f0688b7dffd1b29cb90a1066998f003abdf920523cac8dcb535837726957`

Deployed definition: `workflow_definitions` row `community_neighborhood_book_club_book-vote`
at `version 4` (checked before driving, because a `createInstance` naming an unpublished type
returns success and does nothing — that failure mode does not apply here).

## Identity

- Keycloak user `loom-book-organizer-1`, fan id `fan-book-organizer-1`, role `book-organizer`.
- Credential verified independently from this shell before touching the device: a password grant
  against `loom-test-client` returned **HTTP 200** with a token whose claims are
  `preferred_username: loom-book-organizer-1` / `fanId: fan-book-organizer-1`.
- The app already held a session for this same fan (the `book-meeting-rsvp` walkthrough earlier the
  same day banked its rows under `fan-book-organizer-1`), so **no identity switch was performed** and
  the clear-both-Chrome-and-app procedure was not needed.
- Identity is not claimed from the "Signed in as Book Organizer 1 — Organizer" panel. It is
  established by the **server-written** `created_by_fan_id` on the resulting row, which the service
  derives from the bearer token rather than from anything the client selects.

## Baseline (measured, not assumed)

The brief's hint said "about 0 rows, few or none of `book-vote`". The hint was **stale on the total
and correct on the type**. Measured from this shell immediately before driving:

- `workflow_instances` total: **95 rows** (not ~0)
- `workflow_type = 'book-vote'`: **0 rows**
- Control, so an empty result means absent rather than a broken query: the same table held
  `book-discussion-message` 1, `book-meeting-rsvp` 1, `book-meeting-rsvp-response` 1,
  `book-nomination` 1 — the query shape works.

Remote communities start empty by the 2026-09-07 decision, so the package's `vote-august` seed does
not exist server-side. Creating the ballot was the point.

## Which exit was driven, and why

`book-vote` has exactly two transitions out of `open`, both terminal and both guarded
`allowedRoleIds: ["book-organizer"]`: `close-vote` → `closed` and `cancel-vote` → `cancelled`.
I drove **`close-vote`**, the ordinary success path, leaving the destructive `cancel-vote` untaken.

Read from the package before driving: `close-vote` carries **no** `relatedAggregate` and no formula
precondition — only the role guard. So the tally concern the brief raised does not apply, and the
card rendered `Close vote` while showing `0 votes`, with no `book-vote-response` rows in existence.
This workflow is single-party by design; the member side lives in `book-vote-response`, a separate
row, and was correctly not needed here.

## Path driven

1. Book Club → bottom nav scrolled right to reveal the `books` tab ("Books").
2. Books tab rendered the **New ballot** FAB — itself the `byRoleIds: ["book-organizer"]` create
   action passing its guard.
3. Filled the four required `formEntry` fields: Prompt, Candidates, Closes (native date picker,
   **selected** rather than typed), For.
4. **Create** → card rendered `Voting open`.
5. Scrolled the card; both organizer transitions rendered — `Close vote` (primary) and
   `Cancel ballot` (destructive).
6. Tapped **Close vote** → card re-rendered as `Closed` with the actions correctly withdrawn
   (state `closed` is `isTerminal: true`, and the binding switches to `summary`).

## Database confirmation (same session)

    select instance_id, community_id, workflow_type, created_by_fan_id,
           current_state, created_at, updated_at
      from workflow_instances where workflow_type='book-vote';

| field | value |
|---|---|
| `instance_id` | `community_neighborhood_book_club_book-vote_lj1a6xno3rs5` |
| `community_id` | `community_neighborhood_book_club` |
| `workflow_type` | `book-vote` |
| `created_by_fan_id` | `fan-book-organizer-1` |
| `current_state` | `closed` |
| `created_at` | `1789883943168` = 2026-09-20T05:59:03.168Z |
| `updated_at` | `1789883996826` = 2026-09-20T05:59:56.826Z |

Stored `instance_data`, read back from the row rather than from the screen:

    {"prompt":"B25 Sep19 Ballot","candidates":["Piranesi","Klara and the Sun"],
     "deadline":"2026-09-30","meetingContext":"Sep26 discussion"}

**The two halves agree.** The UI showed `Voting open` then `Closed`; the row shows `current_state`
`closed` under `created_by_fan_id` `fan-book-organizer-1`, the identity driven.

**This row is identified by its instance id and timestamps, not by a change in the row count.**
`created_at` lands **403 ms** after the wall-clock stamp taken immediately before the Create tap
(`1789883942765`), and `updated_at` **839 ms** after the stamp taken before the Close tap
(`1789883995987`). Both are this run's writes.

**No `adb shell input text` truncation.** Every typed value survives in full in the stored row, and
`candidates` was correctly parsed from the comma-separated entry into a two-element list. This was
settled against the database, not against the on-screen text, because a field that scrolls
horizontally shows a plausible prefix while the stored value is short.

## Defects observed

**None in the product.** `book-vote` behaved exactly as declared at every step: the create action
was offered only to the organizer role, all four required fields persisted intact, both terminal
transitions rendered for the guarded role, and firing one drove the instance to `closed` and
withdrew the actions.

The known, accepted Book Club defect (`nominatorFanId` stamped only on submission, so a `draft`
nomination is invisible to its own author) was **not** encountered — it belongs to `book-nomination`,
not this workflow. No package change was proposed or made; Book Club regeneration remains held by
user decision (tracker row-247).

## Harness note — not a product finding

Opening the soft keyboard collapsed the creation dialog's field area to zero height, putting all
four fields out of reach; this is the documented "coordinates go stale the moment the keyboard
opens" trap. Dismissing the keyboard with `keyevent 111` (ESCAPE) dismissed the **whole dialog**
rather than just the IME — verified to have written nothing (`book-vote` still 0 rows at that
point). The run was completed by disabling the soft keyboard
(`adb shell ime disable …/LatinIME`), which lets a tap focus a field without any layout shift so
coordinates stay valid; `input text` still delivers to the focused view. **The IME was re-enabled
and re-selected afterwards**, restoring the device to its prior state.

This is a note about driving the device, not about the app.

## Checks run

- All six `loom` pods `1/1 Running` before and after.
- No ANR or crash dialog: focused window was the app throughout
  (`mCurrentFocus=…loom_communities_demo/.MainActivity`).
- `logcat` scanned for `FATAL`, `AndroidRuntime`, `authentication_required`, `BACKEND UNREACHABLE`,
  `LoomAuthException`, `403`, `unknown_permission` — no real matches. (The only `403` hits were the
  substring inside keyboard resource ids `2132214031`/`2132214032`, not an HTTP status.)
