import 'dart:io';

/// A byte-identical pair across a DECLARED action-proof boundary -- the pair
/// the test itself said has a tap between the two frames. This is the
/// failure case: the frame that was supposed to prove the tap fired is
/// indistinguishable from the frame before it, so either the tap did not
/// fire or it fired and rendered nothing. Either way this is not proof of
/// an action, and the row is invalid.
class DuplicateActionProofFrame {
  const DuplicateActionProofFrame({
    required this.firstScreenshotPath,
    required this.duplicateScreenshotPath,
  });

  final String firstScreenshotPath;
  final String duplicateScreenshotPath;

  String get detail =>
      'The declared action-proof frames "$firstScreenshotPath" and '
      '"$duplicateScreenshotPath" are byte-for-byte identical, across a '
      'boundary the test declared has a tap between them. Either the tap '
      'did not fire, or it fired and rendered nothing -- either way this is '
      'not proof of an action and the row is invalid.';

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'byte-identical-action-proof-frame',
    'firstScreenshotPath': firstScreenshotPath,
    'duplicateScreenshotPath': duplicateScreenshotPath,
    'detail': detail,
  };
}

/// A row that reports `b25RowOutcome == "attempted"` in a population that
/// requires a declared action-proof pair (`actionProofFramePairsRequired`),
/// but declared none -- or declared a pair naming a frame absent from
/// `screenshotNames`. Declaring nothing must not read as "nothing to prove":
/// that is the row dodging the check above, which is exactly what the
/// closure rule exists to catch.
class MissingActionProofDeclaration {
  const MissingActionProofDeclaration({required this.detail});

  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'missing-action-proof-declaration',
    'detail': detail,
  };
}

/// A byte-identical pair OUTSIDE any declared action-proof boundary. B25
/// never claimed the frames between two arbitrary captures must differ --
/// only that a declared tap boundary must -- so this carries no proof
/// weight in either direction. It is recorded for audit and does not fail
/// the row.
class InformationalDuplicateFrame {
  const InformationalDuplicateFrame({
    required this.firstScreenshotPath,
    required this.duplicateScreenshotPath,
  });

  final String firstScreenshotPath;
  final String duplicateScreenshotPath;

  String get detail =>
      'The frames "$firstScreenshotPath" and "$duplicateScreenshotPath" are '
      'byte-for-byte identical. Neither is a declared action-proof frame, so '
      'this cannot distinguish a legitimately unchanged screen from a '
      'duplicate write; it is recorded for audit only and does not fail '
      'the row.';

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'byte-identical-frame-informational',
    'firstScreenshotPath': firstScreenshotPath,
    'duplicateScreenshotPath': duplicateScreenshotPath,
    'detail': detail,
  };
}

class WorkflowScreenshotFrameIntegrity {
  const WorkflowScreenshotFrameIntegrity({
    required this.verifiedScreenshotCount,
    required this.actionProofDuplicates,
    required this.missingDeclarations,
    required this.informationalDuplicates,
  });

  /// Every screenshot file this workflow row captured. Unlike the old
  /// global-uniqueness check, a byte-identical frame outside a declared
  /// pair is still real, legitimate evidence -- it is simply not proof of
  /// an action -- so it is no longer excluded from the count.
  final int verifiedScreenshotCount;
  final List<DuplicateActionProofFrame> actionProofDuplicates;
  final List<MissingActionProofDeclaration> missingDeclarations;
  final List<InformationalDuplicateFrame> informationalDuplicates;

  bool get hasFailingFindings =>
      actionProofDuplicates.isNotEmpty || missingDeclarations.isNotEmpty;

  List<Map<String, Object?>> get failingFindingsJson => <Map<String, Object?>>[
    for (final duplicate in actionProofDuplicates) duplicate.toJson(),
    for (final missing in missingDeclarations) missing.toJson(),
  ];
}

