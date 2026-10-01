# HARNESS — the identity picker opens asynchronously under remote wiring, and ticket B's auth is on the wrong branch

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Follows** [HARNESS-production-wiring-and-direct-grant-auth.md](HARNESS-production-wiring-and-direct-grant-auth.md).
Scoped with the Root Cause Agent (`--session-key harness-remote-auth-branch`); **its enumeration was
short and the population below is mine, verified by grep** — see "Population".

## The evidence this is built on

A `targeted-precheck` capture ran on a real device against the deployed backend, 2026-10-01. Real
`dart` exit 1. It proved the live-backend wiring works and then failed five Garden rows:

    LOOM_BINDING service=workflow-engine mode=remote endpoint=http://192.168.56.10:30083/ outcome=ok   (x670)
    LOOM_BINDING service=auth-token-endpoint ... outcome=ok status=200                                 (x3)
    WORKFLOW_EVIDENCE_RESULT status=fail screenshotStatus=complete b25Proven=0/5 b25RowExecutionFailed=5

**Three of those five are ONE defect cascading**, in package execution order:

| Row | Recorded reason | Actually |
|---|---|---|
| `garden-tool-loan` | `No element` | **origin** — the dialog was not open yet |
| `garden-tool-giveaway` | tap missed, "obscured… `RenderOffstage`" | victim — the late dialog covered this row |
| `garden-export-custom-schemas` | "expected community `ext_garden_club`; found `actor-identity-picker-dialog`" | victim — correct refusal, wrong row blamed |

The remaining two are separate and **out of scope here**: `garden-event-rsvp` stalled waiting for
`spring-workshop`, which is a `workflowInstances` seed that only ever reaches the local engine
(remote communities start empty by design, 2026-09-07), and `plant-exchange-submission` is defect B
below.

## Defect A — the picker dialog now opens after an await, and every caller assumes it opens in-frame

`part01_local_extension_screen.dart:1025` does:

    final accounts = await activeIdentity.authApi.listAccounts(...);   // real HTTP under remote
    ... then showDialog(...)

Locally that future completes inside `pumpAndSettle`, so "tap the button, settle, interact with the
dialog" was safe for months. Under production wiring it is a network round trip, so the dialog opens
**after** the caller has already concluded the dialog is absent — and then opens anyway, during a
later row.

**Fix shape: wait for the dialog with a budget before interacting with it.** The harness already has
`_waitForEvidenceFinder` for exactly this. Two properties matter as much as the wait itself:

- **If the dialog genuinely never opens, the throw must happen with the dialog closed**, so nothing
  leaks into the next row. That is what converts a cascade into a single honest row failure.
- **The stall message must name what was being waited for.** A bare `No element` is what made this
  cost an investigation.

**Prefer ONE shared helper over five copies.** This repo has recorded a rule duplicated five times
being missed a sixth. A single helper that taps the picker button, waits for
`actor-identity-picker-dialog`, and returns only once it is open is the shape to build; the five
sites then call it.

### Population — FIVE sites, not two

Verified by `grep` over `app/apps/loom_communities_demo`, after the scoping agent reported two:

| # | Site | Shape today |
|---|---|---|
| 1 | `test/workflow_ui_test_harness.dart:2126-2131` (`signInEvidenceAccount`) | `pumpAndSettle()` then a **bare** `ensureVisible(specificPerson)` — no wait, no assert. **This is the origin of the cascade.** |
| 2 | `test/workflow_ui_test_harness.dart:1910-1914` (`selectActorIdentity`) | `pumpAndSettle()` then `expect(dialog, findsOneWidget)` — asserts the dialog but does not wait for it |
| 3 | `integration_test/workflow_ui_evidence_test.dart:757` (Mosque B17) | `tap` → `pumpAndSettle` → **`capture('B17_actor_identity_inventory_picker')`** → `tap(find.text('Cancel'))` |
| 4 | `integration_test/workflow_ui_evidence_test.dart:785` (Mosque B18) | same shape, captures `B18_member_actor_identity_picker_dialog` |
| 5 | `integration_test/workflow_ui_evidence_test.dart:849` (Mosque B19) | same shape, captures `B19_member_alternate_leave_unchanged`; **note its cancel round-trip is DESIGNED to restore the start pixels** |

