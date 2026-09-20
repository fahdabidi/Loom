**Workflow:** `soccer-reminder-notification` in Riverside Youth Soccer
**Outcome:** **BLOCKED — not proven. No instance of this workflow was created, and none can be.**
The row's only writer is unreachable: `soccer-reminder-notification` is created solely by the
`createInstance` effect on `soccer-practice-rsvp-response.send-reminder`, and **no
`soccer-practice-rsvp-response` row can ever exist in this community**, because the platform's
response-row fan-out supplies exactly two fields while the package declares **eleven** as `required`.
The engine rejects every fan-out attempt with `Validation error on "eventTitle": Required field is
missing or null`. This is a package authoring defect, reproduced twice on the device, and it is
invisible to the validator.

**Package identity:** `skillVersion: "3.3.0"`, `specVersion: 4`, sha256
`a36df7d62bea301e2e686db11d401027efce93c5e92210564b63569761777504`
(`docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc`;
byte-identical to `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc`,
verified with `cmp` in this session.)

**Date:** 2026-09-20 (UTC; device clock 2026-09-19 local) · **Device:** `emulator-5554` (Windows host,
reached from the VM over an ssh reverse tunnel to `:5037`)
**Community id (workflow-service):** `community_riverside_youth_soccer` — read off the stored row, not assumed.
**Deployed images:** `loom-workflow-service:1.0.8` (pod `workflow-service-86f694557d-gd4k9`, started
`2026-09-19T23:29:46Z`), `loom/app-access:0.3.11`, `loom/fan-passport:0.3.1`, `loom-keycloak:phase-c3`.
All six `loom` pods `1/1`.
**Engine actually exercised:** remote, from the app's own telemetry —
`LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ scope=ext_youth_soccer outcome=ok status=200`.

---

## Identity — the stale-SSO hazard was excluded, not assumed

The package was read before choosing an identity. `soccer-reminder-notification` is created by a
**coach**-guarded transition (`send-reminder`, `allowedRoleIds: ["soccer-coach"]`) and then
transitioned by its **recipient** (`actorEqualsField: recipientFanId`, all six transitions). So the
walkthrough was driven as the coach, which is the role that holds the create.

Authenticated as **`loom-soccer-coach-1`** / fan id **`fan-soccer-coach-1`**, role `soccer-coach`.
No credential was created or reset.

**Both Chrome and the app were cleared, and each clear is proven rather than asserted:**

- `pm clear com.example.loom_communities_demo` → the community entry gate rendered
  `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`
- `pm clear com.android.chrome` → Chrome opened on its **first-run** screen ("Make Chrome your own");
  after skipping it, Keycloak served a **genuinely empty** `Sign in to your account` form at
  `192.168.56.10:30082`. No SSO cookie survived, so no previous fan could have been silently re-issued
  a token.

The account then selected in the picker was `fan-soccer-coach-1` — the same identity that
authenticated, which is what the app's anti-impersonation check requires. The in-app header read
**"Signed in as Soccer Coach 1 · Coach"**.

---

## Controls taken before the first write

`select count(*) … where workflow_type='soccer-reminder-notification'` returned **0**, while the same
query grouped over all types returned real counts for fifteen other workflows — so the query worked and
the zero is a real absence, not a broken predicate. `soccer-reminder-notification` **is** published:
it is one of ten `soccer%` rows in `workflow_definitions`, so this is not the
unpublished-`createInstance` failure mode.

---

## What was driven live, and where it stopped

| # | Actor | Device action | Engine result |
|---|---|---|---|
| 1 | coach | **"New practice"** FAB → filled all nine fields → **Create** | `…_soccer-practice-schedule_lrc7f27ymmen`, state `upcoming`, `created_at 1789869341458` (`01:55:41.458Z`). Tap `01:55:40.462Z` → write **996 ms** later |
| 2 | coach | card rendered `RSVPs open: No`, `0 / 12 going`, and **"No response record is available for you for this event."** | correct — fan-out has not run yet |
| 3 | coach | tapped **"Publish practice and open RSVPs"** (`01:57:13.621Z`) | **FAILED.** Card showed *"Could not save this change. Please try again."* Service logged `WorkflowValidationError`, correlation `6133e293-ce31-4758-8216-c3f4d9dcb1ac` |
| 4 | coach | tapped **Retry** | **FAILED identically**, correlation `217a617d-3ed3-47f8-ad1b-00ca8ac5208e` |

**Stopped at step 3.** The chain `publish → response rows → send-reminder → soccer-reminder-notification`
cannot start, so no reminder notification was created and none could be.

### The state claim is the stored row, not the tap

`soccer-practice-schedule_lrc7f27ymmen` still reads `current_state = upcoming` with
**`updated_at == created_at == 1789869341458`** and `instance_data.published = false` after both
attempts. So the publish transition did not merely fail to fan out — the whole transition **rolled
back atomically**, which is the correct behaviour and worth recording as a positive: the fan-out runs
inside the parent's transaction (`WorkflowDatabase._executeTx`), so a failed fan-out leaves no
half-published event.

