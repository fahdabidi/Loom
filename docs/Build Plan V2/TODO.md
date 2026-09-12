# Live TODO — cross-effort rollup

**This is an index, not a memory.** One line per open item, newest/most-relevant first, each linking to its
full entry (context, source, exact wording) in the owning tracker's own `## 8. Live TODO / Next Steps Queue`
section (`docs/Build Plan V2/Tools/reference-tracker-template.md` defines that section's shape and the fixed
tag taxonomy used everywhere below). Never write item detail directly here — if you're about to write more
than one line for an item, that content belongs in the tracker, not here.

**How this file gets updated:** propose-then-promote, never a dispatched agent editing this file directly.
An Implementation Agent proposes next steps in its own STATUS.md (`## Proposed next steps`); during your own
independent-verification step, you review that proposal, write the confirmed items into the owning tracker's
§8, and add/remove the matching one-line rollup here. Every `call_*.sh` dispatch script prints a reminder
banner at completion so this step is never silently skipped — see `docs/Build Plan V2/Tools/README.md`'s core
pipeline step 5.5.

**Use the Root Cause Agent (`data/call_root_cause_agent.sh`) for two jobs, across every tracker this
file rolls up, not only the one it's traditionally been used for.** (1) To scope a non-trivial change
*before* writing an implementation ticket — what it actually touches, the real mechanism, what it would
break — rather than writing a ticket from an assumed mechanism and finding out it was wrong a full
implementation round later. (2) Its standing job: anything resisting normal investigation — a stubborn
defect, a stalled walkthrough, an unclear suite failure — goes to it before spending more implementation
rounds guessing. Never write a ticket that asserts a mechanism nobody has actually traced.

**Verification sweep 2026-08-24.** Every checkable claim below was re-measured against the working tree
rather than carried forward, and nine items closed on measurement alone — they had been fixed by later work
and never struck. Suite baselines quoted inside older tracker entries are stale by construction; the current
numbers are judges **432**, app shell **271**, engine **281 (+3 skipped)**, demo **156**, zero failures on
Windows.

**Backend-integration sweep 2026-08-26/27.** The app now runs on the real backends by default and the
document library exists end to end. Current baselines: judges **434**, app shell **307**, engine **299
(+4 skipped)**, workflow service **75 (+5)**, demo **160**, app-access **49**.

**A pattern this sweep kept finding: declared and never read.** Seven constants, fields or code paths
existed and nothing consumed them — `sharingGrantable`, a state `readGuard` under a non-`guarded`
default, `explicitReaderFanIds` (`writableBy: None`), the renderer contract's `calendar`
surface-family, `SurfaceQuery.dateWindowStart/End`, the engine's `workflowType == 'notification'`
delivery branch, and `dueNotifications` itself. None failed anything. **A grep for a declaration
proves it exists, not that anything reads it** — check the consumer.

**A measurement caveat worth carrying.** Two sweeps run that day were wrong in the same way: they read an
artifact instead of the code path that consumes it. `grep actorIdentities` over the packages returned zero
and was read as "packages declare no identities" — they are *derived* from `roles[]` at load. A role
cross-check that ignored `_roleIdsForB25Role`'s synonym fallbacks reported 11 blocked rows when the real
number is 5. Both had been "validated", but only against cases of one kind. **Validate a sweep against a
known answer for every kind of thing it claims to find, not just one.**

**Restructured 2026-09-12.** This file had drifted into the opposite of its own stated design:
87 closed rows against 36 open ones, multi-paragraph entries where the header demands one line,
and two tags (`needs-spec-decision`, `needs-user-decision`) outside the fixed taxonomy. The order
below is deliberate — **what unblocks the production bar first**. Nothing was deleted: every open
row's full text is in [TODO-open-detail.md](TODO-open-detail.md), and every closed row is in
[TODO-closed.md](TODO-closed.md).

**The bar, re-measured 2026-09-12 rather than recalled** (`check_b25_status.sh`): **72 real rows ·
walkthrough half 10 · judge half 57 · both halves 10**. So 47 rows already hold a judge artifact and
lack only a live walkthrough — class 4 below is the single biggest lever, and nothing in class 3 or 5
moves the bar until those walkthroughs run.

