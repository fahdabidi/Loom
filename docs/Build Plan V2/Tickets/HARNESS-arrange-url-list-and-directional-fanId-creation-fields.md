# HARNESS — arrange `url` and `list` creation fields, then `fanId` with DIRECTIONAL derivation

**Status:** written 2026-10-05. **DISPATCHED AND SHIPPED as `b11a27c6`** -- verified by my own five-suite run and A/B, not on the agent's word. Device-measured effect: field-type refusals 14 to 1; screenshots 35 to 52. Kept for its reasoning; do NOT re-dispatch.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by** `data/call_root_cause_agent.sh` (session key `b25-arrangement-classes`), then
re-scoped by me against the **current** population, because the class doubled after the readGuard
fix landed. Every claim below I verified by reading the code.

## Why this is now the top increment

The readGuard predictor fix (`28224656`) cleared 14 of 15 false refusals, measured on a device:
`visibility.readGuard` refusals **15 → 1**. The 82 rows reconcile exactly before and after, so the
movement is accounted: **7 of the cleared rows landed in "requires creation field"**, taking that
class from 7 to **14** — now the largest *actionable* arrangement class.

| arrangement sub-class | before | now |
|---|---|---|
| `visibility.readGuard` | 15 | **1** |
| **requires creation field** | 7 | **14** |
| no create action (effect-born) | 10 | 10 |
| later-state | 11 | 11 |
| formula guard | 2 | 2 |
| total | 45 | **38** |

## The exact population — 14 rows, 13 buildable

| # | community | workflow | field | type | part |
|---|---|---|---|---|---|
| 1 | Chess Club | `chess-rules-documents` | `documentUrl` | `url` | **A** |
| 2 | Neighborhood Book Club | `book-reading-material` | `materialUrl` | `url` | **A** |
| 3 | Riverside Youth Soccer | `soccer-guardian-join-approval` | `waiverUrl` | `url` | **A** |
| 4 | Riverside Youth Soccer | `soccer-waiver-document` | `documentUrl` | `url` | **A** |
| 5 | Chess Club | `chess-export-package` | `exportScope` | `list` | **A** |
| 6 | Chess Club | `chess-pairing-queue` | `waitingPlayerNames` | `list` | **A** |
| 7 | Data Portability | `export-schema-listing` | `schemaNames` | `list` | **A** |
| 8 | Data Portability | `export-transfer-verification` | `transferScope` | `list` | **A** |
| 9 | Cedar Commons HOA | `hoa-owner-notification` | `recipientFanId` | `fanId` | **B** |
| 10 | Garden Club | `garden-tool-giveaway` | `coordinatorFanId` | `fanId` | **B** |
| 11 | Garden Club | `garden-tool-loan` | `coordinatorFanId` | `fanId` | **B** |
| 12 | Member Social Space | `platform-connection` | `inviteeFanId` | `fanId` | **B** |
| 13 | Chess Club | `chess-match-result` | `participantFanIds` | `fanId[]` | **B** |
| 14 | Camera Club | `critique-submission` | `photoImage` | `image` | **EXCLUDED** |

**Row 14 is excluded and must stay excluded.** `photoImage` declares `storage: "reference"` — its
value points at uploaded bytes, and uploads are a missing platform service. Typing the seed's
reference string would mint an instance claiming an image that was never uploaded. That is the
placeholder shape this project forbids outright. Leave it refusing and say so in your reply.

## PART A — `url` and `list` (8 rows). Land this independently.

**Both already work; the planner just refuses them.** Verified by reading
`part33_generic_creation_card.dart`: its editor `switch` has cases only for `bool`, `date` and
`time`, so **`url` and `list` fall through to the default plain `TextField`** — byte-for-byte the
same `tester.enterText` path the existing `text`/`textarea` arrangement already drives. The
planner's own comment claiming `url` "needs its own widget interaction" is factually wrong.

And `list` needs no new widget either: the card's normalizer **splits a comma-separated String into
a trimmed, non-empty list** for `type == 'list'` (`part33:143-160`, verified). So join the seed's
list with `', '` and type it.

