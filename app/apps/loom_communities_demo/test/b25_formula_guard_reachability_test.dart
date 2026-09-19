// Regression coverage for `b25_formula_guard_reachability.dart`, added to
// fix the B25 defect where `_shippedWorkflowSelector`
// (`integration_test/workflow_ui_evidence_test.dart`) picked the FIRST
// instance of a workflow type whose ordinary checks passed, with no
// awareness of `formula` guards. Garden Club's `claim-giveaway` guards on
// `if(ownerFanId == $actor, false, true)`; the selector kept choosing the
// self-owned, formula-denied instance over a reachable one, and the row
// recorded `primary_action_unavailable` even after the reachable instance
// was seeded.
//
// Every test below was run once against a version of
// `formulaGuardVerdictForTransition` short-circuited to always return
// `FormulaGuardVerdict.denied` (and once with `unknown` folded into
// `denied` inside `b25PrimaryMatchIsReachable`) to confirm each assertion
// fails for the reason it claims to guard, then restored -- per CLAUDE.md,
// "neutralise the call and show it failing before reporting it as working."

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_formula_guard_reachability.dart';

LoomWorkflowTransition _claimGiveaway({String? formula}) =>
    LoomWorkflowTransition(
      id: 'claim-giveaway',
      label: 'Claim',
      from: const ['listed'],
      to: 'claimed',
      guard: WorkflowGuard(
        allowedRoleIds: const ['garden-member'],
        formula: formula,
      ),
    );

