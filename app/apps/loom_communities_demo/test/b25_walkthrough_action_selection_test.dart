import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show LoomWorkflowStateMachine, LoomWorkflowTransition, WorkflowGuard;

import 'workflow_ui_test_harness.dart';

void main() {
  group('selectB25WalkthroughActions', () {
    test('word-boundary matching excludes negations from primary', () {
      final declined = _transition(
        id: 'respond-declined',
        label: 'Not attending',
        action: 'respond',
      );
      final going = _transition(
        id: 'respond-going',
        label: 'Going',
        action: 'respond',
      );

      final declinedMatch = matchB25TransitionAgainstTerms(
        declined,
        primaryTerms: const [
          'rsvp',
          'attend',
          'going',
          'reserve spot',
          'confirm attendance',
        ],
        alternateTerms: const [
          'decline',
          'not attending',
          'maybe',
          'change response',
          'edit response',
          'cancel rsvp',
        ],
      );
      expect(
        declinedMatch.primary,
        isFalse,
        reason: '"Not attending" must not satisfy the primary "attend"',
      );
      expect(declinedMatch.alternate, isTrue);

      final goingMatch = matchB25TransitionAgainstTerms(
        going,
        primaryTerms: const ['rsvp', 'attend', 'going'],
        alternateTerms: const ['decline', 'not attending'],
      );
      expect(goingMatch.primary, isTrue);
      expect(goingMatch.alternate, isFalse);
    });

    test('paired event-rsvp drives going then a distinct decline/change',
        () async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      final row = _b25RowFor(target, 'garden-event-rsvp', 'member');

      final package = await readShippedEvidencePackage(target);
      final definitions = package.experience.workflowDefinitions!;
      final responseMachine = definitions['garden-event-rsvp-response']!;
      final candidates = _roleEligibleFrom(
        responseMachine,
        responseMachine.initialState,
        'garden-member',
      );

      final selection = selectB25WalkthroughActions(
        candidates: candidates,
        primaryTerms: row.requiredPrimaryActions,
        alternateTerms: row.requiredAlternateActions,
      );

      expect(selection.primary?.id, 'respond-going');
      expect(
        matchB25TransitionAgainstTerms(
          selection.primary!,
          primaryTerms: row.requiredPrimaryActions,
          alternateTerms: row.requiredAlternateActions,
        ).primary,
        isTrue,
      );

      expect(selection.alternate, isNotNull);
      expect(selection.alternate!.id, isNot(selection.primary!.id));
      expect(
        matchB25TransitionAgainstTerms(
          selection.alternate!,
          primaryTerms: row.requiredPrimaryActions,
          alternateTerms: row.requiredAlternateActions,
        ).alternate,
        isTrue,
        reason:
            'the alternate frame must exercise a distinct decline/change/'
            'reject action, not another primary',
      );
      expect(
        selection.alternate!.id,
        'respond-maybe',
        reason:
            'the first declared alternate in the response workflow is '
            '"Maybe" (respond-maybe)',
      );
    });

    test('self-shaped rsvp drives send-reminder then cancel', () async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.communityId == 'community_chess_club',
      );
      final row = _b25RowFor(target, 'chess-club-night', 'organizer');

      final package = await readShippedEvidencePackage(target);
      final machine = package.experience.workflowDefinitions!['chess-club-night']!;
      final instance = package.experience.workflowInstances!.firstWhere(
        (instance) => instance.workflowType == 'chess-club-night',
      );
      final candidates = _roleEligibleFrom(
        machine,
        instance.currentState,
        'chess-organizer',
      );

      final selection = selectB25WalkthroughActions(
        candidates: candidates,
        primaryTerms: row.requiredPrimaryActions,
        alternateTerms: row.requiredAlternateActions,
      );

      expect(selection.primary?.id, 'send-reminder');
      expect(
        matchB25TransitionAgainstTerms(
          selection.primary!,
          primaryTerms: row.requiredPrimaryActions,
          alternateTerms: row.requiredAlternateActions,
        ).primary,
        isTrue,
      );

      expect(selection.alternate?.id, 'cancel-club-night');
      expect(selection.alternate!.id, isNot(selection.primary!.id));
      expect(
        matchB25TransitionAgainstTerms(
          selection.alternate!,
          primaryTerms: row.requiredPrimaryActions,
          alternateTerms: row.requiredAlternateActions,
        ).alternate,
        isTrue,
      );
    });
  });
}

LoomWorkflowTransition _transition({
  required String id,
  required String label,
  String? action,
}) {
  return LoomWorkflowTransition(
    id: id,
    label: label,
    action: action,
    icon: null,
    tone: null,
    from: const [],
    to: null,
    guard: const WorkflowGuard(),
    effects: const [],
  );
}

B25ProductDocInteractionModel _b25RowFor(
  LoomEvidenceTarget target,
  String workflowId,
  String role,
) {
  final repositoryRoot = locateB25RepositoryRoot();
  final catalog = B25ProductDocInteractionCatalog.fromAssetJson(
    File(
      '${repositoryRoot.path}/$b25InteractionModelAssetRepositoryPath',
    ).readAsStringSync(),
  );
  return catalog.requireModel(
    communityId: target.communityId,
    communityName: target.communityName,
    workflowId: workflowId,
    role: role,
  );
}

List<LoomWorkflowTransition> _roleEligibleFrom(
  LoomWorkflowStateMachine machine,
  String state,
  String roleId,
) {
  return machine.transitionsFrom(state).where((transition) {
    final allowedRoleIds = transition.guard.allowedRoleIds;
    return allowedRoleIds == null ||
        allowedRoleIds.isEmpty ||
        allowedRoleIds.contains(roleId);
  }).toList(growable: false);
}
