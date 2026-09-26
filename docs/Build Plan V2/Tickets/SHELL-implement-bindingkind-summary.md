# SHELL — implement `bindingKind`, so `summary` means compact/read-only

**Status:** written 2026-09-25, **NOT dispatched** (user decided: implement it).
**Route:** `data/call_implementation_agent.sh --fresh`.
**UNBLOCKED 2026-09-26. The prerequisite is MET — `check_orphan_summary_bindings.py` reports
0 orphans, exit 0.** ~~BLOCKED ON [SKILL-summary-orphan-primary-bindings.md](SKILL-summary-orphan-primary-bindings.md); five states across three communities lose reachable actions.~~

**The "five orphan states" framing was wrong and you must not act on it.** Re-measured: only **two**
were real, and both are fixed — Book Club's `book-search-ai-digest`/`saved` (`d87f9875`) and Ad-Free's
`ad-off-community-checkout`/`funded` (`a8c01fe5`), each moved into its tab's existing primary.

**The other three were never defects, and this matters directly to your work.** Cedar's
`hoa-architectural-request`/`approved`, `/denied` and `hoa-committee-decision`/`changes-needed` have
exits that are **`transitionRelated` cascade targets** — `reopen-case`, `owner-resubmitted`,
`owner-withdraw` are fired by a *sibling workflow's effects*, never by a button. Their member-shaped
guards authorize the cascade, not an affordance.

**So when your change makes `summary` read-only, those three states WILL lose rendered buttons, and
that is CORRECT — it is the defect being repaired, not a regression.** Do not exempt Cedar, do not add
a primary binding to "restore" them, and do not weaken a test that observes it. Firing one of those
transitions directly desynchronizes the workflow pair (the decision advances while the request stays
put, with no revision submitted); they are reachable today **only** because `bindingKind` is inert,
which is the very thing you are fixing.

If a test breaks because a Cedar action disappears from a summary card, the test was asserting the
defect. Report it and say which one — do not quietly adjust it.

## The defect

`bindingKind` is **REQUIRED** by the grammar (`render-bindings.md:33`, `:49`) and documented
normatively at `:553-560`:

| `bindingKind` | Renders as |
|---|---|
| `primary` | Full, interactive card — includes the action buttons |
| `summary` | Compact/read-only card |

**Nothing in the shell reads it.** Verified across all three places it could act:

- **Resolution** — `binding_resolver.dart:10-37` filters on `states`, `role`/audience and
  `audienceMemberField` only.
- **Card selection** — `part27_engine_native_binding_dispatcher.dart:364` keys on `cardSurfaceFamily`;
  `part32:132` keys on `cardSurfaceFamily == 'table'`.
- **Rendering** — **zero** `.bindingKind` reads in the shell's `lib/`. The single occurrence,
  `part02_tab_shell.dart:996`, is a hardcoded `'primary'` inside an unrelated built-in Messages thread
  fixture: a *write*, not a branch.

So a `summary` binding renders a fully interactive card today. Authors pay a real cost — a required
key, plus validator rules premised on it (`workflow_validator.dart:2217,2381`, and `:607` actively
*recommends* authoring `"bindingKind": "summary"`) — for a distinction the platform does not implement.

**Interactivity currently comes from elsewhere entirely**, which is what to change: action buttons from
transitions and guards per instance, editors from `states[].editGuard` (`part28:1634-1656`), and
compactness from `displayContext`/`showEditors`, which are **surface**-driven (`part32:194-199` sets
`detail` for `notificationInbox`) and never binding-driven.

## What to build

Make `bindingKind` authoritative for **interactivity**, at the one place every card is selected.

1. **Suppress action affordances when `resolved.binding.bindingKind == 'summary'`.** Prefer threading
   a single derived flag (e.g. `interactive: binding.bindingKind != 'summary'`) from the dispatcher
   into the cards over adding a `bindingKind` read to each card — one decision site, not seven.
   `part32`'s `table` path needs the same treatment, since it never reaches the dispatcher.
2. **"Read-only" means no transition affordances and no editors.** Specifically: no action buttons, no
   instance-scoped create buttons, and `showEditors` forced false regardless of
   `states[].editableFields`/`editGuard`. A summary card still renders fields, facets and the state
   badge — it is a status view, not a blank.
