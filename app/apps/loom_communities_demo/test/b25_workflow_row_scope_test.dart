import 'package:flutter_test/flutter_test.dart';

import 'b25_actor_audience_resolution.dart';
import 'b25_shipped_state_postcondition.dart';
import 'b25_workflow_row_selection.dart';

void main() {
  group('B25 workflow row scope', () {
    test(
      'an audience-resolution failure is recorded verbatim and the next row runs',
      () async {
        final attemptedRows = <String>[];
        final blocked = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-nomination');
          throw B25ActorAudienceResolutionFailure(
            workflowId: 'book-nomination',
            instanceId: 'nom-draft-1',
            roleId: 'book-member',
            actorEqualsField: 'nominatorFanId',
          );
        });
        final next = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-vote');
          return 'continued';
        });

        expect(attemptedRows, ['book-nomination', 'book-vote']);
        expect(blocked.completed, isFalse);
        expect(blocked.failure!.rowOutcome, 'blocked_by_audience');
        expect(blocked.failure!.actionProofStatus, 'blocked_by_audience');
        expect(
          blocked.failure!.reason,
          'B25 audience resolution failed promptly: workflow '
          'book-nomination, instance nom-draft-1, role book-member, '
          'actorEqualsField nominatorFanId is absent from the instance data. '
          'deriveInstanceRoles did not resolve an actor audience, so B25 will '
          'not wait for a widget the renderer cannot show.',
        );
        expect(next.completed, isTrue);
        expect(next.value, 'continued');
      },
    );

    test(
      'a selector-setup failure is recorded verbatim and the next row runs',
      () async {
        final attemptedRows = <String>[];
        const reason =
            'Walkthrough workflow book-vote could not derive an actionable '
            'instance, actorIdentity, and tab from the shipped package.';
        final blocked = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-vote');
          throw B25SelectorSetupFailure(reason);
        });
        final next = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-reading-material');
          return 'continued';
        });

        expect(attemptedRows, ['book-vote', 'book-reading-material']);
        expect(blocked.completed, isFalse);
        expect(blocked.failure!.rowOutcome, 'blocked_by_selector_setup');
        expect(blocked.failure!.actionProofStatus, 'blocked_by_selector_setup');
        expect(blocked.failure!.reason, reason);
        expect(next.completed, isTrue);
        expect(next.value, 'continued');
      },
    );

    test(
      'an action with no positionable result is recorded verbatim and the next row runs',
      () async {
        final attemptedRows = <String>[];
        const reason =
            'Shipped workflow book-reading-material changed source instance '
            'data after acknowledge-material, but B25 could not locate a '
            'changed rendered value or explicit success acknowledgement for '
            'material-public to position the result frame.';
        final unverified = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-reading-material');
          throw B25ResultFramePositioningFailure(reason);
        });
        final next = await runB25WorkflowRowScope<String>(() async {
          attemptedRows.add('book-vote');
          return 'continued';
        });

        expect(attemptedRows, ['book-reading-material', 'book-vote']);
        expect(unverified.completed, isFalse);
        expect(
          unverified.failure!.rowOutcome,
          'action_succeeded_result_unverified',
        );
        expect(
          unverified.failure!.actionProofStatus,
          'action_succeeded_result_unverified',
        );
        expect(unverified.failure!.actionSucceededButResultUnverified, isTrue);
        expect(unverified.failure!.reason, reason);
        expect(next.completed, isTrue);
        expect(next.value, 'continued');
      },
    );

    test(
      'unproven target-state checks stay distinct from blocked rows, proof, and result positioning',
      () async {
        final proven = await runB25WorkflowRowScope<String>(
          () async => 'proven',
        );
        final audience = await runB25WorkflowRowScope<String>(() async {
          throw B25ActorAudienceResolutionFailure(
            workflowId: 'book-nomination',
            instanceId: 'nom-draft-1',
            roleId: 'book-member',
            actorEqualsField: 'nominatorFanId',
          );
        });
        final setup = await runB25WorkflowRowScope<String>(() async {
          throw B25SelectorSetupFailure('selector setup failed');
        });
        final unverified = await runB25WorkflowRowScope<String>(() async {
          throw B25ResultFramePositioningFailure(
            'result frame was unavailable',
          );
        });
        final productFinding = await runB25WorkflowRowScope<String>(() async {
          throw B25ProductFindingFailure(
            'publish-announcement persisted sent but remained offered.',
          );
        });
        var neverReachedElapsed = Duration.zero;
        var neverReachedReads = 0;
        final neverReached = await waitForB25ShippedTargetState(
          targetState: 'sent',
          readCurrentState: () async {
            neverReachedReads += 1;
            return 'previewed';
          },
          waitForRetry: () async {
            neverReachedElapsed += const Duration(seconds: 1);
          },
          elapsed: () => neverReachedElapsed,
          maximumAttempts: 3,
        );
        final targetStateUnproven = await runB25WorkflowRowScope<String>(
          () async {
            throw B25PostconditionNotObservedFailure(
              neverReached.failureReason(
                workflowType: 'mosque-announcement',
                transitionId: 'publish-announcement',
                instanceId: 'announcement-42',
              ),
              actionExecutionEvidence: const [
                B25ActionExecutionEvidence(
                  transitionId: 'publish-announcement',
                  tapReturned: 'returned',
                  handlerEntry: 'not_observable',
                  engineCallCompletion: 'not_observable',
                  errorSurface: 'not_observed',
                  postcondition: 'target_state_not_observed',
                ),
              ],
            );
          },
        );
        var delayedElapsed = Duration.zero;
        var delayedReads = 0;
        final delayedStates = <String>['previewed', 'previewed', 'sent'];
        final delayedTarget = await waitForB25ShippedTargetState(
          targetState: 'sent',
          readCurrentState: () async => delayedStates[delayedReads++],
          waitForRetry: () async {
            delayedElapsed += const Duration(seconds: 1);
          },
          elapsed: () => delayedElapsed,
          maximumAttempts: 5,
        );

        expect(proven.completed, isTrue);
        expect(proven.value, 'proven');
        expect(audience.failure!.rowOutcome, 'blocked_by_audience');
        expect(setup.failure!.rowOutcome, 'blocked_by_selector_setup');
        expect(
          unverified.failure!.rowOutcome,
          'action_succeeded_result_unverified',
        );
        expect(productFinding.failure!.rowOutcome, 'product_finding');
        expect(productFinding.failure!.actionProofStatus, 'product_finding');
        expect(
          productFinding.failure!.reason,
          'publish-announcement persisted sent but remained offered.',
        );
        expect(neverReached.targetStateObserved, isFalse);
        expect(neverReached.lastObservedState, 'previewed');
        expect(neverReached.readAttempts, 3);
        expect(neverReachedReads, 3);
        final targetStateReason = neverReached.failureReason(
          workflowType: 'mosque-announcement',
          transitionId: 'publish-announcement',
          instanceId: 'announcement-42',
        );
        expect(
          targetStateReason,
          'After the walkthrough attempted publish-announcement for '
          'mosque-announcement instance announcement-42, the state check did '
          'not observe target state sent; the last observed state was '
          'previewed. Waited 0m 2s. Transition dispatch and successful '
          'completion were not verified.',
        );
        expect(targetStateReason, isNot(contains('persist')));
        expect(targetStateReason, isNot(contains('engine returned success')));
        expect(targetStateUnproven.completed, isFalse);
        expect(targetStateUnproven.failure!.rowOutcome, 'row_execution_failed');
        expect(
          targetStateUnproven.failure!.actionProofStatus,
          'row_execution_failed',
        );
        expect(
          targetStateUnproven
              .failure!
              .actionExecutionEvidence
              .single
              .postcondition,
          'target_state_not_observed',
        );
        expect(delayedTarget.targetStateObserved, isTrue);
        expect(delayedTarget.lastObservedState, 'sent');
        expect(delayedTarget.readAttempts, 3);
        expect(delayedReads, 3);
        expect(delayedElapsed, const Duration(seconds: 2));
        expect({
          audience.failure!.rowOutcome,
          setup.failure!.rowOutcome,
          unverified.failure!.rowOutcome,
          productFinding.failure!.rowOutcome,
          targetStateUnproven.failure!.rowOutcome,
        }, hasLength(5));
      },
    );

    test(
      'dedicated B17-B20 work-item failures are recorded and later items run',
      () async {
        const dedicatedItems = <String>[
          'B17/admin',
          'B18/member',
          'B19/member',
          'B19/admin',
          'B20/admin',
          'B20/member',
          'B20/capability-garden',
        ];
        final attempted = <String>[];
        final outcomes = <String>[];

        for (final item in dedicatedItems) {
          final scoped = await runB25WorkflowRowScope<String>(() async {
            attempted.add(item);
            throw StateError('forced dedicated failure for $item');
          });
          outcomes.add(scoped.failure!.rowOutcome);
        }

        expect(attempted, dedicatedItems);
        expect(outcomes, everyElement('row_execution_failed'));
      },
    );

    test(
      'a failed B20 publication names its blocked receiver and later work runs',
      () async {
        final attempted = <String>[];
        final admin = await runB25WorkflowRowScope<void>(() async {
          attempted.add('B20/admin');
          throw StateError('publication did not produce announcement id');
        });
        final receiver = await runB25WorkflowRowScope<void>(() async {
          attempted.add('B20/member');
          throw B25DependentReceiverBlockedFailure(
            'B20 member receiver is blocked by the named prerequisite B20 '
            'admin publication: no published announcement id was produced. '
            'Admin outcome ${admin.failure!.rowOutcome}; reason '
            '${admin.failure!.reason}.',
          );
        });
        final capability = await runB25WorkflowRowScope<String>(() async {
          attempted.add('B20/capability-soccer');
          return 'continued';
        });

        expect(attempted, ['B20/admin', 'B20/member', 'B20/capability-soccer']);
        expect(admin.failure!.rowOutcome, 'row_execution_failed');
        expect(receiver.failure!.rowOutcome, 'blocked_by_prerequisite');
        expect(
          receiver.failure!.reason,
          'B20 member receiver is blocked by the named prerequisite B20 '
          'admin publication: no published announcement id was produced. '
          'Admin outcome row_execution_failed; reason publication did not '
          'produce announcement id.',
        );
        expect(capability.value, 'continued');
      },
    );

    test(
      'a created but unidentified B20 announcement records an unverified action and names that prerequisite outcome',
      () async {
        const identityFailure =
            'The shipped mosque-announcement creation completed, but the '
            'created instance did not expose its engine-native identity key.\n'
            'Expected: exactly one newly rendered engine-native list key on '
            'tab "admin" that was absent before creation.\n'
            'Actual: 0 matching candidate(s): [].';
        final attempted = <String>[];
        final admin = await runB25WorkflowRowScope<void>(() async {
          attempted.add('B20/admin');
          throw B25ResultFramePositioningFailure(identityFailure);
        });
        final receiver = await runB25WorkflowRowScope<void>(() async {
          attempted.add('B20/member');
          throw B25DependentReceiverBlockedFailure(
            'B20 member receiver is blocked by the named prerequisite B20 '
            'admin publication: no published announcement id was produced. '
            'Admin outcome ${admin.failure!.rowOutcome}; reason '
            '${admin.failure!.reason}.',
          );
        });

        expect(attempted, ['B20/admin', 'B20/member']);
        expect(admin.failure!.rowOutcome, 'action_succeeded_result_unverified');
        expect(
          admin.failure!.actionProofStatus,
          'action_succeeded_result_unverified',
        );
        expect(admin.failure!.reason, identityFailure);
        expect(receiver.failure!.rowOutcome, 'blocked_by_prerequisite');
        expect(
          receiver.failure!.reason,
          'B20 member receiver is blocked by the named prerequisite B20 '
          'admin publication: no published announcement id was produced. '
          'Admin outcome action_succeeded_result_unverified; reason '
          '$identityFailure.',
        );
      },
    );

    test(
      'unselected dedicated-community prerequisites are never invoked',
      () async {
        const selectedExtensionIds = <String>{'ext_garden_club'};
        final prerequisiteCalls = <String>[];

        Future<void> runSelectedCommunitySetup(String extensionId) async {
          if (!isB25DedicatedCommunitySelected(
            selectedExtensionIds: selectedExtensionIds,
            extensionId: extensionId,
            phases: const <String>['B17', 'B18', 'B19', 'B20'],
            includesPhase: (phase) => phase == 'B20',
          )) {
            return;
          }
          prerequisiteCalls.add(extensionId);
        }

        await runSelectedCommunitySetup('ext_mosque');
        await runSelectedCommunitySetup('ext_garden_club');

        expect(prerequisiteCalls, ['ext_garden_club']);
      },
    );

    test('a global failure outside the row scope still aborts', () async {
      Future<void> runBatch() async {
        final row = await runB25WorkflowRowScope<String>(() async {
          throw B25SelectorSetupFailure('selector setup failed');
        });
        expect(row.completed, isFalse);

        throw StateError('community surface is unreachable globally');
      }

      await expectLater(
        runBatch,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'community surface is unreachable globally',
          ),
        ),
      );
    });

    test(
      'a community teardown failure is recorded and the next community runs',
      () async {
        final attemptedCommunities = <String>[];
        final provenRows = <String>[];
        var gardenLastRow = 'garden-tool-loan/member';
        final garden = await runB25CommunityScope<void>(() async {
          attemptedCommunities.add('Garden Club');
          provenRows.add(gardenLastRow);
          throw StateError(
            buildB25CommunityTeardownFailureMessage(
              communityName: 'Garden Club',
              extensionId: 'ext_garden_club',
              lastRowWalked: gardenLastRow,
              observedSurface: 'marketplace-detail-dialog-steel-wheelbarrow',
            ),
          );
        });
        final gardenRecord = B25CommunityTraversalRecord.fromScope(
          scope: garden,
          phase: 'B16',
          communityId: 'garden-club',
          communityName: 'Garden Club',
          extensionId: 'ext_garden_club',
          lastRowWalked: gardenLastRow,
        );

        final book = await runB25CommunityScope<void>(() async {
          attemptedCommunities.add('Book Club');
          provenRows.add('book-vote/member');
        });
        final bookRecord = B25CommunityTraversalRecord.fromScope(
          scope: book,
          phase: 'B16',
          communityId: 'book-club',
          communityName: 'Book Club',
          extensionId: 'ext_neighborhood_book_club',
          lastRowWalked: 'book-vote/member',
        );

        expect(attemptedCommunities, ['Garden Club', 'Book Club']);
        expect(provenRows, ['garden-tool-loan/member', 'book-vote/member']);
        expect(garden.completed, isFalse);
        expect(gardenRecord.isIncomplete, isTrue);
        final gardenRecordData = gardenRecord.toReportData();
        expect(gardenRecordData['phase'], 'B16');
        expect(gardenRecordData['communityId'], 'garden-club');
        expect(gardenRecordData['communityName'], 'Garden Club');
        expect(gardenRecordData['extensionId'], 'ext_garden_club');
        expect(gardenRecordData['traversalStatus'], 'incompletely_traversed');
        expect(gardenRecordData['lastRowWalked'], 'garden-tool-loan/member');
        expect(
          gardenRecordData['reason'],
          allOf(
            contains('Garden Club'),
            contains('garden-tool-loan/member'),
            contains('a Back tooltip'),
            contains('marketplace-detail-dialog-steel-wheelbarrow'),
          ),
        );
        expect(book.completed, isTrue);
        expect(bookRecord.isIncomplete, isFalse);
        expect(
          bookRecord.toReportData()['traversalStatus'],
          'completely_traversed',
        );
      },
    );

    test('a global failure outside the community scope still aborts', () async {
      Future<void> runBatch() async {
        final community = await runB25CommunityScope<void>(() async {
          throw StateError('community teardown failed');
        });
        expect(community.completed, isFalse);

        throw StateError('capture harness failed globally');
      }

      await expectLater(
        runBatch,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'capture harness failed globally',
          ),
        ),
      );
    });

    test('a final cleanup failure replaces only the last traversal record', () {
      final completed = B25CommunityTraversalRecord.fromScope(
        scope: const B25CommunityScopeResult<void>.completed(null),
        phase: 'B20',
        communityId: 'community-mosque',
        communityName: 'Masjid Nur',
        extensionId: 'ext_mosque',
        lastRowWalked: 'wf_multi-persona-workflow-evidence/member',
      );

      final finalised = completed.withFinalCleanupFailure(
        'Direct navigation did not land on the community list.',
      );

      expect(completed.isIncomplete, isFalse);
      expect(finalised.isIncomplete, isTrue);
      expect(finalised.lastRowWalked, completed.lastRowWalked);
      expect(
        finalised.toReportData()['reason'],
        'Direct navigation did not land on the community list.',
      );
    });
  });
}
