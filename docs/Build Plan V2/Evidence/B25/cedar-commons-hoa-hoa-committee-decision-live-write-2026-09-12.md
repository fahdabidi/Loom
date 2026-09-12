**Workflow:** `hoa-committee-decision` in Cedar Commons HOA
**Outcome:** Both halves of the proof standard were met — signed in as `loom-hoa-member-1`, created and submitted an `hoa-architectural-request` through the Requests tab, which spawned a NEW `hoa-committee-decision` row, then opened that decision's own card in the UI and fired `owner-withdraw` on it to reach the declared terminal `withdrawn`, confirming both in Postgres.

(That outcome sentence is deliberately kept on one line: `check_b25_status.sh` matches the phrase
with a line-based grep, so wrapping it mid-phrase makes a proven row read as unproven.)

**Package identity driven:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc`
- `skillVersion`: `3.6.0`
- `sha256`: `38c70ed08eabe2ef07011658bdea2434008e385b271e4ae6b98a29007369fd7f`
- Verified byte-identical to the copy **bundled inside the installed APK**, re-derived in this
  session rather than inherited: the APK was pulled from the device (`pm path` → `base.apk`,
  193,852,333 bytes) and its
  `assets/flutter_assets/packages/loom_communities_app_shell/assets/…CedarCommonsHOA….jsonc`
  hashed to the same sha256.
- **Why it was re-derived:** the earlier `hoa-architectural-request` manifest for this community
  records `lastUpdateTime=2026-09-12 06:19:23` and 193,851,555 bytes, but the installed APK is now
  `lastUpdateTime=2026-09-12 11:28:15` and 193,852,333 bytes — a *different* APK. The Cedar package
  inside it is nonetheless identical, but that had to be measured, not assumed.

Date: 2026-09-12. Run host: Loom VM (`fahd-VirtualBox`, 192.168.56.10), emulator hosted on Windows,
reached via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037` (`emulator-5554`).

---

## Identity

- Keycloak account: **`loom-hoa-member-1`**
- Fan id: **`fan-hoa-member-1`**
- Role exercised: **`hoa-member`** (the app shell rendered it as "Homeowner")

No escalation to any other account, and **no identity switch mid-run**. Every transition fired is
guarded `allowedRoleIds: ["hoa-member"]` plus `actorEqualsField: requesterFanId`.

**Sign-in was a genuine, fresh OAuth login, not a reused session.** The device arrived holding a
Masjid walkthrough's session (`fan-masjid-member-1` visible in on-screen data), so this was an
identity switch and both stores were cleared:

    adb shell pm clear com.android.chrome
    adb shell pm clear com.example.loom_communities_demo

Evidence the switch was real rather than an SSO re-issue of the previous fan:

- The launch screen printed **"Loaded 10 example communities"**, confirming the preload flag is
  compiled into this APK (and that app data had genuinely been cleared).
- Opening Cedar showed `LoomAuthNotLoggedInException: No Loom authentication session is stored;
  login is required.` with "Continue to secure sign-in" — the error branch, i.e. no stored session.
- Keycloak served a **real username/password form** at `192.168.56.10:30082`. A stale SSO cookie
  would have skipped this and returned a green "You're signed in" for the old fan.
- Both typed fields were read back on screen before submitting (password revealed via the eye
  toggle) to rule out `adb shell input text` truncation: `loom-hoa-member-1` / `LoomTest123!`.
- The account picker was then answered with **Hoa Member 1 / `fan-hoa-member-1`**, matching the
  token's `fanId`; the app's anti-impersonation guard compares those and would have refused a
  mismatch.
- Independently, a password-grant token request against `loom-test-client` returned HTTP 200 with
  `preferred_username: loom-hoa-member-1` and `fanId: fan-hoa-member-1`.
- Final confirmation is the DB itself: `created_by_fan_id = fan-hoa-member-1` on the row below.

---

## Baseline, measured in this session before touching anything

    select count(*) from workflow_instances;              -- 65

    workflow_type = 'hoa-committee-decision':
    community_cedar_commons_hoa_hoa-committee-decision_m3z1jsw245x4 | fan-hoa-member-1 | withdrawn | 1789227238259