`soccer-practice-rsvp-response` rows: **0**. `soccer-reminder-notification` rows: **0**, re-read as a
closing control.

### Typed values were settled against the stored row, not the screen

`adb shell input text` truncates silently, so every value was read back out of Postgres:

    title=ReminderProof  location=RiversideComplex  reminderBody=BringWaterAndShinGuards
    eventDate=2026-09-26  eventTime=18:00  published=false

None truncated. `eventDate` and `eventTime` were **selected** from the app's date/time pickers rather
than typed.

---

## The defect, stated exactly

The service named its own cause; this is not inferred:

    "errorType":"WorkflowValidationError",
    "error":"Validation error on \"eventTitle\": Required field is missing or null"
    #2  LocalWorkflowEngineApi._fanOutEventRsvpResponseRows (local_workflow_engine_api.dart:1583)
    #3  LocalWorkflowEngineApi._applyTransitionEffectsAndPersistWithinTransaction (…:1483)

`_fanOutEventRsvpResponseRows` creates each response row with **exactly two** fields — the
`responseTable.eventField` and `fanId` — and the archetype contract says it must:
`docs/references/archetypes/event-rsvp.md` §4 "Who creates a row" states the row is created
*"in the response workflow's declared initial state. Nothing in community JSON declares the creation."*
`_validateSeedData` then rejects the row on the first `required` field it cannot find.

`soccer-practice-rsvp-response` declares **11** required fields. Two are suppliable; **nine are not**:

| field | `writableBy` | suppliable by fan-out |
|---|---|---|
| `eventId`, `fanId` | (form entry) | **yes** |
| `eventTitle`, `eventDate`, `eventTime`, `location`, `fieldName`, `reminderChannel`, `reminderBody` | (form entry) | no |
| `reminderStatus`, `responseUpdatedAt` | **`effect`** | no — and these are unsatisfiable by *any* creation path, since an effect runs on a transition, never at creation |

### Scope — this is one package, not a platform fault

Swept all ten shipped packages for `responseTable` declarations and compared each target's required
set against what the fan-out supplies:

| community | response workflow | required | verdict |
|---|---|---|---|
| Camera Club | `photo-walk-response` | 2 | OK |
| Garden Club | `garden-event-rsvp-response` | 2 | OK |
| Book Club | `book-meeting-rsvp-response` | 2 | OK |
| Tabletop Club | `event-rsvp-response` | 2 | OK |
| **Riverside Youth Soccer** | **`soccer-practice-rsvp-response`** | **11** | **BLOCKED — 9 unsuppliable** |

Four peers declare exactly the two fields the platform supplies. Riverside is the sole outlier, and
Garden's identical path is **proven working on this same engine** — `event-cancel-response-sweep-ui-path-proof-2026-09-19.md`
records two Garden response rows materializing by fan-out on `workflow-service:1.0.8`. So the engine
is not at fault and no engine change is implied.

### Why nothing caught this

- **The validator passes it.** Youth Soccer was re-validated against a freshly started validator on
  2026-09-19 (TODO.md line 399): `status: pass`, **0 errors**. It cannot catch this, because every
  declaration is individually well-formed — the defect exists only in the relationship between the
  package's `required` set and the engine's fan-out contract, which no per-declaration rule can see.
  This is the documented "a workflow can be perfectly valid and still have an outcome nobody can
  reach" family.
- **The parent card offers a decoy.** `soccer-practice-schedule.send-next-reminder` renders as
  **"Send practice reminder"** and is coach-visible, but its only effect is
  `append reminderHistory` — it creates no notification. The transition that actually writes one is
  `send-reminder`, on the response row that cannot exist. A reader checking "can the coach send a
  reminder?" from the parent card would conclude yes.

---

## What is owed, and by whom

**A Skill dispatch to regenerate Riverside Youth Soccer** so `soccer-practice-rsvp-response` declares
only what the platform can supply as `required` — matching the four conforming peers. Community JSON
is authored solely by the Skill, so this was **not** hand-edited here. Note that `reminderStatus` and
`responseUpdatedAt` being simultaneously `required: true` and `writableBy: "effect"` is independently
contradictory and should be fixed in the same pass.

Until then `soccer-reminder-notification` is unreachable through the app, and so are all five of its
other transitions (`keep-reminder-unread`, `mute-reminders`, `unmute-reminders`,
`request-reminder-change`, `open-related-schedule`).

**This manifest deliberately does not carry the proven phrase**, so `check_b25_status.sh` counts it in
the not-proven bucket. The bar stays at **45**; it does not move to 46.

---

## Artifacts

Screenshots were captured at every step but `*.png` is gitignored, so they are transient. The durable
evidence is this manifest plus the Postgres reads and the service log lines quoted above, all taken in
this session.
