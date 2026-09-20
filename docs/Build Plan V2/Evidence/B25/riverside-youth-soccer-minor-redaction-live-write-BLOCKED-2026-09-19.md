# B25 live-write evidence — Riverside Youth Soccer `soccer-minor-redaction` — **BLOCKED**

**Workflow:** `soccer-minor-redaction` in Riverside Youth Soccer
**Outcome:** **Not proven. No `soccer-minor-redaction` row was written, because none can be.**
This workflow has **no create path of its own**. Its only creator is a `createInstance` effect on
another workflow's transition, and that transition is unreachable through the UI for two
independent reasons, both observed live on the device in this session. The bar does **not** move;
it stays at **46**.

This manifest deliberately omits the success phrase the bar tool keys on, so
`check_b25_status.sh` counts it under *manifests recording NOT-proven* and this workflow under
*workflows with ONLY a failed run*. That is the correct accounting.

**Package identity:** `skillVersion: "3.3.0"`, `specVersion: 4`, sha256
`a36df7d62bea301e2e686db11d401027efce93c5e92210564b63569761777504`
(`app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc`;
`cmp`-verified byte-identical to
`docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc`
in this session).

**Date:** 2026-09-20 UTC (device clock 2026-09-19 local, America/Los_Angeles)
**Device:** `emulator-5554`, Windows-hosted, reached from the Loom VM over an ssh reverse tunnel
to :5037. The VM has no AVD.
**Deployed images:** `loom-workflow-service:1.0.8`, `loom/app-access:0.3.11`,
`loom/fan-passport:0.3.1`, `loom-keycloak:phase-c3`. All six `loom` pods `1/1`.
**Engine actually exercised:** remote, from the app's own telemetry rather than assumption —
`LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ scope=ext_youth_soccer outcome=ok status=200`,
observed under **both** identities.

## Control read, before any device interaction

```
select count(*) from workflow_instances where workflow_type='soccer-minor-redaction';  ->  0
```

The query is not broken — the same shape returned five other soccer workflow types with non-zero
counts (`soccer-export-metadata` 1, `soccer-guardian-join-approval` 2, `soccer-practice-schedule` 1,
`soccer-registration-payment` 2, `soccer-waiver-document` 2). So zero is a real absence.

**The same count was still 0 at the end of the session**, as was `soccer-team-roster` — the sibling
instance the same effect would have created. Both are created by the *same* `approve-request`
effect block, so their joint absence is one fact, not two.

## Who the actor is — established from the package, not assumed from the row name

The ticket asked me not to assume a persona. The package is unambiguous: **all five**
`soccer-minor-redaction` transitions guard identically on
`allowedRoleIds: ["soccer-guardian"]` **and** `actorEqualsField: { key: "guardianFanId" }`, and the
read guard is `actorEqualsField: { key: "guardianFanId" }`. The product doc's B25 addendum row
names the persona `guardian`. So the **guardian is the correct actor**, and the capture runs that
recorded `primary_action_unavailable` under the guardian persona were **not** looking at the wrong
role and **not** on the refused side of a correct guard.

They recorded an unavailable action because **there is no instance to act on, anywhere, for anyone.**

| Keycloak user | fan id | role | used here |
|---|---|---|---|
| `loom-soccer-guardian-1` | `fan-soccer-guardian-1` | `soccer-guardian` | yes |
| `loom-soccer-coach-1` | `fan-soccer-coach-1` | `soccer-coach` | yes |
| `loom-soccer-owner-1` | `fan-soccer-owner-1` | `soccer-owner` | no — holds nothing on this path |

No credential was created or reset. `group_membership_role` for group
`loom_communities_riverside-youth-soccer` shows the three package roles cleanly separated across
six fans plus one `riverside-youth-soccer-admin` holder — **no fan holds both `soccer-guardian` and
`soccer-coach`**, so the dual-role escape discussed below does not exist and was not manufactured.

**Both Chrome and app data were cleared before each of the two sign-ins, and each clear is proven
rather than asserted.** After `pm clear` on both, the app rendered
`LoomAuthNotLoggedInException: No Loom authentication session is stored; login is required`, and
Keycloak then presented a **real, empty login form** at `192.168.56.10:30082` — not a silent SSO
re-issue. Every typed credential was read back off the device in full (`loom-soccer-guardian-1`,
`loom-soccer-coach-1`, and `LoomTest123!` revealed with the eye toggle) before submitting, and each
was typed in short chunks to defeat the `adb shell input text` truncation trap.

## Why the row cannot exist — the creation chain, and where it is severed

`soccer-minor-redaction` declares **no `kind: "create"` action** on either of its two render
bindings. Its sole creator is this effect on `soccer-guardian-join-approval`'s `approve-request`:

```json
{ "op": "createInstance", "workflowType": "soccer-minor-redaction",
  "fields": { "registrationCaseId": "{id}", "playerLabel": "{playerLabel}",
              "guardianFanId": "{guardianFanId}", ... } }
```

