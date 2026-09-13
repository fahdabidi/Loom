import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'b25_actor_audience_resolution.dart';
import 'workflow_ui_test_harness.dart';

void main() {
  group('B25 actor audience resolution', () {
    test(
      'an absent actor audience is blocked with its reason and the next row runs',
      () {
        final selectedRows = <String>[];

        final blocked = selectB25ActorAudienceRow<String>(() {
          selectedRows.add('book-nomination');
          return requireB25ActorBindingAudience(
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
          );
        });
        final nextRow = selectB25ActorAudienceRow<String>(() {
          selectedRows.add('next-workflow');
          return requireB25ActorBindingAudience(
            workflowId: 'next-workflow',
            instance: _instance(
              instanceData: const {'nominatorFanId': 'book-member'},
            ),
            roleId: 'book-member',
            candidates: const [
              B25ActorAudienceCandidate(
                fanId: 'book-member',
                roleId: 'book-member',
              ),
            ],
            machine: _machine(),
          );
        });

        expect(selectedRows, ['book-nomination', 'next-workflow']);
        expect(blocked.isBlockedByAudience, isTrue);
        expect(blocked.selector, isNull);
        expect(
          blocked.blockedReason,
          allOf(
            contains('workflow book-nomination'),
            contains('instance nom-draft-1'),
            contains('role book-member'),
            contains('actorEqualsField nominatorFanId'),
            contains('absent from the instance data'),
            contains('deriveInstanceRoles'),
          ),
        );
        expect(nextRow.isBlockedByAudience, isFalse);
        expect(nextRow.selector, 'book-member');
      },
    );

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

    test(
      'the held Book Club package records all four audience blocks',
      () async {
        final target = loomEvidenceTargets.singleWhere(
          (target) => target.extensionId == 'ext_neighborhood_book_club',
        );
        final package = await readShippedEvidencePackage(target);
        const expectedRows =
            <({String workflowId, String instanceId, String field})>[
              (
                workflowId: 'book-nomination',
                instanceId: 'nom-draft-1',
                field: 'nominatorFanId',
              ),
              (
                workflowId: 'book-vote-response',
                instanceId: 'vresp-2',
                field: 'voterFanId',
              ),
              (
                workflowId: 'book-shared-library-item',
                instanceId: 'item-draft',
                field: 'ownerFanId',
              ),
              (
                workflowId: 'book-search-ai-digest',
                instanceId: 'digest-draft',
                field: 'submitterFanId',
              ),
            ];
        final actorCandidates = package.experience.actorIdentities!
            .where((identity) => identity.roleId == 'book-member')
            .map(
              (identity) => B25ActorAudienceCandidate(
                fanId: identity.fanId,
                roleId: identity.roleId,
              ),
            )
            .toList(growable: false);

        final selections = <B25ActorAudienceRowSelection<String>>[
          for (final expected in expectedRows)
            selectB25ActorAudienceRow(
              () => requireB25ActorBindingAudience(
                workflowId: expected.workflowId,
                instance: _workflowInstanceForAudienceResolution(
                  package.experience.workflowInstances!.singleWhere(
                    (instance) => instance.instanceId == expected.instanceId,
                  ),
                ),
                roleId: 'book-member',
                candidates: actorCandidates,
                machine: package
                    .experience
                    .workflowDefinitions![expected.workflowId]!,
              ),
            ),
        ];

        expect(selections, hasLength(4));
        expect(
          selections.where((selection) => selection.isBlockedByAudience),
          hasLength(4),
        );
        expect(
          selections.map((selection) => selection.blockedCause),
          everyElement(
            B25ActorAudienceResolutionFailure.absentActorEqualsFieldCause,
          ),
        );
        for (var index = 0; index < expectedRows.length; index += 1) {
          final expected = expectedRows[index];
          expect(
            selections[index].blockedReason,
            allOf(
              contains('workflow ${expected.workflowId}'),
              contains('instance ${expected.instanceId}'),
              contains('actorEqualsField ${expected.field}'),
              contains('absent from the instance data'),
            ),
          );
        }
      },
    );
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

WorkflowInstance _workflowInstanceForAudienceResolution(
  LoomWorkflowSeedInstance instance,
) => WorkflowInstance(
  instanceId: instance.instanceId,
  workflowType: instance.workflowType,
  currentState: instance.currentState,
  createdByFanId: instance.createdByFanId ?? '',
  instanceData: instance.instanceData,
);
