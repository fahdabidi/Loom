import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/b25_capture_drive_plan.dart';
import 'package:test/test.dart';

void main() {
  group('B25 prebuilt application-binary capture', () {
    test('the source-build command and phase loop remain unchanged', () {
      const phases = <String>['B12', 'B14'];

      expect(b25CaptureDrivePhases(phases: phases), orderedEquals(phases));
      expect(
        b25CaptureFlutterDriveCommand(
          device: 'emulator-5554',
          phase: 'B14',
          communities: const <String>['Camera Club', 'Chess Club'],
          shardCount: 7,
          shardIndex: 3,
        ),
        orderedEquals(<String>[
          'drive',
          '--driver=test_driver/workflow_ui_evidence_test.dart',
          '--target=integration_test/workflow_ui_evidence_test.dart',
          '-d',
          'emulator-5554',
          '--dart-define=LOOM_EVIDENCE_EXTERNAL_ANDROID_SCREENSHOTS=true',
          '--dart-define=LOOM_EVIDENCE_PHASE_FILTER=B14',
          '--dart-define=LOOM_EVIDENCE_COMMUNITY_FILTER=Camera Club,Chess Club',
          '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT=7',
          '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX=3',
        ]),
      );
    });

    test('one prebuilt drive has no compile-time selection defines', () {
      const applicationBinary = '/build/loom-unfiltered.apk';
      const phases = <String>[
        'B12',
        'B13',
        'B14',
        'B15',
        'B16',
        'B17',
        'B18',
        'B19',
        'B20',
      ];

      expect(
        b25CaptureDrivePhases(
          phases: phases,
          applicationBinaryPath: applicationBinary,
        ),
        orderedEquals(const <String>['B12']),
        reason: 'An unfiltered prebuilt APK is driven once for all phases.',
      );
      final command = b25CaptureFlutterDriveCommand(
        device: 'emulator-5554',
        phase: 'B12',
        communities: const <String>['Camera Club'],
        shardCount: 17,
        shardIndex: 9,
        applicationBinaryPath: applicationBinary,
      );

      expect(command, contains('--use-application-binary=$applicationBinary'));
      expect(
        command.where((argument) => argument.startsWith('--dart-define')),
        isEmpty,
      );
      expect(command, isNot(contains('LOOM_EVIDENCE_PHASE_FILTER')));
      expect(command, isNot(contains('LOOM_EVIDENCE_COMMUNITY_FILTER')));
      expect(command, isNot(contains('LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT')));
      expect(command, isNot(contains('LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX')));
    });

    test(
      'a missing prebuilt APK fails before flutter drive launches',
      () async {
        final harness = await _FakeCaptureHarness.create();
        addTearDown(harness.dispose);
        final missingApk = File('${harness.root.path}/missing.apk');

        final result = await _runCapture(<String>[
          '--use-application-binary=${missingApk.path}',
          '--evidence-root=${harness.evidenceRoot.path}',
        ], environment: harness.environment);

        expect(result.exitCode, 64);
        expect(result.stderr, contains(missingApk.path));
        expect(result.stderr, contains('path does not exist'));
        expect(harness.flutterInvocations.existsSync(), isFalse);
      },
    );

    test(
      'a prebuilt APK runs one drive, streams a screenshot event, and preserves all phases',
      () async {
        final harness = await _FakeCaptureHarness.create();
        addTearDown(harness.dispose);
        final applicationBinary = File('${harness.root.path}/loom.apk')
          ..writeAsBytesSync(<int>[1, 2, 3]);

        final result = await _runCapture(<String>[
          '--use-application-binary=${applicationBinary.path}',
          '--evidence-root=${harness.evidenceRoot.path}',
          '--log=${harness.root.path}/drive.log',
          '--progress-report=${harness.root.path}/progress.json',
        ], environment: harness.environment);

        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
        final invocations = harness.flutterInvocations
            .readAsLinesSync()
            .where((line) => line.isNotEmpty)
            .toList();
        expect(invocations, hasLength(1));
        expect(
          invocations.single,
          contains('--use-application-binary=${applicationBinary.path}'),
        );
        expect(invocations.single, isNot(contains('--dart-define')));
        expect(result.stdout, contains('captured '));
        expect(result.stdout, contains('prebuilt_listener.png'));

        final aggregate = _jsonFile(
          File(
            '${harness.evidenceRoot.path}/B20/all-workflow-ui-evidence.json',
          ),
        );
        expect(aggregate['phases'], hasLength(9));
        expect(aggregate['screenshotCount'], 180);
        expect(aggregate['fullB25Coverage'], isTrue);
        expect(aggregate['commitEligible'], isTrue);
        expect(aggregate['completionGateEligible'], isTrue);
      },
    );

    test(
      'full B25 rejects a partial phase request before flutter drive',
      () async {
        final harness = await _FakeCaptureHarness.create();
        addTearDown(harness.dispose);
        final applicationBinary = File('${harness.root.path}/loom.apk')
          ..writeAsBytesSync(<int>[1, 2, 3]);

        final result = await _runCapture(<String>[
          '--use-application-binary=${applicationBinary.path}',
          '--phases=B12',
          '--evidence-root=${harness.evidenceRoot.path}',
        ], environment: harness.environment);

        expect(result.exitCode, 64);
        expect(result.stderr, contains('requires full B12-B20 coverage'));
        expect(harness.flutterInvocations.existsSync(), isFalse);
      },
    );

    test('full B25 refuses a low screenshot result', () async {
      final harness = await _FakeCaptureHarness.create();
      addTearDown(harness.dispose);
      harness.environment['FAKE_SCREENSHOT_COUNT'] = '19';
      final applicationBinary = File('${harness.root.path}/loom.apk')
        ..writeAsBytesSync(<int>[1, 2, 3]);

      final result = await _runCapture(<String>[
        '--use-application-binary=${applicationBinary.path}',
        '--evidence-root=${harness.evidenceRoot.path}',
      ], environment: harness.environment);

      expect(result.exitCode, 65);
      expect(
        result.stderr,
        contains('expected at least 180 screenshots, found 171'),
      );
      final aggregate = _jsonFile(
        File('${harness.evidenceRoot.path}/B20/all-workflow-ui-evidence.json'),
      );
      expect(aggregate['screenshotCount'], 171);
      expect(aggregate['status'], 'fail');
      expect(aggregate['commitEligible'], isFalse);
      expect(aggregate['completionGateEligible'], isFalse);
    });

    test('full B25 refuses byte-identical frames', () async {
      final harness = await _FakeCaptureHarness.create();
      addTearDown(harness.dispose);
      harness.environment['FAKE_DUPLICATE_FRAME'] = 'true';
      final applicationBinary = File('${harness.root.path}/loom.apk')
        ..writeAsBytesSync(<int>[1, 2, 3]);

      final result = await _runCapture(<String>[
        '--use-application-binary=${applicationBinary.path}',
        '--evidence-root=${harness.evidenceRoot.path}',
      ], environment: harness.environment);

      expect(result.exitCode, 65);
      expect(result.stderr, contains('byte-identical workflow frames'));
      final aggregate = _jsonFile(
        File('${harness.evidenceRoot.path}/B20/all-workflow-ui-evidence.json'),
      );
      expect(aggregate['status'], 'fail');
      expect(aggregate['commitEligible'], isFalse);
      expect(aggregate['completionGateEligible'], isFalse);
    });

    test(
      'a phase with zero workflows records its outcome and reason',
      () async {
        final harness = await _FakeCaptureHarness.create();
        addTearDown(harness.dispose);
        harness.environment['FAKE_EMPTY_PHASE'] = 'B15';
        final applicationBinary = File('${harness.root.path}/loom.apk')
          ..writeAsBytesSync(<int>[1, 2, 3]);

        final result = await _runCapture(<String>[
          '--use-application-binary=${applicationBinary.path}',
          '--evidence-root=${harness.evidenceRoot.path}',
        ], environment: harness.environment);

        expect(result.exitCode, 65);
        expect(
          result.stderr,
          contains('phase B15 did not record any workflows'),
        );
        final phaseManifest = _jsonFile(
          File('${harness.evidenceRoot.path}/B15/workflow-ui-evidence.json'),
        );
        expect(phaseManifest['status'], 'fail');
        expect(phaseManifest['workflowCount'], 0);
        expect(phaseManifest['phaseOutcome'], 'no_workflows_recorded');
        expect(
          phaseManifest['phaseOutcomeReason'],
          'no workflows recorded, reason unknown',
        );
        expect(phaseManifest['completionGateEligible'], isFalse);
      },
    );

    test('canonical eligibility refuses incomplete result guards', () {
      expect(
        isCanonicalB25CaptureEligible(
          mode: 'full-b25',
          fullB25Coverage: false,
          screenshotCount: 180,
          hasDuplicateFrames: false,
        ),
        isFalse,
      );
      expect(
        isCanonicalB25CaptureEligible(
          mode: 'full-b25',
          fullB25Coverage: true,
          screenshotCount: 179,
          hasDuplicateFrames: false,
        ),
        isFalse,
      );
      expect(
        isCanonicalB25CaptureEligible(
          mode: 'full-b25',
          fullB25Coverage: true,
          screenshotCount: 180,
          hasDuplicateFrames: true,
        ),
        isFalse,
      );
      expect(
        isCanonicalB25CaptureEligible(
          mode: 'full-b25',
          fullB25Coverage: true,
          screenshotCount: 180,
          hasDuplicateFrames: false,
        ),
        isTrue,
      );
    });
  });
}

