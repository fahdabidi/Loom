# ENGINE — `reminderAt` is assigned a raw `DateTime`, so any ungated reminder breaks JSON encoding

**Status:** written 2026-10-10, **NOT dispatched**. VM auth is expired so no dispatcher is reachable;
this is ready to go the moment it is back.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Traced by me to the exact line, with the fix's shape demonstrated in the same file** — so this did
not need a root-cause scoping dispatch. What it does still need is the per-block audit below, and
that is part of the work rather than a precondition.

## The defect

`local_workflow_engine_api.dart:2720`:

    final dueAt = reminder.dueAtFor(computed);          // :2716
    // ...
    if (dueAt != null) computed['reminderAt'] = dueAt;  // :2720  <- a DateTime

`WorkflowReminder.dueAtFor` returns **`DateTime?`** (`workflow_models.dart:1274`). `computed` becomes
the instance data that is later JSON-encoded, producing exactly the
`JsonUnsupportedObjectError: Instance of 'DateTime'` this project has recorded — surfacing as a **500
on instance listing** for the affected workflow.

**This is the shared engine, so it is not a per-community defect.** Cedar and Garden are two
communities reaching one bug. The earlier Cedar write-up names `reminderAt` as the leak but not the
line; it is `:2720`.

## The fix, and its shape is already in this file

`:945-950` resolves the identical value deliberately, and it accepts a String:

    final rawDueAt = declared ?? computed['dueAt'];
    final DateTime? dueAt = switch (rawDueAt) {
      final DateTime value => value,
      final String value => DateTime.tryParse(value),
      _ => null,
    };

**That sibling is the evidence for what `:2720` should store: an ISO-8601 string.** The read path
already expects `dueAt` may arrive as a String and parses it, so writing `dueAt.toIso8601String()` is
consistent with the shape the engine already consumes rather than a new convention. **Confirm that
reading before changing the write** — if any consumer requires a `DateTime` object specifically, say
so and stop rather than converting at the call site, because then the question is which shape
instance data owns, and that is a design decision rather than a fix.

**Do not fix this by gating the reminder in a package.** Community JSON is Skill-authored, the
packages are conformant, and the platform is the defect — the same layering rule this project applies
to the `actor`-audience fallback. A package change would also leave every future ungated reminder
broken.

## The population — audit it, do not assume it

Measured by me today across the 10 shipped packages: **11 `reminder` blocks in 7 packages** — Garden
**4**, Cedar 2, one each in Ad-Free, Book Club, Chess, Mosque, Youth Soccer. Camera Club, Data
Portability and Member Social Space have none.

**Four packages mention `reminderEnabled` zero times — Book Club, Garden, Mosque, Youth Soccer —
covering 7 of the 11 blocks.** An ungated reminder is the condition that produces the leak, since
Cedar's healthy control escaped only because its rows never set the gate.

**That count does NOT settle per-block gating and must not be quoted as a row total.** Cedar has 2
blocks and 11 `reminderEnabled` mentions while one of its two is unconditional, so the mention count
is a package-level signal, not a per-block one. **Part of this ticket is to read each of the 11 blocks
and report, per block, whether its reminder is gated and by what** — then state how many workflows the
fix actually repairs. Report that list in your reply.

## Honesty test — it must fail against today's code

- **A unit test over the computed-data resolution asserting `instanceData['reminderAt']` is
  JSON-encodable.** The cheapest honest form is `jsonEncode(instanceData)` succeeding, since that is
  the operation that actually fails in production. Build it on a machine with an **ungated** reminder.
- **Run it against the unfixed engine first and record the verbatim failure.** It must fail with
  `JsonUnsupportedObjectError: Instance of 'DateTime'`. A test that passes both before and after
  proves nothing.
- **Assert the VALUE, not just encodability.** A fix that dropped the field entirely would also make
  `jsonEncode` succeed, and would silently delete a real reminder. Assert the parsed value equals the
  `DateTime` the reminder computes, so encodability cannot be satisfied by omission.
- **Keep `:945-950` green**, and add a case proving the round trip: a stored ISO string read back
  through that `switch` yields the same instant.
- **A/B it:** neutralise only the conversion at `:2720`, confirm the new test fails, restore, and
  `cmp`-verify byte-identical.

## Scope limit

The engine's reminder assignment plus its tests, and the per-block audit report. Do **not** touch any
community `*.jsonc` (Skill-only), the reminder schedule semantics, the
`set_reminder`/`send_reminder`/`deliver_reminder` ownership split — this project records those as three
independent mechanisms that migrations keep collapsing — or the Cedar formula-field theory, which was
already refuted and is not the cause. If another row fails while you work, record its outcome and
continue.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **312** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL). The engine and
  service suites are the ones this change can move, so account for any delta there by name.
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a **rotating** test name —
  confirm a `TimeoutException` and an isolated pass before believing it.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own `N issues found`
  line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is correct for anything you genuinely could not run.
