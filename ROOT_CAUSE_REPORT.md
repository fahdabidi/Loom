# Root-cause report: `c2e0cded` app-shell failures

## Outcome: confident diagnosis and recommended fixes

The new fan-out is the trigger for both newly failing tests, but the failures have different mechanisms. Neither failure is caused by an `event-rsvp` family false positive, a swallowed fan-out exception, or a database lock.

## 1. `slideOutRight presents and submits the same event creation flow`

### Confirmed mechanism

This is a bounded-wait test failure after a real increase in the awaited submit work, not a permanently stuck dialog.

The submit path in `part33_generic_creation_card.dart:90-124` does not pop its route until the singular `engine.createInstance(...)` future resolves. At `local_workflow_engine_api.dart:1144-1181`, that future now creates the event and then synchronously awaits `_fanOutEventRsvpResponseRows`. For this test, the workflow is genuinely `event-rsvp`, has the required `responseTable`, has no transition whose `action` is `create`, and the screen registers five active test accounts. The fan-out therefore performs five membership lookups, reads the existing response table, and validates/inserts five response rows before returning.

Before `c2e0cded`, the app-shell callback removed by the commit constructed a fresh `LocalAuthApi` and queried it with the rewritten extension ID `calr3h1-slideOutRight`. That fresh auth store has no accounts under that ID, so the old callback submitted an empty bulk-create batch. The formerly passing test was consequently timing a much shorter, accidentally vacuous follow-up.

The test taps Submit at `v3_calr3h1_slideoutright_presentation_test.dart:173`, runs exactly ten iterations of `_settleBounded` (`:136-142`), and immediately asserts at `:200`. The helper is not tied to either completion of `createInstance` or dismissal of the route. In the widget-test async/fake-async boundary, the newly awaited membership/query/insert sequence can consume the bounded iterations; if `Navigator.pop` begins near the end of the bound, the `showGeneralDialog` route also still needs its 280 ms reverse transition. `AlertDialog` therefore remains in the tree at the instant of the assertion.

A read-only exact-fixture engine reproduction loaded all 33 frozen seed rows, registered the same five identities, installed the same active-membership behavior, and executed the same singular `event-rsvp` creation data. It returned normally and produced exactly five response rows. There was no exception, lock, or unresolved engine future. This rules out the creation card's catch path (`part33_generic_creation_card.dart:125-132`) as the mechanism for this fixture.

### Recommended fix

Change the test's post-submit synchronization to wait for an observable completion condition. After tapping `new-event-submit`, poll while interleaving `tester.runAsync` and `tester.pump` until the `AlertDialog` (or `new-event-submit`) is gone, then perform the existing event assertion. The polling helper should time out with the current error widget text so a genuine submit exception remains distinguishable from slow completion. Do not fix this by merely increasing `_settleBounded`'s fixed iteration count.

Do not make fan-out unawaited or pop the production dialog before fan-out solely to satisfy this test: the commit's required contract is that response rows exist when event creation completes.

## 2. `Make recurring creates calendar occurrences and seeds every RSVP response row`

### Confirmed mechanism

This test has two different membership sources, and the newly implemented recurrence fan-out exposes the mismatch.

During installation, `_install` at `v3_milestone_a8_calendar_end_to_end_test.dart:87-93` reads the 13 frozen Tabletop accounts from `ext_verify_tabletop_club` and registers all 13 IDs in the engine with `setPersonaType`. This direct-calendar test never installs an `activeMembershipLookup`, so `_fanOutEventRsvpResponseRows` uses all registered IDs at `local_workflow_engine_api.dart:1108-1116`.

The `generateRecurringInstances` effect creates the two sibling occurrences and awaits fan-out for each at `local_workflow_engine_api.dart:1859-1885`. Each sibling therefore correctly receives 13 `event-rsvp-response` rows.

The assertion derives its expected set differently. At `v3_milestone_a8_calendar_end_to_end_test.dart:1218-1222`, it constructs a new `LocalAuthApi` and asks for accounts under the rewritten ID `a8-make-recurring`. A new local auth store contains no accounts for that ID, so `accountIds` is empty. The assertion at `:1244` consequently expects zero responses even though the engine's actual, explicitly registered membership boundary contains 13 IDs. Before this commit the test passed only because recurrence created no response rows; its “seeds every RSVP response row” check was vacuous.

A read-only exact-fixture reproduction of the test's engine setup and `make-recurring` transition produced the expected three dates and exactly 13 response rows for each of the two new sibling events, while the test's rewritten-extension auth lookup produced zero IDs. The transition completed normally, ruling out a transaction lock or partial fan-out.

### Recommended fix

Make the test assert against the same identities it registers in `_install`. Prefer carrying the registered account-ID set on `_InstalledTabletop` and using that set at `:1218`; at minimum, read `ext_verify_tabletop_club`, the same source used at `:88-90`. Then require 13 rows per generated sibling and exact identity-set equality. Do not change the engine to consult the empty rewritten-extension auth store: this direct-widget fixture explicitly configured engine membership via `setPersonaType`.

## Trigger scope and exclusions

- Ordinary workflow types do not perform response-row fan-out. Singular `createInstance` now does an extra definition lookup and transition scan, but `_fanOutEventRsvpResponseRows` returns at `local_workflow_engine_api.dart:1068-1069` unless `_resolvedArchetypes[workflowType].family` is exactly `event-rsvp`. It then additionally requires an `event-rsvp` render binding with a non-null `responseTable` at `:1071-1079`.
- The slide-out test triggers the legacy singular-create compatibility branch because the real `event-rsvp` machine has no transition with `action: "create"` (`:1166-1179`).
- The recurring test triggers the explicit occurrence hook (`:1871-1884`), once for each generated sibling.
- The changed date/time-picker `OK` timeout in the pre-existing A11 failure is not explained by fan-out. Those picker interactions occur before the Submit tap, while the new engine hook is entered only from `_submit`'s later `createInstance` call. No changed code in `c2e0cded` executes between opening the creation card and those picker interactions. It should remain a separate test-stability investigation rather than evidence of a fan-out lock.