Future<ProcessResult> _runCapture(
  List<String> arguments, {
  required Map<String, String> environment,
}) => Process.run(
  _dartExecutable(),
  <String>[_captureScript.path, ...arguments],
  workingDirectory: _appRoot.path,
  environment: <String, String>{...Platform.environment, ...environment},
  includeParentEnvironment: false,
);

String _dartExecutable() {
  final result = Process.runSync('which', <String>['dart']);
  if (result.exitCode != 0) {
    throw StateError('dart must be available to execute the capture CLI test.');
  }
  return result.stdout.toString().trim();
}

Map<String, dynamic> _jsonFile(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Directory get _packageRoot => Directory.current;

Directory get _appRoot => _packageRoot.parent.parent.parent;

File get _captureScript =>
    File('${_packageRoot.path}/bin/b25_capture_workflow_screenshots.dart');

class _FakeCaptureHarness {
  _FakeCaptureHarness._({
    required this.root,
    required this.evidenceRoot,
    required this.flutterInvocations,
    required this.environment,
  });

  final Directory root;
  final Directory evidenceRoot;
  final File flutterInvocations;
  final Map<String, String> environment;

  static Future<_FakeCaptureHarness> create() async {
    final root = await Directory.systemTemp.createTemp('loom-b25-prebuilt-');
    final bin = Directory('${root.path}/bin')..createSync();
    final sdk = Directory('${root.path}/sdk/platform-tools')
      ..createSync(recursive: true);
    final evidenceRoot = Directory('${root.path}/evidence');
    final flutterInvocations = File('${root.path}/flutter-invocations.txt');
    final flutter = File('${bin.path}/flutter');
    final adb = File('${sdk.path}/adb');
    flutter.writeAsStringSync(_fakeFlutterScript);
    adb.writeAsStringSync(_fakeAdbScript);
    await Process.run('chmod', <String>['+x', flutter.path, adb.path]);
    return _FakeCaptureHarness._(
      root: root,
      evidenceRoot: evidenceRoot,
      flutterInvocations: flutterInvocations,
      environment: <String, String>{
        'PATH': '${bin.path}:${Platform.environment['PATH']}',
        'ANDROID_SDK_ROOT': '${root.path}/sdk',
        'FAKE_FLUTTER_INVOCATIONS': flutterInvocations.path,
      },
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
}

const _fakeFlutterScript = r'''#!/bin/sh
set -eu
printf '%s\n' "$*" >> "$FAKE_FLUTTER_INVOCATIONS"
root="$WORKFLOW_EVIDENCE_ROOT"
for phase in B12 B13 B14 B15 B16 B17 B18 B19 B20
do
  mkdir -p "$root/$phase"
  if [ "${FAKE_EMPTY_PHASE:-}" = "$phase" ]
  then
    printf '{"phase":"%s","workflows":[]}' "$phase" > "$root/$phase/workflow-ui-evidence.json"
    continue
  fi
  paths=""
  index=1
  while [ "$index" -le "${FAKE_SCREENSHOT_COUNT:-20}" ]
  do
    frame="$root/$phase/frame_$index.png"
    if [ "${FAKE_DUPLICATE_FRAME:-false}" = "true" ] && [ "$phase" = "B12" ] && [ "$index" -eq 2 ]
    then
      printf '%s' 'B12-frame-1' > "$frame"
    else
      printf '%s' "$phase-frame-$index" > "$frame"
    fi
    if [ -n "$paths" ]; then paths="$paths,"; fi
    paths="$paths\"$frame\""
    index=$((index + 1))
  done
  printf '{"phase":"%s","workflows":[{"workflowId":"workflow-%s","screenshotPaths":[%s]}]}' "$phase" "$phase" "$paths" > "$root/$phase/workflow-ui-evidence.json"
done
printf '%s\n' 'B25_CAPTURE_PROGRESS {"status":"screenshot-start","phase":"B12","screenshotName":"prebuilt_listener"}'
''';

const _fakeAdbScript = r'''#!/bin/sh
set -eu
case "$*" in
  *"dumpsys window displays"*)
    printf '%s\n' 'mCurrentFocus=Window{abc123 u0 com.example.loom_communities_demo/.MainActivity}'
    ;;
  *"exec-out screencap -p"*)
    printf '%s' 'fake-prebuilt-listener-frame'
    ;;
  *)
    printf '%s\n' "unexpected fake adb invocation: $*" >&2
    exit 1
    ;;
esac
''';
