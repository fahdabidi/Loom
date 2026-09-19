import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/b25_device_dialog_guard.dart';

class WorkflowUiEvidenceWriter {
  WorkflowUiEvidenceWriter({
    required this.evidenceRoot,
    required this.commandOutputPath,
  });

  /// Strings that mean a dialog is being rendered INSIDE the Flutter tree.
  ///
  /// This is the SECONDARY check, and on its own it is not sufficient: a native
  /// Android system dialog (ANR, crash, permission prompt) is a window outside
  /// the Flutter tree, so it never reaches `find.byType(Text)` and can never
  /// appear here. The primary mechanism is the device-side window check in
  /// `package:loom_ux_judges/b25_device_dialog_guard.dart`, whose findings this
  /// writer merges in below. Keep both: this one catches an in-app dialog the
  /// device check cannot see, because an in-app dialog does not move window
  /// focus away from the app.
  ///
  /// MARKER SAFETY: every entry is matched as a lowercased substring of real
  /// on-screen product copy, so an entry that occurs inside a shipped string
  /// would reject valid frames. `'wait'` was removed for exactly that reason --
  /// it matched `Join waitlist`, a real affordance in five communities. The
  /// three below were each checked against the shipped copy: no community
  /// string contains them.
  static const systemDialogMarkers = <String>{
    "isn't responding",
    'close app',
    'system ui',
  };

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
    final b25CommunityTraversals =
        (data?['b25CommunityTraversals'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
    final b25RowSummary = _summarizeB25Rows(entries);
    // Seeded to an empty list before the walkthrough runs and only replaced
    // with its final value once the run reaches its own report finalisation.
    // A run that aborts mid-walkthrough leaves this false, and the rows
    // recorded so far (if any) are not a complete count -- see
    // _summarizeB25CommunityTraversals's `finalised` field.
    final b25TraversalFinalised = data?['b25TraversalFinalised'] == true;
    final b25CommunityTraversalSummary = _summarizeB25CommunityTraversals(
      b25CommunityTraversals,
      finalised: b25TraversalFinalised,
    );
    final b25BlockedAudienceReasonGroups =
        _formatB25BlockedAudienceReasonGroups(b25RowSummary);
    final b25BlockedSelectorSetupReasonGroups =
        _formatB25BlockedSelectorSetupReasonGroups(b25RowSummary);
    final b25BlockedPrerequisiteReasonGroups =
        _formatB25BlockedPrerequisiteReasonGroups(b25RowSummary);
    final b25BlockedRows = _formatB25BlockedRows(b25RowSummary);
    final b25NonProvenRows = _formatB25NonProvenRows(b25RowSummary);
    final requestedPhases = _stringList(data?['requestedPhases']);
    final phases = <String>{
      ...requestedPhases,
      for (final entry in entries)
        if (entry['phase'] case final String phase) phase,
      for (final traversal in b25CommunityTraversals)
        if (traversal['phase'] case final String phase) phase,
    }.toList()..sort();
    final screenshotVisibleTextByName =
        (data?['screenshotVisibleTextByName'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        const <String, String>{};
    final systemDialogFrames = _detectSystemDialogFrames(
      entries: entries,
      screenshotVisibleTextByName: screenshotVisibleTextByName,
      evidenceRoot: evidenceRoot,
    );
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
    final noWorkflowPhaseReasons = <String, String>{
      for (final phase in phases)
        if ((grouped[phase] ?? const <Map<String, dynamic>>[]).isEmpty)
          phase:
              'No workflow evidence rows were recorded for phase $phase '
              '(expected workflow count: '
              '${expectedWorkflowCountByPhase[phase] ?? 0}).',
    };
    expectedScreenshotNameSet.addAll(
      _stringList(screenshotCapture['requestedScreenshotNames']),
    );
    final expectedScreenshotNames = expectedScreenshotNameSet.toList()..sort();
    for (final name in expectedScreenshotNames) {
      final hostCapturedFile = File(
        '${evidenceRoot.path}/${_phaseFor(name, null)}/screenshots/$name.png',
      );
      if (hostCapturedFile.existsSync()) {
        _screenshotPaths.putIfAbsent(name, () => hostCapturedFile.path);
      }
    }

    // A frame showing a system dialog is not evidence: remove it from the
    // captured set (and delete its PNG) so no screenshot count can include it.
    for (final name in systemDialogFrames.keys) {
      final path = _screenshotPaths.remove(name);
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }

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
        noWorkflowPhaseReasons.isEmpty &&
        entries.every((entry) => entry['status'] == 'pass') &&
        b25CommunityTraversalSummary['incompletelyTraversedCommunities'] == 0;
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
      b25CommunityTraversalSummary: b25CommunityTraversalSummary,
      noWorkflowPhaseReasons: noWorkflowPhaseReasons,
      walkthroughPassed: walkthroughPassed,
      screenshotUnavailable: screenshotUnavailable,
      missingScreenshots: missingScreenshots,
      systemDialogFrames: systemDialogFrames,
    );
    final systemDialogFailureReason = _systemDialogFailureReason(
      systemDialogFrames,
    );
    final device = _deviceFields(data);
    final phaseSummaries = <Map<String, Object?>>[];

    for (final phase in phases) {
      final phaseEntries = grouped[phase] ?? const <Map<String, dynamic>>[];
      final phaseOutcomeReason = noWorkflowPhaseReasons[phase];
      final phaseCommunityTraversals = b25CommunityTraversals
          .where((traversal) => traversal['phase'] == phase)
          .toList(growable: false);
      final phaseCommunityTraversalSummary = _summarizeB25CommunityTraversals(
        phaseCommunityTraversals,
        finalised: b25TraversalFinalised,
      );
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
          phaseEntries.every((entry) => entry['status'] == 'pass') &&
          phaseCommunityTraversalSummary['incompletelyTraversedCommunities'] ==
              0;
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
          'recordedRowStatus': entry['status'],
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
        if (phaseOutcomeReason != null) 'phaseOutcome': 'no_workflows_recorded',
        if (phaseOutcomeReason != null)
          'phaseOutcomeReason': phaseOutcomeReason,
        if (phaseOutcomeReason != null) 'failureReason': phaseOutcomeReason,
        ...device,
        'commandOutputPath': commandOutputPath,
        'expectedWorkflowCount': expectedPhaseWorkflowCount,
        'workflowCount': phaseEntries.length,
        'b25RowSummary': _summarizeB25Rows(phaseEntries),
        'b25CommunityTraversals': phaseCommunityTraversals,
        'b25CommunityTraversalSummary': phaseCommunityTraversalSummary,
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
          if (phaseOutcomeReason != null)
            'phaseOutcome': 'no_workflows_recorded',
          if (phaseOutcomeReason != null)
            'phaseOutcomeReason': phaseOutcomeReason,
          if (phaseOutcomeReason != null) 'failureReason': phaseOutcomeReason,
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
        if (phaseOutcomeReason != null) 'phaseOutcome': 'no_workflows_recorded',
        if (phaseOutcomeReason != null)
          'phaseOutcomeReason': phaseOutcomeReason,
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
        'b25RowSummary': b25RowSummary,
        'b25CommunityTraversals': b25CommunityTraversals,
        'b25CommunityTraversalSummary': b25CommunityTraversalSummary,
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
      'b25Proven=${b25RowSummary['provenRows']}/'
      '${b25RowSummary['recordedRows']} '
      'b25PrimaryActionUnavailable='
      '${b25RowSummary['primaryActionUnavailableRows']} '
      'b25BlockedByAudience=${b25RowSummary['blockedByAudienceRows']} '
      'b25BlockedByAudienceReasonGroups=$b25BlockedAudienceReasonGroups '
      'b25BlockedBySelectorSetup='
      '${b25RowSummary['blockedBySelectorSetupRows']} '
      'b25BlockedBySelectorSetupReasonGroups='
      '$b25BlockedSelectorSetupReasonGroups '
      'b25BlockedByPrerequisite='
      '${b25RowSummary['blockedByPrerequisiteRows']} '
      'b25BlockedByPrerequisiteReasonGroups='
      '$b25BlockedPrerequisiteReasonGroups '
      'b25BlockedRows=$b25BlockedRows '
      'b25ActionSucceededResultUnverified='
      '${b25RowSummary['actionSucceededResultUnverifiedRows']} '
      'b25ProductFindings=${b25RowSummary['productFindingRows']} '
      'b25RowExecutionFailed=${b25RowSummary['rowExecutionFailedRows']} '
      'b25NonProvenRows=$b25NonProvenRows '
      'b25Communities=${_formatB25CommunityRatio(b25CommunityTraversalSummary)} '
      'b25IncompletelyTraversed='
      '${_formatB25IncompleteCount(b25CommunityTraversalSummary)} '
      'b25TraversalFinalised=$b25TraversalFinalised '
      'screenshots=${_screenshotPaths.length}/${expectedScreenshotNames.length} '
      'completionGateEligible=${runStatus == 'pass'}',
    );

    if (systemDialogFailureReason != null) {
      throw StateError(systemDialogFailureReason);
    }
    if (walkthroughPassed && runStatus == 'fail') {
      throw StateError(failureReason ?? 'Workflow evidence capture failed.');
    }
  }

  File get _aggregateFile =>
      File('${evidenceRoot.path}/B20/all-workflow-ui-evidence.json');
}

String _formatB25BlockedAudienceReasonGroups(Map<String, Object?> summary) {
  final groups =
      summary['blockedByAudienceReasonGroups'] as List<Map<String, Object?>>;
  if (groups.isEmpty) {
    return 'none';
  }
  return groups
      .map(
        (group) =>
            '${(group['cause']! as String).replaceAll(' ', '_')}:${group['count']}',
      )
      .join(',');
}

String _formatB25BlockedSelectorSetupReasonGroups(
  Map<String, Object?> summary,
) {
  final groups =
      summary['blockedBySelectorSetupReasonGroups']
          as List<Map<String, Object?>>;
  if (groups.isEmpty) {
    return 'none';
  }
  return groups
      .map(
        (group) =>
            '${(group['cause']! as String).replaceAll(' ', '_')}:${group['count']}',
      )
      .join(',');
}

String _formatB25BlockedPrerequisiteReasonGroups(Map<String, Object?> summary) {
  final groups =
      summary['blockedByPrerequisiteReasonGroups']
          as List<Map<String, Object?>>;
  if (groups.isEmpty) {
    return 'none';
  }
  return groups
      .map(
        (group) =>
            '${(group['cause']! as String).replaceAll(' ', '_')}:${group['count']}',
      )
      .join(',');
}

String _formatB25BlockedRows(Map<String, Object?> summary) =>
    jsonEncode(summary['blockedRows']);

String _formatB25NonProvenRows(Map<String, Object?> summary) =>
    jsonEncode(summary['nonProvenRows']);

/// A number nobody finished writing must never print as a measurement: an
/// aborted run can still hold a `recordedCommunities`/`completelyTraversed`
/// ratio that looks clean purely because it undercounts, so an unfinalised
/// summary reports `unknown` rather than a ratio that reads as complete.
String _formatB25CommunityRatio(Map<String, Object?> summary) {
  if (summary['finalised'] != true) return 'unknown';
  return '${summary['completelyTraversedCommunities']}/'
      '${summary['recordedCommunities']}';
}

String _formatB25IncompleteCount(Map<String, Object?> summary) {
  if (summary['finalised'] != true) return 'unknown';
  return '${summary['incompletelyTraversedCommunities']}';
}

Map<String, Object?> _summarizeB25CommunityTraversals(
  Iterable<Map<String, dynamic>> traversals, {
  required bool finalised,
}) {
  final records = traversals.toList(growable: false);
  final incompleteCommunities =
      records
          .where(
            (traversal) =>
                traversal['traversalStatus'] == 'incompletely_traversed',
          )
          .map(
            (traversal) => <String, Object?>{
              'phase': traversal['phase'],
              'communityId': traversal['communityId'],
              'communityName': traversal['communityName'],
              'extensionId': traversal['extensionId'],
              'lastRowWalked': traversal['lastRowWalked'],
              'reason': traversal['reason'],
            },
          )
          .toList(growable: false)
        ..sort(
          (left, right) => '${left['phase']}/${left['communityName']}'
              .compareTo('${right['phase']}/${right['communityName']}'),
        );
  final completelyTraversedCommunities = records
      .where(
        (traversal) => traversal['traversalStatus'] == 'completely_traversed',
      )
      .length;
  return <String, Object?>{
    'recordedCommunities': records.length,
    'completelyTraversedCommunities': completelyTraversedCommunities,
    'incompletelyTraversedCommunities': incompleteCommunities.length,
    'incompleteCommunities': incompleteCommunities,
    // Whether the run reached its own report finalisation. A run that
    // aborted mid-walkthrough can still have recorded some communities as
    // "completely_traversed" before it died, but the counts above are then
    // an undercount of the whole run, not a clean result -- see the stdout
    // formatting below, which reports "unknown" rather than a ratio when
    // this is false.
    'finalised': finalised,
  };
}

Map<String, Object?> _summarizeB25Rows(Iterable<Map<String, dynamic>> entries) {
  const blockedOutcomes = <String>{
    'blocked_by_audience',
    'blocked_by_selector_setup',
    'blocked_by_prerequisite',
  };
  final rows = entries
      .where((entry) => entry['b25RowOutcome'] is String)
      .toList(growable: false);
  final blockedRows = rows
      .where((entry) => blockedOutcomes.contains(entry['b25RowOutcome']))
      .toList(growable: false);
  final blockedByAudienceRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_audience')
      .toList(growable: false);
  final blockedBySelectorSetupRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_selector_setup')
      .toList(growable: false);
  final blockedByPrerequisiteRows = blockedRows
      .where((entry) => entry['b25RowOutcome'] == 'blocked_by_prerequisite')
      .toList(growable: false);
  final primaryUnavailableRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'primary_action_unavailable')
      .toList(growable: false);
  final actionSucceededResultUnverifiedRows = rows
      .where(
        (entry) =>
            entry['b25RowOutcome'] == 'action_succeeded_result_unverified',
      )
      .toList(growable: false);
  final productFindingRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'product_finding')
      .toList(growable: false);
  final rowExecutionFailedRows = rows
      .where((entry) => entry['b25RowOutcome'] == 'row_execution_failed')
      .toList(growable: false);
  final provenRows = rows
      .where(
        (entry) =>
            entry['b25RowOutcome'] == 'attempted' &&
            entry['b25ActionProofStatus'] == 'pass',
      )
      .toList(growable: false);
  final completedRows = rows
      .where((entry) => !blockedOutcomes.contains(entry['b25RowOutcome']))
      .toList(growable: false);