**Off-taxonomy tags retired.** `needs-spec-decision` and `needs-user-decision` were never in the
template's fixed set. Both are now `blocked` — the template's own tag for "can't proceed until a named
external thing resolves" — with the decision stated as one answerable question in class 2, so they can
be batched rather than rediscovered one at a time.

## Open

### 1. Release blockers

- [ ] `new-ticket` — Live cluster holds state that exists nowhere in git (`test-fan-alice`/`test-fan-bob` and their `fanId` claims) — [detail](TODO-open-detail.md#row-197)
- [ ] `new-ticket` — 68 seeded accounts share one password (`LoomTest123!`) — doubled since first written — [detail](TODO-open-detail.md#row-199)
- [ ] `new-ticket` — Rotate three exposed secrets before GA — Google client secret, Facebook app secret, DeepSeek API key — [detail](TODO-open-detail.md#row-298)

### 2. Decisions owed by the user

- [ ] `blocked` — `deriveInstanceRoles` picks the FIRST `actorEqualsField` guard — array order is not a business-party selector — [detail](TODO-open-detail.md#row-248)
- [ ] `blocked` — A payment-service stub needs a service-backed transition binding specified first — grammar gap, stops and asks — [detail](TODO-open-detail.md#row-251)
- [ ] `blocked` — Field-label humanization disagrees with itself across 4 sites in `part18`/`part26`/`part28` — [detail](TODO-open-detail.md#row-256)
- [ ] `blocked` — Garden Club: a silent borrower strands the owner's own listing, and there is no coordinator override — [detail](TODO-open-detail.md#row-259)
- [ ] `blocked` — `queryInstances` has no date-window parameter, so every calendar tab pages the whole instance set — [detail](TODO-open-detail.md#row-275)

### 3. Ready to ticket

- [ ] `new-ticket` — A product doc contradicts itself internally — it disclaims rows in its header while its own tables still count them — [detail](TODO-open-detail.md#row-158)
- [ ] `new-ticket` — 11 B25 evidence manifests predate package-identity recording, so they cannot be checked for staleness — [detail](TODO-open-detail.md#row-160)
- [ ] `new-ticket` — pass-42 blockers — `c14` vision review is ~97% scaffold (7 of 204 screens carry real evidence) — [detail](TODO-open-detail.md#row-161)
- [ ] `new-ticket` — ONE defect behind three rows: all three generic form builders fall through to a plain `TextFormField` for every type but `bool`/`date`/`time` — so `fanId[]`, `image`, `url` collect free text — [detail](TODO-open-detail.md#row-269)
  - [ ] `new-ticket` — ↳ a `platform-connection` invite can be addressed to a fan who can never answer it — [detail](TODO-open-detail.md#row-210)
  - [ ] `new-ticket` — ↳ `participantFanIds` mixes role ids and fan ids in one `fanId[]` field — [detail](TODO-open-detail.md#row-268)
- [ ] `new-ticket` — Backlog of deferred polish findings (ISO-8601 humanization, `maxLines` truncation, contradictory chip pairs) — [detail](TODO-open-detail.md#row-297)
- [ ] `new-ticket` — Membership-assignment call needs a fan actor, which a client-credentials token structurally cannot supply — header fixed, identity question open — [detail](TODO-open-detail.md#row-353)

### 4. Live validation — the production bar

- [ ] `new-ticket` — 47 rows already hold a judge artifact and need ONLY a live walkthrough (~20h device time) — the single biggest lever on the bar — [detail](TODO-open-detail.md#row-209)
- [ ] `new-ticket` — Six fakes still back 53 distinct platform APIs while the cluster runs five real services — retiring them is unscoped — [detail](TODO-open-detail.md#row-213)
- [ ] `needs-verification` — Prove reminders live end to end — no reminder-bearing instance exists anywhere in the cluster to observe against — [detail](TODO-open-detail.md#row-245)
- [ ] `needs-live-validation` — §6 step 7 product-doc reconciliation gate — confirmed closed for Cedar Commons HOA only, 9 communities unconfirmed — [detail](TODO-open-detail.md#row-295)

### 5. Unscoped milestones

- [ ] `new-ticket` — Platform phases A, A.1, B, C, D, E, G.4 remain — [detail](TODO-open-detail.md#row-215)
- [ ] `new-ticket` — Outstanding Skill dispatches: DataPortability (6 prefill), AdFree (4 orphan), Camera (rejected), Book Club (held) — [detail](TODO-open-detail.md#row-216)
- [ ] `new-milestone` — Document ACL — `sharedWith` is one flat `fanId` list, so group sharing is impossible. Sequenced AFTER Phase F — [detail](TODO-open-detail.md#row-239)
- [ ] `new-milestone` — Spec-version compatibility hardening — Layer 4 (`requiresCapabilities`) needs a spec decision — [detail](TODO-open-detail.md#row-240)
- [ ] `new-milestone` — Archetype-owned bookkeeping unimplemented, so `grant_access`/`share` can never populate the field a grant reads — [detail](TODO-open-detail.md#row-246)
- [ ] `needs-skill-dispatch` — Book Club regeneration is HELD by user decision — dispatching now would bake in a known loss permanently — [detail](TODO-open-detail.md#row-247)
- [ ] `needs-skill-dispatch` — Ad-Free product-doc enrichment needs redoing under hard rule 14b — the shipped doc is fine; only the rejected dispatch output was not — [detail](TODO-open-detail.md#row-292)
- [ ] `new-milestone` — §7 step 8 — legacy Dart catalog + bespoke-widget removal, now unblocked and far more tractable than 'unscoped' suggests — [detail](TODO-open-detail.md#row-296)

### 6. Needs the Root Cause Agent

- [ ] `needs-debug-agent` — CJM.16 Messages-tab fix, landing with Phase F rather than as its own dispatch — [detail](TODO-open-detail.md#row-288)

### 7. Delegated — detail lives in the owning tracker

- [ ] `new-ticket` — Never derive the community key from the group id — underscored vs hyphenated — [detail](TODO-open-detail.md#row-138)
- [ ] `new-ticket` — Staleness sweep of the migrated blocks — 54 unadjudicated checkboxes, 12 adjudicated so far — [detail](TODO-open-detail.md#row-195)
- [ ] `new-ticket` — The `chmod 444` guard on community JSON is not durable — [detail](TODO-open-detail.md#row-230)

## Closed on evidence, 2026-09-12

Re-measured rather than carried forward, in the sweep that restructured this file:

- [x] Six "dead" queue transitions in Book Club, Camera and Garden — CLOSED 2026-09-12 on this row's own finding — its text already reads `NOT dead; that framing was a premise error, corrected 2026-09-08`. All six transitions route correctly through the shared `EquipmentLoanArchetypeCard`.
- [x] App Access policy endpoints had no caller authorization — Superseded and CLOSED 2026-09-12 by P1 (`loom-backend f134935`), deployed as `app-access 0.3.11` and verified live: a plain fan token on `installCommunityPackage` now returns `403 provisioning_principal_required`. The exposure this row describes is closed in the running cluster, not just in source.
- [x] Masjid over-grant root cause — the platform had no notion of role KIND — Superseded and CLOSED 2026-09-12 by P3 (`loom-backend 1b9b320`, `role_kind` + `RoleGrantCompatibilityValidator`) and P5 (`4668822`, actor-attributed policy audit), both deployed in `app-access 0.3.11`. The platform now has the notion of role KIND whose absence this row identified as the root cause.
- [x] Remote fixture upload for `hoa-member-document` instances — CLOSED 2026-09-12 on this row's own finding — its text already reads `OBSOLETE AS FRAMED, 2026-09-10`: the fixture step it describes cannot be performed because package seed data populates only the local engine, which is the 2026-09-07 decision, not a defect.

## Closed

Moved verbatim to [TODO-closed.md](TODO-closed.md) — 87 rows, kept rather than deleted. The
template's rule is that a closed row's rollup line leaves this index once closed; it had never
been applied, which is why the open queue was buried.
