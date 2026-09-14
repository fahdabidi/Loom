import 'package:flutter_test/flutter_test.dart';

import 'b25_actor_audience_resolution.dart';
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
      'a result-unverified row is distinct from blocked rows and proof',
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

        expect(proven.completed, isTrue);
        expect(proven.value, 'proven');
        expect(audience.failure!.rowOutcome, 'blocked_by_audience');
        expect(setup.failure!.rowOutcome, 'blocked_by_selector_setup');
        expect(
          unverified.failure!.rowOutcome,
          'action_succeeded_result_unverified',
        );
        expect({
          audience.failure!.rowOutcome,
          setup.failure!.rowOutcome,
          unverified.failure!.rowOutcome,
        }, hasLength(3));
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
  });
}
