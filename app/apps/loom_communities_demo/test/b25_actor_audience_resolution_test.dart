import 'package:flutter_test/flutter_test.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_actor_audience_resolution.dart';

void main() {
  group('B25 actor audience resolution', () {
    test('missing actorEqualsField fails promptly with the audience cause', () {
      final stopwatch = Stopwatch()..start();

      expect(
        () => requireB25ActorBindingAudience(
          workflowId: 'book-nomination',
          instance: _instance(),
          roleId: 'book-member',
          candidates: const [
            B25ActorAudienceCandidate(
              fanId: 'book-member',
              roleId: 'book-member',
            ),
          ],
          machine: _machine(),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('workflow book-nomination'),
              contains('instance nom-draft-1'),
              contains('role book-member'),
              contains('actorEqualsField nominatorFanId'),
              contains('absent from the instance data'),
              contains('deriveInstanceRoles'),
            ),
          ),
        ),
      );

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 1)),
        reason:
            'An absent rendering identity must fail selection rather than '
            'entering the bounded widget wait.',
      );
    });

    test('matching actorEqualsField selects the renderer-approved actor', () {
      final instance = _instance(
        instanceData: const {'nominatorFanId': 'book-member'},
      );
      const candidate = B25ActorAudienceCandidate(
        fanId: 'book-member',
        roleId: 'book-member',
      );

      expect(
        requireB25ActorBindingAudience(
          workflowId: 'book-nomination',
          instance: instance,
          roleId: candidate.roleId,
          candidates: const [candidate],
          machine: _machine(),
        ),
        candidate.fanId,
      );
      expect(
        deriveInstanceRoles(
          _machine(),
          instance,
          viewerFanId: candidate.fanId,
          viewerRoleId: candidate.roleId,
        ),
        contains('actor'),
      );
    });

    test('B25 and deriveInstanceRoles agree on guarded actor candidates', () {
      const candidates = [
        B25ActorAudienceCandidate(fanId: 'book-member', roleId: 'book-member'),
        B25ActorAudienceCandidate(
          fanId: 'another-member',
          roleId: 'book-member',
        ),
      ];
      final instance = _instance(
        instanceData: const {'nominatorFanId': 'book-member'},
      );
      final b25CandidateFanIds = b25ResolvableActorAudienceCandidates(
        machine: _machine(),
        instance: instance,
        candidates: candidates,
      ).map((candidate) => candidate.fanId);
      final rendererCandidateFanIds = candidates
          .where(
            (candidate) => deriveInstanceRoles(
              _machine(),
              instance,
              viewerFanId: candidate.fanId,
              viewerRoleId: candidate.roleId,
            ).contains('actor'),
          )
          .map((candidate) => candidate.fanId);

      expect(b25CandidateFanIds, orderedEquals(rendererCandidateFanIds));
      expect(b25CandidateFanIds, orderedEquals(['book-member']));
    });
  });
}

LoomWorkflowStateMachine _machine() =>
    LoomWorkflowStateMachine.fromJson(<String, dynamic>{
      'initialState': 'draft',
      'states': <String, dynamic>{
        'draft': <String, dynamic>{'label': 'Draft'},
      },
      'transitions': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'revise-nomination',
          'label': 'Edit nomination',
          'from': <String>['draft'],
          'to': 'draft',
          'guard': <String, dynamic>{
            'actorEqualsField': <String, dynamic>{'key': 'nominatorFanId'},
          },
        },
      ],
      'renderBindings': <Map<String, dynamic>>[],
      'visibility': <String, dynamic>{'default': 'public'},
      'instanceDataSchema': <String, dynamic>{},
    }, 'book-nomination');

WorkflowInstance _instance({Map<String, dynamic> instanceData = const {}}) =>
    WorkflowInstance(
      instanceId: 'nom-draft-1',
      workflowType: 'book-nomination',
      currentState: 'draft',
      createdByFanId: 'book-member',
      instanceData: instanceData,
    );
