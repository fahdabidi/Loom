// Regression coverage for the B25 result-frame state-label locator
// (`exactRenderedTextFinder` in workflow_ui_test_harness.dart, consumed with
// `b25StateLabelRenderCandidates` from b25_visible_postcondition.dart).
//
// The defect: `integration_test/workflow_ui_evidence_test.dart` positioned
// the result frame with `find.text(stateLabel)`, an exact match against the
// bare declared state label. Garden Club's giveaway card never renders that
// bare label -- its `transferSummary` field composes it through
// `labelTemplate: "Transfer: {value}"`, so the rendered text is "Transfer:
// Ownership transferred" and the old exact match could never find it.
//
// Two things this file exists to prove, because a locator fix that "passes"
// without proving either is not a guard:
//
// 1. THE MECHANISM: a state label rendered only through a labelTemplate is
//    found by the new locator, and is NOT found by the old bare-label-only
//    match -- proven by literally exercising both against the same fixture.
// 2. THE FALSE-POSITIVE GUARD: matching stays exact, never substring. A
//    different instance's card carrying a different (but textually
//    overlapping) composed label is not matched, and a superstring decoy on
//    the SAME instance's card is not matched either. Loosening this to
//    `find.textContaining` would satisfy both decoys, which is exactly the
//    hazard `CLAUDE.md` records for product vocabulary ("Not attending"
//    contains `attend`; "Join waitlist" contains `wait`).
//
// Every "can fail" claim below is exercised directly in the test, not
// asserted from a fixed fixture -- each test computes both the candidate
// (fixed) locator and a deliberately weaker one, and shows they disagree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_visible_postcondition.dart';
import 'workflow_ui_test_harness.dart';

/// Garden Club's actual giveaway schema shape, trimmed to the one field that
/// matters here: a formula-backed field whose value can equal the terminal
/// state's label and whose labelTemplate composes it into a longer string.
const _gardenGiveawaySchema = <String, InstanceDataField>{
  'transferSummary': InstanceDataField(
    type: 'text',
    labelTemplate: 'Transfer: {value}',
  ),
};

Widget _twoInstanceCardsFixture({
  required String targetInstanceId,
  required String targetRenderedText,
  required String otherInstanceId,
  required String otherRenderedText,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          KeyedSubtree(
            key: ValueKey('result-card-$targetInstanceId'),
            child: Text(targetRenderedText),
          ),
          KeyedSubtree(
            key: ValueKey('result-card-$otherInstanceId'),
            child: Text(otherRenderedText),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('exactRenderedTextFinder mechanism', () {
    testWidgets(
      'finds a state label rendered only through a labelTemplate-composed '
      'string',
      (tester) async {
        await tester.pumpWidget(
          _twoInstanceCardsFixture(
            targetInstanceId: 'cedar-compost-bin-giveaway',
            targetRenderedText: 'Transfer: Ownership transferred',
            otherInstanceId: 'terracotta-pots-giveaway',
            otherRenderedText: 'Transfer: Awaiting claim',
          ),
        );

        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          _gardenGiveawaySchema,
        );
        final scope = find.byKey(
          const ValueKey('result-card-cedar-compost-bin-giveaway'),
        );

        expect(exactRenderedTextFinder(scope, candidates), findsOneWidget);
      },
    );

    testWidgets(
      'the bare-label-only match this fixes could never have found it -- '
      'proving the locator can fail for the reason it claims to fix',
      (tester) async {
        await tester.pumpWidget(
          _twoInstanceCardsFixture(
            targetInstanceId: 'cedar-compost-bin-giveaway',
            targetRenderedText: 'Transfer: Ownership transferred',
            otherInstanceId: 'terracotta-pots-giveaway',
            otherRenderedText: 'Transfer: Awaiting claim',
          ),
        );

        // The old defect: `find.text(stateLabel)`, i.e. a candidate set of
        // just the bare label with no labelTemplate composition.
        const bareLabelOnly = <String>{'Ownership transferred'};
        final scope = find.byKey(
          const ValueKey('result-card-cedar-compost-bin-giveaway'),
        );

        expect(
          exactRenderedTextFinder(scope, bareLabelOnly),
          findsNothing,
          reason:
              'The card never renders the bare label -- only "Transfer: '
              'Ownership transferred". A locator that does not compose '
              'through the labelTemplate must fail here, which is the '
              'exact defect this ticket fixes.',
        );
      },
    );
  });

  group('exactRenderedTextFinder false-positive guard', () {
    testWidgets(
      'does not match a different instance\'s card even though it shares '
      'the same labelTemplate prefix', (tester) async {
        await tester.pumpWidget(
          _twoInstanceCardsFixture(
            targetInstanceId: 'cedar-compost-bin-giveaway',
            targetRenderedText: 'Transfer: Ownership transferred',
            otherInstanceId: 'terracotta-pots-giveaway',
            otherRenderedText: 'Transfer: Awaiting claim',
          ),
        );

        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          _gardenGiveawaySchema,
        );
        final otherScope = find.byKey(
          const ValueKey('result-card-terracotta-pots-giveaway'),
        );

        expect(exactRenderedTextFinder(otherScope, candidates), findsNothing);
      },
    );

    testWidgets(
      'does not match a superstring decoy on the very card being searched',
      (tester) async {
        await tester.pumpWidget(
          _twoInstanceCardsFixture(
            targetInstanceId: 'cedar-compost-bin-giveaway',
            // A decoy that CONTAINS the composed candidate as a substring
            // but describes a different, unresolved status.
            targetRenderedText:
                'Transfer: Ownership transferred (pending review)',
            otherInstanceId: 'terracotta-pots-giveaway',
            otherRenderedText: 'Transfer: Awaiting claim',
          ),
        );

        final candidates = b25StateLabelRenderCandidates(
          'Ownership transferred',
          _gardenGiveawaySchema,
        );
        final scope = find.byKey(
          const ValueKey('result-card-cedar-compost-bin-giveaway'),
        );

        expect(
          exactRenderedTextFinder(scope, candidates),
          findsNothing,
          reason:
              'A superstring must not satisfy an exact match. This is the '
              'same hazard CLAUDE.md records for product vocabulary '
              '("Not attending" contains attend); the fix must not '
              'reintroduce it in the other direction.',
        );

        // Prove the guard can actually fail: a textContaining-style
        // (substring) match over the SAME fixture WOULD wrongly accept the
        // decoy, which is exactly why exactRenderedTextFinder must not be
        // implemented that way.
        final substringMatch = find.descendant(
          of: scope,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                candidates.any(
                  (candidate) => (widget.data ?? '').contains(candidate),
                ),
            description: 'substring-matching decoy probe',
          ),
        );
        expect(
          substringMatch,
          findsOneWidget,
          reason:
              'This probe exists only to prove the decoy is a genuine '
              'substring hazard, not an unreachable fixture -- a '
              'substring-based finder does match it, which is why exact '
              'matching is required.',
        );
      },
    );
  });
}
