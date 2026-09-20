# B25 live-write evidence — Riverside Youth Soccer guardian join approval

**Workflow:** `soccer-guardian-join-approval` in Riverside Youth Soccer
**Outcome:** Both halves of the proof standard were met — a registration was created and driven
through **five** transitions by **two genuinely distinct authenticated fans**, alternating
guardian → coach → coach → guardian, with every state change settled against the stored Postgres
row in this same session. The instance's own `history` carries four entries stamped by the engine
with two different `byFanId` values, and the row's `guardianFanId` and `coachReviewerFanId` hold
different fans.

**This is the one claim a local-engine capture cannot make.** On the local path the shell aliases
`fanId` to `roleId` and both parties collapse into one person, so a two-party row can appear to pass
while actually proving a self-transaction. Here the two parties are separate Keycloak accounts with
separate OAuth sessions, and the engine attributed each transition to the right one.

**Package identity:** `skillVersion: "3.3.0"`, `specVersion: 4`, sha256
`a36df7d62bea301e2e686db11d401027efce93c5e92210564b63569761777504`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc`;
byte-identical to `docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc`,
verified with `cmp` in this session).

**Date:** 2026-09-20 (UTC; device clock 2026-09-19 local) · **Device:** `emulator-5554` (Windows host,
reached over an ssh reverse tunnel to :5037)
**Community id (workflow-service):** `community_riverside_youth_soccer` — read off the row, not assumed.
**Deployed images at time of run:** `loom-workflow-service:1.0.8`, `loom/app-access:0.3.11`,
`loom/fan-passport:0.3.1`, `loom-keycloak:phase-c3`. All six `loom` pods `1/1`.
**Engine actually exercised:** remote. The app's own telemetry, not an assumption —
`LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ scope=ext_youth_soccer outcome=ok status=200`,
observed under both identities.

## Which row, and why

A live row already existed at `submitted` (`…_qh3begb23hjv`, created 2026-09-08 by
`fan-soccer-guardian-1`). **I created a fresh row instead of advancing it**, deliberately: advancing
the old one would have proven only the coach's half live, leaving the guardian's half resting on an
eleven-day-old write nobody observed. A fresh row lets *both* parties be driven live in one session,
which is the property this row exists to demonstrate. The pre-existing row was left untouched and is
still at `submitted`.

## Identity — and how the stale-SSO hazard was excluded, three times

The package decides who acts, and it is not one role: `submit-request`, `revise-request`,
`resubmit-request` and `withdraw-request` guard on `soccer-guardian` with
`actorEqualsField: guardianFanId`; `review-request`, `request-changes`, `reject-request` and
`approve-request` guard on `soccer-coach`. So the walkthrough was driven as **both**.

Role holders were confirmed in `group_membership_role` **before** the run — `soccer-guardian` and
`soccer-coach` each have two holders in group `loom_communities_riverside-youth-soccer`, so a
two-party interaction is genuinely possible rather than blocked by single-holder seeding. No
credential was created or reset.

| Keycloak user | fan id | role |
|---|---|---|
| `loom-soccer-guardian-1` | `fan-soccer-guardian-1` | `soccer-guardian` |
| `loom-soccer-coach-1` | `fan-soccer-coach-1` | `soccer-coach` |

**Both Chrome and app data were cleared before each of the three sign-ins**, and each clear is
proven rather than asserted:

- `pm clear com.example.loom_communities_demo` → the community entry gate rendered
  `LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required.`
- `pm clear com.android.chrome` → the custom tab opened on Chrome's **first-run** activity
  (`org.chromium.chrome.browser.firstrun.FirstRunActivity`), and after skipping it Keycloak served a
  **genuinely empty** `Sign in to your account` form at `192.168.56.10:30082`.

All three sign-ins showed that empty form. No SSO cookie survived in either direction, so neither fan
was ever silently re-issued the other's token. The account selected in the picker each time was the
same identity that had just authenticated, which is what the app's anti-impersonation check requires
(it compares the selected account id against the token's `fanId`).

The in-app header read **"Signed in as Soccer Guardian 1 · Guardian"** and
**"Signed in as Soccer Coach 1 · Coach"** respectively. The tab bar changed with the identity —
the guardian saw **Payments**, the coach saw **Coach & Owner** — which is independent confirmation
that the role actually changed rather than the label alone.

## Control read, taken before the first write

    select instance_id, current_state, created_by_fan_id, created_at, updated_at
      from workflow_instances where workflow_type='soccer-guardian-join-approval';

returned **exactly one row** (the 2026-09-08 `…_qh3begb23hjv` at `submitted`). The control is a
*positive* one: the query demonstrably returns rows for this workflow type, so the second row
appearing afterwards is a real write and not an artifact of a broken predicate.

## Half 1 — driven live through the real UI

Every step below is a tap on the app's own control. Nothing was invoked against the service directly,
and no transition was fired that the UI did not offer.

1. **(guardian)** Riverside Youth Soccer → Home → tapped the **"Register a player"** FAB — the
   package's own `create` action on the `formEntry` primary binding, `byRoleIds: ["soccer-guardian"]`.
   Filled all seven fields, tapped **Create**. Card rendered **"Draft registration request"**.
2. **(guardian)** Tapped **"Send registration request"** (`submit-request`). Card became
   **"Submitted to coach"** with `Payment: Unpaid` / `Waiver: Unread`.
3. **(coach)** After a full identity switch: **Coach & Owner** tab → the guardian's request appeared
   in the approval queue (`approvalQueueItem`, `audience: "receiver"`). Tapped **"Review request"**
   (`review-request`). Card became **"Under coach review"** and gained
   **`Reviewer: Fan Soccer Coach 1`**.
4. **(coach)** Tapped **"Request changes"** (`request-changes`), which opened the transition's own
   required-input dialog (`missingItems` list, `reviewerComment` text), filled both, submitted. Card
   became **"Missing information"** with `Missing: ProofOfInsurance`.
5. **(guardian)** After a second full identity switch: the guardian's Home card now showed **the
   coach's two history entries**, then tapped **"Resubmit request"** (`resubmit-request`). Card
   returned to **"Submitted to coach"**.

Screenshots were captured at every step but `*.png` is gitignored, so they are transient; this
manifest is the durable artifact.

## Half 2 — independently confirmed in Postgres, same session

| | |
|---|---|
| instance_id | `community_riverside_youth_soccer_soccer-guardian-join-approval_1p5co7fymx4k` |
| community_id | `community_riverside_youth_soccer` |
| workflow_type | `soccer-guardian-join-approval` |
| created_by_fan_id | **`fan-soccer-guardian-1`** |
| current_state | **`submitted`** (was `draft` at creation; reached via `submitted` → `under-review` → `missing-info` → `submitted`) |
| created_at | 1789870908639 → `2026-09-20 02:21:48.639Z` |
| updated_at | **1789871666878 → `2026-09-20 02:34:26.878Z` — no longer equal to `created_at`** |

### Each transition, with the tap→write gap

Each row's evidence is the stored `history` entry, which carries the actor and the engine's own
timestamp. Taps were wall-clocked on the host immediately before `adb shell input tap`.

| # | Actor | Transition (button) | To state | Tap (UTC) | Stored effect timestamp | Gap |
|---|---|---|---|---|---|---|
| 1 | guardian | *create* ("Register a player" → Create) | `draft` | 02:21:48.459 | `created_at` 02:21:48.639 | 180 ms |
| 2 | guardian | `submit-request` ("Send registration request") | `submitted` | 02:23:07.110 | `2026-09-20T02:23:07.479105Z` | 369 ms |
| 3 | **coach** | `review-request` ("Review request") | `under-review` | 02:27:29.546 | `2026-09-20T02:27:30.067334Z` | 521 ms |
| 4 | **coach** | `request-changes` ("Request changes") | `missing-info` | 02:30:30.001 | `2026-09-20T02:30:30.358434Z` | 357 ms |
| 5 | guardian | `resubmit-request` ("Resubmit request") | `submitted` | 02:34:26.568 | `2026-09-20T02:34:26.878635Z` | 311 ms |

### The two-party proof, as stored

    "history": [
      { "at": "2026-09-20T02:23:07.479105Z", "event": "Registration request submitted",
        "byFanId": "fan-soccer-guardian-1" },
      { "at": "2026-09-20T02:27:30.067334Z", "event": "Coach review started",
        "byFanId": "fan-soccer-coach-1" },
      { "at": "2026-09-20T02:30:30.358434Z", "event": "Coach requested changes",
        "byFanId": "fan-soccer-coach-1", "comment": "Coach-needs-insurance-proof" },
      { "at": "2026-09-20T02:34:26.878635Z", "event": "Guardian resubmitted request",
        "byFanId": "fan-soccer-guardian-1" }
    ]
    "guardianFanId":      "fan-soccer-guardian-1"
    "coachReviewerFanId": "fan-soccer-coach-1"

Two distinct fans on one instance, each written by `$actor` at the moment that fan tapped.

### Typed values settled against the stored row, not the screen

`adb shell input text` truncates silently and a horizontally-scrolling field shows a plausible
prefix, so every typed value was read back out of `instance_data`. All nine survived byte-exact:

| Field | Stored value | chars |
|---|---|---|
| `caseTitle` | `Reg-2026-Nils` | 13 |
| `playerLabel` | `Nils-T` | 6 |
| `requestDetails` | `Season-registration-live-write` | 30 |
| `registrationFeeLabel` | `USD-140` | 7 |
| `waiverTitle` | `Season-Waiver-2026` | 18 |
| `waiverVersion` | `v2.0` | 4 |
| `waiverUrl` | `https://example.org/waiver2.pdf` | 31 |
| `missingItems` (transition input) | `["ProofOfInsurance"]` — stored as a real list | — |
| `reviewerComment` (transition input) | `Coach-needs-insurance-proof` | 27 |