The dispatching session's hint ("about 65 rows, few or none of `hoa-committee-decision`") was
accurate on the count and **wrong on the second half**: one row already existed. That row is the
cascade the brief warned about — created 2026-09-12T15:33:58Z, already terminal `withdrawn`, never
opened in any UI. **It is not cited as proof here.** My row is distinguished by instance id and
`created_at`, not by the row count.

After the run: **67 rows** (+2 — my architectural request and my decision).

---

## The path driven

1. **Requests** tab (visible to `hoa-member` per `visibleRoleIds: ["hoa-member", "hoa-board"]`) →
   FAB **"Submit property request"**.
2. Filled all five required `formEntry` fields — `title`, `propertyLot`, `changeDetails`,
   `documentCheckpoint`, `paymentCheckpoint`. Created in `draft` as
   `community_cedar_commons_hoa_hoa-architectural-request_kbxpshwvrxop`.
3. Fired **`submit-request`** (`draft → submitted`). **This spawned the decision row.**
4. Found the spawned **`hoa-committee-decision`** card on the Requests tab (`statusTimeline`
   summary binding) showing `Submitted` / "Current step: Awaiting committee review", and **opened
   it** — its own destructive action **"Owner withdrew"** was rendered on the card.
5. Fired **`owner-withdraw`** (`submitted → withdrawn`, a declared terminal) **from the decision's
   own card**. The card then showed the `Owner withdrew` state badge, "Current step: Owner withdrew
   request", both history events, and **no remaining action** (terminal).

This is the part that distinguishes this run from the pre-existing row: the transition was fired
**through the decision's own UI card**, not as a server-side cascade.

---

## Half 1 — final UI state

My decision card, Requests tab, as `fan-hoa-member-1`:

- State badge: **`Owner withdrew`**
- `B25 Decision Lot42`, `Property: Lot 42`, `Requester: Fan Hoa Member 1`
- `Submitted 2026-09-12T22:50:18.153820Z`
- `Current step: Owner withdrew request`
- `Documents: CCR 2026 V3`, `Payment: Dues Current 2026 Q3`
- History events: `submitted` by `fan-hoa-member-1` at `22:50:18.153820Z`; `withdrawn` by
  `fan-hoa-member-1` at `22:52:02.079340Z`
- `Owner notice: Not sent`
- No action buttons remain.

No ANR or crash dialog at any point (`dumpsys window` → `<no ANR has occurred since boot>`);
focus stayed on `com.example.loom_communities_demo/.MainActivity` throughout.

## Half 2 — the Postgres row

    select instance_id, community_id, workflow_type, created_by_fan_id, current_state, created_at
      from workflow_instances where workflow_type='hoa-committee-decision' order by created_at desc;

| field | value |
|---|---|
| `instance_id` | `community_cedar_commons_hoa_hoa-committee-decision_jafn7fhi1lk0` |
| `community_id` | `community_cedar_commons_hoa` |
| `workflow_type` | `hoa-committee-decision` |
| `created_by_fan_id` | `fan-hoa-member-1` |
| `current_state` | `withdrawn` |
| `created_at` | `1789253418153` = 2026-09-12T22:50:18.153Z |

`instance_data` confirms the effects of `owner-withdraw` landed:

    "currentStep": "Owner withdrew request"
    "statusHistory": [
      { "status": "submitted", "actorFanId": "fan-hoa-member-1", "at": "2026-09-12T22:50:18.153820Z" },
      { "status": "withdrawn",  "actorFanId": "fan-hoa-member-1", "at": "2026-09-12T22:52:02.079340Z" }
    ]

**Do the two halves agree? Yes, on every field**, including `created_by_fan_id = fan-hoa-member-1`,
which matches the identity driven. The state badge, current step and both history timestamps on
screen are the same values stored in the row.

---

## `requestInstanceId` linkage — reported verbatim as asked

    "requestInstanceId": "community_cedar_commons_hoa_hoa-architectural-request_kbxpshwvrxop"

My architectural request's instance id is
`community_cedar_commons_hoa_hoa-architectural-request_kbxpshwvrxop`.