Future<WorkflowScreenshotFrameIntegrity> applyWorkflowScreenshotFrameIntegrity(
  Map<String, dynamic> workflow,
) async {
  final screenshotPaths =
      (workflow['screenshotPaths'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false);
  final screenshotNames =
      (workflow['screenshotNames'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toSet();
  final pathsByName = <String, String>{
    for (final entry
        in (workflow['screenshotPathsByName'] as Map<dynamic, dynamic>? ??
                const <dynamic, dynamic>{})
            .entries)
      entry.key.toString(): entry.value.toString(),
  };
  final declaredPairs = <List<String>>[
    for (final pair
        in (workflow['actionProofFramePairs'] as List<dynamic>? ??
            const <dynamic>[]))
      if (pair is List && pair.length == 2)
        <String>[pair[0].toString(), pair[1].toString()],
  ];

  final bytesByPath = <String, List<int>>{};
  for (final path in screenshotPaths) {
    bytesByPath[path] = await File(path).readAsBytes();
  }

  // --- Closure rule: a row that fired an action in a population that
  // requires proof of it cannot dodge enforcement by declaring nothing.
  // See CLAUDE.md "B25 capture: byte-distinctness must prove an action, not
  // merely differ".
  final missingDeclarations = <MissingActionProofDeclaration>[];
  final requiresActionProof =
      workflow['b25RowOutcome'] == 'attempted' &&
      workflow['actionProofFramePairsRequired'] == true;
  if (requiresActionProof && declaredPairs.isEmpty) {
    missingDeclarations.add(
      const MissingActionProofDeclaration(
        detail:
            'This row reports b25RowOutcome "attempted" in a population '
            'that requires a declared action-proof frame pair, but declared '
            'none. A row that fired an action must name the frames that '
            'prove it.',
      ),
    );
  }
  for (final pair in declaredPairs) {
    for (final name in pair) {
      if (!screenshotNames.contains(name)) {
        missingDeclarations.add(
          MissingActionProofDeclaration(
            detail:
                'Declared action-proof pair names "$name", which does not '
                'appear in this row\'s screenshotNames.',
          ),
        );
      }
    }
  }

  // --- Declared-pair enforcement: THIS is what "proves an action" and the
  // only thing that may fail the row for byte-identity.
  final actionProofDuplicates = <DuplicateActionProofFrame>[];
  final declaredPathPairs = <List<String>>[];
  for (final pair in declaredPairs) {
    final firstPath = pathsByName[pair[0]];
    final secondPath = pathsByName[pair[1]];
    if (firstPath == null || secondPath == null) {
      // Already reported above: a declared name with no captured file.
      continue;
    }
    declaredPathPairs.add(<String>[firstPath, secondPath]);
    final firstBytes = bytesByPath[firstPath];
    final secondBytes = bytesByPath[secondPath];
    if (firstBytes != null &&
        secondBytes != null &&
        _sameBytes(firstBytes, secondBytes)) {
      actionProofDuplicates.add(
        DuplicateActionProofFrame(
          firstScreenshotPath: firstPath,
          duplicateScreenshotPath: secondPath,
        ),
      );
    }
  }

  // --- Informational sweep: every OTHER identical pair, for audit only.
  // Distinctness carries proof weight only across a declared tap boundary;
  // a duplicate anywhere else (an unavailable branch matching `start`, an
  // alternate-action frame matching the primary result because no scroll
  // was needed) is neither a defect nor evidence -- it is simply what the
  // screen looked like.
  bool isDeclaredPair(String a, String b) => declaredPathPairs.any(
    (pair) => (pair[0] == a && pair[1] == b) || (pair[0] == b && pair[1] == a),
  );
  final informationalDuplicates = <InformationalDuplicateFrame>[];
  final distinctFrames = <_CapturedScreenshotBytes>[];
  for (final path in screenshotPaths) {
    final bytes = bytesByPath[path]!;
    _CapturedScreenshotBytes? firstMatchingFrame;
    for (final distinctFrame in distinctFrames) {
      if (_sameBytes(distinctFrame.bytes, bytes)) {
        firstMatchingFrame = distinctFrame;
        break;
      }
    }
    if (firstMatchingFrame == null) {
      distinctFrames.add(_CapturedScreenshotBytes(path: path, bytes: bytes));
    } else if (!isDeclaredPair(firstMatchingFrame.path, path)) {
      informationalDuplicates.add(
        InformationalDuplicateFrame(
          firstScreenshotPath: firstMatchingFrame.path,
          duplicateScreenshotPath: path,
        ),
      );
    }
  }

  final integrity = WorkflowScreenshotFrameIntegrity(
    verifiedScreenshotCount: screenshotPaths.length,
    actionProofDuplicates: actionProofDuplicates,
    missingDeclarations: missingDeclarations,
    informationalDuplicates: informationalDuplicates,
  );

  final existingIntegrityFindings = <Object?>[
    ...(workflow['captureIntegrityFindings'] as List<dynamic>? ??
        const <dynamic>[]),
  ];
  existingIntegrityFindings
    ..addAll(actionProofDuplicates.map((duplicate) => duplicate.toJson()))
    ..addAll(missingDeclarations.map((missing) => missing.toJson()))
    ..addAll(informationalDuplicates.map((duplicate) => duplicate.toJson()));
  if (existingIntegrityFindings.isNotEmpty) {
    // Retain every finding, including informational ones: this is audit
    // evidence, not something this writer may hide or replace.
    workflow['captureIntegrityFindings'] = existingIntegrityFindings;
  }

  workflow['screenshotCount'] = integrity.verifiedScreenshotCount;
  if (!integrity.hasFailingFindings) {
    return integrity;
  }

  final productFindings = <Object?>[
    ...(workflow['productFindings'] as List<dynamic>? ?? const <dynamic>[]),
  ];
  productFindings
    ..addAll(actionProofDuplicates.map((duplicate) => duplicate.detail))
    ..addAll(missingDeclarations.map((missing) => missing.detail));

  workflow['status'] = 'fail';
  workflow['pass'] = false;
  workflow['screenshotStatus'] = 'failed-duplicate-frame';
  workflow['b25ActionProofStatus'] = 'fail';
  workflow['invalidScreenshotCount'] =
      actionProofDuplicates.length + missingDeclarations.length;
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
