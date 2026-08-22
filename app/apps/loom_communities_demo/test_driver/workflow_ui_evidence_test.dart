import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

import 'workflow_ui_evidence_writer.dart';

Future<void> main() async {
  final evidenceRoot = Directory(
    Platform.environment['WORKFLOW_EVIDENCE_ROOT'] ??
        '../../../docs/Build Plan V2/Evidence',
  );
  final commandOutputPath =
      Platform.environment['WORKFLOW_EVIDENCE_COMMAND_OUTPUT'] ??
      '${evidenceRoot.path}/B20/flutter-drive-workflow-ui-evidence.log';
  final evidenceWriter = WorkflowUiEvidenceWriter(
    evidenceRoot: evidenceRoot,
    commandOutputPath: commandOutputPath,
  );

  await evidenceWriter.markRunStarted();

  await integrationDriver(
    driver: await FlutterDriver.connect(),
    writeResponseOnFailure: true,
    onScreenshot: evidenceWriter.recordScreenshot,
    responseDataCallback: evidenceWriter.writeEvidence,
  );
}
