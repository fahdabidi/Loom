import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import '../test_driver/workflow_ui_evidence_writer.dart';

void main() {
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
