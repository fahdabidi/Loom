import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/b25_capture_integrity.dart';
import 'package:loom_ux_judges/b25_capture_package_provenance.dart';
import 'package:loom_ux_judges/b25_device_dialog_guard.dart';
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';
import 'package:loom_ux_judges/src/community_package_provenance.dart';

const _fullB25Phases = <String>[
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

void main(List<String> args) async {
  final device = _argValue(args, '--device') ?? 'emulator-5554';
  final appPackage =
      _argValue(args, '--app-package') ?? 'com.example.loom_communities_demo';
  final mode = _argValue(args, '--mode') ?? 'full-b25';
  if (mode != 'full-b25' && mode != 'targeted-precheck') {
    stderr.writeln(
      'b25_capture_workflow_screenshots: --mode must be full-b25 or targeted-precheck.',
    );
    exit(64);
  }
  final phases = (_argValue(args, '--phases') ?? _fullB25Phases.join(','))
      .split(',')
      .map((phase) => phase.trim())
      .where((phase) => phase.isNotEmpty)
      .toList(growable: false);
  final communities = (_argValue(args, '--communities') ?? '')
      .split(',')
      .map((community) => community.trim())
      .where((community) => community.isNotEmpty)
      .toList(growable: false);
  final targetedShardOverrideText = _argValue(args, '--shards');
  final targetedShardOverride = targetedShardOverrideText == null
      ? null
      : int.tryParse(targetedShardOverrideText);
  final targetedOnlyShardText = _argValue(args, '--only-shard');
  final targetedOnlyShard = targetedOnlyShardText == null
      ? null
      : int.tryParse(targetedOnlyShardText);
  if (targetedShardOverrideText != null &&
      (targetedShardOverride == null || targetedShardOverride < 1)) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: --shards must be a positive integer.',
    );
    exit(64);
  }
  if (targetedOnlyShardText != null &&
      (targetedOnlyShard == null || targetedOnlyShard < 0)) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: --only-shard must be a non-negative integer.',
    );
    exit(64);
  }
  final fullCoverage = _samePhases(phases, _fullB25Phases);
  if (mode == 'full-b25' && !fullCoverage) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: canonical B25 evidence requires full B12-B20 coverage. '
      'Requested phases=${phases.join(',')}; expected=${_fullB25Phases.join(',')}. '
      'Use --mode targeted-precheck for remediation diagnostics that must not be committed as canonical B25 evidence.',
    );
    exit(64);
  }
  if (mode == 'full-b25' && communities.isNotEmpty) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: canonical B25 evidence cannot filter communities. '
      'Requested communities=${communities.join(',')}. Use --mode targeted-precheck '
      'for a community-scoped diagnostic.',
    );
    exit(64);
  }
  if (mode == 'full-b25' &&
      (targetedShardOverride != null || targetedOnlyShard != null)) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: canonical B25 sharding is fixed by '
      'phase so a caller cannot weaken capture reliability. Use --shards or '
      '--only-shard only '
      'with --mode targeted-precheck.',
    );
    exit(64);
  }
  final appRoot = Directory.current;
  final repoRoot = appRoot.parent;
  final communityProvenanceManifest =
      CommunityPackageProvenanceManifest.fromFile(
        communityProvenanceManifestFile(repoRoot),
      );
  final communityProvenanceIndex =
      CommunityPackageProvenanceIndex.fromRepository(
        repositoryRoot: repoRoot,
        provenanceManifest: communityProvenanceManifest,
      );
  final interactionModelAsset = generateB25InteractionModelAsset(
    repositoryRoot: repoRoot,
  );
  final demoDir = Directory('${appRoot.path}/apps/loom_communities_demo');
  if (!demoDir.existsSync()) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: expected Demo App at ${demoDir.path}',
    );
    exit(64);
  }

  final evidenceRoot = Directory(
    _argValue(args, '--evidence-root') ??
        '${repoRoot.path}/docs/Build Plan V2/Evidence',
  ).absolute;
  await evidenceRoot.create(recursive: true);
  final captureStartedAt = DateTime.now().toUtc().subtract(
    const Duration(minutes: 1),
  );

  final logPath =
      _argValue(args, '--log') ??
      '${evidenceRoot.path}/B20/flutter-drive-workflow-ui-evidence.log';
  await Directory(File(logPath).parent.path).create(recursive: true);
  final progressReportPath =
      _argValue(args, '--progress-report') ??
      '${evidenceRoot.path}/B25/b25-capture-progress.json';
  await Directory(File(progressReportPath).parent.path).create(recursive: true);

  final output = StringBuffer()
    ..writeln('b25_capture_workflow_screenshots')
    ..writeln('workingDirectory=${demoDir.path}')
    ..writeln('WORKFLOW_EVIDENCE_ROOT=${evidenceRoot.path}')
    ..writeln('mode=$mode')
    ..writeln('phases=${phases.join(',')}')
    ..writeln('communities=${communities.join(',')}')
    ..writeln('device=$device')
    ..writeln('appPackage=$appPackage')
    ..writeln('b25InteractionModelAsset=${interactionModelAsset.path}')
    ..writeln('progressReport=$progressReportPath')
    ..writeln();

  _writeProgressReport(progressReportPath, {
    'status': 'starting',
    'mode': mode,
    'phases': phases,
    'phaseCount': phases.length,
    'completedPhases': 0,
    'currentPhase': null,
    'currentPhaseIndex': 0,
    'currentWorkflowId': null,
    'completedWorkflowsInCurrentPhase': 0,
    'totalWorkflowsInCurrentPhase': null,
    'device': device,
    'evidenceRoot': evidenceRoot.path,
    'logPath': logPath,
  });

  // Frames the DEVICE refused: a native system dialog owned the screen, so the
  // frame is not evidence and was never written. Collected across the run and
  // failed loudly below -- never silently dropped.
  final deviceRejectedFrames = <GuardedFrameCapture>[];

  for (var phaseIndex = 0; phaseIndex < phases.length; phaseIndex += 1) {
    final phase = phases[phaseIndex];
    final shardCount = targetedShardOverride ?? _shardCountForPhase(phase);
    if (targetedOnlyShard != null && targetedOnlyShard >= shardCount) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: --only-shard '
        '$targetedOnlyShard is outside 0..${shardCount - 1}.',
      );
      exit(64);
    }
    _writeProgressReport(progressReportPath, {
      'status': 'running',
      'mode': mode,
      'phases': phases,
      'phaseCount': phases.length,
      'completedPhases': phaseIndex,
      'currentPhase': phase,
      'currentPhaseIndex': phaseIndex + 1,
      'currentWorkflowId': null,
      'completedWorkflowsInCurrentPhase': 0,
      'totalWorkflowsInCurrentPhase': null,
      'device': device,
      'evidenceRoot': evidenceRoot.path,
      'logPath': logPath,
      'shardCount': shardCount,
    });

    final phaseWorkflows = <Map<String, dynamic>>[];
    Map<String, dynamic>? phaseManifestTemplate;
    for (var shardIndex = 0; shardIndex < shardCount; shardIndex += 1) {
      if (targetedOnlyShard != null && shardIndex != targetedOnlyShard) {
        continue;
      }
      // A findings file left by an earlier shard or run must never be read as
      // this run's result.
      clearDeviceDialogFindings(evidenceRoot: evidenceRoot, phase: phase);
      final command = <String>[
        'drive',
        '--driver=test_driver/workflow_ui_evidence_test.dart',
        '--target=integration_test/workflow_ui_evidence_test.dart',
        '-d',
        device,
        '--dart-define=LOOM_EVIDENCE_EXTERNAL_ANDROID_SCREENSHOTS=true',
        '--dart-define=LOOM_EVIDENCE_PHASE_FILTER=$phase',
        if (communities.isNotEmpty)
          '--dart-define=LOOM_EVIDENCE_COMMUNITY_FILTER=${communities.join(',')}',
        if (shardCount > 1) ...[
          '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT=$shardCount',
          '--dart-define=LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX=$shardIndex',
        ],
      ];

      stdout.writeln(
        'b25_capture_workflow_screenshots: [$phase] shard ${shardIndex + 1}/$shardCount running flutter ${command.join(' ')}',
      );
      final result = await _runProcessStreaming(
        executable: 'flutter',
        arguments: command,
        workingDirectory: demoDir.path,
        environment: <String, String>{
          ...Platform.environment,
          'WORKFLOW_EVIDENCE_ROOT': evidenceRoot.path,
          'WORKFLOW_EVIDENCE_COMMAND_OUTPUT': logPath,
        },
        onProgress: (event) {
          if (event['status'] == 'screenshot-start' &&
              event['phase'] is String &&
              event['screenshotName'] is String) {
            final capture = _captureAndroidScreenshot(
              device: device,
              appPackage: appPackage,
              evidenceRoot: evidenceRoot,
              phase: event['phase']! as String,
              screenshotName: event['screenshotName']! as String,
            );
            if (capture.finding != null) {
              deviceRejectedFrames.add(capture);
            }
          }
          final completed = event['completedWorkflows'];
          final total = event['totalWorkflows'];
          _writeProgressReport(progressReportPath, {
            'status': 'running',
            'mode': mode,
            'phases': phases,
            'phaseCount': phases.length,
            'completedPhases': phaseIndex,
            'currentPhase': event['phase'] ?? phase,
            'currentPhaseIndex': phaseIndex + 1,
            'currentShardIndex': shardIndex,
            'shardCount': shardCount,
            'currentWorkflowId': event['workflowId'],
            'currentCommunityName': event['communityName'],
            'currentScreenshotName': event['screenshotName'],
            'workflowStatus': event['status'],
            'completedWorkflowsInCurrentPhase': completed,
            'totalWorkflowsInCurrentPhase': total,
            'device': device,
            'evidenceRoot': evidenceRoot.path,
            'logPath': logPath,
            'command': 'flutter ${command.join(' ')}',
            'lastProgressEvent': event,
          });
          if (completed is int && total is int && total > 0) {
            stdout.writeln(
              'b25_capture_workflow_screenshots: [$phase] shard ${shardIndex + 1}/$shardCount progress $completed/$total '
              'current=${event['workflowId'] ?? event['screenshotName'] ?? 'unknown'} '
              'status=${event['status'] ?? 'running'}',
            );
          }
        },
      );

      output
        ..writeln('--- $phase shard ${shardIndex + 1}/$shardCount ---')
        ..writeln('\$ flutter ${command.join(' ')}')
        ..writeln('exitCode=${result.exitCode}')
        ..writeln()
        ..writeln('--- stdout ---')
        ..write(result.stdout)
        ..writeln()
        ..writeln('--- stderr ---')
        ..write(result.stderr)
        ..writeln();
      await File(logPath).writeAsString(output.toString(), flush: true);

      if (deviceRejectedFrames.isNotEmpty) {
        final detail = deviceRejectedFrames
            .map(
              (capture) =>
                  'frame=${capture.screenshotName} phase=${capture.phase} '
                  '${capture.finding}',
            )
            .join(' | ');
        stderr.writeln(
          'b25_capture_workflow_screenshots: DEVICE SYSTEM DIALOG DETECTED. '
          '${deviceRejectedFrames.length} frame(s) were refused and not '
          'written, so no screenshot count includes them: $detail',
        );
        _writeProgressReport(progressReportPath, {
          'status': 'failed',
          'mode': mode,
          'phases': phases,
          'phaseCount': phases.length,
          'completedPhases': phaseIndex,
          'currentPhase': phase,
          'currentPhaseIndex': phaseIndex + 1,
          'currentShardIndex': shardIndex,
          'shardCount': shardCount,
          'failure': 'device system dialog detected',
          'deviceRejectedFrames': [
            for (final capture in deviceRejectedFrames)
              <String, Object?>{
                'screenshotName': capture.screenshotName,
                'phase': capture.phase,
                ...?capture.finding?.toJson(),
              },
          ],
          'device': device,
          'evidenceRoot': evidenceRoot.path,
          'logPath': logPath,
        });
        exit(66);
      }

      if (result.exitCode != 0) {
        _writeProgressReport(progressReportPath, {
          'status': 'failed',
          'mode': mode,
          'phases': phases,
          'phaseCount': phases.length,
          'completedPhases': phaseIndex,
          'currentPhase': phase,
          'currentPhaseIndex': phaseIndex + 1,
          'currentShardIndex': shardIndex,
          'shardCount': shardCount,
          'exitCode': result.exitCode,
          'device': device,
          'evidenceRoot': evidenceRoot.path,
          'logPath': logPath,
        });
        stderr.writeln(
          'b25_capture_workflow_screenshots: [$phase] shard ${shardIndex + 1}/$shardCount flutter drive failed; log written to $logPath',
        );
        exit(result.exitCode);
      }

      final phaseManifest = File(
        '${evidenceRoot.path}/$phase/workflow-ui-evidence.json',
      );
      if (!phaseManifest.existsSync()) {
        stderr.writeln(
          'b25_capture_workflow_screenshots: [$phase] missing ${phaseManifest.path}; screenshot driver did not write evidence.',
        );
        _writeProgressReport(progressReportPath, {
          'status': 'failed',
          'mode': mode,
          'phases': phases,
          'phaseCount': phases.length,
          'completedPhases': phaseIndex,
          'currentPhase': phase,
          'currentPhaseIndex': phaseIndex + 1,
          'currentShardIndex': shardIndex,
          'shardCount': shardCount,
          'failure': 'missing phase manifest',
          'missingManifest': phaseManifest.path,
          'device': device,
          'evidenceRoot': evidenceRoot.path,
          'logPath': logPath,
        });
        exit(65);
      }
      final decoded = jsonDecode(await phaseManifest.readAsString());
      if (decoded is! Map<String, dynamic>) {
        stderr.writeln(
          'b25_capture_workflow_screenshots: [$phase] invalid ${phaseManifest.path}; screenshot driver did not write a JSON object.',
        );
        exit(65);
      }
      phaseManifestTemplate ??= decoded;
      phaseWorkflows.addAll(
        (decoded['workflows'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>(),
      );
    }

    if (shardCount > 1) {
      if (phaseManifestTemplate == null || phaseWorkflows.isEmpty) {
        stderr.writeln(
          'b25_capture_workflow_screenshots: [$phase] sharded capture produced no workflows.',
        );
        exit(65);
      }
      final phaseDirectory = Directory('${evidenceRoot.path}/$phase');
      await phaseDirectory.create(recursive: true);
      final mergedManifest = <String, Object?>{
        ...phaseManifestTemplate,
        'status': 'pass',
        'workflowCount': phaseWorkflows.length,
        'workflowShards': shardCount,
        'workflows': phaseWorkflows,
      };
      await File(
        '${phaseDirectory.path}/workflow-ui-evidence.json',
      ).writeAsString(
        const JsonEncoder.withIndent('  ').convert(mergedManifest),
        flush: true,
      );
      await File('${phaseDirectory.path}/evidence-audit.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 1,
          'phase': phase,
          'status': 'pass',
          'workflowShards': shardCount,
          'screenshotsAudited': phaseWorkflows
              .expand((entry) => entry['screenshotPaths'] as List<dynamic>)
              .length,
          'missingScreenshots': const <String>[],
        }),
        flush: true,
      );
    }
    _writeProgressReport(progressReportPath, {
      'status': 'running',
      'mode': mode,
      'phases': phases,
      'phaseCount': phases.length,
      'completedPhases': phaseIndex + 1,
      'currentPhase': phase,
      'currentPhaseIndex': phaseIndex + 1,
      'phaseStatus': 'complete',
      'shardCount': shardCount,
      'device': device,
      'evidenceRoot': evidenceRoot.path,
      'logPath': logPath,
    });
  }

  final combinedSummary = await _writeCombinedManifest(
    evidenceRoot: evidenceRoot,
    phases: phases,
    commandOutputPath: logPath,
    captureStartedAt: captureStartedAt,
    mode: mode,
    communityProvenanceIndex: communityProvenanceIndex,
  );

  final screenshotCount = combinedSummary.screenshotCount;
  if (combinedSummary.hasDuplicateFrames) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: byte-identical workflow frames '
      'make this capture invalid. The files are retained for review; no frame '
      'was dropped or retaken.',
    );
    for (final finding in combinedSummary.duplicateFrameFindings) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: duplicate frame '
        '${finding['firstScreenshotPath']} == '
        '${finding['duplicateScreenshotPath']} '
        '(phase=${finding['phase']} workflow=${finding['workflowId']}).',
      );
    }
    _writeProgressReport(progressReportPath, {
      'status': 'failed',
      'failure': 'byte-identical-workflow-frame',
      'mode': mode,
      'phases': phases,
      'phaseCount': phases.length,
      'completedPhases': phases.length,
      'screenshotCount': screenshotCount,
      'aggregatePath': combinedSummary.aggregatePath,
      'captureIntegrityFindings': combinedSummary.duplicateFrameFindings,
      'commitEligible': false,
      'device': device,
      'evidenceRoot': evidenceRoot.path,
      'logPath': logPath,
    });
    exit(65);
  }
  if (mode == 'full-b25' && screenshotCount < 180) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: expected at least 180 screenshots, found $screenshotCount.',
    );
    exit(65);
  }

  if (mode == 'targeted-precheck') {
    _writeProgressReport(progressReportPath, {
      'status': 'complete',
      'mode': mode,
      'phases': phases,
      'phaseCount': phases.length,
      'completedPhases': phases.length,
      'screenshotCount': screenshotCount,
      'aggregatePath': combinedSummary.aggregatePath,
      'commitEligible': false,
      'device': device,
      'evidenceRoot': evidenceRoot.path,
      'logPath': logPath,
    });
    stdout.writeln(
      'b25_capture_workflow_screenshots: targeted precheck captured phases=${phases.join(',')} '
      'screenshots=$screenshotCount aggregate=${combinedSummary.aggregatePath}. '
      'This artifact is not commit-eligible for B25 closeout.',
    );
    return;
  }

  _writeProgressReport(progressReportPath, {
    'status': 'complete',
    'mode': mode,
    'phases': phases,
    'phaseCount': phases.length,
    'completedPhases': phases.length,
    'screenshotCount': screenshotCount,
    'aggregatePath': combinedSummary.aggregatePath,
    'commitEligible': true,
    'device': device,
    'evidenceRoot': evidenceRoot.path,
    'logPath': logPath,
  });
  stdout.writeln(
    'b25_capture_workflow_screenshots: ok fullB25Coverage=true screenshots=$screenshotCount log=$logPath',
  );
}

