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

  test('an audience-blocked row has its own unproven summary bucket', () async {
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
          'B12': 2 + blockedAudienceRows.length,
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
            'status': 'pass',
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
      expect(summary['recordedRows'], 6);
      expect(summary['provenRows'], 1);
      expect(summary['completedRows'], 2);
      expect(summary['primaryActionUnavailableRows'], 1);
      expect(summary['blockedByAudienceRows'], 4);
      expect(summary['blockedByAudienceRowsByCommunity'], {'Book Club': 4});
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
        'requestedPhases': <String>['B12', 'B20'],
        'expectedWorkflowCountByPhase': <String, int>{'B12': 1, 'B20': 2},
        'workflowEvidence': _responseData(
          screenshotCaptureStatus: 'unavailable',
        )['workflowEvidence'],
        'screenshotCapture': <String, Object?>{
          'status': 'unavailable',
          'reason': 'MissingPluginException(captureScreenshot)',
          'requestedScreenshotNames': <String>[
            ..._harnessScreenshotNames,
            'B20_announcement_admin_start',
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
