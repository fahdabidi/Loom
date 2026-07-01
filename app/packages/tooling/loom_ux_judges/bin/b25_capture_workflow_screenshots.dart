import 'dart:convert';
import 'dart:io';

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
  final fullCoverage = _samePhases(phases, _fullB25Phases);
  if (mode == 'full-b25' && !fullCoverage) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: canonical B25 evidence requires full B12-B20 coverage. '
      'Requested phases=${phases.join(',')}; expected=${_fullB25Phases.join(',')}. '
      'Use --mode targeted-precheck for remediation diagnostics that must not be committed as canonical B25 evidence.',
    );
    exit(64);
  }
  final appRoot = Directory.current;
  final repoRoot = appRoot.parent;
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
    ..writeln('device=$device')
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

  for (var phaseIndex = 0; phaseIndex < phases.length; phaseIndex += 1) {
    final phase = phases[phaseIndex];
    final shardCount = _shardCountForPhase(phase);
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
      final command = <String>[
        'drive',
        '--driver=test_driver/workflow_ui_evidence_test.dart',
        '--target=integration_test/workflow_ui_evidence_test.dart',
        '-d',
        device,
        '--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true',
        '--dart-define=LOOM_EVIDENCE_PHASE_FILTER=$phase',
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
  );

  final screenshotCount = combinedSummary.screenshotCount;
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

int _shardCountForPhase(String phase) {
  switch (phase) {
    case 'B14':
      return 4;
    case 'B16':
      return 3;
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
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
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
  if (!line.startsWith(prefix)) {
    return null;
  }
  try {
    final decoded = jsonDecode(line.substring(prefix.length));
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
}) async {
  var workflowCount = 0;
  var screenshotCount = 0;
  final manifestPaths = <String>[];

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
    workflowCount += workflows.length;
    for (final workflow in workflows.whereType<Map<String, dynamic>>()) {
      final paths = workflow['screenshotPaths'];
      if (paths is List) {
        screenshotCount += paths.length;
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
      }
    }
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
  await File(aggregatePath).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'status': 'pass',
      'phases': phases,
      'expectedPhases': _fullB25Phases,
      'missingPhases': _fullB25Phases
          .where((phase) => !phases.contains(phase))
          .toList(growable: false),
      'workflowCount': workflowCount,
      'screenshotCount': screenshotCount,
      'workflowEvidenceManifestPaths': manifestPaths,
      'commandOutputPath': commandOutputPath,
      'captureMode': mode,
      'fullB25Coverage': fullCoverage,
      'commitEligible': mode == 'full-b25' && fullCoverage,
    }),
    flush: true,
  );
  return _CombinedManifestSummary(
    aggregatePath: aggregatePath,
    screenshotCount: screenshotCount,
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
  });

  final String aggregatePath;
  final int screenshotCount;
}