String? _argValue(List<String> args, String name) {
  for (var index = 0; index < args.length; index += 1) {
    final arg = args[index];
    if (arg == name && index + 1 < args.length) {
      return args[index + 1];
    }
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

bool _samePhases(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) {
      return false;
    }
  }
  return true;
}

/// Grabs one frame with adb, but only after the DEVICE confirms the app under
/// test -- not an ANR, crash or permission dialog -- owns the screen.
///
/// See `b25_device_dialog_guard.dart` for why this device-side check exists in
/// addition to the Flutter-side text guard in the evidence writer.
GuardedFrameCapture _captureAndroidScreenshot({
  required String device,
  required String appPackage,
  required Directory evidenceRoot,
  required String phase,
  required String screenshotName,
}) {
  final capture = captureGuardedAndroidFrame(
    evidenceRoot: evidenceRoot,
    phase: phase,
    screenshotName: screenshotName,
    appPackage: appPackage,
    probe: adbDeviceWindowStateProbe(device),
    grabFrame: () {
      final result = Process.runSync(
        adbExecutableForEnvironment(Platform.environment),
        ['-s', device, 'exec-out', 'screencap', '-p'],
        stdoutEncoding: null,
        stderrEncoding: utf8,
      );
      if (result.exitCode != 0 || result.stdout is! List<int>) {
        stderr.writeln(
          'b25_capture_workflow_screenshots: adb screencap failed for '
          '$phase/$screenshotName exitCode=${result.exitCode} '
          'stderr=${result.stderr}',
        );
        return null;
      }
      return result.stdout as List<int>;
    },
  );
  if (capture.error != null) {
    stderr.writeln('b25_capture_workflow_screenshots: ${capture.error}.');
  }
  if (capture.finding != null) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: refusing frame '
      '$phase/$screenshotName -- ${capture.finding}',
    );
  }
  if (capture.captured) {
    stdout.writeln(
      'b25_capture_workflow_screenshots: captured ${capture.path} '
      'bytes=${File(capture.path!).lengthSync()}',
    );
  }
  return capture;
}