**They are equal.** The `{id}` token in the `createInstance` effect's `fields` resolved correctly —
consistent with `{id}` being a known-good context in effect `fields` (as distinct from
`transitionRelated` filters, where `{id}` silently matches nothing).

The vehicle request itself remains `submitted`, which is expected: `owner-withdraw` on the decision
declares no cascade back to the request, and I deliberately did not fire the request's own
`withdraw-request` (that workflow is already proven and is only the vehicle here).

## Guard behaviour observed

The six `hoa-board` transitions (`begin-committee-review`, `approve-request`,
`request-owner-changes`, `deny-request`, `reopen-decision`, `resume-review`) were **not offered** on
the decision card — only `owner-withdraw`. Correct: they are the committee's, not the owner's.

On the architectural request in `draft`, exactly the three member-guarded actions were offered —
`Submit request`, `Discard draft`, `Attach document`. No board actions.

**The `readGuard` question the brief flagged is answered affirmatively:** although
`hoa-committee-decision` declares `readGuard: { allowedRoleIds: ["hoa-board"] }`, the requester
*could* see their own decision row, via `fields.parties: ["requesterFanId", { "role": "hoa-board" }]`
plus the all-eight-states `audience: "any"` binding on `tabId: "requests"`. Both the pre-existing
decision row and my own rendered for `fan-hoa-member-1`. **No visibility defect.**

---

## Field values settled against the database, not the screen

`adb shell input text` truncates silently, so all five typed values were read back out of
`instance_data` rather than trusted from the UI. Stored exactly as typed:

    "title": "B25-Decision-Lot42"
    "propertyLot": "Lot-42"
    "changeDetails": "Install-rear-pergola"
    "documentCheckpoint": "CCR-2026-V3"
    "paymentCheckpoint": "Dues-Current-2026-Q3"
    "requesterFanId": "fan-hoa-member-1"      (from the create action's $actor prefill)

No truncation. The spawned decision carries the same values, copied by the `createInstance` effect.

**Two device-interaction notes**, recorded because they cost time and will recur:

- **`keyevent 61` (TAB) does not move focus between fields in this creation form.** Title filled
  correctly and the next two `input text` calls went nowhere — the form looked half-filled for no
  visible reason. Tapping each field individually is required.
- **Typing into a field while the soft keyboard is open shifts the dialog's layout**, so fixed tap
  coordinates land on the wrong field; one such tap opened Gboard's clipboard panel. Dismissing the
  keyboard (single `keyevent 4`) between fields keeps the layout stable. Note a *second* back press
  closes the whole dialog — which happened once, discarding an incompletely filled form. Nothing
  partial was written: no instance existed until `Create`, confirmed by the row count.

---

## Defect observed — cosmetic, non-blocking

**A raw schema key is rendered to the user as chip text, with no value.** On every
`hoa-committee-decision` card the Requests tab shows a chip reading literally
**`requestInstanceId`** — the field name — and no value beside it. Visible on both my card and the
pre-existing one, so it is consistent rather than a one-off.

Read against the declaration before calling it a defect, per the standing rule. In the decision's
`instanceDataSchema` the field is declared with no display metadata at all:

    "requestInstanceId": { "type": "text", "required": true },

Every neighbouring field in the same schema declares `labelTemplate` and `displayContexts` (e.g.
`requestTitle` has `"labelTemplate": "{value}", "displayContexts": ["tile", "detail"]`). The
architectural request's own copy of the same field instead carries
`"writableBy": "effect", "hideWhenEmpty": true`, and it does **not** render a stray chip.

So the observable result is a user-facing chip displaying an internal camelCase key. It does not
affect reachability, the transition, or the stored data, and it did not impede this proof — the
workflow is fully reachable and both halves are met. Reporting it rather than papering over it;
**the fix belongs to the Skill, not to a hand-edit of the package** (community JSON is Skill-authored
only), and this manifest makes no change to any package.

---

## Scope

No application code, community JSON, or tracker was modified. No credential was created or reset.
This manifest is the only file added. `integration_test/on_device_remote_backend_proof_test.dart`
was not used.
