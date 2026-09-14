import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/b25_device_dialog_guard.dart';

import '../test_driver/workflow_ui_evidence_writer.dart';
import 'workflow_ui_test_harness.dart';

void main() {
  test('capture fails loudly when a frame shows a system dialog', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'loom-workflow-evidence-system-dialog-',
    );
    try {
      final writer = WorkflowUiEvidenceWriter(
        evidenceRoot: temporaryRoot,
        commandOutputPath: 'system-dialog.log',
      );
      for (final name in _harnessScreenshotNames) {
        await writer.recordScreenshot(name, <int>[1, 2, 3]);
      }

      final responseData = _responseData(screenshotCaptureStatus: 'complete');
      (responseData['screenshotVisibleTextByName'] = <String, String>{
        ..._harnessVisibleTexts,
        'B12_harness_action': 'System UI isn\'t responding  Close app  Wait',
      });
      responseData['workflowEvidence'] = <Map<String, Object?>>[
        <String, Object?>{
          'phase': 'B12',
          'appId': 'workflow-ui-evidence-harness',
          'workflowId': 'workflow-ui-evidence-harness',
          'role': 'harness-member',
          'screenshotNames': _harnessScreenshotNames,
          'status': 'pass',
        },
      ];

      await expectLater(
        writer.writeEvidence(responseData),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('System dialog detected'),
              contains('B12_harness_action'),
              contains("isn't responding"),
              contains('workflow-ui-evidence-harness'),
              contains('harness-member'),
            ),
          ),
        ),
      );

      final aggregate = await _readAggregate(temporaryRoot);
      expect(aggregate['status'], 'fail');
      expect(aggregate['screenshotStatus'], 'partial');
      expect(aggregate['screenshotCount'], 2);
      expect(
        (aggregate['missingScreenshotNames'] as List<dynamic>),
        contains('B12_harness_action'),
      );
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'capture is not treated as a system dialog when a frame shows Join waitlist',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'loom-workflow-evidence-join-waitlist-',
      );
      try {
        final writer = WorkflowUiEvidenceWriter(
          evidenceRoot: temporaryRoot,
          commandOutputPath: 'join-waitlist.log',
        );
        for (final name in _harnessScreenshotNames) {
          await writer.recordScreenshot(name, <int>[1, 2, 3]);
        }

        final responseData = _responseData(screenshotCaptureStatus: 'complete');
        (responseData['screenshotVisibleTextByName'] = <String, String>{
          ..._harnessVisibleTexts,
          'B12_harness_action': 'Event is full  Join waitlist',
        });

        await writer.writeEvidence(responseData);

        final aggregate = await _readAggregate(temporaryRoot);
        expect(aggregate['status'], 'pass');
        expect(aggregate['walkthroughStatus'], 'pass');
        expect(aggregate['screenshotStatus'], 'complete');
        expect(aggregate['completionGateEligible'], isTrue);
        expect(aggregate['screenshotCount'], 3);
        expect((aggregate['missingScreenshotNames'] as List<dynamic>), isEmpty);
        expect(aggregate.containsKey('failureReason'), isFalse);
      } finally {
        await temporaryRoot.delete(recursive: true);
      }
    },
  );

  test(
    'a named blocked receiver is non-proven in the persisted B25 summary',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'loom-workflow-evidence-blocked-receiver-',
      );
      try {
        final writer = WorkflowUiEvidenceWriter(
          evidenceRoot: temporaryRoot,
          commandOutputPath: 'blocked-receiver.log',
        );
        for (final name in _harnessScreenshotNames) {
          await writer.recordScreenshot(name, <int>[1, 2, 3]);
        }
        final responseData = _responseData(screenshotCaptureStatus: 'complete')
          ..['requestedPhases'] = <String>['B12', 'B20']
          ..['expectedWorkflowCountByPhase'] = <String, int>{'B12': 1, 'B20': 1}
          ..['workflowEvidence'] = <Map<String, Object?>>[
            ..._responseData(
                  screenshotCaptureStatus: 'complete',
                )['workflowEvidence']
                as List<Map<String, Object?>>,
            <String, Object?>{
              'phase': 'B20',
              'appId': 'ext_mosque',
              'communityName': 'Masjid Nur',
              'workflowId': 'wf_multi-persona-workflow-evidence',
              'role': 'member',
              'screenshotNames': const <String>[],
              'b25RowOutcome': 'blocked_by_prerequisite',
              'b25ActionProofStatus': 'blocked_by_prerequisite',
              'blockedByPrerequisiteReason':
                  'B20 member receiver is blocked by the named prerequisite '
                  'B20 admin publication: no published announcement id was produced.',
              'productFindings': const <String>[
                'B20 member receiver is blocked by the named prerequisite '
                    'B20 admin publication: no published announcement id was produced.',
              ],
              'status': 'blocked_by_prerequisite',
            },
          ];

        await writer.writeEvidence(responseData);

        final aggregate = await _readAggregate(temporaryRoot);
        final summary = aggregate['b25RowSummary'] as Map<String, dynamic>;
        expect(summary['recordedRows'], 1);
        expect(summary['provenRows'], 0);
        expect(summary['completedRows'], 0);
        expect(summary['blockedByPrerequisiteRows'], 1);
        expect(
          (summary['nonProvenRows'] as List<dynamic>).single['reason'],
          'B20 member receiver is blocked by the named prerequisite B20 admin '
          'publication: no published announcement id was produced.',
        );
      } finally {
        await temporaryRoot.delete(recursive: true);
      }
    },
  );

  // The Flutter-side text guard above cannot see a NATIVE Android dialog: it
  // only reads `Text` widgets, and a system dialog is a window outside the
  // Flutter tree. The capture CLI asks the device directly and records what it
  // found; these two tests pin that the writer honours that record.
  test(
    'a device-reported system dialog fails the capture and names the row',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'loom-workflow-evidence-device-dialog-',
      );
      try {
        final writer = WorkflowUiEvidenceWriter(
          evidenceRoot: temporaryRoot,
          commandOutputPath: 'device-dialog.log',
        );
        for (final name in _harnessScreenshotNames) {
          await writer.recordScreenshot(name, <int>[1, 2, 3]);
        }
        recordDeviceDialogFinding(
          evidenceRoot: temporaryRoot,
          phase: 'B12',
          screenshotName: 'B12_harness_action',
          finding: const DeviceDialogFinding(
            kind: 'system-dialog',
            detail:
                'an Android system dialog window is present: '
                '"Application Not Responding: com.google.android.gms"',
            focusedWindow: 'Application Not Responding: com.google.android.gms',
            stage: 'after-capture',
          ),
        );

        // Nothing on the Flutter side looks wrong; only the device saw it.
        final responseData = _responseData(screenshotCaptureStatus: 'complete');
        responseData['screenshotVisibleTextByName'] = <String, String>{
          ..._harnessVisibleTexts,
        };
        responseData['workflowEvidence'] = <Map<String, Object?>>[
          <String, Object?>{
            'phase': 'B12',
            'appId': 'workflow-ui-evidence-harness',
            'workflowId': 'workflow-ui-evidence-harness',
            'role': 'harness-member',
            'communityId': 'community_workflow_ui_evidence_harness',
            'screenshotNames': _harnessScreenshotNames,
            'status': 'pass',
          },
        ];

        await expectLater(
          writer.writeEvidence(responseData),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('System dialog detected'),
                contains('B12_harness_action'),
                contains('source=device'),
                contains('Application Not Responding'),
                contains('workflow-ui-evidence-harness'),
                contains('harness-member'),
                contains('community_workflow_ui_evidence_harness'),
              ),
            ),
          ),
        );

        final aggregate = await _readAggregate(temporaryRoot);
        expect(aggregate['status'], 'fail');
        expect(aggregate['screenshotCount'], 2);
        expect(
          (aggregate['missingScreenshotNames'] as List<dynamic>),
          contains('B12_harness_action'),
        );
        expect(
          File(
            '${temporaryRoot.path}/B12/screenshots/B12_harness_action.png',
          ).existsSync(),
          isFalse,
        );
      } finally {
        await temporaryRoot.delete(recursive: true);
      }
    },
  );

  test('a clean device report leaves the capture passing', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'loom-workflow-evidence-device-clean-',
    );
    try {
      final writer = WorkflowUiEvidenceWriter(
        evidenceRoot: temporaryRoot,
        commandOutputPath: 'device-clean.log',
      );
      for (final name in _harnessScreenshotNames) {
        await writer.recordScreenshot(name, <int>[1, 2, 3]);
      }
      clearDeviceDialogFindings(evidenceRoot: temporaryRoot, phase: 'B12');

      await writer.writeEvidence(
        _responseData(screenshotCaptureStatus: 'complete'),
      );

      final aggregate = await _readAggregate(temporaryRoot);
      expect(aggregate['status'], 'pass');
      expect(aggregate['screenshotCount'], 3);
      expect(aggregate.containsKey('failureReason'), isFalse);
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('blocked rows have separate unproven audience and selector buckets', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'loom-workflow-evidence-audience-blocked-',
    );
    try {
      final writer = WorkflowUiEvidenceWriter(
        evidenceRoot: temporaryRoot,
        commandOutputPath: 'audience-blocked.log',
      );
      const blockedAudienceRows =
          <({String workflowId, String instanceId, String actorEqualsField})>[
            (
              workflowId: 'book-nomination',
              instanceId: 'nom-draft-1',
              actorEqualsField: 'nominatorFanId',
            ),
            (
              workflowId: 'book-vote-response',
              instanceId: 'vresp-2',
              actorEqualsField: 'voterFanId',
            ),
            (
              workflowId: 'book-shared-library-item',
              instanceId: 'item-draft',
              actorEqualsField: 'ownerFanId',
            ),
            (
              workflowId: 'book-search-ai-digest',
              instanceId: 'digest-draft',
              actorEqualsField: 'submitterFanId',
            ),
          ];
      for (final name in _harnessScreenshotNames) {
        await writer.recordScreenshot(name, <int>[1, 2, 3]);
      }
      final responseData = _responseData(screenshotCaptureStatus: 'complete')
        ..['expectedWorkflowCountByPhase'] = <String, int>{
          'B12': 5 + blockedAudienceRows.length,
        }
        ..['workflowEvidence'] = <Map<String, Object?>>[
          <String, Object?>{
            'phase': 'B12',
            'appId': 'ext_book_club',
            'communityName': 'Book Club',
            'workflowId': 'book-available',
            'role': 'book-member',
            'screenshotNames': _harnessScreenshotNames,
            'b25RowOutcome': 'attempted',
            'b25ActionProofStatus': 'pass',
            'status': 'pass',
          },
          <String, Object?>{
            'phase': 'B12',
            'appId': 'ext_book_club',
            'communityName': 'Book Club',
            'workflowId': 'book-guarded-off',
            'role': 'book-member',
            'screenshotNames': _harnessScreenshotNames,
            'b25RowOutcome': 'primary_action_unavailable',
            'b25ActionProofStatus': 'fail',
            'productFindings': [
              'primary_action_unavailable: no primary action candidates were '
                  'selected for this workflow row.',
            ],
            'status': 'pass',
          },
          <String, Object?>{
            'phase': 'B12',
            'appId': 'ext_book_club',
            'communityName': 'Book Club',
            'workflowId': 'book-vote',
            'role': 'member',
            'screenshotNames': const <String>[],
            'b25RowOutcome': 'blocked_by_selector_setup',
            'b25ActionProofStatus': 'blocked_by_selector_setup',
            'blockedBySelectorSetupCause':
                'selector setup could not derive an actionable instance, '
                'actorIdentity, and tab',
            'blockedBySelectorSetupReason':
                'Walkthrough workflow book-vote could not derive an actionable '
                'instance, actorIdentity, and tab from the shipped '
                'ext_neighborhood_book_club experience and appShell for B25 '
                'product-doc role `member` from '
                '`docs/references/communities/neighborhood-book-club-product-experience.md`.',
            'status': 'blocked_by_selector_setup',
          },
          <String, Object?>{
            'phase': 'B12',
            'appId': 'ext_book_club',
            'communityName': 'Book Club',
            'workflowId': 'book-reading-material',
            'role': 'book-member',
            'screenshotNames': const <String>[],
            'b25RowOutcome': 'action_succeeded_result_unverified',
            'b25ActionProofStatus': 'action_succeeded_result_unverified',
            'actionSucceededResultUnverifiedReason':
                'Shipped workflow book-reading-material changed source '
                'instance data after acknowledge-material, but B25 could not '
                'locate a changed rendered value or explicit success '
                'acknowledgement for material-public to position the result '
                'frame.',
            'status': 'action_succeeded_result_unverified',
          },
          <String, Object?>{
            'phase': 'B12',
            'appId': 'ext_mosque',
            'communityName': 'Masjid Nur',
            'workflowId': 'mosque-announcement',
            'role': 'masjid-admin',
            'screenshotNames': const <String>[],
            'b25RowOutcome': 'product_finding',
            'b25ActionProofStatus': 'product_finding',
            'productFindings': const <String>[
              'publish-announcement persisted sent but the shipped Admin '
                  'surface still offered the completed action.',
            ],
            'status': 'product_finding',
          },
          for (final blocked in blockedAudienceRows)
            <String, Object?>{
              'phase': 'B12',
              'appId': 'ext_book_club',
              'communityName': 'Book Club',
              'workflowId': blocked.workflowId,
              'role': 'book-member',
              'screenshotNames': const <String>[],
              'b25RowOutcome': 'blocked_by_audience',
              'b25ActionProofStatus': 'blocked_by_audience',
              'blockedByAudienceCause':
                  'actorEqualsField absent from the instance data',
              'blockedByAudienceReason':
                  'B25 audience resolution failed promptly: workflow '
                  '${blocked.workflowId}, instance ${blocked.instanceId}, role '
                  'book-member, actorEqualsField ${blocked.actorEqualsField} '
                  'is absent from the instance data. deriveInstanceRoles did '
                  'not resolve an actor audience, so B25 will not wait for a '
                  'widget the renderer cannot show.',
              'status': 'blocked_by_audience',
            },
        ];

      await writer.writeEvidence(responseData);

      final aggregate = await _readAggregate(temporaryRoot);
      final summary = aggregate['b25RowSummary'] as Map<String, dynamic>;
      expect(aggregate['status'], 'fail');
      expect(summary['recordedRows'], 9);
      expect(summary['provenRows'], 1);
      expect(summary['completedRows'], 4);
      expect(summary['primaryActionUnavailableRows'], 1);
      expect(summary['actionSucceededResultUnverifiedRows'], 1);
      expect(summary['actionSucceededResultUnverifiedRowsByCommunity'], {
        'Book Club': 1,
      });
      expect(summary['productFindingRows'], 1);
      expect(summary['productFindingRowsByCommunity'], {'Masjid Nur': 1});
      expect(summary['blockedByAudienceRows'], 4);
      expect(summary['blockedByAudienceRowsByCommunity'], {'Book Club': 4});
      expect(summary['blockedBySelectorSetupRows'], 1);
      expect(summary['blockedBySelectorSetupRowsByCommunity'], {
        'Book Club': 1,
      });
      final blockedRows = summary['blockedRows'] as List<dynamic>;
      expect(blockedRows, hasLength(5));
      expect(
        blockedRows.whereType<Map<String, dynamic>>().map(
          (row) => row['outcome'],
        ),
        containsAll(['blocked_by_audience', 'blocked_by_selector_setup']),
      );
      final selectorSetupRow = blockedRows
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['outcome'] == 'blocked_by_selector_setup');
      expect(selectorSetupRow['communityName'], 'Book Club');
      expect(selectorSetupRow['workflowId'], 'book-vote');
      expect(selectorSetupRow['role'], 'member');
      expect(
        selectorSetupRow['reason'],
        'Walkthrough workflow book-vote could not derive an actionable '
        'instance, actorIdentity, and tab from the shipped '
        'ext_neighborhood_book_club experience and appShell for B25 '
        'product-doc role `member` from '
        '`docs/references/communities/neighborhood-book-club-product-experience.md`.',
      );
      final reasonGroups =
          summary['blockedByAudienceReasonGroups'] as List<dynamic>;
      expect(reasonGroups, hasLength(1));
      expect(
        (reasonGroups.single as Map<String, dynamic>)['cause'],
        'actorEqualsField absent from the instance data',
      );
      expect((reasonGroups.single as Map<String, dynamic>)['count'], 4);
      expect(
        ((reasonGroups.single as Map<String, dynamic>)['rows'] as List<dynamic>)
            .map((row) => (row as Map<String, dynamic>)['reason'])
            .join(' '),
        allOf(
          contains('nominatorFanId'),
          contains('voterFanId'),
          contains('ownerFanId'),
          contains('submitterFanId'),
        ),
      );
      final selectorSetupReasonGroups =
          summary['blockedBySelectorSetupReasonGroups'] as List<dynamic>;
      expect(selectorSetupReasonGroups, hasLength(1));
      expect(
        (selectorSetupReasonGroups.single as Map<String, dynamic>)['cause'],
        'selector setup could not derive an actionable instance, '
        'actorIdentity, and tab',
      );
      expect(
        (selectorSetupReasonGroups.single as Map<String, dynamic>)['count'],
        1,
      );
      final nonProvenRows = summary['nonProvenRows'] as List<dynamic>;
      expect(nonProvenRows, hasLength(8));
      final unverifiedRow = nonProvenRows
          .cast<Map<String, dynamic>>()
          .singleWhere(
            (row) => row['outcome'] == 'action_succeeded_result_unverified',
          );
      expect(unverifiedRow['communityName'], 'Book Club');
      expect(unverifiedRow['workflowId'], 'book-reading-material');
      expect(unverifiedRow['role'], 'book-member');
      expect(
        unverifiedRow['reason'],
        'Shipped workflow book-reading-material changed source instance data '
        'after acknowledge-material, but B25 could not locate a changed '
        'rendered value or explicit success acknowledgement for '
        'material-public to position the result frame.',
      );
      final productFindingRow = nonProvenRows
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['outcome'] == 'product_finding');
      expect(productFindingRow['communityName'], 'Masjid Nur');
      expect(productFindingRow['workflowId'], 'mosque-announcement');
      expect(productFindingRow['role'], 'masjid-admin');
      expect(
        productFindingRow['reason'],
        'publish-announcement persisted sent but the shipped Admin surface '
        'still offered the completed action.',
      );

      final phaseManifest =
          jsonDecode(
                await File(
                  '${temporaryRoot.path}/B12/workflow-ui-evidence.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final blockedRow = (phaseManifest['workflows'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((row) => row['b25RowOutcome'] == 'blocked_by_audience');
      expect(blockedRow['recordedRowStatus'], 'blocked_by_audience');
      expect(blockedRow['b25ActionProofStatus'], 'blocked_by_audience');
      final blockedSetupRow = (phaseManifest['workflows'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (row) => row['b25RowOutcome'] == 'blocked_by_selector_setup',
          );
      expect(blockedSetupRow['recordedRowStatus'], 'blocked_by_selector_setup');
      expect(
        blockedSetupRow['b25ActionProofStatus'],
        'blocked_by_selector_setup',
      );
      final actionSucceededResultUnverifiedRow =
          (phaseManifest['workflows'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (row) =>
                    row['b25RowOutcome'] ==
                    'action_succeeded_result_unverified',
              );
      expect(
        actionSucceededResultUnverifiedRow['recordedRowStatus'],
        'action_succeeded_result_unverified',
      );
      expect(
        actionSucceededResultUnverifiedRow['b25ActionProofStatus'],
        'action_succeeded_result_unverified',
      );
      final persistedProductFindingRow =
          (phaseManifest['workflows'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .singleWhere((row) => row['b25RowOutcome'] == 'product_finding');
      expect(
        persistedProductFindingRow['recordedRowStatus'],
        'product_finding',
      );
      expect(
        persistedProductFindingRow['b25ActionProofStatus'],
        'product_finding',
      );
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('walkthrough target without a shipped package fails loudly', () async {
    const target = LoomEvidenceTarget(
      phase: 'B12',
      communityId: 'community_missing_package',
      communityName: 'Missing Package Community',
      handle: 'missing-package',
      extensionId: 'ext_missing_package',
      accentColor: '#000000',
      seedDataFiles: [],
    );

    await expectLater(
      readShippedEvidencePackage(target),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Missing Package Community'),
            contains('ext_missing_package'),
          ),
        ),
      ),
    );
  });

  test(
    'an incomplete community traversal retains its proven rows and reason in evidence',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'loom-workflow-evidence-community-scope-',
      );
      try {
        final writer = WorkflowUiEvidenceWriter(
          evidenceRoot: temporaryRoot,
          commandOutputPath: 'community-scope.log',
        );
        for (final name in _harnessScreenshotNames) {
          await writer.recordScreenshot(name, <int>[1, 2, 3]);
        }
        final responseData = _responseData(screenshotCaptureStatus: 'complete')
          ..['workflowEvidence'] = <Map<String, Object?>>[
            <String, Object?>{
              'phase': 'B12',
              'appId': 'ext_garden_club',
              'communityId': 'garden-club',
              'communityName': 'Garden Club',
              'workflowId': 'garden-tool-loan',
              'role': 'member',
              'screenshotNames': _harnessScreenshotNames,
              'b25RowOutcome': 'attempted',
              'b25ActionProofStatus': 'pass',
              'status': 'pass',
            },
          ]
          ..['b25CommunityTraversals'] = <Map<String, Object?>>[
            <String, Object?>{
              'phase': 'B12',
              'communityId': 'garden-club',
              'communityName': 'Garden Club',
              'extensionId': 'ext_garden_club',
              'traversalStatus': 'incompletely_traversed',
              'lastRowWalked': 'garden-tool-loan/member',
              'reason':
                  'B25 community teardown failed for community Garden '
                  'Club (ext_garden_club). Last row walked: '
                  'garden-tool-loan/member. Sought control: a Back tooltip. '
                  'Observed surface: marketplace-detail-dialog-test-item.',
            },
            <String, Object?>{
              'phase': 'B12',
              'communityId': 'book-club',
              'communityName': 'Book Club',
              'extensionId': 'ext_neighborhood_book_club',
              'traversalStatus': 'completely_traversed',
              'lastRowWalked': 'book-vote/member',
            },
          ];

        await writer.writeEvidence(responseData);

        final aggregate = await _readAggregate(temporaryRoot);
        expect(aggregate['status'], 'fail');
        expect(aggregate['walkthroughStatus'], 'fail');
        final rowSummary = aggregate['b25RowSummary'] as Map<String, dynamic>;
        expect(rowSummary['recordedRows'], 1);
        expect(rowSummary['provenRows'], 1);
        final traversalSummary =
            aggregate['b25CommunityTraversalSummary'] as Map<String, dynamic>;
        expect(traversalSummary['recordedCommunities'], 2);
        expect(traversalSummary['completelyTraversedCommunities'], 1);
        expect(traversalSummary['incompletelyTraversedCommunities'], 1);
        final incompleteCommunities =
            traversalSummary['incompleteCommunities'] as List<dynamic>;
        expect(incompleteCommunities, hasLength(1));
        expect(
          (incompleteCommunities.single as Map<String, dynamic>)['reason'],
          allOf(
            contains('Garden Club'),
            contains('garden-tool-loan/member'),
            contains('Back tooltip'),
            contains('marketplace-detail-dialog-test-item'),
          ),
        );
        expect(aggregate['failureReason'], contains('incompletely traversed'));

        final phaseManifest =
            jsonDecode(
                  await File(
                    '${temporaryRoot.path}/B12/workflow-ui-evidence.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        expect(phaseManifest['status'], 'fail');
        final phaseRowSummary =
            phaseManifest['b25RowSummary'] as Map<String, dynamic>;
        expect(phaseRowSummary['provenRows'], 1);
        final phaseTraversalSummary =
            phaseManifest['b25CommunityTraversalSummary']
                as Map<String, dynamic>;
        expect(phaseTraversalSummary['incompletelyTraversedCommunities'], 1);
      } finally {
        await temporaryRoot.delete(recursive: true);
      }
    },
  );

  test('wf_example-workflow-ux-evidence-harness', () async {
    expect(loomEvidenceTargets, hasLength(10));
    expect(
      loomEvidenceTargets.map((target) => target.phase).toSet(),
      containsAll(['B13', 'B14', 'B15', 'B16']),
    );
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      expect(experience.workflows, isNotEmpty);
      for (final workflow in experience.workflows) {
        final screenshotNames = [
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_start',
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_action',
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_complete',
        ];
        expect(screenshotNames.toSet(), hasLength(3));
      }
    }

    const canonicalShippedRoles = <String, Set<String>>{
      'ext_garden_club': {'garden-member', 'garden-coordinator'},
      'ext_camera_club': {'camera-club-member', 'camera-club-organizer'},
      'ext_neighborhood_book_club': {'book-member', 'book-organizer'},
      'ext_chess_club': {'chess-member', 'chess-organizer', 'chess-owner'},
      'ext_mosque': {'community-member', 'owner'},
      'ext_youth_soccer': {'soccer-guardian', 'soccer-coach', 'soccer-owner'},
      'ext_ad_free_community': {'ad-off-member', 'ad-off-owner'},
      'ext_cedar_commons_hoa': {'hoa-member', 'hoa-board'},
      'ext_data_portability_community': {
        'portability-owner',
        'portability-member',
        'portability-receiving-provider',
      },
      'ext_member_social_space': {'member', 'moderator'},
    };
    for (final entry in canonicalShippedRoles.entries) {
      final target = loomEvidenceTargets.singleWhere(
        (target) => target.extensionId == entry.key,
      );
      expect(hasShippedEvidencePackage(target.extensionId), isTrue);
      final package = await readShippedEvidencePackage(target);
      expect(package.experience.workflows, isEmpty);
      expect(package.experience.workflowDefinitions, isNotEmpty);
      expect(package.experience.workflowInstances, isNotEmpty);
      expect(
        package.experience.actorIdentities!
            .map((actorIdentity) => actorIdentity.roleId)
            .toSet(),
        entry.value,
      );
      expect(package.appShellConfiguration['tabs'], isNotEmpty);

      final pair = await writeEvidencePackagePair(target);
      final initialization =
          jsonDecode(await File(pair.initializationPath).readAsString())
              as Map<String, dynamic>;
      expect(initialization['experience'], package.source['experience']);
      expect(initialization['appShell'], package.source['appShell']);
      await File(pair.extensionPath).parent.delete(recursive: true);
    }

    final temporaryRoot = await Directory.systemTemp.createTemp(
      'loom-workflow-evidence-writer-',
    );
    try {
      final fullRoot = Directory('${temporaryRoot.path}/full');
      final fullWriter = WorkflowUiEvidenceWriter(
        evidenceRoot: fullRoot,
        commandOutputPath: 'full.log',
      );
      for (final name in _harnessScreenshotNames) {
        await fullWriter.recordScreenshot(name, <int>[1, 2, 3]);
      }
      await fullWriter.writeEvidence(
        _responseData(screenshotCaptureStatus: 'complete'),
      );
      final full = await _readAggregate(fullRoot);
      expect(full['status'], 'pass');
      expect(full['walkthroughStatus'], 'pass');
      expect(full['screenshotStatus'], 'complete');
      expect(full['completionGateEligible'], isTrue);
      expect(full['screenshotCount'], 3);

      final walkthroughOnlyRoot = Directory(
        '${temporaryRoot.path}/walkthrough-only',
      );
      final walkthroughOnlyWriter = WorkflowUiEvidenceWriter(
        evidenceRoot: walkthroughOnlyRoot,
        commandOutputPath: 'walkthrough-only.log',
      );
      await walkthroughOnlyWriter.writeEvidence(
        _responseData(
          screenshotCaptureStatus: 'unavailable',
          screenshotUnavailableReason:
              'MissingPluginException(captureScreenshot)',
        ),
      );
      final walkthroughOnly = await _readAggregate(walkthroughOnlyRoot);
      expect(walkthroughOnly['status'], 'walkthrough-only');
      expect(walkthroughOnly['walkthroughStatus'], 'pass');
      expect(walkthroughOnly['screenshotStatus'], 'unavailable');
      expect(walkthroughOnly['completionGateEligible'], isFalse);
      expect(walkthroughOnly['screenshotCount'], 0);
      expect(walkthroughOnly['phases'], ['B12']);

      final failedRoot = Directory('${temporaryRoot.path}/failed');
      final failedWriter = WorkflowUiEvidenceWriter(
        evidenceRoot: failedRoot,
        commandOutputPath: 'failed.log',
      );
      await failedWriter.markRunStarted();
      final started = await _readAggregate(failedRoot);
      expect(started['status'], 'fail');
      expect(started['walkthroughStatus'], 'not-completed');
      expect(started['completionGateEligible'], isFalse);
      await failedWriter.writeEvidence(<String, dynamic>{
        'walkthroughStatus': 'running',
        'requestedPhases': <String>['B12', 'B15'],
        'expectedWorkflowCountByPhase': <String, int>{'B12': 1, 'B15': 2},
        'workflowEvidence': _responseData(
          screenshotCaptureStatus: 'unavailable',
        )['workflowEvidence'],
        'screenshotCapture': <String, Object?>{
          'status': 'unavailable',
          'reason': 'MissingPluginException(captureScreenshot)',
          'requestedScreenshotNames': <String>[
            ..._harnessScreenshotNames,
            'B15_expected_workflow_action',
          ],
        },
      });
      final failed = await _readAggregate(failedRoot);
      expect(failed['status'], 'fail');
      expect(failed['walkthroughStatus'], 'fail');
      expect(failed['screenshotStatus'], 'unavailable');
      expect(failed['completionGateEligible'], isFalse);
      expect(failed['workflowCount'], 1);
      expect(failed['expectedWorkflowCount'], 3);
      expect(
        (failed['phaseSummaries'] as List<dynamic>).map(
          (dynamic phase) => (phase as Map<String, dynamic>)['status'],
        ),
        <String>['walkthrough-only', 'fail'],
      );
      final emptyB15Phase =
          jsonDecode(
                await File(
                  '${failedRoot.path}/B15/workflow-ui-evidence.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(emptyB15Phase['workflowCount'], 0);
      expect(emptyB15Phase['phaseOutcome'], 'no_workflows_recorded');
      expect(
        emptyB15Phase['phaseOutcomeReason'],
        'No workflow evidence rows were recorded for phase B15 '
        '(expected workflow count: 2).',
      );
      expect(emptyB15Phase['completionGateEligible'], isFalse);
    } finally {
      await temporaryRoot.delete(recursive: true);
    }
  });
}

const _harnessScreenshotNames = <String>[
  'B12_harness_start',
  'B12_harness_action',
  'B12_harness_complete',
];

const _harnessVisibleTexts = <String, String>{
  'B12_harness_start': 'Harness start screen',
  'B12_harness_action': 'Harness action screen',
  'B12_harness_complete': 'Harness complete screen',
};

Map<String, dynamic> _responseData({
  required String screenshotCaptureStatus,
  String? screenshotUnavailableReason,
}) => <String, dynamic>{
  'walkthroughStatus': 'pass',
  'requestedPhases': <String>['B12'],
  'expectedWorkflowCountByPhase': <String, int>{'B12': 1},
  'deviceName': 'test-device',
  'emulatorName': 'test-device',
  'deviceClass': 'test',
  'platform': 'test',
  'workflowEvidence': <Map<String, Object?>>[
    <String, Object?>{
      'phase': 'B12',
      'appId': 'workflow-ui-evidence-harness',
      'workflowId': 'workflow-ui-evidence-harness',
      'screenshotNames': _harnessScreenshotNames,
      'status': 'pass',
    },
  ],
  'screenshotCapture': <String, Object?>{
    'status': screenshotCaptureStatus,
    if (screenshotUnavailableReason != null)
      'reason': screenshotUnavailableReason,
  },
};

Future<Map<String, dynamic>> _readAggregate(Directory evidenceRoot) async =>
    jsonDecode(
          await File(
            '${evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
          ).readAsString(),
        )
        as Map<String, dynamic>;
