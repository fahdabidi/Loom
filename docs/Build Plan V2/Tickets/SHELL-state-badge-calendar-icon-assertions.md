# SHELL — two calendar tests assert "no check-circle icon" and the state badge now renders one

**Status:** written 2026-09-25, **NOT dispatched**. Follow-up to
[SHELL-state-label-bespoke-cards.md](SHELL-state-label-bespoke-cards.md), which is otherwise done.
**Route:** `data/call_implementation_agent.sh --fresh`. **Two test files. No product code.**

## What happened

The state-label work landed correctly — app shell is **435 (+2 skipped), exit 0**, up exactly 14 from
421, every one accounted for (14 archetypes − 1 exempt `table` = 13 registry-driven cases, plus 1
standalone). It did **not** weaken any assertion: the only test file it touched is the new conformance
test.

But the demo app suite is **260 passed, 2 failed** against a 262/0 baseline, and both failures are the
same shape:

    Expected: no matching candidates
      Actual: _IconWidgetFinder:<Found 1 widget with icon "IconData(U+0E15A)": [
                Icon(IconData(U+0E15A), size: 18.0, color: Color(... green: 0.5569 ...))]>

| File | Line | Assertion |
|---|---|---|
| `b27_calendar_tab_real_data_test.dart` | 119 | `expect(find.byIcon(Icons.check_circle_outline), findsNothing);` |
| `b36_calendar_engine_rsvp_test.dart` | 213 | `expect(find.byIcon(Icons.check_circle_outline), findsNothing);` |

`_WorkflowStateBadge` renders `Icons.check_circle_outline` in green for a state whose `tone` is
`positive` — so on a calendar event in a positive state, a check-circle now legitimately exists.

**The population is exactly these two, verified with a control.** A sweep for an unscoped
`findsNothing` on any of the five tone icons (`check_circle_outline`, `warning_amber_outlined`,
`cancel_outlined`, `info_outline`, `pending_outlined`) across every `*_test.dart` in `app/` returns
these two lines and nothing else; the control — every `byIcon` assertion on those five icons anywhere
— returns the same two files, so there is no third site waiting to break.

## The rule for this fix, and it is the whole point of the ticket

**Do NOT delete these assertions, and do NOT weaken them to make the suite green.** They are guarding
something real. Read line 119 in context: its three sibling assertions check that the event detail
renders `Icons.schedule`, `Icons.location_on_outlined` and `Icons.person_outline`, each scoped with
`find.descendant(of: detail, ...)`. The check-circle line is the negative half of "uses **semantic**
icons" — it exists to catch a generic, meaningless checkmark standing in for real event facts.

That guard must survive. What has changed is only that a check-circle is no longer *necessarily*
meaningless: the badge's is the declared state's tone, which is exactly the contract
`workflow-grammar.md:279` requires be shown.

**So make the assertion say what it always meant: no check-circle OTHER than the state badge's.**
The shape that does this without losing anything:

```dart
final badge = find.byKey(const ValueKey('workflow-state-badge-<instanceId>'));
// the badge's own tone icon is expected...
expect(find.descendant(of: badge, matching: find.byIcon(Icons.check_circle_outline)),
       findsOneWidget);
// ...and it is the ONLY one on the screen, so a stray generic check still fails.
expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
```

This is **stronger** than the original, not weaker: it still fails on a stray checkmark, and it
additionally pins where the legitimate one lives. Note the two assertions are load-bearing together —
the second alone would pass if the one check-circle were a stray and the badge were missing.

**Confirm the tone before writing it.** The badge only renders `check_circle_outline` when the
rendered instance's state declares `tone: "positive"`. Read each fixture's state and its declared tone
rather than assuming; if a fixture's state is not positive-toned, the icon in that test will be a
different one and the assertion must name that icon instead.

**Do not change `_WorkflowStateBadge`, `_stateToneIcon`, or any product code.** The badge is correct
and its suite is green. If you conclude the product is wrong rather than the assertion, **stop and
report that** instead of editing either — that is a design question, not a test fix.

## Verification

- Demo app suite returns to **262 passed, exit 0, zero failures**. It is green as of `4192dbb8`, so
  **any** remaining failure is in scope for this ticket.
- App shell stays at **435 (+2 skipped), exit 0**.
- Prove each changed assertion can still fail: temporarily render a second `check_circle_outline`
  outside the badge, confirm the test goes red, then remove it. An assertion that cannot fail for the
  reason it claims is not a check — and that is precisely the trap this ticket exists to avoid.
- Diff must touch **only** those two test files.