  Map<String, int> countByCommunity(Iterable<Map<String, dynamic>> blocked) {
    final counts = <String, int>{};
    for (final row in blocked) {
      final communityName = row['communityName'] as String? ?? '(unknown)';
      counts.update(communityName, (count) => count + 1, ifAbsent: () => 1);
    }
    return <String, int>{
      for (final communityName in counts.keys.toList()..sort())
        communityName: counts[communityName]!,
    };
  }

  List<Map<String, Object?>> reasonGroups(
    Iterable<Map<String, dynamic>> blocked, {
    required String causeField,
    required String reasonField,
  }) {
    final rowsByCause = <String, List<Map<String, dynamic>>>{};
    for (final row in blocked) {
      final cause = row[causeField] as String? ?? '(unknown)';
      rowsByCause.putIfAbsent(cause, () => <Map<String, dynamic>>[]).add(row);
    }
    return <Map<String, Object?>>[
      for (final cause in rowsByCause.keys.toList()..sort())
        <String, Object?>{
          'cause': cause,
          'count': rowsByCause[cause]!.length,
          'rows': <Map<String, Object?>>[
            for (final row in rowsByCause[cause]!)
              <String, Object?>{
                'communityName': row['communityName'],
                'workflowId': row['workflowId'],
                'role': row['role'],
                'reason': row[reasonField],
              },
          ],
        },
    ];
  }