**Sites 3–5 are the dangerous ones and the scoping agent missed all three.** They capture an evidence
frame immediately after the settle, so under remote wiring they would write a PNG *named*
`B18_member_actor_identity_picker_dialog` that actually shows the community route — a frame that is
wrong in the one field nobody re-reads, which is worse than no frame at all. Every one of these must
capture only once the dialog is confirmed open.

## Defect B — ticket B's authentication is behind the wrong discriminator

`integration_test/workflow_ui_evidence_test.dart` ~line 2068:

    if (selector.accountId case final accountId?) { ... seedEvidenceAccounts + signInEvidenceAccount }
    else if (loomAuthSession != null)             { ... authenticateEvidenceFanForRemote }

It branches on whether the row's **selector carries an accountId**, not on whether **remote auth is
active**. `seedEvidenceAccounts` (`test/workflow_ui_test_harness.dart:2095`) hard-`fail`s when the
auth API is not `LocalAuthApi`, which is correct — so a row with a non-null `accountId` dies under
remote. That is `plant-exchange-submission`.

**Remote-active must win the branch.** Keep the existing two blocks untouched and put the remote
check first.

`selector.accountId` is a **demo-identity-space** value derived from a package seed
(`instanceData[actorEqualsField.key]`, or an `actorInList` member matched to the role by prefix). It
has no remote meaning: the seed does not exist remotely, and an instance the walkthrough creates
remotely prefills `$actor` with the authenticated fan. **Do not try to map it to a fan id** —
`authenticateEvidenceFanForRemote` already keys credentials on `roleId` through the documented slug
convention, and the picker's remote account list belongs to the authenticated fan, so the selected id
is the token's own `fanId` and `RemoteLoomAuthApi.signIn`'s anti-impersonation check passes.

`accountId` is non-null for a **minority** of rows (1 of 5 on this run; the other 4 reached the
remote branch and 3 logged in successfully). Do not widen the change on the assumption it is common.

## What this does NOT buy, stated so nobody reports otherwise

**No Garden row goes green from this ticket.** Defect B converts `plant-exchange-submission`'s hard
failure into the same empty-remote-data outcome as `garden-event-rsvp`. Defect A removes three row
failures that were one cascade and leaves one honest failure in its place. The remaining gap — no
rows exist remotely — needs a create path and is **not** in scope; it is
[SCOPING-harness-remote-data-strategy.md](SCOPING-harness-remote-data-strategy.md), which is a
scoping request and must not be dispatched to the implementation agent.

## Do not

- **Do not weaken or delete any assertion**, and do not relax a timeout to make the race go away. The
  fix is to wait for the right condition, not to wait longer for the wrong one.
- **Do not add a blind "dismiss any overlay and continue" recovery.** This repo records
  `_returnToCommunityList` tapping a covered Back button with `warnIfMissed: false` and missing
  silently forever. Assert the expected surface and fail loudly naming the unexpected one.
- **Do not change the between-row `before` assert into a recovery step.** Its refusal is correct
  behaviour and is what surfaced this at all.
- **Do not touch community JSON** (Skill-authored only) or `docs/references/**`.

## Worth doing if cheap, and say so if you skip it

The `before`-mismatch message could name the **previous** row as the likely leaker — `lastRowWalked`
is already in scope. This investigation blamed `export-custom-schemas` when the cause was two rows
earlier; naming the predecessor would have pointed straight at it.

## Verification

- A regression test that **fails before the fix and passes after**. For defect A the honest test is a
  picker whose `listAccounts` completes on a delayed future: assert the caller waits, and assert that
  on a genuine timeout the dialog is **not** left open. Run it against the un-fixed behaviour first —
  a test that cannot fail for the reason it claims proves nothing.
- All five suites, with the skip counts read before the pass counts. **Re-measure the baseline first:**
  commits `8032e602` and `09152970` landed from another session today and added a 193-line test file
  to `loom_auth_session`, so the previously recorded totals (app shell 448 +2, demo 262, judges 525,
  engine 345 +1, service 168 +1) predate the current tree and must be re-derived, not assumed.
- `flutter analyze` clean on both touched packages (the demo app carries 2 pre-existing issues; a
  third is yours).
