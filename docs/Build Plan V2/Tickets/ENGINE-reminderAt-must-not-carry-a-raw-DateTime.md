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


## MEASURED AGAINST THE DEPLOYED CATALOG 2026-10-10 — this supersedes the repo-side estimate above, which was wrong

The section above estimated the population from package-level `reminderEnabled` mentions and said
plainly that a per-block audit was still owed. **That audit is now done, against the live
`workflow_definitions` and `workflow_instances` tables, and the estimate was wrong in both
directions.**

**First, the key.** A reminder block's gate is **`enabledField`** — the block's real keys are
`anchorDateField`, `anchorTimeField`, `enabledField`, `leadHours`, `leadHoursField`. My first query
guessed `enabledWhen` and a text match on `reminderEnabled`, and produced verdicts that were right
only by accident for three types. **Read the keys the data uses before trusting any gating column.**

| Deployed type | `enabledField` | Live instances |
|---|---|---:|
| `ad-off-community-checkout` | `reminderEnabled` | 5 |
| `chess-match-meetup` | `reminderEnabled` | 0 |
| `hoa-facility-reservation` | `reminderEnabled` | 4 |
| `book-meeting-rsvp` | **absent — UNGATED** | 2 |
| `garden-event-rsvp` | **absent — UNGATED** | 6 |
| `garden-tool-loan` | **absent — UNGATED** | 4 |
| `garden-volunteer-shift` | **absent — UNGATED** | 0 |
| `hoa-dues-payment` | **absent — UNGATED** | 2 |
| `mosque-event-rsvp` | **absent — UNGATED** | 1 |
| `plant-exchange-submission` | **absent — UNGATED** | 2 |
| `soccer-practice-schedule` | **absent — UNGATED** | 1 |

**So the blast radius is 8 ungated types carrying 18 live instances** — of 85 deployed definitions,
11 of which declare a reminder, and 196 live instances. Not zero, and not all 11.

**Two things corroborate the measurement rather than resting on it.** The deployed count of 11
reminder-declaring definitions matches the repo-side count of 11 blocks exactly, so catalog and
packages agree. And the split reproduces CLAUDE.md's documented Cedar case precisely without being
told: `hoa-dues-payment` is **ungated** — the workflow recorded as 500ing — while
`hoa-facility-reservation` is **gated** — the one recorded as its healthy control.

**And it refutes the package-level proxy I used first.** Cedar mentions `reminderEnabled` 11 times, so
a per-package count called it gated; its *dues* block has no `enabledField` at all. A package-level
signal cannot settle a per-block question, which is why the caveat was in the ticket — and why it
needed this query rather than more reading.


## RULED OUT 2026-10-10: nothing masks this, and that absence is probably CORRECT

Before dispatching, I checked the one thing that could have made this defect unreachable — a JSON
encoder that handles `DateTime`. **There is none.** `toEncodable` appears **zero** times in both
`loom_workflow_service/lib` and `loom_workflow_engine/lib`, while the control shows the service calls
`jsonEncode` at **32 sites**. `jsonEncode` without a `toEncodable` throws `JsonUnsupportedObjectError`
on a `DateTime`, which is exactly the error recorded against Cedar's listing. **So the defect is real
and unmasked**, and this check is why that is now stated rather than assumed.

**Why I checked at all, and the lesson that prompted it:** the sibling one-row-stall ticket turned out
already implemented, because the handling existed *elsewhere* than the line the ticket cited. Verifying
a cited line proves the mechanism is intact; it does **not** prove the consequence still reaches the
surface. Those are two different claims and this ticket now carries both.

**One observation, deliberately NOT a recommendation.** 32 unguarded `jsonEncode` sites means *any*
`DateTime` reaching instance data breaks a response, not only one arriving via `reminderAt`. The
obvious belt-and-braces move is a `toEncodable` that ISO-formats dates globally. **Do not add one as
part of this ticket, and think twice before proposing it separately:** it would convert a loud 500
into a silent coercion, so the next writer that leaks a `DateTime` would ship quietly instead of
failing. This project consistently prefers the loud failure, and the fix belongs at the writer. If a
global handler is ever wanted, it is a deliberate design decision with that trade stated, not a
hardening tweak smuggled into a one-line fix.

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

- All five suites, **sequentially**, skip counts before pass counts: demo **324** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL). The engine and
  service suites are the ones this change can move, so account for any delta there by name.
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a **rotating** test name —
  confirm a `TimeoutException` and an isolated pass before believing it.
- `flutter analyze` on the demo app: **3** pre-existing issues, from the tool's own `N issues found`
  line, with the working directory stated.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is correct for anything you genuinely could not run.

## DO NOT TRY TO CONFIRM THIS FROM THE SERVICE LOG — measured 2026-10-10, it cannot work

I attempted exactly that, reasoning that 18 live instances of ungated reminder types should make the
failure appear in `workflow-service` logs on real traffic. **The service does no request logging at
all:** `\bGET\b|\bPOST\b` matches **0** lines and `HTTP/[0-9]` matches **0**, across both the current
container (466 lines) and the previous one (3362 lines). So `JsonUnsupportedObjectError` = 0 and
`Instance of 'DateTime'` = 0 are **not evidence of anything** — the channel never carries the signal.

**And my "control passed" claim was itself false, which is the part worth copying.** I counted 130
lines matching `GET|POST` case-insensitively and read that as "request logging exists". All 130 were
the word **`postgres`**. The tell was the *next* command printing nothing when I asked to see four of
those lines — an empty result immediately after a confident count is the signal that the count
matched something other than what I meant.

**So this defect's reachability rests on the data plus the code, which is sufficient** — 8 ungated
deployed types, 18 live instances, and the assignment at `local_workflow_engine_api.dart:2720` — and
on the Cedar 500 this project already recorded by observation. **Confirming it live needs a real
authenticated request against an affected instance, not a log grep.**

**One benign thing seen while looking, recorded so nobody chases it:** the log's dominant content is
13 `Workflow service startup failed; retrying Postgres in 5 seconds` frames
(`SocketException: Connection timed out` then `Connection refused`). That is the pod starting before
Postgres is ready, handled by the service's own retry loop — it **succeeded**, the log ends with
`Document storage ready on minio…`, and the pod is `Running ready=true`. Not a defect, and not
related to this ticket.