  String nonProvenReason(Map<String, dynamic> row) {
    String? reason;
    switch (row['b25RowOutcome']) {
      case 'blocked_by_audience':
        reason = row['blockedByAudienceReason'] as String?;
        break;
      case 'blocked_by_selector_setup':
        reason = row['blockedBySelectorSetupReason'] as String?;
        break;
      case 'blocked_by_prerequisite':
        reason = row['blockedByPrerequisiteReason'] as String?;
        break;
      case 'action_succeeded_result_unverified':
        reason = row['actionSucceededResultUnverifiedReason'] as String?;
        break;
      case 'row_execution_failed':
        reason = row['rowExecutionFailureReason'] as String?;
        break;
    }
    if (reason == null) {
      final findings = row['productFindings'];
      if (findings is Iterable) {
        reason = findings.whereType<String>().firstOrNull;
      }
    }
    if (reason == null || reason.isEmpty) {
      throw StateError(
        'B25 non-proven row ${row['workflowId']}/${row['role']} has no '
        'verbatim recorded reason.',
      );
    }
    return reason;
  }

  final explicitBlockedRows =
      <Map<String, Object?>>[
        for (final row in blockedRows)
          <String, Object?>{
            'outcome': row['b25RowOutcome'],
            'communityName': row['communityName'],
            'workflowId': row['workflowId'],
            'role': row['role'],
            'reason': row['b25RowOutcome'] == 'blocked_by_audience'
                ? row['blockedByAudienceReason']
                : row['b25RowOutcome'] == 'blocked_by_selector_setup'
                ? row['blockedBySelectorSetupReason']
                : row['blockedByPrerequisiteReason'],
          },
      ]..sort(
        (
          left,
          right,
        ) => '${left['outcome']}/${left['communityName']}/${left['workflowId']}/${left['role']}'
            .compareTo(
              '${right['outcome']}/${right['communityName']}/${right['workflowId']}/${right['role']}',
            ),
      );
  final explicitNonProvenRows =
      <Map<String, Object?>>[
        for (final row in rows)
          if (row['b25ActionProofStatus'] != 'pass')
            <String, Object?>{
              'outcome': row['b25RowOutcome'],
              'communityName': row['communityName'],
              'workflowId': row['workflowId'],
              'role': row['role'],
              'reason': nonProvenReason(row),
            },
      ]..sort(
        (
          left,
          right,
        ) => '${left['outcome']}/${left['communityName']}/${left['workflowId']}/${left['role']}'
            .compareTo(
              '${right['outcome']}/${right['communityName']}/${right['workflowId']}/${right['role']}',
            ),
      );
  return <String, Object?>{
    'recordedRows': rows.length,
    'provenRows': provenRows.length,
    'completedRows': completedRows.length,
    'primaryActionUnavailableRows': primaryUnavailableRows.length,
    'blockedRows': explicitBlockedRows,
    'nonProvenRows': explicitNonProvenRows,
    'blockedByAudienceRows': blockedByAudienceRows.length,
    'blockedByAudienceRowsByCommunity': countByCommunity(blockedByAudienceRows),
    'blockedByAudienceReasonGroups': reasonGroups(
      blockedByAudienceRows,
      causeField: 'blockedByAudienceCause',
      reasonField: 'blockedByAudienceReason',
    ),
    'blockedBySelectorSetupRows': blockedBySelectorSetupRows.length,
    'blockedBySelectorSetupRowsByCommunity': countByCommunity(
      blockedBySelectorSetupRows,
    ),
    'blockedBySelectorSetupReasonGroups': reasonGroups(
      blockedBySelectorSetupRows,
      causeField: 'blockedBySelectorSetupCause',
      reasonField: 'blockedBySelectorSetupReason',
    ),
    'blockedByPrerequisiteRows': blockedByPrerequisiteRows.length,
    'blockedByPrerequisiteRowsByCommunity': countByCommunity(
      blockedByPrerequisiteRows,
    ),
    'blockedByPrerequisiteReasonGroups': reasonGroups(
      blockedByPrerequisiteRows,
      causeField: 'b25RowOutcome',
      reasonField: 'blockedByPrerequisiteReason',
    ),
    'actionSucceededResultUnverifiedRows':
        actionSucceededResultUnverifiedRows.length,
    'actionSucceededResultUnverifiedRowsByCommunity': countByCommunity(
      actionSucceededResultUnverifiedRows,
    ),
    'productFindingRows': productFindingRows.length,
    'productFindingRowsByCommunity': countByCommunity(productFindingRows),
    'rowExecutionFailedRows': rowExecutionFailedRows.length,
    'rowExecutionFailedRowsByCommunity': countByCommunity(
      rowExecutionFailedRows,
    ),
  };
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
  required Map<String, Object?> b25CommunityTraversalSummary,
  required Map<String, String> noWorkflowPhaseReasons,
  required bool walkthroughPassed,
  required bool screenshotUnavailable,
  required List<String> missingScreenshots,
  required Map<String, List<_SystemDialogFinding>> systemDialogFrames,
}) {
  if (systemDialogFrames.isNotEmpty) {
    return _systemDialogFailureReason(systemDialogFrames);
  }
  if (!walkthroughPassed) {
    final incompleteCommunities =
        b25CommunityTraversalSummary['incompleteCommunities']
            as List<Map<String, Object?>>;
    if (incompleteCommunities.isNotEmpty) {
      return 'One or more communities were incompletely traversed: '
          '${jsonEncode(incompleteCommunities)}';
    }
    if (noWorkflowPhaseReasons.isNotEmpty) {
      return noWorkflowPhaseReasons.entries
          .map((entry) => entry.value)
          .join(' ');
    }
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

Map<String, List<_SystemDialogFinding>> _detectSystemDialogFrames({
  required List<Map<String, dynamic>> entries,
  required Map<String, String> screenshotVisibleTextByName,
  required Directory evidenceRoot,
}) {
  final findings = <String, List<_SystemDialogFinding>>{};
  final deviceFindingsByPhase = <String, Map<String, DeviceDialogFinding>>{};
  for (final entry in entries) {
    final workflowId = entry['workflowId']?.toString() ?? '';
    final role = entry['role']?.toString() ?? '';
    final appId = entry['appId']?.toString() ?? '';
    final communityId = entry['communityId']?.toString() ?? '';
    for (final name in _stringList(entry['screenshotNames'])) {
      // PRIMARY: what the device reported while the host grabbed this frame.
      // The capture CLI writes these; a native system dialog can only be seen
      // this way.
      final phase = _phaseFor(name, null);
      final deviceFindings = deviceFindingsByPhase.putIfAbsent(
        phase,
        () =>
            readDeviceDialogFindings(evidenceRoot: evidenceRoot, phase: phase),
      );
      final deviceFinding = deviceFindings[name];
      if (deviceFinding != null) {
        findings
            .putIfAbsent(name, () => <_SystemDialogFinding>[])
            .add(
              _SystemDialogFinding(
                frame: name,
                source: 'device',
                detected:
                    '${deviceFinding.kind} at ${deviceFinding.stage}: '
                    '${deviceFinding.detail}',
                workflowId: workflowId,
                role: role,
                appId: appId,
                communityId: communityId,
              ),
            );
      }

      // SECONDARY: an in-app dialog rendered by Flutter itself.
      final visibleText = screenshotVisibleTextByName[name] ?? '';
      final marker = _systemDialogMarkerIn(visibleText);
      if (marker == null) {
        continue;
      }
      findings
          .putIfAbsent(name, () => <_SystemDialogFinding>[])
          .add(
            _SystemDialogFinding(
              frame: name,
              source: 'flutter-text',
              detected: marker,
              workflowId: workflowId,
              role: role,
              appId: appId,
              communityId: communityId,
            ),
          );
    }
  }
  return findings;
}

String? _systemDialogMarkerIn(String visibleText) {
  final normalized = visibleText.toLowerCase();
  for (final marker in WorkflowUiEvidenceWriter.systemDialogMarkers) {
    if (normalized.contains(marker)) {
      return marker;
    }
  }
  return null;
}

String? _systemDialogFailureReason(
  Map<String, List<_SystemDialogFinding>> systemDialogFrames,
) {
  if (systemDialogFrames.isEmpty) {
    return null;
  }
  final details = systemDialogFrames.entries
      .map((entry) {
        final findings = entry.value;
        return findings
            .map(
              (finding) =>
                  'frame=${finding.frame} source=${finding.source} '
                  'detected="${finding.detected}" '
                  'workflow=${finding.workflowId} '
                  'role=${finding.role} community=${finding.communityId}',
            )
            .join('; ');
      })
      .join(' | ');
  return 'System dialog detected on captured frame(s); these frames are not '
      'valid evidence and were not recorded: $details';
}

class _SystemDialogFinding {
  const _SystemDialogFinding({
    required this.frame,
    required this.source,
    required this.detected,
    required this.workflowId,
    required this.role,
    required this.appId,
    required this.communityId,
  });

  final String frame;

  /// `device` (the device-side window check) or `flutter-text` (the in-app
  /// secondary check). Recorded so a report says which mechanism fired.
  final String source;
  final String detected;
  final String workflowId;
  final String role;
  final String appId;
  final String communityId;
}

String _pretty(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