and `approve-request` is guarded:

```json
"guard": { "allowedRoleIds": ["soccer-coach"],
           "formula": "waiverCheckpoint == 'acknowledged' && paymentCheckpoint == 'paid'" }
```

Both checkpoint fields are `writableBy: "effect"` on the registration, and each has exactly **one**
writer, in a *different* workflow, via a `relatedInstance` effect. Both writers are unreachable.

### Severance 1 — `paymentCheckpoint` can never become `paid` (coach has no surface)

`paymentCheckpoint` is written only by `record-offline-payment` on `soccer-registration-payment`:
`{ "op": "set", "key": "paymentCheckpoint", "value": "paid", "relatedInstance": "registrationCaseId" }`.
That transition is guarded `allowedRoleIds: ["soccer-coach"]`. The payment workflow declares two
render bindings: `tabId: "giving"` for all five states, and `tabId: "home"` for `paid`/`refunded`
only. The `giving` tab is `visibleRoleIds: ["soccer-guardian"]`.

So the coach-only transition lives on a guardian-only tab, and the one coach-reachable binding is
gated on `paid` — the state that transition exists to produce.

**Re-verified live today rather than quoted from the 2026-09-08 manifest that first found it**
(blockers rot; this one had not):

- As `fan-soccer-guardian-1` the tab bar is **Home, Schedule, Payments, Team, Documents, Messages**.
- As `fan-soccer-coach-1` it is **Home, Schedule, Coach & Owner, Team, Documents, Messages** —
  **six tabs, no Payments.** The bar was scrolled to both ends under both identities to confirm
  nothing was clipped.
- The coach's **Home** tab was scrolled to its end: it renders the practice-schedule card and the
  **two** join-approval cards, then `Local package details`. No payment card.
- The coach's **Coach & Owner** tab was scrolled to its end: same, no payment card.

The control that makes those absences meaningful: the coach's own surfaces rendered other
workflows' cards correctly in the same pass, and the guardian saw a Payments tab minutes earlier on
the same build. The query works; the absence is real.

### Severance 2 — `waiverCheckpoint` can never become `acknowledged` (NEW, found in this session)

`waiverCheckpoint` is written only by `acknowledge-latest-version` on `soccer-waiver-document`,
which **is** guardian-guarded and **did** render. I signed in as `fan-soccer-guardian-1`, opened
**Documents**, confirmed by its version badge that I was on the **v2.0** card — the waiver linked to
registration case `…_1p5co7fymx4k`, not the older v1.0 card — and tapped **Acknowledge waiver** at
`02:51:50.168Z`.

**The app refused it:**

> Could not record your document state. It is unavailable.

**Postgres confirms nothing was written.** The waiver row `…_ks7nnx5a4l4y` is still `unread`, its
`acknowledgementHistory` is still `[]`, and its `updated_at` is still `02:23:07.530Z` — the
`submit-request` `createInstance`, 28 minutes earlier and untouched by my tap.

**This is a real app-shell gate, not a service outage, and the distinction was checked rather than
assumed.** `_applyTransition` maps the package's `action: "acknowledge"` to a document member-state
update and then refuses when `_loadingMemberState || _memberStateUnavailable || _document == null`
(`part36_engine_native_marketplace_surface.dart:1598-1605`). The card rendered the
`document-library-no-stored-document` branch — literally *"No stored document yet."* — which is set
at `:1300` when `client.listForInstance` **succeeds and returns an empty list**, with
`_memberStateUnavailable = false`. A service failure takes a *different* branch with a different
message. So the Document Library answered fine and genuinely holds nothing for this instance.

And it can hold nothing, by construction: this community's waivers are **link-published, never
uploaded**. The instance is created by a `createInstance` effect carrying a `documentUrl`, and the
only version transition is `prepare-new-version`, labelled *"Publish linked waiver version"*, which
sets `documentUrl`. The card offered no upload affordance to the guardian — its actions were
*Open document* ×2, *Acknowledge waiver*, *Request access*, *Publish linked waiver version*,
*Download document*, *Ask coach*.

**One thing I could NOT establish, stated as such.** I did not find a positive control — a
document card anywhere that *does* acknowledge successfully — so I cannot say whether this gate is
satisfiable for any community today. What I can say is narrower: across the whole live database, no
row of any document-shaped workflow has ever reached an `acknowledged` state
(`soccer-waiver-document` 2 rows, both `unread`; `hoa-member-document` 1 `published`, 1 `deleted` —
and that second workflow has a different state machine, so it is not a control for acknowledgement
at all). That is *consistent* with the severance being general rather than specific to this row, and
it is **not** evidence of it, because nobody may have tried. The severance for *this* row is
established by the observed refusal plus the code path, not by that query.

**So a link-published waiver can never be acknowledged**, because the shell gates acknowledgement on
a *stored* Document Library object that this community never creates. That is a second, independent
severance of the same chain, and unlike severance 1 it was not previously recorded.

