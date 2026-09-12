**Workflow:** `hoa-architectural-request` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — signed in as `loom-hoa-member-1`, created an architectural request through the Requests tab's "Submit property request" FAB, then fired the member-guarded `submit-request` and `withdraw-request` transitions to drive it `draft → submitted → withdrawn` (terminal), confirming each step in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity driven:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f`
- Verified byte-identical to the copy **bundled inside the installed APK**: the APK was pulled from
  the device (`pm path` → `base.apk`, 193,851,555 bytes) and its
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/…CedarCommonsHOA….jsonc`
  hashed to the same sha256. The hash therefore describes the package actually driven, not merely
  the one in the working tree.

Date: 2026-09-12. Run host: Loom VM (`fahd-VirtualBox`, 192.168.56.10), emulator hosted on Windows,
reached via `adb -H 192.168.56.1 -P 5037`. APK `lastUpdateTime=2026-09-12 06:19:23`.

---

## Identity

- Keycloak account: **`loom-hoa-member-1`**
- Fan id: **`fan-hoa-member-1`**
- Role exercised: **`hoa-member`** (the role the workflow's member-side guards name)

No escalation to any other account was needed: every transition on the path driven is guarded
`allowedRoleIds: ["hoa-member"]` plus `actorEqualsField: requesterFanId`.

**On sign-in:** the app already held a live authenticated session for this exact identity, carried
over from the `hoa-facility-reservation` proof earlier the same day. No fresh Keycloak login was
performed, and **no credential was created or reset**. The stale-SSO hazard the brief warns about is
the risk of banking evidence under the *previous* fan — here the previous fan and the intended fan
are the same account, and the identity was confirmed three independent ways rather than assumed:

1. The app shell's own header rendered **"Signed in as Hoa Member 1 / Homeowner"**.
2. The bottom navigation exposed Home, Calendar, Giving, Documents, Requests, Messages and **not
   Admin** — `admin` is `visibleRoleIds: ["hoa-board"]`, so a board session would have shown it.
3. Decisively, `created_by_fan_id` on **both** resulting rows is `fan-hoa-member-1` (below), and the
   `requesterFanId` prefilled from `$actor` resolved to `fan-hoa-member-1` — a real fan id, not a
   role-id-shaped string. That last point also confirms the write went through the production
   identity model, not the shell's demo `fanId`-aliases-`roleId` path.

## Baseline — measured independently before touching anything

The brief's hint ("about **32** rows, and few or none of `hoa-architectural-request`") was accurate
this time, which is worth recording explicitly because it was stale twice on 2026-09-09:

- `workflow_instances` held **33 rows** before this run.
- `hoa-architectural-request` rows: **0**. The query returned `(0 rows)` — a real negative result,
  not a broken query: the same query shape returned rows for 26 other `workflow_type` values in the
  same breath, which is the control.

So there was no prior instance to be confused with, and this run's row is identified below by
instance id and `created_at` rather than by any change in the row count.

**Publication pre-check.** All three types in the chain — `hoa-architectural-request`,
`hoa-committee-decision`, `hoa-owner-notification` — are present in `workflow_definitions`. This
matters because a `createInstance` naming an unpublished type returns success and does nothing, and
the path driven below depends on exactly that effect.

## Path driven on the device, through the real UI

1. **Requests tab** (reached by scrolling the bottom navigation; it is `visibleRoleIds:
   ["hoa-member", "hoa-board"]`). Tab was empty, agreeing with the zero-row baseline.
2. **"Submit property request" FAB** — the `kind: "create"` action declared `byRoleIds:
   ["hoa-member"]` on the `formEntry` binding, with `prefill: { requesterFanId: "$actor" }`.
3. Filled the five required `formEntry` fields. A first Create attempt was **correctly refused**
   client-side with *"Document checkpoint is required."* and **wrote nothing** — the database still
   showed `(0 rows)` at that moment. That is an honest validation failure, recorded here because a
   silent partial write would have been the dangerous outcome.
4. Second Create succeeded → instance created in `draft`.
5. **"Submit request"** (`submit-request`, `draft → submitted`).
6. **"Withdraw request"** (`withdraw-request`, `submitted → withdrawn`, `isTerminal: true`).

Final UI state: card badge reads **"Withdrawn"**, `Current step: Withdrawn by owner`, two status
events rendered (`submitted`, `withdrawn`) both showing `Actor Fan Id: fan-hoa-member-1`, and **no
action buttons remain** on the card. No ANR or crash dialog appeared at any point (checked via
`dumpsys window`; focus stayed on `MainActivity` throughout).

## The database rows, confirmed in this same session

```
instance_id  | community_cedar_commons_hoa_hoa-architectural-request_tvevsywi9ei9
community_id | community_cedar_commons_hoa
workflow_type| hoa-architectural-request
created_by_fan_id | fan-hoa-member-1
current_state| withdrawn
created_at   | 1789227172533   (2026-09-12T15:32:52.533Z)
updated_at   | 1789227273398   (2026-09-12T15:34:33.398Z)
```

The `submit-request` effect's `createInstance` also produced a real second row, which is part of the
proof that the effect graph actually executed rather than merely returning success:

```
instance_id  | community_cedar_commons_hoa_hoa-committee-decision_m3z1jsw245x4
workflow_type| hoa-committee-decision
created_by_fan_id | fan-hoa-member-1
current_state| withdrawn        (via the withdraw-request `transitionRelated` effect, "Owner withdrew")
created_at   | 1789227238259   (2026-09-12T15:33:58.259Z)
```

Row count moved 33 → **35**, consistent with exactly these two new rows.

### Do the two halves agree?

**Yes, on every field checked.** `created_by_fan_id` is `fan-hoa-member-1`, matching the identity
driven. `current_state` is `withdrawn`, matching the terminal badge on screen. The status history
stored server-side matches the two status events rendered on the card, to the microsecond:

```
statusHistory: [
  { status: "submitted", actorFanId: "fan-hoa-member-1", at: "2026-09-12T15:33:58.253938Z" },
  { status: "withdrawn", actorFanId: "fan-hoa-member-1", at: "2026-09-12T15:34:33.398780Z" }
]
```

**Typed values settled against the stored row, not the screen** (the documented
`adb shell input text` truncation trap). All five survived exactly, with no truncation:

| Field | Typed | Stored in `instance_data` |
|---|---|---|
| `title` | `B25-arch-lot27` | `B25-arch-lot27` |
| `propertyLot` | `Lot-27` | `Lot-27` |
| `changeDetails` | `Fence-replace-6ft` | `Fence-replace-6ft` |
| `documentCheckpoint` | `CCR-2026-v3` | `CCR-2026-v3` |
| `paymentCheckpoint` | `Dues-current-2026Q3` | `Dues-current-2026Q3` |

Note the card *displays* these humanised ("Document checkpoint: CCR 2026 V3") via `labelTemplate`
rendering; the underlying stored values are the exact strings above. The on-screen form's inline
editor showed them unhumanised and correct.

`requestInstanceId` resolved to the instance's own id on both rows, so the `{id}` substitution and
the cross-workflow linkage both worked.

---

## Defect observed

**A raw schema key leaks into the member-facing card as a chip.** On the spawned
`hoa-committee-decision` card, a chip renders the literal text **`requestInstanceId`** — the field
*name*, camelCase, unhumanised — sitting alongside properly-rendered chips like "Property: Lot 27".

- Community: Cedar Commons HOA. Workflow: `hoa-committee-decision` (the partner workflow this row's
  `submit-request` effect creates). Surface: Requests tab, `statusTimeline` card.
- The underlying data is **fine**: `requestInstanceId` is correctly populated with
  `community_cedar_commons_hoa_hoa-architectural-request_tvevsywi9ei9`. This is a rendering defect,
  not a data defect.
- What distinguishes this field from its neighbours in the package: its declaration is
  `"requestInstanceId": { "type": "text", "required": true }` — with **no `labelTemplate` and no
  `displayContexts`**, whereas every neighbouring rendered field declares both.
- Severity: cosmetic, non-blocking. It did not impede any transition.
- **Scope of what I verified:** I confirmed the chip on screen and confirmed the declaration lacks
  those two keys. I did **not** read the renderer to establish *why* a field with no
  `displayContexts` is rendered at all, nor whether the fix belongs in the package or the card
  renderer. Both are open questions, and the second is the more interesting one — if the renderer
  displays fields that never declared themselves displayable, other communities will have this too.

## Observation, reported as unconfirmed rather than as a defect

With the soft keyboard open, the creation dialog's field area collapsed to zero height, leaving only
the title and the Cancel/Create buttons visible; and both BACK and ESC dismissed the **whole dialog**
(discarding entered input) rather than just the keyboard.

I am recording this as an observation, not a finding, because **I could not establish that it
affects a human user**: a person can plausibly scroll within the dialog, and I did not verify
whether that scroll works. It is stated here because it shaped the run — it is why the form was
filled one field at a time, tapping each field from the keyboard-hidden layout and pressing TAB
afterwards to restore that layout. Worth a deliberate check by someone driving the surface by hand.

A related automation note for whoever runs this next: `input keyevent 61` (TAB) **blurs the field
and closes the keyboard** here rather than advancing focus to the next field. Chaining
`tap → text → TAB → text` therefore silently drops every value after the first — the second and
third strings went nowhere and the fields stayed empty. Caught by screenshotting between steps; it
would otherwise have produced an instance with missing fields and no obvious cause.

## What I did not do

- Did not drive the board-side transitions (`begin-review`, `approve-case`, `deny-case`,
  `request-changes-case`, `reopen-case`). All five are `allowedRoleIds: ["hoa-board"]` and this run
  authenticated as `hoa-member`. The member-side path to a terminal state is complete without them.
- Did not modify application code, community JSON, or any tracker. Did not create or reset any
  credential. This manifest is the only file added.
