# SHELL — five bespoke archetype cards drop the declared state label

**Status:** written 2026-09-25, **NOT dispatched** (user-directed: create and slot, do not dispatch).
**Route:** `data/call_implementation_agent.sh --fresh` (app-shell Dart; never hand-edit).
**Scoped by:** root cause agent, session key `state-label-bespoke-cards`. Its two premise corrections
are folded in below — read "What was wrong with the first framing" before the fix.

## The defect

`workflow-grammar.md:279` declares, in the `states` field table:

    | `label` | string | **yes** | Human-readable state name, shown in the UI |

`label` is the **only required key** on a state and its documented meaning is display. `tone`
(`:280`) exists solely to colour it. **Five bespoke card families never render it.** They build their
`Card` columns from `instanceDataSchema` fields, facets and actions, and never read
`machine.states[instance.currentState].label`. The only `states[...]` read in any of the five is
`_editableKeys`'s `editGuard` check (`part28:1635`).

**The packages are correct as authored. The shell is the defect.** Do not propose package changes —
community JSON is Skill-authored only.

### The user-visible symptom

Book Club's `book-meeting-rsvp` declares
`"cancelled": { "label": "Cancelled", "tone": "negative", "isTerminal": true }` and binds it to
`event-rsvp`. Observed on a device, a cancelled meeting renders as:

    B25 Reverify Sep19  ·  12 going  ·  12 seats left  ·  19:00

No cancellation notice. A member sees a normal event with a live attendee count; the only signal is
that the action buttons vanished, which is indistinguishable from "you already responded" or "you
lack permission". Garden's `garden-tool-giveaway` is identical via `equipment-loan` for
`given`/`delisted`.

**This is not a terminal-state problem.** The event-rsvp card renders no state label in *any* state —
`open` and `cancelled` look equally unlabelled. Terminal states are merely where it becomes visible,
because that is when the buttons disappear and the label becomes the only remaining signal.

## Population — six families, and one of them bypasses the dispatcher

`part27_engine_native_binding_dispatcher.dart:364` is, by its own comment, *"the single place
`cardSurfaceFamily` is ever switched on for rendering purposes."* That comment is **not quite true**,
which is why this table matters more than the switch:

| Card | Family | Bindings | Renders label? | Routed by |
|---|---|---|---|---|
| `_EventRsvpDetailCard` (`part28:1473`) | `event-rsvp` | 16 | **No — fix** | dispatcher |
| `EquipmentLoanArchetypeCard` (`part36:385`) | `equipment-loan` | 13 | **No — fix** | dispatcher |
| `DocumentLibraryArchetypeCard` (`part36:1077`) | `documentLibrary` | 12 | **No — fix** | dispatcher |
| `VotePollArchetypeCard` (`part35`) | `votePoll` | 4 | **No — fix** | dispatcher, *conditionally* |
| `SearchAiAnswerArchetypeCard` (`part36:2711`) | `searchAiAnswer` | 4 | **No — fix** | dispatcher |
| `WorkflowTableArchetypeCard` | `table` | 5 | **No — OUT OF SCOPE, own row** | `part32:132`, **before** the dispatcher |
| `ExportWizardArchetypeCard` (`part36:1983`) | `exportWizard` | 46 | **Yes** (`part36:2538`) — leave alone | dispatcher |
| `GenericWorkflowInstanceCard` (`part26`) | 8 other families | ~175 | **Yes** (`part26:507`) — leave alone | dispatcher default |

`votePoll` routes to its bespoke card only when the binding has a `repeater` or the workflow type is
`tournament-event`; otherwise it already falls through to Generic and is fine. Fix the bespoke path.

**Scope is the five marked "fix".** `table` gets its own row because it is intercepted in `part32`
before the dispatcher is reached — the single most important fact in this ticket, because it is what
makes a dispatcher-level fix insufficient.

## What was wrong with the first framing — read this before choosing an approach

I originally proposed adding the badge to *"the shared dispatcher wrapper that already sits above all
of them"*. **There is no such wrapper.** `EngineNativeArchetypeCard.build` computes two locals and
then switches; every case `return`s its card directly and nothing composes chrome around the result.
So the choice was never "card vs existing wrapper" but "card vs a **new** wrapper", and a new wrapper
fails on three counts:

- **Placement.** Both shipped badges sit *inside* the card's `Card` chrome, at the top of its padded
  `Column` (`part26:498-514`, `part36:2530-2548`). A wrapper can only stack a chip *above* the
  `Card`, outside its border and fill — a visibly different design, on every bespoke surface at once.
- **Double-render.** `GenericWorkflowInstanceCard` flows through the same dispatcher (default case,
  plus the `votePoll` fall-through), as does `ExportWizardArchetypeCard`. A naive wrapper
  double-renders for ~221 of ~250 bindings — the exemption set is most of the traffic.
- **Coverage.** It would miss `table` entirely, since that family never reaches the dispatcher.

## What to build

### 1. One shared helper, not five copies

The app shell is a single library (`part of` files), and `_StateBadge` (`part08:515`) is already
shared across parts. Add beside it:

```dart
/// The declared-state badge every archetype card renders at the top of its Card
/// column. workflow-grammar.md's `states` table marks `label` REQUIRED and
/// "shown in the UI"; this widget is the single implementation of that contract
/// for bespoke cards. GenericWorkflowInstanceCard and ExportWizardArchetypeCard
/// predate it and deliberately keep their own — see "Do not migrate" below.
class _WorkflowStateBadge extends StatelessWidget {
  const _WorkflowStateBadge({
    required this.machine,
    required this.instance,
    this.modernTheme,
    this.displayContext,
  });

  @override
  Widget build(BuildContext context) {
    final state = machine.states[instance.currentState];
    return Align(
      alignment: Alignment.centerLeft,
      child: _StateBadge(
        key: ValueKey(
          'workflow-state-badge-${instance.instanceId}'
          '${displayContext == null ? '' : '-$displayContext'}',
        ),
        icon: _stateToneIcon(state?.tone),
        label: state?.label ?? instance.currentState,
        foreground: _stateToneColor(context, state?.tone),
        accent: modernTheme?.accent,
      ),
    );
  }
}
```

