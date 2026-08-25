import 'dart:io';

class DuplicateScreenshotFrame {
  const DuplicateScreenshotFrame({
    required this.firstScreenshotPath,
    required this.duplicateScreenshotPath,
  });

  final String firstScreenshotPath;
  final String duplicateScreenshotPath;

  /// This check intentionally cannot decide whether the repeated bytes came
  /// from a duplicate write or from a screen that did not change.  Either case
  /// fails the capture: B25 needs the second frame to prove an action, and
  /// guessing would certify evidence the capture cannot support.
  String get detail =>
      'The frames "$firstScreenshotPath" and "$duplicateScreenshotPath" are '
      'byte-for-byte identical. The capture cannot distinguish a legitimately '
      'unchanged screen from a duplicate write, so this workflow evidence is '
      'invalid and must be reviewed and re-run.';

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'byte-identical-workflow-frame',
    'firstScreenshotPath': firstScreenshotPath,
    'duplicateScreenshotPath': duplicateScreenshotPath,
    'detail': detail,
  };
}

class WorkflowScreenshotFrameIntegrity {
  const WorkflowScreenshotFrameIntegrity({
    required this.verifiedScreenshotCount,
    required this.duplicateFrames,
  });

  final int verifiedScreenshotCount;
  final List<DuplicateScreenshotFrame> duplicateFrames;

  bool get hasDuplicateFrames => duplicateFrames.isNotEmpty;
}

Future<WorkflowScreenshotFrameIntegrity> applyWorkflowScreenshotFrameIntegrity(
  Map<String, dynamic> workflow,
) async {
  final screenshotPaths =
      (workflow['screenshotPaths'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false);
  final distinctFrames = <_CapturedScreenshotBytes>[];
  final duplicates = <DuplicateScreenshotFrame>[];

  for (final screenshotPath in screenshotPaths) {
    final bytes = await File(screenshotPath).readAsBytes();
    _CapturedScreenshotBytes? firstMatchingFrame;
    for (final distinctFrame in distinctFrames) {
      if (_sameBytes(distinctFrame.bytes, bytes)) {
        firstMatchingFrame = distinctFrame;
        break;
      }
    }
    if (firstMatchingFrame == null) {
      distinctFrames.add(
        _CapturedScreenshotBytes(path: screenshotPath, bytes: bytes),
      );
    } else {
      duplicates.add(
        DuplicateScreenshotFrame(
          firstScreenshotPath: firstMatchingFrame.path,
          duplicateScreenshotPath: screenshotPath,
        ),
      );
    }
  }

  final integrity = WorkflowScreenshotFrameIntegrity(
    verifiedScreenshotCount: distinctFrames.length,
    duplicateFrames: duplicates,
  );
  if (!integrity.hasDuplicateFrames) {
    return integrity;
  }

  final existingIntegrityFindings = <Object?>[
    ...(workflow['captureIntegrityFindings'] as List<dynamic>? ??
        const <dynamic>[]),
  ];
  existingIntegrityFindings.addAll(
    duplicates.map((duplicate) => duplicate.toJson()),
  );
  final productFindings = <Object?>[
    ...(workflow['productFindings'] as List<dynamic>? ?? const <dynamic>[]),
  ];
  productFindings.addAll(duplicates.map((duplicate) => duplicate.detail));

  // Retain every path in screenshotPaths.  The colliding frame is audit
  // evidence, not something this writer may hide or replace.  Only the
  // verified count excludes it.
  workflow['status'] = 'fail';
  workflow['pass'] = false;
  workflow['screenshotStatus'] = 'failed-duplicate-frame';
  workflow['b25ActionProofStatus'] = 'fail';
  workflow['screenshotCount'] = integrity.verifiedScreenshotCount;
  workflow['invalidScreenshotCount'] = duplicates.length;
  workflow['captureIntegrityFindings'] = existingIntegrityFindings;
  workflow['productFindings'] = productFindings;
  return integrity;
}

class _CapturedScreenshotBytes {
  const _CapturedScreenshotBytes({required this.path, required this.bytes});

  final String path;
  final List<int> bytes;
}

bool _sameBytes(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