A first attempt to fill the create form using keyboard TAB traversal concatenated two values into one
field; it was **cancelled, not submitted**, and the form was refilled field-by-field. No corrupted
value reached the engine — the stored row above is the proof.

### The `createInstance` side-effects also fired

`submit-request` declares two `createInstance` effects, and both produced real rows:

| workflow_type | instance_id | state | created_by_fan_id |
|---|---|---|---|
| `soccer-registration-payment` | `…_soccer-registration-payment_albde74evywc` | `unpaid` | `fan-soccer-guardian-1` |
| `soccer-waiver-document` | `…_soccer-waiver-document_ks7nnx5a4l4y` | `unread` | `fan-soccer-guardian-1` |

## Where I stopped, and why

**Stopped at `submitted`, having proven every transition the guards legitimately allow this pair to
fire.** The remaining terminal state, `approved`, was **not** reached, and its absence is correct
behaviour rather than a failure of the walkthrough:

`approve-request` is guarded by
`{ allowedRoleIds: ["soccer-coach"], formula: "waiverCheckpoint == 'acknowledged' && paymentCheckpoint == 'paid'" }`.
The row holds `waiverCheckpoint: "unread"` and `paymentCheckpoint: "unpaid"`, so the formula is
false. **This was confirmed empirically, not merely read:** on the `under-review` card the coach was
offered exactly **"Request changes"** and **"Reject request"**, and **"Approve and add to roster" did
not render**. The guard is working.