void main() {
  group('formulaGuardVerdictForTransition', () {
    test('a formula that evaluates false for this actor is denied', () {
      final transition = _claimGiveaway(
        formula: r'if(ownerFanId == $actor, false, true)',
      );
      expect(
        formulaGuardVerdictForTransition(
          transition: transition,
          instanceData: const {'ownerFanId': 'garden-member'},
          actorId: 'garden-member',
          allowViewerResponse: false,
        ),
        FormulaGuardVerdict.denied,
      );
    });

    test('the same formula evaluates true for a different owner', () {
      final transition = _claimGiveaway(
        formula: r'if(ownerFanId == $actor, false, true)',
      );
      expect(
        formulaGuardVerdictForTransition(
          transition: transition,
          instanceData: const {'ownerFanId': 'garden-coordinator'},
          actorId: 'garden-member',
          allowViewerResponse: false,
        ),
        FormulaGuardVerdict.allowed,
      );
    });

    test('no formula on the transition is unknown, not denied', () {
      final transition = _claimGiveaway();
      expect(
        formulaGuardVerdictForTransition(
          transition: transition,
          instanceData: const {'ownerFanId': 'garden-member'},
          actorId: 'garden-member',
          allowViewerResponse: false,
        ),
        FormulaGuardVerdict.unknown,
      );
    });

    test(
      'a formula that throws because its field cannot be resolved is '
      'unknown, not denied',
      () {
        final transition = _claimGiveaway(formula: 'daysUntil(missingDate)');
        expect(
          formulaGuardVerdictForTransition(
            transition: transition,
            instanceData: const {},
            actorId: 'garden-member',
            allowViewerResponse: false,
          ),
          FormulaGuardVerdict.unknown,
        );
      },
    );

    test('a formula that resolves to a non-bool value is unknown', () {
      final transition = _claimGiveaway(formula: '1 + 1');
      expect(
        formulaGuardVerdictForTransition(
          transition: transition,
          instanceData: const {},
          actorId: 'garden-member',
          allowViewerResponse: false,
        ),
        FormulaGuardVerdict.unknown,
      );
    });

    test(
      'a relatedAggregate-guarded transition with no formula is unknown, '
      'never denied for lacking a precomputed aggregate -- the evaluateGuard '
      'trap this file exists to avoid',
      () {
        final transition = LoomWorkflowTransition(
          id: 'submit-nomination',
          label: 'Submit nomination',
          from: const ['open'],
          to: 'nominated',
          guard: const WorkflowGuard(
            relatedAggregate: RelatedAggregateGuard(
              workflowType: 'book-vote-response',
              filter: {},
              op: 'count',
              comparator: '<',
              compareTo: 5,
            ),
          ),
        );
        expect(
          formulaGuardVerdictForTransition(
            transition: transition,
            instanceData: const {},
            actorId: 'book-member',
            allowViewerResponse: false,
          ),
          FormulaGuardVerdict.unknown,
        );
      },
    );

    test(
      'a response-workflow candidate is unknown regardless of its formula, '
      'because instanceData belongs to the parent instance',
      () {
        final transition = _claimGiveaway(
          formula: r'if(ownerFanId == $actor, false, true)',
        );
        expect(
          formulaGuardVerdictForTransition(
            transition: transition,
            instanceData: const {'ownerFanId': 'garden-member'},
            actorId: 'garden-member',
            allowViewerResponse: true,
          ),
          FormulaGuardVerdict.unknown,
        );
      },
    );
  });

  group('b25PrimaryMatchIsReachable', () {
    bool matchesClaimGiveaway(LoomWorkflowTransition transition) =>
        transition.id == 'claim-giveaway';

    test(
      'a formula-denied instance is passed over in favour of a '
      'formula-passing one of the same workflow type',
      () {
        // Mirrors the real defect exactly: Garden Club ships two
        // `garden-tool-giveaway` instances of the same workflow type,
        // `terracotta-pots-giveaway` (self-owned, so `claim-giveaway` is
        // formula-denied for `garden-member`) declared before
        // `cedar-compost-bin-giveaway` (owned by someone else, so
        // reachable). The selector's outer loop walks instances in
        // declared order and must stop at the first REACHABLE one, not the
        // first one whose ordinary checks merely pass.
        final instancesInDeclaredOrder = {
          'terracotta-pots-giveaway': const {'ownerFanId': 'garden-member'},
          'cedar-compost-bin-giveaway': const {
            'ownerFanId': 'garden-coordinator',
          },
        };
        final transition = _claimGiveaway(
          formula: r'if(ownerFanId == $actor, false, true)',
        );

        String? selectedInstanceId;
        for (final entry in instancesInDeclaredOrder.entries) {
          final reachable = b25PrimaryMatchIsReachable(
            candidates: [transition],
            matchesPrimaryTerm: matchesClaimGiveaway,
            formulaVerdict: (t) => formulaGuardVerdictForTransition(
              transition: t,
              instanceData: entry.value,
              actorId: 'garden-member',
              allowViewerResponse: false,
            ),
          );
          if (reachable) {
            selectedInstanceId = entry.key;
            break;
          }
        }

        expect(selectedInstanceId, 'cedar-compost-bin-giveaway');
      },
    );

    test(
      'when every candidate matching the primary term is formula-denied, '
      'the row is not reachable and nothing is thrown',
      () {
        final transition = _claimGiveaway(
          formula: r'if(ownerFanId == $actor, false, true)',
        );
        final reachable = b25PrimaryMatchIsReachable(
          candidates: [transition],
          matchesPrimaryTerm: matchesClaimGiveaway,
          formulaVerdict: (t) => formulaGuardVerdictForTransition(
            transition: t,
            instanceData: const {'ownerFanId': 'garden-member'},
            actorId: 'garden-member',
            allowViewerResponse: false,
          ),
        );

        // A `false` result -- reached without raising -- is exactly the
        // signal `_shippedWorkflowSelector` uses to reuse its existing
        // `b25FallbackSelector` slot, which is how the row still ends in
        // `primary_action_unavailable` instead of a selector failure.
        expect(reachable, isFalse);
      },
    );

    test(
      'an unresolvable formula verdict (unknown) still counts as reachable',
      () {
        final transition = _claimGiveaway(formula: 'daysUntil(missingDate)');
        final reachable = b25PrimaryMatchIsReachable(
          candidates: [transition],
          matchesPrimaryTerm: matchesClaimGiveaway,
          formulaVerdict: (t) => formulaGuardVerdictForTransition(
            transition: t,
            instanceData: const {},
            actorId: 'garden-member',
            allowViewerResponse: false,
          ),
        );

        expect(reachable, isTrue);
      },
    );

    test(
      'a relatedAggregate-guarded primary transition with no precomputed '
      'aggregate is still reachable',
      () {
        final transition = LoomWorkflowTransition(
          id: 'submit-nomination',
          label: 'Submit nomination',
          from: const ['open'],
          to: 'nominated',
          guard: const WorkflowGuard(
            relatedAggregate: RelatedAggregateGuard(
              workflowType: 'book-vote-response',
              filter: {},
              op: 'count',
              comparator: '<',
              compareTo: 5,
            ),
          ),
        );
        final reachable = b25PrimaryMatchIsReachable(
          candidates: [transition],
          matchesPrimaryTerm: (t) => t.id == 'submit-nomination',
          formulaVerdict: (t) => formulaGuardVerdictForTransition(
            transition: t,
            instanceData: const {},
            actorId: 'book-member',
            allowViewerResponse: false,
          ),
        );

        expect(reachable, isTrue);
      },
    );

    test(
      'a candidate that does not match the primary term at all does not '
      'make the row reachable, formula aside',
      () {
        final unrelated = LoomWorkflowTransition(
          id: 'set_reminder',
          label: 'Set reminder',
          from: const ['listed'],
          guard: const WorkflowGuard(),
        );
        final reachable = b25PrimaryMatchIsReachable(
          candidates: [unrelated],
          matchesPrimaryTerm: matchesClaimGiveaway,
          formulaVerdict: (t) => formulaGuardVerdictForTransition(
            transition: t,
            instanceData: const {},
            actorId: 'garden-member',
            allowViewerResponse: false,
          ),
        );

        expect(reachable, isFalse);
      },
    );
  });
}