int _shardCountForPhase(String phase) {
  switch (phase) {
    case 'B13':
      // Four Garden rows. Keep each Android process below the emulator's
      // reliable screenshot-callback ceiling while retaining fresh evidence.
      return 2;
    case 'B14':
      // Thirty-four product-doc rows across Book, Soccer, HOA, and Masjid.
      return 17;
    case 'B15':
      // Thirteen product-doc rows across Chess and Camera.
      return 7;
    case 'B16':
      // Twenty-three product-doc rows across Social, Ad-Free, and Data.
      return 12;
    default:
      return 1;
  }
}

String _slug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'targeted' : slug;
}

Future<_StreamingProcessResult> _runProcessStreaming({
  required String executable,
  required List<String> arguments,
  required String workingDirectory,
  required Map<String, String> environment,
  required void Function(Map<String, Object?> event) onProgress,
}) async {
  // lutter and dart are .bat shims on Windows, which Process.start
  // cannot resolve from the bare name -- it fails with "The system cannot find
  // the file specified". Running through the shell lets Windows apply PATHEXT.
  // Left off elsewhere so POSIX hosts keep exec semantics and argument quoting.
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: Platform.isWindows,
  );
  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        stdout.writeln(line);
        stdoutBuffer.writeln(line);
        final event = _parseProgressLine(line);
        if (event != null) {
          onProgress(event);
        }
      })
      .asFuture<void>();
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        stderr.writeln(line);
        stderrBuffer.writeln(line);
      })
      .asFuture<void>();

  final exitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  return _StreamingProcessResult(
    exitCode: exitCode,
    stdout: stdoutBuffer.toString(),
    stderr: stderrBuffer.toString(),
  );
}

