# HARNESS — two-identity arrangement (create as A, act as B) plus date/time creation fields

**Status:** written 2026-10-02, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by:** Root Cause Agent, session key `harness-remote-data-strategy`. **Load-bearing claims
re-verified by me against the cited lines; the citations are exact.**
**Follows:** `9dac864f` (provable-source-state). Read `b25_remote_arrangement.dart` at HEAD first — it
changed in that commit.

## Why these two ship together

Two-identity is the largest remaining gap (~21 rows). Date/time is the dominant unsupported creation
field type (~14 rows). **They co-occur on the same form**, because the field that blocks the row sits
on the *creator's* form — Garden's `garden-volunteer-shift` and `garden-event-rsvp` need both.
Shipping either alone leaves those rows blocked and risks converting a crisp block into a misleading
"unavailable". Garden's four two-identity rows exercise everything here.

## Change 1 — split the planner's one `actorFanId` into creator and actor (correctness, not plumbing)

`planB25RemoteArrangement` takes a single `actorFanId` (`test/b25_remote_arrangement.dart:108`) and
uses it for **both** jobs — verified: prefill resolution at `:170`, and the formula verdict's
`actorId:` at `:195`. Its own doc comment conflates them ("the real fan id that will authenticate
**and** create", `:72`).

Under two identities those diverge:

- prefill `"$actor"` must resolve to the **creator** (fan A) — that is who the product stamps;
- formula verdicts must evaluate with the **actor** (fan B).

Worked case: tool-loan's `if(ownerFanId == $actor, false, true)` must be evaluated with
`ownerFanId = fanA` and `$actor = fanB`, which is **allowed**. With one id it is denied and the row is
wrongly blocked — or worse, mis-synthesized and wrongly passed.

**Do:** take `creatorFanId` and `actorFanId` separately. Where the row's own role cannot create, the
creation-binding search (`:140-158`) drops its `byRoleIds.contains(roleId)` restriction and returns
**which role can create**, so the caller knows who to authenticate as A.

## Change 2 — `excludeFanIds` on the credential helper (same-role rows)

`authenticateEvidenceFanForRemote` derives usernames `loom-<slug>-<n>` starting deterministically at
suffix 1 (`test/workflow_ui_test_harness.dart:2092-2096`). For tool-loan and tool-giveaway, A and B
hold the **same** role (`garden-member`), so calling it twice authenticates the *same* fan twice and
recreates the self-creator wall with extra steps.

**Do:** add an exclusion parameter so B resolves to a different holder. The data exists —
`fan-garden-member-1` and `fan-garden-member-2` are both live with passports (I queried this today).

## Change 3 — date/time creation fields

- The editor is an `InkWell` keyed **`new-<workflowType>-editor-<field>`**
  (`part33_generic_creation_card.dart:193`) opening `showDatePicker`/`showTimePicker` (`:231-271`);
  the card formats the value itself as `yyyy-MM-dd` / `HH:mm`.
- **A value cannot be supplied without the picker.** `_values` is private and pre-populated only from
  `resolvedInitialValues` (`:46`), which comes from the *package's* prefill — never from a caller.
- **Minimal correct implementation:** tap the editor key, `pumpAndSettle`, then tap the dialog's
  **OK**, which accepts `DateTime.now()` / `TimeOfDay.now()` when the field was empty. One tap per
  field.
- **For clock-constrained fields that default is WRONG.** `chess-match-meetup.expiresAt` is guarded
  `isBefore(now(), expiresAt)` by `accept-match`, so accepting today-at-midnight **denies the row's
  own action**. Those need a strictly-future value via the dialog's input-mode toggle, whose entry
  format is **locale-dependent** (`MM/dd/yyyy` under the test locale, not the stored format) — put
  that in one shared helper, not per call site.
- **Do not copy a clock-compared value from the seed.** Seeds carry absolute dates authored weeks
  ago, so a stale `expiresAt` denies today what the package legitimately allows. Synthesize
  relative-to-now **only** for clock-compared fields; the seed stays authoritative everywhere else.

## Change 4 — fix the identifier-space seam before it bites (latent, in just-shipped code)

`_transitionAccountId` reads a fan id out of `instanceData` and gates it through `_fanIdMatchesRole`,
which accepts only `fanId == roleId` or `startsWith('<roleId>-')`
(`integration_test/workflow_ui_evidence_test.dart:4339-4346`, verified). That heuristic was written
for **demo-space aliases** (`garden-member-rina`). A **real** seeded fan is `fan-garden-member-2`,
which can never prefix-match `garden-member`, so the function returns **null**.

Harmless at selection time, where it runs against seed data. But since `9dac864f` the synthetic
selector carries *real* fan ids, so any post-arrangement path calling it silently drops or
misclassifies a transition. **There are five call sites — `:3921`, `:3949`, `:3957`, `:3997`,
`:4311`.** Determine which receive synthetic data and route those through exact matching against the
known `fanA`/`fanB`. **State which of the five you changed and why the others are safe.**

## The between-identities protocol

1. **Resolve BOTH fan ids before creating.** Some creator forms must name fan B —
   `hoa-dues-payment` is board-created and every member transition guards
   `actorEqualsField: payerFanId`, so the board's form must put **B's** id there.
2. Authenticate A, create, capture the instance id. It is server-assigned and survives logout:
   `logout()` clears only locally persisted tokens and "deliberately does not call Keycloak's
   browser-oriented end-session endpoint" (`loom_auth_session.dart:228-245`).
3. Re-authenticate as B. **No extra route-reopen step is needed** —
   `authenticateEvidenceFanForRemote` already calls `openEvidenceTarget` after every successful login
   (`:2110-2115`, the `ea169ea7` fix), so a second call reopens and re-selects automatically.
4. Act as B, then **assert the actor-stamped effect field**, not merely the target state: `sign-up`
   appends `$actor` to `signedUpFanIds`, so assert the read-back **contains fanB** — not that it
   "grew by one". For tool-loan assert `borrowerFanId == fanB`. That is the only check that
   distinguishes *B acted* from *someone acted*.
5. Assert `fanB != fanA` explicitly. Cheap, and it catches Change 2 regressing.

## Do not

- **Do not add browser or SSO-cookie hygiene.** That trap cannot occur here:
  `loginWithTestCredentials` is Keycloak's **direct access grant** — a bare POST with
  `grant_type: 'password'` (`loom_auth_session.dart:164-202`, verified) — so no browser and no cookie
  exist on this path. The 2026-09-08 near-miss was the *device* flow through Chrome. Acting identity
  is already structurally guaranteed by `RemoteLoomAuthApi.signIn` rejecting
  `accountId != token.fanId` (`part39_remote_auth_api.dart:242-252`).
- **Do not build the general fanId-direction engine here** beyond what Garden needs. Garden's
  candidate paths need none (`sign-up` uses `actorInList(present: false)`, satisfied by a fresh
  creation; tool-loan's member path is formula-only). `hoa-dues-payment` is unprovable without it —
  note that and leave it.
- **Do not attempt communities whose creator `roleId` is not community-prefixed** without checking
  live Keycloak first. Masjid's creator role is plain `owner`, deriving `loom-owner-1`; whether the
  seeded account is that or `loom-masjid-owner-1` is **not established**, and the overrides map has
  no entry. Garden's `garden-coordinator` maps cleanly and is confirmed live.
- **Do not run a capture to verify.** `--mode targeted-precheck` currently overwrites canonical
  manifests for phases it did not run — a separate open defect. If you believe a device run is
  needed, say so and stop.
- **Do not touch `docs/references/**`** — hard-locked. No package edits are needed.

## Verification

- Tests that **fail before and pass after**, run against the un-fixed code first: a two-identity plan
  where creator and actor differ must evaluate the creator-deny formula as **allowed**; and a
  same-role row must resolve two *distinct* fans.
- Add a plan-time `readGuard` gate (evaluate `machine.visibility.readGuard` against the synthetic
  data with B as viewer; throw out-of-scope naming it). No current Garden row needs it — all four
  targets are `membersOnly`/`public` — but it converts a future silent dead-end into a crisp block
  for about three lines.
- All five suites, skip counts before pass counts: demo **276** (0 failed, 0 skipped), app shell
  **448** (+2), engine **345** (+1, both credential sets), service **168** (+1, the one skip being
  the App Access one and **not** PostgreSQL), judges **525**. All measured green by me on 2026-10-02,
  so any movement is yours. **If you lack Postgres credentials, say so** — more skips means your run
  proved less.
- `flutter analyze` on the demo app: **3** pre-existing issues; take the count from flutter's own
  `N issues found` line. A fourth is yours.
- **Report what you actually ran.** The last four dispatches in this programme each exited status 0
  having reported only their intent and produced no suite total. If you cannot complete verification,
  say which parts you did not do rather than describing what you were about to do.
