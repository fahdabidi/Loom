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
    'a byte-identical pair with NO action-proof declaration at all is '
    'informational only and does not fail the row',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-undeclared-duplicates-',
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

      expect(integrity.hasFailingFindings, isFalse);
      expect(integrity.actionProofDuplicates, isEmpty);
      expect(integrity.missingDeclarations, isEmpty);
      expect(integrity.informationalDuplicates, hasLength(1));
      // Every captured file counts now: a duplicate outside a declared pair
      // is still real evidence, just not proof of an action.
      expect(integrity.verifiedScreenshotCount, 3);
      expect(workflow['status'], 'pass');
      expect(workflow['screenshotCount'], 3);
      expect(
        (workflow['captureIntegrityFindings'] as List<dynamic>).single,
        containsPair('kind', 'byte-identical-frame-informational'),
      );
    },
  );

  test(
    'a byte-identical DECLARED action-proof pair fails the row',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-declared-duplicate-',
      );
      addTearDown(() => root.delete(recursive: true));
      final start = File('${root.path}/start.png')
        ..writeAsBytesSync(<int>[9, 9, 9]);
      final action = File('${root.path}/primary_action.png')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      // Identical to `action`: the tap fired (or did not) and the screen
      // rendered nothing new. This is exactly what the guard exists to
      // catch: the boundary that is supposed to prove an action fired.
      final result = File('${root.path}/primary_result.png')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      const names = ['start', 'primary_action', 'primary_result'];
      final workflow = <String, dynamic>{
        'status': 'pass',
        'screenshotStatus': 'complete',
        'b25RowOutcome': 'attempted',
        'b25ActionProofStatus': 'pass',
        'actionProofFramePairsRequired': true,
        'actionProofFramePairs': const [
          ['primary_action', 'primary_result'],
        ],
        'screenshotNames': names,
        'screenshotPaths': [start.path, action.path, result.path],
        'screenshotPathsByName': {
          'start': start.path,
          'primary_action': action.path,
          'primary_result': result.path,
        },
        'productFindings': <String>[],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasFailingFindings, isTrue);
      expect(integrity.actionProofDuplicates, hasLength(1));
      expect(integrity.missingDeclarations, isEmpty);
      expect(workflow['status'], 'fail');
      expect(workflow['screenshotStatus'], 'failed-duplicate-frame');
      expect(workflow['b25ActionProofStatus'], 'fail');
      expect(
        (workflow['productFindings'] as List<dynamic>).single,
        allOf(
          contains(action.path),
          contains(result.path),
          contains('declared action-proof frames'),
        ),
      );
    },
  );

  test(
    'diagnostic frames from a failed row are never summed into '
    'verifiedScreenshotCount/screenshotCount, and byte-identity among them '
    'is never flagged',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-diagnostic-frames-',
      );
      addTearDown(() => root.delete(recursive: true));
      // Byte-identical to each other -- if the duplicate-frame guard ever
      // looked at diagnostics, this pair would trip it.
      final diagnosticStart = File('${root.path}/start.png')
        ..writeAsBytesSync(<int>[7, 7, 7]);
      final diagnosticAction = File('${root.path}/primary_action.png')
        ..writeAsBytesSync(<int>[7, 7, 7]);
      final workflow = <String, dynamic>{
        'status': 'row_execution_failed',
        'screenshotStatus': 'complete',
        'b25RowOutcome': 'row_execution_failed',
        'b25ActionProofStatus': 'row_execution_failed',
        // No evidence frames at all: this row captured two frames and then
        // failed. Only the diagnostic field carries them.
        'screenshotNames': const <String>[],
        'screenshotPaths': const <String>[],
        'diagnosticScreenshotNames': const ['start', 'primary_action'],
        'diagnosticScreenshotPaths': [
          diagnosticStart.path,
          diagnosticAction.path,
        ],
        'productFindings': <String>['forced failure after two frames'],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasFailingFindings, isFalse);
      expect(integrity.verifiedScreenshotCount, 0);
      expect(integrity.actionProofDuplicates, isEmpty);
      expect(integrity.missingDeclarations, isEmpty);
      expect(integrity.informationalDuplicates, isEmpty);
      expect(workflow['screenshotCount'], 0);
      expect(workflow['status'], 'row_execution_failed');
      expect(workflow.containsKey('captureIntegrityFindings'), isFalse);
      // The diagnostic files themselves are untouched -- this function must
      // not delete or otherwise treat them as invalid just because it does
      // not count them.
      expect(diagnosticStart.existsSync(), isTrue);
      expect(diagnosticAction.existsSync(), isTrue);
    },
  );

  test(
    'a duplicate OUTSIDE a declared pair -- the gear-loan-request shape -- '
    'passes even though the row declares other pairs',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-gear-loan-request-shape-',
      );
      addTearDown(() => root.delete(recursive: true));
      final start = File('${root.path}/start.png')..writeAsBytesSync(<int>[1]);
      final action = File('${root.path}/primary_action.png')
        ..writeAsBytesSync(<int>[2]);
      final primaryResult = File('${root.path}/primary_result.png')
        ..writeAsBytesSync(<int>[3]);
      // No scroll was needed to reveal the alternate action, so it renders
      // the exact same pixels as primaryResult. This is real and must NOT
      // fail the row: the tap boundary it actually proves --
      // alternate_action -> result_receiver -- is declared separately and
      // is byte-distinct.
      final alternateAction = File('${root.path}/alternate_action.png')
        ..writeAsBytesSync(<int>[3]);
      final result = File('${root.path}/result_receiver.png')
        ..writeAsBytesSync(<int>[4]);
      const names = [
        'start',
        'primary_action',
        'primary_result',
        'alternate_action',
        'result_receiver',
      ];
      final files = [start, action, primaryResult, alternateAction, result];
      final workflow = <String, dynamic>{
        'status': 'pass',
        'screenshotStatus': 'complete',
        'b25RowOutcome': 'attempted',
        'b25ActionProofStatus': 'pass',
        'actionProofFramePairsRequired': true,
        'actionProofFramePairs': const [
          ['primary_action', 'primary_result'],
          ['alternate_action', 'result_receiver'],
        ],
        'screenshotNames': names,
        'screenshotPaths': [for (final file in files) file.path],
        'screenshotPathsByName': {
          for (var index = 0; index < names.length; index += 1)
            names[index]: files[index].path,
        },
        'productFindings': <String>[],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasFailingFindings, isFalse);
      expect(integrity.actionProofDuplicates, isEmpty);
      expect(integrity.missingDeclarations, isEmpty);
      expect(integrity.informationalDuplicates, hasLength(1));
      expect(integrity.verifiedScreenshotCount, 5);
      expect(workflow['status'], 'pass');
      expect(workflow['screenshotStatus'], 'complete');
      expect(workflow['productFindings'], isEmpty);
    },
  );

  test(
    'the closure rule fails a row that fired an action but declared no pair '
    '-- it must not silently pass',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-closure-rule-',
      );
      addTearDown(() => root.delete(recursive: true));
      final start = File('${root.path}/start.png')..writeAsBytesSync(<int>[1]);
      final action = File('${root.path}/primary_action.png')
        ..writeAsBytesSync(<int>[2]);
      final result = File('${root.path}/primary_result.png')
        ..writeAsBytesSync(<int>[3]);
      const names = ['start', 'primary_action', 'primary_result'];
      final files = [start, action, result];
      final workflow = <String, dynamic>{
        'status': 'pass',
        'screenshotStatus': 'complete',
        'b25RowOutcome': 'attempted',
        'b25ActionProofStatus': 'pass',
        'actionProofFramePairsRequired': true,
        // Declares nothing, even though a primary transition fired -- the
        // dodge the closure rule exists to catch.
        'actionProofFramePairs': const <List<String>>[],
        'screenshotNames': names,
        'screenshotPaths': [for (final file in files) file.path],
        'screenshotPathsByName': {
          for (var index = 0; index < names.length; index += 1)
            names[index]: files[index].path,
        },
        'productFindings': <String>[],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasFailingFindings, isTrue);
      expect(integrity.missingDeclarations, hasLength(1));
      expect(integrity.actionProofDuplicates, isEmpty);
      expect(workflow['status'], 'fail');
      expect(workflow['screenshotStatus'], 'failed-duplicate-frame');
      expect(
        (workflow['productFindings'] as List<dynamic>).single,
        contains('requires a declared action-proof frame pair'),
      );
    },
  );

  test(
    'a declared pair naming a screenshot absent from screenshotNames fails '
    'via the closure rule',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'loom-b25-closure-rule-bad-name-',
      );
      addTearDown(() => root.delete(recursive: true));
      final start = File('${root.path}/start.png')..writeAsBytesSync(<int>[1]);
      final action = File('${root.path}/primary_action.png')
        ..writeAsBytesSync(<int>[2]);
      final result = File('${root.path}/primary_result.png')
        ..writeAsBytesSync(<int>[3]);
      const names = ['start', 'primary_action', 'primary_result'];
      final files = [start, action, result];
      final workflow = <String, dynamic>{
        'status': 'pass',
        'screenshotStatus': 'complete',
        'b25RowOutcome': 'attempted',
        'b25ActionProofStatus': 'pass',
        'actionProofFramePairsRequired': true,
        'actionProofFramePairs': const [
          ['primary_action', 'a_name_never_captured'],
        ],
        'screenshotNames': names,
        'screenshotPaths': [for (final file in files) file.path],
        'screenshotPathsByName': {
          for (var index = 0; index < names.length; index += 1)
            names[index]: files[index].path,
        },
        'productFindings': <String>[],
      };

      final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);

      expect(integrity.hasFailingFindings, isTrue);
      expect(integrity.missingDeclarations, hasLength(1));
      expect(workflow['status'], 'fail');
      expect(
        (workflow['productFindings'] as List<dynamic>).single,
        contains('a_name_never_captured'),
      );
    },
  );
}