Map<String, Object?>? _parseProgressLine(String line) {
  const prefix = 'B25_CAPTURE_PROGRESS ';
  final prefixIndex = line.indexOf(prefix);
  if (prefixIndex < 0) {
    return null;
  }
  try {
    final decoded = jsonDecode(line.substring(prefixIndex + prefix.length));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException {
    return <String, Object?>{
      'status': 'invalid-progress-line',
      'rawLine': line,
    };
  }
  return null;
}

void _writeProgressReport(String path, Map<String, Object?> fields) {
  File(path).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'toolId': 'b25_capture_workflow_screenshots',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      ...fields,
    }),
    flush: true,
  );
}

Future<_CombinedManifestSummary> _writeCombinedManifest({
  required Directory evidenceRoot,
  required List<String> phases,
  required String commandOutputPath,
  required DateTime captureStartedAt,
  required String mode,
  required CommunityPackageProvenanceIndex communityProvenanceIndex,
}) async {
  var workflowCount = 0;
  var screenshotCount = 0;
  final manifestPaths = <String>[];
  final duplicateFrameFindings = <Map<String, Object?>>[];
  final capturedCommunities = <B25CapturedCommunity>[];

  for (final phase in phases) {
    final manifestPath =
        '${evidenceRoot.path}/$phase/workflow-ui-evidence.json';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: missing phase manifest $manifestPath',
      );
      exit(65);
    }
    final manifestModifiedAt = await manifestFile.lastModified();
    if (manifestModifiedAt.toUtc().isBefore(captureStartedAt)) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: phase $phase manifest is stale. '
        'modified=$manifestModifiedAt captureStarted=$captureStartedAt path=$manifestPath',
      );
      exit(65);
    }
    final manifest = jsonDecode(await manifestFile.readAsString());
    if (manifest is! Map<String, dynamic>) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: invalid phase manifest $manifestPath',
      );
      exit(65);
    }
    final workflows = manifest['workflows'];
    if (workflows is! List || workflows.isEmpty) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: phase $phase did not record any workflows.',
      );
      exit(65);
    }
    capturedCommunities.addAll(
      recordB25CapturePackageProvenance(
        manifest: manifest,
        provenanceIndex: communityProvenanceIndex,
      ),
    );
    workflowCount += workflows.length;
    var phaseScreenshotCount = 0;
    final phaseDuplicateFrameFindings = <Map<String, Object?>>[];
    for (final workflow in workflows.whereType<Map<String, dynamic>>()) {
      final paths = workflow['screenshotPaths'];
      if (paths is List) {
        for (final path in paths.whereType<String>()) {
          final screenshot = File(path);
          if (!screenshot.existsSync()) {
            stderr.writeln(
              'b25_capture_workflow_screenshots: missing screenshot $path',
            );
            exit(65);
          }
          final modifiedAt = await screenshot.lastModified();
          if (modifiedAt.toUtc().isBefore(captureStartedAt)) {
            stderr.writeln(
              'b25_capture_workflow_screenshots: stale screenshot $path. '
              'modified=$modifiedAt captureStarted=$captureStartedAt',
            );
            exit(65);
          }
        }
        final integrity = await applyWorkflowScreenshotFrameIntegrity(workflow);
        phaseScreenshotCount += integrity.verifiedScreenshotCount;
        for (final duplicate in integrity.duplicateFrames) {
          final finding = <String, Object?>{
            'phase': phase,
            'workflowId': workflow['workflowId'],
            ...duplicate.toJson(),
          };
          phaseDuplicateFrameFindings.add(finding);
          duplicateFrameFindings.add(finding);
        }
      }
    }
    screenshotCount += phaseScreenshotCount;
    if (phaseDuplicateFrameFindings.isNotEmpty) {
      manifest['status'] = 'fail';
      manifest['screenshotStatus'] = 'failed-duplicate-frame';
      manifest['completionGateEligible'] = false;
      manifest['screenshotCount'] = phaseScreenshotCount;
      manifest['invalidScreenshotCount'] = phaseDuplicateFrameFindings.length;
      manifest['captureIntegrityFindings'] = phaseDuplicateFrameFindings;
      manifest['failureReason'] =
          'Byte-identical frames were captured within a workflow; the capture '
          'cannot distinguish an unchanged screen from a duplicate write.';
      await _markPhaseAuditFailedForDuplicateFrames(
        evidenceRoot: evidenceRoot,
        phase: phase,
        screenshotCount: phaseScreenshotCount,
        duplicateFrameFindings: phaseDuplicateFrameFindings,
      );
    }
    // The package provenance is part of the phase manifest even when no
    // screenshot-integrity finding requires another mutation.
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    manifestPaths.add(manifestPath);
  }

  final fullCoverage = _samePhases(phases, _fullB25Phases);
  final finalDirectory = mode == 'full-b25'
      ? Directory('${evidenceRoot.path}/B20')
      : Directory('${evidenceRoot.path}/B25');
  await finalDirectory.create(recursive: true);
  final aggregatePath = mode == 'full-b25'
      ? '${finalDirectory.path}/all-workflow-ui-evidence.json'
      : '${finalDirectory.path}/targeted-workflow-ui-evidence-${_slug(phases.join('-'))}.json';
  final hasDuplicateFrames = duplicateFrameFindings.isNotEmpty;
  await File(aggregatePath).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'status': hasDuplicateFrames ? 'fail' : 'pass',
      'screenshotStatus': hasDuplicateFrames
          ? 'failed-duplicate-frame'
          : 'complete',
      'phases': phases,
      'expectedPhases': _fullB25Phases,
      'missingPhases': _fullB25Phases
          .where((phase) => !phases.contains(phase))
          .toList(growable: false),
      'workflowCount': workflowCount,
      'screenshotCount': screenshotCount,
      'capturedCommunities': [
        for (final community in combineB25CapturedCommunities(
          capturedCommunities,
        ))
          community.toJson(),
      ],
      'invalidScreenshotCount': duplicateFrameFindings.length,
      if (hasDuplicateFrames)
        'captureIntegrityFindings': duplicateFrameFindings,
      'workflowEvidenceManifestPaths': manifestPaths,
      'commandOutputPath': commandOutputPath,
      'captureMode': mode,
      'fullB25Coverage': fullCoverage,
      'commitEligible':
          mode == 'full-b25' && fullCoverage && !hasDuplicateFrames,
    }),
    flush: true,
  );
  return _CombinedManifestSummary(
    aggregatePath: aggregatePath,
    screenshotCount: screenshotCount,
    duplicateFrameFindings: duplicateFrameFindings,
  );
}