- Add `'url'` and `'list'` to `b25ArrangeableFieldTypes` (`b25_remote_arrangement.dart:17-24`).
- **The seed stays the data authority.** Use the seed's own value for the field; do not invent a
  URL or a list. A row whose seed has no value for a required field must keep refusing — there is
  already a test for exactly that (`a required field with no seed value is out of scope`), and it
  must stay green.
- Correct the stale `url` comment rather than leaving it to mislead the next reader.

## PART B — `fanId` and `fanId[]` (5 rows). DIRECTIONAL, and this is where it can go wrong.

The card renders `FanIdFormPicker` over the real `communityMembers` directory, so this is
**selection of a real member, never typing** — which matters, because `adb shell input text`
silently truncates identifiers and a truncated fan id still looks valid.

**Filling an identity field is directional, and "pick any member" is wrong in both directions.**
Derive the direction from the row's own candidate guards, not from a default:

- A field the acting fan must **equal** (`actorEqualsField: <field>`) takes the **acting** fan.
- A field a guard requires to be **someone else** — e.g. a formula of the shape
  `if(<field> == $actor, false, true)` — takes a **different** real member.
- A list field whose guard is `actorInList: <field>` must **contain** the acting fan.

Applied to this population, and each of these needs confirming against the package rather than
taken from me: rows 9–12 all appear to need a fan **other than** the actor
(`recipientFanId`, `coordinatorFanId` ×2, `inviteeFanId`), while row 13's `participantFanIds` is
read by `actorInList` guards and so must **include** the actor. **State per row which direction you
derived and from which guard.**

**Two hazards specific to this field, both already recorded in this project:**

- **`participantFanIds` is the field that historically held ROLE ids** rather than fan ids, written
  by an older picker, and `actorInList` guards read it. Fill it with real fan ids from the
  directory. Do not reproduce the legacy aliasing.
- **A fixture whose fan id and role id are the same string cannot discriminate this bug.** Any new
  test must keep the two spaces textually distinct — fan `fan-x-member-1`, role `x-member` — or it
  will pass against both the correct and the incorrect provenance.

## What must NOT be taken down

- **Part A must not be blocked by Part B.** If Part B proves harder than scoped, land Part A, report
  Part B honestly as not done, and say which rows remain. Eight rows banked beats thirteen rows
  attempted and abandoned.
- **Do not touch the other arrangement classes** — the 10 effect-born rows (never create those
  directly; it fabricates provenance the product never produces), the 11 later-state rows, or the 2
  formula-guard rows.
- **If a row fails while you work, record its outcome and continue to the next row.** Do not abort
  the batch.

## Honesty tests — each must be able to FAIL

- **Settle every filled value against the stored row, not the screen.** A field that scrolls
  horizontally shows a plausible prefix while the stored value is short; this project has recorded
  that exact false pass. Assert the DB value equals the intended real fan id / URL / list.
- **A/B both parts.** Neutralise only the new type entries (Part A) and only the direction
  derivation (Part B), confirm the new tests fail, restore and `cmp`-verify byte-identical.
- **Keep the refusing cases green**: the no-seed-value test, and `image` still refusing.
- **For Part B, assert the DIRECTION, not just non-emptiness.** A test that only checks the field is
  populated passes when the wrong fan was chosen — which is the failure that banks evidence under
  the wrong person.

## Expected measurement

Re-run `--mode targeted-precheck --phases B12,B13` with a **scratch `--evidence-root`**. Success is
the field-type sub-class falling from 14 toward 1 (the excluded `image` row), with **no** increase in
`row_execution_failed`. Expect some rows to move to a *different* honest refusal — that is still
success for this ticket. **Do not quote a bar figure:** `targeted-precheck` is
`commitEligible: false`, `b25Proven` on the bar is 0 and `CONFIRMED` is 0.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **304** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a rotating test name;
  confirm a `TimeoutException` and an isolated pass before believing it, and note its assertions are
  about a **spawned subprocess exit code**, so a starved child yields a failed `expect` rather than a
  timeout.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own
  `N issues found` line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct and expected entry for anything you genuinely could not run.
