import 'package:loom_ux_judges/loom_ux_judges.dart' show fullB25MinimumScreenshotRows;

/// The `flutter drive` argument construction for B25 screenshot capture.
///
/// A supplied application binary is already compiled, so Dart environment
/// defines cannot change its walkthrough selection. In that case one
/// unfiltered drive invocation must cover every requested capture phase.
List<String> b25CaptureDrivePhases({
  required List<String> phases,
  String? applicationBinaryPath,
}) {
  if (applicationBinaryPath == null || phases.isEmpty) {
    return List<String>.unmodifiable(phases);
  }
  return List<String>.unmodifiable(<String>[phases.first]);
}

/// Builds one B25 `flutter drive` command.
///
/// Without [applicationBinaryPath], this retains the existing source-build
/// selection defines. With a prebuilt binary, it deliberately supplies no
/// Dart defines: all of them are compile-time values already baked into the
/// APK.
List<String> b25CaptureFlutterDriveCommand({
  required String device,
  required String phase,
  required List<String> communities,
  required int shardCount,
  required int shardIndex,
  String? applicationBinaryPath,
}) {
  final command = <String>[
    'drive',
    '--driver=test_driver/workflow_ui_evidence_test.dart',
    '--target=integration_test/workflow_ui_evidence_test.dart',
    '-d',
    device,
  ];
  if (applicationBinaryPath != null) {
    command.add('--use-application-binary=$applicationBinaryPath');
    return List<String>.unmodifiable(command);
  }

  command.addAll(<String>[
    '--dart-define=LOOM_EVIDENCE_EXTERNAL_ANDROID_SCREENSHOTS=true',
    '--dart-define=LOOM_EVIDENCE_PHASE_FILTER=$phase',
  ]);
  if (communities.isNotEmpty) {
    command.add(
      '--dart-define=LOOM_EVIDENCE_COMMUNITY_FILTER=${communities.join(',')}',
    );
  }
  if (shardCount > 1) {
    command.addAll(<String>[
      '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT=$shardCount',
      '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX=$shardIndex',
    ]);
  }
  return List<String>.unmodifiable(command);
}

/// Whether a produced aggregate, rather than its launch command, is eligible
/// to close the canonical B25 capture gate.
bool isCanonicalB25CaptureEligible({
  required String mode,
  required bool fullB25Coverage,
  required int screenshotCount,
  required bool hasDuplicateFrames,
}) =>
    mode == 'full-b25' &&
    fullB25Coverage &&
    screenshotCount >= fullB25MinimumScreenshotRows &&
    !hasDuplicateFrames;