Future<void> _markPhaseAuditFailedForDuplicateFrames({
  required Directory evidenceRoot,
  required String phase,
  required int screenshotCount,
  required List<Map<String, Object?>> duplicateFrameFindings,
}) async {
  final auditFile = File('${evidenceRoot.path}/$phase/evidence-audit.json');
  if (!auditFile.existsSync()) {
    return;
  }
  final decoded = jsonDecode(await auditFile.readAsString());
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: invalid phase audit ${auditFile.path}; '
      'the duplicate frame failure is recorded in the phase manifest.',
    );
    return;
  }
  decoded['status'] = 'fail';
  decoded['screenshotStatus'] = 'failed-duplicate-frame';
  decoded['completionGateEligible'] = false;
  decoded['screenshotsAudited'] = screenshotCount;
  decoded['invalidScreenshotCount'] = duplicateFrameFindings.length;
  decoded['captureIntegrityFindings'] = duplicateFrameFindings;
  await auditFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(decoded),
    flush: true,
  );
}

class _StreamingProcessResult {
  const _StreamingProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _CombinedManifestSummary {
  const _CombinedManifestSummary({
    required this.aggregatePath,
    required this.screenshotCount,
    required this.duplicateFrameFindings,
  });

  final String aggregatePath;
  final int screenshotCount;
  final List<Map<String, Object?>> duplicateFrameFindings;

  bool get hasDuplicateFrames => duplicateFrameFindings.isNotEmpty;
}
