import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_skill_debug_harness/loom_skill_debug_harness.dart';

void main() {
  test('wf_skill-prompt-build-validate-complete', () {
    final outputDirectory = Directory.systemTemp.createTempSync(
      'loom_b11_skill_prompt_',
    );
    final report = const LoomSkillLocalBuildHarness().buildAndValidate(
      prompt: _readText(
        'docs/Build Plan V2/Skill/examples/arbitrary-camera-club/owner-prompt.txt',
      ),
      outputDirectory: outputDirectory,
    );

    expect(report.complete, isTrue);
    expect(report.mode, 'local-demo');
    expect(report.communityId, 'community_camera_club');
    expect(report.extensionId, 'ext_camera_club');
    expect(report.importedCommunityName, 'Camera Club');
    expect(report.openExtensionId, 'local:ext_camera_club@latest');
    expect(
      report.workflowResults.map((result) => result.workflowId),
      containsAll([
        'photo-walk-rsvp',
        'critique-submission',
        'gear-loan-request',
      ]),
    );
    expect(report.workflowResults.every((result) => result.complete), isTrue);

    for (final path in report.generatedArtifacts.allPaths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(
      report.generatedArtifacts.extensionPackagePath.endsWith(
        '.loom-extension.zip',
      ),
      isTrue,
    );
    expect(
      report.generatedArtifacts.initializationPackagePath.endsWith(
        '.loom-init.zip',
      ),
      isTrue,
    );

    final validationReport =
        jsonDecode(
              File(
                '${outputDirectory.path}/validation-report.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(validationReport['complete'], isTrue);
    expect(validationReport['openExtensionId'], 'local:ext_camera_club@latest');
  });
}

String _readText(String path) {
  final candidates = ['../$path', '../../../$path'];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail('Could not find $path from ${Directory.current.path}');
}
