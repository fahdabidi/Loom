import 'dart:io';

import 'package:loom_ux_judges/b25_capture_integrity.dart';
import 'package:test/test.dart';

void main() {
  test(
    'the capture script resolves screencap adb through the common resolver',
    () {
      final captureScript = File(
        'bin/b25_capture_workflow_screenshots.dart',
      ).readAsStringSync();

      expect(
        captureScript,
        contains('adbExecutableForEnvironment(Platform.environment)'),
      );
      expect(captureScript, isNot(contains("Process.runSync(\n        'adb'")));
    },
  );

  test(
    'byte-identical frames fail the workflow instead of counting twice',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-duplicates-',
      );
      addTearDown(() => root.delete(recursive: true));
      final first = File('${root.path}/member_primary_result.png')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final duplicate = File('${root.path}/member_result_receiver.png')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final distinct = File('${root.path}/member_complete.png')
        ..writeAsBytesSync(<int>[4, 5, 6]);
      final workflow = <String, dynamic>{
        'status': 'pass',
        'screenshotStatus': 'complete',
        'b25ActionProofStatus': 'pass',
        'screenshotPaths': <String>[first.path, duplicate.path, distinct.path],
        'productFindings': <String>[],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasDuplicateFrames, isTrue);
      expect(integrity.verifiedScreenshotCount, 2);
      expect(workflow['status'], 'fail');
      expect(workflow['screenshotStatus'], 'failed-duplicate-frame');
      expect(workflow['b25ActionProofStatus'], 'fail');
      expect(workflow['screenshotCount'], 2);
      expect(
        (workflow['productFindings'] as List<dynamic>).single,
        allOf(contains(first.path), contains(duplicate.path)),
      );
    },
  );
}