Hoist `_stateToneIcon` / `_stateToneColor` from `part26:377-394` to top-level functions in `part08`
and have `part26` call the hoisted versions — behaviour unchanged, one implementation. A rule
duplicated five times is a rule that gets missed a sixth; this repo already records that from the
`_remoteEngine` sweep.

### 2. Insert it as the first child of each of the five cards' main `Column`

`_WorkflowStateBadge(...)` followed by `SizedBox(height: 12)`, matching `part26:498-514`.

**Two cautions, both load-bearing:**

- **Include `displayContext` where the card has one.** Marketplace renders the same instance as a
  tile **and** a detail dialog simultaneously (`part36:214` and `:355`) — which is exactly why
  `ExportWizardArchetypeCard`'s badge key already carries it. Two widgets with the same `ValueKey`
  in one tree is an error.
- **Do NOT copy `part26:471`'s `machine.states[_instance.currentState]!`.** That bang throws on an
  undeclared state. The helper's null-fallback to the raw state id is the correct degradation —
  unknown must remain a rendered third state, not a crash, for the same reason a tri-state guard does
  not collapse "unavailable" into false. (`part26`'s own bang is a separate row; do not change it
  here.)

### 3. The recurrence gate — a conformance test, not runtime structure

A wrapper would only protect cards routed through the dispatcher. The gate that actually closes the
class is a test over the **registry**: iterate `knownWorkflowArchetypeIds` — which
`workflow_validator.dart:625` already calls the source of truth for render-binding families — and for
each id build a minimal machine whose current state declares a sentinel label, pump that family's
real entry point, and assert the sentinel renders.

- Sentinel: `'ZZ State Sentinel'` — no substring collision with product vocabulary.
- Entry point: `EngineNativeArchetypeCard` for switch families; `WorkflowTableArchetypeCard` may be
  **explicitly exempted with a `TODO` naming its own tracker row**, since table state rendering is
  deferred.
- Assertion: `expect(find.text('ZZ State Sentinel'), findsWidgets)`.
- **A registry id with no fixture must fail with a named error.** That is the closure rule that stops
  a sixth card shipping badge-less.

**Prove the test can fail before believing it.** Before the fix it must fail for exactly the five
families and pass for `exportWizard` plus every generic-rendered family. Report that split — it is
the evidence the test fails for the reason it claims, not a decoration.

## Do NOT migrate the two cards that already render a badge

Leave `GenericWorkflowInstanceCard` and `ExportWizardArchetypeCard` untouched.

`ExportWizard`'s badge is **not** a duplicate to consolidate — it is *richer*: off-path detection,
custom `_stateIcon`/`_stateTint`, and an off-path caption at `part36:2549`. It is also the
most-declared family at **46 bindings**. Replacing it with the shared helper would change a working
surface for zero user value. Generic's badge is asserted by existing tests via its
`generic-instance-state-<id>` key.

There is no double-render risk, because the badge is added per-card rather than wrapped.
Consolidating all three onto one helper is an optional follow-up, explicitly not this ticket.

## Verification

Nothing outside the app shell: no definition publish, no package install, no vocabulary copy, no
deploy. This is pure rendering, so the multi-layer trap does not apply here.

- **Run all five suites** — "verified means all five". Baselines **re-measured 2026-09-25**: judges
  **525**, app shell **421 (+2 skipped)**, engine **346 cases** (`345 +1` with PostgreSQL
  credentials; `341 +5` without), service **169 cases** (`168 +1`) with BOTH credential sets,
  demo app **262, exit 0, ZERO failures**.
- **The demo app suite is GREEN — ANY failure in it is yours.** This bullet previously told you to
  expect one known failure matching `Found 0 widgets with key 'generic-instance-card-nom-draft-1'` in
  `b43_book_engine_migration_test.dart`. **That is obsolete**: `d87f9875` fixed the underlying defect
  and `4192dbb8` inverted the test that had been asserting it still existed. There is no failure here
  you should read past.
- **Three service PostgreSQL tests time out under concurrency** — transaction-rollback, guard-refusal
  and idempotency-race. Re-run any alone at `--concurrency=1` before filing a regression.
- **Watch for newly-ambiguous text finders.** The demo-app harness pumps real packages, so any
  existing `find.text(...)` expecting a state word exactly once — a facet or history entry echoing
  "Cancelled" — can now find two. **Diff every changed `findsOneWidget → findsNWidgets` and justify
  each**; do not weaken an assertion to get green.
- `flutter analyze` clean on the app shell (it was "No issues found" as of 2026-09-13, so a new
  finding there is real, not pre-existing noise).

## Out of scope — each has its own tracker row

1. **`bindingKind` is REQUIRED, documented as changing rendering, and read by nothing in the shell.**
   Do not touch it here. Wiring `summary → read-only` would change live behaviour for every shipped
   `summary` binding on a *non-terminal* state (Youth Soccer declares them on `active`), so it needs
   a sweep of all ten packages first. **The one interaction that matters for this ticket: the state
   badge must render for BOTH kinds** — a `summary` binding on a terminal state is precisely where
   the label is the card's only remaining content.
2. **`table` family state rendering** (`WorkflowTableArchetypeCard`, routed at `part32:132`).
3. **`part26:471`'s crash-on-unknown-state bang.**

Community JSON, `docs/references/**`, the engine, and the workflow service are all out of scope.