## What I did prove live, and where I stopped

I advanced the chain as far as the guards legitimately allow. The furthest legitimate point is the
registration reaching `under-review`, and I drove that transition for real.

| # | Actor | Transition | from → to | Stored evidence |
|---|---|---|---|---|
| 1 | `fan-soccer-guardian-1` | `acknowledge-latest-version` | — | **refused by the app**; waiver row unchanged at `unread`, `acknowledgementHistory` `[]` |
| 2 | `fan-soccer-coach-1` | `review-request` | `submitted` → `under-review` | `current_state = under-review`, `updated_at = 2026-09-20T02:57:25.426Z` |

**Transition 2 is a genuine live write with a measured tap→write gap.** Tap at
`02:57:25.149Z`, stored at `02:57:25.426Z` — **277 ms**. The engine appended a fifth history entry,
`{"event":"Coach review started","byFanId":"fan-soccer-coach-1","at":"2026-09-20T02:57:25.426550Z"}`,
and the card rendered it. This is a state claim settled against the stored row, not against a tap
that returned.

Instance acted on: `community_riverside_youth_soccer_soccer-guardian-join-approval_1p5co7fymx4k`,
created `2026-09-20T02:21:48.639Z` by `fan-soccer-guardian-1`. Final stored state at session end:

```
current_state = under-review
waiverCheckpoint = unread      <- severance 2
paymentCheckpoint = unpaid     <- severance 1
```

**I left the registration at `under-review`.** That is a legitimate resting state with two live
exits for the coach, and it is where the chain genuinely stops. I did not escalate to
`fan-soccer-owner-1` (the owner holds nothing on this path) and I did **not** substitute the
generated `riverside-youth-soccer-admin` role for either package domain role.

### The decisive frame — the guard withholding the action, observed

With the registration in `under-review` and both checkpoints stale, the coach's card offered exactly
**two** actions: **Request changes** and **Reject request**. **"Approve and add to roster" was
absent.**

That is the whole finding in one screen, and it is a *discriminating* observation rather than an
empty one: `under-review` has **three** declared exits and **two** rendered. So the surface is
working and the engine is evaluating the formula guard correctly against live server state — it is
the guard's inputs that can never be satisfied. Had all three been missing, this would have proved
nothing about the formula.

## Why this is not fixable from where I stand

- It is **not** a seeding gap. Every role has two holders; the accounts authenticate; the guardian
  is the correct actor and reached the right surfaces.
- It is **not** a provisioning gap. No role is missing.
- It is **not** a role-substitution problem to be worked around. Making one fan hold both
  `soccer-guardian` and `soccer-coach` would satisfy both the `giving` tab's `visibleRoleIds` and
  `record-offline-payment`'s guard — and it would be a live authorization change made to
  manufacture evidence for a self-dealing path the product does not intend. I did not do it.
- **Severance 1 is a package authoring gap** (a coach-guarded transition with no coach-visible
  binding), and the package is Skill-owned. A coach-visible binding — the `admin` tab, or widening
  the `home` summary's `states` — would close it.
- **Severance 2 is an app-shell/product gap**: acknowledgement is gated on a stored Document Library
  object, but the grammar supports link-published documents that never produce one. Either the
  shell must allow acknowledgement of a link-published document, or the platform needs a document
  the effect can store.

Both must close before `soccer-minor-redaction` can be created at all. Closing either alone leaves
`approve-request`'s formula unsatisfied.

## Scope — this severance blocks TWO bar rows, not one

I was handed one row, but `approve-request`'s effect block creates **two** instances, and both are
B25 bar rows for this community:

```json
{ "op": "createInstance", "workflowType": "soccer-team-roster",     ... }
{ "op": "createInstance", "workflowType": "soccer-minor-redaction", ... }
```

`soccer-team-roster` is row 2 of Riverside's 8 addendum rows, and it has **no live-write manifest at
all** — checked, not assumed. Its live count in Postgres is **0**, alongside
`soccer-minor-redaction`'s 0. It is uncreatable for exactly the same reason and by exactly the same
two severances.

So the repair that unblocks this row unblocks a second one at no extra cost, and any ticket written
from this manifest should be scoped to the **chain**, not to `soccer-minor-redaction` alone.

## Judge half

This row already has judge coverage — `soccer-minor-redaction` is named as a `workflowId` in the
B25 judge/remediation artifacts under `docs/Build Plan V2/Evidence/B25/`. The judge half is not
what is missing. **The walkthrough half is, and it is blocked, not merely undone.**

## Honest summary

- `soccer-minor-redaction` rows written this session: **0 of 1 attempted** — and 0 is the only
  achievable number today.
- Transitions of `soccer-minor-redaction` proven: **0 of 5**.
- Live writes performed on the enclosing chain: **1** (`review-request`), fully settled against
  Postgres.
- Actions refused by the product and recorded rather than papered over: **1**
  (`acknowledge-latest-version`).
- Bar: **46 → 46.** It does not move.
