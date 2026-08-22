import 'dart:convert';
import 'dart:io';

class WorkflowUiEvidenceWriter {
  WorkflowUiEvidenceWriter({
    required this.evidenceRoot,
    required this.commandOutputPath,
  });

  final Directory evidenceRoot;
  final String commandOutputPath;
  final Map<String, String> _screenshotPaths = <String, String>{};

  Future<void> markRunStarted() async {
    final finalDirectory = Directory('${evidenceRoot.path}/B20');
    await finalDirectory.create(recursive: true);
    await _aggregateFile.writeAsString(
      _pretty({
        'schemaVersion': 2,
        'status': 'fail',
        'evidenceMode': 'failed',
        'walkthroughStatus': 'not-completed',
        'screenshotStatus': 'not-captured',
        'completionGateEligible': false,
        'failureReason':
            'The walkthrough started but did not return a completed result.',
        'phases': const <String>[],
        'workflowCount': 0,
        'requestedScreenshotCount': 0,
        'screenshotCount': 0,
        'missingScreenshotCount': 0,
        'workflowEvidenceManifestPaths': const <String>[],
        'commandOutputPath': commandOutputPath,
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  Future<bool> recordScreenshot(
    String name,
    List<int> image, [
    Map<String, Object?>? args,
  ]) async {
    final phase = _phaseFor(name, args);
    final directory = Directory('${evidenceRoot.path}/$phase/screenshots');
    await directory.create(recursive: true);
    final file = File('${directory.path}/$name.png');
    await file.writeAsBytes(image, flush: true);
    _screenshotPaths[name] = file.path;
    return true;
  }

  Future<void> writeEvidence(Map<String, dynamic>? data) async {
    final entries = (data?['workflowEvidence'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
    final requestedPhases = _stringList(data?['requestedPhases']);
    final phases = <String>{
      ...requestedPhases,
      for (final entry in entries)
        if (entry['phase'] case final String phase) phase,
    }.toList()..sort();
    final screenshotVisibleTextByName =
        (data?['screenshotVisibleTextByName'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        const <String, String>{};
    final screenshotCapture = _stringMap(data?['screenshotCapture']);
    final screenshotUnavailable = screenshotCapture['status'] == 'unavailable';
    final expectedWorkflowCountByPhase = _intMap(
      data?['expectedWorkflowCountByPhase'],
    );
    final grouped = <String, List<Map<String, dynamic>>>{
      for (final phase in phases) phase: <Map<String, dynamic>>[],
    };
    final expectedScreenshotNameSet = <String>{};

    for (final entry in entries) {
      final phase = entry['phase'] as String? ?? 'unknown';
      final screenshotNames = _stringList(entry['screenshotNames']);
      expectedScreenshotNameSet.addAll(screenshotNames);
      grouped.putIfAbsent(phase, () => <Map<String, dynamic>>[]).add(entry);
    }
    expectedScreenshotNameSet.addAll(
      _stringList(screenshotCapture['requestedScreenshotNames']),
    );
    final expectedScreenshotNames = expectedScreenshotNameSet.toList()..sort();

    final missingScreenshots =
        expectedScreenshotNames
            .where((name) {
              final path = _screenshotPaths[name];
              return path == null || !File(path).existsSync();
            })
            .toSet()
            .toList()
          ..sort();
    final entriesPassed =
        entries.isNotEmpty &&
        entries.every((entry) => entry['status'] == 'pass');
    final walkthroughPassed =
        data?['walkthroughStatus'] == 'pass' && entriesPassed;
    final screenshotsComplete =
        expectedScreenshotNames.isNotEmpty && missingScreenshots.isEmpty;
    final walkthroughOnly =
        walkthroughPassed &&
        screenshotUnavailable &&
        expectedScreenshotNames.isNotEmpty &&
        _screenshotPaths.isEmpty;
    final runStatus = walkthroughPassed && screenshotsComplete
        ? 'pass'
        : walkthroughOnly
        ? 'walkthrough-only'
        : 'fail';
    final screenshotStatus = screenshotsComplete
        ? 'complete'
        : screenshotUnavailable && _screenshotPaths.isEmpty
        ? 'unavailable'
        : _screenshotPaths.isEmpty
        ? 'missing'
        : 'partial';
    final evidenceMode = runStatus == 'pass'
        ? 'full'
        : runStatus == 'walkthrough-only'
        ? 'walkthrough-only'
        : 'failed';
    final failureReason = _failureReason(
      data: data,
      entries: entries,
      walkthroughPassed: walkthroughPassed,
      screenshotUnavailable: screenshotUnavailable,
      missingScreenshots: missingScreenshots,
    );
    final device = _deviceFields(data);
    final phaseSummaries = <Map<String, Object?>>[];

    for (final phase in phases) {
      final phaseEntries = grouped[phase] ?? const <Map<String, dynamic>>[];
      final phaseExpectedNameSet = <String>{
        for (final entry in phaseEntries)
          ..._stringList(entry['screenshotNames']),
        ..._stringList(
          screenshotCapture['requestedScreenshotNames'],
        ).where((name) => _phaseFor(name, null) == phase),
      };
      final phaseExpectedNames = phaseExpectedNameSet.toList()..sort();
      final phaseMissingNames = phaseExpectedNames
          .where((name) => missingScreenshots.contains(name))
          .toList(growable: false);
      final phaseCapturedCount =
          phaseExpectedNames.length - phaseMissingNames.length;
      final expectedPhaseWorkflowCount =
          expectedWorkflowCountByPhase[phase] ?? phaseEntries.length;
      final phaseAssertionsPassed =
          phaseEntries.isNotEmpty &&
          phaseEntries.length == expectedPhaseWorkflowCount &&
          phaseEntries.every((entry) => entry['status'] == 'pass');
      final phaseScreenshotsComplete =
          phaseExpectedNames.isNotEmpty && phaseMissingNames.isEmpty;
      final phaseWalkthroughOnly =
          phaseAssertionsPassed &&
          screenshotUnavailable &&
          phaseExpectedNames.isNotEmpty &&
          phaseCapturedCount == 0;
      final phaseStatus = phaseAssertionsPassed && phaseScreenshotsComplete
          ? 'pass'
          : phaseWalkthroughOnly
          ? 'walkthrough-only'
          : 'fail';
      final phaseScreenshotStatus = phaseScreenshotsComplete
          ? 'complete'
          : screenshotUnavailable && phaseCapturedCount == 0
          ? 'unavailable'
          : phaseCapturedCount == 0
          ? 'missing'
          : 'partial';
      final writtenEntries = <Map<String, dynamic>>[];

      for (final entry in phaseEntries) {
        final screenshotNames = _stringList(entry['screenshotNames']);
        final paths = <String>[];
        final visibleTexts = <String>[];
        for (final name in screenshotNames) {
          final path = _screenshotPaths[name];
          if (path != null && File(path).existsSync()) {
            paths.add(path);
          }
          visibleTexts.add(screenshotVisibleTextByName[name] ?? '');
        }
        writtenEntries.add({
          ...entry,
          'status': phaseStatus,
          'assertionStatus': entry['status'] == 'pass' ? 'pass' : 'fail',
          'screenshotStatus': phaseScreenshotStatus,
          'screenshotPaths': paths,
          'screenshotVisibleTexts': visibleTexts,
          'commandOutputPath': commandOutputPath,
          ...device,
          'pass': phaseStatus == 'pass',
        });
      }

      final directory = Directory('${evidenceRoot.path}/$phase');
      await directory.create(recursive: true);
      final manifest = <String, Object?>{
        'schemaVersion': 2,
        'phase': phase,
        'status': phaseStatus,
        'walkthroughStatus': phaseAssertionsPassed ? 'pass' : 'fail',
        'screenshotStatus': phaseScreenshotStatus,
        'completionGateEligible': phaseStatus == 'pass',
        ...device,
        'commandOutputPath': commandOutputPath,
        'expectedWorkflowCount': expectedPhaseWorkflowCount,
        'workflowCount': phaseEntries.length,
        'requestedScreenshotCount': phaseExpectedNames.length,
        'screenshotCount': phaseCapturedCount,
        'missingScreenshotCount': phaseMissingNames.length,
        'missingScreenshotNames': phaseMissingNames,
        if (phaseScreenshotStatus == 'unavailable')
          'screenshotUnavailableReason': screenshotCapture['reason'],
        'workflows': writtenEntries,
      };
      await File(
        '${directory.path}/workflow-ui-evidence.json',
      ).writeAsString(_pretty(manifest), flush: true);
      await File('${directory.path}/evidence-audit.json').writeAsString(
        _pretty({
          'schemaVersion': 2,
          'phase': phase,
          'status': phaseStatus,
          'walkthroughStatus': phaseAssertionsPassed ? 'pass' : 'fail',
          'screenshotStatus': phaseScreenshotStatus,
          'completionGateEligible': phaseStatus == 'pass',
          'screenshotsAudited': phaseCapturedCount,
          'missingScreenshots': phaseMissingNames,
          if (phaseScreenshotStatus == 'unavailable')
            'screenshotUnavailableReason': screenshotCapture['reason'],
        }),
        flush: true,
      );
      phaseSummaries.add({
        'phase': phase,
        'status': phaseStatus,
        'walkthroughStatus': phaseAssertionsPassed ? 'pass' : 'fail',
        'screenshotStatus': phaseScreenshotStatus,
        'expectedWorkflowCount': expectedPhaseWorkflowCount,
        'workflowCount': phaseEntries.length,
        'requestedScreenshotCount': phaseExpectedNames.length,
        'screenshotCount': phaseCapturedCount,
      });
    }

    final finalDirectory = Directory('${evidenceRoot.path}/B20');
    await finalDirectory.create(recursive: true);
    await _aggregateFile.writeAsString(
      _pretty({
        'schemaVersion': 2,
        'status': runStatus,
        'evidenceMode': evidenceMode,
        'walkthroughStatus': walkthroughPassed ? 'pass' : 'fail',
        'screenshotStatus': screenshotStatus,
        'completionGateEligible': runStatus == 'pass',
        if (failureReason != null) 'failureReason': failureReason,
        if (screenshotUnavailable)
          'screenshotUnavailableReason': screenshotCapture['reason'],
        'phases': phases,
        'phaseSummaries': phaseSummaries,
        'expectedWorkflowCount': expectedWorkflowCountByPhase.values.fold(
          0,
          (total, count) => total + count,
        ),
        'workflowCount': entries.length,
        'requestedScreenshotCount': expectedScreenshotNames.length,
        'screenshotCount': _screenshotPaths.length,
        'missingScreenshotCount': missingScreenshots.length,
        'missingScreenshotNames': missingScreenshots,
        'workflowEvidenceManifestPaths': [
          for (final phase in phases)
            '${evidenceRoot.path}/$phase/workflow-ui-evidence.json',
        ],
        ...device,
        'commandOutputPath': commandOutputPath,
        'recordedAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );

    stdout.writeln(
      'WORKFLOW_EVIDENCE_RESULT status=$runStatus '
      'walkthroughStatus=${walkthroughPassed ? 'pass' : 'fail'} '
      'screenshotStatus=$screenshotStatus workflows=${entries.length} '
      'screenshots=${_screenshotPaths.length}/${expectedScreenshotNames.length} '
      'completionGateEligible=${runStatus == 'pass'}',
    );

    if (walkthroughPassed && runStatus == 'fail') {
      throw StateError(failureReason ?? 'Workflow evidence capture failed.');
    }
  }

  File get _aggregateFile =>
      File('${evidenceRoot.path}/B20/all-workflow-ui-evidence.json');
}

Map<String, Object?> _deviceFields(Map<String, dynamic>? data) => {
  'deviceName': data?['deviceName'] ?? data?['emulatorName'] ?? 'unknown',
  'emulatorName': data?['emulatorName'] ?? data?['deviceName'] ?? 'unknown',
  'deviceClass': data?['deviceClass'] ?? 'unknown',
  'platform': data?['platform'] ?? 'unknown',
  if (data?['apiLevel'] case final String apiLevel) 'apiLevel': apiLevel,
};

String? _failureReason({
  required Map<String, dynamic>? data,
  required List<Map<String, dynamic>> entries,
  required bool walkthroughPassed,
  required bool screenshotUnavailable,
  required List<String> missingScreenshots,
}) {
  if (!walkthroughPassed) {
    if (data?['walkthroughStatus'] != 'pass') {
      return 'The walkthrough assertions did not complete successfully; see commandOutputPath.';
    }
    if (entries.isEmpty) {
      return 'The walkthrough returned no workflow evidence entries.';
    }
    return 'At least one walkthrough evidence entry reported a failed assertion.';
  }
  if (screenshotUnavailable) {
    return null;
  }
  if (missingScreenshots.isNotEmpty) {
    return 'Screenshot capture was incomplete: ${missingScreenshots.length} requested screenshot file(s) are missing.';
  }
  return null;
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) {
    return const <String, int>{};
  }
  return <String, int>{
    for (final entry in value.entries)
      if (entry.value is int) entry.key.toString(): entry.value as int,
  };
}

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[]).whereType<String>().toList(
      growable: false,
    );

String _phaseFor(String name, Map<String, Object?>? args) {
  final fromArgs = args?['phase'];
  if (fromArgs is String && fromArgs.isNotEmpty) {
    return fromArgs;
  }
  final separator = name.indexOf('_');
  return separator == -1 ? 'unknown' : name.substring(0, separator);
}

String _pretty(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