3. **Do not conflate `summary` with `displayContext`.** They answer different questions: `summary` is
   *this binding is not where you act*, `displayContext` is *how much room there is*. Leave the
   existing `displayContext` logic alone.
4. **Leave `primary` behaviour exactly as it is today.** This ticket removes affordances from `summary`
   bindings; it must not add or change anything on `primary`.

**Scope by the population, not by the first card you open.** Enumerate every card that renders an
action affordance and state in your report which you changed and which you left: the dispatcher's six
bespoke cases, `GenericWorkflowInstanceCard`, and `WorkflowTableArchetypeCard` via `part32`.

## Blast radius — measured, so you can check your own work against it

Swept across all ten packages:

- **115** `summary` bindings total.
- **59** include at least one non-terminal state — these are the bindings whose rendering visibly
  changes.
- For **115 state-coverages** a `primary` binding elsewhere also covers the state, so actions survive
  on the primary and the summary correctly becomes a status view. **That is the intended outcome.**
- **0 orphaned states — already true as of 2026-09-26.** Re-run the gate yourself before you begin and
  confirm it still holds:

      python3 "docs/Build Plan V2/Tools/code/check_orphan_summary_bindings.py"

  Expect `ORPHANED summary states WITH live exits: 0`, exit 0, and **3 states listed under EXCLUDED as
  cascade-only**. Those three are Cedar's, they are reported deliberately rather than hidden, and they
  are **not** work for you. If the orphan count is anything but 0, stop and say so rather than
  proceeding.

## Regression tests

- **A `summary` binding renders no action button** where the same instance and role on a `primary`
  binding does. Assert both halves in one test — the contrast is the evidence; a one-sided assertion
  passes against a card that renders nothing for unrelated reasons.
- **A `summary` binding renders no editor** even when the current state declares `editableFields` and
  the viewer passes its `editGuard`.
- **A `summary` binding still renders its fields and its state badge** — the guard against
  over-suppressing into a blank card.
- **`primary` is unchanged** — an existing primary-card action test must still pass untouched.
- **`table` gets the same treatment**, since it bypasses the dispatcher.

**Prove each can fail.** Neutralise only the new flag and confirm the first test goes red for the
stated reason. A test never observed failing is not a guard.

## Verification

- **All five suites** — "verified means all five". Baselines **re-measured 2026-09-25**: judges
  **525**, app shell **421 (+2 skipped)**, engine **346 cases** (`345 +1` with PostgreSQL
  credentials; `341 +5` without), service **169 cases** (`168 +1`) with BOTH credential sets,
  demo app **262, exit 0, ZERO failures**.
- **The demo app suite is GREEN now — any failure in it is yours.** Earlier copies of this ticket said
  to expect one known failure matching `Found 0 widgets with key 'generic-instance-card-nom-draft-1'`.
  **That is obsolete**: `d87f9875` fixed the defect and `4192dbb8` inverted the test that asserted it.
  This matters more for this ticket than the others — 59 bindings change what they render, so you will
  see churn here, and an obsolete "one failure is expected" line is exactly how real churn gets waved
  through.
- **Three service PostgreSQL tests time out under concurrency** — transaction-rollback, guard-refusal
  and idempotency-race. Re-run any alone at `--concurrency=1` before filing a regression.
- **Expect demo-app churn and do not paper over it.** The harness pumps real packages, and 59 bindings
  change what they render. Any test asserting an action is tappable on what is actually a `summary`
  binding was asserting the defect. **Diff every changed assertion and justify each** — a test that
  now fails because the binding is `summary` should be *moved to the primary binding*, not weakened.
  Do not change any `findsNWidgets(N)` count without saying why the product genuinely differs.
- `flutter analyze` clean on the app shell.

## Out of scope

Community JSON (the prerequisite ticket owns it), `docs/references/**`, the engine, the workflow
service. Do **not** amend `render-bindings.md` — this ticket makes the doc true rather than rewriting
it. And do not touch the state-badge work in
[SHELL-state-label-bespoke-cards.md](SHELL-state-label-bespoke-cards.md); the two are independent, but
note that a `summary` binding on a terminal state is precisely where the state badge is the card's
only remaining content, so **both must render the badge** — that ticket's badge must not be suppressed
by this ticket's read-only rule.