Neither checkpoint is writable from this workflow. Both are set by cross-type `relatedInstance`
effects on the two sibling workflows created in step 2:

- `waiverCheckpoint → "acknowledged"` by `acknowledge-latest-version` on `soccer-waiver-document`
  (guardian-guarded). **Not exercised in this session** — it belongs to that workflow's own row, and I
  make no claim about it here.
- `paymentCheckpoint → "paid"` by `record-offline-payment` on `soccer-registration-payment`
  (`allowedRoleIds: ["soccer-coach"]`).

**The payment leg is blocked, and this is an already-known defect rather than a new finding.** It is
the "guarded role cannot see the instance" shape recorded in `CLAUDE.md` for this exact community. I
confirmed it holds at the package and empirically:

- the only binding rendering a `soccer-registration-payment` instance in state `unpaid` is
  `tabId: "giving"`, and that tab is `visibleRoleIds: ["soccer-guardian"]`;
- its other binding is `tabId: "home"` restricted to `states: ["paid", "refunded"]`, so an `unpaid`
  row does not render there;
- **the coach's tab bar in this session showed Home / Schedule / Coach & Owner / Team and no
  Payments tab**, while the guardian's showed Payments.

So the only transition that can satisfy half the `approve-request` formula is guarded to a role that
has no surface on which to fire it, and `approved` is therefore unreachable through the product UI.

I did **not** escalate around this by calling the workflow service directly, and did not substitute
the generated `riverside-youth-soccer-admin` for the package's `soccer-coach` domain role. Both would
have manufactured a state no real user can reach.

## What this manifest does not claim

- It does not claim `approved` is reachable, or that the payment/waiver sibling rows were proven.
- The judge half of this row is carried by pre-existing judge artifacts keyed on
  `"workflowId": "soccer-guardian-join-approval"`; this manifest supplies the walkthrough half only.
- Screenshots are transient (`*.png` is gitignored); the durable evidence is this manifest plus the
  Postgres rows it cites, which were read in the same session as the taps.
